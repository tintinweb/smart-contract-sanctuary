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
        return addressList.start();
    }

    /// @notice Exposes the internal next() iterator
    /// @param current The current address
    /// @return Returns the next address in the list
    function next(address current) public view returns (address) {
        return addressList.next(current);
    }
    
    /// @notice Exposes the end of the list
    /// @return The sentinel address
    function end() public view returns (address) {
        return addressList.end();
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
pragma experimental ABIEncoderV2;

import "./interfaces/KeeperCompatibleInterface.sol";
import "./interfaces/PeriodicPrizeStrategyInterface.sol";
import "./interfaces/PrizePoolRegistryInterface.sol";
import "./interfaces/PrizePoolInterface.sol";
import "./utils/SafeAwardable.sol";

import "@pooltogether/pooltogether-generic-registry/contracts/AddressRegistry.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

///@notice Contract implements Chainlink's Upkeep system interface, automating the upkeep of PrizePools in the associated registry. 
contract PrizeStrategyUpkeep is KeeperCompatibleInterface, Ownable {

    /// @notice Ensures the target address is a prize strategy (has both canStartAward and canCompleteAward)
    using SafeAwardable for address;

    /// @notice Stores the maximum number of prize strategies to upkeep. 
    AddressRegistry public prizePoolRegistry;

    /// @notice Stores the maximum number of prize strategies to upkeep. 
    /// @dev Set accordingly to prevent out-of-gas transactions during calls to performUpkeep
    uint256 public upkeepBatchSize;

    /// @notice Stores the last upkeep block number
    uint256 public upkeepLastUpkeepBlockNumber;

    /// @notice Stores the minimum block interval between permitted performUpkeep() calls
    uint256 public upkeepMinimumBlockInterval;

    /// @notice Emitted when the upkeepBatchSize has been changed
    event UpkeepBatchSizeUpdated(uint256 upkeepBatchSize);

    /// @notice Emitted when the prize pool registry has been changed
    event UpkeepPrizePoolRegistryUpdated(AddressRegistry prizePoolRegistry);

    /// @notice Emitted when the Upkeep Minimum Block interval is updated
    event UpkeepMinimumBlockIntervalUpdated(uint256 upkeepMinimumBlockInterval);

    /// @notice Emitted when the Upkeep has been performed
    event UpkeepPerformed(uint256 startAwardsPerformed, uint256 completeAwardsPerformed);


    constructor(AddressRegistry _prizePoolRegistry, uint256 _upkeepBatchSize, uint256 _upkeepMinimumBlockInterval) public Ownable() {
        prizePoolRegistry = _prizePoolRegistry;
        emit UpkeepPrizePoolRegistryUpdated(_prizePoolRegistry);

        upkeepBatchSize = _upkeepBatchSize;
        emit UpkeepBatchSizeUpdated(_upkeepBatchSize);

        upkeepMinimumBlockInterval = _upkeepMinimumBlockInterval;
        emit UpkeepMinimumBlockIntervalUpdated(_upkeepMinimumBlockInterval);
    }


    /// @notice Checks if PrizePools require upkeep. Call in a static manner every block by the Chainlink Upkeep network.
    /// @param checkData Not used in this implementation.
    /// @return upkeepNeeded as true if performUpkeep() needs to be called, false otherwise. performData returned empty. 
    function checkUpkeep(bytes calldata checkData) external view override returns (bool upkeepNeeded, bytes memory performData) {

        if(block.number < upkeepLastUpkeepBlockNumber + upkeepMinimumBlockInterval){
            return (false, performData);
        }
        
        address[] memory prizePools = prizePoolRegistry.getAddresses();

        // check if canStartAward()
        for(uint256 pool = 0; pool < prizePools.length; pool++){
            address prizeStrategy = PrizePoolInterface(prizePools[pool]).prizeStrategy();
            if(prizeStrategy.canStartAward()){
                return (true, performData);
            } 
        }
        // check if canCompleteAward()
        for(uint256 pool = 0; pool < prizePools.length; pool++){
            address prizeStrategy = PrizePoolInterface(prizePools[pool]).prizeStrategy();
            if(prizeStrategy.canCompleteAward()){
                return (true, performData);
            } 
        }
        return (false, performData);
    }
    
    /// @notice Performs upkeep on the prize pools. 
    /// @param performData Not used in this implementation.
    function performUpkeep(bytes calldata performData) external override {

        uint256 _upkeepLastUpkeepBlockNumber = upkeepLastUpkeepBlockNumber; // SLOAD
        require(block.number > _upkeepLastUpkeepBlockNumber + upkeepMinimumBlockInterval, "PrizeStrategyUpkeep::minimum block interval not reached");

        address[] memory prizePools = prizePoolRegistry.getAddresses();

      
        uint256 batchCounter = upkeepBatchSize; //counter for batch

        uint256 poolIndex = 0;
        uint256 startAwardCounter = 0;
        uint256 completeAwardCounter = 0;

        uint256 updatedUpkeepBlockNumber;

        while(batchCounter > 0 && poolIndex < prizePools.length){
            
            address prizeStrategy = PrizePoolInterface(prizePools[poolIndex]).prizeStrategy();
            
            if(prizeStrategy.canStartAward()){
                PeriodicPrizeStrategyInterface(prizeStrategy).startAward();
                startAwardCounter++;
                batchCounter--;
            }
            else if(prizeStrategy.canCompleteAward()){
                PeriodicPrizeStrategyInterface(prizeStrategy).completeAward();       
                completeAwardCounter++;
                batchCounter--;
            }
            poolIndex++;            
        }
        
        if(startAwardCounter > 0 || completeAwardCounter > 0){
            updatedUpkeepBlockNumber = block.number;
        }

        // update if required
        if(_upkeepLastUpkeepBlockNumber != updatedUpkeepBlockNumber){
            upkeepLastUpkeepBlockNumber = updatedUpkeepBlockNumber; //SSTORE
            emit UpkeepPerformed(startAwardCounter, completeAwardCounter);
        }
  
    }


    /// @notice Updates the upkeepBatchSize which is set to prevent out of gas situations
    /// @param _upkeepBatchSize Amount upkeepBatchSize will be set to
    function updateUpkeepBatchSize(uint256 _upkeepBatchSize) external onlyOwner {
        upkeepBatchSize = _upkeepBatchSize;
        emit UpkeepBatchSizeUpdated(_upkeepBatchSize);
    }


    /// @notice Updates the prize pool registry
    /// @param _prizePoolRegistry New registry address
    function updatePrizePoolRegistry(AddressRegistry _prizePoolRegistry) external onlyOwner {
        prizePoolRegistry = _prizePoolRegistry;
        emit UpkeepPrizePoolRegistryUpdated(_prizePoolRegistry);
    }


    /// @notice Updates the upkeep minimum interval blocks
    /// @param _upkeepMinimumBlockInterval New upkeepMinimumBlockInterval
    function updateUpkeepMinimumBlockInterval(uint256 _upkeepMinimumBlockInterval) external onlyOwner {
        upkeepMinimumBlockInterval = _upkeepMinimumBlockInterval;
        emit UpkeepMinimumBlockIntervalUpdated(_upkeepMinimumBlockInterval);
    }

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface PeriodicPrizeStrategyInterface {
  function startAward() external;
  function completeAward() external;
  function canStartAward() external view returns (bool);
  function canCompleteAward() external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface PrizePoolInterface {
    function prizeStrategy() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface PrizePoolRegistryInterface {
    function getPrizePools() external view returns(address[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "../interfaces/PeriodicPrizeStrategyInterface.sol";


///@notice Wrapper library for address that checks that the address supports canStartAward() and canCompleteAward() before calling
library SafeAwardable{

    ///@return canCompleteAward returns true if the function is supported AND can be completed 
    function canCompleteAward(address self) internal view returns (bool canCompleteAward){
        if(supportsFunction(self, PeriodicPrizeStrategyInterface.canCompleteAward.selector)){
            return PeriodicPrizeStrategyInterface(self).canCompleteAward();      
        }
        return false;
    }

    ///@return canStartAward returns true if the function is supported AND can be started, false otherwise
    function canStartAward(address self) internal view returns (bool canStartAward){
        if(supportsFunction(self, PeriodicPrizeStrategyInterface.canStartAward.selector)){
            return PeriodicPrizeStrategyInterface(self).canStartAward();
        }
        return false;
    }
    
    ///@param selector is the function selector to check against
    ///@return success returns true if function is implemented, false otherwise
    function supportsFunction(address self, bytes4 selector) internal view returns (bool success){
        bytes memory encodedParams = abi.encodeWithSelector(selector);
        (bool success, bytes memory result) = self.staticcall{ gas: 30000 }(encodedParams);
        if (result.length < 32){
            return (false);
        }
        if(!success && result.length > 0){
            revert(string(result));
        }
        return (success);
    }
}

