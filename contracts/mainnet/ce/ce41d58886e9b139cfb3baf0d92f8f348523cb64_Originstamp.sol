//SPDX-License-Identifier: MIT;
pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;

contract Originstamp {
    
    address public owner;

   
    event onSubmissionDocHash(bytes32 indexed docHash);
    event onSubmissionISCCHash(string indexed ISCCHash);
   
    modifier onlyOwner() {
        require(msg.sender == owner,"Sender not authorized");
        _;
    }

    constructor () public {
    	owner = msg.sender;
    }
    
    function submitBothHash(bytes32[] calldata docHash, string[] calldata ISCCHash) external onlyOwner() {
       for(uint8 i =0;i<docHash.length;i++){
           emit onSubmissionDocHash(docHash[i]);
       }
       for(uint8 i =0;i<ISCCHash.length;i++){
           emit onSubmissionISCCHash(ISCCHash[i]);
       }
    }

    function submitDocHash(bytes32[] calldata docHash) external onlyOwner() {
        
        for(uint8 i =0;i<docHash.length;i++){
           emit onSubmissionDocHash(docHash[i]);
       }
    }
    
    
    function submitISCCHash(string[] calldata ISCCHash) external onlyOwner() {
         for(uint8 i =0;i<ISCCHash.length;i++){
           emit onSubmissionISCCHash(ISCCHash[i]);
       }
    }
    
  
}