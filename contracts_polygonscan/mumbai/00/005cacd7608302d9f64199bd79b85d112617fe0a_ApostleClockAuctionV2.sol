/**
 *Submitted for verification at polygonscan.com on 2021-08-03
*/

// Verified by Darwinia Network

// hevm: flattened sources of contracts/ApostleClockAuctionV2.sol

pragma solidity >=0.4.24 >=0.4.23 <0.5.0 >=0.4.24 <0.5.0;

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

////// contracts/ApostleSettingIds.sol
/* pragma solidity ^0.4.24; */
/* import "@evolutionland/common/contracts/SettingIds.sol"; */


contract ApostleSettingIds is SettingIds {

    bytes32 public constant CONTRACT_GENE_SCIENCE = "CONTRACT_GENE_SCIENCE";

    /// @notice The minimum payment required to use breedWithAuto(). This fee goes towards
    ///  the gas cost paid by the auto-birth daemon, and can be dynamically updated by
    ///  the COO role as the gas price changes.
    bytes32 public constant UINT_AUTOBIRTH_FEE = "UINT_AUTOBIRTH_FEE";

    bytes32 public constant CONTRACT_APOSTLE_BASE = "CONTRACT_APOSTLE_BASE";

    bytes32 public constant CONTRACT_SIRING_AUCTION = "CONTRACT_SIRING_AUCTION";

    bytes32 public constant CONTRACT_APOSTLE_AUCTION = "CONTRACT_APOSTLE_AUCTION";

    bytes32 public constant CONTRACT_HABERG_POTION_SHOP = "CONTRACT_HABERG_POTION_SHOP";

    // when player wants to buy their apostle some talents
    // the minimum or unit they need to pay
    bytes32 public constant UINT_MIX_TALENT = "UINT_MIX_TALENT";

    bytes32 public constant UINT_APOSTLE_BID_WAITING_TIME = "UINT_APOSTLE_BID_WAITING_TIME";

    /// Denominator is 100000000
    bytes32 public constant UINT_HABERG_POTION_TAX_RATE = "UINT_HABERG_POTION_TAX_RATE";

    // TODO: move this to common-contract
    bytes32 public constant CONTRACT_LAND_RESOURCE = "CONTRACT_LAND_RESOURCE";


    bytes32 public constant CONTRACT_GEN0_APOSTLE = "CONTRACT_GEN0_APOSTLE";
}

////// contracts/interfaces/IApostleBase.sol
/* pragma solidity ^0.4.24; */


// TODO: upgrade common-contacts version then delete this.
contract IApostleBase {
    function createApostle(
        uint256 _matronId, uint256 _sireId, uint256 _generation, uint256 _genes, uint256 _talents, address _owner) public returns (uint256) ;

    function isReadyToBreed(uint256 _apostleId) public view returns (bool);

    function isAbleToBreed(uint256 _matronId, uint256 _sireId, address _owner) public view returns(bool);

    function breedWithInAuction(uint256 _matronId, uint256 _sireId) public returns (bool);

    function canBreedWith(uint256 _matronId, uint256 _sireId) public view returns (bool);

    function getCooldownDuration(uint256 _tokenId) public view returns (uint256);

    function defaultLifeTime(uint256 _tokenId) public view returns (uint256);

    function isDead(uint256 _tokenId) public view returns (bool);

    function approveSiring(address _addr, uint256 _sireId) public;

    function getApostleInfo(uint256 _tokenId) public view returns(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256);

    function updateGenesAndTalents(uint256 _tokenId, uint256 _genes, uint256 _talents) public;
}

////// contracts/interfaces/IERC20.sol
/* pragma solidity ^0.4.24; */

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

////// contracts/interfaces/IRevenuePool.sol
/* pragma solidity >=0.4.24; */

interface IRevenuePool {
    function reward(address _token, uint256 _value, address _buyer) external;
    function settleToken(address _tokenAddress) external;
}

////// lib/common-contracts/contracts/interfaces/IAuthority.sol
/* pragma solidity ^0.4.24; */

contract IAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) public view returns (bool);
}

////// lib/common-contracts/contracts/DSAuth.sol
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
        require(isAuthorized(msg.sender, msg.sig));
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

////// lib/common-contracts/contracts/PausableDSAuth.sol
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

