/**
 *Submitted for verification at polygonscan.com on 2021-11-12
*/

/**
 *Submitted for verification at Etherscan.io on 2019-09-22
*/

pragma solidity 0.4.24;

// File: contracts/Auction/ISaleClockAuction.sol

contract ISaleClockAuction {

    function isSaleClockAuction() public returns(bool);


    /// @dev Creates and begins a new auction.
    /// @param _tokenId - ID of token to auction, sender must be owner.
    /// @param _startingPrice - Price of item (in wei) at beginning of auction.
    /// @param _endingPrice - Price of item (in wei) at end of auction.
    /// @param _duration - Length of auction (in seconds).
    /// @param _seller - Seller, if not the message sender
    function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _seller
    )
    external;

    /// @dev Updates lastSalePrice if seller is the nft contract
    /// Otherwise, works the same as default bid method.
    function bid(uint256 _tokenId)
    external
    payable;

    function cancelAuction(uint256 _tokenId)
    external;

    // cancel all old auctions
    function clearAll(address _seller, uint planetLimitation)
    external;

    // cancel an old auction for the token id
    function clearOne(address _seller, uint256 _tokenId)
    external;

    function averageExpansionSalePrice(uint256 _rarity) external view returns (uint256);

    function withdrawBalance() external;
}

// File: contracts/Common/ArrayArchiveTools.sol

contract ArrayArchiveTools {

    function _splitUint40ToArray(uint256 _hash) internal pure returns (uint256[5] _array) {
        for (uint i = 0; i < 5; i++) {
            _array[i] = uint256(uint8(_hash >> (8 * i)));
        }
    }

    function _mergeArrayToUint40(uint256[5] _array) internal pure returns (uint256 _hash) {
        for (uint i = 0; i < 5; i++) {
            _hash |= (_array[i] << (8 * i));
        }
    }

    function _splitUint80ToArray(uint256 _hash) internal pure returns (uint256[5] _array) {
        for (uint i = 0; i < 5; i++) {
            _array[i] = uint256(uint16(_hash >> (16 * i)));
        }
    }

    function _mergeArrayToUint80(uint256[5] _array) internal pure returns (uint256 _hash) {
        for (uint i = 0; i < 5; i++) {
            _hash |= (_array[i] << (16 * i));
        }
    }
}

// File: contracts/Common/MathTools.sol

contract MathTools {
    function _divisionWithRound(uint _numerator, uint _denominator) internal pure returns (uint _r) {
        _r = _numerator / _denominator;
        if (_numerator % _denominator >= _denominator / 2) {
            _r++;
        }
    }
}

// File: contracts/Discovery/UniverseDiscoveryConstant.sol

//TODO: run as separate contract
contract UniverseDiscoveryConstant {
    //ships
    uint256 internal constant MAX_RANKS_COUNT = 20;

    //resources
    uint256 internal constant MAX_ID_LIST_LENGTH = 5;
}

// File: contracts/PlanetExploration/IUniversePlanetExploration.sol

contract IUniversePlanetExploration is UniverseDiscoveryConstant {

    function isUniversePlanetExploration() external returns(bool);

    function explorePlanet(uint256 _rarity)
    external
    returns (
        uint[MAX_ID_LIST_LENGTH] resourcesId,
        uint[MAX_ID_LIST_LENGTH] resourcesVelocity
    );
}

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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: contracts/Access/Treasurer.sol

