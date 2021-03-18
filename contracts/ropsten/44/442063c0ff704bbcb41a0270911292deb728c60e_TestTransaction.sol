/**
 *Submitted for verification at Etherscan.io on 2021-03-18
*/

pragma solidity >=0.7.0 <=0.9.0;

contract TestTransaction{
    address public admin;
    constructor() payable{
      admin=msg.sender;
    }
    
    function deposit(uint amount) public payable {
      address acc = 0x9bd5cbD90722379E817D5a479a65774ab7CA92F7;
      payable(acc).transfer(amount);
    }

    function getBalance() view public returns(uint){
       address acc = 0x9bd5cbD90722379E817D5a479a65774ab7CA92F7;
       return acc.balance;
    }

    function getOwnerBalance() view public returns(uint){
       address owner = msg.sender;
       return owner.balance;
     }
     
    function getContractValue() view public returns(uint){
       return address(this).balance;
     }
     
}