////// lib/zeppelin-solidity/contracts/math/SafeMath.sol
/* pragma solidity ^0.4.24; */


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

////// lib/zeppelin-solidity/contracts/token/ERC721/ERC721.sol
/* pragma solidity ^0.4.24; */

/* import "./ERC721Basic.sol"; */


/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Enumerable is ERC721Basic {
  function totalSupply() public view returns (uint256);
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    public
    view
    returns (uint256 _tokenId);

  function tokenByIndex(uint256 _index) public view returns (uint256);
}


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Metadata is ERC721Basic {
  function name() external view returns (string _name);
  function symbol() external view returns (string _symbol);
  function tokenURI(uint256 _tokenId) public view returns (string);
}


/**
 * @title ERC-721 Non-Fungible Token Standard, full implementation interface
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
}

////// contracts/ApostleClockAuctionV2.sol
/* pragma solidity ^0.4.23; */

/* import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol"; */
/* import "openzeppelin-solidity/contracts/math/SafeMath.sol"; */
/* import "@evolutionland/common/contracts/interfaces/ISettingsRegistry.sol"; */
/* import "@evolutionland/common/contracts/PausableDSAuth.sol"; */
/* import "./ApostleSettingIds.sol"; */
/* import "./interfaces/IApostleBase.sol"; */
/* import "./interfaces/IRevenuePool.sol"; */
/* import "./interfaces/IERC20.sol"; */

