// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

// import { IAddressProvider } from "../interfaces/IAddressProvider.sol";
contract AddressProvider is Ownable {
	event DAOSet(address indexed dao_);
	event EmergencyAdminSet(address indexed newAddr_);
	event AddressSet(bytes32 id, address indexed newAddr_);

	mapping(bytes32 => address) private _addresses;
	bytes32 private constant DAO = "DAO";
	bytes32 private constant EMERGENCY_ADMIN = "EMERGENCY_ADMIN";
	bytes32 private constant ORACLE_MASTER = "ORACLE_MASTER";

	function getAddress(bytes32 id_) external view returns (address) {
		return _addresses[id_];
	}

	function setAddress(bytes32 id_, address newAddress_) external onlyOwner {
		require(bytes32(id_).length != 0, "AP: ZERO INPUT");
		require(newAddress_ != address(0), "AP: ZR ADDR");
		_addresses[id_] = newAddress_;
		emit AddressSet(id_, newAddress_);
	}

	/// @dev get & set emergency admin
	function getEmergencyAdmin() external view returns (address) {
		return _addresses[EMERGENCY_ADMIN];
	}

	function setEmergencyAdmin(address emergencyAdmin_) external onlyOwner {
		require(emergencyAdmin_ != address(0), "AP: ZR ADDR");
		_addresses[EMERGENCY_ADMIN] = emergencyAdmin_;
		emit EmergencyAdminSet(emergencyAdmin_);
	}

	/// @dev get & set dao
	function getDAO() external view returns (address) {
		return _addresses[DAO];
	}

	function setDAO(address dao_) external onlyOwner {
		require(dao_ != address(0), "AP: ZR ADDR");
		_addresses[DAO] = dao_;
		emit DAOSet(dao_);
	}

	/// @dev get & set dao
	function getOracleMaster() external view returns (address) {
		return _addresses[ORACLE_MASTER];
	}

	function setOracleMaster(address newAddr_) external onlyOwner {
		require(newAddr_ != address(0), "AP: ZR ADDR");
		_addresses[ORACLE_MASTER] = newAddr_;
		emit AddressSet(ORACLE_MASTER, newAddr_);
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}