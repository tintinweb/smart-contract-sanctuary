/**
 *Submitted for verification at BscScan.com on 2021-11-15
*/

pragma solidity >=0.6.0 <0.7.0;

contract Context {
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  constructor() internal {}

  function _msgSender() internal view returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

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
contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() internal {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

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

contract Whitelist is Ownable {
  mapping(address => bool) private _whitelist;
  bool public _disable=true; // default - false means whitelist feature is working on. if true no more use of whitelist

  event Whitelisted(address indexed _address, bool whitelist);
  event EnableWhitelist();
  event DisableWhitelist();

  modifier onlyWhitelisted {
    require(
      _disable || _whitelist[msg.sender],
      "Whitelist: caller is not on the whitelist"
    );
    _;
  }

  function isWhitelist(address _address) public view returns (bool) {
    return _whitelist[_address];
  }

  function setWhitelist(address _address, bool _on) external onlyOwner {
    _whitelist[_address] = _on;

    emit Whitelisted(_address, _on);
  }

  function disableWhitelist(bool disable) external onlyOwner {
    _disable = disable;
    if (disable) {
      emit DisableWhitelist();
    } else {
      emit EnableWhitelist();
    }
  }
}

contract ERC20Locker is ReentrancyGuard, Whitelist {
  uint256 public fiveYears = 5 * 365 * 24 * 60 * 60;
  struct LPLock {
    uint256 amount;
    uint256 endLockTime;
  }

  mapping(address => mapping(address => LPLock)) public userLpLockInfo;
  mapping(address => address[]) public userLps;

  constructor() public {}

  function lockErc20(
    address lp,
    uint256 _amount,
    uint256 _endLockTime
  ) public nonReentrant onlyWhitelisted {
    if (userLpLockInfo[msg.sender][lp].endLockTime == 0) {
      require(_endLockTime > block.timestamp, "endLockTime wrong");
      require(
        _endLockTime < block.timestamp + fiveYears,
        "max time is 5 years"
      );
      userLpLockInfo[msg.sender][lp].endLockTime = _endLockTime;
    } else {
      require(
        _endLockTime > userLpLockInfo[msg.sender][lp].endLockTime,
        "endLockTime incorrect"
      );
      require(
        _endLockTime < block.timestamp + fiveYears,
        "max time is 5 years"
      );
      userLpLockInfo[msg.sender][lp].endLockTime = _endLockTime;
    }
    uint256 beforeBalance = IERC20(lp).balanceOf(address(this));
    if (_amount == 0) {
      _amount = IERC20(lp).balanceOf(msg.sender);
    }
    IERC20(lp).transferFrom(msg.sender, address(this), _amount);
    uint256 afterBalance = IERC20(lp).balanceOf(address(this));
    require(
      _amount >= afterBalance - beforeBalance,
      "There are more during transfer"
    );
    userLpLockInfo[msg.sender][lp].amount += afterBalance - beforeBalance;
    userLps[msg.sender].push(lp);
  }

  function withdraw(address lp, uint256 _amount)
    public
    nonReentrant
    onlyWhitelisted
  {
    require(
      block.timestamp > userLpLockInfo[msg.sender][lp].endLockTime,
      "time not arrived"
    );
    require(userLpLockInfo[msg.sender][lp].amount > 0, "your balance is 0");
    if (_amount == 0) _amount = userLpLockInfo[msg.sender][lp].amount;
    require(_amount <= userLpLockInfo[msg.sender][lp].amount, "exceed balance");
    if (_amount == userLpLockInfo[msg.sender][lp].amount)
      userLpLockInfo[msg.sender][lp].endLockTime = 0;
    userLpLockInfo[msg.sender][lp].amount -= _amount;
    IERC20(lp).transfer(msg.sender, _amount);
  }

  function rescueWrongTokens(address payable _recipient) public onlyOwner {
    _recipient.transfer(address(this).balance);
  }

  receive() external payable {}
}