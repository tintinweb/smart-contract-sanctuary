// SPDX-License-Identifier: Unlicense

pragma solidity >=0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interface/ICoinDeed.sol";
import "../interface/ILendingPool.sol";
import "../interface/ICoinDeedAddressesProvider.sol";

library CoinDeedUtils {
    uint256 public constant BASE_DENOMINATOR = 10_000;

    function cancelCheck(
        ICoinDeed.DeedState state,
        ICoinDeed.ExecutionTime memory executionTime,
        ICoinDeed.DeedParameters memory deedParameters,
        uint256 totalSupply
    ) external view returns (bool) {
        if (
            state == ICoinDeed.DeedState.SETUP &&
            block.timestamp > executionTime.recruitingEndTimestamp
        )
        {
            return true;
        }
        else if (
            totalSupply < deedParameters.deedSize * deedParameters.minimumBuy / BASE_DENOMINATOR &&
            block.timestamp > executionTime.buyTimestamp
        )
        {
            return true;
        }
        else {
            return false;
        }
    }

    function withdrawStakeCheck(
        ICoinDeed.DeedState state,
        ICoinDeed.ExecutionTime memory executionTime,
        uint256 stake,
        bool isManager
    ) external view returns (bool) {
        require(
            state != ICoinDeed.DeedState.READY &&
            state != ICoinDeed.DeedState.OPEN,
            "Deed is not in correct state"
        );
        require(stake > 0, "No stake");
        require(
            state == ICoinDeed.DeedState.CLOSED ||
            !isManager,
            "Can not withdraw your stake."
        );
        require(
            state != ICoinDeed.DeedState.SETUP ||
            executionTime.recruitingEndTimestamp < block.timestamp,
            "Recruiting did not end."
        );
        return true;
    }


    function getClaimAmount(
        ICoinDeed.DeedState state,
        address tokenA,
        uint256 totalSupply,
        uint256 buyIn
    ) external view returns (uint256 claimAmount)
    {
        require(buyIn > 0, "No share.");
        uint256 balance;
        // Get balance. Assuming delegate call as a library function
        if (tokenA == address(0x00)) {
            balance = address(this).balance;
        }
        else {
            balance = IERC20(tokenA).balanceOf(address(this));
        }

        // Assign claim amount
        if (state == ICoinDeed.DeedState.CLOSED) {
            // buyer can claim tokenA in the same proportion as their buyins
            claimAmount = balance * buyIn / (totalSupply);

            // just a sanity check in case division rounds up
            if (claimAmount > balance) {
                claimAmount = balance;
            }
        } else {
            // buyer can claim tokenA back
            claimAmount = buyIn;
        }
        return claimAmount;
    }

    function getTotalTokenB(address addressProvider, address tokenB) external view returns (uint256 returnAmount, uint256 depositAmount) {
        ICoinDeedAddressesProvider coinDeedAddressesProvider = ICoinDeedAddressesProvider(addressProvider);
        ILendingPool lendingPool = ILendingPool(coinDeedAddressesProvider.lendingPool());
        if (lendingPool.poolInfo(tokenB).isCreated) {
            returnAmount = lendingPool.totalDepositBalance(tokenB, msg.sender);
            depositAmount = lendingPool.depositAmount(tokenB, msg.sender);
        } else {
            returnAmount = IERC20(tokenB).balanceOf(msg.sender);
        }
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

//SPDX-License-Identifier: Unlicense
/** @title Interface for CoinDeed
  * @author Bitus Labs
 **/
pragma solidity ^0.8.0;

interface ICoinDeed {


    enum DeedState {SETUP, READY, OPEN, CLOSED, CANCELED}

    /// @notice Class of all initial deed creation parameters.
    struct DeedParameters {
        uint256 deedSize;
        uint8 leverage;
        uint256 managementFee;
        uint256 minimumBuy;
    }

    struct Pair {address tokenA; address tokenB;}

    /// @notice Stores all the timestamps that must be checked prior to moving through deed phases.
    struct ExecutionTime {
        uint256 recruitingEndTimestamp;
        uint256 buyTimestamp;
        uint256 sellTimestamp;
    }

    /** @notice Risk mitigation can be triggered twice. *trigger* and *secondTrigger* are the percent drops that the collateral asset
      * can drop compared to the debt asset before the position is eligible for liquidation. The first mitigation is a partial
      * liquidation, liquidating just enough assets to return the position to the *leverage*. */
    struct RiskMitigation {
        uint256 trigger;
        uint256 secondTrigger;
        uint8 leverage;
    }

    /// @notice Stores all the parameters related to brokers
    struct BrokerConfig {
        bool allowed;
        uint256 minimumStaking;
    }


    ///  Reserve a wholesale to swap on execution time
    function reserveWholesale(uint256 wholesaleId) external;

    ///  Add stake by deed manager or brokers. If brokersEnabled for the deed anyone can call this function to be a broker
    function stake(uint256 amount) external;

    ///  Brokers can withdraw their stake
    function withdrawStake() external;

    ///  Edit Broker Config
    function editBrokerConfig(BrokerConfig memory brokerConfig) external;

    ///  Edit RiskMitigation
    function editRiskMitigation(RiskMitigation memory riskMitigation) external;

    ///  Edit ExecutionTime
    function editExecutionTime(ExecutionTime memory executionTime) external;

    ///  Edit DeedInfo
    function editBasicInfo(uint256 deedSize, uint8 leverage, uint256 managementFee, uint256 minimumBuy) external;

    ///  Returns the deed manager
    function manager() external view returns (address);

    ///  Edit all deed parameters. Use previous parameters if unchanged.
    function edit(DeedParameters memory deedParameters,
        ExecutionTime memory executionTime,
        RiskMitigation memory riskMitigation,
        BrokerConfig memory brokerConfig) external;

    /**  Initial swap for the deed to buy the tokens
      * @notice After validating the deed's eligibility to move to the OPEN phase,
      * the management fee is subtracted, and then the deed contract is loaned
      * enough of the buyin token to bring it to the specified leverage.
      * The deed then swaps the tokens into the collateral token and deposits
      * it into the lending pool to earn additional yield. The deed is now
      * in the open state.
      * @dev There is no economic incentive built in to call this function.
      * No safety check for swapping assets */
    function buy() external;

    /**  Sells the entire deed's collateral
      * @notice After validating that the sell execution time has passed,
      * withdraws all collateral from the lending pool, sells it for the debt token,
      * and repays the loan in full. This closes the deed.
      * @dev There is no economic incentive built in to call this function.
      * No safety check for swapping assets */
    function sell() external;

    ///  Cancels deed if it is in the setup or ready phase
    function cancel() external;

    ///  Buyers buys into the deed
    function buyIn(uint256 amount) external;

    ///  Buyers buys in from the deed with ETH
    function buyInEth() external payable;

    ///  Buyers claims their balance if the deed is completed.
    function claimBalance() external;

    /**  Executes risk mitigation
      * @notice Validates that the position is eligible for liquidation,
      * and then liquidates the appropriate amount of collateral depending on
      * whether risk mitigation has already been triggered.
      * If this is the second risk mitigation, closes the deed.
      * Allocates a liquidation bonus from the collateral to the caller. */
    function executeRiskMitigation() external;

    /**  Message sender exits the deed
      * @notice When the deed is open, this withdraws the buyer's share of collateral
      * and sells the entire amount. From this amount, repay the buyer's share of the debt
      * and return the rest to sender */
    function exitDeed(bool _payoff) payable external;
}

//SPDX-License-Identifier: MIT

import "../interface/IOracle.sol";

pragma solidity >=0.7.0;

interface ILendingPool {
    struct AccrueInterestVars {
        uint256 blockDelta;
        uint256 simpleInterestFactor;
        uint256 interestAccumulated;
        uint256 simpleInterestSupplyFactor;
        uint256 borrowIndexNew;
        uint256 totalBorrowNew;
        uint256 totalReservesNew;
        uint256 supplyIndexNew;
    }

    // Info of each pool.
    struct PoolInfo {
        uint256 totalBorrows;
        uint256 totalReserves;
        uint256 borrowIndex;
        uint256 supplyIndex;
        uint256 accrualBlockNumber;
        bool isCreated;
        uint256 decimals;
        uint256 sypplyIndexDebt;
        uint256 accTokenPerShare; // Accumulated DTokens per share, time 1e18. See below
    }

    // Info of each deed.
    struct DeedInfo {
        uint256 borrow;
        uint256 totalBorrow;
        uint256 borrowIndex;
        bool isValid;
    }

    struct UserAssetInfo {
        uint256 amount; // How many tokens the lender has provided
        uint256 supplyIndex;
    }

    event PoolAdded(address indexed token, uint256 decimals);
    event PoolUpdated(
        address indexed token,
        uint256 decimals,
        address oracle,
        uint256 oracleDecimals
    );
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Borrow(address indexed user, uint256 amount);
    event Repay(address indexed user, uint256 amount);
    event Collateral(address indexed user, uint256 amount);


    /**
  * @notice Event emitted when interest is accrued
  */
    event AccrueInterest(
        uint256 cashPrior,
        uint256 interestAccumulated,
        uint256 borrowIndex,
        uint256 totalBorrows,
        uint256 totalReserves,
        uint256 supplyIndex
    );

    function POOL_DECIMALS() external returns (uint256);

    function poolInfo(address) external view returns (PoolInfo memory);

    function userAssetInfo(address lender, address token) external view returns (UserAssetInfo memory);

    function depositAmount(address token, address lender) external view returns (uint256);

    // Stake tokens to Pool
    function deposit(address _tokenAddress, uint256 _amount) external payable;

    // Borrow
    function borrow(address _tokenAddress, uint256 _amount) external;

    function addNewDeed(address _address) external;

    function removeExpireDeed(address _address) external;
/*
    function getDtokenExchange(address _token, uint256 reward)
    external
    view
    returns (uint256);
*/
    // Withdraw tokens from STAKING.
    function withdraw(address _tokenAddress, uint256 _amount) external;

    function totalDepositBalance(address _token, address _deed)
    external
    view
    returns (uint256);

    function totalBorrowBalance(address _token, address _deed)
    external
    view
    returns (uint256);

    function pendingDToken(address _token, address _lender) external view returns (uint256);

    function repay(address _tokenAddress, uint256 _amount)
    external
    payable;

    function borrowIndex(address _token) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICoinDeedAddressesProvider {
    event FeedRegistryChanged(address feedRegistry);
    event SwapRouterChanged(address router);
    event LendingPoolChanged(address lendingPool);
    event CoinDeedFactoryChanged(address coinDeedFactory);
    event WholesaleFactoryChanged(address wholesaleFactory);
    event DeedTokenChanged(address deedToken);
    event CoinDeedDeployerChanged(address coinDeedDeployer);
    event TreasuryChanged(address treasury);
    event DaoChanged(address dao);

    function feedRegistry() external view returns (address);
    function swapRouter() external view returns (address);
    function lendingPool() external view returns (address);
    function coinDeedFactory() external view returns (address);
    function wholesaleFactory() external view returns (address);
    function deedToken() external view returns (address);
    function coinDeedDeployer() external view returns (address);
    function treasury() external view returns (address);
    function dao() external view returns (address);
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

interface IOracle {
    function decimals() external view returns (uint256);
    function latestAnswer() external view returns (int256);
    function latestTimestamp() external view returns (uint256);
    function latestRound() external view returns (uint256);
    function getAnswer(uint256 roundId) external view returns (int256);
    function getTimestamp(uint256 roundId) external view returns (uint256);

    event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);
    event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}