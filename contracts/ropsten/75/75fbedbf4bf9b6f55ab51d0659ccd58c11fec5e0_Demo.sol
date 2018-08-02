pragma solidity ^0.4.22;


contract Demo {

    string public message;
    bool public isEnding;

    constructor() public{
        isEnding = true;
    }

    function writeMessage(string _msg) public{
        message = _msg;
    }
    function readMessage() view public returns (string _rMsg) {
        return message;    
    }

    function testYBool() public view returns(bool _rYBool){
        return isEnding;
    }
    
    // function testNBool() public  returns(bool _rNBool){
    //     bool storage temVar = false;
    //     return temVar;
    // }

    

}