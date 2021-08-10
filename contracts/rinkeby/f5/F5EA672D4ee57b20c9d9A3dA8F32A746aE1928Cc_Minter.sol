// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

import {SplitStorage} from "./SplitStorage.sol";

// Zora Market, Media, and AuctionHouse Contract Interface
interface IZora {
    // D256
    struct D256 {
        uint256 value;
    }
    // Market
    struct Bid {
        uint256 amount;
        address currency;
        address bidder;
        address recipient;
        D256 sellOnShare;
    }
    struct Ask {
        uint256 amount;
        address currency;
    }
    struct BidShares {
        D256 prevOwner;
        D256 creator;
        D256 owner;
    }

    function setBidShares(uint256 tokenId, BidShares calldata bidShares)
        external;

    function setAsk(uint256 tokenId, Ask calldata ask) external;

    function removeAsk(uint256 tokenId) external;

    function setBid(
        uint256 tokenId,
        Bid calldata bid,
        address spender
    ) external;

    function removeBid(uint256 tokenId, address bidder) external;

    function acceptBid(uint256 tokenId, Bid calldata expectedBid) external;

    // Media
    struct EIP712Signature {
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }
    struct MediaData {
        string tokenURI;
        string metadataURI;
        bytes32 contentHash;
        bytes32 metadataHash;
    }

    function mint(MediaData calldata data, BidShares calldata bidShares)
        external;

    function mintWithSig(
        address creator,
        MediaData calldata data,
        BidShares calldata bidShares,
        EIP712Signature calldata sig
    ) external;

    function auctionTransfer(uint256 tokenId, address recipient) external;

    function setBid(uint256 tokenId, Bid calldata bid) external;

    function removeBid(uint256 tokenId) external;

    function revokeApproval(uint256 tokenId) external;

    function updateTokenURI(uint256 tokenId, string calldata tokenURI) external;

    function updateTokenMetadataURI(
        uint256 tokenId,
        string calldata metadataURI
    ) external;

    // AuctionHouse
    struct Auction {
        uint256 tokenId;
        address tokenContract;
        bool approved;
        uint256 amount;
        uint256 duration;
        uint256 firstBidTime;
        uint256 reservePrice;
        uint8 curatorFeePercentage;
        address tokenOwner;
        address payable bidder;
        address payable curator;
        address auctionCurrency;
    }

    function createAuction(
        uint256 tokenId,
        address tokenContract,
        uint256 duration,
        uint256 reservePrice,
        address payable curator,
        uint8 curatorFeePercentages,
        address auctionCurrency
    ) external returns (uint256);

    function setAuctionApproval(uint256 auctionId, bool approved) external;

    function setAuctionReservePrice(uint256 auctionId, uint256 reservePrice)
        external;

    function createBid(uint256 auctionId, uint256 amount) external payable;

    function endAuction(uint256 auctionId) external;

    function cancelAuction(uint256 auctionId) external;
}

// Basic ERC-721 Interface
interface IERC721 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function setApprovalForAll(address operator, bool _approved) external;

    function tokenByIndex(uint256 index) external view returns (uint256);
}

interface IERC20 {
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function totalSupply() external view returns (uint256);
}

contract Minter is SplitStorage {
    // event ProxyReceivedNFT(uint256 tokenId);

    //======== Immutable storage =========
    address public immutable zoraMedia;
    address public immutable zoraMarket;
    address public immutable auctionHouse;

    constructor(
        address zoraMedia_,
        address zoraMarket_,
        address auctionHouse_,
        address wethAddress_
    ) {
        zoraMedia = zoraMedia_;
        zoraMarket = zoraMarket_;
        auctionHouse = auctionHouse_;
        wethAddress = wethAddress_;
    }

    /**
     * Approve the splitOwner and Zora Auction House to manage Split's ERC-721s
     * Called in Proxy's constructor
     */
    function setApprovalsForSplit(address splitOwner) external {
        IERC721(zoraMedia).setApprovalForAll(splitOwner, true);
        IERC721(zoraMedia).setApprovalForAll(auctionHouse, true);
    }

    /**
     * Update Zora Approvals upon Proxy's transferOwnership()
     */
    function updateApprovalsForSplit(
        address oldSplitOwner,
        address newSplitOwner
    ) external {
        IERC721(zoraMedia).setApprovalForAll(oldSplitOwner, false);
        IERC721(zoraMedia).setApprovalForAll(newSplitOwner, true);
    }

    // function updateTokenId(uint256 tokenId_) internal {
    //     emit ProxyReceivedNFT(tokenId_);
    //     _tokenId = tokenId_;
    // }

    // Mints a Zora NFT with this Split as the Creator and Then create an auction
    function mintToAuction(
        IZora.MediaData calldata mediaData,
        IZora.BidShares calldata bidShares,
        uint256 duration,
        uint256 reservePrice,
        address payable curator,
        uint8 curatorFeePercentages,
        address auctionCurrency
    ) external {
        require(
            auctionCurrency == 0x0000000000000000000000000000000000000000 ||
                auctionCurrency == wethAddress
        );
        IZora(zoraMedia).mint(mediaData, bidShares);
        uint256 index = IERC20(zoraMedia).totalSupply() - 1;
        uint256 tokenId_ = IERC721(zoraMedia).tokenByIndex(index);
        IZora(auctionHouse).createAuction(
            tokenId_,
            zoraMedia,
            duration,
            reservePrice,
            curator,
            curatorFeePercentages,
            auctionCurrency
        );
    }

    function cancelAuction(uint256 auctionId) external {
        IZora(auctionHouse).cancelAuction(auctionId);
    }

    function setAuctionApproval(uint256 auctionId, bool approved) external {
        IZora(auctionHouse).setAuctionApproval(auctionId, approved);
    }

    function setAuctionReservePrice(uint256 auctionId, uint256 reservePrice)
        external
    {
        IZora(auctionHouse).setAuctionReservePrice(auctionId, reservePrice);
    }

    function isApprovedForAll(address creator, address notCreator)
        external
        view
        returns (bool)
    {
        return IERC721(zoraMedia).isApprovedForAll(creator, notCreator);
        // return isApproved;
    }

    // In case ERC721 gets stuck in Account
    function safeTransferNFT(
        uint256 tokenId,
        address tokenContract,
        address newOwner
    ) external {
        IERC721(tokenContract).safeTransferFrom(
            address(this),
            newOwner,
            tokenId
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

/**
 * @title SplitStorage
 * @author MirrorXYZ
 *
 * Modified to store:
 * address of the deployed Minter Contract
 *
 */
contract SplitStorage {
    bytes32 public merkleRoot;
    uint256 public currentWindow;

    address internal wethAddress;
    address internal _splitter;
    address internal _minter;

    uint256[] public balanceForWindow;
    mapping(bytes32 => bool) internal claimed;
    uint256 internal depositedInWindow;
}

{
  "optimizer": {
    "enabled": true,
    "runs": 2000
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}