pragma solidity ^0.4.24;

// File: contracts/AbstractBaseContract.sol

/**
 * @title AbstractBaseContract
 * @dev The basic abstract contract that every contract in the WT platform should implement.
 * The version and contract type are used to identify the correct interface
 * for each WT contract.
 */
contract AbstractBaseContract {

  // The hex-encoded version, follows the semantic standard MAJOR.MINOR.PATCH-EXTENSION
  // It should always match the version in package.json.
  bytes32 public version = bytes32("0.2.3");

  // The hex-encoded type of the contract, in all lowercase letters without any spaces.
  // It has to be defined in each contract that uses this interface.
  bytes32 public contractType;

}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: contracts/AbstractWTIndex.sol

/**
 * @title AbstractWTIndex
 * @dev Interface of WTIndex contract, inherits from OpenZeppelin&#39;s Ownable and
 * from WT&#39;s &#39;AbstractBaseContract&#39;.
 */
contract AbstractWTIndex is Ownable, AbstractBaseContract {
  address[] public hotels;
  mapping(address => uint) public hotelsIndex;
  mapping(address => address[]) public hotelsByManager;
  mapping(address => uint) public hotelsByManagerIndex;
  address public LifToken;

  function registerHotel(string dataUri) external;
  function deleteHotel(address hotel) external;
  function callHotel(address hotel, bytes data) external;
  function getHotelsLength() view public returns (uint);
  function getHotels() view public returns (address[]);
  function getHotelsByManager(address manager) view public returns (address[]);

  event HotelRegistered(address hotel, uint managerIndex, uint allIndex);
  event HotelDeleted(address hotel, uint managerIndex, uint allIndex);
  event HotelCalled(address hotel);
}

// File: openzeppelin-solidity/contracts/lifecycle/Destructible.sol

/**
 * @title Destructible
 * @dev Base contract that can be destroyed by owner. All funds in contract will be sent to the owner.
 */
contract Destructible is Ownable {

  constructor() public payable { }

  /**
   * @dev Transfers the current balance to the owner and terminates the contract.
   */
  function destroy() onlyOwner public {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) onlyOwner public {
    selfdestruct(_recipient);
  }
}

// File: contracts/hotel/AbstractHotel.sol

/**
 * @title AbstractHotel
 * @dev Interface of Hotel contract, inherits
 * from OpenZeppelin&#39;s `Destructible` and WT&#39;s &#39;AbstractBaseContract&#39;.
 */
contract AbstractHotel is Destructible, AbstractBaseContract {

  // Who owns this Hotel and can manage it.
  address public manager;
  // Arbitrary locator of the off-chain stored hotel data
  // This might be an HTTPS resource, IPFS hash, Swarm address...
  // This is intentionally generic.
  string public dataUri;
  // Number of block when the Hotel was created
  uint public created;


  function _editInfoImpl(string _dataUri) internal;

  /**
   * @dev `editInfo` Allows manager to change hotel&#39;s dataUri.
   * @param  _dataUri New dataUri pointer of this hotel
   */
  function editInfo(string _dataUri) onlyOwner public {
    _editInfoImpl(_dataUri);
  }
}

// File: contracts/hotel/Hotel.sol

/**
 * @title Hotel, contract for a Hotel registered in the WT network
 * @dev A contract that represents a hotel in the WT network. Inherits
 * from OpenZeppelin&#39;s `Destructible` and WT&#39;s &#39;AbstractBaseContract&#39;.
 */
contract Hotel is AbstractHotel {

  bytes32 public contractType = bytes32("hotel");

  // Who owns this Hotel and can manage it.
  address public manager;
  // Arbitrary locator of the off-chain stored hotel data
  // This might be an HTTPS resource, IPFS hash, Swarm address...
  // This is intentionally generic.
  string public dataUri;
  // Number of block when the Hotel was created
  uint public created;

  /**
   * @dev Constructor.
   * @param _manager address of hotel owner
   * @param _dataUri pointer to hotel data
   */
  constructor(address _manager, string _dataUri) public {
    require(_manager != address(0));
    require(bytes(_dataUri).length != 0);
    manager = _manager;
    dataUri = _dataUri;
    created = block.number;
  }

  function _editInfoImpl(string _dataUri) internal {
    require(bytes(_dataUri).length != 0);
    dataUri = _dataUri;
  }

  /**
   * @dev `destroy` allows the owner to delete the Hotel
   */
  function destroy() onlyOwner public {
    super.destroyAndSend(tx.origin);
  }

}

// File: contracts/WTIndex.sol

/**
 * @title WTIndex, registry of all hotels registered on WT
 * @dev The hotels are stored in an array and can be filtered by the owner
 * address. Inherits from OpenZeppelin&#39;s `Ownable` and `AbstractBaseContract`.
 */
