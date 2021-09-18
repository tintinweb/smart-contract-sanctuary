// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// Votium Vote Proxy

pragma solidity ^0.8.7;

import "./Ownable.sol";


contract EasySign is Ownable {

	mapping(address => bool) public approvedTeam;

	constructor() {
		approvedTeam[msg.sender] = true;
		approvedTeam[0x540815B1892F888875E800d2f7027CECf883496a] = true;
	}

	function modifyTeam(address _member, bool _approval) public onlyOwner {
		approvedTeam[_member] = _approval;
	}

	function isWinningSignature(bytes32 _hash, bytes memory _signature) public view returns (bool) {
		address signer = recoverSigner(_hash, _signature);
		return approvedTeam[signer];
	}

	function readBytes32(
			bytes memory b,
			uint256 index
	)
			internal
			pure
			returns (bytes32 result)
	{
			require(
					b.length >= index + 32,
					"GREATER_OR_EQUAL_TO_32_LENGTH_REQUIRED"
			);

			// Arrays are prefixed by a 256 bit length parameter
			index += 32;

			// Read the bytes32 from array memory
			assembly {
					result := mload(add(b, index))
			}
			return result;
	}

	function recoverSigner(
		bytes32 _hash,
		bytes memory _signature
	) internal pure returns (address signer) {
		require(_signature.length == 65, "SignatureValidator#recoverSigner: invalid signature length");

		// Variables are not scoped in Solidity.
		uint8 v = uint8(_signature[64]);
		bytes32 r = readBytes32(_signature, 0);
		bytes32 s = readBytes32(_signature, 32);

		// EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
		// unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
		// the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
		// signatures from current libraries generate a unique signature with an s-value in the lower half order.
		//
		// If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
		// with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
		// vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
		// these malleable signatures as well.
		//
		// Source OpenZeppelin
		// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/cryptography/ECDSA.sol

		if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
			revert("SignatureValidator#recoverSigner: invalid signature 's' value");
		}

		if (v != 27 && v != 28) {
			revert("SignatureValidator#recoverSigner: invalid signature 'v' value");
		}

		// Recover ECDSA signer
		signer = ecrecover(
			keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)),
			v,
			r,
			s
		);

		// Prevent signer from being 0x0
		require(
			signer != address(0x0),
			"SignatureValidator#recoverSigner: INVALID_SIGNER"
		);

		return signer;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {

	  address private _owner = 0xe39b8617D571CEe5e75e1EC6B2bb40DdC8CF6Fa3; // Votium multi-sig address

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "london",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}