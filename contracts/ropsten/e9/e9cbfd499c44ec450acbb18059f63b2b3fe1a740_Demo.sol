pragma solidity ^0.4.22;


contract UpDemo {

    string public message;
    bool public isEnding;

    constructor() public{
        isEnding = true;
        message = &quot;&quot;;
    }

    function testYBool() public view returns(bool _rYBool){
        return isEnding;
    }
}



contract Demo is UpDemo {

    function writeMessage(string _msg) public{
        message = _msg;
    }
    function readMessage() view public returns (string _rMsg) {
        return message;    
    }

    function newOK() public view returns(bool _rOk){
        return isEnding;
    }
    
}