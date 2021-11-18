// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import './interfaces/IGovernanceStrategy.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/**
 * @title Governance Strategy contract
 * @dev Smart contract containing logic to measure users' relative power to propose and vote.
 * User Power = User Power from Lotto Token + User Power from Game Lotto Token.
 **/
contract GovernanceStrategy is IGovernanceStrategy {
  address public LOTTO;
  address public GAME_LOTTO;

  /**
   * @dev Constructor, register tokens used for Power.
   * @param lotto The address of the Lotto Token contract.
   * @param gLotto The address of the gLotto Token Contract
   **/
  constructor(address lotto, address gLotto){
    LOTTO = lotto;
    GAME_LOTTO = gLotto;
  }

  /**
   * @dev Returns the total supply of Proposition Tokens Available for Governance
   * Voting supply will be equal Lotto supply. Cause the supply of Game lotto will be equal 
   * to the locked in the staking contract lotto tokens 
   * @return total supply 
   **/
  function getTotalVotingSupply() public view override returns (uint256) {
    return IERC20(LOTTO).totalSupply();
  }

  /**
   * @dev Returns the Vote Power of a user.
   * @param user Address of the user.
   * @return Vote number
   **/
  function getVotingPower(address user)
    public
    view
    override
    returns (uint256)
  {
    return  IERC20(LOTTO).balanceOf(user) + IERC20(GAME_LOTTO).balanceOf(user);
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;
pragma abicoder v2;

interface IGovernanceStrategy {
  /**
   * @dev Returns the total supply of Outstanding Voting Tokens 
   * @return total supply at blockNumber
   **/
  function getTotalVotingSupply() external view returns (uint256);
  /**
   * @dev Returns the Vote Power of a user at a specific block number.
   * @param user Address of the user.
   * @return Vote number
   **/
  function getVotingPower(address user) external view returns (uint256);
}