/**
 *Submitted for verification at BscScan.com on 2021-11-14
*/

pragma solidity 0.8.7;

// @TODO: Formatting
library LibBytes {
  // @TODO: see if we can just set .length = 
  function trimToSize(bytes memory b, uint newLen)
    internal
    pure
  {
    require(b.length > newLen, "BytesLib: only shrinking");
    assembly {
      mstore(b, newLen)
    }
  }


  /***********************************|
  |        Read Bytes Functions       |
  |__________________________________*/

  /**
   * @dev Reads a bytes32 value from a position in a byte array.
   * @param b Byte array containing a bytes32 value.
   * @param index Index in byte array of bytes32 value.
   * @return result bytes32 value from byte array.
   */
  function readBytes32(
    bytes memory b,
    uint256 index
  )
    internal
    pure
    returns (bytes32 result)
  {
    // Arrays are prefixed by a 256 bit length parameter
    index += 32;

    require(b.length >= index, "BytesLib: length");

    // Read the bytes32 from array memory
    assembly {
      result := mload(add(b, index))
    }
    return result;
  }
}



interface IERC1271Wallet {
	function isValidSignature(bytes32 hash, bytes calldata signature) external view returns (bytes4 magicValue);
}

library SignatureValidator {
	using LibBytes for bytes;

	enum SignatureMode {
		EIP712,
		EthSign,
		SmartWallet,
		Spoof
	}

	// bytes4(keccak256("isValidSignature(bytes32,bytes)"))
	bytes4 constant internal ERC1271_MAGICVALUE_BYTES32 = 0x1626ba7e;

	function recoverAddr(bytes32 hash, bytes memory sig) internal view returns (address) {
		return recoverAddrImpl(hash, sig, false);
	}

	function recoverAddrImpl(bytes32 hash, bytes memory sig, bool allowSpoofing) internal view returns (address) {
		require(sig.length >= 1, "SV_SIGLEN");
		uint8 modeRaw;
		unchecked { modeRaw = uint8(sig[sig.length - 1]); }
		SignatureMode mode = SignatureMode(modeRaw);

		// {r}{s}{v}{mode}
		if (mode == SignatureMode.EIP712 || mode == SignatureMode.EthSign) {
			require(sig.length == 66, "SV_LEN");
			bytes32 r = sig.readBytes32(0);
			bytes32 s = sig.readBytes32(32);
			uint8 v = uint8(sig[64]);
			// Hesitant about this check: seems like this is something that has no business being checked on-chain
			require(v == 27 || v == 28, "SV_INVALID_V");
			if (mode == SignatureMode.EthSign) hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
			address signer = ecrecover(hash, v, r, s);
			require(signer != address(0), "SV_ZERO_SIG");
			return signer;
		// {sig}{verifier}{mode}
		} else if (mode == SignatureMode.SmartWallet) {
			// 32 bytes for the addr, 1 byte for the type = 33
			require(sig.length > 33, "SV_LEN_WALLET");
			uint newLen;
			unchecked {
				newLen = sig.length - 33;
			}
			IERC1271Wallet wallet = IERC1271Wallet(address(uint160(uint256(sig.readBytes32(newLen)))));
			sig.trimToSize(newLen);
			require(ERC1271_MAGICVALUE_BYTES32 == wallet.isValidSignature(hash, sig), "SV_WALLET_INVALID");
			return address(wallet);
		// {address}{mode}; the spoof mode is used when simulating calls
		} else if (mode == SignatureMode.Spoof && allowSpoofing) {
			require(tx.origin == address(1), "SV_SPOOF_ORIGIN");
			require(sig.length == 33, "SV_SPOOF_LEN");
			sig.trimToSize(32);
			return abi.decode(sig, (address));
		} else revert("SV_SIGMODE");
	}
}


