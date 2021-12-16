/**
 *Submitted for verification at BscScan.com on 2021-12-16
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

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
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);

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

contract ChumbiPrivateVesting {
    using SafeMath for uint256;

    IERC20 public token;
    
    uint256 public totalLockedToken;
    uint256 public unlockTokenNumber;
    address public unlockAddress = 0x95D3934AF9479f40cfa1CF738001355265Bd5089;
    
    uint256 public currentUnlockToken;
    uint256 public startUnlockTime;
    uint256 public lastUnlockTime;
    uint256 public baseTime = 60;                // 1 min = 60 sec
    uint256 public maxUnlockingTimes = 365 days; // 365 days

    event ClaimToken(address indexed mananger, uint256 day, uint256 amount);

    modifier unlockCheck() {
        if(currentUnlockToken == 0) {
            require(
                balanceOf() >= totalLockedToken,
                "The project party is requested to transfer enough tokens to start the lock up contract"
            );
        }
        require(msg.sender == unlockAddress, "You do not have permission to unlock");
        _;
    }

    constructor(address _token) public {
        token = IERC20(_token);
        startUnlockTime = 1639922400;                                      // First unlocking time： 2021-12-19 02:00:00 PM
        uint256 _decimals = token.decimals();
        totalLockedToken = (10 ** _decimals).mul(457_142_857_14).div(100); // TOTAL: 457,142,857.14 CHMB
        maxUnlockingTimes = maxUnlockingTimes.div(baseTime);
        unlockTokenNumber = totalLockedToken.div(maxUnlockingTimes);       // Unlock quantity per second
    }

    function blockTimestamp() public view returns(uint256) {
        return block.timestamp;
    }

    function getUnlockedTimes() public view returns(uint256) {
        if(blockTimestamp() > startUnlockTime) {
            return blockTimestamp().sub(startUnlockTime).div(baseTime);
        } else {
            return 0;
        }
    }

    function balanceOf() public view returns(uint256) {
        return token.balanceOf(address(this));
    }

    function managerBalanceOf() public view returns(uint256) {
        return token.balanceOf(unlockAddress);
    }

    function claimToken() public unlockCheck {
        require(balanceOf() > 0, "There is no balance to unlock and withdraw");
        uint256 unlockTime = getUnlockedTimes();
        uint256 unlockToken;
        if(unlockTime >= maxUnlockingTimes) {
            unlockToken = balanceOf();
            lastUnlockTime = maxUnlockingTimes;
        } else {
            require(unlockTime > lastUnlockTime, "No current extractable times");
            unlockToken = unlockTime.sub(lastUnlockTime).mul(unlockTokenNumber);
            lastUnlockTime = unlockTime;
        }
        currentUnlockToken = currentUnlockToken.add(unlockToken);
        _safeTransfer(unlockToken);
        emit ClaimToken(unlockAddress, unlockTime, unlockToken);
    }
    
    function _safeTransfer(uint256 unlockToken) private {
        require(balanceOf() >= unlockToken, "Insufficient available balance for transfer");
        token.transfer(unlockAddress, unlockToken);
    }
}