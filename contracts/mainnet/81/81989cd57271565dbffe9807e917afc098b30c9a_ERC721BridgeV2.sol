/**
 *Submitted for verification at Etherscan.io on 2021-07-10
*/

// hevm: flattened sources of contracts/ERC721BridgeV2.sol

pragma solidity >=0.4.23 <0.5.0 >=0.4.24 <0.5.0;

////// contracts/interfaces/IAuthority.sol
/* pragma solidity ^0.4.24; */

contract IAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) public view returns (bool);
}

////// contracts/DSAuth.sol
/* pragma solidity ^0.4.24; */

/* import './interfaces/IAuthority.sol'; */

contract DSAuthEvents {
    event LogSetAuthority (address indexed authority);
    event LogSetOwner     (address indexed owner);
}

/**
 * @title DSAuth
 * @dev The DSAuth contract is reference implement of https://github.com/dapphub/ds-auth
 * But in the isAuthorized method, the src from address(this) is remove for safty concern.
 */
contract DSAuth is DSAuthEvents {
    IAuthority   public  authority;
    address      public  owner;

    constructor() public {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    function setOwner(address owner_)
        public
        auth
    {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function setAuthority(IAuthority authority_)
        public
        auth
    {
        authority = authority_;
        emit LogSetAuthority(authority);
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig), "ds-auth-unauthorized");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == owner) {
            return true;
        } else if (authority == IAuthority(0)) {
            return false;
        } else {
            return authority.canCall(src, this, sig);
        }
    }
}

////// contracts/PausableDSAuth.sol
/* pragma solidity ^0.4.24; */

