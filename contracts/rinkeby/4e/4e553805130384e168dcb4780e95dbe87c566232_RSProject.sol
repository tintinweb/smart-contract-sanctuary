// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC165.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC721Metadata.sol";
import "./Address.sol";
import "./Context.sol";
import "./Strings.sol";
import "./ERC165.sol";
import "./ERC721.sol";
import "./IERC721Enumerable.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract RSProject is ERC721Enumerable, Ownable {
    uint256 public constant MAX_SUPPLY = 500;
    uint256 public constant RESERVES = 100;

    uint256 private _preSaleLimit = 2;
    uint256 private _maxPerTx = 5;
    uint256 private _price = 10000000000000000; // .01 ETH

    // For presale
    mapping(address => bool) addressToPreSaleEntry;
    mapping(address => uint256) addressToPreSaleTokensMinted;

    bool private PAUSE_SALE = true;
    bool private PAUSE_PRESALE = true;

    string private _baseTokenURI = "";

    event PauseEvent(bool pause);

    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol){}

    modifier preSaleIsOpen() {
        require(totalSupply() <= RESERVES, "Soldout!");
        require(!PAUSE_PRESALE, "The presale has not yet started.");
        _;
    }

    modifier saleIsOpen() {
        require(totalSupply() <= MAX_SUPPLY, "Soldout!");
        require(!PAUSE_SALE, "The sale has not yet started");
        _;
    }
    
    function setPreSaleAddresses(address[] memory preSaleWalletAddresses) public onlyOwner {
        for (uint256 i; i < preSaleWalletAddresses.length; i++) {
            addressToPreSaleEntry[preSaleWalletAddresses[i]] = true;
        }
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }
    
    function getBaseURI() public view returns (string memory) {
        return _baseTokenURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setPreSaleLimit(uint256 _val) public onlyOwner {
        _preSaleLimit = _val;
    }

    function getPreSaleLimit() public view returns (uint256) {
        return _preSaleLimit;
    }

    function setSaleLimit(uint256 _val) public onlyOwner {
        _maxPerTx = _val;
    }

    function getSaleLimit() public view returns (uint256) {
        return _maxPerTx;
    }

    function setPrice(uint256 _newWEIPrice) public onlyOwner {
        _price = _newWEIPrice;
    }

    function getPrice() public view returns (uint256) {
        return _price;
    }

    function setSalePause(bool _pause) public onlyOwner{
        PAUSE_SALE = _pause;
        emit PauseEvent(PAUSE_SALE);
    }

    function getPreSalePause(bool _pause) public onlyOwner{
        PAUSE_PRESALE = _pause;
        emit PauseEvent(PAUSE_PRESALE);
    }
    
    function addWalletToPreSale(address _address) public onlyOwner {
        addressToPreSaleEntry[_address] = true;
    }

    function isWalletInPreSale(address _address) public view returns (bool) {
        return addressToPreSaleEntry[_address];
    }

    function preSaleTokensMinted(address _address)
        public
        view
        returns (uint256)
    {
        return addressToPreSaleTokensMinted[_address];
    }

    function preSaleMint(uint256 _count) public payable preSaleIsOpen {
        uint256 totalSupply = totalSupply();
        require(
            _count <= _preSaleLimit,
            "Mint transaction exceeds your available supply."
        );
        require(
            addressToPreSaleEntry[msg.sender] == true,
            "This address is not whitelisted for the presale."
        );
        require(
            addressToPreSaleTokensMinted[msg.sender] + _count <=
                _preSaleLimit,
            "Exceeds supply of presale Tokens you can mint."
        );
        require(_price * _count <= msg.value, "Transaction value too low.");

        for (uint256 i; i < _count; i++) {
            _safeMint(msg.sender, totalSupply + i);
        }

        // Keeps track of how many they've minted
        addressToPreSaleTokensMinted[msg.sender] += _count;
    }

    function mint(uint256 _count) public payable saleIsOpen {
        uint256 totalSupply = totalSupply();
        require(
            _count < _maxPerTx,
            "Exceeds the number of Tokens to mint!"
        );
        require(totalSupply < MAX_SUPPLY, "All Tokens are already minted.");
        require(
            totalSupply + _count <= MAX_SUPPLY,
            "This amount of Tokens will exceed max supply."
        );
        require(_price * _count <= msg.value, "Transaction value too low.");

        for (uint256 i; i < _count; i++) {
            _safeMint(msg.sender, totalSupply + i);
        }
    }

    function reserveTokens(uint256 _count) public onlyOwner {
        uint256 totalSupply = totalSupply();
        require(PAUSE_PRESALE, "The presale has already started.");
        require(totalSupply + _count <= RESERVES, "Beyond max limit");

        for (uint256 i; i < _count; i++) {
            _safeMint(msg.sender, totalSupply + i);
        }
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        }

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}