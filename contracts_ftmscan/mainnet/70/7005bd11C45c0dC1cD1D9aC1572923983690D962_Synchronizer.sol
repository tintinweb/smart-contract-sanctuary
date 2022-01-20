// Be name Khoda
// Bime Abolfazl
// SPDX-License-Identifier: MIT

// =================================================================================================================
//  _|_|_|    _|_|_|_|  _|    _|    _|_|_|      _|_|_|_|  _|                                                       |
//  _|    _|  _|        _|    _|  _|            _|            _|_|_|      _|_|_|  _|_|_|      _|_|_|    _|_|       |
//  _|    _|  _|_|_|    _|    _|    _|_|        _|_|_|    _|  _|    _|  _|    _|  _|    _|  _|        _|_|_|_|     |
//  _|    _|  _|        _|    _|        _|      _|        _|  _|    _|  _|    _|  _|    _|  _|        _|           |
//  _|_|_|    _|_|_|_|    _|_|    _|_|_|        _|        _|  _|    _|    _|_|_|  _|    _|    _|_|_|    _|_|_|     |
// =================================================================================================================
// ==================== DEUS Synchronizer ===================
// ==========================================================
// DEUS Finance: https://github.com/DeusFinance

// Primary Author(s)
// Vahid: https://github.com/vahid-dev

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./interfaces/ISynchronizer.sol";
import "./interfaces/IDEIStablecoin.sol";
import "./interfaces/IRegistrar.sol";


/// @title Synchronizer
/// @author deus.finance
/// @notice deus ecosystem synthetics token trading contract
contract Synchronizer is ISynchronizer, Ownable {
	using ECDSA for bytes32;

	// variables
	address public muonContract;  // address of muon verifier contract
	address public deiContract;  // address of dei token
	uint256 public minimumRequiredSignature;  // number of signatures that required
	uint256 public scale = 1e18;  // used for math
	uint256 public withdrawableFeeAmount;  // trading fee amount
	uint256 public virtualReserve;
	uint8 public APP_ID;  // muon's app id
	bool public useVirtualReserve;

	event Buy(address user, address registrar, uint256 registrarAmount, uint256 collateralAmount, uint256 feeAmount);
	event Sell(address user, address registrar, uint256 registrarAmount, uint256 collateralAmount, uint256 feeAmount);
	event WithdrawFee(uint256 amount, address recipient);

	constructor (
		uint256 _minimumRequiredSignature,
		uint256 _virtualReserve,
		address _collateralToken
	) {
		minimumRequiredSignature = _minimumRequiredSignature;
		virtualReserve = _virtualReserve;
		deiContract = _collateralToken;
	}

	/// @notice This function use pool feature to manage buyback and recollateralize on DEI minter pool
	/// @dev simulates the collateral in the contract
	/// @param collat_usd_price pool's collateral price (is 1e6) (decimal is 6)
	/// @return amount of collateral in the contract
    function collatDollarBalance(uint256 collat_usd_price) public view returns (uint256) {
        uint256 collateralRatio = IDEIStablecoin(deiContract).global_collateral_ratio();
        return (virtualReserve * collateralRatio) / 1e6;
    }

	/// @notice used for trade signatures
	/// @return number of chainID
	function getChainID() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

	/// @notice sell the synthetic tokens
	/// @dev SchnorrSign is a TSS structure
	/// @param _user collateral will be send to the _user
	/// @param registrar synthetic token address
	/// @param amount synthetic token amount (decimal is 18)
	/// @param fee trading fee
	/// @param expireBlock signature expire time
	/// @param price synthetic token price
	/// @param _reqId muon request id
	/// @param sigs muon network's TSS signatures
	function sellFor(
		address _user,
		address registrar,
		uint256 amount,
		uint256 fee,
		uint256 expireBlock,
		uint256 price,
		bytes calldata _reqId,
		SchnorrSign[] calldata sigs
	)
		external
	{
		require(
            sigs.length >= minimumRequiredSignature,
            "SYNCHRONIZER: insufficient number of signatures"
        );
		require(amount > 0, "SYNCHRONIZER: amount should be bigger than 0");

		{
            bytes32 hash = keccak256(
                abi.encodePacked(
                    registrar, 
					price, 
					fee, 
					expireBlock, 
					uint256(0),
					getChainID(),
					APP_ID
                )
            );

            IMuonV02 muon = IMuonV02(muonContract);
            require(
                muon.verify(_reqId, uint256(hash), sigs),
                "SYNCHRONIZER: not verified"
            );
        }

		uint256 collateralAmount = amount * price / scale;
		uint256 feeAmount = collateralAmount * fee / scale;

		withdrawableFeeAmount = withdrawableFeeAmount + feeAmount;

		IRegistrar(registrar).burn(msg.sender, amount);

		uint256 deiAmount = collateralAmount - feeAmount;
		IDEIStablecoin(deiContract).pool_mint(_user, deiAmount);
		if (useVirtualReserve) virtualReserve += deiAmount;

		emit Sell(_user, registrar, amount, collateralAmount, feeAmount);
	}

	/// @notice buy the synthetic tokens
	/// @dev SchnorrSign is a TSS structure
	/// @param _user synthetic token will be send to the _user
	/// @param registrar synthetic token address
	/// @param amount synthetic token amount (decimal is 18)
	/// @param fee trading fee
	/// @param expireBlock signature expire time
	/// @param price synthetic token price
	/// @param _reqId muon request id
	/// @param sigs muon network's TSS signatures
	function buyFor(
		address _user,
		address registrar,
		uint256 amount,
		uint256 fee,
		uint256 expireBlock,
		uint256 price,
		bytes calldata _reqId,
		SchnorrSign[] calldata sigs
	)
		external
	{
		require(
            sigs.length >= minimumRequiredSignature,
            "SYNCHRONIZER: insufficient number of signatures"
        );
		require(amount > 0, "SYNCHRONIZER: amount should be bigger than 0");

		{
            bytes32 hash = keccak256(
                abi.encodePacked(
                    registrar, 
					price, 
					fee, 
					expireBlock, 
					uint256(1),
					getChainID(),
					APP_ID
                )
            );

            IMuonV02 muon = IMuonV02(muonContract);
            require(
                muon.verify(_reqId, uint256(hash), sigs),
                "SYNCHRONIZER: not verified"
            );
        }

		uint256 collateralAmount = amount * price / scale;
		uint256 feeAmount = collateralAmount * fee / scale;

		withdrawableFeeAmount = withdrawableFeeAmount + feeAmount;

		uint256 deiAmount = collateralAmount + feeAmount;
		IDEIStablecoin(deiContract).pool_burn_from(msg.sender, deiAmount);
		if (useVirtualReserve) virtualReserve -= deiAmount;

		IRegistrar(registrar).mint(_user, amount);

		emit Buy(_user, registrar, amount, collateralAmount, feeAmount);
	}

	/// @notice withdraw accumulated trading fee by DAO
	/// @dev fee will be minted in DEI
	/// @param amount_ fee amount that DAO want to withdraw
	/// @param recipient_ receiver of fee
	function withdrawFee(uint256 amount_, address recipient_) external onlyOwner {
		withdrawableFeeAmount = withdrawableFeeAmount - amount_;
		IDEIStablecoin(deiContract).pool_mint(recipient_, amount_);
		emit WithdrawFee(amount_, recipient_);
	}

	/// @notice changes minimum required signatures in trading functions by DAO
	/// @param _minimumRequiredSignature number of required signatures
	function setMinimumRequiredSignature(uint256 _minimumRequiredSignature) external onlyOwner {
		minimumRequiredSignature = _minimumRequiredSignature;
	}

	function setScale(uint scale_) external onlyOwner {
		scale = scale_;
	}

	/// @notice changes muon's app id by DAO
	/// @dev each app becomes different from others by app id
	/// @param APP_ID_ muon's app id
	function setAppId(uint8 APP_ID_) external onlyOwner {
		APP_ID = APP_ID_;
	}

	function setvirtualReserve(uint256 virtualReserve_) external onlyOwner {
        virtualReserve = virtualReserve_;
    }

	function setMuonContract(address muonContract_) external onlyOwner {
		muonContract = muonContract_;
	}

	/// @dev it affects buyback and recollateralize functions on DEI minter pool 
	function toggleUseVirtualReserve() external onlyOwner {
		useVirtualReserve = !useVirtualReserve;
	}
}

