// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../libraries/helpers/MarketErrors.sol";
import "../interfaces/IVault.sol";
import "../interfaces/IExchangeOrderList.sol";
import "../interfaces/ISellOrderList.sol";

import "../interfaces/mini-interfaces/MiniINFTList.sol";
import "../interfaces/mini-interfaces/MiniIAddressesProvider.sol";

/**
 * @title Market contract
 * - Owned by the MochiLab
 * @author MochiLab
 **/
contract Market is Initializable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 public constant SAFE_NUMBER = 1e12;
    MiniIAddressesProvider public addressesProvider;
    MiniINFTList public nftList;
    ISellOrderList public sellOrderList;
    IVault public vault;
    IExchangeOrderList public exchangeOrderList;
    address public moma;

    mapping(address => bool) public acceptedToken;
    uint256 internal _regularFeeNumerator;
    uint256 internal _regularFeeDenominator;
    uint256 internal _momaFeeNumerator;
    uint256 internal _momaFeeDenominator;

    event RegularFeeUpdated(uint256 numerator, uint256 denominator);
    event MOMAFeeUpdated(uint256 numerator, uint256 denominator);

    modifier onlyMarketAdmin() {
        require(addressesProvider.getAdmin() == msg.sender, MarketErrors.CALLER_NOT_MARKET_ADMIN);
        _;
    }

    /**
     * @dev Function is invoked by the proxy contract when the Market contract is added to the
     * AddressesProvider of the market.
     * - Caching the address of the AddressesProvider in order to reduce gas consumption
     *   on subsequent operations
     * @param provider The address of AddressesProvider
     * @param regularFeeNumerator The fee numerator
     * @param regularFeeDenominator The fee denominator
     **/
    function initialize(
        address provider,
        address momaToken,
        uint256 momaFeeNumerator,
        uint256 momaFeeDenominator,
        uint256 regularFeeNumerator,
        uint256 regularFeeDenominator
    ) external initializer {
        require(
            momaFeeDenominator >= momaFeeNumerator && regularFeeDenominator >= regularFeeNumerator,
            MarketErrors.DEMONINATOR_NOT_GREATER_THAN_NUMERATOR
        );
        addressesProvider = MiniIAddressesProvider(provider);
        nftList = MiniINFTList(addressesProvider.getNFTList());
        sellOrderList = ISellOrderList(addressesProvider.getSellOrderList());
        exchangeOrderList = IExchangeOrderList(addressesProvider.getExchangeOrderList());
        vault = IVault(addressesProvider.getVault());

        moma = momaToken;
        _momaFeeNumerator = momaFeeNumerator;
        _momaFeeDenominator = momaFeeDenominator;
        _regularFeeNumerator = regularFeeNumerator;
        _regularFeeDenominator = regularFeeDenominator;
    }

    /**
     * @dev Accept a token as an exchange unit on the Market
     * - Can only be called by market admin
     * @param token Token address
     **/
    function acceptToken(address token) external onlyMarketAdmin {
        require(acceptedToken[token] == false, MarketErrors.TOKEN_ALREADY_ACCEPTED);
        if (token != address(0)) {
            IERC20(token).safeApprove(address(vault), type(uint256).max);
        }
        vault.setupRewardToken(token);
        acceptedToken[token] = true;
    }

    /**
     * @dev Revoke a token so it cannot be circulated on the Market
     * - Can only be called by market admin
     * @param token Token address
     **/
    function revokeToken(address token) external onlyMarketAdmin {
        require(acceptedToken[token] == true, MarketErrors.TOKEN_ALREADY_REVOKED);
        if (token != address(0)) {
            IERC20(token).approve(address(vault), 0);
        }
        acceptedToken[token] = false;
    }

    /**
     * @dev Update fee for transactions
     * - Can only be called by market admin
     * @param numerator The fee numerator
     * @param denominator The fee denominator
     **/
    function updateRegularFee(uint256 numerator, uint256 denominator) external onlyMarketAdmin {
        require(denominator >= numerator, MarketErrors.DEMONINATOR_NOT_GREATER_THAN_NUMERATOR);
        _regularFeeNumerator = numerator;
        _regularFeeDenominator = denominator;
        emit RegularFeeUpdated(numerator, denominator);
    }

    /**
     * @dev Update fee for transactions
     * - Can only be called by market admin
     * @param numerator The fee numerator
     * @param denominator The fee denominator
     **/
    function updateMomaFee(uint256 numerator, uint256 denominator) external onlyMarketAdmin {
        require(denominator >= numerator, MarketErrors.DEMONINATOR_NOT_GREATER_THAN_NUMERATOR);
        _momaFeeNumerator = numerator;
        _momaFeeDenominator = denominator;
        emit MOMAFeeUpdated(numerator, denominator);
    }

    /**
     * @dev Create a sell order
     * - Can be called at anyone
     * @param nftAddress The address of nft contract
     * @param tokenId The tokenId of nft
     * @param amount The amount of nft seller wants to sell
     * @param price The price offered by seller
     * @param token The token that seller wants to be paid for
     **/
    function createSellOrder(
        address nftAddress,
        uint256 tokenId,
        uint256 amount,
        uint256 price,
        address token
    ) external nonReentrant {
        require(nftList.isAcceptedNFT(nftAddress), MarketErrors.NFT_NOT_ACCEPTED);
        require(price > 0, MarketErrors.PRICE_IS_ZERO);
        require(acceptedToken[token] == true, MarketErrors.TOKEN_NOT_ACCEPTED);

        _transferAsset(nftAddress, tokenId, amount, msg.sender, address(this), "0x");

        sellOrderList.addSellOrder(nftAddress, tokenId, amount, payable(msg.sender), price, token);
    }

    /**
     * @dev Cancel a sell order
     * - Can only be called by seller
     * @param sellId Sell order id
     **/
    function cancelSellOrder(uint256 sellId) external nonReentrant {
        SellOrderType.SellOrder memory sellOrder = sellOrderList.getSellOrderById(sellId);
        require(sellOrder.seller == msg.sender, MarketErrors.CALLER_NOT_SELLER);
        require(sellOrder.isActive == true, MarketErrors.SELL_ORDER_NOT_ACTIVE);

        _transferAsset(
            sellOrder.nftAddress,
            sellOrder.tokenId,
            sellOrder.amount - sellOrder.soldAmount,
            address(this),
            sellOrder.seller,
            "0x"
        );

        sellOrderList.deactiveSellOrder(sellId);
    }

    function removeSellOrder(uint256 sellId) external onlyMarketAdmin {
        SellOrderType.SellOrder memory sellOrder = sellOrderList.getSellOrderById(sellId);
        require(sellOrder.isActive == true, MarketErrors.SELL_ORDER_NOT_ACTIVE);

        _transferAsset(
            sellOrder.nftAddress,
            sellOrder.tokenId,
            sellOrder.amount - sellOrder.soldAmount,
            address(this),
            sellOrder.seller,
            "0x"
        );

        sellOrderList.deactiveSellOrder(sellId);
    }

    /**
     * @dev Buy 1 nft through the respective sell order
     * -  Can be called at anyone
     * @param sellId Sell order id
     * @param amount The amount buyer wants to buy
     **/
    function buy(
        uint256 sellId,
        uint256 amount,
        address receiver,
        bytes calldata data
    ) external payable nonReentrant {
        SellOrderType.SellOrder memory sellOrder = sellOrderList.getSellOrderById(sellId);

        require(sellOrder.seller != msg.sender, MarketErrors.CALLER_IS_SELLER);
        require(sellOrder.isActive == true, MarketErrors.SELL_ORDER_NOT_ACTIVE);

        require(amount > 0, MarketErrors.AMOUNT_IS_ZERO);
        require(
            amount <= sellOrder.amount - sellOrder.soldAmount,
            MarketErrors.AMOUNT_IS_NOT_ENOUGH
        );
        uint256 amountToken = amount * sellOrder.price;

        _transferAndDepositMoney(
            sellOrder.token,
            amountToken,
            sellOrder.seller,
            sellOrder.nftAddress
        );

        _transferAsset(
            sellOrder.nftAddress,
            sellOrder.tokenId,
            amount,
            address(this),
            receiver,
            data
        );

        sellOrderList.completeSellOrder(sellId, msg.sender, amount);
    }

    /**
     * @dev Update price of a sell order
     * - Can only be called by seller
     * @param id Sell order id
     * @param newPrice The new price of sell order
     **/
    function updatePrice(uint256 id, uint256 newPrice) external nonReentrant {
        SellOrderType.SellOrder memory sellOrder = sellOrderList.getSellOrderById(id);
        require(sellOrder.seller == msg.sender, MarketErrors.CALLER_NOT_SELLER);
        require(sellOrder.isActive == true, MarketErrors.SELL_ORDER_NOT_ACTIVE);
        require(sellOrder.price != newPrice, MarketErrors.PRICE_NOT_CHANGE);

        sellOrderList.updatePrice(id, newPrice);
    }

    /**
     * @dev Create an exchange order
     * - Can be called at anyone
     * @param nftAddresses The addresses of source nft and destination nft
     * @param tokenIds The tokenIds of source nft and destination nft
     * @param nftAmounts The amount of source nft and destination nft
     * @param tokens The token that seller wants to be paid for
     * @param prices The price that seller wants
     * @param users Users address
     * @param data Calldata that seller wants to execute when he receives destination nft
     **/
    function createExchangeOrder(
        address[] memory nftAddresses,
        uint256[] memory tokenIds,
        uint256[] memory nftAmounts,
        address[] memory tokens,
        uint256[] memory prices,
        address[] memory users,
        bytes[] memory data
    ) external nonReentrant {
        require(
            nftAddresses.length == tokenIds.length &&
                tokenIds.length == nftAmounts.length &&
                nftAmounts.length == tokens.length &&
                tokens.length == prices.length &&
                prices.length == data.length &&
                users.length == 1,
            MarketErrors.PARAMETERS_NOT_MATCH
        );
        require(msg.sender == users[0], MarketErrors.PARAMETERS_NOT_MATCH);

        require(data[0].length == 0, MarketErrors.INVALID_CALLDATA);

        for (uint256 i = 0; i < nftAddresses.length; i++) {
            require(nftList.isAcceptedNFT(nftAddresses[i]), MarketErrors.NFT_NOT_ACCEPTED);
            if (nftList.isERC1155(nftAddresses[i]) == true) {
                require(nftAmounts[i] > 0, MarketErrors.AMOUNT_IS_ZERO);
            } else {
                require(nftAmounts[i] == 1, MarketErrors.AMOUNT_IS_NOT_EQUAL_ONE);
            }
            if (i > 0 && prices[i] > 0) {
                require(acceptedToken[tokens[i]] == true, MarketErrors.TOKEN_NOT_ACCEPTED);
            }
        }

        _transferAsset(
            nftAddresses[0],
            tokenIds[0],
            nftAmounts[0],
            msg.sender,
            address(this),
            "0x"
        );

        exchangeOrderList.addExchangeOrder(
            nftAddresses,
            tokenIds,
            nftAmounts,
            tokens,
            prices,
            users,
            data
        );
    }

    /**
     * @dev Cancel an exchange order
     * - Can only be called by seller
     * @param exchangeId Exchange order id
     **/
    function cancelExchangeOrder(uint256 exchangeId) external nonReentrant {
        ExchangeOrderType.ExchangeOrder memory exchangeOrder = exchangeOrderList
            .getExchangeOrderById(exchangeId);
        require(exchangeOrder.users[0] == msg.sender, MarketErrors.CALLER_NOT_SELLER);
        require(exchangeOrder.isActive == true, MarketErrors.EXCHANGE_ORDER_NOT_ACTIVE);

        _transferAsset(
            exchangeOrder.nftAddresses[0],
            exchangeOrder.tokenIds[0],
            exchangeOrder.nftAmounts[0],
            address(this),
            exchangeOrder.users[0],
            "0x"
        );

        exchangeOrderList.deactiveExchangeOrder(exchangeId);
    }

    function removeExchangeOrder(uint256 exchangeId) external onlyMarketAdmin {
        ExchangeOrderType.ExchangeOrder memory exchangeOrder = exchangeOrderList
            .getExchangeOrderById(exchangeId);
        require(exchangeOrder.isActive == true, MarketErrors.EXCHANGE_ORDER_NOT_ACTIVE);

        _transferAsset(
            exchangeOrder.nftAddresses[0],
            exchangeOrder.tokenIds[0],
            exchangeOrder.nftAmounts[0],
            address(this),
            exchangeOrder.users[0],
            "0x"
        );

        exchangeOrderList.deactiveExchangeOrder(exchangeId);
    }

    /**
     * @dev Purchase an exchange order
     * -  Can be called at anyone
     * @param exchangeId Exchange order id
     * @param data Calldata that buyer wants to execute upon receiving the nft
     **/
    function exchange(
        uint256 exchangeId,
        uint256 destinationId,
        address receiver,
        bytes memory data
    ) external payable nonReentrant {
        ExchangeOrderType.ExchangeOrder memory exchangeOrder = exchangeOrderList
            .getExchangeOrderById(exchangeId);
        require(exchangeOrder.users[0] != msg.sender, MarketErrors.CALLER_IS_SELLER);
        require(exchangeOrder.isActive == true, MarketErrors.EXCHANGE_ORDER_NOT_ACTIVE);
        require(
            destinationId > 0 && destinationId < exchangeOrder.nftAddresses.length,
            MarketErrors.INVALID_DESTINATION
        );

        _transferAndDepositMoney(
            exchangeOrder.tokens[destinationId],
            exchangeOrder.prices[destinationId],
            exchangeOrder.users[0],
            exchangeOrder.nftAddresses[0]
        );

        _transferAsset(
            exchangeOrder.nftAddresses[destinationId],
            exchangeOrder.tokenIds[destinationId],
            exchangeOrder.nftAmounts[destinationId],
            msg.sender,
            exchangeOrder.users[0],
            exchangeOrder.data[destinationId]
        );

        _transferAsset(
            exchangeOrder.nftAddresses[0],
            exchangeOrder.tokenIds[0],
            exchangeOrder.nftAmounts[0],
            address(this),
            receiver,
            data
        );

        exchangeOrderList.completeExchangeOrder(exchangeId, destinationId, msg.sender);
    }

    /**
     * @dev Get regular fee
     * - external view function
     * @return Regular fee numerator and denominator
     **/
    function getRegularFee() external view returns (uint256, uint256) {
        return (_regularFeeNumerator, _regularFeeDenominator);
    }

    /**
     * @dev Get moma fee
     * - external view function
     * @return Moma fee numerator and denominator
     **/
    function getMomaFee() external view returns (uint256, uint256) {
        return (_momaFeeNumerator, _momaFeeDenominator);
    }

    /**
     * @dev Calculate fee
     * - internal view function, called inside buy(), exchange() function
     * @param token The  token address
     * @param price The price of transaction
     **/
    function _calculateFee(address token, uint256 price) internal view returns (uint256 fee) {
        if (token == moma) {
            fee = ((price * SAFE_NUMBER * _momaFeeNumerator) / _momaFeeDenominator) / SAFE_NUMBER;
        } else {
            fee =
                ((price * SAFE_NUMBER * _regularFeeNumerator) / _regularFeeDenominator) /
                SAFE_NUMBER;
        }
    }

    function _transferAndDepositMoney(
        address token,
        uint256 amount,
        address seller,
        address nftAddress
    ) internal {
        uint256 fee = _calculateFee(token, amount);

        if (token == address(0)) {
            require(msg.value == amount, MarketErrors.VALUE_NOT_EQUAL_PRICE);
            payable(seller).transfer(amount - fee);

            if (fee > 0) {
                vault.deposit{value: fee}(nftAddress, seller, msg.sender, token, fee);
            }
        } else {
            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
            IERC20(token).safeTransfer(seller, amount - fee);

            if (fee > 0) {
                vault.deposit(nftAddress, seller, msg.sender, token, fee);
            }
        }
    }

    function _transferAsset(
        address nftAddress,
        uint256 tokenId,
        uint256 amount,
        address from,
        address to,
        bytes memory data
    ) internal {
        if (nftList.isERC1155(nftAddress) == true) {
            require(amount > 0, MarketErrors.AMOUNT_IS_ZERO);
            IERC1155(nftAddress).safeTransferFrom(from, to, tokenId, amount, data);
        } else {
            require(amount == 1, MarketErrors.AMOUNT_IS_NOT_EQUAL_ONE);
            IERC721(nftAddress).safeTransferFrom(from, to, tokenId, data);
        }
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external pure returns (bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

library MarketErrors {
    string public constant CALLER_NOT_MARKET_ADMIN = "Caller is not the market admin"; // 'The caller must be the market admin'
    string public constant DEMONINATOR_NOT_GREATER_THAN_NUMERATOR =
        "Demoninator not greater than numerator"; // 'The fee denominator must be greater than fee numerator'
    string public constant TOKEN_ALREADY_ACCEPTED = "Token already accepted"; // 'Token already accepted'
    string public constant TOKEN_ALREADY_REVOKED = "Token already revoked"; // 'Token must be accepted'
    string public constant NFT_NOT_ACCEPTED = "NFT is not accepted"; // 'The nft address muse be accepted'
    string public constant TOKEN_NOT_ACCEPTED = "Token is not accepted"; // 'Token is not accepted'
    string public constant AMOUNT_IS_ZERO = "Amount is zero"; // 'Amount must be accepted'
    string public constant INSUFFICIENT_BALANCE = "Insufficient balance"; // 'The fund must be equal or greater than amount to withdraw'
    string public constant NFT_NOT_APPROVED_FOR_MARKET = "NFT is not approved for Market"; // 'The nft must be approved for Market'
    string public constant SELL_ORDER_DUPLICATE = "Sell order is duplicate"; // 'The sell order must be unique'
    string public constant AMOUNT_IS_NOT_EQUAL_ONE = "Amount is not equal 1"; // 'Amount must equal 1'
    string public constant CALLER_NOT_NFT_OWNER = "Caller is not nft owner"; // 'The caller must be the owner of nft'
    string public constant PRICE_IS_ZERO = "Price is zero"; // 'The new price must be greater than zero'
    string public constant CALLER_NOT_SELLER = "Caller is not seller"; // 'The caller must be the seller'
    string public constant SELL_ORDER_NOT_ACTIVE = "Sell order is not active"; // 'The sell order must be active'
    string public constant CALLER_IS_SELLER = "Caller is seller"; // 'The caller must be not the seller'
    string public constant AMOUNT_IS_NOT_ENOUGH = "Amount is not enough"; // 'Amount is not enough'
    string public constant VALUE_NOT_EQUAL_PRICE = "Msg.value is not equal price"; // 'The msg.value must equal price'
    string public constant PRICE_NOT_CHANGE = "Price is not change"; // 'The new price must be not equal price'
    string public constant PARAMETERS_NOT_MATCH = "The parameters are not match"; // 'The parameters must be match'
    string public constant INVALID_CALLDATA = "Invalid call data"; // 'Invalid call data'
    string public constant EXCHANGE_ORDER_DUPLICATE = "Exchange order is duplicate"; // 'The exchange order must be unique'
    string public constant INVALID_DESTINATION = "Invalid destination"; // 'Invalid destination id'
    string public constant EXCHANGE_ORDER_NOT_ACTIVE = "Exchange order is not active";
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/**
 * @title Interface of Vault contract
 * - Owned by the MochiLab
 * @author MochiLab
 **/
interface IVault {
    function setupRewardToken(address token) external;

    function deposit(
        address nftAddress,
        address seller,
        address buyer,
        address token,
        uint256 amount
    ) external payable;

    function withdrawFund(
        address token,
        uint256 amount,
        address payable receiver
    ) external;

    function claimRoyalty(
        address nftAddress,
        address token,
        uint256 amount,
        address payable receiver
    ) external;

    function withrawRewardToken(
        address rewardToken,
        uint256 amount,
        address receiver
    ) external;

    function setupRewardParameters(
        uint256 periodOfCycle,
        uint256 numberOfCycle,
        uint256 startTime,
        uint256 firstRate
    ) external;

    function updateRoyaltyParameters(uint256 numerator, uint256 denominator) external;

    function getCurrentRate() external view returns (uint256);

    function getCurrentPeriod() external view returns (uint256);

    function getRewardToken(address token) external view returns (address);

    function getRewardTokenBalance(address user, address rewardToken)
        external
        view
        returns (uint256);

    function getMochiFund(address token) external view returns (uint256);

    function getRoyaltyParameters() external view returns (uint256, uint256);

    function checkRewardIsActive() external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "../libraries/types/ExchangeOrderType.sol";

/**
 * @title Interface of ExchangeOrderList contract
 * - Owned by the MochiLab
 * @author MochiLab
 **/
interface IExchangeOrderList {
    function addExchangeOrder(
        address[] memory nftAddresses,
        uint256[] memory tokenIds,
        uint256[] memory nftAmounts,
        address[] memory tokens,
        uint256[] memory prices,
        address[] memory users,
        bytes[] memory datas
    ) external;

    function deactiveExchangeOrder(uint256 exchangeId) external;

    function completeExchangeOrder(
        uint256 exchangeId,
        uint256 destinationId,
        address buyer
    ) external;

    function getExchangeOrderById(uint256 exchangeId)
        external
        view
        returns (ExchangeOrderType.ExchangeOrder memory);

    function getExchangeOrdersByIdList(uint256[] memory idList)
        external
        view
        returns (ExchangeOrderType.ExchangeOrder[] memory);

    function getAllExchangeOrders()
        external
        view
        returns (ExchangeOrderType.ExchangeOrder[] memory);

    function getExchangeOrderCount() external view returns (uint256);

    function getAvailableExchangeOrders()
        external
        view
        returns (
            ExchangeOrderType.ExchangeOrder[] memory,
            ExchangeOrderType.ExchangeOrder[] memory
        );

    function getAvailableExchangeOrdersIdList()
        external
        view
        returns (uint256[] memory, uint256[] memory);

    function getAllExchangeOrdersByUser(address user)
        external
        view
        returns (ExchangeOrderType.ExchangeOrder[] memory);

    function getAllExchangeOrdersIdListByUser(address user)
        external
        view
        returns (uint256[] memory);

    function getAvailableExchangeOrdersByUser(address user)
        external
        view
        returns (
            ExchangeOrderType.ExchangeOrder[] memory,
            ExchangeOrderType.ExchangeOrder[] memory
        );

    function getAvailableExchangeOrdersIdListByUser(address user)
        external
        view
        returns (uint256[] memory, uint256[] memory);

    function getAllExchangeOrdersByNftAddress(address nftAddress)
        external
        view
        returns (ExchangeOrderType.ExchangeOrder[] memory);

    function getAvailableExchangeOrdersByNftAddress(address nftAddress)
        external
        view
        returns (ExchangeOrderType.ExchangeOrder[] memory);

    function getAllExchangeOrdersIdListByNftAddress(address nftAddress)
        external
        view
        returns (uint256[] memory);

    function getAvailableExchangeOrdersIdListByNftAddress(address nftAddress)
        external
        view
        returns (uint256[] memory);

    function getExchangeOrdersBoughtByUser(address user)
        external
        view
        returns (ExchangeOrderType.ExchangeOrder[] memory);

    function getExchangeOrdersBoughtIdListByUser(address user)
        external
        view
        returns (uint256[] memory);

    function getLatestExchangeIdERC721(address nftAddress, uint256 tokenId)
        external
        view
        returns (bool found, uint256 id);

    function getLatestExchangeIdERC1155(
        address seller,
        address nftAddress,
        uint256 tokenId
    ) external view returns (bool found, uint256 id);

    function checkDuplicateERC721(
        address nftAddress,
        uint256 tokenId,
        address seller
    ) external view returns (bool);

    function checkDuplicateERC1155(
        address nftAddress,
        uint256 tokenId,
        address seller
    ) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "../libraries/types/SellOrderType.sol";

/**
 * @title Interface of SellOrderList contract
 * - Owned by the MochiLab
 * @author MochiLab
 **/
interface ISellOrderList {
    function addSellOrder(
        address nftAddress,
        uint256 tokenId,
        uint256 amount,
        address payable seller,
        uint256 price,
        address token
    ) external;

    function deactiveSellOrder(uint256 sellId) external;

    function completeSellOrder(
        uint256 sellId,
        address buyer,
        uint256 amount
    ) external;

    function updatePrice(uint256 sellId, uint256 newPrice) external;

    function getSellOrderById(uint256 sellId)
        external
        view
        returns (SellOrderType.SellOrder memory);

    function getSellOrdersByIdList(uint256[] memory idList)
        external
        view
        returns (SellOrderType.SellOrder[] memory);

    function getSellOrdersByRange(uint256 fromId, uint256 toId)
        external
        view
        returns (SellOrderType.SellOrder[] memory);

    function getAllSellOrders() external view returns (SellOrderType.SellOrder[] memory);

    function getSellOrderCount() external view returns (uint256);

    function getAvailableSellOrders()
        external
        view
        returns (SellOrderType.SellOrder[] memory erc721, SellOrderType.SellOrder[] memory erc1155);

    function getAvailableSellOrdersIdList()
        external
        view
        returns (uint256[] memory erc721, uint256[] memory erc1155);

    function getAllSellOrdersByUser(address user)
        external
        view
        returns (SellOrderType.SellOrder[] memory);

    function getAllSellOrdersIdListByUser(address user) external view returns (uint256[] memory);

    function getAvailableSellOrdersByUser(address user)
        external
        view
        returns (SellOrderType.SellOrder[] memory erc721, SellOrderType.SellOrder[] memory erc1155);

    function getAvailableSellOrdersIdListByUser(address user)
        external
        view
        returns (uint256[] memory erc721, uint256[] memory erc1155);

    function getAllSellOrdersByNftAddress(address nftAddress)
        external
        view
        returns (SellOrderType.SellOrder[] memory);

    function getAllSellOrdersIdListByNftAddress(address nftAddress)
        external
        view
        returns (uint256[] memory);

    function getAvailableSellOrdersByNftAddress(address nftAddress)
        external
        view
        returns (SellOrderType.SellOrder[] memory);

    function getAvailableSellOrdersIdListByNftAddress(address nftAddress)
        external
        view
        returns (uint256[] memory);

    function getSellOrdersBoughtByUser(address user)
        external
        view
        returns (SellOrderType.SellOrder[] memory);

    function getSellOrdersBoughtIdListByUser(address user) external view returns (uint256[] memory);

    function getLatestSellIdERC721(address nftAddress, uint256 tokenId)
        external
        view
        returns (bool found, uint256 id);

    function getLatestSellIdERC1155(
        address seller,
        address nftAddress,
        uint256 tokenId
    ) external view returns (bool found, uint256 id);

    function checkDuplicateERC721(
        address nftAddress,
        uint256 tokenId,
        address seller
    ) external view returns (bool);

    function checkDuplicateERC1155(
        address nftAddress,
        uint256 tokenId,
        address seller
    ) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "../../libraries/types/NFTInfoType.sol";

/**
 * @title Interface of NFTList contract
 * - Owned by the MochiLab
 * @author MochiLab
 **/
interface MiniINFTList {
    function isERC1155(address nftAddress) external view returns (bool);

    function getNFTInfo(address nftAddress) external view returns (NFTInfoType.NFTInfo memory);

    function getNFTCount() external view returns (uint256);

    function getAcceptedNFTs() external view returns (address[] memory);

    function isAcceptedNFT(address nftAddress) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/**
 * @title Interface of AddressesProvider contract
 * - Owned by the MochiLab
 * @author MochiLab
 **/
interface MiniIAddressesProvider {
    function getAddress(bytes32 id) external view returns (address);

    function getNFTList() external view returns (address);

    function getMarket() external view returns (address);

    function getSellOrderList() external view returns (address);

    function getExchangeOrderList() external view returns (address);

    function getVault() external view returns (address);

    function getCreativeStudio() external view returns (address);

    function getAdmin() external view returns (address);
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

library ExchangeOrderType {
    struct ExchangeOrder {
        // exchangeId
        uint256 exchangeId;
        // source and destination nft address
        address[] nftAddresses;
        // source and destination nft tokenId
        uint256[] tokenIds;
        // amount of soucre and destination nft
        uint256[] nftAmounts;
        // tokens
        address[] tokens;
        // prices
        uint256[] prices;
        // users join exchane
        address[] users;
        // exchange times
        uint256[] times;
        // call data;
        bytes[] data;
        // is active
        bool isActive;
        // sold amount
        uint256 soldAmount;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

library SellOrderType {
    struct SellOrder {
        //the id of sell order in array
        uint256 sellId;
        // the address of the nft
        address nftAddress;
        // the tokenId
        uint256 tokenId;
        // amount to sell
        uint256 amount;
        // sold amount
        uint256 soldAmount;
        // seller
        address payable seller;
        // unit price
        uint256 price;
        // token
        address token;
        // is active to buy
        bool isActive;
        // time create a sell order
        uint256 sellTime;
        // buyers
        address[] buyers;
        // buy time
        uint256[] buyTimes;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

library NFTInfoType {
    struct NFTInfo {
        // the id of the nft in array
        uint256 id;
        // nft address
        address nftAddress;
        // is ERC1155
        bool isERC1155;
        // is registered
        bool isRegistered;
        // is accepted by admin
        bool isAccepted;
        // registrant
        address registrant;
    }
}