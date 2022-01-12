/**
 *Submitted for verification at Etherscan.io on 2022-01-11
*/

pragma solidity ^0.4.18;

contract UserNick {
   
    address Account2;
    address Owner;
  
    string userNick;
   

    uint amount;
 
    constructor() public{
        Account2 = 0xa8ed6c761D14FDD5CBEA97911e718929b500b9E6;
        Owner = msg.sender;
    }



function () payable external{}
   
    function UserNick_Register(string _userNick) public payable {
       userNick = _userNick;
       address(uint160(Account2)).transfer(0.01 ether);
    }
}