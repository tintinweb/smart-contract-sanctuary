/**
 *Submitted for verification at polygonscan.com on 2021-08-03
*/

// Verified by Darwinia Network

// hevm: flattened sources of contracts/TokenUseV2.sol

pragma solidity >=0.4.24 >=0.4.24 <0.5.0;

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

////// contracts/interfaces/IActivity.sol
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

////// contracts/interfaces/IActivityObject.sol
/* pragma solidity ^0.4.24; */

/* import "openzeppelin-solidity/contracts/introspection/ERC165.sol"; */

contract IActivityObject is ERC165 {
    bytes4 internal constant InterfaceId_IActivityObject = 0x2b9eccc6; 
    /*
     * 0x2b9eccc6 ===
     *   bytes4(keccak256('activityAdded(uint256,address,address)')) ^ 
     *   bytes4(keccak256('activityRemoved(uint256,address,address)'))
     */

    function activityAdded(uint256 _tokenId, address _activity, address _user) public;

    function activityRemoved(uint256 _tokenId, address _activity, address _user) public;
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

////// contracts/interfaces/IInterstellarEncoder.sol
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

////// contracts/interfaces/IRevenuePool.sol
/* pragma solidity >=0.4.24; */

interface IRevenuePool {
    function reward(address _token, uint256 _value, address _buyer) external;
    function settleToken(address _tokenAddress) external;
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

////// contracts/TokenUseV2.sol
/* pragma solidity ^0.4.24; */

/* import "openzeppelin-solidity/contracts/math/SafeMath.sol"; */
/* import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol"; */
/* import "./interfaces/IActivity.sol"; */
/* import "./interfaces/ISettingsRegistry.sol"; */
/* import "./interfaces/IInterstellarEncoder.sol"; */
/* import "./interfaces/IActivityObject.sol"; */
/* import "./interfaces/IRevenuePool.sol"; */
/* import "./SettingIds.sol"; */
/* import "./DSAuth.sol"; */
/* import "./interfaces/IERC20.sol"; */

contract TokenUseV2 is DSAuth, SettingIds {
    using SafeMath for *;

    // claimedToken event
    event ClaimedTokens(address indexed token, address indexed owner, uint amount);

    event OfferCreated(uint256 indexed tokenId, uint256 duration, uint256 price, address acceptedActivity, address owner);
    event OfferCancelled(uint256 tokenId);
    event OfferTaken(uint256 indexed tokenId, address from, address owner, uint256 now, uint256 endTime);
    event ActivityAdded(uint256 indexed tokenId, address activity, uint256 endTime);
    event ActivityRemoved(uint256 indexed tokenId, address activity);
    event TokenUseRemoved(uint256 indexed tokenId, address owner, address user, address activity);

    struct UseStatus {
        address user;
        address owner;
        uint48  startTime;
        uint48  endTime;
        uint256 price;  // RING per second.
        address acceptedActivity;   // can only be used in this activity.
    }

    struct UseOffer {
        address owner;
        uint48 duration;
        // total price of hiring mft for full duration
        uint256 price;
        address acceptedActivity;   // If 0, then accept any activity
    }

    struct CurrentActivity {
        address activity;
        uint48 endTime;
    }

    bool private singletonLock = false;

    ISettingsRegistry public registry;
    mapping (uint256 => UseStatus) public tokenId2UseStatus;
    mapping (uint256 => UseOffer) public tokenId2UseOffer;

    mapping (uint256 => CurrentActivity ) public tokenId2CurrentActivity;

    /*
     *  Modifiers
     */
    modifier singletonLockCall() {
        require(!singletonLock, "Only can call once");
        _;
        singletonLock = true;
    }

    function initializeContract(ISettingsRegistry _registry) public singletonLockCall {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);

        registry = _registry;
    }

    // false if it is not in useStage
    // based on data in TokenUseStatus
    function isObjectInHireStage(uint256 _tokenId) public view returns (bool) {
        if (tokenId2UseStatus[_tokenId].user == address(0)) {
            return false;
        }
        
        return tokenId2UseStatus[_tokenId].startTime <= now && now <= tokenId2UseStatus[_tokenId].endTime;
    }

    // by check this function
    // you can know if an nft is ok to addActivity
    // based on data in CurrentActivity
    function isObjectReadyToUse(uint256 _tokenId) public view returns (bool) {

        if(tokenId2CurrentActivity[_tokenId].endTime == 0) {
            return tokenId2CurrentActivity[_tokenId].activity == address(0);
        } else {
            return now > tokenId2CurrentActivity[_tokenId].endTime;
        }
    }


    function getTokenUser(uint256 _tokenId) public view returns (address) {
        return tokenId2UseStatus[_tokenId].user;
    }

    function receiveApproval(address _from, uint _tokenId, bytes /*_data*/) public {
        if(msg.sender == registry.addressOf(CONTRACT_OBJECT_OWNERSHIP)) {
            uint256 duration;
            uint256 price;
            address acceptedActivity;
            assembly {
                let ptr := mload(0x40)
                calldatacopy(ptr, 0, calldatasize)
                duration := mload(add(ptr, 132))
                price := mload(add(ptr, 164))
                acceptedActivity := mload(add(ptr, 196))
            }

            // already approve that msg.sender == ownerOf(_tokenId)

            _createTokenUseOffer(_tokenId, duration, price, acceptedActivity, _from);
        }
    }


    // need approval from msg.sender
    function createTokenUseOffer(uint256 _tokenId, uint256 _duration, uint256 _price, address _acceptedActivity) public {
        require(ERC721(registry.addressOf(CONTRACT_OBJECT_OWNERSHIP)).ownerOf(_tokenId) == msg.sender, "Only can call by the token owner.");

        _createTokenUseOffer(_tokenId, _duration, _price, _acceptedActivity, msg.sender);
    }

    // TODO: be careful with unit of duration and price
    // remember to deal with unit off chain
    function _createTokenUseOffer(uint256 _tokenId, uint256 _duration, uint256 _price, address _acceptedActivity, address _owner) internal {
        require(isObjectReadyToUse(_tokenId), "No, it is still in use.");
        require(tokenId2UseOffer[_tokenId].owner == 0, "Token already in another offer.");
        require(_price >= 1 ether, "price must larger than 1 ring.");
        require(_duration >= 7 days);

        ERC721(registry.addressOf(CONTRACT_OBJECT_OWNERSHIP)).transferFrom(_owner, address(this), _tokenId);

        tokenId2UseOffer[_tokenId] = UseOffer({
            owner: _owner,
            duration: uint48(_duration),
            price : _price,
            acceptedActivity: _acceptedActivity
        });

        emit OfferCreated(_tokenId,_duration, _price, _acceptedActivity, _owner);
    }

    function cancelTokenUseOffer(uint256 _tokenId) public {
        require(tokenId2UseOffer[_tokenId].owner == msg.sender, "Only token owner can cancel the offer.");

        ERC721(registry.addressOf(CONTRACT_OBJECT_OWNERSHIP)).transferFrom(address(this), msg.sender,  _tokenId);

        delete tokenId2UseOffer[_tokenId];

        emit OfferCancelled(_tokenId);
    }

    function _pay(address ring, address _seller, uint256 expense) internal {
        uint256 cut = expense.mul(registry.uintOf(UINT_TOKEN_OFFER_CUT)).div(10000);
        IERC20(ring).transfer(_seller, expense.sub(cut));
        address pool = registry.addressOf(CONTRACT_REVENUE_POOL);
        IERC20(ring).approve(pool, cut);
        IRevenuePool(pool).reward(ring, cut, msg.sender);
    }

    function takeTokenUseOffer(uint256 _tokenId, uint256 _amountMax) public {
        uint256 expense = uint256(tokenId2UseOffer[_tokenId].price);
        require(_amountMax >= expense, "offer too low");
        address ring = registry.addressOf(CONTRACT_RING_ERC20_TOKEN);
        IERC20(ring).transferFrom(msg.sender, address(this), expense);
        _pay(ring, tokenId2UseOffer[_tokenId].owner, expense);
        _takeTokenUseOffer(_tokenId, msg.sender);
    }

    function _takeTokenUseOffer(uint256 _tokenId, address _from) internal {
        require(tokenId2UseOffer[_tokenId].owner != address(0), "Offer does not exist for this token.");
        require(isObjectReadyToUse(_tokenId), "Token already in another activity.");

        tokenId2UseStatus[_tokenId] = UseStatus({
            user: _from,
            owner: tokenId2UseOffer[_tokenId].owner,
            startTime: uint48(now),
            endTime : uint48(now) + tokenId2UseOffer[_tokenId].duration,
            price : tokenId2UseOffer[_tokenId].price,
            acceptedActivity : tokenId2UseOffer[_tokenId].acceptedActivity
            });

        delete tokenId2UseOffer[_tokenId];

        emit OfferTaken(_tokenId, _from, tokenId2UseStatus[_tokenId].owner, now, uint256(tokenId2UseStatus[_tokenId].endTime));

    }

    // start activity when token has no user at all
    function addActivity(
        uint256 _tokenId, address _user, uint256 _endTime
    ) public auth {
        // require the token user to verify even if it is from business logic.
        // if it is rent by others, can not addActivity by default.
        if(tokenId2UseStatus[_tokenId].user != address(0)) {
            require(_user == tokenId2UseStatus[_tokenId].user);
            require(
                tokenId2UseStatus[_tokenId].acceptedActivity == address(0) ||
                tokenId2UseStatus[_tokenId].acceptedActivity == msg.sender, "Token accepted activity is not accepted.");
        } else {
            require(
                address(0) == _user || ERC721(registry.addressOf(CONTRACT_OBJECT_OWNERSHIP)).ownerOf(_tokenId) == _user, "you can not use this token.");
        }

        require(tokenId2UseOffer[_tokenId].owner == address(0), "Can not start activity when offering.");

        require(IActivity(msg.sender).supportsInterface(0x6086e7f8), "Msg sender must be activity");

        require(isObjectReadyToUse(_tokenId), "Token should be available.");

        address activityObject = IInterstellarEncoder(registry.addressOf(CONTRACT_INTERSTELLAR_ENCODER)).getObjectAddress(_tokenId);
        IActivityObject(activityObject).activityAdded(_tokenId, msg.sender, _user);

        tokenId2CurrentActivity[_tokenId].activity = msg.sender;

        if(tokenId2UseStatus[_tokenId].endTime != 0) {
            tokenId2CurrentActivity[_tokenId].endTime = tokenId2UseStatus[_tokenId].endTime;
        } else {
            tokenId2CurrentActivity[_tokenId].endTime = uint48(_endTime);
        }


        emit ActivityAdded(_tokenId, msg.sender, uint48(tokenId2CurrentActivity[_tokenId].endTime));
    }

    function removeActivity(uint256 _tokenId, address _user) public auth {
                // require the token user to verify even if it is from business logic.
        // if it is rent by others, can not addActivity by default.
        if(tokenId2UseStatus[_tokenId].user != address(0)) {
            require(_user == tokenId2UseStatus[_tokenId].user);
        } else {
            require(
                address(0) == _user || ERC721(registry.addressOf(CONTRACT_OBJECT_OWNERSHIP)).ownerOf(_tokenId) == _user, "you can not use this token.");
        }
        
        require(tokenId2CurrentActivity[_tokenId].activity == msg.sender || msg.sender == address(this), "Must stop from current activity");

        address activityObject = IInterstellarEncoder(registry.addressOf(CONTRACT_INTERSTELLAR_ENCODER)).getObjectAddress(_tokenId);
        IActivityObject(activityObject).activityRemoved(_tokenId, msg.sender, _user);

        IActivity(tokenId2CurrentActivity[_tokenId].activity).activityStopped(_tokenId);

        delete tokenId2CurrentActivity[_tokenId];

        emit ActivityRemoved(_tokenId, msg.sender);
    }

    function removeTokenUseAndActivity(uint256 _tokenId) public {
        require(tokenId2UseStatus[_tokenId].user != address(0), "Object does not exist.");

        // when in activity, only user can stop
        if(isObjectInHireStage(_tokenId)) {
            require(tokenId2UseStatus[_tokenId].user == msg.sender);
        }

        _removeTokenUse(_tokenId);

        if (tokenId2CurrentActivity[_tokenId].activity != address(0)) {
            this.removeActivity(_tokenId, address(0));
        }
    }


    function _removeTokenUse(uint256 _tokenId) internal {

        address owner = tokenId2UseStatus[_tokenId].owner;
        address user = tokenId2UseStatus[_tokenId].user;
        address activity = tokenId2CurrentActivity[_tokenId].activity;
        ERC721(registry.addressOf(CONTRACT_OBJECT_OWNERSHIP)).transferFrom(
            address(this), owner,  _tokenId);

        delete tokenId2UseStatus[_tokenId];
//        delete tokenId2CurrentActivity[_tokenId];

        emit TokenUseRemoved(_tokenId, owner, user, activity);
    }

    // for user-friendly
    function removeUseAndCreateOffer(uint256 _tokenId, uint256 _duration, uint256 _price, address _acceptedActivity) public {

        require(msg.sender == tokenId2UseStatus[_tokenId].owner);
        removeTokenUseAndActivity(_tokenId);

        tokenId2UseOffer[_tokenId] = UseOffer({
            owner: msg.sender,
            duration: uint48(_duration),
            price : _price,
            acceptedActivity: _acceptedActivity
            });

        emit OfferCreated(_tokenId, _duration, _price, _acceptedActivity, msg.sender);
    }

    /// @notice This method can be used by the owner to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
    function claimTokens(address _token) public auth {
        if (_token == 0x0) {
            owner.transfer(address(this).balance);
            return;
        }
        IERC20 token = IERC20(_token);
        uint balance = token.balanceOf(address(this));
        token.transfer(owner, balance);

        emit ClaimedTokens(_token, owner, balance);
    }

}