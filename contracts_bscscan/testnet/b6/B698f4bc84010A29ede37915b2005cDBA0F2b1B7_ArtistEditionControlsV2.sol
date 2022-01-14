pragma solidity 0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

import "../interfaces/IKODAV2Controls.sol";

/**
* @title Artists self minting for KnownOrigin (KODA)
*
* Allows for the edition artists to mint there own assets and control the price of an edition
*
* https://www.knownorigin.io/
*
* BE ORIGINAL. BUY ORIGINAL.
*/
contract ArtistEditionControlsV2 is Ownable, Pausable {
  using SafeMath for uint256;

  // Interface into the KODA world
  IKODAV2Controls public kodaAddress;

  event PriceChanged(
    uint256 indexed _editionNumber,
    address indexed _artist,
    uint256 _priceInWei
  );

  event EditionGifted(
    uint256 indexed _editionNumber,
    address indexed _artist,
    uint256 indexed _tokenId
  );

  event EditionDeactivated(
    uint256 indexed _editionNumber
  );

  bool public deactivationPaused = false;

  modifier whenDeactivationNotPaused() {
    require(!deactivationPaused);
    _;
  }

  constructor(IKODAV2Controls _kodaAddress) public {
    kodaAddress = _kodaAddress;
  }

  /**
   * @dev Ability to gift new NFTs to an address, from a KODA edition
   * @dev Only callable from edition artists defined in KODA NFT contract
   * @dev Only callable when contract is not paused
   * @dev Reverts if edition is invalid
   * @dev Reverts if edition is not active in KDOA NFT contract
   */
  function gift(address _receivingAddress, uint256 _editionNumber)
  external
  whenNotPaused
  returns (uint256)
  {
    require(_receivingAddress != address(0), "Unable to send to zero address");

    (address artistAccount, uint256 _) = kodaAddress.artistCommission(_editionNumber);
    require(msg.sender == artistAccount || msg.sender == owner, "Only from the edition artist account");

    bool isActive = kodaAddress.editionActive(_editionNumber);
    require(isActive, "Only when edition is active");

    uint256 tokenId = kodaAddress.mint(_receivingAddress, _editionNumber);

    emit EditionGifted(_editionNumber, msg.sender, tokenId);

    return tokenId;
  }

  /**
   * @dev Sets the price of the provided edition in the WEI
   * @dev Only callable from edition artists defined in KODA NFT contract
   * @dev Only callable when contract is not paused
   * @dev Reverts if edition is invalid
   */
  function updateEditionPrice(uint256 _editionNumber, uint256 _priceInWei)
  external
  whenNotPaused
  returns (bool)
  {
    (address artistAccount, uint256 _) = kodaAddress.artistCommission(_editionNumber);
    require(msg.sender == artistAccount || msg.sender == owner, "Only from the edition artist account");

    kodaAddress.updatePriceInWei(_editionNumber, _priceInWei);

    emit PriceChanged(_editionNumber, msg.sender, _priceInWei);

    return true;
  }

  /**
   * @dev Sets provided edition to deactivated so it does not appear on the platform
   * @dev Only callable from edition artists defined in KODA NFT contract
   * @dev Only callable when contract is not paused
   * @dev Reverts if edition is invalid
   * @dev Reverts if edition is not active in KDOA NFT contract
   */
  function deactivateEdition(uint256 _editionNumber)
  external
  whenNotPaused
  whenDeactivationNotPaused
  returns (bool)
  {
    (address artistAccount, uint256 _) = kodaAddress.artistCommission(_editionNumber);
    require(msg.sender == artistAccount || msg.sender == owner, "Only from the edition artist account");

    // Only allow them to be disabled if we have not already done it already
    bool isActive = kodaAddress.editionActive(_editionNumber);
    require(isActive, "Only when edition is active");

    kodaAddress.updateActive(_editionNumber, false);

    emit EditionDeactivated(_editionNumber);

    return true;
  }

  /**
   * @dev Sets the KODA address
   * @dev Only callable from owner
   */
  function setKodavV2(IKODAV2Controls _kodaAddress) onlyOwner public {
    kodaAddress = _kodaAddress;
  }

  /**
   * @dev Disables the ability to deactivate editions from the this contract
   * @dev Only callable from owner
   */
  function pauseDeactivation() onlyOwner public {
    deactivationPaused = true;
  }

  /**
   * @dev Enables the ability to deactivate editions from the this contract
   * @dev Only callable from owner
   */
  function enablesDeactivation() onlyOwner public {
    deactivationPaused = false;
  }

}

pragma solidity 0.4.24;

/**
* Minimal interface definition for KODA V2 contract calls
*
* https://www.knownorigin.io/
*/
interface IKODAV2Controls {
  function mint(address _to, uint256 _editionNumber) external returns (uint256);

  function editionActive(uint256 _editionNumber) external view returns (bool);

  function artistCommission(uint256 _editionNumber) external view returns (address _artistAccount, uint256 _artistCommission);

  function updatePriceInWei(uint256 _editionNumber, uint256 _priceInWei) external;

  function updateActive(uint256 _editionNumber, bool _active) external;
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