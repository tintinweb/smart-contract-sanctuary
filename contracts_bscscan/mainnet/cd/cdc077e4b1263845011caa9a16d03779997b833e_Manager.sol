/**
 *Submitted for verification at BscScan.com on 2022-01-12
*/

// Sources flattened with hardhat v2.8.0 https://hardhat.org


// SPDX-License-Identifier: BUSL-1.1


// File contracts/interfaces/IRoleAccess.sol

pragma solidity 0.8.10;

interface IRoleAccess {
    function isAdmin(address user) view external returns (bool);
    function isDeployer(address user) view external returns (bool);
    function isConfigurator(address user) view external returns (bool);
    function isApprover(address user) view external returns (bool);
    function isRole(string memory roleName, address user) view external returns (bool);
}


// File contracts/interfaces/IRandomProvider.sol


pragma solidity 0.8.10;


interface IRandomProvider {
    function requestRandom() external;
    function grantAccess(address campaign) external;
}


// File contracts/interfaces/IBnbOracle.sol


pragma solidity 0.8.10;


interface IBnbOracle {
    function getRate(address currency) external view returns (int, uint8);
}


// File contracts/interfaces/IManager.sol


pragma solidity 0.8.10;



interface IManager {
    function addCampaign(address newContract, address projectOwner) external;
    function getFeeVault() external view returns (address);
    function getSvLaunchAddress() external view returns (address);
    function getEggAddress() external view returns (address);
    function getRoles() external view returns (IRoleAccess);
    function getRandomProvider() external view returns (IRandomProvider);
    function getBnbOracle() external view returns (IBnbOracle);
}


// File contracts/lib/DataTypes.sol



pragma solidity 0.8.10;

