struct Acquirer:
	first_name: String[32]
	last_name: String[32]
	patronymic: String[32]


struct Organization:
	name: String[64]


struct Certificate:
	certificate_id: String[16]
	acquirer: Acquirer
	issuer: Organization
	type: String[16]
	issue_date: uint256
	place_of_issue: String[64]
	additional_info: String[64]
	is_cancelled: bool


event Issuance:
	id: indexed(String[16])


event Cancellation:
	id: indexed(String[16])


supervisor: address
regulators: HashMap[address, Organization]
certificateIdToCertificate: HashMap[String[16], Certificate]


@external
def __init__():
    '''
    @dev Contract constructor.
    '''
    self.supervisor = msg.sender


@external
def addRegulator(_regulator: address, _organization_name: String[64]):
	assert msg.sender == self.supervisor, 'Only supervisor is allowed to perform this operation'
	
	assert _regulator != empty(address), 'Regulator Address must not be empty'
	assert _organization_name != '', 'Organization Name must not be empty'
	
	self.regulators[_regulator] = Organization({name: _organization_name})


@external
def issue(_acquirer_first_name: String[32], _acquirer_last_name: String[32], _acquirer_patronymic: String[32],
	_certificate_type: String[16], 	_certificate_id: String[16], _certificate_issue_date: uint256, _certificate_place_of_issue: String[64], _certificate_additional_info: String[64]):
	regulator: Organization = self.regulators[msg.sender]
	assert regulator.name != '', 'Only regulator is allowed to perform this operation'
	assert _certificate_id != '', 'Certificate ID must not be empty'
	assert self.certificateIdToCertificate[_certificate_id].certificate_id == '', 'Certificate with a given ID already exists'

	assert _acquirer_first_name != '', 'Acquirer First Name must not be empty'
	assert _acquirer_last_name != '', 'Acquirer Last Name must not be empty'
	assert _acquirer_patronymic != '', 'Acquirer Patronymic must not be empty'
	assert _certificate_type != '', 'Certificate Type must not be empty'
	assert _certificate_issue_date != 0, 'Certificate Issue Date must not be empty'
	assert _certificate_place_of_issue != '', 'Certificate Place of Issue must not be empty'

	acquirer: Acquirer = Acquirer({
		first_name: _acquirer_first_name,
		last_name: _acquirer_last_name,
		patronymic: _acquirer_patronymic
	})
	certificate: Certificate = Certificate({
		certificate_id: _certificate_id,
		acquirer: acquirer,
		issuer: regulator,
		type: _certificate_type,
		issue_date: _certificate_issue_date,
		place_of_issue: _certificate_place_of_issue,
		additional_info: _certificate_additional_info,
		is_cancelled: False
	})
	self.certificateIdToCertificate[_certificate_id] = certificate
	log Issuance(_certificate_id)


@external
def cancel(_certificate_id: String[16]):
	assert self.regulators[msg.sender].name != '', 'Only regulator is allowed to perform this operation'
	assert _certificate_id != '', 'Certificate ID must not be empty'
	assert self.certificateIdToCertificate[_certificate_id].certificate_id != '', 'Certificate with a given ID does not exist'

	self.certificateIdToCertificate[_certificate_id].is_cancelled = True
	log Cancellation(_certificate_id)


@view
@external
def getCertificateById(_certificate_id: String[16]) -> Certificate:
	assert _certificate_id != '', 'Certificate ID must not be empty'
	assert self.certificateIdToCertificate[_certificate_id].certificate_id != '', 'Certificate with a given ID does not exist'

	return self.certificateIdToCertificate[_certificate_id]