/**
 *Submitted for verification at Etherscan.io on 2021-07-28
*/

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

// NOTE: this interface lacks return values for transfer/transferFrom/approve on purpose,
// as we use the SafeERC20 library to check the return value
interface GeneralERC20 {
	function transfer(address to, uint256 amount) external;
	function transferFrom(address from, address to, uint256 amount) external;
	function approve(address spender, uint256 amount) external;
	function balanceOf(address spender) external view returns (uint);
	function allowance(address owner, address spender) external view returns (uint);
}

library SafeERC20 {
	function checkSuccess()
		private
		pure
		returns (bool)
	{
		uint256 returnValue = 0;

		assembly {
			// check number of bytes returned from last function call
			switch returndatasize()

			// no bytes returned: assume success
			case 0x0 {
				returnValue := 1
			}

			// 32 bytes returned: check if non-zero
			case 0x20 {
				// copy 32 bytes into scratch space
				returndatacopy(0x0, 0x0, 0x20)

				// load those bytes into returnValue
				returnValue := mload(0x0)
			}

			// not sure what was returned: don't mark as success
			default { }
		}

		return returnValue != 0;
	}

	function transfer(address token, address to, uint256 amount) internal {
		GeneralERC20(token).transfer(to, amount);
		require(checkSuccess(), "SafeERC20: transfer failed");
	}

	function transferFrom(address token, address from, address to, uint256 amount) internal {
		GeneralERC20(token).transferFrom(from, to, amount);
		require(checkSuccess(), "SafeERC20: transferFrom failed");
	}

	function approve(address token, address spender, uint256 amount) internal {
		GeneralERC20(token).approve(spender, amount);
		require(checkSuccess(), "SafeERC20: approve failed");
	}
}


library SignatureValidator {
	enum SignatureMode {
		NO_SIG,
		EIP712,
		GETH,
		TREZOR,
		ADEX
	}

	function recoverAddr(bytes32 hash, bytes32[3] memory signature) internal pure returns (address) {
		SignatureMode mode = SignatureMode(uint8(signature[0][0]));

		if (mode == SignatureMode.NO_SIG) {
			return address(0x0);
		}

		uint8 v = uint8(signature[0][1]);

		if (mode == SignatureMode.GETH) {
			hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
		} else if (mode == SignatureMode.TREZOR) {
			hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n\x20", hash));
		} else if (mode == SignatureMode.ADEX) {
			hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n108By signing this message, you acknowledge signing an AdEx bid with the hash:\n", hash));
		}

		return ecrecover(hash, v, signature[1], signature[2]);
	}

	/// @dev Validates that a hash was signed by a specified signer.
	/// @param hash Hash which was signed.
	/// @param signer Address of the signer.
	/// @param signature ECDSA signature along with the mode [{mode}{v}, {r}, {s}]
	/// @return Returns whether signature is from a specified user.
	function isValid(bytes32 hash, address signer, bytes32[3] memory signature) internal pure returns (bool) {
		return recoverAddr(hash, signature) == signer;
	}
}

