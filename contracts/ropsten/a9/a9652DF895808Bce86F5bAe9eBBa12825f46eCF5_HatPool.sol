/**
 *Submitted for verification at Etherscan.io on 2021-08-12
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

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

contract HatPool{
    using SafeMath for uint256;

    IERC20 public hat;
    address payable public receiveAddress;
    uint256 public fee = 2e17;
    uint256 public basicRate = 1;
    uint256 public consumeRate = 50;
    uint256 public base = 100000;
    struct UserInfo{
        uint256 shares;
        uint256 totalShares;
        uint256 rewardDebt;
        address payable invite;
        uint256 active;
        uint256 lastRewardTime;
        uint256 inviteCount;
    }
    mapping(address=>UserInfo) public userInfo;

    event Deposit(address indexed user, address invite, uint256 amount);
    event WithdrawHAT(address indexed user,  uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event InviteProfit(address indexed receiverAddr, uint256 amount);

    constructor(address payable _add, IERC20 _hat) public {
        receiveAddress = _add;
        hat = _hat;
    }

    function deposit(address payable _invite) public payable {
        updateReward();
        UserInfo storage user = userInfo[msg.sender];
        UserInfo storage invite = userInfo[_invite];
        if (user.active == 0) {
            if (_invite != address(0)) {
                require(invite.active == 1,"Invitee Invalid");
                require(invite.shares >= fee,"Invitee has not enough Okt");
                updateReward(_invite);
                if (invite.invite == address (0)) {
                    receiveAddress.transfer(fee);
                    invite.shares = invite.shares.sub(fee);
                    emit InviteProfit(receiveAddress,fee);
                } else {
                    uint256 mFee = fee.div(2);
                    receiveAddress.transfer(mFee);
                    emit InviteProfit(receiveAddress,mFee);
                    invite.shares = invite.shares.sub(fee);
                    invite.invite.transfer(fee.sub(mFee));
                    emit InviteProfit(invite.invite,fee.sub(mFee));
                }
                invite.inviteCount = invite.inviteCount.add(1);
            }
            user.invite = _invite;
            user.active = 1;
        }
        user.shares = user.shares.add(msg.value);
        user.totalShares = user.totalShares.add(msg.value);
        user.lastRewardTime = block.timestamp;
        emit Deposit(msg.sender, _invite, msg.value);
    }

    function withdrawHAT(uint256 _amount) public {
        updateReward();
        UserInfo storage user = userInfo[msg.sender];
        require(user.rewardDebt >= _amount, "user.rewardDebt is not enough");
        safeTransfer(msg.sender,_amount);
        user.rewardDebt = user.rewardDebt.sub(_amount);
        emit WithdrawHAT(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) public payable {
        updateReward();
        UserInfo storage user = userInfo[msg.sender];
        require(user.shares >= _amount, "user.shares not euough");
        user.shares = user.shares.sub(_amount);
        user.totalShares = user.totalShares.sub(_amount);
        msg.sender.transfer(_amount);
        emit Withdraw(msg.sender, _amount);
    }

    function updateReward(address _account) public {
        UserInfo storage user = userInfo[_account];
        uint256 reward = getUserProfit(_account);
        user.rewardDebt = user.rewardDebt.add(reward);
        user.lastRewardTime = block.timestamp;
        if (user.invite != address(0)) {
            UserInfo storage invite = userInfo[user.invite];
            invite.rewardDebt = invite.rewardDebt.add(reward.mul(20).div(100));
        }
    }

    function updateReward() public {
        updateReward(msg.sender);
    }

    function getUserProfit() public view returns (uint256) {
        return getUserProfit(msg.sender);
    }

    function getUserProfit(address account) public view returns (uint256) {
        UserInfo storage user = userInfo[account];
        uint256 profitAmount = 0;
        if (user.shares > 0) {
            uint256 time = block.timestamp;
            uint256 hour = time.sub(user.lastRewardTime).div(3600);
            if (hour >= 1) {
                profitAmount = user.totalShares.sub(user.inviteCount.mul(fee)).mul(user.inviteCount.mul(consumeRate).add(basicRate)).div(base).mul(hour);
            }
        }
        return profitAmount;
    }

    function safeTransfer(address _to, uint256 _Amt) internal {
        uint256 TokenBal = hat.balanceOf(address(this));
        if (_Amt > TokenBal) {
            hat.transfer(_to, TokenBal);
        } else {
            hat.transfer(_to, _Amt);
        }
    }
}