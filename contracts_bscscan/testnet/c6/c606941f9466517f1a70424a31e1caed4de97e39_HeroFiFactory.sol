// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./SafeMath.sol";
import "./HeroFiNFT.sol";
import "./Counters.sol";
import "./Initializable.sol";

contract HeroFiFactory is Initializable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    struct Category {
        uint256 id;
        string baseUrl;
        string uri;
        uint256 amount;
        uint256 max;
        uint256 price;
        bool isSale;
        HeroFiNFT nft;
        string name;
        string symbol;
    }

    address private _owner;

    mapping(uint256 => Category) private _indexToCategory;
    Counters.Counter private _indexTracker; // id of category NFT start from 1

    // category id to number of promotional art
    mapping(uint256 => uint256) public _promotion;

    function initialize() public initializer {
        _owner = msg.sender;
    }

    event AddCategory(
        uint256 id,
        string baseUrl_,
        string uri_,
        string name_,
        string symbol_,
        uint256 max_,
        uint256 price_
    );

    event EditCategory(
        uint256 id,
        string baseUrl_,
        string uri_,
        string name_,
        string symbol_,
        uint256 max_,
        uint256 price_
    );

    // edit price
    event EditPriceCategory(uint256 index_, uint256 price_);
    // enable cate can sale
    event EnableCategory(uint256 index_);

    event WithdrawBalance(address from, address to, uint256 price);
    // mint nft with cate have id "arId" and send to address "To"
    event MintArt(address to, uint256 arId);

    modifier onlyOwner() {
        require(msg.sender == _owner, "Not Owner");
        _;
    }

    function addCategory(
        string memory baseUrl_,
        string memory uri_,
        string memory name_,
        string memory symbol_,
        uint256 max_,
        uint256 price_,
        uint256 number_of_promotion
    ) public virtual onlyOwner {
        require(
            number_of_promotion > 0 && max_ >= number_of_promotion,
            "The number item of category must > number_of_promotion"
        );
        require(price_ > 0, "The price item must > 0");

        _indexTracker.increment();
        uint256 index = _indexTracker.current();

        HeroFiNFT nft = new HeroFiNFT(name_, symbol_, baseUrl_, uri_, index);

        Category memory cate = Category({
            id: index,
            baseUrl: baseUrl_,
            uri: uri_,
            amount: number_of_promotion,
            max: max_,
            price: price_,
            isSale: bool(false),
            nft: nft,
            name: name_,
            symbol: symbol_
        });
        _indexToCategory[index] = cate;
        _promotion[index] = number_of_promotion;

        emit AddCategory(index, baseUrl_, uri_, name_, symbol_, max_, price_);
    }

    function editPriceCategory(uint256 index_, uint256 price_)
        public
        onlyOwner
    {
        require(_indexToCategory[index_].max > 0, "Not exist Category");
        require(price_ > 0, "The price item must > 0");
        
         Category memory cate = _indexToCategory[index_];
        require(!cate.isSale, "NFT - opened for sale");
        
        _indexToCategory[index_].price = price_;

        emit EditPriceCategory(index_, price_);
    }

    function enableCategory(uint256 index_) public onlyOwner {
        require(_indexToCategory[index_].max > 0, "Not exist Category");
        Category memory cate = _indexToCategory[index_];
        require(
            !cate.isSale && cate.amount != cate.max,
            "NFT - opened for sale"
        );
        cate.isSale = bool(true);
        _indexToCategory[index_] = cate;
        emit EnableCategory(index_);
    }

    function editCategory(
        uint256 index_,
        string memory baseUrl_,
        string memory uri_,
        string memory name_,
        string memory symbol_,
        uint256 max_,
        uint256 price_,
        uint256 number_of_promotion
    ) public virtual onlyOwner {
        require(
            number_of_promotion > 0 && max_ >= number_of_promotion,
            "The number item of category must > number_of_promotion"
        );

        Category memory cate = _indexToCategory[index_];

        require(!cate.isSale, "NFT - opened for sale");

        require(max_ > 0, "The number item of category must > 0");
        require(price_ > 0, "The price item must > 0");

        cate.baseUrl = baseUrl_;
        cate.uri = uri_;
        cate.name = name_;
        cate.symbol = symbol_;
        cate.max = max_;
        cate.price = price_;
        cate.amount = number_of_promotion;

        _indexToCategory[index_] = cate;
        _promotion[index_] = number_of_promotion;
        emit EditCategory(index_, baseUrl_, uri_, name_, symbol_, max_, price_);
    }

    function getCategoryLength() external view returns (uint256) {
        return _indexTracker.current();
    }

    function getNFTAddress(uint256 index_) public view returns (address) {
        return address(_indexToCategory[index_].nft);
    }

    function getCategory(uint256 index_) public view returns (Category memory) {
        return _indexToCategory[index_];
    }

    function mintArtByCategoryId(uint256 categoryId_) external payable {
        require(_indexToCategory[categoryId_].max > 0, "Not exist Category Id");
        Category memory cate = _indexToCategory[categoryId_];
        require(cate.isSale == true, "Sold out");
        require(msg.value == cate.price, "fees are not enough");
        cate.amount = cate.amount.add(1);
        if (cate.amount == cate.max) {
            cate.isSale = bool(false);
        }
        _indexToCategory[categoryId_] = cate;

        uint256 arId = cate.nft.mintArt(msg.sender);

        emit MintArt(msg.sender, arId);
    }

    function mintArtForPromotion(uint256 categoryId_, address _to) external onlyOwner {
        require(_indexToCategory[categoryId_].max > 0, "Not exist Category Id");
        Category memory cate = _indexToCategory[categoryId_];
        require(_promotion[categoryId_] > 0, "promotion end");
        if (!cate.isSale) {
            cate.isSale = bool(true);
            _indexToCategory[categoryId_] = cate;
        }

        _promotion[categoryId_] = _promotion[categoryId_].sub(1);

        uint256 arId = cate.nft.mintArt(_to);

        emit MintArt(_to, arId);
    }

    
    function setBaseURI(string memory url_, uint256 categoryId_) public virtual onlyOwner {
        require(_indexToCategory[categoryId_].max > 0, "Not exist Category Id");
        Category memory cate = _indexToCategory[categoryId_];
        cate.baseUrl = url_;
        _indexToCategory[categoryId_] = cate;
        cate.nft.setBaseURI(url_);
    }

    function withdrawBalance(address receiver) external onlyOwner {
        payable(receiver).transfer(address(this).balance);
        emit WithdrawBalance(address(this), receiver, address(this).balance);
    }
}