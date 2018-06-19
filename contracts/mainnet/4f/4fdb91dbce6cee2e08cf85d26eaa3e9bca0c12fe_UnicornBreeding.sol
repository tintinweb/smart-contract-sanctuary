pragma solidity ^0.4.21;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}



contract UnicornManagementInterface {

    function ownerAddress() external view returns (address);
    function managerAddress() external view returns (address);
    function communityAddress() external view returns (address);
    function dividendManagerAddress() external view returns (address);
    function walletAddress() external view returns (address);
    function blackBoxAddress() external view returns (address);
    function unicornBreedingAddress() external view returns (address);
    function geneLabAddress() external view returns (address);
    function unicornTokenAddress() external view returns (address);
    function candyToken() external view returns (address);
    function candyPowerToken() external view returns (address);

    function createDividendPercent() external view returns (uint);
    function sellDividendPercent() external view returns (uint);
    function subFreezingPrice() external view returns (uint);
    function subFreezingTime() external view returns (uint64);
    function subTourFreezingPrice() external view returns (uint);
    function subTourFreezingTime() external view returns (uint64);
    function createUnicornPrice() external view returns (uint);
    function createUnicornPriceInCandy() external view returns (uint);
    function oraclizeFee() external view returns (uint);

    function paused() external view returns (bool);
    //    function locked() external view returns (bool);

    function isTournament(address _tournamentAddress) external view returns (bool);

    function getCreateUnicornFullPrice() external view returns (uint);
    function getHybridizationFullPrice(uint _price) external view returns (uint);
    function getSellUnicornFullPrice(uint _price) external view returns (uint);
    function getCreateUnicornFullPriceInCandy() external view returns (uint);


    //service
    function registerInit(address _contract) external;

}

contract ERC20 {
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
}

contract DividendManagerInterface {
    function payDividend() external payable;
}

contract BlackBoxInterface {
    function createGen0(uint _unicornId) public payable;
    function geneCore(uint _childUnicornId, uint _parent1UnicornId, uint _parent2UnicornId) public payable;
}

contract UnicornTokenInterface {

    //ERC721
    function balanceOf(address _owner) public view returns (uint256 _balance);
    function ownerOf(uint256 _unicornId) public view returns (address _owner);
    function transfer(address _to, uint256 _unicornId) public;
    function approve(address _to, uint256 _unicornId) public;
    function takeOwnership(uint256 _unicornId) public;
    function totalSupply() public constant returns (uint);
    function owns(address _claimant, uint256 _unicornId) public view returns (bool);
    function allowance(address _claimant, uint256 _unicornId) public view returns (bool);
    function transferFrom(address _from, address _to, uint256 _unicornId) public;

    //specific
    function createUnicorn(address _owner) external returns (uint);
    //    function burnUnicorn(uint256 _unicornId) external;
    function getGen(uint _unicornId) external view returns (bytes);
    function setGene(uint _unicornId, bytes _gene) external;
    function updateGene(uint _unicornId, bytes _gene) external;
    function getUnicornGenByte(uint _unicornId, uint _byteNo) external view returns (uint8);

    function setName(uint256 _unicornId, string _name ) external returns (bool);
    function plusFreezingTime(uint _unicornId) external;
    function plusTourFreezingTime(uint _unicornId) external;
    function minusFreezingTime(uint _unicornId, uint64 _time) external;
    function minusTourFreezingTime(uint _unicornId, uint64 _time) external;
    function isUnfreezed(uint _unicornId) external view returns (bool);
    function isTourUnfreezed(uint _unicornId) external view returns (bool);

    function marketTransfer(address _from, address _to, uint256 _unicornId) external;
}



