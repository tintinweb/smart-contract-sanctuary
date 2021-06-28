/**
 *Submitted for verification at Etherscan.io on 2021-06-28
*/

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol

pragma solidity ^0.7.0;

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
    constructor () {
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

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.7.0;

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

// File: @openzeppelin/contracts/utils/Counters.sol

pragma solidity ^0.7.0;


/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

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
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

// File: contracts/LCX_Register.sol

pragma solidity ^0.7.6;

/*
    SPDX-License-Identifier: 
    Copyright 2018, Vicent Nos, Enrique Santos & Mireia Puig

    License:
    https://creativecommons.org/licenses/by-nc-nd/4.0/legalcode

 */


contract LCX_Register is Ownable {
    using Counters for Counters.Counter;

    /******************
    EVENTS
    ******************/
    event ProducerRegistered(uint256 producerId, address indexed wallet);
    event TransporterRegistered(uint256 transporterId, address indexed wallet);
    event HumanRegistered(uint256 humanId, address indexed wallet);
    event ProducerValidityChanged(uint256 producerId, bool indexed validated);
    event TransporterValidityChanged(uint256 transporterId, bool indexed validated);
    event HumanValidityChanged(uint256 humanId, bool indexed validated);
    event ProducerStarredChanged(uint256 producerId, bool indexed starred);
    event TransporterStarredChanged(uint256 transporterId, bool indexed starred);
    event HumanStarredChanged(uint256 humanId, bool indexed starred);

    /******************
    INTERNAL ACCOUNTING
    *******************/
    Counters.Counter private producerId;
    Counters.Counter private transporterId;
    Counters.Counter private humanId;

    mapping(uint256 => Producer) public producers;
    mapping(uint256 => Transporter) public transporters;
    mapping(uint256 => Human) public humans;

    struct Producer {
        address creator;
        string name;
        string place;
        string description;
        string productData;
        string logisticDetails;
        bool validated;
        bool starred;
    }

    struct Transporter {
        address creator;
        uint256 pricePerKm;
        string name;
        string place;
        string description;
        string logisticCapability;
        bool validated;
        bool starred;
    }

    struct Human {
        address creator;
        string name;
        string place;
        string description;
        string jobData;
        string logisticDetails;
        bool validated;
        bool starred;
    }

    /******************
    PUBLIC FUNCTIONS
    *******************/
    function registerProducer(
        string memory _name,
        string memory _place,
        string memory _description,
        string memory _productData,
        string memory _logisticDetails
    ) public returns (uint256) {
        uint256 producerIndex = producerId.current();
        producerId.increment();

        producers[producerIndex] = Producer({
            creator: msg.sender,
            name: _name,
            place: _place,
            description: _description,
            productData: _productData,
            logisticDetails: _logisticDetails,
            validated: false,
            starred: false
        });

        emit ProducerRegistered(producerIndex, msg.sender);

        return producerIndex;
    }

    function registerTransporter(
        uint256 _pricePerKm,
        string memory _name,
        string memory _place,
        string memory _description,
        string memory _logisticCapability
    ) public returns (uint256) {
        uint256 transporterIndex = transporterId.current();
        transporterId.increment();

        transporters[transporterIndex] = Transporter({
            creator: msg.sender,
            pricePerKm: _pricePerKm,
            name: _name,
            place: _place,
            description: _description,
            logisticCapability: _logisticCapability,
            validated: false,
            starred: false
        });

        emit TransporterRegistered(transporterIndex, msg.sender);

        return transporterIndex;
    }

    function registerHuman(
        string memory _name,
        string memory _place,
        string memory _description,
        string memory _jobData,
        string memory _logisticDetails
    ) public returns (uint256) {
        uint256 humanIndex = humanId.current();
        humanId.increment();

        humans[humanIndex] = Human({
            creator: msg.sender,
            name: _name,
            place: _place,
            description: _description,
            jobData: _jobData,
            logisticDetails: _logisticDetails,
            validated: false,
            starred: false
        });

        emit HumanRegistered(humanIndex, msg.sender);

        return humanIndex;
    }

    function updateProducer(
        string memory _name,
        string memory _place,
        string memory _description,
        string memory _productData,
        string memory _logisticDetails,
        uint256 _producerIndex
    ) public returns (uint256) {
        Producer memory producerInIndex = producers[_producerIndex];
        require(
            msg.sender == owner() || msg.sender == producerInIndex.creator,
            "LCX_Register: Update must be done by Owner or Creator."
        );

        producers[_producerIndex] = Producer({
            creator: producerInIndex.creator,
            name: _name,
            place: _place,
            description: _description,
            productData: _productData,
            logisticDetails: _logisticDetails,
            validated: producerInIndex.validated,
            starred: producerInIndex.starred
        });

        return _producerIndex;
    }

    function updateTransporter(
        uint256 _pricePerKm,
        string memory _name,
        string memory _place,
        string memory _description,
        string memory _logisticCapability,
        uint256 _transporterIndex
    ) public returns (uint256) {
        Transporter memory transporterInIndex = transporters[_transporterIndex];
        require(
            msg.sender == owner() || msg.sender == transporterInIndex.creator,
            "LCX_Register: Update must be done by Owner or Creator."
        );

        transporters[_transporterIndex] = Transporter({
            creator: transporterInIndex.creator,
            pricePerKm: _pricePerKm,
            name: _name,
            place: _place,
            description: _description,
            logisticCapability: _logisticCapability,
            validated: transporterInIndex.validated,
            starred: transporterInIndex.starred
        });

        return _transporterIndex;
    }

    function updateHuman(
        string memory _name,
        string memory _place,
        string memory _description,
        string memory _jobData,
        string memory _logisticDetails,
        uint256 _humanIndex
    ) public returns (uint256) {
        Human memory humanInIndex = humans[_humanIndex];
        require(
            msg.sender == owner() || msg.sender == humanInIndex.creator,
            "LCX_Register: Update must be done by Owner or Creator."
        );

        humans[_humanIndex] = Human({
            creator: humanInIndex.creator,
            name: _name,
            place: _place,
            description: _description,
            jobData: _jobData,
            logisticDetails: _logisticDetails,
            validated: humanInIndex.validated,
            starred: humanInIndex.starred
        });

        return _humanIndex;
    }

    function changeProducerValidity(uint256 _producerId, bool _validated)
        public
        onlyOwner
    {
        producers[_producerId].validated = _validated;
        emit ProducerValidityChanged(_producerId, _validated);
    }

    function changeHumanValidity(uint256 _humanId, bool _validated)
        public
        onlyOwner
    {
        humans[_humanId].validated = _validated;
        emit HumanValidityChanged(_humanId, _validated);
    }

    function changeTransporterValidity(uint256 _transporterId, bool _validated)
        public
        onlyOwner
    {
        transporters[_transporterId].validated = _validated;
        emit TransporterValidityChanged(_transporterId, _validated);
    }


    function changeProducerStarred(uint256 _producerId, bool _starred)
        public
        onlyOwner
    {
        producers[_producerId].starred = _starred;
        emit ProducerStarredChanged(_producerId, _starred);
    }

    function changeHumanStarred(uint256 _humanId, bool _starred)
        public
        onlyOwner
    {
        humans[_humanId].starred = _starred;
        emit HumanStarredChanged(_humanId, _starred);
    }

    function changeTransporterStarred(uint256 _transporterId, bool _starred)
        public
        onlyOwner
    {
        transporters[_transporterId].starred = _starred;
        emit TransporterStarredChanged(_transporterId, _starred);
    }
}