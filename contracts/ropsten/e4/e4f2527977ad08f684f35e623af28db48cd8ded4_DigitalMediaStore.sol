/**
 *Submitted for verification at Etherscan.io on 2021-12-07
*/

/**
 *Submitted for verification at Etherscan.io on 2019-06-12
*/

// File: REMIX_FILE_SYNC/openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.4.21;


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

// File: REMIX_FILE_SYNC/ApprovedCreatorRegistryInterface.sol

pragma solidity ^0.4.22;


/**
 * Interface to the digital media store external contract that is 
 * responsible for storing the common digital media and collection data.
 * This allows for new token contracts to be deployed and continue to reference
 * the digital media and collection data.
 */
contract ApprovedCreatorRegistryInterface {

    function getVersion() public pure returns (uint);
    function typeOfContract() public pure returns (string);
    function isOperatorApprovedForCustodialAccount(
        address _operator,
        address _custodialAddress) public view returns (bool);

}

// File: REMIX_FILE_SYNC/DigitalMediaStoreInterface.sol

pragma solidity 0.4.25;


/**
 * Interface to the digital media store external contract that is 
 * responsible for storing the common digital media and collection data.
 * This allows for new token contracts to be deployed and continue to reference
 * the digital media and collection data.
 */
contract DigitalMediaStoreInterface {

    function getDigitalMediaStoreVersion() public pure returns (uint);

    function getStartingDigitalMediaId() public view returns (uint256);

    function registerTokenContractAddress() external;

    /**
     * Creates a new digital media object in storage
     * @param  _creator address the address of the creator
     * @param  _printIndex uint32 the current print index for the limited edition media
     * @param  _totalSupply uint32 the total allowable prints for this media
     * @param  _collectionId uint256 the collection id that this media belongs to
     * @param  _metadataPath string the ipfs metadata path
     * @return the id of the new digital media created
     */
    function createDigitalMedia(
                address _creator, 
                uint32 _printIndex, 
                uint32 _totalSupply, 
                uint256 _collectionId, 
                string _metadataPath) external returns (uint);

    /**
     * Increments the current print index of the digital media object
     * @param  _digitalMediaId uint256 the id of the digital media
     * @param  _increment uint32 the amount to increment by
     */
    function incrementDigitalMediaPrintIndex(
                uint256 _digitalMediaId, 
                uint32 _increment)  external;

    /**
     * Retrieves the digital media object by id
     * @param  _digitalMediaId uint256 the address of the creator
     */
    function getDigitalMedia(uint256 _digitalMediaId) external view returns(
                uint256 id,
                uint32 totalSupply,
                uint32 printIndex,
                uint256 collectionId,
                address creator,
                string metadataPath);

    /**
     * Creates a new collection
     * @param  _creator address the address of the creator
     * @param  _metadataPath string the ipfs metadata path
     * @return the id of the new collection created
     */
    function createCollection(address _creator, string _metadataPath) external returns (uint);

    /**
     * Retrieves a collection by id
     * @param  _collectionId uint256
     */
    function getCollection(uint256 _collectionId) external view
            returns(
                uint256 id,
                address creator,
                string metadataPath);
}

// File: REMIX_FILE_SYNC/openzeppelin-solidity/contracts/ownership/Ownable.sol

pragma solidity ^0.4.21;


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

// File: REMIX_FILE_SYNC/openzeppelin-solidity/contracts/lifecycle/Pausable.sol

pragma solidity ^0.4.21;



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

// File: REMIX_FILE_SYNC/MediaStoreVersionControl.sol

pragma solidity 0.4.25;



/**
 * A special control class that is used to configure and manage a token contract's 
 * different digital media store versions.
 *
 * Older versions of token contracts had the ability to increment the digital media's
 * print edition in the media store, which was necessary in the early stages to provide
 * upgradeability and flexibility.
 *
 * New verions will get rid of this ability now that token contract logic
 * is more stable and we've built in burn capabilities.  
 *
 * In order to support the older tokens, we need to be able to look up the appropriate digital
 * media store associated with a given digital media id on the latest token contract.
 */
contract MediaStoreVersionControl is Pausable {

    // The single allowed creator for this digital media contract.
    DigitalMediaStoreInterface public v1DigitalMediaStore;

    // The current digitial media store, used for this tokens creation.
    DigitalMediaStoreInterface public currentDigitalMediaStore;
    uint256 public currentStartingDigitalMediaId;


    /**
     * Validates that the managers are initialized.
     */
    modifier managersInitialized() {
        require(v1DigitalMediaStore != address(0));
        require(currentDigitalMediaStore != address(0));
        _;
    }

    /**
     * Sets a digital media store address upon construction.  
     * Once set it's immutable, so that a token contract is always
     * tied to one digital media store.
     */
    function setDigitalMediaStoreAddress(address _dmsAddress)  
            internal {
        DigitalMediaStoreInterface candidateDigitalMediaStore = DigitalMediaStoreInterface(_dmsAddress);
        require(candidateDigitalMediaStore.getDigitalMediaStoreVersion() == 2, "Incorrect version.");
        currentDigitalMediaStore = candidateDigitalMediaStore;
        currentDigitalMediaStore.registerTokenContractAddress();
        currentStartingDigitalMediaId = currentDigitalMediaStore.getStartingDigitalMediaId();
    }

    /**
     * Publicly callable by the owner, but can only be set one time, so don't make 
     * a mistake when setting it.
     *
     * Will also check that the version on the other end of the contract is in fact correct.
     */
    function setV1DigitalMediaStoreAddress(address _dmsAddress) public onlyOwner {
        require(address(v1DigitalMediaStore) == 0, "V1 media store already set.");
        DigitalMediaStoreInterface candidateDigitalMediaStore = DigitalMediaStoreInterface(_dmsAddress);
        require(candidateDigitalMediaStore.getDigitalMediaStoreVersion() == 1, "Incorrect version.");
        v1DigitalMediaStore = candidateDigitalMediaStore;
        v1DigitalMediaStore.registerTokenContractAddress();
    }

    /**
     * Depending on the digital media id, determines whether to return the previous
     * version of the digital media manager.
     */
    function _getDigitalMediaStore(uint256 _digitalMediaId) 
            internal 
            view
            managersInitialized
            returns (DigitalMediaStoreInterface) {
        if (_digitalMediaId < currentStartingDigitalMediaId) {
            return v1DigitalMediaStore;
        } else {
            return currentDigitalMediaStore;
        }
    }  
}

// File: REMIX_FILE_SYNC/DigitalMediaManager.sol

pragma solidity 0.4.25;




/**
 * Manager that interfaces with the underlying digital media store contract.
 */
