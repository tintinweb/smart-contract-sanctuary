pragma solidity 0.8.4;

// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts/access/Ownable.sol";
// import "hardhat/console.sol";

contract NOIZDStaking is Ownable
{
   /**
      The mapping that keeps track of how much a user has staked.
   */
   mapping(address => uint256) public stakes;

   /**
      The mapping that keeps track of which users requested direct
      withdrawal.
   */
   mapping(address => uint256) public freezes;

   /**
      Before taking any action on the platform, potential buyers
      must stake their ETH with this contract.
   */
   function stake()
      payable
      external
   {
      stakes[msg.sender] += msg.value;
   }

   /**
      Instant withdrawal triggered by Noizd backend.
   */
   function withdrawInstant(address staker, uint256 amount)
      external
      onlyOwner
   {
      require(stakes[staker] >= amount, "Insufficient funds to withdraw.");
      stakes[staker] -= amount;
      (bool success, ) = staker.call{value: amount}("");
      require(success, "Failed to withdraw stake.");
   }

   /**
      Creates a pending direct withdrawal for the user. This is
      detected by the Noizd backend and the user is frozen out
      of any purchasing activity on the site.
   */
   function withdrawFreeze()
      external
   {
      freezes[msg.sender] = block.timestamp;
   }

   /**
      Completes a pending direct withdrawal for the user once
      the freeze has expired. Freeze lasts for two weeks.
   */
   function withdrawFrozen(uint256 amount)
      external
   {
      require(stakes[msg.sender] >= amount, "Insufficient funds to withdraw.");
      require(freezes[msg.sender] > 0, "The freeze was not set.");
      require((block.timestamp - freezes[msg.sender]) > 14 days, "The freezout period has not ended.");
      stakes[msg.sender] -= amount;
      (bool success, ) = msg.sender.call{value: amount}("");
      require(success, "Failed to withdraw stake.");
      delete freezes[msg.sender];
   }

   /**
      Transfer staked funds from one party to another via Noizd backend.
   */
   function transfer(address staker, address target, uint256 amount)
      external
      onlyOwner
   {
      require(stakes[staker] >= amount, "Insufficient funds to withdraw.");
      stakes[staker] -= amount;
      (bool success, ) = target.call{value: amount}("");
      require(success, "Failed to transfer stake.");
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
        return msg.data;
    }
}

