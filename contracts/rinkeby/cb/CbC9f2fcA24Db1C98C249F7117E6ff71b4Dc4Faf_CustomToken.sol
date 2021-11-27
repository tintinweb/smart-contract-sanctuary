// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.8.9;
import "SafeMath.sol";

contract CustomToken {
    using SafeMath for uint256;
    address owner;
    uint256 public tokenPrice;
    string public name;
    string public symbol;
    uint256 public tokenSold = 0;
    uint256 profit = 0;
    mapping(address => uint256) private balance;
    address lib = 0xc0b843678E1E73c090De725Ee1Af6a9F728E2C47;
    event Purchase(address buyer, uint256 amount);
    event Transfer(address sender, address receiver, uint256 amount);
    event Sell(address seller, uint256 amount);
    event Price(uint256 price);
    event WithdrawProfit(uint256 amount);
    event TokenCreated(
        string name,
        string symbol,
        uint256 initTokenPrice
    );

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _tokenPrice
    ) {
        owner = msg.sender;
        name = _name;
        symbol = _symbol;
        tokenPrice = _tokenPrice;
        emit TokenCreated(name, symbol,tokenPrice);
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "You don't have the access to this function!"
        );
        _;
    }
    function buyToken(uint256 amount) external payable returns (bool) {
        require(
            msg.value >= calculator(amount, true),
            "Please pay enough money to buy the token."
        );
        balance[msg.sender] = balance[msg.sender].add(amount);
        tokenSold = tokenSold.add(amount);
        profit = profit.add(calculator(amount, true) - tokenPrice.mul(amount));
        uint256 refund = msg.value.sub(calculator(amount, true));
        if (refund == 0) {
            emit Purchase(msg.sender, amount);
            return true;
        }
        (bool success, ) = lib.delegatecall(
            abi.encodeWithSignature(
                "customSend(uint256,address)",
                refund,
                msg.sender
            )
        );
        if (success) {
            emit Purchase(msg.sender, amount);
            return true;
        } else {
            return false;
        }
    }

    function transfer(address recipient, uint256 amount)
        external
        returns (bool)
    {
        require(amount > 0, "You cannot transfer 0 amount!");
        require(
            balance[msg.sender] > amount,
            "You don't have enough amount of token to transfer!"
        );
        balance[msg.sender] = balance[msg.sender].sub(amount);
        balance[recipient] = balance[msg.sender].add(amount);
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function sellToken(uint256 amount) external returns (bool) {
        require(
            balance[msg.sender] > amount,
            "You don't have enough amount to sell!"
        );   
        uint256 value = calculator(amount, false);
        balance[msg.sender] = balance[msg.sender].sub(amount);
        tokenSold = tokenSold.sub(amount);
        profit = profit.add(tokenPrice.mul(amount).sub(value));
        (bool success, ) = lib.delegatecall(
            abi.encodeWithSignature(
                "customSend(uint256, address)",
                value,
                msg.sender
            )
        );
        if (success) {
            emit Sell(msg.sender, amount);
            return true;
        } else {
            return false;
        }
    }

    function changePrice(uint256 price)
        external
        payable
        onlyOwner
        returns (bool)
    {
        require(price > tokenPrice, "You cannot lower the price");
        if (address(this).balance < price.mul(tokenSold)){
            return false;
        } else {
            tokenPrice = price;
            emit Price(price);
            return true;
        }
    }

    function getBalance() external view returns (uint256) {
        return balance[msg.sender];
    }

    function calculator(uint256 amount, bool buy)
        public
        view
        returns (uint256)
    {
        if (buy == true) {
            return (tokenPrice.mul(amount) + tokenPrice.mul(amount).div(100));
        } else {
            return (tokenPrice.mul(amount) - tokenPrice.mul(amount).div(100));
        }
    }

    function withdrawProfit() external onlyOwner returns (bool) {
        require(profit > 0, "insufficient profit to withdraw");
        uint256 amount = profit;
        profit = 0;
        (bool success, ) = lib.delegatecall(
            abi.encodeWithSignature(
                "customSend(uint256, address)",
                amount,
                msg.sender
            )
        );
        if (success) {
            emit WithdrawProfit(amount);
            return true;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT
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