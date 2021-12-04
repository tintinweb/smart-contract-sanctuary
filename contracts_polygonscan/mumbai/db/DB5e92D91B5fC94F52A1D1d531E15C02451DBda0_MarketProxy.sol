// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IZoraAuctionHouse} from "./interfaces/IZoraAuctionHouse.sol";

/// @title MarketProxy
contract MarketProxy {
    // ============ Structs ============

    struct AuctionInfo {
        uint256 nftId;
        uint256 auctionId;
    }

    // ============ Variables ============

    // owner => AuctionInfo array
    mapping(address => AuctionInfo[]) public _myAuctions;

    address[] public _owners;

    address public immutable _nftToken; // NFT contract
    address public immutable _zoraMarket;

    // ============ Constructor function ============

    constructor(address market, address nftToken) {
        _zoraMarket = market;
        _nftToken = nftToken;
    }

    // ============ External functions ============

    function addAuction(
        uint256 nftId,
        uint256 auctionId,
        address owner
    ) external {
        IZoraAuctionHouse.Auction memory auctionInMarket = readAuction(auctionId);
        require(auctionInMarket.tokenOwner != address(0), "nonexist auction");
        require(auctionInMarket.tokenContract == _nftToken, "wrong tokenContract");
        require(auctionInMarket.tokenId == nftId, "wrong tokenId");

        if (owner == address(0)) {
            owner = msg.sender;
        }

        AuctionInfo memory info = AuctionInfo({nftId: nftId, auctionId: auctionId});
        AuctionInfo[] storage actions = _myAuctions[owner];
        actions.push(info);

        _addOwner(owner);
    }

    function getAuction(address owner) external returns (AuctionInfo[] memory) {
        AuctionInfo[] storage actions = _myAuctions[owner];
        uint256 count = actions.length;

        for (uint256 i = 0; i < count; ) {
            uint256 actionId = actions[i].auctionId;
            IZoraAuctionHouse.Auction memory auctionInMarket = readAuction(actionId);
            if (auctionInMarket.tokenOwner == address(0)) {
                count--;
                if (i != count) {
                    actions[i] = actions[count];
                } else {
                    i++;
                }
                actions.pop();
            } else {
                i++;
            }
        }

        return actions;
    }

    function scanMarket(uint256 beginId, uint256 endId) external {
        for (uint256 i = beginId; i <= endId; i++) {
            IZoraAuctionHouse.Auction memory auctionInMarket = readAuction(i);
            address owner = auctionInMarket.tokenOwner;
            if (auctionInMarket.tokenContract == _nftToken) {
                bool found = false;
                AuctionInfo[] storage actions = _myAuctions[owner];
                for (uint256 j = 0; j < actions.length; j++) {
                    if (auctionInMarket.tokenId == actions[j].nftId) {
                        found = true;
                        break;
                    }
                }

                if (!found) {
                    AuctionInfo memory info = AuctionInfo({nftId: auctionInMarket.tokenId, auctionId: i});
                    actions.push(info);
                    _addOwner(owner);
                }
            }
        }
    }

    // ========== Public functions ==========

    function readAuction(uint256 auctionId) public returns (IZoraAuctionHouse.Auction memory result) {
        (bool success, bytes memory returnData) = _zoraMarket.call(abi.encodeWithSignature("auctions(uint256)", auctionId));

        if (!success) {
            revert(_getRevertMsg(returnData));
        }

        result = abi.decode(returnData, (IZoraAuctionHouse.Auction));
    }

    // ========== Internal functions ==========

    /// @return revertMsg Revert message
    function _getRevertMsg(bytes memory revertData) internal pure returns (string memory revertMsg) {
        uint256 dataLen = revertData.length;

        if (dataLen < 68) {
            revertMsg = "Transaction reverted silently";
        } else {
            uint256 t;
            assembly {
                revertData := add(revertData, 4)
                t := mload(revertData) // Save the content of the length slot
                mstore(revertData, sub(dataLen, 4)) // Set proper length
            }
            revertMsg = abi.decode(revertData, (string));
            assembly {
                mstore(revertData, t) // Restore the content of the length slot
            }
        }
    }

    function _addOwner(address owner) internal {
        for (uint256 i = 0; i < _owners.length; i++) {
            if (_owners[i] == owner) {
                return;
            }
        }

        _owners.push(owner);
    }
}

// SPDX-License-Identifier: GPL-3.0
// Reproduced from https://github.com/ourzora/auction-house/blob/main/contracts/interfaces/IAuctionHouse.sol under terms of GPL-3.0
// Modified slightly

pragma solidity ^0.8.0;

/**
 * @title Interface for Auction Houses
 */
interface IZoraAuctionHouse {
    struct Auction {
        // ID for the ERC721 token
        uint256 tokenId;
        // Address for the ERC721 contract
        address tokenContract;
        // Whether or not the auction curator has approved the auction to start
        bool approved;
        // The current highest bid amount
        uint256 amount;
        // The length of time to run the auction for, after the first bid was made
        uint256 duration;
        // The time of the first bid
        uint256 firstBidTime;
        // The minimum price of the first bid
        uint256 reservePrice;
        // The sale percentage to send to the curator
        uint8 curatorFeePercentage;
        // The address that should receive the funds once the NFT is sold.
        address tokenOwner;
        // The address of the current highest bid
        address payable bidder;
        // The address of the auction's curator.
        // The curator can reject or approve an auction
        address payable curator;
        // The address of the ERC-20 currency to run the auction with.
        // If set to 0x0, the auction will be run in ETH
        address auctionCurrency;
    }

    event AuctionCreated(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        uint256 duration,
        uint256 reservePrice,
        address tokenOwner,
        address curator,
        uint8 curatorFeePercentage,
        address auctionCurrency
    );

    event AuctionApprovalUpdated(uint256 indexed auctionId, uint256 indexed tokenId, address indexed tokenContract, bool approved);

    event AuctionReservePriceUpdated(uint256 indexed auctionId, uint256 indexed tokenId, address indexed tokenContract, uint256 reservePrice);

    event AuctionBid(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        address sender,
        uint256 value,
        bool firstBid,
        bool extended
    );

    event AuctionDurationExtended(uint256 indexed auctionId, uint256 indexed tokenId, address indexed tokenContract, uint256 duration);

    event AuctionEnded(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        address tokenOwner,
        address curator,
        address winner,
        uint256 amount,
        uint256 curatorFee,
        address auctionCurrency
    );

    event AuctionCanceled(uint256 indexed auctionId, uint256 indexed tokenId, address indexed tokenContract, address tokenOwner);

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

    function setAuctionReservePrice(uint256 auctionId, uint256 reservePrice) external;

    function createBid(uint256 auctionId, uint256 amount) external payable;

    function endAuction(uint256 auctionId) external;

    function cancelAuction(uint256 auctionId) external;
}