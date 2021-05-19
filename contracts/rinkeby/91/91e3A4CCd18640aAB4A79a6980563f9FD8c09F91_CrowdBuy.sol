/**
 *Submitted for verification at Etherscan.io on 2021-05-19
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;



// Part: OpenZeppelin/[email protected]/SafeMath

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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: SumBuying.sol

/// @title Base contract for simple crowdbuy
contract CrowdBuy {
    using SafeMath for uint256;
    /**
     * Евент о получении платежа
     * @param from Адрес от кого получили
     * @param amount Количество полученного эфира
     */
    event PaymentReceived(address from, uint256 amount);
    /**
     * Евент об окончании сбора средств
     * @param productID ID покупаемого товара
     * @param totalSum Общая собранная сумма
     */
    event CrowdFinished(uint256 productID, uint256 totalSum);

    uint256 beginDate;
    uint256 endDate;
    uint256 minPayment;
    address payable destAddress;
    uint256 currSum;
    uint256 totalSum;
    uint256 productID;
    bool isFinished = false;
    mapping(address => uint256) participantsList;


    modifier checkIsFinished() {
        require(!isFinished);
        _;
    }

    modifier checkIsSeller() {
        require(!isFinished);
        _;
    }
    /**
     * @param _endDate Даты окончания покупки
     * @param _minPayment Минимальный входной платеж
     * @param _totalSum Общая сумма, которую нужно собрать
     * @param _destAddress Адрес, куда пойдут собранные деньги
     * @param _productID ID товара который собрались покупать
     */
    constructor(
        uint256 _endDate,
        uint256 _minPayment,
        uint256 _totalSum,
        address payable _destAddress,
        uint256 _productID
    ) public {
        require(_endDate > block.timestamp);
        require(_totalSum > 0);
        require(_destAddress != address(0));
        require(_minPayment > 0);

        beginDate = block.timestamp;
        endDate = _endDate;
        minPayment = _minPayment;
        currSum = 0;
        totalSum = _totalSum;
        destAddress = _destAddress;
        productID = _productID;
    }

    /**
     * @dev Getter for the current total donated sum
     */
    function getCurrSum() public view returns (uint256) {
        return currSum;
    }

    /**
     * @dev Getter for the total required sum
     */
    function getNeededSum() public view returns (uint256) {
        return totalSum;
    }
    /**
     * @dev Проверка закончились ли сборы
     */
    function getIsFinished() public view returns (bool) {
        return isFinished;
    }

    /**
     * @dev Getter for the end date of collecting etherium
     */
    function getEndedDate() public view returns (uint256) {
        return endDate;
    }
    /**
     * @dev Получение очередного платежа
     */
    receive() external payable {
        require(currSum < totalSum);
        require(block.timestamp < endDate);
        require(msg.value >= minPayment);
        require(!isFinished);

        currSum = currSum.add(msg.value);
        //никак не используется
        participantsList[msg.sender] = participantsList[msg.sender].add(msg.value);

        if (currSum >= totalSum) {
            finishCrowd();
        }
        emit PaymentReceived(msg.sender, msg.value);
    }

    function endCrowdbuy() external checkIsFinished checkIsSeller {
        require(!isFinished);
        finishCrowd();
    }

    function finishCrowd() internal {
        isFinished = true;
        destAddress.transfer(currSum);
        emit CrowdFinished(productID, currSum);
    }
}