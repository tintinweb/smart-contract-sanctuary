/**
 *Submitted for verification at Etherscan.io on 2021-03-22
*/

// Dependency file: openzeppelin-solidity/contracts/math/SafeMath.sol

// pragma solidity ^0.4.24;


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


// Dependency file: openzeppelin-solidity/contracts/introspection/ERC165.sol

// pragma solidity ^0.4.24;


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


// Dependency file: openzeppelin-solidity/contracts/token/ERC721/ERC721Basic.sol

// pragma solidity ^0.4.24;

// import "openzeppelin-solidity/contracts/introspection/ERC165.sol";


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


// Dependency file: openzeppelin-solidity/contracts/token/ERC721/ERC721.sol

// pragma solidity ^0.4.24;

// import "openzeppelin-solidity/contracts/token/ERC721/ERC721Basic.sol";


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


// Dependency file: openzeppelin-solidity/contracts/introspection/SupportsInterfaceWithLookup.sol

// pragma solidity ^0.4.24;

// import "openzeppelin-solidity/contracts/introspection/ERC165.sol";


/**
 * @title SupportsInterfaceWithLookup
 * @author Matt Condon (@shrugs)
 * @dev Implements ERC165 using a lookup table.
 */
contract SupportsInterfaceWithLookup is ERC165 {

  bytes4 public constant InterfaceId_ERC165 = 0x01ffc9a7;
  /**
   * 0x01ffc9a7 ===
   *   bytes4(keccak256('supportsInterface(bytes4)'))
   */

  /**
   * @dev a mapping of interface id to whether or not it's supported
   */
  mapping(bytes4 => bool) internal supportedInterfaces;

  /**
   * @dev A contract implementing SupportsInterfaceWithLookup
   * implement ERC165 itself
   */
  constructor()
    public
  {
    _registerInterface(InterfaceId_ERC165);
  }

  /**
   * @dev implement supportsInterface(bytes4) using a lookup table
   */
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool)
  {
    return supportedInterfaces[_interfaceId];
  }

  /**
   * @dev private method for registering an interface
   */
  function _registerInterface(bytes4 _interfaceId)
    internal
  {
    require(_interfaceId != 0xffffffff);
    supportedInterfaces[_interfaceId] = true;
  }
}


// Dependency file: @evolutionland/common/contracts/interfaces/IMintableERC20.sol

// pragma solidity ^0.4.23;

contract IMintableERC20 {

    function mint(address _to, uint256 _value) public;
}

// Dependency file: @evolutionland/common/contracts/interfaces/ISettingsRegistry.sol

// pragma solidity ^0.4.24;

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

// Dependency file: @evolutionland/common/contracts/interfaces/IAuthority.sol

// pragma solidity ^0.4.24;

contract IAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) public view returns (bool);
}

// Dependency file: @evolutionland/common/contracts/DSAuth.sol

// pragma solidity ^0.4.24;

// import '/Users/echo/workspace/contract/evolutionlandorg/land/node_modules/@evolutionland/common/contracts/interfaces/IAuthority.sol';

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


// Dependency file: @evolutionland/common/contracts/SettingIds.sol

// pragma solidity ^0.4.24;