contract DigitalMediaManager is MediaStoreVersionControl {

    struct DigitalMedia {
        uint256 id;
        uint32 totalSupply;
        uint32 printIndex;
        uint256 collectionId;
        address creator;
        string metadataPath;
    }

    struct DigitalMediaCollection {
        uint256 id;
        address creator;
        string metadataPath;
    }

    ApprovedCreatorRegistryInterface public creatorRegistryStore;

    // Set the creator registry address upon construction. Immutable.
    function setCreatorRegistryStore(address _crsAddress) internal {
        ApprovedCreatorRegistryInterface candidateCreatorRegistryStore = ApprovedCreatorRegistryInterface(_crsAddress);
        require(candidateCreatorRegistryStore.getVersion() == 1);
        // Simple check to make sure we are adding the registry contract indeed
        // https://fravoll.github.io/solidity-patterns/string_equality_comparison.html
        require(keccak256(candidateCreatorRegistryStore.typeOfContract()) == keccak256("approvedCreatorRegistry"));
        creatorRegistryStore = candidateCreatorRegistryStore;
    }

    /**
     * Validates that the Registered store is initialized.
     */
    modifier registryInitialized() {
        require(creatorRegistryStore != address(0));
        _;
    }

    /**
     * Retrieves a collection object by id.
     */
    function _getCollection(uint256 _id) 
            internal 
            view 
            managersInitialized 
            returns(DigitalMediaCollection) {
        uint256 id;
        address creator;
        string memory metadataPath;
        (id, creator, metadataPath) = currentDigitalMediaStore.getCollection(_id);
        DigitalMediaCollection memory collection = DigitalMediaCollection({
            id: id,
            creator: creator,
            metadataPath: metadataPath
        });
        return collection;
    }

    /**
     * Retrieves a digital media object by id.
     */
    function _getDigitalMedia(uint256 _id) 
            internal 
            view 
            managersInitialized 
            returns(DigitalMedia) {
        uint256 id;
        uint32 totalSupply;
        uint32 printIndex;
        uint256 collectionId;
        address creator;
        string memory metadataPath;
        DigitalMediaStoreInterface _digitalMediaStore = _getDigitalMediaStore(_id);
        (id, totalSupply, printIndex, collectionId, creator, metadataPath) = _digitalMediaStore.getDigitalMedia(_id);
        DigitalMedia memory digitalMedia = DigitalMedia({
            id: id,
            creator: creator,
            totalSupply: totalSupply,
            printIndex: printIndex,
            collectionId: collectionId,
            metadataPath: metadataPath
        });
        return digitalMedia;
    }

    /**
     * Increments the print index of a digital media object by some increment.
     */
    function _incrementDigitalMediaPrintIndex(DigitalMedia _dm, uint32 _increment) 
            internal 
            managersInitialized {
        DigitalMediaStoreInterface _digitalMediaStore = _getDigitalMediaStore(_dm.id);
        _digitalMediaStore.incrementDigitalMediaPrintIndex(_dm.id, _increment);
    }

    // Check if the token operator is approved for the owner address
    function isOperatorApprovedForCustodialAccount(
        address _operator, 
        address _owner) internal view registryInitialized returns(bool) {
        return creatorRegistryStore.isOperatorApprovedForCustodialAccount(
            _operator, _owner);
    }
}

// File: REMIX_FILE_SYNC/SingleCreatorControl.sol

pragma solidity 0.4.25;


/**
 * A special control class that's used to help enforce that a DigitalMedia contract
 * will service only a single creator's address.  This is used when deploying a 
 * custom token contract owned and managed by a single creator.
 */
contract SingleCreatorControl {

    // The single allowed creator for this digital media contract.
    address public singleCreatorAddress;

    // The single creator has changed.
    event SingleCreatorChanged(
        address indexed previousCreatorAddress, 
        address indexed newCreatorAddress);

    /**
     * Sets the single creator associated with this contract.  This function
     * can only ever be called once, and should ideally be called at the point
     * of constructing the smart contract.
     */
    function setSingleCreator(address _singleCreatorAddress) internal {
        require(singleCreatorAddress == address(0), "Single creator address already set.");
        singleCreatorAddress = _singleCreatorAddress;
    }

    /**
     * Checks whether a given creator address matches the single creator address.
     * Will always return true if a single creator address was never set.
     */
    function isAllowedSingleCreator(address _creatorAddress) internal view returns (bool) {
        require(_creatorAddress != address(0), "0x0 creator addresses are not allowed.");
        return singleCreatorAddress == address(0) || singleCreatorAddress == _creatorAddress;
    }

    /**
     * A publicly accessible function that allows the current single creator
     * assigned to this contract to change to another address.
     */
    function changeSingleCreator(address _newCreatorAddress) public {
        require(_newCreatorAddress != address(0));
        require(msg.sender == singleCreatorAddress, "Not approved to change single creator.");
        singleCreatorAddress = _newCreatorAddress;
        emit SingleCreatorChanged(singleCreatorAddress, _newCreatorAddress);
    }
}

// File: REMIX_FILE_SYNC/openzeppelin-solidity/contracts/token/ERC721/ERC721Basic.sol

pragma solidity ^0.4.21;


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

// File: REMIX_FILE_SYNC/openzeppelin-solidity/contracts/token/ERC721/ERC721.sol

pragma solidity ^0.4.21;



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

// File: REMIX_FILE_SYNC/openzeppelin-solidity/contracts/token/ERC721/ERC721Receiver.sol

pragma solidity ^0.4.21;


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

// File: REMIX_FILE_SYNC/openzeppelin-solidity/contracts/AddressUtils.sol

pragma solidity ^0.4.21;


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

// File: REMIX_FILE_SYNC/openzeppelin-solidity/contracts/token/ERC721/ERC721BasicToken.sol

pragma solidity ^0.4.21;






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

// File: REMIX_FILE_SYNC/openzeppelin-solidity/contracts/token/ERC721/ERC721Token.sol

pragma solidity ^0.4.21;




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

// File: REMIX_FILE_SYNC/ERC721Safe.sol

pragma solidity 0.4.25;

// We have to specify what version of compiler this code will compile with



contract ERC721Safe is ERC721Token {
    bytes4 constant internal InterfaceSignature_ERC165 =
        bytes4(keccak256('supportsInterface(bytes4)'));

    bytes4 constant internal InterfaceSignature_ERC721 =
        bytes4(keccak256('name()')) ^
        bytes4(keccak256('symbol()')) ^
        bytes4(keccak256('totalSupply()')) ^
        bytes4(keccak256('balanceOf(address)')) ^
        bytes4(keccak256('ownerOf(uint256)')) ^
        bytes4(keccak256('approve(address,uint256)')) ^
        bytes4(keccak256('safeTransferFrom(address,address,uint256)'));
	
   function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}

// File: REMIX_FILE_SYNC/Memory.sol

pragma solidity 0.4.25;


