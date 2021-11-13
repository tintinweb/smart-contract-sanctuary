// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IAutofarmV2_CrossChain.sol";
import "../../interfaces/IAutofarmDeposit.sol";

/**
 * @title AutofarmDepositBridge
 * @author DeFi Basket
 *
 * @notice Deposits, withdraws and harvest rewards from AutofarmV2_CrossChain contract in Polygon.
 *
 * @dev This contract has 2 main functions:
 *
 * 1. Deposit in AutofarmV2_CrossChain (example: QUICK/ETH -> autofarm doesn't return a deposit token)
 * 2. Withdraw from AutofarmV2_CrossChain
 *
 */

contract AutofarmDepositBridge is IAutofarmDeposit {
    // Hardcoded to make less variables needed for the user to check (UI will help explain/debug it)
    address constant autofarmAddress = 0x89d065572136814230A55DdEeDDEC9DF34EB0B76;
    address constant wMaticAddress = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address constant pAutoAddress = 0x7f426F6Dc648e50464a0392E60E1BB465a67E9cf;

    /**
      * @notice Deposits into the Autofarm protocol.
      *
      * @dev Wraps the Autofarm deposit and generate the necessary events to communicate with DeFi Basket's UI and back-end.
      *
      * @param percentageIn Percentage of the balance of the asset that will be deposited
      */
    function deposit(uint256 poolId, uint256 percentageIn) external override {
        IAutofarmV2_CrossChain autofarm = IAutofarmV2_CrossChain(autofarmAddress);
        (IERC20 assetIn, , , , address vaultAddress) = autofarm.poolInfo(poolId);

        uint256 amountIn = assetIn.balanceOf(address(this)) * percentageIn / 100000;

        // Approve 0 first as a few ERC20 tokens are requiring this pattern.
        assetIn.approve(autofarmAddress, 0);
        assetIn.approve(autofarmAddress, amountIn);

        autofarm.deposit(poolId, amountIn);

        emit DEFIBASKET_AUTOFARM_DEPOSIT(vaultAddress, address(assetIn), amountIn);
    }

    /**
      * @notice Withdraws from the Autofarm protocol.
      *
      * @dev Wraps the Autofarm withdraw and generate the necessary events to communicate with DeFi Basket's UI and
      * back-end. A harvest is withdraw where percentageOut == 0.
      *
      * @param poolId Autofarm pool id
      * @param percentageOut Percentage of the balance of the asset that will be withdrawn
      */
    function withdraw(uint256 poolId, uint256 percentageOut) external override {
        IAutofarmV2_CrossChain autofarm = IAutofarmV2_CrossChain(autofarmAddress);
        (IERC20 assetOut, , , , address vaultAddress) = autofarm.poolInfo(poolId);

        uint256 wMaticBalance = IERC20(wMaticAddress).balanceOf(address(this));
        uint256 pAutoBalance = IERC20(pAutoAddress).balanceOf(address(this));

        uint256 amountOut = autofarm.stakedWantTokens(poolId, address(this)) * percentageOut / 100000;
        autofarm.withdraw(poolId, amountOut);

        uint256 wMaticReward = IERC20(wMaticAddress).balanceOf(address(this)) - wMaticBalance;
        uint256 pAutoReward = IERC20(pAutoAddress).balanceOf(address(this)) - pAutoBalance;

        emit DEFIBASKET_AUTOFARM_WITHDRAW(vaultAddress, address(assetOut), amountOut, wMaticReward, pAutoReward);
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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IAutofarmV2_CrossChain {
    struct PoolInfo {
        IERC20 want; // Address of the want token.
        uint256 allocPoint; // How many allocation points assigned to this pool. AUTO to distribute per block.
        uint256 lastRewardBlock; // Last block number that AUTO distribution occurs.
        uint256 accAUTOPerShare; // Accumulated AUTO per share, times 1e12. See below.
        address strat; // Strategy address that will auto compound want tokens
    }

    function poolInfo(uint i) external returns (IERC20, uint256, uint256, uint256, address);

    function deposit(uint256 _pid, uint256 _wantAmt) external;

    function withdraw(uint256 _pid, uint256 _wantAmt) external;

    function stakedWantTokens(uint256 _pid, address _user) external view returns (uint256);

    function poolLength() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

interface IAutofarmDeposit {
    event DEFIBASKET_AUTOFARM_DEPOSIT (
        address vaultAddress,
        address assetIn,
        uint256 amount
    );

    event DEFIBASKET_AUTOFARM_WITHDRAW (
        address vaultAddress,
        address assetOut,
        uint256 amount,
        uint256 wMaticReward,
        uint256 pAutoReward
    );

    function deposit(uint256 percentageIn, uint256 poolId) external;

    function withdraw(uint256 percentageOut, uint256 poolId) external;
}