/**
    Id definitions for SettingsRegistry.sol
    Can be used in conjunction with the settings registry to get properties
*/
contract SettingIds {
    bytes32 public constant CONTRACT_RING_ERC20_TOKEN = "CONTRACT_RING_ERC20_TOKEN";

    bytes32 public constant CONTRACT_KTON_ERC20_TOKEN = "CONTRACT_KTON_ERC20_TOKEN";

    bytes32 public constant CONTRACT_GOLD_ERC20_TOKEN = "CONTRACT_GOLD_ERC20_TOKEN";

    bytes32 public constant CONTRACT_WOOD_ERC20_TOKEN = "CONTRACT_WOOD_ERC20_TOKEN";

    bytes32 public constant CONTRACT_WATER_ERC20_TOKEN = "CONTRACT_WATER_ERC20_TOKEN";

    bytes32 public constant CONTRACT_FIRE_ERC20_TOKEN = "CONTRACT_FIRE_ERC20_TOKEN";

    bytes32 public constant CONTRACT_SOIL_ERC20_TOKEN = "CONTRACT_SOIL_ERC20_TOKEN";

    bytes32 public constant CONTRACT_OBJECT_OWNERSHIP = "CONTRACT_OBJECT_OWNERSHIP";

    bytes32 public constant CONTRACT_TOKEN_LOCATION = "CONTRACT_TOKEN_LOCATION";

    bytes32 public constant CONTRACT_LAND_BASE = "CONTRACT_LAND_BASE";

    bytes32 public constant CONTRACT_USER_POINTS = "CONTRACT_USER_POINTS";

    bytes32 public constant CONTRACT_INTERSTELLAR_ENCODER = "CONTRACT_INTERSTELLAR_ENCODER";

    bytes32 public constant CONTRACT_DIVIDENDS_POOL = "CONTRACT_DIVIDENDS_POOL";

    bytes32 public constant CONTRACT_TOKEN_USE = "CONTRACT_TOKEN_USE";

    bytes32 public constant CONTRACT_REVENUE_POOL = "CONTRACT_REVENUE_POOL";

    bytes32 public constant CONTRACT_ERC721_BRIDGE = "CONTRACT_ERC721_BRIDGE";

    bytes32 public constant CONTRACT_PET_BASE = "CONTRACT_PET_BASE";

    // Cut owner takes on each auction, measured in basis points (1/100 of a percent).
    // this can be considered as transaction fee.
    // Values 0-10,000 map to 0%-100%
    // set ownerCut to 4%
    // ownerCut = 400;
    bytes32 public constant UINT_AUCTION_CUT = "UINT_AUCTION_CUT";  // Denominator is 10000

    bytes32 public constant UINT_TOKEN_OFFER_CUT = "UINT_TOKEN_OFFER_CUT";  // Denominator is 10000

    // Cut referer takes on each auction, measured in basis points (1/100 of a percent).
    // which cut from transaction fee.
    // Values 0-10,000 map to 0%-100%
    // set refererCut to 4%
    // refererCut = 400;
    bytes32 public constant UINT_REFERER_CUT = "UINT_REFERER_CUT";

    bytes32 public constant CONTRACT_LAND_RESOURCE = "CONTRACT_LAND_RESOURCE";
}

// Dependency file: @evolutionland/common/contracts/interfaces/IInterstellarEncoder.sol

// pragma solidity ^0.4.24;

contract IInterstellarEncoder {
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

    function registerNewTokenContract(address _tokenAddress) public;

    function encodeTokenId(address _tokenAddress, uint8 _objectClass, uint128 _objectIndex) public view returns (uint256 _tokenId);

    function encodeTokenIdForObjectContract(
        address _tokenAddress, address _objectContract, uint128 _objectId) public view returns (uint256 _tokenId);

    function getContractAddress(uint256 _tokenId) public view returns (address);

    function getObjectId(uint256 _tokenId) public view returns (uint128 _objectId);

    function getObjectClass(uint256 _tokenId) public view returns (uint8);

    function getObjectAddress(uint256 _tokenId) public view returns (address);
}

// Dependency file: @evolutionland/common/contracts/interfaces/ITokenUse.sol

// pragma solidity ^0.4.24;

contract ITokenUse {
    uint48 public constant MAX_UINT48_TIME = 281474976710655;

    function isObjectInHireStage(uint256 _tokenId) public view returns (bool);

    function isObjectReadyToUse(uint256 _tokenId) public view returns (bool);

    function getTokenUser(uint256 _tokenId) public view returns (address);

    function createTokenUseOffer(uint256 _tokenId, uint256 _duration, uint256 _price, address _acceptedActivity) public;

    function cancelTokenUseOffer(uint256 _tokenId) public;

    function takeTokenUseOffer(uint256 _tokenId) public;

    function addActivity(uint256 _tokenId, address _user, uint256 _endTime) public;

    function removeActivity(uint256 _tokenId, address _user) public;
}

// Dependency file: @evolutionland/common/contracts/interfaces/IActivity.sol

// pragma solidity ^0.4.24;

// import "openzeppelin-solidity/contracts/introspection/ERC165.sol";

