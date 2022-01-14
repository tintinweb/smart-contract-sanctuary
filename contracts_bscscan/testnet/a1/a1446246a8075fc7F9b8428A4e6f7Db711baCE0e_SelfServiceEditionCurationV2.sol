pragma solidity 0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

import "./SelfServiceAccessControls.sol";

interface IKODAV2SelfServiceEditionCuration {

  function createActiveEdition(
    uint256 _editionNumber,
    bytes32 _editionData,
    uint256 _editionType,
    uint256 _startDate,
    uint256 _endDate,
    address _artistAccount,
    uint256 _artistCommission,
    uint256 _priceInWei,
    string _tokenUri,
    uint256 _totalAvailable
  ) external returns (bool);

  function artistsEditions(address _artistsAccount) external returns (uint256[1] _editionNumbers);

  function totalAvailableEdition(uint256 _editionNumber) external returns (uint256);

  function highestEditionNumber() external returns (uint256);
}

interface IKODAAuction {
  function setArtistsControlAddressAndEnabledEdition(uint256 _editionNumber, address _address) external;
}

contract SelfServiceEditionCurationV2 is Ownable, Pausable {
  using SafeMath for uint256;

  event SelfServiceEditionCreated(
    uint256 indexed _editionNumber,
    address indexed _creator,
    uint256 _priceInWei,
    uint256 _totalAvailable,
    bool _enableAuction
  );

  // Calling address
  IKODAV2SelfServiceEditionCuration public kodaV2;
  IKODAAuction public auction;
  SelfServiceAccessControls public accessControls;

  // Default artist commission
  uint256 public artistCommission = 85;

  // Config which enforces editions to not be over this size
  uint256 public maxEditionSize = 100;

  // Config the minimum price per edition
  uint256 public minPricePerEdition = 0;

  // When true this will skip the invocation in time period check
  bool public disableInvocationCheck = false;

  // Max number of editions to be created in the time period
  uint256 public maxInvocations = 1;

  // The rolling time period for max number of invocations
  uint256 public maxInvocationsTimePeriod = 1 days;

  // Number of invocations the caller has performed in the time period
  mapping(address => uint256) public invocationsInTimePeriod;

  // When the current time period started
  mapping(address => uint256) public timeOfFirstInvocationInPeriod;

  /**
   * @dev Construct a new instance of the contract
   */
  constructor(
    IKODAV2SelfServiceEditionCuration _kodaV2,
    IKODAAuction _auction,
    SelfServiceAccessControls _accessControls
  ) public {
    kodaV2 = _kodaV2;
    auction = _auction;
    accessControls = _accessControls;
  }

  /**
   * @dev Called by artists, create new edition on the KODA platform
   */
  function createEdition(
    uint256 _totalAvailable,
    uint256 _priceInWei,
    uint256 _startDate,
    string _tokenUri,
    bool _enableAuction
  )
  public
  whenNotPaused
  returns (uint256 _editionNumber)
  {
    validateInvocations();
    return _createEdition(msg.sender, _totalAvailable, _priceInWei, _startDate, _tokenUri, _enableAuction);
  }

  /**
   * @dev Caller by owner, can create editions for other artists
   * @dev Only callable from owner regardless of pause state
   */
  function createEditionFor(
    address _artist,
    uint256 _totalAvailable,
    uint256 _priceInWei,
    uint256 _startDate,
    string _tokenUri,
    bool _enableAuction
  )
  public
  onlyOwner
  returns (uint256 _editionNumber)
  {
    return _createEdition(_artist, _totalAvailable, _priceInWei, _startDate, _tokenUri, _enableAuction);
  }

  /**
   * @dev Internal function for edition creation
   */
  function _createEdition(
    address _artist,
    uint256 _totalAvailable,
    uint256 _priceInWei,
    uint256 _startDate,
    string _tokenUri,
    bool _enableAuction
  )
  internal
  returns (uint256 _editionNumber){

    // Enforce edition size
    require(_totalAvailable > 0, "Must be at least one available in edition");
    require(_totalAvailable <= maxEditionSize, "Must not exceed max edition size");

    // Enforce min price
    require(_priceInWei >= minPricePerEdition, "Price must be greater than minimum");

    // If we are the owner, skip this artists check
    if (msg.sender != owner) {

      // Enforce who can call this
      if (!accessControls.openToAllArtist()) {
        require(accessControls.allowedArtists(_artist), "Only allowed artists can create editions for now");
      }
    }

    // Find the next edition number we can use
    uint256 editionNumber = getNextAvailableEditionNumber();

    // Attempt to create a new edition
    require(
      _createNewEdition(editionNumber, _artist, _totalAvailable, _priceInWei, _startDate, _tokenUri),
      "Failed to create new edition"
    );

    // Enable the auction if desired
    if (_enableAuction) {
      auction.setArtistsControlAddressAndEnabledEdition(editionNumber, _artist);
    }

    // Trigger event
    emit SelfServiceEditionCreated(editionNumber, _artist, _priceInWei, _totalAvailable, _enableAuction);

    return editionNumber;
  }

  /**
   * @dev Internal function for calling external create methods with some none configurable defaults
   */
  function _createNewEdition(
    uint256 _editionNumber,
    address _artist,
    uint256 _totalAvailable,
    uint256 _priceInWei,
    uint256 _startDate,
    string _tokenUri
  )
  internal
  returns (bool) {
    return kodaV2.createActiveEdition(
      _editionNumber,
      0x0, // _editionData - no edition data
      1, // _editionType - KODA always type 1
      _startDate,
      0, // _endDate - 0 = MAX unit256
      _artist,
      artistCommission,
      _priceInWei,
      _tokenUri,
      _totalAvailable
    );
  }

  function validateInvocations() internal {
    if (disableInvocationCheck) {
      return;
    }
    uint256 invocationPeriodStart = timeOfFirstInvocationInPeriod[msg.sender];

    // If we are new to this process or its been cleared, skip the check
    if (invocationPeriodStart != 0) {

      // Work out how much time has passed
      uint256 timePassedInPeriod = block.timestamp - invocationPeriodStart;

      // If we are still in this time period
      if (timePassedInPeriod < maxInvocationsTimePeriod) {

        uint256 invocations = invocationsInTimePeriod[msg.sender];

        uint256 currentInvocation = invocations + 1;

        // Ensure the number of invocations does not exceed the max number of invocations allowed
        require(currentInvocation <= maxInvocations, "Exceeded max invocations for time period");

        // Update the invocations for this period if passed validation check
        invocationsInTimePeriod[msg.sender] = currentInvocation;

      } else {
        // if we have passed the time period simple clear out the fields and start the period again
        invocationsInTimePeriod[msg.sender] = 1;
        timeOfFirstInvocationInPeriod[msg.sender] = block.timestamp;
      }

    } else {
      // initial the counters if not used before
      invocationsInTimePeriod[msg.sender] = 1;
      timeOfFirstInvocationInPeriod[msg.sender] = block.timestamp;
    }
  }

  /**
   * @dev Internal function for dynamically generating the next KODA edition number
   */
  function getNextAvailableEditionNumber()
  internal
  returns (uint256 editionNumber) {

    // Get current highest edition and total in the edition
    uint256 highestEditionNumber = kodaV2.highestEditionNumber();
    uint256 totalAvailableEdition = kodaV2.totalAvailableEdition(highestEditionNumber);

    // Add the current highest plus its total, plus 1 as tokens start at 1 not zero
    uint256 nextAvailableEditionNumber = highestEditionNumber.add(totalAvailableEdition).add(1);

    // Round up to next 100, 1000 etc based on max allowed size
    return ((nextAvailableEditionNumber + maxEditionSize - 1) / maxEditionSize) * maxEditionSize;
  }

  /**
   * @dev Sets the KODA address
   * @dev Only callable from owner
   */
  function setKodavV2(IKODAV2SelfServiceEditionCuration _kodaV2) onlyOwner public {
    kodaV2 = _kodaV2;
  }

  /**
   * @dev Sets the KODA auction
   * @dev Only callable from owner
   */
  function setAuction(IKODAAuction _auction) onlyOwner public {
    auction = _auction;
  }

  /**
   * @dev Sets the default commission for each edition
   * @dev Only callable from owner
   */
  function setArtistCommission(uint256 _artistCommission) onlyOwner public {
    artistCommission = _artistCommission;
  }

  /**
   * @dev Sets the max edition size
   * @dev Only callable from owner
   */
  function setMaxEditionSize(uint256 _maxEditionSize) onlyOwner public {
    maxEditionSize = _maxEditionSize;
  }

  /**
   * @dev Sets the max invocations
   * @dev Only callable from owner
   */
  function setMaxInvocations(uint256 _maxInvocations) onlyOwner public {
    maxInvocations = _maxInvocations;
  }

  /**
   * @dev Sets the disable invocation check, when true the invocation in time period check is skipped
   * @dev Only callable from owner
   */
  function setDisableInvocationCheck(bool _disableInvocationCheck) onlyOwner public {
    disableInvocationCheck = _disableInvocationCheck;
  }

  /**
   * @dev Sets minimum price per edition
   * @dev Only callable from owner
   */
  function setMinPricePerEdition(uint256 _minPricePerEdition) onlyOwner public {
    minPricePerEdition = _minPricePerEdition;
  }

  /**
   * @dev Checks to see if the account can mint more assets
   */
  function canCreateAnotherEdition(address account) public view returns (bool) {
    if (!isEnabledForAccount(account)) {
      return false;
    }
    return invocationsInTimePeriod[account] < maxInvocations;
  }

  /**
   * @dev Checks to see if the account can create editions
   */
  function isEnabledForAccount(address account) public view returns (bool) {
    return accessControls.isEnabledForAccount(account);
  }

  /**
   * @dev Allows for the ability to extract stuck ether
   * @dev Only callable from owner
   */
  function withdrawStuckEther(address _withdrawalAccount) onlyOwner public {
    require(_withdrawalAccount != address(0), "Invalid address provided");
    _withdrawalAccount.transfer(address(this).balance);
  }
}

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "../interfaces/ISelfServiceAccessControls.sol";

