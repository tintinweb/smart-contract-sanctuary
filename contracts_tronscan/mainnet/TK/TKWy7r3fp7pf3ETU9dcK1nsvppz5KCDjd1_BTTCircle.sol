//SourceUnit: BTT11Circle.sol

/*  
# https://btt11circle.com

*/

pragma solidity ^0.5.10;
contract BTTCircle{
    trcToken trcid=1002000;   
    address  public owner;
    event Registration(address indexed user, uint indexed referrerId,  uint slotid, uint amount  );
    event SlotBook(address indexed from,uint indexed userid, uint indexed slotid, uint amount);  
    constructor(address  ownerWallet)  public { 
       owner = ownerWallet; 
    }   
    function RegisterUser(uint referrerId,uint reg_fee, uint slotid ) public payable {
        registration(msg.sender, referrerId, reg_fee, slotid);
    }  
    function registration(address userAddress,  uint referrerId , uint reg_fee, uint slotid ) private {
        DeductBalance(reg_fee); 
        emit Registration(userAddress,referrerId, slotid, reg_fee );  
    }
    function SlotBooking(uint userid,uint slotid, uint Amount) public payable {     
        DeductBalance(Amount); 
        emit SlotBook(msg.sender,userid,slotid, Amount);          
    }
    function DeductBalance(uint Amount) private    {   
         return address(uint160(owner)).transferToken(Amount,trcid);
    }
}