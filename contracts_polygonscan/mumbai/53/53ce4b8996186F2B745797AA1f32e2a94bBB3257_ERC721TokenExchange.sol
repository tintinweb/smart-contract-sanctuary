// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

/**
 * @dev Exchange Contract for ERC721 Token
 */
contract ERC721TokenExchange is IERC721Receiver {
    /**
    * @dev Exchange struct for ERC721 Token
    */
    struct ERC721Exchange {
        string exchangeName;
        address creatorAddress;
        address exchangeTokenAddress;
        address offerTokenAddress;
        uint price;
    }

    /**
    * @dev Offer struct for ERC721 Token
    */
    struct ERC721Offer {
        uint exchangeId;
        uint offerId;
        string offerType;
        address creatorAddress;
        uint tokenId;
        uint price;
    }

    /**
    * @dev Request struct for creating ERC721TokenExchange
    */
    struct CreateERC721TokenExchangeRequest {
        string exchangeName;
        address exchangeTokenAddress;
        address offerTokenAddress;
        uint tokenId;
        uint price;
    }

    /**
    * @dev Request struct for Place ERC721Token Offer
    */
    struct PlaceERC721TokenOfferRequest {
        uint exchangeId;
        uint tokenId;
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
    * @dev count variables for ERC721Token exchange and offer mapping
    */
    uint internal _erc721ExchangeCount;
    uint internal _erc721OfferCount;

    /**
    * @dev variables for storing ERC721Token Exchange and Offer
    */
    mapping(uint => ERC721Exchange) internal _erc721Exchanges;
    mapping(uint => ERC721Offer) internal _erc721Offers;

    // ----- EVENTS ----- //
    event ERC721TokenExchangeCreated(uint exchangeId, uint initialOfferId);
    event ERC721TokenBuyingOfferPlaced(uint offerId);
    event ERC721TokenSellingOfferPlaced(uint offerId);
    event ERC721TokenBuyingOfferCanceled(uint offerId);
    event ERC721TokenSellingOfferCanceled(uint offerId);
    event ERC721TokenFromOfferBought(uint offerId);
    event ERC721TokenFromOfferSold(uint offerId);

    /**
    * @dev Constructor Function
    */
    constructor() {
        _erc721ExchangeCount = 0;
        _erc721OfferCount = 0;
    }

    // ----- VIEWS ----- //
    function getErc721ExchangeCount() external view returns(uint){
        return _erc721ExchangeCount;
    }

    function getErc721OfferCount() external view returns(uint){
        return _erc721OfferCount;
    }

    function getErc721ExchangeAll() external view returns(ERC721Exchange[] memory){
        ERC721Exchange[] memory exchanges = new ERC721Exchange[](_erc721ExchangeCount);
        for(uint i = 1; i <= _erc721ExchangeCount; i++)
            exchanges[i-1] = _erc721Exchanges[i];
        return exchanges;
    }

    function getErc721OfferAll() external view returns(ERC721Offer[] memory){
        ERC721Offer[] memory offers = new ERC721Offer[](_erc721OfferCount);
        for(uint i = 1; i <= _erc721OfferCount; i++) {
            offers[i-1] = _erc721Offers[i];
        }
        return offers;
    }

    function getErc721ExchangeById(uint _exchangeId) external view returns(ERC721Exchange memory){
        return _erc721Exchanges[_exchangeId];
    }

    function getErc721OfferById(uint _offerId) external view returns(ERC721Offer memory){
        return _erc721Offers[_offerId];
    }

    // ----- PUBLIC METHODS ----- //
    /**
    * @dev Owner of token can create Exchange of ERC721
    * @dev exchangeTokenAddress address of exchangeToken(ERC721) 
    * @dev offerTokenAddress address of exchangeToken(ERC721) 
    * @dev tokenId ERC721 token id of Exchange
    * @dev price token price of Exchange
    */
    function CreateERC721TokenExchange(CreateERC721TokenExchangeRequest memory input, address caller) external {
        IERC721 token = IERC721(input.exchangeTokenAddress);
        require(token.ownerOf(input.tokenId) == caller, "TokenExchange.CreateERC721TokenExchange: You need to own this token");
        require(input.price > 0, "TokenExchange.CreateERC721TokenExchange: price can't be lower or equal to zero");
        require(
            token.isApprovedForAll(caller, address(this)),
            "TokenExchange.CreateERC721TokenExchange: Owner has not approved"
        );
        
        token.safeTransferFrom(caller, address(this), input.tokenId, "");

        /**
        * @dev store exchange and initial offer
        */
        ERC721Exchange memory exchange;
        exchange.exchangeName = input.exchangeName;
        exchange.creatorAddress = caller;
        exchange.exchangeTokenAddress = input.exchangeTokenAddress;
        exchange.offerTokenAddress = input.offerTokenAddress;
        exchange.price = input.price; 

        _erc721ExchangeCount++;
        _erc721Exchanges[_erc721ExchangeCount] = exchange;

        ERC721Offer memory offer;
        offer.exchangeId = _erc721ExchangeCount;
        offer.offerType = "SELL";
        offer.creatorAddress = caller;
        offer.tokenId = input.tokenId;
        offer.price = exchange.price;

        _erc721OfferCount++;
        offer.offerId = _erc721OfferCount;
        _erc721Offers[_erc721OfferCount] = offer;

        emit ERC721TokenExchangeCreated(_erc721ExchangeCount, _erc721OfferCount);
    }

    /**
    * @dev someone can create buying offer for ERC721 token exchange
    * @dev exchangeTokenId id of exchange 
    * @dev tokenId ERC721 token id of Exchange
    * @dev price token price of Exchange
    */
    function PlaceERC721TokenBuyingOffer(PlaceERC721TokenOfferRequest memory input, address caller) external {
        IERC20 token = IERC20(_erc721Exchanges[input.exchangeId].offerTokenAddress);
        require(token.balanceOf(caller) >= input.price, "TokenExchange.PlaceERC721TokenBuyingOffer: you don't have enough balance");
        require(input.price > 0, "TokenExchange.PlaceERC721TokenBuyingOffer: price can't be lower or equal to zero");

        token.transferFrom(caller, address(this), input.price);

        /**
        * @dev store buying offer
        */
        ERC721Offer memory offer;
        offer.exchangeId = input.exchangeId;
        offer.offerType = "BUY";
        offer.creatorAddress = caller;
        offer.tokenId = input.tokenId;
        offer.price = input.price;

        _erc721OfferCount++;
        offer.offerId = _erc721OfferCount;
        _erc721Offers[_erc721OfferCount] = offer;

        emit ERC721TokenBuyingOfferPlaced(_erc721OfferCount);
    }

    /**
    * @dev owner of token can create selling offer for ERC721 token exchange
    * @dev exchangeTokenId id of exchange 
    * @dev tokenId ERC721 token id of Exchange
    * @dev price token price of Exchange
    */
    function PlaceERC721TokenSellingOffer(PlaceERC721TokenOfferRequest memory input, address caller) external {
        IERC721 token = IERC721(_erc721Exchanges[input.exchangeId].exchangeTokenAddress);
        require(token.ownerOf(input.tokenId) == caller, "TokenExchange.PlaceERC721TokenSellingOffer: You need to own this token");
        require(input.price > 0, "TokenExchange.PlaceERC721TokenSellingOffer: price can't be lower or equal to zero");
        require(
            token.isApprovedForAll(caller, address(this)),
            "TokenExchange.PlaceERC721TokenSellingOffer: Owner has not approved"
        );

        token.safeTransferFrom(caller, address(this), input.tokenId);

        /**
        * @dev store selling offer
        */
        ERC721Offer memory offer;
        offer.exchangeId = input.exchangeId;
        offer.offerType = "SELL";
        offer.creatorAddress = caller;
        offer.tokenId = input.tokenId;
        offer.price = input.price;

        _erc721OfferCount++;
        offer.offerId = _erc721OfferCount;
        _erc721Offers[_erc721OfferCount] = offer;

        emit ERC721TokenSellingOfferPlaced(_erc721OfferCount);
    }

    /**
    * @dev creator of buying offer can cancel his ERC721Token BuyingOffer
    * @dev exchangeTokenId id of exchange 
    * @dev offerId id of offer
    */
    function CancelERC721TokenBuyingOffer(CancelOfferRequest memory input, address caller) external{
        ERC721Offer memory offer = _erc721Offers[input.offerId];
        IERC20 token = IERC20(_erc721Exchanges[input.exchangeId].offerTokenAddress);
        require(offer.creatorAddress == caller, "TokenExchange.CancelERC721TokenBuyingOffer: should be owner");
        require(offer.exchangeId == input.exchangeId, "TokenExchange.CancelERC721TokenBuyingOffer: should be the same exchangeId");
        require(
            keccak256(abi.encodePacked(offer.offerType)) == keccak256(abi.encodePacked("BUY")), 
            "TokenExchange.CancelERC721TokenBuyingOffer: should be the buying offer"
        );

        require(
            token.balanceOf(address(this)) >= offer.price,
            "TokenExchange.CancelERC721TokenBuyingOffer: you don't have enough balance"
        );
        
        token.transfer(caller, offer.price);            
        delete _erc721Offers[input.offerId];

        emit ERC721TokenBuyingOfferCanceled(input.offerId);
    }

    /**
    * @dev creator of selling offer can cancel his ERC721 SellingOffer
    * @dev exchangeTokenId id of exchange 
    * @dev offerId id of offer
    */
    function CancelERC721TokenSellingOffer(CancelOfferRequest memory input, address caller) external{
        ERC721Offer memory offer = _erc721Offers[input.offerId];
        IERC721 token = IERC721(_erc721Exchanges[input.exchangeId].exchangeTokenAddress);
        require(offer.creatorAddress == caller, "TokenExchange.CancelERC721TokenSellingOffer: should be owner");
        require(offer.exchangeId == input.exchangeId, "TokenExchange.CancelERC721TokenSellingOffer: should be the same exchangeId");
        require(
            keccak256(abi.encodePacked(offer.offerType)) == keccak256(abi.encodePacked("SELL")), 
            "TokenExchange.CancelERC721TokenSellingOffer: should be the selling offer"
        );
        require(token.ownerOf(offer.tokenId) == address(this), "TokenExchange.CancelERC721TokenSellingOffer: need to own this token");
        
        token.safeTransferFrom(address(this), caller, offer.tokenId);
        delete _erc721Offers[input.offerId];

        emit ERC721TokenSellingOfferCanceled(input.offerId);
    }

    /**
    * @dev someone can buy token(ERC721) from selling offer
    * @dev exchangeTokenId id of exchange 
    * @dev offerId id of offer
    */
    function BuyERC721TokenFromOffer(OfferRequest memory input, address caller) external{
        ERC721Offer memory offer = _erc721Offers[input.offerId];
        IERC20 erc20token = IERC20(_erc721Exchanges[input.exchangeId].offerTokenAddress);
        IERC721 erc721token = IERC721(_erc721Exchanges[input.exchangeId].exchangeTokenAddress);

        require(offer.exchangeId == input.exchangeId, "TokenExchange.BuyERC721TokenFromOffer: should be the same exchangeId");
        require(
            keccak256(abi.encodePacked(offer.offerType)) == keccak256(abi.encodePacked("SELL")), 
            "TokenExchange.BuyERC721TokenFromOffer: should be the selling offer"
        );
        require(
            erc20token.balanceOf(caller) >= offer.price,
            "TokenExchange.BuyERC721TokenFromOffer: you don't have enough balance"
        );
        require(erc721token.ownerOf(offer.tokenId) == address(this), "TokenExchange.BuyERC721TokenFromOffer: need to own this token");

        erc20token.transferFrom(caller, offer.creatorAddress, offer.price); 
        erc721token.safeTransferFrom(address(this), caller, offer.tokenId);
        delete _erc721Offers[input.offerId];

        emit ERC721TokenFromOfferBought(input.offerId);
    }

    /**
    * @dev owner of token can sell token(ERC721) from buying offer
    * @dev exchangeTokenId id of exchange 
    * @dev offerId id of offer
    */
    function SellERC721TokenFromOffer(OfferRequest memory input, address caller) external{
        ERC721Offer memory offer = _erc721Offers[input.offerId];
        IERC20 erc20token = IERC20(_erc721Exchanges[input.exchangeId].offerTokenAddress);
        IERC721 erc721token = IERC721(_erc721Exchanges[input.exchangeId].exchangeTokenAddress);

        require(offer.exchangeId == input.exchangeId, "TokenExchange.SellERC721TokenFromOffer: should be the same exchangeId");
        require(
            keccak256(abi.encodePacked(offer.offerType)) == keccak256(abi.encodePacked("BUY")), 
            "TokenExchange.SellERC721TokenFromOffer: should be the buying offer"
        );
        require(
            erc20token.balanceOf(address(this)) >= offer.price,
            "TokenExchange.SellERC721TokenFromOffer: you don't have enough balance"
        );
        require(erc721token.ownerOf(offer.tokenId) == caller, "TokenExchange.SellERC721TokenFromOffer: need to own this token");

        erc20token.transfer(caller, offer.price); 
        erc721token.safeTransferFrom(caller, offer.creatorAddress, offer.tokenId);
        delete _erc721Offers[input.offerId];

        emit ERC721TokenFromOfferSold(input.offerId);
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
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

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}