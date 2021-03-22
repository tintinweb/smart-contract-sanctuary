pragma solidity ^0.5.5;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following 
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.5.0;

import "./Context.sol";
import "./IERC20.sol";
import "./KineSafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20 {
    using KineSafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
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
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

pragma solidity ^0.5.16;

import "./KineOracleInterface.sol";
import "./KineControllerInterface.sol";
import "./KUSDMinterDelegate.sol";
import "./Math.sol";
import "./IERC20.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";

/// @notice IKineUSD, a simplified interface of KineUSD (see KineUSD)
interface IKineUSD {
    function mint(address account, uint amount) external;

    function burn(address account, uint amount) external;

    function balanceOf(address account) external view returns (uint256);
}

/// @notice IKMCD, a simplified interface of KMCD (see KMCD)
interface IKMCD {
    function borrowBehalf(address payable borrower, uint borrowAmount) external;

    function repayBorrowBehalf(address borrower, uint repayAmount) external;

    function liquidateBorrowBehalf(address liquidator, address borrower, uint repayAmount, address kTokenCollateral) external;

    function borrowBalance(address account) external view returns (uint);

    function totalBorrows() external view returns (uint);
}

/**
 * @title IRewardDistributionRecipient
 */
contract IRewardDistributionRecipient is KUSDMinterDelegate {
    /// @notice Emitted when reward distributor changed
    event NewRewardDistribution(address oldRewardDistribution, address newRewardDistribution);

    /// @notice The reward distributor who is responsible to transfer rewards to this recipient and notify the recipient that reward is added.
    address public rewardDistribution;

    /// @notice Notify this recipient that reward is added.
    function notifyRewardAmount(uint reward) external;

    /// @notice Only reward distributor can notify that reward is added.
    modifier onlyRewardDistribution() {
        require(_msgSender() == rewardDistribution, "Caller is not reward distribution");
        _;
    }

    /// @notice Set reward distributor to new one.
    function setRewardDistribution(address _rewardDistribution) external onlyOwner {
        address oldRewardDistribution = rewardDistribution;
        rewardDistribution = _rewardDistribution;
        emit NewRewardDistribution(oldRewardDistribution, _rewardDistribution);
    }
}

/**
 * @title KUSDMinter is responsible to stake/unstake users' Kine MCD (see KMCD) and mint/burn KUSD (see KineUSD) on behalf of users.
 * When user want to mint KUSD against their collaterals (see KToken), KUSDMinter will borrow Knie MCD on behalf of user (which will increase user's debt ratio)
 * and then call KineUSD to mint KUSD to user. When user want to  burn KUSD, KUSDMinter will call KineUSD to burn KUSD from user and  repay Kine MCD on behalf of user.
 * KUSDMinter also let treasury account to mint/burn its balance to keep KUSD amount (the part that user transferred into Kine off-chain trading system) synced with Kine off-chain trading system.
 * @author Kine
 */
