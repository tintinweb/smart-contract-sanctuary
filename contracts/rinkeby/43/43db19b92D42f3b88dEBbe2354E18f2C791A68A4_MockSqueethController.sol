// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

/**
* @title MockSqueethController
* @dev A Mock Controller for testing out the Squeeth controller implementation
 */
contract MockSqueethController is Ownable{
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    mapping(uint => uint) public indexByDuration; //mock index price(ETH^2) price
    mapping(uint => uint) public denormalizedMarkPrice; //mock denormalizedMarkPrice
    mapping(uint => uint) public denormalizedMarkPriceForFunding; // mock denormalizedmarkForFunding
    mapping(uint => bool) public isExistingMarkPricePeriod; //to check if this rate is already added(for test purposes)

    uint public currentPosition = 1;
    uint public totalIndexPrices = 0;
    uint public totalMarkPrices = 0;

    uint public volatilityPrice = 1;
    uint public transactionPeriod; //dummy transaction period to be set by the contract owner(for testing purposes)

    Counters.Counter private indexIds;
    Counters.Counter private markPriceIds;
    Counters.Counter private denormalizedMarkPriceForFundingIds;

    constructor() public{

    }

    modifier isValidDuration(uint _duration){
        require(_duration != 0,"Invalid Duration");
        _;
    }

    modifier periodIsNotRegistered(uint _period){
        require(isExistingMarkPricePeriod[_period] == false,"Transaction Duration Exists");
        _;
    }

    modifier periodIsRegistered(uint _period){
        require(isExistingMarkPricePeriod[_period] == true,"Transaction Duration Not Registered");
        _;
    }

    event NewIndex(address indexed caller, uint indexed newIndex, uint indexed date); // new ETH^2 price
    event NewMarkPrice(address indexed user, uint indexed newMarkprice, uint indexed date);
    event NewTransactionPeriod(address indexed user, uint indexed newTxPeriod, uint indexed date);
    event NewDenormalizedMarkPriceForFunding(address indexed user, uint indexed newFundingMarkPrice, uint indexed date);

    /**
    * @dev sets a mock transaction period
    * @return bool true if new tx period is set successfully otherwise false
    */
    function setTransactionPeriod(uint _period) public onlyOwner isValidDuration(_period) periodIsNotRegistered(_period) returns(bool){
        transactionPeriod = _period;
        isExistingMarkPricePeriod[_period] = true;
        emit NewTransactionPeriod(msg.sender, _period, block.timestamp);
        return true;
    }

    /**
    * @dev sets a new (ETH^2) price
    * @param _period uint the period for the ETH^2 trading
    * @return bool true is new ETH^2 price is set successfully otherwise false
    */
    function setIndex(uint _period) public onlyOwner isValidDuration(_period) returns(bool){
        indexIds.increment();
        uint currentIndexId = indexIds.current();
        indexByDuration[_period] = currentIndexId;
        totalIndexPrices = totalIndexPrices.add(1); // to prevent integer overflow
        emit NewIndex(msg.sender,currentIndexId, block.timestamp);
        return true;
    }

    /**
    * @dev sets a new PowerPerp mark price
    * @param _period the duraion of the trade
    * @return bool true if new price is set successfully otherwisw false
    */
    function setDenormalizedMark(uint _period) public onlyOwner isValidDuration(_period) returns(bool){
        markPriceIds.increment();
        uint currentDenormalizedMarkPrice = markPriceIds.current();
        denormalizedMarkPrice[_period] = currentDenormalizedMarkPrice;
        totalMarkPrices = totalMarkPrices.add(1);
        emit NewMarkPrice(msg.sender,currentDenormalizedMarkPrice, block.timestamp);
        return true;
    }
    
    /**
    * @dev sets a
    * @param _period uint the funding period
    * @return true if new funding period is set otherwise false
    */
    function setDenormalizedMarkForFunding(uint _period) public onlyOwner isValidDuration(_period) returns(bool){
        denormalizedMarkPriceForFundingIds.increment();
        uint currentDenFundIdForFunding = denormalizedMarkPriceForFundingIds.current();
        denormalizedMarkPriceForFunding[_period] = currentDenFundIdForFunding;
        emit NewDenormalizedMarkPriceForFunding(msg.sender, currentDenFundIdForFunding, block.timestamp);
        return true;
    }

    /**
    * @dev get the index price of the powerPerp, scaled down
    * @return index price denominated in $USD
    */
    function getIndex(uint _period) public view periodIsRegistered(_period) returns(uint){
        return indexByDuration[_period];
    }

    /**
    * @dev get the expected mark price of powerPerp after funding has been applied
    * @return uint the powerPer price based on the trading period
    */
    function getDenormalizedMark(uint _period) public view periodIsRegistered(_period) returns(uint){
        return denormalizedMarkPrice[_period];
    }

    /**
    * @dev get the mark price of powerPerp before funding has been applied
    * @return uint mark price
    */
    function getDenormalizedMarkForFunding(uint _period) public view periodIsRegistered(_period) returns(uint){
        return denormalizedMarkPriceForFunding[_period];
    }

    /**
    * returns the price volatility between the trades of ETH^2 and oSQTH
    */
    function getVolatilityPrice() public view returns(uint){
        return volatilityPrice;
    }

    /**
    * @dev gets the funding rates based on the proived period
    * @return uint the calucalted funding rate
    */
    function getCurrentFundingRate(uint _period) public view periodIsRegistered(_period) returns(uint){
        uint markPrice = getDenormalizedMark(_period);
        uint indexPrice = getIndex(_period);
        return _getCurrentFundingRate(markPrice,indexPrice);
    }

    /**
    * @dev returns the funding rate based on an average of the two toke prices(mark price and index price) 
    * for testing only and not the exact implementation from squeeth protocol
    */
    function getHistoricalFundingRate(uint _periodFrom, uint _periodTo) public view returns(uint){
        require(_periodFrom != _periodTo,"Invalid Period Range");
        require(_periodTo > _periodFrom,"Period To must be greator than the initial range");
        require(_periodTo != 0,"Final Period Range cannot be zero");
        require(_periodFrom > 0,"Intitial Period Range must not be zero");

        uint initialMarkPrice = getDenormalizedMark(_periodFrom);
        uint latestMarkPrice =  getDenormalizedMark(_periodTo);

        uint totalMarkPrice = initialMarkPrice.add(latestMarkPrice);
        uint avgMarkPrice = totalMarkPrice.div(2);

        uint initialIndexPrice = getIndex(_periodFrom);
        uint latestIndexPrice = getIndex(_periodTo);

        uint totalIndexPrice = initialIndexPrice.add(latestIndexPrice);
        uint avgIndexPrice = totalIndexPrice.div(2);

        return _getHistoricalFundingRate(avgMarkPrice,avgIndexPrice);
    }

    /**
    * @notice Funding rates are payments made by long Squeeth traders to short Squeeth traders 
    * based on the disparity between the Index Price (ETH²) and the Mark Price
    * @dev a helper function that calculates the current funding rate from the mark price(ETH^2 price and index price )
    */
    function _getCurrentFundingRate(uint _markPrice, uint _indexPrice) internal view returns(uint){
        uint difference = _markPrice.sub(_indexPrice);
        uint position = _getCurrentPosition();
        return position.mul(difference);
    }

    /**
    * @dev internal functin that calculates the funding rates
    */
    function _getHistoricalFundingRate(uint _avgMarkPrice, uint _avgIndexPrice) internal view returns(uint){
        return _getCurrentFundingRate(_avgMarkPrice,_avgIndexPrice);
    }

    /**
    * @dev fetches the user\'s current token position
    */
    function _getCurrentPosition() internal view returns(uint){
        return currentPosition;
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}