library Memory {

    // Size of a word, in bytes.
    uint internal constant WORD_SIZE = 32;
    // Size of the header of a 'bytes' array.
    uint internal constant BYTES_HEADER_SIZE = 32;
    // Address of the free memory pointer.
    uint internal constant FREE_MEM_PTR = 0x40;

    // Compares the 'len' bytes starting at address 'addr' in memory with the 'len'
    // bytes starting at 'addr2'.
    // Returns 'true' if the bytes are the same, otherwise 'false'.
    function equals(uint addr, uint addr2, uint len) internal pure returns (bool equal) {
        assembly {
            equal := eq(keccak256(addr, len), keccak256(addr2, len))
        }
    }

    // Compares the 'len' bytes starting at address 'addr' in memory with the bytes stored in
    // 'bts'. It is allowed to set 'len' to a lower value then 'bts.length', in which case only
    // the first 'len' bytes will be compared.
    // Requires that 'bts.length >= len'
    function equals(uint addr, uint len, bytes memory bts) internal pure returns (bool equal) {
        require(bts.length >= len);
        uint addr2;
        assembly {
            addr2 := add(bts, /*BYTES_HEADER_SIZE*/32)
        }
        return equals(addr, addr2, len);
    }

    // Allocates 'numBytes' bytes in memory. This will prevent the Solidity compiler
    // from using this area of memory. It will also initialize the area by setting
    // each byte to '0'.
    function allocate(uint numBytes) internal pure returns (uint addr) {
        // Take the current value of the free memory pointer, and update.
        assembly {
            addr := mload(/*FREE_MEM_PTR*/0x40)
            mstore(/*FREE_MEM_PTR*/0x40, add(addr, numBytes))
        }
        uint words = (numBytes + WORD_SIZE - 1) / WORD_SIZE;
        for (uint i = 0; i < words; i++) {
            assembly {
                mstore(add(addr, mul(i, /*WORD_SIZE*/32)), 0)
            }
        }
    }

    // Copy 'len' bytes from memory address 'src', to address 'dest'.
    // This function does not check the or destination, it only copies
    // the bytes.
    function copy(uint src, uint dest, uint len) internal pure {
        // Copy word-length chunks while possible
        for (; len >= WORD_SIZE; len -= WORD_SIZE) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += WORD_SIZE;
            src += WORD_SIZE;
        }

        // Copy remaining bytes
        uint mask = 256 ** (WORD_SIZE - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    // Returns a memory pointer to the provided bytes array.
    function ptr(bytes memory bts) internal pure returns (uint addr) {
        assembly {
            addr := bts
        }
    }

    // Returns a memory pointer to the data portion of the provided bytes array.
    function dataPtr(bytes memory bts) internal pure returns (uint addr) {
        assembly {
            addr := add(bts, /*BYTES_HEADER_SIZE*/32)
        }
    }

    // This function does the same as 'dataPtr(bytes memory)', but will also return the
    // length of the provided bytes array.
    function fromBytes(bytes memory bts) internal pure returns (uint addr, uint len) {
        len = bts.length;
        assembly {
            addr := add(bts, /*BYTES_HEADER_SIZE*/32)
        }
    }

    // Creates a 'bytes memory' variable from the memory address 'addr', with the
    // length 'len'. The function will allocate new memory for the bytes array, and
    // the 'len bytes starting at 'addr' will be copied into that new memory.
    function toBytes(uint addr, uint len) internal pure returns (bytes memory bts) {
        bts = new bytes(len);
        uint btsptr;
        assembly {
            btsptr := add(bts, /*BYTES_HEADER_SIZE*/32)
        }
        copy(addr, btsptr, len);
    }

    // Get the word stored at memory address 'addr' as a 'uint'.
    function toUint(uint addr) internal pure returns (uint n) {
        assembly {
            n := mload(addr)
        }
    }

    // Get the word stored at memory address 'addr' as a 'bytes32'.
    function toBytes32(uint addr) internal pure returns (bytes32 bts) {
        assembly {
            bts := mload(addr)
        }
    }

    /*
    // Get the byte stored at memory address 'addr' as a 'byte'.
    function toByte(uint addr, uint8 index) internal pure returns (byte b) {
        require(index < WORD_SIZE);
        uint8 n;
        assembly {
            n := byte(index, mload(addr))
        }
        b = byte(n);
    }
    */
}

// File: REMIX_FILE_SYNC/HelperUtils.sol

pragma solidity 0.4.25;


/**
 * Internal helper functions
 */
contract HelperUtils {

    // converts bytes32 to a string
    // enable this when you use it. Saving gas for now
    // function bytes32ToString(bytes32 x) private pure returns (string) {
    //     bytes memory bytesString = new bytes(32);
    //     uint charCount = 0;
    //     for (uint j = 0; j < 32; j++) {
    //         byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
    //         if (char != 0) {
    //             bytesString[charCount] = char;
    //             charCount++;
    //         }
    //     }
    //     bytes memory bytesStringTrimmed = new bytes(charCount);
    //     for (j = 0; j < charCount; j++) {
    //         bytesStringTrimmed[j] = bytesString[j];
    //     }
    //     return string(bytesStringTrimmed);
    // } 

    /**
     * Concatenates two strings
     * @param  _a string
     * @param  _b string
     * @return string concatenation of two string
     */
    function strConcat(string _a, string _b) internal pure returns (string) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ab = new string(_ba.length + _bb.length);
        bytes memory bab = bytes(ab);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) bab[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) bab[k++] = _bb[i];
        return string(bab);
    }
}

// File: REMIX_FILE_SYNC/DigitalMediaToken.sol

pragma solidity 0.4.25;





/**
 * The DigitalMediaToken contract.  Fully implements the ERC721 contract
 * from OpenZeppelin without any modifications to it.
 * 
 * This contract allows for the creation of:
 *  1. New Collections
 *  2. New DigitalMedia objects
 *  3. New DigitalMediaRelease objects
 * 
 * The primary piece of logic is to ensure that an ERC721 token can 
 * have a supply and print edition that is enforced by this contract.
 */
