pragma solidity ^0.4.24;

// File: contracts\utils\ItemUtils.sol

library ItemUtils {

    uint256 internal constant UID_SHIFT = 2 ** 0; // 32
    uint256 internal constant RARITY_SHIFT = 2 ** 32; // 4
    uint256 internal constant CLASS_SHIFT = 2 ** 36;  // 10
    uint256 internal constant TYPE_SHIFT = 2 ** 46;  // 10
    uint256 internal constant TIER_SHIFT = 2 ** 56; // 7
    uint256 internal constant NAME_SHIFT = 2 ** 63; // 7
    uint256 internal constant REGION_SHIFT = 2 ** 70; // 8
    uint256 internal constant BASE_SHIFT = 2 ** 78;

    function createItem(uint256 _class, uint256 _type, uint256 _rarity, uint256 _tier, uint256 _name, uint256 _region) internal pure returns (uint256 dna) {
        dna = setClass(dna, _class);
        dna = setType(dna, _type);
        dna = setRarity(dna, _rarity);
        dna = setTier(dna, _tier);
        dna = setName(dna, _name);
        dna = setRegion(dna, _region);
    }

    function setUID(uint256 _dna, uint32 _value) internal pure returns (uint256) {
        require(_value < RARITY_SHIFT / UID_SHIFT);
        return setValue(_dna, _value, UID_SHIFT);
    }

    function setRarity(uint256 _dna, uint256 _value) internal pure returns (uint256) {
        require(_value < CLASS_SHIFT / RARITY_SHIFT);
        return setValue(_dna, _value, RARITY_SHIFT);
    }

    function setClass(uint256 _dna, uint256 _value) internal pure returns (uint256) {
        require(_value < TYPE_SHIFT / CLASS_SHIFT);
        return setValue(_dna, _value, CLASS_SHIFT);
    }

    function setType(uint256 _dna, uint256 _value) internal pure returns (uint256) {
        require(_value < TIER_SHIFT / TYPE_SHIFT);
        return setValue(_dna, _value, TYPE_SHIFT);
    }

    function setTier(uint256 _dna, uint256 _value) internal pure returns (uint256) {
        require(_value < NAME_SHIFT / TIER_SHIFT);
        return setValue(_dna, _value, TIER_SHIFT);
    }

    function setName(uint256 _dna, uint256 _value) internal pure returns (uint256) {
        require(_value < REGION_SHIFT / NAME_SHIFT);
        return setValue(_dna, _value, NAME_SHIFT);
    }

    function setRegion(uint256 _dna, uint256 _value) internal pure returns (uint256) {
        require(_value < BASE_SHIFT / REGION_SHIFT);
        return setValue(_dna, _value, REGION_SHIFT);
    }

    function getUID(uint256 _dna) internal pure returns (uint256) {
        return (_dna % RARITY_SHIFT) / UID_SHIFT;
    }

    function getRarity(uint256 _dna) internal pure returns (uint256) {
        return (_dna % CLASS_SHIFT) / RARITY_SHIFT;
    }

    function getClass(uint256 _dna) internal pure returns (uint256) {
        return (_dna % TYPE_SHIFT) / CLASS_SHIFT;
    }

    function getType(uint256 _dna) internal pure returns (uint256) {
        return (_dna % TIER_SHIFT) / TYPE_SHIFT;
    }

    function getTier(uint256 _dna) internal pure returns (uint256) {
        return (_dna % NAME_SHIFT) / TIER_SHIFT;
    }

    function getName(uint256 _dna) internal pure returns (uint256) {
        return (_dna % REGION_SHIFT) / NAME_SHIFT;
    }

    function getRegion(uint256 _dna) internal pure returns (uint256) {
        return (_dna % BASE_SHIFT) / REGION_SHIFT;
    }

    function setValue(uint256 dna, uint256 value, uint256 shift) internal pure returns (uint256) {
        return dna + (value * shift);
    }
}

// File: contracts\utils\StringUtils.sol

library StringUtils {

    function concat(string _base, string _value) internal pure returns (string) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        string memory _tmpValue = new string(_baseBytes.length + _valueBytes.length);
        bytes memory _newValue = bytes(_tmpValue);

        uint i;
        uint j;

        for (i = 0; i < _baseBytes.length; i++) {
            _newValue[j++] = _baseBytes[i];
        }

        for (i = 0; i < _valueBytes.length; i++) {
            _newValue[j++] = _valueBytes[i++];
        }

        return string(_newValue);
    }

    function uint2str(uint i) internal pure returns (string){
        if (i == 0) return "0";
        uint j = i;
        uint length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint k = length - 1;
        while (i != 0) {
            bstr[k--] = byte(48 + i % 10);
            i /= 10;
        }
        return string(bstr);
    }

}

