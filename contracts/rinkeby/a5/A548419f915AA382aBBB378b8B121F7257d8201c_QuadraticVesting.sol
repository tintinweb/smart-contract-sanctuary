pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
/*
 This Contract allows for quadratic vesting of a single ERC20 token starting at a hardcoded Timestamp for a hardcoded duration.
 the amount of the balance a user can retrieve is linearly dependent on 
 the fraction of the duration that has already passed since startTime squared.
 => retrievableAmount = (timePassed/Duration)^2 * totalAmount
 => 50 percent of time passed => 25% of total amount is retrievable
*/
contract QuadraticVesting is Ownable {

  IERC20 private token;
  uint256 public startTime;
  uint256 public duration;
  uint256 constant private dec = 10**0;     // @dev: fix decimals after testing
  mapping(address => uint256) public totalDeposit;
  mapping(address => uint256) private drainedAmount;

  constructor(IERC20 _token, uint256 _durationInDays, uint256 startInDays) {
    token = _token;
    startTime = block.timestamp + startInDays * 86400;
    duration = _durationInDays*86400;
  }

  function rawDeposit(address _from, address _for, uint256 _amount) internal {
    require(token.transferFrom(_from, address(this), _amount));
    totalDeposit[_for] += _amount;
  }

  function depositFor(address _recipient, uint256 _amount) public {
    rawDeposit(msg.sender, _recipient, _amount);
  }

  function depositAllFor(address _recipient) external {
    depositFor(_recipient, token.balanceOf(_recipient));
  }

  function retrieve() external {
    uint256 amount = _getRetrievableAmount(msg.sender);
    require(amount != 0, "nothing to retrieve");
    drainedAmount[msg.sender] += amount;
    token.transfer(msg.sender, amount);
    assert(drainedAmount[msg.sender] <= totalDeposit[msg.sender]);
  }

  function decreaseVesting(address _account, uint256 amount) external onlyOwner {
    require(drainedAmount[_account] <= totalDeposit[_account] - amount*dec, "deposit has to be >= drainedAmount");
    totalDeposit[_account] -= amount*dec;
  }
    // 1e8 => 100%; 1e7 => 10%; 1e6 => 1%;
    // if startTime is not reached return 0
    // if the duration is over return 1e10
  function _getPercentage() private view returns(uint256) {
    if(startTime > block.timestamp){
      return 0;
    }else if(startTime + duration > block.timestamp){
      return ((1e2 * (block.timestamp - startTime))**2 / duration**2);
    }else{
      return 1e4;
    }
  }

  function _getRetrievableAmount(address _account) private view returns(uint256){
    return (_getPercentage() * totalDeposit[_account] / 1e4) - drainedAmount[_account];
  }

  function getRetrievableAmount() external view returns(uint256) {
    return _getRetrievableAmount(msg.sender)/dec;
  }

  function getTotalDeposit(address _account) external view returns(uint256){
    return totalDeposit[_account]/dec;
  }

  function getRetrievablePercentage() external view returns(uint256) {
    return _getPercentage() / 100;
  }

  function balanceOf(address account) external view returns(uint256) {
    return token.balanceOf(account) + totalDeposit[account] - drainedAmount[account];
  }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
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