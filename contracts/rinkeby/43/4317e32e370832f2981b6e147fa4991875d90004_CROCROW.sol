// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Context.sol";
import "./Counters.sol";
import "./IERC20.sol";

contract CROCROW is
    Context,
    Ownable,
    ERC721Enumerable,
    ERC721Burnable
{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;

    string private _baseTokenURI;
    string private _contractURI;
    uint256 public max = 7777;
    uint256 public maxMintPerTx = 20;
    uint256 public maxMintPerTxWL = 4;

    mapping(address => bool) whitelist;

    bool public publicSaleStarted = false;

    bool public tokenURIFrozen = false;
    uint256 public cost = 1 ether;
    
    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        uint256 reserved,
        address[] memory _address
    ) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;
        _tokenIdTracker.increment();
        
        for (uint256 i = 1; i <= reserved; i++) {
            require(_tokenIdTracker.current() <= max, "Transaction exceeds max mint amount");
            _mint(_msgSender(), _tokenIdTracker.current());
            _tokenIdTracker.increment();
        }
        
        uint256 count = _address.length;
        for (uint256 i = 0; i < count; i++){
            whitelist[_address[i]] = true;
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }
    
    function adminMint(uint256 _mintAmount) public onlyOwner{
        for (uint256 i = 1; i <= _mintAmount; i++) {
            require(_tokenIdTracker.current() <= max, "Transaction exceeds max mint amount");
            _mint(_msgSender(), _tokenIdTracker.current());
            _tokenIdTracker.increment();
        }
    }
    function whitelistMint(uint256 _mintAmount) public payable {
        require(whitelist[_msgSender()] == true, "User is not whitelisted");
        require(_mintAmount <= maxMintPerTxWL, "Exceeds max amount per WL mint");
        require(msg.value >= cost * _mintAmount, "Not enough ether provided");
        for (uint256 i = 1; i <= _mintAmount; i++) {
            require(_tokenIdTracker.current() <= max, "Transaction exceeds max mint amount");
            _mint(_msgSender(), _tokenIdTracker.current());
            _tokenIdTracker.increment();
        }
        whitelist[_msgSender()] = false;
    }
    function mint(uint256 _mintAmount) public payable {
        require(publicSaleStarted == true, "Public Sale not started yet");
        require(_mintAmount <= maxMintPerTx, "Exceeds max amount per mint");
        require(msg.value >= cost * _mintAmount, "Not enough ether provided");
        for (uint256 i = 1; i <= _mintAmount; i++) {
            require(_tokenIdTracker.current() <= max, "Transaction exceeds max mint amount");
            _mint(_msgSender(), _tokenIdTracker.current());
            _tokenIdTracker.increment();
        }
    }
    function withdraw(address token, uint256 amount) public onlyOwner {
        if(token == address(0)) { 
            payable(_msgSender()).transfer(amount);
        } else {
            IERC20(token).transfer(_msgSender(), amount);
        }
    }
    
    function setContractURI(string memory uri) public onlyOwner {
        require(tokenURIFrozen == false, "Token URIs are frozen");
        _contractURI = uri;
    }
    function setBaseTokenURI(string memory uri) public onlyOwner {
        require(tokenURIFrozen == false, "Token URIs are frozen");
        _baseTokenURI = uri;
    }
    
    function setCost(uint256 price) public onlyOwner {
        cost = price;
    }
    
    function freezeBaseURI() public onlyOwner {
        tokenURIFrozen = true;
    }
    
    function startPublicSale() public onlyOwner {
        publicSaleStarted = true;
    }
    
    function setWL(address[] memory _address) public onlyOwner {
        uint256 count = _address.length;
        for (uint256 i = 0; i < count; i++){
            whitelist[_address[i]] = true;
        }
    }

    function isWhitelisted(address _address) public view returns(bool) {
        return whitelist[_address];
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}