// File: contracts\Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an emitter and administrator addresses, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address emitter;
    address administrator;

    /**
     * @dev Sets the original `emitter` of the contract
     */
    function setEmitter(address _emitter) internal {
        require(_emitter != address(0));
        require(emitter == address(0));
        emitter = _emitter;
    }

    /**
     * @dev Sets the original `administrator` of the contract
     */
    function setAdministrator(address _administrator) internal {
        require(_administrator != address(0));
        require(administrator == address(0));
        administrator = _administrator;
    }

    /**
     * @dev Throws if called by any account other than the emitter.
     */
    modifier onlyEmitter() {
        require(msg.sender == emitter);
        _;
    }

    /**
     * @dev Throws if called by any account other than the administrator.
     */
    modifier onlyAdministrator() {
        require(msg.sender == administrator);
        _;
    }

    /**
   * @dev Allows the current super emitter to transfer control of the contract to a emitter.
   * @param _emitter The address to transfer emitter ownership to.
   * @param _administrator The address to transfer administrator ownership to.
   */
    function transferOwnership(address _emitter, address _administrator) public onlyAdministrator {
        require(_emitter != _administrator);
        require(_emitter != emitter);
        require(_emitter != address(0));
        require(_administrator != address(0));
        emitter = _emitter;
        administrator = _administrator;
    }
}

// File: contracts\token\ERC20\ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: contracts\math\SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
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
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
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

// File: contracts\token\ERC20\BasicToken.sol

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

// File: contracts\token\ERC20\ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: contracts\token\ERC20\StandardToken.sol

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

// File: contracts\GameCoin.sol

contract GameCoin is StandardToken {
    string public constant name = "GameCoin";

    string public constant symbol = "GC";

    uint8 public constant decimals = 0;

    bool public isGameCoin = true;

    /**
   * @dev Constructor that gives msg.sender all of existing tokens.
   */
    constructor(address[] owners) public {
        for (uint256 i = 0; i < owners.length; i++) {
            _mint(owners[i], 2 * 10 ** 6);
        }
    }

    /**
     * @dev Internal function that mints an amount of the token and assigns it to
     * an account. This encapsulates the modification of balances such that the
     * proper events are emitted.
     * @param _account The account that will receive the created tokens.
     * @param _amount The amount that will be created.
     */
    function _mint(address _account, uint256 _amount) internal {
        require(_account != 0);
        totalSupply_ = totalSupply_.add(_amount);
        balances[_account] = balances[_account].add(_amount);
        emit Transfer(address(0), _account, _amount);
    }
}

// File: contracts\PresaleGacha.sol