contract Identity {

	mapping (address => bool) public privileges;
	// The next allowed nonce
	uint public nonce = 0;

	// Events
	event LogPrivilegeChanged(address indexed addr, bool priv);

	// Transaction structure
	// Those can be executed by keys with >= PrivilegeLevel.Transactions
	// Even though the contract cannot receive ETH, we are able to send ETH (.value), cause ETH might've been sent to the contract address before it's deployed
	struct Transaction {
		// replay protection
		address identityContract;
		uint nonce;
		// tx fee, in tokens
		address feeTokenAddr;
		uint feeAmount;
		// all the regular txn data
		address to;
		uint value;
		bytes data;
	}

	constructor(address[] memory addrs) {
		uint len = addrs.length;
		for (uint i=0; i<len; i++) {
			privileges[addrs[i]] = true;
			emit LogPrivilegeChanged(addrs[i], true);
		}
	}

	// This contract can accept ETH
	fallback() external payable {}
	
	// This contract can accept ETH with emoty calldata
	receive() external payable {}
	
	function getBalance() public view returns (uint) {
        return address(this).balance;
    }
	
	// Send ETH from identity
	function send(address payable recepient) public payable {
	    require(privileges[msg.sender] == true, 'INSUFFICIENT_PRIVILEGE_SENDER');
        (bool sent, bytes memory _data) = recepient.call{value: msg.value}("");
        require(sent, 'Send Ether failed');
    }

	function setAddrPrivilege(address addr, bool priv)
		external
	{
		require(msg.sender == address(this), 'ONLY_IDENTITY_CAN_CALL');
		privileges[addr] = priv;
		emit LogPrivilegeChanged(addr, priv);
	}

	function execute(Transaction[] memory txns, bytes32[3][] memory signatures)
		public
	{
		require(txns.length > 0, 'MUST_PASS_TX');
		address feeTokenAddr = txns[0].feeTokenAddr;
		uint feeAmount = 0;
		uint len = txns.length;
		for (uint i=0; i<len; i++) {
			Transaction memory txn = txns[i];
			require(txn.identityContract == address(this), 'TRANSACTION_NOT_FOR_CONTRACT');
			require(txn.feeTokenAddr == feeTokenAddr, 'EXECUTE_NEEDS_SINGLE_TOKEN');
			require(txn.nonce == nonce, 'WRONG_NONCE');

			// If we use the naive abi.encode(txn) and have a field of type `bytes`,
			// there is a discrepancy between ethereumjs-abi and solidity
			// if we enter every field individually, in order, there is no discrepancy
			//bytes32 hash = keccak256(abi.encode(txn));
			bytes32 hash = keccak256(abi.encode(txn.identityContract, txn.nonce, txn.feeTokenAddr, txn.feeAmount, txn.to, txn.value, txn.data));
			address signer = SignatureValidator.recoverAddr(hash, signatures[i]);

			require(privileges[signer] == true, 'INSUFFICIENT_PRIVILEGE_TRANSACTION');

			// NOTE: we have to change nonce on every txn: do not be tempted to optimize this by incrementing it once by the full txn count
			// otherwise reentrancies are possible, and/or anyone who is reading nonce within a txn will read a wrong value
			nonce = nonce + 1;
			feeAmount = feeAmount + txn.feeAmount;

			executeCall(txn.to, txn.value, txn.data);
			// The actual anti-bricking mechanism - do not allow a signer to drop his own priviledges
			require(privileges[signer] == true, 'PRIVILEGE_NOT_DOWNGRADED');
		}
		if (feeAmount > 0) {
			SafeERC20.transfer(feeTokenAddr, msg.sender, feeAmount);
		}
	}

	function executeBySender(Transaction[] memory txns)
		public
	{
		require(privileges[msg.sender] == true, 'INSUFFICIENT_PRIVILEGE_SENDER');
		uint len = txns.length;
		for (uint i=0; i<len; i++) {
			Transaction memory txn = txns[i];
			require(txn.nonce == nonce, 'WRONG_NONCE');

			nonce = nonce + 1;

			executeCall(txn.to, txn.value, txn.data);
		}
		// The actual anti-bricking mechanism - do not allow the sender to drop his own priviledges
		require(privileges[msg.sender] == true, 'PRIVILEGE_NOT_DOWNGRADED');
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
	}
}

contract IdentityFactory {
	event LogDeployed(address addr, uint256 salt);

	address public creator;
	constructor() {
		creator = msg.sender;
	}

	function deploy(bytes memory code, uint256 salt) public {
		deploySafe(code, salt);
	}

	// When the relayer needs to act upon an /execute call, it'll either call execute on the Identity directly
	// if it's already deployed, or call `deployAndExecute` if the account is still counterfactual
	// can't have deployAndExecuteBySender, because the sender will be the factory
	function deployAndExecute(
		bytes memory code, uint256 salt,
		Identity.Transaction[] memory txns, bytes32[3][] memory signatures
	) public {
		address payable addr = payable(deploySafe(code, salt));
		Identity(addr).execute(txns, signatures);
	}

	// Withdraw the earnings from various fees (deploy fees and execute fees earned cause of `deployAndExecute`)
	function withdraw(address tokenAddr, address to, uint256 tokenAmount) public {
		require(msg.sender == creator, 'ONLY_CREATOR');
		SafeERC20.transfer(tokenAddr, to, tokenAmount);
	}

	// This is done to mitigate possible frontruns where, for example, deploying the same code/salt via deploy()
	// would make a pending deployAndExecute fail
	// The way we mitigate that is by checking if the contract is already deployed and if so, we continue execution
	function deploySafe(bytes memory code, uint256 salt) internal returns (address) {
		address expectedAddr = address(uint160(uint256(
			keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(code)))
		)));
		uint size;
		assembly { size := extcodesize(expectedAddr) }
		// If there is code at that address, we can assume it's the one we were about to deploy,
		// because of how CREATE2 and keccak256 works
		if (size == 0) {
			address addr;
			assembly { addr := create2(0, add(code, 0x20), mload(code), salt) }
			require(addr != address(0), 'FAILED_DEPLOYING');
			require(addr == expectedAddr, 'FAILED_MATCH');
			emit LogDeployed(addr, salt);
		}
		return expectedAddr;
	}
}