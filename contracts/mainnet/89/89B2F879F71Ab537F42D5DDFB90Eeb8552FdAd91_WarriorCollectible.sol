// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.5.17;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import 'multi-token-standard/contracts/tokens/ERC1155/ERC1155.sol';
import 'multi-token-standard/contracts/tokens/ERC1155/ERC1155Metadata.sol';
import 'multi-token-standard/contracts/tokens/ERC1155/ERC1155MintBurn.sol';
import "./Strings.sol";

contract OwnableDelegateProxy { }

contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title ERC1155Tradable
 * ERC1155Tradable - ERC1155 contract that whitelists an operator address, has create and mint functionality, and supports useful standards from OpenZeppelin,
  like _exists(), name(), symbol(), and totalSupply()
 */
contract ERC1155Tradable is ERC1155, ERC1155MintBurn, ERC1155Metadata, Ownable {
  using Strings for string;

  address proxyRegistryAddress;
  uint256 private _currentTokenID = 0;
  mapping (uint256 => address) public creators;
  mapping (uint256 => uint256) public tokenSupply;
  // Contract name
  string public name;
  // Contract symbol
  string public symbol;

  /**
   * @dev Require msg.sender to be the creator of the token id
   */
  modifier creatorOnly(uint256 _id) {
    require(creators[_id] == msg.sender, "ERC1155Tradable#creatorOnly: ONLY_CREATOR_ALLOWED");
    _;
  }

  /**
   * @dev Require msg.sender to own more than 0 of the token id
   */
  modifier ownersOnly(uint256 _id) {
    require(balances[msg.sender][_id] > 0, "ERC1155Tradable#ownersOnly: ONLY_OWNERS_ALLOWED");
    _;
  }

  constructor(
    string memory _name,
    string memory _symbol,
    address _proxyRegistryAddress
  ) public {
    name = _name;
    symbol = _symbol;
    proxyRegistryAddress = _proxyRegistryAddress;
  }

  function uri (
    uint256 _id
  ) public view returns (string memory) {
    require(_exists(_id), "ERC721Tradable#uri: NONEXISTENT_TOKEN");
    return Strings.strConcat(
      baseMetadataURI,
      Strings.uint2str(_id)
    );
  }

  /**
    * @dev Returns the total quantity for a token ID
    * @param _id uint256 ID of the token to query
    * @return amount of token in existence
    */
  function totalSupply(
    uint256 _id
  ) public view returns (uint256) {
    return tokenSupply[_id];
  }

  /**
   * @dev Will update the base URL of token's URI
   * @param _newBaseMetadataURI New base URL of token's URI
   */
  function setBaseMetadataURI(
    string memory _newBaseMetadataURI
  ) public onlyOwner {
    _setBaseMetadataURI(_newBaseMetadataURI);
  }

  /**
    * @dev Creates a new token type and assigns _initialSupply to an address
    * NOTE: remove onlyOwner if you want third parties to create new tokens on your contract (which may change your IDs)
    * @param _initialOwner address of the first owner of the token
    * @param _initialSupply amount to supply the first owner
    * @param _uri Optional URI for this token type
    * @param _data Data to pass if receiver is contract
    * @return The newly created token ID
    */
  function create(
    address _initialOwner,
    uint256 _initialSupply,
    string calldata _uri,
    bytes calldata _data
  ) external onlyOwner returns (uint256) {

    uint256 _id = _getNextTokenID();
    _incrementTokenTypeId();
    creators[_id] = msg.sender;

    if (bytes(_uri).length > 0) {
      emit URI(_uri, _id);
    }

    _mint(_initialOwner, _id, _initialSupply, _data);
    tokenSupply[_id] = _initialSupply;
    return _id;
  }

  /**
    * @dev Mints some amount of tokens to an address
    * @param _to          Address of the future owner of the token
    * @param _id          Token ID to mint
    * @param _quantity    Amount of tokens to mint
    * @param _data        Data to pass if receiver is contract
    */
  function mint(
    address _to,
    uint256 _id,
    uint256 _quantity,
    bytes memory _data
  ) public creatorOnly(_id) {
    _mint(_to, _id, _quantity, _data);
    tokenSupply[_id] = tokenSupply[_id].add(_quantity);
  }

  /**
    * @dev Mint tokens for each id in _ids
    * @param _to          The address to mint tokens to
    * @param _ids         Array of ids to mint
    * @param _quantities  Array of amounts of tokens to mint per id
    * @param _data        Data to pass if receiver is contract
    */
  function batchMint(
    address _to,
    uint256[] memory _ids,
    uint256[] memory _quantities,
    bytes memory _data
  ) public {
    for (uint256 i = 0; i < _ids.length; i++) {
      uint256 _id = _ids[i];
      require(creators[_id] == msg.sender, "ERC1155Tradable#batchMint: ONLY_CREATOR_ALLOWED");
      uint256 quantity = _quantities[i];
      tokenSupply[_id] = tokenSupply[_id].add(quantity);
    }
    _batchMint(_to, _ids, _quantities, _data);
  }

  /**
    * @dev Change the creator address for given tokens
    * @param _to   Address of the new creator
    * @param _ids  Array of Token IDs to change creator
    */
  function setCreator(
    address _to,
    uint256[] memory _ids
  ) public {
    require(_to != address(0), "ERC1155Tradable#setCreator: INVALID_ADDRESS.");
    for (uint256 i = 0; i < _ids.length; i++) {
      uint256 id = _ids[i];
      _setCreator(_to, id);
    }
  }

  /**
   * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-free listings.
   */
  function isApprovedForAll(
    address _owner,
    address _operator
  ) public view returns (bool isOperator) {
    // Whitelist OpenSea proxy contract for easy trading.
    ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    if (address(proxyRegistry.proxies(_owner)) == _operator) {
      return true;
    }

    return ERC1155.isApprovedForAll(_owner, _operator);
  }

  /**
    * @dev Change the creator address for given token
    * @param _to   Address of the new creator
    * @param _id  Token IDs to change creator of
    */
  function _setCreator(address _to, uint256 _id) internal creatorOnly(_id)
  {
      creators[_id] = _to;
  }

  /**
    * @dev Returns whether the specified token exists by checking to see if it has a creator
    * @param _id uint256 ID of the token to query the existence of
    * @return bool whether the token exists
    */
  function _exists(
    uint256 _id
  ) internal view returns (bool) {
    return creators[_id] != address(0);
  }

  /**
    * @dev calculates the next token ID based on value of _currentTokenID
    * @return uint256 for the next token ID
    */
  function _getNextTokenID() internal view returns (uint256) {
    return _currentTokenID.add(1);
  }

  /**
    * @dev increments the value of _currentTokenID
    */
  function _incrementTokenTypeId() internal  {
    _currentTokenID++;
  }
}

// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

