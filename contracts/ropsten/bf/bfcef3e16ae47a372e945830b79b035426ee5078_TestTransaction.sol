/**
 *Submitted for verification at Etherscan.io on 2021-06-09
*/

pragma solidity ^0.4.6;

contract TestTransaction{
     function deposit() payable {
        address acc = 0xC38Cf81518591ad7a1331D239fAb9922347aC67f;
        acc.transfer(msg.value);//向acc地址转账msg.value个以太坊
     }

    function getBalance() constant returns(uint){
        address acc = 0xC38Cf81518591ad7a1331D239fAb9922347aC67f;
        return acc.balance;
    }
    
    function getOwnerBalance() constant returns(uint){
         address owner = msg.sender;
        return owner.balance;
     }
}