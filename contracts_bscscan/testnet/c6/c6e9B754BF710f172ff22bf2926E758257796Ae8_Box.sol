// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Counters.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./NFT.sol";
import "./BoxDetails.sol";

contract Box {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using BoxDetails for BoxDetails.Details;

    Counters.Counter private _boxIdCounter;
    Counters.Counter private _epicBoxCounter;
    Counters.Counter private _legendBoxCounter;

    uint256 constant EPIC = 1;
    uint256 constant LEGEND = 2;

    uint256 constant BOX_BOUGHT = 1;
    uint256 constant BOX_OPENED = 2;

    bool private paused;
    address private owner;
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

    modifier onlyOwner() {
        require(owner == msg.sender, "NOT_OWNER_CONTRACT");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "PAUSED");
        _;
    }

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

    event SetAntiBoxTime(address _owner, uint256 _timesec);
    event WithdrawToken(address _owner, uint256 _amount);
    event AddBlacklist(address _user);
    event RemoveBlacklist(address _user);
    event SetBoxesPrice(uint256 _rarity, uint256 _price);

    constructor(
        address _placeverseToken,
        address _placeverse,
        uint256 _antiBotTime,
        uint256 _numberOfEpicSale,
        uint256 _numberOfLegendSale,
        uint256 _boxEpicPrice,
        uint256 _boxLegendPrice
    ) {
        placeverseToken = IERC20(_placeverseToken);
        pvsPlace = PlaceverseNFT(_placeverse);

        antiBotTime = _antiBotTime;

        boxEpicSale = _numberOfEpicSale;
        boxLegendSale = _numberOfLegendSale;

        boxEpicPrice = _boxEpicPrice;
        boxLegendPrice = _boxLegendPrice;

        owner = msg.sender;
    }

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

        require(placeverseToken.transferFrom(sender, address(this), boxEpicPrice));

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

        require(boughtLegend >= boxLegendPerUser, "LIMIT_BUY_LEGEND_BOX");
        require(_legendBoxCounter.current() < boxLegendSale, "SOLD_OUT");

        require(placeverseToken.transferFrom(sender, address(this), boxLegendPrice));

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

    function setAntiBotTime(uint256 timeSeconds) public onlyOwner {
        antiBotTime = timeSeconds;
        emit SetAntiBoxTime(owner, timeSeconds);
    }

    function setPaused(bool _paused) public onlyOwner {
        paused = _paused;
    }

    function setBoxEpicPrice(uint256 _boxEpicPrice) public onlyOwner {
        require(_boxEpicPrice > 0, "ZERO_BOX_EPIC_PRICE");
        boxEpicPrice = _boxEpicPrice;
    }

    function setBoxLegendPrice(uint256 _boxLegendPrice) public onlyOwner {
        require(_boxLegendPrice > 0, "ZERO_BOX_LEGEND_PRICE");
        boxLegendPrice = _boxLegendPrice;
    }

    function setBoxEpicSale(uint256 _boxEpicSale) public onlyOwner {
        require(
            _boxEpicSale > boxEpicSale,
            "BOX_EPIC_SALE_PARAMS_LARGER_REQUIRE"
        );
        boxEpicSale = _boxEpicSale;
    }

    function setBoxLegendSale(uint256 _boxLegendSale) public onlyOwner {
        require(
            _boxLegendSale > boxLegendSale,
            "BOX_LEGEND_SALE_PARAMS_SMARLLER_REQUIRE"
        );
        boxLegendSale = _boxLegendSale;
    }

    function withdrawToken() public onlyOwner {
        uint256 amount = placeverseToken.balanceOf(address(this));
        placeverseToken.transfer(msg.sender, amount);
        emit SetAntiBoxTime(owner, amount);
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
        for (uint256 i = 0; i < boxIds.length; i++) {
            bds[i] = boxDetails[boxIds[i]];
        }
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

    function getBoxEpicSale() public view returns(uint256) {
        return boxEpicSale;
    }

    function getBoxLegendSale() public view returns(uint256) {
        return boxLegendSale;
    }
}