contract Treasurer is Ownable {
    address public treasurer;

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyTreasurer() {
        require(msg.sender == treasurer, "Only treasurer");
        _;
    }

    function transferTreasurer(address _treasurer) public onlyOwner {
        if (_treasurer != address(0)) {
            treasurer = _treasurer;
        }
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
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

// File: contracts/Access/AccessControl.sol

contract AccessControl is Ownable, Treasurer, Pausable {

    modifier onlyTeam() {
        require(
            msg.sender == owner ||
            msg.sender == treasurer
        , "Only owner and treasure have access"
        );
        _;
    }

    function pause() public onlyTeam {
        return super.pause();
    }
}

// File: contracts/Common/Random.sol

//TODO: Should be moved to separate library
contract Random {
    uint internal saltForRandom;

    function _rand() internal returns (uint256) {
        uint256 lastBlockNumber = block.number - 1;

        uint256 hashVal = uint256(blockhash(lastBlockNumber));

        // This turns the input data into a 100-sided die
        // by dividing by ceil(2 ^ 256 / 100).
        uint256 factor = 1157920892373161954235709850086879078532699846656405640394575840079131296399;

        saltForRandom += uint256(msg.sender) % 100 + uint256(uint256(hashVal) / factor);

        return saltForRandom;
    }

    function _randRange(uint256 min, uint256 max) internal returns (uint256) {
        return uint256(keccak256(_rand())) % (max - min + 1) + min;
    }

    function _randChance(uint percent) internal returns (bool) {
        return _randRange(0, 100) < percent;
    }

    function _now() internal view returns (uint256) {
        return now;
    }
}

// File: contracts/Settings/IUniverseBalance.sol

contract IUniverseBalance {
    function isUniverseBalance() external returns(bool);

    function autoClearAuction() external returns(bool);

    function getUIntValue(uint record) external view returns (uint);
    function getUIntArray2Value(uint record) external view returns (uint[2]);
    function getUIntArray3Value(uint record) external view returns (uint[3]);
    function getUIntArray4Value(uint record) external view returns (uint[4]);

    function getRankParamsValue(uint rankId) external view returns (uint[3]);
    function getRankResourcesCountByRarity(uint rankId) external view returns (uint[4]);

    function getGroupId(uint _x, uint _y) external view returns (uint);

    function getResourcesQuantityByRarity(uint256 rarity) external pure returns (uint256[2]);
}

// File: contracts/Galaxy/UniverseGalaxyConstant.sol

//TODO: run as separate contract
contract UniverseGalaxyConstant {
    //map
    uint256 internal constant SECTOR_X_MAX = 25;
    uint256 internal constant SECTOR_Y_MAX = 40;

    uint256 internal constant PLANETS_COUNT = 1000000;

    uint256 internal constant SECTORS_COUNT = SECTOR_X_MAX * SECTOR_Y_MAX; // 1000

    uint256 internal constant PLANETS_COUNT_PER_SECTOR = PLANETS_COUNT / SECTORS_COUNT; // 1000000 / 1000 = 1000

    //resources
    uint256 internal constant MAX_ID_LIST_LENGTH = 5;
}

// File: openzeppelin-solidity/contracts/token/ERC721/ERC721Basic.sol

/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Basic {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function exists(uint256 _tokenId) public view returns (bool _exists);

  function approve(address _to, uint256 _tokenId) public;
  function getApproved(uint256 _tokenId) public view returns (address _operator);

  function setApprovalForAll(address _operator, bool _approved) public;
  function isApprovedForAll(address _owner, address _operator) public view returns (bool);

  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public;
}

// File: contracts/Galaxy/IUniverseGalaxy.sol

contract IUniverseGalaxy is ERC721Basic, UniverseGalaxyConstant{

    function getPlanet(uint256 _id) external view
    returns (
        uint256 rarity,
        uint256 discovered,
        uint256 sectorX,
        uint256 sectorY,
        uint256[MAX_ID_LIST_LENGTH] resourcesId,
        uint256[MAX_ID_LIST_LENGTH] resourcesVelocity
    );

    function createSaleAuction(uint256 _planetId, uint256 _startingPrice, uint256 _endingPrice, uint256 _duration) external;

    function findAvailableResource(address _owner, uint _rarity) external returns (int8);
    function getDiscoveredPlanetsDensity(uint sectorX, uint sectorY) external view returns (uint);

    function createPlanet(
        address _owner,
        uint256 _rarity,
        uint256 _sectorX,
        uint256 _sectorY,
        uint256 _startPopulation
    ) external returns(uint256);

    function spendResources(address _owner, uint[MAX_ID_LIST_LENGTH] _resourcesId, uint[MAX_ID_LIST_LENGTH] _resourcesNeeded) external;

    function spendResourceOnPlanet(address _owner, uint _planetId, uint _resourceId, uint _resourceValue) external;

    function spendKnowledge(address _owner, uint _spentKnowledge) external;

    function recountPlanetResourcesAndUserKnowledge(address _owner, uint256 _planetId) external;

    function countPlanetsByRarityInGroup(uint _groupIndex, uint _rarity) external view returns (uint);

    function countPlanetsByRarity(uint _rarity) external view returns (uint);

    function checkWhetherEnoughPromoPlanet() external;
}

// File: openzeppelin-solidity/contracts/ownership/Whitelist.sol

/**
 * @title Whitelist
 * @dev The Whitelist contract has a whitelist of addresses, and provides basic authorization control functions.
 * @dev This simplifies the implementation of "user permissions".
 */
contract Whitelist is Ownable {
  mapping(address => bool) public whitelist;

  event WhitelistedAddressAdded(address addr);
  event WhitelistedAddressRemoved(address addr);

  /**
   * @dev Throws if called by any account that's not whitelisted.
   */
  modifier onlyWhitelisted() {
    require(whitelist[msg.sender]);
    _;
  }

  /**
   * @dev add an address to the whitelist
   * @param addr address
   * @return true if the address was added to the whitelist, false if the address was already in the whitelist
   */
  function addAddressToWhitelist(address addr) onlyOwner public returns(bool success) {
    if (!whitelist[addr]) {
      whitelist[addr] = true;
      emit WhitelistedAddressAdded(addr);
      success = true;
    }
  }

  /**
   * @dev add addresses to the whitelist
   * @param addrs addresses
   * @return true if at least one address was added to the whitelist,
   * false if all addresses were already in the whitelist
   */
  function addAddressesToWhitelist(address[] addrs) onlyOwner public returns(bool success) {
    for (uint256 i = 0; i < addrs.length; i++) {
      if (addAddressToWhitelist(addrs[i])) {
        success = true;
      }
    }
  }

  /**
   * @dev remove an address from the whitelist
   * @param addr address
   * @return true if the address was removed from the whitelist,
   * false if the address wasn't in the whitelist in the first place
   */
  function removeAddressFromWhitelist(address addr) onlyOwner public returns(bool success) {
    if (whitelist[addr]) {
      whitelist[addr] = false;
      emit WhitelistedAddressRemoved(addr);
      success = true;
    }
  }

  /**
   * @dev remove addresses from the whitelist
   * @param addrs addresses
   * @return true if at least one address was removed from the whitelist,
   * false if all addresses weren't in the whitelist in the first place
   */
  function removeAddressesFromWhitelist(address[] addrs) onlyOwner public returns(bool success) {
    for (uint256 i = 0; i < addrs.length; i++) {
      if (removeAddressFromWhitelist(addrs[i])) {
        success = true;
      }
    }
  }

}

// File: openzeppelin-solidity/contracts/token/ERC721/ERC721.sol

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Enumerable is ERC721Basic {
  function totalSupply() public view returns (uint256);
  function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256 _tokenId);
  function tokenByIndex(uint256 _index) public view returns (uint256);
}


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Metadata is ERC721Basic {
  function name() public view returns (string _name);
  function symbol() public view returns (string _symbol);
  function tokenURI(uint256 _tokenId) public view returns (string);
}


/**
 * @title ERC-721 Non-Fungible Token Standard, full implementation interface
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
}

// File: openzeppelin-solidity/contracts/AddressUtils.sol

/**
 * Utility library of inline functions on addresses
 */
library AddressUtils {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   *  as the code is not actually created until after the constructor finishes.
   * @param addr address to check
   * @return whether the target address is a contract
   */
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    assembly { size := extcodesize(addr) }  // solium-disable-line security/no-inline-assembly
    return size > 0;
  }

}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: openzeppelin-solidity/contracts/token/ERC721/ERC721Receiver.sol

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 *  from ERC721 asset contracts.
 */
contract ERC721Receiver {
  /**
   * @dev Magic value to be returned upon successful reception of an NFT
   *  Equals to `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`,
   *  which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
   */
  bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

  /**
   * @notice Handle the receipt of an NFT
   * @dev The ERC721 smart contract calls this function on the recipient
   *  after a `safetransfer`. This function MAY throw to revert and reject the
   *  transfer. This function MUST use 50,000 gas or less. Return of other
   *  than the magic value MUST result in the transaction being reverted.
   *  Note: the contract address is always the message sender.
   * @param _from The sending address
   * @param _tokenId The NFT identifier which is being transfered
   * @param _data Additional data with no specified format
   * @return `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`
   */
  function onERC721Received(address _from, uint256 _tokenId, bytes _data) public returns(bytes4);
}

