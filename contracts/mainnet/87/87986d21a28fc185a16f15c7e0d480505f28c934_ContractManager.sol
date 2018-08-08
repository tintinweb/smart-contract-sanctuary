pragma solidity ^0.4.23;

// File: contracts/interfaces/ContractManagerInterface.sol

/**
 * @title Contract Manager Interface
 * @author Bram Hoven
 * @notice Interface for communicating with the contract manager
 */
interface ContractManagerInterface {
  /**
   * @notice Triggered when contract is added
   * @param _address Address of the new contract
   * @param _contractName Name of the new contract
   */
  event ContractAdded(address indexed _address, string _contractName);

  /**
   * @notice Triggered when contract is removed
   * @param _contractName Name of the contract that is removed
   */
  event ContractRemoved(string _contractName);

  /**
   * @notice Triggered when contract is updated
   * @param _oldAddress Address where the contract used to be
   * @param _newAddress Address where the new contract is deployed
   * @param _contractName Name of the contract that has been updated
   */
  event ContractUpdated(address indexed _oldAddress, address indexed _newAddress, string _contractName);

  /**
   * @notice Triggered when authorization status changed
   * @param _address Address who will gain or lose authorization to _contractName
   * @param _authorized Boolean whether or not the address is authorized
   * @param _contractName Name of the contract
   */
  event AuthorizationChanged(address indexed _address, bool _authorized, string _contractName);

  /**
   * @notice Check whether the accessor is authorized to access that contract
   * @param _contractName Name of the contract that is being accessed
   * @param _accessor Address who wants to access that contract
   */
  function authorize(string _contractName, address _accessor) external view returns (bool);

  /**
   * @notice Add a new contract to the manager
   * @param _contractName Name of the new contract
   * @param _address Address of the new contract
   */
  function addContract(string _contractName, address _address) external;

  /**
   * @notice Get a contract by its name
   * @param _contractName Name of the contract
   */
  function getContract(string _contractName) external view returns (address _contractAddress);

  /**
   * @notice Remove an existing contract
   * @param _contractName Name of the contract that will be removed
   */
  function removeContract(string _contractName) external;

  /**
   * @notice Update an existing contract (changing the address)
   * @param _contractName Name of the existing contract
   * @param _newAddress Address where the new contract is deployed
   */
  function updateContract(string _contractName, address _newAddress) external;

  /**
   * @notice Change whether an address is authorized to use a specific contract or not
   * @param _contractName Name of the contract to which the accessor will gain authorization or not
   * @param _authorizedAddress Address which will have its authorisation status changed
   * @param _authorized Boolean whether the address will have access or not
   */
  function setAuthorizedContract(string _contractName, address _authorizedAddress, bool _authorized) external;
}

// File: contracts/ContractManager.sol

/**
 * @title Contract Manager
 * @author Bram Hoven
 * @notice Contract whom manages every other contract connected to this project and the authorization
 */