contract KUSDMinter is IRewardDistributionRecipient {
    using KineSafeMath for uint;
    using SafeERC20 for IERC20;

    /// @notice Emitted when KMCD changed
    event NewKMCD(address oldKMCD, address newKMCD);
    /// @notice Emitted when KineUSD changed
    event NewKUSD(address oldKUSD, address newKUSD);
    /// @notice Emitted when Kine changed
    event NewKine(address oldKine, address newKine);
    /// @notice Emitted when reward duration changed
    event NewRewardDuration(uint oldRewardDuration, uint newRewardDuration);
    /// @notice Emitted when reward release period changed
    event NewRewardReleasePeriod(uint oldRewardReleasePeriod, uint newRewardReleasePeriod);
    /// @notice Emitted when burn cool down time changed
    event NewBurnCooldownTime(uint oldCooldown, uint newCooldownTime);
    /// @notice Emitted when user mint KUSD
    event Mint(address indexed user, uint mintKUSDAmount, uint stakedKMCDAmount, uint userStakesNew, uint totalStakesNew);
    /// @notice Emitted when user burnt KUSD
    event Burn(address indexed user, uint burntKUSDAmount, uint unstakedKMCDAmount, uint userStakesNew, uint totalStakesNew);
    /// @notice Emitted when user burnt maximum KUSD
    event BurnMax(address indexed user, uint burntKUSDAmount, uint unstakedKMCDAmount, uint userStakesNew, uint totalStakesNew);
    /// @notice Emitted when liquidator liquidate staker's Kine MCD
    event Liquidate(address indexed liquidator, address indexed staker, uint burntKUSDAmount, uint unstakedKMCDAmount, uint stakerStakesNew, uint totalStakesNew);
    /// @notice Emitted when distributor notify reward is added
    event RewardAdded(uint reward);
    /// @notice Emitted when user claimed reward
    event RewardPaid(address indexed user, uint reward);
    /// @notice Emitted when treasury account mint kusd
    event TreasuryMint(uint amount);
    /// @notice Emitted when treasury account burn kusd
    event TreasuryBurn(uint amount);
    /// @notice Emitted when treasury account changed
    event NewTreasury(address oldTreasury, address newTreasury);
    /// @notice Emitted when vault account changed
    event NewVault(address oldVault, address newVault);
    /// @notice Emitted when controller changed
    event NewController(address oldController, address newController);

    /**
     * @notice This is for avoiding reward calculation overflow (see https://sips.synthetix.io/sips/sip-77)
     * 1.15792e59 < uint(-1) / 1e18
    */
    uint public constant REWARD_OVERFLOW_CHECK = 1.15792e59;

    /**
     * @notice Implementation address slot for delegation mode;
     */
    address public implementation;

    /// @notice Flag to mark if this contract has been initialized before
    bool public initialized;

    /// @notice Contract which holds Kine MCD
    IKMCD public kMCD;

    /// @notice Contract which holds Kine USD
    IKineUSD public kUSD;

    /// @notice Contract of controller which holds Kine Oracle
    KineControllerInterface public controller;

    /// @notice Treasury is responsible to keep KUSD amount consisted with Kine off-chain trading system
    address public treasury;

    /// @notice Vault is the place to store Kine trading system's reserved KUSD
    address public vault;

    /****************
    * Reward related
    ****************/

    /// @notice Contract which hold Kine Token
    IERC20 public kine;
    /// @notice Reward distribution duration. Added reward will be distribute to Kine MCD stakers within this duration.
    uint public rewardDuration;
    /// @notice Staker's reward will mature gradually in this period.
    uint public rewardReleasePeriod;
    /// @notice Start time that users can start staking/burning KUSD and claim their rewards.
    uint public startTime;
    /// @notice End time of this round of reward distribution.
    uint public periodFinish = 0;
    /// @notice Per second reward to be distributed
    uint public rewardRate = 0;
    /// @notice Accrued reward per Kine MCD staked per second.
    uint public rewardPerTokenStored;
    /// @notice Last time that rewardPerTokenStored is updated. Happens whenever total stakes going to be changed.
    uint public lastUpdateTime;
    /**
     * @notice The minium cool down time before user can burn kUSD after they mint kUSD everytime.
     * This is to raise risk and cost to arbitrageurs who front run our prices updates in oracle to drain profit from stakers.
     * Should be larger then minium price post interval.
     */
    uint public burnCooldownTime;

    struct AccountRewardDetail {
        /// @dev Last time account claimed its reward
        uint lastClaimTime;
        /// @dev RewardPerTokenStored at last time accrue rewards to this account
        uint rewardPerTokenUpdated;
        /// @dev Accrued rewards haven't been claimed of this account
        uint accruedReward;
        /// @dev Last time account mint kUSD
        uint lastMintTime;
    }

    /// @notice Mapping of account addresses to account reward detail
    mapping(address => AccountRewardDetail) public accountRewardDetails;

    function initialize(address kine_, address kUSD_, address kMCD_, address controller_, address treasury_, address vault_, address rewardDistribution_, uint startTime_, uint rewardDuration_, uint rewardReleasePeriod_) external {
        require(initialized == false, "KUSDMinter can only be initialized once");
        kine = IERC20(kine_);
        kUSD = IKineUSD(kUSD_);
        kMCD = IKMCD(kMCD_);
        controller = KineControllerInterface(controller_);
        treasury = treasury_;
        vault = vault_;
        rewardDistribution = rewardDistribution_;
        startTime = startTime_;
        rewardDuration = rewardDuration_;
        rewardReleasePeriod = rewardReleasePeriod_;
        initialized = true;
    }

    /**
     * @dev Local vars in calculating equivalent amount between KUSD and Kine MCD
     */
    struct CalculateVars {
        uint equivalentKMCDAmount;
        uint equivalentKUSDAmount;
    }

    /// @notice Prevent stakers' actions before start time
    modifier checkStart() {
        require(block.timestamp >= startTime, "not started yet");
        _;
    }

    /// @notice Prevent accounts other than treasury to mint/burn KUSD
    modifier onlyTreasury() {
        require(msg.sender == treasury, "only treasury account is allowed");
        _;
    }

    modifier afterCooldown(address staker) {
        require(accountRewardDetails[staker].lastMintTime.add(burnCooldownTime) < block.timestamp, "burn still cooling down");
        _;
    }

    /***
     * @notice Accrue account's rewards and store this time accrued results
     * @param account Reward status of whom to be updated
     */
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            accountRewardDetails[account].accruedReward = earned(account);
            accountRewardDetails[account].rewardPerTokenUpdated = rewardPerTokenStored;
            if (accountRewardDetails[account].lastClaimTime == 0) {
                accountRewardDetails[account].lastClaimTime = block.timestamp;
            }
        }
        _;
    }

    /**
     * @notice Current time which hasn't past this round reward's duration.
     * @return Current timestamp that hasn't past this round rewards' duration.
     */
    function lastTimeRewardApplicable() public view returns (uint) {
        return Math.min(block.timestamp, periodFinish);
    }

    /**
     * @notice Calculate new accrued reward per staked Kine MCD.
     * @return Current accrued reward per staked Kine MCD.
     */
    function rewardPerToken() public view returns (uint) {
        uint totalStakes = totalStakes();
        if (totalStakes == 0) {
            return rewardPerTokenStored;
        }
        return
        rewardPerTokenStored.add(
            lastTimeRewardApplicable()
            .sub(lastUpdateTime)
            .mul(rewardRate)
            .mul(1e18)
            .div(totalStakes)
        );
    }

    /**
     * @notice Calculate account's earned rewards so far.
     * @param account Which account to be viewed.
     * @return Account's earned rewards so far.
     */
    function earned(address account) public view returns (uint) {
        return accountStakes(account)
        .mul(rewardPerToken().sub(accountRewardDetails[account].rewardPerTokenUpdated))
        .div(1e18)
        .add(accountRewardDetails[account].accruedReward);
    }

    /**
     * @notice Calculate account's claimable rewards so far.
     * @param account Which account to be viewed.
     * @return Account's claimable rewards so far.
     */
    function claimable(address account) external view returns (uint) {
        uint accountNewAccruedReward = earned(account);
        uint pastTime = block.timestamp.sub(accountRewardDetails[account].lastClaimTime);
        uint maturedReward = rewardReleasePeriod == 0 ? accountNewAccruedReward : accountNewAccruedReward.mul(pastTime).div(rewardReleasePeriod);
        if (maturedReward > accountNewAccruedReward) {
            maturedReward = accountNewAccruedReward;
        }
        return maturedReward;
    }

    /**
    * @notice Mint will borrow equivalent Kine MCD for user, stake borrowed MCD and mint specified amount of KUSD. Call will fail if hasn't reached start time.
    * Mint will fail if hasn't reach start time.
    * @param kUSDAmount The amount of KUSD user want to mint
    */
    function mint(uint kUSDAmount) external checkStart updateReward(msg.sender) {
        address payable msgSender = _msgSender();
        // update sender's mint time
        accountRewardDetails[msgSender].lastMintTime = block.timestamp;

        uint kMCDPriceMantissa = KineOracleInterface(controller.getOracle()).getUnderlyingPrice(address(kMCD));
        require(kMCDPriceMantissa != 0, "Mint: get Kine MCD price zero");

        CalculateVars memory vars;

        // KUSD has 18 decimals
        // KMCD has 18 decimals
        // kMCDPriceMantissa is KMCD's price (quoted by KUSD, has 6 decimals) scaled by 1e36 / KMCD's decimals = 1e36 / 1e18 = 1e18
        // so the calculation of equivalent Kine MCD amount is as below
        //                          kUSDAmount        1e12 * 1e6               kUSDAmount * 1e18
        // equivalentKMCDAmount =  ----------- *  ------------------ * 1e18 =  -----------------
        //                             1e18         kMCDPriceMantissa           kMCDPriceMantissa

        vars.equivalentKMCDAmount = kUSDAmount.mul(1e18).div(kMCDPriceMantissa);

        // call KMCD contract to borrow Kine MCD for user and stake them
        kMCD.borrowBehalf(msgSender, vars.equivalentKMCDAmount);

        // mint KUSD to user
        kUSD.mint(msgSender, kUSDAmount);

        emit Mint(msgSender, kUSDAmount, vars.equivalentKMCDAmount, accountStakes(msgSender), totalStakes());
    }

    /**
    * @notice Burn repay equivalent Kine MCD for user and burn specified amount of KUSD
    * Burn will fail if hasn't reach start time.
    * @param kUSDAmount The amount of KUSD user want to burn
    */
    function burn(uint kUSDAmount) external checkStart afterCooldown(msg.sender) updateReward(msg.sender) {
        address msgSender = _msgSender();

        // burn user's KUSD
        kUSD.burn(msgSender, kUSDAmount);

        // calculate equivalent Kine MCD amount to specified amount of KUSD
        uint kMCDPriceMantissa = KineOracleInterface(controller.getOracle()).getUnderlyingPrice(address(kMCD));
        require(kMCDPriceMantissa != 0, "Burn: get Kine MCD price zero");

        CalculateVars memory vars;

        // KUSD has 18 decimals
        // KMCD has 18 decimals
        // kMCDPriceMantissa is KMCD's price (quoted by KUSD, has 6 decimals) scaled by 1e36 / KMCD's decimals = 1e36 / 1e18 = 1e18
        // so the calculation of equivalent Kine MCD amount is as below
        //                          kUSDAmount        1e12 * 1e6               kUSDAmount * 1e18
        // equivalentKMCDAmount =  ----------- *  ------------------ * 1e18 =  -----------------
        //                             1e18         kMCDPriceMantissa           kMCDPriceMantissa

        vars.equivalentKMCDAmount = kUSDAmount.mul(1e18).div(kMCDPriceMantissa);

        // call KMCD contract to repay Kine MCD for user
        kMCD.repayBorrowBehalf(msgSender, vars.equivalentKMCDAmount);

        emit Burn(msgSender, kUSDAmount, vars.equivalentKMCDAmount, accountStakes(msgSender), totalStakes());
    }

    /**
    * @notice BurnMax unstake and repay all borrowed Kine MCD for user and burn equivalent KUSD
    */
    function burnMax() external checkStart afterCooldown(msg.sender) updateReward(msg.sender) {
        address msgSender = _msgSender();

        uint kMCDPriceMantissa = KineOracleInterface(controller.getOracle()).getUnderlyingPrice(address(kMCD));
        require(kMCDPriceMantissa != 0, "BurnMax: get Kine MCD price zero");

        CalculateVars memory vars;

        // KUSD has 18 decimals
        // KMCD has 18 decimals
        // kMCDPriceMantissa is KMCD's price (quoted by KUSD, has 6 decimals) scaled by 1e36 / KMCD's decimals = 1e36 / 1e18 = 1e18
        // so the calculation of equivalent KUSD amount is as below
        //                         accountStakes     kMCDPriceMantissa         accountStakes * kMCDPriceMantissa
        // equivalentKUSDAmount =  ------------- *  ------------------ * 1e18 = ---------------------------------
        //                             1e18            1e12 * 1e6                          1e18
        //

        // try to unstake all Kine MCD
        uint userStakes = accountStakes(msgSender);
        vars.equivalentKMCDAmount = userStakes;
        vars.equivalentKUSDAmount = userStakes.mul(kMCDPriceMantissa).div(1e18);

        // in case user's kUSD is not enough to unstake all mcd, then just burn all kUSD and unstake part of MCD
        uint kUSDbalance = kUSD.balanceOf(msgSender);
        if (vars.equivalentKUSDAmount > kUSDbalance) {
            vars.equivalentKUSDAmount = kUSDbalance;
            vars.equivalentKMCDAmount = kUSDbalance.mul(1e18).div(kMCDPriceMantissa);
        }

        // burn user's equivalent KUSD
        kUSD.burn(msgSender, vars.equivalentKUSDAmount);

        // call KMCD contract to repay Kine MCD for user
        kMCD.repayBorrowBehalf(msgSender, vars.equivalentKMCDAmount);

        emit BurnMax(msgSender, vars.equivalentKUSDAmount, vars.equivalentKMCDAmount, accountStakes(msgSender), totalStakes());
    }

    /**
     * @notice Caller liquidates the staker's Kine MCD and seize staker's collateral.
     * Liquidate will fail if hasn't reach start time.
     * @param staker The staker of Kine MCD to be liquidated.
     * @param unstakeKMCDAmount The amount of Kine MCD to unstake.
     * @param maxBurnKUSDAmount The max amount limit of KUSD of liquidator to be burned.
     * @param kTokenCollateral The market in which to seize collateral from the staker.
     */
    function liquidate(address staker, uint unstakeKMCDAmount, uint maxBurnKUSDAmount, address kTokenCollateral) external checkStart updateReward(staker) {
        address msgSender = _msgSender();

        uint kMCDPriceMantissa = KineOracleInterface(controller.getOracle()).getUnderlyingPrice(address(kMCD));
        require(kMCDPriceMantissa != 0, "Liquidate: get Kine MCD price zero");

        CalculateVars memory vars;

        // KUSD has 18 decimals
        // KMCD has 18 decimals
        // kMCDPriceMantissa is KMCD's price (quoted by KUSD, has 6 decimals) scaled by 1e36 / KMCD's decimals = 1e36 / 1e18 = 1e18
        // so the calculation of equivalent KUSD amount is as below
        //                         accountStakes     kMCDPriceMantissa         accountStakes * kMCDPriceMantissa
        // equivalentKUSDAmount =  ------------- *  ------------------ * 1e18 = ---------------------------------
        //                             1e18            1e12 * 1e6                          1e30
        //

        vars.equivalentKUSDAmount = unstakeKMCDAmount.mul(kMCDPriceMantissa).div(1e18);

        require(maxBurnKUSDAmount >= vars.equivalentKUSDAmount, "Liquidate: reach out max burn KUSD amount limit");

        // burn liquidator's KUSD
        kUSD.burn(msgSender, vars.equivalentKUSDAmount);

        // call KMCD contract to liquidate staker's Kine MCD and seize collateral
        kMCD.liquidateBorrowBehalf(msgSender, staker, unstakeKMCDAmount, kTokenCollateral);

        emit Liquidate(msgSender, staker, vars.equivalentKUSDAmount, unstakeKMCDAmount, accountStakes(staker), totalStakes());
    }

    /**
     * @notice Show account's staked Kine MCD amount
     * @param account The account to be get MCD amount from
     */
    function accountStakes(address account) public view returns (uint) {
        return kMCD.borrowBalance(account);
    }

    /// @notice Show total staked Kine MCD amount
    function totalStakes() public view returns (uint) {
        return kMCD.totalBorrows();
    }

    /**
     * @notice Claim the matured rewards of caller.
     * Claim will fail if hasn't reach start time.
     */
    function getReward() external checkStart updateReward(msg.sender) {
        uint reward = accountRewardDetails[msg.sender].accruedReward;
        if (reward > 0) {
            uint pastTime = block.timestamp.sub(accountRewardDetails[msg.sender].lastClaimTime);
            uint maturedReward = rewardReleasePeriod == 0 ? reward : reward.mul(pastTime).div(rewardReleasePeriod);
            if (maturedReward > reward) {
                maturedReward = reward;
            }

            accountRewardDetails[msg.sender].accruedReward = reward.sub(maturedReward);
            accountRewardDetails[msg.sender].lastClaimTime = block.timestamp;
            kine.safeTransfer(msg.sender, maturedReward);
            emit RewardPaid(msg.sender, maturedReward);
        }
    }

    /**
     * @notice Notify rewards has been added, trigger a new round of reward period, recalculate reward rate and duration end time.
     * If distributor notify rewards before this round duration end time, then the leftover rewards of this round will roll over to
     * next round and will be distributed together with new rewards in next round of reward period.
     * @param reward How many of rewards has been added for new round of reward period.
     */
    function notifyRewardAmount(uint reward) external onlyRewardDistribution updateReward(address(0)) {
        if (block.timestamp > startTime) {
            if (block.timestamp >= periodFinish) {
                // @dev to avoid of rewardPerToken calculation overflow (see https://sips.synthetix.io/sips/sip-77), we check the reward to be inside a properate range
                // which is 2^256 / 10^18
                require(reward < REWARD_OVERFLOW_CHECK, "reward rate will overflow");
                rewardRate = reward.div(rewardDuration);
            } else {
                uint remaining = periodFinish.sub(block.timestamp);
                uint leftover = remaining.mul(rewardRate);
                // @dev to avoid of rewardPerToken calculation overflow (see https://sips.synthetix.io/sips/sip-77), we check the reward to be inside a properate range
                // which is 2^256 / 10^18
                require(reward.add(leftover) < REWARD_OVERFLOW_CHECK, "reward rate will overflow");
                rewardRate = reward.add(leftover).div(rewardDuration);
            }
            lastUpdateTime = block.timestamp;
            periodFinish = block.timestamp.add(rewardDuration);
            emit RewardAdded(reward);
        } else {
            // @dev to avoid of rewardPerToken calculation overflow (see https://sips.synthetix.io/sips/sip-77), we check the reward to be inside a properate range
            // which is 2^256 / 10^18
            require(reward < REWARD_OVERFLOW_CHECK, "reward rate will overflow");
            rewardRate = reward.div(rewardDuration);
            lastUpdateTime = startTime;
            periodFinish = startTime.add(rewardDuration);
            emit RewardAdded(reward);
        }
    }

    /**
     * @notice Set new reward duration, will start a new round of reward period immediately and recalculate rewardRate.
     * @param newRewardDuration New duration of each reward period round.
     */
    function _setRewardDuration(uint newRewardDuration) external onlyOwner updateReward(address(0)) {
        uint oldRewardDuration = rewardDuration;
        rewardDuration = newRewardDuration;

        if (block.timestamp > startTime) {
            if (block.timestamp >= periodFinish) {
                rewardRate = 0;
            } else {
                uint remaining = periodFinish.sub(block.timestamp);
                uint leftover = remaining.mul(rewardRate);
                rewardRate = leftover.div(rewardDuration);
            }
            lastUpdateTime = block.timestamp;
            periodFinish = block.timestamp.add(rewardDuration);
        } else {
            rewardRate = rewardRate.mul(oldRewardDuration).div(rewardDuration);
            lastUpdateTime = startTime;
            periodFinish = startTime.add(rewardDuration);
        }

        emit NewRewardDuration(oldRewardDuration, newRewardDuration);
    }

    /**
     * @notice Set new reward release period. The unclaimed rewards will be affected immediately.
     * @param newRewardReleasePeriod New release period of how long all earned rewards will be matured each time
     * before user claim reward.
     */
    function _setRewardReleasePeriod(uint newRewardReleasePeriod) external onlyOwner updateReward(address(0)) {
        uint oldRewardReleasePeriod = rewardReleasePeriod;
        rewardReleasePeriod = newRewardReleasePeriod;
        emit NewRewardReleasePeriod(oldRewardReleasePeriod, newRewardReleasePeriod);
    }

    function _setCooldownTime(uint newCooldownTime) external onlyOwner {
        uint oldCooldown = burnCooldownTime;
        burnCooldownTime = newCooldownTime;
        emit NewBurnCooldownTime(oldCooldown, newCooldownTime);
    }

    /**
     * @notice Mint KUSD to treasury account to keep on-chain KUSD consist with off-chain trading system
     * @param amount The amount of KUSD to mint to treasury
     */
    function treasuryMint(uint amount) external onlyTreasury {
        kUSD.mint(vault, amount);
        emit TreasuryMint(amount);
    }

    /**
     * @notice Burn KUSD from treasury account to keep on-chain KUSD consist with off-chain trading system
     * @param amount The amount of KUSD to burn from treasury
     */
    function treasuryBurn(uint amount) external onlyTreasury {
        kUSD.burn(vault, amount);
        emit TreasuryBurn(amount);
    }

    /**
     * @notice Change treasury account to a new one
     * @param newTreasury New treasury account address
     */
    function _setTreasury(address newTreasury) external onlyOwner {
        address oldTreasury = treasury;
        treasury = newTreasury;
        emit NewTreasury(oldTreasury, newTreasury);
    }

    /**
     * @notice Change vault account to a new one
     * @param newVault New vault account address
     */
    function _setVault(address newVault) external onlyOwner {
        address oldVault = vault;
        vault = newVault;
        emit NewVault(oldVault, newVault);
    }

    /**
     * @notice Change KMCD contract address to a new one.
     * @param newKMCD New KMCD contract address.
     */
    function _setKMCD(address newKMCD) external onlyOwner {
        address oldKMCD = address(kMCD);
        kMCD = IKMCD(newKMCD);
        emit NewKMCD(oldKMCD, newKMCD);
    }

    /**
     * @notice Change KUSD contract address to a new one.
     * @param newKUSD New KineUSD contract address.
     */
    function _setKUSD(address newKUSD) external onlyOwner {
        address oldKUSD = address(kUSD);
        kUSD = IKineUSD(newKUSD);
        emit NewKUSD(oldKUSD, newKUSD);
    }

    /**
     * @notice Change Kine contract address to a new one.
     * @param newKine New Kine contract address.
     */
    function _setKine(address newKine) external onlyOwner {
        address oldKine = address(kine);
        kine = IERC20(newKine);
        emit NewKine(oldKine, newKine);
    }
    /**
     * @notice Change Kine Controller address to a new one.
     * @param newController New Controller contract address.
     */
    function _setController(address newController) external onlyOwner {
        address oldController = address(controller);
        controller = KineControllerInterface(newController);
        emit NewController(oldController, newController);
    }
}

