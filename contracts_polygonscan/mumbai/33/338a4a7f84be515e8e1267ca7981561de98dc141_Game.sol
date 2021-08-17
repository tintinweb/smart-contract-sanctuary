/**
 *Submitted for verification at polygonscan.com on 2021-08-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
	bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

	/**
	 * @dev Converts a `uint256` to its ASCII `string` decimal representation.
	 */
	function toString(uint256 value) internal pure returns (string memory) {
		// Inspired by OraclizeAPI's implementation - MIT licence
		// https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

		if (value == 0) {
			return "0";
		}
		uint256 temp = value;
		uint256 digits;
		while (temp != 0) {
			digits++;
			temp /= 10;
		}
		bytes memory buffer = new bytes(digits);
		while (value != 0) {
			digits -= 1;
			buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
			value /= 10;
		}
		return string(buffer);
	}

	/**
	 * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
	 */
	function toHexString(uint256 value) internal pure returns (string memory) {
		if (value == 0) {
			return "0x00";
		}
		uint256 temp = value;
		uint256 length = 0;
		while (temp != 0) {
			length++;
			temp >>= 8;
		}
		return toHexString(value, length);
	}

	/**
	 * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
	 */
	function toHexString(uint256 value, uint256 length)
		internal
		pure
		returns (string memory)
	{
		bytes memory buffer = new bytes(2 * length + 2);
		buffer[0] = "0";
		buffer[1] = "x";
		for (uint256 i = 2 * length + 1; i > 1; --i) {
			buffer[i] = _HEX_SYMBOLS[value & 0xf];
			value >>= 4;
		}
		require(value == 0, "Strings: hex length insufficient");
		return string(buffer);
	}
}

contract EIP712Base {
	struct EIP712Domain {
		string name;
		string version;
		address verifyingContract;
		bytes32 salt;
	}

	bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
		keccak256(
			bytes(
				"EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
			)
		);

	bytes32 internal domainSeparator;

	constructor(string memory name, string memory version) {
		domainSeparator = keccak256(
			abi.encode(
				EIP712_DOMAIN_TYPEHASH,
				keccak256(bytes(name)),
				keccak256(bytes(version)),
				address(this),
				bytes32(getChainID())
			)
		);
	}

	function getChainID() internal view returns (uint256 id) {
		assembly {
			id := chainid()
		}
	}

	function getDomainSeparator() private view returns (bytes32) {
		return domainSeparator;
	}

	/**
	 * Accept message hash and returns hash message in EIP712 compatible form
	 * So that it can be used to recover signer from signature signed using EIP712 formatted data
	 * https://eips.ethereum.org/EIPS/eip-712
	 * "\\x19" makes the encoding deterministic
	 * "\\x01" is the version byte to make it compatible to EIP-191
	 */
	function toTypedMessageHash(bytes32 messageHash)
		internal
		view
		returns (bytes32)
	{
		return
			keccak256(
				abi.encodePacked("\x19\x01", getDomainSeparator(), messageHash)
			);
	}
}