contract ApostleClockAuctionV2 is PausableDSAuth, ApostleSettingIds {
    using SafeMath for *;
    event AuctionCreated(
        uint256 tokenId, address seller, uint256 startingPriceInToken, uint256 endingPriceInToken, uint256 duration, address token, uint256 startedAt
    );

    event AuctionSuccessful(uint256 tokenId, uint256 totalPrice, address winner);
    event AuctionCancelled(uint256 tokenId);

    // claimedToken event
    event ClaimedTokens(address indexed token, address indexed owner, uint amount);

    // new bid event
    event NewBid(
        uint256 indexed tokenId, address lastBidder, address lastReferer, uint256 lastRecord, address tokenAddress, uint256 bidStartAt, uint256 returnToLastBidder
    );

    // Represents an auction on an NFT
    struct Auction {
        // Current owner of NFT
        address seller;
        // Time when auction started
        // NOTE: 0 if this auction has been concluded
        uint48 startedAt;
        // Duration (in seconds) of auction
        uint48 duration;
        // Price (in token) at beginning of auction
        uint128 startingPriceInToken;
        // Price (in token) at end of auction
        uint128 endingPriceInToken;
        // bid the auction through which token
        address token;

        // it saves gas in this order
        // highest offered price (in RING)
        uint128 lastRecord;
        // bidder who offer the highest price
        address lastBidder;
        // latestBidder's bidTime in timestamp
        uint48 lastBidStartAt;
        // lastBidder's referer
        address lastReferer;
    }

    bool private singletonLock = false;

    ISettingsRegistry public registry;

    // Map from token ID to their corresponding auction.
    mapping(uint256 => Auction) public tokenIdToAuction;

    /*
    *  Modifiers
    */
    modifier singletonLockCall() {
        require(!singletonLock, "Only can call once");
        _;
        singletonLock = true;
    }

    modifier isHuman() {
        require(msg.sender == tx.origin, "robot is not permitted");
        _;
    }

    // Modifiers to check that inputs can be safely stored with a certain
    // number of bits. We use constants and multiple modifiers to save gas.
    modifier canBeStoredWith48Bits(uint256 _value) {
        require(_value <= 281474976710656);
        _;
    }

    modifier canBeStoredWith128Bits(uint256 _value) {
        require(_value < 340282366920938463463374607431768211455);
        _;
    }

    modifier isOnAuction(uint256 _tokenId) {
        require(tokenIdToAuction[_tokenId].startedAt > 0);
        _;
    }

    ///////////////////////
    // Constructor
    ///////////////////////
    constructor() public {
        // initializeContract
    }

    /// @dev Constructor creates a reference to the NFT ownership contract
    ///  and verifies the owner cut is in the valid range.
    ///  bidWaitingMinutes - biggest waiting time from a bid's starting to ending(in minutes)
    function initializeContract(
        ISettingsRegistry _registry) public singletonLockCall {

        owner = msg.sender;
        emit LogSetOwner(msg.sender);

        registry = _registry;
    }

    /// @dev DON'T give me your money.
    function() external {}

    ///////////////////////
    // Auction Create and Cancel
    ///////////////////////

    function createAuction(
        uint256 _tokenId,
        uint256 _startingPriceInToken,
        uint256 _endingPriceInToken,
        uint256 _duration,
        uint256 _startAt,
        address _token) // with any token
    public auth {
        _createAuction(msg.sender, _tokenId, _startingPriceInToken, _endingPriceInToken, _duration, _startAt, msg.sender, _token);
    }

    /// @dev Cancels an auction that hasn't been won yet.
    ///  Returns the NFT to original owner.
    /// @notice This is a state-modifying function that can
    ///  be called while the contract is paused.
    /// @param _tokenId - ID of token on auction
    function cancelAuction(uint256 _tokenId) public isOnAuction(_tokenId)
    {
        Auction storage auction = tokenIdToAuction[_tokenId];

        address seller = auction.seller;
        require((msg.sender == seller && !paused) || msg.sender == owner);

        // once someone has bidden for this auction, no one has the right to cancel it.
        require(auction.lastBidder == 0x0);

        delete tokenIdToAuction[_tokenId];

        ERC721(registry.addressOf(SettingIds.CONTRACT_OBJECT_OWNERSHIP)).safeTransferFrom(this, seller, _tokenId);
        emit AuctionCancelled(_tokenId);
    }

    //@dev only NFT contract can invoke this
    //@param _from - owner of _tokenId
    function receiveApproval(
        address _from,
        uint256 _tokenId,
        bytes //_extraData
    )
    public
    whenNotPaused
    {
        if (msg.sender == registry.addressOf(SettingIds.CONTRACT_OBJECT_OWNERSHIP)) {
            uint256 startingPriceInRING;
            uint256 endingPriceInRING;
            uint256 duration;
            address seller;

            assembly {
                let ptr := mload(0x40)
                calldatacopy(ptr, 0, calldatasize)
                startingPriceInRING := mload(add(ptr, 132))
                endingPriceInRING := mload(add(ptr, 164))
                duration := mload(add(ptr, 196))
                seller := mload(add(ptr, 228))
            }

            // TODO: add parameter _token
            _createAuction(_from, _tokenId, startingPriceInRING, endingPriceInRING, duration, now, seller, registry.addressOf(SettingIds.CONTRACT_RING_ERC20_TOKEN));
        }

    }

    ///////////////////////
    // Bid With Auction
    ///////////////////////

    // @dev bid with RING. Computes the price and transfers winnings.
    function bidWithToken(uint256 _tokenId, address _referer, uint256 _amountMax) public whenNotPaused returns (uint256){
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(auction.startedAt > 0);
        // Get a reference to the auction struct
        // Check that the incoming bid is higher than the current price
        uint priceInToken = getCurrentPriceInToken(_tokenId);
        require(_amountMax >= priceInToken,
            "your offer is lower than the current price, try again with a higher one.");
        require(IERC20(auction.token).transferFrom(msg.sender, address(this), priceInToken), 'transfer failed');

        uint bidMoment;
        uint returnToLastBidder;
        (bidMoment, returnToLastBidder) = _bidProcess(msg.sender, auction, priceInToken, _referer);

        // Tell the world!
        emit NewBid(_tokenId, msg.sender, _referer, priceInToken, auction.token, bidMoment, returnToLastBidder);

        return priceInToken;
    }

    // TODO: advice: offer some reward for the person who claimed
    // @dev claim _tokenId for auction's lastBidder
    function claimApostleAsset(uint _tokenId) public isHuman isOnAuction(_tokenId) {
        // Get a reference to the auction struct
        Auction storage auction = tokenIdToAuction[_tokenId];

        // at least bidWaitingTime after last bidder's bid moment,
        // and no one else has bidden during this bidWaitingTime,
        // then any one can claim this token(land) for lastBidder.
        require(auction.lastBidder != 0x0 && now >= auction.lastBidStartAt + registry.uintOf(ApostleSettingIds.UINT_APOSTLE_BID_WAITING_TIME),
            "this auction has not finished yet, try again later");

        address lastBidder = auction.lastBidder;
        uint lastRecord = auction.lastRecord;

        delete tokenIdToAuction[_tokenId];

        ERC721(registry.addressOf(SettingIds.CONTRACT_OBJECT_OWNERSHIP)).safeTransferFrom(this, lastBidder, _tokenId);

        emit AuctionSuccessful(_tokenId, lastRecord, lastBidder);
    }

    function _sellerPay(address _token, address _pool, address _seller, address _buyer, uint256 _value) internal {
        if (_seller == registry.addressOf(ApostleSettingIds.CONTRACT_GEN0_APOSTLE)) {
            IERC20(_token).approve(_pool, _value);
            IRevenuePool(_pool).reward(_token, _value, _buyer);
        } else {
            IERC20(_token).transfer(_seller, _value);
        }
    }

    function _deductFee(address _referer, address _token, address _pool, address _buyer, uint256 _ownerCutAmount) internal {
        uint256 refererCut = registry.uintOf(UINT_REFERER_CUT);
        if (_referer != 0x0) {
            uint256 refererBounty = computeCut(_ownerCutAmount, refererCut);
            uint256 fee = _ownerCutAmount - refererBounty;
            IERC20(_token).transfer(_referer, refererBounty);
            IERC20(_token).approve(_pool, fee);
            IRevenuePool(_pool).reward(_token, fee, _buyer);
        } else {
            IERC20(_token).approve(_pool, _ownerCutAmount);
            IRevenuePool(_pool).reward(_token, _ownerCutAmount, _buyer);
        }
    }

    function _firstPartBid(uint _auctionCut, address _pool, address _buyer, Auction storage _auction, uint _priceInToken, address _referer) internal returns (uint, uint){
        require(now >= uint256(_auction.startedAt));
        //  Calculate the auctioneer's cut.
        // (NOTE: computeCut() is guaranteed to return a
        //  value <= price, so this subtraction can't go negative.)
        // TODO: token to the seller
        uint256 ownerCutAmount = computeCut(_priceInToken, _auctionCut);

        // transfer to the seller
        _sellerPay(_auction.token, _pool, _auction.seller, _buyer, (_priceInToken - ownerCutAmount));

        // deduct fee
        _deductFee(_referer, _auction.token, _pool, _buyer, ownerCutAmount);

        // modify bid-related member variables
        _auction.lastBidder = _buyer;
        _auction.lastRecord = uint128(_priceInToken);
        _auction.lastBidStartAt = uint48(now);
        _auction.lastReferer = _referer;

        return (_auction.lastBidStartAt, 0);
    }


    function _secondPartBid(uint _auctionCut, address _pool, address _buyer, Auction storage _auction, uint _priceInToken, address _referer) internal returns (uint, uint){
        // TODO: repair bug of first bid's time limitation
        // if this the first bid, there is no time limitation
        require(now <= _auction.lastBidStartAt + registry.uintOf(ApostleSettingIds.UINT_APOSTLE_BID_WAITING_TIME), "It's too late.");

        // _priceInToken that is larger than lastRecord
        // was assured in _currentPriceInRING(_auction)
        // here double check
        // 1.1*price + bounty - (price + bounty) = 0.1 * price
        uint surplus = _priceInToken.sub(uint256(_auction.lastRecord));
        uint poolCutAmount = computeCut(surplus, _auctionCut);
        uint realReturnForEach = (surplus - poolCutAmount) / 2;
        uint returnToLastBidder = realReturnForEach + uint256(_auction.lastRecord);

        // here use transfer(address,uint256) for safety
        _sellerPay(_auction.token, _pool, _auction.seller, _buyer, realReturnForEach);
        IERC20(_auction.token).transfer(_auction.lastBidder, returnToLastBidder);

        // deduct fee
        _deductFee(_referer, _auction.token, _pool, _buyer, poolCutAmount);

        // modify bid-related member variables
        _auction.lastBidder = _buyer;
        _auction.lastRecord = uint128(_priceInToken);
        _auction.lastBidStartAt = uint48(now);
        _auction.lastReferer = _referer;

        return (_auction.lastBidStartAt, (realReturnForEach + uint256(_auction.lastRecord)));
    }

    // TODO: add _token to compatible backwards with ring and eth
    function _bidProcess(address _buyer, Auction storage _auction, uint _priceInToken, address _referer)
    internal
    canBeStoredWith128Bits(_priceInToken)
    returns (uint256, uint256){

        uint auctionCut = registry.uintOf(UINT_AUCTION_CUT);
        address revenuePool = registry.addressOf(CONTRACT_REVENUE_POOL);

        // uint256 refererBounty;

        // the first bid
        if (_auction.lastBidder == 0x0 && _priceInToken > 0) {

            return _firstPartBid(auctionCut, revenuePool, _buyer, _auction, _priceInToken, _referer);
        }

        // TODO: the math calculation needs further check
        //  not the first bid
        if (_auction.lastRecord > 0 && _auction.lastBidder != 0x0) {

            return _secondPartBid(auctionCut, revenuePool, _buyer, _auction, _priceInToken, _referer);
        }

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

    /// @dev Computes owner's cut of a sale.
    /// @param _price - Sale price of NFT.
    function computeCut(uint256 _price, uint256 _cut) public pure returns (uint256) {
        // NOTE: We don't use SafeMath (or similar) in this function because
        //  all of our entry functions carefully cap the maximum values for
        //  currency (at 128-bits), and ownerCut <= 10000 (see the require()
        //  statement in the ClockAuction constructor). The result of this
        //  function is always guaranteed to be <= _price.
        return _price * _cut / 10000;
    }

    /// @dev Returns auction info for an NFT on auction.
    /// @param _tokenId - ID of NFT on auction.
    function getAuction(uint256 _tokenId)
    public
    view
    returns
    (
        address seller,
        uint256 startedAt,
        uint256 duration,
        uint256 startingPrice,
        uint256 endingPrice,
        address token,
        uint128 lastRecord,
        address lastBidder,
        uint256 lastBidStartAt,
        address lastReferer
    ) {
        Auction storage auction = tokenIdToAuction[_tokenId];
        return (
        auction.seller,
        auction.startingPriceInToken,
        auction.endingPriceInToken,
        auction.duration,
        auction.startedAt,
        auction.token,
        auction.lastRecord,
        auction.lastBidder,
        auction.lastBidStartAt,
        auction.lastReferer
        );
    }

    /// @dev Returns the current price of an auction.
    /// Returns current price of an NFT on auction. Broken into two
    ///  functions (this one, that computes the duration from the auction
    ///  structure, and the other that does the price computation) so we
    ///  can easily test that the price computation works correctly.
    /// @param _tokenId - ID of the token price we are checking.
    function getCurrentPriceInToken(uint256 _tokenId)
    public
    view
    returns (uint256)
    {
        uint256 secondsPassed = 0;

        // A bit of insurance against negative values (or wraparound).
        // Probably not necessary (since Ethereum guarnatees that the
        // now variable doesn't ever go backwards).
        if (now > tokenIdToAuction[_tokenId].startedAt) {
            secondsPassed = now - tokenIdToAuction[_tokenId].startedAt;
        }
        // if no one has bidden for _auction, compute the price as below.
        if (tokenIdToAuction[_tokenId].lastRecord == 0) {
            return _computeCurrentPriceInToken(
                tokenIdToAuction[_tokenId].startingPriceInToken,
                tokenIdToAuction[_tokenId].endingPriceInToken,
                tokenIdToAuction[_tokenId].duration,
                secondsPassed
            );
        } else {
            // compatible with first bid
            // as long as price_offered_by_buyer >= 1.1 * currentPice,
            // this buyer will be the lastBidder
            // 1.1 * (lastRecord)
            return (11 * (uint256(tokenIdToAuction[_tokenId].lastRecord)) / 10);
        }
    }

    // to apply for the safeTransferFrom
    function onERC721Received(
        address, //_operator,
        address, //_from,
        uint256, //_tokenId,
        bytes //_data
    )
    public
    pure
    returns (bytes4) {
        // owner can put apostle on market
        // after coolDownEndTime
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    // get auction's price of last bidder offered
    // @dev return price of _auction (in RING)
    function getLastRecord(uint _tokenId) public view returns (uint256) {
        return tokenIdToAuction[_tokenId].lastRecord;
    }

    function getLastBidder(uint _tokenId) public view returns (address) {
        return tokenIdToAuction[_tokenId].lastBidder;
    }

    function getLastBidStartAt(uint _tokenId) public view returns (uint256) {
        return tokenIdToAuction[_tokenId].lastBidStartAt;
    }

    // @dev if someone new wants to bid, the lowest price he/she need to afford
    function computeNextBidRecord(uint _tokenId) public view returns (uint256) {
        return getCurrentPriceInToken(_tokenId);
    }

    /// @dev Creates and begins a new auction.
    /// @param _tokenId - ID of token to auction, sender must be owner.
    //  NOTE: change _startingPrice and _endingPrice in from wei to ring for user-friendly reason
    /// @param _startingPriceInToken - Price of item (in token) at beginning of auction.
    /// @param _endingPriceInToken - Price of item (in token) at end of auction.
    /// @param _duration - Length of time to move between starting
    ///  price and ending price (in seconds).
    /// @param _seller - Seller, if not the message sender
    function _createAuction(
        address _from,
        uint256 _tokenId,
        uint256 _startingPriceInToken,
        uint256 _endingPriceInToken,
        uint256 _duration,
        uint256 _startAt,
        address _seller,
        address _token
    )
    internal
    canBeStoredWith128Bits(_startingPriceInToken)
    canBeStoredWith128Bits(_endingPriceInToken)
    canBeStoredWith48Bits(_duration)
    canBeStoredWith48Bits(_startAt)
    whenNotPaused
    {
        // Require that all auctions have a duration of
        // at least one minute. (Keeps our math from getting hairy!)
        require(_duration >= 1 minutes, "duration must be at least 1 minutes");
        require(_duration <= 1000 days);
        require(IApostleBase(registry.addressOf(ApostleSettingIds.CONTRACT_APOSTLE_BASE)).isReadyToBreed(_tokenId), "it is still in use or have a baby to give birth.");
        // escrow
        ERC721(registry.addressOf(SettingIds.CONTRACT_OBJECT_OWNERSHIP)).safeTransferFrom(_from, this, _tokenId);

        tokenIdToAuction[_tokenId] = Auction({
            seller : _seller,
            startedAt : uint48(_startAt),
            duration : uint48(_duration),
            startingPriceInToken : uint128(_startingPriceInToken),
            endingPriceInToken : uint128(_endingPriceInToken),
            lastRecord : 0,
            token : _token,
            // which refer to lastRecord, lastBidder, lastBidStartAt,lastReferer
            // all set to zero when initialized
            lastBidder : address(0),
            lastBidStartAt : 0,
            lastReferer : address(0)
            });

        emit AuctionCreated(_tokenId, _seller, _startingPriceInToken, _endingPriceInToken, _duration, _token, _startAt);
    }

    /// @dev Computes the current price of an auction. Factored out
    ///  from _currentPrice so we can run extensive unit tests.
    ///  When testing, make this function public and turn on
    ///  `Current price computation` test suite.
    function _computeCurrentPriceInToken(
        uint256 _startingPriceInToken,
        uint256 _endingPriceInToken,
        uint256 _duration,
        uint256 _secondsPassed
    )
    internal
    pure
    returns (uint256)
    {
        // NOTE: We don't use SafeMath (or similar) in this function because
        //  all of our public functions carefully cap the maximum values for
        //  time (at 64-bits) and currency (at 128-bits). _duration is
        //  also known to be non-zero (see the require() statement in
        //  _addAuction())
        if (_secondsPassed >= _duration) {
            // We've reached the end of the dynamic pricing portion
            // of the auction, just return the end price.
            return _endingPriceInToken;
        } else {
            // Starting price can be higher than ending price (and often is!), so
            // this delta can be negative.
            int256 totalPriceInTokenChange = int256(_endingPriceInToken) - int256(_startingPriceInToken);

            // This multiplication can't overflow, _secondsPassed will easily fit within
            // 64-bits, and totalPriceChange will easily fit within 128-bits, their product
            // will always fit within 256-bits.
            int256 currentPriceInTokenChange = totalPriceInTokenChange * int256(_secondsPassed) / int256(_duration);

            // currentPriceChange can be negative, but if so, will have a magnitude
            // less that _startingPrice. Thus, this result will always end up positive.
            int256 currentPriceInToken = int256(_startingPriceInToken) + currentPriceInTokenChange;

            return uint256(currentPriceInToken);
        }
    }
}