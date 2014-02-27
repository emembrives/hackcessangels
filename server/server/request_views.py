# coding=utf-8

from server import app
from server import utils
from server.database import get_db
from server.models import Point
import server.error_messages

from flask import Response
from flask import redirect
from flask import render_template
from flask import request
from flask import session

import datetime

# POST: Creates a new user. Needed parameters: email, password
# GET: Get an existing user. Needed parameters: email
# PUT: Updates an existing user. Needed parameters: email, password, user
# DELETE: Delets an existing user. Needed parameters: email, password
@app.route("/api/request",methods=['GET', 'POST', 'PUT', 'DELETE'])
@utils.json_response
@utils.user_login_required
def request_api():
    requests = get_db().request
    users = get_db().user

    request_data = utils.load_form_or_json_params(request)

    # Create a new request
    if request.method == "POST":
        if "lat" not in request_data and "lng" not in request_data:
            return server.error_messages.MALFORMED_REQUEST, 400

        user = users.find_one({"email": session["email"]})
        if user == None:
            return server.error_messages.UNKNOWN_USER, 404
        user = users.User(user)

        help_request = requests.Request()
        help_request["user"] = user["_id"]
        help_request["location"]["user_location"] = Point(
                request_data["lat"], request_data["lng"])
        help_request["location"]["last_update"] = datetime.datetime.today()
        help_request["date_requested"] = datetime.datetime.today()
        help_request["active"] = True
        help_request.save()

        return help_request.to_json()

    # Get the current request
    elif request.method == "GET":
        user = users.find_one({"email": session["email"]})
        if user == None:
            return server.error_messages.UNKNOWN_USER, 404
        user = users.User(user)
        help_request = requests.find_one({"user": user["_id"], "active": True})
        if help_request == None:
            return {}
        help_request = requests.Request(help_request)
        return help_request.to_json()

    elif request.method == "PUT":
        if "lat" not in request_data and "lng" not in request_data:
            return server.error_messages.MALFORMED_REQUEST, 400
        user = users.find_one({"email": session["email"]})
        if user == None:
            return server.error_messages.UNKNOWN_USER, 404
        user = users.User(user)
        help_request = requests.find_one({"user": user["_id"], "active": True})
        if help_request == None:
            return [], 404
        help_request = requests.Request(help_request)
        help_request["location"]["user_location"] = Point(
                request_data["lat"], request_data["lng"])
        help_request.save()
        return help_request.to_json()

    elif request.method == "DELETE":
        user = users.find_one({"email": session["email"]})
        if user == None:
            return server.error_messages.UNKNOWN_USER, 404
        user = users.User(user)
        user_requests = requests.find({"user": user["_id"], "active": True})
        for help_request in user_requests:
            help_request = requests.Request(help_request)
            help_request["active"] = False
            help_request.save()
        return [], 200

    return [], 405