contract PresaleGacha {

    uint32 internal constant CLASS_NONE = 0;
    uint32 internal constant CLASS_CHARACTER = 1;
    uint32 internal constant CLASS_CHEST = 2;
    uint32 internal constant CLASS_MELEE = 3;
    uint32 internal constant CLASS_RANGED = 4;
    uint32 internal constant CLASS_HELMET = 5;
    uint32 internal constant CLASS_LEGS = 6;
    uint32 internal constant CLASS_GLOVES = 7;
    uint32 internal constant CLASS_BOOTS = 8;
    uint32 internal constant CLASS_NECKLACE = 9;
    uint32 internal constant CLASS_MODS = 10;
    uint32 internal constant CLASS_TROPHY = 11;
    uint32 internal constant CLASS_ARMOR = 12;

    uint32 internal constant TYPE_CHEST_NONE = 0;
    uint32 internal constant TYPE_CHEST_GLADIATOR = 1;
    uint32 internal constant TYPE_CHEST_WARRIOR = 2;
    uint32 internal constant TYPE_CHEST_WARLORD = 3;
    uint32 internal constant TYPE_CHEST_APPRENTICE = 4;
    uint32 internal constant TYPE_CHEST_TOKEN_PACK = 6;
    uint32 internal constant TYPE_CHEST_INVESTOR_PACK = 7;

    uint32 internal constant TYPE_RANGED_PRESALE_RIFLE = 1;
    uint32 internal constant TYPE_ARMOR_PRESALE_ARMOR = 1;
    uint32 internal constant TYPE_LEGS_PRESALE_LEGS = 1;
    uint32 internal constant TYPE_BOOTS_PRESALE_BOOTS = 1;
    uint32 internal constant TYPE_GLOVES_PRESALE_GLOVES = 1;
    uint32 internal constant TYPE_HELMET_PRESALE_HELMET = 1;
    uint32 internal constant TYPE_NECKLACE_PRESALE_NECKLACE = 1;
    uint32 internal constant TYPE_MODES_PRESALE_MODES = 1;

    uint32 internal constant NAME_NONE = 0;
    uint32 internal constant NAME_COSMIC = 1;
    uint32 internal constant NAME_FUSION = 2;
    uint32 internal constant NAME_CRIMSON= 3;
    uint32 internal constant NAME_SHINING = 4;
    uint32 internal constant NAME_ANCIENT = 5;

    uint32 internal constant RARITY_NONE = 0;
    uint32 internal constant RARITY_COMMON = 1;
    uint32 internal constant RARITY_RARE = 2;
    uint32 internal constant RARITY_EPIC = 3;
    uint32 internal constant RARITY_LEGENDARY = 4;
    uint32 internal constant RARITY_UNIQUE = 5;

    struct ChestItem {
        uint32 _class;
        uint32 _type;
        uint32 _rarity;
        uint32 _tier;
        uint32 _name;
    }

    mapping(uint256 => ChestItem) chestItems;

    mapping(uint32 => uint32) apprenticeChestProbability;
    mapping(uint32 => uint32) warriorChestProbability;
    mapping(uint32 => uint32) gladiatorChestProbability;
    mapping(uint32 => uint32) warlordChestProbability;

    constructor () public {
        chestItems[0] = ChestItem(CLASS_RANGED, TYPE_RANGED_PRESALE_RIFLE, RARITY_NONE, 0,NAME_NONE);
        chestItems[1] = ChestItem(CLASS_ARMOR, TYPE_ARMOR_PRESALE_ARMOR, RARITY_NONE, 0, NAME_NONE);
        chestItems[2] = ChestItem(CLASS_LEGS, TYPE_LEGS_PRESALE_LEGS, RARITY_NONE, 0, NAME_NONE);
        chestItems[3] = ChestItem(CLASS_BOOTS, TYPE_BOOTS_PRESALE_BOOTS, RARITY_NONE, 0, NAME_NONE);
        chestItems[4] = ChestItem(CLASS_GLOVES, TYPE_GLOVES_PRESALE_GLOVES, RARITY_NONE, 0, NAME_NONE);
        chestItems[5] = ChestItem(CLASS_HELMET, TYPE_HELMET_PRESALE_HELMET, RARITY_NONE, 0, NAME_NONE);
        chestItems[6] = ChestItem(CLASS_NECKLACE, TYPE_NECKLACE_PRESALE_NECKLACE, RARITY_NONE, 0, NAME_NONE);
        chestItems[7] = ChestItem(CLASS_MODS, TYPE_MODES_PRESALE_MODES, RARITY_NONE, 0, NAME_NONE);

        apprenticeChestProbability[0] = 30;
        apprenticeChestProbability[1] = 40;
        apprenticeChestProbability[2] = 10;
        apprenticeChestProbability[3] = 10;
        apprenticeChestProbability[4] = 6;
        apprenticeChestProbability[5] = 4;

        warriorChestProbability[0] = 30;
        warriorChestProbability[1] = 30;
        warriorChestProbability[2] = 16;
        warriorChestProbability[3] = 15;
        warriorChestProbability[4] = 5;
        warriorChestProbability[5] = 4;

        gladiatorChestProbability[0] = 18;
        gladiatorChestProbability[1] = 15;
        gladiatorChestProbability[2] = 28;
        gladiatorChestProbability[3] = 20;
        gladiatorChestProbability[4] = 12;
        gladiatorChestProbability[5] = 7;

        warlordChestProbability[0] = 10;
        warlordChestProbability[1] = 10;
        warlordChestProbability[2] = 20;
        warlordChestProbability[3] = 20;
        warlordChestProbability[4] = 20;
        warlordChestProbability[5] = 20;
    }

    function getTier(uint32 _type, uint256 _id) internal pure returns (uint32){
        if (_type == TYPE_CHEST_APPRENTICE) {
            return (_id == 0 || _id == 3) ? 3 : (_id == 1 || _id == 4) ? 4 : 5;
        } else if (_type == TYPE_CHEST_WARRIOR) {
            return (_id == 0 || _id == 3 || _id == 5) ? 4 : (_id == 1 || _id == 4) ? 5 : 3;
        } else if (_type == TYPE_CHEST_GLADIATOR) {
            return (_id == 0 || _id == 3 || _id == 5) ? 5 : (_id == 2 || _id == 4) ? 5 : 3;
        } else if (_type == TYPE_CHEST_WARLORD) {
            return (_id == 1 || _id == 4) ? 4 : 5;
        } else {
            require(false);
        }
    }

    function getRarity(uint32 _type, uint256 _id) internal pure returns (uint32) {
        if (_type == TYPE_CHEST_APPRENTICE) {
            return _id < 3 ? RARITY_RARE : RARITY_EPIC;
        } else if (_type == TYPE_CHEST_WARRIOR) {
            return _id < 2 ? RARITY_RARE : (_id > 1 && _id < 5) ? RARITY_EPIC : RARITY_LEGENDARY;
        } else if (_type == TYPE_CHEST_GLADIATOR) {
            return _id == 0 ? RARITY_RARE : (_id > 0 && _id < 4) ? RARITY_EPIC : RARITY_LEGENDARY;
        } else if (_type == TYPE_CHEST_WARLORD) {
            return (_id == 0 || _id == 3) ? RARITY_EPIC : RARITY_LEGENDARY;
        } else {
            require(false);
        }
    }

    function isApprenticeChest(uint256 _identifier) internal pure returns (bool) {
        return ItemUtils.getType(_identifier) == TYPE_CHEST_APPRENTICE;
    }

    function isWarriorChest(uint256 _identifier) internal pure returns (bool) {
        return ItemUtils.getType(_identifier) == TYPE_CHEST_WARRIOR;
    }

    function isGladiatorChest(uint256 _identifier) internal pure returns (bool) {
        return ItemUtils.getType(_identifier) == TYPE_CHEST_GLADIATOR;
    }

    function isWarlordChest(uint256 _identifier) internal pure returns (bool) {
        return ItemUtils.getType(_identifier) == TYPE_CHEST_WARLORD;
    }

    function getApprenticeDistributedRandom(uint256 rnd) internal view returns (uint256) {
        uint256 tempDist = 0;
        for (uint8 i = 0; i < 6; i++) {
            tempDist += apprenticeChestProbability[i];
            if (rnd <= tempDist) {
                return i;
            }
        }
        return 0;
    }

    function getWarriorDistributedRandom(uint256 rnd) internal view returns (uint256) {
        uint256 tempDist = 0;
        for (uint8 i = 0; i < 6; i++) {
            tempDist += warriorChestProbability[i];
            if (rnd <= tempDist) {
                return i;
            }
        }
        return 0;
    }

    function getGladiatorDistributedRandom(uint256 rnd) internal view returns (uint256) {
        uint256 tempDist = 0;
        for (uint8 i = 0; i < 6; i++) {
            tempDist += gladiatorChestProbability[i];
            if (rnd <= tempDist) {
                return i;
            }
        }
        return 0;
    }

    function getWarlordDistributedRandom(uint256 rnd) internal view returns (uint256) {
        uint256 tempDist = 0;
        for (uint8 i = 0; i < 6; i++) {
            tempDist += warlordChestProbability[i];
            if (rnd <= tempDist) {
                return i;
            }
        }
        return 0;
    }
}