//Dar panah khoda

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
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
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

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
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
        } else if (signature.length == 64) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let vs := mload(add(signature, 0x40))
                r := mload(add(signature, 0x20))
                s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
                v := add(shr(255, vs), 27)
            }
        } else {
            revert("ECDSA: invalid signature length");
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./IMuonV02.sol";

interface ISynchronizer {

    function muonContract() external view returns(address);
    function minimumRequiredSignature() external view returns(uint256);
    function scale() external view returns(uint256);
    function withdrawableFeeAmount() external view returns(uint256);
    function virtualReserve() external view returns(uint256);
    function APP_ID() external view returns(uint8);
    function useVirtualReserve() external view returns(bool);
    function deiContract() external view returns(address);
    function collatDollarBalance(uint256 collat_usd_price) external view returns (uint256);
	function getChainID() external view returns (uint256);
	function sellFor(
		address _user,
		address registrar,
		uint256 amount,
		uint256 fee,
		uint256 expireBlock,
		uint256 price,
		bytes calldata _reqId,
		SchnorrSign[] calldata sigs
	) external;
	function buyFor(
		address _user,
		address registrar,
		uint256 amount,
		uint256 fee,
		uint256 expireBlock,
		uint256 price,
		bytes calldata _reqId,
		SchnorrSign[] calldata sigs
	) external;
	function withdrawFee(uint256 amount_, address recipient_) external;
	function setMinimumRequiredSignature(uint256 _minimumRequiredSignature) external;
	function setScale(uint scale_) external;
	function setAppId(uint8 APP_ID_) external;
	function setvirtualReserve(uint256 virtualReserve_) external;
	function setMuonContract(address muonContract_) external;
	function toggleUseVirtualReserve() external;
}

//Dar panah khoda

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.10;

interface IDEIStablecoin {
    function pool_burn_from(address b_address, uint256 b_amount) external;
    function pool_mint(address m_address, uint256 m_amount) external;
    function global_collateral_ratio() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface IRegistrar {
	function totalSupply() external view returns (uint256);
	function mint(address to, uint256 amount) external;
	function burn(address from, uint256 amount) external;
}

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

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

struct SchnorrSign {
    uint256 signature;
    address owner;
    address nonce;
}

interface IMuonV02{
    function verify(bytes calldata reqId, uint256 hash, SchnorrSign[] calldata _sigs) external returns (bool);
}