pragma solidity ^0.5.16;

import "./Ownable.sol";

/**
 * @title KUSDMinterDelegate
 * @author Kine
 */
contract KUSDMinterDelegate is Ownable {
    /**
     * @notice Emitted when implementation is changed
     */
    event NewImplementation(address oldImplementation, address newImplementation);

    /**
     * @notice Implementation address
     */
    address public implementation;
}

pragma solidity ^0.5.16;

import "./KUSDMinter.sol";
import "./KineOracleInterface.sol";
import "./KineControllerInterface.sol";
import "./Ownable.sol";
import "./KineSafeMath.sol";

pragma experimental ABIEncoderV2;

/**
 * @title Kaptain allows Kine oracle reporter to report Kine token price and balance change of kUSD vault at the same time,
 * meanwhile will calculate the new MCD price according to new kUSD total supply and kMCD total amount.
 * Prices will be post to Kine oracle, and kUSD vault balance change will be submit to kUSD minter.
 * @author Kine
 */
contract Kaptain is Ownable {
    using KineSafeMath for uint;
    /// @notice Emitted when controller changed
    event NewController(address oldController, address newController);
    /// @notice Emitted when kUSD minter changed
    event NewMinter(address oldMinter, address newMinter);
    /// @notice Emitted when kUSD address changed
    event NewKUSD(address oldKUSD, address newKUSD);
    /// @notice Emitted when steered
    event Steer(uint256 scaledMCDPrice, bool isVaultIncreased, uint256 vaultKusdDelta, uint256 reporterNonce);
    /// @notice Emitted when poster changed
    event NewPoster(address oldPoster, address newPoster);

    /// @notice Oracle which gives the price of given asset
    KineControllerInterface public controller;
    /// @notice KUSD minter (see KUSDMinter) only allow treasury to mint/burn KUSD to vault account.
    /// @dev Minter need to set treasury to this Kaptain.
    KUSDMinter public minter;
    /// @notice kUSD address
    IERC20 public kUSD;
    /// @notice Addres of Kine poster
    address public poster;
    /// @notice To prevent replaying reporter signed message and make sure posts are in sequence
    uint public reporterNonce;

    modifier onlyPoster() {
        require(msg.sender == poster, "only poster is allowed");
        _;
    }

    constructor (address controller_, address minter_, address kUSD_, address poster_) public {
        controller = KineControllerInterface(controller_);
        minter = KUSDMinter(minter_);
        kUSD = IERC20(kUSD_);
        poster = poster_;
    }

    /**
     * @notice Owner is Kine oracle prices poster, it post Kine tokens' price and mint/burn kUSD to vault account according to Kine synthetic assets total value states.
     * @param message Signed price data of tokens and kUSD vault balance change
     * @param signature Signature used to recover reporter public key
     */
    function steer(bytes calldata message, bytes calldata signature) external onlyPoster {
        // recover message signer
        address source = source(message, signature);

        // check if signer is Kine oracle reporter
        KineOracleInterface oracle = KineOracleInterface(controller.getOracle());
        require(source == oracle.reporter(), "only accept reporter signed message");

        // decode message
        (bytes[] memory messages, bytes[] memory signatures, string[] memory symbols, uint256 vaultKusdDelta, bool isVaultIncreased, uint256 nonce) = abi.decode(message, (bytes[], bytes[], string[], uint256, bool, uint256));
        // check if nonce is exactly +1, to make sure posts are in sequence
        reporterNonce = reporterNonce.add(1);
        require(reporterNonce == nonce, "bad reporter nonce");

        // call minter to update kUSD total supply
        if (isVaultIncreased) {
            minter.treasuryMint(vaultKusdDelta);
        } else {
            minter.treasuryBurn(vaultKusdDelta);
        }

        // calculate new kMCD price
        uint kMCDTotal = minter.totalStakes();
        uint kUSDTotal = kUSD.totalSupply();

        // kUSD has 18 decimals
        // kMCD has 18 decimals
        // mcdPrice = kUSD total supply / kMCD total amount * 1e6 (scaling factor)
        // if there is no borrowed kMCD, then the kMCD price will be set to inital value 1.
        uint mcdPrice;
        if(kMCDTotal == 0) {
            mcdPrice = 1e6;
        } else {
            mcdPrice = kUSDTotal.mul(1e18).div(kMCDTotal).div(1e12);
        }

        // post kMCD price to oracle, kMCD price will never be guarded by oracle.
        oracle.postMcdPrice(mcdPrice);

        // post Kine token price to oracle
        // @dev it's ok that post Kine price might be guarded.
        oracle.postPrices(messages, signatures, symbols);

        emit Steer(mcdPrice, isVaultIncreased, vaultKusdDelta, reporterNonce);
    }

    /**
     * @notice Recovers the source address which signed a message
     * @dev Comparing to a claimed address would add nothing,
     *  as the caller could simply perform the recover and claim that address.
     * @param message The data that was presumably signed
     * @param signature The fingerprint of the data + private key
     * @return The source address which signed the message, presumably
     */
    function source(bytes memory message, bytes memory signature) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = abi.decode(signature, (bytes32, bytes32, uint8));
        bytes32 hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(message)));
        return ecrecover(hash, v, r, s);
    }

    /// @notice Change oracle to new one
    function _setController(address newController) external onlyOwner {
        address oldController = address(controller);
        controller = KineControllerInterface(newController);
        emit NewController(oldController, newController);
    }

    /// @notice Change minter to new one
    function _setMinter(address newMinter) external onlyOwner {
        address oldMinter = address(minter);
        minter = KUSDMinter(newMinter);
        emit NewMinter(oldMinter, newMinter);
    }

    /// @notice Change kUSD to new one
    function _setKUSD(address newKUSD) external onlyOwner {
        address oldKUSD = address(kUSD);
        kUSD = IERC20(newKUSD);
        emit NewKUSD(oldKUSD, newKUSD);
    }

    /// @notice Change Poster to new one
    function _setPoster(address newPoster) external onlyOwner {
        address oldPoster = poster;
        poster = newPoster;
        emit NewPoster(oldPoster, newPoster);
    }
}

