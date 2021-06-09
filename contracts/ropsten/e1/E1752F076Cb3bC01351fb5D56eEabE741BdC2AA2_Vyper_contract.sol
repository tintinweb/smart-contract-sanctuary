struct Student:
	full_name: String[48]
	guid: String[36]


struct Issuer:
	name: String[48]
	location: String[32]


struct Certificate:
	id: String[16]
	student: Student
	issuer: Issuer
	type: String[16]
	registration_date: uint256
	release_date: uint256
	organization: String[48]
	place_of_issue: String[32]
	additional_info: String[64]
	is_cancelled: bool


event Issuance:
	id: indexed(String[16])


event Cancellation:
	id: indexed(String[16])


supervisor: address
regulators: HashMap[address, Issuer]
certificateIdToCertificate: HashMap[String[16], Certificate]

@external
def __init__():
    '''
    @dev Contract constructor.
    '''
    self.supervisor = msg.sender


@external
def addRegulator(_regulator: address, _issuer_name: String[48], _issuer_location: String[32]):
	assert msg.sender == self.supervisor, 'Only supervisor is allowed to perform this operation'
	
	assert _regulator != empty(address), 'Regulator Address must not be empty'
	assert _issuer_name != '', 'Issuer Name must not be empty'
	assert _issuer_location != '', 'Issuer Location must not be empty'
	
	self.regulators[_regulator] = Issuer({
		name: _issuer_name,
		location: _issuer_location
	})

@external
def removeRegulator(_regulator: address):
	assert msg.sender == self.supervisor, 'Only supervisor is allowed to perform this operation'
	assert _regulator != empty(address), 'Regulator Address must not be empty'
	
	self.regulators[_regulator] = empty(Issuer)


@internal
def validateCertificate(_regulator_name: String[48], _certificate_id: String[16],
	_student_full_name: String[48], _student_guid: String[36],
	_certificate_type: String[16], 	_certificate_registration_date: uint256, _certificate_release_date: uint256,
	_certificate_place_of_issue: String[32], _certificate_additional_info: String[64]):
	assert _regulator_name != '', 'Only regulator is allowed to perform this operation'
	assert _certificate_id != '', 'Certificate ID must not be empty'
	assert self.certificateIdToCertificate[_certificate_id].id == '', 'Certificate with a given ID already exists'

	assert _student_full_name != '', 'Student Full Name must not be empty'
	assert _student_guid != '', 'Student GUID must not be empty'
	assert _certificate_type != '', 'Certificate Type must not be empty'
	assert _certificate_registration_date != 0, 'Certificate Registration Date must not be empty'
	assert _certificate_release_date != 0, 'Certificate Release Date must not be empty'
	assert _certificate_place_of_issue != '', 'Certificate Place of Issue must not be empty'


@external
def issueByRegulator(_certificate_id: String[16], _student_full_name: String[48], _student_guid: String[36],
	_certificate_type: String[16], _certificate_registration_date: uint256, _certificate_release_date: uint256,
	_certificate_place_of_issue: String[32], _certificate_additional_info: String[64]):
	regulator: Issuer = self.regulators[msg.sender]
	self.validateCertificate(
		regulator.name, _certificate_id, _student_full_name, _student_guid,
		_certificate_type, _certificate_registration_date, _certificate_release_date,
		_certificate_place_of_issue, _certificate_additional_info
	)
	
	student: Student = Student({
		full_name: _student_full_name,
		guid: _student_guid
	})
	certificate: Certificate = Certificate({
		id: _certificate_id,
		student: student,
		issuer: regulator,
		type: _certificate_type,
		registration_date: _certificate_registration_date,
		release_date: _certificate_release_date,
		organization: regulator.name,
		place_of_issue: _certificate_place_of_issue,
		additional_info: _certificate_additional_info,
		is_cancelled: False
	})
	self.certificateIdToCertificate[_certificate_id] = certificate
	log Issuance(_certificate_id)


@external
def issueBySupervisor(_certificate_id: String[16], _student_full_name: String[48], _student_guid: String[36],
	_certificate_type: String[16], _certificate_registration_date: uint256, _certificate_release_date: uint256, _certificate_organization: String[48],
	_certificate_place_of_issue: String[32], _certificate_additional_info: String[64]):
	assert self.supervisor == msg.sender, 'Only supervisor is allowed to perform this operation'
	regulator: Issuer = self.regulators[msg.sender]
	self.validateCertificate(
		regulator.name, _certificate_id, _student_full_name, _student_guid,
		_certificate_type, _certificate_registration_date, _certificate_release_date,
		_certificate_place_of_issue, _certificate_additional_info
	)
	assert _certificate_organization != '', 'Certificate Organization must not be empty'

	student: Student = Student({
		full_name: _student_full_name,
		guid: _student_guid
	})
	certificate: Certificate = Certificate({
		id: _certificate_id,
		student: student,
		issuer: regulator,
		type: _certificate_type,
		registration_date: _certificate_registration_date,
		release_date: _certificate_release_date,
		organization: _certificate_organization,
		place_of_issue: _certificate_place_of_issue,
		additional_info: _certificate_additional_info,
		is_cancelled: False
	})
	self.certificateIdToCertificate[_certificate_id] = certificate
	log Issuance(_certificate_id)


@external
def cancel(_certificate_id: String[16]):
	regulator: Issuer = self.regulators[msg.sender]
	is_regulator: bool = regulator.name != ''
	is_supervisor: bool = self.supervisor == msg.sender
	assert (is_supervisor or is_regulator), 'Only supervisor or regulator are allowed to perform this operation'
	assert _certificate_id != '', 'Certificate ID must not be empty'
	assert self.certificateIdToCertificate[_certificate_id].id != '', 'Certificate with a given ID does not exist'

	certificate: Certificate = self.certificateIdToCertificate[_certificate_id]
		
	if is_regulator and not is_supervisor:
		assert certificate.organization == regulator.name, 'Certificate to be cancelled must be issued by your organization'

	self.certificateIdToCertificate[_certificate_id].is_cancelled = True
	log Cancellation(_certificate_id)


@view
@external
def getCertificateById(_certificate_id: String[16]) -> Certificate:
	assert _certificate_id != '', 'Certificate ID must not be empty'
	assert self.certificateIdToCertificate[_certificate_id].id != '', 'Certificate with a given ID does not exist'

	return self.certificateIdToCertificate[_certificate_id]