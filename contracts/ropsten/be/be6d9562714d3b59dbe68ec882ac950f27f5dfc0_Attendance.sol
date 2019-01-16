pragma solidity ^0.4.24;

contract Attendance {
    
    bytes16 private examCode; //Nonce-ish to validate student in the class
    uint private studentNumber;
    string private hashedSignature; //IPFS direction of screenshot of signature
    uint8 private time; //Maybe change for confirmed block?

    
    address public student;
    
    constructor() public {
        student = msg.sender;
    }
    
    function signAttendance(bytes16 _examCode,uint _studentNumber, string _hashedSignature, uint8 _time ) public    {
        examCode = _examCode;
        studentNumber= _studentNumber;
        hashedSignature =_hashedSignature;
        time = _time;
    }
}