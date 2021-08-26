// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Governance.sol";
import "../openzeppelin/IERC20.sol";
import "../openzeppelin/IERC721.sol";
import "../openzeppelin/IERC1155.sol";
import "../openzeppelin/ERC721Holder.sol";
import "../openzeppelin/ERC1155Holder.sol";
import "../openzeppelin/Counters.sol";
import "../openzeppelin/SafeERC20.sol";
import "../openzeppelin/SafeMath.sol";
import "./EnumerableDataSet.sol";

contract Marketplace is Governance, ERC721Holder, ERC1155Holder {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using EnumerableDataSet for EnumerableDataSet.DataSet;

    struct ExchangeData {
        address token;
        uint256 tokenId;
        uint256 amount;
        uint256 price;
        address owner;
        uint256 createdAt;
        uint256 expiredAt;
        uint8 status; // 0: selling, 1: sold, 2: canceled
    }

    struct AuctionData {
        address token;
        uint256 tokenId;
        uint256 amount;
        uint256 price;
        uint256 saleFee;
        uint256 purchaseFee;
        address owner;
        address winner;
        uint256 createdAt;
        uint256 expiredAt;
        uint8 status; // 0: auctioning, 1: finished
    }

    // The unit of money used in a shopping mall
    IERC20 private oxiToken;

    // Auto increase id
    Counters.Counter private exchangeIdTracker;
    Counters.Counter private auctionIdTracker;

    // Mapping exchangeId to exchange data
    mapping(uint256 => ExchangeData) private exchanges;
    // Mapping auctionId to auction data
    mapping(uint256 => AuctionData) private auctions;

    // NFTs approved for listing in shopping mall
    mapping(address => bool) private nft721Approvals;
    mapping(address => bool) private nft1155Approvals;

    // Beneficiaries
    address public beneficiary;

    // Fees
    uint256 public saleFeePercent = 500; // (500/10000)*100 = 5%
    uint256 public purchaseFeePercent = 200; // (200/10000)*100 = 2%

    // Storage all exchange id with selling status
    EnumerableDataSet.DataSet private sellings;
    // Storage all auction id with auctioning status
    EnumerableDataSet.DataSet private auctionings;

    // Events
    event Sold(address seller, uint256 exchangeId);
    event Bought(address buyer, uint256 exchangeId);
    event Canceled(address seller, uint256 exchangeId);
    event AuctionBegan(address owner, uint256 auctionId);
    event AuctionEnded(address owner, uint256 auctionId, address winner);

    constructor() Governance() {}

    //////////////Config Functions////////////////////
    function getApproved(address token_) public view returns (bool approved, bool is721) {
        is721 = nft721Approvals[token_];
        approved = is721 || nft1155Approvals[token_];
    }

    function setApprovalNFT721(address token_, bool approved_) external onlyGovernance {
        nft721Approvals[token_] = approved_;
    }

    function setApprovalNFT1155(address token_, bool approved_) external onlyGovernance {
        nft1155Approvals[token_] = approved_;
    }

    function setBeneficiary(address beneficiary_) external onlyGovernance {
        beneficiary = beneficiary_;
    }

    function setOxiToken(address token_) external onlyGovernance {
        oxiToken = IERC20(token_);
    }

    function setSaleFeePercent(uint256 saleFeePercent_) external onlyGovernance {
        saleFeePercent = saleFeePercent_;
    }

    function setPurchaseFeePercent(uint256 purchaseFeePercent_) external onlyGovernance {
        purchaseFeePercent = purchaseFeePercent_;
    }

    function getSaleFee(uint256 price_) public view returns (uint256) {
        return price_.mul(saleFeePercent).div(10000);
    }

    function getPurchaseFee(uint256 price_) public view returns (uint256) {
        return price_.mul(purchaseFeePercent).div(10000);
    }

    function checkLimitTime(uint256 time_) public pure returns (bool) {
        return time_ <= 30 days;
    }

    //////////////Exchange Functions//////////////////
    /**
     * @dev Sell NFT token.
     * require seller approval for contract to transfer oxi token.
     * require seller approval for contract to hold NFT token.
     */
    function sell(
        address token_,
        uint256 tokenId_,
        uint256 amount_,
        uint256 price_,
        uint256 timeLimit_
    ) external {
        (bool approved, bool is721) = getApproved(token_);
        require(price_ > 0, "Marketplace: !price");
        require(checkLimitTime(timeLimit_), "Marketplace: !timeLimit");
        require(approved, "Marketplace: !token");

        // pay sale fee
        oxiToken.safeTransferFrom(msg.sender, beneficiary, getSaleFee(price_));
        // hold nft
        _holdNFT(token_, msg.sender, tokenId_, amount_, is721);
        uint256 id = exchangeIdTracker.current();

        exchanges[id] = ExchangeData({
            token: token_,
            tokenId: tokenId_,
            amount: amount_,
            price: price_,
            owner: msg.sender,
            createdAt: block.timestamp,
            expiredAt: timeLimit_.add(block.timestamp),
            status: 0
        });

        exchangeIdTracker.increment();

        sellings.addData(id);
        sellings.addDataOfOwner(msg.sender, id);

        emit Sold(msg.sender, id);
    }

    /**
     * @dev Buy NFT token.
     * require buyer approval for contract to transfer oxi token.
     */
    function buy(uint256 exchangeId_) external {
        require(existsExchange(exchangeId_), "Marketplace: exchange is not exists");
        require(exchanges[exchangeId_].status == 0, "Marketplace: !selling");
        require(exchanges[exchangeId_].expiredAt > block.timestamp, "Marketplace: !expired");

        ExchangeData storage exchange = exchanges[exchangeId_];
        exchange.status = 1;

        sellings.removeData(exchangeId_);
        sellings.removeDataOfOwner(exchange.owner, exchangeId_);

        // pay purchase fee
        oxiToken.safeTransferFrom(msg.sender, beneficiary, getPurchaseFee(exchange.price));
        // pay for purchases
        oxiToken.safeTransferFrom(msg.sender, exchange.owner, exchange.price);
        // transfer nft
        _transferNFT(exchange.token, msg.sender, exchange.tokenId, exchange.amount, nft721Approvals[exchange.token]);

        emit Bought(msg.sender, exchangeId_);
    }

    /**
     * @dev cancel selling NFT token and return NFT token to owner.
     * note this function allow to call by governance to cancel expired exchanges.
     */
    function cancel(uint256 exchangeId_) external {
        require(existsExchange(exchangeId_), "Marketplace: exchange is not exists");
        require(exchanges[exchangeId_].status == 0, "Marketplace: !selling");
        if (msg.sender != exchanges[exchangeId_].owner) {
            require(exchanges[exchangeId_].expiredAt <= block.timestamp, "Marketplace: !expired");
        }

        ExchangeData storage exchange = exchanges[exchangeId_];
        exchange.status = 2;

        sellings.removeData(exchangeId_);
        sellings.removeDataOfOwner(exchange.owner, exchangeId_);

        _transferNFT(exchange.token, exchange.owner, exchange.tokenId, exchange.amount, nft721Approvals[exchange.token]);

        emit Canceled(exchange.owner, exchangeId_);
    }

    function getExchangeData(uint256 exchangeId_) external view returns (ExchangeData memory) {
        require(existsExchange(exchangeId_), "Marketplace: query for nonexistent exchange");
        return exchanges[exchangeId_];
    }

    function existsExchange(uint256 exchangeId_) public view returns (bool) {
        return exchanges[exchangeId_].owner != address(0);
    }

    //////////////Auction Functions///////////////////
    /**
     * @dev create NFT token auction.
     * require auctioneer approval for contract to hold NFT token.
     */
    function auction(
        address token_,
        uint256 tokenId_,
        uint256 amount_,
        uint256 minPrice_,
        uint256 timeLimit_
    ) external {
        (bool approved, bool is721) = getApproved(token_);
        require(minPrice_ > 0, "Marketplace: !minPrice");
        require(checkLimitTime(timeLimit_), "Marketplace: !timeLimit");
        require(approved, "Marketplace: !token");

        uint256 saleFee = getSaleFee(minPrice_);
        // hold sale fee
        _holdOxi(msg.sender, saleFee);
        // hold nft
        _holdNFT(token_, msg.sender, tokenId_, amount_, is721);
        uint256 id = auctionIdTracker.current();

        auctions[id] = AuctionData({
            token: token_,
            tokenId: tokenId_,
            amount: amount_,
            price: minPrice_,
            saleFee: saleFee,
            purchaseFee: 0,
            owner: msg.sender,
            winner: address(0),
            createdAt: block.timestamp,
            expiredAt: timeLimit_.add(block.timestamp),
            status: 0
        });

        auctionIdTracker.increment();

        auctionings.addData(id);
        auctionings.addDataOfOwner(msg.sender, id);

        emit AuctionBegan(msg.sender, id);
    }

    /**
     * @dev bid for the NFT token auction.
     * require bidder approval for contract to hold oxi token
     */
    function bid(uint256 auctionId_, uint256 price_) external {
        require(existsAuction(auctionId_), "Marketplace: auction is not exists");
        require(auctions[auctionId_].status == 0, "Marketplace: !auctioning");
        require(auctions[auctionId_].expiredAt > block.timestamp, "Marketplace: expired!");

        AuctionData storage auctionData = auctions[auctionId_];
        uint256 purchaseFee = getPurchaseFee(price_);

        if (auctionData.winner == address(0)) {
            require(price_ >= auctionData.price, "Marketplace: !price");

            _holdOxi(msg.sender, price_.add(purchaseFee));

            // update auction data
            auctionData.winner = msg.sender;
            auctionData.purchaseFee = purchaseFee;
            auctionData.price = price_;
        } else {
            require(price_ > auctionData.price, "Marketplace: !price");

            _holdOxi(msg.sender, price_.add(purchaseFee));

            address refundAddress = auctionData.winner;
            uint256 refundAmount = auctionData.price.add(auctionData.purchaseFee);

            // update auction data
            auctionData.winner = msg.sender;
            auctionData.purchaseFee = purchaseFee;
            auctionData.price = price_;

            // refund to previous bidder
            _transferOxi(refundAddress, refundAmount);
        }
    }

    /**
     * @dev call this to finish auction.
     */
    function endAuction(uint256 auctionId_) external {
        require(existsAuction(auctionId_), "Marketplace: auction is not exists");
        require(auctions[auctionId_].status == 0, "Marketplace: !auctioning");
        require(auctions[auctionId_].expiredAt <= block.timestamp, "Marketplace: !expired");

        AuctionData storage auctionData = auctions[auctionId_];
        auctionData.status = 1;

        auctionings.removeData(auctionId_);
        auctionings.removeDataOfOwner(auctionData.owner, auctionId_);

        if (auctionData.winner == address(0)) {
            // return NFT token to owner
            _transferNFT(auctionData.token, auctionData.owner, auctionData.tokenId, auctionData.amount, nft721Approvals[auctionData.token]);
        } else {
            // recalculate sale fee
            uint256 saleFee = getSaleFee(auctionData.price);
            // transfer oxi to owner
            _transferOxi(auctionData.owner, auctionData.price.sub(saleFee.sub(auctionData.saleFee)));
            // transfer fee
            _transferOxi(beneficiary, auctionData.purchaseFee.add(saleFee));

            // transfer NFT token to winner
            _transferNFT(auctionData.token, auctionData.winner, auctionData.tokenId, auctionData.amount, nft721Approvals[auctionData.token]);
        }

        emit AuctionEnded(auctionData.owner, auctionId_, auctionData.winner);
    }

    function getAuctionData(uint256 auctionId_) external view returns (AuctionData memory) {
        require(existsAuction(auctionId_), "Marketplace: query for nonexistent auction");
        return auctions[auctionId_];
    }

    function existsAuction(uint256 auctionId_) public view returns (bool) {
        return auctions[auctionId_].owner != address(0);
    }

    function _transferNFT(
        address token_,
        address to_,
        uint256 tokenId_,
        uint256 amount_,
        bool is721_
    ) internal {
        if (is721_) {
            IERC721(token_).safeTransferFrom(address(this), to_, tokenId_);
        } else {
            IERC1155(token_).safeTransferFrom(address(this), to_, tokenId_, amount_, "");
        }
    }

    function _holdNFT(
        address token_,
        address owner_,
        uint256 tokenId_,
        uint256 amount_,
        bool is721_
    ) internal {
        if (is721_) {
            IERC721(token_).safeTransferFrom(owner_, address(this), tokenId_);
        } else {
            IERC1155(token_).safeTransferFrom(owner_, address(this), tokenId_, amount_, "");
        }
    }

    function _transferOxi(address to_, uint256 amount_) internal {
        oxiToken.safeTransfer(to_, amount_);
    }

    function _holdOxi(address from_, uint256 amount_) internal {
        oxiToken.safeTransferFrom(from_, address(this), amount_);
    }

    //////////////List View Functions/////////////////
    function sellingLength() external view returns (uint256) {
        return sellings.length();
    }

    function sellingAt(uint256 index_) external view returns (uint256) {
        return sellings.dataAt(index_);
    }

    function sellingLengthOfOwner(address owner_) external view returns (uint256) {
        return sellings.lengthOfOwner(owner_);
    }

    function sellingOfOwnerAt(address owner_, uint256 index_) external view returns (uint256) {
        return sellings.dataOfOwnerAt(owner_, index_);
    }

    function auctioningLength() external view returns (uint256) {
        return auctionings.length();
    }

    function auctioningAt(uint256 index_) external view returns (uint256) {
        return auctionings.dataAt(index_);
    }

    function auctioningLengthOfOwner(address owner_) external view returns (uint256) {
        return auctionings.lengthOfOwner(owner_);
    }

    function auctioningOfOwnerAt(address owner_, uint256 index_) external view returns (uint256) {
        return auctionings.dataOfOwnerAt(owner_, index_);
    }
    //////////////////////////////////////////////////
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Governance {
    address public governance;
    address private pendingGovernance;
    mapping(address => bool) public minters;

    constructor() {
        governance = msg.sender;
    }

    modifier onlyGovernance() {
        require(msg.sender == governance, "Governance: !governance");
        _;
    }

    modifier onlyMinter() {
        require(minters[msg.sender], "Governance: !minter");
        _;
    }

    function setGovernance(address governance_) external virtual onlyGovernance {
        require(governance_ != address(0), "Governance: new governance is the zero address");
        pendingGovernance = governance_;
    }

    function claimGovernance() external virtual {
        require(msg.sender == pendingGovernance, "Governance: !pendingGovernance");
        governance = pendingGovernance;
        delete pendingGovernance;
    }

    function addMinter(address minter_) external virtual onlyGovernance {
        require(minter_ != address(0), "Governance: minter is the zero address");
        minters[minter_] = true;
    }

    function removeMinter(address minter_) external virtual onlyGovernance {
        require(minter_ != address(0), "Governance: minter is the zero address");
        minters[minter_] = false;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

import "./IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require((value == 0) || (token.allowance(address(this), spender) == 0), "SafeERC20: approve from non-zero to non-zero allowance");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library EnumerableDataSet {
    struct DataSet {
        // Mapping from owner to amount of data owned
        mapping(address => uint256) _ownedCount;
        // Mapping from owner to list of owned data
        mapping(address => mapping(uint256 => uint256)) _ownedData;
        // Mapping from data to index of the owner data list
        mapping(uint256 => uint256) _ownedIndex;
        // Array with all data, used for enumeration
        uint256[] _allData;
        // Mapping from data to position in the _allData array
        mapping(uint256 => uint256) _allIndex;
    }

    function length(DataSet storage set) internal view returns (uint256) {
        return set._allData.length;
    }

    function lengthOfOwner(DataSet storage set, address owner) internal view returns (uint256) {
        return set._ownedCount[owner];
    }

    function dataAt(DataSet storage set, uint256 index) internal view returns (uint256) {
        require(index < set._allData.length, "EnumerableDataSet: index out of bounds");
        return set._allData[index];
    }

    function dataOfOwnerAt(
        DataSet storage set,
        address owner,
        uint256 index
    ) internal view returns (uint256) {
        require(index < set._ownedCount[owner], "EnumerableDataSet: index out of bounds");
        return set._ownedData[owner][index];
    }

    /**
     * @dev function to add data to this extension's tracking data structures.
     */
    function addData(DataSet storage set, uint256 data) internal {
        set._allIndex[data] = set._allData.length;
        set._allData.push(data);
    }

    /**
     * @dev function to add a data to this extension's ownership-tracking data structures.
     */
    function addDataOfOwner(
        DataSet storage set,
        address owner,
        uint256 data
    ) internal {
        uint256 _length = set._ownedCount[owner];
        set._ownedData[owner][_length] = data;
        set._ownedIndex[data] = _length;
        set._ownedCount[owner] += 1;
    }

    /**
     * @dev function to remove a data from this extension's ownership-tracking data structures.
     * Note that while the data is not assigned a new owner, the `_ownedIndex` mapping is _not_
     * updated: this allows for gas optimizations e.g. when performing a transfer operation
     * (avoiding double writes). This has O(1) time complexity, but alters the order of the
     * _ownedData array.
     */
    function removeDataOfOwner(
        DataSet storage set,
        address owner,
        uint256 data
    ) internal {
        uint256 lastIndex = set._ownedCount[owner] - 1;
        uint256 dataIndex = set._ownedIndex[data];

        // When the data to delete is the last data, the swap operation is unnecessary
        if (dataIndex != lastIndex) {
            uint256 lastData = set._ownedData[owner][lastIndex];

            // Move the last data to the slot of the to-delete data
            set._ownedData[owner][dataIndex] = lastData;
            // Update the moved data's index
            set._ownedIndex[lastData] = dataIndex;
        }

        set._ownedCount[owner] -= 1;

        // Delete the contents at the last position of the array
        delete set._ownedIndex[data];
        delete set._ownedData[owner][lastIndex];
    }

    /**
     * @dev function to remove a data from this extension's tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allData array.
     */
    function removeData(DataSet storage set, uint256 data) internal {
        uint256 lastIndex = set._allData.length - 1;
        uint256 dataIndex = set._allIndex[data];

        uint256 lastdataId = set._allData[lastIndex];

        // Move the last data to the slot of the to-delete data
        set._allData[dataIndex] = lastdataId;
        // Update the moved data's index
        set._allIndex[lastdataId] = dataIndex;

        // Delete the contents at the last position of the array
        delete set._allIndex[data];
        set._allData.pop();
    }
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

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC1155Receiver.sol";
import "./ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 999999
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