pragma solidity ^0.5.16;

/**
Copyright 2020 Compound Labs, Inc.
Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
* Original work from Compound: https://github.com/compound-finance/compound-protocol/blob/master/contracts/ComptrollerInterface.sol
* Modified to work in the Kine system.
* Main modifications:
*   1. removed Comp token related logics.
*   2. removed interest rate model related logics.
*   3. removed error code propagation mechanism to fail fast and loudly
*/

contract KineControllerInterface {
    /// @notice Indicator that this is a Controller contract (for inspection)
    bool public constant isController = true;

    /// @notice oracle getter function
    function getOracle() external view returns (address);

    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata kTokens) external;

    function exitMarket(address kToken) external;

    /*** Policy Hooks ***/

    function mintAllowed(address kToken, address minter, uint mintAmount) external returns (bool, string memory);

    function mintVerify(address kToken, address minter, uint mintAmount, uint mintTokens) external;

    function redeemAllowed(address kToken, address redeemer, uint redeemTokens) external returns (bool, string memory);

    function redeemVerify(address kToken, address redeemer, uint redeemTokens) external;

    function borrowAllowed(address kToken, address borrower, uint borrowAmount) external returns (bool, string memory);

    function borrowVerify(address kToken, address borrower, uint borrowAmount) external;

    function repayBorrowAllowed(
        address kToken,
        address payer,
        address borrower,
        uint repayAmount) external returns (bool, string memory);

    function repayBorrowVerify(
        address kToken,
        address payer,
        address borrower,
        uint repayAmount) external;

    function liquidateBorrowAllowed(
        address kTokenBorrowed,
        address kTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount) external returns (bool, string memory);

    function liquidateBorrowVerify(
        address kTokenBorrowed,
        address kTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount,
        uint seizeTokens) external;

    function seizeAllowed(
        address kTokenCollateral,
        address kTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external returns (bool, string memory);

    function seizeVerify(
        address kTokenCollateral,
        address kTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external;

    function transferAllowed(address kToken, address src, address dst, uint transferTokens) external returns (bool, string memory);

    function transferVerify(address kToken, address src, address dst, uint transferTokens) external;

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address kTokenBorrowed,
        address kTokenCollateral,
        uint repayAmount) external view returns (uint);
}

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