contract DigitalMediaToken is DigitalMediaManager, ERC721Safe, HelperUtils, SingleCreatorControl {

    event DigitalMediaReleaseCreateEvent(
        uint256 id, 
        address owner,
        uint32 printEdition,
        string tokenURI, 
        uint256 digitalMediaId);

    // Event fired when a new digital media is created
    event DigitalMediaCreateEvent(
        uint256 id, 
        address storeContractAddress,
        address creator, 
        uint32 totalSupply, 
        uint32 printIndex, 
        uint256 collectionId, 
        string metadataPath);

    // Event fired when a digital media's collection is 
    event DigitalMediaCollectionCreateEvent(
        uint256 id, 
        address storeContractAddress,
        address creator, 
        string metadataPath);

    // Event fired when a digital media is burned
    event DigitalMediaBurnEvent(
        uint256 id,
        address caller,
        address storeContractAddress);

    // Event fired when burning a token
    event DigitalMediaReleaseBurnEvent(
        uint256 tokenId, 
        address owner);

    event UpdateDigitalMediaPrintIndexEvent(
        uint256 digitalMediaId,
        uint32 printEdition);

    // Event fired when a creator assigns a new creator address.
    event ChangedCreator(
        address creator,
        address newCreator);

    struct DigitalMediaRelease {
        // The unique edition number of this digital media release
        uint32 printEdition;

        // Reference ID to the digital media metadata
        uint256 digitalMediaId;
    }

    // Maps internal ERC721 token ID to digital media release object.
    mapping (uint256 => DigitalMediaRelease) public tokenIdToDigitalMediaRelease;

    // Maps a creator address to a new creator address.  Useful if a creator
    // changes their address or the previous address gets compromised.
    mapping (address => address) public approvedCreators;

    // Token ID counter
    uint256 internal tokenIdCounter = 0;

    constructor (string _tokenName, string _tokenSymbol, uint256 _tokenIdStartingCounter) 
            public ERC721Token(_tokenName, _tokenSymbol) {
        tokenIdCounter = _tokenIdStartingCounter;
    }

    /**
     * Creates a new digital media object.
     * @param  _creator address  the creator of this digital media
     * @param  _totalSupply uint32 the total supply a creation could have
     * @param  _collectionId uint256 the collectionId that it belongs to
     * @param  _metadataPath string the path to the ipfs metadata
     * @return uint the new digital media id
     */
    function _createDigitalMedia(
          address _creator, uint32 _totalSupply, uint256 _collectionId, string _metadataPath) 
          internal 
          returns (uint) {

        require(_validateCollection(_collectionId, _creator), "Creator for collection not approved.");

        uint256 newDigitalMediaId = currentDigitalMediaStore.createDigitalMedia(
            _creator,
            0, 
            _totalSupply,
            _collectionId,
            _metadataPath);

        emit DigitalMediaCreateEvent(
            newDigitalMediaId,
            address(currentDigitalMediaStore),
            _creator,
            _totalSupply,
            0,
            _collectionId,
            _metadataPath);

        return newDigitalMediaId;
    }

    /**
     * Burns a token for a given tokenId and caller.
     * @param  _tokenId the id of the token to burn.
     * @param  _caller the address of the caller.
     */
    function _burnToken(uint256 _tokenId, address _caller) internal {
        address owner = ownerOf(_tokenId);
        require(_caller == owner || 
                getApproved(_tokenId) == _caller || 
                isApprovedForAll(owner, _caller),
                "Failed token burn.  Caller is not approved.");
        _burn(owner, _tokenId);
        delete tokenIdToDigitalMediaRelease[_tokenId];
        emit DigitalMediaReleaseBurnEvent(_tokenId, owner);
    }

    /**
     * Burns a digital media.  Once this function succeeds, this digital media
     * will no longer be able to mint any more tokens.  Existing tokens need to be 
     * burned individually though.
     * @param  _digitalMediaId the id of the digital media to burn
     * @param  _caller the address of the caller.
     */
    function _burnDigitalMedia(uint256 _digitalMediaId, address _caller) internal {
        DigitalMedia memory _digitalMedia = _getDigitalMedia(_digitalMediaId);
        require(_checkApprovedCreator(_digitalMedia.creator, _caller) || 
                isApprovedForAll(_digitalMedia.creator, _caller), 
                "Failed digital media burn.  Caller not approved.");

        uint32 increment = _digitalMedia.totalSupply - _digitalMedia.printIndex;
        _incrementDigitalMediaPrintIndex(_digitalMedia, increment);
        address _burnDigitalMediaStoreAddress = address(_getDigitalMediaStore(_digitalMedia.id));
        emit DigitalMediaBurnEvent(
          _digitalMediaId, _caller, _burnDigitalMediaStoreAddress);
    }

    /**
     * Creates a new collection
     * @param  _creator address the creator of this collection
     * @param  _metadataPath string the path to the collection ipfs metadata
     * @return uint the new collection id
     */
    function _createCollection(
          address _creator, string _metadataPath) 
          internal 
          returns (uint) {
        uint256 newCollectionId = currentDigitalMediaStore.createCollection(
            _creator,
            _metadataPath);

        emit DigitalMediaCollectionCreateEvent(
            newCollectionId,
            address(currentDigitalMediaStore),
            _creator,
            _metadataPath);

        return newCollectionId;
    }

    /**
     * Creates _count number of new digital media releases (i.e a token).  
     * Bumps up the print index by _count.
     * @param  _owner address the owner of the digital media object
     * @param  _digitalMediaId uint256 the digital media id
     */
    function _createDigitalMediaReleases(
        address _owner, uint256 _digitalMediaId, uint32 _count)
        internal {

        require(_count > 0, "Failed print edition.  Creation count must be > 0.");
        require(_count < 10000, "Cannot print more than 10K tokens at once");
        DigitalMedia memory _digitalMedia = _getDigitalMedia(_digitalMediaId);
        uint32 currentPrintIndex = _digitalMedia.printIndex;
        require(_checkApprovedCreator(_digitalMedia.creator, _owner), "Creator not approved.");
        require(isAllowedSingleCreator(_owner), "Creator must match single creator address.");
        require(_count + currentPrintIndex <= _digitalMedia.totalSupply, "Total supply exceeded.");
        
        string memory tokenURI = HelperUtils.strConcat("ipfs://ipfs/", _digitalMedia.metadataPath);

        for (uint32 i=0; i < _count; i++) {
            uint32 newPrintEdition = currentPrintIndex + 1 + i;
            DigitalMediaRelease memory _digitalMediaRelease = DigitalMediaRelease({
                printEdition: newPrintEdition,
                digitalMediaId: _digitalMediaId
            });

            uint256 newDigitalMediaReleaseId = _getNextTokenId();
            tokenIdToDigitalMediaRelease[newDigitalMediaReleaseId] = _digitalMediaRelease;
        
            emit DigitalMediaReleaseCreateEvent(
                newDigitalMediaReleaseId,
                _owner,
                newPrintEdition,
                tokenURI,
                _digitalMediaId
            );

            // This will assign ownership and also emit the Transfer event as per ERC721
            _mint(_owner, newDigitalMediaReleaseId);
            _setTokenURI(newDigitalMediaReleaseId, tokenURI);
            tokenIdCounter = tokenIdCounter.add(1);

        }
        _incrementDigitalMediaPrintIndex(_digitalMedia, _count);
        emit UpdateDigitalMediaPrintIndexEvent(_digitalMediaId, currentPrintIndex + _count);
    }

    /**
     * Checks that a given caller is an approved creator and is allowed to mint or burn
     * tokens.  If the creator was changed it will check against the updated creator.
     * @param  _caller the calling address
     * @return bool allowed or not
     */
    function _checkApprovedCreator(address _creator, address _caller) 
            internal 
            view 
            returns (bool) {
        address approvedCreator = approvedCreators[_creator];
        if (approvedCreator != address(0)) {
            return approvedCreator == _caller;
        } else {
            return _creator == _caller;
        }
    }

    /**
     * Validates the an address is allowed to create a digital media on a
     * given collection.  Collections are tied to addresses.
     */
    function _validateCollection(uint256 _collectionId, address _address) 
            private 
            view 
            returns (bool) {
        if (_collectionId == 0 ) {
            return true;
        }

        DigitalMediaCollection memory collection = _getCollection(_collectionId);
        return _checkApprovedCreator(collection.creator, _address);
    }

    /**
    * Generates a new token id.
    */
    function _getNextTokenId() private view returns (uint256) {
        return tokenIdCounter.add(1); 
    }

    /**
     * Changes the creator that is approved to printing new tokens and creations.
     * Either the _caller must be the _creator or the _caller must be the existing
     * approvedCreator.
     * @param _caller the address of the caller
     * @param  _creator the address of the current creator
     * @param  _newCreator the address of the new approved creator
     */
    function _changeCreator(address _caller, address _creator, address _newCreator) internal {
        address approvedCreator = approvedCreators[_creator];
        require(_caller != address(0) && _creator != address(0), "Creator must be valid non 0x0 address.");
        require(_caller == _creator || _caller == approvedCreator, "Unauthorized caller.");
        if (approvedCreator == address(0)) {
            approvedCreators[_caller] = _newCreator;
        } else {
            require(_caller == approvedCreator, "Unauthorized caller.");
            approvedCreators[_creator] = _newCreator;
        }
        emit ChangedCreator(_creator, _newCreator);
    }

    /**
     * Introspection interface as per ERC-165 (https://github.com/ethereum/EIPs/issues/165).
     */
    function supportsInterface(bytes4 _interfaceID) external view returns (bool) {
        return ((_interfaceID == InterfaceSignature_ERC165) || (_interfaceID == InterfaceSignature_ERC721));
    }

}

