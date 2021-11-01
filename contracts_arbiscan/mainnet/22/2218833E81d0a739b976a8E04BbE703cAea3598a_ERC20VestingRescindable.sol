/**
 *Submitted for verification at arbiscan.io on 2021-10-31
*/

pragma solidity ^0.8.0;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {

  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  )
    internal
  {
    // safeApprove should only be called when setting an initial allowance, 
    // or when resetting it to zero. To increase and decrease it, use 
    // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
    require((value == 0) || (token.allowance(msg.sender, spender) == 0));
    require(token.approve(spender, value));
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  )
    internal
  {
    uint256 newAllowance = token.allowance(address(this), spender) + value;
    require(token.approve(spender, newAllowance));
  }

  function safeDecreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  )
    internal
  {
    uint256 newAllowance = token.allowance(address(this), spender) - value;
    require(token.approve(spender, newAllowance));
  }
}



/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}


/**
 * @title TokenVesting
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme, with a cliff and vesting period.
 * 
 * Note: Deploy one Vesting contract per user
 *
 * Note you do not want to transfer tokens you have withdrawn back to this contract. This will
 * result in some fraction of your transferred tokens being locked up again.
 *
 * Updated from Code taken from OpenZeppelin/openzeppelin-solidity at commit 4115686b4f8c1abf29f1f855eb15308076159959.
 */
contract ERC20VestingRescindable is Ownable {
  using SafeERC20 for IERC20;

  event TokensReleased(address token, uint256 amount);

  // beneficiary of tokens after they are released
  address public _beneficiary;

  uint256 public _cliff;
  uint256 public _start;
  uint256 public _duration;

  mapping (address => uint256) private _released;
  /**
   * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
   * beneficiary, gradually in a linear fashion until start + duration. By then all
   * of the balance will have vested.
   * @param beneficiary_ address of the beneficiary to whom vested tokens are transferred
   * @param cliffDuration_ duration in seconds of the cliff in which tokens will begin to vest
   * @param duration_ duration in seconds of the period in which the tokens will vest
   */
  constructor(
    address beneficiary_,
    uint256 cliffDuration_,
    uint256 duration_
  )
  {
    require(beneficiary_ != address(0));
    require(cliffDuration_ <= duration_);
    require(duration_ > 0);
    

    _beneficiary = beneficiary_;
    _duration = duration_;
    _cliff = block.timestamp + cliffDuration_;
    _start = block.timestamp;
  }
  
   /**
   * @dev Rescind a vesting contract. If the owner of this contract wants to stop vesting they can do it with this function.
   * When called rescind sends the amount of tokens already vested to the beneficiary and sends the rest back to the owner. 
   * It also updates the _duration variable to reflect that vesting for this contract has ended. 
   * Because of this functions structure only a single ERC20 may be vested per contract.
   * @param token the address of the token to rescind
   */
  function rescind(IERC20 token) public onlyOwner {
      uint256 releasableNow = releasable(address(token));
      uint256 toRescind = token.balanceOf(address(this)) - releasableNow;
      token.safeTransfer(owner(), toRescind);
      _duration = block.timestamp - _start;//now _start + duration == block.timestamp
      token.safeTransfer(_beneficiary, releasableNow);
  }

  /**
   * @return the amount of the token released.
   */
  function released(address token) public view returns(uint256) {
    return _released[token];
  }

  /**
   * @return the amount of token that can be released at the current block timestamp.
   */
  function releasable(address token) public view returns(uint256) {
    return _releasableAmount(IERC20(token));
  }

  /**
   * @notice Transfers vested tokens to beneficiary.
   * @param token ERC20 token which is being vested
   */
  function release(IERC20 token) public {
    uint256 unreleased = _releasableAmount(token);

    require(unreleased > 0);
    address tokenAddress = address(token);
    _released[tokenAddress] = _released[tokenAddress] + unreleased;

    token.safeTransfer(_beneficiary, unreleased);

    emit TokensReleased(tokenAddress, unreleased);
  }

  /**
   * @dev Calculates the amount that has already vested but hasn't been released yet.
   * @param token ERC20 token which is being vested
   */
  function _releasableAmount(IERC20 token) private view returns (uint256) {
    return _vestedAmount(token) - _released[address(token)];
  }

  /**
   * @dev Calculates the amount that has already vested.
   * @param token ERC20 token which is being vested
   */
  function _vestedAmount(IERC20 token) private view returns (uint256) {
    uint256 currentBalance = token.balanceOf(address(this));
    uint256 totalBalance = currentBalance + _released[address(token)];

    if (block.timestamp < _cliff) {
      return 0;
    } else if (block.timestamp >= _start + _duration) {
      return totalBalance;
    } else {
      return (totalBalance * (block.timestamp - _start)) / _duration;
    }
  }
}