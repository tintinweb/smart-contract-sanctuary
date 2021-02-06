/**
 *Submitted for verification at Etherscan.io on 2021-02-06
*/

// SPDX-License-Identifier: -- 💰 --

pragma solidity ^0.7.5;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Generic SafeMath Library, can be removed if the
 * contract will be rewritten to ^0.8.0 Solidity compiler
 */
library SafeMath {

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
        require(c >= a, 'SafeMath: addition overflow');

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
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
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
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

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
        return div(a, b, 'SafeMath: division by zero');
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
        return mod(a, b, 'SafeMath: modulo by zero');
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
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

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

/*
 * @dev Context for msg.sender and msg.data can be removed
 * used in Ownable to determine msg.sender through _msgSender();
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owner = _msgSender();
        emit OwnershipTransferred(
            address(0),
            _owner
        );
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
        require(
            isOwner(),
            'Ownable: caller is not the owner'
        );
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
        emit OwnershipTransferred(
            _owner,
            address(0x0)
        );
        _owner = address(0x0);
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
        require(
            newOwner != address(0x0),
            'Ownable: new owner is the zero address'
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

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

/**
 * @dev Collection of functions related to the address type
 */
library Address {

    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     */
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
}

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 */
library SafeERC20 {

    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    )
        internal
    {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.transfer.selector,
                to,
                value
            )
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    )
        internal
    {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.transferFrom.selector,
                from,
                to,
                value
            )
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    )
        internal
    {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeERC20: approve from non-zero to non-zero allowance'
        );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                value
            )
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    )
        internal
    {
        uint256 newAllowance = token.allowance(
            address(this),
            spender
        ).add(value);

        callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    )
        internal
    {
        uint256 newAllowance = token.allowance(
            address(this),
            spender
        ).sub(value);

        callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function callOptionalReturn(
        IERC20 token,
        bytes memory data
    )
        private
    {
        require(
            address(token).isContract(),
            'SafeERC20: call to non-contract'
        );

        (bool success, bytes memory returndata) = address(token).call(data);
        require(
            success,
            'SafeERC20: low-level call failed'
        );

        if (returndata.length > 0) {
            require(
                abi.decode(returndata, (bool)),
                'SafeERC20: ERC20 operation did not succeed'
            );
        }
    }
}

/**
 * @title LPTokenWrapper
 * @dev Wraps around ERC20 that is represented as Liquidity token
 * contract and is being distributed for providing liquidity for the pair.
 * This token is the staking token in this system / contract.
 */
contract LPTokenWrapper {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // ONBOARDING: Specify Liquidity Token Address
    IERC20 public uni = IERC20(
        0xB6E544c3e420154C2C663f14eDAd92737d7FbdE5
    );

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    /**
     * @dev Returns total supply of staked token
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Returns balance of specific user
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev internal function for staking LP tokens
     */
    function _stake(uint256 amount) internal {

        _totalSupply = _totalSupply.add(amount);

        _balances[msg.sender] =
        _balances[msg.sender].add(amount);

        uni.safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
    }

    /**
     * @dev internal function for withdrwaing LP tokens
     */
    function _withdraw(uint256 amount) internal {

        _totalSupply = _totalSupply.sub(amount);

        _balances[msg.sender] =
        _balances[msg.sender].sub(amount);

        uni.safeTransfer(
            msg.sender,
            amount
        );
    }
}

contract FeyLPStaking is LPTokenWrapper, Ownable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // ONBOARDING: Specify Reward Token Address (FEY)
    IERC20 public fey = IERC20(
        0xe8E06a5613dC86D459bC8Fb989e173bB8b256072
    );

    // ONBOARDING: Specify duration of single cycle for the reward distribution
    // reward distribution should be announced through {notifyRewardAmount} call
    uint256 public constant DURATION = 52 weeks;

    uint256 public periodFinish;
    uint256 public rewardRate;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    event RewardAdded(
        uint256 reward
    );

    event Staked(
        address indexed user,
        uint256 amount
    );

    event Withdrawn(
        address indexed user,
        uint256 amount
    );

    event RewardPaid(
        address indexed user,
        uint256 reward
    );

    modifier updateReward(address account) {

        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();

        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    /**
     * @dev Checks when last time the reward
     * was changed based on when the distribution
     * is about to be finished
     */
    function lastTimeRewardApplicable()
        public
        view
        returns (uint256)
    {
        return Math.min(
            block.timestamp,
            periodFinish
        );
    }

    /**
     * @dev Determines the ratio of reward per each token
     * stakd so the relative value can be calculated
     */
    function rewardPerToken()
        public
        view
        returns (uint256)
    {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }

        return rewardPerTokenStored.add(
            lastTimeRewardApplicable()
                .sub(lastUpdateTime)
                .mul(rewardRate)
                .mul(1e18)
                .div(totalSupply())
        );
    }

    /**
     * @dev Returns amount of tokens specific address or
     * staker has earned so far based on his stake and time
     * the stake been active so far.
     */
    function earned(
        address account
    )
        public
        view
        returns (uint256)
    {
        return balanceOf(account)
            .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
            .div(1E18)
            .add(rewards[account]);
    }

    /**
     * @dev Ability to stake liquidity tokens
     */
    function stake(
        uint256 amount
    )
        public
        updateReward(msg.sender)
    {
        require(
            amount > 0,
            'Cannot stake 0'
        );

        _stake(amount);

        emit Staked(
            msg.sender,
            amount
        );
    }

    /**
     * @dev Ability to withdraw liquidity tokens
     */
    function withdraw(
        uint256 amount
    )
        public
        updateReward(msg.sender)
    {
        require(
            amount > 0,
            'Cannot withdraw 0'
        );

        _withdraw(amount);

        emit Withdrawn(
            msg.sender,
            amount
        );
    }

    /**
     * @dev allows to withdraw staked tokens
     *
     * withdraws all staked tokens by user
     * also withdraws rewards as user exits
     */
    function exit() external {
        withdraw(balanceOf(msg.sender));
        getReward();
    }

    /**
     * @dev allows to withdraw staked tokens
     *
     * withdraws all staked tokens by user
     * also withdraws rewards as user exits
     */
    function getReward()
        public
        updateReward(msg.sender)
        returns (uint256 reward)
    {
        reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;
            fey.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    /**
     * @dev Starts the distribution
     *
     * This must be called to start the distribution cycle
     * and allow stakers to start earning rewards
     */
    function notifyRewardAmount(uint256 reward)
        external
        onlyOwner
        updateReward(address(0x0))
    {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(DURATION);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(DURATION);
        }
        uint256 balance = fey.balanceOf(address(this));
        require(
            rewardRate <= balance.div(DURATION),
            'Provided reward too high'
        );
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(DURATION);
        emit RewardAdded(reward);
    }
}