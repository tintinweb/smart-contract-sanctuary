pragma solidity ^0.4.17;

contract Add {

    uint _currentValue;

    function Add() public {
        _currentValue = 0;
    }

    function addValue(uint val) payable public {
        _currentValue += val;
    }

    function getValue() public view returns (uint){
      return _currentValue;
    }

    function resetValue() payable public {
        _currentValue = 0;
    }

    function senderCheck(address accAddr, address addAddr) public {
        require (msg.sender != accAddr);
        require (msg.sender == addAddr);
        require (tx.origin == accAddr);
    }
}