// File: REMIX_FILE_SYNC/OBOControl.sol

pragma solidity 0.4.25;



contract OBOControl is Pausable {
	// List of approved on behalf of users.
    mapping (address => bool) public approvedOBOs;

	/**
     * Add a new approved on behalf of user address.
     */
    function addApprovedOBO(address _oboAddress) external onlyOwner {
        approvedOBOs[_oboAddress] = true;
    }

    /**
     * Removes an approved on bhealf of user address.
     */
    function removeApprovedOBO(address _oboAddress) external onlyOwner {
        delete approvedOBOs[_oboAddress];
    }

    /**
    * @dev Modifier to make the obo calls only callable by approved addressess
    */
    modifier isApprovedOBO() {
        require(approvedOBOs[msg.sender] == true);
        _;
    }
}

// File: REMIX_FILE_SYNC/WithdrawFundsControl.sol

pragma solidity 0.4.25;



contract WithdrawFundsControl is Pausable {

	// List of approved on withdraw addresses
    mapping (address => uint256) public approvedWithdrawAddresses;

    // Full day wait period before an approved withdraw address becomes active
    uint256 constant internal withdrawApprovalWaitPeriod = 60 * 60 * 24;

    event WithdrawAddressAdded(address withdrawAddress);
    event WithdrawAddressRemoved(address widthdrawAddress);

	/**
     * Add a new approved on behalf of user address.
     */
    function addApprovedWithdrawAddress(address _withdrawAddress) external onlyOwner {
        approvedWithdrawAddresses[_withdrawAddress] = now;
        emit WithdrawAddressAdded(_withdrawAddress);
    }

    /**
     * Removes an approved on bhealf of user address.
     */
    function removeApprovedWithdrawAddress(address _withdrawAddress) external onlyOwner {
        delete approvedWithdrawAddresses[_withdrawAddress];
        emit WithdrawAddressRemoved(_withdrawAddress);
    }

    /**
     * Checks that a given withdraw address ia approved and is past it's required
     * wait time.
     */
    function isApprovedWithdrawAddress(address _withdrawAddress) internal view returns (bool)  {
        uint256 approvalTime = approvedWithdrawAddresses[_withdrawAddress];
        require (approvalTime > 0);
        return now - approvalTime > withdrawApprovalWaitPeriod;
    }
}

// File: REMIX_FILE_SYNC/openzeppelin-solidity/contracts/token/ERC721/ERC721Holder.sol

pragma solidity ^0.4.21;



contract ERC721Holder is ERC721Receiver {
  function onERC721Received(address, uint256, bytes) public returns(bytes4) {
    return ERC721_RECEIVED;
  }
}

// File: REMIX_FILE_SYNC/DigitalMediaSaleBase.sol

pragma solidity 0.4.25;







/**
 * Base class that manages the underlying functions of a Digital Media Sale,
 * most importantly the escrow of digital tokens.
 *
 * Manages ensuring that only approved addresses interact with this contract.
 *
 */
contract DigitalMediaSaleBase is ERC721Holder, Pausable, OBOControl, WithdrawFundsControl {
    using SafeMath for uint256;

     // Mapping of token contract address to bool indicated approval.
    mapping (address => bool) public approvedTokenContracts;

    /**
     * Adds a new token contract address to be approved to be called.
     */
    function addApprovedTokenContract(address _tokenContractAddress) 
            public onlyOwner {
        approvedTokenContracts[_tokenContractAddress] = true;
    }

    /**
     * Remove an approved token contract address from the list of approved addresses.
     */
    function removeApprovedTokenContract(address _tokenContractAddress) 
            public onlyOwner {            
        delete approvedTokenContracts[_tokenContractAddress];
    }

    /**
     * Checks that a particular token contract address is a valid address.
     */
    function _isValidTokenContract(address _tokenContractAddress) 
            internal view returns (bool) {
        return approvedTokenContracts[_tokenContractAddress];
    }

    /**
     * Returns an ERC721 instance of a token contract address.  Throws otherwise.
     * Only valid and approved token contracts are allowed to be interacted with.
     */
    function _getTokenContract(address _tokenContractAddress) internal view returns (ERC721Safe) {
        require(_isValidTokenContract(_tokenContractAddress));
        return ERC721Safe(_tokenContractAddress);
    }

    /**
     * Checks with the ERC-721 token contract that the _claimant actually owns the token.
     */
    function _owns(address _claimant, uint256 _tokenId, address _tokenContractAddress) internal view returns (bool) {
        ERC721Safe tokenContract = _getTokenContract(_tokenContractAddress);
        return (tokenContract.ownerOf(_tokenId) == _claimant);
    }

    /**
     * Checks with the ERC-721 token contract the owner of the a token
     */
    function _ownerOf(uint256 _tokenId, address _tokenContractAddress) internal view returns (address) {
        ERC721Safe tokenContract = _getTokenContract(_tokenContractAddress);
        return tokenContract.ownerOf(_tokenId);
    }

    /**
     * Checks to ensure that the token owner has approved the escrow contract 
     */
    function _approvedForEscrow(address _seller, uint256 _tokenId, address _tokenContractAddress) internal view returns (bool) {
        ERC721Safe tokenContract = _getTokenContract(_tokenContractAddress);
        return (tokenContract.isApprovedForAll(_seller, this) || 
                tokenContract.getApproved(_tokenId) == address(this));
    }

    /**
     * Escrows an ERC-721 token from the seller to this contract.  Assumes that the escrow contract
     * is already approved to make the transfer, otherwise it will fail.
     */
    function _escrow(address _seller, uint256 _tokenId, address _tokenContractAddress) internal {
        // it will throw if transfer fails
        ERC721Safe tokenContract = _getTokenContract(_tokenContractAddress);
        tokenContract.safeTransferFrom(_seller, this, _tokenId);
    }

    /**
     * Transfer an ERC-721 token from escrow to the buyer.  This is to be called after a purchase is
     * completed.
     */
    function _transfer(address _receiver, uint256 _tokenId, address _tokenContractAddress) internal {
        // it will throw if transfer fails
        ERC721Safe tokenContract = _getTokenContract(_tokenContractAddress);
        tokenContract.safeTransferFrom(this, _receiver, _tokenId);
    }

    /**
     * Method to check whether this is an escrow contract
     */
    function isEscrowContract() public pure returns(bool) {
        return true;
    }

    /**
     * Withdraws all the funds to a specified non-zero address
     */
    function withdrawFunds(address _withdrawAddress) public onlyOwner {
        require(isApprovedWithdrawAddress(_withdrawAddress));
        _withdrawAddress.transfer(address(this).balance);
    }
}

// File: REMIX_FILE_SYNC/DigitalMediaCore.sol

pragma solidity 0.4.25;