// File: openzeppelin-solidity/contracts/token/ERC721/ERC721BasicToken.sol

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721BasicToken is ERC721Basic {
  using SafeMath for uint256;
  using AddressUtils for address;

  // Equals to `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`
  // which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
  bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

  // Mapping from token ID to owner
  mapping (uint256 => address) internal tokenOwner;

  // Mapping from token ID to approved address
  mapping (uint256 => address) internal tokenApprovals;

  // Mapping from owner to number of owned token
  mapping (address => uint256) internal ownedTokensCount;

  // Mapping from owner to operator approvals
  mapping (address => mapping (address => bool)) internal operatorApprovals;

  /**
   * @dev Guarantees msg.sender is owner of the given token
   * @param _tokenId uint256 ID of the token to validate its ownership belongs to msg.sender
   */
  modifier onlyOwnerOf(uint256 _tokenId) {
    require(ownerOf(_tokenId) == msg.sender);
    _;
  }

  /**
   * @dev Checks msg.sender can transfer a token, by being owner, approved, or operator
   * @param _tokenId uint256 ID of the token to validate
   */
  modifier canTransfer(uint256 _tokenId) {
    require(isApprovedOrOwner(msg.sender, _tokenId));
    _;
  }

  /**
   * @dev Gets the balance of the specified address
   * @param _owner address to query the balance of
   * @return uint256 representing the amount owned by the passed address
   */
  function balanceOf(address _owner) public view returns (uint256) {
    require(_owner != address(0));
    return ownedTokensCount[_owner];
  }

  /**
   * @dev Gets the owner of the specified token ID
   * @param _tokenId uint256 ID of the token to query the owner of
   * @return owner address currently marked as the owner of the given token ID
   */
  function ownerOf(uint256 _tokenId) public view returns (address) {
    address owner = tokenOwner[_tokenId];
    require(owner != address(0));
    return owner;
  }

  /**
   * @dev Returns whether the specified token exists
   * @param _tokenId uint256 ID of the token to query the existance of
   * @return whether the token exists
   */
  function exists(uint256 _tokenId) public view returns (bool) {
    address owner = tokenOwner[_tokenId];
    return owner != address(0);
  }

  /**
   * @dev Approves another address to transfer the given token ID
   * @dev The zero address indicates there is no approved address.
   * @dev There can only be one approved address per token at a given time.
   * @dev Can only be called by the token owner or an approved operator.
   * @param _to address to be approved for the given token ID
   * @param _tokenId uint256 ID of the token to be approved
   */
  function approve(address _to, uint256 _tokenId) public {
    address owner = ownerOf(_tokenId);
    require(_to != owner);
    require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

    if (getApproved(_tokenId) != address(0) || _to != address(0)) {
      tokenApprovals[_tokenId] = _to;
      emit Approval(owner, _to, _tokenId);
    }
  }

  /**
   * @dev Gets the approved address for a token ID, or zero if no address set
   * @param _tokenId uint256 ID of the token to query the approval of
   * @return address currently approved for a the given token ID
   */
  function getApproved(uint256 _tokenId) public view returns (address) {
    return tokenApprovals[_tokenId];
  }

  /**
   * @dev Sets or unsets the approval of a given operator
   * @dev An operator is allowed to transfer all tokens of the sender on their behalf
   * @param _to operator address to set the approval
   * @param _approved representing the status of the approval to be set
   */
  function setApprovalForAll(address _to, bool _approved) public {
    require(_to != msg.sender);
    operatorApprovals[msg.sender][_to] = _approved;
    emit ApprovalForAll(msg.sender, _to, _approved);
  }

  /**
   * @dev Tells whether an operator is approved by a given owner
   * @param _owner owner address which you want to query the approval of
   * @param _operator operator address which you want to query the approval of
   * @return bool whether the given operator is approved by the given owner
   */
  function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
    return operatorApprovals[_owner][_operator];
  }

  /**
   * @dev Transfers the ownership of a given token ID to another address
   * @dev Usage of this method is discouraged, use `safeTransferFrom` whenever possible
   * @dev Requires the msg sender to be the owner, approved, or operator
   * @param _from current owner of the token
   * @param _to address to receive the ownership of the given token ID
   * @param _tokenId uint256 ID of the token to be transferred
  */
  function transferFrom(address _from, address _to, uint256 _tokenId) public canTransfer(_tokenId) {
    require(_from != address(0));
    require(_to != address(0));

    clearApproval(_from, _tokenId);
    removeTokenFrom(_from, _tokenId);
    addTokenTo(_to, _tokenId);

    emit Transfer(_from, _to, _tokenId);
  }

  /**
   * @dev Safely transfers the ownership of a given token ID to another address
   * @dev If the target address is a contract, it must implement `onERC721Received`,
   *  which is called upon a safe transfer, and return the magic value
   *  `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`; otherwise,
   *  the transfer is reverted.
   * @dev Requires the msg sender to be the owner, approved, or operator
   * @param _from current owner of the token
   * @param _to address to receive the ownership of the given token ID
   * @param _tokenId uint256 ID of the token to be transferred
  */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
    canTransfer(_tokenId)
  {
    // solium-disable-next-line arg-overflow
    safeTransferFrom(_from, _to, _tokenId, "");
  }

  /**
   * @dev Safely transfers the ownership of a given token ID to another address
   * @dev If the target address is a contract, it must implement `onERC721Received`,
   *  which is called upon a safe transfer, and return the magic value
   *  `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`; otherwise,
   *  the transfer is reverted.
   * @dev Requires the msg sender to be the owner, approved, or operator
   * @param _from current owner of the token
   * @param _to address to receive the ownership of the given token ID
   * @param _tokenId uint256 ID of the token to be transferred
   * @param _data bytes data to send along with a safe transfer check
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public
    canTransfer(_tokenId)
  {
    transferFrom(_from, _to, _tokenId);
    // solium-disable-next-line arg-overflow
    require(checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
  }

  /**
   * @dev Returns whether the given spender can transfer a given token ID
   * @param _spender address of the spender to query
   * @param _tokenId uint256 ID of the token to be transferred
   * @return bool whether the msg.sender is approved for the given token ID,
   *  is an operator of the owner, or is the owner of the token
   */
  function isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
    address owner = ownerOf(_tokenId);
    return _spender == owner || getApproved(_tokenId) == _spender || isApprovedForAll(owner, _spender);
  }

  /**
   * @dev Internal function to mint a new token
   * @dev Reverts if the given token ID already exists
   * @param _to The address that will own the minted token
   * @param _tokenId uint256 ID of the token to be minted by the msg.sender
   */
  function _mint(address _to, uint256 _tokenId) internal {
    require(_to != address(0));
    addTokenTo(_to, _tokenId);
    emit Transfer(address(0), _to, _tokenId);
  }

  /**
   * @dev Internal function to burn a specific token
   * @dev Reverts if the token does not exist
   * @param _tokenId uint256 ID of the token being burned by the msg.sender
   */
  function _burn(address _owner, uint256 _tokenId) internal {
    clearApproval(_owner, _tokenId);
    removeTokenFrom(_owner, _tokenId);
    emit Transfer(_owner, address(0), _tokenId);
  }

  /**
   * @dev Internal function to clear current approval of a given token ID
   * @dev Reverts if the given address is not indeed the owner of the token
   * @param _owner owner of the token
   * @param _tokenId uint256 ID of the token to be transferred
   */
  function clearApproval(address _owner, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _owner);
    if (tokenApprovals[_tokenId] != address(0)) {
      tokenApprovals[_tokenId] = address(0);
      emit Approval(_owner, address(0), _tokenId);
    }
  }

  /**
   * @dev Internal function to add a token ID to the list of a given address
   * @param _to address representing the new owner of the given token ID
   * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
   */
  function addTokenTo(address _to, uint256 _tokenId) internal {
    require(tokenOwner[_tokenId] == address(0));
    tokenOwner[_tokenId] = _to;
    ownedTokensCount[_to] = ownedTokensCount[_to].add(1);
  }

  /**
   * @dev Internal function to remove a token ID from the list of a given address
   * @param _from address representing the previous owner of the given token ID
   * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
   */
  function removeTokenFrom(address _from, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _from);
    ownedTokensCount[_from] = ownedTokensCount[_from].sub(1);
    tokenOwner[_tokenId] = address(0);
  }

  /**
   * @dev Internal function to invoke `onERC721Received` on a target address
   * @dev The call is not executed if the target address is not a contract
   * @param _from address representing the previous owner of the given token ID
   * @param _to target address that will receive the tokens
   * @param _tokenId uint256 ID of the token to be transferred
   * @param _data bytes optional data to send along with the call
   * @return whether the call correctly returned the expected magic value
   */
  function checkAndCallSafeTransfer(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    internal
    returns (bool)
  {
    if (!_to.isContract()) {
      return true;
    }
    bytes4 retval = ERC721Receiver(_to).onERC721Received(_from, _tokenId, _data);
    return (retval == ERC721_RECEIVED);
  }
}