contract UnicornAccessControl {

    UnicornManagementInterface public unicornManagement;

    function UnicornAccessControl(address _unicornManagementAddress) public {
        unicornManagement = UnicornManagementInterface(_unicornManagementAddress);
        unicornManagement.registerInit(this);
    }

    modifier onlyOwner() {
        require(msg.sender == unicornManagement.ownerAddress());
        _;
    }

    modifier onlyManager() {
        require(msg.sender == unicornManagement.managerAddress());
        _;
    }

    modifier onlyCommunity() {
        require(msg.sender == unicornManagement.communityAddress());
        _;
    }

    modifier onlyTournament() {
        require(unicornManagement.isTournament(msg.sender));
        _;
    }

    modifier whenNotPaused() {
        require(!unicornManagement.paused());
        _;
    }

    modifier whenPaused {
        require(unicornManagement.paused());
        _;
    }


    modifier onlyManagement() {
        require(msg.sender == address(unicornManagement));
        _;
    }

    modifier onlyBreeding() {
        require(msg.sender == unicornManagement.unicornBreedingAddress());
        _;
    }

    modifier onlyGeneLab() {
        require(msg.sender == unicornManagement.geneLabAddress());
        _;
    }

    modifier onlyBlackBox() {
        require(msg.sender == unicornManagement.blackBoxAddress());
        _;
    }

    modifier onlyUnicornToken() {
        require(msg.sender == unicornManagement.unicornTokenAddress());
        _;
    }

    function isGamePaused() external view returns (bool) {
        return unicornManagement.paused();
    }
}

