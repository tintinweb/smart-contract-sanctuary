/**
 *Submitted for verification at BscScan.com on 2021-10-04
*/

pragma solidity ^0.8.0;

// -------------------------------------------------------------------------------------------------------------------------
//
// BossMarket simple NFT Exchange 
// Buy, Sell, Trade using only your wallet and a super low 0.75% transaction fee.
//
//
// 1. To Sell
// 1a. Approve your NFT to be sent to this contract address
// 1b. Call tradeOpen with your NFT address, ID, price and start timestamp. Minimum waiting time for open is 5 minutes.
// 1c. NFT will be transferred to this contract for escrow, if anyone buys it you'll receive the amount you requested
// 1d. Otherwise you can call tradeCancel with your tradeID, and your NFT will be returned to your
//
//
// 2. To buy
// 1a. You can call getTrade to discover available trades
// 1b. Send the amount requested to this contract via simple wallet transfer, that's it!
// NOTE: If anything goes wrong the transaction will revert and you'll receive your BNB back
//
// -------------------------------------------------------------------------------------------------------------------------

contract BossMarket {
    event OnTradeStatus(uint256 tradeId, trade_status status);

    enum trade_status{UNDEFINED, OPEN, EXECUTED, CANCELLED }
    struct Trade {
        address creator;
        IERC721 erc721_address;
        uint256 erc721_id;
        uint256 bnb_price;
        uint startTime;
        
        trade_status status;
    }

    address admin;
    uint256 currentTradeId;
    mapping(uint256 => Trade) public tradeById;
    mapping(uint256 => uint256) public tradePriceToId;

    constructor ()
    {
        admin = msg.sender;
        currentTradeId = 1;
    }

    function getTrade(uint256 tradeId)
        public
        virtual
        view
        returns(address, address, uint256, uint256, uint256, trade_status)
    {
        Trade memory trade = tradeById[tradeId];
        if (trade.bnb_price == 0) {
            trade.status = trade_status.UNDEFINED;
        }
        return (trade.creator, address(trade.erc721_address), trade.erc721_id, trade.bnb_price, trade.startTime, trade.status);
    }

    function testToken(address erc721_address, uint256 erc721_id) public
    {
        require(msg.sender == admin, "Only admins can test!");
        
        // tranfer NFT to contract
        IERC721 erc721 = IERC721(erc721_address);
        erc721.transferFrom(msg.sender, address(this), erc721_id);
        
        // transfer it back
        erc721.transferFrom(address(this), msg.sender, erc721_id);
    }

    function tradeOpen(address erc721_address, uint256 erc721_id, uint256 bnb_price, uint startTime)
        public
        returns (uint256)
    {
        // just to be safe, do not open the trade instantly
        if (startTime < block.timestamp + 300)
            startTime = block.timestamp + 300;
        require(bnb_price > 10000, "Price cannot be zero");
        require(erc721_address != address(0), "Address cannot be zero");
        
        // transfer token to myself
        IERC721(erc721_address).transferFrom(msg.sender, address(this), erc721_id);
        
        while (tradePriceToId[bnb_price] > 0) {
            bnb_price += 10**15;
        }
        Trade memory t = Trade({creator: msg.sender,
            erc721_address: IERC721(erc721_address),
            erc721_id: erc721_id,
            bnb_price: bnb_price,
            startTime: startTime,
            status: trade_status.OPEN
        });
        tradeById[currentTradeId] = t;
        tradePriceToId[bnb_price] = currentTradeId;
        
        emit OnTradeStatus(currentTradeId, trade_status.OPEN);
        currentTradeId ++;
        
        return currentTradeId-1;
    }

    function tradeCancel(uint256 TradeId)
        public
    {
        Trade memory trade = tradeById[TradeId];
        require(msg.sender == trade.creator || msg.sender == admin, "Trade can be cancelled only by creator or admin!");
        require(trade.status == trade_status.OPEN, "Trade is not Open.");
        
        IERC721(trade.erc721_address).transferFrom(address(this), trade.creator, trade.erc721_id);
        tradeById[TradeId].status = trade_status.CANCELLED;
        delete tradePriceToId[trade.bnb_price];
        
        emit OnTradeStatus(currentTradeId, trade_status.CANCELLED);
    }

    event Received(address, uint);
    receive() external payable {
        require(tradePriceToId[msg.value] > 0, "Cannot find trade");
        emit Received(msg.sender, msg.value);
        
        uint256 TradeId = tradePriceToId[msg.value];
        Trade memory trade = tradeById[TradeId];
        
        require(trade.status == trade_status.OPEN, "Trade is not Open.");
        require(block.timestamp > trade.startTime, "Trade is not yet Open.");
        
        // transfer token from escrow to sender!
        IERC721(trade.erc721_address).transferFrom(address(this), msg.sender, trade.erc721_id);
        
        uint256 transfer_amt = msg.value - ((msg.value * 10075 / 10000) - msg.value);    // 0.75% fee
        require(transfer_amt < msg.value, "Too high transfer error");
        
        // pay the token owner (minus fee!)
        payable(trade.creator).transfer(transfer_amt);
        emit OnTradeStatus(TradeId, trade_status.EXECUTED);
    }
    
    function transfer_out() public
    {
       require(address(this).balance > 0, "Nothing to transfer");
       payable(admin).transfer(address(this).balance);
    }
}





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