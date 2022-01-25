// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// ============================ VERSION_0.1.0 ==============================
//   ██       ██████  ████████ ████████    ██      ██ ███    ██ ██   ██
//   ██      ██    ██    ██       ██       ██      ██ ████   ██ ██  ██
//   ██      ██    ██    ██       ██       ██      ██ ██ ██  ██ █████
//   ██      ██    ██    ██       ██       ██      ██ ██  ██ ██ ██  ██
//   ███████  ██████     ██       ██    ██ ███████ ██ ██   ████ ██   ██    
// ======================================================================
//  ================ Open source smart contract on EVM =================
//   ============== Verify Random Function by ChainLink ===============


import "@openzeppelin/contracts/access/Ownable.sol";
import "./IContData.sol";

/**
 * @dev this contract is source of every types of variables used by LOTT.LINK Ecosystem.
 */
contract ContData is IContData, Ownable{

    function version() public pure returns(string memory){
        return "0.1.0";
    }

    /**
     * @dev holding one-to-one assignments.
     */
    mapping(bytes32 => bool) bytes32ToBool;
    mapping(bytes32 => uint) bytes32ToUint;
    mapping(bytes32 => int) bytes32ToInt;
    mapping(bytes32 => address) bytes32ToAddress;
    mapping(bytes32 => string) bytes32ToString;
    mapping(bytes32 => bytes) bytes32ToBytes;


    /**
     * @dev emits when a one-to-one variable is assigned or removed.
     */
    event SetBool(bytes32 tag, bool data);
    event SetUint(bytes32 tag, uint data);
    event SetInt(bytes32 tag, int data);
    event SetAddress(bytes32 tag, address data);
    event SetString(bytes32 tag, string data);
    event SetBytes(bytes32 tag, bytes data);


    /**
     * @dev returns any `data` assigned to a `tag`.
     */
    function getBool(bytes32 tag) external view returns(bool data) {
        return bytes32ToBool[tag];
    }
    function getUint(bytes32 tag) external view returns(uint data) {
        return bytes32ToUint[tag];
    }
    function getInt(bytes32 tag) external view returns(int data) {
        return bytes32ToInt[tag];
    }
    function getAddress(bytes32 tag) external view returns(address data) {
        return bytes32ToAddress[tag];
    }
    function getString(bytes32 tag) external view returns(string memory data) {
        return bytes32ToString[tag];
    }
    function getBytes(bytes32 tag) external view returns(bytes memory data) {
        return bytes32ToBytes[tag];
    }


    /**
     * @dev assign `data` to a `tag` decided by the governance.
     */
    function setBool(bytes32 tag, bool data) external onlyOwner {
        bytes32ToBool[tag] = data;
        emit SetBool(tag, data);
    }
    function setUint(bytes32 tag, uint data) external onlyOwner {
        bytes32ToUint[tag] = data;
        emit SetUint(tag, data);
    }
    function setInt(bytes32 tag, int data) external onlyOwner {
        bytes32ToInt[tag] = data;
        emit SetInt(tag, data);
    }
    function setAddress(bytes32 tag, address data) external onlyOwner {
        bytes32ToAddress[tag] = data;
        emit SetAddress(tag, data);
    }
    function setString(bytes32 tag, string memory data) external onlyOwner {
        bytes32ToString[tag] = data;
        emit SetString(tag, data);
    }
    function setBytes(bytes32 tag, bytes memory data) external onlyOwner {
        bytes32ToBytes[tag] = data;
        emit SetBytes(tag, data);
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
pragma solidity ^0.8.7;

// ============================ VERSION_0.1.0 ==============================
//   ██       ██████  ████████ ████████    ██      ██ ███    ██ ██   ██
//   ██      ██    ██    ██       ██       ██      ██ ████   ██ ██  ██
//   ██      ██    ██    ██       ██       ██      ██ ██ ██  ██ █████
//   ██      ██    ██    ██       ██       ██      ██ ██  ██ ██ ██  ██
//   ███████  ██████     ██       ██    ██ ███████ ██ ██   ████ ██   ██    
// ======================================================================
//  ================ Open source smart contract on EVM =================
//   ============== Verify Random Function by ChainLink ===============


interface IContData {
    function getBool(bytes32 tag) external view returns(bool data);
    function getUint(bytes32 tag) external view returns(uint data);
    function getInt(bytes32 tag) external view returns(int data);
    function getAddress(bytes32 tag) external view returns(address data);
    function getString(bytes32 tag) external view returns(string memory data);
    function getBytes(bytes32 tag) external view returns(bytes memory data);
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