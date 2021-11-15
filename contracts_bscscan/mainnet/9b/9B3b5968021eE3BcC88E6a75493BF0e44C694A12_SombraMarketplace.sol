pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface ISombraNFT {
    function minter(uint256 id) external returns (address);
}

// Not to be confused with the actual WETH contract. This is a simple
// contract to keep track of ETH/BNB the user is owned by the contract.
//
// The user can withdraw it at any moment, it's not a token, hence it's not
// transferable. The marketplace will automatically try to refund the ETH to
// the user (e.g outbid, NFT sold) with a gas limit. This is simply backup
// when the ETH/BNB could not be sent to the user/address. For example, if
// the user is a smart contract that uses a lot of gas on it's payable.
contract WrappedETH is ReentrancyGuard {
    mapping(address => uint256) public wethBalance;

    function claimBNB() external {
        uint256 refund = wethBalance[msg.sender];
        wethBalance[msg.sender] = 0;
        (bool success,) = msg.sender.call{value: refund}("");

        // If the tx failed, restore back their balance.
        if(!success) {
            wethBalance[msg.sender] = refund;
        }
    }

    // claimBNBForUser tries to payout the user's owned balance with
    // a gas limit. Does not throw if it failed to send.
    function claimBNBForUser(address user) public {
        uint256 refund = wethBalance[user];
        wethBalance[user] = 0;

        (bool success,) = user.call{value: refund, gas: 3500}("");

        // If the tx failed, restore back their balance.
        if(!success) {
            wethBalance[user] = refund;
        }
    }

    // rewardBNBToUser tries to send specified amount of BNB to the user.
    // If it cannot, it will add it to their balance. It will NOT throw.
    // Used for paying out other users safely, e.g when outbidding someone.
    function rewardBNBToUser(address user, uint256 amount) internal {
        (bool success,) = user.call{value: amount, gas: 3500}("");

        if(!success) {
            wethBalance[user] += amount;
        }
    }
}

contract Buyback {
    // Uniswap V2 Router address for buyback functionality.
    IUniswapV2Router02 public uniswapV2Router;
    // Keep store of the WETH address to save on gas.
    address WETH;

    // devWalletAddress is the Sombra development address for 10% fees, and buyback.
    address constant public devWalletAddress = 0x949d36d76236217D4Fae451000861B535D9500Ab;

    uint256 ethToBuybackWith = 0;

    event UniswapRouterUpdated(
        address newAddress
    );

    event SombraBuyback(
        uint256 ethSpent
    );

    function updateBuybackUniswapRouter(address newRouterAddress) internal {
        uniswapV2Router = IUniswapV2Router02(newRouterAddress);
        WETH = uniswapV2Router.WETH();

        emit UniswapRouterUpdated(newRouterAddress);
    }

    function buybackSombra() external {
        require(msg.sender == address(this), "can only be called by the contract");
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = 0x8ad8e9B85787ddd0D31b32ECF655E93bfc0747eF;

        uint256 amount = ethToBuybackWith;
        ethToBuybackWith = 0;

        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0, // accept any amount of Tokens
            path,
            devWalletAddress,
            block.timestamp
        );
        
        emit SombraBuyback(amount);
    }

    function swapETHForTokens(uint256 amount) internal {
        ethToBuybackWith += amount;
        // 500k gas is more than enough.
        try this.buybackSombra{gas: 500000}() {} catch {}
    }
}

