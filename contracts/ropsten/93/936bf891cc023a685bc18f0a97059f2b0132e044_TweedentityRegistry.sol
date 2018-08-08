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

// File: openzeppelin-solidity/contracts/lifecycle/Pausable.sol

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

// File: contracts/TweedentityRegistry.sol

/**
 * @title TweedentityRegistry
 * @author Francesco Sullo <francesco@sullo.co>
 * @dev It store the tweedentities contracts addresses to allows dapp to be updated
 */


contract TweedentityRegistry  /** 1.0.0 */
is Pausable
{

  function TweedentityRegistry()
  public
  {
    paused = true;
  }

  uint public totalStores;
  mapping (bytes32 => address) public stores;
  address public manager;
  address public claimer;


  function setManager(
    address _address
  )
  external
  onlyOwner
  {
    require(_address != 0x0);
    manager = _address;
  }


  function setClaimer(
    address _address
  )
  external
  onlyOwner
  {
    require(_address != 0x0);
    claimer = _address;
  }


  function setManagerAndClaimer(
    address _manager,
    address _claimer
  )
  external
  onlyOwner
  {
    require(_manager != 0x0);
    require(_claimer != 0x0);
    manager = _manager;
    claimer = _claimer;
  }


  function setStore(
    string _appNickname,
    address _address
  )
  external
  onlyOwner
  {
    require(_address != 0x0);
    if (getStore(_appNickname) == address(0)) {
      totalStores++;
    }
    stores[keccak256(_appNickname)] = _address;
  }


  /**
   * @dev Gets the store managing the specified app
   * @param _appNickname The nickname of the app
   */
  function getStore(
    string _appNickname
  )
  public
  constant returns(address)
  {
    return stores[keccak256(_appNickname)];
  }


  /**
   * @dev Returns true if the registry looks ready
   */
  function isReady()
  external
  constant returns(bool)
  {
    return totalStores > 0 && manager != address(0) && claimer != address(0) && !paused;
  }


}