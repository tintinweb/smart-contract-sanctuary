// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";


contract WallStreetGang is ERC721Enumerable, Ownable {

    uint256 public constant PRICE = 0.05 ether;

    uint256 public constant MAX_WSG = 8701;         // max for the contract, postmint not included

    uint256 public constant POSTMINT_WSG = 101;      // reserved for presmint

    uint256 public constant PRESALE_MAX_PER_MINT = 4;   // max per presale mint
    uint256 public constant PRESALE_MAX_MINT = 4;       // max presale mint per address
    uint256 public constant PRESALE_MAX_WSG = 2002;     // max for the presale

    uint256 public constant MAX_PER_MINT = 7;       // max per public mint
    uint256 public constant MAX_WSG_MINT = 42;      // max per address

    uint256 public numWsgMinted;    // total minted tokens
    address withdraw_address;
    address postmint_address;        // WSG_marketing wallet for presmint

    string public baseTokenURI;     // URL to an API

    bool public publicSaleStarted;
    bool public presaleStarted;

    mapping(address => bool) private _presaleEligible;  // resale white list

    event BaseURIChanged(string baseURI);
    event PresaleMint(address minter, uint256 amountOfWsg);
    event PublicSaleMint(address minter, uint256 amountOfWsg);

    modifier whenPresaleStarted() {
        require(presaleStarted, "Presale has not started");
        _;
    }

    modifier whenPublicSaleStarted() {
        require(publicSaleStarted, "Public sale has not started");
        _;
    }

    constructor(string memory baseURI, address _withdraw_address, address _postmint_address) ERC721("WallStreetGang", "WSG") {
        baseTokenURI = baseURI;
        withdraw_address = _withdraw_address;
        postmint_address = _postmint_address;
    }

    function addToPresale(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Cannot add null address");

            _presaleEligible[addresses[i]] = true;
        }
    }

    function checkPresaleEligiblity(address addr) external view returns (bool) {
        return _presaleEligible[addr];
    }

    function mintPresale(uint256 amountOfWsg) external payable whenPresaleStarted {
        require(_presaleEligible[msg.sender], "You are not eligible for the presale");
        require(totalSupply() <= PRESALE_MAX_WSG, "All presale tokens have been minted");
        require(totalSupply() + amountOfWsg <= PRESALE_MAX_WSG, "Minting would exceed presale max supply");
        require(amountOfWsg <= PRESALE_MAX_PER_MINT, "Cannot purchase this many tokens during presale");
        require(balanceOf(msg.sender) + amountOfWsg <= PRESALE_MAX_MINT, "Purchase exceeds max allowed for presale");
        require(amountOfWsg > 0, "Must mint at least one WSG");
        require(PRICE * amountOfWsg == msg.value, "ETH amount is incorrect");

        for (uint256 i = 0; i < amountOfWsg; i++) {
            uint256 tokenId = numWsgMinted;

            numWsgMinted += 1;
            _safeMint(msg.sender, tokenId);
        }

        _withdraw(PRICE * amountOfWsg);

        emit PresaleMint(msg.sender, amountOfWsg);
    }

    function mint(uint256 amountOfWsg) external payable whenPublicSaleStarted {
        require(totalSupply() <= MAX_WSG, "All tokens have been minted");
        require(totalSupply() + amountOfWsg <= MAX_WSG, "Minting would exceed max supply");
        require(amountOfWsg <= MAX_PER_MINT, "Cannot purchase this many tokens in a transaction");
        require(balanceOf(msg.sender) + amountOfWsg <= MAX_WSG_MINT, "Purchase exceeds max allowed per address");
        require(amountOfWsg > 0, "Must mint at least one WSG");
        require(PRICE * amountOfWsg == msg.value, "ETH amount is incorrect");

        for (uint256 i = 0; i < amountOfWsg; i++) {
            uint256 tokenId = numWsgMinted;

            numWsgMinted += 1;
            _safeMint(msg.sender, tokenId);
        }

        _withdraw(PRICE * amountOfWsg);

        emit PublicSaleMint(msg.sender, amountOfWsg);
    }

    function postmint() external onlyOwner {
        require(numWsgMinted >= MAX_WSG, "Public sale has not finished");
        require(numWsgMinted < MAX_WSG + POSTMINT_WSG, "All tokens have been minted");
        for (uint256 i = numWsgMinted; i < numWsgMinted + POSTMINT_WSG; i++) {
            _safeMint(postmint_address, i);
        }
        numWsgMinted += POSTMINT_WSG;
    }

    function transfer_postminted(address reciever, uint _from, uint _to) external {      // token #_to is not included
        require(reciever != address(0), "Cannot add null address");
        require(msg.sender == postmint_address, "Caller is not the postminted tokens owner");
        require(_from < _to, "Wrong range boundaries");
        require(_from >= MAX_WSG, "Below postmint range");
        require(_from <= numWsgMinted && _to < numWsgMinted + POSTMINT_WSG, "The postminted range has been exceeded");
        require(balanceOf(reciever) + _to - _from <= MAX_WSG_MINT, "Transfer exceeds max allowed tokens per address");
        for (uint256 i = _from; i < _to; i++) {
            safeTransferFrom(msg.sender, reciever, i);
        }
    }

    function togglePresaleStarted() external onlyOwner {
        presaleStarted = !presaleStarted;
    }

    function togglePublicSaleStarted() external onlyOwner {
        publicSaleStarted = !publicSaleStarted;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
        emit BaseURIChanged(baseURI);
    }

    function _withdraw(uint256 _amount) internal {
        (bool success, ) = withdraw_address.call{ value: _amount }("");
        require(success, "Failed to transfer Ether");
    }
}