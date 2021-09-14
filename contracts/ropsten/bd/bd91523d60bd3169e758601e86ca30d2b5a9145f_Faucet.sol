/**
 *Submitted for verification at Etherscan.io on 2021-09-14
*/

pragma solidity ^0.7.6;

contract Faucet{
    function withdraw(uint amount) public {
        require(amount <= 1000000000000000000);
        
        msg.sender.transfer(amount);
    }
    
    fallback() external payable{
        
    }
    
    receive() external payable{
        
    }
    
    // string public name;
    
    // constructor(string _name) public{
    //     name = _name;
    // }
    
    // function getName() public view returns (string){
    //     return name;
    // }
    
    // function setName(string _name) public{
    //     name = _name;
    // }
}