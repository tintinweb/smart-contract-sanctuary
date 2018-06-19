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

// File: contracts/interfaces/MemberManagerInterface.sol

/**
 * @title Member Manager Interface
 * @author Bram Hoven
 */
interface MemberManagerInterface {
  /**
   * @notice Triggered when member is added
   * @param member Address of newly added member
   */
  event MemberAdded(address indexed member);

  /**
   * @notice Triggered when member is removed
   * @param member Address of removed member
   */
  event MemberRemoved(address indexed member);

  /**
   * @notice Triggered when member has bought tokens
   * @param member Address of member
   * @param tokensBought Amount of tokens bought
   * @param tokens Amount of total tokens bought by member
   */
  event TokensBought(address indexed member, uint256 tokensBought, uint256 tokens);

  /**
   * @notice Remove a member from this contract
   * @param _member Address of member that will be removed
   */
  function removeMember(address _member) external;

  /**
   * @notice Add to the amount this member has bought
   * @param _member Address of the corresponding member
   * @param _amountBought Amount of tokens this member has bought
   */
  function addAmountBoughtAsMember(address _member, uint256 _amountBought) external;
}

// File: zeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: contracts/MemberManager.sol

/**
 * @title Member Manager
 * @author Bram Hoven
 * @notice Stores a list of member which can be used for something like authorization
 */
contract MemberManager is MemberManagerInterface {
  using SafeMath for uint256;
  
  // Map containing every member
  mapping(address => bool) public members;
  // Map containing amount of tokens bought
  mapping(address => uint256) public bought;
  // List containing all members
  address[] public memberKeys;

  // Name of this contract
  string public contractName;
  // Contract Manager
  ContractManagerInterface internal contractManager;

  /**
   * @notice Triggered when member is added
   * @param member Address of newly added member
   */
  event MemberAdded(address indexed member);

  /**
   * @notice Triggered when member is removed
   * @param member Address of removed member
   */
  event MemberRemoved(address indexed member);

  /**
   * @notice Triggered when member has bought tokens
   * @param member Address of member
   * @param tokensBought Amount of tokens bought
   * @param tokens Amount of total tokens bought by member
   */
  event TokensBought(address indexed member, uint256 tokensBought, uint256 tokens);

  /**
   * @notice Constructor for creating member manager
   * @param _contractName Name of this contract for lookup in contract manager
   * @param _contractManager Address where the contract manager is located
   */
  constructor(string _contractName, address _contractManager) public {
    contractName = _contractName;
    contractManager = ContractManagerInterface(_contractManager);
  }

  /**
   * @notice Add a member to this contract
   * @param _member Address of the new member
   */
  function _addMember(address _member) internal {
    require(contractManager.authorize(contractName, msg.sender));

    members[_member] = true;
    memberKeys.push(_member);

    emit MemberAdded(_member);
  }

  /**
   * @notice Remove a member from this contract
   * @param _member Address of member that will be removed
   */
  function removeMember(address _member) external {
    require(contractManager.authorize(contractName, msg.sender));
    require(members[_member] == true);

    delete members[_member];

    for (uint256 i = 0; i < memberKeys.length; i++) {
      if (memberKeys[i] == _member) {
        delete memberKeys[i];
        break;
      }
    }

    emit MemberRemoved(_member);
  }

  /**
   * @notice Add to the amount this member has bought
   * @param _member Address of the corresponding member
   * @param _amountBought Amount of tokens this member has bought
   */
  function addAmountBoughtAsMember(address _member, uint256 _amountBought) external {
    require(contractManager.authorize(contractName, msg.sender));
    require(_amountBought != 0);

    if(!members[_member]) {
      _addMember(_member);
    }

    bought[_member] = bought[_member].add(_amountBought);

    emit TokensBought(_member, _amountBought, bought[_member]);
  }
}