// File: openzeppelin-solidity/contracts/token/ERC721/ERC721Token.sol

/**
 * @title Full ERC721 Token
 * This implementation includes all the required and some optional functionality of the ERC721 standard
 * Moreover, it includes approve all functionality using operator terminology
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Token is ERC721, ERC721BasicToken {
  // Token name
  string internal name_;

  // Token symbol
  string internal symbol_;

  // Mapping from owner to list of owned token IDs
  mapping (address => uint256[]) internal ownedTokens;

  // Mapping from token ID to index of the owner tokens list
  mapping(uint256 => uint256) internal ownedTokensIndex;

  // Array with all token ids, used for enumeration
  uint256[] internal allTokens;

  // Mapping from token id to position in the allTokens array
  mapping(uint256 => uint256) internal allTokensIndex;

  // Optional mapping for token URIs
  mapping(uint256 => string) internal tokenURIs;

  /**
   * @dev Constructor function
   */
  function ERC721Token(string _name, string _symbol) public {
    name_ = _name;
    symbol_ = _symbol;
  }

  /**
   * @dev Gets the token name
   * @return string representing the token name
   */
  function name() public view returns (string) {
    return name_;
  }

  /**
   * @dev Gets the token symbol
   * @return string representing the token symbol
   */
  function symbol() public view returns (string) {
    return symbol_;
  }

  /**
   * @dev Returns an URI for a given token ID
   * @dev Throws if the token ID does not exist. May return an empty string.
   * @param _tokenId uint256 ID of the token to query
   */
  function tokenURI(uint256 _tokenId) public view returns (string) {
    require(exists(_tokenId));
    return tokenURIs[_tokenId];
  }

  /**
   * @dev Gets the token ID at a given index of the tokens list of the requested owner
   * @param _owner address owning the tokens list to be accessed
   * @param _index uint256 representing the index to be accessed of the requested tokens list
   * @return uint256 token ID at the given index of the tokens list owned by the requested address
   */
  function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256) {
    require(_index < balanceOf(_owner));
    return ownedTokens[_owner][_index];
  }

  /**
   * @dev Gets the total amount of tokens stored by the contract
   * @return uint256 representing the total amount of tokens
   */
  function totalSupply() public view returns (uint256) {
    return allTokens.length;
  }

  /**
   * @dev Gets the token ID at a given index of all the tokens in this contract
   * @dev Reverts if the index is greater or equal to the total number of tokens
   * @param _index uint256 representing the index to be accessed of the tokens list
   * @return uint256 token ID at the given index of the tokens list
   */
  function tokenByIndex(uint256 _index) public view returns (uint256) {
    require(_index < totalSupply());
    return allTokens[_index];
  }

  /**
   * @dev Internal function to set the token URI for a given token
   * @dev Reverts if the token ID does not exist
   * @param _tokenId uint256 ID of the token to set its URI
   * @param _uri string URI to assign
   */
  function _setTokenURI(uint256 _tokenId, string _uri) internal {
    require(exists(_tokenId));
    tokenURIs[_tokenId] = _uri;
  }

  /**
   * @dev Internal function to add a token ID to the list of a given address
   * @param _to address representing the new owner of the given token ID
   * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
   */
  function addTokenTo(address _to, uint256 _tokenId) internal {
    super.addTokenTo(_to, _tokenId);
    uint256 length = ownedTokens[_to].length;
    ownedTokens[_to].push(_tokenId);
    ownedTokensIndex[_tokenId] = length;
  }

  /**
   * @dev Internal function to remove a token ID from the list of a given address
   * @param _from address representing the previous owner of the given token ID
   * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
   */
  function removeTokenFrom(address _from, uint256 _tokenId) internal {
    super.removeTokenFrom(_from, _tokenId);

    uint256 tokenIndex = ownedTokensIndex[_tokenId];
    uint256 lastTokenIndex = ownedTokens[_from].length.sub(1);
    uint256 lastToken = ownedTokens[_from][lastTokenIndex];

    ownedTokens[_from][tokenIndex] = lastToken;
    ownedTokens[_from][lastTokenIndex] = 0;
    // Note that this will handle single-element arrays. In that case, both tokenIndex and lastTokenIndex are going to
    // be zero. Then we can make sure that we will remove _tokenId from the ownedTokens list since we are first swapping
    // the lastToken to the first position, and then dropping the element placed in the last position of the list

    ownedTokens[_from].length--;
    ownedTokensIndex[_tokenId] = 0;
    ownedTokensIndex[lastToken] = tokenIndex;
  }

  /**
   * @dev Internal function to mint a new token
   * @dev Reverts if the given token ID already exists
   * @param _to address the beneficiary that will own the minted token
   * @param _tokenId uint256 ID of the token to be minted by the msg.sender
   */
  function _mint(address _to, uint256 _tokenId) internal {
    super._mint(_to, _tokenId);

    allTokensIndex[_tokenId] = allTokens.length;
    allTokens.push(_tokenId);
  }

  /**
   * @dev Internal function to burn a specific token
   * @dev Reverts if the token does not exist
   * @param _owner owner of the token to burn
   * @param _tokenId uint256 ID of the token being burned by the msg.sender
   */
  function _burn(address _owner, uint256 _tokenId) internal {
    super._burn(_owner, _tokenId);

    // Clear metadata (if any)
    if (bytes(tokenURIs[_tokenId]).length != 0) {
      delete tokenURIs[_tokenId];
    }

    // Reorg all tokens array
    uint256 tokenIndex = allTokensIndex[_tokenId];
    uint256 lastTokenIndex = allTokens.length.sub(1);
    uint256 lastToken = allTokens[lastTokenIndex];

    allTokens[tokenIndex] = lastToken;
    allTokens[lastTokenIndex] = 0;

    allTokens.length--;
    allTokensIndex[_tokenId] = 0;
    allTokensIndex[lastToken] = tokenIndex;
  }

}