contract IActivity is ERC165 {
    bytes4 internal constant InterfaceId_IActivity = 0x6086e7f8; 
    /*
     * 0x6086e7f8 ===
     *   bytes4(keccak256('activityStopped(uint256)'))
     */

    function activityStopped(uint256 _tokenId) public;
}

// Dependency file: @evolutionland/common/contracts/interfaces/IMinerObject.sol

// pragma solidity ^0.4.24;

// import "openzeppelin-solidity/contracts/introspection/ERC165.sol";

contract IMinerObject is ERC165  {
    bytes4 internal constant InterfaceId_IMinerObject = 0x64272b75;
    
    /*
     * 0x64272b752 ===
     *   bytes4(keccak256('strengthOf(uint256,address)'))
     */

    function strengthOf(uint256 _tokenId, address _resourceToken, uint256 _landTokenId) public view returns (uint256);

}

// Dependency file: contracts/interfaces/ILandBase.sol

// pragma solidity ^0.4.24;

contract ILandBase {

    /*
     *  Event
     */
    event ModifiedResourceRate(uint indexed tokenId, address resourceToken, uint16 newResourceRate);
    event HasboxSetted(uint indexed tokenId, bool hasBox);

    event ChangedReourceRateAttr(uint indexed tokenId, uint256 attr);

    event ChangedFlagMask(uint indexed tokenId, uint256 newFlagMask);

    event CreatedNewLand(uint indexed tokenId, int x, int y, address beneficiary, uint256 resourceRateAttr, uint256 mask);

    function defineResouceTokenRateAttrId(address _resourceToken, uint8 _attrId) public;

    function setHasBox(uint _landTokenID, bool isHasBox) public;
    function isReserved(uint256 _tokenId) public view returns (bool);
    function isSpecial(uint256 _tokenId) public view returns (bool);
    function isHasBox(uint256 _tokenId) public view returns (bool);

    function getResourceRateAttr(uint _landTokenId) public view returns (uint256);
    function setResourceRateAttr(uint _landTokenId, uint256 _newResourceRateAttr) public;

    function getResourceRate(uint _landTokenId, address _resouceToken) public view returns (uint16);
    function setResourceRate(uint _landTokenID, address _resourceToken, uint16 _newResouceRate) public;

    function getFlagMask(uint _landTokenId) public view returns (uint256);

    function setFlagMask(uint _landTokenId, uint256 _newFlagMask) public;
}


// Dependency file: contracts/LandSettingIds.sol

// pragma solidity ^0.4.24;

// import "@evolutionland/common/contracts/SettingIds.sol";

contract LandSettingIds is SettingIds {

}

// Root file: contracts/LandResourceV4.sol

pragma solidity ^0.4.23;

// import "openzeppelin-solidity/contracts/math/SafeMath.sol";
// import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";
// import "openzeppelin-solidity/contracts/introspection/SupportsInterfaceWithLookup.sol";
// import "@evolutionland/common/contracts/interfaces/IMintableERC20.sol";
// import "@evolutionland/common/contracts/interfaces/ISettingsRegistry.sol";
// import "@evolutionland/common/contracts/DSAuth.sol";
// import "@evolutionland/common/contracts/SettingIds.sol";
// import "@evolutionland/common/contracts/interfaces/IInterstellarEncoder.sol";
// import "@evolutionland/common/contracts/interfaces/ITokenUse.sol";
// import "@evolutionland/common/contracts/interfaces/IActivity.sol";
// import "@evolutionland/common/contracts/interfaces/IMinerObject.sol";
// import "contracts/interfaces/ILandBase.sol";
// import "contracts/LandSettingIds.sol";

/**
 * @title LandResource
 * @dev LandResource is registry that manage the element resources generated on Land, and related resource releasing speed.
 * difference between LandResourceV2:
     1. add function landWorkingOn to get which land the apostle is working on
     2. add function updateMinerStrength to update miner strength on land
     3. add event UpdateMiningStrength
 */


