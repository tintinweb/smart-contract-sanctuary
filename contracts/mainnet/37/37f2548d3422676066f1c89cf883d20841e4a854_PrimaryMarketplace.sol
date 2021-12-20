// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ReentrancyGuard.sol";
import "./Context.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./ECDSA.sol";

import "./IHabitatNFT.sol";
import "./IAggregatorPrice.sol";
import "./EditionRoyalty.sol";

contract PrimaryMarketplace is ReentrancyGuard, Context {
    using ECDSA for bytes32;
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    IAggregatorPrice private priceFeed;

    struct Edition {
        uint256 itemId;
        address nftContract;
        uint256 tokenId;
        uint256 totalAmount;
        uint256 availableAmount;
        address payable seller;
        uint256 price;
        uint256 royalty;
    }

    struct Auction {
        bool isAuction;
        bool transfered;
    }

    address payable private owner;

    mapping(uint256 => Edition) private idToEdition;
    mapping(uint256 => Auction) private itemIdToAuction;
    mapping(address => bool) private creatorsWhitelist;

    modifier onlyOwner() {
        require(_msgSender() == owner, "Only Habitat can execute this");
        _;
    }

    modifier onlyOwnerOrCreator() {
        require(
            creatorsWhitelist[_msgSender()] || _msgSender() == owner,
            "Only Habitat and Habitat's creators can execute this"
        );
        _;
    }

    modifier onlyAvailableEdition(uint256 itemId) {
        require(
            idToEdition[itemId].nftContract != address(0),
            "Item doensn't exist"
        );
        _;
    }

    modifier onlyNonClaimableEdition(uint256 itemId) {
        require(idToEdition[itemId].price > 0, "Can't buy this edition");
        _;
    }

    modifier onlyCorrectPriceForEdition(uint256 itemId, uint256 amount) {
        uint256 pricePerItemInUSD = idToEdition[itemId].price;
        uint256 pricePerItem = pricePerItemInUSD.mul(priceInWEI());
        uint256 price = pricePerItem.mul(amount);
        require(
            msg.value >= price,
            "Please submit the asking price in order to complete the purchase"
        );
        _;
    }

    modifier onlyNonAuction(uint256 itemId) {
        require(
            itemIdToAuction[itemId].isAuction == false,
            "Can't buy this edition"
        );
        _;
    }

    modifier onlyAuction(uint256 itemId) {
        require(
            itemIdToAuction[itemId].isAuction == true,
            "This auction edition doesn't exist"
        );
        _;
    }

    modifier onlyActiveAuction(uint256 itemId) {
        require(
            itemIdToAuction[itemId].transfered == false,
            "This auction edition is not active"
        );
        _;
    }

    constructor(address priceAggregatorAddress) {
        owner = payable(msg.sender);
        priceFeed = IAggregatorPrice(priceAggregatorAddress);
    }

    receive() external payable {}

    fallback() external payable {}

    function addCreator(address creator) external onlyOwner {
        creatorsWhitelist[creator] = true;
    }

    function addEdition(
        address nftContract,
        uint256 tokenId,
        uint256 amount,
        uint256 price,
        uint256 royalty,
        bool isHighestBidAuction
    ) external nonReentrant onlyOwnerOrCreator {
        _itemIds.increment();
        uint256 itemId = _itemIds.current();

        EditionRoyalty.Royalty memory editionRoyalty = EditionRoyalty.Royalty(
            payable(_msgSender()),
            royalty
        );

        IHabitatNFT(nftContract).mint(
            _msgSender(),
            tokenId,
            amount,
            editionRoyalty,
            ""
        );

        idToEdition[itemId] = Edition(
            itemId,
            nftContract,
            tokenId,
            amount,
            amount,
            payable(_msgSender()),
            price,
            royalty
        );

        if (isHighestBidAuction == true) {
            itemIdToAuction[itemId] = Auction(true, false);
        }

        emit EditionAdded(
            itemId,
            nftContract,
            tokenId,
            amount,
            _msgSender(),
            price
        );
    }

    function transferEdition(
        uint256 itemId,
        uint256 amount,
        address receiver
    )
        external
        nonReentrant
        onlyOwner
        onlyAvailableEdition(itemId)
        onlyNonAuction(itemId)
    {
        _safeTransfer(itemId, amount, receiver);
        emit EditionTransfered(itemId, receiver);
    }

    function transferAuction(uint256 itemId, address receiver)
        external
        nonReentrant
        onlyOwner
        onlyAuction(itemId)
        onlyActiveAuction(itemId)
    {
        _safeTransfer(itemId, 1, receiver);
        itemIdToAuction[itemId].transfered = true;
        emit AuctionTransfered(itemId, receiver);
    }

    function burnToken(uint256 itemId) external onlyOwnerOrCreator {
        uint256 amount = idToEdition[itemId].availableAmount;
        IHabitatNFT(idToEdition[itemId].nftContract).burn(
            idToEdition[itemId].seller,
            idToEdition[itemId].tokenId,
            amount
        );
        idToEdition[itemId].availableAmount.sub(amount);
        emit BurnedEdition(itemId, amount);
    }

    function itemPrice(uint256 itemId)
        external
        view
        onlyAvailableEdition(itemId)
        returns (uint256)
    {
        uint256 pricePerItemInUSD = idToEdition[itemId].price;
        uint256 pricePerItem = pricePerItemInUSD.mul(priceInWEI());
        return pricePerItem;
    }

    function fetchEditions() external view returns (Edition[] memory) {
        uint256 itemCount = _itemIds.current();
        uint256 currentIndex = 0;
        Edition[] memory items = new Edition[](itemCount);
        for (uint256 i = 0; i < itemCount; i++) {
            Edition memory currentItem = idToEdition[i + 1];
            items[currentIndex] = currentItem;
            currentIndex += 1;
        }
        return items;
    }

    function fetchCreatorEditions(address habitatNFTCreatorAddress)
        external
        view
        returns (Edition[] memory)
    {
        uint256 itemCount = _itemIds.current();
        uint256 resultCount = 0;
        uint256 currentIndex = 0;
        for (uint256 i = 0; i < itemCount; i++) {
            if (idToEdition[i + 1].nftContract == habitatNFTCreatorAddress) {
                resultCount += 1;
            }
        }
        Edition[] memory result = new Edition[](resultCount);
        for (uint256 i = 0; i < itemCount; i++) {
            if (idToEdition[i + 1].nftContract == habitatNFTCreatorAddress) {
                Edition memory currentItem = idToEdition[i + 1];
                result[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return result;
    }

    function buyEdition(uint256 itemId, uint256 amount)
        external
        payable
        nonReentrant
        onlyAvailableEdition(itemId)
        onlyNonAuction(itemId)
        onlyNonClaimableEdition(itemId)
        onlyCorrectPriceForEdition(itemId, amount)
    {
        _safeTransfer(itemId, amount, _msgSender());
        payable(idToEdition[itemId].seller).transfer(msg.value);
        emit EditionBought(itemId, _msgSender(), msg.value);
    }

    function hashTransaction(address account, uint256 price)
        internal
        pure
        returns (bytes32)
    {
        bytes32 dataHash = keccak256(abi.encodePacked(account, price));
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash)
            );
    }

    function recoverSignerAddress(
        address account,
        uint256 price,
        bytes memory signature
    ) internal pure returns (address) {
        bytes32 hash = hashTransaction(account, price);
        return hash.recover(signature);
    }

    function payForBid(
        uint256 itemId,
        uint256 price,
        bytes memory signature
    ) external payable nonReentrant onlyActiveAuction(itemId) {
        address verifiedSigner = recoverSignerAddress(
            _msgSender(),
            price,
            signature
        );

        require(verifiedSigner == owner, "You chan't buy this");
        require(
            msg.value >= price * priceInWEI(),
            "Please submit the asking price in order to complete the purchase"
        );

        _safeTransfer(itemId, 1, _msgSender());
        itemIdToAuction[itemId].transfered = true;
        payable(idToEdition[itemId].seller).transfer(msg.value);
        emit WinnerPaidForBid(itemId, _msgSender(), msg.value);
    }

    function _safeTransfer(
        uint256 itemId,
        uint256 amount,
        address receiver
    ) internal {
        uint256 availableAmount = idToEdition[itemId].availableAmount;
        require(availableAmount > 0, "Sold out");
        require(availableAmount >= amount, "Not available quantity");
        IHabitatNFT(idToEdition[itemId].nftContract).safeTransferFrom(
            idToEdition[itemId].seller,
            receiver,
            idToEdition[itemId].tokenId,
            amount,
            ""
        );
        idToEdition[itemId].availableAmount -= amount;
    }

    function _priceOfETH() private view returns (uint256) {
        (
            uint80 roundID,
            int256 price,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        (roundID, startedAt, timeStamp, answeredInRound);
        return uint256(price);
    }

    function priceInWEI() public view returns (uint256) {
        return uint256(10**18 / uint256(_priceOfETH() / 10**_decimals()));
    }

    function _decimals() private view returns (uint256) {
        uint256 decimals = uint256(priceFeed.decimals());
        return decimals;
    }

    event EditionAdded(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        uint256 amount,
        address seller,
        uint256 price
    );
    event EditionBought(
        uint256 indexed itemId,
        address indexed receiver,
        uint256 price
    );
    event EditionTransfered(uint256 indexed itemId, address indexed receiver);
    event AuctionTransfered(uint256 indexed itemId, address indexed receiver);
    event BurnedEdition(uint256 indexed itemId, uint256 amount);
    event WinnerPaidForBid(
        uint256 indexed itemId,
        address indexed winner,
        uint256 indexed bidAmount
    );
}