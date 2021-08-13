/**
 *Submitted for verification at BscScan.com on 2021-08-13
*/

// Sources flattened with hardhat v2.4.3 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File @openzeppelin/contracts/utils/math/[email protected]



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


// File @openzeppelin/contracts/utils/[email protected]



pragma solidity ^0.8.0;

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
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/[email protected]



pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/security/[email protected]



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


// File contracts/pool/BNBPool.sol


pragma solidity >=0.8.6;
contract BNBPool is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    uint256 boomIndexET = 1e3;
    uint256 boomIndexBNB = 1e2;
    uint256 public burnedET;
    address public burnAddress = 0x0000000000000000000000000000000000000002;
    uint256 public rewardsDuration;

    IERC20 et;
    IERC20 bnb;

    uint256 public poolSharesBNB;
    uint256 public poolBoomBurnedBNB;
    uint256 public poolBoomBurnedET;

    uint256 public historyAirdropBNB;
    uint256 public totalAirdropBNB;
    uint256 public totalHarvestBNB;
    uint256 public totalStoreBNB;

    uint256 public airdropStartTime; // 本轮奖励开始增发时间，每天15点
    uint256 public airdropStopTime; // 本轮奖励生产量截止日期

    mapping(address => uint256) public userSharesBNB; // user => amount
    mapping(address => uint256) public userBoomBurnedBNB; // user => amount
    mapping(address => uint256) public userBoomBurnedET; // user => amount
    mapping(address => uint256) public userHarvestedBNB; // user => amount
    mapping(address => uint256) public userStoredBNB; // user => amount

    // User
    uint256 public userLength;
    mapping(address => bool) public isUser; // address => bool
    mapping(uint256 => address) public userAddress; // id => address

    event NewUser(address user, uint256 userId);
    event Burn(address indexed user, uint256 amount, string indexed pName);
    event Withdraw(address indexed user, uint256 amount, string indexed pName);
    event Harvest(address indexed user, uint256 amount, string indexed pName);

    constructor(
        address ETContract,
        address BNBContract,
        uint256 _airdropStartTime
    ) {
        et = IERC20(ETContract);
        bnb = IERC20(BNBContract);
        airdropStartTime = _airdropStartTime;
    }

    function poolSharePriceBNB() public view returns (uint256) {
        if (
            poolSharesBNB > 0 &&
            airdropStopTime > 0 &&
            block.timestamp > airdropStartTime
        ) {
            if (block.timestamp > airdropStopTime) {
                // 超过时间，本轮之外，价格停滞
                uint256 totalMixedAmt = poolBoomBurnedBNB
                    .add(totalAirdropBNB)
                    .sub(totalHarvestBNB);
                return totalMixedAmt.div(poolSharesBNB);
            } else {
                // 本轮从开始到现在总计产量 + 历史产量
                uint256 rewardsSpeed = totalAirdropBNB
                    .sub(historyAirdropBNB)
                    .div(rewardsDuration);
                uint256 deltaRewards = block
                    .timestamp
                    .sub(airdropStartTime)
                    .mul(rewardsSpeed);
                uint256 totalRewards = deltaRewards.add(historyAirdropBNB);
                // 质押 + 总产量
                uint256 totalMixedAmt = poolBoomBurnedBNB.add(totalRewards).sub(
                    totalHarvestBNB
                );
                // 份额价格
                return totalMixedAmt.div(poolSharesBNB);
            }
        } else {
            return 1e8; // 池子中没有份额，那么份额价格是初始值1
        }
    }

    // Add User
    function addUser(address newUser) private {
        if (!isUser[newUser]) {
            userLength = userLength.add(1);
            userAddress[userLength] = newUser;
            isUser[newUser] = true;
            emit NewUser(newUser, userLength);
        }
    }

    function userBurnedET(address user) public view returns (uint256) {
        return userBoomBurnedET[user].div(boomIndexET);
    }

    function poolBurnedET() public view returns (uint256) {
        return poolBoomBurnedET.div(boomIndexET);
    }

    function userProductedBNB(address user) public view returns (uint256) {
        return
            userHarvestedBNB[user].add(userRewardBNB(user)).sub(
                userStoredBNB[user]
            );
    }

    function userRewardBNB(address user) public view returns (uint256) {
        return
            userTotalMixedAmtBNB(user).add(userStoredBNB[user]).sub(
                userBoomBurnedBNB[user]
            );
    }

    function userTotalMixedAmtBNB(address user) public view returns (uint256) {
        return userSharesBNB[user].mul(poolSharePriceBNB());
    }

    function updateAirdrop(uint256 duration) public onlyOwner {
        rewardsDuration = duration;
        if (poolSharesBNB > 0 && airdropStopTime > 0) {
            uint256 newTotalAirdropBNB = bnb
                .balanceOf(address(this))
                .add(totalHarvestBNB)
                .sub(totalStoreBNB);
            if (block.timestamp > airdropStopTime) {
                historyAirdropBNB = totalAirdropBNB;
                totalAirdropBNB = newTotalAirdropBNB;
                airdropStartTime = airdropStopTime;
                airdropStopTime = airdropStartTime.add(rewardsDuration);
            }
        } else {
            airdropStopTime = airdropStartTime.add(rewardsDuration);
            totalAirdropBNB = bnb.balanceOf(address(this));
        }
    }

    // random Send BNB
    function randomSendBNB(uint256 amount, uint256 randNonce) public onlyOwner {
        require(
            bnb.balanceOf(address(this)) >= amount,
            "BNBPool: contract balance is insufficient"
        );
        address[] memory userList;
        uint256 j = 0;
        for (uint256 i = 0; i < userLength; i++) {
            address user = userAddress[i + 1];
            if (userBurnedET(user) >= 10000e18) {
                userList[j++] = user;
            }
        }
        if (userList.length > 0) {
            uint256 random = uint256(
                keccak256(
                    abi.encodePacked(block.timestamp, msg.sender, randNonce)
                )
            ) % userList.length;
            // Transfer to User
            bnb.transfer(userList[random], amount);
        }
    }

    // Deposit
    function deposit(uint256 amount) public nonReentrant {
        require(airdropStopTime > 0, "BNBPool: pool is not opened");
        require(
            et.balanceOf(_msgSender()) >= amount,
            "BNBPool: user balance is insufficient"
        );
        // Transfer
        et.transferFrom(_msgSender(), burnAddress, amount);
        burnedET = burnedET.add(amount);
        // Boom
        uint256 boomAmtET = amount.mul(boomIndexET);
        uint256 boomAmtBNB = amount.mul(boomIndexBNB);
        // User
        addUser(_msgSender());
        // Update User Data
        uint256 shareBNB = boomAmtBNB.div(poolSharePriceBNB());
        userBoomBurnedBNB[_msgSender()] = userBoomBurnedBNB[_msgSender()].add(
            boomAmtBNB
        );
        userBoomBurnedET[_msgSender()] = userBoomBurnedET[_msgSender()].add(
            boomAmtET
        );
        userSharesBNB[_msgSender()] = userSharesBNB[_msgSender()].add(shareBNB);
        // Update Pool
        poolBoomBurnedBNB = poolBoomBurnedBNB.add(boomAmtBNB);
        poolBoomBurnedET = poolBoomBurnedET.add(boomAmtET);
        poolSharesBNB = poolSharesBNB.add(shareBNB);
        // Log
        emit Burn(_msgSender(), amount, "ET");
    }

    // Harvest BNB
    function harvestBNB() public nonReentrant {
        uint256 harvestAmt = userRewardBNB(_msgSender());
        require(
            bnb.balanceOf(address(this)) >= harvestAmt,
            "BNBPool: contract balance is insufficient"
        );
        // // Transfer to User
        bnb.transfer(_msgSender(), harvestAmt);
        // Update User Data
        uint256 lastStoredBNB = userStoredBNB[_msgSender()];
        if (userBoomBurnedBNB[_msgSender()] > 0) {
            // 若userBoomBurnedBNB为0，则已经更新过数据
            uint256 realAmt = harvestAmt.sub(lastStoredBNB);
            uint256 share = realAmt.div(poolSharePriceBNB());
            userSharesBNB[_msgSender()] = userSharesBNB[_msgSender()].sub(
                share
            );
            userHarvestedBNB[_msgSender()] = userHarvestedBNB[_msgSender()].add(
                realAmt
            );
            // Update Pool Data
            poolSharesBNB = poolSharesBNB.sub(share);
            totalHarvestBNB = totalHarvestBNB.add(realAmt);
        }
        totalStoreBNB = totalStoreBNB.sub(lastStoredBNB);
        userStoredBNB[_msgSender()] = 0;

        // Log
        emit Harvest(_msgSender(), harvestAmt, "BNB");
    }
}