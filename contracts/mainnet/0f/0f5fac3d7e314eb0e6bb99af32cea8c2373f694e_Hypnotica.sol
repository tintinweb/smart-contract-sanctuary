// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";



/*
*    ▄▄   ▄▄ ▄▄   ▄▄ ▄▄▄▄▄▄▄ ▄▄    ▄ ▄▄▄▄▄▄▄ ▄▄▄▄▄▄▄ ▄▄▄ ▄▄▄▄▄▄▄ ▄▄▄▄▄▄▄
*   █  █ █  █  █ █  █       █  █  █ █       █       █   █       █       █
*   █  █▄█  █  █▄█  █    ▄  █   █▄█ █   ▄   █▄     ▄█   █       █   ▄   █
*   █       █       █   █▄█ █       █  █ █  █ █   █ █   █     ▄▄█  █▄█  █
*   █   ▄   █▄     ▄█    ▄▄▄█  ▄    █  █▄█  █ █   █ █   █    █  █       █
*   █  █ █  █ █   █ █   █   █ █ █   █       █ █   █ █   █    █▄▄█   ▄   █
*   █▄▄█ █▄▄█ █▄▄▄█ █▄▄▄█   █▄█  █▄▄█▄▄▄▄▄▄▄█ █▄▄▄█ █▄▄▄█▄▄▄▄▄▄▄█▄▄█ █▄▄█
*/



contract Hypnotica is ERC721, ERC721URIStorage, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    string baseURI;
    string private spp;

    uint256 public constant PRICE = 0.05 ether;
    uint256 public constant WHITELIST_PRICE = 0.03 ether;

    uint256 public constant START_AT = 1;

    uint256 public constant MAX_ELEMENTS = 2048;
    uint256 public constant MAX_PER_TRANSACTION = 10;

    uint256 public constant MAX_PRESALE_ELEMENTS = 400;
    uint256 public constant MAX_PER_WHITELIST_TRANSACTION = 5;
    uint256 public constant MAX_PRESALE_AMOUNT_WALLET = 5;

    bool private IS_PAUSED = true;
    bool public ONLY_WHITELISTED = true;

    constructor(string memory baseTokenURI, string memory _spp) ERC721("Hypnotica", "HPNTK") {
        setBaseURI(baseTokenURI);
        setSpp(_spp);
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function setSpp(string memory _spp) public onlyOwner {
        spp = _spp;
    }

    // ENABLE/DISABLE PRESALE
    function setOnlyWhitelisted(bool _state) public onlyOwner {
        ONLY_WHITELISTED = _state;
    }

    // DETECT IF SALE IS OPEN - BOOL RETURN
    modifier isSaleOpen {
        require(totalToken() <= MAX_ELEMENTS, "Soldout!");
        require(!IS_PAUSED, "Sales not open");
        _;
    }

    // Get current amount of minted (= the current id)
    function totalToken() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function setPause(bool _pause) public onlyOwner{
        IS_PAUSED = _pause;
    }

    function totalPrice(uint256 _amount, uint256 _price) public pure returns (uint256) {
        return _price.mul(_amount);
    }

    // MINTING
    function mint(uint256 _amount, string memory _spp) public payable isSaleOpen{
        address wallet = msg.sender;
        uint256 total = totalToken(); // get total token
        uint256 currentPrice = ONLY_WHITELISTED ? WHITELIST_PRICE : PRICE;
        uint256 maxPerTransation = ONLY_WHITELISTED ? MAX_PER_WHITELIST_TRANSACTION : MAX_PER_TRANSACTION;
        uint256 overAllLimit = ONLY_WHITELISTED ? MAX_PRESALE_ELEMENTS : MAX_ELEMENTS;


        if(ONLY_WHITELISTED){
            require(checkSpp(_spp), "Not whitelisted");
            require(balanceOf(wallet) + _amount <= MAX_PRESALE_AMOUNT_WALLET, "Too many in wallet");
        }

        require(_amount <= maxPerTransation, "Exceeds per transaction");
        require(total + _amount <= overAllLimit, "Global overlimit");
        require(msg.value >= totalPrice(_amount, currentPrice), "Value below price");

        for(uint8 i = 0; i < _amount; i++){
            safeMint(wallet);
        }
    }

    function safeMint(address to) private {
        _tokenIdCounter.increment();
        _safeMint(to, _tokenIdCounter.current());
    }

    // WITHDRAW
    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, 'Withdraw failed');
    }

    // CHECK SPP
    function checkSpp(string memory _spp) private view returns (bool) {
        return (keccak256(abi.encodePacked((spp))) == keccak256(abi.encodePacked((_spp))));
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return string(abi.encodePacked(super.tokenURI(tokenId),".json"));
    }
}