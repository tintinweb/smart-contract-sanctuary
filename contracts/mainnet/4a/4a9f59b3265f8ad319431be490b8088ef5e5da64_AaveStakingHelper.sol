// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;


interface IStakedAaveImplWithInitialize {
  function initialize(
    address aaveGovernance,
    string calldata name,
    string calldata symbol,
    uint8 decimals
  ) external;

  function stake(address onBehalfOf, uint256 amount) external;

  function redeem(address to, uint256 amount) external;

  function cooldown() external;

  function claimRewards(address to, uint256 amount) external;

  function balanceOf(address user) external view returns (uint256);
}



/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 * From https://github.com/OpenZeppelin/openzeppelin-contracts
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

/**
 * @title interface EIP2612
 * @author Aave
 * @dev Generic interface for the EIP2612 permit function
 */
interface IEIP2612Token is IERC20 {
  /**
   * @dev implements the permit function as for https://github.com/ethereum/EIPs/blob/8a34d644aacf0f9f8f00815307fd7dd5da07655f/EIPS/eip-2612.md
   * @param owner the owner of the funds
   * @param spender the spender
   * @param value the amount
   * @param deadline the deadline timestamp, type(uint256).max for max deadline
   * @param v signature param
   * @param s signature param
   * @param r signature param
   */
  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external virtual;
}


/**
 * @title StakingHelper contract
 * @author Aave
 * @dev implements a staking function that allows staking through the EIP2612 capabilities of the AAVE token
 **/

contract AaveStakingHelper {
  IStakedAaveImplWithInitialize public immutable STAKE;
  IEIP2612Token public immutable AAVE;

  constructor(address stake, address aave) public {
    STAKE = IStakedAaveImplWithInitialize(stake);
    AAVE = IEIP2612Token(aave);
    //approves the stake to transfer uint256.max tokens from this contract
    //avoids approvals on every stake action
    IEIP2612Token(aave).approve(address(stake), type(uint256).max);
  }

  /**
   * @dev stakes on behalf of msg.sender using signed approval.
   * The function expects a valid signed message from the user, and executes a permit()
   * to approve the transfer. The helper then stakes on behalf of the user
   * @param amount the amount to stake
   * @param v signature param
   * @param r signature param
   * @param s signature param
   **/
  function stake(
    uint256 amount,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    AAVE.permit(msg.sender, address(this), amount, type(uint256).max, v, r, s);
    AAVE.transferFrom(msg.sender, address(this), amount);
    STAKE.stake(msg.sender, amount);
  }
}