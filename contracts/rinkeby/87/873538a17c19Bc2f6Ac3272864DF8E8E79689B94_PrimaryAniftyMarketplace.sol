//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract PrimaryAniftyMarketplace is ERC1155Holder {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _saleIds;
    Counters.Counter private _auctionIds;

    struct AuctionSignature {
        uint256 auctionId;
        uint256 tokenId;
        uint256 amount;
        uint256 price;
        address bidder;
        address token;
    }

    struct Sale {
        address lister;
        address payable artist;
        address buyer;
        address token;
        uint256 tokenId;
        uint256 amount;
        uint256 price;
        uint256 creationTimestamp;
        uint256 endTimestamp;
    }

    struct Auction {
        address lister;
        address artist;
        address buyer;
        address token;
        uint256 tokenId;
        uint256 amount;
        uint256 initialPrice;
        uint256 creationTimestamp;
        uint256 endTimestamp;
        uint256 buyPrice;
    }

    // struct for view
    struct SaleData {
        address[] artists;
        address[] buyers;
        address[] tokens;
        uint256[] tokenIds;
        uint256[] amounts;
        uint256[] prices;
        uint256[] creationTimestamps;
        uint256[] endTimestamps;
    }

    // struct for view
    struct AuctionData {
        address[] artists;
        address[] buyers;
        address[] tokens;
        uint256[] tokenIds;
        uint256[] amounts;
        uint256[] prices;
        uint256[] creationTimestamps;
        uint256[] endTimestamps;
        uint256[] buyPrices;
    }

    struct ArtistInfo {
        bool hasDiscount;
        bool isArtist;
    }

    uint256 constant PRECISION = 10000;
    // Discount to give to artist e.g 250 for 2.5%
    uint256 public discount;
    // Comission fee used to calculate amount to give to use e.g 500 for 5%
    uint256 public commissionFee;
    // Address that collects the commissions
    address payable commissionWallet;
    // Admin account that grants owner roles
    address public admin;
    IERC1155 Anifty;

    // address => is owner
    mapping(address => bool) public owners;

    // saleId => Sale struct
    mapping(uint256 => Sale) public sales;

    // auctionId => Auction struct
    mapping(uint256 => Auction) public auctions;

    // Artist info
    mapping(address => ArtistInfo) public artistInfo;

    // The mapping of supported ERC20 token addresses for sales
    mapping(address => bool) public saleSupportedTokens;

    // The mapping of supported ERC20 token addresses for auctions
    mapping(address => bool) public supportedTokens;

    string public constant name = "PrimaryMP";

    bytes32 constant DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
        );
    // The winning bidder allows lister to transfer amount
    bytes32 constant BID_TYPEHASH =
        keccak256(
            "Bid(uint256 auctionId,uint256 tokenId,uint256 amount,uint256 price,address bidder,address token)"
        );

    event ListSale(
        uint256 saleId,
        uint256 tokenId,
        uint256 amount,
        uint256 price,
        uint256 creationTimestamp,
        address artist
    );

    event CancelSale(uint256 saleId, uint256 endTimestamp, address artist);
    event UpdateSale(uint256 saleId, uint256 price);
    event CompleteSale(
        uint256 saleId,
        uint256 tokenId,
        uint256 amount,
        uint256 paymentAmount,
        uint256 buyTimestamp,
        address buyer
    );
    event ListAuction(
        uint256 auctionId,
        uint256 tokenId,
        uint256 amount,
        uint256 initialPrice,
        uint256 creationTimestamp,
        uint256 endTimestamp,
        address token,
        address artist
    );
    event CancelAuction(
        uint256 auctionId,
        uint256 endTimestamp,
        address artist
    );
    event AuctionClaimed(
        uint256 auctionId,
        uint256 tokenId,
        uint256 amount,
        uint256 price,
        uint256 timestamp,
        address indexed artist,
        address indexed bidder
    );

    constructor(
        address[] memory _saleSupportTokens,
        address[] memory _supportTokens,
        address _anifty,
        address _admin,
        address _commissionWallet,
        uint256 _commissionFee,
        uint256 _discount
    ) public {
        commissionWallet = payable(_commissionWallet);
        commissionFee = _commissionFee;
        discount = _discount;
        Anifty = IERC1155(_anifty);
        admin = _admin;
        // address(0) indicates ETH
        for (uint8 i = 0; i < _saleSupportTokens.length; i++) {
            saleSupportedTokens[_saleSupportTokens[i]] = true;
        }
        for (uint8 i = 0; i < _supportTokens.length; i++) {
            supportedTokens[_supportTokens[i]] = true;
        }
    }

    /********************** MODIFIERS ********************************/

    modifier onlyAdminOrOwner() {
        require(
            admin == msg.sender || owners[msg.sender],
            "PrimaryMP: !admin/owner"
        );
        _;
    }

    modifier onlyAdmin() {
        require(admin == msg.sender, "PrimaryMP: !admin");
        _;
    }

    modifier onlyWhitelisted() {
        require(
            admin == msg.sender ||
                owners[msg.sender] ||
                artistInfo[msg.sender].isArtist,
            "PrimaryMP: !whitelisted"
        );
        _;
    }

    modifier onlyLister(address lister) {
        require(lister == msg.sender, "PrimaryMP: !lister");
        _;
    }

    /********************** VIEWS ********************************/

    function getSalesInfo(uint256[] memory _saleIds)
        external
        view
        returns (
            address[] memory,
            address[] memory,
            address[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        SaleData memory saleData = SaleData(
            new address[](_saleIds.length), // artists
            new address[](_saleIds.length), // buyers
            new address[](_saleIds.length), // tokens
            new uint256[](_saleIds.length), // tokenIds
            new uint256[](_saleIds.length), // amounts
            new uint256[](_saleIds.length), // prices
            new uint256[](_saleIds.length), // creationTimestamps
            new uint256[](_saleIds.length) // endTimestamps
        );

        for (uint256 i = 0; i < _saleIds.length; i++) {
            saleData.artists[i] = sales[_saleIds[i]].artist;
            saleData.buyers[i] = sales[_saleIds[i]].buyer;
            saleData.tokens[i] = sales[_saleIds[i]].token;
            saleData.tokenIds[i] = sales[_saleIds[i]].tokenId;
            saleData.amounts[i] = sales[_saleIds[i]].amount;
            saleData.prices[i] = sales[_saleIds[i]].price;
            saleData.creationTimestamps[i] = sales[_saleIds[i]]
            .creationTimestamp;
            saleData.endTimestamps[i] = sales[_saleIds[i]].endTimestamp;
        }

        return (
            saleData.artists,
            saleData.buyers,
            saleData.tokens,
            saleData.tokenIds,
            saleData.amounts,
            saleData.prices,
            saleData.creationTimestamps,
            saleData.endTimestamps
        );
    }

    function getAuctionsInfo(uint256[] memory _auctionIds)
        external
        view
        returns (
            address[] memory,
            address[] memory,
            address[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        AuctionData memory auctionData = AuctionData(
            new address[](_auctionIds.length), // artists
            new address[](_auctionIds.length), // buyers
            new address[](_auctionIds.length), // tokens
            new uint256[](_auctionIds.length), // tokenIds
            new uint256[](_auctionIds.length), // amounts
            new uint256[](_auctionIds.length), // prices
            new uint256[](_auctionIds.length), // creationTimestamps
            new uint256[](_auctionIds.length), // endTimestamps
            new uint256[](_auctionIds.length) // buyPrices
        );

        for (uint256 i = 0; i < _auctionIds.length; i++) {
            auctionData.artists[i] = auctions[_auctionIds[i]].artist;
            auctionData.buyers[i] = auctions[_auctionIds[i]].buyer;
            auctionData.tokens[i] = auctions[_auctionIds[i]].token;
            auctionData.tokenIds[i] = auctions[_auctionIds[i]].tokenId;
            auctionData.amounts[i] = auctions[_auctionIds[i]].amount;
            auctionData.prices[i] = auctions[_auctionIds[i]].initialPrice;
            auctionData.creationTimestamps[i] = auctions[_auctionIds[i]]
            .creationTimestamp;
            auctionData.endTimestamps[i] = auctions[_auctionIds[i]]
            .endTimestamp;
            auctionData.buyPrices[i] = auctions[_auctionIds[i]].buyPrice;
        }

        return (
            auctionData.artists,
            auctionData.buyers,
            auctionData.tokens,
            auctionData.tokenIds,
            auctionData.amounts,
            auctionData.prices,
            auctionData.creationTimestamps,
            auctionData.endTimestamps,
            auctionData.buyPrices
        );
    }

    /********************** SALE ********************************/

    // List new sale of NFT
    function listNewSale(
        uint256 _tokenId,
        uint256 _amount,
        uint256 _price,
        address _token,
        address payable _artist
    ) external onlyWhitelisted {
        require(_price > 0, "PrimaryMP: Price > 0");
        require(saleSupportedTokens[_token], "PrimaryMP: Token not supported");
        // Transfer tokens into marketplace contract
        Anifty.safeTransferFrom(
            msg.sender,
            address(this),
            _tokenId,
            _amount,
            ""
        );
        // Add to sales mapping
        _saleIds.increment();
        uint256 saleId = _saleIds.current();
        sales[saleId] = Sale(
            msg.sender,
            _artist,
            address(0),
            _token,
            _tokenId,
            _amount,
            _price,
            block.timestamp,
            0
        );

        emit ListSale(
            saleId,
            _tokenId,
            _amount,
            _price,
            block.timestamp,
            _artist
        );
    }

    // Cancel sale of NFT
    function cancelSale(uint256 _saleId)
        external
        onlyLister(sales[_saleId].lister)
    {
        sales[_saleId].price = 0;
        sales[_saleId].endTimestamp = block.timestamp;

        // Transfer tokens into back to lister
        Anifty.safeTransferFrom(
            address(this),
            msg.sender,
            sales[_saleId].tokenId,
            sales[_saleId].amount,
            ""
        );
        emit CancelSale(_saleId, block.timestamp, msg.sender);
    }

    // Update the price of sale
    function updateSale(uint256 _saleId, uint256 _price)
        external
        onlyLister(sales[_saleId].lister)
    {
        require(_price > 0, "PrimaryMP: Price > 0");
        sales[_saleId].price = _price;

        emit UpdateSale(_saleId, _price);
    }

    // Buy NFT
    function buyFromSale(uint256 _saleId) external payable {
        Sale memory sale = sales[_saleId];
        require(
            sale.artist != address(0) && sale.buyer == address(0),
            "PrimaryMP: !sale"
        );
        require(sale.price > 0, "PrimaryMP: Sale cancelled");
        // Set buyer for sale
        sales[_saleId].buyer = msg.sender;
        if (sale.token == address(0)) {
            require(
                msg.value >= sale.price,
                "PrimaryMP: Payable value too low"
            );
            // Anifty takes commission for every sale
            uint256 commissionAmount = msg.value.mul(commissionFee).div(
                PRECISION
            );
            if (artistInfo[sale.artist].hasDiscount) {
                commissionAmount = commissionAmount.sub(
                    msg.value.mul(discount).div(PRECISION)
                );
            }
            // Transfer artist the price - commission fee
            sale.artist.transfer(msg.value.sub(commissionAmount));
            // Transfer commission wallet the commission fee
            commissionWallet.transfer(commissionAmount);
        } else {
            IERC20 token = IERC20(sale.token);
            // Anifty takes commission for every sale
            uint256 commissionAmount = sale.price.mul(commissionFee).div(
                PRECISION
            );
            if (artistInfo[sale.artist].hasDiscount) {
                commissionAmount = commissionAmount.sub(
                    sale.price.mul(discount).div(PRECISION)
                );
            }
            // Transfer artist the price - commission fee
            token.transferFrom(
                msg.sender,
                sale.artist,
                sale.price.sub(commissionAmount)
            );
            // Transfer commission wallet the commission fee
            token.transferFrom(msg.sender, commissionWallet, commissionAmount);
        }
        // Give buyer ERC1155
        Anifty.safeTransferFrom(
            address(this),
            msg.sender,
            sale.tokenId,
            sale.amount,
            ""
        );
        emit CompleteSale(
            _saleId,
            sale.tokenId,
            sale.amount,
            msg.value,
            block.timestamp,
            msg.sender
        );
        delete sale;
    }

    /********************** AUCTION ********************************/

    // List new auction
    function listNewAuction(
        uint256 _tokenId,
        uint256 _amount,
        uint256 _initialPrice,
        uint256 _endTimestamp,
        address _token,
        address _artist
    ) external onlyWhitelisted {
        require(_initialPrice > 0, "PrimaryMP: Initial price must be above 0");
        require(supportedTokens[_token], "PrimaryMP: Token not supported");
        require(
            _endTimestamp > block.timestamp,
            "PrimaryMP: Invalid end timestamp"
        );
        // Transfer tokens into marketplace contract
        Anifty.safeTransferFrom(
            msg.sender,
            address(this),
            _tokenId,
            _amount,
            ""
        );
        // Add to auctions mapping
        _auctionIds.increment();
        uint256 auctionId = _auctionIds.current();
        auctions[auctionId] = Auction(
            msg.sender,
            _artist,
            address(0),
            _token,
            _tokenId,
            _amount,
            _initialPrice,
            block.timestamp,
            _endTimestamp,
            0
        );

        emit ListAuction(
            auctionId,
            _tokenId,
            _amount,
            _initialPrice,
            block.timestamp,
            _endTimestamp,
            _token,
            _artist
        );
    }

    // Cancel auction of NFT
    function cancelAuction(uint256 _auctionId)
        external
        onlyLister(auctions[_auctionId].lister)
    {
        auctions[_auctionId].initialPrice = 0;
        auctions[_auctionId].endTimestamp = block.timestamp;

        // Transfer tokens into back to lister
        Anifty.safeTransferFrom(
            address(this),
            msg.sender,
            auctions[_auctionId].tokenId,
            auctions[_auctionId].amount,
            ""
        );
        emit CancelAuction(_auctionId, block.timestamp, msg.sender);
    }

    function listerClaimBySig(
        AuctionSignature memory auctionSignature,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external onlyLister(auctions[auctionSignature.auctionId].lister) {
        // Check if signature is valid
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                getChainId(),
                address(this)
            )
        );
        bytes32 structHash = keccak256(
            abi.encode(
                BID_TYPEHASH,
                auctionSignature.auctionId,
                auctionSignature.tokenId,
                auctionSignature.amount,
                auctionSignature.price,
                auctionSignature.bidder,
                auctionSignature.token
            )
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );
        address signatory = ecrecover(digest, v, r, s);
        // Make sure the signature is from the bidder, who allows the artist to claim price
        require(
            signatory == auctionSignature.bidder,
            "PrimaryMP: Invalid signature"
        );
        // The lister is responsible for transfering their NFT to bidder and receiving the token
        _sellClaim(auctionSignature);
    }

    function getChainId() internal pure returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }

    function _sellClaim(AuctionSignature memory auctionSignature) internal {
        Auction memory auction = auctions[auctionSignature.auctionId];
        require(
            auction.buyer == address(0),
            "PrimaryMP: This auction has already been completed"
        );
        require(
            auction.initialPrice > 0,
            "PrimaryMP: This auction has been cancelled"
        );
        require(
            auctionSignature.price >= auction.initialPrice,
            "PrimaryMP: Bid is less than initial price"
        );
        // Make sure bidder is bidding the correct token
        require(
            auction.token == auctionSignature.token,
            "PrimaryMP: Invalid token"
        );
        // Set buyer for auction, once this is set this auction cannot be claimed again
        auctions[auctionSignature.auctionId].buyer = auctionSignature.bidder;
        auctions[auctionSignature.auctionId].endTimestamp = block.timestamp;
        auctions[auctionSignature.auctionId].buyPrice = auctionSignature.price;
        IERC20 token = IERC20(auctionSignature.token);
        uint256 commissionAmount = auctionSignature
        .price
        .mul(commissionFee)
        .div(PRECISION);
        if (artistInfo[auction.artist].hasDiscount) {
            commissionAmount = commissionAmount.sub(
                auctionSignature.price.mul(discount).div(PRECISION)
            );
        }
        // Transfer token to artist
        token.transferFrom(
            auctionSignature.bidder,
            auction.artist,
            auctionSignature.price.sub(commissionAmount)
        );
        // Transfer token to commission wallet
        token.transferFrom(
            auctionSignature.bidder,
            commissionWallet,
            commissionAmount
        );
        Anifty.safeTransferFrom(
            address(this),
            auctionSignature.bidder,
            auction.tokenId,
            auction.amount,
            ""
        );
        emit AuctionClaimed(
            auctionSignature.auctionId,
            auction.tokenId,
            auction.amount,
            auctionSignature.price,
            block.timestamp,
            msg.sender,
            auctionSignature.bidder
        );
    }

    /********************** OWNER ********************************/

    function setCommissionFee(uint256 _commissionFee)
        external
        onlyAdminOrOwner
    {
        commissionFee = _commissionFee;
    }

    function setCommissionWallet(address payable _commissionWallet)
        external
        onlyAdminOrOwner
    {
        commissionWallet = _commissionWallet;
    }

    function setDiscount(uint256 _discount) external onlyAdminOrOwner {
        discount = _discount;
    }

    function setValidArtistInfo(
        address[] memory _artists,
        bool _isArtist,
        bool _hasDiscount
    ) external onlyAdminOrOwner {
        for (uint256 i = 0; i < _artists.length; i++) {
            artistInfo[_artists[i]].isArtist = _isArtist;
            artistInfo[_artists[i]].hasDiscount = _hasDiscount;
        }
    }

    function setSaleSupportedTokens(
        address[] memory _saleSupportTokens,
        bool _set
    ) external onlyAdminOrOwner {
        for (uint8 i = 0; i < _saleSupportTokens.length; i++) {
            saleSupportedTokens[_saleSupportTokens[i]] = _set;
        }
    }

    function setSupportedTokens(address[] memory _supportTokens, bool _set)
        external
        onlyAdminOrOwner
    {
        for (uint8 i = 0; i < _supportTokens.length; i++) {
            supportedTokens[_supportTokens[i]] = _set;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../math/SafeMath.sol";

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

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
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

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
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

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
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC1155Receiver.sol";
import "../../introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    constructor() internal {
        _registerInterface(
            ERC1155Receiver(address(0)).onERC1155Received.selector ^
            ERC1155Receiver(address(0)).onERC1155BatchReceived.selector
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * _Available since v3.1._
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
    )
        external
        returns(bytes4);

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
    )
        external
        returns(bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
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