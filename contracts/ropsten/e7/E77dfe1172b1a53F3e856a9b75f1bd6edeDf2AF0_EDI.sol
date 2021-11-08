/**
 *Submitted for verification at Etherscan.io on 2021-11-08
*/

//SPDX-License-Identifier: MIT

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

struct Course{
  uint16 ID;
  string name;
  string academic_degree;
}

struct Degree{
  bytes32 ID;
  string number;
  string register_number;
  string process_number;
  uint256 completion_date;
  uint256 graduation_date;
  uint256 issue_date;
  uint256 registration_date;
  uint16 course_ID;
  Student student;
  bool is_valid;
}

contract EDI{
  string public IES_name = unicode"Instituto Federal de Educação, Ciência e Tecnologia de Mato Grosso";
  string public IES_acronym = "IFMT";
  string public IES_CNPJ = "11111111111111";

  address public admin;      // Endereco do administrador do contrato.
  address[] public issuers;  // Enderecos autorizados a emitir diplomas.
  
  mapping(bytes32 => Degree) public degrees; // Mapping que armazena todos so diplomas.
  bytes32[] degrees_keys;             // Lista das chaves dos diplomas.

  mapping(uint16 => Course) public courses;  // Mapping que armazena todos os cursos ofertados pela IES.
  uint16 private last_course_ID = 0;          // Ultimo valor utilizado como course_ID.
  
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

  /*
  * Adiciona um novo curso a lista de cursos (courses) da IES.
  */
  function addCourse(string memory _name, string memory _academic_degree) public onlyAdmin{
    uint16 ID = ++last_course_ID;

    courses[ID].name = _name;
    courses[ID].academic_degree = _academic_degree;
  }

  /*
  * Altera as informacoes do curso identificado por _ID
  *
  * Requirements:
  * - O curso deve ter um ID valido.
  */
  function changeCourse(uint16 _ID, string memory _name, string memory _academic_degree) public onlyAdmin{
    require(_ID <= last_course_ID, "course_ID_not_exists");

    courses[_ID].name = _name;
    courses[_ID].academic_degree = _academic_degree;
  }
  
  /*
  * Adiciona um novo endereco a lista de enderecos autorizados a emitir diplomas.
  */
  function addIssuer(address _issuer) public onlyAdmin{
    if(!hasIssuer(_issuer))
      issuers.push(_issuer);
  }

  /*
  * Deleta um endereco da lista de enderecos autorizados a emitir diplomas.
  *
  * Requirements:
  * - O endereco deve existir na lista de enderecos autorizados a emitir diplomas.
  */
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

  /*
  * Gera um degreeID a partir do CPF e o nome do curso do estudante.
  * Requirements:
  * - O curso deve existir.
  */
  function _generateDegreeID(string memory _student_CPF, uint16 _course_ID) internal view returns(bytes32 ){
    require(hasCourse(_course_ID), "course_not_found");

    return keccak256(abi.encodePacked(_student_CPF, courses[_course_ID].name));
  }
  
  /*
  * Cria um novo diploma.
  *
  * Requirements:
  * - O curso selecionado deve existir;
  * - O diploma nao pode existir na lista de diplomas.
  */
  function createDegree(
    string memory _student_CPF,
    uint16 _course_ID,
    string memory _number,
    string memory _register_number,
    string memory _process_number,
    uint256 _completion_date,
    uint256 _graduation_date,
    uint256 _registration_date
  ) public onlyIssuers returns(bytes32){
         
    bytes32 ID = _generateDegreeID(_student_CPF, _course_ID);

    require(hasCourse(_course_ID), "course_not_found");
    require(!hasDegree(ID), "degree_already_exists");
    
    degrees[ID].ID                    = ID;
    degrees[ID].course_ID             = _course_ID;
    degrees[ID].number                = _number;
    degrees[ID].register_number       = _register_number;
    degrees[ID].process_number        = _process_number;
    degrees[ID].completion_date       = _completion_date;
    degrees[ID].graduation_date       = _graduation_date;
    degrees[ID].registration_date     = _registration_date;
    
    degrees_keys.push(ID);
    return ID;     
  }

  /*
  * Adiciona o estudante ao diploma.
  *
  * Requirements:
  * - O diploma deve ter sido criado anteriomente;
  * - O diploma nao pode ter sido emitido.
  */
  function addStudent(
    string memory _CPF,
    uint16 _course_ID,
    string memory _name,
    string memory _nationality,
    string memory _RG_number,
    string memory _RG_agency,
    string memory _RG_UF,
    string memory _birthplace,
    uint256 _birthdate
  ) public onlyIssuers returns (bytes32){

    bytes32 ID = _generateDegreeID(_CPF, _course_ID);

    require(degrees[ID].graduation_date > 0, 'degree_not_created');
    require(degrees[ID].issue_date == 0, 'degree_already_issued');

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
  
  function getDegreeByCPFAndCourse(string memory _student_CPF, uint16 _course_ID) public view returns (Degree memory){
    bytes32 ID = _generateDegreeID(_student_CPF, _course_ID);
    return degrees[ID];
  }

  function getIssuers() public view returns(address[] memory){
    return issuers;
  }

  function getDegreeIDs() public onlyAdmin view returns(bytes32[] memory){
    return degrees_keys;
  }

  function getCourses() public view returns(Course[] memory){
    Course[] memory _courses = new Course[](last_course_ID);

    for(uint16 i=0; i < last_course_ID; i++){
      _courses[i] = courses[i + 1];
    }

    return _courses;
  }

  function hasCourse(uint16 _ID) public view returns(bool){
    if(_ID <= last_course_ID)
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
}