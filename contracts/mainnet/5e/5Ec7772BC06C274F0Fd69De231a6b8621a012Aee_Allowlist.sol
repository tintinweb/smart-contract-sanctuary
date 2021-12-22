// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IAllowlist.sol";

/**
 * @title Allowlist
 * @dev The Allowlist contract has a allowlist of addresses, and provides basic authorization control functions.
 * @dev This simplifies the implementation of "user permissions".
 */
contract Allowlist is IAllowlist, Ownable {
    mapping(address => bool) public override allowlist;
    uint256 public override remainingSeats = 2500;
    // 2022-01-15 12:00 pm UTC
    uint256 public override deadline = 1642248000;

    // ------------------
    // Public write functions
    // ------------------

    function addAddressToAllowlist(address _addr) external override {
        require(block.timestamp <= deadline, "RetroPhonesAllowlist: Allowlist already closed");
        require(remainingSeats > 0, "RetroPhonesAllowlist: Allowlist is full");
        require(!allowlist[_addr], "RetroPhonesAllowlist: Already on the list");
        remainingSeats--;
        allowlist[_addr] = true;
    }

    function removeSelfFromAllowlist() external override {
        require(allowlist[msg.sender], "RetroPhonesAllowlist: Not on the list");
        remainingSeats++;
        allowlist[msg.sender] = false;
    }

    // ------------------
    // Function for the owner
    // ------------------

    function addSeats(uint256 _seatsToAdd) external override onlyOwner {
        remainingSeats = remainingSeats + _seatsToAdd;
    }

    function reduceSeats(uint256 _seatsToSubstract) external override onlyOwner {
        remainingSeats = remainingSeats - _seatsToSubstract;
    }

    function setDeadline(uint256 _newDeadline) external override onlyOwner {
        deadline = _newDeadline;
    }

    function addAddressesToAllowlist(address[] calldata _addrs) external override onlyOwner {
        require(block.timestamp <= deadline, "RetroPhonesAllowlist: Allowlist already closed");
        require(remainingSeats >= _addrs.length, "RetroPhonesAllowlist: Allowlist is full");

        for (uint256 i = 0; i < _addrs.length; i++) {
            if (!allowlist[_addrs[i]]) {
                remainingSeats--;
                allowlist[_addrs[i]] = true;
            }
        }
    }
}

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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

interface IAllowlist {
    // Getters
    function allowlist(address) external returns (bool);

    function remainingSeats() external returns (uint256);

    function deadline() external returns (uint256);

    // ------------------
    // Public write functions
    // ------------------

    function addAddressToAllowlist(address _addr) external;

    function removeSelfFromAllowlist() external;

    // ------------------
    // Function for the owner
    // ------------------

    function addSeats(uint256 _seatsToAdd) external;

    function reduceSeats(uint256 _seatsToSubstract) external;

    function setDeadline(uint256 _newDeadline) external;

    function addAddressesToAllowlist(address[] calldata _addrs) external;
}

// SPDX-License-Identifier: MIT

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