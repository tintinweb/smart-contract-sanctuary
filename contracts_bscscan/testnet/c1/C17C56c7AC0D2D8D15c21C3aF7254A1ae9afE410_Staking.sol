// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/// @author TokenX Team
/// @title Staking
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
interface PriceConsumerV3 {
    function getLatestPrice() external view returns (uint256);
}

interface TokenG {
    function mint(address _to, uint256 _amount) external;
}
contract Staking {
    // Owner address.
    address payable public owner;
    // Token Staking (Token M Address).
    IERC20 public stakingToken = IERC20(address(0xdc9540A68bc3cA9DBB7f10a389Ea64Ae837D7540));
    // Token Reward (Token G Address).
    IERC20 public rewardToken = IERC20(address(0x0ddF3Fb9025Ca9918a14358828596eC054f9FA55));
    TokenG tg = TokenG(address(0x0ddF3Fb9025Ca9918a14358828596eC054f9FA55));
    // Timestamp when reward starts.
    uint256 public start;
    // Timestamp when reward ends.
    uint256 public end;
    // Token G backed by 0.00055 Oz of gold.
    uint256 public goldBacked = 550000000000000;
    // Total number of seconds per year.
    uint256 public secondsPerYear =  31536000;
    // Percent APR reward.
    uint256 public percentAPR = 150000000000000000;
    // Gole price address.
    address public goldPriceAddress;
    PriceConsumerV3 pc;
    

   // Info of each user.
    struct UserInfo {
        uint256 amount; // How many token M the user has provided.
        uint256 lastRewardBlock;  //Last block number that user claim rewards.
        uint256 lastRewardTimestamp;  //Last block timestamp that user claim rewards.
    }
    // Info of each user that stakes tokens.
    mapping (address => UserInfo) public userInfo;
    /// @dev Emited when user deposit.
    event Deposit(address sender, uint256 amount);
    /// @dev Emited when user withdraw.
    event Withdraw(address sender, uint256 amount);
    /// @dev Emited when user harvest.
    event Harvest(address sender, address user, uint256 amount);
    /// @dev Emited when admin update new start & end timestamp.
    event NewStartAndEnd(uint256 start, uint256 end);
    /// @dev Emited when admin update gold price address.
    event UpdateGoldPriceAddress(address oldAddress, address newAddress);
    //event TestLog(uint256 goldPrice, uint256 pending);

    using SafeMath for uint256;
    constructor(uint256 _start, uint256 _end, address _goldPriceAddress){
        owner = payable(msg.sender);
        start = _start;
        end = _end;
        goldPriceAddress = _goldPriceAddress;
        pc = PriceConsumerV3(goldPriceAddress);
    }
    modifier onlyOwner() {
        require(owner == msg.sender, "Only owner");
        _;
    }

    /** 
     * @dev Deposit token M and harvest token G.
     * @param _amount: amount of token M to deposit.
     */
    function deposit(uint256 _amount) public {
        UserInfo storage user = userInfo[msg.sender];
        if (user.amount > 0 && block.timestamp > user.lastRewardTimestamp) {
            uint256 pending = _getPendingReward(user.lastRewardTimestamp, block.timestamp, user.amount);
            if(pending > 0) {
                _mintReward(msg.sender, pending);
            }
        }
        if(_amount > 0) {
            stakingToken.transferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.lastRewardBlock = block.number;
        user.lastRewardTimestamp = block.timestamp;
        emit Deposit(msg.sender, _amount);
    }

    /** 
     * @dev Withdraw token M and harvest token G.
     * @param _amount: amount of token M to  withdraw.
     */
    function withdraw(uint256 _amount) public {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "withdraw not good");
        uint256 pending = _getPendingReward(user.lastRewardTimestamp, block.timestamp, user.amount);
        if(pending > 0) {
            _mintReward(msg.sender, pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            stakingToken.transfer(address(msg.sender), _amount);
        }
        user.lastRewardBlock = block.number;
        user.lastRewardTimestamp = block.timestamp;
        emit Withdraw(msg.sender, _amount);
    }

    /** 
     * @dev harvest Harvest rewards.
     * @param _user: user address.
     */
    function harvest(address _user) public {
        UserInfo storage user = userInfo[_user];
        require(user.amount > 0, "Nothing to harvest");
        uint256 pending = _getPendingReward(user.lastRewardTimestamp, block.timestamp, user.amount);
        require(pending > 0, "Nothing to harvest");
        _mintReward(_user, pending);
        user.lastRewardBlock = block.number;
        user.lastRewardTimestamp = block.timestamp;
        emit Harvest(msg.sender, _user, pending);
    }

    /** 
     * @dev pendingReward Return  pending rewards.
     * @param _user: user address.
     * @return Return pending rewards
     */
    function pendingReward(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        return _getPendingReward(user.lastRewardTimestamp, block.timestamp, user.amount);
    }

    /**
     * @dev It allows the admin to update start and end timestamp
     * @param _start: new start timestamp
     * @param _end: new end timestamp
     */
    function updateStartAndEnd(uint256 _start, uint256 _end) public onlyOwner {
        require(_start < _end, "New start must be lower than new end");
        require(block.timestamp < _start, "New start must be higher than current");
        start = _start;
        end = _end;
        emit NewStartAndEnd(_start, _end);
    }

    /**
     * @dev It allows the admin to update gold price address
     * @param _address: new address
     */
    function updateGoldPriceAddress(address _address) public onlyOwner {
        address oldGoldPriceAddress = goldPriceAddress;
        goldPriceAddress = _address;
        pc = PriceConsumerV3(goldPriceAddress);
        emit UpdateGoldPriceAddress(oldGoldPriceAddress, goldPriceAddress);
    }
    
    /** 
     * @dev _getMultiplier Return reward multiplier over the given _from to _to block timestamp.
     * @param _from: time to start
     * @param _to: time to finish
     * @return Reward multiplier
     */
    function _getMultiplier(uint256 _from, uint256 _to) private view returns (uint256) {
        if (_to <= end) {
            return _to.sub(_from);
        } else if (_from >= end) {
            return 0;
        } else {
            return end.sub(_from);
        }
    }

    /** 
     * @dev _getPendingReward Return  pending rewards over the given _lastRewardTimestamp to _currentTimestamp block timestamp.
     * @param _lastRewardTimestamp: last block timestamp that user claim rewards.
     * @param _currentTimestamp: current block timestamp.
     * @param _amount: amount of token M to claim rewards.
     * @return Return pending rewards
     */
    function _getPendingReward(uint256 _lastRewardTimestamp, uint256 _currentTimestamp, uint256 _amount) private view returns(uint256){
        uint256 goldPrice = pc.getLatestPrice();
        require(goldPrice > 0, "Gold Price Error");
        uint256 multiplier = _getMultiplier(_lastRewardTimestamp, _currentTimestamp);
        uint256 _a =  percentAPR.mul(_amount).mul(multiplier) * 1e18;
        uint256 pending = _a.div((goldPrice.mul(goldBacked).mul(secondsPerYear)));
        return pending;
    }

    /** 
     * @dev _mintReward  Mint reward from this address to user
     * @param _to: user address.
     * @param _amount: The amount of tokens to mint.
     */
    function _mintReward(address _to, uint256 _amount) private{
       tg.mint(_to, _amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}