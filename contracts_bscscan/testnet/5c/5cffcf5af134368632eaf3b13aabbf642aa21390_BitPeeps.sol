//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/*
 * The MarketPlace and NFT holder contract for BitPeeps.
 * All 25.000 ever to exist BitPeeps is generated through a logarithmic
 * randomizer to guarantuee that no BitPeep is any other alike.
 *
 * The first 1000 BitPeeps will be free of charge. The rest will charge
 * minting cost.
 *
 * Mint and start holding your BitPeeps before everyone else at https://bitpeeps.io
 *
 */

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Counters.sol";
import "./Address.sol";

contract BitPeeps is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Address for address;

    string private _name = "BitPeeps";
    string private _symbol = "BTPPS";
    uint256 private _maxSupply = 25000;
    uint256 private _maxFreePeeps = 1000; // Will forever only be 1000 free BitPeeps
    uint256 private _maxDevPeeps = 500; // Only 500 will be allowed to mint for free for devs
    uint256 private _peepsToMint = _maxSupply;
    uint256 private _mintedDevPeeps = 0;

    bool public marketOpen = false;
    bool public mintingOpen = false;

    constructor() ERC721(_name, _symbol) {}

    struct _offer {
        bool isForSale;
        uint256 peepIndex;
        address seller;
        uint256 price; // in bnb
        address onlySellTo; // specify to sell only to a specific person
    }

    struct _bid {
        bool hasBid;
        uint256 peepIndex;
        address bidder;
        uint256 bid; // in bnb
    }

    mapping(uint256 => address) public _mintedByAddress;
    mapping(uint256 => string) private _peepLinks;
    mapping(uint256 => _offer) public _offers;
    mapping(uint256 => _bid) public _bids;

    event bitPeepEvent(
        uint256 indexed peepIndex,
        uint256 indexed eventType,
        uint256 value,
        address fromAddress,
        address toAddress
    );

    function openMarket() public virtual onlyOwner {
        marketOpen = true;
    }

    function openMinting() public virtual onlyOwner {
        mintingOpen = true;
    }

    function maxSupply() public view virtual returns (uint256) {
        return _maxSupply;
    }

    function peepsToMint() public view virtual returns (uint256) {
        return _peepsToMint;
    }

    function peepsMinted() public view virtual returns (uint256) {
        return _maxSupply - _peepsToMint;
    }

    function offerForSale(uint256 peepIndex, uint256 minPriceInWei)
        public
        virtual
    {
        require(marketOpen, "Market not open.");
        require(_exists(peepIndex), "Invalid BitPeep");
        require(ownerOf(peepIndex) == msg.sender, "Not owner");
        require(!_offers[peepIndex].isForSale, "Already on sale");
        _offers[peepIndex] = _offer(
            true,
            peepIndex,
            msg.sender,
            minPriceInWei,
            address(0)
        );
        emit bitPeepEvent(peepIndex, 1, minPriceInWei, address(0), address(0));
    }

    function offerForSaleModifyPrice(uint256 peepIndex, uint256 minPriceInWei)
        public
        virtual
    {
        require(marketOpen, "Market not open.");
        require(_exists(peepIndex), "Invalid BitPeep");
        require(ownerOf(peepIndex) == msg.sender, "Not owner");
        require(_offers[peepIndex].isForSale, "Not on sale");
        _offers[peepIndex].price = minPriceInWei;
        emit bitPeepEvent(
            peepIndex,
            2,
            minPriceInWei,
            address(0),
            _offers[peepIndex].onlySellTo
        );
    }

    function offerForSaleToBuyer(
        uint256 peepIndex,
        uint256 minPriceInWei,
        address buyerAddress
    ) public virtual {
        require(marketOpen, "Market not open.");
        require(_exists(peepIndex), "Invalid BitPeep");
        require(ownerOf(peepIndex) == msg.sender, "Not owner");
        require(ownerOf(peepIndex) != buyerAddress, "Cannot sell to yourself");
        require(!_offers[peepIndex].isForSale, "Already on sale");
        _offers[peepIndex] = _offer(
            true,
            peepIndex,
            msg.sender,
            minPriceInWei,
            buyerAddress
        );
        emit bitPeepEvent(
            peepIndex,
            1,
            minPriceInWei,
            address(0),
            buyerAddress
        );
    }

    function removeOfferForSale(uint256 peepIndex) public virtual {
        require(marketOpen, "Market not open.");
        require(_exists(peepIndex), "Invalid BitPeep");
        require(ownerOf(peepIndex) == msg.sender, "Not owner");
        require(_offers[peepIndex].isForSale, "Not on sale");
        _offers[peepIndex] = _offer(
            false,
            peepIndex,
            address(0),
            0,
            address(0)
        );
        emit bitPeepEvent(peepIndex, 3, 0, address(0), address(0));
    }

    function bidForBitPeep(uint256 peepIndex)
        public
        payable
        virtual
        nonReentrant
    {
        require(marketOpen, "Market not open.");
        require(_exists(peepIndex), "Invalid BitPeep");
        require(
            ownerOf(peepIndex) != msg.sender,
            "Cannot bid on your own BitPeeps"
        );
        require(msg.value > _bids[peepIndex].bid, "Not highest bid");
        if (_bids[peepIndex].bid > 0) {
            payable(_bids[peepIndex].bidder).transfer(_bids[peepIndex].bid);
            emit bitPeepEvent(
                peepIndex,
                6,
                _bids[peepIndex].bid,
                msg.sender,
                address(0)
            );
        }
        emit bitPeepEvent(peepIndex, 4, msg.value, msg.sender, address(0));
        if (
            _offers[peepIndex].isForSale &&
            _offers[peepIndex].seller == ownerOf(peepIndex) &&
            msg.value >= _offers[peepIndex].price &&
            (_offers[peepIndex].onlySellTo == address(0) ||
                _offers[peepIndex].onlySellTo == msg.sender)
        ) {
            _bids[peepIndex] = _bid(false, peepIndex, address(0), 0);
            payable(_offers[peepIndex].seller).transfer(msg.value);
            _transfer(_offers[peepIndex].seller, msg.sender, peepIndex);
            emit bitPeepEvent(
                peepIndex,
                5,
                msg.value,
                _offers[peepIndex].seller,
                msg.sender
            );
            _offers[peepIndex] = _offer(
                false,
                peepIndex,
                address(0),
                0,
                address(0)
            );
        } else {
            _bids[peepIndex] = _bid(true, peepIndex, msg.sender, msg.value);
        }
    }

    function buyBitPeep(uint256 peepIndex) public payable virtual nonReentrant {
        require(marketOpen, "Market not open.");
        require(_exists(peepIndex), "Invalid BitPeep");
        require(
            ownerOf(peepIndex) != msg.sender,
            "Cannot buy your own BitPeeps"
        );
        require(_offers[peepIndex].isForSale, "BitPeep not for sale");
        require(
            (_offers[peepIndex].onlySellTo == address(0) ||
                _offers[peepIndex].onlySellTo == msg.sender),
            "Not to be sold to this user"
        );
        require(
            msg.value >= _offers[peepIndex].price,
            "Did not send enough payment"
        );
        require(
            _offers[peepIndex].seller == ownerOf(peepIndex),
            "Seller is not the owner"
        );
        address seller = _offers[peepIndex].seller;
        payable(_offers[peepIndex].seller).transfer(msg.value);
        _transfer(_offers[peepIndex].seller, msg.sender, peepIndex);
        _offers[peepIndex] = _offer(
            false,
            peepIndex,
            address(0),
            0,
            address(0)
        );
        emit bitPeepEvent(peepIndex, 5, msg.value, seller, msg.sender);
        if (_bids[peepIndex].bidder == msg.sender) {
            payable(msg.sender).transfer(_bids[peepIndex].bid);
            _bids[peepIndex] = _bid(false, peepIndex, address(0), 0);
        }
    }

    function cancelBidForBitPeep(uint256 peepIndex)
        public
        virtual
        nonReentrant
    {
        require(marketOpen, "Market not open.");
        require(_exists(peepIndex), "Invalid BitPeep");
        require(
            ownerOf(peepIndex) != msg.sender,
            "Cannot withdraw bid on your own BitPeeps"
        );
        require(
            _bids[peepIndex].bidder == msg.sender,
            "You are not the bidder"
        );
        payable(msg.sender).transfer(_bids[peepIndex].bid);
        emit bitPeepEvent(
            peepIndex,
            6,
            _bids[peepIndex].bid,
            msg.sender,
            address(0)
        );
        _bids[peepIndex] = _bid(false, peepIndex, address(0), 0);
    }

    function acceptBidForBitPeep(uint256 peepIndex, uint256 minPriceInWei)
        public
        virtual
        nonReentrant
    {
        require(marketOpen, "Market not open.");
        require(_exists(peepIndex), "Invalid BitPeep");
        require(
            ownerOf(peepIndex) == msg.sender,
            "Not your BitPeep to accept bid."
        );
        require(_bids[peepIndex].bid > 0, "Invalid bid");
        require(_bids[peepIndex].bid >= minPriceInWei, "Bid to low");
        payable(msg.sender).transfer(_bids[peepIndex].bid);
        _transfer(msg.sender, _bids[peepIndex].bidder, peepIndex);
        emit bitPeepEvent(
            peepIndex,
            5,
            _bids[peepIndex].bid,
            msg.sender,
            _bids[peepIndex].bidder
        );
        _bids[peepIndex] = _bid(false, peepIndex, address(0), 0);
        _offers[peepIndex] = _offer(
            false,
            peepIndex,
            address(0),
            0,
            address(0)
        );
    }

    function getPeepsForOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 numPeeps = balanceOf(_owner);
        if (numPeeps == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](numPeeps);
            for (uint256 i = 0; i < numPeeps; i++) {
                result[i] = tokenOfOwnerByIndex(_owner, i);
            }
            return result;
        }
    }

    function transfer(uint256 peepIndex, address toAddress) public virtual {
        require(ownerOf(peepIndex) == msg.sender, "Not owner");
        _transfer(msg.sender, toAddress, peepIndex);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory baseURI = _baseURI();
        string memory peepLink = _peepLinks[tokenId];
        return string(abi.encodePacked(baseURI, peepLink));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return "ipfs://";
    }

    function mint(uint256 peepIndex, string memory peepLink)
        public
        payable
        virtual
        nonReentrant
    {
        _doMint(peepIndex, peepLink, false);
    }

    function mint(
        uint256 peepIndex,
        string memory peepLink,
        bool peepChoice
    ) public payable virtual nonReentrant {
        _doMint(peepIndex, peepLink, peepChoice);
    }

    function _doMint(
        uint256 peepIndex,
        string memory peepLink,
        bool peepChoice
    ) internal {
        require(mintingOpen, "Minting not open.");
        require(totalSupply() < _maxSupply, "All BitPeeps has been minted");
        require(!_exists(peepIndex), "BitPeep already minted");
        require(peepIndex > 0, "peepIndex to low");
        require(peepIndex <= _maxSupply, "peepIndex to high");
        bool freePeep = false;
        if (totalSupply() < _maxFreePeeps + _mintedDevPeeps) {
            // Max 3 free per account.
            if (balanceOf(msg.sender) < 3) {
                freePeep = true;
            }
        }
        if (!freePeep) {
            uint256 mintingCost = _mintingCost(totalSupply(), peepChoice);
            require(
                msg.value >= mintingCost,
                "The payment received is not enough for minting."
            );
            if (msg.value > mintingCost) {
                payable(msg.sender).transfer(msg.value - mintingCost);
            }
            //_mintingFees += mintingCost;
        } else {
            if (msg.value > 0) {
                payable(msg.sender).transfer(msg.value);
            }
        }
        _mint(peepIndex, peepLink);
    }

    function multiMint(uint256[] memory peepIndices, string[] memory peepLinks)
        public
        payable
        virtual
        nonReentrant
    {
        require(mintingOpen, "Minting not open.");
        uint256 _totalSupply = totalSupply();
        require(totalSupply() < _maxSupply, "All BitPeeps has been minted");
        require(peepLinks.length <= 20, "More than max allowed");
        uint256 n = peepLinks.length;
        if (n > _peepsToMint) {
            n = _peepsToMint;
        }
        uint256 mintingCost = _multiMintingCost(n, _totalSupply);
        require(
            msg.value >= mintingCost,
            "The payment received is not enough for minting."
        );
        if (msg.value > mintingCost) {
            payable(msg.sender).transfer(msg.value - mintingCost);
        }
        for (uint256 i = 0; i < n; i++) {
            if (
                !_exists(peepIndices[i]) &&
                peepIndices[i] >= 1 &&
                peepIndices[i] <= _maxSupply
            ) {
                _mint(peepIndices[i], peepLinks[i]);
            }
        }
    }

    function devMint(uint256[] memory peepIndices, string[] memory peepLinks)
        public
        virtual
        onlyOwner
        nonReentrant
    {
        require(totalSupply() < _maxSupply, "All BitPeeps has been minted");
        uint256 n = peepLinks.length;
        if (n > _peepsToMint) {
            n = _peepsToMint;
        }
        for (uint256 i = 0; i < n; i++) {
            if (!_exists(peepIndices[i])) {
                _mint(peepIndices[i], peepLinks[i]);
                _mintedDevPeeps += 1;
            }
        }
    }

    function withdrawFees() public virtual nonReentrant onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    // Internal minting function
    function _mint(uint256 peepIndex, string memory peepLink) internal {
        _safeMint(msg.sender, peepIndex);
        _peepLinks[peepIndex] = peepLink;
        _mintedByAddress[peepIndex] = msg.sender;
        _peepsToMint -= 1;
        if (totalSupply() >= _maxSupply) {
            mintingOpen = false;
        }
    }

    function getMintingCost() public view virtual returns (uint256) {
        uint256 totalSupply = totalSupply();
        return _mintingCost(totalSupply, false);
    }

    function getMintingCost(bool selectPeep)
        public
        view
        virtual
        returns (uint256)
    {
        uint256 totalSupply = totalSupply();
        return _mintingCost(totalSupply, selectPeep);
    }

    function getMultiMintingCost(uint256 peepAmount)
        public
        view
        virtual
        returns (uint256)
    {
        uint256 totalSupply = totalSupply();
        uint256 _peepAmount = peepAmount;
        if (_peepAmount > 20) {
            _peepAmount = 20;
        }
        return _multiMintingCost(_peepAmount, totalSupply);
    }

    function _multiMintingCost(uint256 _peepAmount, uint256 _totalSupply)
        internal
        view
        returns (uint256)
    {
        uint256 _totalCost = 0 ether;
        for (uint256 i = 0; i < _peepAmount; i++) {
            _totalCost += _mintingCost(_totalSupply, false);
        }
        return _totalCost;
    }

    function _mintingCost(uint256 _totalSupply, bool _specificPeep)
        internal
        view
        returns (uint256)
    {
        if (_specificPeep) {
            return 1.00 ether;
        } else if (_totalSupply <= _maxFreePeeps + _mintedDevPeeps) {
            return 0.02 ether;
        } else if (_totalSupply <= 3000) {
            return 0.04 ether;
        } else if (_totalSupply <= 4000) {
            return 0.06 ether;
        } else if (_totalSupply <= 6000) {
            return 0.08 ether;
        } else if (_totalSupply <= 8000) {
            return 0.10 ether;
        } else if (_totalSupply <= 10000) {
            return 0.12 ether;
        } else if (_totalSupply <= 12000) {
            return 0.16 ether;
        } else if (_totalSupply <= 14000) {
            return 0.18 ether;
        } else if (_totalSupply <= 16000) {
            return 0.20 ether;
        } else if (_totalSupply <= 18000) {
            return 0.22 ether;
        } else if (_totalSupply <= 20000) {
            return 0.24 ether;
        } else if (_totalSupply <= 22000) {
            return 0.26 ether;
        } else if (_totalSupply <= 24000) {
            return 0.28 ether;
        } else if (_totalSupply <= 25000) {
            return 0.30 ether;
        }
        return 0.00;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Enumerable) {
        _offers[tokenId] = _offer(false, tokenId, address(0), 0, address(0));
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}