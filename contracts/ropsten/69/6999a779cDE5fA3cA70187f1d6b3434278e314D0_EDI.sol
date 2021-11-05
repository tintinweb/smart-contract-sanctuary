/**
 *Submitted for verification at Etherscan.io on 2021-11-05
*/

pragma solidity ^0.8.0;

struct Student{
  string name;
  string nationality;
  string RG_number;
  string RG_agency;
  string RG_UF;
  string birthplace;
  uint256 birthdate;
}

struct Degree{
  bytes32 ID;
  string number;
  string register_number;
  string process_number;
  string course;
  string academic_degree;
  uint256 completion_date;
  uint256 graduation_date;
  uint256 issue_date;
  uint256 registration_date;
  bool is_valid;
  Student student;
}

contract EDI{
  string public IES_name = unicode"Instituto Federal de Educação, Ciência e Tecnologia de Mato Grosso";
  string public IES_acronym = "IFMT";
  string public IES_CNPJ = "00000000000";
  string[] public IES_courses;
  
  address  admin;
  address[] issuers;
  
  mapping(bytes32 => Degree) degrees;
  bytes32[] degrees_keys;
  
  constructor(){
    admin = msg.sender;
  }
  
  modifier onlyAdmin{
    require(msg.sender == admin, "only_admin");
    _;
  }
  
  modifier onlyIssuers{
    bool is_issuer = false;
    
    for (uint16 i=0; i < issuers.length; i++){
      if(msg.sender == issuers[i])
        is_issuer = true;
    }
    
    require(is_issuer, "only_issuers");
    _;
  }
  
  function addIssuer(address _issuer) public onlyAdmin{
    if(!hasIssuer(_issuer))
      issuers.push(_issuer);
  }

  function removeIssuer(address _issuer) public onlyAdmin{
    int indexToBeDeleted = -1;
    
    for (uint i=0; i < issuers.length; i++){
      if (issuers[i] == _issuer){
        indexToBeDeleted = int(i);
        break;
      }
    }

    if (indexToBeDeleted < 0)
      require(false, "issuer_not_found");

    issuers[uint(indexToBeDeleted)] = issuers[issuers.length-1];
    issuers.pop(); 
  }

  function getIssuers() public view returns(address[] memory){
    return issuers;
  }

  function addCourse(string memory _course) public onlyAdmin{
    if(!hasCourse(_course))
      IES_courses.push(_course);
  }
  
  function getCourses() public view returns(string[] memory){
    return IES_courses;
  }

  function _generateID(string memory _student_CPF, string memory _course) internal pure returns(bytes32 ){
    return keccak256(abi.encodePacked(_student_CPF, _course));
  }
  
  function createDegree(
    string memory _student_CPF,
    string memory _course,
    string memory _number,
    string memory _register_number,
    string memory _process_number,
    string memory _academic_degree,
    uint256 _completion_date,
    uint256 _graduation_date,
    uint256 _registration_date
  ) public onlyIssuers returns(bytes32){
          
    bytes32 ID = _generateID(_student_CPF, _course);

    require(hasCourse(_course), "course_not_found");
    require(!hasDegree(ID), "degree_already_exists");
    
    degrees[ID].ID                    = ID;
    degrees[ID].number                = _number;
    degrees[ID].register_number       = _register_number;
    degrees[ID].process_number        = _process_number;
    degrees[ID].course                = _course;
    degrees[ID].academic_degree       = _academic_degree;
    degrees[ID].completion_date       = _completion_date;
    degrees[ID].graduation_date       = _graduation_date;
    degrees[ID].registration_date     = _registration_date;
    
    degrees_keys.push(ID);
    return ID;     
  }

  function addStudent(
    string memory _CPF,
    string memory _degree_course,
    string memory _name,
    string memory _nationality,
    string memory _RG_number,
    string memory _RG_agency,
    string memory _RG_UF,
    string memory _birthplace,
    uint256 _birthdate
  ) public onlyIssuers returns (bytes32){

    bytes32 ID = _generateID(_CPF, _degree_course);

    require(degrees[ID].issue_date == 0, 'degree_already_issued');
    require(degrees[ID].graduation_date > 0, 'degree_not_created');

    degrees[ID].student.name          = _name;
    degrees[ID].student.nationality   = _nationality;
    degrees[ID].student.RG_number     = _RG_number;
    degrees[ID].student.RG_agency     = _RG_agency;
    degrees[ID].student.RG_UF         = _RG_UF;
    degrees[ID].student.birthplace    = _birthplace;
    degrees[ID].student.birthdate     = _birthdate;
    degrees[ID].issue_date            = block.timestamp;
    degrees[ID].is_valid              = true;

    return ID;    
  }

  
  function invalidateDegree(bytes32 _ID) public onlyIssuers{
    degrees[_ID].is_valid = false;
  }
  
  function getDegreeByID(bytes32 _ID) public view returns (Degree memory){
    return degrees[_ID];
  }
  
  function getDegreeByCPFAndCourse(string memory _student_CPF, string memory _course) public view returns (Degree memory){
    bytes32 ID = _generateID(_student_CPF, _course);
    return degrees[ID];
  }
  
  function hasCourse(string memory _course) public view returns(bool){
    for (uint16 i=0; i < IES_courses.length; i++) 
      if (keccak256(abi.encodePacked(IES_courses[i])) == keccak256(abi.encodePacked(_course)))
        return true;
    
    return false;
  }
  
  function hasIssuer(address  _issuer) public view returns(bool){
    for (uint i=0; i < issuers.length; i++)
      if (issuers[i] == _issuer)
        return true;
    
    return false;
  }

  function hasDegree(bytes32 _ID) public view returns(bool){
    for (uint i=0; i < degrees_keys.length; i++)
      if (degrees_keys[i] == _ID)
        return true;
    
    return false;
  }

  function getDegreeIDs() public onlyAdmin view returns(bytes32[] memory){
    return degrees_keys;
  }
}