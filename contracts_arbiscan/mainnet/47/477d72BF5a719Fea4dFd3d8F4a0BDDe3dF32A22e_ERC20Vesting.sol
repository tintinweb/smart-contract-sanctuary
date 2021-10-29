/**
 *Submitted for verification at arbiscan.io on 2021-10-29
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
 * @title ERC20Vesting
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
contract ERC20Vesting {
  using SafeERC20 for IERC20;

  event TokensReleased(address token, uint256 amount);

  // beneficiary of tokens after they are released
  address public beneficiary;

  uint256 public cliff;
  uint256 public start;
  uint256 public duration;

  mapping (address => uint256) public released;
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
    
    beneficiary = beneficiary_;
    duration = duration_;
    cliff = block.timestamp + cliffDuration_;
    start = block.timestamp;
  }
  
   /**
   * @dev The current beneficiary is able to set the next beneficiary if they'd
   * like to renounce their share.
   * @param newBeneficiary the address of the new beneficiary
   */
  function setBeneficiary(address newBeneficiary) external {
    require(msg.sender == beneficiary, "Not beneficiary");
    beneficiary = newBeneficiary;
  }

  /**
   * @return the amount of token that can be released at the current block timestamp.
   */
  function releasable(address token) external view returns(uint256) {
    return _releasableAmount(IERC20(token));
  }

  /**
   * @notice Transfers vested tokens to beneficiary.
   * @param token ERC20 token which is being vested
   */
  function release(IERC20 token) external {
    uint256 unreleased = _releasableAmount(token);

    require(unreleased > 0);
    address tokenAddress = address(token);
    released[tokenAddress] = released[tokenAddress] + unreleased;

    token.safeTransfer(beneficiary, unreleased);

    emit TokensReleased(tokenAddress, unreleased);
  }

  /**
   * @dev Calculates the amount that has already vested but hasn't been released yet.
   * @param token ERC20 token which is being vested
   */
  function _releasableAmount(IERC20 token) private view returns (uint256) {
    return _vestedAmount(token) - released[address(token)];
  }

  /**
   * @dev Calculates the amount that has already vested.
   * @param token ERC20 token which is being vested
   */
  function _vestedAmount(IERC20 token) private view returns (uint256) {
    uint256 currentBalance = token.balanceOf(address(this));
    uint256 totalBalance = currentBalance + released[address(token)];

    if (block.timestamp < cliff) {
      return 0;
    } else if (block.timestamp >= start + duration) {
      return totalBalance;
    } else {
      return (totalBalance * (block.timestamp - start)) / duration;
    }
  }
}