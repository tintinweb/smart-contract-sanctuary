/**
 *Submitted for verification at BscScan.com on 2021-08-14
*/

// SPDX-License-Identifier: GPLv3

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

interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

interface ERC20 is IERC20Metadata {
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


contract AIFarmer is Ownable, ReentrancyGuard {
    using SafeMath for uint;
    
    uint[2] public refRewardRates = [70, 30];
    ERC20 public stakedToken;
    ERC20 public usdtToken;
    
    uint rewardPerBlock = 625000000000;         // 0.018 ether / 28800
    uint freeBlockNimber = 864000;              // 28800 * 30
    uint collectionRate = 600;
    address payee;
    
    uint lastRewardBlock;
    uint accruedTokenPerShare;
    uint totalAmount;
    uint totalUsers;
    
    uint inTotal;
    uint outTotal;
    uint settledTotal;
    
    struct Agent {
        uint inTotal;
        uint rewardTotal;
        uint withdrawTotal;
    }
    struct User {
        bool activated;
        address ref;
        uint amount;
        uint shares;
        uint rewardDebt;
        uint avgDepositBlock;
        uint recommendNum1;
        uint recommendAmount1;
        uint recommendNum2;
        uint recommendAmount2;
        address top;
        Agent agent;
    }
    mapping(address => User) public users;
    
    event Deposit(address indexed user, uint amount);
    event Withdraw(address indexed user, uint amount);
    event AdminTokenRecovery(address tokenRecovered, uint amount);
    event NewRewardPerBlock(uint rewardPerBlock);
    event NewFreeBlockNimber(uint freeBlockNimber);
    event NewPayee(address newPayee);
    event NewCollectionRate(uint newCollectionRate);
    
    constructor(ERC20 _usdtToken, ERC20 _stakedToken, address _payee) {
        usdtToken = _usdtToken;
        stakedToken = _stakedToken;
        payee = _payee;
        lastRewardBlock = block.number;
        users[msg.sender].activated = true;
        totalUsers = 1;
    }
    
    receive() external payable { }

    function deposit(uint _amount, address _ref, bool isUsdt) external nonReentrant {
        User storage user = users[msg.sender];
        require(user.activated || users[_ref].activated, "Referrer is not activated");
        
        updatePool();
        settleAndEvenReward(user, msg.sender, _amount, amountSharesRate(), true, false);
        if (_amount == 0) return;
        
        if (user.amount == 0) {
            user.avgDepositBlock = block.number;
        } else {
            user.avgDepositBlock = user.avgDepositBlock.add(block.number.sub(user.avgDepositBlock).mul(user.amount).div(user.amount.add(_amount)));
        }
        
        if (! user.activated) {
            user.activated = true;
            user.ref = _ref;
            totalUsers = totalUsers.add(1);
            
            address userRef1 = _ref;
            for (uint i = 0; i < refRewardRates.length; i++) {
                if (userRef1 == address(0)) break;
                User storage refUser = users[userRef1];
                if (i == 0) {
                    refUser.recommendNum1 = refUser.recommendNum1.add(1);
                } else {
                    refUser.recommendNum2 = refUser.recommendNum2.add(1);
                }
                userRef1 = refUser.ref;
            }
            
            if (users[_ref].ref == address(0)) {
                user.top = msg.sender;
            } else {
                user.top = users[_ref].top;
            }
        }
        
        if (users[user.ref].ref != address(0)) {
            users[user.top].agent.inTotal = users[user.top].agent.inTotal.add(_amount);
        }
        user.amount = user.amount.add(_amount);
        totalAmount = totalAmount.add(_amount);
        inTotal = inTotal.add(_amount);
        ERC20 token = isUsdt ? usdtToken : stakedToken;
        token.transferFrom(msg.sender, address(this), _amount);
        token.transfer(payee, _amount.mul(collectionRate).div(1000));
        
        address userRef = user.ref;
        for (uint i = 0; i < refRewardRates.length; i++) {
            if (userRef == address(0)) break;
            User storage refUser = users[userRef];
            settleAndEvenReward(refUser, userRef, _amount, refRewardRates[i], true, false);
            
            if (i == 0) {
                refUser.recommendAmount1 = refUser.recommendAmount1.add(_amount);
            } else {
                refUser.recommendAmount2 = refUser.recommendAmount2.add(_amount);
            }
            userRef = refUser.ref;
        }
        emit Deposit(msg.sender, _amount);
    }
    
    function withdraw() external nonReentrant {
        User storage user = users[msg.sender];
        require(user.activated, "User not activated");
        require(user.amount > 0, "'Deposit amount must be greater than 0");
        uint _amount = user.amount;
        
        updatePool();
        settleAndEvenReward(user, msg.sender, _amount, amountSharesRate(), false, true);
        
        user.amount = 0;
        totalAmount = totalAmount.sub(_amount);
        if (msg.sender == owner()) {
            usdtToken.transfer(msg.sender, _amount);
            outTotal = outTotal.add(_amount);
        } else {
            if (block.number >= user.avgDepositBlock.add(freeBlockNimber)) {
                usdtToken.transfer(msg.sender, _amount);
                outTotal = outTotal.add(_amount);
                if (users[user.ref].ref != address(0)) {
                    users[user.top].agent.withdrawTotal = users[user.top].agent.withdrawTotal.add(_amount);
                }
            } else {
                uint num = _amount.mul(amountSharesRate()).div(1000);
                usdtToken.transfer(msg.sender, num);
                outTotal = outTotal.add(num);
                if (users[user.ref].ref != address(0)) {
                    users[user.top].agent.withdrawTotal = users[user.top].agent.withdrawTotal.add(num);
                }
            }
        }
        
        address userRef = user.ref;
        for (uint i = 0; i < refRewardRates.length; i++) {
            if (userRef == address(0)) break;
            User storage refUser = users[userRef];
            settleAndEvenReward(refUser, userRef, _amount, refRewardRates[i], false, false);
            
            if (i == 0) {
                refUser.recommendAmount1 = refUser.recommendAmount1.sub(_amount);
            } else {
                refUser.recommendAmount2 = refUser.recommendAmount2.sub(_amount);
            }
            userRef = refUser.ref;
        }
        emit Withdraw(msg.sender, _amount);
    }
    
    function query_account(address _addr) external view returns(uint, uint, uint, uint, uint) {
        return (_addr.balance,
                stakedToken.allowance(_addr, address(this)),
                stakedToken.balanceOf(_addr),
                usdtToken.allowance(_addr, address(this)),
                usdtToken.balanceOf(_addr));
    }

    function query_stake(address _addr) external view returns(bool, address, uint, uint, uint, uint, uint, uint, uint, uint, address, uint) {
        User storage user = users[_addr];
        return (user.activated,
                user.ref,
                user.amount,
                user.shares,
                user.rewardDebt,
                user.avgDepositBlock,
                user.recommendNum1,
                user.recommendAmount1,
                user.recommendNum2,
                user.recommendAmount2,
                user.top,
                pendingReward(user));
    }
    
    function query_agent(address _addr) external view returns(uint, uint, uint) {
        User storage user = users[_addr];
        require (users[user.ref].ref == address(0), "caller is not an agent");
        return (user.agent.inTotal,
                user.agent.withdrawTotal,
                user.agent.rewardTotal);
    }

    function query_summary() external view returns(uint, uint, uint, uint, uint, uint, uint) {
        return (totalUsers, 
                totalAmount,
                lastRewardBlock,
                accruedTokenPerShare,
                rewardPerBlock,
                freeBlockNimber,
                block.number);
    }
    
    function query_settle() external view returns(uint, uint, uint, uint) {
        return (inTotal,
                outTotal,
                settledTotal,
                inTotal.sub(outTotal).sub(settledTotal));
    }
    
    function query_owner() external onlyOwner view returns(uint, address) {
        return (collectionRate,
                payee);
    }
    
    function collect_token(address _addr, uint _amount) external onlyOwner {
        require(_addr != address(0), "address is null");
        stakedToken.transfer(_addr, _amount);
    }
    
    function collect_usdt(address _addr, uint _amount) external onlyOwner {
        require(_addr != address(0), "address is null");
        usdtToken.transfer(_addr, _amount);
    }
    
    function recoverWrongTokens(address _tokenAddress, uint _tokenAmount) external onlyOwner {
        require(_tokenAddress != address(stakedToken), "Cannot be staked token");
        require(_tokenAddress != address(usdtToken), "Cannot be usdt token");
        ERC20(_tokenAddress).transfer(msg.sender, _tokenAmount);
        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }
    
    function updateRewardPerBlock(uint _rewardPerBlock) external onlyOwner {
        rewardPerBlock = _rewardPerBlock;
        emit NewRewardPerBlock(_rewardPerBlock);
    }
    
    function updateFreeBlockNimber(uint _freeBlockNimber) external onlyOwner {
        freeBlockNimber = _freeBlockNimber;
        emit NewFreeBlockNimber(_freeBlockNimber);
    }
    
    function updateCollectionRate(uint _collectionRate) external onlyOwner {
        collectionRate = _collectionRate;
        emit NewCollectionRate(_collectionRate);
    }
    
    function updatePayee(address _payee) external onlyOwner {
        payee = _payee;
        emit NewPayee(_payee);
    }
    
    function settle(uint amount) external onlyOwner {
        require(inTotal.sub(outTotal).sub(settledTotal) >= amount, "Insufficient balance");
        settledTotal = settledTotal.add(amount);
    }
    
    function settleAndEvenReward(User storage user, address userAddr, uint changeAmount, uint changeSharesRate, bool isAdd, bool isWithdrawUser) private {
        if (user.amount > 0) {
            uint pending = user.shares.mul(accruedTokenPerShare).div(1 ether).sub(user.rewardDebt);
            if (pending > 0) {
                usdtToken.transfer(userAddr, pending);
                outTotal = outTotal.add(pending);
                if (users[user.ref].ref != address(0)) {
                    users[user.top].agent.rewardTotal = users[user.top].agent.rewardTotal.add(pending);
                }
            }
        }
        
        if (changeAmount > 0) {
            uint changeShares = changeAmount.mul(changeSharesRate).div(1000);
            if (isAdd) {
                user.shares = user.shares.add(changeShares);
            } else {
                if (isWithdrawUser && msg.sender != owner()) {
                    changeShares = user.shares;
                    user.shares = 0;
                } else {
                    user.shares = user.shares.sub(changeShares);
                }
            }
        }
        
        user.rewardDebt = user.shares.mul(accruedTokenPerShare).div(1 ether);
    }
    
    function pendingReward(User storage user) private view returns (uint) {
        if (totalAmount <= 0) return 0;
        if (block.number <= lastRewardBlock) {
            return user.shares.mul(accruedTokenPerShare).sub(user.rewardDebt);
        }
        uint multiplier = block.number.sub(lastRewardBlock);
        uint adjustedTokenPerShare = accruedTokenPerShare.add(multiplier.mul(rewardPerBlock));
        return user.shares.mul(adjustedTokenPerShare).div(1 ether).sub(user.rewardDebt);
    }
    
    function refRewardRateTotal() private view returns (uint) {
        uint total;
        for (uint i; i < refRewardRates.length; i++) {
            total = total.add(refRewardRates[i]);
        }
        return total;
    }
    
    function amountSharesRate() private view returns (uint) {
        return uint(1000).sub(refRewardRateTotal());
    }
    
    function updatePool() private {
        if (block.number <= lastRewardBlock) return;
        if (totalAmount > 0) {
            uint multiplier = block.number.sub(lastRewardBlock);
            accruedTokenPerShare = accruedTokenPerShare.add(multiplier.mul(rewardPerBlock));
        }
        lastRewardBlock = block.number;
    }
    
    function lastRewardBlockRepair(uint lastRewardBlock_) external onlyOwner {
        lastRewardBlock = lastRewardBlock_;
    }
    
    function depositRepair(address _addr, uint _amount, address _ref) external onlyOwner {
        User storage user = users[_addr];
        require(user.activated || users[_ref].activated, "Referrer is not activated");
        if (_amount == 0) return;
        
        if (user.amount == 0) {
            user.avgDepositBlock = block.number;
        } else {
            user.avgDepositBlock = user.avgDepositBlock.add(block.number.sub(user.avgDepositBlock).mul(user.amount).div(user.amount.add(_amount)));
        }
        
        if (! user.activated) {
            user.activated = true;
            user.ref = _ref;
            totalUsers = totalUsers.add(1);
            
            address userRef1 = _ref;
            for (uint i = 0; i < refRewardRates.length; i++) {
                if (userRef1 == address(0)) break;
                User storage refUser = users[userRef1];
                if (i == 0) {
                    refUser.recommendNum1 = refUser.recommendNum1.add(1);
                } else {
                    refUser.recommendNum2 = refUser.recommendNum2.add(1);
                }
                userRef1 = refUser.ref;
            }
            
            if (users[_ref].ref == address(0)) {
                user.top = _addr;
            } else {
                user.top = users[_ref].top;
            }
        }
        
        if (users[user.ref].ref != address(0)) {
            users[user.top].agent.inTotal = users[user.top].agent.inTotal.add(_amount);
        }
        user.amount = user.amount.add(_amount);
        totalAmount = totalAmount.add(_amount);
        inTotal = inTotal.add(_amount);
        shareRepair(user, _amount, amountSharesRate());
        
        address userRef = user.ref;
        for (uint i = 0; i < refRewardRates.length; i++) {
            if (userRef == address(0)) break;
            User storage refUser = users[userRef];
            shareRepair(refUser, _amount, refRewardRates[i]);
            
            if (i == 0) {
                refUser.recommendAmount1 = refUser.recommendAmount1.add(_amount);
            } else {
                refUser.recommendAmount2 = refUser.recommendAmount2.add(_amount);
            }
            userRef = refUser.ref;
        }
    }
    
    function shareRepair(User storage user, uint changeAmount, uint changeSharesRate) private {
        if (changeAmount > 0) {
            uint changeShares = changeAmount.mul(changeSharesRate).div(1000);
            user.shares = user.shares.add(changeShares);
        }
    }
}