/**
 *Submitted for verification at Etherscan.io on 2021-04-08
*/

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.6.0;

/** 
 * @title - EIP712 Testing Contract  
 **/

contract EIP712Test { 
    
    event LogClaimHash(bytes32 claim_hash);
    
    struct EIP712Domain {
        string  name;
        string  version;
        uint256 chainId;
        address verifyingContract;
    }
 
    // user_id as nonce  
    struct Claim {
        uint32 user_id;
        address user_address;
        uint256 user_amount;
    }

    // create type hash that will be rolled up into the final signed message
    bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

    // typehash for our proof  
    bytes32 constant GTC_TOKEN_CLAIM_TYPEHASH = keccak256(
        "Claim(uint32 user_id,address user_address,uint256 user_amount)"
    );
        
    // hash of the domain separator data
    bytes32 DOMAIN_SEPARATOR;
    
    // for simplicity we define our domain seperator on contract deployment 
    constructor() public {
        
        DOMAIN_SEPARATOR = hash(EIP712Domain({
            name: "ZKZ",
            version: '1.0.0',
            chainId: 1,
            verifyingContract: address(this)
        }));
    }
    
    // taken from standard - https://github.com/ethereum/EIPs/blob/master/assets/eip-712/Example.sol
    function hash(EIP712Domain memory eip712Domain) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            EIP712DOMAIN_TYPEHASH,
            keccak256(bytes(eip712Domain.name)),
            keccak256(bytes(eip712Domain.version)),
            eip712Domain.chainId,
            eip712Domain.verifyingContract
        ));
    }
    
    // the function will hash our claim struct - NOTICE abi.encode  
    function hash(Claim memory claim) internal pure returns (bytes32) {
        return keccak256(abi.encode( 
            GTC_TOKEN_CLAIM_TYPEHASH,
            claim.user_id,
            claim.user_address,
            claim.user_amount
        ));
    }
    
    // quick route to see your DOMAIN_SEPERATOR hash 
    function getDOMAINSEPARATOR() public view returns (bytes32) {
        return DOMAIN_SEPARATOR;    
    }

    // quick route to see your GTC_TOKEN_CLAIM_TYPEHASH
    function getClaimTYPEHASH() public pure returns (bytes32) {
        return GTC_TOKEN_CLAIM_TYPEHASH;    
    }
    
    // This function proves that we can generate the same digest in Python & Solidity 
    function getDigest(Claim memory claim) internal view returns (bytes32) {
        // Note: we need to use `encodePacked` here instead of `encode`.
        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            hash(claim)
        ));
        return digest;
    }
    
    // quick way to test a claim 
    function testClaim() public returns (bytes32) {
        // Example signed message
        Claim memory claim = Claim({
            user_id: 42,
            user_address: msg.sender, 
            user_amount: 1000000000000000
        });
        
        // not encodePacked method 
        emit LogClaimHash(hash(claim));
        return getDigest(claim);
     }

}