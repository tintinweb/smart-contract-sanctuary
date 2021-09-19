/**
 *Submitted for verification at BscScan.com on 2021-09-19
*/

pragma solidity 0.4.25;

contract WriteForEver {
    
    struct ArchiveForever {
        string MessageFromBlockChain_;
    }
    
  address ContractOwner;
  
  constructor() public {
      ContractOwner = msg.sender;
     
  }
    
    modifier DevelopperChief() {
        if(msg.sender == ContractOwner) {
            _;
        }
    }
    
   ArchiveForever[] public ReadBlockChain;
   function InsertDate( string MessageFromBlockChain_ ) public DevelopperChief {
    
          ReadBlockChain.push(ArchiveForever(MessageFromBlockChain_));
   }
}