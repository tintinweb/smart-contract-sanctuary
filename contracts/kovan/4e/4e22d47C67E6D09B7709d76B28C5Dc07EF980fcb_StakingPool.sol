pragma solidity ^0.7.0;

interface ILibertasToken {
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function balanceOf(address _owner) external returns (uint256 balance);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external returns (uint256 remaining);
}

pragma solidity ^0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./ILibertasToken.sol";

contract StakingPool {
    using SafeMath for uint256;
    
    address public _LIBERTAS;
    mapping(address => UserInfo) public _userInfo;
    uint256 private _accLibertasPerShare;
    uint256 private _totalDeposits;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    constructor(address LIBERTAS) {
        _LIBERTAS = LIBERTAS;
    }

    function deposit(uint256 amount) public {
        UserInfo storage user = _userInfo[msg.sender];
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(_accLibertasPerShare).div(1e12).sub(user.rewardDebt);
            if (pending > 0) {
                safeLIBERTASTransfer(msg.sender, pending);
            }
        }
        if (amount > 0) {
            if (ILibertasToken(_LIBERTAS).transferFrom(msg.sender, address(this), amount)) {
                user.amount = user.amount.add(amount);
                _totalDeposits = _totalDeposits.add(amount);
            }
        }
        user.rewardDebt = user.amount.mul(_accLibertasPerShare).div(1e12);
        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint256 amount) public {
        UserInfo storage user = _userInfo[msg.sender];
        require(user.amount >= amount, "Withdraw too much");
        uint256 pending = user.amount.mul(_accLibertasPerShare).div(1e12).sub(user.rewardDebt);
        if (pending > 0) {
            safeLIBERTASTransfer(msg.sender, pending);
        }
        if (amount > 0) {
            user.amount = user.amount.sub(amount);
            _totalDeposits = _totalDeposits.sub(amount);
            ILibertasToken(_LIBERTAS).transfer(msg.sender, amount);
        }
        user.rewardDebt = user.amount.mul(_accLibertasPerShare).div(1e12);
        emit Withdraw(msg.sender, amount);
    }

    function claim() public {
        if (_userInfo[msg.sender].amount == 0) {
            return;
        }
        UserInfo storage user = _userInfo[msg.sender];
        uint256 pending = user.amount.mul(_accLibertasPerShare).div(1e12).sub(user.rewardDebt);
        if (pending > 0) {
            safeLIBERTASTransfer(msg.sender, pending);
        }
        user.rewardDebt = user.amount.mul(_accLibertasPerShare).div(1e12);
    }

    function emergencyWithdraw() public {
        UserInfo storage user = _userInfo[msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        safeLIBERTASTransfer(msg.sender, amount);
        emit EmergencyWithdraw(msg.sender, amount);
    }

    function supplyReward(uint256 reward) public {
        if (_totalDeposits == 0) {
            return;
        }
        _accLibertasPerShare = _accLibertasPerShare.add(reward.mul(1e12).div(_totalDeposits));
    }

    function safeLIBERTASTransfer(address _to, uint256 _amount) internal {
        uint256 totalBalance = ILibertasToken(_LIBERTAS).balanceOf(address(this));
        if (totalBalance < _amount) {
            ILibertasToken(_LIBERTAS).transfer(_to, totalBalance);
        } else {
            ILibertasToken(_LIBERTAS).transfer(_to, _amount);
        }
    }

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
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

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}