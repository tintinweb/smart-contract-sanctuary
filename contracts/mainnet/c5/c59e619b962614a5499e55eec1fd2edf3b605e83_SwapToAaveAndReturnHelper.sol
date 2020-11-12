// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;


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

interface ILendToAaveMigrator {
  function migrationStarted() external view returns (bool);

  function LEND() external view returns (IERC20);

  function AAVE() external view returns (IERC20);

  function migrateFromLEND(uint256 amount) external;
}


/**
 * @title SwapToAaveAndReturnHelper
 * @notice Swaps LEND to AAVE and sends the AAVE balance to the configured `RECEIVER`
 * @author Aave
 **/
contract SwapToAaveAndReturnHelper {
  address public immutable RECEIVER;
  ILendToAaveMigrator public immutable MIGRATOR;

  constructor(ILendToAaveMigrator migrator, address receiver) public {
    RECEIVER = receiver;
    MIGRATOR = migrator;
  }

  /**
   * @dev Swap the whole LEND balance of this contract, migrates to AAVE and sends to `RECEIVER`
   **/
  function swapAndReturn() public {
    IERC20 lend = MIGRATOR.LEND();
    IERC20 aave = MIGRATOR.AAVE();
    uint256 lendBalance = lend.balanceOf(address(this));

    lend.approve(address(MIGRATOR), lendBalance);
    MIGRATOR.migrateFromLEND(lendBalance);
    aave.transfer(RECEIVER, aave.balanceOf(address(this)));
  }

  /**
   * @dev Rescue any token sent to this contract, only callable by `RECEIVER`
   **/
  function rescueToken(IERC20 token) public {
    require(msg.sender == RECEIVER, 'ONLY_BY_RECEIVER');

    token.transfer(RECEIVER, token.balanceOf(address(this)));
  }
}