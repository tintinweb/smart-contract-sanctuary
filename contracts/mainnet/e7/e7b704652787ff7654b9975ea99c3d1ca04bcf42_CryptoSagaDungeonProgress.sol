/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
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
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


/**
 * @title Claimable
 * @dev Extension for the Ownable contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
contract Claimable is Ownable {
  address public pendingOwner;

  /**
   * @dev Modifier throws if called by any account other than the pendingOwner.
   */
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

  /**
   * @dev Allows the current owner to set the pendingOwner address.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

  /**
   * @dev Allows the pendingOwner address to finalize the transfer.
   */
  function claimOwnership() onlyPendingOwner public {
    OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}


/**
 * @title AccessMint
 * @dev Adds grant/revoke functions to the contract.
 */
contract AccessMint is Claimable {

  // Access for minting new tokens.
  mapping(address => bool) private mintAccess;

  // Modifier for accessibility to define new hero types.
  modifier onlyAccessMint {
    require(msg.sender == owner || mintAccess[msg.sender] == true);
    _;
  }

  // @dev Grant acess to mint heroes.
  function grantAccessMint(address _address)
    onlyOwner
    public
  {
    mintAccess[_address] = true;
  }

  // @dev Revoke acess to mint heroes.
  function revokeAccessMint(address _address)
    onlyOwner
    public
  {
    mintAccess[_address] = false;
  }

}


/**
 * @title AccessDeploy
 * @dev Adds grant/revoke functions to the contract.
 */
contract AccessDeploy is Claimable {

  // Access for deploying heroes.
  mapping(address => bool) private deployAccess;

  // Modifier for accessibility to deploy a hero on a location.
  modifier onlyAccessDeploy {
    require(msg.sender == owner || deployAccess[msg.sender] == true);
    _;
  }

  // @dev Grant acess to deploy heroes.
  function grantAccessDeploy(address _address)
    onlyOwner
    public
  {
    deployAccess[_address] = true;
  }

  // @dev Revoke acess to deploy heroes.
  function revokeAccessDeploy(address _address)
    onlyOwner
    public
  {
    deployAccess[_address] = false;
  }

}


/**
 * @title CryptoSagaDungeonProgress
 * @dev Storage contract for progress of dungeons.
 */
contract CryptoSagaDungeonProgress is Claimable, AccessDeploy {

  // The progress of the player in dungeons.
  mapping(address => uint32[25]) public addressToProgress;

  // @dev Get progress.
  function getProgressOfAddressAndId(address _address, uint32 _id)
    external view
    returns (uint32)
  {
    var _progressList = addressToProgress[_address];
    return _progressList[_id];
  }

  // @dev Increment progress.
  function incrementProgressOfAddressAndId(address _address, uint32 _id)
    onlyAccessDeploy
    public
  {
    var _progressList = addressToProgress[_address];
    _progressList[_id]++;
    addressToProgress[_address] = _progressList;
  }
}