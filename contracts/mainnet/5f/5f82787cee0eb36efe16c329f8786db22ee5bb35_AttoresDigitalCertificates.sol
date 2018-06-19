pragma solidity ^0.4.19;
// Digital Signature Contract
// This contract has been created by Gaurang Torvekar, the co-founder and CTO of Attores, a Singaporean company which is creating a SaaS platform for Smart Contracts

contract AttoresDigitalCertificates{
   uint public amountInContract;
    
    mapping (address => bool) public ownerList;
    
    struct SignatureDetails{
        bytes32 email;
        uint timeStamp;
    }
    
    mapping (bytes32 => SignatureDetails) public hashList;
    
    uint public constant WEI_PER_ETHER = 1000000000000000000;
    
    function AttoresDigitalCertificates (address _owner){
       ownerList[_owner] = true;
       amountInContract += msg.value;
   }
   
   modifier ifOwner() {
       require(ownerList[msg.sender]);
       _;
   }
   
   function addOwner(address someone) ifOwner {
       ownerList[someone] = true;
   }
   
   function removeOwner(address someone) ifOwner {
       ownerList[someone] = false;
   }
   
   function certificate(bytes32 email, bytes32 hash) ifOwner{
       hashList[hash] = SignatureDetails({
           email: email,
           timeStamp: now
       });
   }

}