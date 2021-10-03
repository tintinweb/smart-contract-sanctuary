/**
 *Submitted for verification at Etherscan.io on 2021-10-03
*/

pragma solidity ^0.5.11;

contract FirstContract {
    uint value;
    address sender; 
    
    function getValue() external view returns(uint) { 
        return value;
    }
    
    function setValue(uint _value) external {
        sender = msg.sender;
        value = _value;
    }
    
    function getMsgSender() external view returns(address) { 
        return sender;
    }
    
    
}