// File: contracts/Galaxy/UniverseGalaxyStore.sol

contract UniverseGalaxyStore is IUniverseGalaxy, ERC721Token, Whitelist, AccessControl, Random, MathTools, ArrayArchiveTools {
    /*** EVENTS ***/
    event PlanetCreated(
        address indexed owner,
        uint256 indexed planetId,
        uint256 sectorX,
        uint256 sectorY,
        uint256 rarity,
        uint256[MAX_ID_LIST_LENGTH] resourcesId,
        uint256[MAX_ID_LIST_LENGTH] resourcesVelocity,
        uint256 startPopulation
    );

    /*** DATA TYPES ***/

    struct Planet {
        uint256 rarity;
        uint256 discovered;
        uint256 updated;
        uint256 sectorX;
        uint256 sectorY;
        uint[MAX_ID_LIST_LENGTH] resourcesId;
        uint[MAX_ID_LIST_LENGTH] resourcesVelocity;
        uint[MAX_ID_LIST_LENGTH] resourcesUpdated;
    }

    /*** STORAGE ***/

    //    struct Planet {
    //        uint48 discovered;
    //        uint40 resourcesId;
    //        uint40 resourcesVelocity;
    //        uint8 sectorX;
    //        uint8 sectorY;
    //        uint8 rarity;
    //    }
    uint256[] public planets;

    //    struct PlanetState {
    //        uint48 updated;
    //        uint40 resourcesId;
    //        uint80 resourcesUpdated;
    //    }
    mapping (uint256 => uint256) planetStates;

    // x => (y => discovered_planet_count)
    mapping (uint => mapping ( uint => uint )) discoveredPlanetsCountMap;

    // group index => rarity => discovered planet count
    mapping (uint => mapping (uint => uint)) planetCountByRarityInGroups;

    // rarity => discovered planet count in galaxy
    mapping (uint => uint) planetCountByRarity;

    IUniverseBalance public universeBalance;
    IUniversePlanetExploration public universePlanetExploration;

    function UniverseGalaxyStore() ERC721Token("0xUniverse", "PLANET")
    public { }

    function _getPlanet(uint256 _id)
    internal view
    returns(Planet memory _planet)
    {
        uint256 planet = planets[_id];
        uint256 planetState = planetStates[_id];

        _planet.discovered = uint256(uint48(planet));
        _planet.resourcesId = _splitUint40ToArray(uint40(planet >> 48));
        _planet.resourcesVelocity = _splitUint40ToArray(uint40(planet >> 88));
        _planet.sectorX = uint256(uint8(planet >> 128));
        _planet.sectorY = uint256(uint8(planet >> 136));
        _planet.rarity = uint256(uint8(planet >> 144));

        _planet.updated = uint256(uint48(planetState));
        _planet.resourcesUpdated = _splitUint80ToArray(uint80(planetState >> 88));
    }

    function _convertPlanetToPlanetHash(Planet memory _planet)
    internal
    pure
    returns(uint256 _planetHash)
    {
        _planetHash = _planet.discovered;
        _planetHash |= _mergeArrayToUint40(_planet.resourcesId) << 48;
        _planetHash |= _mergeArrayToUint40(_planet.resourcesVelocity) << 88;
        _planetHash |= _planet.sectorX << 128;
        _planetHash |= _planet.sectorY << 136;
        _planetHash |= uint256(_planet.rarity) << 144;
    }

    function _convertPlanetToPlanetStateHash(Planet memory _planet)
    internal
    pure
    returns(uint256 _planetStateHash)
    {
        _planetStateHash = _planet.updated;
        _planetStateHash |= _mergeArrayToUint40(_planet.resourcesId) << 48;
        _planetStateHash |= _mergeArrayToUint80(_planet.resourcesUpdated) << 88;
    }

    function getDiscoveredPlanetsDensity(uint sectorX, uint sectorY) external view returns (uint) {
        uint discoveredPlanetsCount = discoveredPlanetsCountMap[sectorX][sectorY];
        // жёсткая проверка на количество планет в секторе и защита от переполнения переменной
        if (discoveredPlanetsCount >= PLANETS_COUNT_PER_SECTOR) {
            return 0;
        }
        return 100 - (discoveredPlanetsCount * 100) / PLANETS_COUNT_PER_SECTOR;
    }

    function countPlanetsByRarityInGroup(uint _groupIndex, uint _rarity) external view returns (uint){
        return planetCountByRarityInGroups[_groupIndex][_rarity];
    }

    function countPlanetsByRarity(uint _rarity) external view returns (uint){
        return planetCountByRarity[_rarity];
    }

    function setUniverseBalanceAddress(address _address) external onlyOwner {
        IUniverseBalance candidateContract = IUniverseBalance(_address);

        // NOTE: verify that a contract is what we expect
        // https://github.com/Lunyr/crowdsale-contracts/blob/cfadd15986c30521d8ba7d5b6f57b4fefcc7ac38/contracts/LunyrToken.sol#L117
        require(candidateContract.isUniverseBalance(), "Incorrect address param");

        // Set the new contract address
        universeBalance = candidateContract;
    }

    function setUniversePlanetExplorationAddress(address _address) external onlyOwner {
        IUniversePlanetExploration candidateContract = IUniversePlanetExploration(_address);

        // NOTE: verify that a contract is what we expect
        // https://github.com/Lunyr/crowdsale-contracts/blob/cfadd15986c30521d8ba7d5b6f57b4fefcc7ac38/contracts/LunyrToken.sol#L117
        require(candidateContract.isUniversePlanetExploration(), "Incorrect address param");

        // Set the new contract address
        universePlanetExploration = candidateContract;
    }

    function getPlanet(uint256 _id)
    external
    view
    returns (
        uint256 rarity,
        uint256 discovered,
        uint256 sectorX,
        uint256 sectorY,
        uint256[MAX_ID_LIST_LENGTH] resourcesId,
        uint256[MAX_ID_LIST_LENGTH] resourcesVelocity
    ) {
        Planet memory pl = _getPlanet(_id);

        rarity = pl.rarity;
        discovered = pl.discovered;
        sectorX = pl.sectorX;
        sectorY = pl.sectorY;
        resourcesId = pl.resourcesId;
        resourcesVelocity = pl.resourcesVelocity;
    }

    function _getOwnedTokensCount(address _owner) internal view returns (uint256){
        return ownedTokens[_owner].length;
    }

    function _getOwnedTokensByIndex(address _owner, uint256 _ownerTokenIndex) internal view returns (uint256){
        return ownedTokens[_owner][_ownerTokenIndex];
    }

    function findAvailableResource(address _owner, uint _rarity) external returns (int8) {
        uint ownedPlanetsCount = _getOwnedTokensCount(_owner);

        uint[] memory resourceList = new uint[](ownedPlanetsCount * MAX_ID_LIST_LENGTH);

        uint[2] memory resourcesOrderByRarity = universeBalance.getResourcesQuantityByRarity(_rarity);
        uint firstResourceId = resourcesOrderByRarity[0];
        uint lastResourceId = resourcesOrderByRarity[0] + resourcesOrderByRarity[1] - 1;

        uint maxResourceListElement = 0;
        for (uint i = 0; i < ownedPlanetsCount; i++) {
            Planet memory planet = _getPlanet( _getOwnedTokensByIndex(_owner, i) );

            for (uint k = 1; k < planet.resourcesId.length; k++) {
                uint resourceId = planet.resourcesId[k];
                if(resourceId == 0) break;

                if(resourceId >= firstResourceId && resourceId <= lastResourceId) {
                    resourceList[maxResourceListElement] = resourceId; // замена resourceList.push(j);
                    maxResourceListElement++;
                }
            }
        }

        if (maxResourceListElement > 0) { // выбираем из них один случайный
            return int8(resourceList[_randRange(0, maxResourceListElement - 1)]);
        } else {
            return -1;
        }
    }

    function createPlanet(
        address _owner,
        uint256 _rarity,
        uint256 _sectorX,
        uint256 _sectorY,
        uint256 _startPopulation
    )
    external
    onlyWhitelisted
    returns (uint256)
    {
        Planet memory planet = _createPlanetWithRandomResources(_rarity, _sectorX, _sectorY, _startPopulation);
        return _savePlanet(_owner, planet);
    }

    function _savePlanet(
        address _owner,
        Planet _planet
    )
    internal
    returns (uint)
    {
        uint256 planet = _convertPlanetToPlanetHash(_planet);
        uint256 planetState = _convertPlanetToPlanetStateHash(_planet);

        uint256 newPlanetId = planets.push(planet) - 1;
        planetStates[newPlanetId] = planetState;

        require(newPlanetId < PLANETS_COUNT, "No more planets");

        emit PlanetCreated(
            _owner,
            newPlanetId,
            _planet.sectorX,
            _planet.sectorY,
            _planet.rarity,
            _planet.resourcesId,
            _planet.resourcesVelocity,
            _planet.resourcesUpdated[0]
        );

        discoveredPlanetsCountMap[_planet.sectorX][_planet.sectorY] += 1;

        if (_planet.rarity == 3) {
            uint groupIndex = universeBalance.getGroupId(_planet.sectorX, _planet.sectorY);
            planetCountByRarityInGroups[groupIndex][3] += 1;
        }

        if (_planet.rarity == 4) {
            planetCountByRarity[4] += 1;
        }

        _mint(_owner, newPlanetId);

        return newPlanetId;
    }

    function _createPlanetWithRandomResources(uint _rarity, uint _sectorX, uint _sectorY, uint _startPopulation)
    internal
    returns (Planet memory _planet)
    {
        uint[MAX_ID_LIST_LENGTH] memory resourcesId;
        uint[MAX_ID_LIST_LENGTH] memory resourcesVelocity;
        (resourcesId, resourcesVelocity) = universePlanetExploration.explorePlanet(_rarity);

        uint[MAX_ID_LIST_LENGTH] memory resourcesUpdated;
        resourcesUpdated[0] = _startPopulation;

        _planet = Planet({
            rarity: _rarity,
            discovered: uint256(now),
            updated: uint256(now),
            sectorX: _sectorX,
            sectorY: _sectorY,
            resourcesId: resourcesId,
            resourcesVelocity: resourcesVelocity,
            resourcesUpdated: resourcesUpdated
            });
    }
}

