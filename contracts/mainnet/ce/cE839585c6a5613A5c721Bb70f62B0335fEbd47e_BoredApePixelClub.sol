// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "./BoredApeYachtClub.sol";


contract BoredApePixelClub is ERC721, Ownable {
    using SafeMath for uint;

    BoredApeYachtClub private _boredApeYachtClub;

    uint private constant _PRICE = 30000000000000000;

    string private _provenanceHash = '';

    uint256 private _maxSupply;

    bool private _activeSale = false;

    event WithdrawCompleted(address indexed recipient, uint amount);

    event ReserveCompleted(address indexed recipient, uint tokenId);

    event BaseURIUpdated(string newBaseURI);

    event ProvenanceHashUpdated(string newProvenanceHash);

    event BAYCAddressUpdated(address newBoredApeYachtClubAddress);

    event PurchaseCompleted(address indexed recipient, uint numberOfTokens, uint payment);

    constructor(string memory name, string memory symbol, uint maxSupply, address boredApeYachtClubAddress) ERC721(name, symbol) {
        _boredApeYachtClub = BoredApeYachtClub(boredApeYachtClubAddress);
        _maxSupply = maxSupply;
    }

    function flipSaleState() public onlyOwner {
        _activeSale = !_activeSale;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        msg.sender.transfer(balance);

        emit WithdrawCompleted(msg.sender, balance);
    }

    function reserve(uint tokenId) public onlyOwner {
        require(!_exists(tokenId), "Token has already been minted");

        _safeMint(msg.sender, tokenId);

        emit ReserveCompleted(msg.sender, tokenId);
    }

    function numberBoredApesBought() public view returns (uint) {
        return _boredApeYachtClub.balanceOf(msg.sender);
    }

    function getNumberAvailableApes() public view returns (uint) {
        uint numberAvailable = 0;
        uint numberBAYC = numberBoredApesBought();

        for (uint i= 0; i < numberBAYC; i++) {
            uint tokenIndex = _boredApeYachtClub.tokenOfOwnerByIndex(msg.sender, i);
            if (!_exists(tokenIndex)) {
                numberAvailable++;
            }
        }

        return numberAvailable;
    }

    function random(uint range, uint nonce) public view returns (uint) {
        uint randomNumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) % range;
        return randomNumber;
    }

    function purchase(uint numberOfTokens) public payable {
        require(_PRICE.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");
        require(_activeSale, "Sale must be active to mint");
        require(totalSupply().add(numberOfTokens) <= _maxSupply, "Minting would exceed max supply");

        uint numberBAYC = numberBoredApesBought();
        uint numberMinted = 0;

        uint startIndex = random(numberBAYC, numberBAYC);

        for (uint i = startIndex; i < numberBAYC + startIndex; i++) {

            uint tokenIndex = _boredApeYachtClub.tokenOfOwnerByIndex(msg.sender, i % numberBAYC);

            if (!_exists(tokenIndex)) {
                _safeMint(msg.sender, tokenIndex);

                numberMinted++;

                if (numberMinted == numberOfTokens) {
                    emit PurchaseCompleted(msg.sender, numberOfTokens, msg.value);
                    return;
                }
            }
        }

        // We can only reach this line if numberOfTokens is greater than the number of available tokens
        require(false, "Number of requested tokens exceeds available tokens");
    }

    function provenanceHash() public view virtual returns (string memory) {
        return _provenanceHash;
    }

    function price() public view virtual returns (uint) {
        return _PRICE;
    }

    function maxSupply() public view virtual returns (uint) {
        return _maxSupply;
    }

    function activeSale() public view virtual returns (bool) {
        return _activeSale;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);

        emit BaseURIUpdated(baseURI);
    }

    function setProvenanceHash(string memory newProvenanceHash) public onlyOwner {
        _provenanceHash = newProvenanceHash;

        emit ProvenanceHashUpdated(newProvenanceHash);
    }

    function setBoredApeYachtClubAddress(address boredApeYachtClubAddress) public onlyOwner {
        _boredApeYachtClub = BoredApeYachtClub(boredApeYachtClubAddress);

        emit BAYCAddressUpdated(boredApeYachtClubAddress);
    }
}