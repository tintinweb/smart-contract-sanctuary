// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ERC721Enumerable.sol';
import './Ownable.sol';
import './Pausable.sol';

contract CryptoDads is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_DADS = 100000;
    uint256 public constant PRICE = 0.00001 ether;
    uint256 public constant MAX_PER_MINT = 100;
    uint256 public constant PRESALE_MAX_MINT = 50;
    uint256 public constant MAX_DADS_MINT = 10000;
    uint256 public constant RESERVED_DADS = 10;
    address public constant founderAddress = 0xa041a38E72c20528c749843E0d54d52cA4750E33;
    address public constant devAddress = 0xF38de0b221f9671c8CEcdb64Cceeee8d69778135;

    uint256 public reservedClaimed;

    uint256 public numDadsMinted;

    string public baseTokenURI;

    bool public publicSaleStarted;
    bool public presaleStarted;

    mapping(address => bool) private _presaleEligible;
    mapping(address => uint256) private _totalClaimed;

    event BaseURIChanged(string baseURI);
    event PresaleMint(address minter, uint256 amountOfDads);
    event PublicSaleMint(address minter, uint256 amountOfDads);

    modifier whenPresaleStarted() {
        require(presaleStarted, 'Presale has not started');
        _;
    }

    modifier whenPublicSaleStarted() {
        require(publicSaleStarted, 'Public sale has not started');
        _;
    }

    constructor(string memory baseURI) ERC721('CryptoDads', 'DAD') {
        baseTokenURI = baseURI;
    }

    function claimReserved(address recipient, uint256 amount) external onlyOwner {
        require(reservedClaimed != RESERVED_DADS, 'Already have claimed all reserved dads');
        require(reservedClaimed + amount <= RESERVED_DADS, 'Minting would exceed max reserved dads');
        require(recipient != address(0), 'Cannot add null address');
        require(totalSupply() < MAX_DADS, 'All tokens have been minted');
        require(totalSupply() + amount <= MAX_DADS, 'Minting would exceed max supply');

        uint256 _nextTokenId = numDadsMinted + 1;

        for (uint256 i = 0; i < amount; i++) {
            _safeMint(recipient, _nextTokenId + i);
        }
        numDadsMinted += amount;
        reservedClaimed += amount;
    }

    function addToPresale(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), 'Cannot add null address');

            _presaleEligible[addresses[i]] = true;

            _totalClaimed[addresses[i]] > 0 ? _totalClaimed[addresses[i]] : 0;
        }
    }

    function checkPresaleEligiblity(address addr) external view returns (bool) {
        return _presaleEligible[addr];
    }

    function amountClaimedBy(address owner) external view returns (uint256) {
        require(owner != address(0), 'Cannot add null address');

        return _totalClaimed[owner];
    }

    function mintPresale(uint256 amountOfDads) external payable whenPresaleStarted {
        require(_presaleEligible[msg.sender], 'You are not eligible for the presale');
        require(totalSupply() < MAX_DADS, 'All tokens have been minted');
        require(amountOfDads <= PRESALE_MAX_MINT, 'Cannot purchase this many tokens during presale');
        require(totalSupply() + amountOfDads <= MAX_DADS, 'Minting would exceed max supply');
        require(_totalClaimed[msg.sender] + amountOfDads <= PRESALE_MAX_MINT, 'Purchase exceeds max allowed');
        require(amountOfDads > 0, 'Must mint at least one dad');
        require(PRICE * amountOfDads == msg.value, 'ETH amount is incorrect');

        for (uint256 i = 0; i < amountOfDads; i++) {
            uint256 tokenId = numDadsMinted + 1;

            numDadsMinted += 1;
            _totalClaimed[msg.sender] += 1;
            _safeMint(msg.sender, tokenId);
        }

        emit PresaleMint(msg.sender, amountOfDads);
    }

    function mint(uint256 amountOfDads) external payable whenPublicSaleStarted {
        require(totalSupply() < MAX_DADS, 'All tokens have been minted');
        require(amountOfDads <= MAX_PER_MINT, 'Cannot purchase this many tokens in a transaction');
        require(totalSupply() + amountOfDads <= MAX_DADS, 'Minting would exceed max supply');
        require(_totalClaimed[msg.sender] + amountOfDads <= MAX_DADS_MINT, 'Purchase exceeds max allowed per address');
        require(amountOfDads > 0, 'Must mint at least one dad');
        require(PRICE * amountOfDads == msg.value, 'ETH amount is incorrect');

        for (uint256 i = 0; i < amountOfDads; i++) {
            uint256 tokenId = numDadsMinted + 1;

            numDadsMinted += 1;
            _totalClaimed[msg.sender] += 1;
            _safeMint(msg.sender, tokenId);
        }

        emit PublicSaleMint(msg.sender, amountOfDads);
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

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, 'Insufficent balance');
        _widthdraw(devAddress, ((balance * 15) / 100));
        _widthdraw(founderAddress, address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}('');
        require(success, 'Failed to widthdraw Ether');
    }
}