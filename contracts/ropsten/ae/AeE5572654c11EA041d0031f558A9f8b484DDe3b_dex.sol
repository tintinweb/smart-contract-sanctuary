// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
import "./ERC20.sol";
contract dex  is ERC20{
   address payable Owner;
   uint256  InitialBlockNumber;
    constructor()  ERC20("dex token","dex"){
         MainHolder();
  	     Owner=msg.sender;
  	     InitialBlockNumber=block.number;
   } 
     function ClaimAfterVesting() public{
         //change 518400 to willed blocknumber from launching block for example if u deploy contract on 100 block number and you want to excute function after 175 you have to write InitialBlockNumber+75
        require(block.number>InitialBlockNumber+25,"Time Is Not Reached");
        require(VestedTokens[msg.sender]>0,"You Are Not Eligible For Claim");
        _mint(msg.sender,VestedTokens[msg.sender]);
        VestedTokens[msg.sender]=0;
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