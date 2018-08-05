pragma solidity ^0.4.0;
 
contract Register{
    struct student{ // 학생구조 정보
        uint number;
        string affiliation;
        string name;
        uint count;
        address saddress;
    }
    string name;
    string symbol;
    uint totalToken;
    uint numberOfStudent;
    address owner;

    mapping(address => uint) balance;
    mapping(uint => student) studentList;
    
    event Student(uint indexed number, string indexed affiliation, string indexed name);

    
    function Register(uint _token, string _name, string _symbol){ // 토큰 초기화
        totalToken = _token;
        name = _name;
        symbol = _symbol;
        balance[msg.sender] = _token;
        owner = msg.sender;
    }
    

    function transfer(uint _num, uint _token) {
        balance[studentList[_num].saddress] += _token;
    }

    
    function saveStudent(uint _number, string _affiliation, string _name, address _address) { // 학생 등록
        numberOfStudent++;
        studentList[_number].number = _number;
        studentList[_number].affiliation = _affiliation;
        studentList[_number].name = _name;
        studentList[_number].saddress = _address;
        Student(_number, _affiliation, _name);
    }
    

    function getstudentInfo(uint _number) constant returns (uint, string, string, address, uint){ // 각 학생 정보 반환
       address checkingaddress = studentList[_number].saddress;
       uint checkingbalance = balance[checkingaddress];
       return (_number, studentList[_number].affiliation, studentList[_number].name, studentList[_number].saddress, checkingbalance); 
    
    }

    function getResult() constant returns (uint, string, string, uint){ // 최고 상점자  반환
        uint winner = 1;
        for(uint i = 2; i <= numberOfStudent; i++){
            if(balance[studentList[winner].saddress] <= balance[studentList[i].saddress]) winner = i;
        }
        return (winner, studentList[winner].affiliation, studentList[winner].name, studentList[winner].count);
    }
}