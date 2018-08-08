pragma solidity ^0.4.18;

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

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

// File: openzeppelin-solidity/contracts/ownership/HasNoEther.sol

/**
 * @title Contracts that should not own Ether
 * @author Remco Bloemen <remco@2π.com>
 * @dev This tries to block incoming ether to prevent accidental loss of Ether. Should Ether end up
 * in the contract, it will allow the owner to reclaim this ether.
 * @notice Ether can still be send to this contract by:
 * calling functions labeled `payable`
 * `selfdestruct(contract_address)`
 * mining directly to the contract address
*/
contract HasNoEther is Ownable {

  /**
  * @dev Constructor that rejects incoming Ether
  * @dev The `payable` flag is added so we can access `msg.value` without compiler warning. If we
  * leave out payable, then Solidity will allow inheriting contracts to implement a payable
  * constructor. By doing it this way we prevent a payable constructor from working. Alternatively
  * we could use assembly to access msg.value.
  */
  function HasNoEther() public payable {
    require(msg.value == 0);
  }

  /**
   * @dev Disallows direct send by settings a default function without the `payable` flag.
   */
  function() external {
  }

  /**
   * @dev Transfer all Ether held by the contract to the owner.
   */
  function reclaimEther() external onlyOwner {
    assert(owner.send(this.balance));
  }
}

// File: contracts/TweedentityRegistry.sol

interface ManagerInterface {

  function paused()
  public
  constant returns (bool);


  function claimer()
  public
  constant returns (address);

  function totalStores()
  public
  constant returns (uint);


  function getStoreAddress(
    string _appNickname
  )
  external
  constant returns (address);


  function getStoreAddressById(
    uint _appId
  )
  external
  constant returns (address);


  function isStoreActive(
    uint _appId
  )
  public
  constant returns (bool);

}

interface ClaimerInterface {

  function manager()
  public
  constant returns (address);
}


interface StoreInterface {

  function appSet()
  public
  constant returns (bool);


  function manager()
  public
  constant returns (address);

}


/**
 * @title TweedentityRegistry
 * @author Francesco Sullo <francesco@sullo.co>
 * @dev It store the tweedentities contracts addresses to allows dapp to be updated
 */


contract TweedentityRegistry
is HasNoEther
{

  string public fromVersion = "1.0.0";

  address public manager;
  address public claimer;

  event ContractRegistered(
    bytes32 indexed key,
    string spec,
    address addr
  );


  function setManager(
    address _manager
  )
  public
  onlyOwner
  {
    require(_manager != address(0));
    manager = _manager;
    ContractRegistered(keccak256("manager"), "", _manager);
  }


  function setClaimer(
    address _claimer
  )
  public
  onlyOwner
  {
    require(_claimer != address(0));
    claimer = _claimer;
    ContractRegistered(keccak256("claimer"), "", _claimer);
  }


  function setManagerAndClaimer(
    address _manager,
    address _claimer
  )
  external
  onlyOwner
  {
    setManager(_manager);
    setClaimer(_claimer);
  }


  /**
   * @dev Gets the store managing the specified app
   * @param _appNickname The nickname of the app
   */
  function getStore(
    string _appNickname
  )
  public
  constant returns (address)
  {
    ManagerInterface theManager = ManagerInterface(manager);
    return theManager.getStoreAddress(_appNickname);
  }


  // error codes

  uint public allSet = 0;
  uint public managerUnset = 10;
  uint public claimerUnset = 20;
  uint public wrongClaimerOrUnsetInManager = 30;
  uint public wrongManagerOrUnsetInClaimer = 40;
  uint public noStoresSet = 50;
  uint public noStoreIsActive = 60;
  uint public managerIsPaused = 70;
  uint public managerNotSetInApp = 1000;

  /**
   * @dev Returns true if the registry looks ready
   */
  function isReady()
  external
  constant returns (uint)
  {
    if (manager == address(0)) {
      return managerUnset;
    }
    if (claimer == address(0)) {
      return claimerUnset;
    }
    ManagerInterface theManager = ManagerInterface(manager);
    ClaimerInterface theClaimer = ClaimerInterface(claimer);
    if (theManager.claimer() != claimer) {
      return wrongClaimerOrUnsetInManager;
    }
    if (theClaimer.manager() != manager) {
      return wrongManagerOrUnsetInClaimer;
    }
    uint totalStores = theManager.totalStores();
    if (totalStores == 0) {
      return noStoresSet;
    }
    bool atLeastOneIsActive;
    for (uint i = 1; i <= totalStores; i++) {
      StoreInterface theStore = StoreInterface(theManager.getStoreAddressById(i));
      if (theManager.isStoreActive(i)) {
        atLeastOneIsActive = true;
      }
      if (theManager.isStoreActive(i)) {
        if (theStore.manager() != manager) {
          return managerNotSetInApp + i;
        }
      }
    }
    if (atLeastOneIsActive == false) {
      return noStoreIsActive;
    }
    if (theManager.paused() == true) {
      return managerIsPaused;
    }
    return allSet;
  }

}