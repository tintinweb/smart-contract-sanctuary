/**
 *Submitted for verification at Etherscan.io on 2021-10-05
*/

pragma solidity ^0.6.0;

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
  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

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

contract ReentrancyGuard {
  // Booleans are more expensive than uint256 or any type that takes up a full
  // word because each write operation emits an extra SLOAD to first read the
  // slot's contents, replace the bits taken up by the boolean, and then write
  // back. This is the compiler's defense against contract upgrades and
  // pointer aliasing, and it cannot be disabled.

  // The values being non-zero value makes deployment a bit more expensive,
  // but in exchange the refund on every call to nonReentrant will be lower in
  // amount. Since refunds are capped to a percentage of the total
  // transaction's gas, it is best to keep them low in cases like this one, to
  // increase the likelihood of the full refund coming into effect.
  uint256 private constant _NOT_ENTERED = 1;
  uint256 private constant _ENTERED = 2;

  uint256 private _status;

  constructor() internal {
    _status = _NOT_ENTERED;
  }

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * Calling a `nonReentrant` function from another `nonReentrant`
   * function is not supported. It is possible to prevent this from happening
   * by making the `nonReentrant` function external, and make it call a
   * `private` function that does the actual work.
   */
  modifier nonReentrant() {
    // On the first call to nonReentrant, _notEntered will be true
    require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

    // Any calls to nonReentrant after this point will fail
    _status = _ENTERED;

    _;

    // By storing the original value once again, a refund is triggered (see
    // https://eips.ethereum.org/EIPS/eip-2200)
    _status = _NOT_ENTERED;
  }
}

contract ERC20Locker is ReentrancyGuard {
  uint256 public fiveYears=31536000;
  struct LPLock {
    uint256 amount;
    uint256 endLockTime;
  }
  mapping(address => mapping(address => LPLock)) public userLpLockInfo;

  function lockErc20(
    address lp,
    uint256 _amount,
    uint256 _endLockTime
  ) public nonReentrant {
    if (userLpLockInfo[msg.sender][lp].endLockTime == 0) {
      require(_endLockTime > block.timestamp, "endLockTime wrong");
      require(_endLockTime<block.timestamp+fiveYears,"max time is 5 years");
      userLpLockInfo[msg.sender][lp].endLockTime = _endLockTime;
    } else {
      require(
        _endLockTime > userLpLockInfo[msg.sender][lp].endLockTime,
        "endLockTime incorrect"
      );
      require(_endLockTime<block.timestamp+fiveYears,"max time is 5 years");
      userLpLockInfo[msg.sender][lp].endLockTime = _endLockTime;
    }
    uint256 beforeBalance = IERC20(lp).balanceOf(address(this));

    IERC20(lp).transferFrom(msg.sender, address(this), _amount);
    uint256 afterBalance = IERC20(lp).balanceOf(address(this));
    require(
      _amount <= afterBalance - beforeBalance,
      "There are losses during transfer"
    );
    userLpLockInfo[msg.sender][lp].amount += afterBalance - beforeBalance;
  }

  function withdraw(address lp, uint256 _amount) public nonReentrant {
    require(
      block.timestamp > userLpLockInfo[msg.sender][lp].endLockTime,
      "time not arrived"
    );
    require(userLpLockInfo[msg.sender][lp].amount > 0, "your balance is 0");
    if (_amount == 0) _amount = userLpLockInfo[msg.sender][lp].amount;
    require(_amount <= userLpLockInfo[msg.sender][lp].amount, "exceed balance");
    userLpLockInfo[msg.sender][lp].amount -= _amount;
    IERC20(lp).transfer(msg.sender, _amount);
  }
}