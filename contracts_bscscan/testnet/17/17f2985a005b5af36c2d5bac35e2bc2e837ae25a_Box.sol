// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "./PausableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./Counters.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./NFT.sol";
import "./BoxDetails.sol";

contract Box is
    Initializable,
    UUPSUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable
{
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using BoxDetails for BoxDetails.Details;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    Counters.Counter private _boxIdCounter;
    Counters.Counter private _epicBoxCounter;
    Counters.Counter private _legendBoxCounter;

    uint256 constant EPIC = 1;
    uint256 constant LEGEND = 2;

    uint256 constant BOX_BOUGHT = 1;
    uint256 constant BOX_OPENED = 2;
    uint256 constant BOX_DESTROY = 3; // For use-case the box is canceled

    uint256 private antiBotTime; // seconds

    uint256 private boxEpicSale;
    uint256 private boxLegendSale;

    uint256 private boxEpicPrice;
    uint256 private boxLegendPrice;

    uint256 private boxLegendPerUser;

    IERC20 placeverseToken;
    PlaceverseNFT pvsPlace;

    // cache last time user by box
    mapping(address => uint256) private lastBuyEpic;
    mapping(uint256 => uint256) private boxDetails;
    mapping(address => uint256[]) private boxByAddress;
    mapping(address => uint256) private boxLegendBought;
    uint256[] private detroyBoxes;

    event BuyBox(
        address _buyer,
        uint256 _boxId,
        uint256 _amount,
        uint256 _boughtAt,
        uint256 _rarity,
        bytes32 _hash
    );

    event OpenBox(
        address _buyer,
        uint256 _boxId,
        uint256 _tokenId,
        bytes32 _boxHash,
        string _placeId,
        string _uri,
        uint256 _openAt
    );

    event SetAntiBoxTime(address _operator, uint256 _timesec);
    event WithdrawToken(address _owner, uint256 _amount);
    event AddBlacklist(address _opearator, address _user);
    event RemoveBlacklist(address _user);
    event SetBoxesPrice(uint256 _rarity, uint256 _price);
    event DetroyBox(address _operator, uint256 _boxId);
    event SetBoxLegendPerUser(uint256 _boxLegendPerUser);
    event SetBoxEpicPrice(address _operator, uint256 _boxEpicPrice);
    event SetBoxLegendPrice(address _operator, uint256 _boxLegendPrice);
    event SetBoxEpicSale(address _operator, uint256 _boxEpicSale);
    event SetBoxLegendSale(address _operator, uint256 _boxLegendSale);

    function initialize(
        address _owner,
        address _placeverseToken,
        address _placeverse,
        uint256 _antiBotTime,
        uint256 _numberOfEpicSale,
        uint256 _numberOfLegendSale,
        uint256 _boxEpicPrice,
        uint256 _boxLegendPrice,
        uint256 _boxLegendPerUser
    ) public initializer {
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _owner);

        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);

        placeverseToken = IERC20(_placeverseToken);
        pvsPlace = PlaceverseNFT(_placeverse);

        antiBotTime = _antiBotTime;

        boxEpicSale = _numberOfEpicSale;
        boxLegendSale = _numberOfLegendSale;

        boxEpicPrice = _boxEpicPrice;
        boxLegendPrice = _boxLegendPrice;
        boxLegendPerUser = _boxLegendPerUser;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function transferAdmin(address _admin) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_admin != address(0), "ZERO_ADDRESS");
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}

    /**
     * @dev buy box
     * boxStatus: 1. BOUGHT, 2. OPEN
     */
    function buyEpicBox() public whenNotPaused {
        address sender = msg.sender;
        require(_epicBoxCounter.current() < boxEpicSale, "SOLD_OUT");
        require(
            block.timestamp - lastBuyEpic[sender] > antiBotTime,
            "LOCK_ANTI_BOT"
        );

        require(
            placeverseToken.transferFrom(sender, address(this), boxEpicPrice)
        );

        _epicBoxCounter.increment();
        _boxIdCounter.increment();

        uint256 boxId = _boxIdCounter.current();
        uint256 boughtAt = block.timestamp;
        uint256 boxDetail = BoxDetails.encode(
            BoxDetails.Details(boxId, BOX_BOUGHT, boughtAt, 0, EPIC, 0)
        );

        boxDetails[boxId] = boxDetail;
        boxByAddress[sender].push(boxId);
        lastBuyEpic[sender] = boughtAt;

        emit BuyBox(
            sender,
            boxId,
            boxEpicPrice,
            boughtAt,
            EPIC,
            BoxDetails.hash(boxDetail, sender)
        );
    }

    /**
     * @dev buy box
     */
    function buyLegendBox() public whenNotPaused {
        address sender = msg.sender;
        uint256 boughtLegend = boxLegendBought[sender];

        require(boughtLegend < boxLegendPerUser, "LIMIT_BUY_LEGEND_BOX");
        require(_legendBoxCounter.current() < boxLegendSale, "SOLD_OUT");

        require(
            placeverseToken.transferFrom(sender, address(this), boxLegendPrice)
        );

        boxLegendBought[sender] = boughtLegend.add(1);

        _legendBoxCounter.increment();
        _boxIdCounter.increment();
        uint256 boxId = _boxIdCounter.current();

        uint256 boughtAt = block.timestamp;
        uint256 boxDetail = BoxDetails.encode(
            BoxDetails.Details(boxId, BOX_BOUGHT, boughtAt, 0, LEGEND, 0)
        );

        boxDetails[boxId] = boxDetail;
        boxByAddress[sender].push(boxId);

        emit BuyBox(
            sender,
            boxId,
            boxEpicPrice,
            boughtAt,
            LEGEND,
            BoxDetails.hash(boxDetail, sender)
        );
    }

    function openBox(
        uint256 _boxId,
        bytes32 _boxHash,
        string memory _placeId,
        string memory _uri
    ) public whenNotPaused {
        address sender = msg.sender;
        uint256 boxDetail = boxDetails[_boxId];
        require(
            BoxDetails.hash(boxDetail, sender) == _boxHash,
            "INVALID_BOX_HASH"
        );
        uint256 rarity = BoxDetails.decodeRarity(boxDetail);
        uint256 tokenId = pvsPlace.mintByAdmin(sender, _uri, rarity, _placeId);
        require(tokenId > 0, "ZERO_TOKENID");
        uint256 openAt = block.timestamp;

        boxDetail = BoxDetails.updateStatus(boxDetail, BOX_OPENED);
        boxDetail = BoxDetails.updateOpenAt(boxDetail, openAt);
        boxDetail = BoxDetails.updateTokenId(boxDetail, tokenId);

        boxDetails[_boxId] = boxDetail;

        emit OpenBox(sender, _boxId, tokenId, _boxHash, _placeId, _uri, openAt);
    }

    function detroyBox(uint256 _boxId) public onlyRole(OPERATOR_ROLE) {
        uint256 boxDetail = boxDetails[_boxId];
        uint256 status = BoxDetails.decodeStatus(boxDetail);
        require(status == BOX_BOUGHT, "INVALID_BOX_STATUS");

        boxDetail = BoxDetails.updateStatus(boxDetail, BOX_DESTROY);
        boxDetails[_boxId] = boxDetail;

        detroyBoxes.push(_boxId);
        emit DetroyBox(msg.sender, _boxId);
    }

    function setAntiBotTime(uint256 timeSeconds)
        public
        onlyRole(OPERATOR_ROLE)
    {
        antiBotTime = timeSeconds;
        emit SetAntiBoxTime(msg.sender, timeSeconds);
    }

    function setBoxEpicPrice(uint256 _boxEpicPrice)
        public
        onlyRole(OPERATOR_ROLE)
    {
        require(_boxEpicPrice > 0, "ZERO_BOX_EPIC_PRICE");
        boxEpicPrice = _boxEpicPrice;
        emit SetBoxEpicPrice(msg.sender, _boxEpicPrice);
    }

    function setBoxLegendPrice(uint256 _boxLegendPrice)
        public
        onlyRole(OPERATOR_ROLE)
    {
        require(_boxLegendPrice > 0, "ZERO_BOX_LEGEND_PRICE");
        boxLegendPrice = _boxLegendPrice;
        emit SetBoxLegendPrice(msg.sender, _boxLegendPrice);
    }

    function setBoxEpicSale(uint256 _boxEpicSale)
        public
        onlyRole(OPERATOR_ROLE)
    {
        require(
            _boxEpicSale > boxEpicSale,
            "BOX_EPIC_SALE_PARAMS_LARGER_REQUIRE"
        );
        boxEpicSale = _boxEpicSale;
        emit SetBoxEpicSale(msg.sender, _boxEpicSale);
    }

    function setBoxLegendSale(uint256 _boxLegendSale)
        public
        onlyRole(OPERATOR_ROLE)
    {
        require(
            _boxLegendSale > boxLegendSale,
            "BOX_LEGEND_SALE_PARAMS_SMARLLER_REQUIRE"
        );
        boxLegendSale = _boxLegendSale;
        emit SetBoxLegendSale(msg.sender, _boxLegendSale);
    }

    function setBoxLegendPerUser(uint256 _boxLegendPerUser)
        public
        onlyRole(OPERATOR_ROLE)
    {
        boxLegendPerUser = _boxLegendPerUser;
        emit SetBoxLegendPerUser(_boxLegendPerUser);
    }

    function withdrawToken() public onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 amount = placeverseToken.balanceOf(address(this));
        placeverseToken.transfer(msg.sender, amount);
        emit WithdrawToken(msg.sender, amount);
    }

    function getEpicBoxBought() public view returns (uint256) {
        return _epicBoxCounter.current();
    }

    function getLegendBoxBought() public view returns (uint256) {
        return _legendBoxCounter.current();
    }

    function getBoxDetails(uint256 _boxId)
        public
        view
        returns (BoxDetails.Details memory)
    {
        uint256 boxDetail = boxDetails[_boxId];
        require(boxDetail > 0, "BOX_NOT_FOUND");
        return BoxDetails.decode(boxDetail);
    }

    function getBoxesByUser(address _user)
        public
        view
        returns (uint256[] memory)
    {
        require(_user != address(0), "ZERO_ADDRESS");
        uint256[] memory boxIds = boxByAddress[_user];
        require(boxIds.length > 0, "BOX_NOT_FOUND");
        uint256[] memory bds = new uint256[](boxIds.length);
        for (uint256 i = 0; i < boxIds.length; i++)
            bds[i] = boxDetails[boxIds[i]];

        return bds;
    }

    function getAntiBotTime() public view returns (uint256) {
        return antiBotTime;
    }

    function getBoxEpicPrice() public view returns (uint256) {
        return boxEpicPrice;
    }

    function getBoxLegendPrice() public view returns (uint256) {
        return boxLegendPrice;
    }

    function getBoxEpicSale() public view returns (uint256) {
        return boxEpicSale;
    }

    function getBoxLegendSale() public view returns (uint256) {
        return boxLegendSale;
    }

    function getDetroyBoxes() public view returns (uint256[] memory) {
        return detroyBoxes;
    }

    function version() public pure returns (string memory) {
        return "v1.0!";
    }
}