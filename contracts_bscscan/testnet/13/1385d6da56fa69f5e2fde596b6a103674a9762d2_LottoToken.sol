/**
 *Submitted for verification at BscScan.com on 2022-01-02
*/

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


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

// File: contracts/LottoToken.sol

//SPDX-License-Identifier: GPL-3.0

pragma solidity^0.8.0;

contract LottoToken {
    using SafeMath for uint256;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint)) allowance;
    uint256 public _totalSupply ;
    string public name;
    string public symbol;
    uint public decimals;
    address public tokenAdmin;
    address constant public developerAddr = 0xe2f35Fa533066723Fd94Af3cE7C34B30b84105B9;
    address constant public burnAddr = address(0);
    event Transfer(address indexed from, address indexed recipient, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event TransferFrom(address indexed from, address indexed recipient, uint value);

    constructor() {
        tokenAdmin = msg.sender;
        decimals = 18;
        name = "LottoCoin";
        symbol = "LOTTO";
        _totalSupply =  777777 * (10 ** uint(decimals));
        balances[tokenAdmin] = _totalSupply.mul(99).div(100);
        balances[developerAddr] = _totalSupply.mul(1).div(100);
    }

   function balanceOf(address _owner) public view returns(uint256) {
       return balances[_owner];
   }


    function approve(address spender, uint value) public returns(bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }


    function takeTax(uint256 value) internal pure returns(uint256, uint256, uint256) {
        uint256 recieveValue = value.mul(99).div(100);
        uint256 newValue = value - recieveValue;
        uint256 burnValue = newValue.mul(23).div(100);
        uint256 tax = newValue.mul(77).div(100);
        return (recieveValue, burnValue, tax);
    }

   function transfer(address to, uint256 value) public returns(bool) {
       require(balanceOf(msg.sender) >= value, "Balance too low");
        (uint256 recieveValue, uint256 burnValue, uint256 tax) = takeTax(value);
        balances[to] += recieveValue;
        balances[msg.sender] -= recieveValue;
        burn(burnValue);
        balances[tokenAdmin] += tax;
        emit Transfer(msg.sender, to, recieveValue);
        return true;
   }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, "Balance is insufficient");
        require(allowance[from][msg.sender] >= value, "Allowance too low");
        (uint256 recieveValue, uint256 burnValue, uint256 tax) = takeTax(value);
        balances[to] += recieveValue;
        balances[from] -= recieveValue;
        burn(burnValue);
        balances[tokenAdmin] += tax;
        emit TransferFrom(from, to, value);
        return true;
    }


    function burn(uint256 _amntToBurn) public returns(bool) {
        require(balanceOf(msg.sender)>=_amntToBurn, "Insufficient balance");
        balances[burnAddr] += _amntToBurn;
        balances[msg.sender] -= _amntToBurn;
        return true;
    }

    function burnApproved(address from, uint256 _amntToBurn) public returns(bool) {
        require(balanceOf(from) >= _amntToBurn, "Balance is insufficient");
        require(allowance[from][msg.sender] >= _amntToBurn, "Allowance too low");
        balances[burnAddr] += _amntToBurn;
        balances[from] -= _amntToBurn;
        return true;
    }

    function changeAdmin(address newAdmin) public returns(bool) {
        require(msg.sender == tokenAdmin, "You are not the current token admin");
        tokenAdmin = newAdmin;
        return true;
    }

    function totalSupply() public view returns(uint256) {
        return _totalSupply;
    }


}