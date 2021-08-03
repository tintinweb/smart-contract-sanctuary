/**
 *Submitted for verification at polygonscan.com on 2021-08-03
*/

// Verified by Darwinia Network

// hevm: flattened sources of contracts/MysteriousTreasure.sol

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

////// contracts/interfaces/IMysteriousTreasure.sol
/* pragma solidity ^0.4.24; */

contract IMysteriousTreasure {

    function unbox(uint256 _tokenId) public returns (uint, uint, uint, uint, uint);

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

////// contracts/MysteriousTreasure.sol
/* pragma solidity ^0.4.23; */

/* import "openzeppelin-solidity/contracts/math/SafeMath.sol"; */
/* import "@evolutionland/common/contracts/interfaces/ISettingsRegistry.sol"; */
/* import "@evolutionland/common/contracts/DSAuth.sol"; */
/* import "@evolutionland/common/contracts/SettingIds.sol"; */
/* import "./interfaces/ILandBase.sol"; */
/* import "./interfaces/IMysteriousTreasure.sol"; */

contract MysteriousTreasure is DSAuth, SettingIds, IMysteriousTreasure {
    using SafeMath for *;
    
    bool private singletonLock = false;

    ISettingsRegistry public registry;

    // the key of resourcePool are 0,1,2,3,4
    // respectively refer to gold,wood,water,fire,soil
    mapping (uint256 => uint256) public resourcePool;

    // number of box left
    uint public totalBoxNotOpened;

    // event unbox
    event Unbox(uint indexed tokenId, uint goldRate, uint woodRate, uint waterRate, uint fireRate, uint soilRate);

    /*
  *  Modifiers
  */
    modifier singletonLockCall() {
        require(!singletonLock, "Only can call once");
        _;
        singletonLock = true;
    }

    // this need to be created in ClockAuction cotnract
    constructor() public {

      // initializeContract
    }

    function initializeContract(ISettingsRegistry _registry, uint256[5] _resources) public singletonLockCall {
        owner = msg.sender;

        registry = _registry;

        totalBoxNotOpened = 176;
        for(uint i = 0; i < 5; i++) {
            _setResourcePool(i, _resources[i]);
        }
    }

    //TODO: consider authority again
    // this is invoked in auction.claimLandAsset
    function unbox(uint256 _tokenId)
    public
    auth
    returns (uint, uint, uint, uint, uint) {
        ILandBase landBase = ILandBase(registry.addressOf(SettingIds.CONTRACT_LAND_BASE));
        if(! landBase.isHasBox(_tokenId) ) {
            return (0,0,0,0,0);
        }

        // after unboxing, set hasBox(tokenId) to false to restrict unboxing
        // set hasBox to false before unboxing operations for safety reason
        landBase.setHasBox(_tokenId, false);

        uint16[5] memory resourcesReward;
        (resourcesReward[0], resourcesReward[1],
        resourcesReward[2], resourcesReward[3], resourcesReward[4]) = _computeAndExtractRewardFromPool();

        address resouceToken = registry.addressOf(SettingIds.CONTRACT_GOLD_ERC20_TOKEN);
        landBase.setResourceRate(_tokenId, resouceToken, landBase.getResourceRate(_tokenId, resouceToken) + resourcesReward[0]);

        resouceToken = registry.addressOf(SettingIds.CONTRACT_WOOD_ERC20_TOKEN);
        landBase.setResourceRate(_tokenId, resouceToken, landBase.getResourceRate(_tokenId, resouceToken) + resourcesReward[1]);

        resouceToken = registry.addressOf(SettingIds.CONTRACT_WATER_ERC20_TOKEN);
        landBase.setResourceRate(_tokenId, resouceToken, landBase.getResourceRate(_tokenId, resouceToken) + resourcesReward[2]);

        resouceToken = registry.addressOf(SettingIds.CONTRACT_FIRE_ERC20_TOKEN);
        landBase.setResourceRate(_tokenId, resouceToken, landBase.getResourceRate(_tokenId, resouceToken) + resourcesReward[3]);

        resouceToken = registry.addressOf(SettingIds.CONTRACT_SOIL_ERC20_TOKEN);
        landBase.setResourceRate(_tokenId, resouceToken, landBase.getResourceRate(_tokenId, resouceToken) + resourcesReward[4]);

        // only record increment of resources
        emit Unbox(_tokenId, resourcesReward[0], resourcesReward[1], resourcesReward[2], resourcesReward[3], resourcesReward[4]);

        return (resourcesReward[0], resourcesReward[1], resourcesReward[2], resourcesReward[3], resourcesReward[4]);
    }

    // rewards ranges from [0, 2 * average_of_resourcePool_left]
    // if early players get high resourceReward, then the later ones will get lower.
    // in other words, if early players get low resourceReward, the later ones get higher.
    // think about snatching wechat's virtual red envelopes in groups.
    function _computeAndExtractRewardFromPool() internal returns(uint16,uint16,uint16,uint16,uint16) {
        if ( totalBoxNotOpened == 0 ) {
            return (0,0,0,0,0);
        }

        uint16[5] memory resourceRewards;

        // from fomo3d
        // msg.sender is always address(auction),
        // so change msg.sender to tx.origin
        uint256 seed = uint256(keccak256(abi.encodePacked(
                (block.timestamp).add
                (block.difficulty).add
                ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)).add
                (block.gaslimit).add
                ((uint256(keccak256(abi.encodePacked(tx.origin)))) / (now)).add
                (block.number)
            )));

        for(uint i = 0; i < 5; i++) {
            if (totalBoxNotOpened > 1) {
                // recources in resourcePool is set by owner
                // nad totalBoxNotOpened is set by rules
                // there is no need to consider overflow
                // goldReward, woodReward, waterReward, fireReward, soilReward
                // 2 ** 16 - 1
                uint doubleAverage = (2 * resourcePool[i] / totalBoxNotOpened);
                if (doubleAverage > 65535) {
                    doubleAverage = 65535;
                }
                
                uint resourceReward = seed % doubleAverage;

                resourceRewards[i] = uint16(resourceReward);
                
                // update resourcePool
                _setResourcePool(i, resourcePool[i] - resourceRewards[i]);
            }

            if(totalBoxNotOpened == 1) {
                resourceRewards[i] = uint16(resourcePool[i]);
                _setResourcePool(i, resourcePool[i] - uint256(resourceRewards[i]));
            }
        }

        totalBoxNotOpened--;

        return (resourceRewards[0],resourceRewards[1], resourceRewards[2], resourceRewards[3], resourceRewards[4]);

    }


    function _setResourcePool(uint _keyNumber, uint _resources) internal {
        require(_keyNumber >= 0 && _keyNumber < 5);
        resourcePool[_keyNumber] = _resources;
    }

    function setResourcePool(uint _keyNumber, uint _resources) public auth {
        _setResourcePool(_keyNumber, _resources);
    }

    function setTotalBoxNotOpened(uint _totalBox) public auth {
        totalBoxNotOpened = _totalBox;
    }

}