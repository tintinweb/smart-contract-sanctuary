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
library SafeMathUpgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12 <=0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./utils/MappedSinglyLinkedList.sol";

///@notice A registry to hold Contract addresses.  Underlying data structure is a singly linked list. 
contract AddressRegistry is Ownable {

    using MappedSinglyLinkedList for MappedSinglyLinkedList.Mapping;

    MappedSinglyLinkedList.Mapping internal addressList;

    /// @notice Emmitted when a contract has been added to the registry
    event AddressAdded(address indexed _address);
    
    /// @notice Emmitted when a contract has been removed to the registry
    event AddressRemoved(address indexed _address);

    /// @notice Emitted when all the registry addresses are cleared
    event AllAddressesCleared();

    /// @notice Storage field for what type of contract this Registry is storing 
    string public addressType;    

    /// @notice Contract constructor sets addressType, intializes list and transfers ownership
    /// @param _addressType The type of contracts stored in this registry 
    /// @param _owner The address to set as owner of the contract
    constructor(string memory _addressType, address _owner) Ownable() {
        addressType = _addressType;
        addressList.initialize();
        transferOwnership(_owner);
    }

    /// @notice Returns an array of all contract addresses in the linked list
    /// @return Array of contract addresses
    function getAddresses() view external returns(address[] memory) {
        return addressList.addressArray();
    } 

    /// @notice Adds addresses to the linked list. Will revert if the address is already in the list.  Can only be called by the Registry owner.
    /// @param _addresses Array of contract addresses to be added
    function addAddresses(address[] calldata _addresses) public onlyOwner {
        for(uint256 _address = 0; _address < _addresses.length; _address++ ){
            addressList.addAddress(_addresses[_address]);
            emit AddressAdded(_addresses[_address]);
        }
    }

    /// @notice Removes an address from the linked list. Can only be called by the Registry owner.
    /// @param _previousContract The address positionally located before the address that will be deleted. This may be the SENTINEL address if the list contains one contract address
    /// @param _address The address to remove from the linked list. 
    function removeAddress(address _previousContract, address _address) public onlyOwner {
        addressList.removeAddress(_previousContract, _address); 
        emit AddressRemoved(_address);
    } 

    /// @notice Removes every address from the list
    function clearAll() public onlyOwner {
        addressList.clearAll();
        emit AllAddressesCleared();
    }
    
    /// @notice Determines whether the list contains the given address
    /// @param _addr The address to check
    /// @return True if the address is contained, false otherwise.
    function contains(address _addr) public returns (bool) {
        return addressList.contains(_addr);
    }

    /// @notice Gives the address at the start of the list
    /// @return The address at the start of the list
    function start() public view returns (address) {
        return addressList.addressMap[MappedSinglyLinkedList.SENTINEL];
    }

    /// @notice Exposes the internal next() iterator
    /// @param current The current address
    /// @return Returns the next address in the list
    function next(address current) public view returns (address) {
        return addressList.addressMap[current];
    }
    
    /// @notice Exposes the end of the list
    /// @return The sentinel address
    function end() public pure returns (address) {
        return MappedSinglyLinkedList.SENTINEL;
    }

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.6;

/// @notice An efficient implementation of a singly linked list of addresses
/// @dev A mapping(address => address) tracks the 'next' pointer.  A special address called the SENTINEL is used to denote the beginning and end of the list.
library MappedSinglyLinkedList {

  /// @notice The special value address used to denote the end of the list
  address public constant SENTINEL = address(0x1);

  /// @notice The data structure to use for the list.
  struct Mapping {
    uint256 count;

    mapping(address => address) addressMap;
  }

  /// @notice Initializes the list.
  /// @dev It is important that this is called so that the SENTINEL is correctly setup.
  function initialize(Mapping storage self) internal {
    require(self.count == 0, "Already init");
    self.addressMap[SENTINEL] = SENTINEL;
  }

  function start(Mapping storage self) internal view returns (address) {
    return self.addressMap[SENTINEL];
  }

  function next(Mapping storage self, address current) internal view returns (address) {
    return self.addressMap[current];
  }

  function end(Mapping storage) internal pure returns (address) {
    return SENTINEL;
  }

  function addAddresses(Mapping storage self, address[] memory addresses) internal {
    for (uint256 i = 0; i < addresses.length; i++) {
      addAddress(self, addresses[i]);
    }
  }

  /// @notice Adds an address to the front of the list.
  /// @param self The Mapping struct that this function is attached to
  /// @param newAddress The address to shift to the front of the list
  function addAddress(Mapping storage self, address newAddress) internal {
    require(newAddress != SENTINEL && newAddress != address(0), "Invalid address");
    require(self.addressMap[newAddress] == address(0), "Already added");
    self.addressMap[newAddress] = self.addressMap[SENTINEL];
    self.addressMap[SENTINEL] = newAddress;
    self.count = self.count + 1;
  }

  /// @notice Removes an address from the list
  /// @param self The Mapping struct that this function is attached to
  /// @param prevAddress The address that precedes the address to be removed.  This may be the SENTINEL if at the start.
  /// @param addr The address to remove from the list.
  function removeAddress(Mapping storage self, address prevAddress, address addr) internal {
    require(addr != SENTINEL && addr != address(0), "Invalid address");
    require(self.addressMap[prevAddress] == addr, "Invalid prevAddress");
    self.addressMap[prevAddress] = self.addressMap[addr];
    delete self.addressMap[addr];
    self.count = self.count - 1;
  }

  /// @notice Determines whether the list contains the given address
  /// @param self The Mapping struct that this function is attached to
  /// @param addr The address to check
  /// @return True if the address is contained, false otherwise.
  function contains(Mapping storage self, address addr) internal view returns (bool) {
    return addr != SENTINEL && addr != address(0) && self.addressMap[addr] != address(0);
  }

  /// @notice Returns an address array of all the addresses in this list
  /// @dev Contains a for loop, so complexity is O(n) wrt the list size
  /// @param self The Mapping struct that this function is attached to
  /// @return An array of all the addresses
  function addressArray(Mapping storage self) internal view returns (address[] memory) {
    address[] memory array = new address[](self.count);
    uint256 count;
    address currentAddress = self.addressMap[SENTINEL];
    while (currentAddress != address(0) && currentAddress != SENTINEL) {
      array[count] = currentAddress;
      currentAddress = self.addressMap[currentAddress];
      count++;
    }
    return array;
  }

  /// @notice Removes every address from the list
  /// @param self The Mapping struct that this function is attached to
  function clearAll(Mapping storage self) internal {
    address currentAddress = self.addressMap[SENTINEL];
    while (currentAddress != address(0) && currentAddress != SENTINEL) {
      address nextAddress = self.addressMap[currentAddress];
      delete self.addressMap[currentAddress];
      currentAddress = nextAddress;
    }
    self.addressMap[SENTINEL] = SENTINEL;
    self.count = 0;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

import "@pooltogether/pooltogether-generic-registry/contracts/AddressRegistry.sol";

import "./interfaces/IPod.sol";
import "./interfaces/KeeperCompatibleInterface.sol";

/// @notice Contract implements Chainlink's Upkeep system interface, automating the upkeep of a registry of Pod contracts
contract PodsUpkeep is KeeperCompatibleInterface, Ownable, Pausable {

    using SafeMathUpgradeable for uint256;
    
    /// @notice Address of the registry of pods contract which require upkeep
    AddressRegistry public podsRegistry;

    /// @dev Fixed length of the last upkeep block number (multiple this by 8 to get the maximum number of pods for storage)
    uint8 constant PODS_PACKED_ARRAY_SIZE = 10;

    uint256[PODS_PACKED_ARRAY_SIZE] internal lastUpkeepBlockNumber;

    /// @notice Global upkeep interval expressed in blocks at which pods.batch() will be called
    uint256 public upkeepBlockInterval;    

    /// @notice Emitted when the upkeep block interval is updated
    event UpkeepBlockIntervalUpdated(uint upkeepBlockInterval);

    /// @notice Emitted when the upkeep max batch is updated
    event UpkeepBatchLimitUpdated(uint upkeepBatchLimit);
    
    /// @notice Emitted when the address registry is updated
    event PodsRegistryUpdated(AddressRegistry addressRegistry);

    /// @notice Maximum number of pods that performUpkeep can be called on
    uint256 public upkeepBatchLimit;

    /// @notice Contract Constructor. No initializer. 
    constructor(AddressRegistry _podsRegistry, address _owner, uint256 _upkeepBlockInterval, uint256 _upkeepBatchLimit) Ownable() {
        
        podsRegistry = _podsRegistry;
        emit PodsRegistryUpdated(_podsRegistry);

        transferOwnership(_owner);
        
        upkeepBlockInterval = _upkeepBlockInterval;
        emit UpkeepBlockIntervalUpdated(_upkeepBlockInterval);

        upkeepBatchLimit = _upkeepBatchLimit;
        emit UpkeepBatchLimitUpdated(_upkeepBatchLimit);
    }

    /// @notice Updates a 256 bit word with a 32 bit representation of a block number at a particular index
    /// @param _existingUpkeepBlockNumbers The 256 word
    /// @param _podIndex The index within that word (0 to 7)
    /// @param _value The block number value to be inserted
    function _updateLastBlockNumberForPodIndex(uint256 _existingUpkeepBlockNumbers, uint8 _podIndex, uint32 _value) internal pure returns (uint256) { 

        uint256 mask =  (type(uint32).max | uint256(0)) << (_podIndex * 32); // get a mask of all 1's at the pod index    
        uint256 updateBits =  (uint256(0) | _value) << (_podIndex * 32); // position value at index with 0's in every other position

        /* 
        (updateBits | ~mask) 
            negation of the mask is 0's at the location of the block number, 1's everywhere else
            OR'ing it with updateBits will give 1's everywhere else, block number intact
        
        (_existingUpkeepBlockNumbers | mask)
            OR'ing the exstingUpkeepBlockNumbers with mask will give maintain other blocknumber, put all 1's at podIndex
        
            finally AND'ing the two halves will filter through 1's if they are supposed to be there
        */
        return (updateBits | ~mask) & (_existingUpkeepBlockNumbers | mask); 
    }

    /// @notice Takes a 256 bit word and 0 to 7 index within and returns the uint32 value at that index
    /// @param _existingUpkeepBlockNumbers The 256 word
    /// @param _podIndex The index within that word
    function _readLastBlockNumberForPodIndex(uint256 _existingUpkeepBlockNumbers, uint8 _podIndex) internal pure returns (uint32) { 
  
        uint256 mask =  (type(uint32).max | uint256(0)) << (_podIndex * 32);
        return uint32((_existingUpkeepBlockNumbers & mask) >> (_podIndex * 32));
    }

    /// @notice Get the last Upkeep block number for a pod
    /// @param podIndex The position of the pod in the Registry
    function readLastBlockNumberForPodIndex(uint256 podIndex) public view returns (uint32) {
        
        uint256 wordIndex = podIndex / 8;
        return _readLastBlockNumberForPodIndex(lastUpkeepBlockNumber[wordIndex], uint8(podIndex % 8));
    }

    /// @notice Checks if Pods require upkeep. Call in a static manner every block by the Chainlink Upkeep network.
    /// @param checkData Not used in this implementation.
    /// @return upkeepNeeded as true if performUpkeep() needs to be called, false otherwise. performData returned empty. 
    function checkUpkeep(bytes calldata checkData) override external view returns (bool upkeepNeeded, bytes memory performData) {
        
        if(paused()) return (false, performData);   

        address[] memory pods = podsRegistry.getAddresses();
        uint256 _upkeepBlockInterval = upkeepBlockInterval;
        uint256 podsLength = pods.length;

        for(uint256 podWord = 0; podWord <= podsLength / 8; podWord++){

            uint256 _lastUpkeep = lastUpkeepBlockNumber[podWord]; // this performs the SLOAD
            for(uint256 i = 0; i + (podWord * 8) < podsLength; i++){
                
                uint32 podLastUpkeepBlockNumber = _readLastBlockNumberForPodIndex(_lastUpkeep, uint8(i));
                if(block.number > podLastUpkeepBlockNumber + _upkeepBlockInterval){
                    return (true, "");
                }
            }
        }       
        return (false, "");    
    }

    /// @notice Performs upkeep on the pods contract and updates lastUpkeepBlockNumbers
    /// @param performData Not used in this implementation.
    function performUpkeep(bytes calldata performData) override external whenNotPaused{
    
        address[] memory pods = podsRegistry.getAddresses();
        uint256 podsLength = pods.length;
        uint256 _batchLimit = upkeepBatchLimit;
        uint256 batchesPerformed = 0;

        for(uint8 podWord = 0; podWord <= podsLength / 8; podWord++){ // give word index
            
            uint256 _updateBlockNumber = lastUpkeepBlockNumber[podWord]; // this performs the SLOAD

            for(uint8 i = 0; i + (podWord * 8) < podsLength; i++){ // pod index within word
                
                if(batchesPerformed >= _batchLimit) {
                    break;
                }
                // get the 32 bit block number from the 256 bit word
                uint32 podLastUpkeepBlockNumber = _readLastBlockNumberForPodIndex(_updateBlockNumber, i);
                if(block.number > podLastUpkeepBlockNumber + upkeepBlockInterval) {
                    IPod(pods[i + (podWord * 8)]).drop();
                    batchesPerformed++;
                    // updated pod's most recent upkeep block number and store update to that 256 bit word
                    _updateBlockNumber = _updateLastBlockNumberForPodIndex(_updateBlockNumber, i, uint32(block.number));                   
                }
            }         
            lastUpkeepBlockNumber[podWord] = _updateBlockNumber; // update the entire 256 bit word at once
        }
    }

    /// @notice Updates the upkeepBlockInterval. Can only be called by the contract owner
    /// @param _upkeepBlockInterval The new upkeepBlockInterval (in blocks)
    function updateBlockUpkeepInterval(uint256 _upkeepBlockInterval) external onlyOwner {
        upkeepBlockInterval = _upkeepBlockInterval;
        emit UpkeepBlockIntervalUpdated(_upkeepBlockInterval);
    }

    /// @notice Updates the upkeep max batch. Can only be called by the contract owner
    /// @param _upkeepBatchLimit The new _upkeepBatchLimit
    function updateUpkeepBatchLimit(uint256 _upkeepBatchLimit) external onlyOwner {
        upkeepBatchLimit = _upkeepBatchLimit;
        emit UpkeepBatchLimitUpdated(_upkeepBatchLimit);
    }

    /// @notice Updates the address registry. Can only be called by the contract owner
    /// @param _addressRegistry The new podsRegistry
    function updatePodsRegistry(AddressRegistry _addressRegistry) external onlyOwner {
        podsRegistry = _addressRegistry;
        emit PodsRegistryUpdated(_addressRegistry);
    }

    /// @notice Pauses the contract. Only callable by owner.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses the contract. Only callable by owner.
    function unpause() external onlyOwner {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;


interface IPod {     
 
     function drop() external returns (uint256);
    

}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface KeeperCompatibleInterface {

  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(
    bytes calldata checkData
  )
    external
    returns (
      bool upkeepNeeded,
      bytes memory performData
    );
  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(
    bytes calldata performData
  ) external;
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "remappings": [],
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