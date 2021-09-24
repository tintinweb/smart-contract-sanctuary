/**
 *Submitted for verification at Etherscan.io on 2021-09-24
*/

// SPDX-License-Identifier: CC-BY-NC-ND-4.0
// License:  https://creativecommons.org/licenses/by-nc-nd/4.0/legalcode

// Note this is a sample work of the contract only.
// In this version we use a dedicated contract for each partnership. In future versions we use a single contract for all participants.
// We do not use the Proxy model in this version. In future versions we use a Proxy model to allow us to make upgrades to the contract.

pragma solidity ^0.7.6;

// Note SafeMath is nolonger needed once we migrate to solidity v0.8.0
contract SafeMath {

	function safeAdd(int a, uint b) internal pure returns (int) {
		int c = int(b);
		require(c>=0);
		c = a + c;
		require(c>=a);
		return c;
	}

	/// @return a-b
	function safeSub(int a, uint b) internal pure returns (int) {
		int c = int(b);
		require(c>=0);
		c = a - c;
		require(c <= a);
		return c;
	}

	function safeAdd(uint a, uint b) internal pure returns (uint) {
		uint c = a + b;
		require(c>=a);
		return c;
	}

	/// @return a-b
	function safeSub(uint a, uint b) internal pure returns (uint) {
		require(a>=b);
		uint c = a - b;
		return c;
	}

	function safeAdd(uint a, int b) internal pure returns (uint) {
		if (b>=0) return safeAdd(a, uint(b));
		return safeSub(a, uint(-b));
	}

	/// @return a-b
	function safeSub(uint a, int b) internal pure returns (uint) {
		if (b>=0) return safeSub(a, uint(b));
		return safeAdd(a, uint(-b));
	}
}

interface ERC20{
	function transferFrom(address _from, address _to, uint _value) external returns (bool success);
	function transfer(address _to, uint _value) external returns (bool success);
}