/* import "./DSAuth.sol"; */


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract PausableDSAuth is DSAuth {
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

////// contracts/SettingIds.sol
/* pragma solidity ^0.4.24; */

/**
    Id definitions for SettingsRegistry.sol
    Can be used in conjunction with the settings registry to get properties
*/
contract SettingIds {
    // 0x434f4e54524143545f52494e475f45524332305f544f4b454e00000000000000
    bytes32 public constant CONTRACT_RING_ERC20_TOKEN = "CONTRACT_RING_ERC20_TOKEN";

    // 0x434f4e54524143545f4b544f4e5f45524332305f544f4b454e00000000000000
    bytes32 public constant CONTRACT_KTON_ERC20_TOKEN = "CONTRACT_KTON_ERC20_TOKEN";

    // 0x434f4e54524143545f474f4c445f45524332305f544f4b454e00000000000000
    bytes32 public constant CONTRACT_GOLD_ERC20_TOKEN = "CONTRACT_GOLD_ERC20_TOKEN";

    // 0x434f4e54524143545f574f4f445f45524332305f544f4b454e00000000000000
    bytes32 public constant CONTRACT_WOOD_ERC20_TOKEN = "CONTRACT_WOOD_ERC20_TOKEN";

    // 0x434f4e54524143545f57415445525f45524332305f544f4b454e000000000000
    bytes32 public constant CONTRACT_WATER_ERC20_TOKEN = "CONTRACT_WATER_ERC20_TOKEN";

    // 0x434f4e54524143545f464952455f45524332305f544f4b454e00000000000000
    bytes32 public constant CONTRACT_FIRE_ERC20_TOKEN = "CONTRACT_FIRE_ERC20_TOKEN";

    // 0x434f4e54524143545f534f494c5f45524332305f544f4b454e00000000000000
    bytes32 public constant CONTRACT_SOIL_ERC20_TOKEN = "CONTRACT_SOIL_ERC20_TOKEN";

    // 0x434f4e54524143545f4f424a4543545f4f574e45525348495000000000000000
    bytes32 public constant CONTRACT_OBJECT_OWNERSHIP = "CONTRACT_OBJECT_OWNERSHIP";

    // 0x434f4e54524143545f544f4b454e5f4c4f434154494f4e000000000000000000
    bytes32 public constant CONTRACT_TOKEN_LOCATION = "CONTRACT_TOKEN_LOCATION";

    // 0x434f4e54524143545f4c414e445f424153450000000000000000000000000000
    bytes32 public constant CONTRACT_LAND_BASE = "CONTRACT_LAND_BASE";

    // 0x434f4e54524143545f555345525f504f494e5453000000000000000000000000
    bytes32 public constant CONTRACT_USER_POINTS = "CONTRACT_USER_POINTS";

    // 0x434f4e54524143545f494e5445525354454c4c41525f454e434f444552000000
    bytes32 public constant CONTRACT_INTERSTELLAR_ENCODER = "CONTRACT_INTERSTELLAR_ENCODER";

    // 0x434f4e54524143545f4449564944454e44535f504f4f4c000000000000000000
    bytes32 public constant CONTRACT_DIVIDENDS_POOL = "CONTRACT_DIVIDENDS_POOL";

    // 0x434f4e54524143545f544f4b454e5f5553450000000000000000000000000000
    bytes32 public constant CONTRACT_TOKEN_USE = "CONTRACT_TOKEN_USE";

    // 0x434f4e54524143545f524556454e55455f504f4f4c0000000000000000000000
    bytes32 public constant CONTRACT_REVENUE_POOL = "CONTRACT_REVENUE_POOL";

    // 0x434f4e54524143545f4252494447455f504f4f4c000000000000000000000000
    bytes32 public constant CONTRACT_BRIDGE_POOL = "CONTRACT_BRIDGE_POOL";

    // 0x434f4e54524143545f4552433732315f42524944474500000000000000000000
    bytes32 public constant CONTRACT_ERC721_BRIDGE = "CONTRACT_ERC721_BRIDGE";

    // 0x434f4e54524143545f5045545f42415345000000000000000000000000000000
    bytes32 public constant CONTRACT_PET_BASE = "CONTRACT_PET_BASE";

    // Cut owner takes on each auction, measured in basis points (1/100 of a percent).
    // this can be considered as transaction fee.
    // Values 0-10,000 map to 0%-100%
    // set ownerCut to 4%
    // ownerCut = 400;
    // 0x55494e545f41554354494f4e5f43555400000000000000000000000000000000
    bytes32 public constant UINT_AUCTION_CUT = "UINT_AUCTION_CUT";  // Denominator is 10000

    // 0x55494e545f544f4b454e5f4f464645525f435554000000000000000000000000
    bytes32 public constant UINT_TOKEN_OFFER_CUT = "UINT_TOKEN_OFFER_CUT";  // Denominator is 10000

    // Cut referer takes on each auction, measured in basis points (1/100 of a percent).
    // which cut from transaction fee.
    // Values 0-10,000 map to 0%-100%
    // set refererCut to 4%
    // refererCut = 400;
    // 0x55494e545f524546455245525f43555400000000000000000000000000000000
    bytes32 public constant UINT_REFERER_CUT = "UINT_REFERER_CUT";

    // 0x55494e545f4252494447455f4645450000000000000000000000000000000000
    bytes32 public constant UINT_BRIDGE_FEE = "UINT_BRIDGE_FEE";

    // 0x434f4e54524143545f4c414e445f5245534f5552434500000000000000000000
    bytes32 public constant CONTRACT_LAND_RESOURCE = "CONTRACT_LAND_RESOURCE";
}

////// contracts/interfaces/IBurnableERC20.sol
/* pragma solidity ^0.4.23; */

contract IBurnableERC20 {
    function burn(address _from, uint _value) public;
}

////// contracts/interfaces/IERC165.sol

/* pragma solidity ^0.4.24; */

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
contract IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

////// contracts/interfaces/IERC1155.sol

/* pragma solidity ^0.4.24; */

/* import "./IERC165.sol"; */

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
contract IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] accounts, uint256[] ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] ids, uint256[] amounts, bytes data) external;
}

////// contracts/interfaces/IERC1155Receiver.sol

/* pragma solidity ^0.4.24; */

/**
 * _Available since v3.1._
 */
contract IERC1155Receiver {

    bytes4 internal constant ERC1155_RECEIVED_VALUE = 0xf23a6e61;
    bytes4 internal constant ERC1155_BATCH_RECEIVED_VALUE = 0xbc197c81;

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] ids,
        uint256[] values,
        bytes data
    )
        external
        returns(bytes4);
}

////// contracts/interfaces/IERC721.sol
/* pragma solidity ^0.4.24; */

/* import "./IERC165.sol"; */

