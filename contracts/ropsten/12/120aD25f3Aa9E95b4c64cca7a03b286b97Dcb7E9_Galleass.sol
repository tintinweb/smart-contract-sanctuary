pragma solidity ^0.4.18;

/*

  https://galleass.io
  by Austin Thomas Griffith
    austin@concurrence.io
    https://austingriffith.com/portfolio/galleass/
  
  The Galleass contract contains a reference to all contracts in the fleet and
  provides a method of upgrading/replacing old contract versions.

  Galleass follows a Predecessor system where previous deployments of this
  contract will forward on to their decendants.

  Galleass contains an authentication system where contracts are allowed to do
  specific actions based on the permissions they are assigned.

  Finally, there is the notion of building, staging, and production modes. Once
  the contract is set to production, it is fully decentralized and not even the
  owner account can make changes.

*/






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



/**
 * @title Contactable token
 * @dev Basic version of a contactable contract, allowing the owner to provide a string with their
 * contact information.
 */
contract Contactable is Ownable {

  string public contactInformation;

  /**
    * @dev Allows the owner to set a string with their contact information.
    * @param info The contact information to attach to the contract.
    */
  function setContactInformation(string info) onlyOwner public {
    contactInformation = info;
  }
}


contract Staged is Ownable {

  enum StagedMode {
    PAUSED,
    BUILD,
    STAGE,
    PRODUCTION
  }

  StagedMode public stagedMode;

  function Staged() public {
    stagedMode=StagedMode.BUILD;
  }

  modifier isBuilding() {
    require(stagedMode == StagedMode.BUILD);
    _;
  }

  modifier isStaging() {
    require(stagedMode == StagedMode.STAGE);
    _;
  }

  modifier isNotProduction() {
    require(stagedMode != StagedMode.PRODUCTION);
    _;
  }

  modifier isNotPaused() {
    require(stagedMode != StagedMode.PAUSED);
    _;
  }

  function pause() isNotProduction onlyOwner public returns (bool) {
    stagedMode=StagedMode.PAUSED;
  }

  function stage() isNotProduction onlyOwner public returns (bool) {
    stagedMode=StagedMode.STAGE;
  }

  function build() isNotProduction onlyOwner public returns (bool) {
    stagedMode=StagedMode.BUILD;
  }

  function destruct() isNotProduction onlyOwner public returns (bool) {
    selfdestruct(owner);
  }

  function production() isStaging onlyOwner public returns (bool) {
    stagedMode=StagedMode.PRODUCTION;
  }

}


contract Predecessor is Ownable, Staged{
    function Predecessor() public {}
    address public descendant;
    function setDescendant(address _descendant) onlyOwner isNotProduction public {
      descendant=_descendant;
    }
    modifier hasNoDescendant() {
      require(descendant == address(0));
      _;
    }
}


contract Galleass is Staged, Contactable, Predecessor{

  string public constant name = "Galleass";
  string public constant author = "Austin Thomas Griffith austin@concurrence.io";

  event UpgradeContract(address _contractAddress,address _descendant,address _whoDid);
  event SetContract(bytes32 _name,address _contractAddress,address _whoDid);
  event SetPermission(address _account,bytes32 _permission,bool _value);

  mapping(bytes32 => address) contracts;
  mapping(address => mapping(bytes32 => bool)) permission;

  function Galleass(string _contact) public { setContactInformation(_contact); }

  function upgradeContract(address _contract) onlyOwner isBuilding public returns (bool) {
    Galleasset(_contract).upgradeGalleass(descendant);
    UpgradeContract(_contract,descendant,msg.sender);
    return true;
  }

  function setContract(bytes32 _name,address _contract) onlyOwner isBuilding public returns (bool) {
    contracts[_name]=_contract;
    SetContract(_name,_contract,msg.sender);
    return true;
  }

  function setPermission(address _contract, bytes32 _permission, bool _value) onlyOwner isBuilding public returns (bool) {
    permission[_contract][_permission]=_value;
    SetPermission(_contract,_permission,_value);
    return true;
  }

  function getContract(bytes32 _name) public view returns (address) {
    if(descendant!=address(0)) {
      return Galleass(descendant).getContract(_name);
    }else{
      return contracts[_name];
    }
  }

  function hasPermission(address _contract, bytes32 _permission) public view returns (bool) {
    if(descendant!=address(0)) {
      return Galleass(descendant).hasPermission(_contract,_permission);
    }else{
      return permission[_contract][_permission];
    }
  }

  function withdraw(uint256 _amount) public onlyOwner returns (bool) {
    require(address(this).balance >= _amount);
    assert(owner.send(_amount));
    return true;
  }
  function withdrawToken(address _token,uint256 _amount) public onlyOwner returns (bool) {
    StandardTokenInterface token = StandardTokenInterface(_token);
    token.transfer(msg.sender,_amount);
    return true;
  }

}

contract Galleasset {
  function upgradeGalleass(address _galleass) public returns (bool) { }
}

contract StandardTokenInterface {
  function transfer(address _to, uint256 _value) public returns (bool) { }
}