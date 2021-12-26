// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./Pausable.sol";

contract KBA is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 public MAX_KBA = 10000; 
    uint256 public PRICE = 0.06 ether; 
    uint256 public MAX_KBA_MINT = 25;
    uint256 public MAX_PER_TX = 5;

    uint256 public constant HANDPICKED_MAX_MINT = 2;
    uint256 public constant PRESALE_MAX_MINT = 3;
    uint256 public constant RESERVED_KBA = 125; 
    address public constant founderAddress = 0xcE11A91E03C7b1cc45e86D80881C0980f9e93C28; 

    address private constant launchpadAddress = 0xcE11A91E03C7b1cc45e86D80881C0980f9e93C28; 
    address private constant donationAddress = 0xcE11A91E03C7b1cc45e86D80881C0980f9e93C28; 

    uint256 public reservedClaimed;

    uint256 public numBabyapesMinted;

    string public baseTokenURI;

    bool public publicSaleStarted;
    bool public presaleStarted;

    mapping(address => bool) private _handpickedEligible;
    mapping(address => bool) private _presaleEligible;

    mapping(address => uint256) public totalClaimed;

    mapping(address => uint256) private _totalClaimedHandpicked;
    mapping(address => uint256) private _totalClaimedPresale;

    event BaseURIChanged(string baseURI);
    event HandpickedMint(address minter, uint256 amountOfBabyapes);
    event PresaleMint(address minter, uint256 amountOfBabyapes);
    event PublicSaleMint(address minter, uint256 amountOfBabyapes);

    modifier whenPresaleStarted() {
        require(presaleStarted, "Presale has not started");
        _;
    }

    modifier whenPublicSaleStarted() {
        require(publicSaleStarted, "Public sale has not started");
        _;
    }

    constructor(string memory baseURI) ERC721("Kindergarten BabyApes", "KBA") {
        baseTokenURI = baseURI;
    }

    function claimReserved(address recipient, uint256 amount) external onlyOwner {
        require(reservedClaimed + amount <= RESERVED_KBA, "Minting would exceed max reserved KBA");
        require(recipient != address(0), "Cannot add null address");
        require(totalSupply() + amount <= MAX_KBA, "Minting would exceed max supply");

        uint256 _nextTokenId = numBabyapesMinted + 1;

        for (uint256 i = 0; i < amount; i++) {
            _safeMint(recipient, _nextTokenId + i);
        }
        numBabyapesMinted += amount;
        reservedClaimed += amount;
    }

    function addToHandpickedPresale(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Cannot add null address");

            _handpickedEligible[addresses[i]] = true;
        }
    }

    function addToPartnershipPresale(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Cannot add null address");

            _presaleEligible[addresses[i]] = true;
        }
    }

    function checkHandpickedEligibility(address addr) external view returns (bool) {
        return _handpickedEligible[addr];
    }

    function checkPresaleEligibility(address addr) external view returns (bool) {
        return _presaleEligible[addr];
    }

    function getHandpickedMintsClaimed(address addr) external view returns (uint256) {
        return _totalClaimedHandpicked[addr];
    }

    function getPresaleMintsClaimed(address addr) external view returns (uint256) {
        return _totalClaimedPresale[addr];
    }

    function mintPartnershipPresale() external payable whenPresaleStarted {
        require(_presaleEligible[msg.sender], "You are not eligible for the partnership presale");
        require(totalSupply() + 1 <= MAX_KBA - (RESERVED_KBA - reservedClaimed), "Minting would exceed max supply");
        require(_totalClaimedPresale[msg.sender] + 1 <= PRESALE_MAX_MINT, "Exceeds max allowed per wallet on presale");
        require(PRICE <= msg.value, "ETH amount is incorrect");

        uint256 tokenId = numBabyapesMinted + 1;

        numBabyapesMinted += 1;
        totalClaimed[msg.sender] += 1;
        _totalClaimedPresale[msg.sender] += 1;
        _safeMint(msg.sender, tokenId);

        emit PresaleMint(msg.sender, 1);
    }

    function mintHandpickedPresale(uint256 amountOfBabyapes) external payable whenPresaleStarted {
        require(_handpickedEligible[msg.sender], "You are not eligible for the handpicked presale");
        require(totalSupply() + amountOfBabyapes <= MAX_KBA - (RESERVED_KBA - reservedClaimed), "Minting would exceed max supply");
        require(_totalClaimedHandpicked[msg.sender] + amountOfBabyapes <= HANDPICKED_MAX_MINT, "Purchase exceeds max allowed");
        require(amountOfBabyapes > 0, "Must mint at least one KBA");
        require(PRICE * amountOfBabyapes <= msg.value, "ETH amount is incorrect");

        for (uint256 i = 0; i < amountOfBabyapes; i++) {
            uint256 tokenId = numBabyapesMinted + 1;

            numBabyapesMinted += 1;
            totalClaimed[msg.sender] += 1;
            _totalClaimedHandpicked[msg.sender] += 1;
            _safeMint(msg.sender, tokenId);
        }

        emit HandpickedMint(msg.sender, amountOfBabyapes);
    }

    function mint(uint256 amountOfBabyapes) external payable whenPublicSaleStarted {
        require(totalSupply() + amountOfBabyapes <= MAX_KBA - (RESERVED_KBA - reservedClaimed), "Minting would exceed max supply");
        require(totalClaimed[msg.sender] + amountOfBabyapes <= MAX_KBA_MINT, "Purchase exceeds max allowed per address");
        require(amountOfBabyapes > 0, "Must mint at least one KBA");
        require(amountOfBabyapes <= MAX_PER_TX, "Amount over max per transaction. ");
        require(PRICE * amountOfBabyapes <= msg.value, "ETH amount is incorrect");

        for (uint256 i = 0; i < amountOfBabyapes; i++) {
            uint256 tokenId = numBabyapesMinted + 1;

            numBabyapesMinted += 1;
            totalClaimed[msg.sender] += 1;
            _safeMint(msg.sender, tokenId);
        }

        emit PublicSaleMint(msg.sender, amountOfBabyapes);
    }

    function bulkPurchase(uint256 amountOfBabyapes) external payable {
        require(totalSupply() + amountOfBabyapes <= MAX_KBA - (RESERVED_KBA - reservedClaimed), "Minting would exceed max supply");
        require(amountOfBabyapes > 0, "Must mint at least one KBA");
        require(msg.sender == launchpadAddress || msg.sender == donationAddress, "Must be launchpad or donation wallet address");
        require(msg.sender == donationAddress || PRICE * amountOfBabyapes <= msg.value, "ETH amount is incorrect");
        require(amountOfBabyapes <= 100, "Cannot mint over 200");

        for (uint256 i = 0; i < amountOfBabyapes; i++) {
            uint256 tokenId = numBabyapesMinted + 1;

            numBabyapesMinted += 1;
            _safeMint(msg.sender, tokenId);
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

    function setMaxTokens(uint256 newMax) external onlyOwner {
        MAX_KBA = newMax;
    } 

    function setNewPrice(uint256 newPriceInWEI) external onlyOwner {
        PRICE = newPriceInWEI;
    }

    function setNewMaxMintPerAddress(uint256 newMax) external onlyOwner {
        MAX_KBA_MINT = newMax;
    }

    function setNewMaxPerTx(uint256 newMax) external onlyOwner {
        MAX_PER_TX = newMax;
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        _withdraw(founderAddress, address(this).balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{ value: _amount }("");
        require(success, "Failed to withdraw Ether");
    }
}