/**
 * @title KineOracleInterface brief abstraction of Price Oracle
 */
interface KineOracleInterface {

    /**
     * @notice Get the underlying collateral price of given kToken.
     * @dev Returned kToken underlying price is scaled by 1e(36 - underlying token decimals)
     */
    function getUnderlyingPrice(address kToken) external view returns (uint);

    /**
     * @notice Post prices of tokens owned by Kine.
     * @param messages Signed price data of tokens
     * @param signatures Signatures used to recover reporter public key
     * @param symbols Token symbols
     */
    function postPrices(bytes[] calldata messages, bytes[] calldata signatures, string[] calldata symbols) external;

    /**
     * @notice Post Kine MCD price.
     */
    function postMcdPrice(uint mcdPrice) external;

    /**
     * @notice Get the reporter address.
     */
    function reporter() external returns (address);
}

pragma solidity ^0.5.0;

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

/**
 * Original work from OpenZeppelin: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/math/SafeMath.sol
 * changes we made:
 * 1. add two methods that take errorMessage as input parameter
 */

library KineSafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     * added by Kine
     */
    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     * added by Kine
     */
    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errorMessage);

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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

pragma solidity ^0.5.0;

import "./Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.5.0;

import "./IERC20.sol";
import "./KineSafeMath.sol";
import "./Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using KineSafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}