/**
 *Submitted for verification at Etherscan.io on 2021-07-02
*/

/**
 *Submitted for verification at hecoinfo.com on 2021-07-02
*/

// Verified by Darwinia Network

// hevm: flattened sources of contracts/LandResourceV6.sol

pragma solidity >=0.4.23 <0.5.0 >=0.4.24 <0.5.0;

////// contracts/interfaces/ILandBase.sol
/* pragma solidity ^0.4.24; */

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

////// contracts/interfaces/ILandBaseExt.sol
/* pragma solidity ^0.4.24; */

contract ILandBaseExt {
    function resourceToken2RateAttrId(address _resourceToken) external view returns (uint256);
}

////// contracts/interfaces/IMetaDataTeller.sol
/* pragma solidity ^0.4.24; */

interface IMetaDataTeller {
	function addTokenMeta(
		address _token,
		uint16 _grade,
		uint112 _strengthRate
	) external;

	//0xf666196d
	function getMetaData(address _token, uint256 _id)
		external
		view
		returns (
			uint16,
			uint16,
			uint16
		);

	//0x7999a5cf
	function getPrefer(address _token) external view returns (uint256);

	//0x33281815
	function getRate(
		address _token,
		uint256 _id,
		uint256 _index
	) external view returns (uint256);
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

////// lib/common-contracts/contracts/interfaces/IActivity.sol
/* pragma solidity ^0.4.24; */

/* import "openzeppelin-solidity/contracts/introspection/ERC165.sol"; */

contract IActivity is ERC165 {
    bytes4 internal constant InterfaceId_IActivity = 0x6086e7f8; 
    /*
     * 0x6086e7f8 ===
     *   bytes4(keccak256('activityStopped(uint256)'))
     */

    function activityStopped(uint256 _tokenId) public;
}

////// lib/common-contracts/contracts/interfaces/IInterstellarEncoder.sol
/* pragma solidity ^0.4.24; */

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

////// lib/common-contracts/contracts/interfaces/IMinerObject.sol
/* pragma solidity ^0.4.24; */

/* import "openzeppelin-solidity/contracts/introspection/ERC165.sol"; */

contract IMinerObject is ERC165  {
    bytes4 internal constant InterfaceId_IMinerObject = 0x64272b75;
    
    /*
     * 0x64272b752 ===
     *   bytes4(keccak256('strengthOf(uint256,address)'))
     */

    function strengthOf(uint256 _tokenId, address _resourceToken, uint256 _landTokenId) public view returns (uint256);

}

////// lib/common-contracts/contracts/interfaces/IMintableERC20.sol
/* pragma solidity ^0.4.23; */

contract IMintableERC20 {

    function mint(address _to, uint256 _value) public;
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

////// lib/common-contracts/contracts/interfaces/ITokenUse.sol
/* pragma solidity ^0.4.24; */

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

////// lib/zeppelin-solidity/contracts/introspection/SupportsInterfaceWithLookup.sol
/* pragma solidity ^0.4.24; */

/* import "./ERC165.sol"; */


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

////// contracts/LandResourceV6.sol
/* pragma solidity ^0.4.24; */

/* import "openzeppelin-solidity/contracts/math/SafeMath.sol"; */
/* import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol"; */
/* import "openzeppelin-solidity/contracts/introspection/SupportsInterfaceWithLookup.sol"; */
/* import "@evolutionland/common/contracts/interfaces/IMintableERC20.sol"; */
/* import "@evolutionland/common/contracts/interfaces/ISettingsRegistry.sol"; */
/* import "@evolutionland/common/contracts/DSAuth.sol"; */
/* import "@evolutionland/common/contracts/interfaces/IInterstellarEncoder.sol"; */
/* import "@evolutionland/common/contracts/interfaces/ITokenUse.sol"; */
/* import "@evolutionland/common/contracts/interfaces/IActivity.sol"; */
/* import "@evolutionland/common/contracts/interfaces/IMinerObject.sol"; */
/* import "./interfaces/ILandBase.sol"; */
/* import "./interfaces/ILandBaseExt.sol"; */
/* import "./interfaces/IMetaDataTeller.sol"; */

// DSAuth see https://github.com/evolutionlandorg/common-contracts/blob/2873a4f8f970bd442ffcf9c6ae63b3dc79e743db/contracts/DSAuth.sol#L40
contract LandResourceV6 is SupportsInterfaceWithLookup, DSAuth, IActivity {
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

	event StartMining(
		uint256 minerTokenId,
		uint256 landId,
		address _resource,
		uint256 strength
	);
	event StopMining(
		uint256 minerTokenId,
		uint256 landId,
		address _resource,
		uint256 strength
	);
	event ResourceClaimed(
		address owner,
		uint256 landTokenId,
		uint256 goldBalance,
		uint256 woodBalance,
		uint256 waterBalance,
		uint256 fireBalance,
		uint256 soilBalance
	);
	event UpdateMiningStrengthWhenStop(
		uint256 apostleTokenId,
		uint256 landId,
		uint256 strength
	);
	event UpdateMiningStrengthWhenStart(
		uint256 apostleTokenId,
		uint256 landId,
		uint256 strength
	);

	// v5 add begin
	event StartBarMining(
		uint256 barIndex,
		uint256 landId,
		address resource,
		uint256 rate
	);
	event StopBarMining(uint256 barIndex, uint256 landId, address rate);
	event LandResourceClaimed(
		address owner,
		uint256 landId,
		uint256 goldBalance,
		uint256 woodBalance,
		uint256 waterBalance,
		uint256 fireBalance,
		uint256 soilBalance
	);
	event ItemResourceClaimed(
		address owner,
		address itemToken,
		uint256 itemTokenId,
		uint256 goldBalance,
		uint256 woodBalance,
		uint256 waterBalance,
		uint256 fireBalance,
		uint256 soilBalance
	);

	// land item bar
	event Equip(
		uint256 indexed tokenId,
		address resource,
		uint256 index,
		address staker,
		address token,
		uint256 id
	);
	event Divest(
		uint256 indexed tokenId,
		address resource,
		uint256 index,
		address staker,
		address token,
		uint256 id
	);

    	event SetMaxLandBar(uint256 maxAmount);
    	event SetMaxMiner(uint256 maxMiners);

	// 0x434f4e54524143545f4c414e445f424153450000000000000000000000000000
	bytes32 public constant CONTRACT_LAND_BASE = "CONTRACT_LAND_BASE";

	// 0x434f4e54524143545f474f4c445f45524332305f544f4b454e00000000000000
	bytes32 public constant CONTRACT_GOLD_ERC20_TOKEN =
		"CONTRACT_GOLD_ERC20_TOKEN";

	// 0x434f4e54524143545f574f4f445f45524332305f544f4b454e00000000000000
	bytes32 public constant CONTRACT_WOOD_ERC20_TOKEN =
		"CONTRACT_WOOD_ERC20_TOKEN";

	// 0x434f4e54524143545f57415445525f45524332305f544f4b454e000000000000
	bytes32 public constant CONTRACT_WATER_ERC20_TOKEN =
		"CONTRACT_WATER_ERC20_TOKEN";

	// 0x434f4e54524143545f464952455f45524332305f544f4b454e00000000000000
	bytes32 public constant CONTRACT_FIRE_ERC20_TOKEN =
		"CONTRACT_FIRE_ERC20_TOKEN";

	// 0x434f4e54524143545f534f494c5f45524332305f544f4b454e00000000000000
	bytes32 public constant CONTRACT_SOIL_ERC20_TOKEN =
		"CONTRACT_SOIL_ERC20_TOKEN";

	// 0x434f4e54524143545f494e5445525354454c4c41525f454e434f444552000000
	bytes32 public constant CONTRACT_INTERSTELLAR_ENCODER =
		"CONTRACT_INTERSTELLAR_ENCODER";

	// 0x434f4e54524143545f4f424a4543545f4f574e45525348495000000000000000
	bytes32 public constant CONTRACT_OBJECT_OWNERSHIP =
		"CONTRACT_OBJECT_OWNERSHIP";

	// 0x434f4e54524143545f544f4b454e5f5553450000000000000000000000000000
	bytes32 public constant CONTRACT_TOKEN_USE = "CONTRACT_TOKEN_USE";

	//0x4655524e4143455f4954454d5f4d494e455f4645450000000000000000000000
	bytes32 public constant FURNACE_ITEM_MINE_FEE = "FURNACE_ITEM_MINE_FEE";

	// 0x434f4e54524143545f4d455441444154415f54454c4c45520000000000000000
	bytes32 public constant CONTRACT_METADATA_TELLER =
		"CONTRACT_METADATA_TELLER";

	// 0x55494e545f4954454d4241525f50524f544543545f504552494f440000000000
	bytes32 public constant UINT_ITEMBAR_PROTECT_PERIOD =
		"UINT_ITEMBAR_PROTECT_PERIOD";

	// rate precision
	uint128 public constant RATE_PRECISION = 10**8;

	uint256 public maxMiners;

	// (itemTokenAddress => (itemTokenId => (resourceAddress => mined balance)))
	mapping(address => mapping(uint256 => mapping(address => uint256)))
		public itemMinedBalance;

	// (landTokenId => (resourceAddress => (landBarIndex => itemEnhancedRate)))
	mapping(uint256 => mapping(address => mapping(uint256 => uint256)))
		public land2BarRate;

	// land bar
	struct Bar {
		address staker;
		address token;
		uint256 id;
		address resource;
	}

	// bar status
	struct Status {
		address staker;
		uint256 tokenId;
		uint256 index;
	}

	// max land bar amount
	uint256 public maxAmount;
	// (landTokenId => (landBarIndex => BAR))
	mapping(uint256 => mapping(uint256 => Bar)) public landId2Bars;
	// (itemTokenAddress => (itemTokenId => STATUS))
	mapping(address => mapping(uint256 => Status)) public itemId2Status;
	// (itemTokenAddress => (itemTokenId => itemProtectPeriod))
	mapping(address => mapping(uint256 => uint256)) public protectPeriod;
	// v5 add end

	/*
	 *  Modifiers
	 */
	modifier singletonLockCall() {
		require(!singletonLock, "Only can call once");
		_;
		singletonLock = true;
	}

    	// initializeContract be called by proxy contract
    	// see https://blog.openzeppelin.com/the-transparent-proxy-pattern/
	function initializeContract(
		address _registry,
		uint256 _resourceReleaseStartTime
	) public singletonLockCall {
        require(_registry!= address(0), "_registry is a zero value");
		// Ownable constructor
		owner = msg.sender;
		emit LogSetOwner(msg.sender);

		registry = ISettingsRegistry(_registry);

		resourceReleaseStartTime = _resourceReleaseStartTime;

        	//see https://github.com/evolutionlandorg/common-contracts/blob/2873a4f8f970bd442ffcf9c6ae63b3dc79e743db/contracts/interfaces/IActivity.sol#L6
		_registerInterface(InterfaceId_IActivity);

        	maxMiners = 5;
        	maxAmount = 5;
	}

	// get amount of speed uint at this moment
	function _getReleaseSpeedInSeconds(uint256 _tokenId, uint256 _time)
		internal
		view
		returns (uint256 currentSpeed)
	{
		require(_time >= resourceReleaseStartTime, "Should after release time");
		require(
			_time >= land2ResourceMineState[_tokenId].lastUpdateTime,
			"Should after release last update time"
		);

		// after 10000 days from start
		// the resource release speed decreases to 0
		if (TOTAL_SECONDS < _time - resourceReleaseStartTime) {
			return 0;
		}

		// max amount of speed unit of _tokenId for now
		// suppose that speed_uint = 1 in this function
		uint256 availableSpeedInSeconds =
			TOTAL_SECONDS.sub(_time - resourceReleaseStartTime);
		return availableSpeedInSeconds;
		// // time from last update
		// uint256 timeBetween =
		// 	_time - land2ResourceMineState[_tokenId].lastUpdateTime;

		// // the recover speed is 20/10000, 20 times.
		// // recoveryRate overall from lasUpdateTime til now + amount of speed uint at lastUpdateTime
		// uint256 nextSpeedInSeconds =
		// 	land2ResourceMineState[_tokenId].lastUpdateSpeedInSeconds +
		// 		timeBetween *
		// 		recoverAttenPerDay;
		// // destroyRate overall from lasUpdateTime til now amount of speed uint at lastUpdateTime
		// uint256 destroyedSpeedInSeconds =
		// 	timeBetween *
		// 		land2ResourceMineState[_tokenId].lastDestoryAttenInSeconds;

		// if (nextSpeedInSeconds < destroyedSpeedInSeconds) {
		// 	nextSpeedInSeconds = 0;
		// } else {
		// 	nextSpeedInSeconds = nextSpeedInSeconds - destroyedSpeedInSeconds;
		// }

		// if (nextSpeedInSeconds > availableSpeedInSeconds) {
		// 	nextSpeedInSeconds = availableSpeedInSeconds;
		// }

		// return nextSpeedInSeconds;
	}

	function getReleaseSpeed(
		uint256 _tokenId,
		address _resource,
		uint256 _time
	) public view returns (uint256 currentSpeed) {
		return
			ILandBase(registry.addressOf(CONTRACT_LAND_BASE))
				.getResourceRate(_tokenId, _resource)
				.mul(_getReleaseSpeedInSeconds(_tokenId, _time))
				.mul(1 ether)
				.div(TOTAL_SECONDS);
	}

	// For every seconds, the speed will decrease by current speed multiplying (DENOMINATOR_in_seconds - seconds) / DENOMINATOR_in_seconds.
	// resource will decrease 1/10000 every day.
    	// `minableBalance` is an area of a trapezoid.
    	// The reason for dividing by `1 days` twice is that the definition of `getResourceRate` is the number of mines that can be mined per day.
	function _getMinableBalance(
		uint256 _tokenId,
		address _resource,
		uint256 _currentTime,
		uint256 _lastUpdateTime
	) public view returns (uint256 minableBalance) {
		uint256 speed_in_current_period =
			ILandBase(registry.addressOf(CONTRACT_LAND_BASE))
				.getResourceRate(_tokenId, _resource)
				.mul(
				_getReleaseSpeedInSeconds(
					_tokenId,
					((_currentTime + _lastUpdateTime) / 2)
				)
			)
				.mul(1 ether)
				.div(1 days)
				.div(TOTAL_SECONDS);

		// calculate the area of trapezoid
		minableBalance = speed_in_current_period.mul(
			_currentTime - _lastUpdateTime
		);
	}

	function _getMaxMineBalance(
		uint256 _tokenId,
		address _resource,
		uint256 _currentTime,
		uint256 _lastUpdateTime
	) internal view returns (uint256) {
		// totalMinerStrength is in wei
		return
			getTotalMiningStrength(_tokenId, _resource)
				.mul(_currentTime - _lastUpdateTime)
				.div(1 days);
	}

	function setMaxMiners(uint256 _maxMiners) public auth {
		require(_maxMiners > maxMiners, "Land: INVALID_MAXMINERS");
		maxMiners = _maxMiners;
        emit SetMaxMiner(maxMiners);
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

	function _mineAllResource(
		uint256 _landTokenId,
		address _gold,
		address _wood,
		address _water,
		address _fire,
		address _soil
	) internal {
		require(
			IInterstellarEncoder(
				registry.addressOf(CONTRACT_INTERSTELLAR_ENCODER)
			)
				.getObjectClass(_landTokenId) == 1,
			"Token must be land."
		);

		// v5 remove
		// if (land2ResourceMineState[_landTokenId].lastUpdateTime == 0) {
		// 	land2ResourceMineState[_landTokenId].lastUpdateTime = uint128(
		// 		resourceReleaseStartTime
		// 	);
		// 	land2ResourceMineState[_landTokenId]
		// 		.lastUpdateSpeedInSeconds = TOTAL_SECONDS;
		// }

		_mineResource(_landTokenId, _gold);
		_mineResource(_landTokenId, _wood);
		_mineResource(_landTokenId, _water);
		_mineResource(_landTokenId, _fire);
		_mineResource(_landTokenId, _soil);

		// v5 remove
		// land2ResourceMineState[_landTokenId]
		// 	.lastUpdateSpeedInSeconds = _getReleaseSpeedInSeconds(
		// 	_landTokenId,
		// 	now
		// );

		land2ResourceMineState[_landTokenId].lastUpdateTime = uint128(now);
	}

	function _distribution(
		uint256 _landId,
		address _resource,
		uint256 minedBalance,
		uint256 barsRate
	) internal returns (uint256) {
		uint256 landBalance =
			minedBalance.mul(RATE_PRECISION).div(barsRate.add(RATE_PRECISION));
		uint256 barsBalance = minedBalance.sub(landBalance);
		for (uint256 i = 0; i < maxAmount; i++) {
			(address itemToken, uint256 itemId, address resouce) =
				getBarItem(_landId, i);
			if (itemToken != address(0) && resouce == _resource) {
				uint256 barBalance =
					barsBalance.mul(getBarRate(_landId, _resource, i)).div(
						barsRate
					);
				(barBalance, landBalance) = _payFee(barBalance, landBalance);
				itemMinedBalance[itemToken][itemId][
					_resource
				] = getItemMinedBalance(itemToken, itemId, _resource).add(
					barBalance
				);
			}
		}
		return landBalance;
	}

	function _payFee(uint256 barBalance, uint256 landBalance)
		internal
		view
		returns (uint256, uint256)
	{
		uint256 fee =
			barBalance.mul(registry.uintOf(FURNACE_ITEM_MINE_FEE)).div(
				RATE_PRECISION
			);
		barBalance = barBalance.sub(fee);
		landBalance = landBalance.add(fee);
		return (barBalance, landBalance);
	}

	function _mineResource(uint256 _landId, address _resource) internal {
		// the longest seconds to zero speed.
		if (getLandMiningStrength(_landId, _resource) == 0) {
			return;
		}
		uint256 minedBalance = _calculateMinedBalance(_landId, _resource, now);
		if (minedBalance == 0) {
			return;
		}

		uint256 barsRate = getBarsRate(_landId, _resource);
		uint256 landBalance = minedBalance;
		if (barsRate > 0) {
			// V5 yeild distribution
			landBalance = _distribution(
				_landId,
				_resource,
				minedBalance,
				barsRate
			);
		}
		land2ResourceMineState[_landId].mintedBalance[
			_resource
		] = getLandMinedBalance(_landId, _resource).add(landBalance);
	}

	function _calculateMinedBalance(
		uint256 _landTokenId,
		address _resourceToken,
		uint256 _currentTime
	) internal view returns (uint256) {
		uint256 currentTime = _currentTime;

		uint256 minedBalance;
		uint256 minableBalance;
		if (currentTime > (resourceReleaseStartTime + TOTAL_SECONDS)) {
			currentTime = (resourceReleaseStartTime + TOTAL_SECONDS);
		}

		uint256 lastUpdateTime =
			land2ResourceMineState[_landTokenId].lastUpdateTime;
		require(currentTime >= lastUpdateTime, "Land: INVALID_TIMESTAMP");

		if (lastUpdateTime >= (resourceReleaseStartTime + TOTAL_SECONDS)) {
			minedBalance = 0;
			minableBalance = 0;
		} else {
			minedBalance = _getMaxMineBalance(
				_landTokenId,
				_resourceToken,
				currentTime,
				lastUpdateTime
			);
			minableBalance = _getMinableBalance(
				_landTokenId,
				_resourceToken,
				currentTime,
				lastUpdateTime
			);
		}

		if (minedBalance > minableBalance) {
			minedBalance = minableBalance;
		} 

		return minedBalance;
	}

	// v5 remove
	// function claimAllResource(uint256 _landTokenId) public {
	// 	require(
	// 		msg.sender == ownership.ownerOf(_landTokenId),
	// 		"Must be the owner of the land"
	// 	);

	// 	_mineAllResource(_landTokenId, gold, wood, water, fire, soil);

	// 	uint256 goldBalance;
	// 	uint256 woodBalance;
	// 	uint256 waterBalance;
	// 	uint256 fireBalance;
	// 	uint256 soilBalance;

	// 	if (land2ResourceMineState[_landTokenId].mintedBalance[gold] > 0) {
	// 		goldBalance = land2ResourceMineState[_landTokenId].mintedBalance[
	// 			gold
	// 		];
	// 		IMintableERC20(gold).mint(msg.sender, goldBalance);
	// 		land2ResourceMineState[_landTokenId].mintedBalance[gold] = 0;
	// 	}

	// 	if (land2ResourceMineState[_landTokenId].mintedBalance[wood] > 0) {
	// 		woodBalance = land2ResourceMineState[_landTokenId].mintedBalance[
	// 			wood
	// 		];
	// 		IMintableERC20(wood).mint(msg.sender, woodBalance);
	// 		land2ResourceMineState[_landTokenId].mintedBalance[wood] = 0;
	// 	}

	// 	if (land2ResourceMineState[_landTokenId].mintedBalance[water] > 0) {
	// 		waterBalance = land2ResourceMineState[_landTokenId].mintedBalance[
	// 			water
	// 		];
	// 		IMintableERC20(water).mint(msg.sender, waterBalance);
	// 		land2ResourceMineState[_landTokenId].mintedBalance[water] = 0;
	// 	}

	// 	if (land2ResourceMineState[_landTokenId].mintedBalance[fire] > 0) {
	// 		fireBalance = land2ResourceMineState[_landTokenId].mintedBalance[
	// 			fire
	// 		];
	// 		IMintableERC20(fire).mint(msg.sender, fireBalance);
	// 		land2ResourceMineState[_landTokenId].mintedBalance[fire] = 0;
	// 	}

	// 	if (land2ResourceMineState[_landTokenId].mintedBalance[soil] > 0) {
	// 		soilBalance = land2ResourceMineState[_landTokenId].mintedBalance[
	// 			soil
	// 		];
	// 		IMintableERC20(soil).mint(msg.sender, soilBalance);
	// 		land2ResourceMineState[_landTokenId].mintedBalance[soil] = 0;
	// 	}

	// 	emit ResourceClaimed(
	// 		msg.sender,
	// 		_landTokenId,
	// 		goldBalance,
	// 		woodBalance,
	// 		waterBalance,
	// 		fireBalance,
	// 		soilBalance
	// 	);
	// }

	// both for own _tokenId or hired one
	function startMining(
		uint256 _tokenId,
		uint256 _landTokenId,
		address _resource
	) public {
		// require the permission from land owner;
		require(
			msg.sender ==
				ERC721(registry.addressOf(CONTRACT_OBJECT_OWNERSHIP)).ownerOf(
					_landTokenId
				),
			"Must be the owner of the land"
		);

		// make sure that _tokenId won't be used repeatedly
		require(miner2Index[_tokenId].landTokenId == 0);

		ITokenUse(registry.addressOf(CONTRACT_TOKEN_USE)).addActivity(
			_tokenId,
			msg.sender,
			0
		);

		// update status!
		mine(_landTokenId);

		uint256 _index =
			land2ResourceMineState[_landTokenId].miners[_resource].length;

		land2ResourceMineState[_landTokenId].totalMiners += 1;

		// v5 remove
		// if (land2ResourceMineState[_landTokenId].maxMiners == 0) {
		// 	land2ResourceMineState[_landTokenId].maxMiners = 5;
		// }

		require(
			land2ResourceMineState[_landTokenId].totalMiners <= maxMiners,
			"Land: EXCEED_MAXAMOUNT"
		);

		address miner =
			IInterstellarEncoder(
				registry.addressOf(CONTRACT_INTERSTELLAR_ENCODER)
			)
				.getObjectAddress(_tokenId);
		uint256 strength =
			IMinerObject(miner).strengthOf(_tokenId, _resource, _landTokenId);

		land2ResourceMineState[_landTokenId].miners[_resource].push(_tokenId);
		land2ResourceMineState[_landTokenId].totalMinerStrength[_resource] = land2ResourceMineState[_landTokenId].totalMinerStrength[_resource].add(strength);

		miner2Index[_tokenId] = MinerStatus({
			landTokenId: _landTokenId,
			resource: _resource,
			indexInResource: uint64(_index)
		});

		emit StartMining(_tokenId, _landTokenId, _resource, strength);
	}

	function batchStartMining(
		uint256[] _tokenIds,
		uint256[] _landTokenIds,
		address[] _resources
	) external {
		require(
			_tokenIds.length == _landTokenIds.length &&
				_landTokenIds.length == _resources.length,
			"input error"
		);
		uint256 length = _tokenIds.length;

		for (uint256 i = 0; i < length; i++) {
			startMining(_tokenIds[i], _landTokenIds[i], _resources[i]);
		}
	}

	function batchClaimLandResource(uint256[] _landTokenIds) external {
		uint256 length = _landTokenIds.length;

		for (uint256 i = 0; i < length; i++) {
			claimLandResource(_landTokenIds[i]);
		}
	}

	// Only trigger from Token Activity.
	function activityStopped(uint256 _tokenId) public auth {
		_stopMining(_tokenId);
	}

	function stopMining(uint256 _tokenId) public {
		ITokenUse(registry.addressOf(CONTRACT_TOKEN_USE)).removeActivity(
			_tokenId,
			msg.sender
		);
	}

	function _stopMining(uint256 _tokenId) internal {
		// remove the miner from land2ResourceMineState;
		uint64 minerIndex = miner2Index[_tokenId].indexInResource;
		address resource = miner2Index[_tokenId].resource;
		uint256 landTokenId = miner2Index[_tokenId].landTokenId;

		// update status!
		mine(landTokenId);

		uint64 lastMinerIndex =
			uint64(
				land2ResourceMineState[landTokenId].miners[resource].length.sub(
					1
				)
			);
		uint256 lastMiner =
			land2ResourceMineState[landTokenId].miners[resource][
				lastMinerIndex
			];

		land2ResourceMineState[landTokenId].miners[resource][
			minerIndex
		] = lastMiner;
		land2ResourceMineState[landTokenId].miners[resource][
			lastMinerIndex
		] = 0;

		land2ResourceMineState[landTokenId].miners[resource].length = land2ResourceMineState[landTokenId].miners[resource].length.sub(1);
		miner2Index[lastMiner].indexInResource = minerIndex;

		land2ResourceMineState[landTokenId].totalMiners -= 1;

		address miner =
			IInterstellarEncoder(
				registry.addressOf(CONTRACT_INTERSTELLAR_ENCODER)
			)
				.getObjectAddress(_tokenId);
		uint256 strength =
			IMinerObject(miner).strengthOf(_tokenId, resource, landTokenId);

		// for backward compatibility
		// if strength can fluctuate some time in the future
		if (
			land2ResourceMineState[landTokenId].totalMinerStrength[resource] !=
			0
		) {
			if (
				land2ResourceMineState[landTokenId].totalMinerStrength[
					resource
				] > strength
			) {
				land2ResourceMineState[landTokenId].totalMinerStrength[
					resource
				] = land2ResourceMineState[landTokenId].totalMinerStrength[
					resource
				]
					.sub(strength);
			} else {
				land2ResourceMineState[landTokenId].totalMinerStrength[
					resource
				] = 0;
			}
		}

		if (land2ResourceMineState[landTokenId].totalMiners == 0) {
			land2ResourceMineState[landTokenId].totalMinerStrength[
				resource
			] = 0;
		}

		delete miner2Index[_tokenId];

		emit StopMining(_tokenId, landTokenId, resource, strength);
	}

	// v5 remove
	// function getMinerOnLand(
	// 	uint256 _landTokenId,
	// 	address _resourceToken,
	// 	uint256 _index
	// ) public view returns (uint256) {
	// 	return
	// 		land2ResourceMineState[_landTokenId].miners[_resourceToken][_index];
	// }

	// function getTotalMiningStrength(
	// 	uint256 _landTokenId,
	// 	address _resourceToken
	// ) public view returns (uint256) {
	// 	return
	// 		land2ResourceMineState[_landTokenId].totalMinerStrength[
	// 			_resourceToken
	// 		];
	// }

	// function availableResources(
	// 	uint256 _landTokenId,
	// 	address[5] _resourceTokens
	// )
	// 	public
	// 	view
	// 	returns (
	// 		uint256,
	// 		uint256,
	// 		uint256,
	// 		uint256,
	// 		uint256
	// 	)
	// {
	// 	uint256 availableGold =
	// 		_calculateMinedBalance(_landTokenId, _resourceTokens[0], now) +
	// 			land2ResourceMineState[_landTokenId].mintedBalance[
	// 				_resourceTokens[0]
	// 			];
	// 	uint256 availableWood =
	// 		_calculateMinedBalance(_landTokenId, _resourceTokens[1], now) +
	// 			land2ResourceMineState[_landTokenId].mintedBalance[
	// 				_resourceTokens[1]
	// 			];
	// 	uint256 availableWater =
	// 		_calculateMinedBalance(_landTokenId, _resourceTokens[2], now) +
	// 			land2ResourceMineState[_landTokenId].mintedBalance[
	// 				_resourceTokens[2]
	// 			];
	// 	uint256 availableFire =
	// 		_calculateMinedBalance(_landTokenId, _resourceTokens[3], now) +
	// 			land2ResourceMineState[_landTokenId].mintedBalance[
	// 				_resourceTokens[3]
	// 			];
	// 	uint256 availableSoil =
	// 		_calculateMinedBalance(_landTokenId, _resourceTokens[4], now) +
	// 			land2ResourceMineState[_landTokenId].mintedBalance[
	// 				_resourceTokens[4]
	// 			];

	// 	return (
	// 		availableGold,
	// 		availableWood,
	// 		availableWater,
	// 		availableFire,
	// 		availableSoil
	// 	);
	// }

	// V5 remove
	// function mintedBalanceOnLand(uint256 _landTokenId, address _resourceToken) public view returns (uint256) {
	//     return land2ResourceMineState[_landTokenId].mintedBalance[_resourceToken];
	// }

	// function landWorkingOn(uint256 _apostleTokenId) public view returns (uint256 landTokenId) {
	//     landTokenId = miner2Index[_apostleTokenId].landTokenId;
	// }

	function _updateMinerStrength(uint256 _apostleTokenId, bool _isStop)
		internal
		returns (uint256, uint256)
	{
		// require that this apostle
		uint256 landTokenId = landWorkingOn(_apostleTokenId);
		require(landTokenId != 0, "this apostle is not mining.");

		address resource = miner2Index[_apostleTokenId].resource;

		address miner =
			IInterstellarEncoder(
				registry.addressOf(CONTRACT_INTERSTELLAR_ENCODER)
			)
				.getObjectAddress(_apostleTokenId);
		uint256 strength =
			IMinerObject(miner).strengthOf(
				_apostleTokenId,
				resource,
				landTokenId
			);

		mine(landTokenId);

		if (_isStop) {
			land2ResourceMineState[landTokenId].totalMinerStrength[
				resource
			] = land2ResourceMineState[landTokenId].totalMinerStrength[resource]
				.sub(strength);
		} else {
			land2ResourceMineState[landTokenId].totalMinerStrength[resource] = land2ResourceMineState[landTokenId].totalMinerStrength[resource].add(strength);
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
		emit UpdateMiningStrengthWhenStop(
			_apostleTokenId,
			landTokenId,
			strength
		);
	}

	function updateMinerStrengthWhenStart(uint256 _apostleTokenId) public auth {
		uint256 landTokenId;
		uint256 strength;
		(landTokenId, strength) = _updateMinerStrength(_apostleTokenId, false);
		// _isStop == true - minus strength
		// _isStop == false - add strength
		emit UpdateMiningStrengthWhenStart(
			_apostleTokenId,
			landTokenId,
			strength
		);
	}

	// V5 add
	function getLandMinedBalance(uint256 _landId, address _resource)
		public
		view
		returns (uint256)
	{
		return land2ResourceMineState[_landId].mintedBalance[_resource];
	}

	function getItemMinedBalance(
		address _itemToken,
		uint256 _itemId,
		address _resource
	) public view returns (uint256) {
		return itemMinedBalance[_itemToken][_itemId][_resource];
	}

	function getLandMiningStrength(uint256 _landId, address _resource)
		public
		view
		returns (uint256)
	{
		return land2ResourceMineState[_landId].totalMinerStrength[_resource];
	}

	function getBarMiningStrength(
		uint256 _landId,
		address _resource,
		uint256 _index
	) public view returns (uint256) {
		return
			getLandMiningStrength(_landId, _resource)
				.mul(getBarRate(_landId, _resource, _index))
				.div(RATE_PRECISION);
	}

	function getBarRate(
		uint256 _landId,
		address _resource,
		uint256 _index
	) public view returns (uint256) {
		return land2BarRate[_landId][_resource][_index];
	}

	function getBarsRate(uint256 _landId, address _resource)
		public
		view
		returns (uint256 barsRate)
	{
		for (uint256 i = 0; i < maxAmount; i++) {
			barsRate = barsRate.add(getBarRate(_landId, _resource, i));
		}
	}

	function getBarsMiningStrength(uint256 _landId, address _resource)
		public
		view
		returns (uint256 barsMiningStrength)
	{
		return
			getLandMiningStrength(_landId, _resource)
				.mul(getBarsRate(_landId, _resource))
				.div(RATE_PRECISION);
	}

	function getTotalMiningStrength(uint256 _landId, address _resource)
		public
		view
		returns (uint256)
	{
		return
			getLandMiningStrength(_landId, _resource).add(
				getBarsMiningStrength(_landId, _resource)
			);
	}

	function getMinerOnLand(
		uint256 _landId,
		address _resource,
		uint256 _index
	) public view returns (uint256) {
		return land2ResourceMineState[_landId].miners[_resource][_index];
	}

	function landWorkingOn(uint256 _apostleTokenId)
		public
		view
		returns (uint256 landId)
	{
		landId = miner2Index[_apostleTokenId].landTokenId;
	}

	function _getBarRateByIndex(
		uint256 _landId,
		address _resource,
		uint256 _index
	) internal view returns (uint256) {
		return enhanceStrengthRateByIndex(_resource, _landId, _index);
	}

	function _startBarMining(
		uint256 _index,
		uint256 _landId,
		address _resource
	) internal {
		uint256 rate = _getBarRateByIndex(_landId, _resource, _index);
		land2BarRate[_landId][_resource][_index] = rate;
		emit StartBarMining(_index, _landId, _resource, rate);
	}

	function _stopBarMinig(
		uint256 _index,
		uint256 _landId,
		address _resource
	) internal {
		delete land2BarRate[_landId][_resource][_index];
		emit StopBarMining(_index, _landId, _resource);
	}

	function _claimItemResource(
		address _itemToken,
		uint256 _itemId,
		address _resource
	) internal returns (uint256) {
		uint256 balance = getItemMinedBalance(_itemToken, _itemId, _resource);
		if (balance > 0) {
			IMintableERC20(_resource).mint(msg.sender, balance);
			itemMinedBalance[_itemToken][_itemId][_resource] = 0;
			return balance;
		} else {
			return 0;
		}
	}

	function claimItemResource(address _itemToken, uint256 _itemId) public {
		(address staker, uint256 landId) = getLandIdByItem(_itemToken, _itemId);
		if (staker == address(0) && landId == 0) {
			require(
				ERC721(_itemToken).ownerOf(_itemId) == msg.sender,
				"Land: ONLY_ITEM_OWNER"
			);
		} else {
			require(staker == msg.sender, "Land: ONLY_ITEM_STAKER");
			mine(landId);
		}

		address gold = registry.addressOf(CONTRACT_GOLD_ERC20_TOKEN);
		address wood = registry.addressOf(CONTRACT_WOOD_ERC20_TOKEN);
		address water = registry.addressOf(CONTRACT_WATER_ERC20_TOKEN);
		address fire = registry.addressOf(CONTRACT_FIRE_ERC20_TOKEN);
		address soil = registry.addressOf(CONTRACT_SOIL_ERC20_TOKEN);
		uint256 goldBalance = _claimItemResource(_itemToken, _itemId, gold);
		uint256 woodBalance = _claimItemResource(_itemToken, _itemId, wood);
		uint256 waterBalance = _claimItemResource(_itemToken, _itemId, water);
		uint256 fireBalance = _claimItemResource(_itemToken, _itemId, fire);
		uint256 soilBalance = _claimItemResource(_itemToken, _itemId, soil);

		emit ItemResourceClaimed(
			msg.sender,
			_itemToken,
			_itemId,
			goldBalance,
			woodBalance,
			waterBalance,
			fireBalance,
			soilBalance
		);
	}

	function _claimLandResource(uint256 _landId, address _resource)
		internal
		returns (uint256)
	{
		uint256 balance = getLandMinedBalance(_landId, _resource);
		if (balance > 0) {
			IMintableERC20(_resource).mint(msg.sender, balance);
			land2ResourceMineState[_landId].mintedBalance[_resource] = 0;
			return balance;
		} else {
			return 0;
		}
	}

	function claimLandResource(uint256 _landId) public {
		require(
			msg.sender ==
				ERC721(registry.addressOf(CONTRACT_OBJECT_OWNERSHIP)).ownerOf(
					_landId
				),
			"Land: ONLY_LANDER"
		);

		address gold = registry.addressOf(CONTRACT_GOLD_ERC20_TOKEN);
		address wood = registry.addressOf(CONTRACT_WOOD_ERC20_TOKEN);
		address water = registry.addressOf(CONTRACT_WATER_ERC20_TOKEN);
		address fire = registry.addressOf(CONTRACT_FIRE_ERC20_TOKEN);
		address soil = registry.addressOf(CONTRACT_SOIL_ERC20_TOKEN);
		_mineAllResource(_landId, gold, wood, water, fire, soil);

		uint256 goldBalance = _claimLandResource(_landId, gold);
		uint256 woodBalance = _claimLandResource(_landId, wood);
		uint256 waterBalance = _claimLandResource(_landId, water);
		uint256 fireBalance = _claimLandResource(_landId, fire);
		uint256 soilBalance = _claimLandResource(_landId, soil);

		emit LandResourceClaimed(
			msg.sender,
			_landId,
			goldBalance,
			woodBalance,
			waterBalance,
			fireBalance,
			soilBalance
		);
	}

	function _calculateResources(
		address _itemToken,
		uint256 _itemId,
		uint256 _landId,
		address _resource,
		uint256 _minedBalance
	) internal view returns (uint256 landBalance, uint256 barResource) {
		uint256 barsRate = getBarsRate(_landId, _resource);
		// V5 yeild distribution
		landBalance = _minedBalance.mul(RATE_PRECISION).div(
			barsRate.add(RATE_PRECISION)
		);
		if (barsRate > 0) {
			uint256 barsBalance = _minedBalance.sub(landBalance);
			for (uint256 i = 0; i < maxAmount; i++) {
				uint256 barBalance =
					barsBalance.mul(getBarRate(_landId, _resource, i)).div(
						barsRate
					);
				(barBalance, landBalance) = _payFee(barBalance, landBalance);
				(address itemToken, uint256 itemId, ) = getBarItem(_landId, i);
				if (_itemId == itemId && _itemToken == itemToken) {
					barResource = barResource.add(barBalance);
				}
			}
		}
	}

	function availableLandResources(
		uint256 _landId,
		address[] _resources
	) external view returns (uint256[] memory) {
		uint256[] memory availables = new uint256[](_resources.length);
		for (uint256 i = 0; i < _resources.length; i++) {
			uint256 mined = _calculateMinedBalance(_landId, _resources[i], now);
			(uint256 available, ) =
				_calculateResources(
					address(0),
					0,
					_landId,
					_resources[i],
					mined
				);
			availables[i] = available.add(
				getLandMinedBalance(_landId, _resources[i])
			);
		}
		return availables;
	}

	function availableItemResources(
		address _itemToken,
		uint256 _itemId,
		address[] _resources
	) external view returns (uint256[] memory) {
		uint256[] memory availables = new uint256[](_resources.length);
		for (uint256 i = 0; i < _resources.length; i++) {
			(address staker, uint256 landId) =
				getLandIdByItem(_itemToken, _itemId);
			uint256 available = 0;
			if (staker != address(0) && landId != 0) {
				uint256 mined =
					_calculateMinedBalance(landId, _resources[i], now);
				(, uint256 availableItem) =
					_calculateResources(
						_itemToken,
						_itemId,
						landId,
						_resources[i],
						mined
					);
				available = available.add(availableItem);
			}
			available = available.add(
				getItemMinedBalance(_itemToken, _itemId, _resources[i])
			);
			availables[i] = available;
		}
		return availables;
	}

	function isNotProtect(address _token, uint256 _id)
		public
		view
		returns (bool)
	{
		return protectPeriod[_token][_id] < now;
	}

	function getBarItem(uint256 _tokenId, uint256 _index)
		public
		view
		returns (
			address,
			uint256,
			address
		)
	{
		require(_index < maxAmount, "Furnace: INDEX_FORBIDDEN.");
		return (
			landId2Bars[_tokenId][_index].token,
			landId2Bars[_tokenId][_index].id,
			landId2Bars[_tokenId][_index].resource
		);
	}

	function getLandIdByItem(address _item, uint256 _itemId)
		public
		view
		returns (address, uint256)
	{
		return (
			itemId2Status[_item][_itemId].staker,
			itemId2Status[_item][_itemId].tokenId
		);
	}

	/**
        @dev Equip function, A NFT can equip to EVO Bar (LandBar or ApostleBar).
        @param _tokenId  Token Id which to be quiped.
        @param _resource Which resouce appply to.
        @param _index    Index of the Bar.
        @param _token    Token address which to quip.
        @param _id       Token Id which to quip.
    	*/
	function equip(
		uint256 _tokenId,
		address _resource,
		uint256 _index,
		address _token,
		uint256 _id
	) public {
		_equip(_tokenId, _resource, _index, _token, _id);
	}

	function _equip(
		uint256 _tokenId,
		address _resource,
		uint256 _index,
		address _token,
		uint256 _id
	) internal {
		beforeEquip(_tokenId, _resource);
		IMetaDataTeller teller =
			IMetaDataTeller(registry.addressOf(CONTRACT_METADATA_TELLER));
		uint256 resourceId =
			ILandBaseExt(registry.addressOf(CONTRACT_LAND_BASE))
				.resourceToken2RateAttrId(_resource);
		require(resourceId > 0 && resourceId < 6, "Furnace: INVALID_RESOURCE");
		require(
			IInterstellarEncoder(
				registry.addressOf(CONTRACT_INTERSTELLAR_ENCODER)
			)
				.getObjectClass(_tokenId) == 1,
			"Funace: ONLY_LAND"
		);
		(uint16 objClassExt, uint16 class, uint16 grade) =
			teller.getMetaData(_token, _id);
		require(objClassExt > 0, "Furnace: PERMISSION");
		require(_index < maxAmount, "Furnace: INDEX_FORBIDDEN");
		Bar storage bar = landId2Bars[_tokenId][_index];
		if (bar.token != address(0)) {
			require(isNotProtect(bar.token, bar.id), "Furnace: PROTECT_PERIOD");
			(, uint16 originClass, uint16 originGrade) =
				teller.getMetaData(bar.token, bar.id);
			require(
				class > originClass ||
					(class == originClass && grade > originGrade) ||
					ERC721(registry.addressOf(CONTRACT_OBJECT_OWNERSHIP))
						.ownerOf(_tokenId) ==
					msg.sender,
				"Furnace: FORBIDDEN"
			);
			//TODO:: safe transfer
			ERC721(bar.token).transferFrom(address(this), bar.staker, bar.id);
		}
		ERC721(_token).transferFrom(msg.sender, address(this), _id);
		bar.staker = msg.sender;
		bar.token = _token;
		bar.id = _id;
		bar.resource = _resource;
		itemId2Status[bar.token][bar.id] = Status({
			staker: bar.staker,
			tokenId: _tokenId,
			index: _index
		});
		if (isNotProtect(bar.token, bar.id)) {
			protectPeriod[bar.token][bar.id] = _calculateProtectPeriod(class)
				.add(now);
		}
		afterEquiped(_index, _tokenId, _resource);
		emit Equip(_tokenId, _resource, _index, bar.staker, bar.token, bar.id);
	}

	function _calculateProtectPeriod(
		uint16 _class
	) internal view returns (uint256) {
		uint256 baseProtectPeriod =
			registry.uintOf(UINT_ITEMBAR_PROTECT_PERIOD);
		return uint256(_class).mul(baseProtectPeriod);
	}

	function beforeEquip(uint256 _landTokenId, address _resource) internal {
		if (getLandMiningStrength(_landTokenId, _resource) > 0) {
			mine(_landTokenId);
		}
	}

	function afterEquiped(
		uint256 _index,
		uint256 _landTokenId,
		address _resource
	) internal {
		_startBarMining(_index, _landTokenId, _resource);
	}

	function afterDivested(
		uint256 _index,
		uint256 _landTokenId,
		address _resource
	) internal {
		if (getLandMiningStrength(_landTokenId, _resource) > 0) {
			mine(_landTokenId);
		}
		_stopBarMinig(_index, _landTokenId, _resource);
	}

    	function devestAndClaim(address _itemToken, uint256 _tokenId, uint256 _index) public {
		divest(_tokenId, _index);
		claimItemResource(_itemToken, _tokenId);
    	}

	/**
        @dev Divest function, A NFT can Divest from EVO Bar (LandBar or ApostleBar).
        @param _tokenId Token Id which to be unquiped.
        @param _index   Index of the Bar.
    	*/
	function divest(uint256 _tokenId, uint256 _index) public {
		_divest(_tokenId, _index);
	}

	function _divest(uint256 _tokenId, uint256 _index) internal {
		Bar memory bar = landId2Bars[_tokenId][_index];
		require(bar.token != address(0), "Furnace: EMPTY");
		require(bar.staker == msg.sender, "Furnace: FORBIDDEN");
		ERC721(bar.token).transferFrom(address(this), bar.staker, bar.id);
		afterDivested(_index, _tokenId, bar.resource);
		//clean
		delete itemId2Status[bar.token][bar.id];
		delete landId2Bars[_tokenId][_index];
		emit Divest(
			_tokenId,
			bar.resource,
			_index,
			bar.staker,
			bar.token,
			bar.id
		);
	}

	function setMaxAmount(uint256 _maxAmount) public auth {
        require(_maxAmount > maxAmount, "Furnace: INVALID_MAXAMOUNT");
        maxAmount = _maxAmount;
        emit SetMaxLandBar(maxAmount);
	}

	function enhanceStrengthRateByIndex(
		address _resource,
		uint256 _tokenId,
		uint256 _index
	) public view returns (uint256) {
		Bar storage bar = landId2Bars[_tokenId][_index];
		if (bar.token == address(0)) {
			return 0;
		}
		IMetaDataTeller teller =
			IMetaDataTeller(registry.addressOf(CONTRACT_METADATA_TELLER));
		uint256 resourceId =
			ILandBaseExt(registry.addressOf(CONTRACT_LAND_BASE))
				.resourceToken2RateAttrId(_resource);
		return teller.getRate(bar.token, bar.id, resourceId);
	}

	function enhanceStrengthRateOf(address _resource, uint256 _tokenId)
		external
		view
		returns (uint256)
	{
		uint256 rate;
		for (uint256 i = 0; i < maxAmount; i++) {
			rate = rate.add(enhanceStrengthRateByIndex(_resource, _tokenId, i));
		}
		return rate;
	}
}