contract Identity {
	mapping (address => bytes32) public privileges;
	// The next allowed nonce
	uint public nonce;

	// Events
	event LogPrivilegeChanged(address indexed addr, bytes32 priv);
	event LogErr(address indexed to, uint value, bytes data, bytes returnData); // only used in tryCatch

	// Transaction structure
	// we handle replay protection separately by requiring (address(this), chainID, nonce) as part of the sig
	struct Transaction {
		address to;
		uint value;
		bytes data;
	}

	constructor(address[] memory addrs) {
		uint len = addrs.length;
		for (uint i=0; i<len; i++) {
			// @TODO should we allow setting to any arb value here?
			privileges[addrs[i]] = bytes32(uint(1));
			emit LogPrivilegeChanged(addrs[i], bytes32(uint(1)));
		}
	}

	// This contract can accept ETH without calldata
	receive() external payable {}

	// This contract can accept ETH with calldata
	// However, to support EIP 721 and EIP 1155, we need to respond to those methods with their own method signature
	fallback() external payable {
		bytes4 method = msg.sig;
		if (
			method == 0x150b7a02 // bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))
				|| method == 0xf23a6e61 // bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))
				|| method == 0xbc197c81 // bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))
		) {
			// Copy back the method
			// solhint-disable-next-line no-inline-assembly
			assembly {
				calldatacopy(0, 0, 0x04)
				return (0, 0x20)
			}
		}
	}

	function setAddrPrivilege(address addr, bytes32 priv)
		external
	{
		require(msg.sender == address(this), 'ONLY_IDENTITY_CAN_CALL');
		// Anti-bricking measure: if the privileges slot is used for special data (not 0x01),
		// don't allow to set it to true
		if (uint(privileges[addr]) > 1) require(priv != bytes32(uint(1)), 'UNSETTING_SPECIAL_DATA');
		privileges[addr] = priv;
		emit LogPrivilegeChanged(addr, priv);
	}

	function tipMiner(uint amount)
		external
	{
		require(msg.sender == address(this), 'ONLY_IDENTITY_CAN_CALL');
		// See https://docs.flashbots.net/flashbots-auction/searchers/advanced/coinbase-payment/#managing-payments-to-coinbaseaddress-when-it-is-a-contract
		// generally this contract is reentrancy proof cause of the nonce
		executeCall(block.coinbase, amount, new bytes(0));
	}

	function tryCatch(address to, uint value, bytes calldata data)
		external
	{
		require(msg.sender == address(this), 'ONLY_IDENTITY_CAN_CALL');
		(bool success, bytes memory returnData) = to.call{value: value, gas: gasleft()}(data);
		if (!success) emit LogErr(to, value, data, returnData);
	}


	// WARNING: if the signature of this is changed, we have to change IdentityFactory
	function execute(Transaction[] calldata txns, bytes calldata signature)
		external
	{
		require(txns.length > 0, 'MUST_PASS_TX');
		uint currentNonce = nonce;
		// NOTE: abi.encode is safer than abi.encodePacked in terms of collision safety
		bytes32 hash = keccak256(abi.encode(address(this), block.chainid, currentNonce, txns));
		// We have to increment before execution cause it protects from reentrancies
		nonce = currentNonce + 1;

		address signer = SignatureValidator.recoverAddrImpl(hash, signature, true);
		require(privileges[signer] != bytes32(0), 'INSUFFICIENT_PRIVILEGE');
		uint len = txns.length;
		for (uint i=0; i<len; i++) {
			Transaction memory txn = txns[i];
			executeCall(txn.to, txn.value, txn.data);
		}
		// The actual anti-bricking mechanism - do not allow a signer to drop their own priviledges
		require(privileges[signer] != bytes32(0), 'PRIVILEGE_NOT_DOWNGRADED');
	}

	// no need for nonce management here cause we're not dealing with sigs
	function executeBySender(Transaction[] calldata txns) external {
		require(txns.length > 0, 'MUST_PASS_TX');
		require(privileges[msg.sender] != bytes32(0), 'INSUFFICIENT_PRIVILEGE');
		uint len = txns.length;
		for (uint i=0; i<len; i++) {
			Transaction memory txn = txns[i];
			executeCall(txn.to, txn.value, txn.data);
		}
		// again, anti-bricking
		require(privileges[msg.sender] != bytes32(0), 'PRIVILEGE_NOT_DOWNGRADED');
	}

	function executeBySelf(Transaction[] calldata txns) external {
		require(msg.sender == address(this), 'ONLY_IDENTITY_CAN_CALL');
		require(txns.length > 0, 'MUST_PASS_TX');
		uint len = txns.length;
		for (uint i=0; i<len; i++) {
			Transaction memory txn = txns[i];
			executeCall(txn.to, txn.value, txn.data);
		}
	}

	// we shouldn't use address.call(), cause: https://github.com/ethereum/solidity/issues/2884
	// copied from https://github.com/uport-project/uport-identity/blob/develop/contracts/Proxy.sol
	// there's also
	// https://github.com/gnosis/MultiSigWallet/commit/e1b25e8632ca28e9e9e09c81bd20bf33fdb405ce
	// https://github.com/austintgriffith/bouncer-proxy/blob/master/BouncerProxy/BouncerProxy.sol
	// https://github.com/gnosis/safe-contracts/blob/7e2eeb3328bb2ae85c36bc11ea6afc14baeb663c/contracts/base/Executor.sol
	function executeCall(address to, uint256 value, bytes memory data)
		internal
	{
		assembly {
			let result := call(gas(), to, value, add(data, 0x20), mload(data), 0, 0)

			switch result case 0 {
				let size := returndatasize()
				let ptr := mload(0x40)
				returndatacopy(ptr, 0, size)
				revert(ptr, size)
			}
			default {}
		}
		// A single call consumes around 477 more gas with the pure solidity version, for whatever reason
		// WARNING: do not use this, it corrupts the returnData string (returns it in a slightly different format)
		//(bool success, bytes memory returnData) = to.call{value: value, gas: gasleft()}(data);
		//if (!success) revert(string(data));
	}

	// EIP 1271 implementation
	// see https://eips.ethereum.org/EIPS/eip-1271
	function isValidSignature(bytes32 hash, bytes calldata signature) external view returns (bytes4) {
		if (privileges[SignatureValidator.recoverAddr(hash, signature)] != bytes32(0)) {
			// bytes4(keccak256("isValidSignature(bytes32,bytes)")
			return 0x1626ba7e;
		} else {
			return 0xffffffff;
		}
	}

	// EIP 1155 implementation
	// we pretty much only need to signal that we support the interface for 165, but for 1155 we also need the fallback function
	function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
		return
			interfaceID == 0x01ffc9a7 ||    // ERC-165 support (i.e. `bytes4(keccak256('supportsInterface(bytes4)'))`).
			interfaceID == 0x4e2312e0;      // ERC-1155 `ERC1155TokenReceiver` support (i.e. `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")) ^ bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`).
	}
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract QuickAccManager {
	// Note: nonces are scoped by identity rather than by accHash - the reason for this is that there's no reason to scope them by accHash,
	// we merely need them for replay protection
	mapping (address => uint) public nonces;
	mapping (bytes32 => uint) public scheduled;

	bytes4 constant CANCEL_PREFIX = 0xc47c3100;

	// Events
	// we only need those for timelocked stuff so we can show scheduled txns to the user; the oens that get executed immediately do not need logs
	event LogScheduled(bytes32 indexed txnHash, bytes32 indexed accHash, address indexed signer, uint nonce, uint time, Identity.Transaction[] txns);
	event LogCancelled(bytes32 indexed txnHash, bytes32 indexed accHash, address indexed signer, uint time);
	event LogExecScheduled(bytes32 indexed txnHash, bytes32 indexed accHash, uint time);

	// EIP 2612
	/// @notice Chain Id at this contract's deployment.
	uint256 internal immutable DOMAIN_SEPARATOR_CHAIN_ID;
	/// @notice EIP-712 typehash for this contract's domain at deployment.
	bytes32 internal immutable _DOMAIN_SEPARATOR;

	constructor() {
		DOMAIN_SEPARATOR_CHAIN_ID = block.chainid;
		_DOMAIN_SEPARATOR = calculateDomainSeparator();
	}

	struct QuickAccount {
		uint timelock;
		address one;
		address two;
		// We decided to not allow certain options here such as ability to skip the second sig for send(), but leaving this a struct rather than a tuple
		// for clarity and to ensure it's future proof
	}
	struct DualSig {
		bool isBothSigned;
		bytes one;
		bytes two;
	}

	// NOTE: a single accHash can control multiple identities, as long as those identities set it's hash in privileges[address(this)]
	// this is by design

	// isBothSigned is hashed in so that we don't allow signatures from two-sig txns to be reused for single sig txns,
	// ...potentially frontrunning a normal two-sig transaction and making it wait
	// WARNING: if the signature of this is changed, we have to change IdentityFactory
	function send(Identity identity, QuickAccount calldata acc, DualSig calldata sigs, Identity.Transaction[] calldata txns) external {
		bytes32 accHash = keccak256(abi.encode(acc));
		require(identity.privileges(address(this)) == accHash, 'WRONG_ACC_OR_NO_PRIV');
		uint initialNonce = nonces[address(identity)]++;
		// Security: we must also hash in the hash of the QuickAccount, otherwise the sig of one key can be reused across multiple accs
		bytes32 hash = keccak256(abi.encode(
			address(this),
			block.chainid,
			address(identity),
			accHash,
			initialNonce,
			txns,
			sigs.isBothSigned
		));
		if (sigs.isBothSigned) {
			require(acc.one == SignatureValidator.recoverAddr(hash, sigs.one), 'SIG_ONE');
			require(acc.two == SignatureValidator.recoverAddr(hash, sigs.two), 'SIG_TWO');
			identity.executeBySender(txns);
		} else {
			address signer = SignatureValidator.recoverAddr(hash, sigs.one);
			require(acc.one == signer || acc.two == signer, 'SIG');
			// no need to check whether `scheduled[hash]` is already set here cause of the incrementing nonce
			scheduled[hash] = block.timestamp + acc.timelock;
			emit LogScheduled(hash, accHash, signer, initialNonce, block.timestamp, txns);
		}
	}

	function cancel(Identity identity, QuickAccount calldata acc, uint nonce, bytes calldata sig, Identity.Transaction[] calldata txns) external {
		bytes32 accHash = keccak256(abi.encode(acc));
		require(identity.privileges(address(this)) == accHash, 'WRONG_ACC_OR_NO_PRIV');

		bytes32 hash = keccak256(abi.encode(CANCEL_PREFIX, address(this), block.chainid, address(identity), accHash, nonce, txns, false));
		address signer = SignatureValidator.recoverAddr(hash, sig);
		require(signer == acc.one || signer == acc.two, 'INVALID_SIGNATURE');

		// @NOTE: should we allow cancelling even when it's matured? probably not, otherwise there's a minor grief
		// opportunity: someone wants to cancel post-maturity, and you front them with execScheduled
		bytes32 hashTx = keccak256(abi.encode(address(this), block.chainid, accHash, nonce, txns, false));
		uint scheduledTime = scheduled[hashTx];
		require(scheduledTime != 0 && block.timestamp < scheduledTime, 'TOO_LATE');
		delete scheduled[hashTx];

		emit LogCancelled(hashTx, accHash, signer, block.timestamp);
	}

	function execScheduled(Identity identity, bytes32 accHash, uint nonce, Identity.Transaction[] calldata txns) external {
		require(identity.privileges(address(this)) == accHash, 'WRONG_ACC_OR_NO_PRIV');

		bytes32 hash = keccak256(abi.encode(address(this), block.chainid, address(identity), accHash, nonce, txns, false));
		uint scheduledTime = scheduled[hash];
		require(scheduledTime != 0 && block.timestamp >= scheduledTime, 'NOT_TIME');

		delete scheduled[hash];
		identity.executeBySender(txns);

		emit LogExecScheduled(hash, accHash, block.timestamp);
	}

	// EIP 1271 implementation
	// see https://eips.ethereum.org/EIPS/eip-1271
	// NOTE: this method is not intended to be called from off-chain eth_calls; technically it's not a clean EIP 1271
	// ...implementation, because EIP1271 assumes every smart wallet implements that method, while this contract is not a smart wallet
	function isValidSignature(bytes32 hash, bytes calldata signature) external view returns (bytes4) {
		(uint timelock, bytes memory sig1, bytes memory sig2) = abi.decode(signature, (uint, bytes, bytes));
		bytes32 accHash = keccak256(abi.encode(QuickAccount({
			timelock: timelock,
			one: SignatureValidator.recoverAddr(hash, sig1),
			two: SignatureValidator.recoverAddr(hash, sig2)
		})));
		if (Identity(payable(address(msg.sender))).privileges(address(this)) == accHash) {
			// bytes4(keccak256("isValidSignature(bytes32,bytes)")
			return 0x1626ba7e;
		} else {
			return 0xffffffff;
		}
	}


	// EIP 712 methods
	// all of the following are 2/2 only
	struct DualSigAlwaysBoth {
		bytes one;
		bytes two;
	}

	function calculateDomainSeparator() internal view returns (bytes32) {
		return keccak256(
			abi.encode(
				keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
				// @TODO: maybe we should use a more user friendly name here?
				keccak256(bytes('QuickAccManager')),
				keccak256(bytes('1')),
				block.chainid,
				address(this)
			)
		);
	}

	/// @notice EIP-712 typehash for this contract's domain.
	function DOMAIN_SEPARATOR() public view returns (bytes32) {
		return block.chainid == DOMAIN_SEPARATOR_CHAIN_ID ? _DOMAIN_SEPARATOR : calculateDomainSeparator();
	}

	bytes32 private constant TRANSFER_TYPEHASH = keccak256('Transfer(address tokenAddr,address to,uint256 value,uint256 fee,address identity,uint256 nonce)');
	struct Transfer { address token; address to; uint amount; uint fee; }
	// WARNING: if the signature of this is changed, we have to change IdentityFactory
	function sendTransfer(Identity identity, QuickAccount calldata acc, DualSigAlwaysBoth calldata sigs, Transfer calldata t) external {
		require(identity.privileges(address(this)) == keccak256(abi.encode(acc)), 'WRONG_ACC_OR_NO_PRIV');

		bytes32 hash = keccak256(abi.encodePacked(
			'\x19\x01',
			DOMAIN_SEPARATOR(),
			keccak256(abi.encode(TRANSFER_TYPEHASH, t.token, t.to, t.amount, t.fee, address(identity), nonces[address(identity)]++))
		));
		require(acc.one == SignatureValidator.recoverAddr(hash, sigs.one), 'SIG_ONE');
		require(acc.two == SignatureValidator.recoverAddr(hash, sigs.two), 'SIG_TWO');
		Identity.Transaction[] memory txns = new Identity.Transaction[](2);
		txns[0].to = t.token;
		txns[0].data = abi.encodeWithSelector(IERC20.transfer.selector, t.to, t.amount);
		txns[1].to = t.token;
		txns[1].data = abi.encodeWithSelector(IERC20.transfer.selector, msg.sender, t.fee);
		identity.executeBySender(txns);
	}

	// Reference for arrays: https://github.com/sportx-bet/smart-contracts/blob/e36965a0c4748bf73ae15ed3cab5660c9cf722e1/contracts/impl/trading/EIP712FillHasher.sol
	// and https://eips.ethereum.org/EIPS/eip-712
	// and for signTypedData_v4: https://gist.github.com/danfinlay/750ce1e165a75e1c3387ec38cf452b71
	struct Txn { string description; address to; uint value; bytes data; }
	bytes32 private constant TXNS_TYPEHASH = keccak256('Txn(string description,address to,uint256 value,bytes data)');
	bytes32 private constant BUNDLE_TYPEHASH = keccak256('Bundle(address identity,uint256 nonce,Txn[] transactions)');
	// WARNING: if the signature of this is changed, we have to change IdentityFactory
	function sendTxns(Identity identity, QuickAccount calldata acc, DualSigAlwaysBoth calldata sigs, Txn[] calldata txns) external {
		require(identity.privileges(address(this)) == keccak256(abi.encode(acc)), 'WRONG_ACC_OR_NO_PRIV');

		// hashing + prepping args
		bytes32[] memory txnBytes = new bytes32[](txns.length);
		Identity.Transaction[] memory identityTxns = new Identity.Transaction[](txns.length);
		uint txnLen = txns.length;
		for (uint256 i = 0; i < txnLen; i++) {
			txnBytes[i] = keccak256(abi.encode(TXNS_TYPEHASH, txns[i].description, txns[i].to, txns[i].value, txns[i].data));
			identityTxns[i].to = txns[i].to;
			identityTxns[i].value = txns[i].value;
			identityTxns[i].data = txns[i].data;
		}
		bytes32 txnsHash = keccak256(abi.encodePacked(txnBytes));
		bytes32 hash = keccak256(abi.encodePacked(
			'\x19\x01',
			DOMAIN_SEPARATOR(),
			keccak256(abi.encode(BUNDLE_TYPEHASH, address(identity), nonces[address(identity)]++, txnsHash))
		));
		require(acc.one == SignatureValidator.recoverAddr(hash, sigs.one), 'SIG_ONE');
		require(acc.two == SignatureValidator.recoverAddr(hash, sigs.two), 'SIG_TWO');
		identity.executeBySender(identityTxns);
	}

}