// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ILendingPool.sol";
import "./interfaces/IAaveIncentivesController.sol";
import "../../interfaces/IAaveV2Deposit.sol";

/**
 * @title AaveV2DepositBridge
 * @author DeFi Basket
 *
 * @notice Deposits, withdraws and harvest rewards from Aave's LendingPool contract in Polygon.
 *
 * @dev This contract has 2 main functions:
 *
 * 1. Deposit in Aave's LendingPool (example: DAI -> amDAI)
 * 2. Withdraw from Aave's LendingPool (example: amDAI -> DAI)
 *
 * Notice that we haven't implemented any kind of borrowing mechanisms, mostly because that would be nice to have
 * control mechanics to go along with it.
 *
 */

contract AaveV2DepositBridge is IAaveV2Deposit {

    address constant aaveLendingPoolAddress = 0x8dFf5E27EA6b7AC08EbFdf9eB090F32ee9a30fcf;
    address constant incentivesControllerAddress = 0x357D51124f59836DeD84c8a1730D72B749d8BC23;

    /**
      * @notice Deposits into the Aave protocol.
      *
      * @dev Wraps the Aave deposit and generate the necessary events to communicate with DeFi Basket's UI and back-end.
      *
      * @param assetIn Address of the asset to be deposited into the Aave protocol
      * @param percentageIn Percentage of the balance of the asset that will be deposited
      */
    function deposit(address assetIn, uint256 percentageIn) external override {
        ILendingPool _aaveLendingPool = ILendingPool(aaveLendingPoolAddress);

        uint256 amount = IERC20(assetIn).balanceOf(address(this)) * percentageIn / 100000;

        // Approve 0 first as a few ERC20 tokens are requiring this pattern.
        IERC20(assetIn).approve(aaveLendingPoolAddress, 0);
        IERC20(assetIn).approve(aaveLendingPoolAddress, amount);

        _aaveLendingPool.deposit(assetIn, amount, address(this), 0);

        address assetOut = _aaveLendingPool.getReserveData(assetIn).aTokenAddress;

        emit DEFIBASKET_AAVEV2_DEPOSIT(assetOut, amount);
    }

    /**
      * @notice Withdraws from the Aave protocol.
      *
      * @dev Wraps the Aave withdrawal and generates the necessary events to communicate with DeFi Basket's UI and back-end.
      * To perform a harvest invoke withdraw with percentageOut set to 0.
      *
      * @param assetOut Address of the asset to be withdrawn from the Aave protocol
      * @param percentageOut Percentage of the balance of the asset that will be withdrawn
      */
    function withdraw(address assetOut, uint256 percentageOut) external override {
        IAaveIncentivesController distributor = IAaveIncentivesController(incentivesControllerAddress);
        ILendingPool _aaveLendingPool = ILendingPool(aaveLendingPoolAddress);

        address assetIn = _aaveLendingPool.getReserveData(assetOut).aTokenAddress;
        uint256 amount = 0;

        if (percentageOut > 0) {
            amount = IERC20(assetIn).balanceOf(address(this)) * percentageOut / 100000;
            _aaveLendingPool.withdraw(assetOut, amount, address(this));
        }

        address[] memory assets = new address[](1);
        assets[0] = assetIn;

        uint256 amountToClaim = distributor.getRewardsBalance(assets, address(this));
        uint256 claimedReward = distributor.claimRewards(assets, amountToClaim, address(this));
        address claimedAsset = distributor.REWARD_TOKEN();

        emit DEFIBASKET_AAVEV2_WITHDRAW(assetIn, amount, claimedAsset, claimedReward);
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

import {DataTypes} from '../libraries/DataTypes.sol';

interface ILendingPool {
    function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

    function withdraw(address asset, uint256 amount, address to) external returns (uint256);

    function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

interface IAaveIncentivesController {
    function getRewardsBalance(address[] calldata assets, address user) external view returns (uint256);

    function claimRewards(
        address[] calldata assets,
        uint256 amount,
        address to
    ) external returns (uint256);

    function REWARD_TOKEN() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

interface IAaveV2Deposit {
    event DEFIBASKET_AAVEV2_DEPOSIT (
        address assetOut,
        uint256 amount
    );

    event DEFIBASKET_AAVEV2_WITHDRAW (
        address assetIn,
        uint256 amount,
        address rewardAsset,
        uint256 rewardAmount
    );

    function deposit(address assetIn, uint256 percentageIn) external;

    function withdraw(address assetOut, uint256 percentageOut) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

library DataTypes {
    // refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
    struct ReserveData {
        //stores the reserve configuration
        ReserveConfigurationMap configuration;
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex;
        //variable borrow index. Expressed in ray
        uint128 variableBorrowIndex;
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate;
        //the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate;
        //the current stable borrow rate. Expressed in ray
        uint128 currentStableBorrowRate;
        uint40 lastUpdateTimestamp;
        //tokens addresses
        address aTokenAddress;
        address stableDebtTokenAddress;
        address variableDebtTokenAddress;
        //address of the interest rate strategy
        address interestRateStrategyAddress;
        //the id of the reserve. Represents the position in the list of the active reserves
        uint8 id;
    }

    struct ReserveConfigurationMap {
        //bit 0-15: LTV
        //bit 16-31: Liq. threshold
        //bit 32-47: Liq. bonus
        //bit 48-55: Decimals
        //bit 56: Reserve is active
        //bit 57: reserve is frozen
        //bit 58: borrowing is enabled
        //bit 59: stable rate borrowing enabled
        //bit 60-63: reserved
        //bit 64-79: reserve factor
        uint256 data;
    }

    struct UserConfigurationMap {
        uint256 data;
    }

    enum InterestRateMode {NONE, STABLE, VARIABLE}
}