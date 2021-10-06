/**
 *Submitted for verification at Etherscan.io on 2021-10-05
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/Delegator.sol
// SPDX-License-Identifier: MIT
pragma solidity =0.8.6 >=0.8.0 <0.9.0;

////// lib/openzeppelin-contracts/contracts/utils/Context.sol

/* pragma solidity ^0.8.0; */

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

////// lib/openzeppelin-contracts/contracts/access/Ownable.sol

/* pragma solidity ^0.8.0; */

/* import "../utils/Context.sol"; */

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

////// src/interfaces/IGovernanceToken.sol
/* pragma solidity 0.8.6; */

interface IGovernanceToken {
   function delegate(address delegatee) external;

   function delegates(address delegator) external returns (address);

   function transfer(address dst, uint256 rawAmount) external returns (bool);

   function transferFrom(
      address src,
      address dst,
      uint256 rawAmount
   ) external returns (bool);

   function balanceOf(address src) external returns (uint256);

   function decimals() external returns (uint8);
}

////// src/Delegator.sol
/* pragma solidity 0.8.6; */

/* import "./interfaces/IGovernanceToken.sol"; */
/* import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol"; */

/**
 * @title Delegator Contract
 * @author Cryptex.Finance
 * @notice Contract in charge of handling delegations.
 */

contract Delegator is Ownable {
   /* ========== STATE VARIABLES ========== */

   /// @notice Address of the staking governance token
   address public immutable token;

   /// @notice Tracks the amount of staked tokens per user
   mapping(address => uint256) public stakerBalance;

   /* ========== CONSTRUCTOR ========== */

   /**
    * @notice Constructor
    * @param delegatee_ address
    * @param token_ address
    * @dev when created delegates all it's power to delegatee_ and can't be changed later
    * @dev sets delegator factory as owner
    */
   constructor(address delegatee_, address token_) {
      require(
         delegatee_ != address(0) && token_ != address(0),
         "Address can't be 0"
      );
      require(IGovernanceToken(token_).decimals() == 18, "Decimals must be 18");
      token = token_;
      IGovernanceToken(token_).delegate(delegatee_);
   }

   /* ========== MUTATIVE FUNCTIONS ========== */

   /**
    * @notice Increases the balance of the staker
    * @param staker_ caller of the stake function
    * @param amount_ uint to be staked and delegated
    * @dev Only delegatorFactory can call it
    * @dev after the balance is updated the amount is transferred from the user to this contract
    */
   function stake(address staker_, uint256 amount_) external onlyOwner {
      stakerBalance[staker_] += amount_;
   }

   /**
    * @notice Decreases the balance of the staker
    * @param staker_ caller of the stake function
    * @param amount_ uint to be withdrawn and undelegated
    * @dev Only delegatorFactory can call it
    * @dev after the balance is updated the amount is transferred back to the user from this contract
    */
   function removeStake(address staker_, uint256 amount_) external onlyOwner {
      stakerBalance[staker_] -= amount_;
      require(
         IGovernanceToken(token).transfer(staker_, amount_),
         "Transfer failed"
      );
   }

   /* ========== VIEWS ========== */

   /// @notice returns the delegatee of this contract
   function delegatee() external returns (address) {
      return IGovernanceToken(token).delegates(address(this));
   }
}