contract SelfServiceAccessControls is Ownable, ISelfServiceAccessControls {

  // Simple map to only allow certain artist create editions at first
  mapping(address => bool) public allowedArtists;

  // When true any existing KO artist can mint their own editions
  bool public openToAllArtist = false;

  /**
   * @dev Controls is the contract is open to all
   * @dev Only callable from owner
   */
  function setOpenToAllArtist(bool _openToAllArtist) onlyOwner public {
    openToAllArtist = _openToAllArtist;
  }

  /**
   * @dev Controls who can call this contract
   * @dev Only callable from owner
   */
  function setAllowedArtist(address _artist, bool _allowed) onlyOwner public {
    allowedArtists[_artist] = _allowed;
  }

  /**
   * @dev Checks to see if the account can create editions
   */
  function isEnabledForAccount(address account) public view returns (bool) {
    if (openToAllArtist) {
      return true;
    }
    return allowedArtists[account];
  }

  /**
   * @dev Allows for the ability to extract stuck ether
   * @dev Only callable from owner
   */
  function withdrawStuckEther(address _withdrawalAccount) onlyOwner public {
    require(_withdrawalAccount != address(0), "Invalid address provided");
    _withdrawalAccount.transfer(address(this).balance);
  }
}

pragma solidity 0.4.24;

interface ISelfServiceAccessControls {

  function isEnabledForAccount(address account) public view returns (bool);

}

pragma solidity ^0.4.24;


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

pragma solidity ^0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

pragma solidity ^0.4.24;


import "../ownership/Ownable.sol";


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
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}