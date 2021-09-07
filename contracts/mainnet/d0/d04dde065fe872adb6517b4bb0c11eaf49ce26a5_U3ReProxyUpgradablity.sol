/**
 *Submitted for verification at Etherscan.io on 2021-09-07
*/

// Sources flattened with hardhat v2.5.0 https://hardhat.org

// File contracts/abstract/Context.sol

// SPDX-License-Identifier: MIT;

pragma solidity ^0.7.6;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File contracts/security/Pausable.sol


pragma solidity ^0.7.6;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}


// File contracts/abstract/Ownable.sol


pragma solidity ^0.7.6;

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

abstract contract Ownable is Pausable {
    address public _owner;
    address public _admin;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor(address ownerAddress) {
        _owner = msg.sender;
        _admin = ownerAddress;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyAdmin() {
        require(_admin == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyAdmin {
        emit OwnershipTransferred(_owner, _admin);
        _owner = _admin;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


// File contracts/libraries/SafeMath.sol


pragma solidity ^0.7.6;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}


// File contracts/legacy/U3Legacy.sol

pragma solidity ^0.7.6;

abstract contract OwnableV3 {
    function transferOwnership(address newOwner) external virtual;

    function owner() external virtual returns (address);
}

abstract contract Admin is OwnableV3 {
    struct tokenInfo {
        bool isExist;
        uint8 decimal;
        uint256 userMinStake;
        uint256 userMaxStake;
        uint256 totalMaxStake;
        uint256 lockableDays;
        bool optionableStatus;
    }

    uint256 public stakeDuration;
    uint256 public refPercentage;
    uint256 public optionableBenefit;
    mapping(address => address[]) public tokensSequenceList;
    mapping(address => tokenInfo) public tokenDetails;
    mapping(address => mapping(address => uint256))
        public tokenDailyDistribution;
    mapping(address => mapping(address => bool)) public tokenBlockedStatus;

    function safeWithdraw(address tokenAddress, uint256 amount)
        external
        virtual;
}

abstract contract U3Legacy is Admin {
    uint256 public poolStartTime;
    mapping(address => uint256) public totalStaking;

    function viewStakingDetails(address _user)
        external
        view
        virtual
        returns (
            address[] memory,
            address[] memory,
            bool[] memory,
            uint8[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        );
}


// File contracts/proxy/U3Proxy.sol


pragma solidity ^0.7.6;

abstract contract AdminV3Proxy {
    address public oldPaidAddress;
    address public newPaidAddress;

    mapping(address => uint256) public totalUnStakingB;
    mapping(address => mapping(uint256 => bool)) public unstakeStatus;

    function safeWithdraw(address tokenAddress, uint256 amount)
        external
        virtual;

    function transferOwnership(address newOwner) external virtual;

    function owner() external virtual returns (address);
}

abstract contract U3Proxy is AdminV3Proxy {}


// File contracts/abstract/IERC20.sol


pragma solidity ^0.7.6;

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


// File contracts/reproxy/V3Reproxy.sol

pragma solidity ^0.7.6;

abstract contract V3Reproxy {
    mapping(address => mapping(uint256 => bool)) public u3UnstakeStatus;

    function safeWithdraw(address tokenAddress, uint256 amount)
        external
        virtual;

    function transferOwnership(address newOwner) public virtual;
}


// File contracts/U3ReProxyUpgradablity.sol


pragma solidity ^0.7.6;


contract U3ReProxyUpgradablity is Ownable {
    /// @notice LockableToken struct for storing token lockable details
    struct LockableTokens {
        uint256 lockableDays;
        bool optionableStatus;
    }
    /// @notice U3 Instance
    U3Legacy public uniV3;

    /// @notice U3Proxy Instance
    U3Proxy public uniV3Proxy;

    /// @notice ReProxy Instance
    V3Reproxy public u3Reproxy;

    /// @notice SafeMath using for Arthmetic Operations.
    using SafeMath for uint256;

    /// @notice intervalDays for reward calculation x days.
    uint256[] public intervalDays = [1, 8, 15, 22, 29, 36];

    /// @notice Days (86400 seconds)
    uint256 public constant DAYS = 1 days;

    /// @notice Hours (3600 seconds)
    uint256 public constant HOURS = 1 hours;

    /// @notice old Paid Address
    address public oldPaidAddress;

    /// @notice new Paid Address
    address public newPaidAddress;

    /// @notice poolStartTime
    uint256 public poolStartTime;

    /// @notice store total unstaking of u3Upgrade
    mapping(address => uint256) public totalStaking;

    /// @notice lockable token mapping
    mapping(address => LockableTokens) public u3UpgradeLockableDetails;

    /// @notice mapping for storing the unStaking status of a user.
    mapping(address => mapping(uint256 => bool)) public u3UnstakeStatus;

    event IntervalDaysDetails(uint256[] updatedIntervals, uint256 time);

    event Claim(
        address indexed userAddress,
        address indexed stakedTokenAddress,
        address indexed tokenAddress,
        uint256 claimRewards,
        uint256 time
    );

    event UnStake(
        address indexed userAddress,
        address indexed unStakedtokenAddress,
        uint256 unStakedAmount,
        uint256 time,
        uint256 stakeID
    );

    event ReferralEarn(
        address indexed userAddress,
        address indexed callerAddress,
        address indexed rewardTokenAddress,
        uint256 rewardAmount,
        uint256 time
    );

    event LockableTokenDetails(
        address indexed tokenAddress,
        uint256 lockableDys,
        bool optionalbleStatus,
        uint256 updatedTime
    );

    event WithdrawDetails(
        address indexed tokenAddress,
        uint256 withdrawalAmount,
        uint256 time
    );

    constructor() Ownable(msg.sender) {}

    function cohortConfig() external onlyOwner {
        poolStartTime = uniV3.poolStartTime();
        oldPaidAddress = uniV3Proxy.oldPaidAddress();
        newPaidAddress = uniV3Proxy.newPaidAddress();
    }

    function updateTotalStaking(
        address[] memory tokenAddresses,
        uint256[] memory overAllTotalStake
    ) external onlyOwner returns (bool) {
        require(
            tokenAddresses.length == overAllTotalStake.length,
            "U3ReProxyUpgradablity: Invalid Inputs"
        );
        for (uint8 n = 0; n < tokenAddresses.length; n++) {
            require(
                tokenAddresses[n] != address(0),
                "U3ReProxyUpgradablity: invalid poolAddress"
            );
            require(
                overAllTotalStake[n] > 0,
                "U3ReProxyUpgradablity: emptied overAllStaked"
            );
            totalStaking[tokenAddresses[n]] = overAllTotalStake[n];
        }
        return true;
    }

    function updatePoolStartTime(uint256 _newPoolStartTime)
        external
        onlyOwner
        returns (bool)
    {
        poolStartTime = _newPoolStartTime;
        return true;
    }

    function init(address[] memory tokenAddress)
        external
        onlyOwner
        returns (bool)
    {
        for (uint256 i = 0; i < tokenAddress.length; i++) {
            transferFromContractV3(tokenAddress[i]);
        }
        return true;
    }

    function transferFromContractV3(address tokenAddress) internal {
        uint256 bal = IERC20(tokenAddress).balanceOf(address(u3Reproxy));
        if (bal > 0) u3Reproxy.safeWithdraw(tokenAddress, bal);
    }

    /**
     * @notice Get rewards for one day
     * @param stakedAmount Stake amount of the user
     * @param stakedToken Staked token address of the user
     * @param rewardToken Reward token address
     * @return reward One dayh reward for the user
     */

    function getOneDayReward(
        uint256 stakedAmount,
        address stakedToken,
        address rewardToken,
        uint256 totalStake
    ) public view returns (uint256 reward) {
        reward = (
            stakedAmount.mul(
                uniV3.tokenDailyDistribution(stakedToken, rewardToken)
            )
        ).div(totalStake);
    }

    /**
     * @notice send rewards
     * @param stakedToken Stake amount of the user
     * @param tokenAddress Reward token address
     * @param amount Amount to be transferred as reward
     */
    function sendToken(
        address user,
        address stakedToken,
        address tokenAddress,
        uint256 amount
    ) internal {
        // Checks
        if (tokenAddress != address(0)) {
            require(
                IERC20(tokenAddress).balanceOf(address(this)) >= amount,
                "SEND: Insufficient Balance in Contract"
            );

            IERC20(tokenAddress).transfer(user, amount);

            emit Claim(
                user,
                stakedToken,
                tokenAddress,
                amount,
                block.timestamp
            );
        }
    }

    function getTotalStaking(address tokenAddress)
        public
        view
        returns (uint256)
    {
        (, uint256 _totalStaking) = swapPaidToken(tokenAddress);
        return _totalStaking;
    }

    /**
     * @notice Unstake and claim rewards
     * @param stakeId Stake ID of the user
     */
    function unStake(address user, uint256 stakeId) external whenNotPaused {
        require(
            msg.sender == user || msg.sender == _owner,
            "UNSTAKE: Invalid User Entry"
        );

        (
            ,
            address[] memory tokenAddress,
            bool[] memory activeStatus,
            ,
            ,
            uint256[] memory stakedAmount,
            uint256[] memory startTime
        ) = (uniV3.viewStakingDetails(user));

        bool isAlreadyUnstaked = uniV3Proxy.unstakeStatus(user, stakeId);
        bool isAlreadyUnstakedFromProxy = u3Reproxy.u3UnstakeStatus(
            user,
            stakeId
        );

        // lockableDays check
        require(
            u3UpgradeLockableDetails[tokenAddress[stakeId]].lockableDays <=
                block.timestamp,
            "Token Locked"
        );

        // optional lock check
        if (
            u3UpgradeLockableDetails[tokenAddress[stakeId]].optionableStatus ==
            true
        ) {
            require(
                poolStartTime.add(uniV3.stakeDuration()) <= block.timestamp,
                "Locked in optional lock"
            );
        }

        // Checks
        if (
            u3UnstakeStatus[user][stakeId] == false &&
            isAlreadyUnstaked == false &&
            isAlreadyUnstakedFromProxy == false &&
            activeStatus[stakeId] == true
        ) u3UnstakeStatus[user][stakeId] = true;
        else revert("UNSTAKE : Unstaked Already");

        (address stakedToken, uint256 _totalStaking) = swapPaidToken(
            tokenAddress[stakeId]
        );

        // Balance check
        require(
            IERC20(stakedToken).balanceOf(address(this)) >=
                stakedAmount[stakeId],
            "UNSTAKE : Insufficient Balance"
        );

        IERC20(stakedToken).transfer(user, stakedAmount[stakeId]);

        // precaution for overflow.
        uint256 endTime = poolStartTime.add(uniV3.stakeDuration());

        if (endTime > startTime[stakeId]) {
            claimRewards(user, stakeId, _totalStaking);
        }

        // Emit state changes
        emit UnStake(
            user,
            stakedToken,
            stakedAmount[stakeId],
            block.timestamp,
            stakeId
        );
    }

    function claimRewards(
        address user,
        uint256 stakeId,
        uint256 _totalStaking
    ) internal {
        (
            address[] memory referrerAddress,
            address[] memory tokenAddress,
            ,
            ,
            ,
            uint256[] memory stakedAmount,
            uint256[] memory startTime
        ) = (uniV3.viewStakingDetails(user));

        // Local variables
        uint256 interval;
        uint256 endOfProfit;

        interval = poolStartTime.add(uniV3.stakeDuration());

        if (interval > block.timestamp) endOfProfit = block.timestamp;
        else endOfProfit = poolStartTime.add(uniV3.stakeDuration());

        interval = endOfProfit.sub(startTime[stakeId]);

        // Reward calculation
        if (interval >= HOURS)
            _rewardCalculation(
                user,
                referrerAddress[stakeId],
                tokenAddress[stakeId],
                stakedAmount[stakeId],
                interval,
                _totalStaking
            );
    }

    function _rewardCalculation(
        address user,
        address referrerAddress,
        address stakedToken,
        uint256 stakedAmount,
        uint256 interval,
        uint256 totalStake
    ) internal {
        uint256 rewardsEarned;
        uint256 noOfDays;
        uint256 noOfHours;

        noOfHours = interval.div(HOURS);
        noOfDays = interval.div(DAYS);

        rewardsEarned = noOfHours.mul(
            getOneDayReward(stakedAmount, stakedToken, stakedToken, totalStake)
        );

        (address stakedToken1, ) = swapPaidToken(stakedToken);

        // Referrer Earning
        if (referrerAddress != address(0)) {
            uint256 refEarned = (rewardsEarned.mul(uniV3.refPercentage())).div(
                100 ether
            );
            rewardsEarned = rewardsEarned.sub(refEarned);
            require(
                IERC20(stakedToken1).transfer(referrerAddress, refEarned),
                "Transfer Failed"
            );

            emit ReferralEarn(
                referrerAddress,
                user,
                stakedToken1,
                refEarned,
                block.timestamp
            );
        }

        //  Rewards Send
        sendToken(user, stakedToken1, stakedToken1, rewardsEarned);

        uint8 i = 1;
        while (i < intervalDays.length) {
            if (noOfDays >= intervalDays[i]) {
                uint256 balHours = noOfHours.sub(
                    (intervalDays[i].sub(1)).mul(24)
                );

                address rewardToken = uniV3.tokensSequenceList(stakedToken, i);

                if (
                    rewardToken != stakedToken &&
                    uniV3.tokenBlockedStatus(stakedToken, rewardToken) == false
                ) {
                    rewardsEarned = balHours.mul(
                        getOneDayReward(
                            stakedAmount,
                            stakedToken,
                            rewardToken,
                            totalStake
                        )
                    );

                    (address rewardToken1, ) = swapPaidToken(rewardToken);

                    // Referrer Earning

                    if (referrerAddress != address(0)) {
                        uint256 refEarned = (
                            rewardsEarned.mul(uniV3.refPercentage())
                        ).div(100 ether);
                        rewardsEarned = rewardsEarned.sub(refEarned);

                        require(
                            IERC20(rewardToken1).transfer(
                                referrerAddress,
                                refEarned
                            ),
                            "Transfer Failed"
                        );

                        emit ReferralEarn(
                            referrerAddress,
                            user,
                            rewardToken1,
                            refEarned,
                            block.timestamp
                        );
                    }

                    //  Rewards Send
                    sendToken(user, stakedToken, rewardToken1, rewardsEarned);
                }
                i = i + 1;
            } else {
                break;
            }
        }
    }

    function swapPaidToken(address tokenAddress)
        internal
        view
        returns (address, uint256)
    {
        if (tokenAddress == oldPaidAddress) {
            return (newPaidAddress, totalStaking[oldPaidAddress]);
        } else {
            return (tokenAddress, totalStaking[tokenAddress]);
        }
    }

    function updateIntervalDays(uint256[] memory _interval) public onlyOwner {
        intervalDays = new uint256[](0);
        for (uint8 i = 0; i < _interval.length; i++) {
            uint256 noD = uniV3.stakeDuration().div(DAYS);
            require(noD > _interval[i], "Invalid Interval Day");
            intervalDays.push(_interval[i]);
        }
        emit IntervalDaysDetails(intervalDays, block.timestamp);
    }

    function lockableToken(
        address tokenAddress,
        uint8 lockableStatus,
        uint256 lockedDays,
        bool optionableStatus
    ) external onlyOwner {
        require(
            lockableStatus == 1 || lockableStatus == 2 || lockableStatus == 3,
            "Invalid Lockable Status"
        );

        (bool tokenExist, , , , , , ) = uniV3.tokenDetails(tokenAddress);

        require(tokenExist == true, "Token Not Exist");

        if (lockableStatus == 1) {
            u3UpgradeLockableDetails[tokenAddress].lockableDays = block
                .timestamp
                .add(lockedDays);
        } else if (lockableStatus == 2)
            u3UpgradeLockableDetails[tokenAddress].lockableDays = 0;
        else if (lockableStatus == 3)
            u3UpgradeLockableDetails[tokenAddress]
                .optionableStatus = optionableStatus;

        emit LockableTokenDetails(
            tokenAddress,
            u3UpgradeLockableDetails[tokenAddress].lockableDays,
            u3UpgradeLockableDetails[tokenAddress].optionableStatus,
            block.timestamp
        );
    }

    function transferV3ProxyOwnership(address newOwner) external onlyOwner {
        u3Reproxy.transferOwnership(newOwner);
    }

    function safeWithdraw(address tokenAddress, uint256 amount)
        external
        onlyOwner
    {
        require(
            IERC20(tokenAddress).balanceOf(address(this)) >= amount,
            "SAFEWITHDRAW: Insufficient Balance"
        );

        require(
            IERC20(tokenAddress).transfer(_owner, amount) == true,
            "SAFEWITHDRAW: Transfer failed"
        );

        emit WithdrawDetails(tokenAddress, amount, block.timestamp);
    }

    function setAllLegacyCohortU3(address[] memory u3Addresses)
        external
        onlyOwner
        returns (bool)
    {
        uniV3 = U3Legacy(u3Addresses[0]);
        uniV3Proxy = U3Proxy(u3Addresses[1]);
        u3Reproxy = V3Reproxy(u3Addresses[2]);
        return true;
    }

    function updateOldPaidAddress(address oldPaid)
        external
        onlyOwner
        returns (bool)
    {
        oldPaidAddress = oldPaid;
        return true;
    }

    function updateNewPaidAddress(address newPaid)
        external
        onlyOwner
        returns (bool)
    {
        newPaidAddress = newPaid;
        return true;
    }

    function emergencyUnstake(
        uint256 stakeId,
        address userAddress,
        address[] memory rewardtokens,
        uint256[] memory amount
    ) external onlyOwner {
        (
            address[] memory referrerAddress,
            address[] memory tokenAddress,
            bool[] memory activeStatus,
            ,
            ,
            uint256[] memory stakedAmount,

        ) = (uniV3.viewStakingDetails(userAddress));

        bool isAlreadyUnstaked = uniV3Proxy.unstakeStatus(userAddress, stakeId);
        // Checks
        if (
            u3UnstakeStatus[userAddress][stakeId] == false &&
            isAlreadyUnstaked == false &&
            activeStatus[stakeId] == true &&
            u3Reproxy.u3UnstakeStatus(userAddress,stakeId) == false
        ) u3UnstakeStatus[userAddress][stakeId] = true;
        else revert("EMERGENCY: Unstaked Already");

        (address stakedToken, ) = swapPaidToken(tokenAddress[stakeId]);

        // Balance check
        require(
            IERC20(stakedToken).balanceOf(address(this)) >=
                stakedAmount[stakeId],
            "EMERGENCY : Insufficient Balance"
        );

        IERC20(stakedToken).transfer(userAddress, stakedAmount[stakeId]);

        for (uint256 i = 0; i < rewardtokens.length; i++) {
            require(
                IERC20(rewardtokens[i]).balanceOf(address(this)) >= amount[i],
                "EMERGENCY : Insufficient Reward Balance"
            );
            uint256 rewardsEarned = amount[i];

            if (referrerAddress[stakeId] != address(0)) {
                uint256 refEarned = (rewardsEarned.mul(uniV3.refPercentage()))
                    .div(100 ether);
                rewardsEarned = rewardsEarned.sub(refEarned);

                require(
                    IERC20(rewardtokens[i]).transfer(
                        referrerAddress[stakeId],
                        refEarned
                    ),
                    "EMERGENCY : Transfer Failed"
                );

                emit ReferralEarn(
                    referrerAddress[stakeId],
                    userAddress,
                    rewardtokens[i],
                    refEarned,
                    block.timestamp
                );
            }
            sendToken(userAddress, stakedToken, rewardtokens[i], rewardsEarned);
        }

        // Emit state changes
        emit UnStake(
            userAddress,
            stakedToken,
            stakedAmount[stakeId],
            block.timestamp,
            stakeId
        );
    }

    function lockContract(bool pauseStatus) external onlyOwner {
        if (pauseStatus == true) _pause();
        else if (pauseStatus == false) _unpause();
    }
}