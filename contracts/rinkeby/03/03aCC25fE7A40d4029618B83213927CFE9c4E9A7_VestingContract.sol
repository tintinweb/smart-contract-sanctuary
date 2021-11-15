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

pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/*
 This Contract allows for quadratic vesting of a single ERC20 token starting at a hardcoded Timestamp for a hardcoded duration.
 the amount of the balance a user can retrieve is linearly dependent on 
 the fraction of the duration that has already passed since startTime squared.
 => retrievableAmount = (timePassed/Duration)^2 * totalAmount
*/
contract VestingContract {

  IERC20 private token;
  uint256 public startTime;
  uint256 public duration;
  uint256 constant private dec = 10**18;
  mapping(address => uint256) private totalDeposit;
  mapping(address => uint256) private drainedAmount;

  constructor(address _token, uint256 _durationInDays, uint256 startInDays) {
    startTime = block.timestamp + startInDays * 3600;
    duration = _durationInDays*3600;
    token = IERC20(_token);
  }

  function depositFor(address _recipient, uint256 _amount) external {
    require(token.transferFrom(msg.sender, address(this), _amount*dec), "transfer failed");
    totalDeposit[_recipient] += _amount*dec;
  }

  function retrieve() external {
    uint256 amount = getRetrievableAmount(msg.sender);
    require(amount != 0, 'nothing to retrieve');
    drainedAmount[msg.sender] += amount;
    token.transfer(msg.sender, amount);
    //sanity check
    assert(drainedAmount[msg.sender] <= totalDeposit[msg.sender]);
  }

    // 1e8 => 100%; 1e7 => 10%; 1e6 => 1%;
    // if startTime is not reached return 0
    // if the duration is over return 1e10
  function getPercentage() public view returns(uint256) {
    if(block.timestamp < startTime){
      return 0;
    }else if(startTime + duration > block.timestamp){
      return (1e4 * (block.timestamp - startTime) / duration)**2;
    }else{
      return 1e8;
    }
  }

  function getRetrievableAmount(address _account) public view returns(uint256){
    return (getPercentage() * totalDeposit[_account] / 1e8) - drainedAmount[_account];
  }

  function getTotalBalance(address _account) external view returns(uint256){
    return (totalDeposit[_account] - drainedAmount[_account])/dec;
  }
}

