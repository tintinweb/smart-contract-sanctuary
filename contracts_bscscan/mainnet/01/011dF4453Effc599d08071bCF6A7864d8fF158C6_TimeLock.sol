/**
 *Submitted for verification at BscScan.com on 2021-10-20
*/

// Dependency file: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

// pragma solidity ^0.8.0;

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


// Root file: contracts/operators/TimeLock.sol

pragma solidity >=0.8.4 <0.9.0;

// import '/Users/chiro/GitHub/infrastructure/node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract TimeLock {
  address private immutable _owner;

  address private immutable _beneficiary;

  uint256 private immutable _timelock;

  IERC20 private immutable _token;

  event StartTimeLock(address indexed beneficiary, address indexed token, uint256 indexed timelock);

  modifier onlyBeneficiary() {
    require(msg.sender == _beneficiary);
    _;
  }

  modifier onlyOwner() {
    require(msg.sender == _owner);
    _;
  }

  constructor(
    address beneficiary_,
    address token_,
    uint256 ifoTime_
  ) {
    _owner = msg.sender;
    _beneficiary = beneficiary_;
    _timelock = ifoTime_ + 1 hours + 5 minutes;
    _token = IERC20(token_);
  }

  // Beneficiary could able to withdraw any time after the time lock passed
  function withdraw() external onlyBeneficiary {
    require(block.timestamp > _timelock);
    _token.transfer(_beneficiary, _token.balanceOf(address(this)));
  }

  // Owner could able to help beneficiary to withdraw regardless the time lock
  // This could resolve the glitch between blockchain time and epoch time
  function helpWithdraw() external onlyOwner {
    _token.transfer(_beneficiary, _token.balanceOf(address(this)));
  }

  function getBlockchainTime() public view returns (uint256, uint256) {
    return (block.timestamp, _timelock);
  }
}