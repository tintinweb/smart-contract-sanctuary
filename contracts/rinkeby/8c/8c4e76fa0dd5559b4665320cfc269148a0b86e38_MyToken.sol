/**
 *Submitted for verification at Etherscan.io on 2021-04-19
*/

pragma solidity ^0.7.0;

contract MyToken{
    
    address public owner;
    mapping(address => uint256) public balances;
    
    event Sent(address from,address to, uint256 amount);
    
    constructor() {
        owner=msg.sender;
    }
    
    function mint(address receiver, uint256 amount) public{
        
        require( msg.sender == owner);
        require( amount > 0);
        balances[receiver]+=amount;
        
    }
    
    function send( address receiver, uint256 amount) public{
        
        require(amount<=balances[msg.sender], "Insufficient balance");
        balances[msg.sender]-=amount;
        balances[receiver]+=amount;
        emit Sent( msg.sender,  receiver,  amount);
        
    }
    
    function balance(address _address) external view returns(uint){
        return balances[_address];
        
    }
}