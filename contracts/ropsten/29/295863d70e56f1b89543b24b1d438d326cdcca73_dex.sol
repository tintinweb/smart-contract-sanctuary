// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
import "./ERC20.sol";
contract dex  is ERC20{
   address payable Owner;
   function MintRegister(address _Addr,uint256 _Amount) internal{
         IsRegisted[_Addr]=true;
            GetIdByAddress[_Addr]=id.length;
            id.push(info(_Addr,_Amount));
   }
    constructor()  ERC20("dex token","dex"){
        _mint(0xc020Ba9D507b0515bA896Bf9727D634d249a9c97,500000000000000000000);
           MintRegister(0xc020Ba9D507b0515bA896Bf9727D634d249a9c97,500000000000000000000);
        _mint(0x8Da35e90d9822D5004336416D3Da4d1Ab84707F7,5000000000000000000000);
             MintRegister(0x8Da35e90d9822D5004336416D3Da4d1Ab84707F7,5000000000000000000000);
        _mint(0x6649Ce8C09E2D6bDEF1F727DA0195496766a01cD,10000000000000000000000);
          MintRegister(0x6649Ce8C09E2D6bDEF1F727DA0195496766a01cD,10000000000000000000000);
  	    _mint(0x0518cd230ed4426A0466B6966956DA01ddC87EF2,10000000000000000000000);
  	         MintRegister(0x0518cd230ed4426A0466B6966956DA01ddC87EF2,10000000000000000000000);
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