library DataTypes {
    
    uint public constant LUT_SIZE = 9; // Lookup Table size
     
    struct Store {
        Data data;
        
        uint state; // Bitmask of bool //
        FinalState finalState; // only valid after FinishUp is called
        
        Subscriptions subscriptions;
        Guaranteed guaranteed;
        Lottery lottery;
        OverSubscriptions overSubscription;
        Live live;
        Vesting vesting;
        Lp lp;
        History history;
        
        ReturnFunds returnFunds; // When IDO did not meet softCap 
    }
    
     // Data //
    struct Data {
        address token; // The IDO token. Can be zero address if this is a seed raise without LP provision.
        uint subStart; // Subscription Starts
        uint subEnd;   // Subscription Ends
        uint idoStart; // Ido Starts
        uint idoEnd;   // Ido Ends
        uint softCap;  // Unit in currency
        uint hardCap;  // Unit in currency
        uint tokenSalesQty; // Total tokens for sales
        uint minBuyLimitPublic; // min and max buy limit for Public open sales (after subscription). Unit in currency.
        uint maxBuyLimitPublic; // Unit in currency
        uint snapShotId;    // SnapshotId
        address currency; // The raised currency
        address svLaunchAddress;
        address eggAddress;
        
        uint feePcnt; // In 1e6
        
        // Cache
        uint tokensPerCapital;
    }
    
    // Subscription
    struct SubscriptionResultParams {
        bool resultAvailable;
        bool guaranteed;
        uint guaranteedAmount;
        bool wonLottery;
        uint lotteryAmount;
        bool wonOverSub;
        uint overSubAmount;
        uint priority;
        uint eggBurnAmount;
    }
    
    struct SubscriptionParams {
        bool guaranteed;
        uint guaranteedAmount;
        bool inLottery;
        uint lotteryAmount;
        uint overSubAmount;
        uint priority;
        uint eggBurnAmount;
    }
    
    struct SubItem {
        uint paidCapital; // Unit in currency
        bool refundedUnusedCapital; // Has user gets back his un-used capital ?
    }

    struct Subscriptions {
        mapping(address=> DataTypes.SubItem)  items;
        uint count;
    }
    
    struct Guaranteed {
        mapping(address=> uint) subscribedAmount;
        
        uint svLaunchSupplyAtSnapShot;
        uint totalSubscribed; // Unit in currency.
    }

    // Lottery Info
    struct LotteryItem {
        uint index;       
        bool exist;    
    }
  
    struct TallyLotteryResult {
        uint numWinners;
        uint leftOverAmount;
        uint winnerStartIndex;
    }

    struct TallyLotteryRandom {
        bool initialized;
        uint requestTime;
        uint value;
        bool valid;
    }
    
    struct LotteryData {
        uint totalAllocatedAmount; // Unit in currency.
        uint eachAllocationAmount; // Unit in currency.
        bool tallyCompleted;
    }
    struct Lottery {
        mapping(address=>LotteryItem) items;
        uint count;
        
        LotteryData data;
        TallyLotteryRandom random;
        TallyLotteryResult result;
    }

    // Over Subscription
    struct TallyOverSubResult {
        bool tallyCompleted;
        uint winningBucket;
        uint firstLoserIndex;
        uint leftOverAmount;
        uint burnableEggs;
    }

    struct OverSubItem {
        uint amount;        // Amount of over-subscribe tokens. Max is 0.5% of total sales qty.
        uint priority;      // 0 - 100
        uint index;
        uint cumulativeEggBurn; // Cummulative amount of egg burns in the bucket that this user belongs to. As each items is pushed into the array,
                                // this cummulative value increases.
    }

    struct Bucket {
        address[] users;    // This is users address, secondary priority is FCFS
        uint total;         // Precalculated total for optimization.
        uint totalEggs;     // Precalculated total Eggs for optimization.
        
        // Quick lookup-table for pre-calculated total at specific intervals 
        uint[][LUT_SIZE] fastLookUp; // Provide a fast look-up of the total amount at specific indices. 10s, 100s, 1000s, 10,000s, 100,000s, 1,000,000s
    }
    
    struct OverSubscriptions {
        mapping(address=> OverSubItem) items;
        mapping(uint => Bucket) buckets; // 0-100 buckets of address[]

        OverSubData data;

        uint allocatedAmount;
        uint totalOverSubAmount;  // Keep tracks of the total over-subscribed amount
        uint totalMaxBurnableEggs;  // Keep track of the total egg burns amount
        
        TallyOverSubResult result;
    }
    
    struct OverSubData {
        uint stdOverSubQty; // Unit in currency
        uint stdEggBurnQty; // Unit in Egg
    }
    
    struct Live {
        
        LiveData data;
        
        uint allocLeftAtOpen; // This is the amount of allocation (in Currency unit) remaining at Live opening (after subscription)
        uint allocSoldInLiveSoFar; // This is the amount of allocation (in Currency unit) sold in Live, so far.
        
        mapping(uint=>mapping(address=>bool)) whitelistMap;
         
         // Record of user's purchases 
        mapping(address=>uint)  whitelistPurchases; // record of sales in whitelist round 
        mapping(address=>uint)  publicPurchases;    // record of sales in publc round 
    }
    
    // Live: Tier system for Whitelist FCFS
    struct Tier {
        uint minBuyAmount;
        uint maxBuyAmount; 
    }
    
    struct LiveData {
        uint whitelistFcfsDuration; // 0 if whitelist is not turned on
        Tier[] tiers; // if has at least 1 tier, then the WhitelistFcfs is enabled 
    }
    
    struct LockInfo {
        uint[] pcnts;
        uint[] durations;
        DataTypes.VestingReleaseType releaseType;
    }
    
    struct ClaimInfo {
        bool[] claimed;
        uint amount;
    }
    
    struct ClaimRecords {
        mapping(address=>ClaimInfo) team;
    }
    
    struct Vesting {
       VestData data;
        ClaimRecords claims;
    }
    
    struct VestData {
        LockInfo    teamLock;
        uint        teamLockAmount; // Total vested amount
        uint desiredUnlockTime;
    }
    
    struct ClaimIntervalResult {
        uint claimedSoFar;
        uint claimable;
        uint nextLockedAmount;
        uint claimStartIndex;
        uint numClaimableSlots;
        uint nextUnlockIndex;
        uint nextUnlockTime;
    }
    
    struct ClaimLinearResult {
        uint claimedSoFar;
        uint claimable;
        uint lockedAmount;
        uint newStartTime;
        uint endTime;
    }
    
    struct ReturnFunds {
        mapping(address=>uint)  amount;
    }
    
    struct PurchaseDetail {
        uint guaranteedAmount;
        uint lotteryAmount;
        uint overSubscribeAmount;
        uint liveWlFcfsAmount;
        uint livePublicAmount;
        uint total;
        bool hasReturnedFund;
    }
    
    // LP 
    struct Lp {
        LpData data;
        LpLocks locks;
        LpResult result;
        bool enabled;

        LpSwap swap;
    }
    struct LpData {
        DataTypes.LpSize  size;
        uint sizeParam;
        uint rate;
        uint softCap;
        uint hardCap;
       
        // DEX routers and factory
        address[] routers;
        address[] factory;
        
        uint[] splits;
        address tokenA;
        address currency; // The raised currency 
    }
    
    struct LpLocks {
        uint[]  pcnts;
        uint[]  durations;
        uint    startTime;
    }
    
    struct LpResult {
        uint[] tokenAmountUsed;
        uint[] currencyAmountUsed;
        uint[] lpTokenAmount;
        bool[] claimed;
        bool created;
    }
    
    struct LpSwap {
       bool needSwap;
       bool swapped;
       uint newCurrencyAmount;
    }
    
    // History
    enum ActionType {
        FundIn,
        FundOut,
        Subscribe,
        RefundExcess,
        BuyTokens,
        ReturnFund,
        ClaimFund,
        ClaimLp
    }
    
    struct Action {
        uint128     actionType;
        uint128     time;
        uint256     data1;
        uint256     data2;
    }
   
    struct History {
        mapping(address=>Action[]) investor;
        mapping(address=>Action[]) campaignOwner;

        // Keep track of all investor's address for exporting purpose
        address[] allInvestors;
        mapping(address => bool) invested;
    }
    
    // ENUMS
    enum Ok {
        BasicSetup,
        Config,
        Finalized,
        FundedIn,
        Tally,
        FinishedUp,
        LpCreated
    }
    
    enum FinalState {
        Invalid,
        Success, // met soft cap
        Failure, // did not meet soft cap
        Aborted  // when a campaign is cancelled
    }
    
    enum LpProvider {
        PancakeSwap,
        ApeSwap,
        WaultFinance
    }
    
    enum FundType {
        Currency,
        Token,
        WBnb,
        Egg
    }
    
    enum LpSize {
        Zero,       // No Lp provision
        Min,        // SoftCap
        Max,        // As much as we can raise above soft-cap. It can be from soft-cap all the way until hard-cap
        MaxCapped   // As much as we can raise above soft-cap, but capped at a % of hardcap. Eg 90% of hardcap.
    }
    
    enum VestingReleaseType {
        ByIntervals,
        ByLinearContinuous
    }
    
    // Period according to timeline
    enum Period {
        None,
        Setup,
        Subscription,
        IdoWhitelisted,
        IdoPublic,
        IdoEnded
    }
}


