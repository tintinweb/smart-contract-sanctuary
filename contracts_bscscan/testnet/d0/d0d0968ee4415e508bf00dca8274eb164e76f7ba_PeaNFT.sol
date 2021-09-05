// SPDX-License-Identifier: UNLICENSED
import "./SafeMath.sol";
import "./EnumerableSet.sol";
import "./ERC721.sol";
import "./PeaManager.sol";
import "./PeanToken.sol";

pragma solidity ^0.7.6;
pragma abicoder v2;

contract PeaNFT is PeaManager, ERC721 {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    enum Level {
        __KEY,
        ARCHER,
        FIGHTER,
        DESTROYER,
        WANDERER,
        TEMPLAR
    }
    struct Pean {
        Level level;
        uint256 exp;
        uint256 bornAt;
    }

    event Buy(
        uint256 indexed tokenId,
        address buyer,
        address seller,
        uint256 price
    );
    event PlaceOrder(uint256 indexed tokenId, address seller, uint256 price);
    event EXP(uint256 indexed tokenId, address owner, uint256 exp);
    event CancelOrder(uint256 indexed tokenId, address seller);

    struct ItemSale {
        uint256 tokenId;
        address owner;
        uint256 price;
    }
    mapping(uint256 => Pean) internal peans;
    mapping(uint256 => ItemSale) internal markets;

    EnumerableSet.UintSet private tokenSales;
    mapping(address => EnumerableSet.UintSet) private sellerTokens;

    event Gem(uint256 indexed tokenId, address to);
    event CrackGem(uint256 indexed tokenId, Level level);

    PeanToken public peanToken;

    constructor(
        string memory _name,
        string memory _symbol,
        address _manager,
        address _peanToken
    ) ERC721(_name, _symbol, _manager) PeaManager(_manager) {
        _setBaseURI("ipfs://");
        peanToken = PeanToken(_peanToken);
    }

    modifier notKey(uint256 _tokenId) {
        require(peans[_tokenId].level != Level.__KEY, "not same key level");
        _;
    }

    function _mint(address to, uint256 tokenId) internal override(ERC721) {
        super._mint(to, tokenId);

        _incrementTokenId();
    }

    function gem(address _to_address) public onlyGemer(_to_address) {
        uint256 nextTokenId = _getNextTokenId();
        _mint(_to_address, nextTokenId);

        peans[nextTokenId] = Pean({
            level: Level.__KEY,
            exp: 0,
            bornAt: block.timestamp
        });

        emit Gem(nextTokenId, _to_address);
    }

    function upExp(
        uint256 _tokenId,
        address _owner,
        uint256 _exp
    ) public onlyGemer(_owner) {
        require(_exp > 0, "require: non zero exp");
        Pean storage pean = peans[_tokenId];
        pean.exp = pean.exp.add(_exp);
        emit EXP(_tokenId, _owner, _exp);
    }

    function crackGem(
        uint256 _tokenId,
        address _owner,
        Level _level
    ) public onlyGemer(_owner) {
        require(ownerOf(_tokenId) == _owner, "require: owner KEY");
        Pean storage pean = peans[_tokenId];
        require(pean.level == Level.__KEY, "require: level KEY");
        require(_level != Level.__KEY, "require: upgrade Pean");

        pean.bornAt = block.timestamp;
        pean.level = _level;

        emit CrackGem(_tokenId, pean.level);
    }

    function multiGem(address _to_address, uint256 amount) public onlyGemer(_to_address) {
        require(amount > 1, "require: multiple");
        for (uint256 index = 0; index < amount; index++) {
            gem(_to_address);
        }
    }

    /**
     * @dev calculates the next token ID based on value of latestTokenId
     * @return uint256 for the next token ID
     */
    function _getNextTokenId() private view returns (uint256) {
        return latestTokenId.add(1);
    }

    /**
     * @dev increments the value of latestTokenId
     */
    function _incrementTokenId() private {
        latestTokenId++;
    }

    function getPean(uint256 _tokenId) public view returns (Pean memory) {
        return peans[_tokenId];
    }

    function placeOrder(uint256 _tokenId, uint256 _price)
        public
        notKey(_tokenId)
    {
        require(ownerOf(_tokenId) == _msgSender(), "Only owner can sell");
        require(_price > 0, "Cannot sell without fee");
        transferFrom(_msgSender(), address(this), _tokenId);

        tokenSales.add(_tokenId);
        sellerTokens[_msgSender()].add(_tokenId);

        markets[_tokenId] = ItemSale({
            tokenId: _tokenId,
            price: _price,
            owner: _msgSender()
        });

        emit PlaceOrder(_tokenId, _msgSender(), _price);
    }

    function marketsSize() public view returns (uint256) {
        return tokenSales.length();
    }

    function orders(address _seller) public view returns (uint256) {
        return sellerTokens[_seller].length();
    }

    function cancelOrder(uint256 _tokenId) public {
        require(tokenSales.contains(_tokenId), "not sale");
        ItemSale storage itemSale = markets[_tokenId];
        require(itemSale.owner == _msgSender(), "Only owner can cancel");
        transferFrom(address(this), _msgSender(), _tokenId);

        tokenSales.remove(_tokenId);
        sellerTokens[itemSale.owner].remove(_tokenId);
        markets[_tokenId] = ItemSale({tokenId: 0, price: 0, owner: address(0)});

        emit CancelOrder(_tokenId, _msgSender());
    }

    function fillOrder(uint256 _tokenId) public {
        require(tokenSales.contains(_tokenId), "not sale");
        ItemSale storage itemSale = markets[_tokenId];
        uint256 feeMarket = itemSale.price.mul(router.feeMarket()).div(
            router.divPercent()
        );
        peanToken.transferFrom(_msgSender(), router.feeAddress(), feeMarket);
        peanToken.transferFrom(
            _msgSender(),
            itemSale.owner,
            itemSale.price.sub(feeMarket)
        );

        transferFrom(address(this), _msgSender(), _tokenId);

        tokenSales.remove(_tokenId);
        sellerTokens[itemSale.owner].remove(_tokenId);
        markets[_tokenId] = ItemSale({tokenId: 0, price: 0, owner: address(0)});

        emit CancelOrder(_tokenId, _msgSender());
    }

    function tokenSaleByIndex(uint256 index) public view returns (uint256) {
        return tokenSales.at(index);
    }

    function tokenSaleOfOwnerByIndex(address _seller, uint256 index)
        public
        view
        returns (uint256)
    {
        return sellerTokens[_seller].at(index);
    }

    function orderSale(uint256 _tokenId) public view returns (ItemSale memory) {
        if (tokenSales.contains(_tokenId)) return markets[_tokenId];
        return ItemSale({tokenId: 0, owner: address(0), price: 0});
    }
}