library LibWarrior {
	
    //////////////////////////////////////////////////////////////////////////////////////////
    // Config
    //////////////////////////////////////////////////////////////////////////////////////////
    
    //Warrior Attribute Factors
    uint8 constant hpConFactor = 3;
    uint8 constant hpStrFactor = 1;
    uint16 constant startingStr = 5;
    uint16 constant startingDex = 5;
    uint16 constant startingCon = 5;
    uint16 constant startingLuck = 5;
    uint16 constant startingPoints = 500;

    //Warrior Advancement
    uint8 constant levelExponent = 4;
    uint8 constant levelOffset = 4;
    uint8 constant killLevelOffset = 4;
    uint8 constant levelPointsExponent = 2;
    uint8 constant pointsLevelOffset = 6;
    uint8 constant pointsLevelMultiplier = 2;
    uint8 constant practiceLevelOffset = 1;
    uint32 constant trainingTimeFactor = 1 minutes; 
    uint16 constant intPotionFactor = 10;
    
    //Costing Config (costs are in FAME tokens)
    uint constant warriorCost = 100;
    uint constant warriorReviveBaseCost = warriorCost/20;
    uint constant strCostExponent = 2;
    uint constant dexCostExponent = 2;
    uint constant conCostExponent = 2;
    uint constant luckCostExponent = 3;
    uint constant potionCost = 100;
    uint constant intPotionCost = 500;
    uint constant armorCost = 10;
    uint constant weaponCost = 10;
    uint constant shieldCost = 10;
    uint constant armorCostExponent = 3;
    uint constant shieldCostExponent = 3;
    uint constant weaponCostExponent = 3;
    uint constant armorCostOffset = 2;
    uint constant shieldCostOffset = 2;
    uint constant weaponCostOffset = 2;

    //Value Constraints
    uint8 constant maxPotions = 5;
    uint8 constant maxIntPotions = 10;
    uint16 constant maxWeapon = 10;
    uint16 constant maxArmor = 10;
    uint16 constant maxShield = 10;

    //Misc Config
    uint32 constant cashoutDelay = 24 hours;
    uint16 constant wearPercentage = 10;
    uint16 constant potionHealAmount = 100;

    //////////////////////////////////////////////////////////////////////////////////////////
    // Enums
    //////////////////////////////////////////////////////////////////////////////////////////

    enum warriorState { 
        Idle, 
        Busy, 
        Incapacitated, 
        Retired
    }

    enum ArmorType {
        Minimal,
        Light,
        Medium,
        Heavy
    }

    enum ShieldType {
        None,
        Light,
        Medium,
        Heavy
    }

    enum WeaponClass {
        Slashing,
        Cleaving,
        Bludgeoning,
        ExtRange
    }

    enum WeaponType {
        //Slashing
        Sword,              //0
        Falchion,           //1
        //Cleaving
        Broadsword,         //2
        Axe,                //3
        //Bludgeoning
        Mace,               //4
        Hammer,             //5
        Flail,              //6
        //Extended-Reach
        Trident,            //7
        Halberd,            //8
        Spear               //9
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Structs
    //////////////////////////////////////////////////////////////////////////////////////////

    struct warriorStats {
        uint64 baseHP;
        uint64 dmg; 
        uint64 xp;
        uint16 str;
        uint16 dex;
        uint16 con;
        uint16 luck;
        uint64 points;
        uint16 level;
    }

    struct warriorEquipment {
        uint8 potions;
        uint8 intPotions;
        ArmorType armorType;
        ShieldType shieldType;
        WeaponType weaponType;
        uint8 armorStrength;
        uint8 shieldStrength;
        uint8 weaponStrength;
        uint8 armorWear;
        uint8 shieldWear;
        uint8 weaponWear;
        bool helmet;
    }

    struct warrior {
        //Header
        address owner;
        bytes32 bytesName;
        uint balance;
        uint cosmeticSeed;
        uint16 colorHue;
        warriorState state;
        uint32 creationTime;
        //Stats
        warriorStats stats;
        //Equipment
        warriorEquipment equipment;
        uint32 trainingUntil;
        bool special;
        uint32 generation;
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Warrior Constructors
    //////////////////////////////////////////////////////////////////////////////////////////

    function newWarriorFixed(address owner, uint32 generation, bool special, uint randomSeed, uint16 colorHue, uint8 armorType, uint8 shieldType, uint8 weaponType) internal view returns (warrior memory theWarrior) {
        theWarrior = warrior(
			owner,                                              //owner
            bytes32(0),	                                        //bytesName Empty to start
			0,						                            //balance
            random(randomSeed,1),                               //cosmeticSeed
            colorHue,                                           //colorHue
			warriorState.Idle,		                            //state
			uint32(block.timestamp),                            //creationTime
            warriorStats(
                uint64(calcBaseHP(0,startingCon,startingStr)),  //BaseHP
    			0,						                        //dmg
                0,						                        //xp
                startingStr,			                        //str
                startingDex,			                        //dex
                startingCon,			                        //con
                startingLuck,			                        //luck
                startingPoints,			                        //points
                0						                        //level
            ),
            warriorEquipment(
                0,						                        //potions
                0,						                        //intPotions
                ArmorType(armorType),                           //armorType
                ShieldType(shieldType),                         //shieldType
                WeaponType(weaponType),                         //weaponType
                0,                                              //armorStrength
                0,                                              //shieldStrength
                0,                                              //weaponStrength
                0,                                              //armorWear
                0,                                              //shieldWear
                0,                                              //weaponWear
                false                                           //helmet
            ),
			0,      				                            //trainingUntil
			special,				                            //special flag
			generation				                            //generation
        );
    }

    function newWarrior(address owner, uint randomSeed) internal view returns (warrior memory theWarrior) {
        uint8 armorTypeCount = uint8(ArmorType.Heavy)+1; //Count enum states allowed by last item
        uint8 shieldTypeCount = uint8(ShieldType.Heavy)+1; //Count enum states allowed by last item
        uint8 weaponTypeCount = uint8(WeaponType.Spear)+1; //Count enum states allowed by last item

        //Randomly Generate main attributes/cosmetics:
        uint16 colorHue = uint16(random(randomSeed,0));
        uint8 armorType = uint8(random(randomSeed,1)%armorTypeCount);
        uint8 shieldType = uint8(random(randomSeed,2)%shieldTypeCount);
        uint8 weaponType = uint8(random(randomSeed,3)%weaponTypeCount);
        //Then construct:
        theWarrior = newWarriorFixed(owner, 0, false, randomSeed, colorHue, armorType, shieldType, weaponType);
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Utilities
    //////////////////////////////////////////////////////////////////////////////////////////

    function random(uint seeda, uint seedb) internal pure returns (uint) {
        return uint(keccak256(abi.encodePacked(seeda,seedb)));  
    }

	function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    function bytes32ToString(bytes32 source) internal pure returns (string memory result) {
        uint8 len = 32;
        for(uint8 i;i<32;i++){
            if(source[i]==0){
                len = i;
                break;
            }
        }
        bytes memory bytesArray = new bytes(len);
        for (uint8 i=0;i<len;i++) {
            bytesArray[i] = source[i];
        }
        result = string(bytesArray);
    }

    function getWarriorCost() public pure returns(uint) {
        return warriorCost;
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Derivation / Calaculation Pure Functions
    //////////////////////////////////////////////////////////////////////////////////////////

    function calcBaseHP(uint16 level, uint16 con, uint16 str) internal pure returns (uint) {
		return (con*(hpConFactor+level)) + (str*hpStrFactor);
    }

    function calcXPTargetForLevel(uint16 level) internal pure returns(uint64) {
        return (level+levelOffset) ** levelExponent;
    }

    function calcXPForPractice(uint16 level) internal pure returns (uint64) {
        return calcXPTargetForLevel(level)/(((level+practiceLevelOffset)**2)+1);
    }

    function calcDominantStatValue(uint16 con, uint16 dex, uint16 str) internal pure returns(uint16) {
        if(con>dex&&con>str) return con;
        else if(dex>con&&dex>str) return dex;
        else return str;
    }

    function calcTimeToPractice(uint16 level) internal pure returns(uint) {
		return trainingTimeFactor * ((level**levelExponent)+levelOffset);
    }

    function calcAttributeCost(uint8 amount, uint16 stat_base, uint costExponent) internal pure returns (uint cost) {
        for(uint i=0;i<amount;i++){
            cost += (stat_base + i) ** costExponent;
        }
    }
    
    function calcItemCost(uint8 amount, uint8 currentVal, uint baseCost, uint offset, uint exponent) internal pure returns (uint cost) {
        for(uint i=0;i<amount;i++){
            cost += ((i + 1 + currentVal + offset) ** exponent) * baseCost;
        }
    }

    function calcReviveCost(uint16 level) internal pure returns(uint) {
        return ((level ** 2) +1) * warriorReviveBaseCost;
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Derived/Calculated Getters
    //////////////////////////////////////////////////////////////////////////////////////////

    function getName(warrior memory w) public pure returns(string memory name) {
        name = bytes32ToString(w.bytesName);
    }

    function getHP(warrior memory w) public pure returns (int) {
        return int(int64(w.stats.baseHP) - int64(w.stats.dmg));
    }

    function getWeaponClass(warrior memory w) public pure returns (WeaponClass) {
        if((w.equipment.weaponType==WeaponType.Broadsword || w.equipment.weaponType==WeaponType.Axe)) return WeaponClass.Cleaving;
        if((w.equipment.weaponType==WeaponType.Mace || w.equipment.weaponType==WeaponType.Hammer || w.equipment.weaponType==WeaponType.Flail)) return WeaponClass.Bludgeoning;
        if((w.equipment.weaponType==WeaponType.Trident || w.equipment.weaponType==WeaponType.Halberd || w.equipment.weaponType==WeaponType.Spear)) return WeaponClass.ExtRange;        
        //Default, (w.weaponType==WeaponType.Sword || w.weaponType==WeaponType.Falchion):
        return WeaponClass.Slashing;
    }
   
    function canLevelUp(warrior memory w) public pure returns(bool) {
        return (w.stats.xp >= calcXPTargetForLevel(w.stats.level));
    }

    function getCosmeticProperty(warrior memory w, uint propertyIndex) public pure returns (uint) {
        return random(w.cosmeticSeed,propertyIndex);
    }

    function getEquipLevel(warrior memory w) public pure returns (uint) {
        if(w.equipment.weaponStrength>w.equipment.armorStrength && w.equipment.weaponStrength>w.equipment.shieldStrength){
            return w.equipment.weaponStrength;
        }else{
            if(w.equipment.armorStrength>w.equipment.shieldStrength){
                return w.equipment.armorStrength;
            }else{
                return w.equipment.shieldStrength;
            }
        }
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Costing Getters
    //////////////////////////////////////////////////////////////////////////////////////////

    function getStatsCost(warrior memory w, uint8 strAmount, uint8 dexAmount, uint8 conAmount, uint8 luckAmount) public pure returns (uint) {
        return (
            calcAttributeCost(strAmount,w.stats.str,strCostExponent)+
            calcAttributeCost(dexAmount,w.stats.dex,dexCostExponent)+
            calcAttributeCost(conAmount,w.stats.con,conCostExponent)+
            calcAttributeCost(luckAmount,w.stats.luck,luckCostExponent)
        );
    }
    
    function getEquipCost(warrior memory w, uint8 armorAmount, uint8 shieldAmount, uint8 weaponAmount, uint8 potionAmount, uint8 intPotionAmount) public pure returns(uint) {
        return (
            calcItemCost(armorAmount,w.equipment.armorStrength,armorCost,armorCostOffset,armorCostExponent)+
            calcItemCost(shieldAmount,w.equipment.shieldStrength,shieldCost,shieldCostOffset,shieldCostExponent)+
            calcItemCost(weaponAmount,w.equipment.weaponStrength,weaponCost,weaponCostOffset,weaponCostExponent)+
            (potionCost*potionAmount)+
            (intPotionCost+intPotionAmount)
        );
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Setters
    //////////////////////////////////////////////////////////////////////////////////////////

    function setName(warrior memory w, string memory name) public pure returns (warrior memory) {
        require(w.bytesName==bytes32(0));
        w.bytesName = stringToBytes32(name);
        return w;
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Buying Things
    //////////////////////////////////////////////////////////////////////////////////////////

    function buyStats(warrior memory w, uint8 strAmount, uint8 dexAmount, uint8 conAmount, uint8 luckAmount) public pure returns (warrior memory) {
        require(strAmount>0 || dexAmount>0 || conAmount>0 || luckAmount>0); //Require buying at least something, otherwise you are wasting gas!
        w.stats.str += strAmount;
        w.stats.dex += dexAmount;
        w.stats.con += conAmount;
        w.stats.luck += luckAmount;
        w.stats.baseHP = uint64(calcBaseHP(w.stats.level,w.stats.con,w.stats.str));
        return w;
    }

    function buyEquipment(warrior memory w, uint8 armorAmount, uint8 shieldAmount, uint8 weaponAmount, uint8 potionAmount, uint8 intPotionAmount) public pure returns (warrior memory) {
        require(armorAmount>0 || shieldAmount>0 || weaponAmount>0 || potionAmount>0 || intPotionAmount>0); //Require buying at least something, otherwise you are wasting gas!
        require((w.equipment.potions+potionAmount) <= maxPotions);
        require((w.equipment.intPotions+intPotionAmount) <= maxIntPotions);
        w.equipment.armorStrength += armorAmount;
        w.equipment.shieldStrength += shieldAmount;
        w.equipment.weaponStrength += weaponAmount;
        w.equipment.potions += potionAmount;
        w.equipment.intPotions += intPotionAmount;
        return w;
    }    

    //////////////////////////////////////////////////////////////////////////////////////////
    // Actions/Activities/Effects
    //////////////////////////////////////////////////////////////////////////////////////////

    function levelUp(warrior memory w) public pure returns (warrior memory) {
        require(w.stats.xp >= calcXPTargetForLevel(w.stats.level));
        w.stats.level++;
        w.stats.str++;
        w.stats.dex++;
        w.stats.con++;
        w.stats.points += ((w.stats.level+pointsLevelOffset) * pointsLevelMultiplier) ** levelPointsExponent;
        w.stats.baseHP = uint64(calcBaseHP(w.stats.level,w.stats.con,w.stats.str));
        return w;
    }

	function awardXP(warrior memory w, uint64 amount) public pure returns (warrior memory) {
		w.stats.xp += amount;
        if(canLevelUp(w)) {
            return levelUp(w);
        }else{
            return w;
        }
    }

    function practice(warrior memory w) public view returns (warrior memory) {
        require(uint32(block.timestamp)>w.trainingUntil,"BUSY_TRAINING!");
        if(w.equipment.intPotions>0){
            w.equipment.intPotions--;
            w.trainingUntil = uint32(block.timestamp + (calcTimeToPractice(w.stats.level)/intPotionFactor));
        }else{
            w.trainingUntil = uint32(block.timestamp + calcTimeToPractice(w.stats.level)); 
        }
        return awardXP(w,calcXPForPractice(w.stats.level));
    }

    function revive(warrior memory w) public pure returns (warrior memory) {
		w.state = warriorState.Idle;
        w.stats.dmg = 0;
        return w;
    }

    function kill(warrior memory w) public pure returns (warrior memory) {
		w.state = warriorState.Incapacitated;
        return w;
    }

    function drinkPotion(warrior memory w) public pure returns (warrior memory) {
		require(w.equipment.potions>0);
        require(w.stats.dmg>0);
        w.equipment.potions--;
        if(w.stats.dmg>potionHealAmount){
            w.stats.dmg -= potionHealAmount;
        }else{
            w.stats.dmg = 0;
        }
        return w;
    }

    function applyDamage(warrior memory w, uint damage) public pure returns (warrior memory) {
		w.stats.dmg += uint64(damage);
        if(w.stats.dmg >= w.stats.baseHP) {
            w.stats.dmg = w.stats.baseHP;
            kill(w);
        }
        return w;
    }

    function wearWeapon(warrior memory w) public pure returns (warrior memory) {
        if(w.equipment.weaponStrength>0){
            w.equipment.weaponWear++;
            if(w.equipment.weaponWear>((maxWeapon+1)-w.equipment.weaponStrength)){ //Wear increases as you approach max level
                w.equipment.weaponStrength--;
                w.equipment.weaponWear=0;
            }
        }
        return w;
    }

    function wearArmor(warrior memory w) public pure returns (warrior memory) {
        if(w.equipment.armorStrength>0){
            w.equipment.armorWear++;
            if(w.equipment.armorWear>((maxArmor+1)-w.equipment.armorStrength)){ //Wear increases as you approach max level
                w.equipment.armorStrength--;
                w.equipment.armorWear=0;
            }
        }
        return w;
    }

    function wearShield(warrior memory w) public pure returns (warrior memory) {
        if(w.equipment.shieldStrength>0){
            w.equipment.shieldWear++;
            if(w.equipment.shieldWear>((maxShield+1)-w.equipment.shieldStrength)){ //Wear increases as you approach max level
                w.equipment.shieldStrength--;
                w.equipment.shieldWear=0;
            }
        }
        return w;
    }
}

// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.5.17;

library Strings {
  // via https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol
  function strConcat(string memory _a, string memory _b, string memory _c, string memory _d, string memory _e) internal pure returns (string memory) {
      bytes memory _ba = bytes(_a);
      bytes memory _bb = bytes(_b);
      bytes memory _bc = bytes(_c);
      bytes memory _bd = bytes(_d);
      bytes memory _be = bytes(_e);
      string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
      bytes memory babcde = bytes(abcde);
      uint k = 0;
      for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
      for (uint i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
      for (uint i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
      for (uint i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
      for (uint i = 0; i < _be.length; i++) babcde[k++] = _be[i];
      return string(babcde);
    }

    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d) internal pure returns (string memory) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c) internal pure returns (string memory) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string memory _a, string memory _b) internal pure returns (string memory) {
        return strConcat(_a, _b, "", "", "");
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
}

// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "./ERC1155Tradable.sol";
import "./LibWarrior.sol";

//Import ERC1155 standard for utilizing FAME tokens
import 'multi-token-standard/contracts/interfaces/IERC1155.sol'; //Token interface for interacting with token contracts

/**
 * @title WarriorCollectible
 * WarriorCollectible - The contract for managing BattleDrome Warrior NFTs
 */

contract WarriorCollectible is ERC1155Tradable {

    using LibWarrior for LibWarrior.warrior;

    mapping(uint256=>LibWarrior.warrior) warriors;
	mapping(string=>bool) warriorNames;
	mapping(string=>uint) warriorsByName;
    mapping(address=>bool) trustedContracts;

    IERC1155 FAMEContract;
    uint256 FAMETokenID;
    uint256 warriorTaxDivisor;

    constructor(address _proxyRegistryAddress)
        ERC1155Tradable(
        "WarriorCollectible",
        "WAR",
        _proxyRegistryAddress
    ) public {
        _setBaseMetadataURI("https://metadata.battledrome.io/api/erc1155-warrior/");
        warriorTaxDivisor = 100;
    }

    function contractURI() public pure returns (string memory) {
        return "https://metadata.battledrome.io/contract/erc1155-warrior";
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Modifiers
    //////////////////////////////////////////////////////////////////////////////////////////
    
	modifier onlyTrustedContracts() {
		//Check that the message came from a Trusted Contract
		require(trustedContracts[msg.sender]);
		_;
	}
    
	modifier onlyState(uint warriorID, LibWarrior.warriorState state) {
		require(warriors[warriorID].state == state);
		_;
	}

	modifier costsPoints(uint warriorID, uint _points) {
        require(warriors[warriorID].stats.points >= uint64(_points));
        warriors[warriorID].stats.points -= uint64(_points);
        _;
    }

    modifier notWhileTraining(uint warriorID) {
        require(block.timestamp > warriors[warriorID].trainingUntil);
        _;
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Events
    //////////////////////////////////////////////////////////////////////////////////////////

    event WarriorAltered(
        uint64 indexed warrior,
        uint32 timeStamp
        );
    
    //////////////////////////////////////////////////////////////////////////////////////////
    // Warrior Factory
    //////////////////////////////////////////////////////////////////////////////////////////

    //Custom Minting Function for utility (to be called by trusted contracts)
	function mintCustomWarrior(address owner, uint32 generation, bool special, uint randomSeed, uint16 colorHue, uint8 armorType, uint8 shieldType, uint8 weaponType) public onlyTrustedContracts returns(uint theNewWarrior) {
        //Calculate new Token ID for minting
        uint256 _id = _getNextTokenID();
        _incrementTokenTypeId();
        //Log the original creator of this warrior
        creators[_id] = owner;
		//Generate a new warrior metadata structure, and add it to the warriors array
        warriors[_id]=LibWarrior.newWarriorFixed(owner, generation, special, randomSeed, colorHue, armorType, shieldType, weaponType);
        //Mint the new token in the ledger
        _mint(owner, _id, 1, "");
        tokenSupply[_id] = 1;
		//Return new warrior index
        return _id;
	}

    //Standard factory function, allowing minting warriors.
	function newWarrior() public returns(uint theNewWarrior) {
        //Generate a new random seed for the warrior
        uint randomSeed = uint(blockhash(block.number - 1));    //YES WE KNOW this isn't truely random. it's predictable, and vulnerable to malicious miners... 
                                                                //Doesn't actually matter in this case. That's all ok. It's only for generating cosmetics etc...
        //Calculate the fee:
        uint warriorFee = LibWarrior.getWarriorCost();

        //Take fee from the owner
        transferFAME(msg.sender,address(this),warriorFee);

        //Calculate new Token ID for minting
        uint256 _id = _getNextTokenID();
        _incrementTokenTypeId();

        //Log the original creator of this warrior
        creators[_id] = msg.sender;

		//Generate a new warrior metadata structure, and add it to the warriors array
        warriors[_id]=LibWarrior.newWarrior(msg.sender, randomSeed);

		//Transfer the paid fee to the warrior as initial starting FAME
        FAMEToWarrior(_id,warriorFee,false);

        //Mint the new token in the ledger
        _mint(msg.sender, _id, 1, "");
        tokenSupply[_id] = 1;

		//Return new warrior index
        return _id;
	}

    //////////////////////////////////////////////////////////////////////////////////////////
    // ERC1155 Overrides for custom functionality
    //////////////////////////////////////////////////////////////////////////////////////////
    
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes memory _data) public {        
        super.safeTransferFrom(_from,_to,_id,_amount,_data);
        warriors[_id].owner = _to;
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // ERC1155Receiver Functions
    //////////////////////////////////////////////////////////////////////////////////////////

    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _amount, bytes calldata _data) external view returns(bytes4) {
        require(msg.sender == address(FAMEContract) && _id == FAMETokenID, "INVALID_TOKEN!");
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // General Utility Functions
    //////////////////////////////////////////////////////////////////////////////////////////

    function touch(uint warriorID) internal {
        emit WarriorAltered(uint64(warriorID),uint32(block.timestamp));
    }

    function setFAMEContractAddress(address newContract) public onlyOwner {
        FAMEContract = IERC1155(newContract);
    }

    function setFAMETokenID(uint256 id) public onlyOwner {
        FAMETokenID = id;
    }
    
    function setWarriorTaxDivisor(uint256 divisor) public onlyOwner {
        warriorTaxDivisor = divisor;
    }

    function transferFAME(address sender, address recipient, uint256 amount) internal {
        FAMEContract.safeTransferFrom(sender, recipient, FAMETokenID, amount, "");
    }

    function FAMEToWarrior(uint256 id, uint256 amount, bool tax) internal {
        uint256 taxAmount = tax ? amount/warriorTaxDivisor : 0; 
        if (tax && taxAmount<=0) taxAmount = 1;
        warriors[id].balance += (amount - taxAmount);
        if(taxAmount>0) transferFAME(address(this),warriors[id].owner,taxAmount);
    }

	function getWarriorIDByName(string memory name) public view returns(uint) {
		return warriorsByName[name];
	}

    function nameExists(string memory _name) public view returns(bool) {
        return warriorNames[_name] == true;
    }

    function setName(uint warriorID, string memory name) public ownersOnly(warriorID) {
		//Check if the name is unique
		require(!nameExists(name));
        //Set the name
        warriors[warriorID].bytesName = LibWarrior.stringToBytes32(name);
        //Add warrior's name to index
        warriorNames[name] = true;
        warriorsByName[name] = warriorID;
        touch(warriorID);
    }

    function addTrustedContract(address trustee) public onlyOwner {
        trustedContracts[trustee] = true;
    }

    function removeTrustedContract(address trustee) public onlyOwner {
        trustedContracts[trustee] = false;
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Basic Getters
    //////////////////////////////////////////////////////////////////////////////////////////

    function ownerOf(uint _id) public view returns(address) {
        return warriors[_id].owner;
    }

    function getWarriorCost() public pure returns(uint) {
        return LibWarrior.getWarriorCost();
    }

    function getWarriorName(uint warriorID) public view returns(string memory) {
        return warriors[warriorID].getName();
    }

    function getWarrior(uint warriorID) public view returns(LibWarrior.warrior memory) {
        return warriors[warriorID];
    }

    function getWarriorStats(uint warriorID) public view returns(LibWarrior.warriorStats memory) {
        return warriors[warriorID].stats;
    }

    function getWarriorEquipment(uint warriorID) public view returns(LibWarrior.warriorEquipment memory) {
        return warriors[warriorID].equipment;
    }

    function getCosmeticProperty(uint warriorID, uint propertyIndex) public view returns (uint48) {
        return uint48(warriors[warriorID].getCosmeticProperty(propertyIndex));
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Transaction/Payment Handling
    //////////////////////////////////////////////////////////////////////////////////////////

	function payWarrior(uint warriorID, uint amount, bool tax) public {
        //Take sent amount from msg.sender
        transferFAME(msg.sender,address(this),amount);
		//Transfer the paid amount to the warrior
        FAMEToWarrior(warriorID,amount,tax);
        //And alert of an update to the warrior:
        touch(warriorID);
	}

    function transferFAMEFromWarriorToWarrior(uint senderID, uint recipientID, uint amount, bool tax) public onlyTrustedContracts {
        require(warriors[senderID].balance >= amount);
        warriors[senderID].balance -= amount;
        FAMEToWarrior(recipientID,amount,tax);
        touch(senderID);
        touch(recipientID);        
    }

    function transferFAMEFromWarriorToAddress(uint warriorID, address recipient, uint amount) public onlyTrustedContracts {
        require(warriors[warriorID].balance >= amount);
        warriors[warriorID].balance -= amount;
        transferFAME(address(this),recipient,amount);
        touch(warriorID);
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Master Setters for Updating Metadata store on Warrior NFTs
    //////////////////////////////////////////////////////////////////////////////////////////

    function setWarriorState(uint warriorID, LibWarrior.warriorState _warriorState, uint32 _trainingUntil) public onlyTrustedContracts {
        warriors[warriorID].state = _warriorState;
        warriors[warriorID].trainingUntil = _trainingUntil;
        touch(warriorID);
    }

    function setWarriorStats(uint warriorID, LibWarrior.warriorStats memory _statsData) public onlyTrustedContracts {
        warriors[warriorID].stats = _statsData;
        touch(warriorID);
    }

    function setWarriorEquipment(uint warriorID, LibWarrior.warriorEquipment memory _equipmentData) public onlyTrustedContracts {
        warriors[warriorID].equipment = _equipmentData;
        touch(warriorID);
    }

}

pragma solidity ^0.5.16;


interface IERC1155 {

  /****************************************|
  |                 Events                 |
  |_______________________________________*/

  /**
   * @dev Either TransferSingle or TransferBatch MUST emit when tokens are transferred, including zero amount transfers as well as minting or burning
   *   Operator MUST be msg.sender
   *   When minting/creating tokens, the `_from` field MUST be set to `0x0`
   *   When burning/destroying tokens, the `_to` field MUST be set to `0x0`
   *   The total amount transferred from address 0x0 minus the total amount transferred to 0x0 may be used by clients and exchanges to be added to the "circulating supply" for a given token ID
   *   To broadcast the existence of a token ID with no initial balance, the contract SHOULD emit the TransferSingle event from `0x0` to `0x0`, with the token creator as `_operator`, and a `_amount` of 0
   */
  event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _amount);

  /**
   * @dev Either TransferSingle or TransferBatch MUST emit when tokens are transferred, including zero amount transfers as well as minting or burning
   *   Operator MUST be msg.sender
   *   When minting/creating tokens, the `_from` field MUST be set to `0x0`
   *   When burning/destroying tokens, the `_to` field MUST be set to `0x0`
   *   The total amount transferred from address 0x0 minus the total amount transferred to 0x0 may be used by clients and exchanges to be added to the "circulating supply" for a given token ID
   *   To broadcast the existence of multiple token IDs with no initial balance, this SHOULD emit the TransferBatch event from `0x0` to `0x0`, with the token creator as `_operator`, and a `_amount` of 0
   */
  event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _amounts);

  /**
   * @dev MUST emit when an approval is updated
   */
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  /**
   * @dev MUST emit when the URI is updated for a token ID
   *   URIs are defined in RFC 3986
   *   The URI MUST point a JSON file that conforms to the "ERC-1155 Metadata JSON Schema"
   */
  event URI(string _amount, uint256 indexed _id);


  /****************************************|
  |                Functions               |
  |_______________________________________*/

  /**
    * @notice Transfers amount of an _id from the _from address to the _to address specified
    * @dev MUST emit TransferSingle event on success
    * Caller must be approved to manage the _from account's tokens (see isApprovedForAll)
    * MUST throw if `_to` is the zero address
    * MUST throw if balance of sender for token `_id` is lower than the `_amount` sent
    * MUST throw on any other error
    * When transfer is complete, this function MUST check if `_to` is a smart contract (code size > 0). If so, it MUST call `onERC1155Received` on `_to` and revert if the return amount is not `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    * @param _from    Source address
    * @param _to      Target address
    * @param _id      ID of the token type
    * @param _amount  Transfered amount
    * @param _data    Additional data with no specified format, sent in call to `_to`
    */
  function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes calldata _data) external;

  /**
    * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
    * @dev MUST emit TransferBatch event on success
    * Caller must be approved to manage the _from account's tokens (see isApprovedForAll)
    * MUST throw if `_to` is the zero address
    * MUST throw if length of `_ids` is not the same as length of `_amounts`
    * MUST throw if any of the balance of sender for token `_ids` is lower than the respective `_amounts` sent
    * MUST throw on any other error
    * When transfer is complete, this function MUST check if `_to` is a smart contract (code size > 0). If so, it MUST call `onERC1155BatchReceived` on `_to` and revert if the return amount is not `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
    * Transfers and events MUST occur in the array order they were submitted (_ids[0] before _ids[1], etc)
    * @param _from     Source addresses
    * @param _to       Target addresses
    * @param _ids      IDs of each token type
    * @param _amounts  Transfer amounts per token type
    * @param _data     Additional data with no specified format, sent in call to `_to`
  */
  function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external;

  /**
   * @notice Get the balance of an account's Tokens
   * @param _owner  The address of the token holder
   * @param _id     ID of the Token
   * @return        The _owner's balance of the Token type requested
   */
  function balanceOf(address _owner, uint256 _id) external view returns (uint256);

  /**
   * @notice Get the balance of multiple account/token pairs
   * @param _owners The addresses of the token holders
   * @param _ids    ID of the Tokens
   * @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
   */
  function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);

  /**
   * @notice Enable or disable approval for a third party ("operator") to manage all of caller's tokens
   * @dev MUST emit the ApprovalForAll event on success
   * @param _operator  Address to add to the set of authorized operators
   * @param _approved  True if the operator is approved, false to revoke approval
   */
  function setApprovalForAll(address _operator, bool _approved) external;

  /**
   * @notice Queries the approval status of an operator for a given owner
   * @param _owner     The owner of the Tokens
   * @param _operator  Address of authorized operator
   * @return           True if the operator is approved, false if not
   */
  function isApprovedForAll(address _owner, address _operator) external view returns (bool isOperator);
}

pragma solidity ^0.5.16;

/**
 * @dev ERC-1155 interface for accepting safe transfers.
 */
interface IERC1155TokenReceiver {

  /**
   * @notice Handle the receipt of a single ERC1155 token type
   * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated
   * This function MAY throw to revert and reject the transfer
   * Return of other amount than the magic value MUST result in the transaction being reverted
   * Note: The token contract address is always the message sender
   * @param _operator  The address which called the `safeTransferFrom` function
   * @param _from      The address which previously owned the token
   * @param _id        The id of the token being transferred
   * @param _amount    The amount of tokens being transferred
   * @param _data      Additional data with no specified format
   * @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
   */
  function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _amount, bytes calldata _data) external returns(bytes4);

  /**
   * @notice Handle the receipt of multiple ERC1155 token types
   * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated
   * This function MAY throw to revert and reject the transfer
   * Return of other amount than the magic value WILL result in the transaction being reverted
   * Note: The token contract address is always the message sender
   * @param _operator  The address which called the `safeBatchTransferFrom` function
   * @param _from      The address which previously owned the token
   * @param _ids       An array containing ids of each token being transferred
   * @param _amounts   An array containing amounts of each token being transferred
   * @param _data      Additional data with no specified format
   * @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
   */
  function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external returns(bytes4);

  /**
   * @notice Indicates whether a contract implements the `ERC1155TokenReceiver` functions and so can accept ERC1155 token types.
   * @param  interfaceID The ERC-165 interface ID that is queried for support.s
   * @dev This function MUST return true if it implements the ERC1155TokenReceiver interface and ERC-165 interface.
   *      This function MUST NOT consume more than 5,000 gas.
   * @return Whether ERC-165 or ERC1155TokenReceiver interfaces are supported.
   */
  function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

pragma solidity ^0.5.16;


/**
 * @title ERC165
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
 */
interface IERC165 {

    /**
     * @notice Query if a contract implements an interface
     * @dev Interface identification is specified in ERC-165. This function
     * uses less than 30,000 gas
     * @param _interfaceId The interface identifier, as specified in ERC-165
     */
    function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}

pragma solidity ^0.5.16;

import "../../interfaces/IERC165.sol";
import "../../utils/SafeMath.sol";
import "../../interfaces/IERC1155TokenReceiver.sol";
import "../../interfaces/IERC1155.sol";
import "../../utils/Address.sol";


/**
 * @dev Implementation of Multi-Token Standard contract
 */
contract ERC1155 is IERC165, IERC1155 {
  using SafeMath for uint256;
  using Address for address;

  /***********************************|
  |        Variables and Events       |
  |__________________________________*/

  // onReceive function signatures
  bytes4 constant internal ERC1155_RECEIVED_VALUE = 0xf23a6e61;
  bytes4 constant internal ERC1155_BATCH_RECEIVED_VALUE = 0xbc197c81;

  // Objects balances
  mapping (address => mapping(uint256 => uint256)) internal balances;

  // Operator Functions
  mapping (address => mapping(address => bool)) internal operators;


  /***********************************|
  |     Public Transfer Functions     |
  |__________________________________*/

  /**
   * @notice Transfers amount amount of an _id from the _from address to the _to address specified
   * @param _from    Source address
   * @param _to      Target address
   * @param _id      ID of the token type
   * @param _amount  Transfered amount
   * @param _data    Additional data with no specified format, sent in call to `_to`
   */
  function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes memory _data)
    public
  {
    require((msg.sender == _from) || isApprovedForAll(_from, msg.sender), "ERC1155#safeTransferFrom: INVALID_OPERATOR");
    require(_to != address(0),"ERC1155#safeTransferFrom: INVALID_RECIPIENT");
    // require(_amount <= balances[_from][_id]) is not necessary since checked with safemath operations

    _safeTransferFrom(_from, _to, _id, _amount);
    _callonERC1155Received(_from, _to, _id, _amount, gasleft(), _data);
  }

  /**
   * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
   * @param _from     Source addresses
   * @param _to       Target addresses
   * @param _ids      IDs of each token type
   * @param _amounts  Transfer amounts per token type
   * @param _data     Additional data with no specified format, sent in call to `_to`
   */
  function safeBatchTransferFrom(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data)
    public
  {
    // Requirements
    require((msg.sender == _from) || isApprovedForAll(_from, msg.sender), "ERC1155#safeBatchTransferFrom: INVALID_OPERATOR");
    require(_to != address(0), "ERC1155#safeBatchTransferFrom: INVALID_RECIPIENT");

    _safeBatchTransferFrom(_from, _to, _ids, _amounts);
    _callonERC1155BatchReceived(_from, _to, _ids, _amounts, gasleft(), _data);
  }


  /***********************************|
  |    Internal Transfer Functions    |
  |__________________________________*/

  /**
   * @notice Transfers amount amount of an _id from the _from address to the _to address specified
   * @param _from    Source address
   * @param _to      Target address
   * @param _id      ID of the token type
   * @param _amount  Transfered amount
   */
  function _safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount)
    internal
  {
    // Update balances
    balances[_from][_id] = balances[_from][_id].sub(_amount); // Subtract amount
    balances[_to][_id] = balances[_to][_id].add(_amount);     // Add amount

    // Emit event
    emit TransferSingle(msg.sender, _from, _to, _id, _amount);
  }

  /**
   * @notice Verifies if receiver is contract and if so, calls (_to).onERC1155Received(...)
   */
  function _callonERC1155Received(address _from, address _to, uint256 _id, uint256 _amount, uint256 _gasLimit, bytes memory _data)
    internal
  {
    // Check if recipient is contract
    if (_to.isContract()) {
      bytes4 retval = IERC1155TokenReceiver(_to).onERC1155Received.gas(_gasLimit)(msg.sender, _from, _id, _amount, _data);
      require(retval == ERC1155_RECEIVED_VALUE, "ERC1155#_callonERC1155Received: INVALID_ON_RECEIVE_MESSAGE");
    }
  }

  /**
   * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
   * @param _from     Source addresses
   * @param _to       Target addresses
   * @param _ids      IDs of each token type
   * @param _amounts  Transfer amounts per token type
   */
  function _safeBatchTransferFrom(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts)
    internal
  {
    require(_ids.length == _amounts.length, "ERC1155#_safeBatchTransferFrom: INVALID_ARRAYS_LENGTH");

    // Number of transfer to execute
    uint256 nTransfer = _ids.length;

    // Executing all transfers
    for (uint256 i = 0; i < nTransfer; i++) {
      // Update storage balance of previous bin
      balances[_from][_ids[i]] = balances[_from][_ids[i]].sub(_amounts[i]);
      balances[_to][_ids[i]] = balances[_to][_ids[i]].add(_amounts[i]);
    }

    // Emit event
    emit TransferBatch(msg.sender, _from, _to, _ids, _amounts);
  }

  /**
   * @notice Verifies if receiver is contract and if so, calls (_to).onERC1155BatchReceived(...)
   */
  function _callonERC1155BatchReceived(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts, uint256 _gasLimit, bytes memory _data)
    internal
  {
    // Pass data if recipient is contract
    if (_to.isContract()) {
      bytes4 retval = IERC1155TokenReceiver(_to).onERC1155BatchReceived.gas(_gasLimit)(msg.sender, _from, _ids, _amounts, _data);
      require(retval == ERC1155_BATCH_RECEIVED_VALUE, "ERC1155#_callonERC1155BatchReceived: INVALID_ON_RECEIVE_MESSAGE");
    }
  }


  /***********************************|
  |         Operator Functions        |
  |__________________________________*/

  /**
   * @notice Enable or disable approval for a third party ("operator") to manage all of caller's tokens
   * @param _operator  Address to add to the set of authorized operators
   * @param _approved  True if the operator is approved, false to revoke approval
   */
  function setApprovalForAll(address _operator, bool _approved)
    external
  {
    // Update operator status
    operators[msg.sender][_operator] = _approved;
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }

  /**
   * @notice Queries the approval status of an operator for a given owner
   * @param _owner     The owner of the Tokens
   * @param _operator  Address of authorized operator
   * @return True if the operator is approved, false if not
   */
  function isApprovedForAll(address _owner, address _operator)
    public view returns (bool isOperator)
  {
    return operators[_owner][_operator];
  }


  /***********************************|
  |         Balance Functions         |
  |__________________________________*/

  /**
   * @notice Get the balance of an account's Tokens
   * @param _owner  The address of the token holder
   * @param _id     ID of the Token
   * @return The _owner's balance of the Token type requested
   */
  function balanceOf(address _owner, uint256 _id)
    public view returns (uint256)
  {
    return balances[_owner][_id];
  }

  /**
   * @notice Get the balance of multiple account/token pairs
   * @param _owners The addresses of the token holders
   * @param _ids    ID of the Tokens
   * @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
   */
  function balanceOfBatch(address[] memory _owners, uint256[] memory _ids)
    public view returns (uint256[] memory)
  {
    require(_owners.length == _ids.length, "ERC1155#balanceOfBatch: INVALID_ARRAY_LENGTH");

    // Variables
    uint256[] memory batchBalances = new uint256[](_owners.length);

    // Iterate over each owner and token ID
    for (uint256 i = 0; i < _owners.length; i++) {
      batchBalances[i] = balances[_owners[i]][_ids[i]];
    }

    return batchBalances;
  }


  /***********************************|
  |          ERC165 Functions         |
  |__________________________________*/

  /**
   * INTERFACE_SIGNATURE_ERC165 = bytes4(keccak256("supportsInterface(bytes4)"));
   */
  bytes4 constant private INTERFACE_SIGNATURE_ERC165 = 0x01ffc9a7;

  /**
   * INTERFACE_SIGNATURE_ERC1155 =
   * bytes4(keccak256("safeTransferFrom(address,address,uint256,uint256,bytes)")) ^
   * bytes4(keccak256("safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)")) ^
   * bytes4(keccak256("balanceOf(address,uint256)")) ^
   * bytes4(keccak256("balanceOfBatch(address[],uint256[])")) ^
   * bytes4(keccak256("setApprovalForAll(address,bool)")) ^
   * bytes4(keccak256("isApprovedForAll(address,address)"));
   */
  bytes4 constant private INTERFACE_SIGNATURE_ERC1155 = 0xd9b67a26;

  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceID  The interface identifier, as specified in ERC-165
   * @return `true` if the contract implements `_interfaceID` and
   */
  function supportsInterface(bytes4 _interfaceID) external view returns (bool) {
    if (_interfaceID == INTERFACE_SIGNATURE_ERC165 ||
        _interfaceID == INTERFACE_SIGNATURE_ERC1155) {
      return true;
    }
    return false;
  }
}

pragma solidity ^0.5.16;
import "../../interfaces/IERC1155.sol";


/**
 * @notice Contract that handles metadata related methods.
 * @dev Methods assume a deterministic generation of URI based on token IDs.
 *      Methods also assume that URI uses hex representation of token IDs.
 */
contract ERC1155Metadata {
  // URI's default URI prefix
  string internal baseMetadataURI;
  event URI(string _uri, uint256 indexed _id);

  /***********************************|
  |     Metadata Public Function s    |
  |__________________________________*/

  /**
   * @notice A distinct Uniform Resource Identifier (URI) for a given token.
   * @dev URIs are defined in RFC 3986.
   *      URIs are assumed to be deterministically generated based on token ID
   *      Token IDs are assumed to be represented in their hex format in URIs
   * @return URI string
   */
  function uri(uint256 _id) public view returns (string memory) {
    return string(abi.encodePacked(baseMetadataURI, _uint2str(_id), ".json"));
  }


  /***********************************|
  |    Metadata Internal Functions    |
  |__________________________________*/

  /**
   * @notice Will emit default URI log event for corresponding token _id
   * @param _tokenIDs Array of IDs of tokens to log default URI
   */
  function _logURIs(uint256[] memory _tokenIDs) internal {
    string memory baseURL = baseMetadataURI;
    string memory tokenURI;

    for (uint256 i = 0; i < _tokenIDs.length; i++) {
      tokenURI = string(abi.encodePacked(baseURL, _uint2str(_tokenIDs[i]), ".json"));
      emit URI(tokenURI, _tokenIDs[i]);
    }
  }

  /**
   * @notice Will update the base URL of token's URI
   * @param _newBaseMetadataURI New base URL of token's URI
   */
  function _setBaseMetadataURI(string memory _newBaseMetadataURI) internal {
    baseMetadataURI = _newBaseMetadataURI;
  }


  /***********************************|
  |    Utility Internal Functions     |
  |__________________________________*/

  /**
   * @notice Convert uint256 to string
   * @param _i Unsigned integer to convert to string
   */
  function _uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
    if (_i == 0) {
      return "0";
    }

    uint256 j = _i;
    uint256 ii = _i;
    uint256 len;

    // Get number of bytes
    while (j != 0) {
      len++;
      j /= 10;
    }

    bytes memory bstr = new bytes(len);
    uint256 k = len - 1;

    // Get each individual ASCII
    while (ii != 0) {
      bstr[k--] = byte(uint8(48 + ii % 10));
      ii /= 10;
    }

    // Convert to string
    return string(bstr);
  }
}

pragma solidity ^0.5.16;
import "./ERC1155.sol";


/**
 * @dev Multi-Fungible Tokens with minting and burning methods. These methods assume
 *      a parent contract to be executed as they are `internal` functions
 */
contract ERC1155MintBurn is ERC1155 {

  /****************************************|
  |            Minting Functions           |
  |_______________________________________*/

  /**
   * @notice Mint _amount of tokens of a given id
   * @param _to      The address to mint tokens to
   * @param _id      Token id to mint
   * @param _amount  The amount to be minted
   * @param _data    Data to pass if receiver is contract
   */
  function _mint(address _to, uint256 _id, uint256 _amount, bytes memory _data)
    internal
  {
    // Add _amount
    balances[_to][_id] = balances[_to][_id].add(_amount);

    // Emit event
    emit TransferSingle(msg.sender, address(0x0), _to, _id, _amount);

    // Calling onReceive method if recipient is contract
    _callonERC1155Received(address(0x0), _to, _id, _amount, gasleft(), _data);
  }

  /**
   * @notice Mint tokens for each ids in _ids
   * @param _to       The address to mint tokens to
   * @param _ids      Array of ids to mint
   * @param _amounts  Array of amount of tokens to mint per id
   * @param _data    Data to pass if receiver is contract
   */
  function _batchMint(address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data)
    internal
  {
    require(_ids.length == _amounts.length, "ERC1155MintBurn#batchMint: INVALID_ARRAYS_LENGTH");

    // Number of mints to execute
    uint256 nMint = _ids.length;

     // Executing all minting
    for (uint256 i = 0; i < nMint; i++) {
      // Update storage balance
      balances[_to][_ids[i]] = balances[_to][_ids[i]].add(_amounts[i]);
    }

    // Emit batch mint event
    emit TransferBatch(msg.sender, address(0x0), _to, _ids, _amounts);

    // Calling onReceive method if recipient is contract
    _callonERC1155BatchReceived(address(0x0), _to, _ids, _amounts, gasleft(), _data);
  }


  /****************************************|
  |            Burning Functions           |
  |_______________________________________*/

  /**
   * @notice Burn _amount of tokens of a given token id
   * @param _from    The address to burn tokens from
   * @param _id      Token id to burn
   * @param _amount  The amount to be burned
   */
  function _burn(address _from, uint256 _id, uint256 _amount)
    internal
  {
    //Substract _amount
    balances[_from][_id] = balances[_from][_id].sub(_amount);

    // Emit event
    emit TransferSingle(msg.sender, _from, address(0x0), _id, _amount);
  }

  /**
   * @notice Burn tokens of given token id for each (_ids[i], _amounts[i]) pair
   * @param _from     The address to burn tokens from
   * @param _ids      Array of token ids to burn
   * @param _amounts  Array of the amount to be burned
   */
  function _batchBurn(address _from, uint256[] memory _ids, uint256[] memory _amounts)
    internal
  {
    // Number of mints to execute
    uint256 nBurn = _ids.length;
    require(nBurn == _amounts.length, "ERC1155MintBurn#batchBurn: INVALID_ARRAYS_LENGTH");

    // Executing all minting
    for (uint256 i = 0; i < nBurn; i++) {
      // Update storage balance
      balances[_from][_ids[i]] = balances[_from][_ids[i]].sub(_amounts[i]);
    }

    // Emit batch mint event
    emit TransferBatch(msg.sender, _from, address(0x0), _ids, _amounts);
  }
}

pragma solidity ^0.5.16;


/**
 * Utility library of inline functions on addresses
 */
library Address {

  // Default hash for EOA accounts returned by extcodehash
  bytes32 constant internal ACCOUNT_HASH = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract.
   * @param _address address of the account to check
   * @return Whether the target address is a contract
   */
  function isContract(address _address) internal view returns (bool) {
    bytes32 codehash;

    // Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address or if it has a non-zero code hash or account hash
    assembly { codehash := extcodehash(_address) }
    return (codehash != 0x0 && codehash != ACCOUNT_HASH);
  }
}

pragma solidity ^0.5.16;


/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {

  /**
   * @dev Multiplies two unsigned integers, reverts on overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath#mul: OVERFLOW");

    return c;
  }

  /**
   * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath#div: DIVISION_BY_ZERO");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath#sub: UNDERFLOW");
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Adds two unsigned integers, reverts on overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath#add: OVERFLOW");

    return c; 
  }

  /**
   * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
   * reverts when dividing by zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath#mod: DIVISION_BY_ZERO");
    return a % b;
  }
}

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.5.0;

import "../GSN/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {
    "/home/pmumby/Development/BattleDrome/battledrome-erc1155-warrior/contracts/LibWarrior.sol": {
      "LibWarrior": "0x335C8e8d4D2D252c2732A5865407A1F73DA22AAE"
    }
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}