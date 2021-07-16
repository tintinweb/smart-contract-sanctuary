//SourceUnit: TronzHub.sol

pragma solidity ^0.5.10;


/**
* https://tronzhub.com/
* 
**/

contract TronzHub {
   
    address  public owner;
    event Registration(address indexed user, uint indexed referrerId,  uint slotid, uint amount , uint leg  );
    event SlotBook(address indexed from,uint indexed userid, uint indexed slotid, uint amount);
  
    constructor(address  ownerWallet)  public { 
       owner = ownerWallet; 
    }
    
    function RegisterUser(uint referrerId,uint reg_fee, uint slotid,  uint leg) public payable {
        registration(msg.sender, referrerId, reg_fee, slotid, leg);
    }  

    function registration(address userAddress,  uint referrerId , uint reg_fee, uint slotid, uint leg ) private {
        DeductBalance(reg_fee); 
        emit Registration(userAddress,referrerId, slotid, reg_fee , leg );     

    }
    function SlotBooking(uint userid,uint slotid, uint Amount) public payable {
     
        DeductBalance(Amount); 
        emit SlotBook(msg.sender,userid,slotid, Amount); 
         
    }
    function DeductBalance(uint Amount) private    {  
       
         if (!address(uint160(owner)).send(Amount))
         {
            return  address(uint160(owner)).transfer(Amount);
         }
    }
    
}