// File: contracts/Galaxy/UniverseAuction.sol

contract UniverseAuction is UniverseGalaxyStore {

    ISaleClockAuction public saleAuction;

    function setSaleAuctionAddress(address _address) external onlyOwner {
        ISaleClockAuction candidateContract = ISaleClockAuction(_address);

        // NOTE: verify that a contract is what we expect - https://github.com/Lunyr/crowdsale-contracts/blob/cfadd15986c30521d8ba7d5b6f57b4fefcc7ac38/contracts/LunyrToken.sol#L117
        require(candidateContract.isSaleClockAuction(), "Incorrect address param");

        // Set the new contract address
        saleAuction = candidateContract;
    }

    function createSaleAuction(
        uint256 _planetId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    )
    external
    whenNotPaused
    {
        if (universeBalance.autoClearAuction()) saleAuction.clearOne(msg.sender, _planetId);
        // Auction contract checks input sizes
        // If planet is already on any auction, this will throw
        // because it will be owned by the auction contract.
        require(ownerOf(_planetId) == msg.sender, "Not owner");

        approve(saleAuction, _planetId);
        // Sale auction throws if inputs are invalid and clears
        // transfer approval after escrowing the planet.
        saleAuction.createAuction(
            _planetId,
            _startingPrice,
            _endingPrice,
            _duration,
            msg.sender
        );
    }

    function withdrawAuctionBalances() external onlyTeam {
        saleAuction.withdrawBalance();
    }
}