contract ContractManager is ContractManagerInterface {
  // Mapping of all contracts and their name
  mapping(string => address) private contracts;
  // Mapping of all contracts and who has access to them
  mapping(string => mapping(address => bool)) private authorization;

  /**
   * @notice Triggered when contract is added
   * @param _address Address of the new contract
   * @param _contractName Name of the new contract
   */
  event ContractAdded(address indexed _address, string _contractName);

  /**
   * @notice Triggered when contract is removed
   * @param _contractName Name of the contract that is removed
   */
  event ContractRemoved(string _contractName);

  /**
   * @notice Triggered when contract is updated
   * @param _oldAddress Address where the contract used to be
   * @param _newAddress Address where the new contract is deployed
   * @param _contractName Name of the contract that has been updated
   */
  event ContractUpdated(address indexed _oldAddress, address indexed _newAddress, string _contractName);

  /**
   * @notice Triggered when authorization status changed
   * @param _address Address who will gain or lose authorization to _contractName
   * @param _authorized Boolean whether or not the address is authorized
   * @param _contractName Name of the contract
   */
  event AuthorizationChanged(address indexed _address, bool _authorized, string _contractName);

  /**
   * @dev Throws when sender does not match contract name
   * @param _contractName Name of the contract the sender is checked against
   */
  modifier onlyRegisteredContract(string _contractName) {
    require(contracts[_contractName] == msg.sender);
    _;
  }

  /**
   * @dev Throws when sender is not owner of contract manager
   * @param _contractName Name of the contract to check the _accessor against
   * @param _accessor Address that wants to access this specific contract
   */
  modifier onlyContractOwner(string _contractName, address _accessor) {
    require(contracts[_contractName] == msg.sender || contracts[_contractName] == address(this));
    require(_accessor != address(0));
    require(authorization[_contractName][_accessor] == true);
    _;
  }

  /**
   * @notice Constructor for creating the contract manager
   */
  constructor() public {
    contracts["ContractManager"] = address(this);
    authorization["ContractManager"][msg.sender] = true;
  }

  /**
   * @notice Check whether the accessor is authorized to access that contract
   * @param _contractName Name of the contract that is being accessed
   * @param _accessor Address who wants to access that contract
   */
  function authorize(string _contractName, address _accessor) external onlyContractOwner(_contractName, _accessor) view returns (bool) {
    return true;
  }

  /**
   * @notice Add a new contract to the manager
   * @param _contractName Name of the new contract
   * @param _address Address of the new contract
   */
  function addContract(string _contractName, address _address) external  onlyContractOwner("ContractManager", msg.sender) {
    bytes memory contractNameBytes = bytes(_contractName);

    require(contractNameBytes.length != 0);
    require(contracts[_contractName] == address(0));
    require(_address != address(0));

    contracts[_contractName] = _address;

    emit ContractAdded(_address, _contractName);
  }

  /**
   * @notice Get a contract by its name
   * @param _contractName Name of the contract
   */
  function getContract(string _contractName) external view returns (address _contractAddress) {
    require(contracts[_contractName] != address(0));

    _contractAddress = contracts[_contractName];

    return _contractAddress;
  }

  /**
   * @notice Remove an existing contract
   * @param _contractName Name of the contract that will be removed
   */
  function removeContract(string _contractName) external onlyContractOwner("ContractManager", msg.sender) {
    bytes memory contractNameBytes = bytes(_contractName);

    require(contractNameBytes.length != 0);
    // Should not be able to remove this contract
    require(keccak256(_contractName) != keccak256("ContractManager"));
    require(contracts[_contractName] != address(0));
    
    delete contracts[_contractName];

    emit ContractRemoved(_contractName);
  }

  /**
   * @notice Update an existing contract (changing the address)
   * @param _contractName Name of the existing contract
   * @param _newAddress Address where the new contract is deployed
   */
  function updateContract(string _contractName, address _newAddress) external onlyContractOwner("ContractManager", msg.sender) {
    bytes memory contractNameBytes = bytes(_contractName);

    require(contractNameBytes.length != 0);
    require(contracts[_contractName] != address(0));
    require(_newAddress != address(0));

    address oldAddress = contracts[_contractName];
    contracts[_contractName] = _newAddress;

    emit ContractUpdated(oldAddress, _newAddress, _contractName);
  }

  /**
   * @notice Change whether an address is authorized to use a specific contract or not
   * @param _contractName Name of the contract to which the accessor will gain authorization or not
   * @param _authorizedAddress Address which will have its authorisation status changed
   * @param _authorized Boolean whether the address will have access or not
   */
  function setAuthorizedContract(string _contractName, address _authorizedAddress, bool _authorized) external onlyContractOwner("ContractManager", msg.sender) {
    bytes memory contractNameBytes = bytes(_contractName);

    require(contractNameBytes.length != 0);
    require(_authorizedAddress != address(0));
    require(authorization[_contractName][_authorizedAddress] != _authorized);
    
    authorization[_contractName][_authorizedAddress] = _authorized;

    emit AuthorizationChanged(_authorizedAddress, _authorized, _contractName);
  }
}