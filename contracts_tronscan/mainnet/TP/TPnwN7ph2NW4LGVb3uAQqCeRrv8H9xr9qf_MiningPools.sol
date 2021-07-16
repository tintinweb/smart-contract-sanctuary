//SourceUnit: MiningPoolAllInOne.sol

// File: contracts/SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.9;

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

// File: contracts/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.9;

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
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() external view returns (uint8);


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
}// SPDX-License-Identifier: MIT

// File: contracts/IMigrator.sol

pragma solidity ^0.5.9;


interface IMigrator {
    function migrate(IERC20 token) external returns (IERC20);
}

// File: contracts/Context.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.9;

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

// File: contracts/Ownable.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.9;


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
    constructor (address owner_) internal {
        _owner = owner_;
        emit OwnershipTransferred(address(0), _owner);
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

// File: contracts/Address.sol

pragma solidity ^0.5.9;

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

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
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

// File: contracts/IMineableToken.sol

pragma solidity ^0.5.9;

interface IMineableToken {
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
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() external view returns (uint8);


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

    function transferOwnership(address newOwner) external;

    function mint(address to, uint256 amount) external ;
}

// File: contracts/MiningPoolsData.sol

pragma solidity ^0.5.6;




contract MiningPoolsData {
    struct PoolInfo {
        IERC20 stakingToken;
        uint256 startBlock;
        uint256 endBlock;
        uint256 billingCycle;
        uint256 weight;
        uint256 staked;
        uint256 lastRewardBlock;
        uint256 rewardPerShare;
        uint256 minStakeIn;
        uint256 maxStakeIn;
        bool closed;
    }

    struct UserInfo {
        uint256 stakeIn;
        uint256 rewardDebt;
        uint256 willCollect;
        uint256 lastCollectPosition;
    }

    PoolInfo[] public pools;
    mapping (uint256=>mapping(address=>UserInfo)) public users;

    IMineableToken public rewardToken;
    uint256 public rewardPerBlock;
    uint256 public minRewardPerBlock;

    uint256 public rewardCap;
    uint256 public collectedReward;

    mapping(uint256=>bool) public closedPool;

    uint256 public precision = 1e18;

    address public team;
    uint256 public lastTotalSupplyWithoutTeam;
    uint256 public teamRewarded;
    bool public teamRewardPermanentlyDisabled = false;

    bool public globalOpen = true;
    uint256 public globalStartBlock  = ~uint256(0);

    bool public rewardDecreasable;
    uint256 public rewardDecreaseBegin;
    uint256 public rewardDecreaseStep;
    uint256 public rewardDecreaseUnit;

    address constant INIT_ADDRESS = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;
}

// File: contracts/MiningPoolsInternal.sol

pragma solidity ^0.5.9;




contract MiningPoolsInternal is MiningPoolsData {
    using SafeMath for uint256;
    using Address for address payable;

    function _poolsEnabled() internal view returns(bool) {
        return globalOpen && block.number >= globalStartBlock;
    }

    function _poolsTotalWeight() public view returns(uint256) {
        uint256 poolCnt = pools.length;
        uint256 totalWeight = 0;

        if(!_poolsEnabled()) {
            return totalWeight;
        }

        for(uint256 i=0; i<poolCnt; i++) {
            PoolInfo memory pool = pools[i];
            if(pool.closed) {
                continue;
            }

            if(block.number > pool.endBlock &&  pool.endBlock != 0) {
                continue;
            }

            if(pool.startBlock > block.number) {
                continue;
            }

            totalWeight = totalWeight.add(pool.weight);
        }

        return totalWeight;
    }

    function _decreasedRewards(uint256 from, uint256 to) internal view returns(uint256) {
        if(!rewardDecreasable) {
            return 0;
        }

        if(to < rewardDecreaseBegin) {
            return 0;
        }

        if(to <= from) {
            return 0;
        }

        uint256 decreaseBegin = 0;
        uint256 totalDecreased = 0;

        uint256 maxDiff = rewardPerBlock.sub(minRewardPerBlock);
        uint256 maxDecreaseSteps = rewardPerBlock.sub(minRewardPerBlock).div(rewardDecreaseUnit);
        uint256 targetEnd = to.sub(rewardDecreaseBegin).div(rewardDecreaseStep);

        if(from > rewardDecreaseBegin) {
            decreaseBegin = from.sub(rewardDecreaseBegin).div(rewardDecreaseStep);
        }

        if(decreaseBegin >= maxDecreaseSteps) {
            totalDecreased = maxDiff.mul(maxDecreaseSteps.add(1)).div(2);
            return totalDecreased;
        }

        if(targetEnd > maxDecreaseSteps) {
            totalDecreased = maxDiff.mul(targetEnd.sub(maxDecreaseSteps).mul(rewardDecreaseStep));
            targetEnd = maxDecreaseSteps;
        }

        uint256 decreaseCount = targetEnd.sub(decreaseBegin);

        uint256 endReward = decreaseCount.mul(rewardDecreaseUnit);
        uint256 beginReward = decreaseBegin.mul(rewardDecreaseUnit);
        uint256 currentDecreased = endReward.add(beginReward).mul(decreaseCount.add(1)).div(2);

        return totalDecreased.add(currentDecreased);
    }

    function _tryWithdraw(PoolInfo storage pool, UserInfo storage user, uint256 _amount) internal {
        if(user.stakeIn < _amount) {
            return;
        }
        if(_amount > 0) {
            if(address(0) == address(pool.stakingToken)) {
                msg.sender.sendValue(_amount);
            } else {
                pool.stakingToken.transfer(msg.sender, _amount);
            }
        }
    }

    function _poolsOutput(uint256 from, uint256 to) internal view returns(uint256){
        if(from  < globalStartBlock) {
            from = globalStartBlock;
        }

        uint256 averReward = rewardPerBlock;

        uint256 alreadyDecreased = _decreasedRewards(globalStartBlock, from);
        uint256 decreased = _decreasedRewards(from, to);

        uint256 output = to.sub(from).mul(averReward);
        uint256 alreadyOutput = from.sub(globalStartBlock).mul(averReward);

        alreadyOutput = alreadyOutput.sub(alreadyDecreased);
        output = output.sub(decreased);

        if(rewardCap > 0) {
            if(alreadyOutput > rewardCap) {
                return 0;
            }

            if(output.add(alreadyOutput) > rewardCap) {
                output = rewardCap.sub(alreadyOutput);
            }
        }

        return output;
    }

    function _toBeCollected(PoolInfo storage pool, uint256 from, uint256 to) internal view returns (uint256) {
        if(!_poolsEnabled()) {
            return 0;
        }

        if(pool.closed) {
            return 0;
        }

        if(to > pool.endBlock && pool.endBlock != 0) {
            to = pool.endBlock;
        }

        if(block.number < pool.lastRewardBlock) {
            return 0;
        }

        if(to > block.number) {
            return 0;
        }

        if(from < pool.lastRewardBlock) {
            from = pool.lastRewardBlock;
        }

        uint256 poolMultiple = precision;
        poolMultiple = pool.weight.mul(precision).div(_poolsTotalWeight());

        uint256 poolsOutput = _poolsOutput(from, to);
        if(poolsOutput == 0) {
            return 0;
        }

        return poolsOutput.mul(poolMultiple).div(precision);
    }

    function _canDeposit(PoolInfo storage pool, uint256 _amount) internal view returns(bool, string memory) {
        (bool status, string memory info) = _poolsStatusCheck();
        if(!status) {
            return (status, info);
        }

        if(pool.closed) {
            return (false, "pool closed");
        }

        if(_amount == 0) {
            return (false, "deposit must not be 0");
        }

        if(pool.maxStakeIn > 0) {
            if(pool.staked.add(_amount) > pool.maxStakeIn) {
                return (false, "hard cap touched");
            }
        }

        if(pool.endBlock > 0) {
            if(block.number < pool.startBlock) {
                return (false, "pool not started");
            }

            if(block.number > pool.endBlock) {
                return (false, "mining end");
            }
        }

        return (true, "");
    }

    function _canCollect(PoolInfo storage pool, UserInfo storage user) internal view returns(bool, string memory) {
        (bool status, string memory info) = _poolsStatusCheck();
        if(!status) {
            return (status, info);
        }

        bool isLimitedPool = (pool.endBlock > 0);

        if(block.number < pool.startBlock) {
            return (false, "mining pool is not open");
        }

        if(block.number < user.lastCollectPosition) {
            return (false, "not in collect round");
        }

        uint256 userLastCollect = user.lastCollectPosition;
        if(userLastCollect == 0) {
            userLastCollect = pool.startBlock;
        }

        uint256 fromLast = block.number.sub(user.lastCollectPosition);
        if(fromLast < pool.billingCycle) {
            if(isLimitedPool) {
                if(block.number > pool.endBlock) {
                    return (true, "");
                }
            }
            return (false, "not in collect round");
        }

        return (true, "");
    }

    function _poolsStatusCheck() internal view returns(bool, string memory) {
        if(block.number < globalStartBlock) {
            return (false, "mining not started");
        }

        if(!globalOpen) {
            return (false, "pools is temporarily closed");
        }

        return (true, "");
    }

    function _updatePool(PoolInfo storage pool) internal {
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        if (pool.staked == 0) {
            //enable the following line will reduce the total output of every block when no one stake in this pool
            // pool.lastRewardBlock = block.number;
            return;
        }

        uint256 teBeCollect = _toBeCollected(pool, pool.lastRewardBlock, block.number);
        pool.rewardPerShare = pool.rewardPerShare.add(teBeCollect.mul(precision).div(pool.staked));
        pool.lastRewardBlock = block.number;
    }

    function _updatePools() internal {
        uint256 poolLen = pools.length;
        if(block.number < globalStartBlock) {
            return;
        }

        for(uint256 i=0; i<poolLen; i++) {
            PoolInfo storage pool = pools[i];
            if(pool.closed || block.number < pool.startBlock) {
                continue;
            }

            _updatePool(pool);
        }
    }
}

// File: contracts/MiningPoolsAdmin.sol

pragma solidity ^0.5.9;



contract MiningPoolsAdmin is Ownable, MiningPoolsInternal {
    using SafeMath for uint256;

    mapping(address=>address) public administrators;

    modifier onlyAdmin() {
        require(address(0) != administrators[msg.sender], "caller is not the administrator");
        _;
    }

    modifier onlyTeam() {
        require(msg.sender == team, "caller is not the team");
        _;
    }

    function addAdministrator(address _admin) public onlyAdmin {
        administrators[_admin] = _admin;
    }

    function removeAdministrator(address _admin) public onlyAdmin {
        delete administrators[_admin];
    }

    function isAdmin(address _admin) public view returns(bool) {
        return (address(0) != administrators[_admin]);
    }

    function disbaleTeamRewardPermanently() public onlyAdmin {
        teamRewardPermanentlyDisabled = true;
    }

    function setPoolsCap(uint256 cap) public onlyAdmin {
        require(cap > rewardCap);
        rewardCap = cap;
    }

    function addPool(
        address _stakeToken,
        uint256 _weight,
        uint256 _billingCycle,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _minStakeIn,
        uint256 _maxStakeIn) public onlyAdmin {
        require(_startBlock >= globalStartBlock, "must after or at pools start block");
        require(_billingCycle > 0, "pool billing cycle must not be zero");

        if(_startBlock == 0) {
            _startBlock = block.number;
        } else {
            require(_startBlock >= block.number, "start must after or on the tx block");
        }

        if(_endBlock > 0) {
            require(_endBlock > _startBlock);
        }

        _updatePools();

        PoolInfo memory newPool = PoolInfo({
        stakingToken: IERC20(_stakeToken),
        startBlock: _startBlock,
        endBlock: _endBlock,
        billingCycle: _billingCycle,
        weight: _weight,
        staked: 0,
        minStakeIn: _minStakeIn,
        maxStakeIn: _maxStakeIn,
        lastRewardBlock: _startBlock,
        rewardPerShare: 0,
        closed: false
        });

        pools.push(newPool);
    }

    function setPoolStakeToken(uint256 _pid, address _token) public onlyAdmin {
        PoolInfo storage pool = pools[_pid];
        require(address(pool.stakingToken) == INIT_ADDRESS, "address already set");

        pool.stakingToken = IERC20(_token);
    }

    function removePool(uint256 _pid) public onlyAdmin {
        PoolInfo storage pool = pools[_pid];
        require(pool.billingCycle != 0, "no such pool");

        _updatePools();

        pool.weight = 0;
        pool.closed = true;
        pool.lastRewardBlock = block.number;
        pool.endBlock = block.number;
    }

    function setPoolWeight(uint256[] memory _pids, uint256[] memory _newWeights) public onlyAdmin {
        uint256 _pidLen = _pids.length;
        uint256 _newWeightLen = _newWeights.length;

        _updatePools();

        require(_pidLen == _newWeightLen, "invalid parameter");
        for(uint256 i=0; i<_pidLen; i++) {
            PoolInfo storage pool = pools[_pids[i]];
            require(pool.billingCycle != 0, "no such pool");
            require(!pool.closed, "pool already closed");

            pool.weight = _newWeights[i];
        }
    }

    function setTeam(address _team) public onlyAdmin {
        team = _team;
    }

    function mintToTeam() public {
        require (msg.sender == team || isAdmin(msg.sender), "not team or admin");
        require (!teamRewardPermanentlyDisabled, "no team reward");

        uint256 totalAmount = rewardToken.totalSupply();
        uint256 thisSupplyWithoutTeam = totalAmount.sub(teamRewarded);
        uint256 rewardToCollect = thisSupplyWithoutTeam.sub(lastTotalSupplyWithoutTeam).div(10);

        rewardToken.mint(team, rewardToCollect);
        lastTotalSupplyWithoutTeam = thisSupplyWithoutTeam;
        teamRewarded = teamRewarded.add(rewardToCollect);
    }

    function setGlobalStartBlock(uint256 _newStart) public onlyAdmin {
        require(globalStartBlock > _newStart, "new start must less than current start");
        globalStartBlock = _newStart;
    }

    function changeEnableState(bool _enabled) public onlyAdmin {
        globalOpen = _enabled;
    }

    function setRewardDecreased(uint256 _begin, uint256 _step, uint256 _unit, uint256 _minReward) public onlyAdmin {
        require(_begin > block.number && _begin >= globalStartBlock);
        require(_step > 0);
        require(_unit > 0);
        require(_minReward < rewardPerBlock);

        rewardDecreasable = true;
        rewardDecreaseBegin = _begin;
        rewardDecreaseStep = _step;
        rewardDecreaseUnit = _unit;
        minRewardPerBlock = _minReward;
    }
}

// File: contracts/MiningPoolsMigratable.sol

pragma solidity ^0.5.9;





contract MiningPoolsMigratable is Ownable, MiningPoolsData {
    using SafeMath for uint256;

    IMigrator public migrator;

    function setMigrator(IMigrator _migrator) public onlyOwner {
        migrator = _migrator;
    }

    function migrate(uint256 _pid, uint256 _multiple, uint256 _precision) public {
        require(address(migrator) != address(0), "migrate: no migrator");
        PoolInfo storage pool = pools[_pid];
        IERC20 stakingToken = pool.stakingToken;

        uint256 amount = stakingToken.balanceOf(address(this));
        stakingToken.approve(address(migrator), amount);

        IERC20 newStakingToken = migrator.migrate(stakingToken);
        uint256 newBal = newStakingToken.balanceOf(address(this));
        newBal = newBal.mul(_multiple).div(_precision);

        require(amount == newBal, "migrate: failed");
        pool.stakingToken = newStakingToken;
    }
}

// File: contracts/MiningPoolsViews.sol

pragma solidity ^0.5.9;


contract MiningPoolsViews is MiningPoolsInternal {
    function poolsCount() public view returns(uint256) {
        return pools.length;
    }

    function poolsEnabled() public view returns(bool) {
        return _poolsEnabled();
    }

    function totalMined() public view returns(uint256) {
        return _poolsOutput(0, block.number);
    }

    function poolWeight(uint256 _pid) public view returns(uint256) {
        PoolInfo storage pool = pools[_pid];

        return pool.weight.mul(precision).div(_poolsTotalWeight());
    }

    function toBeCollectedOfPool(uint256 _pid) public view returns(uint256){
        PoolInfo storage pool = pools[_pid];
        if(pool.billingCycle == 0) {
            return 0;
        }

        return _toBeCollected(pool, pool.lastRewardBlock, block.number);
    }

    function toBeCollectedOf(uint256 _pid, address _user) public view returns(uint256) {
        PoolInfo storage pool = pools[_pid];
        UserInfo storage user = users[_pid][_user];

        if(pool.billingCycle == 0) {
            return 0;
        }

        if(user.stakeIn == 0) {
            return 0;
        }

        if(block.number < pool.startBlock) {
            return 0;
        }

        uint256 teBeCollect = _toBeCollected(pool, pool.lastRewardBlock, block.number);
        uint256 rewardPerShare = pool.rewardPerShare.add(teBeCollect.mul(precision).div(pool.staked));

        uint256 userReward  = user.willCollect;
        uint256 stillNeed = user.stakeIn.mul(rewardPerShare).div(precision).sub(user.rewardDebt);
        userReward = userReward.add(stillNeed);

        return userReward;
    }
}

// File: contracts/MiningPools.sol

pragma solidity ^0.5.9;









contract MiningPools is Ownable, MiningPoolsAdmin, MiningPoolsMigratable, MiningPoolsViews {
    using SafeMath for uint256;
    using Address for address payable;

    constructor(address _owner, address _admin, address _token, uint256 _rewardPerBlock)
    public Ownable(_owner) {
        rewardToken = IMineableToken(_token);
        rewardPerBlock = _rewardPerBlock;
        administrators[_admin] = _admin;
    }

    function deposit(uint256 _pid, uint256 _amount) public payable {
        PoolInfo storage pool = pools[_pid];
        UserInfo storage user = users[_pid][msg.sender];

        require(pool.billingCycle > 0, "no such pool");
        require(!pool.closed, "closed pool");
        require(address(pool.stakingToken) != INIT_ADDRESS, "stake token not set");

        if(address(0) == address(pool.stakingToken)) {
            _amount = msg.value;
        }

        (bool valid, string memory errInfo) = _canDeposit(pool, _amount);
        require(valid, errInfo);

        if(address(0) != address(pool.stakingToken)) {
            pool.stakingToken.transferFrom(msg.sender, address(this), _amount);
        }

        _updatePool(pool);
        if (user.stakeIn > 0) {
            uint256 willCollect = user.stakeIn.mul(pool.rewardPerShare).div(precision).sub(user.rewardDebt);
            user.willCollect = user.willCollect.add(willCollect);
        }
        pool.staked = pool.staked.add(_amount);
        user.stakeIn = user.stakeIn.add(_amount);
        user.rewardDebt = user.stakeIn.mul(pool.rewardPerShare).div(precision);
    }

    function collect(uint256 _pid, uint256 _withdrawAmount) public {
        PoolInfo storage pool = pools[_pid];
        UserInfo storage user = users[_pid][msg.sender];

        require(pool.billingCycle > 0, "no such pool");
        require(user.stakeIn > 0, "not deposit");
        require(user.stakeIn >= _withdrawAmount, "over withdraw");


        (bool valid, string memory info) = _canCollect(pool, user);
        require(valid, info);

        _tryWithdraw(pool, user, _withdrawAmount);

        user.lastCollectPosition = block.number.sub(block.number.mod(pool.billingCycle));

        _updatePool(pool);
        uint256 userReward  = user.willCollect;
        uint256 stillNeed = user.stakeIn.mul(pool.rewardPerShare).div(precision).sub(user.rewardDebt);
        userReward = userReward.add(stillNeed);
        rewardToken.mint(msg.sender, userReward);

        user.willCollect = 0;
        user.stakeIn = user.stakeIn.sub(_withdrawAmount);
        user.rewardDebt = user.stakeIn.mul(pool.rewardPerShare).div(precision);

        pool.staked = pool.staked.sub(_withdrawAmount);
    }

    function signature() external pure returns (string memory) {
        return "provided by Seal-SC / www.sealsc.com";
    }

    function() external {
        revert("refuse to directly transfer ETH");
    }
}