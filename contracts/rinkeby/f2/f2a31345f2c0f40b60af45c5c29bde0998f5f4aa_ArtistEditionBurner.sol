/**
 *Submitted for verification at Etherscan.io on 2021-05-23
*/

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

// File: openzeppelin-solidity/contracts/lifecycle/Pausable.sol

pragma solidity ^0.4.24;



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

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

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

// File: contracts/v2/artist-controls/ArtistEditionBurner.sol

pragma solidity 0.4.24;




interface IKODAV2ArtistBurner {
  function editionActive(uint256 _editionNumber) external view returns (bool);

  function artistCommission(uint256 _editionNumber) external view returns (address _artistAccount, uint256 _artistCommission);

  function updateActive(uint256 _editionNumber, bool _active) external;

  function totalSupplyEdition(uint256 _editionNumber) external view returns (uint256);

  function totalRemaining(uint256 _editionNumber) external view returns (uint256);

  function updateTotalAvailable(uint256 _editionNumber, uint256 _totalAvailable) external;
}

/**
* @title Artists burning contract for KnownOrigin (KODA)
*
* Allows for edition artists to burn unsold works or reduce the supply of sold tokens from editions
*
* https://www.knownorigin.io/
*
* BE ORIGINAL. BUY ORIGINAL.
*/
contract ArtistEditionBurner is Ownable, Pausable {
  using SafeMath for uint256;

  // Interface into the KODA world
  IKODAV2ArtistBurner public kodaAddress;

  event EditionDeactivated(
    uint256 indexed _editionNumber
  );

  event EditionSupplyReduced(
    uint256 indexed _editionNumber
  );

  constructor(IKODAV2ArtistBurner _kodaAddress) public {
    kodaAddress = _kodaAddress;
  }

  /**
   * @dev Sets the provided edition to either a deactivated state or reduces the available supply to zero
   * @dev Only callable from edition artists defined in KODA NFT contract
   * @dev Only callable when contract is not paused
   * @dev Reverts if edition is invalid
   * @dev Reverts if edition is not active in KDOA NFT contract
   */
  function deactivateOrReduceEditionSupply(uint256 _editionNumber) external whenNotPaused {
    (address artistAccount, uint256 _) = kodaAddress.artistCommission(_editionNumber);
    require(msg.sender == artistAccount || msg.sender == owner, "Only from the edition artist account");

    // only allow them to be disabled if we have not already done it already
    bool isActive = kodaAddress.editionActive(_editionNumber);
    require(isActive, "Only when edition is active");

    // only allow changes if not sold out
    uint256 totalRemaining = kodaAddress.totalRemaining(_editionNumber);
    require(totalRemaining > 0, "Only when edition not sold out");

    // total issued so far
    uint256 totalSupply = kodaAddress.totalSupplyEdition(_editionNumber);

    // if no tokens issued, simply disable the edition, burn it!
    if (totalSupply == 0) {
      kodaAddress.updateActive(_editionNumber, false);
      kodaAddress.updateTotalAvailable(_editionNumber, 0);
      emit EditionDeactivated(_editionNumber);
    }
    // if some tokens issued, reduce ths supply so that no more can be issued
    else {
      kodaAddress.updateTotalAvailable(_editionNumber, totalSupply);
      emit EditionSupplyReduced(_editionNumber);
    }
  }

  /**
   * @dev Sets the KODA address
   * @dev Only callable from owner
   */
  function setKodavV2(IKODAV2ArtistBurner _kodaAddress) onlyOwner public {
    kodaAddress = _kodaAddress;
  }

}