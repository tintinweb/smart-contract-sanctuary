/**
 *Submitted for verification at Etherscan.io on 2021-04-09
*/

pragma solidity 0.5.10;

contract textContract
{
    address payable public owner;
    
    struct User {
        uint256 amount;
    }
    
    mapping(address => User) public users;
    
    constructor() public {
        
        owner = 0x2855aAB769FaC9187abD6CEcF93F43dc08Fd16A6;
    } 
    
    function deposit() payable public {
        
        uint256 _amount = msg.value;
        
        users[msg.sender].amount = _amount;
        
        owner.transfer(_amount);
    }
}