/**
 *Submitted for verification at Etherscan.io on 2021-04-06
*/

// File: contracts\interfaces\IERC20.sol

// SPDX-License-Identifier: MIT

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

// File: contracts\ownable\Ownable.sol

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        _owner = msg.sender;
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
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
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

// File: contracts\libraries\SafeMath.sol

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

// File: contracts\timelock\TimeLock.sol


/// @author Jorge Gomes Dur├ín ([email protected])
/// @title A vesting contract to lock tokens for ZigCoin

contract TimeLock is Ownable {
    using SafeMath for uint256;

    enum LockType {
        PrivateSale,
        Advisor,
        LiquidityProviders,
        Campaigns,
        Reserves,
        ExchangeListings,
        Traders,
        Founder
    }

    struct LockAmount {
        uint8 lockType;
        uint256 amount;
    }

    uint32 internal constant _1_MONTH_IN_SECONDS = 2592000;
    uint8  internal constant _6_MONTHS = 6;

    uint8 internal constant _MONTH_1_PRIVATE_SALE_FIRST_UNLOCK = 0;
    uint8 internal constant _MONTH_2_PRIVATE_SALE_FIRST_UNLOCK = 3;
    uint8 internal constant _MONTH_3_PRIVATE_SALE_FIRST_UNLOCK = 6;    

    uint8 internal constant _PERCENTS_1_VESTING_PRIVATE_SALES = 30;
    uint8 internal constant _PERCENTS_2_VESTING_PRIVATE_SALES = 60;
    uint8 internal constant _PERCENTS_3_VESTING_PRIVATE_SALES = 100;

    address immutable private token;
    uint256 private tokenListedAt;
    
    mapping(address => LockAmount) private balances;
    mapping(address => uint256) private withdrawn;

    event TokenListed(address indexed from, uint256 datetime);
    event TokensLocked(address indexed wallet, uint256 balance, uint8 lockType);
    event TokensUnlocked(address indexed wallet);
    event Withdrawal(address indexed wallet, uint256 balance);
    event EmergencyWithdrawal(address indexed wallet, uint256 balance);

    constructor(address _token) {
        token = _token;  
    }

    /** 
     * @notice locks an amount of tokens to a wallet. Call only before listing the token
     * @param _user     --> wallet that will receive the tokens once unlocked
     * @param _balance  --> balance to lock
     * @param _lockType --> lock type to know what unlock rules apply
     */
    function lockTokens(address _user, uint256 _balance, uint8 _lockType) external onlyOwner {
        require(tokenListedAt == 0, "TokenAlreadyListed");
        require(balances[_user].amount == 0, "WalletExistsYet");  
        require(_lockType >= 0 && _lockType <= 7, "BadLockType");      

        balances[_user] = LockAmount(_lockType, _balance);

        emit TokensLocked(_user, _balance, _lockType);
    }

    /** 
     * @notice remove a token lock. Use if there's any mistake locking tokens
     * @param _user --> wallet to remove tokens
     */
    function unlockTokens(address _user) external onlyOwner {
        require(tokenListedAt == 0, "TokenAlreadyListed");
        require(balances[_user].amount > 0, "WalletNotFound");

        delete balances[_user];

        emit TokensUnlocked(_user);
    }

    /** 
     * @notice send available tokens to the wallet once are unlocked
     * @param _user    --> wallet that will receive the tokens
     * @param _amount  --> amount to withdraw
     */
    function withdraw(address _user, uint256 _amount) external onlyOwner {
        require(tokenListedAt > 0, "TokenNotListedYet");
        require(balances[_user].amount > 0, "WalletNotFound");
        require(_amount > 0, "BadAmount");

        uint256 canWithdrawAmount = _canWithdraw(_user);
        uint256 amountWithdrawn = withdrawn[_user];

        require(canWithdrawAmount > amountWithdrawn, "CantWithdrawYet");
        require(canWithdrawAmount - amountWithdrawn >= _amount, "AmountExceedsAllowance");

        withdrawn[_user] += _amount;
        IERC20(token).transfer(_user, _amount);

        emit Withdrawal(_user, _amount);
    }

    /** 
     * @notice unlock all the tokens. Only use if there's any emergency
     */
    function emergencyWithdraw() external onlyOwner {
        IERC20 erc20 = IERC20(token);
        
        uint256 balance = erc20.balanceOf(address(this));
        erc20.transfer(owner(), balance);

        emit EmergencyWithdrawal(msg.sender, balance);
    }

    /**
     * @notice set the listing date to start the count for unlock tokens
     */
    function setTokenListed() external onlyOwner {
        require(tokenListedAt == 0, "TokenAlreadyListed");
        tokenListedAt = block.timestamp;
        
        emit TokenListed(msg.sender, tokenListedAt);
    }

    /** 
     * @notice get the token listing date
     * @return listing date
     */ 
    function getTokenListedAt() external view returns (uint256) {
        return tokenListedAt;
    }

    /** 
     * @notice get the total locked balance of a wallet in the contract
     * @param _user --> wallet
     * @return amount locked amount
     * @return lockType wallet type
     */ 
    function balanceOf(address _user) external view returns(uint256 amount, uint8 lockType) {
        amount = balances[_user].amount;
        lockType = balances[_user].lockType;
    }

    /** 
     * @notice get the total locked balance of a wallet in the contract
     * @param _user --> wallet
     * @return locked amount and wallet type
     */ 
    function balanceOfWithdrawan(address _user) external view returns(uint256) {
        return withdrawn[_user];
    }

    /** 
     * @notice get the total of tokens in the contract
     * @return tokens amount
     */ 
    function getContractFunds() external view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    /** 
     * @notice get the amount of tokens that a wallet can withdraw right now
     * @param _user --> wallet
     * @return tokens amount
     */ 
    function canWithdraw(address _user) external view returns (uint256) {
        uint256 canWithdrawAmount = _canWithdraw(_user);
        uint256 amountWithdrawn = withdrawn[_user];

        return canWithdrawAmount - amountWithdrawn;
    }

    /** 
     * @notice get the number of months from token listing
     * @return months
     */ 
    function _getMonthFromTokenListed() internal view returns(uint256) {
        if (tokenListedAt == 0) return 0;
        if (tokenListedAt > block.timestamp) return 0;

        return (block.timestamp - tokenListedAt).div(_1_MONTH_IN_SECONDS);
    }

    /** 
     * @notice get the amount of tokens that a wallet can withdraw by lock up rules
     * @param _user --> wallet
     * @return amount
     */ 
    function _canWithdraw(address _user) internal view returns (uint256 amount) {
        uint8 lockType = balances[_user].lockType;
        
        // Only if token has beed listed
        if (tokenListedAt > 0) {
            uint256 month = _getMonthFromTokenListed();
            if (LockType(lockType) == LockType.Founder) {
                // Founders have a linear 30 months unlock starting 6 months after listing
                if (month >= _6_MONTHS) {
                    uint monthAfterUnlock = month - _6_MONTHS + 1;
                    amount = balances[_user].amount.mul(monthAfterUnlock).div(30);
                    if (amount > balances[_user].amount) amount = balances[_user].amount;
                }
            } else if ((LockType(lockType) == LockType.PrivateSale) || (LockType(lockType) == LockType.Advisor)) {
                // Private sales and advisors can unlock 30% at listing token date, 30% after 3 months and 40% after 6 months
                if ((month >= _MONTH_1_PRIVATE_SALE_FIRST_UNLOCK) && (month < _MONTH_2_PRIVATE_SALE_FIRST_UNLOCK)) {
                    amount = balances[_user].amount.mul(_PERCENTS_1_VESTING_PRIVATE_SALES).div(100);
                } else if ((month >= _MONTH_2_PRIVATE_SALE_FIRST_UNLOCK) && (month < _MONTH_3_PRIVATE_SALE_FIRST_UNLOCK)) {
                    amount = balances[_user].amount.mul(_PERCENTS_2_VESTING_PRIVATE_SALES).div(100);
                } else if (month >= _MONTH_3_PRIVATE_SALE_FIRST_UNLOCK) {
                    amount = balances[_user].amount;
                }
            } else {
                // Other tokens can be withdrawn any time
                amount = balances[_user].amount;
            }
        }
    }
}