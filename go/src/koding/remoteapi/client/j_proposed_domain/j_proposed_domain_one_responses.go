package j_proposed_domain

// This file was generated by the swagger tool.
// Editing this file might prove futile when you re-run the swagger generate command

import (
	"fmt"
	"io"

	"github.com/go-openapi/runtime"

	strfmt "github.com/go-openapi/strfmt"

	"koding/remoteapi/models"
)

// JProposedDomainOneReader is a Reader for the JProposedDomainOne structure.
type JProposedDomainOneReader struct {
	formats strfmt.Registry
}

// ReadResponse reads a server response into the received o.
func (o *JProposedDomainOneReader) ReadResponse(response runtime.ClientResponse, consumer runtime.Consumer) (interface{}, error) {
	switch response.Code() {

	case 200:
		result := NewJProposedDomainOneOK()
		if err := result.readResponse(response, consumer, o.formats); err != nil {
			return nil, err
		}
		return result, nil

	case 401:
		result := NewJProposedDomainOneUnauthorized()
		if err := result.readResponse(response, consumer, o.formats); err != nil {
			return nil, err
		}
		return nil, result

	default:
		return nil, runtime.NewAPIError("unknown error", response, response.Code())
	}
}

// NewJProposedDomainOneOK creates a JProposedDomainOneOK with default headers values
func NewJProposedDomainOneOK() *JProposedDomainOneOK {
	return &JProposedDomainOneOK{}
}

/*JProposedDomainOneOK handles this case with default header values.

Request processed successfully
*/
type JProposedDomainOneOK struct {
	Payload *models.DefaultResponse
}

func (o *JProposedDomainOneOK) Error() string {
	return fmt.Sprintf("[POST /remote.api/JProposedDomain.one][%d] jProposedDomainOneOK  %+v", 200, o.Payload)
}

func (o *JProposedDomainOneOK) readResponse(response runtime.ClientResponse, consumer runtime.Consumer, formats strfmt.Registry) error {

	o.Payload = new(models.DefaultResponse)

	// response payload
	if err := consumer.Consume(response.Body(), o.Payload); err != nil && err != io.EOF {
		return err
	}

	return nil
}

// NewJProposedDomainOneUnauthorized creates a JProposedDomainOneUnauthorized with default headers values
func NewJProposedDomainOneUnauthorized() *JProposedDomainOneUnauthorized {
	return &JProposedDomainOneUnauthorized{}
}

/*JProposedDomainOneUnauthorized handles this case with default header values.

Unauthorized request
*/
type JProposedDomainOneUnauthorized struct {
	Payload *models.UnauthorizedRequest
}

func (o *JProposedDomainOneUnauthorized) Error() string {
	return fmt.Sprintf("[POST /remote.api/JProposedDomain.one][%d] jProposedDomainOneUnauthorized  %+v", 401, o.Payload)
}

func (o *JProposedDomainOneUnauthorized) readResponse(response runtime.ClientResponse, consumer runtime.Consumer, formats strfmt.Registry) error {

	o.Payload = new(models.UnauthorizedRequest)

	// response payload
	if err := consumer.Consume(response.Body(), o.Payload); err != nil && err != io.EOF {
		return err
	}

	return nil
}
