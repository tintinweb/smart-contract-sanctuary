// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Staking is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // Info of each user.
    struct UserInfo {
        uint256 initialTokens;
        uint256[] amounts;
        uint256[] milestones;
        uint256 rewards;
        uint256 rewardStartBlock;
        uint256 lastWithdrawlBlock;
        bool[] status;
        bool isFullClaimed;
        bool isStaked;
    }

    // Stake & Reward Token
    address public stakeToken;

    // List of stake holders
    address[] public allStakeHolders;

    // Mapping of User Info
    mapping(address => UserInfo) public UserInfos;

    // Duration of Staking
    uint256 public noOfDays = 100;

    // Avg no.of Blocks per day in BSC - 28623
    uint256 public noOfBlocksPerDay = 50; // Need to update this used for testing

    // hotwallet
    address public hotWallet;

    // APY
    uint256 public apy = 50;

    // days in year
    uint256 public noOfDaysYear = 365;

    constructor(address _owner, address _stakingToken, address _hotWallet) {
        require(_owner != address(0), "Initiate:: _owner can not be Zero address");
        require(_hotWallet != address(0), "Initiate:: _hotWallet can not be Zero address");
        require(_stakingToken != address(0), "Initiate:: _stakingToken can not be Zero address");
        stakeToken = _stakingToken;
        hotWallet = _hotWallet;
        transferOwnership(_owner);
    }

    event StakedAndLocked(address indexed user, uint256 amount);
    event HotWalletUpdated(address oldWallet, address newWallet);
    event FullyClaimed(address who, uint256 when);
    event StakeHarvest(address who, uint256 when, uint256 howmuch);
    event RewardHarvest(address who, uint256 when, uint256 howmuch);
    
    function stakeAndLock(address _to, uint256 _amount) public nonReentrant onlyOwner {
        require(_to != address(0), "StakeAndLock:: The recipient's address cannot be 0");
        require(_amount > 0, "StakeAndLock:: _amount can not be zero");
        require(!UserInfos[_to].isStaked, "StakeAndLock:: Already Staked");
        UserInfo storage user = UserInfos[_to];
        user.initialTokens = user.initialTokens.add(_amount);
        user.isStaked = true;
        user.isFullClaimed = false;
        user.rewards = 0;
        user.rewardStartBlock = block.number;
        user.lastWithdrawlBlock = 0;
        _setAmounts(_to, _amount);
        user.status = _setStatus(user.amounts.length, false);
        user.milestones = _setMilestones(user.amounts.length);
        IERC20(stakeToken).transferFrom(msg.sender, address(this), _amount);
        allStakeHolders.push(_to);
        emit StakedAndLocked(_to, _amount);
    }
    
    function _setAmounts(address _to, uint256 _amount) internal {
        UserInfo storage user = UserInfos[_to];
        UserInfos[_to].amounts.push(_amount.div(2));
        for(uint256 i = 1; i<= 100; i++) {
            user.amounts.push(getAmount(_amount));
        }
    }
    
    function getAmount(uint256 _amount) public pure returns(uint256) {
       return _amount.mul(1e12).mul(1).div(2).div(100).div(1e12);
    }
    
    function _setStatus(uint256 size, bool value) internal pure returns (bool[] memory isClaimed) {
        isClaimed = new bool[](size);
        for (uint256 i = 0; i < size; i++) {
            isClaimed[i] = value;
        }
        return isClaimed;
    }
    
    function _setMilestones(uint256 size) internal view returns (uint256[] memory milestones) {
        milestones = new uint256[](size);
        uint256 _noOfBlocksPerDay = noOfBlocksPerDay;
        uint256 _rewardStartBlock = block.number;
        for (uint256 i = 0; i < size; i++) {
            milestones[i] = _rewardStartBlock.add(_noOfBlocksPerDay.mul(i));
        }
        return milestones;
    }
    
    function harvest() external nonReentrant {
        require(UserInfos[msg.sender].isStaked, "Harvest:: No Stake Found");
        require(!UserInfos[msg.sender].isFullClaimed, "Harvest:: Fully Claimed");
        UserInfo storage user = UserInfos[msg.sender];
        uint256 unlockedTokens = 0;
        uint256 daysStaked = 0;
        for (uint256 i = 0; i < user.amounts.length; i++) {
            if (block.number > user.milestones[i] && user.status[i] == false) {
                unlockedTokens += user.amounts[i];
                user.status[i] = true;
                daysStaked = daysStaked.add(1);
            }
        }
        
        // Tokens allowed to claim
        IERC20(stakeToken).transfer(msg.sender, unlockedTokens);
        user.lastWithdrawlBlock = block.timestamp;
        
        // Rewards Earned
        uint256 rewards = unlockedTokens.mul(apy.mul(1e12).div(1e12)).mul(daysStaked).div(noOfDaysYear);
        IERC20(stakeToken).transferFrom(hotWallet, msg.sender, rewards);
        
        _isFullyClaimed();
        
        emit StakeHarvest(msg.sender, block.timestamp, unlockedTokens);
        emit RewardHarvest(msg.sender, block.timestamp, rewards);
            
    }
    
    function _isFullyClaimed() internal {
        UserInfo storage user = UserInfos[msg.sender];
        uint256 count = 0;
        for (uint256 i = 0; i < user.amounts.length; i++) {
            if(user.status[i] == true) {
                count = count.add(1);
            }
        }
        if(count == 101) {
            user.isFullClaimed = true;
            emit FullyClaimed(msg.sender, block.timestamp);
        }
    }

    function updateHotWallet(address _newHotWallet) external onlyOwner {
        require(_newHotWallet != address(0), "UpdateHotWallet:: Hotwallet can not be zero address");
        address _oldHotWallet = hotWallet;
        hotWallet = _newHotWallet;
        emit HotWalletUpdated(_oldHotWallet, _newHotWallet);
    }

    function userStake(address _to) external view returns(uint256, uint256[] memory, uint256[] memory, uint256, uint256, uint256, bool[] memory, bool, bool) {
        UserInfo storage user = UserInfos[_to];
        return (
            user.initialTokens,
            user.amounts,
            user.milestones,
            user.rewards,
            user.rewardStartBlock,
            user.lastWithdrawlBlock,
            user.status,
            user.isFullClaimed,
            user.isStaked
        );
    }

    function pendingHarvest(address _to) external view returns(uint256) {
        UserInfo storage user = UserInfos[_to];
        uint256 unlockedTokens = 0;
        for (uint256 i = 0; i < user.amounts.length; i++) {
            if (block.number > user.milestones[i] && user.status[i] == false) {
                unlockedTokens += user.amounts[i];
            }
        }
        return unlockedTokens;
    }

    function isStaked(address _to) public view returns (bool) {
        return UserInfos[_to].isStaked;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

    constructor() {
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

