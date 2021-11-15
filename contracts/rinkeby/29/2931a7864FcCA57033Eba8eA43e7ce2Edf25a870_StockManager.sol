pragma solidity ^0.7.0;

contract StockManager {
    mapping(uint256 => uint256) maxStock;
    mapping(uint256 => uint256) currentCounter;
    mapping(uint256 => uint256) price;
    mapping(uint256 => uint256) numberOfOut;
    mapping(uint256 => uint256) idToType; // 0 or 1
    mapping(uint256 => bool) packExists;
    mapping(uint256 => address) public paymentType;
    mapping(uint256 => bool) packAvailable;
    mapping(uint256 => Boundaries) public packToBoundaries;

    struct Boundaries {
        uint256 min;
        uint256 max;
    }

    uint256 packIdCounter;

    address private owner;
    address private father;

    event PackCreated(
        uint256 packId,
        uint256 maxStock,
        uint256 packType,
        uint256 price,
        uint256 min,
        uint256 max
    );

    constructor(address _owner, address _tokenFactory) {
        owner = _owner;
        father = _tokenFactory;
        packIdCounter = 1;
    }

    modifier requireFather() {
        require(msg.sender == father, "NFN");
        _;
    }

    modifier requireOwner() {
        require(msg.sender == owner, "NWN");
        _;
    }

    modifier requireExists(uint256 packId) {
        require(packExists[packId], "NEXST");
        _;
    }

    modifier requireAvailable(uint256 packId) {
        require(packAvailable[packId], "NAVLB");
        _;
    }

    function getAvailablePacks() external view returns (uint256[] memory) {
        uint256[] memory available = new uint256[](packIdCounter);
        uint256 z = 0;
        for (uint256 i = 0; i < packIdCounter; i++) {
            if (packAvailable[i]) {
                available[z] = i;
                z = z + 1;
            }
        }
        return available;
    }

    function getPackInfoByAddresses(uint256[] calldata idList)
        external
        view
        returns (
            uint256[] memory _list_maxStock,
            uint256[] memory _list_currentCounter,
            uint256[] memory _list_price,
            uint256[] memory _list_numberOut,
            uint256[] memory _list_type
        )
    {
        _list_maxStock = new uint256[](idList.length);
        _list_currentCounter = new uint256[](idList.length);
        _list_price = new uint256[](idList.length);
        _list_numberOut = new uint256[](idList.length);
        _list_type = new uint256[](idList.length);

        for (uint256 i = 0; i < idList.length; i++) {
            _list_maxStock[i] = maxStock[idList[i]];
            _list_currentCounter[i] = currentCounter[idList[i]];
            _list_price[i] = price[idList[i]];
            _list_numberOut[i] = numberOfOut[idList[i]];
            _list_type[i] = idToType[idList[i]];
        }

        return (
            _list_maxStock,
            _list_currentCounter,
            _list_price,
            _list_numberOut,
            _list_type
        );
    }

    function createPack(
        uint256 _maxStock,
        uint256 _numberOut,
        uint256 _type,
        uint256 _price,
        uint256 _min,
        uint256 _max,
        address _paymentType
    ) external requireOwner {
        uint256 _id = packIdCounter;
        packExists[_id] = true;
        maxStock[_id] = _maxStock;
        packAvailable[_id] = true;
        idToType[_id] = _type;
        numberOfOut[_id] = _numberOut;
        price[_id] = _price;
        currentCounter[_id] = 1;
        paymentType[_id] = _paymentType;
        packToBoundaries[_id] = Boundaries(_min, _max);
        emit PackCreated(packIdCounter, _maxStock, _type, _price, _min, _max);
        packIdCounter = packIdCounter + 1;
    }

    function getTypeOf(uint256 id)
        external
        view
        requireExists(id)
        returns (uint256)
    {
        return idToType[id];
    }

    function getMaxStockOf(uint256 id)
        external
        view
        requireExists(id)
        returns (uint256)
    {
        return maxStock[id];
    }

    function getCurrentCounterOf(uint256 id)
        external
        view
        requireExists(id)
        returns (uint256)
    {
        return currentCounter[id];
    }

    function getPriceOf(uint256 id)
        external
        view
        requireExists(id)
        returns (uint256)
    {
        return price[id];
    }

    function getNumberOfOut(uint256 id)
        external
        view
        requireExists(id)
        returns (uint256)
    {
        return numberOfOut[id];
    }

    function setPriceOf(uint256 id, uint256 _price)
        external
        requireExists(id)
        requireOwner
    {
        price[id] = _price;
    }

    function setMaxMin(
        uint256 _id,
        uint256 _min,
        uint256 _max
    ) external requireExists(_id) requireOwner {
        packToBoundaries[_id] = Boundaries(_min, _max);
    }

    function setPaymentTypeOf(uint256 id, address _paymentType)
        external
        requireExists(id)
        requireOwner
    {
        paymentType[id] = _paymentType;
    }

    function setMaxStockOf(uint256 id, uint256 max)
        external
        requireExists(id)
        requireOwner
    {
        maxStock[id] = max;
    }

    function setNumberOutOf(uint256 id, uint256 _numberof)
        external
        requireExists(id)
        requireOwner
    {
        numberOfOut[id] = _numberof;
    }

    function setTypeOf(uint256 id, uint256 _type)
        external
        requireExists(id)
        requireOwner
    {
        idToType[id] = _type % 2;
    }

    function setAvailableOf(uint256 id, bool _avab)
        external
        requireExists(id)
        requireOwner
    {
        packAvailable[id] = _avab;
    }

    function increaseCounter(uint256 id)
        external
        requireFather
        requireExists(id)
        requireAvailable(id)
        returns (bool)
    {
        currentCounter[id] = currentCounter[id] + 1;
        return true;
    }

    function availableStock(uint256 id)
        external
        view
        requireExists(id)
        returns (bool)
    {
        uint256 max = maxStock[id];
        uint256 current = currentCounter[id];
        uint256 included = numberOfOut[id];
        if (current - 1 + included <= max) return true;
        return false;
    }
}

