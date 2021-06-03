// SPDX-License-Identifier: LGPL-3.0+

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/xERC20.sol";
import "./interfaces/Igeneric.sol";
// import "hardhat/console.sol";

pragma experimental ABIEncoderV2;
pragma solidity ^0.7.3;

// Purely for Creating sales , handle price.

contract ECFMarket is Ownable {
    using SafeMath for uint256;
    address payable public wallet;

    uint256 public sale_start;
    uint256 public sale_end;
    Igeneric generic;

    struct CardTypeStructure {
        string cardTypeName;
        uint256 start; // card starting serial
        uint256 max; // max output.
        uint256 sold; // sold AND resolved
        uint256[] price_stop; // pricing stuff
        uint256[] price_price;
        uint256 price_pointer;
    }

    mapping(uint256 => CardTypeStructure) CardType;
    uint256 public cardTypeCount; // =0;

    event Refund(
        address buyer,
        uint256 sent,
        uint256 purchased,
        uint256 refund
    );
    event newSalesEndDate(uint256 endDate);

    modifier sale_active() {
        require(getTimestamp() >= sale_start, "SNS"); // Sales not started
        require(getTimestamp() <= sale_end, "SE"); // Sale ended
        _;
    }

    // Start
    constructor(
        uint256 _start,
        uint256 _end,
        address payable _wallet,
        Igeneric _generic
    ) public {
        sale_start = _start;
        sale_end = _end;
        wallet = _wallet;
        generic = _generic;
    }

    function setNewCardType(
        string calldata _cardTypeName,
        uint256 _start,
        uint256 _end,
        uint256[] calldata _stop,
        uint256[] calldata _price
    ) external onlyOwner {
        if (cardTypeCount != 0) {
            require(
                _start > CardType[cardTypeCount - 1].max,
                "SM" // start larger than previous Max
            );
        }
        CardType[cardTypeCount] = CardTypeStructure(
            _cardTypeName,
            _start,
            _end,
            0,
            _stop,
            _price,
            0
        );
        cardTypeCount++;
    }

    // ENTRY POINT TO SALE CONTRACT
    function buyCard(uint256 card_type) external payable sale_active {
        uint256 balance = msg.value;
        uint256 price;
        require(card_type < cardTypeCount, "ICT3"); // Invalid card type
        price = getCard_price(card_type);
        for (uint256 j = 0; j < 65; j++) {
            // Will run out of gas, if more than 60.
            // Refund
            if (balance < price) {
                if (j == 0) require(false, "Didn't enough sent"); // 
                payable(wallet).transfer(msg.value.sub(balance));
                payable(msg.sender).transfer(balance);
                emit Refund(msg.sender, msg.value, j, balance);
                return;
            }
            assignCard(msg.sender, card_type);
            balance = balance.sub(price);
        }
        payable(wallet).transfer(msg.value.sub(balance));
        payable(msg.sender).transfer(balance);
        emit Refund(msg.sender, msg.value, 100, balance);
    }

    function assignCard(address buyer, uint256 card_type) internal {
        uint256 card_remaining = getCard_remaining(card_type);
        require(card_remaining > 0, "CR1");
        uint256 Sum = CardType[card_type].start + CardType[card_type].sold;
        // Mint
        generic.purchaseCard(msg.sender, CardType[card_type].cardTypeName, Sum);
        //console.log(" remaing %s ", card_remaining);
        // console.log(" start %s ", CardType[card_type].start);
        // console.log(" sold %s", CardType[card_type].sold);
        CardType[card_type].price_pointer = bump(
            CardType[card_type].sold,
            1, // pending
            CardType[card_type].price_stop,
            CardType[card_type].price_pointer
        );
        CardType[card_type].sold++;
        return;
    }

    function bump(
        uint256 sold,
        uint256 pending,
        uint256[] memory stop,
        uint256 pointer
    ) internal pure returns (uint256) {
        if (pointer == stop.length - 1) return pointer;
        if (sold + pending > stop[pointer]) {
            return pointer + 1;
        }
        return pointer;
    }

    // Viewer

    function getTimestamp() public view virtual returns (uint256) {
        return block.timestamp;
    }

    function how_long_more(bool _end)
        public
        view
        returns (
            uint256 Days,
            uint256 Hours,
            uint256 Minutes,
            uint256 Seconds
        )
    {
        uint256 gap;
        if (_end) {
            require(getTimestamp() < sale_end, "Sales ended");
            gap = sale_end - getTimestamp();
        } else {
            require(getTimestamp() < sale_start, "Missed It");
            gap = sale_start - getTimestamp();
        }
        Days = gap / (24 * 60 * 60);
        gap = gap % (24 * 60 * 60);
        Hours = gap / (60 * 60);
        gap = gap % (60 * 60);
        Minutes = gap / 60;
        Seconds = gap % 60;
        return (Days, Hours, Minutes, Seconds);
    }

    function getCard_price(uint256 _CardType) public view returns (uint256) {
        require(getCard_remaining(_CardType) > 0, "SO"); // Sold out
        return (
            CardType[_CardType].price_price[CardType[_CardType].price_pointer]
        );
    }

    function sale_is_over() public view returns (bool) {
        return (getTimestamp() > sale_end);
    }

    function getCardTypeData(uint256 _CardType)
        public
        view
        returns (CardTypeStructure memory)
    {
        return CardType[_CardType];
    }

    function getCardType(uint256 serial) public view returns (string memory) {
        if (serial < 10) {
            // 0-9
            return "Founder";
        }
        for (uint256 j = 0; j < cardTypeCount; j++) {
            if (serial < CardType[j].max) {
                return CardType[j].cardTypeName;
            }
        }
        return "Unresolved";
    }

    function numberSold() public view returns (uint256) {
        uint256 totalSold = 0;
        for (uint256 j = 0; j < cardTypeCount; j++) {
            //for loop example
            totalSold += CardType[j].sold;
        }
        return totalSold;
    }

    function getCard_remaining(uint256 _CardType)
        public
        view
        returns (uint256)
    {
        return (CardType[_CardType].max -
            (CardType[_CardType].start + CardType[_CardType].sold) +
            1);
    }

    function CARDTYPE_next(uint256 card_type)
        public
        view
        returns (uint256 left, uint256 nextPrice)
    {
        return
            CARD_next(
                CardType[card_type].price_stop,
                CardType[card_type].price_price,
                CardType[card_type].sold,
                1, // pending
                CardType[card_type].price_pointer
            );
    }

    function CARD_next(
        uint256[] memory stop,
        uint256[] memory price,
        uint256 sold,
        uint256 pending,
        uint256 pointer
    ) internal view returns (uint256 left, uint256 nextPrice) {
        left = stop[pointer] - (sold + pending);
        if (pointer < stop.length - 1) nextPrice = price[pointer + 1];
        else nextPrice = price[pointer];
    }

    // PRESALE FUNCTIONS
    function allocateManyCards(address[] memory buyers, uint256 card_type)
        external
        onlyOwner
    {
        require(card_type < cardTypeCount, "Invalid Card Type"); // Invalid Card Type
        for (uint256 j = 0; j < buyers.length; j++) {
            assignCard(buyers[j], card_type);
        }
    }

    function allocateCard(address buyer, uint256 card_type) external onlyOwner {
        require(card_type < cardTypeCount, "Invalid Card Type"); // Invalid Card Type
        assignCard(buyer, card_type);
    }

    // Admin
    function mintTheRest(uint256 card_type, address target) external onlyOwner {
        require(sale_is_over(), "NO"); // sale is not over yet.
        require(card_type < cardTypeCount, "IT"); // Invalid card type.
        uint256 toMint = 50;
        uint256 remaining = getCard_remaining(card_type);
        remaining = Math.min(remaining, toMint);
        for (uint256 j = 0; j < remaining; j++) {
            assignCard(target, card_type);
        }
    }

    function drain(xERC20 token) external onlyOwner {
        if (address(token) == 0x0000000000000000000000000000000000000000) {
            payable(owner()).transfer(address(this).balance);
        } else {
            token.transfer(owner(), token.balanceOf(address(this)));
        }
    }

    function extendSales(uint8 _NoOfweeks) external onlyOwner {
        // extend no of weeks.
        sale_end = getTimestamp() + (_NoOfweeks * 1 weeks);
        emit newSalesEndDate(sale_end);
    }

    function stopSales() external onlyOwner {
        // end sales.
        sale_end = getTimestamp();
        emit newSalesEndDate(sale_end);
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
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
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

// SPDX-License-Identifier: UNLICENSED
// produced by the Solididy File Flattener (c) David Appleton 2018 - 2020 and beyond
// contact : [email protected]
// source  : https://github.com/DaveAppleton/SolidityFlattery
// released under Apache 2.0 licence
// input  /Users/daveappleton/Documents/akombalabs/ec_traits/contracts/ethercards.sol
// flattened :  Monday, 01-Mar-21 20:16:06 UTC
pragma solidity ^0.7.3;

abstract contract xERC20 {
    function transfer(address, uint256) public virtual returns (bool);

    function balanceOf(address) public view virtual returns (uint256);
}

pragma solidity ^0.7.3;

interface Igeneric {
    function purchaseCard(
        address,
        string calldata,
        uint256
    ) external;
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

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}