/**
 * This is the main driver contract that is used to control and run the service. Funds 
 * are managed through this function, underlying contracts are also updated through 
 * this contract.
 *
 * This class also exposes a set of creation methods that are allowed to be created
 * by an approved token creator, on behalf of a particular address.  This is meant
 * to simply the creation flow for MakersToken users that aren't familiar with 
 * the blockchain.  The ERC721 tokens that are created are still fully compliant, 
 * although it is possible for a malicious token creator to mint unwanted tokens 
 * on behalf of a creator.  Worst case, the creator can burn those tokens.
 */
contract DigitalMediaCore is DigitalMediaToken {
    using SafeMath for uint32;

    // List of approved token creators (on behalf of the owner)
    mapping (address => bool) public approvedTokenCreators;

    // Mapping from owner to operator accounts.
    mapping (address => mapping (address => bool)) internal oboOperatorApprovals;

    // Mapping of all disabled OBO operators.
    mapping (address => bool) public disabledOboOperators;

    // OboApproveAll Event
    event OboApprovalForAll(
        address _owner, 
        address _operator, 
        bool _approved);

    // Fired when disbaling obo capability.
    event OboDisabledForAll(address _operator);

    constructor (
        string _tokenName, 
        string _tokenSymbol, 
        uint256 _tokenIdStartingCounter, 
        address _dmsAddress,
        address _crsAddress)
            public DigitalMediaToken(
                _tokenName, 
                _tokenSymbol,
                _tokenIdStartingCounter) {
        paused = true;
        setDigitalMediaStoreAddress(_dmsAddress);
        setCreatorRegistryStore(_crsAddress);
    }

    /**
     * Retrieves a Digital Media object.
     */
    function getDigitalMedia(uint256 _id) 
            external 
            view 
            returns (
            uint256 id,
            uint32 totalSupply,
            uint32 printIndex,
            uint256 collectionId,
            address creator,
            string metadataPath) {

        DigitalMedia memory digitalMedia = _getDigitalMedia(_id);
        require(digitalMedia.creator != address(0), "DigitalMedia not found.");
        id = _id;
        totalSupply = digitalMedia.totalSupply;
        printIndex = digitalMedia.printIndex;
        collectionId = digitalMedia.collectionId;
        creator = digitalMedia.creator;
        metadataPath = digitalMedia.metadataPath;
    }

    /**
     * Retrieves a collection.
     */
    function getCollection(uint256 _id) 
            external 
            view 
            returns (
            uint256 id,
            address creator,
            string metadataPath) {
        DigitalMediaCollection memory digitalMediaCollection = _getCollection(_id);
        require(digitalMediaCollection.creator != address(0), "Collection not found.");
        id = _id;
        creator = digitalMediaCollection.creator;
        metadataPath = digitalMediaCollection.metadataPath;
    }

    /**
     * Retrieves a Digital Media Release (i.e a token)
     */
    function getDigitalMediaRelease(uint256 _id) 
            external 
            view 
            returns (
            uint256 id,
            uint32 printEdition,
            uint256 digitalMediaId) {
        require(exists(_id));
        DigitalMediaRelease storage digitalMediaRelease = tokenIdToDigitalMediaRelease[_id];
        id = _id;
        printEdition = digitalMediaRelease.printEdition;
        digitalMediaId = digitalMediaRelease.digitalMediaId;
    }

    /**
     * Creates a new collection.
     *
     * No creations of any kind are allowed when the contract is paused.
     */
    function createCollection(string _metadataPath) 
            external 
            whenNotPaused {
        _createCollection(msg.sender, _metadataPath);
    }

    /**
     * Creates a new digital media object.
     */
    function createDigitalMedia(uint32 _totalSupply, uint256 _collectionId, string _metadataPath) 
            external 
            whenNotPaused {
        _createDigitalMedia(msg.sender, _totalSupply, _collectionId, _metadataPath);
    }

    /**
     * Creates a new digital media object and mints it's first digital media release token.
     *
     * No creations of any kind are allowed when the contract is paused.
     */
    function createDigitalMediaAndReleases(
                uint32 _totalSupply,
                uint256 _collectionId,
                string _metadataPath,
                uint32 _numReleases)
            external 
            whenNotPaused {
        uint256 digitalMediaId = _createDigitalMedia(msg.sender, _totalSupply, _collectionId, _metadataPath);
        _createDigitalMediaReleases(msg.sender, digitalMediaId, _numReleases);
    }

    /**
     * Creates a new collection, a new digital media object within it and mints a new
     * digital media release token.
     *
     * No creations of any kind are allowed when the contract is paused.
     */
    function createDigitalMediaAndReleasesInNewCollection(
                uint32 _totalSupply, 
                string _digitalMediaMetadataPath,
                string _collectionMetadataPath,
                uint32 _numReleases)
            external 
            whenNotPaused {
        uint256 collectionId = _createCollection(msg.sender, _collectionMetadataPath);
        uint256 digitalMediaId = _createDigitalMedia(msg.sender, _totalSupply, collectionId, _digitalMediaMetadataPath);
        _createDigitalMediaReleases(msg.sender, digitalMediaId, _numReleases);
    }

    /**
     * Creates a new digital media release (token) for a given digital media id.
     *
     * No creations of any kind are allowed when the contract is paused.
     */
    function createDigitalMediaReleases(uint256 _digitalMediaId, uint32 _numReleases) 
            external 
            whenNotPaused {
        _createDigitalMediaReleases(msg.sender, _digitalMediaId, _numReleases);
    }

    /**
     * Deletes a token / digital media release. Doesn't modify the current print index
     * and total to be printed. Although dangerous, the owner of a token should always 
     * be able to burn a token they own.
     *
     * Only the owner of the token or accounts approved by the owner can burn this token.
     */
    function burnToken(uint256 _tokenId) external {
        _burnToken(_tokenId, msg.sender);
    }

    /* Support ERC721 burn method */
    function burn(uint256 tokenId) public {
        _burnToken(tokenId, msg.sender);
    }

    /**
     * Ends the production run of a digital media.  Afterwards no more tokens
     * will be allowed to be printed for this digital media.  Used when a creator
     * makes a mistake and wishes to burn and recreate their digital media.
     * 
     * When a contract is paused we do not allow new tokens to be created, 
     * so stopping the production of a token doesn't have much purpose.
     */
    function burnDigitalMedia(uint256 _digitalMediaId) external whenNotPaused {
        _burnDigitalMedia(_digitalMediaId, msg.sender);
    }

    /**
     * Resets the approval rights for a given tokenId.
     */
    function resetApproval(uint256 _tokenId) external {
        clearApproval(msg.sender, _tokenId);
    }

    /**
     * Changes the creator for the current sender, in the event we 
     * need to be able to mint new tokens from an existing digital media 
     * print production. When changing creator, the old creator will
     * no longer be able to mint tokens.
     *
     * A creator may need to be changed:
     * 1. If we want to allow a creator to take control over their token minting (i.e go decentralized)
     * 2. If we want to re-issue private keys due to a compromise.  For this reason, we can call this function
     * when the contract is paused.
     * @param _creator the creator address
     * @param _newCreator the new creator address
     */
    function changeCreator(address _creator, address _newCreator) external {
        _changeCreator(msg.sender, _creator, _newCreator);
    }

    /**********************************************************************/
    /**Calls that are allowed to be called by approved creator addresses **/ 
    /**********************************************************************/
    
    /**
     * Add a new approved token creator.
     *
     * Only the owner of this contract can update approved Obo accounts.
     */
    function addApprovedTokenCreator(address _creatorAddress) external onlyOwner {
        require(disabledOboOperators[_creatorAddress] != true, "Address disabled.");
        approvedTokenCreators[_creatorAddress] = true;
    }

    /**
     * Removes an approved token creator.
     *
     * Only the owner of this contract can update approved Obo accounts.
     */
    function removeApprovedTokenCreator(address _creatorAddress) external onlyOwner {
        delete approvedTokenCreators[_creatorAddress];
    }

    /**
    * @dev Modifier to make the approved creation calls only callable by approved token creators
    */
    modifier isApprovedCreator() {
        require(
            (approvedTokenCreators[msg.sender] == true && 
             disabledOboOperators[msg.sender] != true), 
            "Unapproved OBO address.");
        _;
    }

    /**
     * Only the owner address can set a special obo approval list.
     * When issuing OBO management accounts, we should give approvals through
     * this method only so that we can very easily reset it's approval in
     * the event of a disaster scenario.
     *
     * Only the owner themselves is allowed to give OboApproveAll access.
     */
    function setOboApprovalForAll(address _to, bool _approved) public {
        require(_to != msg.sender, "Approval address is same as approver.");
        require(approvedTokenCreators[_to], "Unrecognized OBO address.");
        require(disabledOboOperators[_to] != true, "Approval address is disabled.");
        oboOperatorApprovals[msg.sender][_to] = _approved;
        emit OboApprovalForAll(msg.sender, _to, _approved);
    }

    /**
     * Only called in a disaster scenario if the account has been compromised.  
     * There's no turning back from this and the oboAddress will no longer be 
     * able to be given approval rights or perform obo functions.  
     * 
     * Only the owner of this contract is allowed to disable an Obo address.
     *
     */
    function disableOboAddress(address _oboAddress) public onlyOwner {
        require(approvedTokenCreators[_oboAddress], "Unrecognized OBO address.");
        disabledOboOperators[_oboAddress] = true;
        delete approvedTokenCreators[_oboAddress];
        emit OboDisabledForAll(_oboAddress);
    }

    /**
     * Override the isApprovalForAll to check for a special oboApproval list.  Reason for this
     * is that we can can easily remove obo operators if they every become compromised.
     */
    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        if (disabledOboOperators[_operator] == true) {
            return false;
        } else if (isOperatorApprovedForCustodialAccount(_operator, _owner) == true) {
            return true;
        } else if (oboOperatorApprovals[_owner][_operator]) {
            return true;
        } else {
            return super.isApprovedForAll(_owner, _operator);
        }
    }

    /**
     * Creates a new digital media object and mints it's digital media release tokens.
     * Called on behalf of the _owner. Pass count to mint `n` number of tokens.
     *
     * Only approved creators are allowed to create Obo.
     *
     * No creations of any kind are allowed when the contract is paused.
     */
    function oboCreateDigitalMediaAndReleases(
                address _owner,
                uint32 _totalSupply, 
                uint256 _collectionId, 
                string _metadataPath,
                uint32 _numReleases)
            external 
            whenNotPaused
            isApprovedCreator {
        uint256 digitalMediaId = _createDigitalMedia(_owner, _totalSupply, _collectionId, _metadataPath);
        _createDigitalMediaReleases(_owner, digitalMediaId, _numReleases);
    }

    /**
     * Creates a new collection, a new digital media object within it and mints a new
     * digital media release token.
     * Called on behalf of the _owner.
     *
     * Only approved creators are allowed to create Obo.
     *
     * No creations of any kind are allowed when the contract is paused.
     */
    function oboCreateDigitalMediaAndReleasesInNewCollection(
                address _owner,
                uint32 _totalSupply, 
                string _digitalMediaMetadataPath,
                string _collectionMetadataPath,
                uint32 _numReleases)
            external 
            whenNotPaused
            isApprovedCreator {
        uint256 collectionId = _createCollection(_owner, _collectionMetadataPath);
        uint256 digitalMediaId = _createDigitalMedia(_owner, _totalSupply, collectionId, _digitalMediaMetadataPath);
        _createDigitalMediaReleases(_owner, digitalMediaId, _numReleases);
    }

    /**
     * Creates multiple digital media releases (tokens) for a given digital media id.
     * Called on behalf of the _owner.
     *
     * Only approved creators are allowed to create Obo.
     *
     * No creations of any kind are allowed when the contract is paused.
     */
    function oboCreateDigitalMediaReleases(
                address _owner,
                uint256 _digitalMediaId,
                uint32 _numReleases) 
            external 
            whenNotPaused
            isApprovedCreator {
        _createDigitalMediaReleases(_owner, _digitalMediaId, _numReleases);
    }

}



