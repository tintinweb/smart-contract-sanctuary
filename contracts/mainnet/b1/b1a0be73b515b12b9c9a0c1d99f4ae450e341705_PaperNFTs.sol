// SPDX-License-Identifier: MIT

// Adapted from BoringBananasCo
// Modified and updated to 0.8.0 by @Danny_One_
// Paper NFTs by @chapeljuice
// Smart Contract by @Danny_One_ and modified by @chapeljuice to fit Paper NFTs
// Special thanks to @Danny_One_ and BoringBananasCo for all the resources & assistance along the way!

import "./ERC721_flat.sol";

pragma solidity ^0.8.0;
pragma abicoder v2;

contract PaperNFTs is ERC721, Ownable, nonReentrant {
    string public PAPER_NFTS_PROVENANCE = ""; // IPFS URL WILL BE ADDED WHEN PAPER NFTS ARE ALL SOLD OUT

    uint256 public paperNFTPrice = 77000000000000000; // 0.077 ETH

    uint256 public constant maxPaperNFTPurchase = 20;

    uint256 public constant MAX_PAPER_NFTS = 7777;

    bool public saleIsActive = false;

    // Reserve 100 PaperNFTs for team - Giveaways/Prizes etc
    uint256 public constant MAX_PAPERNFT_RESERVES = 100; // total team reserves allowed
    uint256 public paperNFTReserves = MAX_PAPERNFT_RESERVES; // counter for team reserves remaining

    constructor() ERC721("Paper NFTs", "PNFT") {}

    // withraw to project wallet
    function withdraw(uint256 _amount, address payable _owner)
        public
        onlyOwner
    {
        require(_owner == owner());
        require(_amount < address(this).balance + 1);
        _owner.transfer(_amount);
    }

    // withdraw to team
    function teamWithdraw(address payable _team1, address payable _team2)
        public
        onlyOwner
    {
        uint256 balance1 = (address(this).balance / 10) * 9; // 90%
        uint256 balance2 = address(this).balance - balance1; // 10%
        _team1.transfer(balance1);
        _team2.transfer(balance2);
    }

    function setPaperNFTPrice(uint256 _paperNFTPrice) public onlyOwner {
        paperNFTPrice = _paperNFTPrice;
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        PAPER_NFTS_PROVENANCE = provenanceHash;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }
    
    function reservePaperNFTs(address _to, uint256 _reserveAmount) public onlyOwner {        
        uint reserveMint = MAX_PAPERNFT_RESERVES - paperNFTReserves; // Mint from beginning of tokenIds
        require(_reserveAmount > 0 && _reserveAmount <= paperNFTReserves, "Not enough reserve left to fulfill amount");
        for (uint i = 0; i < _reserveAmount; i++) {
            _safeMint(_to, reserveMint + i);
        }
        paperNFTReserves = paperNFTReserves - _reserveAmount;
    }

    function mintPaperNFT(uint256 numberOfTokens) public payable reentryLock {
        require(saleIsActive, "Sale must be active to mint Paper NFTs.");
        require(
            numberOfTokens > 0 && numberOfTokens < maxPaperNFTPurchase + 1,
            "Can only mint 17 tokens at a time"
        );
        require(
            totalSupply() + numberOfTokens <= MAX_PAPER_NFTS - paperNFTReserves,
            "Purchase would exceed max supply of Paper NFTs."
        );
        require(
            msg.value >= paperNFTPrice * numberOfTokens,
            "Ether value sent is not correct."
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = totalSupply() + paperNFTReserves; // start minting after reserved tokenIds
            if (totalSupply() < MAX_PAPER_NFTS) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }
}