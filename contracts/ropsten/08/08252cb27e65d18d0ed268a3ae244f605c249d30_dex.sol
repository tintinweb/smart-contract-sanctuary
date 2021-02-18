// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
import "./ERC20.sol";
contract dex  is ERC20{
   address payable Owner;
    constructor()  ERC20("dex token","dex"){
       _mint(msg.sender,uint256(1860000)*uint256(10**18));
        Owner=msg.sender;
   } 
   modifier OnlyOwner{
       require(msg.sender==Owner,"unautorized access");
       _;
   }
   function DestructToken() public OnlyOwner{
       selfdestruct(msg.sender);
   }
  // function mint(address payable account,uint256 amount) public OnlyOwner{
    //   _mint(account,amount);
   //}
//   function burn(address payable account,uint256 amount) public OnlyOwner{
  //     _burn(account,amount);
   //}
   function TransferOwnerShip(address payable NewAddress) public OnlyOwner{
      Owner=NewAddress;
    }
   function ShowOwner()public view returns(address){
       return Owner;
   }
   function  disable() public  OnlyOwner{
      IsEnd=true;
   }
}