contract SombraMarketplace is ReentrancyGuard, Ownable, WrappedETH, Buyback {
    // MarketItem consists of buy-now and bid items.
    // Auction refers to items that can be bid on.
    // An item can either be buy-now or bid, or both.
    struct MarketItem {
        uint256 tokenId;

        address payable seller;

        // If purchasePrice is non-0, item can be bought out-right for that price
        // if bidPrice is non-0, item can be bid upon.
        uint256 purchasePrice;
        uint256 bidPrice;

        uint8 state;
        uint64 listingCreationTime;
        uint64 auctionStartTime; // Set when first bid is received. 0 until then.
        uint64 auctionEndTime; // Initially it is the DURATION of the auction.
                               // After the first bid, it is set to the END time
                               // of the auction.

        // Defaults to 0. When 0, no bid has been placed yet.
        address payable highestBidder;
    }

    uint8 constant ON_MARKET = 0;
    uint8 constant SOLD = 1;
    uint8 constant CANCELLED = 2;

    // itemsOnMarket is a list of all items, historic and current, on the marketplace.
    // This includes items all of states, i.e items are never removed from this list.
    MarketItem[] public itemsOnMarket;

    // sombraNFTAddress is the address for the Sombra NFT address.
    address immutable public sombraNFTAddress;

    event AuctionItemAdded(
        uint256 marketId,
        uint256 tokenId,
        address tokenAddress,
        uint256 bidPrice,
        uint256 auctionDuration
    );

    event FixedPriceItemAdded(
        uint256 marketId,
        uint256 tokenId,
        address tokenAddress,
        uint256 purchasePrice
    );

    event ItemSold(
        uint256 marketId,
        uint256 tokenId,
        address buyer,
        uint256 purchasePrice,
        uint256 bidPrice
    );

    event HighestBidIncrease(
        uint256 marketId,
        address bidder,
        uint256 amount,
        uint256 auctionEndTime
    );

    event PriceReduction(
        uint256 marketId,
        uint256 newPurchasePrice,
        uint256 newBidPrice
    );

    event ItemPulledFromMarket(uint256 id);

    constructor(address _sombraNFTAddress, address _uniswapRouterAddress) {
        sombraNFTAddress = _sombraNFTAddress;
        
        updateBuybackUniswapRouter(_uniswapRouterAddress);
    }

    function updateUniswapRouter(address newRouterAddress) external onlyOwner {
        updateBuybackUniswapRouter(newRouterAddress);
    }

    function isMinter(uint256 id, address target) internal returns (bool) {
        ISombraNFT sNFT = ISombraNFT(sombraNFTAddress);
        return sNFT.minter(id) == target;
    }

    function minter(uint256 id) internal returns (address) {
        ISombraNFT sNFT = ISombraNFT(sombraNFTAddress);
        return sNFT.minter(id);
    }

    function handleFees(uint256 tokenId, uint256 amount, bool isMinterSale) internal returns (uint256) {
        uint256 buybackFee;
        if(!isMinterSale) {
            // In resale, 5% buyback and 5% to artist.
            // 90% to seller.
            buybackFee = amount * 5 / 100;

            uint256 artistFee = amount * 5 / 100;
            rewardBNBToUser(minter(tokenId), artistFee);
            amount = amount - artistFee;
        } else {
            // When it's the minter selling, they get 80%
            // 10% to buyback
            // 10% to SOMBRA dev wallet.
            buybackFee = amount * 10 / 100;
 
            uint256 devFee = amount * 10 / 100;
            rewardBNBToUser(devWalletAddress, devFee);
            amount = amount - devFee;
        }

        swapETHForTokens(buybackFee);
   
        return amount - buybackFee;
    }

    function createAuctionItem(
        uint256 tokenId,
        address seller,
        uint256 purchasePrice,
        uint256 startingBidPrice,
        uint256 biddingTime
    ) internal {
        itemsOnMarket.push(
            MarketItem(
                tokenId,
                payable(seller),
                purchasePrice,
                startingBidPrice,
                ON_MARKET,
                uint64(block.timestamp),
                uint64(0),
                uint64(biddingTime),
                payable(address(0))
            )
        );
    }
    
    // purchasePrice is the direct purchasing price. Starting bid price
    // is the starting price for bids. If purchase price is 0, item cannot
    // be bought directly. Similarly for startingBidPrice, if it's 0, item
    // cannot be bid upon. One of them must be non-zero.
    function listItemOnAuction(
        address tokenAddress,
        uint256 tokenId,
        uint256 purchasePrice,
        uint256 startingBidPrice,
        uint256 biddingTime
    )
        external
        returns (uint256)
    {
        IERC721 tokenContract = IERC721(tokenAddress);
        require(tokenContract.ownerOf(tokenId) == msg.sender, "Missing Item Ownership");
        require(tokenContract.getApproved(tokenId) == address(this), "Missing transfer approval");

        require(purchasePrice > 0 || startingBidPrice > 0, "Item must have a price");
        require(startingBidPrice == 0 || biddingTime > 3600, "Bidding time must be above one hour");

        uint256 newItemId = itemsOnMarket.length;
        createAuctionItem(
            tokenId,
            msg.sender,
            purchasePrice,
            startingBidPrice,
            biddingTime
        );
 
        IERC721(sombraNFTAddress).transferFrom(
            msg.sender,
            address(this),
            tokenId
        );

        if(purchasePrice > 0) {
            emit FixedPriceItemAdded(newItemId, tokenId, tokenAddress, purchasePrice);
        }

        if(startingBidPrice > 0) {
            emit AuctionItemAdded(
                newItemId,
                tokenId,
                sombraNFTAddress,
                startingBidPrice,
                biddingTime
            );
        }
        return newItemId;
    }

    function buyFixedPriceItem(uint256 id)
        external
        payable
        nonReentrant
    {
        require(id < itemsOnMarket.length, "Invalid id");
        MarketItem memory item = itemsOnMarket[id];

        require(item.state == ON_MARKET, "Item not for sale");

        require(msg.value >= item.purchasePrice, "Not enough funds sent");
        require(item.purchasePrice > 0, "Item does not have a purchase price.");

        require(msg.sender != item.seller, "Seller can't buy");

        item.state = SOLD;
        IERC721(sombraNFTAddress).safeTransferFrom(
            address(this),
            msg.sender,
            item.tokenId
        );
        
        uint256 netPrice = handleFees(item.tokenId, item.purchasePrice, isMinter(item.tokenId, item.seller));
        rewardBNBToUser(item.seller, netPrice);

        emit ItemSold(id, item.tokenId, msg.sender, item.purchasePrice, item.bidPrice);

        itemsOnMarket[id] = item;

        // If the user sent excess ETH/BNB, send any extra back to the user.
        uint256 refundableEther = msg.value - item.purchasePrice;
        if(refundableEther > 0) {
            rewardBNBToUser(msg.sender, refundableEther);
        }
    }

    function placeBid(uint256 id)
        external
        payable
        nonReentrant
    {
        require(id < itemsOnMarket.length, "Invalid id");
        MarketItem memory item = itemsOnMarket[id];

        require(item.state == ON_MARKET, "Item not for sale");
        
        require(block.timestamp < item.auctionEndTime || item.highestBidder == address(0), "Auction has ended");
        
        if (item.highestBidder != address(0)) {
            require(msg.value >= item.bidPrice * 105 / 100, "Bid must be 5% higher than previous bid");
        } else {
            require(msg.value >= item.bidPrice, "Too low bid");

            // First bid!
            item.auctionStartTime = uint64(block.timestamp);
            // item.auctionEnd is the auction duration. Add current time to it
            // to set it to the end time.
            item.auctionEndTime += uint64(block.timestamp);
        }

        address previousBidder = item.highestBidder;
        // Return BNB to previous highest bidder.
        if (previousBidder != address(0)) {
            rewardBNBToUser(previousBidder, item.bidPrice);
        }

        item.highestBidder = payable(msg.sender);
        item.bidPrice = msg.value;
        // Extend the auction time by 5 minutes if there is less than 5 minutes remaining.
        // This is to prevent snipers sniping in the last block, and give everyone a chance
        // to bid.
        if ((item.auctionEndTime - block.timestamp) < 300){
            item.auctionEndTime = uint64(block.timestamp + 300);
        }

        emit HighestBidIncrease(id, msg.sender, msg.value, item.auctionEndTime);

        itemsOnMarket[id] = item;
    }

    function closeAuction(uint256 id)
        external
        nonReentrant
    {
        require(id < itemsOnMarket.length, "Invalid id");
        MarketItem memory item = itemsOnMarket[id];

        require(item.state == ON_MARKET, "Item not for sale");
        require(item.bidPrice > 0, "Item is not on auction.");
        require(item.highestBidder != address(0), "No bids placed");
        require(block.timestamp > item.auctionEndTime, "Auction is still on going");
        
        item.state = SOLD;
        
        IERC721(sombraNFTAddress).transferFrom(
            address(this),
            item.highestBidder,
            item.tokenId
        );
        
        uint256 netPrice = handleFees(item.tokenId, item.bidPrice, isMinter(item.tokenId, item.seller));
        rewardBNBToUser(item.seller, netPrice);
        
        emit ItemSold(id, item.tokenId, item.highestBidder, item.purchasePrice, item.bidPrice);
        itemsOnMarket[id] = item;
    }

    function reducePrice(
        uint256 id,
        uint256 reducedPrice,
        uint256 reducedBidPrice
    )
        external
        nonReentrant
    {
        require(id < itemsOnMarket.length, "Invalid id");
        MarketItem memory item = itemsOnMarket[id];
        require(item.state == ON_MARKET, "Item not for sale");

        require(msg.sender == item.seller, "Only the item seller can trigger a price reduction");
        require(block.timestamp >= item.listingCreationTime + 600, "Must wait ten minutes after listing before lowering the listing price");
        require(item.highestBidder == address(0), "Cannot reduce price once a bid has been placed");
        require(reducedBidPrice > 0 || reducedPrice > 0, "Must reduce price");

        if (reducedPrice > 0) {
            require(
                item.purchasePrice > 0 && reducedPrice <= item.purchasePrice * 95 / 100,
                "Reduced price must be at least 5% less than the current price"
            );
            item.purchasePrice = reducedPrice;
        }

        if (reducedBidPrice > 0) {
            require(
                item.bidPrice > 0 && reducedBidPrice <= item.bidPrice * 95 / 100,
                "Reduced price must be at least 5% less than the current price"
            );
            item.bidPrice = reducedPrice;
        }

        itemsOnMarket[id] = item;

        emit PriceReduction(
            id,
            item.purchasePrice,
            item.bidPrice
        );
    }

    function pullFromMarket(uint256 id)
        external
        nonReentrant
    {
        require(id < itemsOnMarket.length, "Invalid id");
        MarketItem memory item = itemsOnMarket[id];

        require(item.state == ON_MARKET, "Item not for sale");
        require(msg.sender == item.seller, "Only the item seller can pull an item from the marketplace");

        // Up for debate: Currently we don't allow items to be pulled if it's been bid on
        require(item.highestBidder == address(0), "Cannot pull from market once a bid has been placed");
        require(block.timestamp >= item.listingCreationTime + 600, "Must wait ten minutes after listing before pulling from the market");
        item.state = CANCELLED;

        IERC721(sombraNFTAddress).transferFrom(
            address(this),
            item.seller,
            item.tokenId
        );
        itemsOnMarket[id] = item;

        emit ItemPulledFromMarket(id);
    }
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// pragma solidity >=0.6.2;
interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

