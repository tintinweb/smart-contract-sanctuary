// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
    @author humanshield85
    rachidboudjelida[at]gmail.com
*/

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IWrappedNativeToken.sol";
import "./interfaces/IHODLRewardDistributor.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract HODLRewardsDistributor is Ownable {
    using SafeMath for uint256;

    address immutable public wrappedNativeToken;

    uint256 public accPerShare;   // Accumulated per share, times 1e36.
    uint256 public totalShares;   // total number of shares
    uint256 public totalClaimed;  // total amount claimed
    uint256 public totalRewardsDebt;  // total amount claimed

    // use getShare-holderInfo function to get this data
    mapping (address => ShareHolder) shareHolders;
    address[] public allShareHolders;
    mapping (address => uint256) indexOfShareHolders;

    uint256 private _lastProccessedIndex = 1;

    mapping (address => bool) public excludedFromRewards;

    modifier onlyIncluded (address shareHolderAddress_) {
        require(!excludedFromRewards[shareHolderAddress_],"HODLRewardsDistributor: excluded from rewards");
        _;
    }

    receive() external payable { 
        _updateGlobalShares(msg.value);
    }
    constructor (address wrappedNativeToken_){
        wrappedNativeToken = wrappedNativeToken_;
        allShareHolders.push(address(0)); // use the index zero for address zero
    }

    /**
        retruns the pending rewards amount
        */
    function pending(
        address sharholderAddress_
    ) public view returns (uint256 pendingAmount) {
        ShareHolder storage user = shareHolders[sharholderAddress_];
        pendingAmount = user.shares.mul(accPerShare).div(1e36).sub(user.rewardDebt);
    }

    function totalPending () public view returns (uint256 ) {
        return accPerShare.mul(totalShares).div(1e36).sub(totalRewardsDebt);
    }

    /**
        returns information about the share holder
        */
    function shareHolderInfo (
        address shareHoldr_
    ) external view returns(ShareHolder memory){
        ShareHolder storage user = shareHolders[shareHoldr_];
        return ShareHolder (
            user.shares,     // How many tokens the user is holding.
            user.rewardDebt, // see @masterChef contract for more details
            user.claimed,
            pending(shareHoldr_)
        );
    }


    /**
        CAN BE CALLED BY ANYONE 
        could help add more rewards from other incomes to thus contract
        cannot be used maliciously who ever call this is basically giving wrapped native token as reward
        to all shareholders
        */
    function depositWrappedNativeTokenRewards(
        uint256 amount_
    ) external {
        IWrappedNativeToken(wrappedNativeToken).transferFrom(msg.sender, address(this), amount_);
        IWrappedNativeToken(wrappedNativeToken).withdraw(IWrappedNativeToken(wrappedNativeToken).balanceOf(address(this)));
    }

    function setShare(
        address sharholderAddress_,
        uint256 amount_
    ) onlyOwner onlyIncluded(sharholderAddress_) external {
        ShareHolder storage user = shareHolders[sharholderAddress_];

        // pay any pending rewards
        if(user.shares > 0)
            claimPending(sharholderAddress_);

        // update total shares
        _updateUserShares(sharholderAddress_, amount_);
    }

    /*
        excludes shareHolderToBeExcluded_ from participating in rewards
    */
    function excludeFromRewards (
        address shareHolderToBeExcluded_ 
    ) external onlyOwner {
        if(excludedFromRewards[shareHolderToBeExcluded_])
            return;

        uint256 amountPending = pending(shareHolderToBeExcluded_);
        // update this user's shares to 0
        _updateUserShares(shareHolderToBeExcluded_, 0);
        // distribute his pending share to all shareholders
        if(amountPending > 0)
            _updateGlobalShares(amountPending);
        excludedFromRewards[shareHolderToBeExcluded_] = true;
    }

    /*
        allow shareHolderToBeExcluded_ to participating in rewards
    */
    function includeInRewards(
        address shareHolderToBeIncluded_
    ) external onlyOwner {
        require(excludedFromRewards[shareHolderToBeIncluded_],"HODLRewardsDistributor: not excluded");
        
        _updateUserShares(shareHolderToBeIncluded_, IERC20(owner()).balanceOf(shareHolderToBeIncluded_));
        excludedFromRewards[shareHolderToBeIncluded_] = false;
    }

    /** 
        @dev
        claim pending rewards for sharholderAddress_
        can be called by anyone but only sharholderAddress_
        can receive the reward
    */
    function claimPending(
        address sharholderAddress_
    ) public {
        ShareHolder storage user = shareHolders[sharholderAddress_];

        uint256 pendingAmount = user.shares.mul(accPerShare).div(1e36).sub(user.rewardDebt);

        if(pendingAmount <= 0) return;
        
        (bool sent, bytes memory data) = payable(sharholderAddress_).call{value: pendingAmount}("");
        //if !sent means probably the receiver is a non payable address 
        if(!sent)
            return;
        
        user.claimed = user.claimed.add(pendingAmount);
        totalClaimed = totalClaimed.add(pendingAmount);
        
        totalRewardsDebt = totalRewardsDebt.sub(user.rewardDebt);
        user.rewardDebt = user.shares.mul(accPerShare).div(1e36);
        totalRewardsDebt = totalRewardsDebt.add(user.rewardDebt);
    }

    function batchProcessClaims(uint256 gas) public {
        if(gasleft() < gas) return;
        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();
        uint256 iterations = 1; // index 0 is ocupied by address(0) 

        // we
        while(gasUsed < gas && iterations < allShareHolders.length) {
            claimPending(allShareHolders[_lastProccessedIndex]);
            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            _incrementLastProccessed();
            iterations++;
        }
    }

    /**
        prevents accidental renouncement of owner ship 
        can sill renounce if set explicitly to dead address 
     */
    function renounceOwnership() public virtual override onlyOwner {}

    /**
        updates the accumulatedPerShare amount based on the new amount and total shares
        */
    function _updateGlobalShares(
        uint256 amount_
    ) internal {
        accPerShare = accPerShare.add(amount_.mul(1e36).div(totalShares));
    }

    /**
        updates a user share
        */
    function _updateUserShares(
        address sharholderAddress_,
        uint256 newAmount_
    ) internal {
        ShareHolder storage user = shareHolders[sharholderAddress_];

        totalShares = totalShares.sub(user.shares).add(newAmount_);
        totalRewardsDebt = totalRewardsDebt.sub(user.rewardDebt);
        user.shares = newAmount_;
        user.rewardDebt = user.shares.mul(accPerShare).div(1e36);
        totalRewardsDebt = totalRewardsDebt.add(user.rewardDebt);
        if(user.shares > 0 && indexOfShareHolders[sharholderAddress_] == 0 ){
            // add this shareHolder to array 
            allShareHolders.push(sharholderAddress_);
            indexOfShareHolders[sharholderAddress_] = allShareHolders.length-1;

        } else if(user.shares == 0 && indexOfShareHolders[sharholderAddress_] != 0){
            // remove this share holder from array
            uint256 indexOfRemoved = indexOfShareHolders[sharholderAddress_];
            allShareHolders[indexOfRemoved] = allShareHolders[allShareHolders.length-1]; // last item to the removed item's index
            indexOfShareHolders[sharholderAddress_] = 0;
            indexOfShareHolders[allShareHolders[indexOfRemoved]] = indexOfRemoved;
            allShareHolders.pop(); // remove the last item
        }
    }

    function _incrementLastProccessed() internal {
        _lastProccessedIndex++;
        if(_lastProccessedIndex >= allShareHolders.length)
            _lastProccessedIndex = 1;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
    @author humanshield85
    rachidboudjelida[at]gmail.com
*/

interface IWrappedNativeToken {
    function deposit() external payable;
    function withdraw(uint wad) external;
    function totalSupply() external view returns (uint);
    function approve(address guy, uint wad) external returns (bool);
    function transfer(address dst, uint wad) external returns (bool);
    function transferFrom(address src, address dst, uint wad) external returns (bool);
    function balanceOf(address wallet) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
    @author humanshield85
    rachidboudjelida[at]gmail.com
*/

import '../data/ShareHolder.sol';

interface IHODLRewardDistributor {

    function excludedFromRewards(
        address wallet_
    ) external view returns (bool);

    function pending(
        address sharholderAddress_
    ) external view returns (uint256 pendingAmount);

    function totalPending () external view returns (uint256 );

    function shareHolderInfo (
        address shareHoldr_
    ) external view returns(ShareHolder memory);

    function depositWrappedNativeTokenRewards(
        uint256 amount_
    ) external;

    function setShare(
        address sharholderAddress_,
        uint256 amount_
    ) external;

    function excludeFromRewards (
        address shareHolderToBeExcluded_ 
    ) external;

    function includeInRewards(
        address shareHolderToBeIncluded_
    ) external;

    function claimPending(
        address sharholderAddress_
    ) external;

    function owner() external returns(address);
    
    function batchProcessClaims(uint256 gas) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
    @author humanshield85
    rachidboudjelida[at]gmail.com
*/

struct ShareHolder {
    uint256 shares;
    uint256 rewardDebt;
    uint256 claimed;
    uint256 pending;
}