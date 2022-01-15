// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.10;

import "../libraries/SafeERC20.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IERC20Metadata.sol";
import "../interfaces/ITreasury.sol";
import "./interfaces/ISwapRouter.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/LiquityInterfaces.sol";
import "../types/OlympusAccessControlled.sol";

/**
 *  Contract deploys reserves from treasury into the liquity stabilty pool, and those rewards
 *  are then paid out to the staking contract.  See harvest() function for more details.
 */

contract LUSDAllocator is OlympusAccessControlled {
    /* ======== DEPENDENCIES ======== */

    using SafeERC20 for IERC20;
    using SafeERC20 for IWETH;

    event Deposit(address indexed dst, uint256 amount);

    /* ======== STATE VARIABLES ======== */
    IStabilityPool immutable lusdStabilityPool;
    ILQTYStaking immutable lqtyStaking;
    IWETH immutable weth; // WETH address (0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2)
    ISwapRouter immutable swapRouter;
    ITreasury public treasury; // Olympus Treasury

    uint256 public constant FEE_PRECISION = 1e6;
    uint256 public constant POOL_FEE_MAX = 10000;
    /**
     * @notice The target percent of eth to swap to LUSD at uniswap.  divide by 1e6 to get actual value.
     * Examples:
     * 500000 => 500000 / 1e6 = 0.50 = 50%
     * 330000 => 330000 / 1e6 = 0.33 = 33%
     */
    uint256 public ethToLUSDRatio = 330000; // 33% of ETH to LUSD
    /**
     * @notice poolFee parameter for uniswap swaprouter, divide by 1e6 to get the actual value.  See https://docs.uniswap.org/protocol/guides/swaps/multihop-swaps#calling-the-function-1
     * Maximum allowed value is 10000 (1%)
     * Examples:
     * poolFee =  3000 =>  3000 / 1e6 = 0.003 = 0.3%
     * poolFee = 10000 => 10000 / 1e6 =  0.01 = 1.0%
     */
    uint256 public poolFee = 3000; // Init the uniswap pool fee to 0.3%

    address public hopTokenAddress; //Initially DAI, could potentially be USDC

    // TODO(zx): I don't think we care about front-end because we're our own frontend.
    address public frontEndAddress; // frontEndAddress for potential liquity rewards
    address public lusdTokenAddress; // LUSD Address (0x5f98805A4E8be255a32880FDeC7F6728C6568bA0)
    address public lqtyTokenAddress; // LQTY Address (0x6DEA81C8171D0bA574754EF6F8b412F2Ed88c54D)  from https://github.com/liquity/dev/blob/a12f8b737d765bfee6e1bfcf8bf7ef155c814e1e/packages/contracts/mainnetDeployment/realDeploymentOutput/output14.txt#L61

    uint256 public totalValueDeployed; // total RFV deployed into lending pool
    uint256 public totalAmountDeployed; // Total amount of tokens deployed

    /* ======== CONSTRUCTOR ======== */

    constructor(
        address _authority,
        address _treasury,
        address _lusdTokenAddress,
        address _lqtyTokenAddress,
        address _stabilityPool,
        address _lqtyStaking,
        address _frontEndAddress,
        address _wethAddress,
        address _hopTokenAddress,
        address _uniswapV3Router
    ) OlympusAccessControlled(IOlympusAuthority(_authority)) {
        treasury = ITreasury(_treasury);
        lusdTokenAddress = _lusdTokenAddress;
        lqtyTokenAddress = _lqtyTokenAddress;
        lusdStabilityPool = IStabilityPool(_stabilityPool);
        lqtyStaking = ILQTYStaking(_lqtyStaking);
        frontEndAddress = _frontEndAddress; // address can be 0
        weth = IWETH(_wethAddress);
        hopTokenAddress = _hopTokenAddress; // address can be 0
        swapRouter = ISwapRouter(_uniswapV3Router);

        // infinite approve to save gas 
        weth.safeApprove(address(treasury), type(uint256).max);
        weth.safeApprove(address(swapRouter), type(uint256).max);
        IERC20(lusdTokenAddress).safeApprove(address(lusdStabilityPool), type(uint256).max);
        IERC20(lusdTokenAddress).safeApprove(address(treasury), type(uint256).max);
        IERC20(lqtyTokenAddress).safeApprove(address(treasury), type(uint256).max);
    }

    /**
        StabilityPool::withdrawFromSP() and LQTYStaking::stake() will send ETH here, so capture and emit the event
     */
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    /* ======== CONFIGURE FUNCTIONS for Guardian only ======== */
    function setEthToLUSDRatio(uint256 _ethToLUSDRatio) external onlyGuardian {
        require(_ethToLUSDRatio <= FEE_PRECISION, "Value must be between 0 and 1e6");
        ethToLUSDRatio = _ethToLUSDRatio;
    }

    function setPoolFee(uint256 _poolFee) external onlyGuardian {
        require(_poolFee <= POOL_FEE_MAX, "Value must be between 0 and 10000");
        poolFee = _poolFee;
    }

    function setHopTokenAddress(address _hopTokenAddress) external onlyGuardian {
        hopTokenAddress = _hopTokenAddress;
    }

    /**
     *  @notice setsFrontEndAddress for Stability pool rewards
     *  @param _frontEndAddress address
     */
    function setFrontEndAddress(address _frontEndAddress) external onlyGuardian {
        frontEndAddress = _frontEndAddress;
    }

    function updateTreasury() public onlyGuardian {
        require(authority.vault() != address(0), "Zero address: Vault");
        require(address(authority.vault()) != address(treasury), "No change");
        treasury = ITreasury(authority.vault());
    }

    /* ======== OPEN FUNCTIONS ======== */

    /**
     *  @notice claims LQTY & ETH Rewards.   minETHLUSDRate minimum rate of when swapping ETH->LUSD.  e.g. 3500 means we swap at a rate of 1 ETH for a minimum 3500 LUSD
     
        1.  Harvest from LUSD StabilityPool to get ETH+LQTY rewards
        2.  Stake LQTY rewards from #1.  This txn will also give out any outstanding ETH+LUSD rewards from prior staking
        3.  If we have eth, convert to weth, then swap a percentage of it to LUSD.  If swap successul then send all remaining WETH to treasury
        4.  Deposit LUSD from #2 and potentially #3 into StabilityPool
     */
    function harvest(uint256 minETHLUSDRate) public onlyGuardian returns (bool) {
        uint256 stabilityPoolEthRewards = getETHRewards();
        uint256 stabilityPoolLqtyRewards = getLQTYRewards();

        if (stabilityPoolEthRewards == 0 && stabilityPoolLqtyRewards == 0) {
            return false;
        }
        // 1.  Harvest from LUSD StabilityPool to get ETH+LQTY rewards
        lusdStabilityPool.withdrawFromSP(0); //Passing 0 b/c we don't want to withdraw from the pool but harvest - see https://discord.com/channels/700620821198143498/818895484956835912/908031137010581594

        // 2.  Stake LQTY rewards from #1.  This txn will also give out any outstanding ETH+LUSD rewards from prior staking
        uint256 balanceLqty = IERC20(lqtyTokenAddress).balanceOf(address(this)); // LQTY balance received from stability pool
        if (balanceLqty > 0) {
            //Stake
            lqtyStaking.stake(balanceLqty); //Stake LQTY, also receives any prior ETH+LUSD rewards from prior staking
        }

        // 3.  If we have eth, convert to weth, then swap a percentage of it to LUSD.  If swap successul then send all remaining WETH to treasury
        uint256 ethBalance = address(this).balance; // Use total balance in case we have leftover from a prior failed attempt
        bool swappedLUSDSuccessfully;
        if (ethBalance > 0) {
            // Wrap ETH to WETH
            weth.deposit{value: ethBalance}();

            uint256 wethBalance = weth.balanceOf(address(this)); //Base off of WETH balance in case we have leftover from a prior failed attempt
            if (ethToLUSDRatio > 0) {
                uint256 amountWethToSwap = (wethBalance * ethToLUSDRatio) / FEE_PRECISION;                

                uint256 amountLUSDMin = amountWethToSwap * minETHLUSDRate; //WETH and LUSD is 18 decimals

                // From https://docs.uniswap.org/protocol/guides/swaps/multihop-swaps#calling-the-function-1
                // Multiple pool swaps are encoded through bytes called a `path`. A path is a sequence of token addresses and poolFees that define the pools used in the swaps.
                // The format for pool encoding is (tokenIn, fee, tokenOut/tokenIn, fee, tokenOut) where tokenIn/tokenOut parameter is the shared token across the pools.
                // Since we are swapping WETH to DAI and then DAI to LUSD the path encoding is (WETH, 0.3%, DAI, 0.3%, LUSD).
                ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
                    path: abi.encodePacked(address(weth), poolFee, hopTokenAddress, poolFee, lusdTokenAddress),
                    recipient: address(this), //Send LUSD here
                    deadline: block.timestamp + 25, //25 blocks, at 12 seconds per block is 5 minutes
                    amountIn: amountWethToSwap,
                    amountOutMinimum: amountLUSDMin
                });

                // Executes the swap
                if (swapRouter.exactInput(params) > 0) {
                    swappedLUSDSuccessfully = true;
                }
            }
        }
        if (ethToLUSDRatio == 0 || swappedLUSDSuccessfully) {
            // If swap was successful (or if percent to swap is 0), send the remaining WETH to the treasury.  Crucial check otherwise we'd send all our WETH to the treasury and not respect our desired percentage

            // Get updated balance, send to treasury
            uint256 wethBalance = weth.balanceOf(address(this));
            if (wethBalance > 0) {
                // transfer WETH to treasury                
                weth.safeTransfer(address(treasury), wethBalance);
            }
        }

        // 4.  Deposit LUSD from #2 and potentially #3 into StabilityPool
        uint256 lusdBalance = IERC20(lusdTokenAddress).balanceOf(address(this));
        if (lusdBalance > 0) {
            _depositLUSD(lusdBalance);
        }

        return true;
    }

    /* ======== POLICY FUNCTIONS ======== */

    /**
     *  @notice withdraws asset from treasury, deposits asset into stability pool
     *  @param amount uint
     */
    function deposit(uint256 amount) external onlyGuardian {
        treasury.manage(lusdTokenAddress, amount); // retrieve amount of asset from treasury

        _depositLUSD(amount);
    }

    /**
     *  @notice withdraws from stability pool, and deposits asset into treasury
     *  @param token address
     *  @param amount uint
     */
    function withdraw(address token, uint256 amount) external onlyGuardian {
        require(
            token == lusdTokenAddress || token == lqtyTokenAddress,
            "token address does not match LUSD nor LQTY token"
        );

        if (token == lusdTokenAddress) {
            lusdStabilityPool.withdrawFromSP(amount); // withdraw from SP

            uint256 balance = IERC20(token).balanceOf(address(this)); // balance of asset received from stability pool
            uint256 value = _tokenValue(token, balance); // treasury RFV calculator

            _accountingFor(balance, value, false); // account for withdrawal
            
            treasury.deposit(balance, token, value); // deposit using value as profit so no OHM is minted
        } else {
            lqtyStaking.unstake(amount);

            uint256 balance = IERC20(token).balanceOf(address(this)); // balance of asset received from stability pool
            IERC20(token).safeTransfer(address(treasury), balance);
        }
    }

    /* ======== INTERNAL FUNCTIONS ======== */

    function _depositLUSD(uint256 amount) internal {        
        lusdStabilityPool.provideToSP(amount, frontEndAddress); //s either a front-end address OR 0x0

        uint256 value = _tokenValue(lusdTokenAddress, amount); // treasury RFV calculator
        _accountingFor(amount, value, true); // account for deposit
    }

    /**
     *  @notice accounting of deposits/withdrawals of assets
     *  @param amount uint
     *  @param value uint
     *  @param add bool
     */
    function _accountingFor(
        uint256 amount,
        uint256 value,
        bool add
    ) internal {
        if (add) {
            totalAmountDeployed = totalAmountDeployed + amount;
            totalValueDeployed = totalValueDeployed + value; // track total value allocated into pools
        } else {
            // track total value allocated into pools
            if (amount < totalAmountDeployed) {
                totalAmountDeployed = totalAmountDeployed - amount;
            } else {
                totalAmountDeployed = 0;
            }

            if (value < totalValueDeployed) {
                totalValueDeployed = totalValueDeployed - value;
            } else {
                totalValueDeployed = 0;
            }
        }
    }

    /**
    Helper method copying OlympusTreasury::_tokenValue(), whose name was 'valueOf()' in v1 
    Implemented here so we don't have to upgrade contract later
     */
    function _tokenValue(address _token, uint256 _amount) internal view returns (uint256 value_) {
        value_ = (_amount * (10**9)) / (10**IERC20Metadata(_token).decimals());
        return value_;
    }

    /* ======== VIEW FUNCTIONS ======== */

    /**
     *  @notice get ETH rewards from SP
     *  @return uint
     */
    function getETHRewards() public view returns (uint256) {
        return lusdStabilityPool.getDepositorETHGain(address(this));
    }

    /**
     *  @notice get LQTY rewards from SP
     *  @return uint
     */
    function getLQTYRewards() public view returns (uint256) {
        return lusdStabilityPool.getDepositorLQTYGain(address(this));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

import {IERC20} from "../interfaces/IERC20.sol";

/// @notice Safe IERC20 and ETH transfer library that safely handles missing return values.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/libraries/TransferHelper.sol)
/// Taken from Solmate
library SafeERC20 {
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED");
    }

    function safeApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.approve.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "APPROVE_FAILED");
    }

    function safeTransferETH(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}(new bytes(0));

        require(success, "ETH_TRANSFER_FAILED");
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

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
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