contract EIP712MetaTransaction is EIP712Base {
	bytes32 private constant META_TRANSACTION_TYPEHASH =
		keccak256(
			bytes(
				"MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
			)
		);

	event MetaTransactionExecuted(
		address userAddress,
		address relayerAddress,
		bytes functionSignature
	);
	mapping(address => uint256) private nonces;

	/*
	 * Meta transaction structure.
	 * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
	 * He should call the desired function directly in that case.
	 */
	struct MetaTransaction {
		uint256 nonce;
		address from;
		bytes functionSignature;
	}

	constructor(string memory name, string memory version)
		EIP712Base(name, version)
	{}

	function convertBytesToBytes4(bytes memory inBytes)
		internal
		pure
		returns (bytes4 outBytes4)
	{
		if (inBytes.length == 0) {
			return 0x0;
		}

		assembly {
			outBytes4 := mload(add(inBytes, 32))
		}
	}

	function executeMetaTransaction(
		address userAddress,
		bytes memory functionSignature,
		bytes32 sigR,
		bytes32 sigS,
		uint8 sigV
	) public payable returns (bytes memory) {
		bytes4 destinationFunctionSig = convertBytesToBytes4(functionSignature);
		require(
			destinationFunctionSig != msg.sig,
			"functionSignature can not be of executeMetaTransaction method"
		);
		MetaTransaction memory metaTx = MetaTransaction({
			nonce: nonces[userAddress],
			from: userAddress,
			functionSignature: functionSignature
		});
		require(
			verify(userAddress, metaTx, sigR, sigS, sigV),
			"Signer and signature do not match"
		);
		nonces[userAddress] = nonces[userAddress] + 1;
		// Append userAddress at the end to extract it from calling context
		(bool success, bytes memory returnData) = address(this).call(
			abi.encodePacked(functionSignature, userAddress)
		);

		require(success, "Function call not successful");
		emit MetaTransactionExecuted(
			userAddress,
			msg.sender,
			functionSignature
		);
		return returnData;
	}

	function hashMetaTransaction(MetaTransaction memory metaTx)
		internal
		pure
		returns (bytes32)
	{
		return
			keccak256(
				abi.encode(
					META_TRANSACTION_TYPEHASH,
					metaTx.nonce,
					metaTx.from,
					keccak256(metaTx.functionSignature)
				)
			);
	}

	function getNonce(address user) external view returns (uint256 nonce) {
		nonce = nonces[user];
	}

	function verify(
		address user,
		MetaTransaction memory metaTx,
		bytes32 sigR,
		bytes32 sigS,
		uint8 sigV
	) internal view returns (bool) {
		address signer = ecrecover(
			toTypedMessageHash(hashMetaTransaction(metaTx)),
			sigV,
			sigR,
			sigS
		);
		require(signer != address(0), "Invalid signature");
		return signer == user;
	}

	function msgSender() internal view returns (address sender) {
		if (msg.sender == address(this)) {
			bytes memory array = msg.data;
			uint256 index = msg.data.length;
			assembly {
				// Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
				sender := and(
					mload(add(array, index)),
					0xffffffffffffffffffffffffffffffffffffffff
				)
			}
		} else {
			sender = msg.sender;
		}
		return sender;
	}
}

contract Game is EIP712MetaTransaction {
	struct GameData {
		string name;
	}

	bool public controlledFlag = true;
	address public contractOwner;
	mapping(uint256 => address) public ownerOf;
	mapping(uint256 => GameData) public gameDataOf;
	uint256 public gameCount;
	string private _uri;

	constructor(
		string memory uriStr,
		string memory name,
		string memory version
	) EIP712MetaTransaction(name, version) {
		contractOwner = msgSender();
		_setURI(uriStr);
	}

	modifier isOnlyOwner() {
		require(
			!controlledFlag || msgSender() == contractOwner,
			"Can only be called by Stardust"
		);
		_;
	}

	modifier isGameOwner(uint256 gameId) {
		require(
			msgSender() == ownerOf[gameId],
			"Only the game owner can use this function!"
		);
		_;
	}

	modifier isValidGameId(uint256 gameId) {
		require(gameId < gameCount, "Invalid GameId");
		_;
	}

	function addGame(
		uint256 gameId,
		address owner,
		string memory name
	) external isOnlyOwner {
		require(ownerOf[gameId] == address(0), "GameId already exists!");
		ownerOf[gameId] = owner;
		gameDataOf[gameId] = GameData(name);
		gameCount += 1;
	}

	function transferOwner(uint256 gameId, address newOwner)
		external
		isValidGameId(gameId)
		isGameOwner(gameId)
	{
		ownerOf[gameId] = newOwner;
	}

	function _setURI(string memory newuri) internal virtual {
		_uri = newuri;
	}

	function uri(uint256 _gameId) public view virtual returns (string memory) {
		return
			string(abi.encodePacked(_uri, Strings.toString(_gameId), ".json"));
	}
}