// File: contracts/Galaxy/UniverseGalaxyState.sol

contract UniverseGalaxyState is UniverseAuction {

    uint internal constant SECONDS_IN_DAY = 60 * 60 * 24;

    mapping (address => uint) public ownerToKnowledge;
    mapping (address => uint) public lastKnowledgeSpentDateByOwner;

    function getPlanetUpdatedResources(uint256 _id)
    external
    view
    returns (
        uint256 updated,
        uint256[MAX_ID_LIST_LENGTH] resourcesId,
        uint256[MAX_ID_LIST_LENGTH] resourcesUpdated
    ) {
        Planet memory pl = _getPlanet(_id);

        updated = pl.updated;
        resourcesId = pl.resourcesId;
        resourcesUpdated = pl.resourcesUpdated;
    }

    function spendResourceOnPlanet(
        address _owner,
        uint _planetId,
        uint _resourceId,
        uint _resourceValue
    )
    external
    onlyWhitelisted
    {
        require(_owner != address(0), "Owner param should be defined");
        require(_resourceValue > 0, "ResourceValue param should be bigger that zero");

        Planet memory planet = _getPlanet(_planetId);
        planet = _recountPlanetStateAndUpdateUserKnowledge(_owner, planet);

        require(planet.resourcesUpdated[_resourceId] >= _resourceValue, "Resource current should be bigger that ResourceValue");

        planet.resourcesUpdated[_resourceId] -= _resourceValue;
        _updatePlanetStateHash(_planetId, planet);
    }

    function spendResources(
        address _owner,
        uint[MAX_ID_LIST_LENGTH] _resourcesId,
        uint[MAX_ID_LIST_LENGTH] _resourcesNeeded
    ) external onlyWhitelisted {
        uint ownedPlanetsCount = _getOwnedTokensCount(_owner);

        for (uint j = 0; j < _resourcesId.length; j++) { // 0-4
            uint resourceId = _resourcesId[j];
            uint resourceNeeded = _resourcesNeeded[j];

            if (resourceNeeded == 0) { continue; }

            for (uint i = 0; i < ownedPlanetsCount; i++) { // 0-n
                if (resourceNeeded == 0) { break; }

                uint planetId = _getOwnedTokensByIndex(_owner, i);
                Planet memory planet = _getPlanet(planetId);

                uint foundResourceIndex = 9999;

                for (uint k = 0; k < planet.resourcesId.length; k++) { //0-4
                    if (resourceId == planet.resourcesId[k]) {
                        foundResourceIndex = k;
                        break;
                    }
                }

                if(foundResourceIndex == 9999) {continue;}

                planet = _recountPlanetStateAndUpdateUserKnowledge(_owner, planet);
                if (planet.resourcesUpdated[foundResourceIndex] > 0) {
                    if (planet.resourcesUpdated[foundResourceIndex] >= resourceNeeded) {
                        planet.resourcesUpdated[foundResourceIndex] -= resourceNeeded;
                        resourceNeeded = 0;
                    } else {
                        resourceNeeded -= planet.resourcesUpdated[foundResourceIndex];
                        planet.resourcesUpdated[foundResourceIndex] = 0;
                    }
                }
                _updatePlanetStateHash(planetId, planet);

            }

            if (resourceNeeded > 0) {
                revert("NotEnoughResources");
            }
        }
    }

    function spendKnowledge(address _owner, uint _spentKnowledge) external onlyWhitelisted {
        if (ownerToKnowledge[_owner] < _spentKnowledge) {
            uint balanceVelocity = universeBalance.getUIntValue(/* "settings_time_velocity" */ 34);

            uint spentKnowledge = _spentKnowledge * SECONDS_IN_DAY; // защита от потерь при округлении

            uint knowledge = ownerToKnowledge[_owner] * SECONDS_IN_DAY;

            uint ownedPlanetsCount = _getOwnedTokensCount(_owner);

            bool enoughKnowledge = false;

            for (uint i = 0; i < ownedPlanetsCount; i++) {
                Planet memory planet = _getPlanet( _getOwnedTokensByIndex(_owner, i) );

                uint interval = (_now() - _getLastKnowledgeUpdateForPlanet(_owner, planet)) * balanceVelocity;
                knowledge += (planet.resourcesUpdated[0] + _divisionWithRound(planet.resourcesVelocity[0] * interval, 2 * SECONDS_IN_DAY))
                    * universeBalance.getUIntValue(/* "planets_knowledgePerPeoplePerDay" */17)
                    * interval;

                if (knowledge >= spentKnowledge) {
                    enoughKnowledge = true;
                    break;
                }
            }

            if(!enoughKnowledge) {
                revert("NotEnoughKnowledge");
            }
        }

        ownerToKnowledge[_owner] = 0;
        lastKnowledgeSpentDateByOwner[_owner] = _now();
    }

    // Only for test purpose
    function getCurrentKnowledgeOfOwner(address _owner) external view returns(uint) {
        uint balanceVelocity = universeBalance.getUIntValue(/* "settings_time_velocity" */ 34);

        uint knowledge = ownerToKnowledge[_owner] * SECONDS_IN_DAY;

        uint ownedPlanetsCount = _getOwnedTokensCount(_owner);

        for (uint i = 0; i < ownedPlanetsCount; i++) {
            Planet memory planet = _getPlanet( _getOwnedTokensByIndex(_owner, i) );

            uint interval = (_now() - _getLastKnowledgeUpdateForPlanet(_owner, planet)) * balanceVelocity;
            knowledge += (planet.resourcesUpdated[0] + _divisionWithRound(planet.resourcesVelocity[0] * interval, 2 * SECONDS_IN_DAY))
                * universeBalance.getUIntValue(/* "planets_knowledgePerPeoplePerDay" */17)
                * interval;
        }

        return _divisionWithRound(knowledge, SECONDS_IN_DAY);
    }

    function recountPlanetResourcesAndUserKnowledge(address _owner, uint256 _planetId) external onlyWhitelisted {
        Planet memory planet = _getPlanet(_planetId);
        planet = _recountPlanetStateAndUpdateUserKnowledge(_owner, planet);
        _updatePlanetStateHash(_planetId, planet);
    }

    function _updatePlanetStateHash(uint256 _planetID, Planet memory _planet) internal {
        _planet.updated = _now();

        uint256 planetState = _convertPlanetToPlanetStateHash(_planet);
        planetStates[_planetID] = planetState;
    }

    function _getLastKnowledgeUpdateForPlanet(address _owner, Planet memory _planet) internal view returns (uint256) {
        return ((_planet.updated > lastKnowledgeSpentDateByOwner[_owner]) ? _planet.updated : lastKnowledgeSpentDateByOwner[_owner]);
    }

    function _recountPlanetStateAndUpdateUserKnowledge(address _owner, Planet memory _planet) internal returns (Planet) {
        uint balanceVelocity = universeBalance.getUIntValue(/* "settings_time_velocity" */ 34);

        // update knowledge
        uint intervalForKnowledge = (_now() - _getLastKnowledgeUpdateForPlanet(_owner, _planet)) * balanceVelocity;
        uint knowledge = (_planet.resourcesUpdated[0] + _divisionWithRound(_planet.resourcesVelocity[0] * intervalForKnowledge, 2 * SECONDS_IN_DAY))
            * universeBalance.getUIntValue(/* "planets_knowledgePerPeoplePerDay" */ 17)
            * intervalForKnowledge;

        ownerToKnowledge[_owner] += _divisionWithRound(knowledge, SECONDS_IN_DAY);


        // update resources
        uint interval = (_now() - _planet.updated) * balanceVelocity;

        uint resourcesMultiplierMAX = universeBalance.getUIntValue(/* "planets_resourcesMaxModifier" */ 18);

        // начал j с 0, чтобы и на людей ограничение распространялось. -1 вроде был лишним, там строго меньше сравнение
        for (uint j = 0; j < _planet.resourcesVelocity.length; j++) {
            if (_planet.resourcesVelocity[j] == 0) { continue; }

            _planet.resourcesUpdated[j] += _divisionWithRound(_planet.resourcesVelocity[j] * interval, SECONDS_IN_DAY);

            uint maxResourceAmount = _planet.resourcesVelocity[j] * resourcesMultiplierMAX;
            if (_planet.resourcesUpdated[j] > maxResourceAmount) {
                _planet.resourcesUpdated[j] = maxResourceAmount;
            }
        }

        return _planet;
    }

    function getPlanetCurrentResources(uint _planetId) external view returns (uint[MAX_ID_LIST_LENGTH]) {
        uint balanceVelocity = universeBalance.getUIntValue(/* "settings_time_velocity" */ 34);

        Planet memory planet = _getPlanet(_planetId);

        uint interval = (_now() - planet.updated) * balanceVelocity;

        uint[MAX_ID_LIST_LENGTH] memory velocities = planet.resourcesVelocity;

        uint resourcesMultiplierMAX = universeBalance.getUIntValue(/* "planets_resourcesMaxModifier" */ 18);

        // начал j с 0, чтобы и на людей ограничение распространялось. -1 вроде был лишним, там строго меньше сравнение
        for (uint j = 0; j < velocities.length; j++) {
            if (velocities[j] == 0) { continue; }

            planet.resourcesUpdated[j] += _divisionWithRound(planet.resourcesVelocity[j] * interval, SECONDS_IN_DAY);

            uint maxResourceAmount = planet.resourcesVelocity[j] * resourcesMultiplierMAX;
            if (planet.resourcesUpdated[j] > maxResourceAmount) {
                planet.resourcesUpdated[j] = maxResourceAmount;
            }
        }

        return planet.resourcesUpdated;
    }
}

