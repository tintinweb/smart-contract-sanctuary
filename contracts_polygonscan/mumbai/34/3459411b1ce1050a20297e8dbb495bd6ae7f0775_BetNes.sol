//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import {IERC20} from "./IERC20.sol";
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
contract BetNes {
    IERC20 erc20Token;

    mapping(address => uint256) balances;
    Bet[] bets;
    uint256 MIN_BET;
    uint256 MAX_BET;
    uint8 FEE;
    event Deposit(address indexed from, uint256 amount);
    event Withdrawal(address indexed from, uint256 amount);
    event NewBet(
        address indexed from,
        uint256 index,
        uint256 timestamp,
        uint8 dice1,
        uint8 dice2,
        uint8 dice3,
        uint8 dice4,
        uint8 dice5,
        uint8 dice6
    );
    struct Bet {
        uint8[6] dices;
        bool pending;
        address caller;
        uint256 betAmount;
        uint8 result;
    }

    constructor(address _erc20Token) {
        MIN_BET = 1;
        MAX_BET = 1000;
        FEE = 1;
        erc20Token = IERC20(_erc20Token);
    }

    function validateBet(
        uint256 amount,
        uint8 dice1,
        uint8 dice2,
        uint8 dice3,
        uint8 dice4,
        uint8 dice5,
        uint8 dice6
    ) private view {
        require(amount >= MIN_BET);
        require(amount < MAX_BET);
        require(balances[msg.sender] >= amount);
        require(dice1 <= 6);
        require(dice2 <= 6);
        require(dice3 <= 6);
        require(dice4 <= 6);
        require(dice5 <= 6);
        require(dice6 <= 6);
        require(dice1 == 0 ||
            dice1 != dice2 &&
                dice1 != dice3 &&
                dice1 != dice4 &&
                dice1 != dice5 &&
                dice1 != dice6
        );
        require(dice2 == 0 ||
            dice2 != dice3 && dice2 != dice4 && dice2 != dice5 && dice2 != dice6
        );
        require(dice3 == 0 || dice3 != dice4 && dice3 != dice5 && dice3 != dice6);
        require(dice4 == 0 || dice4 != dice5 && dice4 != dice6);
        require(dice5 == 0 || dice5 != dice6);
    }

    function newBet(
        uint256 amount,
        uint8 dice1,
        uint8 dice2,
        uint8 dice3,
        uint8 dice4,
        uint8 dice5,
        uint8 dice6
    ) public {
        validateBet(amount, dice1, dice2, dice3, dice4, dice5, dice6);
        uint8[6] memory dices = [dice1, dice2, dice3, dice4, dice5, dice6];
        balances[msg.sender] = balances[msg.sender] - amount;
        bets.push(Bet(dices, true, msg.sender, amount, 0));
        emit NewBet(
            msg.sender,
            bets.length,
            block.timestamp,
            dice1,
            dice2,
            dice3,
            dice4,
            dice5,
            dice6
        );
    }

    function betsLength() public view returns (uint256) {
        return bets.length;
    }

    function getBet(uint256 index)
        public view
        returns (
            address caller,
            bool pending,
            uint256 betAmount,
            uint8 result,
            uint8 dice1,
            uint8 dice2,
            uint8 dice3,
            uint8 dice4,
            uint8 dice5,
            uint8 dice6
        )
    {
        Bet memory currentBet = bets[index];
        return (
            currentBet.caller,
            currentBet.pending,
            currentBet.betAmount,
            currentBet.result,
            currentBet.dices[0],
            currentBet.dices[1],
            currentBet.dices[2],
            currentBet.dices[3],
            currentBet.dices[4],
            currentBet.dices[5]
        );
    }

    function runBet(uint256 index, uint8 luckyNumber) public {
        Bet memory bet =  bets[index];
        uint256 commision = SafeMath.div(bet.betAmount, 100);
        uint256 betAmount = SafeMath.sub(bet.betAmount, commision);
        bool won = false;
        uint8 numberOfDices = 0;
        for(uint i = 0; i < 6; i++) {
            uint8 dice = bet.dices[i];
            if(dice != 0) {
                numberOfDices = numberOfDices + 1;
            }
            if(dice == luckyNumber) {
                won = true;
            }
        }
        uint multiplier = SafeMath.div(1000000, SafeMath.div(SafeMath.mul(numberOfDices, 10000), 6));
        if(won) {
            balances[bet.caller] = balances[bet.caller] + SafeMath.div(SafeMath.mul(betAmount, multiplier), 100);
        }
    }
    function deposit(uint256 amount) public {
        require(erc20Token.allowance(msg.sender, address(this)) > amount);
        require(erc20Token.balanceOf(msg.sender) >= amount);
        erc20Token.transferFrom(msg.sender, address(this), amount);
        balances[msg.sender] = balances[msg.sender] + amount;
        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint256 amount) public {
        require(balances[msg.sender] >= amount);
        balances[msg.sender] = balances[msg.sender] - amount;
        erc20Token.transfer(msg.sender, amount);
        emit Withdrawal(msg.sender, amount);
    }

    function balanceOf(address _address) public view returns (uint256) {
        return balances[_address];
    }
}