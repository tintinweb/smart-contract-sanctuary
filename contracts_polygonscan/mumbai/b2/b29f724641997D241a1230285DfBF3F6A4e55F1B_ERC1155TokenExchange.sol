// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

/**
 * @dev Exchange Contract for ERC1155 Token
 */
contract ERC1155TokenExchange is ERC1155Holder {
    /**
    * @dev Exchange struct for ERC1155 Token
    */
    struct ERC1155Exchange {
        string exchangeName;
        address creatorAddress;
        address exchangeTokenAddress;
        address offerTokenAddress;
        uint initialAmount;
        uint price;
    }

    /**
    * @dev Offer struct for ERC1155 Token
    */
    struct ERC1155Offer {
        uint exchangeId;
        uint offerId;
        string offerType;
        address creatorAddress;
        uint tokenId;
        uint amount;
        uint price;
    }

    /**
    * @dev Request struct for creating ERC1155TokenExchange
    */
    struct CreateERC1155TokenExchangeRequest {
        string exchangeName;
        address exchangeTokenAddress;
        address offerTokenAddress;
        uint tokenId;
        uint amount;
        uint price;
    }

    /**
    * @dev Request struct for Place ERC1155Token Offer
    */
    struct PlaceERC1155TokenOfferRequest {
        uint exchangeId;
        uint tokenId;
        uint amount;
        uint price;
    }

    /**
    * @dev Request struct for cancel Exchange
    */
    struct CancelOfferRequest {
        uint exchangeId;
        uint offerId;
    }

    /**
    * @dev Request struct for deal Exchange
    */
    struct OfferRequest {
        uint exchangeId;
        uint offerId;
    }

    /**
    * @dev count variables for ERC1155Token exchange and offer mapping
    */
    uint internal _erc1155ExchangeCount;
    uint internal _erc1155OfferCount;
    
    /**
    * @dev variables for storing ERC1155Token Exchange and Offer
    */
    mapping(uint => ERC1155Exchange) internal _erc1155Exchanges;
    mapping(uint => ERC1155Offer) internal _erc1155Offers;

    // ----- EVENTS ----- //
    event ERC1155TokenExchangeCreated(uint exchangeId, uint initialOfferId);
    event ERC1155TokenBuyingOfferPlaced(uint offerId);
    event ERC1155TokenSellingOfferPlaced(uint offerId);
    event ERC1155TokenBuyingOfferCanceled(uint offerId);
    event ERC1155TokenSellingOfferCanceled(uint offerId);
    event ERC1155TokenFromOfferBought(uint offerId);
    event ERC1155TokenFromOfferSold(uint offerId);

    /**
    * @dev Constructor Function
    */
    constructor() {
        _erc1155ExchangeCount = 0;
        _erc1155OfferCount = 0;
    }

    // ----- VIEWS ----- //
    function getErc1155ExchangeCount() external view returns(uint){
        return _erc1155ExchangeCount;
    }

    function getErc1155OfferCount() external view returns(uint){
        return _erc1155OfferCount;
    }

    function getErc1155ExchangeAll() external view returns(ERC1155Exchange[] memory){
        ERC1155Exchange[] memory exchanges = new ERC1155Exchange[](_erc1155ExchangeCount);
        for(uint i = 1; i <= _erc1155ExchangeCount; i++)
            exchanges[i-1] = _erc1155Exchanges[i];
        return exchanges;
    }

    function getErc1155OfferAll() external view returns(ERC1155Offer[] memory){
        ERC1155Offer[] memory offers = new ERC1155Offer[](_erc1155OfferCount);
        for(uint i = 1; i <= _erc1155OfferCount; i++)
            offers[i-1] = _erc1155Offers[i];
        return offers;
    }

    function getErc1155ExchangeById(uint _exchangeId) external view returns(ERC1155Exchange memory){
        return _erc1155Exchanges[_exchangeId];
    }

    function getErc1155OfferById(uint _offerId) external view returns(ERC1155Offer memory){
        return _erc1155Offers[_offerId];
    }

    // ----- PUBLIC METHODS ----- //
    /**
    * @dev Owner of token can create Exchange of ERC1155
    * @dev exchangeTokenAddress address of exchangeToken(ERC1155) 
    * @dev offerTokenAddress address of exchangeToken(ERC1155) 
    * @dev tokenId ERC1155 token id of Exchange
    * @dev amount amount of exchange
    * @dev price token price of Exchange
    */
    function CreateERC1155TokenExchange(CreateERC1155TokenExchangeRequest memory input, address caller) external {
        IERC1155 token = IERC1155(input.exchangeTokenAddress);
        require(
            token.balanceOf(caller, input.tokenId) >= input.amount, 
            "TokenExchange.CreateERC1155TokenExchange: Your balance is not enough"
        );
        require(input.price > 0, "TokenExchange.CreateERC1155TokenExchange: price can't be lower or equal to zero");
        require(
            token.isApprovedForAll(caller, address(this)),
            "TokenExchange.CreateERC1155TokenExchange: Owner has not approved"
        );
        
        token.safeTransferFrom(caller, address(this), input.tokenId, input.amount, "");

        /**
        * @dev store exchange and initial offer
        */
        ERC1155Exchange memory exchange;
        exchange.exchangeName = input.exchangeName;
        exchange.creatorAddress = caller;
        exchange.exchangeTokenAddress = input.exchangeTokenAddress;
        exchange.offerTokenAddress = input.offerTokenAddress;
        exchange.initialAmount = input.amount;
        exchange.price = input.price; 

        _erc1155ExchangeCount++;
        _erc1155Exchanges[_erc1155ExchangeCount] = exchange;

        ERC1155Offer memory offer;
        offer.exchangeId = _erc1155ExchangeCount;
        offer.offerType = "SELL";
        offer.creatorAddress = caller;
        offer.tokenId = input.tokenId;
        offer.amount = input.amount;
        offer.price = exchange.price;

        _erc1155OfferCount++;
        offer.offerId = _erc1155OfferCount;
        _erc1155Offers[_erc1155OfferCount] = offer;

        emit ERC1155TokenExchangeCreated(_erc1155ExchangeCount, _erc1155OfferCount);
    }

    /**
    * @dev someone can create buying offer for ERC1155 token exchange
    * @dev exchangeTokenId id of exchange 
    * @dev tokenId ERC1155 token id of Exchange
    * @dev amount amount of exchange
    * @dev price token price of Exchange
    */
    function PlaceERC1155TokenBuyingOffer(PlaceERC1155TokenOfferRequest memory input, address caller) external {
        IERC20 token = IERC20(_erc1155Exchanges[input.exchangeId].offerTokenAddress);
        require(
            token.balanceOf(caller) >= (input.price * input.amount), 
            "TokenExchange.PlaceERC1155TokenBuyingOffer: you don't have enough balance"
        );
        require(input.price > 0, "TokenExchange.PlaceERC1155TokenBuyingOffer: price can't be lower or equal to zero");

        token.transferFrom(caller, address(this), input.price * input.amount);

        /**
        * @dev store buying offer
        */
        ERC1155Offer memory offer;
        offer.exchangeId = input.exchangeId;
        offer.offerType = "BUY";
        offer.creatorAddress = caller;
        offer.tokenId = input.tokenId;
        offer.amount = input.amount;
        offer.price = input.price;

        _erc1155OfferCount++;
        offer.offerId = _erc1155OfferCount;
        _erc1155Offers[_erc1155OfferCount] = offer;

        emit ERC1155TokenBuyingOfferPlaced(_erc1155OfferCount);
    }

    /**
    * @dev owner of token can create selling offer for ERC1155 token exchange
    * @dev exchangeTokenId id of exchange 
    * @dev tokenId ERC1155 token id of Exchange
    * @dev amount amount of exchange
    * @dev price token price of Exchange
    */
    function PlaceERC1155TokenSellingOffer(PlaceERC1155TokenOfferRequest memory input, address caller) external {
        IERC1155 token = IERC1155(_erc1155Exchanges[input.exchangeId].exchangeTokenAddress);
        require(
            token.balanceOf(caller, input.tokenId) >= input.amount, 
            "TokenExchange.PlaceERC1155TokenSellingOffer: Your balance is not enough"
        );
        require(input.price > 0, "TokenExchange.PlaceERC1155TokenSellingOffer: price can't be lower or equal to zero");
        require(
            token.isApprovedForAll(caller, address(this)),
            "TokenExchange.PlaceERC1155TokenSellingOffer: Owner has not approved"
        );

        token.safeTransferFrom(caller, address(this), input.tokenId, input.amount, "");

        /**
        * @dev store selling offer
        */
        ERC1155Offer memory offer;
        offer.exchangeId = input.exchangeId;
        offer.offerType = "SELL";
        offer.creatorAddress = caller;
        offer.tokenId = input.tokenId;
        offer.amount = input.amount;
        offer.price = input.price;

        _erc1155OfferCount++;
        offer.offerId = _erc1155OfferCount;
        _erc1155Offers[_erc1155OfferCount] = offer;

        emit ERC1155TokenSellingOfferPlaced(_erc1155OfferCount);
    }

    /**
    * @dev creator of buying offer can cancel his ERC721Token BuyingOffer
    * @dev exchangeTokenId id of exchange 
    * @dev offerId id of offer
    */
    function CancelERC1155TokenBuyingOffer(CancelOfferRequest memory input, address caller) external{
        ERC1155Offer memory offer = _erc1155Offers[input.offerId];
        IERC20 token = IERC20(_erc1155Exchanges[input.exchangeId].offerTokenAddress);
        require(offer.creatorAddress == caller, "TokenExchange.CancelERC1155TokenBuyingOffer: should be owner");
        require(offer.exchangeId == input.exchangeId, "TokenExchange.CancelERC1155TokenBuyingOffer: should be the same exchangeId");
        require(
            keccak256(abi.encodePacked(offer.offerType)) == keccak256(abi.encodePacked("BUY")), 
            "TokenExchange.CancelERC1155TokenBuyingOffer: should be the buying offer"
        );

        require(
            token.balanceOf(address(this)) >= (offer.price * offer.amount),
            "TokenExchange.CancelERC1155TokenBuyingOffer: you don't have enough balance"
        );
        
        token.transfer(caller, offer.price * offer.amount);            
        delete _erc1155Offers[input.offerId];

        emit ERC1155TokenBuyingOfferCanceled(input.offerId);
    }

    /**
    * @dev creator of selling offer can cancel his ERC1155 SellingOffer
    * @dev exchangeTokenId id of exchange 
    * @dev offerId id of offer
    */
    function CancelERC1155TokenSellingOffer(CancelOfferRequest memory input, address caller) external{
        ERC1155Offer memory offer = _erc1155Offers[input.offerId];
        IERC1155 token = IERC1155(_erc1155Exchanges[input.exchangeId].exchangeTokenAddress);
        require(offer.creatorAddress == caller, "TokenExchange.CancelERC1155TokenSellingOffer: should be owner");
        require(offer.exchangeId == input.exchangeId, "TokenExchange.CancelERC1155TokenSellingOffer: should be the same exchangeId");
        require(
            keccak256(abi.encodePacked(offer.offerType)) == keccak256(abi.encodePacked("SELL")), 
            "TokenExchange.CancelERC1155TokenSellingOffer: should be the selling offer"
        );
        require(
            token.balanceOf(address(this), offer.tokenId) >= offer.amount, 
            "TokenExchange.CancelERC1155TokenSellingOffer: need to own this token"
        );
        
        token.safeTransferFrom(address(this), caller, offer.tokenId, offer.amount, "");
        delete _erc1155Offers[input.offerId];

        emit ERC1155TokenSellingOfferCanceled(input.offerId);
    }

    /**
    * @dev someone can buy token(ERC1155) from selling offer
    * @dev exchangeTokenId id of exchange 
    * @dev offerId id of offer
    */
    function BuyERC1155TokenFromOffer(OfferRequest memory input, address caller) external{
        ERC1155Offer memory offer = _erc1155Offers[input.offerId];
        IERC20 erc20token = IERC20(_erc1155Exchanges[input.exchangeId].offerTokenAddress);
        IERC1155 erc1155token = IERC1155(_erc1155Exchanges[input.exchangeId].exchangeTokenAddress);

        require(offer.exchangeId == input.exchangeId, "TokenExchange.BuyERC1155TokenFromOffer: should be the same exchangeId");
        require(
            keccak256(abi.encodePacked(offer.offerType)) == keccak256(abi.encodePacked("SELL")), 
            "TokenExchange.BuyERC1155TokenFromOffer: should be the selling offer"
        );
        require(
            erc20token.balanceOf(caller) >= (offer.price * offer.amount),
            "TokenExchange.BuyERC1155TokenFromOffer: you don't have enough balance"
        );
        require(
            erc1155token.balanceOf(address(this), offer.tokenId) >= offer.amount, 
            "TokenExchange.BuyERC1155TokenFromOffer: Your balance is not enough"
        );

        erc20token.transferFrom(caller, offer.creatorAddress, offer.price * offer.amount); 
        erc1155token.safeTransferFrom(address(this), caller, offer.tokenId, offer.amount, "");
        delete _erc1155Offers[input.offerId];

        emit ERC1155TokenFromOfferBought(input.offerId);
    }

    /**
    * @dev owner of token can sell token(ERC1155) from buying offer
    * @dev exchangeTokenId id of exchange 
    * @dev offerId id of offer
    */
    function SellERC1155TokenFromOffer(OfferRequest memory input, address caller) external{
        ERC1155Offer memory offer = _erc1155Offers[input.offerId];
        IERC20 erc20token = IERC20(_erc1155Exchanges[input.exchangeId].offerTokenAddress);
        IERC1155 erc1155token = IERC1155(_erc1155Exchanges[input.exchangeId].exchangeTokenAddress);

        require(offer.exchangeId == input.exchangeId, "TokenExchange.SellERC1155TokenFromOffer: should be the same exchangeId");
        require(
            keccak256(abi.encodePacked(offer.offerType)) == keccak256(abi.encodePacked("BUY")), 
            "TokenExchange.SellERC1155TokenFromOffer: should be the buying offer"
        );
        require(
            erc20token.balanceOf(address(this)) >= (offer.price * offer.amount),
            "TokenExchange.SellERC1155TokenFromOffer: you don't have enough balance"
        );

        require(
            erc1155token.balanceOf(caller, offer.tokenId) >= offer.amount, 
            "TokenExchange.SellERC1155TokenFromOffe: need to own this token"
        );
        require(
            erc1155token.isApprovedForAll(caller, address(this)),
            "TokenExchange.SellERC1155TokenFromOffe: Owner has not approved2"
        );

        erc20token.transfer(caller, offer.price * offer.amount); 
        erc1155token.safeTransferFrom(caller, offer.creatorAddress, offer.tokenId, offer.amount, "");
        delete _erc1155Offers[input.offerId];

        emit ERC1155TokenFromOfferSold(input.offerId);
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

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

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

import "../../utils/introspection/IERC165.sol";

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

import "../../utils/introspection/IERC165.sol";

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
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

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

