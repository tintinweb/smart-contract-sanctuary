/**
 *Submitted for verification at Etherscan.io on 2021-03-11
*/

// Created By BitDNS.vip
// contact : StakeDnsRewardDnsPool
// SPDX-License-Identifier: MIT

pragma solidity ^0.5.8;

// File: @openzeppelin/contracts/math/SafeMath.sol
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
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol
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

// File: @openzeppelin/contracts/utils/Address.sol
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
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol
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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
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

contract IMinableERC20 is IERC20 {
    function mint(address account, uint amount) public;
}

contract IFdcRewardDnsPool {
    uint256 public totalSupply;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public stakeStartOf;
    mapping(address => uint256) public stakeCount;
    mapping(address => mapping(uint256 => uint256)) public stakeAmount;
    mapping(address => mapping(uint256 => uint256)) public stakeTime;
}

contract StakeFdcRewardDnsPool {
    using SafeMath for uint256;
    using Address for address;
    using SafeERC20 for IERC20;
    using SafeERC20 for IMinableERC20;

    IERC20 public stakeToken;
    IERC20 public rewardToken;
    
    bool public started;
    uint256 public _totalSupply;
    uint256 public rewardFinishTime = 0;
    uint256 public rewardRate = 0;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public rewardedOf;
    mapping(address => uint256) public _balanceOf;
    mapping(address => uint256) public _stakeStartOf;
    mapping(address => uint256) public _stakeCount;
    mapping(address => mapping(uint256 => uint256)) public _stakeAmount;
    mapping(address => mapping(uint256 => uint256)) public _stakeTime;
    address private governance;
    IFdcRewardDnsPool private pool;

    event Staked(address indexed user, uint256 amount, uint256 beforeT, uint256 afterT);
    event Withdrawn(address indexed user, uint256 amount, uint256 beforeT, uint256 afterT);
    event RewardPaid(address indexed user, uint256 reward, uint256 beforeT, uint256 afterT);
    event StakeItem(address indexed user, uint256 idx, uint256 time, uint256 amount);
    event UnstakeItem(address indexed user, uint256 idx, uint256 time, uint256 beforeT, uint256 afterT);

    modifier onlyOwner() {
        require(msg.sender == governance, "!governance");
        _;
    }

    constructor () public {
        governance = msg.sender;
    }

    function start(address stake_token, address reward_token, address pool_addr) public onlyOwner {
        require(!started, "already started");
        require(stake_token != address(0) && stake_token.isContract(), "stake token is non-contract");
        require(reward_token != address(0) && reward_token.isContract(), "reward token is non-contract");

        started = true;
        stakeToken = IERC20(stake_token);
        rewardToken = IERC20(reward_token);
        pool = IFdcRewardDnsPool(pool_addr);
        rewardFinishTime = block.timestamp.add(10 * 365.25 days);
    }

    function lastTimeRewardApplicable() internal view returns (uint256) {
        return block.timestamp < rewardFinishTime ? block.timestamp : rewardFinishTime;
    }

    function earned(address account) public view returns (uint256) {
        uint256 r = 0;
        uint256 stakeIndex = stakeCount(account);
        for (uint256 i = 0; i < stakeIndex; i++) {
            if (stakeAmount(account, i) > 0) {
                r = r.add(calcReward(stakeAmount(account, i), stakeTime(account, i), lastTimeRewardApplicable()));
            }
        }
        return r.add(rewards[account]).sub(rewardedOf[account]);
    }

    function stake(uint256 amount) public {
        require(started, "Not start yet");
        require(amount > 0, "Cannot stake 0");
        require(stakeToken.balanceOf(msg.sender) >= amount, "insufficient balance to stake");
        uint256 beforeT = stakeToken.balanceOf(address(this));
        
        stakeToken.safeTransferFrom(msg.sender, address(this), amount);
        _totalSupply = _totalSupply.add(amount);
        _balanceOf[msg.sender] = _balanceOf[msg.sender].add(amount);
        
        uint256 afterT = stakeToken.balanceOf(address(this));
        emit Staked(msg.sender, amount, beforeT, afterT);

        if (_stakeStartOf[msg.sender] == 0) {
            _stakeStartOf[msg.sender] = block.timestamp;
        }
        uint256 stakeIndex = _stakeCount[msg.sender];
        _stakeAmount[msg.sender][stakeIndex] = amount;
        _stakeTime[msg.sender][stakeIndex] = block.timestamp;
        _stakeCount[msg.sender] = _stakeCount[msg.sender].add(1);
        rewardRate = totalSupply().mul(100).div(160 days);
        emit StakeItem(msg.sender, stakeIndex, block.timestamp, amount);
    }

    function calcReward(uint256 amount, uint256 startTime, uint256 endTime) public pure returns (uint256) {
        uint256 day = endTime.sub(startTime).div(1 days);
        return amount.mul(25 * (day > 160 ? 160 : day));
    }

    function _unstake(address account, uint256 amount) private returns (uint256) {
        uint256 unstakeAmount = 0;
        uint256 stakeIndex = _stakeCount[msg.sender];
        for (uint256 i = 0; i < stakeIndex; i++) {
            uint256 itemAmount = _stakeAmount[msg.sender][i];
            if (itemAmount == 0) {
                continue;
            }
            if (unstakeAmount.add(itemAmount) > amount) {
                itemAmount = amount.sub(unstakeAmount);
            }
            unstakeAmount = unstakeAmount.add(itemAmount);
            _stakeAmount[msg.sender][i] = _stakeAmount[msg.sender][i].sub(itemAmount);
            rewards[msg.sender] = rewards[msg.sender].add(calcReward(itemAmount, _stakeTime[msg.sender][i], lastTimeRewardApplicable()));
            emit UnstakeItem(account, i, block.timestamp, _stakeAmount[msg.sender][i].add(itemAmount), _stakeAmount[msg.sender][i]);
        }
        return unstakeAmount;
    }

    function withdraw(uint256 amount) public {
        require(started, "Not start yet");
        require(amount > 0, "Cannot withdraw 0");
        require(_balanceOf[msg.sender] >= amount, "Insufficient balance to withdraw");

        // Add Lock Time Begin:
        require(canWithdraw(msg.sender), "Must be locked for 30 days or Mining ended");
        uint256 unstakeAmount = _unstake(msg.sender, amount);
        // Add Lock Time End!!!

        uint256 beforeT = stakeToken.balanceOf(address(this));
        
        _totalSupply = _totalSupply.sub(unstakeAmount);
        _balanceOf[msg.sender] = _balanceOf[msg.sender].sub(unstakeAmount);
        stakeToken.safeTransfer(msg.sender, unstakeAmount);

        uint256 afterT = stakeToken.balanceOf(address(this));
        rewardRate = totalSupply().mul(100).div(160 days);
        emit Withdrawn(msg.sender, unstakeAmount, beforeT, afterT);
    }

    function exit() external {
        require(started, "Not start yet");
        withdraw(_balanceOf[msg.sender]);
        getReward();
    }

    function getReward() public {
        require(started, "Not start yet");
        
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewardedOf[msg.sender] = rewardedOf[msg.sender].add(reward);
            uint256 beforeT = rewardToken.balanceOf(address(this));
            //rewardToken.mint(msg.sender, reward);
            rewardToken.safeTransfer(msg.sender, reward);
            uint256 afterT = rewardToken.balanceOf(address(this));
            emit RewardPaid(msg.sender, reward, beforeT, afterT);
        }
    }

    function refoudStakeToken(address account, uint256 amount) public onlyOwner {
        stakeToken.safeTransfer(account, amount);
    }

    function refoudRewardToken(address account, uint256 amount) public onlyOwner {
        rewardToken.safeTransfer(account, amount);
    }
    
    function canHarvest(address account) public view returns (bool) {
        return earned(account) > 0;
    }

    // Add Lock Time Begin:
    function canWithdraw(address account) public view returns (bool) {
        return started && (_balanceOf[account] > 0) && false;
    }
    // Add Lock Time End!!!

    function totalSupply_() public view returns (uint256) {
        return pool.totalSupply();
    }
    
    function rewards_(address account) public view returns (uint256) {
        return pool.rewards(account);
    }

    function balanceOf_(address account) public view returns (uint256) {
        return pool.balanceOf(account);
    }

    function stakeStartOf_(address account) public view returns (uint256) {
        return pool.stakeStartOf(account);
    }

    function stakeCount_(address account) public view returns (uint256) {
        return pool.stakeCount(account);
    }

    function stakeAmount_(address account, uint256 idx) public view returns (uint256) {
        return pool.stakeAmount(account, idx);
    }

    function stakeTime_(address account, uint256 idx) public view returns (uint256) {
        return pool.stakeTime(account, idx);
    }

    function totalSupply() public view returns (uint256) {
        return pool.totalSupply().add(_totalSupply);
    }

    function balanceOf(address account) public view returns (uint256) {
        return pool.balanceOf(account).add(_balanceOf[account]);
    }

    function stakeStartOf(address account) public view returns (uint256) {
        return pool.stakeStartOf(account) > 0 && _stakeStartOf[account] > 0
            ? (_stakeStartOf[account] < pool.stakeStartOf(account) ? _stakeStartOf[account] : pool.stakeStartOf(account))
            : (_stakeStartOf[account] > 0 ? _stakeStartOf[account] : pool.stakeStartOf(account));
    }

    function stakeCount(address account) public view returns (uint256) {
        return pool.stakeCount(account).add(_stakeCount[account]);
    }

    function stakeAmount(address account, uint256 idx) public view returns (uint256) {
        uint256 count = pool.stakeCount(account);
        return idx < count ? pool.stakeAmount(account, idx) 
            : ((idx < count.add(_stakeCount[account])) ? _stakeAmount[account][idx.sub(count)] : 0);
    }

    function stakeTime(address account, uint256 idx) public view returns (uint256) {
        uint256 count = pool.stakeCount(account);
        return idx < count ? pool.stakeTime(account, idx) 
            : ((idx < count.add(_stakeCount[account])) ? _stakeTime[account][idx.sub(count)] : 0);
    }
}