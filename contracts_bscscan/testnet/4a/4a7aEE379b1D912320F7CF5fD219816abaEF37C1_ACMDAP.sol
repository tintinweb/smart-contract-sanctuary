/**
 *Submitted for verification at BscScan.com on 2022-01-22
*/

pragma solidity 0.5.16;

interface iACMDAP {

  /**
   * @dev Register a new account
   */
  function registerAccount(
    address walletAddr,
    string calldata name, 
    string calldata idNumber, 
    string calldata idNumberType,
    bool isKYC
    ) external returns (bool ok);

  /**
   * @dev Deactivate an account
   */
  function deactiveAccount( address walletAddr ) external returns (bool ok);

  /**
   * @dev Activate an account
   */
  function activeAccount( address walletAddr ) external returns (bool ok);

  /**
   * @dev Update account information
   */
  function updateAccountInfor( 
    address walletAddr,
    string calldata name, 
    string calldata idNumber, 
    string calldata idNumberType,
    bool isKYC
    ) external returns (bool ok);

  /**
   * @dev Listing all account
   */
  function accountListing() external view returns ( uint256 counter, address[] memory);

  /**
   * @dev Exchangable condition
   */
  function tradableAccount(address walletAddr) external view returns (bool);

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

  /**
   * @dev Emitted when an account is registered
   */
  event accountRegistered(
      address indexed walletAddr
      );

  /**
   * @dev Emitted when an account is deactived
   */
  event accountDeactivated(
      address indexed walletAddr
      );

  /**
   * @dev Emitted when an account is re-actived
   */
  event accountActivated(
      address indexed walletAddr
      );

  /**
   * @dev Emitted when an account information is updated
   */
  event accountInfoUpdated(
      address indexed walletAddr
      );

}

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
contract Context {
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  constructor () internal { }

  function _msgSender() internal view returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}


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
contract Ownable is Context {
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
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract ACMDAP is Context, iACMDAP, Ownable {


  uint32 public _accountCounter;

  struct identity {
      string name;                /* Identity name */
      string idNumber;            /* Identity card number or others. */
      string idNumberType;        /* Type of identity card number: ID, Driven license, CCCD, ...*/
      bool isRegisted;            /* True if this identity is existence. prevent an address is registed two times*/
      bool isKYC;                 /* True if this identity is successful completed KYC process*/
      bool isActive;              /* True if this identity is active*/
      address grantor;            /* The persion who regis this identity */
      uint256 regisTime;           /* Time of the registration, in days since the UNIX epoch (start of day). */
  }
  
  address [] private _accList;
  mapping(address => identity) private _identity;

  constructor() public {
    _accountCounter = 0;
  }

  /**
   * @dev Returns the current time in seconds
   */
  function timeNow() public view returns (uint256 timeNumber) {
    return block.timestamp;
  }

  /**
   * @dev Register a new account
   */
  function registerAccount(
    address walletAddr,
    string memory name, 
    string memory idNumber, 
    string memory idNumberType,
    bool isKYC
    ) public onlyOwner returns (bool ok) {    

    require(!_identity[walletAddr].isRegisted, "Account already exists");    

    // Create and populate a token grant, referencing vesting schedule.
    _identity[walletAddr] = identity(
      name,
      idNumber,
      idNumberType,
      true/*isExisting*/,
      isKYC,
      false,
      msg.sender,
      timeNow()
    );

    // increase the counter
    _accountCounter ++;
    // acc listing
    _accList.push(walletAddr);

    emit accountRegistered(walletAddr);
    return true;
  }

  /**
   * @dev Deactivate an account
   */
  function deactiveAccount( address walletAddr ) public onlyOwner returns (bool ok) {   
    
    identity storage acc = _identity[walletAddr];

    require(acc.isRegisted, "The account does not exist");
    require(acc.isActive, "The account has been deactivated already");

    acc.isActive = false;
    emit accountDeactivated(walletAddr);

    return true;
  }

  /**
   * @dev Activate an account
   */
  function activeAccount( address walletAddr ) public onlyOwner returns (bool ok) {

    identity storage acc = _identity[walletAddr];

    require(acc.isRegisted, "The account does not exist");
    require(acc.isKYC, "The account need to be KYC first");
    require(!acc.isActive, "The account has been activated already");

    acc.isActive = true;
    emit accountActivated(walletAddr);

    return true;
  }

  /**
   * @dev Update account information
   */
  function updateAccountInfor( 
    address walletAddr,
    string memory name, 
    string memory idNumber, 
    string memory idNumberType,
    bool isKYC
    ) public onlyOwner returns (bool ok) {   
        
    identity storage acc = _identity[walletAddr];
    require(acc.isRegisted, "The account does not exist");

    acc.name = name;
    acc.idNumber = idNumber;
    acc.idNumberType = idNumberType;
    acc.isKYC = isKYC;

    emit accountInfoUpdated(walletAddr);

    return true;
  }

  /**
   * @dev Get account information
   */
  function accountInfo(address walletAddr) public view returns (
    string memory name,
    string memory idNumber,
    string memory idNumberType,
    address grantor,
    uint256 regisTime,
    bool isActive,
    bool isKYC) {
      
    identity memory acc = _identity[walletAddr];
    require(acc.isRegisted, "The account does not exist");

    return (
      acc.name,
      acc.idNumber,
      acc.idNumberType,
      acc.grantor,
      acc.regisTime,
      acc.isActive,
      acc.isKYC
      );
  }

  /**
   * @dev Listing all account
   */
  function accountListing() external view returns ( uint256 counter, address[] memory) {
    return ( _accountCounter, _accList);
  }

  /**
   * @dev Exchangable condition
   */
  function tradableAccount(address walletAddr) external view returns (bool) {
      identity storage acc = _identity[walletAddr];

      if(acc.isRegisted && acc.isActive && acc.isKYC)
        return true;
      else 
        return false;
  }

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address) {
    return owner();
  }
}