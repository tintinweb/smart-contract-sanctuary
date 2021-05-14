/**
 *Submitted for verification at Etherscan.io on 2021-05-13
*/

// SPDX-License-Identifier:  AGPL-3.0-or-later // hevm: flattened sources of contracts/MapleGlobals.sol
pragma solidity =0.6.11 >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

////// lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol
/* pragma solidity >=0.6.0 <0.8.0; */

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

////// contracts/interfaces/IERC20Details.sol
/* pragma solidity 0.6.11; */

/* import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol"; */

interface IERC20Details is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint256);

}

////// contracts/interfaces/IOracle.sol
/* pragma solidity 0.6.11; */

interface IOracle {

    function priceFeed() external view returns (address);

    function globals() external view returns (address);

    function assetAddress() external view returns (address);

    function manualOverride() external view returns (bool);

    function manualPrice() external view returns (int256);

    function getLatestPrice() external view returns (int256);
    
    function changeAggregator(address) external;

    function getAssetAddress() external view returns (address);
    
    function getDenomination() external view returns (bytes32);
    
    function setManualPrice(int256) external;
    
    function setManualOverride(bool) external;

}

////// contracts/interfaces/ISubFactory.sol
/* pragma solidity 0.6.11; */

interface ISubFactory {

    function factoryType() external view returns (uint8);

}

////// lib/openzeppelin-contracts/contracts/math/SafeMath.sol
/* pragma solidity >=0.6.0 <0.8.0; */

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

////// contracts/MapleGlobals.sol
/* pragma solidity 0.6.11; */
/* pragma experimental ABIEncoderV2; */

/* import "lib/openzeppelin-contracts/contracts/math/SafeMath.sol"; */

/* import "./interfaces/IERC20Details.sol"; */
/* import "./interfaces/IOracle.sol"; */
/* import "./interfaces/ISubFactory.sol"; */

interface ICalc { function calcType() external view returns (uint8); }

