/**
 *Submitted for verification at Etherscan.io on 2021-12-02
*/

pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;

// SigRelayer for https://uni.vote
contract SigRelayer {
	bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");
	bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");
	bytes32 public constant BALLOT_TYPEHASH = keccak256("Ballot(uint256 proposalId,uint8 support)");
	uint256 public constant CHAIN_ID = 1; /// Change to appropriate chain before deployment
	
	address public immutable owner;
	address public immutable tokenAddress;
	address public governorAddress;
	

	constructor(address governorAddress_, address tokenAddress_) public {
		governorAddress = governorAddress_;
		tokenAddress = tokenAddress_;

		owner = msg.sender;
	}

	function setGovernor(address governorAddress_) public  {
		require(msg.sender == owner);

		governorAddress = governorAddress_;	
	}

	function relayBySigs(DelegationSig[] memory s1, VoteSig[] memory s2) public {
		for (uint i = 0; i < s1.length; i++) {
			DelegationSig memory sig = s1[i];
			tokenAddress.call(abi.encodeWithSignature("delegateBySig(address,uint256,uint256,uint8,bytes32,bytes32)", sig.delegatee, sig.nonce, sig.expiry, sig.v, sig.r, sig.s));
		}
		for (uint i = 0; i < s2.length; i++) {
			VoteSig memory sig = s2[i];
			governorAddress.call(abi.encodeWithSignature("castVoteBySig(uint256,uint8,uint8,bytes32,bytes32)", sig.proposalId,sig.support,sig.v,sig.r,sig.s));
		}
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
  		uint8 support;
  		uint8 v;
  		bytes32 r;
  		bytes32 s;
  	}
}