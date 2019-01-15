pragma solidity 0.4.24;

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ItemsInterfaceForEternalStorage {
    function createShip(uint256 _itemId) public;
    function createRadar(uint256 _itemId) public;
    function createScanner(uint256 _itemId) public;
    function createDroid(uint256 _itemId) public;
    function createFuel(uint256 _itemId) public;
    function createGenerator(uint256 _itemId) public;
    function createEngine(uint256 _itemId) public;
    function createGun(uint256 _itemId) public;
    function createMicroModule(uint256 _itemId) public;
    function createArtefact(uint256 _itemId) public;
    
    function addItem(string _itemType) public returns(uint256);
}

contract EternalStorage {

    ItemsInterfaceForEternalStorage private mI;

    /* ------ STORAGE ------ */

    mapping(bytes32 => uint256) private uintStorage;
    mapping(bytes32 => uint256[]) private uintArrayStorage;

    mapping(bytes32 => string) private stringStorage;
    mapping(bytes32 => address) private addressStorage;
    mapping(bytes32 => bytes) private bytesStorage;
    mapping(bytes32 => bool) private boolStorage;
    mapping(bytes32 => int256) private intStorage;

    address private ownerOfStorage;
    address private logicContractAddress;

    mapping(address => uint256) private refunds;

    constructor() public {
        ownerOfStorage = msg.sender;
        mI = ItemsInterfaceForEternalStorage(0xf1fd447DAc5AbEAba356cD0010Bac95daA37C265);
    }

    /* ------ MODIFIERS ------ */

    modifier onlyOwnerOfStorage() {
        require(msg.sender == ownerOfStorage);
        _;
    }

    modifier onlyLogicContract() {
        require(msg.sender == logicContractAddress);
        _;
    }
    
    /* ------ INITIALISATION ------ */

    function initWithShips() public onlyOwnerOfStorage {
        createShip(1, &#39;Titanium Ranger Hull&#39;, 200, 2, 0.000018 ether);
        createShip(2, &#39;Platinum Ranger Hull&#39;, 400, 4, 0.45 ether);
        createShip(3, &#39;Adamantium Ranger Hull&#39;, 600, 7, 0.9 ether);
    }

    /* ------ REFERAL SYSTEM FUNCTIONS ------ */

    function addReferrer(address _referrerWalletAddress, uint256 referrerPrize) public onlyLogicContract {
        refunds[_referrerWalletAddress] += referrerPrize;
    }

    function widthdrawRefunds(address _owner) public onlyLogicContract returns(uint256) {
        uint256 refund = refunds[_owner];
        refunds[_owner] = 0;
        return refund;
    }

    function checkRefundExistanceByOwner(address _owner) public view onlyLogicContract returns(uint256) {
        return refunds[_owner];
    }

     /* ------ BUY OPERATIONS ------ */

    function buyItem(uint256 _itemId, address _newOwner, string _itemTitle, string _itemTypeTitle, string _itemIdTitle) public onlyLogicContract returns(uint256) {
        uintStorage[_b2(_itemTitle, _newOwner)]++;
        uintArrayStorage[_b2(_itemTypeTitle, _newOwner)].push(_itemId);

        uint256 newItemId = mI.addItem(_itemTitle);

        uintArrayStorage[_b2(_itemIdTitle, _newOwner)].push(newItemId);

        addressStorage[_b3(_itemTitle, newItemId)] = _newOwner;
        return _itemId;
    }

    function destroyEternalStorage() public onlyOwnerOfStorage {
        selfdestruct(0xd135377eB20666725D518c967F23e168045Ee11F);
    }

    /* ------ HASH FUNCTIONS ------ */

    function _toString(address x) private pure returns (string) {
        bytes memory b = new bytes(20);
        for (uint i = 0; i < 20; i++)
            b[i] = byte(uint8(uint(x) / (2**(8*(19 - i)))));
        return string(b);
    }

    function _b1(string _itemType, uint256 _itemId, string _property) private pure returns(bytes32) {
        return keccak256(abi.encodePacked(_itemType, _itemId, _property));
    }

    function _b2(string _itemType, address _newOwnerAddress) private pure returns(bytes32) {
        return keccak256(abi.encodePacked(_toString(_newOwnerAddress), _itemType));
    }

    function _b3(string _itemType, uint256 _itemId) private pure returns(bytes32) {
        return keccak256(abi.encodePacked(_itemType, _itemId));
    }

    /* ------ READING METHODS FOR USERS ITEMS ------ */

    function getNumberOfItemsByTypeAndOwner(string _itemType, address _owner) public onlyLogicContract view returns(uint256) {
        return uintStorage[_b2(_itemType, _owner)];
    }

    function getItemsByTypeAndOwner(string _itemTypeTitle, address _owner) public onlyLogicContract view returns(uint256[]) {
        return uintArrayStorage[_b2(_itemTypeTitle, _owner)];
    }

    function getItemsIdsByTypeAndOwner(string _itemIdsTitle, address _owner) public onlyLogicContract view returns(uint256[]) {
        return uintArrayStorage[_b2(_itemIdsTitle, _owner)];
    }

    function getOwnerByItemTypeAndId(string _itemType, uint256 _itemId) public onlyLogicContract view returns(address) {
        return addressStorage[_b3(_itemType, _itemId)];
    }

     /* ------ READING METHODS FOR ALL ITEMS ------ */

    function getItemPriceById(string _itemType, uint256 _itemId) public onlyLogicContract view returns(uint256) {
        return uintStorage[_b1(_itemType, _itemId, "price")];
    }

    // Get Radar, Scanner, Droid, Fuel, Generator by ID
    function getTypicalItemById(string _itemType, uint256 _itemId) public onlyLogicContract view returns(
        uint256,
        string,
        uint256,
        uint256,
        uint256
    ) {
        return (
            _itemId,
            stringStorage[_b1(_itemType, _itemId, "name")],
            uintStorage[_b1(_itemType, _itemId, "value")],
            uintStorage[_b1(_itemType, _itemId, "price")],
            uintStorage[_b1(_itemType, _itemId, "durability")]
        );
    }

    function getShipById(uint256 _shipId) public onlyLogicContract view returns(
        uint256,
        string,
        uint256,
        uint256,
        uint256
    ) {
        return (
            _shipId,
            stringStorage[_b1("ships", _shipId, "name")],
            uintStorage[_b1("ships", _shipId, "hp")],
            uintStorage[_b1("ships", _shipId, "block")],
            uintStorage[_b1("ships", _shipId, "price")]
        );
    }

    function getEngineById(uint256 _engineId) public onlyLogicContract view returns(
        uint256,
        string,
        uint256,
        uint256,
        uint256,
        uint256
    ) {
        return (
            _engineId,
            stringStorage[_b1("engines", _engineId, "name")],
            uintStorage[_b1("engines", _engineId, "speed")],
            uintStorage[_b1("engines", _engineId, "giper")],
            uintStorage[_b1("engines", _engineId, "price")],
            uintStorage[_b1("engines", _engineId, "durability")]
        );
    }

    function getGunByIdPart1(uint256 _gunId) public onlyLogicContract view returns(
        uint256,
        string,
        uint256,
        uint256
    ) {
        return (
            _gunId,
            stringStorage[_b1("guns", _gunId, "name")],
            uintStorage[_b1("guns", _gunId, "min")],
            uintStorage[_b1("guns", _gunId, "max")]
        );
    }

    function getGunByIdPart2(uint256 _gunId) public onlyLogicContract view returns(
        uint256,
        uint256,
        uint256,
        uint256,
        uint256
    ) {
        return (
            uintStorage[_b1("guns", _gunId, "radius")],
            uintStorage[_b1("guns", _gunId, "recharge")],
            uintStorage[_b1("guns", _gunId, "ability")],
            uintStorage[_b1("guns", _gunId, "price")],
            uintStorage[_b1("guns", _gunId, "durability")]
        );
    }

    function getMicroModuleByIdPart1(uint256 _microModuleId) public onlyLogicContract view returns(
        uint256,
        string,
        uint256,
        uint256
    ) {
        return (
            _microModuleId,
            stringStorage[_b1("microModules", _microModuleId, "name")],
            uintStorage[_b1("microModules", _microModuleId, "itemType")],
            uintStorage[_b1("microModules", _microModuleId, "bonusType")]
        );
    }

    function getMicroModuleByIdPart2(uint256 _microModuleId) public onlyLogicContract view returns(
        uint256,
        uint256,
        uint256
    ) {
        return (
            uintStorage[_b1("microModules", _microModuleId, "bonus")],
            uintStorage[_b1("microModules", _microModuleId, "level")],
            uintStorage[_b1("microModules", _microModuleId, "price")]
        );
    }

    function getArtefactById(uint256 _artefactId) public onlyLogicContract view returns(
        uint256,
        string,
        uint256,
        uint256,
        uint256
    ) {
        return (
            _artefactId,
            stringStorage[_b1("artefacts", _artefactId, "name")],
            uintStorage[_b1("artefacts", _artefactId, "itemType")],
            uintStorage[_b1("artefacts", _artefactId, "bonusType")],
            uintStorage[_b1("artefacts", _artefactId, "bonus")]
        );
    }
    
    /* ------ DEV CREATION METHODS ------ */

    // Ships
    function createShip(uint256 _shipId, string _name, uint256 _hp, uint256 _block, uint256 _price) public onlyOwnerOfStorage {
        mI.createShip(_shipId);
        stringStorage[_b1("ships", _shipId, "name")] = _name;
        uintStorage[_b1("ships", _shipId, "hp")] = _hp;
        uintStorage[_b1("ships", _shipId, "block")] = _block;
        uintStorage[_b1("ships", _shipId, "price")] = _price;
    }

    // update data for an item by ID
    function _update(string _itemType, uint256 _itemId, string _name, uint256 _value, uint256 _price, uint256 _durability) private {
        stringStorage[_b1(_itemType, _itemId, "name")] = _name;
        uintStorage[_b1(_itemType, _itemId, "value")] = _value;
        uintStorage[_b1(_itemType, _itemId, "price")] = _price;
        uintStorage[_b1(_itemType, _itemId, "durability")] = _durability;
    }

    // Radars
    function createRadar(uint256 _radarId, string _name, uint256 _value, uint256 _price, uint256 _durability) public onlyOwnerOfStorage {
        mI.createRadar(_radarId);
        _update("radars", _radarId, _name, _value, _price, _durability);
    }

    // Scanners
    function createScanner(uint256 _scannerId, string _name, uint256 _value, uint256 _price, uint256 _durability) public onlyOwnerOfStorage {
        mI.createScanner(_scannerId);
        _update("scanners", _scannerId, _name, _value, _price, _durability);
    }

    // Droids
    function createDroid(uint256 _droidId, string _name, uint256 _value, uint256 _price, uint256 _durability) public onlyOwnerOfStorage {
        mI.createDroid(_droidId);
        _update("droids", _droidId, _name, _value, _price, _durability);
    }

    // Fuels
    function createFuel(uint256 _fuelId, string _name, uint256 _value, uint256 _price, uint256 _durability) public onlyOwnerOfStorage {
        mI.createFuel(_fuelId);
        _update("fuels", _fuelId, _name, _value, _price, _durability);
    }

    // Generators
    function createGenerator(uint256 _generatorId, string _name, uint256 _value, uint256 _price, uint256 _durability) public onlyOwnerOfStorage {
        mI.createGenerator(_generatorId);
        _update("generators", _generatorId, _name, _value, _price, _durability);
    }

    // Engines
    function createEngine(uint256 _engineId, string _name, uint256 _speed, uint256 _giper, uint256 _price, uint256 _durability) public onlyOwnerOfStorage {
        mI.createEngine(_engineId);
        stringStorage[_b1("engines", _engineId, "name")] = _name;
        uintStorage[_b1("engines", _engineId, "speed")] = _speed;
        uintStorage[_b1("engines", _engineId, "giper")] = _giper;
        uintStorage[_b1("engines", _engineId, "price")] = _price;
        uintStorage[_b1("engines", _engineId, "durability")] = _durability;
    }

    // Guns
    function createGun(uint256 _gunId, string _name, uint256 _min, uint256 _max, uint256 _radius, uint256 _recharge, uint256 _ability,  uint256 _price, uint256 _durability) public onlyOwnerOfStorage {
        mI.createGun(_gunId);
        stringStorage[_b1("guns", _gunId, "name")] = _name;
        uintStorage[_b1("guns", _gunId, "min")] = _min;
        uintStorage[_b1("guns", _gunId, "max")] = _max;
        uintStorage[_b1("guns", _gunId, "radius")] = _radius;
        uintStorage[_b1("guns", _gunId, "recharge")] = _recharge;
        uintStorage[_b1("guns", _gunId, "ability")] = _ability;
        uintStorage[_b1("guns", _gunId, "price")] = _price;
        uintStorage[_b1("guns", _gunId, "durability")] = _durability;
    }

    // Micro modules
    function createMicroModule(uint256 _microModuleId, string _name, uint256 _itemType, uint256 _bonusType, uint256 _bonus, uint256 _level, uint256 _price) public onlyOwnerOfStorage {
        mI.createMicroModule(_microModuleId);
        stringStorage[_b1("microModules", _microModuleId, "name")] = _name;
        uintStorage[_b1("microModules", _microModuleId, "itemType")] = _itemType;
        uintStorage[_b1("microModules", _microModuleId, "bonusType")] = _bonusType;
        uintStorage[_b1("microModules", _microModuleId, "bonus")] = _bonus;
        uintStorage[_b1("microModules", _microModuleId, "level")] = _level;
        uintStorage[_b1("microModules", _microModuleId, "price")] = _price;
    }

    // Artefacts
    function createArtefact(uint256 _artefactId, string _name, uint256 _itemType, uint256 _bonusType, uint256 _bonus) public onlyOwnerOfStorage {
        mI.createArtefact(_artefactId);
        stringStorage[_b1("artefacts", _artefactId, "name")] = _name;
        uintStorage[_b1("artefacts", _artefactId, "itemType")] = _itemType;
        uintStorage[_b1("artefacts", _artefactId, "bonusType")] = _bonusType;
        uintStorage[_b1("artefacts", _artefactId, "bonus")] = _bonus;
    }

    /* ------ DEV FUNCTIONS ------ */

    function setNewPriceToItem(string _itemType, uint256 _itemTypeId, uint256 _newPrice) public onlyLogicContract {
        uintStorage[_b1(_itemType, _itemTypeId, "price")] = _newPrice;
    }

    /* ------ CHANGE OWNERSHIP OF STORAGE ------ */

    function transferOwnershipOfStorage(address _newOwnerOfStorage) public onlyOwnerOfStorage {
        _transferOwnershipOfStorage(_newOwnerOfStorage);
    }

    function _transferOwnershipOfStorage(address _newOwnerOfStorage) private {
        require(_newOwnerOfStorage != address(0));
        ownerOfStorage = _newOwnerOfStorage;
    }

    /* ------ CHANGE LOGIC CONTRACT ADDRESS ------ */

    function changeLogicContractAddress(address _newLogicContractAddress) public onlyOwnerOfStorage {
        _changeLogicContractAddress(_newLogicContractAddress);
    }

    function _changeLogicContractAddress(address _newLogicContractAddress) private {
        require(_newLogicContractAddress != address(0));
        logicContractAddress = _newLogicContractAddress;
    }
}