/// @title MapleGlobals maintains a central source of parameters and allowlists for the Maple protocol.
contract MapleGlobals {

    using SafeMath for uint256;

    address public immutable mpl;         // The ERC-2222 Maple Token for the Maple protocol.

    address public pendingGovernor;       // The Governor that is declared for governorship transfer. Must be accepted for transfer to take effect.
    address public governor;              // The Governor responsible for management of global Maple variables.
    address public mapleTreasury;         // The MapleTreasury is the Treasury where all fees pass through for conversion, prior to distribution.
    address public globalAdmin;           // The Global Admin of the whole network. Has the power to switch off/on the functionality of entire protocol.

    uint256 public defaultGracePeriod;    // Represents the amount of time a Borrower has to make a missed payment before a default can be triggered.
    uint256 public swapOutRequired;       // Represents minimum amount of Pool cover that a Pool Delegate has to provide before they can finalize a Pool.
    uint256 public fundingPeriod;         // Amount of time to allow a Borrower to drawdown on their Loan after funding period ends.
    uint256 public investorFee;           // Portion of drawdown that goes to the Pool Delegates and individual Lenders.
    uint256 public treasuryFee;           // Portion of drawdown that goes to the MapleTreasury.
    uint256 public maxSwapSlippage;       // Maximum amount of slippage for Uniswap transactions.
    uint256 public minLoanEquity;         // Minimum amount of LoanFDTs required to trigger liquidations (basis points percentage of totalSupply).
    uint256 public stakerCooldownPeriod;  // Period (in secs) after which Stakers are allowed to unstake  their BPTs  from a StakeLocker.
    uint256 public lpCooldownPeriod;      // Period (in secs) after which LPs     are allowed to withdraw their funds from a Pool.
    uint256 public stakerUnstakeWindow;   // Window of time (in secs) after `stakerCooldownPeriod` that an account has to withdraw before their intent to unstake  is invalidated.
    uint256 public lpWithdrawWindow;      // Window of time (in secs) after `lpCooldownPeriod`     that an account has to withdraw before their intent to withdraw is invalidated.

    bool public protocolPaused;  // Switch to pause the functionality of the entire protocol.

    mapping(address => bool) public isValidLiquidityAsset;            // Mapping of valid Liquidity Assets.
    mapping(address => bool) public isValidCollateralAsset;           // Mapping of valid Collateral Assets.
    mapping(address => bool) public validCalcs;                       // Mapping of valid Calculators
    mapping(address => bool) public isValidPoolDelegate;              // Mapping of valid Pool Delegates (prevent unauthorized/unknown addresses from creating Pools).
    mapping(address => bool) public isValidBalancerPool;              // Mapping of valid Balancer Pools that Maple has approved for BPT staking.

    // Determines the liquidation path of various assets in Loans and the Treasury.
    // The value provided will determine whether or not to perform a bilateral or triangular swap on Uniswap.
    // For example, `defaultUniswapPath[WBTC][USDC]` value would indicate what asset to convert WBTC into before conversion to USDC.
    // If `defaultUniswapPath[WBTC][USDC] == USDC`, then the swap is bilateral and no middle asset is swapped.
    // If `defaultUniswapPath[WBTC][USDC] == WETH`, then swap WBTC for WETH, then WETH for USDC.
    mapping(address => mapping(address => address)) public defaultUniswapPath;

    mapping(address => address) public oracleFor;  // Chainlink oracle for a given asset.

    mapping(address => bool)                     public isValidPoolFactory;  // Mapping of valid Pool Factories.
    mapping(address => bool)                     public isValidLoanFactory;  // Mapping of valid Loan Factories.
    mapping(address => mapping(address => bool)) public validSubFactories;   // Mapping of valid sub factories.

    event                     Initialized();
    event              CollateralAssetSet(address asset, uint256 decimals, string symbol, bool valid);
    event               LiquidityAssetSet(address asset, uint256 decimals, string symbol, bool valid);
    event                       OracleSet(address asset, address oracle);
    event TransferRestrictionExemptionSet(address indexed exemptedContract, bool valid);
    event                 BalancerPoolSet(address balancerPool, bool valid);
    event              PendingGovernorSet(address indexed pendingGovernor);
    event                GovernorAccepted(address indexed governor);
    event                 GlobalsParamSet(bytes32 indexed which, uint256 value);
    event               GlobalsAddressSet(bytes32 indexed which, address addr);
    event                  ProtocolPaused(bool pause);
    event                  GlobalAdminSet(address indexed newGlobalAdmin);
    event                 PoolDelegateSet(address indexed delegate, bool valid);

    /**
        @dev Checks that `msg.sender` is the Governor.
    */
    modifier isGovernor() {
        require(msg.sender == governor, "MG:NOT_GOV");
        _;
    }

    /**
        @dev   Constructor function.
        @dev   It emits an `Initialized` event.
        @param _governor    Address of Governor.
        @param _mpl         Address of the ERC-2222 Maple Token for the Maple protocol.
        @param _globalAdmin Address the Global Admin.
    */
    constructor(address _governor, address _mpl, address _globalAdmin) public {
        governor             = _governor;
        mpl                  = _mpl;
        swapOutRequired      = 10_000;     // $10,000 of Pool cover
        fundingPeriod        = 10 days;
        defaultGracePeriod   = 5 days;
        investorFee          = 50;         // 0.5 %
        treasuryFee          = 50;         // 0.5 %
        maxSwapSlippage      = 1000;       // 10 %
        minLoanEquity        = 2000;       // 20 %
        globalAdmin          = _globalAdmin;
        stakerCooldownPeriod = 10 days;
        lpCooldownPeriod     = 10 days;
        stakerUnstakeWindow  = 2 days;
        lpWithdrawWindow     = 2 days;
        emit Initialized();
    }

    /************************/
    /*** Setter Functions ***/
    /************************/

    /**
        @dev  Sets the Staker cooldown period. This change will affect the existing cool down period for the Stakers that already intended to unstake.
              Only the Governor can call this function.
        @dev  It emits a `GlobalsParamSet` event.
        @param newCooldownPeriod New value for the cool down period.
    */
    function setStakerCooldownPeriod(uint256 newCooldownPeriod) external isGovernor {
        stakerCooldownPeriod = newCooldownPeriod;
        emit GlobalsParamSet("STAKER_COOLDOWN_PERIOD", newCooldownPeriod);
    }

    /**
        @dev   Sets the Liquidity Pool cooldown period. This change will affect the existing cool down period for the LPs that already intended to withdraw.
               Only the Governor can call this function.
        @dev   It emits a `GlobalsParamSet` event.
        @param newCooldownPeriod New value for the cool down period.
    */
    function setLpCooldownPeriod(uint256 newCooldownPeriod) external isGovernor {
        lpCooldownPeriod = newCooldownPeriod;
        emit GlobalsParamSet("LP_COOLDOWN_PERIOD", newCooldownPeriod);
    }

    /**
        @dev   Sets the Staker unstake window. This change will affect the existing window for the Stakers that already intended to unstake.
               Only the Governor can call this function.
        @dev   It emits a `GlobalsParamSet` event.
        @param newUnstakeWindow New value for the unstake window.
    */
    function setStakerUnstakeWindow(uint256 newUnstakeWindow) external isGovernor {
        stakerUnstakeWindow = newUnstakeWindow;
        emit GlobalsParamSet("STAKER_UNSTAKE_WINDOW", newUnstakeWindow);
    }

    /**
        @dev   Sets the Liquidity Pool withdraw window. This change will affect the existing window for the LPs that already intended to withdraw.
               Only the Governor can call this function.
        @dev   It emits a `GlobalsParamSet` event.
        @param newLpWithdrawWindow New value for the withdraw window.
    */
    function setLpWithdrawWindow(uint256 newLpWithdrawWindow) external isGovernor {
        lpWithdrawWindow = newLpWithdrawWindow;
        emit GlobalsParamSet("LP_WITHDRAW_WINDOW", newLpWithdrawWindow);
    }

    /**
        @dev   Sets the allowed Uniswap slippage percentage, in basis points. Only the Governor can call this function.
        @dev   It emits a `GlobalsParamSet` event.
        @param newMaxSlippage New max slippage percentage (in basis points)
    */
    function setMaxSwapSlippage(uint256 newMaxSlippage) external isGovernor {
        _checkPercentageRange(newMaxSlippage);
        maxSwapSlippage = newMaxSlippage;
        emit GlobalsParamSet("MAX_SWAP_SLIPPAGE", newMaxSlippage);
    }

    /**
      @dev   Sets the Global Admin. Only the Governor can call this function.
      @dev   It emits a `GlobalAdminSet` event.
      @param newGlobalAdmin New global admin address.
    */
    function setGlobalAdmin(address newGlobalAdmin) external {
        require(msg.sender == governor && newGlobalAdmin != address(0), "MG:NOT_GOV_OR_ADMIN");
        require(!protocolPaused, "MG:PROTO_PAUSED");
        globalAdmin = newGlobalAdmin;
        emit GlobalAdminSet(newGlobalAdmin);
    }

    /**
        @dev   Sets the validity of a Balancer Pool. Only the Governor can call this function.
        @dev   It emits a `BalancerPoolSet` event.
        @param balancerPool Address of Balancer Pool contract.
        @param valid        The new validity status of a Balancer Pool.
    */
    function setValidBalancerPool(address balancerPool, bool valid) external isGovernor {
        isValidBalancerPool[balancerPool] = valid;
        emit BalancerPoolSet(balancerPool, valid);
    }

    /**
      @dev   Sets the paused/unpaused state of the protocol. Only the Global Admin can call this function.
      @dev   It emits a `ProtocolPaused` event.
      @param pause Boolean flag to switch externally facing functionality in the protocol on/off.
    */
    function setProtocolPause(bool pause) external {
        require(msg.sender == globalAdmin, "MG:NOT_ADMIN");
        protocolPaused = pause;
        emit ProtocolPaused(pause);
    }

    /**
        @dev   Sets the validity of a PoolFactory. Only the Governor can call this function.
        @param poolFactory Address of PoolFactory.
        @param valid       The new validity status of a PoolFactory.
    */
    function setValidPoolFactory(address poolFactory, bool valid) external isGovernor {
        isValidPoolFactory[poolFactory] = valid;
    }

    /**
        @dev   Sets the validity of a LoanFactory. Only the Governor can call this function.
        @param loanFactory Address of LoanFactory.
        @param valid       The new validity status of a LoanFactory.
    */
    function setValidLoanFactory(address loanFactory, bool valid) external isGovernor {
        isValidLoanFactory[loanFactory] = valid;
    }

    /**
        @dev   Sets the validity of a sub factory as it relates to a super factory. Only the Governor can call this function.
        @param superFactory The core factory (e.g. PoolFactory, LoanFactory).
        @param subFactory   The sub factory used by core factory (e.g. LiquidityLockerFactory).
        @param valid        The new validity status of a subFactory within context of super factory.
    */
    function setValidSubFactory(address superFactory, address subFactory, bool valid) external isGovernor {
        require(isValidLoanFactory[superFactory] || isValidPoolFactory[superFactory], "MG:INVALID_SUPER_F");
        validSubFactories[superFactory][subFactory] = valid;
    }

    /**
        @dev   Sets the path to swap an asset through Uniswap. Only the Governor can call this function.
        @param from Asset being swapped.
        @param to   Final asset to receive. **
        @param mid  Middle asset.

        ** Set to == mid to enable a bilateral swap (single path swap).
           Set to != mid to enable a triangular swap (multi path swap).
    */
    function setDefaultUniswapPath(address from, address to, address mid) external isGovernor {
        defaultUniswapPath[from][to] = mid;
    }

    /**
        @dev   Sets the validity of a Pool Delegate (those allowed to create Pools). Only the Governor can call this function.
        @dev   It emits a `PoolDelegateSet` event.
        @param delegate Address to manage permissions for.
        @param valid    The new validity status of a Pool Delegate.
    */
    function setPoolDelegateAllowlist(address delegate, bool valid) external isGovernor {
        isValidPoolDelegate[delegate] = valid;
        emit PoolDelegateSet(delegate, valid);
    }

    /**
        @dev   Sets the validity of an asset for collateral. Only the Governor can call this function.
        @dev   It emits a `CollateralAssetSet` event.
        @param asset The asset to assign validity to.
        @param valid The new validity status of a Collateral Asset.
    */
    function setCollateralAsset(address asset, bool valid) external isGovernor {
        isValidCollateralAsset[asset] = valid;
        emit CollateralAssetSet(asset, IERC20Details(asset).decimals(), IERC20Details(asset).symbol(), valid);
    }

    /**
        @dev   Sets the validity of an asset for liquidity in Pools. Only the Governor can call this function.
        @dev   It emits a `LiquidityAssetSet` event.
        @param asset Address of the valid asset.
        @param valid The new validity status a Liquidity Asset in Pools.
    */
    function setLiquidityAsset(address asset, bool valid) external isGovernor {
        isValidLiquidityAsset[asset] = valid;
        emit LiquidityAssetSet(asset, IERC20Details(asset).decimals(), IERC20Details(asset).symbol(), valid);
    }

    /**
        @dev   Sets the validity of a calculator contract. Only the Governor can call this function.
        @param calc  Calculator address.
        @param valid The new validity status of a Calculator.
    */
    function setCalc(address calc, bool valid) external isGovernor {
        validCalcs[calc] = valid;
    }

    /**
        @dev   Sets the investor fee (in basis points). Only the Governor can call this function.
        @dev   It emits a `GlobalsParamSet` event.
        @param _fee The fee, e.g., 50 = 0.50%.
    */
    function setInvestorFee(uint256 _fee) external isGovernor {
        _checkPercentageRange(treasuryFee.add(_fee));
        investorFee = _fee;
        emit GlobalsParamSet("INVESTOR_FEE", _fee);
    }

    /**
        @dev   Sets the treasury fee (in basis points). Only the Governor can call this function.
        @dev   It emits a `GlobalsParamSet` event.
        @param _fee The fee, e.g., 50 = 0.50%.
    */
    function setTreasuryFee(uint256 _fee) external isGovernor {
        _checkPercentageRange(investorFee.add(_fee));
        treasuryFee = _fee;
        emit GlobalsParamSet("TREASURY_FEE", _fee);
    }

    /**
        @dev   Sets the MapleTreasury. Only the Governor can call this function.
        @dev   It emits a `GlobalsParamSet` event.
        @param _mapleTreasury New MapleTreasury address.
    */
    function setMapleTreasury(address _mapleTreasury) external isGovernor {
        require(_mapleTreasury != address(0), "MG:ZERO_ADDR");
        mapleTreasury = _mapleTreasury;
        emit GlobalsAddressSet("MAPLE_TREASURY", _mapleTreasury);
    }

    /**
        @dev   Sets the default grace period. Only the Governor can call this function.
        @dev   It emits a `GlobalsParamSet` event.
        @param _defaultGracePeriod Number of seconds to set the grace period to.
    */
    function setDefaultGracePeriod(uint256 _defaultGracePeriod) external isGovernor {
        defaultGracePeriod = _defaultGracePeriod;
        emit GlobalsParamSet("DEFAULT_GRACE_PERIOD", _defaultGracePeriod);
    }

    /**
        @dev   Sets the minimum Loan equity. Only the Governor can call this function.
        @dev   It emits a `GlobalsParamSet` event.
        @param _minLoanEquity Min percentage of Loan equity an account must have to trigger liquidations.
    */
    function setMinLoanEquity(uint256 _minLoanEquity) external isGovernor {
        _checkPercentageRange(_minLoanEquity);
        minLoanEquity = _minLoanEquity;
        emit GlobalsParamSet("MIN_LOAN_EQUITY", _minLoanEquity);
    }

    /**
        @dev   Sets the funding period. Only the Governor can call this function.
        @dev   It emits a `GlobalsParamSet` event.
        @param _fundingPeriod Number of seconds to set the drawdown grace period to.
    */
    function setFundingPeriod(uint256 _fundingPeriod) external isGovernor {
        fundingPeriod = _fundingPeriod;
        emit GlobalsParamSet("FUNDING_PERIOD", _fundingPeriod);
    }

    /**
        @dev   Sets the the minimum Pool cover required to finalize a Pool. Only the Governor can call this function. FIX
        @dev   It emits a `GlobalsParamSet` event.
        @param amt The new minimum swap out required.
    */
    function setSwapOutRequired(uint256 amt) external isGovernor {
        require(amt >= uint256(10_000), "MG:SWAP_OUT_TOO_LOW");
        swapOutRequired = amt;
        emit GlobalsParamSet("SWAP_OUT_REQUIRED", amt);
    }

    /**
        @dev   Sets a price feed's oracle. Only the Governor can call this function.
        @dev   It emits a `OracleSet` event.
        @param asset  Asset to update price for.
        @param oracle New oracle to use.
    */
    function setPriceOracle(address asset, address oracle) external isGovernor {
        oracleFor[asset] = oracle;
        emit OracleSet(asset, oracle);
    }

    /************************************/
    /*** Transfer Ownership Functions ***/
    /************************************/

    /**
        @dev   Sets a new Pending Governor. This address can become Governor if they accept. Only the Governor can call this function.
        @dev   It emits a `PendingGovernorSet` event.
        @param _pendingGovernor Address of new Pending Governor.
    */
    function setPendingGovernor(address _pendingGovernor) external isGovernor {
        require(_pendingGovernor != address(0), "MG:ZERO_ADDR");
        pendingGovernor = _pendingGovernor;
        emit PendingGovernorSet(_pendingGovernor);
    }

    /**
        @dev Accept the Governor position. Only the Pending Governor can call this function.
        @dev It emits a `GovernorAccepted` event.
    */
    function acceptGovernor() external {
        require(msg.sender == pendingGovernor, "MG:NOT_PENDING_GOV");
        governor        = msg.sender;
        pendingGovernor = address(0);
        emit GovernorAccepted(msg.sender);
    }

    /************************/
    /*** Getter Functions ***/
    /************************/

    /**
        @dev    Fetch price for asset from Chainlink oracles.
        @param  asset Asset to fetch price of.
        @return Price of asset in USD.
    */
    function getLatestPrice(address asset) external view returns (uint256) {
        return uint256(IOracle(oracleFor[asset]).getLatestPrice());
    }

    /**
        @dev   Checks that a subFactory is valid as it relates to a super factory.
        @param superFactory The core factory (e.g. PoolFactory, LoanFactory).
        @param subFactory   The sub factory used by core factory (e.g. LiquidityLockerFactory).
        @param factoryType  The type expected for the subFactory. References listed below.
                                0 = COLLATERAL_LOCKER_FACTORY
                                1 = DEBT_LOCKER_FACTORY
                                2 = FUNDING_LOCKER_FACTORY
                                3 = LIQUIDITY_LOCKER_FACTORY
                                4 = STAKE_LOCKER_FACTORY
    */
    function isValidSubFactory(address superFactory, address subFactory, uint8 factoryType) external view returns (bool) {
        return validSubFactories[superFactory][subFactory] && ISubFactory(subFactory).factoryType() == factoryType;
    }

    /**
        @dev   Checks that a Calculator is valid.
        @param calc     Calculator address.
        @param calcType Calculator type.
    */
    function isValidCalc(address calc, uint8 calcType) external view returns (bool) {
        return validCalcs[calc] && ICalc(calc).calcType() == calcType;
    }

    /**
        @dev    Returns the `lpCooldownPeriod` and `lpWithdrawWindow` as a tuple, for convenience.
        @return [0] = lpCooldownPeriod
                [1] = lpWithdrawWindow
    */
    function getLpCooldownParams() external view returns (uint256, uint256) {
        return (lpCooldownPeriod, lpWithdrawWindow);
    }

    /************************/
    /*** Helper Functions ***/
    /************************/

    /**
        @dev Checks that percentage is less than 100%.
    */
    function _checkPercentageRange(uint256 percentage) internal pure {
        require(percentage <= uint256(10_000), "MG:PCT_OOB");
    }

}