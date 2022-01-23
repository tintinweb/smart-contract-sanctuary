// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";

contract Hypnotica is ERC721, ERC721URIStorage, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    string baseURI;

    uint256 public constant PRICE = 0.05 ether;
    uint256 public constant WHITELIST_PRICE = 0.03 ether;

    uint256 public constant START_AT = 1;

    uint256 public constant MAX_ELEMENTS = 100;
    uint256 public constant MAX_PER_TRANSACTION = 10;

    uint256 public constant MAX_PRESALE_ELEMENTS = 15;
    uint256 public constant MAX_PER_WHITELIST_TRANSACTION = 5;
    uint256 public constant MAX_PRESALE_AMOUNT_WALLET = 5;

    bool private IS_PAUSED = false; // needed? ONLY_WHITELISTED blocks anyone that is not in the private, then turning off allows the mint
    bool public ONLY_WHITELISTED = true;

    address[] private whitelistedAddresses;

    /**
        TO DO:
        - DONE >>>>>>> different price private sale!!!
        - DONE >>>>>>> add control on max elements per private sale (to prevent bot drain)
        - add function to change private / public price (fallback just in case)
    **/

    constructor(string memory baseTokenURI) ERC721("Hypnotica", "HPNTK") {
        setBaseURI(baseTokenURI);
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    // ENABLE/DISABLE PRESALE
    function setOnlyWhitelisted(bool _state) public onlyOwner {
        ONLY_WHITELISTED = _state;
    }

    // ADD WHITELIST WALLETS
    function setWhitelistedUsers(address[] calldata _users) public onlyOwner {
        delete whitelistedAddresses;
        whitelistedAddresses = _users;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
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
    function mint(uint256 _amount) public payable isSaleOpen{
        address wallet = msg.sender;
        uint256 total = totalToken(); // get total token
        uint256 currentPrice = ONLY_WHITELISTED ? WHITELIST_PRICE : PRICE;
        uint256 maxPerTransation = ONLY_WHITELISTED ? MAX_PER_WHITELIST_TRANSACTION : MAX_PER_TRANSACTION;
        uint256 overAllLimit = ONLY_WHITELISTED ? MAX_PRESALE_ELEMENTS : MAX_ELEMENTS;

        if(ONLY_WHITELISTED){
            require(isWhitelisted(wallet), "Not whitelisted");
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

    // DETECT IF WHITELISTED
    function isWhitelisted(address _user) private view returns(bool){
        for(uint256 i = 0; i < whitelistedAddresses.length; i++){
            if(whitelistedAddresses[i] == _user){
                return true;
            }
        }
        return false;
    }

    // WITHDRAW
    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, 'Withdraw failed');
    }


    //
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
        super._beforeTokenTransfer(from, to, tokenId);
    }


    // The following functions are overrides required by Solidity.
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return string(abi.encodePacked(super.tokenURI(tokenId),".json"));
    }
}