// File contracts/interfaces/ILpProvider.sol


pragma solidity 0.8.10;

interface ILpProvider {
    function getLpProvider(DataTypes.LpProvider provider) external view returns (address, address);
    function checkLpProviders(DataTypes.LpProvider[] calldata providers) external view returns (bool);
    function getWBnb() external view returns (address);
}


// File contracts/interfaces/ICampaign.sol


pragma solidity 0.8.10;

interface ICampaign {
    function cancelCampaign() external;
    function daoMultiSigEmergencyWithdraw(address tokenAddress, address to, uint amount) external;
    function sendRandomValueForLottery(uint value) external;
}


// File contracts/interfaces/IUniswapV2Router02.sol


pragma solidity 0.8.10;

interface IUniswapV2Router02 {
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    
    
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    

    function WETH() external pure returns (address);
 
  
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}


// File contracts/lib/Constant.sol



pragma solidity 0.8.10;

library Constant {

    uint    public constant FACTORY_VERSION = 1;
    address public constant ZERO_ADDRESS    = address(0);
    
    string public constant  BNB_NAME        = "BNB";
    uint    public constant VALUE_E18       = 1e18;
    uint    public constant VALUE_MAX_SVLAUNCH = 10_000e18;
    uint    public constant VALUE_MIN_SVLAUNCH = 40e18;
    uint    public constant PCNT_100        = 1e6;
    uint    public constant PCNT_10         = 1e5;
    uint    public constant PCNT_50         = 5e5;
    uint    public constant MAX_PCNT_FEE    = 3e5; // 30% fee is max we can set //
    uint    public constant PRIORITY_MAX    = 100;

    uint    public constant BNB_SWAP_MAX_SLIPPAGE_PCNT = 3e4; // Max slippage is set to 3%

    // Chainlink VRF Support
    uint    public constant VRF_FEE = 2e17; // 0.2 LINK
    uint    public constant VRF_TIME_WINDOW = 60; // The randome value will only be acccep within 60 sec

}


