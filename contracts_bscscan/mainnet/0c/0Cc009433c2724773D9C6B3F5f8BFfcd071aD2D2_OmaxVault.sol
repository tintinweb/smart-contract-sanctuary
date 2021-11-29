/**
 *Submitted for verification at BscScan.com on 2021-11-29
*/

// OpenZeppelin Contracts v4.3.2 (utils/math/SafeMath.sol)

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


// OpenZeppelin Contracts v4.3.2 (token/ERC20/IERC20.sol)

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
pragma solidity ^0.8.3;

contract OmaxVault {

    IERC20 private _token;
    
    
    uint lockFeePenalisation = 25;
    
    bool canDeposit = true;
    
    address contractOwner;
    address marketingWallet = 0x659b57f42a98B406aB4aBCb1F93724d41baf114d;
    
    uint256 currentOmaxDeposited;
    uint256 totalOmaxWithdrawn;

    mapping(uint256 => uint) percentageRewardForTimelock;
    
    uint256 earlyWithdrawalFeeBalance;
    
     struct OmaxDeposit {
        uint256 id;
        address depositOwner;
        uint256 depositValue;
        bool isWithdrawn;
        uint depositTime;
        uint256 timeLockInSeconds;
    }

    OmaxDeposit[] public omaxDeposits;
    mapping(address => mapping(uint256 => bool)) activeDeposits;

    event OmaxTokenDeposit(uint256 depositId, address depositOwner, uint256 depositValue, bool isWithdrawn, uint depositTime, uint256 timeLockInSeconds);
    event OmaxTokenWithdraw(uint256 depositId, address depositOwner, uint256 value, uint withdrawTime, bool forceWithdraw);
    event IncrementedEarlyWithdrawalFeeBalance(uint256 value);
    event WithdrawnEarlyBalance(uint256 value);
    
    using SafeMath for uint256;


    constructor (IERC20 omaxTokenAddress) {
        _token = omaxTokenAddress;
        contractOwner = msg.sender;
    }
    
    function totalAmountDeposited() external view returns(uint256) {
        return currentOmaxDeposited;
    }
    
    function transferContractOwnership(address newOwnerAddress) external returns(bool)
    {
        require(msg.sender == contractOwner, "Only contract owner can use this.");
        contractOwner = newOwnerAddress;
        return true;
    }

    function changeMarketingWallet(address newMarketingWallet) external returns(bool)
    {
        require(msg.sender == contractOwner, "Only contract owner can use this.");
        marketingWallet = newMarketingWallet;
        return true;
    }
    
    function totalAmountWithdrawnWithRewards() external view returns(uint256){
        return totalOmaxWithdrawn;
    }

    
    function setPercentageRewardForTimelock (uint256 timelock, uint percentageReward) external {
        require(msg.sender == contractOwner, "Only the contract owner can set this.");
        percentageRewardForTimelock[timelock] = percentageReward;
    }
    
    
    function getPercentageRewardForTimelock(uint256 timelock) external view returns(uint) {
        return percentageRewardForTimelock[timelock];
        
    }
    
    function getCanDeposit() external view returns(bool) {
        return canDeposit;
    }
    
    function switchCanDeposit() external {
        require(msg.sender == contractOwner, "Only the contract owner can set this.");
        canDeposit = !canDeposit;
    }
    
    function setEarlyWithdrawalPenalisation (uint _lockFeePenalisation) external {
        require(msg.sender == contractOwner, "Only the contract owner can set this.");
        lockFeePenalisation = _lockFeePenalisation;
    }
    
    function getLockFeePenalisation() external view returns(uint) {
        return lockFeePenalisation;
    }    

    function getMarketingWallet() external view returns(address) {
        return marketingWallet;
    }
    
    function getReflectionAndTaxBalance() external view returns(uint256) {
        return (_token.balanceOf(address(this)) - currentOmaxDeposited);
    }
    
    function withdrawReflectionAndTaxBalance(address walletAddress) external returns(bool) {
        require(msg.sender == contractOwner, "Only the contract owner use this.");
        
        _token.transfer(
                 walletAddress, 
                 (_token.balanceOf(address(this)) - currentOmaxDeposited)
        );        
       
        return true;
    }

    function depositOmax(uint256 amountToLockInWei, uint256 timeLockSeconds) external {
        
        require(canDeposit = true, "Deposit is temporarily disabled");
        require(amountToLockInWei != 0, "Cannot lock 0 amount of tokens");
        
        uint256 newItemId = omaxDeposits.length;
        
        omaxDeposits.push(
            OmaxDeposit(
                newItemId,
                msg.sender,
                amountToLockInWei,
                false,
                block.timestamp,
                timeLockSeconds
            )
        );
        
        currentOmaxDeposited += amountToLockInWei;

        _token.transferFrom(msg.sender, address(this), amountToLockInWei);
        

        emit OmaxTokenDeposit(newItemId, msg.sender, amountToLockInWei, false, block.timestamp, timeLockSeconds);
    }
    
    function withdrawDeposit(uint256 depositId) external {
        
        
        require(depositId <= omaxDeposits.length);
        
        require(omaxDeposits[depositId].isWithdrawn == false, "This deposit has already been withdrawn.");
        
        require(omaxDeposits[depositId].depositOwner == msg.sender, "You can only withdraw your own deposits.");
        
        require((block.timestamp - omaxDeposits[depositId].depositTime) >= omaxDeposits[depositId].timeLockInSeconds, 
        "You can't yet unlock this deposit.  please use forceWithdrawDeposit instead"
        );
        
        require(percentageRewardForTimelock[omaxDeposits[depositId].timeLockInSeconds] > 0, "Smart contract owner hasn't defined reward for your deposit. Please contact OMAX team.");
        
        _token.transfer(
                 msg.sender, 
                 omaxDeposits[depositId].depositValue
        );

        _token.transferFrom(
                 marketingWallet,
                 msg.sender, 
                (omaxDeposits[depositId].depositValue.mul(percentageRewardForTimelock[omaxDeposits[depositId].timeLockInSeconds]).div(100))
        );
        
        currentOmaxDeposited -= omaxDeposits[depositId].depositValue;

        omaxDeposits[depositId].isWithdrawn = true;
        
        totalOmaxWithdrawn += omaxDeposits[depositId].depositValue + (omaxDeposits[depositId].depositValue.mul(percentageRewardForTimelock[omaxDeposits[depositId].timeLockInSeconds]).div(100));
        
        emit OmaxTokenWithdraw(depositId, msg.sender, omaxDeposits[depositId].depositValue, block.timestamp, false);
        
    }
    
    function forceWithdrawDeposit(uint256 depositId) external {
        
        require(depositId <= omaxDeposits.length);

        require(omaxDeposits[depositId].depositOwner == msg.sender, "Only the sender can withdraw this deposit");
        
        require(omaxDeposits[depositId].isWithdrawn == false, "This deposit has already been withdrawn.");
        
        _token.transfer(
                 msg.sender, 
                 omaxDeposits[depositId].depositValue - (omaxDeposits[depositId].depositValue.mul(lockFeePenalisation).div(100))
        );
        
        earlyWithdrawalFeeBalance += (omaxDeposits[depositId].depositValue.mul(lockFeePenalisation).div(100));
        
        currentOmaxDeposited -= omaxDeposits[depositId].depositValue;

        emit IncrementedEarlyWithdrawalFeeBalance((omaxDeposits[depositId].depositValue.mul(lockFeePenalisation).div(100)));
        
        omaxDeposits[depositId].isWithdrawn = true;
        
        totalOmaxWithdrawn += omaxDeposits[depositId].depositValue - (omaxDeposits[depositId].depositValue.mul(lockFeePenalisation).div(100));
        
         emit OmaxTokenWithdraw(depositId, msg.sender, omaxDeposits[depositId].depositValue, block.timestamp, true);
        
    }
}