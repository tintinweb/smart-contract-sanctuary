//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ETHFeed.sol";
import "./LiquidityLockConfig.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./IAdvisorPool.sol";


contract LiquidityLock is Ownable {

    // Date-related constants for sanity-checking dates to reject obvious erroneous inputs
    // and conversions from seconds to days and years that are more or less leap year-aware.
    uint32 private constant SECONDS_PER_DAY = 24 * 60 * 60;                 /* 86400 seconds in a day */

    uint8 private constant MAX_FAIL_AMOUNT = 3;

    // Event Data

    // Emitted when a staked user are given their rewards
    event RewardPaid(address indexed user, uint256 reward);

    // Emitted when the execute() function is called
    event Locked(uint256 bznPrice, uint256 weiTotal, uint256 lpTokenTotal, uint256 bznExtra);

    // Emitted when a user deposits Eth
    event Deposit(address indexed user, uint256 amount);

    // Emitted when a user deposits Eth
    event Withdraw(address indexed user, uint256 amount);

    // Emitted when a user redeems either the LP Token or the Extra BZN
    event RedeemedToken(address indexed user, address indexed token, uint256 amount);

    // Emitted when the contract gets disabled and funds are refunded
    event Disabled(string reason);

    // Set to true when the execute() is called
    // deposit() only works when executed = false
    // Redeem functions only work when executed = true
    bool public executed;

    // General config data
    LiquidityLockData public config;
    
    bool private disabled;

    // deposit data
    mapping(address => uint256) public amounts;
    // All users who have deposited
    address[] internal depositors;
    mapping(address => uint256) depositorIndexed;

    // locking data
    struct UserLockingData {
        bool isActive;
        address user;
        uint256 lockStartTime;
        uint256 lpTokenTotal;
        uint256 bznExtraTotal;
    }
    // Locking data for each user
    mapping(address => UserLockingData) public userData;

    // Token Vesting Grant data
    struct tokenGrant {
        bool isActive;              /* true if this vesting entry is active and in-effect entry. */
        uint32 startDay;            /* Start day of the grant, in days since the UNIX epoch (start of day). */
        uint256 amount;             /* Total number of tokens that vest. */
    }

    // Global vesting schedule
    vestingSchedule _tokenVestingSchedule;
    // Token Vesting grants for each user for LP Tokens
    mapping(address => tokenGrant) private _lpTokenGrants;
    // Token Vesting grants for each user for BZN Tokens
    mapping(address => tokenGrant) private _bznTokenGrants;

    // staking data
    IERC20 internal immutable _rewardToken;
    // staking schedule data
    stakingSchedule _tokenStakingSchedule;

    // The last timestamp a user claimed rewards
    mapping(address => uint256) internal _lastClaimTime;
    // The amount of rewards a user has claimed
    mapping(address => uint256) public amountClaimed;

    constructor(LiquidityLockConfig memory _config) {
        _tokenVestingSchedule = _config.schedule;
        _tokenStakingSchedule = stakingSchedule(false, 0, 0, 0, 0);

        config = _config.data;

        _rewardToken = IERC20(config.bznAddress);
    }

    modifier isActive {
        require(!disabled, "Contract is disabled");
        require(!executed, "No longer active");
        _;
    }

    modifier hasExecuted {
        require(!disabled, "Contract is disabled");
        require(executed, "Waiting for execute");
        _;
    }

    modifier isStakingActive {
        require(!disabled, "Contract is disabled");
        require(_tokenStakingSchedule.isActive, "Staking is not active");
        _;
    }

    /**
    * @dev Lets a user deposit ETH to participate in LiquidityLocking. The amount of
    * ETH sent must meet the minimum USD price set
    * Can only be invoked before the execute() function is called by the owner
    */
    function deposit() external payable isActive {
        require(msg.value > 0, "Must send some ether");
        require(msg.sender != config.recipient, "Recipient cant deposit");
        require(msg.sender != owner(), "Owner cant deposit");

        require(msg.value >= config.minimum, "Must send at least the minimum");

        if (amounts[msg.sender] == 0) {
            depositors.push(msg.sender);
        }

        amounts[msg.sender] += msg.value;

        emit Deposit(msg.sender, msg.value);
    }

    /**
    * @dev Lets a user withdraw ETH to un-participate in LiquidityLocking. The amount of
    * ETH being withdrawn must either
    * 1. Be all the ETH that was deposited by the sender
    * 2. Must keep the remaining deposit for the sender above the configured minimum deposit
    * Can only be invoked before the execute() function is called by the owner
    * @param amount The amount of ETH (in wei) to withdraw
    */
    function withdraw(uint256 amount) external payable isActive {
        require(amount > 0, "Withdraw amount must be greater than 0");

        uint256 currentAmount = amounts[msg.sender];

        require(amount <= currentAmount, "Withdraw amount to high");

        require(currentAmount - amount >= config.minimum || currentAmount - amount == 0, "Withdraw amount must not put you below the minimum or must be all");

        amounts[msg.sender] -= amount;

        if (amounts[msg.sender] == 0) {
            //Remove from depositors
            uint256 lastDepositorIndex = depositors.length - 1;
            uint256 depositorIndex = depositorIndexed[msg.sender];

            // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
            // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
            // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
            address lastDepositor = depositors[lastDepositorIndex];

            depositors[depositorIndex] = lastDepositor; // Move the last token to the slot of the to-delete token
            depositorIndexed[lastDepositor] = depositorIndex; // Update the moved token's index

            // This also deletes the contents at the last position of the array
            delete depositorIndexed[msg.sender];
            depositors.pop();
        }

        address payable recipient = payable(msg.sender);

        recipient.transfer(amount);

        emit Withdraw(msg.sender, amount);
    }

    /**
    * @dev Execute the LiquidityLock, locking all deposited Eth
    * in the Uniswap v2 Liquidity Pool for ETH/BZN
    * 
    * The LP Tokens retrieved will be distributed to each user proportional 
    * depending on how much each user has deposited. The LP Tokens will then be staked
    * and vested, so the user may only redeem their LP tokens after a certain cliff period
    * and linearly depending on the vesting schedule. If a user chooses to keep their 
    * LP tokens locked in this contract, then they will earn staking rewards
    *
    * Any extra BZN that did not make it into the Liquidity pool will also be 
    * distributed to each user proportionally depending on how much each user has deposited. The
    * extra BZN will also be vested using the same vesting schedule as the LP Tokens, but they will
    * not earn staking rewards
    */
    function execute() external onlyOwner isActive {
        if (block.timestamp > config.dueDate) {
            _refund("Due date passed");
            return;
        }

        //First we need to grab all of the BZN and bring it here
        IERC20 bzn = IERC20(config.bznAddress);
        IAdvisorPool pool = IAdvisorPool(config.bznSource);

        require(pool.owner() == address(this), "Advisor Pool must be the owner");

        uint256 currentBalance = address(this).balance;
        uint256 weiTotal = currentBalance / 2;
        uint256 recipientAmount = currentBalance - weiTotal;

        uint256 bznAmount = weiTotal * config.bznRatio;

        require(bznAmount >= config.bznSoftLimit, "BZN Amount must be at least the soft limit");
        require(bznAmount < config.bznHardLimit, "BZN Amount exceeds the hard limit");

        //Now transfer the amount we need from the Advisor pool to us
        pool.transfer(address(this), bznAmount);

        uint liquidityAmount = 0;
        uint256 bznExtra = 0;
        IERC20 lpToken;
        {
            uint amountToken; uint amountETH; 

            //Now we to figure out how much BZN[wei] we are putting up per ETH[wei]
            uint256 amountETHDesired = weiTotal;
            uint256 amountTokenDesired = bznAmount;
            
            //This is 1%
            uint256 amountTokenMin = amountTokenDesired - ((amountTokenDesired * 100) / 10000);
            uint256 amountETHMin = amountETHDesired - ((amountETHDesired * 100) / 10000);

            IUniswapV2Router02 uniswap = IUniswapV2Router02(config.uniswapRouter);

            (amountToken, amountETH, liquidityAmount) = uniswap.addLiquidityETH{value:amountETHDesired}(config.bznAddress, amountTokenDesired, amountTokenMin, amountETHMin, address(this), block.timestamp);
            bznExtra = bznAmount - amountToken;

            lpToken = IERC20(IUniswapV2Factory(uniswap.factory()).getPair(config.bznAddress, config.weth));
        }

        //Transfer the reward amount to us
        _tokenStakingSchedule.rewardAmount = config.staking.totalRewardAmount;
        pool.transfer(address(this), config.staking.totalRewardAmount);
        beginRewardPeriod(config.staking.duration, config.staking.isLinear);

        //Now that we have the LP Tokens, lets distrubte these LP Tokens to depositors
        for (uint i = 0; i < depositors.length; i++) {
            address user = depositors[i];
            uint256 userAmount = amounts[user];

            uint256 lpTokenAmount = (liquidityAmount * userAmount) / weiTotal;
            uint256 bznAmount = (bznExtra * userAmount) / weiTotal;

            userData[user] = UserLockingData(
                true,
                user,
                block.timestamp,
                lpTokenAmount,
                bznAmount
            );

            _lpTokenGrants[user] = tokenGrant(
                true/*isActive*/,
                today(),
                lpTokenAmount
            );

            _bznTokenGrants[user] = tokenGrant(
                true,
                today(),
                bznAmount
            );
        }

        executed = true;

        config.recipient.transfer(recipientAmount);
        pool.transferOwnership(config.recipient);

        emit Locked(config.bznRatio, weiTotal, liquidityAmount, bznExtra);
    }

    function _refund(string memory reason) internal {
        disabled = true;

        //Now that we have to refund everyone
        for (uint i = 0; i < depositors.length; i++) {
            address payable user = payable(depositors[i]);
            uint256 userAmount = amounts[user];

            user.transfer(userAmount);
        }

        IAdvisorPool pool = IAdvisorPool(config.bznSource);
        pool.transferOwnership(config.recipient);

        emit Disabled(reason);
    }

    /**
    * @dev Start the staking reward period. Only invoked inside execute()
    * @param _duration The length of the staking period
    * @param isLinear Whether the rewards will be given linearly 
    */
    function beginRewardPeriod(uint256 _duration, bool isLinear) internal {
        _tokenStakingSchedule.duration = _duration;
        _tokenStakingSchedule.startTime = block.timestamp;

        if (isLinear) {
            _tokenStakingSchedule.endTime = _tokenStakingSchedule.startTime + _tokenStakingSchedule.duration;
        } else {
            _tokenStakingSchedule.endTime = 0;
        }

        _tokenStakingSchedule.isActive = true;
    }

    /**
    * @dev The current total amount of LP Tokens being staked
    * @return The total amount of LP Tokens being staked
    */
    function totalStaking() public virtual view returns (uint256) {
        IERC20 lpToken = IERC20(getLPTokenAddress());

        return lpToken.balanceOf(address(this));
    }

    /**
    * @dev The current amount of LP Tokens an owner is staking
    * @param account The account to check
    * @return The total amount of LP Tokens being staked by an account
    */
    function stakingOf(address account) public virtual view returns (uint256) {
        return userData[account].lpTokenTotal;
    }

    /**
    * @dev The current amount of rewards in the reward pool
    * @return The total amount of rewards left in the reward pool
    */
    function totalRewardPool() public virtual view returns (uint256) {
        return _tokenStakingSchedule.rewardAmount;
    }

    /**
    * @dev Get the current amount of rewards earned by an owner
    * @param owner The owner to check
    * @return The current amount of rewards earned thus far
    */
    function rewardAmountFor(address owner) public view isStakingActive returns (uint256) {
        if (totalStaking() == 0)
            return 0;

        uint256 amount = totalRewardPool();
        uint256 stakeAmount = stakingOf(owner);

        amount = (amount * stakeAmount) / totalStaking();

        uint256 lastRewardClaimTime = _lastClaimTime[owner];

        if (_tokenStakingSchedule.endTime == 0) {
            //Non-Linear reward peiod
            if (block.timestamp - lastRewardClaimTime < _tokenStakingSchedule.duration) {
                amount = (amount * (block.timestamp - lastRewardClaimTime)) / _tokenStakingSchedule.duration;
            }
        } else if (block.timestamp < _tokenStakingSchedule.endTime) {
            amount = (amount * (block.timestamp - lastRewardClaimTime)) / (_tokenStakingSchedule.endTime - lastRewardClaimTime);
        } else if (lastRewardClaimTime >= _tokenStakingSchedule.endTime) {
            amount = 0;
        }
        
        return amount;
    }

    /**
    * @dev Claim staking rewards on behalf of an owner. This will not unstake any LP Tokens.
    * Staking rewards will be transferred to the owner, regardless of who invokes
    * the function (allows for meta transactions)
    * @param owner The owner to claim staking rewards for
    */
    function claimFor(address owner) public virtual isStakingActive returns (uint256) {
        uint256 amount = rewardAmountFor(owner);
        
        if (amount > 0) {
            _lastClaimTime[owner] = block.timestamp;
            amountClaimed[owner] = amountClaimed[owner] + amount;
            
            _tokenStakingSchedule.rewardAmount -= amount;
            _rewardToken.transfer(owner, amount);
            
            emit RewardPaid(owner, amount);
        }
        
        return amount;
    }

    /**
    * @dev Redeem any vested LP Tokens and claim any rewards the staked LP
    * tokens have earned on behalf of an owner. The vested LP Tokens 
    * and staking rewards will be transferred to the owner regardless of who invokes
    * the function (allows for meta transactions)
    * @param owner The owner of the vested LP Tokens
    */
    function redeemLPTokens(address owner) external hasExecuted {
        require(userData[owner].isActive, "Address has no tokens to redeem");
        require(userData[owner].lpTokenTotal > 0, "No LP Tokens to redeem");

        uint256 vestedAmount = getAvailableLPAmount(owner, today());

        require(vestedAmount > 0, "No tokens vested yet");

        //First give them the rewards they've collected thus far
        claimFor(owner);

        //Then decrement the amount of tokens they have
        userData[owner].lpTokenTotal -= vestedAmount;

        //Then transfer the LP tokens
        IERC20 lpTokens = IERC20(getLPTokenAddress());
        lpTokens.transfer(owner, vestedAmount);
    }

    /**
    * @dev Redeem extra BZN on the behalf of an owner. This will redeem any
    * vested BZN and transfer it back to the owner regardless of who invokes
    * the function (allows for meta transactions)
    * @param owner The owner of the vested BZN
    */
    function redeemExtraBZN(address owner) external hasExecuted {
        require(userData[owner].isActive, "Address has no tokens to redeem");
        require(userData[owner].bznExtraTotal > 0, "No BZN Tokens to redeem");

        uint256 vestedAmount = getAvailableBZNAmount(owner, today());

        require(vestedAmount > 0, "No tokens vested yet");

        //Decrement the amount of tokens they have
        userData[owner].bznExtraTotal -= vestedAmount;

        //Then transfer the LP tokens
        IERC20 bznTokens = IERC20(config.bznAddress);
        bznTokens.transfer(owner, vestedAmount);
    }

    /**
    * @dev Get the address of the LP Token
    */
    function getLPTokenAddress() public view returns (address) {
        IUniswapV2Router02 uniswap = IUniswapV2Router02(config.uniswapRouter);
        return IUniswapV2Factory(uniswap.factory()).getPair(config.bznAddress, config.weth);
    }

    /**
     * @dev returns true if the account has sufficient funds available to cover the given amount,
     *   including consideration for vesting tokens.
     *
     * @param account = The account to check.
     * @param amount = The required amount of vested funds.
     * @param onDay = The day to check for, in days since the UNIX epoch.
     */
    function _LPAreAvailableOn(address account, uint256 amount, uint32 onDay) internal view returns (bool ok) {
        return (amount <= getAvailableLPAmount(account, onDay));
    }

    /**
     * @dev Computes the amount of funds in the given account which are available for use as of
     * the given day. If there's no vesting schedule then 0 tokens are considered to be vested and
     * this just returns the full account balance.
     *
     * The math is: available amount = total funds - notVestedAmount.
     *
     * @param grantHolder = The account to check.
     * @param onDay = The day to check for, in days since the UNIX epoch.
     */
    function getAvailableBZNAmount(address grantHolder, uint32 onDay) internal view returns (uint256 amountAvailable) {
        uint256 totalTokens = userData[grantHolder].bznExtraTotal;
        uint256 vested = totalTokens - _getNotVestedAmount(grantHolder, onDay, _bznTokenGrants[grantHolder]);
        return vested;
    }

     /**
     * @dev Computes the amount of funds in the given account which are available for use as of
     * the given day. If there's no vesting schedule then 0 tokens are considered to be vested and
     * this just returns the full account balance.
     *
     * The math is: available amount = total funds - notVestedAmount.
     *
     * @param grantHolder = The account to check.
     * @param onDay = The day to check for, in days since the UNIX epoch.
     */
    function getAvailableLPAmount(address grantHolder, uint32 onDay) internal view returns (uint256 amountAvailable) {
        uint256 totalTokens = userData[grantHolder].lpTokenTotal;
        uint256 vested = totalTokens - _getNotVestedAmount(grantHolder, onDay, _lpTokenGrants[grantHolder]);
        return vested;
    }

    /**
     * @dev returns the day number of the current day, in days since the UNIX epoch.
     */
    function today() public view returns (uint32 dayNumber) {
        return uint32(block.timestamp / SECONDS_PER_DAY);
    }

    function _effectiveDay(uint32 onDayOrToday) internal view returns (uint32 dayNumber) {
        return onDayOrToday == 0 ? today() : onDayOrToday;
    }

    /**
     * @dev Determines the amount of tokens that have not vested in the given account.
     *
     * The math is: not vested amount = vesting amount * (end date - on date)/(end date - start date)
     *
     * @param grantHolder = The account to check.
     * @param onDayOrToday = The day to check for, in days since the UNIX epoch. Can pass
     *   the special value 0 to indicate today.
     */
    function _getNotVestedAmount(address grantHolder, uint32 onDayOrToday, tokenGrant memory grant) internal view returns (uint256 amountNotVested) {
        uint32 onDay = _effectiveDay(onDayOrToday);

        // If there's no schedule, or before the vesting cliff, then the full amount is not vested.
        if (!grant.isActive || onDay < grant.startDay + _tokenVestingSchedule.cliffDuration)
        {
            // None are vested (all are not vested)
            return grant.amount;
        }
        // If after end of vesting, then the not vested amount is zero (all are vested).
        else if (onDay >= grant.startDay + _tokenVestingSchedule.duration)
        {
            // All are vested (none are not vested)
            return uint256(0);
        }
        // Otherwise a fractional amount is vested.
        else
        {
            // Compute the exact number of days vested.
            uint32 daysVested = onDay - grant.startDay;
            // Adjust result rounding down to take into consideration the interval.
            uint32 effectiveDaysVested = (daysVested / _tokenVestingSchedule.interval) * _tokenVestingSchedule.interval;

            // Compute the fraction vested from schedule using 224.32 fixed point math for date range ratio.
            // Note: This is safe in 256-bit math because max value of X billion tokens = X*10^27 wei, and
            // typical token amounts can fit into 90 bits. Scaling using a 32 bits value results in only 125
            // bits before reducing back to 90 bits by dividing. There is plenty of room left, even for token
            // amounts many orders of magnitude greater than mere billions.
            uint256 vested = (grant.amount * effectiveDaysVested) / _tokenVestingSchedule.duration;
            return grant.amount - vested;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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
pragma solidity ^0.8.0;

interface ETHFeed {
    function priceForEtherInUsdWei() external view returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

struct vestingSchedule {
    bool isValid;               /* true if an entry exists and is valid */
    uint32 cliffDuration;       /* Duration of the cliff, with respect to the grant start day, in days. */
    uint32 duration;            /* Duration of the vesting schedule, with respect to the grant start day, in days. */
    uint32 interval;            /* Duration in days of the vesting interval. */
}

struct stakingSchedule {
    bool isActive;
    uint256 startTime;
    uint256 endTime;
    uint256 duration;
    uint256 rewardAmount;
}

struct stakingConfig {
    uint256 duration;
    bool isLinear;
    uint256 totalRewardAmount;
}

struct LiquidityLockData {
    uint256 minimum;
    address uniswapRouter;
    address bznAddress;
    uint256 bznSoftLimit;
    uint256 bznHardLimit;
    uint256 bznRatio;
    address bznSource; //advisor pool
    address weth;
    address payable recipient;
    stakingConfig staking;
    uint256 dueDate;
}

struct LiquidityLockConfig {
    LiquidityLockData data;
    vestingSchedule schedule;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IAdvisorPool {
    function owner() external view returns (address);

    function transferOwnership(address newOwner) external;

    function transfer(address _beneficiary, uint256 amount) external returns (bool);

    function balance() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

