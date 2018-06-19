pragma solidity ^0.4.4;


contract showNum {
    address owner = msg.sender;

    uint _num = 0;
   function setNum(uint number) public payable {
        _num = number;
    }

    function getNum() constant public returns(uint) {
        return _num;
    }
}