// File: contracts\introspection\ERC165.sol

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

// File: contracts\token\ERC721\ERC721Basic.sol

/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Basic is ERC165 {

  bytes4 internal constant InterfaceId_ERC721 = 0x80ac58cd;
  /*
   * 0x80ac58cd ===
   *   bytes4(keccak256(&#39;balanceOf(address)&#39;)) ^
   *   bytes4(keccak256(&#39;ownerOf(uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;approve(address,uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;getApproved(uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;setApprovalForAll(address,bool)&#39;)) ^
   *   bytes4(keccak256(&#39;isApprovedForAll(address,address)&#39;)) ^
   *   bytes4(keccak256(&#39;transferFrom(address,address,uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;safeTransferFrom(address,address,uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;safeTransferFrom(address,address,uint256,bytes)&#39;))
   */

  bytes4 internal constant InterfaceId_ERC721Exists = 0x4f558e79;
  /*
   * 0x4f558e79 ===
   *   bytes4(keccak256(&#39;exists(uint256)&#39;))
   */

  bytes4 internal constant InterfaceId_ERC721Enumerable = 0x780e9d63;
  /**
   * 0x780e9d63 ===
   *   bytes4(keccak256(&#39;totalSupply()&#39;)) ^
   *   bytes4(keccak256(&#39;tokenOfOwnerByIndex(address,uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;tokenByIndex(uint256)&#39;))
   */

  bytes4 internal constant InterfaceId_ERC721Metadata = 0x5b5e139f;
  /**
   * 0x5b5e139f ===
   *   bytes4(keccak256(&#39;name()&#39;)) ^
   *   bytes4(keccak256(&#39;symbol()&#39;)) ^
   *   bytes4(keccak256(&#39;tokenURI(uint256)&#39;))
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

// File: contracts\token\ERC721\ERC721.sol

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

// File: contracts\token\ERC721\ERC721Receiver.sol

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
contract ERC721Receiver {
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

// File: contracts\introspection\SupportsInterfaceWithLookup.sol

/**
 * @title SupportsInterfaceWithLookup
 * @author Matt Condon (@shrugs)
 * @dev Implements ERC165 using a lookup table.
 */
contract SupportsInterfaceWithLookup is ERC165 {

  bytes4 public constant InterfaceId_ERC165 = 0x01ffc9a7;
  /**
   * 0x01ffc9a7 ===
   *   bytes4(keccak256(&#39;supportsInterface(bytes4)&#39;))
   */

  /**
   * @dev a mapping of interface id to whether or not it&#39;s supported
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

// File: contracts\utils\AddressUtils.sol

/**
 * Utility library of inline functions on addresses
 */
library AddressUtils {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   * as the code is not actually created until after the constructor finishes.
   * @param _addr address to check
   * @return whether the target address is a contract
   */
  function isContract(address _addr) internal view returns (bool) {
    uint256 size;
    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    // solium-disable-next-line security/no-inline-assembly
    assembly { size := extcodesize(_addr) }
    return size > 0;
  }

}

// File: contracts\token\ERC721\ERC721BasicToken.sol

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721BasicToken is SupportsInterfaceWithLookup, ERC721Basic {

  using SafeMath for uint256;
  using AddressUtils for address;

  // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
  // which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
  bytes4 private constant ERC721_RECEIVED = 0x150b7a02;

  // Mapping from token ID to owner
  mapping (uint256 => address) internal tokenOwner;

  // Mapping from token ID to approved address
  mapping (uint256 => address) internal tokenApprovals;

  // Mapping from owner to number of owned token
  mapping (address => uint256) internal ownedTokensCount;

  // Mapping from owner to operator approvals
  mapping (address => mapping (address => bool)) internal operatorApprovals;

  constructor()
    public
  {
    // register the supported interfaces to conform to ERC721 via ERC165
    _registerInterface(InterfaceId_ERC721);
    _registerInterface(InterfaceId_ERC721Exists);
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
   * @param _tokenId uint256 ID of the token to query the existence of
   * @return whether the token exists
   */
  function exists(uint256 _tokenId) public view returns (bool) {
    address owner = tokenOwner[_tokenId];
    return owner != address(0);
  }

  /**
   * @dev Approves another address to transfer the given token ID
   * The zero address indicates there is no approved address.
   * There can only be one approved address per token at a given time.
   * Can only be called by the token owner or an approved operator.
   * @param _to address to be approved for the given token ID
   * @param _tokenId uint256 ID of the token to be approved
   */
  function approve(address _to, uint256 _tokenId) public {
    address owner = ownerOf(_tokenId);
    require(_to != owner);
    require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

    tokenApprovals[_tokenId] = _to;
    emit Approval(owner, _to, _tokenId);
  }

  /**
   * @dev Gets the approved address for a token ID, or zero if no address set
   * @param _tokenId uint256 ID of the token to query the approval of
   * @return address currently approved for the given token ID
   */
  function getApproved(uint256 _tokenId) public view returns (address) {
    return tokenApprovals[_tokenId];
  }

  /**
   * @dev Sets or unsets the approval of a given operator
   * An operator is allowed to transfer all tokens of the sender on their behalf
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
  function isApprovedForAll(
    address _owner,
    address _operator
  )
    public
    view
    returns (bool)
  {
    return operatorApprovals[_owner][_operator];
  }

  /**
   * @dev Transfers the ownership of a given token ID to another address
   * Usage of this method is discouraged, use `safeTransferFrom` whenever possible
   * Requires the msg sender to be the owner, approved, or operator
   * @param _from current owner of the token
   * @param _to address to receive the ownership of the given token ID
   * @param _tokenId uint256 ID of the token to be transferred
  */
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
  {
    require(isApprovedOrOwner(msg.sender, _tokenId));
    require(_from != address(0));
    require(_to != address(0));

    clearApproval(_from, _tokenId);
    removeTokenFrom(_from, _tokenId);
    addTokenTo(_to, _tokenId);

    emit Transfer(_from, _to, _tokenId);
  }

  /**
   * @dev Safely transfers the ownership of a given token ID to another address
   * If the target address is a contract, it must implement `onERC721Received`,
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   *
   * Requires the msg sender to be the owner, approved, or operator
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
  {
    // solium-disable-next-line arg-overflow
    safeTransferFrom(_from, _to, _tokenId, "");
  }

  /**
   * @dev Safely transfers the ownership of a given token ID to another address
   * If the target address is a contract, it must implement `onERC721Received`,
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   * Requires the msg sender to be the owner, approved, or operator
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
  function isApprovedOrOwner(
    address _spender,
    uint256 _tokenId
  )
    internal
    view
    returns (bool)
  {
    address owner = ownerOf(_tokenId);
    // Disable solium check because of
    // https://github.com/duaraghav8/Solium/issues/175
    // solium-disable-next-line operator-whitespace
    return (
      _spender == owner ||
      getApproved(_tokenId) == _spender ||
      isApprovedForAll(owner, _spender)
    );
  }

  /**
   * @dev Internal function to mint a new token
   * Reverts if the given token ID already exists
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
   * Reverts if the token does not exist
   * @param _tokenId uint256 ID of the token being burned by the msg.sender
   */
  function _burn(address _owner, uint256 _tokenId) internal {
    clearApproval(_owner, _tokenId);
    removeTokenFrom(_owner, _tokenId);
    emit Transfer(_owner, address(0), _tokenId);
  }

  /**
   * @dev Internal function to clear current approval of a given token ID
   * Reverts if the given address is not indeed the owner of the token
   * @param _owner owner of the token
   * @param _tokenId uint256 ID of the token to be transferred
   */
  function clearApproval(address _owner, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _owner);
    if (tokenApprovals[_tokenId] != address(0)) {
      tokenApprovals[_tokenId] = address(0);
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
   * The call is not executed if the target address is not a contract
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
    bytes4 retval = ERC721Receiver(_to).onERC721Received(
      msg.sender, _from, _tokenId, _data);
    return (retval == ERC721_RECEIVED);
  }
}

// File: contracts\token\ERC721\ERC721Token.sol

/**
 * @title Full ERC721 Token
 * This implementation includes all the required and some optional functionality of the ERC721 standard
 * Moreover, it includes approve all functionality using operator terminology
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Token is SupportsInterfaceWithLookup, ERC721BasicToken, ERC721 {

  // Token name
  string internal name_;

  // Token symbol
  string internal symbol_;

  // Mapping from owner to list of owned token IDs
  mapping(address => uint256[]) internal ownedTokens;

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
  constructor(string _name, string _symbol) public {
    name_ = _name;
    symbol_ = _symbol;

    // register the supported interfaces to conform to ERC721 via ERC165
    _registerInterface(InterfaceId_ERC721Enumerable);
    _registerInterface(InterfaceId_ERC721Metadata);
  }

  /**
   * @dev Gets the token name
   * @return string representing the token name
   */
  function name() external view returns (string) {
    return name_;
  }

  /**
   * @dev Gets the token symbol
   * @return string representing the token symbol
   */
  function symbol() external view returns (string) {
    return symbol_;
  }

  /**
   * @dev Returns an URI for a given token ID
   * Throws if the token ID does not exist. May return an empty string.
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
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    public
    view
    returns (uint256)
  {
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
   * Reverts if the index is greater or equal to the total number of tokens
   * @param _index uint256 representing the index to be accessed of the tokens list
   * @return uint256 token ID at the given index of the tokens list
   */
  function tokenByIndex(uint256 _index) public view returns (uint256) {
    require(_index < totalSupply());
    return allTokens[_index];
  }

  /**
   * @dev Internal function to set the token URI for a given token
   * Reverts if the token ID does not exist
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

    // To prevent a gap in the array, we store the last token in the index of the token to delete, and
    // then delete the last slot.
    uint256 tokenIndex = ownedTokensIndex[_tokenId];
    uint256 lastTokenIndex = ownedTokens[_from].length.sub(1);
    uint256 lastToken = ownedTokens[_from][lastTokenIndex];

    ownedTokens[_from][tokenIndex] = lastToken;
    // This also deletes the contents at the last position of the array
    ownedTokens[_from].length--;

    // Note that this will handle single-element arrays. In that case, both tokenIndex and lastTokenIndex are going to
    // be zero. Then we can make sure that we will remove _tokenId from the ownedTokens list since we are first swapping
    // the lastToken to the first position, and then dropping the element placed in the last position of the list

    ownedTokensIndex[_tokenId] = 0;
    ownedTokensIndex[lastToken] = tokenIndex;
  }

  /**
   * @dev Internal function to mint a new token
   * Reverts if the given token ID already exists
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
   * Reverts if the token does not exist
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

// File: contracts\GlitchGoonsItem.sol

contract GlitchGoonsItem is PresaleGacha, ERC721Token, Ownable {
    string public constant name = "GlitchGoons";

    string public constant symbol = "GG";

    uint32 id;

    struct PresalePack {
        uint32 available;
        uint32 gameCoin;
        uint256 price;
    }

    PresalePack tokenPack;
    PresalePack investorPack;
    PresalePack apprenticeChest;
    PresalePack warriorChest;
    PresalePack gladiatorChest;
    PresalePack warlordChest;

    uint256 private closingTime;
    uint256 private openingTime;

    GameCoin gameCoinContract;

    constructor (address _emitter, address _administrator, address _gameCoin, uint256 _openingTime, uint256 _closingTime)
    ERC721Token(name, symbol)
    public {
        setEmitter(_emitter);
        setAdministrator(_administrator);

        GameCoin gameCoinCandidate = GameCoin(_gameCoin);
        require(gameCoinCandidate.isGameCoin());
        gameCoinContract = gameCoinCandidate;

        investorPack = PresalePack(1, 10 ** 6, 500 ether);
        tokenPack = PresalePack(50, 4000, 10 ether);

        apprenticeChest = PresalePack(550, 207, .5 ether);
        warriorChest = PresalePack(200, 717, 1.75 ether);
        gladiatorChest = PresalePack(80, 1405, 3.5 ether);
        warlordChest = PresalePack(35, 3890, 10 ether);

        closingTime = _closingTime;
        openingTime = _openingTime;
    }

    function addItemToInternal(address _to, uint256 _class, uint256 _type, uint256 _rarity, uint256 _tier, uint256 _name, uint256 _region) internal {
        uint256 identity = ItemUtils.createItem(_class, _type, _rarity, _tier, _name, _region);
        identity = ItemUtils.setUID(identity, id++);
        _mint(_to, identity);
        _setTokenURI(identity, string(abi.encodePacked("https://static.glitch-goons.com/metadata/gg/", StringUtils.uint2str(id), ".json")));
    }

    function addItemTo(address _to, uint256 _class, uint256 _type, uint256 _rarity, uint256 _tier, uint256 _name, uint256 _region) public onlyEmitter {
        addItemToInternal(_to, _class, _type, _rarity, _tier, _name, _region);
    }

    function buyTokenPack(uint256 _region) public onlyWhileOpen canBuyPack(tokenPack) payable {
        addItemToInternal(msg.sender, CLASS_CHEST, TYPE_CHEST_TOKEN_PACK, RARITY_NONE, 0, NAME_NONE, _region);
        tokenPack.available--;
        administrator.transfer(msg.value);
    }

    function buyInvestorPack(uint256 _region) public onlyWhileOpen canBuyPack(investorPack) payable {
        addItemToInternal(msg.sender, CLASS_CHEST, TYPE_CHEST_INVESTOR_PACK, RARITY_NONE, 0, NAME_NONE, _region);
        investorPack.available--;
        administrator.transfer(msg.value);
    }

    function buyApprenticeChest(uint256 _region) public onlyWhileOpen canBuyPack(apprenticeChest) payable {
        addItemToInternal(msg.sender, CLASS_CHEST, TYPE_CHEST_APPRENTICE, RARITY_COMMON, 3, NAME_NONE, _region);
        apprenticeChest.available--;
        administrator.transfer(msg.value);
    }

    function buyWarriorChest(uint256 _region) public onlyWhileOpen canBuyPack(warriorChest) payable {
        addItemToInternal(msg.sender, CLASS_CHEST, TYPE_CHEST_WARRIOR, RARITY_RARE, 3, NAME_NONE, _region);
        warriorChest.available--;
        administrator.transfer(msg.value);
    }

    function buyGladiatorChest(uint256 _region) public onlyWhileOpen canBuyPack(gladiatorChest) payable {
        addItemToInternal(msg.sender, CLASS_CHEST, TYPE_CHEST_GLADIATOR, RARITY_EPIC, 4, NAME_NONE, _region);
        gladiatorChest.available--;
        administrator.transfer(msg.value);
    }

    function buyWarlordChest(uint256 _region) public onlyWhileOpen canBuyPack(warlordChest) payable {
        addItemToInternal(msg.sender, CLASS_CHEST, TYPE_CHEST_WARLORD, RARITY_LEGENDARY, 5, NAME_NONE, _region);
        warlordChest.available--;
        administrator.transfer(msg.value);
    }

    function openChest(uint256 _identifier) public onlyChestOwner(_identifier) {
        uint256 _type = ItemUtils.getType(_identifier);

        if (_type == TYPE_CHEST_TOKEN_PACK) {
            transferTokens(tokenPack);
        } else if (_type == TYPE_CHEST_INVESTOR_PACK) {
            transferTokens(investorPack);
        } else {
            uint256 blockNum = block.number;

            for (uint i = 0; i < 5; i++) {
                uint256 hash = uint256(keccak256(abi.encodePacked(_identifier, blockNum, i, block.coinbase, block.timestamp, block.difficulty)));
                blockNum--;
                uint256 rnd = hash % 100;
                uint32 _tier;
                uint32 _rarity = RARITY_EPIC;
                uint256 _id;

                if (isApprenticeChest(_identifier)) {
                    _id = getApprenticeDistributedRandom(rnd);
                    _rarity = getRarity(TYPE_CHEST_APPRENTICE, _id);
                    _tier = getTier(TYPE_CHEST_APPRENTICE, _id);
                } else if (isWarriorChest(_identifier)) {
                    _id = getWarriorDistributedRandom(rnd);
                    _rarity = getRarity(TYPE_CHEST_WARRIOR, _id);
                    _tier = getTier(TYPE_CHEST_WARRIOR, _id);
                } else if (isGladiatorChest(_identifier)) {
                    _id = getGladiatorDistributedRandom(rnd);
                    _rarity = getRarity(TYPE_CHEST_GLADIATOR, _id);
                    _tier = getTier(TYPE_CHEST_GLADIATOR, _id);
                } else if (isWarlordChest(_identifier)) {
                    _id = getWarlordDistributedRandom(rnd);
                    _rarity = getRarity(TYPE_CHEST_WARLORD, _id);
                    _tier = getTier(TYPE_CHEST_WARLORD, _id);
                } else {
                    require(false);
                }
                ChestItem memory chestItem = chestItems[hash / 2 % 8];
                uint256 _region = ItemUtils.getRegion(_identifier);
                uint256 _name = 1 + hash / 3 % 5;
                if (i == hash / 4 % 5) {
                    if (isWarriorChest(_identifier)) {
                        addItemToInternal(msg.sender, chestItem._class, chestItem._type, RARITY_RARE, 3, _name, _region);
                    } else if (isGladiatorChest(_identifier)) {
                        addItemToInternal(msg.sender, chestItem._class, chestItem._type, RARITY_RARE, 5, _name, _region);
                    } else if (isWarlordChest(_identifier)) {
                        addItemToInternal(msg.sender, chestItem._class, chestItem._type, RARITY_LEGENDARY, 5, _name, _region);
                    } else {
                        addItemToInternal(msg.sender, chestItem._class, chestItem._type, _rarity, _tier, _name, _region);
                    }
                } else {
                    addItemToInternal(msg.sender, chestItem._class, chestItem._type, _rarity, _tier, _name, _region);
                }
            }
        }

        _burn(msg.sender, _identifier);
    }

    function getTokenPacksAvailable() view public returns (uint256) {
        return tokenPack.available;
    }

    function getTokenPackPrice() view public returns (uint256) {
        return tokenPack.price;
    }

    function getInvestorPacksAvailable() view public returns (uint256) {
        return investorPack.available;
    }

    function getInvestorPackPrice() view public returns (uint256) {
        return investorPack.price;
    }

    function getApprenticeChestAvailable() view public returns (uint256) {
        return apprenticeChest.available;
    }

    function getApprenticeChestPrice() view public returns (uint256) {
        return apprenticeChest.price;
    }

    function getWarriorChestAvailable() view public returns (uint256) {
        return warriorChest.available;
    }

    function getWarriorChestPrice() view public returns (uint256) {
        return warriorChest.price;
    }

    function getGladiatorChestAvailable() view public returns (uint256) {
        return gladiatorChest.available;
    }

    function getGladiatorChestPrice() view public returns (uint256) {
        return gladiatorChest.price;
    }

    function getWarlordChestAvailable() view public returns (uint256) {
        return warlordChest.available;
    }

    function getWarlordChestPrice() view public returns (uint256) {
        return warlordChest.price;
    }

    /**
    * @dev Reverts if not in presale time range.
    */
    modifier onlyWhileOpen {
        require(isOpen());
        _;
    }

    modifier canBuyPack(PresalePack pack) {
        require(msg.value == pack.price);
        require(pack.available > 0);
        _;
    }

    modifier onlyChestOwner(uint256 _identity) {
        require(ownerOf(_identity) == msg.sender);
        require(ItemUtils.getClass(_identity) == CLASS_CHEST);
        _;
    }

    /**
    * @return true if the presale is open, false otherwise.
    */
    function isOpen() public view returns (bool) {
        return block.timestamp >= openingTime && block.timestamp <= closingTime;
    }

    function getClosingTime() public view returns (uint256) {
        return closingTime;
    }

    function getOpeningTime() public view returns (uint256) {
        return openingTime;
    }

    function transferTokens(PresalePack pack) internal {
        require(gameCoinContract.balanceOf(address(this)) >= pack.gameCoin);
        gameCoinContract.transfer(msg.sender, pack.gameCoin);
    }
}