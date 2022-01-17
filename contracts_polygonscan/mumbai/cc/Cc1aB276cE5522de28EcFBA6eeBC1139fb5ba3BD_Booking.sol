// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import './Room.sol';

contract Booking is Room{
  using SafeMath for uint256;
  using Counters for Counters.Counter;

  struct BookingItem{
    uint roomId;
    uint bookingId;
    uint bookingDate;
    uint amountPaid;
    address payable tenant;
  }

  BookingItem[] public bookings;

  uint public totalBookings = 0;
  Counters.Counter private _bookingIds;

  event CheckoutSuccessfull(address indexed tenant, uint indexed roomId, uint indexed date);

  constructor() public {

  }

  function _registerBooking(uint _roomId, uint _bookingId,uint _amountPaid, address payable _tenant) internal{
    assert(_tenant != address(0));
    require(msg.sender != address(0));
    require(_bookingId != 0,"Booking ID cannot be zero");
    BookingItem memory newBooking = BookingItem(_roomId,_bookingId, block.timestamp,_amountPaid,_tenant);
    bookings.push(newBooking);
    totalBookings = totalBookings.add(1);
    emit RoomBooked(block.timestamp, msg.sender,msg.value,_roomId);
  }
  
  function bookRoom(uint _roomId,uint _numOfNights) public payable 
  nonReentrant 
  roomExists(_roomId) 
  isNotBooked(_roomId){
    RoomItem storage room = roomItemId[_roomId];
    uint totalPayableAmount = _numOfNights.mul(room.pricePerNight);
    require(msg.sender != room.user,"You cannot book your own room");
    require(msg.sender.balance >= totalPayableAmount,"Insufficient Funds");
    require(_numOfNights != 0,"Number of nights cannot be zero");
    require(msg.value == totalPayableAmount,"Please pay the booking fee based on number of nights to be spent");
    _bookingIds.increment();
    uint currentBookingId = _bookingIds.current();
    room.user.transfer(msg.value);
    _setBooked(_roomId);
    _registerBooking(room.id,currentBookingId,msg.value, payable(msg.sender));
    roomTenant[room.id] = msg.sender;
  }

  function checkOut(uint _roomId) public payable nonReentrant {
    RoomItem storage room = roomItemId[_roomId];
    require(room.isBooked == true,"Room is not booked");
    require(msg.sender == roomTenant[room.id],"You currently dont reside in this room");
    room.isBooked = false;
    emit CheckoutSuccessfull(msg.sender,room.id,block.timestamp);
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import './Hotel.sol';

contract Room is Hotel{
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    uint public totalRooms = 0;
    Counters.Counter private _roomIds;

    struct RoomItem{
        uint id;
        uint totalBeds;
        uint hotelId;
        uint pricePerNight;
        uint number;
        bool isBooked;
        address payable user;
        string name;
        string description;
    }

    RoomItem[] public rooms;

    mapping(address => RoomItem) public roomOwner;
    mapping(uint => address) public roomTenant; //who currently resides in the room
    mapping(uint => RoomItem) public roomItemId; //to help track a room item by it's id
    mapping(uint => bool) public existingRoomItem;
    mapping(string => bool) public existingRoomItemName;

    event NewRoomCreated(address indexed user, uint date, uint id);
    event RoomNightPriceSet(address indexed user, uint price, uint indexed date);
    event RoomBooked(uint date, address indexed tenant, uint indexed amountPaid, uint indexed roomId);

    constructor() public{

    }

    modifier roomExists(uint _roomId){
        require(existingRoomItem[_roomId] == true,"Room Does Not Exist");
        _;
    }

    modifier roomNameDoesNotExist(string memory _name) {
      require(bytes(_name).length > 0,"Please specify the room name");
      require(existingRoomItemName[_name] == false,"Room Name Exists");
      _;
    }

    modifier onlyRoomOwner(uint _roomId){
        require(msg.sender == roomItemId[_roomId].user,"You Do Not Own This Room");
        _;
    }

    modifier isNotBooked(uint _roomId){
      require(roomItemId[_roomId].isBooked == false,"Room is occupied");
      _;
    }

    function addRoom(uint _hotelId, uint _totalBeds, uint _pricePerNight, uint _number,string memory _name, string memory _description) public
    hotelExists(_hotelId)
    ownsHotel(_hotelId)
    roomNameDoesNotExist(_name)
    {
        require(msg.sender != address(0));
        require(_totalBeds != 0,"Number of beds cannot be zero");
        require(bytes(_description).length > 0,"Please specify the room description");
        require(_pricePerNight != 0,"The room night price cannot be zero");
        _roomIds.increment();
        uint currentRoomId = _roomIds.current();
        uint hotelId = hotelItemId[_hotelId].id;
        uint hotelItemTotalRooms = hotelItemId[_hotelId].totalRooms;
        roomItemId[currentRoomId]  = RoomItem(currentRoomId,_totalBeds,hotelId,_pricePerNight, _number, false, payable(msg.sender),_name,_description);
        rooms.push(roomItemId[currentRoomId]);
        roomOwner[msg.sender] = roomItemId[currentRoomId];
        hotelItemTotalRooms = hotelItemTotalRooms.add(1);
        totalRooms = totalRooms.add(1);
        existingRoomItem[currentRoomId] = true;
        existingRoomItemName[_name] = true;
        emit NewRoomCreated(msg.sender, block.timestamp, currentRoomId);
    }

    function getRoomBioData(uint _roomId) public view roomExists(_roomId) returns(
        uint _id,
        uint _numOfBeds,
        uint _hotelId,
        uint _pricePerNight,
        uint _number,
        bool _isBooked,
        address _user,
        string memory _name,
        string memory _description)
        {
            RoomItem storage room = roomItemId[_roomId];
            _id = room.id;
            _numOfBeds = room.totalBeds;
            _hotelId = room.hotelId;
            _pricePerNight = room.pricePerNight;
            _number = room.number;
            _isBooked = room.isBooked;
            _user = room.user;
            _name = room.name;
            _description = room.description;
        }

    function getName(uint _roomId) external virtual view override returns(string memory){
      return roomItemId[_roomId].name;
    }

    function getId(uint _roomId) external virtual view override returns(uint){
        return roomItemId[_roomId].id;
    }

    function setNightPrice(uint _roomId, uint _price) public onlyRoomOwner(_roomId){
        require(_price != 0,"price Cannot be zero");
        roomItemId[_roomId].pricePerNight = _price;
        emit RoomNightPriceSet(msg.sender, _price, block.timestamp);
    }

    function _setBooked(uint _roomId) internal roomExists(_roomId){
        roomItemId[_roomId].isBooked = true;
    }

    function listRooms() public view returns(RoomItem[] memory){
        return rooms;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface HotelBookingInterface{
    function getName(uint _index) external view returns(string memory);
    function getId(uint _index) external view returns(uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import './HotelBookingInterface.sol';

  /**
   * @title Hotel Booking 
   * @dev A simple Smart Contract for hotel management
   * @author Dickens Odera [email protected]
  **/

contract Hotel is Ownable, HotelBookingInterface, ReentrancyGuard {
  using SafeMath for uint256;
  using Counters for Counters.Counter;

  uint public totalHotels = 0; //the total number of the hotels
  uint public hotelListingFee = 0.00043 ether; //200 Ksh at the time of writing this smart contract
  Counters.Counter private _hotelIds; //hotel id to be inrecemented when a new hotel is created

  enum HOTEL_CATEGORY {CHAIN_HOTEL, MOTEL, RESORT, INN, ALL_SUITS, BOUTIGUE, EXTENDED_STAY} // hotel types
  HOTEL_CATEGORY public hotelCategory;
  HOTEL_CATEGORY constant DEFAULT_HOTEL_TYPE = HOTEL_CATEGORY.CHAIN_HOTEL; //default hotel type as it is the most common around the world

  //Group hotel data together in a Struct
  struct HotelItem{
    uint id;
    uint totalRooms;
    uint creationDate;
    string name;
    HOTEL_CATEGORY hotelCategory;
    string description;
    string locationAddress;
    address payable user;
    string imageHash;
  }

  HotelItem[] public hotelItems; //hotels array of the Hotel struct above
  mapping(uint => HotelItem) public hotelItemId;
  mapping(address => HotelItem) public hotelOwner; //the owner of this hotel
  mapping(uint => bool) public existingHotelItemId;
  mapping(string => bool) public existingHotelItemName;

  //events
  event HotelCreated(uint date, address indexed causer, uint indexed id);
  event HotelCategoryChanged(address indexed causer, uint date, HOTEL_CATEGORY indexed newCategory);
  event HotelOwnerChanged(address indexed causer, address indexed newOwner, uint date);
  event HotelListingFeeChanged(address indexed user, uint indexed date,uint indexed fee);

  constructor() public {

  }

  //ensure that the hotel exists in the blockchain before performing related transactions
  modifier hotelExists(uint _hotelId){
      require(existingHotelItemId[_hotelId] == true,"Hotel Does Not Exist");
      _;
  }

  //to avoid duplicate hotel names in the contract
  modifier hotelNameExists(string memory _name){
     require(existingHotelItemName[_name] == false,"Hotel Name Exists");
     require(bytes(_name).length > 0,"Please specify the hotel name");
     _;
  }

  //ensure the transactionsender owns this hotel before the transaction
  modifier ownsHotel(uint _hotelId){
      require(msg.sender == hotelItemId[_hotelId].user,"You Do Not Own This Hotel Item");
      _;
  }

  //check that this user address has hotel before adding a room
  modifier hasListedHotel(uint _hotelId){
      bool isListed = false;
        if(msg.sender == hotelItemId[_hotelId].user){
            isListed = true;
        }
      require(isListed == true,"Please List A Hotel Before Adding A Room");
      _;
  }

  function setListingFee(uint _fee) public onlyOwner{
    require(_fee != 0,"Listing Fee Cannot be zero");
    hotelListingFee = _fee;
    emit HotelListingFeeChanged(msg.sender,block.timestamp, _fee);
  }

  function setImageHash(uint hotelId, string memory imageHash) public{
    require(existingHotelItemId[hotelId] == true,"Hotel Does Not Exist");
    hotelItemId[hotelId].imageHash = imageHash;
  }

  function getImageHash(uint hotelId) public view returns(string memory _imageHash){
    require(existingHotelItemId[hotelId] == true,"Hotel Does Not Exist");
    return hotelItemId[hotelId].imageHash;
  }

  function addHotel(string memory _name,string memory _description, string memory _location, string memory _imageHash) public hotelNameExists(_name) nonReentrant payable{
    require(msg.sender != address(0));
    require(msg.value == hotelListingFee,"Invalid Listing Fee");
    require(bytes(_description).length > 0,"Please specify the hotel description");
    require(bytes(_location).length > 0,"Please specify the location of the hotel");
    _hotelIds.increment();
    uint currentHotelId = _hotelIds.current();
    hotelItemId[currentHotelId] = HotelItem(currentHotelId,0, block.timestamp, _name, DEFAULT_HOTEL_TYPE,_description, _location, payable(msg.sender), _imageHash);
    hotelItems.push(hotelItemId[currentHotelId]);
    hotelOwner[msg.sender] = hotelItemId[currentHotelId];
    totalHotels = totalHotels.add(1);
    existingHotelItemId[currentHotelId] = true;
    existingHotelItemName[_name] = true;
    payable(owner()).transfer(msg.value);
    emit HotelCreated(block.timestamp, msg.sender, currentHotelId);
  }

  function listAllHotels() public view returns(HotelItem[] memory){
      return hotelItems;
  }

  function getHotelBioData(uint _hotelId) public view hotelExists(_hotelId) returns(
      uint _id,
      uint _totalRooms,
      uint _date,
      string memory _name,
      string memory _description,
      string memory _location,
      HOTEL_CATEGORY _category,
      string memory _photo
      ){
    HotelItem storage hotelItem = hotelItemId[_hotelId];
    _id = hotelItem.id;
    _totalRooms = hotelItem.totalRooms;
    _date = hotelItem.creationDate;
    _name = hotelItem.name;
    _description = hotelItem.description;
    _location = hotelItem.locationAddress;
    _category = hotelItem.hotelCategory;
    _photo  = hotelItem.imageHash;
  }

  function changeHotelCategory(uint _hotelId, HOTEL_CATEGORY _category) public hotelExists(_hotelId) ownsHotel(_hotelId) {
     HotelItem storage hotelItem = hotelItemId[_hotelId];
     assert(_category != DEFAULT_HOTEL_TYPE);
     assert(_category != hotelItem.hotelCategory);
     hotelItem.hotelCategory = _category;
     emit HotelCategoryChanged(msg.sender, block.timestamp, _category);
  }

  function getName(uint _hotelId) external virtual view override hotelExists(_hotelId) returns(string memory){
      return hotelItemId[_hotelId].name;
  }

  function getId(uint _hotelId) external virtual view override hotelExists(_hotelId) returns(uint){
      return hotelItemId[_hotelId].id;
  }

  function changeHotelOwner(address payable _newOwner, uint _hotelId) public hotelExists(_hotelId) ownsHotel(_hotelId){
      require(msg.sender != _newOwner,"You are the rightful owner already");
      require(_newOwner != address(0),"Please specify a valid ETH address");
      hotelItemId[_hotelId].user = _newOwner;
      emit HotelOwnerChanged(msg.sender, _newOwner, block.timestamp);
  }
}