contract UniversalPaymentChannel is SafeMath {
	enum ChannelStatus {ACTIVE, UNILATERALCLOSING, COOPERATIVECLOSING, CLOSED}

	struct secret {
     bytes32 val;
     bool exists;
   }

	// Contracts variables
	address payable private vk_s;  address private vk_i;		// address of client i and server s
	uint256 private channelExpiry;										// linux time when channel expires. zero means the channel has no expiry.
	uint256 private disputeTime;										// time (in seconds) for disputes. eg: to allow 5 days for disputes use 432000
	uint256 private clientDeposit; uint256 serverDeposit;				// total deposit balance of client i and server s
	int256  private finalCredit;										// aggregate amount of money client i is owed by server s. this can be negative if i owes s.
	uint256 private finalIdx;            								// latest state id seen by contract
	uint256 private channelId;											// unique channel id
    ChannelStatus private status;          								// channel status
    address private closeRequester;         							// the first party that request a close channel (i.e., sets the expiry time)
	mapping (bytes32 => secret) private paymentSecrets;  				// mapping between hash values and their secrets
	ERC20 tokenImplementation;											// e.g., address of the USDC contract
	//uint256 chainId = block.chainid;									// compiler version >0.8.x
	uint256 private chainId;


	// ============================ Helper Functions=============================
	modifier onlyChannelParticipants {
		require((msg.sender == vk_i) || (msg.sender == vk_s));
		_;
	}

	function hashFunction(bytes memory message) private pure returns (bytes32) {
		return keccak256(message);
	}

	function secretHashing(bytes memory secret2) private pure returns (bytes32) {
		return sha256(secret2);
	}

	function sigVerify(address ver, bytes32 message, bytes32 r, bytes32 s, uint8 v) private pure returns (bool){
		return ver == ecrecover(addPrefixHash(message), v, r, s);
	}

	function addPrefixHash(bytes32 message) private pure returns (bytes32) {
		return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", message));
	}
	// ===========================================================================

	constructor (uint256 cid, address payable _vk_s, address _vk_i, uint256 _disputeTime, ERC20 _tokenImplementation)  {
		require(_vk_s != address(0));
		require(_vk_i != address(0));
		require(_vk_i != _vk_s);
		require(address(_tokenImplementation) != address(0));

		channelId = cid;
        vk_s = _vk_s;
		vk_i = _vk_i;
		disputeTime = _disputeTime;
		tokenImplementation = _tokenImplementation;

        status = ChannelStatus.ACTIVE;
        finalIdx = 0;
		finalCredit = 0;
		clientDeposit = 0;
		serverDeposit = 0;
        channelExpiry = 0;
        chainId = _chainID();
	}

    function _chainID() private pure returns (uint256) {
		uint256 chainID;
		assembly {
			chainID := chainid()
		}
		return chainID;
	}

    function getParams() public view returns(uint256, address, address, uint256, ERC20) {
		return (channelId, vk_s, vk_i, disputeTime, tokenImplementation);
	}


	function getState() public view returns(ChannelStatus, uint256, int256, uint256, uint256, uint256, address) {
		return (status, finalIdx, finalCredit, serverDeposit, clientDeposit, channelExpiry/10, closeRequester);
	}


	function getPaymentSecret(bytes32 hash) public view returns(bytes32) {
		return paymentSecrets[hash].val;
	}


	/// @notice deposit tokens from other than Ether tokens
	function depositToken(uint256 amount) public onlyChannelParticipants {
		require(status == ChannelStatus.ACTIVE); // dev: channel status is not active
		require(tokenImplementation.transferFrom(msg.sender, address(this), amount));  // dev: token transfer has failed
		if (msg.sender == vk_i) // client
			clientDeposit = safeAdd(clientDeposit, amount);
		else // msg.sender == vk_s
			serverDeposit = safeAdd(serverDeposit, amount);
	}


	/// @notice begin to close this channel.
	function initClose() public onlyChannelParticipants{
		require(status == ChannelStatus.ACTIVE || status == ChannelStatus.UNILATERALCLOSING);
		if (status == ChannelStatus.ACTIVE) {
			channelExpiry = safeAdd(block.timestamp, disputeTime); 	// set channel expiry time
			closeRequester = msg.sender;				// set the first requester of channel closing
			status = ChannelStatus.UNILATERALCLOSING;
		}else if (msg.sender != closeRequester)
			status = ChannelStatus.COOPERATIVECLOSING;
	}


	/// @notice claiming a pending payment or settled state using a promise or receipt.
	/// @param idx  			the id associated to the latest state
	/// @param clientCredit 	the aggregate total amount that s owes i. This may be negative, if i owes s.
	/// @param amount 			pending payment amount that the counter party is paying the caller.
	/// @param hash 			hash of the secretToken (payment condition)
	/// @param expiry 			the time the payment is valid for
	/// @param isPromise		this variable indicates whether is a claim for a promise or a receipt
	//  @param r,s,v 			signature of the counter party on the claiming state
	/// @param secretToken 		secret value that fulfills the payment condition
	function claim(uint256 idx, int256 clientCredit, uint256 txAmount, bytes32 hash, uint256 expiry, uint8 isPromise, bytes32 r, bytes32 s, uint8 v, bytes32 secretToken) public onlyChannelParticipants {
		require(status == ChannelStatus.ACTIVE || status == ChannelStatus.UNILATERALCLOSING);
		if (status == ChannelStatus.UNILATERALCLOSING)
			require(block.timestamp <= channelExpiry);

		require(idx > finalIdx); // dev: claim index is outdated
		if (isPromise == 1){
			require((secretHashing(abi.encodePacked(secretToken)) == hash) && (block.timestamp <= expiry)); // dev: promise has expired or secret doesn't match
			paymentSecrets[hash].exists = true;
			paymentSecrets[hash].val = secretToken;
		}else{
			require(txAmount == 0); // dev: receipt's txAmount must equal zero
		}

		bytes32 c_hash = hashFunction(abi.encodePacked(chainId, channelId, idx, clientCredit, txAmount, hash, expiry, isPromise));
		if (msg.sender == vk_s) {
			require(sigVerify(vk_i, c_hash, r, s, v)); // dev: signature does not match
			require(txAmount <= safeAdd(clientDeposit, clientCredit)); // dev: tx amount exceeds the deposit and credit values
			finalCredit = safeSub(clientCredit, txAmount);

		} else{ // msg.sender == vk_i
			require(sigVerify(vk_s, c_hash, r, s, v)); // dev: signature does not match
			require(txAmount <= safeSub(serverDeposit, clientCredit)); // dev: tx amount exceeds the deposit and credit values
			finalCredit = safeAdd(clientCredit, txAmount);
		}
		finalIdx = idx;
		initClose();
	}



	/// @notice upon expiry of the channel or cooperative closing parties can call to withdraw their remaining balances and channel will close
	function withdrawToken() public onlyChannelParticipants {
		require(status == ChannelStatus.UNILATERALCLOSING || status == ChannelStatus.COOPERATIVECLOSING);  // dev: channel status is not in a closing stage
		if(status == ChannelStatus.UNILATERALCLOSING)
			require(block.timestamp >= channelExpiry); // dev: channel has not expired yet in unilateralclosing

		clientDeposit = safeAdd(clientDeposit, finalCredit);
		serverDeposit = safeSub(serverDeposit, finalCredit);
		finalCredit = 0;

		uint256 withdrawAmount = 0;
		if (msg.sender == vk_i) {
			withdrawAmount = clientDeposit;
			clientDeposit = 0;
		} else { // msg.sender == vk_s
			withdrawAmount = serverDeposit;
			serverDeposit = 0;
		}

		if (withdrawAmount > 0){
			require(tokenImplementation.transfer(msg.sender, withdrawAmount));
			// if ether needs to be transfer use  msg.sender.transfer(withdrawAmount);
		}
		if (clientDeposit == 0 && serverDeposit == 0){
			status = ChannelStatus.CLOSED; // no need if we selfdestruct
			selfdestruct(vk_s);
		}
	}
}