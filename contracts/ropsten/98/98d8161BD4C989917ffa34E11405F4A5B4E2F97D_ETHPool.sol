// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';

/**
  The ETHPool protocol is a simple pool of ETH that can be used to invest in and wait for team rewards.
 */
contract ETHPool is Ownable {

    /**
      The total amount of ETH deposited by each contributor (reward's time-dependent).
     */
    mapping(address => uint256) private _contributions;
    
    /**
      The total amount of ETH in the pool.
     */
    uint256 public totalPool;
    
    /**
      The total amount of ETH deposited by contributor (reward's time-dependent).
     */
    uint256 private _depositorsProportionalPool;

    event Deposit(address indexed from, uint256 amount);
    event Withdraw(address indexed to, uint256 amount);
    event Reward(uint256 amount);

    constructor() {} 
    
    /**
      Allows Team to deposit rewards into the pool.
     */
    function reward() public payable onlyOwner {
        totalPool += msg.value;
        emit Reward(msg.value);
    }
    
    /**
      Allows msg.sender to deposit ETH into the pool.
     */
    function deposit() public payable {
      uint256 proportionalContribution = msg.value;
      if (totalPool > 0) {
        proportionalContribution = msg.value * _depositorsProportionalPool / totalPool;
      }
      
      _contributions[msg.sender] += proportionalContribution;
      _depositorsProportionalPool += proportionalContribution;
      totalPool += msg.value;
      assert(address(this).balance == totalPool);
      emit Deposit(msg.sender, msg.value);
    }
    

    /**
      Allows the msg.sender to withdraw the deposited ETH plus the corresponding rewards (depending on deposits times).
     */
    function withdraw() public {
      uint256 balance = getBalance(msg.sender);
      require(balance > 0, 'You have no balance to withdraw');
      (bool success, ) = msg.sender.call{value: balance}('');
      require(success, 'Could not withdraw');
      emit Withdraw(msg.sender, balance);
    }

    /**
      Returns the deposited ETH by the msg.sender, plus the corresponding rewards (depending on deposits times).
     */
    function getBalance(address user) public view returns (uint256) {
      if(totalPool == 0 || _depositorsProportionalPool == 0) {
        return 0;
      }
      return _contributions[user] * totalPool / _depositorsProportionalPool;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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