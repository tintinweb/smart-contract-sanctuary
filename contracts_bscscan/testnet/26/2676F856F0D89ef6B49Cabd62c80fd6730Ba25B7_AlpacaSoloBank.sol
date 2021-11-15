// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/AggregatorV3Interface.sol";
import "../interfaces/ISolo.sol";
import "../interfaces/IWETH.sol";


// AlpacaSoloBank is the master of xBURGER. He can make xBURGER and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once xBURGER is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract AlpacaSoloBank is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // Info of each user.
    struct UserInfo {
        uint256 amount;         // How many LP tokens the user has provided.
        uint256 rewardDebt;     // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of RewardTokens
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accRewardPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accRewardPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        address depositToken;        // Address of LP token contract.
        uint256 lastRewardBlock;     // Last block number that RewardTokens distribution occurs.
        uint256 accRewardPerShare;   // Accumulated RewardTokens per share, times 1e18. See below.
        uint256 soloPid; // solo pool id of the depoist token
    }

    address public weth;

    // The reward(USDT) TOKEN!
    address public rewardToken;

    // The SOLO contract address
    address public soloContract;

    // The buyback address
    address public buyback;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // The block number when reward token mining starts.
    uint256 public startBlock;


    struct VaultInfo {
        uint256 apy;
        uint256 remaining;
        uint256 totalDeposit;
        uint256 userEarned;
        uint256 userDeposit;
    }

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        address _weth,
        address _rewardToken,
        address _soloContract,
        address _buyback,
        uint256 _startBlock
    ) public {
        weth = _weth;
        rewardToken = _rewardToken;
        soloContract = _soloContract;
        buyback = _buyback;
        startBlock = _startBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    mapping(address => bool) public poolExistence;

    modifier nonDuplicated(address _depositToken) {
        require(poolExistence[_depositToken] == false, "nonDuplicated: duplicated");
        _;
    }

    receive() external payable {
        assert(msg.sender == weth);
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(address _depositToken, uint256 _soloPid, bool _withUpdate) public onlyOwner nonDuplicated(_depositToken) {
        if (_withUpdate) {
            massUpdatePools();
        }

        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        poolExistence[_depositToken] = true;
        poolInfo.push(
            PoolInfo({
                depositToken : _depositToken,
                lastRewardBlock : lastRewardBlock,
                accRewardPerShare : 0,
                soloPid : _soloPid
            })
        );
    }

    function userDepositInfo(uint256 _pid, address _user) public view returns (uint256 deposit, uint256 earned) {
        UserInfo memory user = userInfo[_pid][_user];
        
        deposit = user.amount;
        earned = user.rewardDebt.add(pendingReward(_pid, _user));
    }

    function poolDepositInfo(uint256 _pid) public view returns (uint256 apy, uint256 totalDeposit, uint256 remaining) {
        PoolInfo memory pool = poolInfo[_pid];
        (,uint256 depositCap, , , , uint accShare, uint256 rawApy,) = ISolo(soloContract).pools(pool.soloPid);
        apy = rawApy.mul(10000).div(9000);
        (totalDeposit,) = ISolo(soloContract).users(pool.soloPid, address(this));
        remaining = depositCap - accShare;
    }

    function totalValue() public view returns (uint256 totalDepositValue, uint256 totalRewardsValue) {
        uint256 length = poolInfo.length;
        uint256 depositAmount = 0;
        uint256 allUnclaimedReward = 0;
        for (uint256 pid = 0; pid < length; ++pid) {
            PoolInfo memory pool = poolInfo[pid];
            (, uint256 totalDeposit,) = poolDepositInfo(pid);
            depositAmount = depositAmount.add(totalDeposit);
            (, int256 _price, , ,) = AggregatorV3Interface(pool.depositToken).latestRoundData();
            uint256 price = uint256(_price);

            totalDepositValue = totalDepositValue.add(depositAmount.mul(price));
            allUnclaimedReward = allUnclaimedReward.add(unclaimedReward(pid));
        }
        uint256 claimedReward = ISolo(soloContract).userStatistics(address(this)).mul(10000).div(9000);
        totalRewardsValue = claimedReward.add(allUnclaimedReward);
    }

    function bankInfoAll(address _user) external view 
        returns (
            uint256 totalDepositValue, 
            uint256 totalRewardsValue,
            VaultInfo[] memory vaultInfo
        ) {
        (totalDepositValue, totalRewardsValue) = totalValue();

        uint256 length = poolInfo.length;
        vaultInfo = new VaultInfo[](length);
        for (uint256 pid = 0; pid < length; ++pid) {
            (uint256 apy, uint256 totalDeposit, uint256 remaining) = poolDepositInfo(pid);
            (uint256 userDeposit, uint256 userEarned) = userDepositInfo(pid, _user);
            vaultInfo[pid] = VaultInfo({
                apy: apy,
                totalDeposit: totalDeposit,
                remaining: remaining,
                userDeposit: userDeposit,
                userEarned: userEarned
            });
        }
    }

    function pendingReward(uint256 _pid, address _user) public view returns (uint256) {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo memory user = userInfo[_pid][_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;
        (uint256 depositTokenSupply,) = ISolo(soloContract).users(pool.soloPid, address(this));
        if (block.number > pool.lastRewardBlock && depositTokenSupply != 0) {
            uint256 reward = unclaimedReward(_pid);
            accRewardPerShare = accRewardPerShare.add(reward.mul(1e18).div(depositTokenSupply));
        }
        return user.amount.mul(accRewardPerShare).div(1e18).sub(user.rewardDebt);
    }


    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    function unclaimedReward(uint256 _pid) public view returns (uint256 reward) {
        return ISolo(soloContract).unclaimedReward(_pid, address(this)).mul(10000).div(9000);
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }

        (uint256 depositTokenSupply,) = ISolo(soloContract).users(pool.soloPid, address(this));
        if (depositTokenSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 reward = unclaimedReward(_pid);
        pool.accRewardPerShare = pool.accRewardPerShare.add(reward.mul(1e18).div(depositTokenSupply));

        pool.lastRewardBlock = block.number;

    }


    // Deposit LP tokens to AlpacaSoloBank for reward allocation.
    function deposit(uint256 _pid, uint256 _amount) payable public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        updatePool(_pid);

        if (address(pool.depositToken) == weth) {
            _amount = msg.value;
        }
        if (_amount > 0) {
            if (address(pool.depositToken) == weth) {
                IWETH(weth).deposit{value : _amount}();
            } else {
                IERC20(pool.depositToken).transferFrom(address(msg.sender), address(this), _amount);
            }

        }
        // deposit to SOLO whether amount>0 or not
        // to make sure all rewards claimed
        ISolo(soloContract).deposit(pool.soloPid, _amount);
        _harvest(_pid);

        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e18);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from AlpacaSoloBank.
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        
        if (_amount > 0) {
            // withdrow from SOLO 
            ISolo(soloContract).withdraw(pool.soloPid, _amount);

            safeTransfer(pool.depositToken, msg.sender, _amount);

            _harvest(_pid);

            user.amount = user.amount.sub(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e18);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    function _harvest(uint256 _pid) internal returns (uint256 reward) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 pending = user.amount.mul(pool.accRewardPerShare).div(1e18).sub(user.rewardDebt);
        if (pending > 0) {
            reward = safeTokenTransfer(rewardToken, msg.sender, pending);
            uint256 buybackAmount = pending.div(9);
            safeTokenTransfer(rewardToken, buyback, buybackAmount);
        }

        return reward;
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;

        if (amount > 0) {
            ISolo(soloContract).withdraw(pool.soloPid, amount);
        }
        safeTransfer(pool.depositToken, msg.sender, amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    function emergencySoloWithdraw(uint256 _pid) public onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        (uint256 amount,) = ISolo(soloContract).users(pool.soloPid, address(this));
        ISolo(soloContract).withdraw(pool.soloPid, amount);
    }

    function emergencySoloAllPoolsWithdraw() public onlyOwner {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            emergencySoloWithdraw(pid);
        }
    }


    // Safe Token transfer function, just in case if rounding error causes pool to not have enough tokens.
    function safeTokenTransfer(address _token, address _to, uint256 _amount) internal returns (uint256) {
        uint256 tokenBal = IERC20(_token).balanceOf(address(this));
        if (_amount > 0 && tokenBal > 0) {
            if (_amount > tokenBal) {
                _amount = tokenBal;
            }
            IERC20(_token).transfer(_to, _amount);
        }
        return _amount;
    }

    function safeTransfer(address _token, address _to, uint256 _amount) internal returns (uint256) {
        if (_token == weth) {
            IWETH(weth).withdraw(_amount);
            address(uint160(_to)).transfer(_amount);
        } else {
            IERC20(_token).transfer(_to, _amount);
        }
        return _amount;
    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * ------------------------ Solo HECO: MDEX Pools ------------------------
 *
 * Contract address: 0x1cF73836aE625005897a1aF831479237B6d1e4D2
 * Reward Token: MDX
 * Pools (pid => token):
 *  0 => BTC (0x66a79D23E58475D2738179Ca52cd0b41d73f0BEa)
 *  1 => ETH (0x64FF637fB478863B7468bc97D30a5bF3A428a1fD)
 *  2 => DOT (0xA2c49cEe16a5E5bDEFDe931107dc1fae9f7773E3)
 *  3 => USDT (0xa71EdC38d189767582C38A3145b5873052c3e47a)
 *  4 => HUSD (0x0298c2b32eaE4da002a15f36fdf7615BEa3DA047), Closed
 *  5 => MDX (0x25D2e80cB6B86881Fd7e07dd263Fb79f4AbE033c)
 *  6 => WHT (0x5545153CCFcA01fbd7Dd11C0b23ba694D9509A6F)
 *
 * ------------------------ Solo HECO: BXH Pools ------------------------
 *
 * Contract address: 0xE1f39a72a1D012315d581c4F35bb40e24196DAc8
 * Reward Token: BXH
 * Pools (pid => token):
 *  0 => BXH (0xcBD6Cb9243d8e3381Fea611EF023e17D1B7AeDF0)
 *  1 => USDT (0xa71EdC38d189767582C38A3145b5873052c3e47a)
 *  2 => HUSD (0x0298c2b32eaE4da002a15f36fdf7615BEa3DA047)
 *  3 => ETH (0x64FF637fB478863B7468bc97D30a5bF3A428a1fD)
 *  4 => BTC (0x66a79D23E58475D2738179Ca52cd0b41d73f0BEa)
 *  5 => DOT (0xA2c49cEe16a5E5bDEFDe931107dc1fae9f7773E3)
 *  6 => LTC (0xecb56cf772B5c9A6907FB7d32387Da2fCbfB63b4)
 *  7 => FIL (0xae3a768f9aB104c69A7CD6041fE16fFa235d1810)
 *  8 => HPT (0xE499Ef4616993730CEd0f31FA2703B92B50bB536)
 *
 * ------------------------ Solo BSC: MDEX Pools ------------------------
 *
 * Contract address: 0x7033A512639119C759A51b250BfA461AE100894b
 * Reward Token: MDX
 * Pools (pid => token):
 *  0 => MDX (0x9C65AB58d8d978DB963e63f2bfB7121627e3a739)
 *  1 => HMDX (0xAEE4164c1ee46ed0bbC34790f1a3d1Fc87796668)
 *  2 => WBNB (0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c)
 *  3 => BTCB (0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c)
 *  4 => ETH (0x2170Ed0880ac9A755fd29B2688956BD959F933F8)
 *  5 => DOT (0x7083609fCE4d1d8Dc0C979AAb8c869Ea2C873402), Closed
 *  6 => BUSD (0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56)
 *  7 => USDT (0x55d398326f99059fF775485246999027B3197955)
 */

interface ISolo {

    /**
     * @dev Get Pool infos
     * If you want to get the pool's available quota, let "avail = depositCap - accShare"
     */
    function pools(uint256 pid) external view returns (
        address token,              // Address of token contract
        uint256 depositCap,         // Max deposit amount
        uint256 depositClosed,      // Deposit closed
        uint256 lastRewardBlock,    // Last block number that reward distributed
        uint256 accRewardPerShare,  // Accumulated rewards per share
        uint256 accShare,           // Accumulated Share
        uint256 apy,                // APY, times 10000
        uint256 used                // How many tokens used for farming
    );

    /**
    * @dev Get pid of given token
    */
    function pidOfToken(address token) external view returns (uint256 pid);

    /**
    * @dev Get User infos
    */
    function users(uint256 pid, address user) external view returns (
        uint256 amount,     // Deposited amount of user
        uint256 rewardDebt  // Ignore
    );

    /**
     * @dev Get user unclaimed reward
     */
    function unclaimedReward(uint256 pid, address user) external view returns (uint256 reward);

    /**
     * @dev Get user total claimed reward of all pools
     */
    function userStatistics(address user) external view returns (uint256 claimedReward);

    /**
     * @dev Deposit tokens and Claim rewards
     * If you just want to claim rewards, call function: "deposit(pid, 0)"
     */
    function deposit(uint256 pid, uint256 amount) external;

    /**
     * @dev Withdraw tokens
     */
    function withdraw(uint256 pid, uint256 amount) external;

}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