contract LandResourceV4 is SupportsInterfaceWithLookup, DSAuth, IActivity, LandSettingIds {
    using SafeMath for *;

    // For every seconds, the speed will decrease by current speed multiplying (DENOMINATOR_in_seconds - seconds) / DENOMINATOR_in_seconds
    // resource will decrease 1/10000 every day.
    uint256 public constant DENOMINATOR = 10000;

    uint256 public constant TOTAL_SECONDS = DENOMINATOR * (1 days);

    bool private singletonLock = false;

    ISettingsRegistry public registry;

    uint256 public resourceReleaseStartTime;

    // TODO: move to global settings contract.
    uint256 public attenPerDay = 1;
    uint256 public recoverAttenPerDay = 20;

    // Struct for recording resouces on land which have already been pinged.
    // 金, Evolution Land Gold
    // 木, Evolution Land Wood
    // 水, Evolution Land Water
    // 火, Evolution Land fire
    // 土, Evolution Land Silicon
    struct ResourceMineState {
        mapping(address => uint256) mintedBalance;
        mapping(address => uint256[]) miners;
        mapping(address => uint256) totalMinerStrength;
        uint256 lastUpdateSpeedInSeconds;
        uint256 lastDestoryAttenInSeconds;
        uint256 industryIndex;
        uint128 lastUpdateTime;
        uint64 totalMiners;
        uint64 maxMiners;
    }

    struct MinerStatus {
        uint256 landTokenId;
        address resource;
        uint64 indexInResource;
    }

    mapping(uint256 => ResourceMineState) public land2ResourceMineState;

    mapping(uint256 => MinerStatus) public miner2Index;

    /*
     *  Event
     */

    event StartMining(uint256 minerTokenId, uint256 landTokenId, address _resource, uint256 strength);
    event StopMining(uint256 minerTokenId, uint256 landTokenId, address _resource, uint256 strength);
    event ResourceClaimed(address owner, uint256 landTokenId, uint256 goldBalance, uint256 woodBalance, uint256 waterBalance, uint256 fireBalance, uint256 soilBalance);

    event UpdateMiningStrengthWhenStop(uint256 apostleTokenId, uint256 landTokenId, uint256 strength);
    event UpdateMiningStrengthWhenStart(uint256 apostleTokenId, uint256 landTokenId, uint256 strength);
    /*
     *  Modifiers
     */
    modifier singletonLockCall() {
        require(!singletonLock, "Only can call once");
        _;
        singletonLock = true;
    }


    function initializeContract(address _registry, uint256 _resourceReleaseStartTime) public singletonLockCall {
        // Ownable constructor
        owner = msg.sender;
        emit LogSetOwner(msg.sender);

        registry = ISettingsRegistry(_registry);

        resourceReleaseStartTime = _resourceReleaseStartTime;

        _registerInterface(InterfaceId_IActivity);
    }

    // get amount of speed uint at this moment
    function _getReleaseSpeedInSeconds(uint256 _tokenId, uint256 _time) internal view returns (uint256 currentSpeed) {
        require(_time >= resourceReleaseStartTime, "Should after release time");
        require(_time >= land2ResourceMineState[_tokenId].lastUpdateTime, "Should after release last update time");

        // after 10000 days from start
        // the resource release speed decreases to 0
        if (TOTAL_SECONDS < _time - resourceReleaseStartTime)
        {
            return 0;
        }

        // max amount of speed unit of _tokenId for now
        // suppose that speed_uint = 1 in this function
        uint256 availableSpeedInSeconds = TOTAL_SECONDS.sub(_time - resourceReleaseStartTime);
        // time from last update
        uint256 timeBetween = _time - land2ResourceMineState[_tokenId].lastUpdateTime;

        // the recover speed is 20/10000, 20 times.
        // recoveryRate overall from lasUpdateTime til now + amount of speed uint at lastUpdateTime
        uint256 nextSpeedInSeconds = land2ResourceMineState[_tokenId].lastUpdateSpeedInSeconds + timeBetween * recoverAttenPerDay;
        // destroyRate overall from lasUpdateTime til now amount of speed uint at lastUpdateTime
        uint256 destroyedSpeedInSeconds = timeBetween * land2ResourceMineState[_tokenId].lastDestoryAttenInSeconds;

        if (nextSpeedInSeconds < destroyedSpeedInSeconds)
        {
            nextSpeedInSeconds = 0;
        } else {
            nextSpeedInSeconds = nextSpeedInSeconds - destroyedSpeedInSeconds;
        }

        if (nextSpeedInSeconds > availableSpeedInSeconds) {
            nextSpeedInSeconds = availableSpeedInSeconds;
        }

        return nextSpeedInSeconds;
    }

    function getReleaseSpeed(uint256 _tokenId, address _resourceToken, uint256 _time) public view returns (uint256 currentSpeed) {
        return ILandBase(registry.addressOf(CONTRACT_LAND_BASE))
        .getResourceRate(_tokenId, _resourceToken).mul(_getReleaseSpeedInSeconds(_tokenId, _time))
        .div(TOTAL_SECONDS);
    }

    /**
     * @dev Get and Query the amount of resources available from lastUpdateTime to now for use on specific land.
     * @param _tokenId The token id of specific land.
    */
    function _getMinableBalance(uint256 _tokenId, address _resourceToken, uint256 _currentTime, uint256 _lastUpdateTime) public view returns (uint256 minableBalance) {

        uint256 speed_in_current_period = ILandBase(registry.addressOf(CONTRACT_LAND_BASE))
        .getResourceRate(_tokenId, _resourceToken).mul(_getReleaseSpeedInSeconds(_tokenId, ((_currentTime + _lastUpdateTime) / 2))).mul(1 ether).div(1 days).div(TOTAL_SECONDS);

        // calculate the area of trapezoid
        minableBalance = speed_in_current_period.mul(_currentTime - _lastUpdateTime);
    }

    function _getMaxMineBalance(uint256 _tokenId, address _resourceToken, uint256 _currentTime, uint256 _lastUpdateTime) internal view returns (uint256) {
        // totalMinerStrength is in wei
        uint256 mineSpeed = land2ResourceMineState[_tokenId].totalMinerStrength[_resourceToken];

        return mineSpeed.mul(_currentTime - _lastUpdateTime).div(1 days);
    }

    function mine(uint256 _landTokenId) public {
        _mineAllResource(
            _landTokenId,
            registry.addressOf(CONTRACT_GOLD_ERC20_TOKEN),
            registry.addressOf(CONTRACT_WOOD_ERC20_TOKEN),
            registry.addressOf(CONTRACT_WATER_ERC20_TOKEN),
            registry.addressOf(CONTRACT_FIRE_ERC20_TOKEN),
            registry.addressOf(CONTRACT_SOIL_ERC20_TOKEN)
        );
    }

    function _mineAllResource(uint256 _landTokenId, address _gold, address _wood, address _water, address _fire, address _soil) internal {
        require(IInterstellarEncoder(registry.addressOf(CONTRACT_INTERSTELLAR_ENCODER)).getObjectClass(_landTokenId) == 1, "Token must be land.");

        if (land2ResourceMineState[_landTokenId].lastUpdateTime == 0) {
            land2ResourceMineState[_landTokenId].lastUpdateTime = uint128(resourceReleaseStartTime);
            land2ResourceMineState[_landTokenId].lastUpdateSpeedInSeconds = TOTAL_SECONDS;
        }

        _mineResource(_landTokenId, _gold);
        _mineResource(_landTokenId, _wood);
        _mineResource(_landTokenId, _water);
        _mineResource(_landTokenId, _fire);
        _mineResource(_landTokenId, _soil);

        land2ResourceMineState[_landTokenId].lastUpdateSpeedInSeconds = _getReleaseSpeedInSeconds(_landTokenId, now);
        land2ResourceMineState[_landTokenId].lastUpdateTime = uint128(now);

    }

    function _mineResource(uint256 _landTokenId, address _resourceToken) internal {
        // the longest seconds to zero speed.
        uint minedBalance = _calculateMinedBalance(_landTokenId, _resourceToken, now);

        land2ResourceMineState[_landTokenId].mintedBalance[_resourceToken] += minedBalance;
    }

    function _calculateMinedBalance(uint256 _landTokenId, address _resourceToken, uint256 _currentTime) internal returns (uint256) {
        uint256 currentTime = _currentTime;

        uint256 minedBalance;
        uint256 minableBalance;
        if (currentTime > (resourceReleaseStartTime + TOTAL_SECONDS))
        {
            currentTime = (resourceReleaseStartTime + TOTAL_SECONDS);
        }

        uint256 lastUpdateTime = land2ResourceMineState[_landTokenId].lastUpdateTime;
        require(currentTime >= lastUpdateTime);

        if (lastUpdateTime >= (resourceReleaseStartTime + TOTAL_SECONDS)) {
            minedBalance = 0;
            minableBalance = 0;
        } else {
            minedBalance = _getMaxMineBalance(_landTokenId, _resourceToken, currentTime, lastUpdateTime);
            minableBalance = _getMinableBalance(_landTokenId, _resourceToken, currentTime, lastUpdateTime);
        }


        if (minedBalance > minableBalance) {
            minedBalance = minableBalance;
        }

        return minedBalance;
    }

    function claimAllResource(uint256 _landTokenId) public {
        require(msg.sender == ERC721(registry.addressOf(CONTRACT_OBJECT_OWNERSHIP)).ownerOf(_landTokenId), "Must be the owner of the land");

        address gold = registry.addressOf(CONTRACT_GOLD_ERC20_TOKEN);
        address wood = registry.addressOf(CONTRACT_WOOD_ERC20_TOKEN);
        address water = registry.addressOf(CONTRACT_WATER_ERC20_TOKEN);
        address fire = registry.addressOf(CONTRACT_FIRE_ERC20_TOKEN);
        address soil = registry.addressOf(CONTRACT_SOIL_ERC20_TOKEN);

        _mineAllResource(_landTokenId, gold, wood, water, fire, soil);

        uint goldBalance;
        uint woodBalance;
        uint waterBalance;
        uint fireBalance;
        uint soilBalance;

        if (land2ResourceMineState[_landTokenId].mintedBalance[gold] > 0) {
            goldBalance = land2ResourceMineState[_landTokenId].mintedBalance[gold];
            IMintableERC20(gold).mint(msg.sender, goldBalance);
            land2ResourceMineState[_landTokenId].mintedBalance[gold] = 0;
        }

        if (land2ResourceMineState[_landTokenId].mintedBalance[wood] > 0) {
            woodBalance = land2ResourceMineState[_landTokenId].mintedBalance[wood];
            IMintableERC20(wood).mint(msg.sender, woodBalance);
            land2ResourceMineState[_landTokenId].mintedBalance[wood] = 0;
        }

        if (land2ResourceMineState[_landTokenId].mintedBalance[water] > 0) {
            waterBalance = land2ResourceMineState[_landTokenId].mintedBalance[water];
            IMintableERC20(water).mint(msg.sender, waterBalance);
            land2ResourceMineState[_landTokenId].mintedBalance[water] = 0;
        }

        if (land2ResourceMineState[_landTokenId].mintedBalance[fire] > 0) {
            fireBalance = land2ResourceMineState[_landTokenId].mintedBalance[fire];
            IMintableERC20(fire).mint(msg.sender, fireBalance);
            land2ResourceMineState[_landTokenId].mintedBalance[fire] = 0;
        }

        if (land2ResourceMineState[_landTokenId].mintedBalance[soil] > 0) {
            soilBalance = land2ResourceMineState[_landTokenId].mintedBalance[soil];
            IMintableERC20(soil).mint(msg.sender, soilBalance);
            land2ResourceMineState[_landTokenId].mintedBalance[soil] = 0;
        }

        emit ResourceClaimed(msg.sender, _landTokenId, goldBalance, woodBalance, waterBalance, fireBalance, soilBalance);
    }

    // both for own _tokenId or hired one
    function startMining(uint256 _tokenId, uint256 _landTokenId, address _resource) public {
        ITokenUse tokenUse = ITokenUse(registry.addressOf(CONTRACT_TOKEN_USE));

        tokenUse.addActivity(_tokenId, msg.sender, 0);

        // require the permission from land owner;
        require(msg.sender == ERC721(registry.addressOf(CONTRACT_OBJECT_OWNERSHIP)).ownerOf(_landTokenId), "Must be the owner of the land");

        // make sure that _tokenId won't be used repeatedly
        require(miner2Index[_tokenId].landTokenId == 0);

        // update status!
        mine(_landTokenId);

        uint256 _index = land2ResourceMineState[_landTokenId].miners[_resource].length;

        land2ResourceMineState[_landTokenId].totalMiners += 1;

        if (land2ResourceMineState[_landTokenId].maxMiners == 0) {
            land2ResourceMineState[_landTokenId].maxMiners = 5;
        }

        require(land2ResourceMineState[_landTokenId].totalMiners <= land2ResourceMineState[_landTokenId].maxMiners);

        address miner = IInterstellarEncoder(registry.addressOf(CONTRACT_INTERSTELLAR_ENCODER)).getObjectAddress(_tokenId);
        uint256 strength = IMinerObject(miner).strengthOf(_tokenId, _resource, _landTokenId);

        land2ResourceMineState[_landTokenId].miners[_resource].push(_tokenId);
        land2ResourceMineState[_landTokenId].totalMinerStrength[_resource] += strength;

        miner2Index[_tokenId] = MinerStatus({
            landTokenId : _landTokenId,
            resource : _resource,
            indexInResource : uint64(_index)
            });

        emit StartMining(_tokenId, _landTokenId, _resource, strength);

    }

    function batchStartMining(uint256[] _tokenIds, uint256[] _landTokenIds, address[] _resources) public {
        require(_tokenIds.length == _landTokenIds.length && _landTokenIds.length == _resources.length, "input error");
        uint length = _tokenIds.length;

        for (uint i = 0; i < length; i++) {
            startMining(_tokenIds[i], _landTokenIds[i], _resources[i]);
        }

    }

    function batchClaimAllResource(uint256[] _landTokenIds) public {
        uint length = _landTokenIds.length;

        for (uint i = 0; i < length; i++) {
            claimAllResource(_landTokenIds[i]);
        }
    }

    // Only trigger from Token Activity.
    function activityStopped(uint256 _tokenId) public auth {

        _stopMining(_tokenId);
    }

    function stopMining(uint256 _tokenId) public {
        ITokenUse(registry.addressOf(CONTRACT_TOKEN_USE)).removeActivity(_tokenId, msg.sender);
    }

    function _stopMining(uint256 _tokenId) internal {
        // remove the miner from land2ResourceMineState;
        uint64 minerIndex = miner2Index[_tokenId].indexInResource;
        address resource = miner2Index[_tokenId].resource;
        uint256 landTokenId = miner2Index[_tokenId].landTokenId;

        // update status!
        mine(landTokenId);

        uint64 lastMinerIndex = uint64(land2ResourceMineState[landTokenId].miners[resource].length.sub(1));
        uint256 lastMiner = land2ResourceMineState[landTokenId].miners[resource][lastMinerIndex];

        land2ResourceMineState[landTokenId].miners[resource][minerIndex] = lastMiner;
        land2ResourceMineState[landTokenId].miners[resource][lastMinerIndex] = 0;

        land2ResourceMineState[landTokenId].miners[resource].length -= 1;
        miner2Index[lastMiner].indexInResource = minerIndex;

        land2ResourceMineState[landTokenId].totalMiners -= 1;

        address miner = IInterstellarEncoder(registry.addressOf(CONTRACT_INTERSTELLAR_ENCODER)).getObjectAddress(_tokenId);
        uint256 strength = IMinerObject(miner).strengthOf(_tokenId, resource, landTokenId);

        // for backward compatibility
        // if strength can fluctuate some time in the future
        if (land2ResourceMineState[landTokenId].totalMinerStrength[resource] != 0) {
            if (land2ResourceMineState[landTokenId].totalMinerStrength[resource] > strength) {
                land2ResourceMineState[landTokenId].totalMinerStrength[resource] = land2ResourceMineState[landTokenId].totalMinerStrength[resource].sub(strength);
            } else {
                land2ResourceMineState[landTokenId].totalMinerStrength[resource] = 0;
            }
        }

        if (land2ResourceMineState[landTokenId].totalMiners == 0) {
            land2ResourceMineState[landTokenId].totalMinerStrength[resource] = 0;
        }

        delete miner2Index[_tokenId];

        emit StopMining(_tokenId, landTokenId, resource, strength);
    }

    function getMinerOnLand(uint _landTokenId, address _resourceToken, uint _index) public view returns (uint256) {
        return land2ResourceMineState[_landTokenId].miners[_resourceToken][_index];
    }

    function getTotalMiningStrength(uint _landTokenId, address _resourceToken) public view returns (uint256) {
        return land2ResourceMineState[_landTokenId].totalMinerStrength[_resourceToken];
    }

    function availableResources(uint256 _landTokenId, address[5] _resourceTokens) public view returns (uint256, uint256, uint256, uint256, uint256) {

        uint availableGold = _calculateMinedBalance(_landTokenId, _resourceTokens[0], now) + land2ResourceMineState[_landTokenId].mintedBalance[_resourceTokens[0]];
        uint availableWood = _calculateMinedBalance(_landTokenId, _resourceTokens[1], now) + land2ResourceMineState[_landTokenId].mintedBalance[_resourceTokens[1]];
        uint availableWater = _calculateMinedBalance(_landTokenId, _resourceTokens[2], now) + land2ResourceMineState[_landTokenId].mintedBalance[_resourceTokens[2]];
        uint availableFire = _calculateMinedBalance(_landTokenId, _resourceTokens[3], now) + land2ResourceMineState[_landTokenId].mintedBalance[_resourceTokens[3]];
        uint availableSoil = _calculateMinedBalance(_landTokenId, _resourceTokens[4], now) + land2ResourceMineState[_landTokenId].mintedBalance[_resourceTokens[4]];

        return (availableGold, availableWood, availableWater, availableFire, availableSoil);
    }

    function mintedBalanceOnLand(uint256 _landTokenId, address _resourceToken) public view returns (uint256) {
        return land2ResourceMineState[_landTokenId].mintedBalance[_resourceToken];
    }

    function landWorkingOn(uint256 _apostleTokenId) public view returns (uint256 landTokenId) {
        landTokenId = miner2Index[_apostleTokenId].landTokenId;
    }




    function _updateMinerStrength(uint256 _apostleTokenId, bool _isStop) internal returns (uint256, uint256){
        // require that this apostle
        uint256 landTokenId = landWorkingOn(_apostleTokenId);
        require(landTokenId != 0, "this apostle is not mining.");

        address resource = miner2Index[_apostleTokenId].resource;

        address miner = IInterstellarEncoder(registry.addressOf(CONTRACT_INTERSTELLAR_ENCODER)).getObjectAddress(_apostleTokenId);
        uint256 strength = IMinerObject(miner).strengthOf(_apostleTokenId, resource, landTokenId);

        mine(landTokenId);

        if (_isStop) {
            land2ResourceMineState[landTokenId].totalMinerStrength[resource] = land2ResourceMineState[landTokenId].totalMinerStrength[resource].sub(strength);
        } else {
            land2ResourceMineState[landTokenId].totalMinerStrength[resource] += strength;
        }

        return (landTokenId, strength);
    }

    // when a mirrorToken or a pet has tied to apostle
    // we need to update status and remove this apostle from mining list first
    // open authority to PetBase
    // can only be called by PetBase
    function updateMinerStrengthWhenStop(uint256 _apostleTokenId) public auth {
        uint256 landTokenId;
        uint256 strength;
        (landTokenId, strength) = _updateMinerStrength(_apostleTokenId, true);
        // _isStop == true - minus strength
        // _isStop == false - add strength
        emit UpdateMiningStrengthWhenStop(_apostleTokenId, landTokenId, strength);
    }

    function updateMinerStrengthWhenStart(uint256 _apostleTokenId) public auth {
        uint256 landTokenId;
        uint256 strength;
        (landTokenId, strength) = _updateMinerStrength(_apostleTokenId, false);
        // _isStop == true - minus strength
        // _isStop == false - add strength
        emit UpdateMiningStrengthWhenStart(_apostleTokenId, landTokenId, strength);
    }

}