/**
 * @title IERC721 Non-Fungible Token Standard basic interface
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract IERC721 is IERC165 {

  bytes4 internal constant InterfaceId_ERC721 = 0x80ac58cd;
  /*
   * 0x80ac58cd ===
   *   bytes4(keccak256('balanceOf(address)')) ^
   *   bytes4(keccak256('ownerOf(uint256)')) ^
   *   bytes4(keccak256('approve(address,uint256)')) ^
   *   bytes4(keccak256('getApproved(uint256)')) ^
   *   bytes4(keccak256('setApprovalForAll(address,bool)')) ^
   *   bytes4(keccak256('isApprovedForAll(address,address)')) ^
   *   bytes4(keccak256('transferFrom(address,address,uint256)')) ^
   *   bytes4(keccak256('safeTransferFrom(address,address,uint256)')) ^
   *   bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)'))
   */

  bytes4 internal constant InterfaceId_ERC721Exists = 0x4f558e79;
  /*
   * 0x4f558e79 ===
   *   bytes4(keccak256('exists(uint256)'))
   */

  bytes4 internal constant InterfaceId_ERC721Enumerable = 0x780e9d63;
  /**
   * 0x780e9d63 ===
   *   bytes4(keccak256('totalSupply()')) ^
   *   bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) ^
   *   bytes4(keccak256('tokenByIndex(uint256)'))
   */

  bytes4 internal constant InterfaceId_ERC721Metadata = 0x5b5e139f;
  /**
   * 0x5b5e139f ===
   *   bytes4(keccak256('name()')) ^
   *   bytes4(keccak256('symbol()')) ^
   *   bytes4(keccak256('tokenURI(uint256)'))
   */

  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 indexed _tokenId
  );
  event Approval(
    address indexed _owner,
    address indexed _approved,
    uint256 indexed _tokenId
  );
  event ApprovalForAll(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function exists(uint256 _tokenId) public view returns (bool _exists);

  function approve(address _to, uint256 _tokenId) public;
  function getApproved(uint256 _tokenId)
    public view returns (address _operator);

  function setApprovalForAll(address _operator, bool _approved) public;
  function isApprovedForAll(address _owner, address _operator)
    public view returns (bool);

  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId)
    public;

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public;
}

////// contracts/interfaces/IERC721Receiver.sol
/* pragma solidity ^0.4.24; */


/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
contract IERC721Receiver {
  /**
   * @dev Magic value to be returned upon successful reception of an NFT
   *  Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`,
   *  which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
   */
  bytes4 internal constant ERC721_RECEIVED = 0x150b7a02;

  /**
   * @notice Handle the receipt of an NFT
   * @dev The ERC721 smart contract calls this function on the recipient
   * after a `safetransfer`. This function MAY throw to revert and reject the
   * transfer. Return of other than the magic value MUST result in the
   * transaction being reverted.
   * Note: the contract address is always the message sender.
   * @param _operator The address which called `safeTransferFrom` function
   * @param _from The address which previously owned the token
   * @param _tokenId The NFT identifier which is being transferred
   * @param _data Additional data with no specified format
   * @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
   */
  function onERC721Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes _data
  )
    public
    returns(bytes4);
}

////// contracts/interfaces/IInterstellarEncoderV3.sol
/* pragma solidity ^0.4.24; */

contract IInterstellarEncoderV3 {
    uint256 constant CLEAR_HIGH =  0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff;

    uint256 public constant MAGIC_NUMBER = 42;    // Interstellar Encoding Magic Number.
    uint256 public constant CHAIN_ID = 1; // Ethereum mainet.
    uint256 public constant CURRENT_LAND = 1; // 1 is Atlantis, 0 is NaN.

    enum ObjectClass { 
        NaN,
        LAND,
        APOSTLE,
        OBJECT_CLASS_COUNT
    }

    function registerNewObjectClass(address _objectContract, uint8 objectClass) public;

    function encodeTokenId(address _tokenAddress, uint8 _objectClass, uint128 _objectIndex) public view returns (uint256 _tokenId);

    function encodeTokenIdForObjectContract(
        address _tokenAddress, address _objectContract, uint128 _objectId) public view returns (uint256 _tokenId);

    function encodeTokenIdForOuterObjectContract(
        address _objectContract, address nftAddress, address _originNftAddress, uint128 _objectId, uint16 _producerId, uint8 _convertType) public view returns (uint256);

    function getContractAddress(uint256 _tokenId) public view returns (address);

    function getObjectId(uint256 _tokenId) public view returns (uint128 _objectId);

    function getObjectClass(uint256 _tokenId) public view returns (uint8);

    function getObjectAddress(uint256 _tokenId) public view returns (address);

    function getProducerId(uint256 _tokenId) public view returns (uint16);

    function getOriginAddress(uint256 _tokenId) public view returns (address);

}

