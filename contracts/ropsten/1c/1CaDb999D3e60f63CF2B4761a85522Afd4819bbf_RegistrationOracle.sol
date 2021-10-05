// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

// import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol';
// import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "ClassRegistrationToken.sol";

contract RegistrationOracle {
    
    address internal owner = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    
    address internal tokenAddr;
    ClassRegistrationToken _token = ClassRegistrationToken(tokenAddr);
    
    function _setTokenAddress(address _addr) private {
        tokenAddr = _addr;
        _token = ClassRegistrationToken(tokenAddr);
    }
    
    // To set the token address
    function setTokenAddress(address _addr) public {
        _setTokenAddress(_addr);
    }
    
    // struct Subject
    struct Subject {
        string code;
        string name;
        uint fee;
        uint8 maxClass;
        // string[] classes;
    }

    // struct Class    
    struct Class {
        string code;
        string start;
        string end;
        uint8 maxStudent;
        address[] students;
    }
    
    // array to store subjects
    Subject[] subjects;
    
    // array to store classes
    Class[] classes;
    
    // mapping for storing classes in each subject    
    mapping (string => mapping (string => Class)) public classesInSubject;
    mapping (string => Subject) public codeToSubject;
    mapping (string => Subject) public nameToSubject;
    mapping (string => uint8) public classCount; 
    mapping (string => address[]) public studentInClass;
    mapping (string => string) public classCodeToSubjectCode;
    mapping (address => mapping (string => Class)) public classesOfEachStudent;
    
    constructor() {
        createSubject("IT1234", "Database", 100, 2);
        createClass("123123", "IT1234", "6h45", "8h25", 50);
    }
    
    function _createSubject(string memory _code, string memory _name, uint _fee, uint8 _maxClass) private notExistedName(_name) notExistedCode(_code) {
        // string memory classes = new string[](0);
        Subject memory sbj = Subject(_code, _name, _fee, _maxClass);
        subjects.push(sbj);
        codeToSubject[_code] = sbj;
        nameToSubject[_code] = sbj;
    }
    
    modifier notExistedCode(string memory _code) {
        require(keccak256(abi.encodePacked(_code)) != keccak256(abi.encodePacked(codeToSubject[_code].code)), "Existed Code!");
        _;
    }
    
    modifier notExistedName(string memory _name) {
        require(keccak256(abi.encodePacked(_name)) != keccak256(abi.encodePacked(nameToSubject[_name].name)), "Existed Name");
        _;
    }
    
    function createSubject(string memory _code, string memory _name, uint _fee, uint8 _maxClass) public {
        _createSubject(_code,_name, _fee, _maxClass);
    }
    
    function getSubject(string memory _code) public view returns (string memory, string memory, uint, uint8) {
        Subject memory sbj = codeToSubject[_code];
        return (sbj.code, sbj.name, sbj.fee, sbj.maxClass);
    }
    
    function getAllSubjects() public view returns (string[] memory) {
        string[] memory result = new string[](subjects.length);
        
        for (uint8 i = 0; i < subjects.length; i++) {
            result[i] = subjects[i].code;
        }
        
        return result;
    }
    
    
    
    // Create Class
    function _createClass(string memory _code, string memory _subject, string memory _start, string memory _end, uint8 _maxStudent) private {
        address[] memory students = new address[](0);
        Class memory cl = Class(_code, _start, _end, _maxStudent, students);
        classes.push(cl);
        classesInSubject[_subject][_code] = cl;
        classCount[_subject]++;
        
        classCodeToSubjectCode[_code] = _subject;
    }
    
    function createClass(string memory _code, string memory _subject, string memory _start, string memory _end, uint8 _maxStudent) public {
        _createClass(_code, _subject, _start, _end, _maxStudent);
    }
    
    // function getClass(string memory _code) public view returns (string memory, string)
    
    function getAllClasses() public view returns (string[] memory) {
        string[] memory result = new string[](classes.length);
        
        for (uint8 i = 0; i < classes.length; i++) {
            result[i] = classes[i].code;
        }
        
        return result;
    }
    
    function getClass(string memory _code) public view returns (string memory, string memory, string memory, string memory, string memory) {  // subject name, subject code, class code, start, end
        // string memory  = classCodeToSubjectCode[_code];
        string memory sbjCode;
        string memory sbjName;
        (sbjCode, sbjName,,) = getSubject(classCodeToSubjectCode[_code]);
        Class memory cls = classesInSubject[sbjCode][_code];
        return (sbjName, sbjCode, _code, cls.start, cls.end);
    }
    
    // register
    function register(address _from, string memory _class) public {
        // classesInSubject[_subject][_class].students.push(msg.sender);
        studentInClass[_class].push(_from);
    }
    
    function transferToken(address _from, address _to, uint _amount) public {
        _token.transferFrom(_from, _to, _amount);
    }
    
    // get all classes by address
    function getRegistedClass(address _student) public view returns (string[] memory) {
        
    }
    
}