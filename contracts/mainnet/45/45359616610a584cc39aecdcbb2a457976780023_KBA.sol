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
    uint256 public kbaPrice = 0.06 ether; 
    uint256 public MAX_KBA_MINT = 25;
    uint256 public MAX_PER_TX = 5;

    uint256 public constant PRESIDENTS_MAX_MINT = 5;
    uint256 public constant WL_MAX_MINT = 3;
    uint256 public constant FREE_MAX_MINT = 1;

    uint256 public constant RESERVED_KBA = 125; 
    address public constant founderAddress = 0x6f452562D7e0E9DF2135b5f797cfF9a34b0B550c; 

    uint256 public reservedClaimed;

    uint256 public numBabyapesMinted;

    string public baseTokenURI;

    bool public publicSaleStarted;
    bool public preSaleStarted;

    mapping(address => bool) private _wlEligible;
    mapping(address => bool) private _presidentsEligible;
    mapping(address => bool) private _freeEligible;


    mapping(address => uint256) public totalClaimed;

    mapping(address => uint256) private _totalClaimedWl;
    mapping(address => uint256) private _totalClaimedPresident;
    mapping(address => uint256) private _totalClaimedFree;


    event BaseURIChanged(string baseURI);
    event WlMint(address minter, uint256 amountOfBabyapes);
    event PresidentMint(address minter, uint256 amountOfBabyapes);
    event FreeMint(address minter, uint256 amountOfBabyapes);

    event PresaleMint(address minter, uint256 amountOfBabyapes);
    event PublicSaleMint(address minter, uint256 amountOfBabyapes);

    modifier whenPresaleStarted() {
        require(preSaleStarted, "Presale has not started");
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

        uint256 _nextTokenId = numBabyapesMinted;

        for (uint256 i = 0; i < amount; i++) {
            _safeMint(recipient, _nextTokenId + i);
        }
        numBabyapesMinted += amount;
        reservedClaimed += amount;
    }

    function addToWlPresale(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Cannot add null address");

            _wlEligible[addresses[i]] = true;
        }
    }

    function addToPresidentPresale(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Cannot add null address");

            _presidentsEligible[addresses[i]] = true;
        }
    }

    function addToFreeMint(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Cannot add null address");

            _freeEligible[addresses[i]] = true;
        }
    }    

    function checkWlEligibility(address addr) external view returns (bool) {
        return _wlEligible[addr];
    }

    function checkPresidentEligibility(address addr) external view returns (bool) {
        return _presidentsEligible[addr];
    }

    function checkFreeEligibility(address addr) external view returns (bool) {
        return _freeEligible[addr];
    }    

    function getWlMintsClaimed(address addr) external view returns (uint256) {
        return _totalClaimedWl[addr];
    }

    function getPresidentsMintsClaimed(address addr) external view returns (uint256) {
        return _totalClaimedPresident[addr];
    }

    function getFreeMintsClaimed(address addr) external view returns (uint256) {
        return _totalClaimedFree[addr];
    }

    function mintWlPresale(uint256 amountOfBabyapes) external payable whenPresaleStarted {
        require(_wlEligible[msg.sender], "You are not eligible for the handpicked presale");
        require(totalSupply() + amountOfBabyapes <= MAX_KBA - (RESERVED_KBA - reservedClaimed), "Minting would exceed max supply");
        require(_totalClaimedWl[msg.sender] + amountOfBabyapes <= WL_MAX_MINT, "Purchase exceeds max allowed");
        require(amountOfBabyapes > 0, "Must mint at least one KBA");
        require(kbaPrice * amountOfBabyapes <= msg.value, "ETH amount is incorrect");

        for (uint256 i = 0; i < amountOfBabyapes; i++) {
            uint256 tokenId = numBabyapesMinted;

            numBabyapesMinted += 1;
            totalClaimed[msg.sender] += 1;
            _totalClaimedWl[msg.sender] += 1;
            _safeMint(msg.sender, tokenId);
        }

        emit WlMint(msg.sender, amountOfBabyapes);
    }

    function mintPresidentsPresale(uint256 amountOfBabyapes) external payable whenPresaleStarted {
        require(_presidentsEligible[msg.sender], "You are not eligible for the Class Presidents presale");
        require(totalSupply() + amountOfBabyapes <= MAX_KBA - (RESERVED_KBA - reservedClaimed), "Minting would exceed max supply");
        require(_totalClaimedWl[msg.sender] + amountOfBabyapes <= PRESIDENTS_MAX_MINT, "Purchase exceeds max allowed");
        require(amountOfBabyapes > 0, "Must mint at least one KBA");
        require(kbaPrice * amountOfBabyapes <= msg.value, "ETH amount is incorrect");

        for (uint256 i = 0; i < amountOfBabyapes; i++) {
            uint256 tokenId = numBabyapesMinted;

            numBabyapesMinted += 1;
            totalClaimed[msg.sender] += 1;
            _totalClaimedWl[msg.sender] += 1;
            _safeMint(msg.sender, tokenId);
        }

        emit PresidentMint(msg.sender, amountOfBabyapes);
    }

    function mintFree(uint256 amountOfBabyapes) external payable whenPresaleStarted {
        require(_freeEligible[msg.sender], "You are not eligible for the Free mint :shrug:");
        require(totalSupply() + amountOfBabyapes <= MAX_KBA - (RESERVED_KBA - reservedClaimed), "Minting would exceed max supply");
        require(_totalClaimedFree[msg.sender] + amountOfBabyapes <= FREE_MAX_MINT, "You can only claim 1 Free.");
        require(amountOfBabyapes < 2, "You can only claim one free KBA");

        for (uint256 i = 0; i < amountOfBabyapes; i++) {
            uint256 tokenId = numBabyapesMinted;

            numBabyapesMinted += 1;
            totalClaimed[msg.sender] += 1;
            _totalClaimedFree[msg.sender] += 1;
            _safeMint(msg.sender, tokenId);
        }

        emit FreeMint(msg.sender, amountOfBabyapes);
    }                

    function mint(uint256 amountOfBabyapes) external payable whenPublicSaleStarted {
        require(totalSupply() + amountOfBabyapes <= MAX_KBA - (RESERVED_KBA - reservedClaimed), "Minting would exceed max supply");
        require(totalClaimed[msg.sender] + amountOfBabyapes <= MAX_KBA_MINT, "Purchase exceeds max allowed per address");
        require(amountOfBabyapes > 0, "Must mint at least one KBA");
        require(amountOfBabyapes <= MAX_PER_TX, "Amount over max per transaction. ");
        require(kbaPrice * amountOfBabyapes <= msg.value, "ETH amount is incorrect");

        for (uint256 i = 0; i < amountOfBabyapes; i++) {
            uint256 tokenId = numBabyapesMinted;

            numBabyapesMinted += 1;
            totalClaimed[msg.sender] += 1;
            _safeMint(msg.sender, tokenId);
        }

        emit PublicSaleMint(msg.sender, amountOfBabyapes);
    }

    function togglePresaleStarted() external onlyOwner {
        preSaleStarted = !preSaleStarted;
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
        kbaPrice = newPriceInWEI;
    }

    function setNewMaxMintPerAddress(uint256 newMax) external onlyOwner {
        MAX_KBA_MINT = newMax;
    } 

    function setNewMaxPerTx(uint256 newMax) external onlyOwner {
        MAX_PER_TX = newMax;
    }

    function withdrawrouted() external onlyOwner {
        uint256 sendAmount = address(this).balance;

        address founder1 = payable(0x81Db670cF7f5208454a07Cc8DD4AdF24FD0a4232);
        address founder2 = payable(0xb70E84202beA66D4af3d079b20196a94b0632825);
        address apeyard1 = payable(0x9aAb7614EdaaEA8A2BB145C3BfEFC10C6fb1bdE0);
        address apeyard2 = payable(0x95012c8A2E28e689e51a15Aa83C3A82AB9BCf170);
        address consultant = payable(0x2C8a40e48c31C167664f71d5235e7E67E9696407);
        address community = payable(0x6f452562D7e0E9DF2135b5f797cfF9a34b0B550c);

        bool success;
        (success, ) = founder1.call{value: ((sendAmount * 40)/100)}("");
        require(success, "Transaction Unsuccessful");

        (success, ) = founder2.call{value: ((sendAmount * 31)/100)}("");
        require(success, "Transaction Unsuccessful");

        (success, ) = apeyard1.call{value: ((sendAmount * 16)/100)}("");
        require(success, "Transaction Unsuccessful");

        (success, ) = apeyard2.call{value: ((sendAmount * 3)/100)}("");
        require(success, "Transaction Unsuccessful");        

        (success, ) = consultant.call{value: ((sendAmount * 3)/100)}("");
        require(success, "Transaction Unsuccessful");

        (success, ) = community.call{value: ((sendAmount * 7)/100)}("");
        require(success, "Transaction Unsuccessful");
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