import "./IERC20.sol";

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface ITreasury {
    function deposit(
        uint256 _amount,
        address _token,
        uint256 _profit
    ) external returns (uint256);

    function withdraw(uint256 _amount, address _token) external;

    function tokenValue(address _token, uint256 _amount) external view returns (uint256 value_);

    function mint(address _recipient, uint256 _amount) external;

    function manage(address _token, uint256 _amount) external;

    function incurDebt(uint256 amount_, address token_) external;

    function repayDebtWithReserve(uint256 amount_, address token_) external;

    function excessReserves() external view returns (uint256);

    function baseSupply() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter  {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

import "../../interfaces/IERC20.sol";
interface IWETH is IERC20 {

    function deposit() external payable;

    function withdraw(uint) external;

}

//https://etherscan.io/address/0x66017D22b0f8556afDd19FC67041899Eb65a21bb
/*
 * The Stability Pool holds LUSD tokens deposited by Stability Pool depositors.
 *
 * When a trove is liquidated, then depending on system conditions, some of its LUSD debt gets offset with
 * LUSD in the Stability Pool:  that is, the offset debt evaporates, and an equal amount of LUSD tokens in the Stability Pool is burned.
 *
 * Thus, a liquidation causes each depositor to receive a LUSD loss, in proportion to their deposit as a share of total deposits.
 * They also receive an ETH gain, as the ETH collateral of the liquidated trove is distributed among Stability depositors,
 * in the same proportion.
 *
 * When a liquidation occurs, it depletes every deposit by the same fraction: for example, a liquidation that depletes 40%
 * of the total LUSD in the Stability Pool, depletes 40% of each deposit.
 *
 * A deposit that has experienced a series of liquidations is termed a "compounded deposit": each liquidation depletes the deposit,
 * multiplying it by some factor in range ]0,1[
 *
 * Please see the implementation spec in the proof document, which closely follows on from the compounded deposit / ETH gain derivations:
 * https://github.com/liquity/liquity/blob/master/papers/Scalable_Reward_Distribution_with_Compounding_Stakes.pdf
 *
 * --- LQTY ISSUANCE TO STABILITY POOL DEPOSITORS ---
 *
 * An LQTY issuance event occurs at every deposit operation, and every liquidation.
 *
 * Each deposit is tagged with the address of the front end through which it was made.
 *
 * All deposits earn a share of the issued LQTY in proportion to the deposit as a share of total deposits. The LQTY earned
 * by a given deposit, is split between the depositor and the front end through which the deposit was made, based on the front end's kickbackRate.
 *
 * Please see the system Readme for an overview:
 * https://github.com/liquity/dev/blob/main/README.md#lqty-issuance-to-stability-providers
 */
interface IStabilityPool {
    // --- Functions ---
    /*
     * Initial checks:
     * - Frontend is registered or zero address
     * - Sender is not a registered frontend
     * - _amount is not zero
     * ---
     * - Triggers a LQTY issuance, based on time passed since the last issuance. The LQTY issuance is shared between *all* depositors and front ends
     * - Tags the deposit with the provided front end tag param, if it's a new deposit
     * - Sends depositor's accumulated gains (LQTY, ETH) to depositor
     * - Sends the tagged front end's accumulated LQTY gains to the tagged front end
     * - Increases deposit and tagged front end's stake, and takes new snapshots for each.
     */
    function provideToSP(uint256 _amount, address _frontEndTag) external;

    /*
     * Initial checks:
     * - _amount is zero or there are no under collateralized troves left in the system
     * - User has a non zero deposit
     * ---
     * - Triggers a LQTY issuance, based on time passed since the last issuance. The LQTY issuance is shared between *all* depositors and front ends
     * - Removes the deposit's front end tag if it is a full withdrawal
     * - Sends all depositor's accumulated gains (LQTY, ETH) to depositor
     * - Sends the tagged front end's accumulated LQTY gains to the tagged front end
     * - Decreases deposit and tagged front end's stake, and takes new snapshots for each.
     *
     * If _amount > userDeposit, the user withdraws all of their compounded deposit.
     */
    function withdrawFromSP(uint256 _amount) external;

    /*
     * Initial checks:
     * - User has a non zero deposit
     * - User has an open trove
     * - User has some ETH gain
     * ---
     * - Triggers a LQTY issuance, based on time passed since the last issuance. The LQTY issuance is shared between *all* depositors and front ends
     * - Sends all depositor's LQTY gain to  depositor
     * - Sends all tagged front end's LQTY gain to the tagged front end
     * - Transfers the depositor's entire ETH gain from the Stability Pool to the caller's trove
     * - Leaves their compounded deposit in the Stability Pool
     * - Updates snapshots for deposit and tagged front end stake
     */
    function withdrawETHGainToTrove(address _upperHint, address _lowerHint) external;

    /*
     * Initial checks:
     * - Frontend (sender) not already registered
     * - User (sender) has no deposit
     * - _kickbackRate is in the range [0, 100%]
     * ---
     * Front end makes a one-time selection of kickback rate upon registering
     */
    function registerFrontEnd(uint256 _kickbackRate) external;

    /*
     * Initial checks:
     * - Caller is TroveManager
     * ---
     * Cancels out the specified debt against the LUSD contained in the Stability Pool (as far as possible)
     * and transfers the Trove's ETH collateral from ActivePool to StabilityPool.
     * Only called by liquidation functions in the TroveManager.
     */
    function offset(uint256 _debt, uint256 _coll) external;

    /*
     * Returns the total amount of ETH held by the pool, accounted in an internal variable instead of `balance`,
     * to exclude edge cases like ETH received from a self-destruct.
     */
    function getETH() external view returns (uint256);

    /*
     * Returns LUSD held in the pool. Changes when users deposit/withdraw, and when Trove debt is offset.
     */
    function getTotalLUSDDeposits() external view returns (uint256);

    /*
     * Calculates the ETH gain earned by the deposit since its last snapshots were taken.
     */
    function getDepositorETHGain(address _depositor) external view returns (uint256);

    /*
     * Calculate the LQTY gain earned by a deposit since its last snapshots were taken.
     * If not tagged with a front end, the depositor gets a 100% cut of what their deposit earned.
     * Otherwise, their cut of the deposit's earnings is equal to the kickbackRate, set by the front end through
     * which they made their deposit.
     */
    function getDepositorLQTYGain(address _depositor) external view returns (uint256);

    /*
     * Return the LQTY gain earned by the front end.
     */
    function getFrontEndLQTYGain(address _frontEnd) external view returns (uint256);

    /*
     * Return the user's compounded deposit.
     */
    function getCompoundedLUSDDeposit(address _depositor) external view returns (uint256);

    /*
     * Return the front end's compounded stake.
     *
     * The front end's compounded stake is equal to the sum of its depositors' compounded deposits.
     */
    function getCompoundedFrontEndStake(address _frontEnd) external view returns (uint256);
}

//
interface ILQTYStaking {
    /*
        sends _LQTYAmount from the caller to the staking contract, and increases their stake.
        If the caller already has a non-zero stake, it pays out their accumulated ETH and LUSD gains from staking.
    */
    function stake(uint256 _LQTYamount) external;

    /**
        reduces the caller’s stake by _LQTYamount, up to a maximum of their entire stake. 
        It pays out their accumulated ETH and LUSD gains from staking.
    */
    function unstake(uint256 _LQTYamount) external;

    function getPendingETHGain(address _user) external view returns (uint256);

    function getPendingLUSDGain(address _user) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

import "../interfaces/IOlympusAuthority.sol";

abstract contract OlympusAccessControlled {

    /* ========== EVENTS ========== */

    event AuthorityUpdated(IOlympusAuthority indexed authority);

    string UNAUTHORIZED = "UNAUTHORIZED"; // save gas

    /* ========== STATE VARIABLES ========== */

    IOlympusAuthority public authority;


    /* ========== Constructor ========== */

    constructor(IOlympusAuthority _authority) {
        authority = _authority;
        emit AuthorityUpdated(_authority);
    }
    

    /* ========== MODIFIERS ========== */
    
    modifier onlyGovernor() {
        require(msg.sender == authority.governor(), UNAUTHORIZED);
        _;
    }
    
    modifier onlyGuardian() {
        require(msg.sender == authority.guardian(), UNAUTHORIZED);
        _;
    }
    
    modifier onlyPolicy() {
        require(msg.sender == authority.policy(), UNAUTHORIZED);
        _;
    }

    modifier onlyVault() {
        require(msg.sender == authority.vault(), UNAUTHORIZED);
        _;
    }
    
    /* ========== GOV ONLY ========== */
    
    function setAuthority(IOlympusAuthority _newAuthority) external onlyGovernor {
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IOlympusAuthority {
    /* ========== EVENTS ========== */

    event GovernorPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event GuardianPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event PolicyPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event VaultPushed(address indexed from, address indexed to, bool _effectiveImmediately);

    event GovernorPulled(address indexed from, address indexed to);
    event GuardianPulled(address indexed from, address indexed to);
    event PolicyPulled(address indexed from, address indexed to);
    event VaultPulled(address indexed from, address indexed to);

    /* ========== VIEW ========== */

    function governor() external view returns (address);

    function guardian() external view returns (address);

    function policy() external view returns (address);

    function vault() external view returns (address);
}