contract DigitalMediaStore is DigitalMediaStoreInterface {
    using SafeMath for uint256;

    uint MediaStoreVersion;
    uint256 internal DigitalMediaId = 0;
    uint256 internal CollectionId = 0;

    struct DigitalMedia {
        uint256 id;
        address creator;
        uint32 printIndex;
        uint32 totalSupply;
        uint256 collectionId;
        string metadataPath;
    }
    
    struct Collection {
        uint256 id;
        address creator;
        string metadataPath;
    }
    
    mapping (uint256=>DigitalMedia) DigitalMedias; 
    mapping (uint256=>Collection) Collections; 
    address tokenContract;

    function getDigitalMediaStoreVersion() public pure returns (uint) {
        uint _version = 2;
        return _version;
    }

    function getStartingDigitalMediaId() public view returns (uint256) {
        return MediaStoreVersion;
    }

    function registerTokenContractAddress() external {
        require(tokenContract == address(0), "Token Contract has set!");
        address _tokenContract = DigitalMediaToken(msg.sender);
        tokenContract = _tokenContract;
    }

    /**
     * Creates a new digital media object in storage
     * @param  _creator address the address of the creator
     * @param  _printIndex uint32 the current print index for the limited edition media
     * @param  _totalSupply uint32 the total allowable prints for this media
     * @param  _collectionId uint256 the collection id that this media belongs to
     * @param  _metadataPath string the ipfs metadata path
     * @return the id of the new digital media created
     */
    function createDigitalMedia(
                address _creator, 
                uint32 _printIndex, 
                uint32 _totalSupply, 
                uint256 _collectionId, 
                string _metadataPath) external returns (uint) {
        require(msg.sender == tokenContract, "Only token contract can operate!");
        Collection memory collection = Collections[_collectionId];
        require(collection.creator == _creator, 'Incorrect Creator, Fail to Create Digital Media!');
        DigitalMediaId = DigitalMediaId.add(1);
        DigitalMedia memory _digitalMedia = DigitalMedia({
            id: DigitalMediaId,
            creator: _creator,
            printIndex: _printIndex,
            totalSupply: _totalSupply,
            collectionId: _collectionId,
            metadataPath: _metadataPath
        });
        DigitalMedias[DigitalMediaId] = _digitalMedia;
        return DigitalMediaId;
    }

    /**
     * Increments the current print index of the digital media object
     * @param  _digitalMediaId uint256 the id of the digital media
     * @param  _increment uint32 the amount to increment by
     */
    function incrementDigitalMediaPrintIndex(
                uint256 _digitalMediaId, 
                uint32 _increment)  external {
        require(msg.sender == tokenContract, "Only token contract can operate!");
        DigitalMedia storage _digitalMedia = DigitalMedias[_digitalMediaId];
        _digitalMedia.printIndex=uint32(uint256(_digitalMedia.printIndex).add(uint256(_increment)));
    }

    /**
     * Retrieves the digital media object by id
     * @param  _digitalMediaId uint256 the address of the creator
     */
    function getDigitalMedia(uint256 _digitalMediaId) external view returns(
                uint256 id,
                uint32 totalSupply,
                uint32 printIndex,
                uint256 collectionId,
                address creator,
                string metadataPath) {
        
        DigitalMedia memory dm = DigitalMedias[_digitalMediaId];
        id = _digitalMediaId;
        totalSupply = dm.totalSupply;
        printIndex = dm.printIndex;
        collectionId = dm.collectionId;
        creator = dm.creator;
        metadataPath = dm.metadataPath;
    }

    /**
     * Creates a new collection
     * @param  _creator address the address of the creator
     * @param  _metadataPath string the ipfs metadata path
     * @return the id of the new collection created
     */
    function createCollection(address _creator, string _metadataPath) external returns (uint) {
        require(msg.sender == tokenContract, "Only token contract can operate!");
        CollectionId=CollectionId.add(1);
        Collection memory collection = Collection({
            id: CollectionId,
            creator: _creator,
            metadataPath: _metadataPath
        });
        Collections[CollectionId]=collection;
        return CollectionId;
    }

    /**
     * Retrieves a collection by id
     * @param  _collectionId uint256
     */
    function getCollection(uint256 _collectionId) external view
            returns(
                uint256 id,
                address creator,
                string metadataPath) {
        Collection memory collection = Collections[_collectionId];
        id=_collectionId;
        creator=collection.creator;
        require(creator != address(0),"Incorrect creator! Collection Not Found!");
        metadataPath=collection.metadataPath;
    }

}


