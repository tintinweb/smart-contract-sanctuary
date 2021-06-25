/**
 *Submitted for verification at Etherscan.io on 2021-06-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;
pragma experimental ABIEncoderV2;

contract SigRelayer {
	bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");
	bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");
	bytes32 public constant BALLOT_TYPEHASH = keccak256("Ballot(uint256 proposalId,bool support)");
	string public constant tokenName = "Uniswap";
	string public constant governanceName = "Uniswap Governor Alpha";
	address public governorAlpha = 0xC4e172459f1E7939D522503B81AFAaC1014CE6F6;
	address public constant tokenAddress = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
	address public owner;

	constructor() public {
		owner = msg.sender;
	}

	function setGovernorAlpha(address newGovernorAlpha) public  {
		require(msg.sender == owner);
		governorAlpha = newGovernorAlpha;
	}

	function relayBySigs(DelegationSig[] memory s1, VoteSig[] memory s2) public {
		for (uint i = 0; i < s1.length; i++) {
			DelegationSig memory sig = s1[i];
			tokenAddress.call(abi.encodeWithSignature("delegateBySig(address,uint256,uint256,uint8,bytes32,bytes32)", sig.delegatee, sig.nonce, sig.expiry, sig.v, sig.r, sig.s));
		}
		for (uint i = 0; i < s2.length; i++) {
			VoteSig memory sig = s2[i];
			governorAlpha.call(abi.encodeWithSignature("castVoteBySig(uint256,bool,uint8,bytes32,bytes32)", sig.proposalId,sig.support,sig.v,sig.r,sig.s));
		}
	}

	function signatoryFromDelegateSig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) public view returns (address) {
	    bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(tokenName)), getChainId(), tokenAddress));
	    bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
	    bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
	    address signatory = ecrecover(digest, v, r, s);
	    require(signatory != address(0), "invalid signature");
	    require(block.timestamp <= expiry, "signature expired");
	    return signatory;
	}

	function signatoryFromVoteSig(uint proposalId, bool support, uint8 v, bytes32 r, bytes32 s) public view returns (address) {
	    bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(governanceName)), getChainId(), governorAlpha));
	    bytes32 structHash = keccak256(abi.encode(BALLOT_TYPEHASH, proposalId, support));
	    bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
	    address signatory = ecrecover(digest, v, r, s);
	    require(signatory != address(0), "invalid signature");
	    return signatory;
	}


  	struct DelegationSig {
	    address delegatee;
	    uint nonce;
	    uint expiry;
	    uint8 v;
	    bytes32 r;
	    bytes32 s;
  	}

  	struct VoteSig {
  		uint proposalId;
  		bool support;
  		uint8 v;
  		bytes32 r;
  		bytes32 s;
  	}

  	function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}