////// contracts/interfaces/IMintableERC20.sol
/* pragma solidity ^0.4.23; */

contract IMintableERC20 {

    function mint(address _to, uint256 _value) public;
}

////// contracts/interfaces/INFTAdaptor.sol
/* pragma solidity ^0.4.24; */


contract INFTAdaptor {
    function toMirrorTokenId(uint256 _originTokenId) public view returns (uint256);

    function toMirrorTokenIdAndIncrease(uint256 _originTokenId) public returns (uint256);

    function toOriginTokenId(uint256 _mirrorTokenId) public view returns (uint256);

    function approveOriginToken(address _bridge, uint256 _originTokenId) public;

    function ownerInOrigin(uint256 _originTokenId) public view returns (address);

    function cacheMirrorTokenId(uint256 _originTokenId, uint256 _mirrorTokenId) public;
}

////// contracts/interfaces/IPetBase.sol
/* pragma solidity ^0.4.24; */

contract IPetBase {
    function pet2TiedStatus(uint256 _mirrorTokenId) public returns (uint256, uint256);
}

////// contracts/interfaces/ISettingsRegistry.sol
/* pragma solidity ^0.4.24; */

contract ISettingsRegistry {
    enum SettingsValueTypes { NONE, UINT, STRING, ADDRESS, BYTES, BOOL, INT }

    function uintOf(bytes32 _propertyName) public view returns (uint256);

    function stringOf(bytes32 _propertyName) public view returns (string);

    function addressOf(bytes32 _propertyName) public view returns (address);

    function bytesOf(bytes32 _propertyName) public view returns (bytes);

    function boolOf(bytes32 _propertyName) public view returns (bool);

    function intOf(bytes32 _propertyName) public view returns (int);

    function setUintProperty(bytes32 _propertyName, uint _value) public;

    function setStringProperty(bytes32 _propertyName, string _value) public;

    function setAddressProperty(bytes32 _propertyName, address _value) public;

    function setBytesProperty(bytes32 _propertyName, bytes _value) public;

    function setBoolProperty(bytes32 _propertyName, bool _value) public;

    function setIntProperty(bytes32 _propertyName, int _value) public;

    function getValueTypeOf(bytes32 _propertyName) public view returns (uint /* SettingsValueTypes */ );

    event ChangeProperty(bytes32 indexed _propertyName, uint256 _type);
}

////// contracts/ERC721BridgeV2.sol
/* pragma solidity ^0.4.24; */

/* import "./PausableDSAuth.sol"; */
/* import "./interfaces/ISettingsRegistry.sol"; */
/* import "./SettingIds.sol"; */
/* import "./interfaces/IInterstellarEncoderV3.sol"; */
/* import "./interfaces/IMintableERC20.sol"; */
/* import "./interfaces/IBurnableERC20.sol"; */
/* import "./interfaces/INFTAdaptor.sol"; */
/* import "./interfaces/IERC1155.sol"; */
/* import "./interfaces/IERC1155Receiver.sol"; */
/* import "./interfaces/IERC721.sol"; */
/* import "./interfaces/IERC721Receiver.sol"; */
/* import "./interfaces/IPetBase.sol"; */


/*
 * naming convention:
 * originTokenId - token outside evolutionLand
 * mirrorTokenId - mirror token
 */
