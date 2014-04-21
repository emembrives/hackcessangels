package server

import (
	"encoding/json"
	"log"
	"net/http"

	"hackcessangels/backend/model"
)

type APIRequest struct {
    Id        string

	IsActive  bool

    User      *ApiUser
	Agent     *ApiUser

    Longitude float64
    Latitude float64
    Precision float64
}

func NewAPIRequestFromHelpRequest(hr *model.HelpRequest) *APIRequest {
	apiRequest := new(APIRequest)
	apiRequest.IsActive = hr.IsActive
    agent, err := hr.GetAgent()
    if (err == nil) {
        apiRequest.Agent = NewApiUser(agent)
    }

    user, err := hr.GetUser()
    if (err == nil) {
        apiRequest.User = NewApiUser(user)
    }
    apiRequest.Longitude = hr.RequesterPosition.Coordinates[0]
    apiRequest.Latitude = hr.RequesterPosition.Coordinates[1]
    apiRequest.Precision = hr.RequesterPosPrecision
    return apiRequest
}

func (s *Server) handleHelp(w http.ResponseWriter, r *http.Request) {
	var data struct {
		HelpRequestId *string  `json:"id,omitempty"`
		Latitude      *float64 `json:"latitude,omitempty"`
		Longitude     *float64 `json:"longitude,omitempty"`
		Precision     *float64 `json:"precision,omitempty"`
	}
	w.Header().Add("Content-Type", "application/json")
	err := getJSONRequest(r, &data)
	if err != nil {
        log.Print(err)
		returnError(400, "Invalid request", w)
		return
	}

	session, err := s.store.Get(r, "user")
	if err != nil {
		returnError(401, "Please log in", w)
		return
	}

	loggedEmail, ok := session.Values["email"].(string)
	if !ok {
		returnError(401, "Please log in", w)
		return
	}
    log.Print(loggedEmail)
	user, err := s.model.GetUserByEmail(loggedEmail)
	if err != nil {
		returnError(404, "Error while getting user data", w)
		return
	}

	switch r.Method {
	case "POST":
		helpRequest, err := s.model.GetOrCreateActiveRequestByRequester(user)
		if err != nil {
			log.Printf("Error while getting active request: %+v", err)
			returnError(500, "Couldn't create request", w)
		}
		if data.Longitude == nil {
			returnError(400, "Invalid request: longitude missing", w)
			return
		}
		if data.Latitude == nil {
			returnError(400, "Invalid request: latitude missing", w)
			return
		}
		helpRequest.SetRequesterPosition(*data.Longitude, *data.Latitude)
		if data.Precision != nil {
			helpRequest.RequesterPosPrecision = *data.Precision
		}
		err = helpRequest.Save()
		if err != nil {
			log.Printf("Error while saving help request: %+v", err)
			returnError(500, "Couldn't save request", w)
			return
		}
		json.NewEncoder(w).Encode(NewAPIRequestFromHelpRequest(helpRequest))
		return
	case "PUT":
		helpRequest, err := s.model.GetActiveRequestByRequester(user)
		if err != nil {
			log.Printf("Error while getting active request: %+v", err)
			returnError(404, "Couldn't get request", w)
		}
		if data.Longitude == nil {
			returnError(400, "Invalid request: longitude missing", w)
			return
		}
		if data.Latitude == nil {
			returnError(400, "Invalid request: latitude missing", w)
			return
		}
		helpRequest.SetRequesterPosition(*data.Longitude, *data.Latitude)
		if data.Precision != nil {
			helpRequest.RequesterPosPrecision = *data.Precision
		}
		err = helpRequest.Save()
		if err != nil {
			log.Printf("Error while saving help request: %+v", err)
			returnError(500, "Couldn't save request", w)
			return
		}
		json.NewEncoder(w).Encode(NewAPIRequestFromHelpRequest(helpRequest))
		return
	case "DELETE":
		helpRequest, err := s.model.GetActiveRequestByRequester(user)
		if err != nil {
			log.Printf("Error while getting active request: %+v", err)
			returnError(404, "Couldn't get request", w)
		}
		helpRequest.Deactivate()
		return
	default:
		returnError(405, "Not implemented", w)
		return
	}
}
