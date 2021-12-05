pragma solidity ^0.6.0;

interface IReinvestment {

    // Reserved share ratio. Will divide by 10000, 0 means not reserved.
    function reservedRatio() external view returns (uint256);

    // total mdx rewards of goblin.
    function userEarnedAmount(address user) external view returns (uint256);

    function deposit(uint256 amount) external;

    function withdraw(uint256 amount) external;
}

pragma solidity ^0.6.0;

interface IBoardRoomMDX {
    // User deposited amount and rewardDebt(don't use it).
    function userInfo(uint _pid, address _user) external view returns (uint256, uint256);

    // Check pending mdx rewards.
    function pending(uint256 _pid, address _user) external view returns (uint256);

    // Deposit mdx. Note MDX's pid in BSC is 4
    function deposit(uint256 _pid, uint256 _amount) external;

    // Withdraw both deposited mdx and reward mdx.
    // if amount is 0 means only withdraw rewards.
    function withdraw(uint256 _pid, uint256 _amount) external;
}

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./Interface/IReinvestment.sol";
import "./Interface/MDX/IBoardRoomMDX.sol";
import "./utils/SafeToken.sol";


contract Reinvestment is Ownable, IReinvestment {
    /// @notice Libraries
    using SafeToken for address;
    using SafeMath for uint256;

    /// @notice Events
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    address mdx;
    IBoardRoomMDX public boardRoom;
    uint256 public boardRoomPid;        // mdx pid in board room, should be 4 in BSC

    /// @notice Mutable state variables

    struct GlobalInfo {
        uint256 totalShares;        // Total staked lp amount.
        uint256 totalMdx;           // Total Mdx amount that already staked to board room.
        uint256 accMdxPerShare;     // Accumulate mdx rewards amount per lp token.
        uint256 lastUpdateTime;
    }

    struct UserInfo {
        uint256 totalShares;            // Total Lp amount.
        uint256 earnedMdxStored;        // Earned mdx amount stored at the last time user info was updated.
        uint256 accMdxPerShareStored;   // The accMdxPerShare at the last time user info was updated.
        uint256 lastUpdateTime;
    }

    mapping(address => UserInfo) public userInfo;
    GlobalInfo public globalInfo;
    uint256 public override reservedRatio;       // Reserved share ratio. will divide by 10000, 0 means not reserved.

    constructor(
        IBoardRoomMDX _boardRoom,
        uint256 _boardRoomPid,          // Should be 4 in BSC
        address _mdx,
        uint256 _reserveRatio           // will divide by 10000, 0 means not reserved.
    ) public {
        boardRoom = _boardRoom;
        boardRoomPid = _boardRoomPid;
        mdx = _mdx;
        reservedRatio = _reserveRatio;

        mdx.safeApprove(address(boardRoom), uint256(-1));
    }

    /* ==================================== Read ==================================== */

    function totalRewards() public view returns (uint256) {
        (uint256 deposited, /* rewardDebt */) = boardRoom.userInfo(boardRoomPid, address(this));
        return mdx.myBalance().add(deposited).add(boardRoom.pending(boardRoomPid, address(this)));
    }

    // TODO need to mul(1e18) and div(1e18) in other place used this function.
    function rewardsPerShare() public view  returns (uint256) {
        if (globalInfo.totalShares != 0) {
            // globalInfo.totalMdx is the mdx amount at the last time update.
            return (totalRewards().sub(globalInfo.totalMdx)).mul(1e18).div(
                globalInfo.totalShares).add(globalInfo.accMdxPerShare);
        } else {
            return globalInfo.accMdxPerShare;
        }
    }

    /// @notice Goblin is the user.
    function userEarnedAmount(address account) public view override returns (uint256) {
        UserInfo storage user = userInfo[account];
        return user.totalShares.mul(rewardsPerShare().sub(user.accMdxPerShareStored)).div(1e18).add(user.earnedMdxStored);
    }

    /* ==================================== Write ==================================== */

    // Deposit mdx.
    function deposit(uint256 amount) external override {
        if (amount > 0) {
            _updatePool(msg.sender);
            mdx.safeTransferFrom(msg.sender, address(this), amount);

            UserInfo storage user = userInfo[msg.sender];
            uint256 shares = _amountToShare(amount);

            // Update global info first
            globalInfo.totalMdx = globalInfo.totalMdx.add(amount);
            globalInfo.totalShares = globalInfo.totalShares.add(shares);

            // If there are some reserved shares
            if (reservedRatio != 0) {
                UserInfo storage owner = userInfo[owner()];
                uint256 ownerShares = shares.mul(reservedRatio).div(10000);
                uint256 ownerAmount = amount.mul(reservedRatio).div(10000);
                owner.totalShares = owner.totalShares.add(ownerShares);
                owner.earnedMdxStored = owner.earnedMdxStored.add(ownerAmount);

                // Calculate the left shares
                shares = shares.sub(ownerShares);
                amount = amount.sub(ownerAmount);
            }

            user.totalShares = user.totalShares.add(shares);
            user.earnedMdxStored = user.earnedMdxStored.add(amount);
        }
    }

    // Withdraw mdx to sender.
    function withdraw(uint256 amount) external override {
        if (amount > 0) {
            _updatePool(msg.sender);
            UserInfo storage user = userInfo[msg.sender];
            if (user.earnedMdxStored >= amount) {
                amount = user.earnedMdxStored;
            }

            bool isWithdraw = false;
            if (mdx.myBalance() < amount) {
                // If balance is not enough Withdraw from board room first.
                (uint256 depositedMdx, /* rewardDebt */) = boardRoom.userInfo(boardRoomPid, address(this));
                boardRoom.withdraw(boardRoomPid, depositedMdx);
                isWithdraw = true;
            }
            mdx.safeTransfer(msg.sender, amount);

            // Update left share and amount.
            uint256 share = _amountToShare(amount);
            globalInfo.totalShares = globalInfo.totalShares.sub(share);
            globalInfo.totalMdx = globalInfo.totalMdx.sub(amount);
            user.totalShares = user.totalShares.sub(share);
            user.earnedMdxStored = user.earnedMdxStored.sub(amount);

            // If withdraw mdx from board room, we need to redeposit.
            if (isWithdraw) {
                boardRoom.deposit(boardRoomPid, mdx.myBalance());
            }
        }
    }

    function reinvest() external {
        boardRoom.withdraw(boardRoomPid, 0);
        boardRoom.deposit(boardRoomPid, mdx.myBalance());
    }

    /* ==================================== Internal ==================================== */

    /// @dev update pool info and user info.
    function _updatePool(address account) internal {
        if (globalInfo.lastUpdateTime != block.timestamp) {
            /// @notice MUST update accMdxPerShare first as it will use the old totalMdx
            globalInfo.accMdxPerShare = rewardsPerShare();
            globalInfo.totalMdx = totalRewards();
            globalInfo.lastUpdateTime = block.timestamp;
        }

        UserInfo storage user = userInfo[account];
        if (account != address(0) && user.lastUpdateTime != block.timestamp) {
            user.earnedMdxStored = userEarnedAmount(account);
            user.accMdxPerShareStored = globalInfo.accMdxPerShare;
            user.lastUpdateTime = block.timestamp;
        }
    }

    function _amountToShare(uint256 amount) internal view returns (uint256) {
        return globalInfo.totalMdx == 0 ?
            amount : amount.mul(globalInfo.totalShares).div(globalInfo.totalMdx);
    }

    /* ==================================== Only Owner ==================================== */

    // Used when boardroom is closed.
    function stopReinvest() external onlyOwner {
        (uint256 deposited, /* rewardDebt */) = boardRoom.userInfo(boardRoomPid, address(this));
        if (deposited > 0) {
            boardRoom.withdraw(boardRoomPid, deposited);
        }
    }
}

pragma solidity ^0.6.0;

interface ERC20Interface {
    function balanceOf(address user) external view returns (uint256);
}

library SafeToken {
    function myBalance(address token) internal view returns (uint256) {
        return ERC20Interface(token).balanceOf(address(this));
    }

    function balanceOf(address token, address user) internal view returns (uint256) {
        return ERC20Interface(token).balanceOf(user);
    }

    function safeApprove(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeApprove");
    }

    function safeTransfer(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransfer");
    }

    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransferFrom");
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "!safeTransferETH");
    }
}

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