contract DigitalMediaStoreV1 is DigitalMediaStoreInterface {
    using SafeMath for uint256;

    uint MediaStoreVersion;
    uint256 internal DigitalMediaId = 0;
    uint256 internal CollectionId = 0;

    struct DigitalMedia {
        uint256 id;
        address creator;
        uint32 printIndex;
        uint32 totalSupply;
        uint256 collectionId;
        string metadataPath;
    }
    
    struct Collection {
        uint256 id;
        address creator;
        string metadataPath;
    }
    
    mapping (uint256=>DigitalMedia) DigitalMedias; 
    mapping (uint256=>Collection) Collections; 
    address tokenContract;

    function getDigitalMediaStoreVersion() public pure returns (uint) {
        uint _version = 1;
        return _version;
    }

    function getStartingDigitalMediaId() public view returns (uint256) {
        return MediaStoreVersion;
    }

    function registerTokenContractAddress() external {
        require(tokenContract == address(0), "Token Contract has set!");
        address _tokenContract = DigitalMediaToken(msg.sender);
        tokenContract = _tokenContract;
    }

    /**
     * Creates a new digital media object in storage
     * @param  _creator address the address of the creator
     * @param  _printIndex uint32 the current print index for the limited edition media
     * @param  _totalSupply uint32 the total allowable prints for this media
     * @param  _collectionId uint256 the collection id that this media belongs to
     * @param  _metadataPath string the ipfs metadata path
     * @return the id of the new digital media created
     */
    function createDigitalMedia(
                address _creator, 
                uint32 _printIndex, 
                uint32 _totalSupply, 
                uint256 _collectionId, 
                string _metadataPath) external returns (uint) {
        require(msg.sender == tokenContract, "Only token contract can operate!");
        Collection memory collection = Collections[_collectionId];
        require(collection.creator == _creator, 'Incorrect Creator, Fail to Create Digital Media!');
        DigitalMediaId = DigitalMediaId.add(1);
        DigitalMedia memory _digitalMedia = DigitalMedia({
            id: DigitalMediaId,
            creator: _creator,
            printIndex: _printIndex,
            totalSupply: _totalSupply,
            collectionId: _collectionId,
            metadataPath: _metadataPath
        });
        DigitalMedias[DigitalMediaId] = _digitalMedia;
        return DigitalMediaId;
    }
 
    /**
     * Increments the current print index of the digital media object
     * @param  _digitalMediaId uint256 the id of the digital media
     * @param  _increment uint32 the amount to increment by
     */
    function incrementDigitalMediaPrintIndex(
                uint256 _digitalMediaId, 
                uint32 _increment)  external {
        require(msg.sender == tokenContract, "Only token contract can operate!");
        DigitalMedia storage _digitalMedia = DigitalMedias[_digitalMediaId];
        _digitalMedia.printIndex=uint32(uint256(_digitalMedia.printIndex).add(uint256(_increment)));
    }

    /**
     * Retrieves the digital media object by id
     * @param  _digitalMediaId uint256 the address of the creator
     */
    function getDigitalMedia(uint256 _digitalMediaId) external view returns(
                uint256 id,
                uint32 totalSupply,
                uint32 printIndex,
                uint256 collectionId,
                address creator,
                string metadataPath) {
        
        DigitalMedia memory dm = DigitalMedias[_digitalMediaId];
        id = _digitalMediaId;
        totalSupply = dm.totalSupply;
        printIndex = dm.printIndex;
        collectionId = dm.collectionId;
        creator = dm.creator;
        metadataPath = dm.metadataPath;
    }

    /**
     * Creates a new collection
     * @param  _creator address the address of the creator
     * @param  _metadataPath string the ipfs metadata path
     * @return the id of the new collection created
     */
    function createCollection(address _creator, string _metadataPath) external returns (uint) {
        require(msg.sender == tokenContract, "Only token contract can operate!");
        CollectionId=CollectionId.add(1);
        Collection memory collection = Collection({
            id: CollectionId,
            creator: _creator,
            metadataPath: _metadataPath
        });
        Collections[CollectionId]=collection;
        return CollectionId;
    }

    /**
     * Retrieves a collection by id
     * @param  _collectionId uint256
     */
    function getCollection(uint256 _collectionId) external view
            returns(
                uint256 id,
                address creator,
                string metadataPath) {
        Collection memory collection = Collections[_collectionId];
        id=_collectionId;
        creator=collection.creator;
        require(creator != address(0),"Incorrect creator! Collection Not Found!");
        metadataPath=collection.metadataPath;
    }

}

contract ApprovedCreatorRegistry is ApprovedCreatorRegistryInterface {

    mapping(address => address) operators;
    
    function getVersion() public pure returns (uint) {
        uint _version = 1;
        return _version;
    }
    
    function typeOfContract() public pure returns (string) {
        return "approvedCreatorRegistry";
    }
    
    function isOperatorApprovedForCustodialAccount(
        address _operator,
        address _custodialAddress) public view returns (bool) {
            require(_operator != address(0), "Invalid operator address, 0x0 address is not allowed!");
            require(_custodialAddress != address(0), "Invalid custodial address, 0x0 address is not allowed!");
            if(operators[_operator] != _custodialAddress) {
                return false;
            }
            return true;
    }

}