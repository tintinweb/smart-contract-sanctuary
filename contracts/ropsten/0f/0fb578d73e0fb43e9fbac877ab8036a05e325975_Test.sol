pragma solidity ^0.4.24;

contract Test {
    address public lastAddr;
    address public lastFrom;
    uint256 public lastAmt;
    
    
    function receiveApproval(address _from, uint256 _value, address _token, bytes _data) public {
        lastAddr = msg.sender;
        lastFrom = _from;
        lastAmt = _value;
    }
	
    
    
    
}