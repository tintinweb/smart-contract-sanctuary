pragma solidity ^0.4.23;


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

contract BBODServiceRegistry is Ownable {

  //1. Manager
  //2. CustodyStorage
  mapping(uint => address) public registry;

    constructor(address _owner) {
        owner = _owner;
    }

  function setServiceRegistryEntry (uint key, address entry) external onlyOwner {
    registry[key] = entry;
  }
}

contract CustodyStorage {

  BBODServiceRegistry public bbodServiceRegistry;

  mapping(address => bool) public custodiesMap;

  //Number of all custodies in the contract
  uint public custodyCounter = 0;

  address[] public custodiesArray;

  event CustodyRemoved(address indexed custody);

  constructor(address _serviceRegistryAddress) public {
    bbodServiceRegistry = BBODServiceRegistry(_serviceRegistryAddress);
  }

  modifier onlyManager() {
    require(msg.sender == bbodServiceRegistry.registry(1));
    _;
  }

  function addCustody(address _custody) external onlyManager {
    custodiesMap[_custody] = true;
    custodiesArray.push(_custody);
    custodyCounter++;
  }

  function removeCustody(address _custodyAddress, uint _arrayIndex) external onlyManager {
    require(custodiesArray[_arrayIndex] == _custodyAddress);

    if (_arrayIndex == custodyCounter - 1) {
      //Removing last custody
      custodiesMap[_custodyAddress] = false;
      emit CustodyRemoved(_custodyAddress);
      custodyCounter--;
      return;
    }

    custodiesMap[_custodyAddress] = false;
    //Overwriting deleted custody with the last custody in the array
    custodiesArray[_arrayIndex] = custodiesArray[custodyCounter - 1];
    custodyCounter--;

    emit CustodyRemoved(_custodyAddress);
  }
}