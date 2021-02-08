/**
 *Submitted for verification at Etherscan.io on 2021-02-08
*/

// File: @0xcert/ethereum-utils/contracts/math/SafeMath.sol

pragma solidity ^0.4.24;

/**
 * @dev Math operations with safety checks that throw on error. This contract is based
 * on the source code at https://goo.gl/iyQsmU.
 */
library SafeMath {

  /**
   * @dev Multiplies two numbers, throws on overflow.
   * @param _a Factor number.
   * @param _b Factor number.
   */
  function mul(
    uint256 _a,
    uint256 _b
  )
    internal
    pure
    returns (uint256)
  {
    if (_a == 0) {
      return 0;
    }
    uint256 c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
   * @dev Integer division of two numbers, truncating the quotient.
   * @param _a Dividend number.
   * @param _b Divisor number.
   */
  function div(
    uint256 _a,
    uint256 _b
  )
    internal
    pure
    returns (uint256)
  {
    uint256 c = _a / _b;
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
   * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
   * @param _a Minuend number.
   * @param _b Subtrahend number.
   */
  function sub(
    uint256 _a,
    uint256 _b
  )
    internal
    pure
    returns (uint256)
  {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
   * @dev Adds two numbers, throws on overflow.
   * @param _a Number.
   * @param _b Number.
   */
  function add(
    uint256 _a,
    uint256 _b
  )
    internal
    pure
    returns (uint256)
  {
    uint256 c = _a + _b;
    assert(c >= _a);
    return c;
  }

}

// File: @0xcert/ethereum-utils/contracts/utils/ERC165.sol

pragma solidity ^0.4.24;

/**
 * @dev A standard for detecting smart contract interfaces. See https://goo.gl/cxQCse.
 */
interface ERC165 {

  /**
   * @dev Checks if the smart contract includes a specific interface.
   * @notice This function uses less than 30,000 gas.
   * @param _interfaceID The interface identifier, as specified in ERC-165.
   */
  function supportsInterface(
    bytes4 _interfaceID
  )
    external
    view
    returns (bool);

}

// File: @0xcert/ethereum-utils/contracts/utils/SupportsInterface.sol

pragma solidity ^0.4.24;


/**
 * @dev Implementation of standard for detect smart contract interfaces.
 */
contract SupportsInterface is
  ERC165
{

  /**
   * @dev Mapping of supported intefraces.
   * @notice You must not set element 0xffffffff to true.
   */
  mapping(bytes4 => bool) internal supportedInterfaces;

  /**
   * @dev Contract constructor.
   */
  constructor()
    public
  {
    supportedInterfaces[0x01ffc9a7] = true; // ERC165
  }

  /**
   * @dev Function to check which interfaces are suported by this contract.
   * @param _interfaceID Id of the interface.
   */
  function supportsInterface(
    bytes4 _interfaceID
  )
    external
    view
    returns (bool)
  {
    return supportedInterfaces[_interfaceID];
  }

}

// File: @0xcert/ethereum-utils/contracts/utils/AddressUtils.sol

pragma solidity ^0.4.24;

/**
 * @dev Utility library of inline functions on addresses.
 */
library AddressUtils {

  /**
   * @dev Returns whether the target address is a contract.
   * @param _addr Address to check.
   */
  function isContract(
    address _addr
  )
    internal
    view
    returns (bool)
  {
    uint256 size;

    /**
     * XXX Currently there is no better way to check if there is a contract in an address than to
     * check the size of the code at that address.
     * See https://ethereum.stackexchange.com/a/14016/36603 for more details about how this works.
     * TODO: Check this again before the Serenity release, because all addresses will be
     * contracts then.
     */
    assembly { size := extcodesize(_addr) } // solium-disable-line security/no-inline-assembly
    return size > 0;
  }

}

// File: @0xcert/ethereum-utils/contracts/ownership/Ownable.sol

pragma solidity ^0.4.24;

/**
 * @dev The contract has an owner address, and provides basic authorization control whitch
 * simplifies the implementation of user permissions. This contract is based on the source code
 * at https://goo.gl/n2ZGVt.
 */
contract Ownable {
  address public owner;

  /**
   * @dev An event which is triggered when the owner is changed.
   * @param previousOwner The address of the previous owner.
   * @param newOwner The address of the new owner.
   */
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The constructor sets the original `owner` of the contract to the sender account.
   */
  constructor()
    public
  {
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
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(
    address _newOwner
  )
    onlyOwner
    public
  {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }

}

// File: @0xcert/ethereum-utils/contracts/ownership/Claimable.sol

pragma solidity ^0.4.24;


/**
 * @dev The contract has an owner address, and provides basic authorization control whitch
 * simplifies the implementation of user permissions. This contract is based on the source code
 * at goo.gl/CfEAkv and upgrades Ownable contracts with additional claim step which makes ownership
 * transfers less prone to errors.
 */
contract Claimable is Ownable {
  address public pendingOwner;

  /**
   * @dev An event which is triggered when the owner is changed.
   * @param previousOwner The address of the previous owner.
   * @param newOwner The address of the new owner.
   */
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev Allows the current owner to give new owner ability to claim the ownership of the contract.
   * This differs from the Owner's function in that it allows setting pedingOwner address to 0x0,
   * which effectively cancels an active claim.
   * @param _newOwner The address which can claim ownership of the contract.
   */
  function transferOwnership(
    address _newOwner
  )
    onlyOwner
    public
  {
    pendingOwner = _newOwner;
  }

  /**
   * @dev Allows the current pending owner to claim the ownership of the contract. It emits
   * OwnershipTransferred event and resets pending owner to 0.
   */
  function claimOwnership()
    public
  {
    require(msg.sender == pendingOwner);
    address previousOwner = owner;
    owner = pendingOwner;
    pendingOwner = 0;
    emit OwnershipTransferred(previousOwner, owner);
  }
}

// File: contracts/Adminable.sol

pragma solidity ^0.4.24;


/**
 * @title Adminable
 * @dev Allows to manage privilages to special contract functionality.
 */
contract Adminable is Claimable {
  mapping(address => uint) public adminsMap;
  address[] public adminList;

  /**
   * @dev Returns true, if provided address has special privilages, otherwise false
   * @param adminAddress - address to check
   */
  function isAdmin(address adminAddress)
    public
    view
    returns(bool isIndeed)
  {
    if (adminAddress == owner) return true;

    if (adminList.length == 0) return false;
    return (adminList[adminsMap[adminAddress]] == adminAddress);
  }

  /**
   * @dev Grants special rights for address holder
   * @param adminAddress - address of future admin
   */
  function addAdmin(address adminAddress)
    public
    onlyOwner
    returns(uint index)
  {
    require(!isAdmin(adminAddress), "Address already has admin rights!");

    adminsMap[adminAddress] = adminList.push(adminAddress)-1;

    return adminList.length-1;
  }

  /**
   * @dev Removes special rights for provided address
   * @param adminAddress - address of current admin
   */
  function removeAdmin(address adminAddress)
    public
    onlyOwner
    returns(uint index)
  {
    // we can not remove owner from admin role
    require(owner != adminAddress, "Owner can not be removed from admin role!");
    require(isAdmin(adminAddress), "Provided address is not admin.");

    uint rowToDelete = adminsMap[adminAddress];
    address keyToMove = adminList[adminList.length-1];
    adminList[rowToDelete] = keyToMove;
    adminsMap[keyToMove] = rowToDelete;
    adminList.length--;

    return rowToDelete;
  }

  /**
   * @dev modifier Throws if called by any account other than the owner.
   */
  modifier onlyAdmin() {
    require(isAdmin(msg.sender), "Can be executed only by admin accounts!");
    _;
  }
}

// File: contracts/Priceable.sol

pragma solidity ^0.4.24;



/**
 * @title Priceable
 * @dev Contracts allows to handle ETH resources of the contract.
 */
contract Priceable is Claimable {

  using SafeMath for uint256;

  /**
   * @dev Emits when owner take ETH out of contract
   * @param balance - amount of ETh sent out from contract
   */
  event Withdraw(uint256 balance);

  /**
   * @dev modifier Checks minimal amount, what was sent to function call.
   * @param _minimalAmount - minimal amount neccessary to  continue function call
   */
  modifier minimalPrice(uint256 _minimalAmount) {
    require(msg.value >= _minimalAmount, "Not enough Ether provided.");
    _;
  }

  /**
   * @dev modifier Associete fee with a function call. If the caller sent too much, then is refunded, but only after the function body.
   * This was dangerous before Solidity version 0.4.0, where it was possible to skip the part after `_;`.
   * @param _amount - ether needed to call the function
   */
  modifier price(uint256 _amount) {
    require(msg.value >= _amount, "Not enough Ether provided.");
    _;
    if (msg.value > _amount) {
      msg.sender.transfer(msg.value.sub(_amount));
    }
  }

  /*
   * @dev Remove all Ether from the contract, and transfer it to account of owner
   */
  function withdrawBalance()
    external
    onlyOwner
  {
    uint256 balance = address(this).balance;
    msg.sender.transfer(balance);

    // Tell everyone !!!!!!!!!!!!!!!!!!!!!!
    emit Withdraw(balance);
  }

  // fallback function that allows contract to accept ETH
  function () public payable {}
}

// File: contracts/Pausable.sol

pragma solidity ^0.4.24;


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism for mainenance purposes
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev modifier to allow actions only when the contract IS paused
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev modifier to allow actions only when the contract IS NOT paused
   */
  modifier whenPaused {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause()
    external
    onlyOwner
    whenNotPaused
    returns (bool)
  {
    paused = true;
    emit Pause();
    return true;
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause()
    external
    onlyOwner
    whenPaused
    returns (bool)
  {
    paused = false;
    emit Unpause();
    return true;
  }
}

// File: contracts/MarbleNFTCandidateInterface.sol

pragma solidity ^0.4.24;

/**
 * @title Marble NFT Candidate Contract
 * @dev Contracts allows public audiance to create Marble NFT candidates. All our candidates for NFT goes through our services to figure out if they are suitable for Marble NFT.
 * once their are picked our other contract will create NFT with same owner as candite and plcae it to minting auction. In minitng auction everyone can buy created NFT until duration period.
 * If duration is over, and noone has bought NFT, then creator of candidate can take Marble NFT from minting auction to his collection.
 */
interface MarbleNFTCandidateInterface {

  /**
   * @dev Sets minimal price for creating Marble NFT Candidate
   * @param _minimalMintingPrice Minimal price asked from creator of Marble NFT candidate (weis)
   */
  function setMinimalPrice(uint256 _minimalMintingPrice)
    external;

  /**
   * @dev Returns true if URI is already a candidate. Otherwise false.
   * @param _uri URI to check
   */
  function isCandidate(string _uri)
    external
    view
    returns(bool isIndeed);


  /**
   * @dev Creates Marble NFT Candidate. This candidate will go through our processing. If it's suitable, then Marble NFT is created.
   * @param _uri URI of resource you want to transform to Marble NFT
   */
  function createCandidate(string _uri)
    external
    payable
    returns(uint index);

  /**
   * @dev Removes URI from candidate list.
   * @param _uri URI to be removed from candidate list.
   */
  function removeCandidate(string _uri)
    external;

  /**
   * @dev Returns total count of candidates.
   */
  function getCandidatesCount()
    external
    view
    returns(uint256 count);

  /**
   * @dev Transforms URI to hash.
   * @param _uri URI to be transformed to hash.
   */
  function getUriHash(string _uri)
    external
    view
    returns(uint256 hash);

  /**
   * @dev Returns Candidate model by URI
   * @param _uri URI representing candidate
   */
  function getCandidate(string _uri)
    external
    view
    returns(
    uint256 index,
    address owner,
    uint256 mintingPrice,
    string url,
    uint256 created);
}

// File: contracts/MarbleNFTCandidate.sol

pragma solidity ^0.4.24;








/**
 * @title Marble NFT Candidate Contract
 * @dev Contracts allows public audiance to create Marble NFT candidates. All our candidates for NFT goes through our services to figure out if they are suitable for Marble NFT.
 * once their are picked our other contract will create NFT with same owner as candite and plcae it to minting auction. In minitng auction everyone can buy created NFT until duration ends.
 * If duration is over, and noone has bought NFT, then creator of candidate can take Marble NFT from minting auction to his collection.
 */
contract MarbleNFTCandidate is
  SupportsInterface,
  Adminable,
  Pausable,
  Priceable,
  MarbleNFTCandidateInterface
{

  using SafeMath for uint256;
  using AddressUtils for address;

  struct Candidate {
    uint256 index;

    // possible NFT creator
    address owner;

    // price paid for minting and placiing NFT to initial auction
    uint256 mintingPrice;

    // CANDIDATES DNA
    string uri;

    // date of creation
    uint256 created;
  }

  // minimal price for creating candidate
  uint256 public minimalMintingPrice;

  // index of candidate in candidates is unique candidate id
  mapping(uint256 => Candidate) public uriHashToCandidates;
  uint256[] public uriHashIndex;


  /**
   * @dev Transforms URI to hash.
   * @param _uri URI to be transformed to hash.
   */
  function _getUriHash(string _uri)
    internal
    pure
    returns(uint256 hash_) // `hash` changed to `hash_` - according to review
  {
    return uint256(keccak256(abi.encodePacked(_uri)));
  }

  /**
   * @dev Returns true if URI is already a candidate. Otherwise false.
   * @param _uri URI to check
   */
  function _isCandidate(string _uri)
    internal
    view
    returns(bool isIndeed)
  {
    if(uriHashIndex.length == 0) return false;

    uint256 uriHash = _getUriHash(_uri);
    return (uriHashIndex[uriHashToCandidates[uriHash].index] == uriHash);
  }

  /**
   * @dev Sets minimal price for creating Marble NFT Candidate
   * @param _minimalMintingPrice Minimal price asked from creator of Marble NFT candidate
   */
  function setMinimalPrice(uint256 _minimalMintingPrice)
    external
    onlyAdmin
  {
    minimalMintingPrice = _minimalMintingPrice;
  }

  /**
   * @dev Returns true if URI is already a candidate. Otherwise false.
   * @param _uri URI to check
   */
  function isCandidate(string _uri)
    external
    view
    returns(bool isIndeed)
  {
    return _isCandidate(_uri);
  }

  /**
   * @dev Creates Marble NFT Candidate. This candidate will go through our processing. If it's suitable, then Marble NFT is created.
   * @param _uri URI of resource you want to transform to Marble NFT
   */
  function createCandidate(string _uri)
    external
    whenNotPaused
    payable
    minimalPrice(minimalMintingPrice)
    returns(uint256 index)
  {
    uint256 uriHash = _getUriHash(_uri);

    require(uriHash != _getUriHash(""), "Candidate URI can not be empty!");
    require(!_isCandidate(_uri), "Candidate is already created!");

    uriHashToCandidates[uriHash] = Candidate(uriHashIndex.push(uriHash)-1, msg.sender, msg.value, _uri, now);
    return uriHashIndex.length -1;
  }


  /**
   * @dev Removes URI from candidate list.
   * @param _uri URI to be removed from candidate list.
   */
  function removeCandidate(string _uri)
    external
    onlyAdmin
  {
    require(_isCandidate(_uri), "Candidate is not present!");

    uint256 uriHash = _getUriHash(_uri);

    uint256 rowToDelete = uriHashToCandidates[uriHash].index;
    uint256 keyToMove = uriHashIndex[uriHashIndex.length-1];
    uriHashIndex[rowToDelete] = keyToMove;
    uriHashToCandidates[keyToMove].index = rowToDelete;

    delete uriHashToCandidates[uriHash];
    uriHashIndex.length--;
  }

  /**
   * @dev Returns total count of candidates.
   */
  function getCandidatesCount()
    external
    view
    returns(uint256 count)
  {
    return uriHashIndex.length;
  }

  /**
   * @dev Transforms URI to hash.
   * @param _uri URI to be transformed to hash.
   */
  function getUriHash(string _uri)
    external
    view
    returns(uint256 hash)
  {
    return _getUriHash(_uri);
  }


  /**
   * @dev Returns Candidate model by URI
   * @param _uri URI representing candidate
   */
  function getCandidate(string _uri)
    external
    view
    returns(
    uint256 index,
    address owner,
    uint256 mintingPrice,
    string uri,
    uint256 created)
  {
    Candidate memory candidate = uriHashToCandidates[_getUriHash(_uri)];

    return (
      candidate.index,
      candidate.owner,
      candidate.mintingPrice,
      candidate.uri,
      candidate.created);
  }

}