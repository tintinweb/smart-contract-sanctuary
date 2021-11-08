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

contract LucidLTest is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 40;
    uint256 public RESERVES = 5;

    uint256 private _preSaleLimit = 8;
    uint256 private _maxPerTx = 15;
    uint256 private _price = 0.04 ether;
    string  private _baseExtension = ".json";

    // Pre-Sale
    mapping(address => bool) addressToPreSaleEntry;
    mapping(address => uint256) addressToPreSaleTokensMinted;

    bool private PAUSE_SALE = true;
    bool private PAUSE_PRESALE = true;

    string private _baseTokenURI = "";

    event PauseEvent(bool pause);

    constructor(
        string memory _name,
        string memory _symbol
    )ERC721(_name, _symbol){}

    modifier preSaleIsOpen() {
        require(totalSupply() <= MAX_SUPPLY, "Soldout!");
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

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        _baseExtension = _newBaseExtension;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), _baseExtension)) : "";
    }

    function setLimitPreSale(uint256 _val) public onlyOwner {
        _preSaleLimit = _val;
    }

    function getLimitPreSale() public view returns (uint256) {
        return _preSaleLimit;
    }

    function setLimitSale(uint256 _val) public onlyOwner {
        _maxPerTx = _val;
    }

    function getLimitSale() public view returns (uint256) {
        return _maxPerTx;
    }

    function setSalePrice(uint256 _newWEIPrice) public onlyOwner {
        _price = _newWEIPrice;
    }

    function getSalePrice() public view returns (uint256) {
        return _price;
    }

    function setPauseSale(bool _pause) public onlyOwner{
        PAUSE_SALE = _pause;
        emit PauseEvent(PAUSE_SALE);
    }

    function setPausePreSale(bool _pause) public onlyOwner{
        PAUSE_PRESALE = _pause;
        emit PauseEvent(PAUSE_PRESALE);
    }

    function setReservesAmount(uint256 _reservesAmount) public onlyOwner {
        RESERVES = _reservesAmount;
    }
    
    function addWalletToPreSale(address _address) public onlyOwner {
        addressToPreSaleEntry[_address] = true;
    }

    function isWalletInPreSale(address _address) public view returns (bool) {
        return addressToPreSaleEntry[_address];
    }

    function preSaleTokensMinted(address _address) public view returns (uint256) {
        return addressToPreSaleTokensMinted[_address];
    }

    //Pre-Sale
    function mintPreSale(uint256 _count) public payable preSaleIsOpen {
        uint256 totalSupply = totalSupply();
        require(
            _count <= _preSaleLimit,
            "Mint transaction exceeds the available presale supply."
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
        RESERVES -= _count;

        for (uint256 i; i < _count; i++) {
            _safeMint(msg.sender, totalSupply + i);
        }

        // Keeps track of how many they've minted
        addressToPreSaleTokensMinted[msg.sender] += _count;
    }

    //Public Sale
    function mintSale(uint256 _count) public payable saleIsOpen {
        uint256 totalSupply = totalSupply();
        require(
            _count < _maxPerTx,
            "Exceeds the number of Tokens allowed to mint!"
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
        RESERVES -= _count;

        for (uint256 i; i < _count; i++) {
            _safeMint(msg.sender, totalSupply + i);
        }
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
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

    function _make_payable(address x) internal pure returns (address payable) {
        return payable(address(uint160(x)));
    }
    
    function withdrawGiveawayTokenIds(uint256[] memory giveawayId, uint256 _amount) public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance >= _amount, "Insufficient funds");
        for (uint256 i; i < giveawayId.length; i++) {
            address tokenIdOwner = ownerOf(giveawayId[i]);
            address payable _tokenOwner = _make_payable(tokenIdOwner);
            (bool success, ) = _tokenOwner.call{value: _amount}("");
            require(success, "Transfer failed.");
        }
    }
    
    function widthdrawTo(address _address, uint256 _amount) public onlyOwner{
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }
    
    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(msg.sender, address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }
}