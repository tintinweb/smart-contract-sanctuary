/**
 *Submitted for verification at Etherscan.io on 2021-09-13
*/

pragma solidity ^0.4.17;

contract Faucet{
    function withdraw(uint amount) public {
        require(amount <= 1000000000000000000);
        
        msg.sender.transfer(amount);
    }
    
    function () public payable{
        
    }
    
    string public name;
    
    constructor(string _name) public{
        name = _name;
    }
    
    function getName() public view returns (string){
        return name;
    }
}