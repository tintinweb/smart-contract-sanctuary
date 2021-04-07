/**
 *Submitted for verification at Etherscan.io on 2021-04-07
*/

contract MyHashContract {
//// The following contract contains a Hash in its source code, which is a hash of a document calculated with a hashing prograam http://www.slavasoft.com/hashcalc/HashCalc 2.02
//// Also, one can send funds from it to a requesting account (this is secondary)

/////////////////////////////////////////////////////////////////
// This is the hash of a document (Lorem Ipsum):
// a3614fe562b348399b7e0a97c5720f71857caa90906434b2a7ad4d2e4ea5c27d
////////////////////////////////////////////////////////////////

     // Give out ether to anyone who asks
     function withdraw(uint withdraw_amount) public {
 
         // Limit withdrawal amount
         require(withdraw_amount <= 100000000000000000);
 
         // Send the amount to the address that requested it
         msg.sender.transfer(withdraw_amount);
     }
 
     // Accept any incoming amount
        function () public payable {}



}