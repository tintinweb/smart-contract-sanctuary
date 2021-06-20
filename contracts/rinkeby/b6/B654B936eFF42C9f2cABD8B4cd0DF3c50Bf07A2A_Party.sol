/**
 *Submitted for verification at Etherscan.io on 2021-06-20
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
pragma abicoder v2;

contract Party{
    
    address public owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    struct partyData {
        int256 id;
        address owner;
        string name;
    }
    
    struct Signing{
        uint8 v;
        bytes32 r;
        bytes32 s;
    }
    
    event CreatePartyEvent(address owner, int256 partyId, string partyName);
    
    mapping(address => partyData) public parties;

    /**
    party example: [1, "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2", "party example"]
    signature example: [27, "0x82370090796841e11ac86960eafc8582c2d8cc93eb80c1f08ca51741e2eadc25", "0x2b80ce945cfcd0e990c1c04243addcf74c8fa11d48fead2ece91d04c350f1646"]
     */
    function createParty(partyData memory party, Signing memory Signatures) public {

        // validate signatures
        require( party.owner == recover(party, Signatures), "Party owner is not signing message");
        
        // validate existing data
        partyData storage partyByOwner = parties[party.owner];
        require( party.owner != partyByOwner.owner, "The owner is already create party");
        
        // write parties
        parties[party.owner].id = party.id;
        parties[party.owner].owner = party.owner;
        parties[party.owner].name = party.name;
        
        // write event
        emit CreatePartyEvent(party.owner, party.id, party.name);
    }
    
    function getEthSignedMessageHash(bytes32 _messageHash) private pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }
    
    function recover(partyData memory party, Signing memory Signatures) private pure returns (address){
        
        bytes32 messageHash = getMessageHash(party);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        
        return ecrecover(ethSignedMessageHash, Signatures.v, Signatures.r, Signatures.s );
    }
    
    function getMessageHash(partyData memory party
    )
        public pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(party.id, party.owner, party.name));
    }
}