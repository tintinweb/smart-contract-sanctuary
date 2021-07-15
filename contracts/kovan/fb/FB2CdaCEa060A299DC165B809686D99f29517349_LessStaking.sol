/**
 *Submitted for verification at Etherscan.io on 2021-07-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
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
    constructor () {
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


// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


/**
 *@dev Staking contract with penalty
 *
 */
contract LessStaking is Ownable {
    using SafeMath for uint256;

    uint24 public constant SEC_IN_DAY = 86400;

    IERC20 public lessToken;
    IUniswapV2Pair public lpToken;
 
    uint256 public minDaysStake = 7;
    uint16 public penaltyDistributed = 5; //100% = 1000
    uint16 public penaltyBurned = 5; //100% = 1000
    uint256 public lessPerLp = 300; //1 LP = 300 LESS

    uint256 public stakeIdLast;

    uint256 public allLp;
    uint256 public allLess;
    uint256 public totalLpRewards;
    uint256 public totalLessRewards;

    struct StakeItem {
        uint256 stakeId;
        uint256 startTime;
        uint256 stakedLp;
        uint256 stakedLess;
        // uint256 lpEarned;
        // uint256 lessEarned;
        uint256 lpRewardsWithdrawn;
        uint256 lessRewardsWithdrawn;
    }

    event Staked(
        address staker,
        uint256 stakeId,
        uint256 startTime,
        uint256 stakedLp,
        uint256 stakedLess
    );

    struct Unstake {
        address staker;
        uint256 stakeId;
        uint256 unstakeTime;
        uint256 unstakedLp;
        uint256 unstakedLess;
        uint256 lpRewards;
        uint256 lessRewards;
        bool isUnstakedEarlier;
        bool isUnstakedFully;
    }

    event Unstaked(Unstake);

    enum BalanceType {
        Less,
        Lp,
        Both
    }

    mapping(address => StakeItem[]) public stakeList;

    address[] stakers;

    constructor(IUniswapV2Pair _lp, IERC20 _less) {
        lessToken = _less;
        lpToken = _lp;
    }

    /**
     * @dev stake tokens
     * @param lpAmount Amount of staked LP tokens
     * @param lessAmount Amount of staked Less tokens
     */

    function stake(uint256 lpAmount, uint256 lessAmount) external {
        require(lpAmount > 0 || lessAmount > 0, "Error: zero staked tokens");
        if (lpAmount > 0) {
            require(
                lpToken.transferFrom(_msgSender(), address(this), lpAmount),
                "Error: LP token tranfer failed"
            );
        }
        if (lessAmount > 0) {
            require(
                lessToken.transferFrom(_msgSender(), address(this), lessAmount),
                "Error: Less token tranfer failed"
            );
        }
        allLp = allLp.add(lpAmount);
        allLess = allLess.add(lessAmount);
        if (stakeList[_msgSender()].length == 0) {
            stakers.push(_msgSender());
        }
        stakeList[_msgSender()].push(
            StakeItem(stakeIdLast, block.timestamp, lpAmount, lessAmount, 0, 0)
        );

        emit Staked(
            _msgSender(),
            stakeIdLast++,
            block.timestamp,
            lpAmount,
            lessAmount
        );
    }

    /**
     * @dev unstake tokens without penalty. Only for owner
     * @param lpAmount Amount of unstaked LP tokens
     * @param lessAmount Amount of unstaked Less tokens
     * @param lpRewards Amount of withdrawing rewards in LP
     * @param lessRewards Amount of withdrawing rewards in Less
     * @param _stakeId id of the unstaked pool
     */

    function unstakeWithoutPenalty(
        uint256 lpAmount,
        uint256 lessAmount,
        uint256 lpRewards,
        uint256 lessRewards,
        uint256 _stakeId
    ) external onlyOwner {
        _unstake(lpAmount, lessAmount, lpRewards, lessRewards, _stakeId, true);
    }

    /**
     * @dev unstake tokens
     * @param lpAmount Amount of unstaked LP tokens
     * @param lessAmount Amount of unstaked Less tokens
     * @param lpRewards Amount of withdrawing rewards in LP
     * @param lessRewards Amount of withdrawing rewards in Less
     * @param _stakeId id of the unstaked pool
     */

    function unstake(
        uint256 lpAmount,
        uint256 lessAmount,
        uint256 lpRewards,
        uint256 lessRewards,
        uint256 _stakeId
    ) external {
        _unstake(lpAmount, lessAmount, lpRewards, lessRewards, _stakeId, false);
    }

struct UnstakeItem {
           uint256 unstakedLp;
           uint256 unstakedLess;
           uint256 lpRewardsAmount;
           uint256 lessRewardsAmount;
        }


    function _unstake(
        uint256 lpAmount,
        uint256 lessAmount,
        uint256 lpRewardsAmount,
        uint256 lessRewardsAmount,
        uint256 _stakeId,
        bool isWithoutPenalty
    ) internal {
        address staker = _msgSender();
        require(stakeList[staker].length > 0, "Error: you haven't stakes");

        

        uint256 index = _getStakeIndexById(staker, _stakeId);
        require(index != ~uint256(0), "Error: no such stake");
        StakeItem memory deposit = stakeList[staker][index];

        uint256 stakeLessRewards = (deposit.stakedLess).mul(lessRewardsAmount).div(allLess);
        uint256 stakeLpRewards = (deposit.stakedLp).mul(lpRewardsAmount).div(allLp);

        require(lpAmount > 0 || lessAmount > 0, "Error: you unstake nothing");
        require(
            lpAmount <= deposit.stakedLp,
            "Error: insufficient LP token balance"
        );
        require(
            lessAmount <= deposit.stakedLess,
            "Error: insufficient Less token balance"
        );
        require(
            lpRewardsAmount <= (stakeLpRewards - deposit.lpRewardsWithdrawn),
            "Error: insufficient LP token rewards"
        );
        require(
            lessRewardsAmount <= (stakeLessRewards - deposit.lessRewardsWithdrawn),
            "Error: insufficient Less token rewards"
        );

        
        UnstakeItem memory unstakeItem = UnstakeItem(lpAmount, lessAmount, lpRewardsAmount, lessRewardsAmount);



        bool isUnstakedEarlier = block.timestamp.sub(deposit.startTime) <
            minDaysStake.mul(SEC_IN_DAY);
        if (isUnstakedEarlier && !isWithoutPenalty) {
            uint256 lpToBurn = unstakeItem.unstakedLp.mul(penaltyBurned).div(1000);
            uint256 lessToBurn = unstakeItem.unstakedLess.mul(penaltyBurned).div(1000);
            uint256 lpToDist = unstakeItem.unstakedLp.mul(penaltyDistributed).div(1000);
            uint256 lessToDist = unstakeItem.unstakedLess.mul(penaltyDistributed).div(1000);

            unstakeItem.unstakedLp = unstakeItem.unstakedLp.sub(lpToBurn.add(lpToDist));
            unstakeItem.unstakedLess = unstakeItem.unstakedLess.sub(lessToBurn.add(lessToDist));

            burnPenalty(lpToBurn, lessToBurn);
            distributePenalty(lpToDist, lessToDist);
        }
        uint256 tranferedLp = unstakeItem.unstakedLp.add(unstakeItem.lpRewardsAmount);
        uint256 tranferedLess = unstakeItem.unstakedLess.add(unstakeItem.lessRewardsAmount);

        require(
            lpToken.transfer(staker, tranferedLp),
            "Error: LP transfer failed"
        );
        require(
            lessToken.transfer(staker, tranferedLess),
            "Error: Less transfer failed"
        );

        allLp = allLp.sub(unstakeItem.unstakedLp);
        allLess = allLess.sub(unstakeItem.unstakedLess);
        deposit.stakedLp = deposit.stakedLp.sub(lpAmount);
        deposit.stakedLess = deposit.stakedLess.sub(lessAmount);
        deposit.lpRewardsWithdrawn = deposit.lpRewardsWithdrawn.add(unstakeItem.lpRewardsAmount);
        deposit.lessRewardsWithdrawn = deposit.lessRewardsWithdrawn.add(unstakeItem.lessRewardsAmount);
        totalLessRewards = totalLessRewards.sub(unstakeItem.lessRewardsAmount);
        totalLpRewards = totalLpRewards.sub(unstakeItem.lpRewardsAmount);
        
        bool isStakeEmpty = deposit.stakedLp == 0 &&
            deposit.stakedLess == 0 &&
            deposit.lpRewardsWithdrawn == stakeLpRewards &&
            deposit.lessRewardsWithdrawn == stakeLessRewards;

        if (isStakeEmpty) {
            removeStake(staker, index);
        }

        if (stakeList[staker].length == 0) {
            deleteStaker(staker);
        }

        emit Unstaked(
            Unstake(
                staker,
                deposit.stakeId,
                block.timestamp,
                unstakeItem.unstakedLp,
                unstakeItem.unstakedLess,
                unstakeItem.lpRewardsAmount,
                unstakeItem.lessRewardsAmount,
                isUnstakedEarlier,
                isStakeEmpty
            )
        );
    }

    /**
     * @dev destribute penalty among all stakers proportional their stake sum.
     * @param lp LP token penalty
     * @param less Less token penalty
     */

    function distributePenalty(uint256 lp, uint256 less) internal {
        require(lp > 0 || less > 0, "Error: zero penalty");
        // for (uint256 i = 0; i < stakers.length; i++) {
        //     StakeItem[] memory stakes = stakeList[stakers[i]];
        //     for (uint256 j = 0; j < stakes.length; j++) {
        //         uint256 lpBalance = stakes[j].stakedLp;
        //         uint256 lessBalance = stakes[j].stakedLess;
        //         uint256 shareLp = lpBalance.mul(lp).div(allLp);
        //         uint256 shareLess = lessBalance.mul(less).div(allLess);

        //         stakes[j].lpEarned = stakes[j].lpEarned.add(shareLp);
        //         stakes[j].lessEarned = stakes[j].lessEarned.add(shareLess);
        //     }
        // }

        totalLessRewards = totalLessRewards.add(less);
        totalLpRewards = totalLpRewards.add(lp);
    }

    /**
     * @dev burn penalty.
     * @param lp LP token penalty
     * @param less Less token penalty
     */

    function burnPenalty(uint256 lp, uint256 less) internal {
        require(lp > 0 || less > 0, "Error: zero penalty");
        if (lp > 0) {
            lpToken.transfer(address(0), lp);
            allLp = allLp.sub(lp);
        }
        if (less > 0) {
            lessToken.transfer(address(0), less);
            allLess = allLess.sub(less);
        }
    }

    /**
     * @dev return full LP balance of staker.
     * @param staker staker address
     */

    function getLpBalanceByAddress(address staker)
        public
        view
        returns (uint256)
    {
        return _getBalanceByAddress(staker, BalanceType.Lp);
    }

    /**
     * @dev return full Less balance of staker.
     * @param staker staker address
     */
    function getLessBalanceByAddress(address staker)
        public
        view
        returns (uint256)
    {
        return _getBalanceByAddress(staker, BalanceType.Less);
    }

    /**
     * @dev return full balance of staker converted to Less.
     * @param staker staker address
     */
    function getOverallBalanceInLessByAddress(address staker)
        public
        view
        returns (uint256)
    {
        return _getBalanceByAddress(staker, BalanceType.Both);
    }

    /**
     * @dev return sum of LP converted in Less
     * @param _amount amount of converted LP
     */
    function getLpInLess(uint256 _amount) public view returns (uint256) {
        return _amount.mul(lessPerLp);
    }

    /**
     * @dev return num of all LP on the contract
     */
    function getOverallLP() public view returns (uint256) {
        return allLp;
    }

    /**
     * @dev return num of all Less on the contract
     */
    function getOverallLess() public view returns (uint256) {
        return allLess;
    }

    /**
     * @dev return full contract balance converted in Less
     */
    function getOverallBalanceInLess() public view returns (uint256) {
        return allLess.add(allLp.mul(lessPerLp));
    }

    /**
     * @dev set num of Less per one LP
     */

    function setLessInLP(uint256 amount) public onlyOwner {
        lessPerLp = amount;
    }

    /**
     * @dev set minimum days of stake for unstake without penalty
     */

    function setMinDaysStake(uint256 _minDaysStake) public onlyOwner {
        minDaysStake = _minDaysStake;
    }

    /**
     * @dev set penalty percent
     */
    function setPenalty(uint16 distributed, uint16 burned) public onlyOwner {
        penaltyDistributed = distributed;
        penaltyBurned = burned;
    }

    /**
     * @dev return index of stake by id
     * @param staker staker address
     * @param stakeId of stake pool
     */

    function _getStakeIndexById(address staker, uint256 stakeId)
        internal
        view
        returns (uint256)
    {
        StakeItem[] memory stakes = stakeList[staker];
        require(stakes.length > 0, "Error: user havn't stakes");
        for (uint256 i = 0; i < stakes.length; i++) {
            if (stakes[i].stakeId == stakeId) return i;
        }
        return ~uint256(0);
    }

    /**
     * @dev support function for get balance of address
     * @param staker staker address
     * @param balanceType type of balance
     */

    function _getBalanceByAddress(address staker, BalanceType balanceType)
        internal
        view
        returns (uint256 balance)
    {
        StakeItem[] memory deposits = stakeList[staker];
        if (deposits.length > 0) {
            for (uint256 i = 0; i < deposits.length; i++) {
                if (balanceType == BalanceType.Lp)
                    balance = balance.add(deposits[i].stakedLp);
                else if (balanceType == BalanceType.Less)
                    balance = balance.add(deposits[i].stakedLess);
                else
                    balance = balance.add(deposits[i].stakedLess).add(
                        getLpInLess(deposits[i].stakedLp)
                    );
            }
        }
    }

    /**
     * @dev remove stake from stakeList by index
     * @param staker staker address
     * @param index of stake pool
     */

    function removeStake(address staker, uint256 index) internal {
        require(stakeList[staker].length != 0);
        if (stakeList[staker].length == 1) {
            stakeList[staker].pop();
        } else {
            stakeList[staker][index] = stakeList[staker][
                stakeList[staker].length
            ];
            stakeList[staker].pop();
        }
    }

    function deleteStaker(address staker) internal {
        require(stakers.length != 0);
        if (stakers.length == 1) {
            stakers.pop();
        } else {
            uint256 index;
            for (uint256 i = 0; i < stakers.length; i++) {
                if (stakers[i] == staker) {
                    index = i;
                    break;
                }
            }
            stakers[index] = stakers[stakers.length];
            stakers.pop();
        }
    }
}