// File @openzeppelin/contracts/token/ERC20/[email protected]


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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]


pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


// File @openzeppelin/contracts/utils/[email protected]


pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// File @openzeppelin/contracts/token/ERC20/[email protected]


pragma solidity ^0.8.0;



/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}


// File contracts/Manager.sol


pragma solidity 0.8.10;








contract Manager is IManager, ILpProvider {

    IRoleAccess private _roles;
    address private _randomProvider;
    address private _bnbOracle;

    address private _feeVault;
    address private immutable _svLaunchAddress;
    address private immutable _eggAddress;
    
    enum Status {
        Inactive,
        Active,
        Cancelled
    }

     modifier onlyFactory() {
        require(_factoryMap[msg.sender], "Errors.NOT_FACTORY");
        _;
    }
    
    modifier onlyAdmin() {
        require(_roles.isAdmin(msg.sender), "Errors.NOT_ADMIN");
        _;
    }
    
    // Events
    event FactoryRegistered(address indexed deployedAddress);
    event CampaignAdded(address indexed contractAddress, address indexed projectOwner);
    event CampaignCancelled(address indexed contractAddress);
    event FeeVaultChanged(address from, address to);
    event SetLpProvider(uint index, address router, address factory);
    event EnableCurrency(address currency, bool enable);
    event AddCurrency(address currency);
    event SetRandomProvider(address provider);
    event SetBnbOracle(address oracle);
    event DaoMultiSigEmergencyWithdraw(address contractAddress, address to, address tokenAddress, uint amount);
    
    struct CampaignInfo {
        address contractAddress;
        address owner;
        Status status;
    }
    
    struct LpProviderInfo {
        address router;
        address factory;
        bool exist;
    }
    
    // History & list of factories.
    mapping(address => bool) private _factoryMap;
    address[] private _factories;
    
    // History/list of all IDOs
    mapping(uint => CampaignInfo) private _indexCampaignMap; // Starts from 1. Zero is invalid //
    mapping(address => uint) private _addressIndexMap;  // Maps a campaign address to an index in _indexCampaignMap.
    uint private _count;
    
    // Supported Currency
    address[] private _supportedCurrency;
    mapping(address=>bool) private _supportedCurrencyMap;
    
    // Supported LP Providers
    mapping(uint => LpProviderInfo) private _lpProvidersMap;
    
    constructor(address svLaunchAddress, address eggAddress, address feeVault, IRoleAccess rolesRegistry)
    {
        _svLaunchAddress = svLaunchAddress;
        _eggAddress = eggAddress;
        _setFeeVault(feeVault);
        _roles = rolesRegistry;
        
        // Add default BNB
         _supportedCurrency.push(Constant.ZERO_ADDRESS);
         _supportedCurrencyMap[Constant.ZERO_ADDRESS] = true;
    }
    
    //--------------------//
    // EXTERNAL FUNCTIONS //
    //--------------------//
    
    function getCampaignInfo(uint id) external view returns (CampaignInfo memory) {
        return _indexCampaignMap[id];
    }
    
    
    function getTotalCampaigns() external view returns (uint) {
        return _count;
    }
    
    function registerFactory(address newFactory) external onlyAdmin {
        if ( _factoryMap[newFactory] == false) {
            _factoryMap[newFactory] = true;
            _factories.push(newFactory);
            emit FactoryRegistered(newFactory);
        }
    }
    
    function isFactory(address contractAddress) external view returns (bool) {
        return _factoryMap[contractAddress];
    }
    
    function getFactory(uint id) external view returns (address) {
        return (  (id < _factories.length) ? _factories[id] : Constant.ZERO_ADDRESS );
    }
    
    function setFeeVault(address newAddress) external onlyAdmin {
        _setFeeVault(newAddress);
    }
    
    function addCurrency(address[] memory tokenAddress) external onlyAdmin {
        
        uint len = tokenAddress.length;
        address token;
        for (uint n=0; n<len; n++) {
            token = tokenAddress[n];
            if (!_currencyExist(token)) {
                _supportedCurrency.push(token);
                _supportedCurrencyMap[token] = true;
                emit AddCurrency(token);
            }
        }

    }
    
    function enableCurrency(address tokenAddress, bool enable) external onlyAdmin {
        _supportedCurrencyMap[tokenAddress] = enable;
        emit EnableCurrency(tokenAddress, enable);
    }

    //------------------------//
    // IMPLEMENTS IManager    //
    //------------------------//
    
    function addCampaign(address newContract, address projectOwner) external override onlyFactory {
        _count++;
        _indexCampaignMap[_count] = CampaignInfo(newContract, projectOwner, Status.Active);
        _addressIndexMap[newContract] = _count;
        emit CampaignAdded(newContract, projectOwner);

        // All the new campaign to access RandomProvider
        require(_randomProvider != address(0), "Errors.INVALID_ADDRESS");
        IRandomProvider(_randomProvider).grantAccess(newContract);
    }
    
    function cancelCampaign(address contractAddress) external onlyAdmin {
        uint index = _addressIndexMap[contractAddress];
        CampaignInfo storage info = _indexCampaignMap[index];
        // Update status if campaign is exist & active
        if (info.status == Status.Active) {
            info.status = Status.Cancelled;         
            
            ICampaign(contractAddress).cancelCampaign();
            emit CampaignCancelled(contractAddress);
        }
    }
    
    // Emergency withdrawal to admin address only. Note: Admin is a multiSig dao address.
    function daoMultiSigEmergencyWithdraw(address contractAddress, address tokenAddress, uint amount) external onlyAdmin {
       
        ICampaign(contractAddress).daoMultiSigEmergencyWithdraw(tokenAddress, msg.sender, amount);
        emit DaoMultiSigEmergencyWithdraw(contractAddress, msg.sender, tokenAddress, amount);
    }
    
    function getFeeVault() external override view returns (address) {
        return _feeVault;
    }

    function isCurrencySupported(address currency) external view returns (bool) {
        return _supportedCurrencyMap[currency];
    }
    
    function getSvLaunchAddress() external view override returns (address) {
        return _svLaunchAddress;
    }
    
    function getEggAddress() external view override returns (address) {
        return _eggAddress;
    }
    
    function getRoles() external view override returns (IRoleAccess) {
        return _roles;
    }

    function getRandomProvider() external view override returns (IRandomProvider) {
        return IRandomProvider(_randomProvider);
    }

    function setRandomProvider(address provider) external onlyAdmin {
        require(provider != address(0), "Errors.INVALID_ADDRESS");
        _randomProvider = provider;
        emit SetRandomProvider(provider);
    }

    function getBnbOracle() external view override returns (IBnbOracle) {
        return IBnbOracle(_bnbOracle);
    }

    function setBnbOracle(address oracle) external onlyAdmin {
        require(oracle != address(0), "Errors.INVALID_ADDRESS");
        _bnbOracle = oracle;
        emit SetBnbOracle(oracle);
    }

    


    //------------------------//
    // IMPLEMENTS ILpProvider //
    //------------------------//
    
    function getLpProvider(DataTypes.LpProvider provider) external view override returns (address, address) {
         LpProviderInfo memory item = _lpProvidersMap[uint(provider)];
         return item.exist ? ( item.router, item.factory) : (Constant.ZERO_ADDRESS, Constant.ZERO_ADDRESS);
    }
    
    function checkLpProviders(DataTypes.LpProvider[] calldata providers) external view override returns (bool) {
        uint len = providers.length;
        
        for (uint n=0; n<len; n++) {
            if (!_lpProvidersMap[uint(providers[n])].exist) {
                return false;
            }
        }
        return true;
    }
    
    function getWBnb() external view override returns (address) {
        address router = _lpProvidersMap[uint(DataTypes.LpProvider.PancakeSwap)].router;
        return IUniswapV2Router02(router).WETH();
    }
     
    
    // Set and override any existing provider
    function setLpProvider(uint index, address router, address factory) external onlyAdmin {
        require(router != address(0) && factory != address(0), "Errors.INVALID_ADDRESS");
        _lpProvidersMap[index] = LpProviderInfo(router, factory, true);
        emit SetLpProvider(index, router, factory);
    }
    
    //--------------------//
    // PRIVATE FUNCTIONS //
    //--------------------//
    
    function _setFeeVault(address newAddress) private {
        require(newAddress!=address(0), "Errors.INVALID_ADDRESS");
        emit FeeVaultChanged(_feeVault, newAddress);
        _feeVault = newAddress;
    }
    
    function _currencyExist(address currency) private view returns (bool) {
        uint len = _supportedCurrency.length;
        for (uint n=0;n<len;n++) {
            if (_supportedCurrency[n]==currency) {
                return true;
            }   
        }
        return false;
    }
}