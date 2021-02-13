/**
 *Submitted for verification at Etherscan.io on 2021-02-13
*/

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

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity >=0.6.0 <0.8.0;

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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

// File: @openzeppelin/contracts/math/SafeMath.sol



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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



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

// File: contracts/EternityVesting.sol


pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;




struct FrozenWallet {
    address wallet;
    uint totalAmount;
    uint monthlyAmount;
    uint initialAmount;
    uint startDay;
    bool immediately;
    bool scheduled;
    uint256 redeemed;
    uint distributionType;
}

struct VestingType {
    uint monthlyRate;
    uint initialRate;
    uint afterDays;
    bool immediately;
    uint distributionType;
    bool vesting;
}

contract EternityVesting is Ownable {
    using SafeMath for uint256;

    mapping (address => FrozenWallet) public frozenWallets;
    VestingType[] public vestingTypes;
    uint256 maxTotalSupply;
    uint256 releaseTime;
    IERC20 private _token;

    constructor() public {
        // Release Date 15.12.2020
        releaseTime = 1613131200;

        vestingTypes.push(VestingType(2500000000000000000, 20000000000000000000, 0, true, 1, true)); // 20% unlock immediately on TGE, rest unlocked over 8 months
        vestingTypes.push(VestingType(10000000000000000000, 20000000000000000000, 0, true, 0, true)); // 20% unlock immediately on TGE, rest unlocked over 8 months
        vestingTypes.push(VestingType(9375000000000000000, 25000000000000000000, 0, true, 0, true)); // 25% unlock immediately on TGE, rest unlocked over 8 months
        vestingTypes.push(VestingType(4160000000000000000, 0, 30 minutes, false, 0, true)); // First unlock at month 10, rest unlock over 24 months
    }

    /**
     * Crowdsale Token
     */
    function setTokenAddress(IERC20 token) external onlyOwner returns (bool) {
        _token = token;
        return true;
    }

    /**
     * Get Total Token
     *
     * @return {uint256} totalToken
     */
    function getTotalToken() public view returns (uint256) {
        return _token.balanceOf(address(this));
    }

    /**
     * Get Release Time
     *
     * @return {uint256} releaseTime
     */
    function getReleaseTime() public view returns (uint256) {
        return releaseTime;
    }

    function addAllocations(address[] memory addresses, uint[] memory totalAmounts, uint vestingTypeIndex) external onlyOwner returns (bool) {
        require(addresses.length == totalAmounts.length, "Address and totalAmounts length must be same");
        require(vestingTypes[vestingTypeIndex].vesting, "Vesting type isn't found");

        VestingType memory vestingType = vestingTypes[vestingTypeIndex];
        uint addressesLength = addresses.length;

        for(uint i = 0; i < addressesLength; i++) {
            address address_ = addresses[i];
            uint256 totalAmount = totalAmounts[i];
            uint256 monthlyAmount = totalAmount.mul(vestingType.monthlyRate).div(100000000000000000000);
            uint256 initialAmount = totalAmount.mul(vestingType.initialRate).div(100000000000000000000);
            uint256 afterDay = vestingType.afterDays;
            bool immediately = vestingType.immediately;
            uint distributionType = vestingType.distributionType;

            addFrozenWallet(address_, totalAmount, monthlyAmount, initialAmount, afterDay, immediately, distributionType);
        }

        return true;
    }
    
    function addFrozenWallet(address wallet, uint totalAmount, uint monthlyAmount, uint initialAmount, uint afterDays, bool immediately, uint distributionType) internal {
        frozenWallets[wallet] = FrozenWallet(
            wallet, 
            totalAmount, 
            monthlyAmount, 
            initialAmount, 
            releaseTime.add(afterDays), 
            immediately, 
            true, 
            0,
            distributionType
        );
    }

    function getTransferable(address sender) public view returns (uint256) {
        FrozenWallet memory frozenWallet = frozenWallets[sender];
        uint distrubitionCount = frozenWallet.distributionType == 1 ? getWeeks(frozenWallet.immediately) : getMonths(frozenWallet.immediately);
        uint256 monthlyTransferableAmount = frozenWallet.monthlyAmount.mul(distrubitionCount);
        uint256 totalTransferable = monthlyTransferableAmount.add(frozenWallet.initialAmount);
        uint transferable = totalTransferable > frozenWallet.totalAmount ? frozenWallet.totalAmount : totalTransferable;

        return transferable.sub(frozenWallet.redeemed);
    }

    // Transfer control 
    function canTransfer(address sender) public view returns (bool) {
        // Control is scheduled wallet
        if (!frozenWallets[sender].scheduled) {
            return true;
        }

        uint256 transferable = getTransferable(sender);

        if (!isStarted(frozenWallets[sender].startDay) || transferable <= 0) {
            return false;
        }

        return true;
    }

    /**
     * Calculate months from starting day
     */
    function getMonths(bool immediately) public view returns (uint) {
        uint delay = immediately ? 0 : 1;

        if (block.timestamp < releaseTime) {
            return 0;
        }

        uint diff = block.timestamp.sub(releaseTime);
        uint months = diff.div(30 minutes).add(delay);
        
        return months;
    }

    /**
     * Calculate months from starting day
     */
    function getWeeks(bool immediately) public view returns (uint) {
        uint delay = immediately ? 0 : 1;

        if (block.timestamp < releaseTime) {
            return 0;
        }

        uint diff = block.timestamp.sub(releaseTime);
        uint weeks_ = diff.div(7 minutes).add(delay);
        
        return weeks_;
    }

    /**
     * Start control
     */
    function isStarted(uint startDay) public view returns (bool) {
        if (block.timestamp < releaseTime || block.timestamp < startDay) {
            return false;
        }

        return true;
    }

    /**
     * Redeem Vetings Tokens
     */
    function redeemTokens() external returns (bool) {
        address sender = _msgSender();
        require(canTransfer(sender), "Wait for the vesting day!");

        uint256 transferable = getTransferable(sender);
        uint256 totalToken = getTotalToken();
        require(totalToken > transferable, "Insufficient token");

        FrozenWallet memory frozenWallet = frozenWallets[sender];

        require(_token.transfer(sender, transferable), "Transfer problem");

        frozenWallets[sender].redeemed = frozenWallet.redeemed.add(transferable);

        return true;
    }
}