contract WTIndex is AbstractWTIndex {

  bytes32 public contractType = bytes32("wtindex");

  // Array of addresses of `Hotel` contracts
  address[] public hotels;
  // Mapping of hotels position in the general hotel index
  mapping(address => uint) public hotelsIndex;

  // Mapping of the hotels indexed by manager&#39;s address
  mapping(address => address[]) public hotelsByManager;
  // Mapping of hotels position in the manager&#39;s indexed hotel index
  mapping(address => uint) public hotelsByManagerIndex;

  // Address of the LifToken contract
  address public LifToken;

  /**
   * @dev Event triggered every time hotel is registered
   */
  event HotelRegistered(address hotel, uint managerIndex, uint allIndex);
  /**
   * @dev Event triggered every time hotel is deleted
   */
  event HotelDeleted(address hotel, uint managerIndex, uint allIndex);
  /**
   * @dev Event triggered every time hotel is called
   */
  event HotelCalled(address hotel);

  /**
   * @dev Constructor. Creates the `WTIndex` contract
   */
	constructor() public {
		hotels.length ++;
	}

  /**
   * @dev `setLifToken` allows the owner of the contract to change the
   * address of the LifToken contract
   * @param _LifToken The new contract address
   */
  function setLifToken(address _LifToken) onlyOwner public {
    LifToken = _LifToken;
  }

  /**
   * @dev `registerHotel` Register new hotel in the index.
   * Emits `HotelRegistered` on success.
   * @param  dataUri Hotel&#39;s data pointer
   */
  function registerHotel(string dataUri) external {
    Hotel newHotel = new Hotel(msg.sender, dataUri);
    hotelsIndex[newHotel] = hotels.length;
    hotels.push(newHotel);
    hotelsByManagerIndex[newHotel] = hotelsByManager[msg.sender].length;
    hotelsByManager[msg.sender].push(newHotel);
    emit HotelRegistered(newHotel, hotelsByManagerIndex[newHotel], hotelsIndex[newHotel]);
	}

  /**
   * @dev `deleteHotel` Allows a manager to delete a hotel, i. e. call destroy
   * on the target Hotel contract. Emits `HotelDeleted` on success.
   * @param  hotel  Hotel&#39;s address
   */
  function deleteHotel(address hotel) external {
    // Ensure hotel address is valid
    require(hotel != address(0));
    // Ensure we know about the hotel at all
    require(hotelsIndex[hotel] != uint(0));
    // Ensure that the caller is the hotel&#39;s rightful owner
    // There may actually be a hotel on index zero, that&#39;s why we use a double check
    require(hotelsByManager[msg.sender][hotelsByManagerIndex[hotel]] != address(0));
    Hotel(hotel).destroy();
    uint index = hotelsByManagerIndex[hotel];
    uint allIndex = hotelsIndex[hotel];
    delete hotels[allIndex];
    delete hotelsIndex[hotel];
    delete hotelsByManager[msg.sender][index];
    delete hotelsByManagerIndex[hotel];
    emit HotelDeleted(hotel, index, allIndex);
	}

  /**
   * @dev `callHotel` Call hotel in the index, the hotel can only
   * be called by its manager. Effectively proxies a hotel call.
   * Emits HotelCalled on success.
   * @param  hotel Hotel&#39;s address
   * @param  data Encoded method call to be done on Hotel contract.
   */
	function callHotel(address hotel, bytes data) external {
    // Ensure hotel address is valid
    require(hotel != address(0));
    // Ensure we know about the hotel at all
    require(hotelsIndex[hotel] != uint(0));
    // Ensure that the caller is the hotel&#39;s rightful owner
    require(hotelsByManager[msg.sender][hotelsByManagerIndex[hotel]] != address(0));
		require(hotel.call(data));
    emit HotelCalled(hotel);
	}

  /**
   * @dev `getHotelsLength` get the length of the `hotels` array
   * @return {" ": "Length of the hotels array. Might contain zero addresses."}
   */
  function getHotelsLength() view public returns (uint) {
    return hotels.length;
  }

  /**
   * @dev `getHotels` get `hotels` array
   * @return {" ": "Array of hotel addresses. Might contain zero addresses."}
   */
  function getHotels() view public returns (address[]) {
    return hotels;
  }

  /**
   * @dev `getHotelsByManager` get all the hotels belonging to one manager
   * @param  manager Manager address
   * @return {" ": "Array of hotels belonging to one manager. Might contain zero addresses."}
   */
	function getHotelsByManager(address manager) view public returns (address[]) {
		return hotelsByManager[manager];
	}

}