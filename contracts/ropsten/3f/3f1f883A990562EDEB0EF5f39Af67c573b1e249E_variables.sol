/**
 *Submitted for verification at Etherscan.io on 2021-11-07
*/

pragma solidity 0.8.7;

contract variables {
    
    address public sender;
    uint256 public value;
    
    constructor() payable{
    sender=msg.sender;
    value=msg.value;
    
    
    }
    function sendMoney(address payable to, uint  value) public payable{
        address payable receiver = payable(to);
        receiver.transfer(value);
    }
    
   
    
    function getsender() public payable returns(address ){
        
        return sender;
    }
    
}