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
}

contract Minter is SplitStorage {
    // event TokenReceived(uint256 tokenId);

    //======== Immutable storage =========
    address public immutable zoraMedia;
    address public immutable zoraMarket;
    address public immutable auctionHouse;
    // address public immutable wethAddress;

    uint256 internal _fakeId = 0;

    function fakeId() public view returns (uint256) {
        return _fakeId;
    }

    constructor(
        address zoraMedia_,
        address zoraMarket_,
        address auctionHouse_,
        address wethAddress_
    ) public {
        zoraMedia = zoraMedia_;
        zoraMarket = zoraMarket_;
        auctionHouse = auctionHouse_;
        wethAddress = wethAddress_;
    }

    // Approve an address (ie SplitManager, AuctionHouse) to manage Split's ERC-721s
    function setApprovalForSplit(address splitOwner_) external {
        IERC721(zoraMedia).setApprovalForAll(splitOwner_, true);
        IERC721(zoraMedia).setApprovalForAll(auctionHouse, true);
        // (bool success, bytes memory returndata) = address(zoraMedia)
        //     .delegatecall(
        //         abi.encodeWithSignature(
        //             "setApprovalForAll(address,bool)",
        //             splitOwner,
        //             approved
        //         )
        //     );
        // (bool success2, bytes memory returndata2) = address(zoraMedia)
        //     .delegatecall(
        //         abi.encodeWithSignature(
        //             "setApprovalForAll(address,bool)",
        //             auctionHouse,
        //             approved
        //         )
        //     );
        // require(success && success2);
    }

    function fakeEvent(uint256 fakeId_) public {
        // emit TokenReceived(fakeId_);
        _fakeId = fakeId_;
    }

    // Mints a Zora NFT with this Split as the Creator and then create an auction
    function mintToAuction(
        IZora.MediaData calldata mediaData,
        IZora.BidShares calldata bidShares,
        uint256 duration,
        uint256 reservePrice,
        address auctionCurrency
    ) external {
        require(
            auctionCurrency == 0x0000000000000000000000000000000000000000 ||
                auctionCurrency == wethAddress
        );
        IZora(zoraMedia).mint(mediaData, bidShares);
        IZora(auctionHouse).createAuction(
            1, //change
            zoraMedia,
            duration,
            reservePrice,
            payable(address(0)),
            0,
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

