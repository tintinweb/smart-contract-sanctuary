// SPDX-License-Identifier: UNLICENSED
import "./IERC20.sol";
import "./IERC721.sol";
import "./SafeMath.sol";
import "./EnumerableSet.sol";

pragma solidity ^0.7.6;
pragma abicoder v2;

interface IPeaManager {
    function divPercent() external view returns (uint256);

    function feeMarket() external view returns (uint256);

    function feeAddress() external view returns (address);
}

interface PeaNFT is IERC721 {
    struct Pean {
        uint256 champ;
        uint256 level;
        uint256 exp;
        uint256 bornAt;
    }

    function getPean(uint256) external view returns (Pean memory);
}

contract PeaMarket {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    event Buy(
        uint256 indexed tokenId,
        address buyer,
        address seller,
        uint256 price
    );
    event PlaceOrder(uint256 indexed tokenId, address seller, uint256 price);
    event CancelOrder(uint256 indexed tokenId, address seller);

    struct ItemSale {
        uint256 tokenId;
        address owner;
        uint256 price;
    }
    mapping(uint256 => ItemSale) internal markets;

    EnumerableSet.UintSet private tokenSales;
    mapping(address => EnumerableSet.UintSet) private sellerTokens;

    IERC20 public peaToken;
    PeaNFT public peaNFT;
    IPeaManager public router;

    constructor(
        address _manager,
        address _peaToken,
        address _peaNFT
    ) {
        peaToken = IERC20(_peaToken);
        peaNFT = PeaNFT(_peaNFT);
        router = IPeaManager(_manager);
    }

    modifier notGem(uint256 _tokenId) {
        require(peaNFT.getPean(_tokenId).champ != 0, "can't sell Gem");
        _;
    }

    function placeOrder(uint256 _tokenId, uint256 _price)
        public
        notGem(_tokenId)
    {
        require(peaNFT.ownerOf(_tokenId) == msg.sender, "Only owner can sell");
        require(_price > 0, "Cannot sell without fee");
        peaNFT.transferFrom(msg.sender, address(this), _tokenId);

        tokenSales.add(_tokenId);
        sellerTokens[msg.sender].add(_tokenId);

        markets[_tokenId] = ItemSale({
            tokenId: _tokenId,
            price: _price,
            owner: msg.sender
        });

        emit PlaceOrder(_tokenId, msg.sender, _price);
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
        require(itemSale.owner == msg.sender, "Only owner can cancel");
        peaNFT.transferFrom(address(this), msg.sender, _tokenId);

        tokenSales.remove(_tokenId);
        sellerTokens[itemSale.owner].remove(_tokenId);
        markets[_tokenId] = ItemSale({tokenId: 0, price: 0, owner: address(0)});

        emit CancelOrder(_tokenId, msg.sender);
    }

    function buyToken(uint256 _tokenId) public {
        require(tokenSales.contains(_tokenId), "not sale");
        ItemSale storage itemSale = markets[_tokenId];
        uint256 feeMarket = itemSale.price.mul(router.feeMarket()).div(
            router.divPercent()
        );
        peaToken.transferFrom(msg.sender, router.feeAddress(), feeMarket);
        peaToken.transferFrom(
            msg.sender,
            itemSale.owner,
            itemSale.price.sub(feeMarket)
        );

        peaNFT.transferFrom(address(this), msg.sender, _tokenId);

        tokenSales.remove(_tokenId);
        sellerTokens[itemSale.owner].remove(_tokenId);
        markets[_tokenId] = ItemSale({tokenId: 0, price: 0, owner: address(0)});

        emit Buy(_tokenId, msg.sender, itemSale.owner, itemSale.price);
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