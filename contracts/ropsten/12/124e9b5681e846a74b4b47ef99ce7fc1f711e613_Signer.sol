/**
 *Submitted for verification at Etherscan.io on 2021-02-20
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;
pragma abicoder v2;

contract Signer {

     mapping(string => Document) private _documents;
     
     struct Document {
         address owner;
         uint256 timestamp;
         bytes metadata;
     }
    
    function sendDocument(string memory documentHash, uint256 timestamp, bytes memory metadata) public {
        _documents[documentHash].owner = msg.sender;
        _documents[documentHash].timestamp = timestamp;
        _documents[documentHash].metadata = metadata;
    }
    
    function getDocument(string memory documentHash) public view returns(uint256 timestamp, bytes memory metadata) {
        timestamp = _documents[documentHash].timestamp;
        metadata = _documents[documentHash].metadata;
    }
}