contract ERC721BridgeV2 is SettingIds, PausableDSAuth, IERC721Receiver, IERC1155Receiver {

    /*
     *  Storage
    */
    bool private singletonLock = false;

    ISettingsRegistry public registry;


    // originNFTContract => its adator
    // for instance, CryptoKitties => CryptoKittiesAdaptor
    // this need to be registered by owner
    mapping(address => address) public originNFT2Adaptor;

    // tokenId_inside => tokenId_outside
    mapping(uint256 => uint256) public mirrorId2OriginId;

    mapping(uint256 => uint256) public mirrorId2OriginId1155;

    /*
     *  Event
     */
    // event BridgeIn(uint256 originTokenId, uint256 mirrorTokenId, address originContract, address adaptorAddress, address owner);

    event SwapIn(address originContract, uint256 originTokenId, uint256 mirrorTokenId, address owner);
    event SwapOut(address originContract, uint256 originTokenId, uint256 mirrorTokenId, address owner);

    function registerAdaptor(address _originNftAddress, address _erc721Adaptor) public whenNotPaused onlyOwner {
        originNFT2Adaptor[_originNftAddress] = _erc721Adaptor;
    }

    function swapOut721(uint256 _mirrorTokenId) public  {
        IInterstellarEncoderV3 interstellarEncoder = IInterstellarEncoderV3(registry.addressOf(SettingIds.CONTRACT_INTERSTELLAR_ENCODER));
        address nftContract = interstellarEncoder.getOriginAddress(_mirrorTokenId);
        require(nftContract != address(0), "No such NFT contract");
        address adaptor = originNFT2Adaptor[nftContract];
        require(adaptor != address(0), "not registered!");
        require(ownerOfMirror(_mirrorTokenId) == msg.sender, "you have no right to swap it out!");

        address petBase = registry.addressOf(SettingIds.CONTRACT_PET_BASE);
        (uint256 apostleTokenId,) = IPetBase(petBase).pet2TiedStatus(_mirrorTokenId);
        require(apostleTokenId == 0, "Pet has been tied.");
        uint256 originTokenId = mirrorId2OriginId[_mirrorTokenId];
        address objectOwnership = registry.addressOf(SettingIds.CONTRACT_OBJECT_OWNERSHIP);
        address owner = IERC721(objectOwnership).ownerOf(_mirrorTokenId);
        if (owner != address(this)) {
            IERC721(nftContract).approve(address(this), originTokenId); // kitty must approve first 
            IERC721(nftContract).transferFrom(address(this), msg.sender, originTokenId);
        }
        IBurnableERC20(objectOwnership).burn(owner, _mirrorTokenId);
        delete mirrorId2OriginId[_mirrorTokenId];
        emit SwapOut(nftContract, originTokenId, _mirrorTokenId, msg.sender);
    }

	// V2 add - Support PolkaPet
    function swapOut1155(uint256 _mirrorTokenId) public  {
        IInterstellarEncoderV3 interstellarEncoder = IInterstellarEncoderV3(registry.addressOf(SettingIds.CONTRACT_INTERSTELLAR_ENCODER));
        address nftContract = interstellarEncoder.getOriginAddress(_mirrorTokenId);
        require(nftContract != address(0), "No such NFT contract");
        address adaptor = originNFT2Adaptor[nftContract];
        require(adaptor != address(0), "not registered!");
        address objectOwnership = registry.addressOf(SettingIds.CONTRACT_OBJECT_OWNERSHIP);
        require(IERC721(objectOwnership).ownerOf(_mirrorTokenId) == msg.sender, "you have no right to swap it out!");

        address petBase = registry.addressOf(SettingIds.CONTRACT_PET_BASE);
        (uint256 apostleTokenId,) = IPetBase(petBase).pet2TiedStatus(_mirrorTokenId);
        require(apostleTokenId == 0, "Pet has been tied.");
        uint256 originTokenId = mirrorId2OriginId1155[_mirrorTokenId];
        IBurnableERC20(objectOwnership).burn(msg.sender, _mirrorTokenId);
        IERC1155(nftContract).safeTransferFrom(address(this), msg.sender, originTokenId, 1, "");
        delete mirrorId2OriginId1155[_mirrorTokenId];
        emit SwapOut(nftContract, originTokenId, _mirrorTokenId, msg.sender);
    }

    function ownerOf(uint256 _mirrorTokenId) public view returns (address) {
        return ownerOfMirror(_mirrorTokenId);
    }

    // return human owner of the token
    function mirrorOfOrigin(address _originNFT, uint256 _originTokenId) public view returns (uint256) {
        INFTAdaptor adapter = INFTAdaptor(originNFT2Adaptor[_originNFT]);

        return adapter.toMirrorTokenId(_originTokenId);
    }

    // return human owner of the token
    function ownerOfMirror(uint256 _mirrorTokenId) public view returns (address) {
        address objectOwnership = registry.addressOf(SettingIds.CONTRACT_OBJECT_OWNERSHIP);
        address owner = IERC721(objectOwnership).ownerOf(_mirrorTokenId);
        if(owner != address(this)) {
            return owner;
        } else {
            uint originTokenId = mirrorId2OriginId[_mirrorTokenId];
            return INFTAdaptor(originNFT2Adaptor[originOwnershipAddress(_mirrorTokenId)]).ownerInOrigin(originTokenId);
        }
    }

    function originOwnershipAddress(uint256 _mirrorTokenId) public view returns (address) {
        IInterstellarEncoderV3 interstellarEncoder = IInterstellarEncoderV3(registry.addressOf(SettingIds.CONTRACT_INTERSTELLAR_ENCODER));

        return interstellarEncoder.getOriginAddress(_mirrorTokenId);
    }

    function isBridged(uint256 _mirrorTokenId) public view returns (bool) {
        return (mirrorId2OriginId[_mirrorTokenId] != 0);
    }

    // V2 add - Support PolkaPet
    function swapIn1155(address _originNftAddress, uint256 _originTokenId, uint256 _value) public whenNotPaused() {
        address _from = msg.sender;
        IERC1155(_originNftAddress).safeTransferFrom(_from, address(this), _originTokenId, _value, "");
        address adaptor = originNFT2Adaptor[_originNftAddress];
        require(adaptor != address(0), "Not registered!");
        address objectOwnership = registry.addressOf(SettingIds.CONTRACT_OBJECT_OWNERSHIP);
        for (uint256 i = 0; i < _value; i++) {
            uint256 mirrorTokenId = INFTAdaptor(adaptor).toMirrorTokenIdAndIncrease(_originTokenId);
            IMintableERC20(objectOwnership).mint(_from, mirrorTokenId);
            mirrorId2OriginId1155[mirrorTokenId] = _originTokenId;
            // emit BridgeIn(_originTokenId, mirrorTokenId, _originNftAddress, adaptor, _from);
            emit SwapIn(_originNftAddress, _originTokenId, mirrorTokenId, _from);
        }
    }

    function swapIn721(address _originNftAddress, uint256 _originTokenId) public whenNotPaused() {
        address _owner = msg.sender;
        IERC721(_originNftAddress).transferFrom(_owner, address(this), _originTokenId);
        address adaptor = originNFT2Adaptor[_originNftAddress];
        require(adaptor != address(0), "Not registered!");
        uint256 mirrorTokenId = INFTAdaptor(adaptor).toMirrorTokenId(_originTokenId);
        address objectOwnership = registry.addressOf(SettingIds.CONTRACT_OBJECT_OWNERSHIP);
        require(!isBridged(mirrorTokenId), "Already swap in");
        INFTAdaptor(adaptor).cacheMirrorTokenId(_originTokenId, mirrorTokenId);
        mirrorId2OriginId[mirrorTokenId] = _originTokenId;
        IMintableERC20(objectOwnership).mint(_owner, mirrorTokenId);
        emit SwapIn(_originNftAddress, _originTokenId, mirrorTokenId, _owner);
    }

    function onERC721Received(
      address /*_operator*/,
      address /*_from*/,
      uint256 /*_tokenId*/,
      bytes /*_data*/
    )
      public 
      returns(bytes4) 
    {
        return ERC721_RECEIVED;
    }

    function onERC1155Received(
      address /*operator*/,
      address /*from*/,
      uint256 /*id*/,
      uint256 /*value*/,
      bytes /*data*/
    )
      external
      returns(bytes4)
    {
        return ERC1155_RECEIVED_VALUE; 
    }

    function onERC1155BatchReceived(
      address /*operator*/,
      address /*from*/,
      uint256[] /*ids*/,
      uint256[] /*values*/,
      bytes /*data*/
    )
      external
      returns(bytes4)
    {
        return ERC1155_BATCH_RECEIVED_VALUE;	
    }
}