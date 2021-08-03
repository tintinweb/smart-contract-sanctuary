/**
 *Submitted for verification at polygonscan.com on 2021-08-03
*/

// Verified by Darwinia Network

// hevm: flattened sources of contracts/auction/GenesisHolderV2.sol

pragma solidity >=0.4.24 <0.5.0;

////// lib/common-contracts/contracts/SettingIds.sol
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

////// contracts/auction/AuctionSettingIds.sol
/* pragma solidity ^0.4.24; */

/* import "@evolutionland/common/contracts/SettingIds.sol"; */

contract AuctionSettingIds is SettingIds {

    bytes32 public constant CONTRACT_CLOCK_AUCTION = "CONTRACT_CLOCK_AUCTION";

    // BidWaitingTime in seconds, default is 30 minutes
    // necessary period of time from invoking bid action to successfully taking the land asset.
    // if someone else bid the same auction with higher price and within bidWaitingTime, your bid failed.
    bytes32 public constant UINT_AUCTION_BID_WAITING_TIME = "UINT_AUCTION_BID_WAITING_TIME";


    bytes32 public constant CONTRACT_MYSTERIOUS_TREASURE = "CONTRACT_MYSTERIOUS_TREASURE";

    // users change eth(in wei) into ring with bancor exchange
    // which introduce bancor protocol to regulate the price of ring
    // bytes32 public constant CONTRACT_BANCOR_EXCHANGE = "BANCOR_EXCHANGE";

    bytes32 public constant CONTRACT_POINTS_REWARD_POOL = "CONTRACT_POINTS_REWARD_POOL";

    // value belongs to [0, 10000000]
    // bytes32 public constant UINT_EXCHANGE_ERROR_SPACE = "UINT_EXCHANGE_ERROR_SPACE";

    // "CONTRACT_CONTRIBUTION_INCENTIVE_POOL" is too long for byted32
    // so compress it to what states below
    bytes32 public constant CONTRACT_CONTRIBUTION_INCENTIVE_POOL = "CONTRACT_CONTRIBUTION_POOL";

    bytes32 public constant CONTRACT_DEV_POOL = "CONTRACT_DEV_POOL";

    bytes32 public constant CONTRACT_GENESIS_HOLDER = "CONTRACT_GENESIS_HOLDER";

}

////// contracts/auction/interfaces/IClockAuction.sol
/* pragma solidity ^0.4.24; */

contract IClockAuction {
    function createAuction(
        uint256 _tokenId,
        uint256 _startingPriceInToken,
        uint256 _endingPriceInToken,
        uint256 _duration,
        uint256 _startAt,
        address _token)public;

    function cancelAuction(uint256 _tokenId) public;
}

////// contracts/auction/interfaces/IERC20.sol

/* pragma solidity ^0.4.24; */

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

////// lib/common-contracts/contracts/interfaces/ISettingsRegistry.sol
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

////// lib/zeppelin-solidity/contracts/ownership/Ownable.sol
/* pragma solidity ^0.4.24; */


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

////// lib/zeppelin-solidity/contracts/introspection/ERC165.sol
/* pragma solidity ^0.4.24; */


/**
 * @title ERC165
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
 */
interface ERC165 {

  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceId The interface identifier, as specified in ERC-165
   * @dev Interface identification is specified in ERC-165. This function
   * uses less than 30,000 gas.
   */
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}

////// lib/zeppelin-solidity/contracts/token/ERC721/ERC721Basic.sol
/* pragma solidity ^0.4.24; */

/* import "../../introspection/ERC165.sol"; */


/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Basic is ERC165 {

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

////// contracts/auction/GenesisHolderV2.sol
/* pragma solidity ^0.4.24; */

/* import "openzeppelin-solidity/contracts/token/ERC721/ERC721Basic.sol"; */
/* import "openzeppelin-solidity/contracts/ownership/Ownable.sol"; */
/* import "@evolutionland/common/contracts/interfaces/ISettingsRegistry.sol"; */
/* import "./interfaces/IClockAuction.sol"; */
/* import "./AuctionSettingIds.sol"; */
/* import "./interfaces/IERC20.sol"; */

contract GenesisHolderV2 is Ownable, AuctionSettingIds {

    bool private singletonLock = false;

    ISettingsRegistry public registry;

    // the account who creates auctions
    address public operator;

    // claimedToken event
    event ClaimedTokens(address indexed token, address indexed owner, uint amount);
    event ClaimedERC721Token(address indexed owner, uint256 tokenId);

    /*
     * Modifiers
     */
    modifier singletonLockCall() {
        require(!singletonLock, "Only can call once");
        _;
        singletonLock = true;
    }

    constructor() public {
        // initializeContract
    }

    function initializeContract(ISettingsRegistry _registry) public singletonLockCall {
        owner = msg.sender;

        registry = _registry;
    }

    function createAuction(
        uint256 _tokenId,
        uint256 _startingPriceInToken,
        uint256 _endingPriceInToken,
        uint256 _duration,
        uint256 _startAt,
        address _token)
    public {

        require(msg.sender == operator);

        IClockAuction auction = IClockAuction(registry.addressOf(AuctionSettingIds.CONTRACT_CLOCK_AUCTION));

        // aprove land to auction contract
        ERC721Basic(registry.addressOf(SettingIds.CONTRACT_OBJECT_OWNERSHIP)).approve(address(auction), _tokenId);
        // create an auciton
        // have to set _seller to this
        auction.createAuction(_tokenId,_startingPriceInToken, _endingPriceInToken, _duration,_startAt, _token);
    }


    function cancelAuction(uint256 _tokenId) public onlyOwner {
        IClockAuction auction = IClockAuction(registry.addressOf(AuctionSettingIds.CONTRACT_CLOCK_AUCTION));
        auction.cancelAuction(_tokenId);
    }

    /// @notice This method can be used by the owner to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
    function claimTokens(address _token) public onlyOwner {
        if (_token == 0x0) {
            owner.transfer(address(this).balance);
            return;
        }
        IERC20 token = IERC20(_token);
        uint balance = token.balanceOf(address(this));
        token.transfer(owner, balance);

        emit ClaimedTokens(_token, owner, balance);
    }

    function claimERC721Tokens(uint256 _tokenId) public onlyOwner {
        ERC721Basic(registry.addressOf(SettingIds.CONTRACT_OBJECT_OWNERSHIP)).transferFrom(address(this), owner, _tokenId);

        emit ClaimedERC721Token(owner, _tokenId);
    }

    function setOperator(address _operator) public onlyOwner {
        operator = _operator;
    }

    function onERC721Received(
        address /*_operator*/,
        address /*_from*/,
        uint256 /*_tokenId*/,
        bytes /*_data*/
    )
    public
    pure
    returns(bytes4) {
        return bytes4(0x150b7a02);
    }

}