contract UnicornBreeding is UnicornAccessControl {
    using SafeMath for uint;
    //onlyOwner
    UnicornTokenInterface public unicornToken; //only on deploy
    BlackBoxInterface public blackBox;

    event HybridizationAdd(uint indexed unicornId, uint price);
    event HybridizationAccept(uint indexed firstUnicornId, uint indexed secondUnicornId, uint newUnicornId);
    event HybridizationDelete(uint indexed unicornId);
    event FundsTransferred(address dividendManager, uint value);
    event CreateUnicorn(address indexed owner, uint indexed unicornId, uint parent1, uint  parent2);
    event NewGen0Limit(uint limit);
    event NewGen0Step(uint step);


    event OfferAdd(uint256 indexed unicornId, uint price);
    event OfferDelete(uint256 indexed unicornId);
    event UnicornSold(uint256 indexed unicornId);

    ERC20 public candyToken;
    ERC20 public candyPowerToken;

    //counter for gen0
    uint public gen0Limit = 30000;
    uint public gen0Count = 0;
    uint public gen0Step = 1000;

    //counter for presale gen0
    uint public gen0PresaleLimit = 1000;
    uint public gen0PresaleCount = 0;

    struct Hybridization{
        uint listIndex;
        uint price;
        bool exists;
    }

    // Mapping from unicorn ID to Hybridization struct
    mapping (uint => Hybridization) public hybridizations;
    mapping(uint => uint) public hybridizationList;
    uint public hybridizationListSize = 0;


    function() public payable {

    }

    function UnicornBreeding(address _unicornManagementAddress) UnicornAccessControl(_unicornManagementAddress) public {
        candyToken = ERC20(unicornManagement.candyToken());

    }

    function init() onlyManagement whenPaused external {
        unicornToken = UnicornTokenInterface(unicornManagement.unicornTokenAddress());
        blackBox = BlackBoxInterface(unicornManagement.blackBoxAddress());
        candyPowerToken = ERC20(unicornManagement.candyPowerToken());
    }

    function makeHybridization(uint _unicornId, uint _price) public {
        require(unicornToken.owns(msg.sender, _unicornId));
        require(unicornToken.isUnfreezed(_unicornId));
        require(!hybridizations[_unicornId].exists);

        hybridizations[_unicornId] = Hybridization({
            price: _price,
            exists: true,
            listIndex: hybridizationListSize
            });
        hybridizationList[hybridizationListSize++] = _unicornId;

        emit HybridizationAdd(_unicornId, _price);
    }


    function acceptHybridization(uint _firstUnicornId, uint _secondUnicornId) whenNotPaused public payable {
        require(unicornToken.owns(msg.sender, _secondUnicornId));
        require(_secondUnicornId != _firstUnicornId);
        require(unicornToken.isUnfreezed(_firstUnicornId) && unicornToken.isUnfreezed(_secondUnicornId));
        require(hybridizations[_firstUnicornId].exists);
        require(msg.value == unicornManagement.oraclizeFee());
        if (hybridizations[_firstUnicornId].price > 0) {
            require(candyToken.transferFrom(msg.sender, this, getHybridizationPrice(_firstUnicornId)));
        }

        plusFreezingTime(_secondUnicornId);
        uint256 newUnicornId = unicornToken.createUnicorn(msg.sender);
        blackBox.geneCore.value(unicornManagement.oraclizeFee())(newUnicornId, _firstUnicornId, _secondUnicornId);
        emit CreateUnicorn(msg.sender, newUnicornId, _firstUnicornId, _secondUnicornId);
        if (hybridizations[_firstUnicornId].price > 0) {
            candyToken.transfer(unicornToken.ownerOf(_firstUnicornId), hybridizations[_firstUnicornId].price);
        }
        emit HybridizationAccept(_firstUnicornId, _secondUnicornId, newUnicornId);
        _deleteHybridization(_firstUnicornId);
    }


    function cancelHybridization (uint _unicornId) public {
        require(unicornToken.owns(msg.sender,_unicornId));
        require(hybridizations[_unicornId].exists);
        _deleteHybridization(_unicornId);
    }

    function deleteHybridization(uint _unicornId) onlyUnicornToken external {
        _deleteHybridization(_unicornId);
    }

    function _deleteHybridization(uint _unicornId) internal {
        if (hybridizations[_unicornId].exists) {
            hybridizations[hybridizationList[--hybridizationListSize]].listIndex = hybridizations[_unicornId].listIndex;
            hybridizationList[hybridizations[_unicornId].listIndex] = hybridizationList[hybridizationListSize];
            delete hybridizationList[hybridizationListSize];
            delete hybridizations[_unicornId];
            emit HybridizationDelete(_unicornId);
        }
    }

    //Create new 0 gen
    function createUnicorn() public payable whenNotPaused returns(uint256)   {
        require(msg.value == getCreateUnicornPrice());
        return _createUnicorn(msg.sender);
    }

    function createUnicornForCandy() public payable whenNotPaused returns(uint256)   {
        require(msg.value == unicornManagement.oraclizeFee());
        require(candyToken.transferFrom(msg.sender, this, getCreateUnicornPriceInCandy()));
        return _createUnicorn(msg.sender);
    }

    function createPresaleUnicorns(uint _count, address _owner) public payable onlyManager whenPaused returns(bool) {
        require(gen0PresaleCount.add(_count) <= gen0PresaleLimit);
        uint256 newUnicornId;
        address owner = _owner == address(0) ? msg.sender : _owner;
        for (uint i = 0; i < _count; i++){
            newUnicornId = unicornToken.createUnicorn(owner);
            blackBox.createGen0(newUnicornId);
            emit CreateUnicorn(owner, newUnicornId, 0, 0);
            gen0Count = gen0Count.add(1);
            gen0PresaleCount = gen0PresaleCount.add(1);
        }
        return true;
    }

    function _createUnicorn(address _owner) private returns(uint256) {
        require(gen0Count < gen0Limit);
        uint256 newUnicornId = unicornToken.createUnicorn(_owner);
        blackBox.createGen0.value(unicornManagement.oraclizeFee())(newUnicornId);
        emit CreateUnicorn(_owner, newUnicornId, 0, 0);
        gen0Count = gen0Count.add(1);
        return newUnicornId;
    }

    function plusFreezingTime(uint _unicornId) private {
        unicornToken.plusFreezingTime(_unicornId);
    }

    function plusTourFreezingTime(uint _unicornId) onlyTournament public {
        unicornToken.plusTourFreezingTime(_unicornId);
    }

    //change freezing time for candy
    function minusFreezingTime(uint _unicornId) public {
        require(candyPowerToken.transferFrom(msg.sender, this, unicornManagement.subFreezingPrice()));
        unicornToken.minusFreezingTime(_unicornId, unicornManagement.subFreezingTime());
    }

    //change tour freezing time for candy
    function minusTourFreezingTime(uint _unicornId) public {
        require(candyPowerToken.transferFrom(msg.sender, this, unicornManagement.subTourFreezingPrice()));
        unicornToken.minusTourFreezingTime(_unicornId, unicornManagement.subTourFreezingTime());
    }

    function getHybridizationPrice(uint _unicornId) public view returns (uint) {
        return unicornManagement.getHybridizationFullPrice(hybridizations[_unicornId].price);
    }

    function getEtherFeeForPriceInCandy() public view returns (uint) {
        return unicornManagement.oraclizeFee();
    }

    function getCreateUnicornPriceInCandy() public view returns (uint) {
        return unicornManagement.getCreateUnicornFullPriceInCandy();
    }


    function getCreateUnicornPrice() public view returns (uint) {
        return unicornManagement.getCreateUnicornFullPrice();
    }


    function withdrawTokens() onlyManager public {
        require(candyToken.balanceOf(this) > 0 || candyPowerToken.balanceOf(this) > 0);
        if (candyToken.balanceOf(this) > 0) {
            candyToken.transfer(unicornManagement.walletAddress(), candyToken.balanceOf(this));
        }
        if (candyPowerToken.balanceOf(this) > 0) {
            candyPowerToken.transfer(unicornManagement.walletAddress(), candyPowerToken.balanceOf(this));
        }
    }


    function transferEthersToDividendManager(uint _value) onlyManager public {
        require(address(this).balance >= _value);
        DividendManagerInterface dividendManager = DividendManagerInterface(unicornManagement.dividendManagerAddress());
        dividendManager.payDividend.value(_value)();
        emit FundsTransferred(unicornManagement.dividendManagerAddress(), _value);
    }


    function setGen0Limit() external onlyCommunity {
        require(gen0Count == gen0Limit);
        gen0Limit = gen0Limit.add(gen0Step);
        emit NewGen0Limit(gen0Limit);
    }

    function setGen0Step(uint _step) external onlyCommunity {
        gen0Step = _step;
        emit NewGen0Step(gen0Limit);
    }





    ////MARKET
    struct Offer{
        uint marketIndex;
        uint price;
        bool exists;
    }

    // Mapping from unicorn ID to Offer struct
    mapping (uint => Offer) public offers;
    // market index => offerId
    mapping(uint => uint) public market;
    uint public marketSize = 0;


    function sellUnicorn(uint _unicornId, uint _price) public {
        require(unicornToken.owns(msg.sender, _unicornId));
        require(!offers[_unicornId].exists);

        offers[_unicornId] = Offer({
            price: _price,
            exists: true,
            marketIndex: marketSize
            });

        market[marketSize++] = _unicornId;

        emit OfferAdd(_unicornId, _price);
    }


    function buyUnicorn(uint _unicornId) public payable {
        require(offers[_unicornId].exists);
        uint price = offers[_unicornId].price;
        require(msg.value == unicornManagement.getSellUnicornFullPrice(price));

        address owner = unicornToken.ownerOf(_unicornId);

        emit UnicornSold(_unicornId);
        //deleteoffer вызовется внутри transfer
        unicornToken.marketTransfer(owner, msg.sender, _unicornId);
        owner.transfer(price);
//        _deleteOffer(_unicornId);
    }


    function revokeUnicorn(uint _unicornId) public {
        require(unicornToken.owns(msg.sender, _unicornId));
        require(offers[_unicornId].exists);
        _deleteOffer(_unicornId);
    }


    function deleteOffer(uint _unicornId) onlyUnicornToken external {
        _deleteOffer(_unicornId);
    }


    function _deleteOffer(uint _unicornId) internal {
        if (offers[_unicornId].exists) {
            offers[market[--marketSize]].marketIndex = offers[_unicornId].marketIndex;
            market[offers[_unicornId].marketIndex] = market[marketSize];
            delete market[marketSize];
            delete offers[_unicornId];
            emit OfferDelete(_unicornId);
        }
    }

    function getOfferPrice(uint _unicornId) public view returns (uint) {
        return unicornManagement.getSellUnicornFullPrice(offers[_unicornId].price);
    }

}