// File: contracts/Galaxy/UniverseGalaxy.sol

contract UniverseGalaxy is UniverseGalaxyState {

    uint256 public constant PROMO_PLANETS_LIMIT = 10000;

    uint256 public promoCreatedCount;

    function UniverseGalaxy() public {
        paused = true;
        transferTreasurer(owner);
    }

    function initialize(address _earthOwner) external onlyOwner {
        require(planets.length == 0, "Earth was created");

        uint[2] memory earthSector = universeBalance.getUIntArray2Value(/* "earth_planet_sector" */ 20);

        uint[3] memory earthResourcesId = universeBalance.getUIntArray3Value(/* "earth_planet_resources_m_keys" */ 21);
        uint[3] memory earthResourcesVelocity = universeBalance.getUIntArray3Value(/* "earth_planet_resources_m_values" */ 22);
        uint[3] memory earthResourcesUpdated = universeBalance.getUIntArray3Value(/* "earth_planet_resourcesUpdated_m_values" */ 24);

        Planet memory earth = Planet({
            rarity: 3,
            discovered: uint256(now),
            updated: uint256(now),
            sectorX: earthSector[0],
            sectorY: earthSector[1],
            resourcesId: [earthResourcesId[0], earthResourcesId[1], earthResourcesId[2], 0, 0],
            resourcesVelocity: [earthResourcesVelocity[0], earthResourcesVelocity[1], earthResourcesVelocity[2], 0, 0],
            resourcesUpdated: [earthResourcesUpdated[0], earthResourcesUpdated[1], earthResourcesUpdated[2], 0, 0]
            });

        _savePlanet(_earthOwner, earth);
    }

    function checkWhetherEnoughPromoPlanet()
    external
    onlyWhitelisted
    {
        promoCreatedCount++;

        require( promoCreatedCount < PROMO_PLANETS_LIMIT, "Promo planet limit is reached" );
    }

    function() external payable onlyWhitelisted {
    }

    function unpause() public onlyOwner whenPaused {
        require(saleAuction != address(0), "SaleClock contract should be defined");
        require(universeBalance != address(0), "Balance contract should be defined");

        // Actually unpause the contract.
        super.unpause();
    }

    function withdrawBalance() external onlyTreasurer {
        uint256 balance = address(this).balance;

        treasurer.transfer(balance);
    }
}