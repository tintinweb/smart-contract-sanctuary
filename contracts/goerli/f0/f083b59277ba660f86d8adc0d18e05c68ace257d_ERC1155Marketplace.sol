// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract ERC1155Marketplace is Initializable, ERC1155HolderUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct MarketFee {
        address currency;
        uint256 percentage;
    }
    
    struct ExchangeFee {
        address currency;
        uint256 amount;
    }

    struct ListingItem {
        address currency;
        uint256 price;
        uint256 amount;
        uint256 feePercentage;
    }

    struct OfferingItem {
        address currency;
        uint256 price;
        uint256 amount;
        uint256 feePercentage;
    }

    struct ExchangingItem {
        uint256 srcItemId;
        uint256[] destItemIds;
        uint256[] destItemAmounts;
        uint256 amount;
        address feeCurrency;
        uint256 feeAmount;
    }

    // The address which will receive the fee
    address public vault;

    // Mapping from ERC-1155 token address to ERC-20 token address which will be used as market fee
    mapping(address => MarketFee) public marketFeeTokens;
   
    // Mapping from ERC-1155 token address to ERC-20 token address which will be used as exchange fee
    mapping(address => ExchangeFee) public exchangeFeeTokens;

    // A mapping from item and seller to its listing information
    mapping(address => mapping(uint256 => mapping(address => ListingItem))) public itemsOnSale;

    // A mapping from item and buyer to its offering information
    mapping(address => mapping(uint256 => mapping(address => OfferingItem))) public itemsWithOffers;

    // A mapping from item and maker to its exchanging information
    mapping(address => mapping(uint256 => mapping(address => ExchangingItem))) public itemsForExchange;

    event ItemListed (
        address indexed itemContract,
        uint256 indexed itemId,
        address seller,
        address currency,
        uint256 price,
        uint256 amount
    );

    event ItemDelisted(
        address indexed itemContract,
        uint256 indexed itemId,
        address seller
    );

    event ItemBought(
        address indexed itemContract,
        uint256 indexed itemId,
        address buyer,
        address seller,
        address currency,
        uint256 price,
        uint256 amount
    );

    event ItemOffered (
        address indexed itemContract,
        uint256 indexed itemId,
        address buyer,
        address currency,
        uint256 price,
        uint256 amount
    );

    event ItemOfferCanceled (
        address indexed itemContract,
        uint256 indexed itemId,
        address buyer
    );

    event ItemOfferTaken (
        address indexed itemContract,
        uint256 indexed itemId,
        address buyer,
        address seller,
        address currency,
        uint256 price,
        uint256 amount
    );

    event ItemExchangeOffered (
        address indexed itemContract,
        uint256 indexed srcItemId,
        uint256[] destItemIds,
        uint256 amount,
        address maker
    );

    event ItemExchanged (
        address indexed itemContract,
        uint256 indexed srcItemId,
        uint256[] destItemIds,
        address maker,
        address taker,
        uint256 amount
    );

    event ItemExchangeCanceled (
        address indexed itemContract,
        uint256 indexed srcItemId,
        uint256[] destItemIds,
        address maker
    );
 
    /**
     * @notice Require that the market fee token exists
     */
    modifier tradingAllowed(address itemContract) {
        MarketFee memory fee = marketFeeTokens[itemContract];

        require(vault != address(0), "Market is not ready");
        require(
            fee.currency != address(0) && fee.percentage > 0 && fee.percentage < 100,
            "Invalid token to trade"
        );
        _;
    }
 
    /**
     * @notice Require that the exchange fee token exists
     */
    modifier exchangingAllowed(address itemContract) {
        ExchangeFee memory fee = exchangeFeeTokens[itemContract];

        require(vault != address(0), "Market is not ready");
        require(
            fee.currency != address(0) && fee.amount > 0, 
            "Invalid token to exchange"
        );
        _;
    }

    /*
     * Constructor
     */
    function __ERC1155Marketplace_init(address _vault) public initializer {
        __Ownable_init();
        vault = _vault;
    }

    // Setting
    function setVault(address _vault) external nonReentrant onlyOwner {
        vault = _vault;
    }

    function setMarketFee(address itemContract, address currency, uint256 percentage) external onlyOwner {
        require(percentage < 100, "Invalid percantage");

        marketFeeTokens[itemContract] = MarketFee({
            currency: currency,
            percentage: percentage
        });
    }

    function setExchangeFee(address itemContract, address currency, uint256 amount) external onlyOwner {
        exchangeFeeTokens[itemContract] = ExchangeFee({
            currency: currency,
            amount: amount
        });
    }

    // Listing
    function list(address itemContract, uint256 itemId, uint256 price, uint256 amount) external tradingAllowed(itemContract) nonReentrant {
        MarketFee memory fee = marketFeeTokens[itemContract];
        ListingItem storage currentListing = itemsOnSale[itemContract][itemId][msg.sender];
        
        require(price > 0, "Invalid price");
        require(
            IERC1155Upgradeable(itemContract).balanceOf(msg.sender, itemId) >= amount, 
            "Not enough balance"
        );

        IERC1155Upgradeable(itemContract).safeTransferFrom(msg.sender, address(this), itemId, amount, "");
        itemsOnSale[itemContract][itemId][msg.sender] = ListingItem({
            currency: fee.currency,
            price: price,
            amount: currentListing.amount + amount,
            feePercentage: fee.percentage
        });

        emit ItemListed(itemContract, itemId, msg.sender, fee.currency, price, currentListing.amount);
    }

    function delist(address itemContract, uint256 itemId) external nonReentrant {
        ListingItem storage currentListing = itemsOnSale[itemContract][itemId][msg.sender];

        require(
            currentListing.price > 0 && currentListing.amount > 0, 
            "Not listed"
        );

        IERC1155Upgradeable(itemContract).safeTransferFrom(address(this), msg.sender, itemId, currentListing.amount, "");
        delete itemsOnSale[itemContract][itemId][msg.sender];
        
        emit ItemDelisted(itemContract, itemId, msg.sender);
    }

    function buy(
        address itemContract,
        uint256 itemId, 
        address currency,
        uint256 price, 
        uint256 amount, 
        address seller
    ) external payable tradingAllowed(itemContract) nonReentrant {
        ListingItem storage currentListing = itemsOnSale[itemContract][itemId][seller];

        address buyer = msg.sender;
        require(buyer != seller, "Cannot buy your own item");
        require(currency == currentListing.currency, "Invalid currency");
        require(price > 0 && price == currentListing.price, "Invalid price");
        require(amount > 0 && amount <= currentListing.amount, "Invalid amount");
        
        uint256 cost = price * amount;
        _handleIncomingFund(cost, currency);
        
        uint256 fee = cost * currentListing.feePercentage / 100;
        _handleOutgoingFund(vault, fee, currency);

        uint256 sellerProfit = cost - fee;
        _handleOutgoingFund(seller, sellerProfit, currency);

        IERC1155Upgradeable(itemContract).safeTransferFrom(address(this), buyer, itemId, amount, "");
        currentListing.amount -= amount;

        emit ItemBought(itemContract, itemId, buyer, seller, currency, price, amount);
    }
    
    // Offering
    function offer(
        address itemContract,
        uint256 itemId, 
        uint256 price, 
        uint256 amount
    ) external payable tradingAllowed(itemContract) nonReentrant {
        MarketFee memory fee = marketFeeTokens[itemContract];
        
        require(price > 0, "Invalid price");

        address buyer = msg.sender;
        OfferingItem storage currentOffer = itemsWithOffers[itemContract][itemId][buyer];

        if (fee.currency != currentOffer.currency && currentOffer.amount > 0) {
            _handleOutgoingFund(buyer, currentOffer.price * currentOffer.amount, currentOffer.currency);
            currentOffer.amount = 0;
        }

        if (fee.currency == currentOffer.currency) {
            require(price != currentOffer.price || amount != currentOffer.amount, "Same offer");
        }

        uint256 currentCost = currentOffer.price * currentOffer.amount;
        uint256 newCost = price * amount;
        bool needRefund = newCost < currentCost;
        uint256 requiredValue = needRefund ? currentCost - newCost : newCost - currentCost;
        if (needRefund) {
            _handleOutgoingFund(buyer, requiredValue, currentOffer.currency);
        } else {
            _handleIncomingFund(requiredValue, fee.currency);
        }

        itemsWithOffers[itemContract][itemId][buyer] = OfferingItem({
            currency: fee.currency,
            price: price,
            amount: amount,
            feePercentage: fee.percentage
        });

        emit ItemOffered(itemContract, itemId, buyer, fee.currency, price, amount);
    }

    function cancelOffer(address itemContract, uint256 itemId) external nonReentrant {
        address buyer = msg.sender;
        OfferingItem storage currentOffer = itemsWithOffers[itemContract][itemId][buyer];

        require(currentOffer.amount > 0, "No offer found");

        _handleOutgoingFund(buyer, currentOffer.price * currentOffer.amount, currentOffer.currency);

        delete itemsWithOffers[itemContract][itemId][buyer];

        emit ItemOfferCanceled(itemContract, itemId, buyer);
    }

    function takeOffer(
        address itemContract,
        uint256 itemId, 
        address currency,
        uint256 price, 
        uint256 amount, 
        address buyer
    ) external tradingAllowed(itemContract) nonReentrant {
        OfferingItem storage currentOffer = itemsWithOffers[itemContract][itemId][buyer];

        address seller = msg.sender;

        require(currency == currentOffer.currency, "Invalid currency");
        require(price == currentOffer.price, "Invalid price");
        require(amount <= currentOffer.amount, "Invalid amount");
        require(buyer != seller, "Cannot buy your own items");

        uint256 totalAmount = price * amount;
        uint256 fee = totalAmount * currentOffer.feePercentage / 100;
        _handleOutgoingFund(vault, fee, currency);

        uint256 sellerProfit = totalAmount - fee;
        _handleOutgoingFund(seller, sellerProfit, currency);

        IERC1155Upgradeable(itemContract).safeTransferFrom(seller, buyer, itemId, amount, "");

        currentOffer.amount -= amount;

        emit ItemOfferTaken(itemContract, itemId, buyer, seller, currency, price, amount);
    }

    // Exchanging
    function offerExchange(
        address itemContract, 
        uint256 srcItemId, 
        uint256[] calldata destItemIds,
        uint256[] calldata destItemAmounts,
        uint256 amount
    ) external payable exchangingAllowed(itemContract) nonReentrant{
        address maker = msg.sender;

        ExchangeFee memory fee = exchangeFeeTokens[itemContract];
        ExchangingItem storage currentExchange = itemsForExchange[itemContract][srcItemId][maker];


        require(amount > 0, "Invalid amount");
        require(destItemIds.length > 0, "Invalid item ids for exchange");
        require(destItemIds.length == destItemAmounts.length, "Ids and amounts length mismatch");

        if (currentExchange.amount > 0) {
            require(destItemIds.length == currentExchange.destItemIds.length, "Already exchanging");
            for (uint256 i = 0; i < destItemIds.length; i++) {
                require(destItemIds[i] == currentExchange.destItemIds[i], "Already exchanging");
            }
        }

        _handleIncomingFund(fee.amount * amount, fee.currency);
        IERC1155Upgradeable(itemContract).safeTransferFrom(maker, address(this), srcItemId, amount, "");

        itemsForExchange[itemContract][srcItemId][maker] = ExchangingItem({
            srcItemId: srcItemId,
            destItemIds: destItemIds,
            destItemAmounts: destItemAmounts,
            amount: currentExchange.amount + amount,
            feeCurrency: fee.currency,
            feeAmount: fee.amount
        });

        emit ItemExchangeOffered(itemContract, srcItemId, destItemIds, currentExchange.amount, maker);
    }

    function cancelOfferExchange(address itemContract, uint256 srcItemId) external nonReentrant {
        address maker = msg.sender;

        ExchangingItem storage currentExchange = itemsForExchange[itemContract][srcItemId][maker];
        require(currentExchange.amount > 0, "No exchanging info found");
        _handleOutgoingFund(maker, currentExchange.feeAmount * currentExchange.amount, currentExchange.feeCurrency);
        IERC1155Upgradeable(itemContract).safeTransferFrom(address(this), maker, srcItemId, currentExchange.amount, "");

        delete itemsForExchange[itemContract][srcItemId][maker];

        emit ItemExchangeCanceled(itemContract, srcItemId, currentExchange.destItemIds, maker);
    }

    function takeExchangeOffer(
        address itemContract, 
        uint256 srcItemId, 
        uint256[] calldata destItemIds,
        uint256[] calldata destItemAmounts, 
        uint256 amount, 
        address maker
    ) external exchangingAllowed(itemContract) nonReentrant {
        address taker = msg.sender;

        ExchangingItem storage currentExchange = itemsForExchange[itemContract][srcItemId][maker];
        require(currentExchange.amount > 0, "No exchanging info found");
        require(amount > 0 && amount <= currentExchange.amount, "Invalid amount");
        require(destItemIds.length == destItemAmounts.length, "Ids and amounts length mismatch");

        require(destItemIds.length == currentExchange.destItemIds.length, "Exchanging info mismatch");
        for (uint256 i = 0; i < destItemIds.length; i++) {
            require(destItemIds[i] == currentExchange.destItemIds[i], "Exchanging ids info mismatch");
            require(destItemAmounts[i] == currentExchange.destItemAmounts[i], "Exchanging amounts info mismatch");
        }

        for (uint256 i = 0; i < amount; i++) {
            // Send dest items to maker
            IERC1155Upgradeable(itemContract).safeBatchTransferFrom(taker, maker, currentExchange.destItemIds, currentExchange.destItemAmounts, "");
            // Send src items to taker
            IERC1155Upgradeable(itemContract).safeTransferFrom(address(this), taker, srcItemId, amount, "");
            // Send fee to vault
            _handleOutgoingFund(vault, currentExchange.feeAmount, currentExchange.feeCurrency);

            currentExchange.amount -= 1;
        }
    
        emit ItemExchanged(itemContract, srcItemId, currentExchange.destItemIds, maker, taker, amount);
    }

    /**
     * @dev Given an amount and a currency, transfer the currency to this contract.
     */
    function _handleIncomingFund(uint256 amount, address currency) internal {
        // If this is an ETH fund, ensure they sent enough
        if(currency == address(0)) {
            require(msg.value == amount, "Sent ETH Value does not match specified amount");
        } else {
            // We must check the balance that was actually transferred to the auction,
            // as some tokens impose a transfer fee and would not actually transfer the
            // full amount to the market, resulting in potentally locked funds
            IERC20Upgradeable token = IERC20Upgradeable(currency);
            uint256 beforeBalance = token.balanceOf(address(this));
            token.safeTransferFrom(msg.sender, address(this), amount);
            uint256 afterBalance = token.balanceOf(address(this));
            require(beforeBalance + amount == afterBalance, "Token transfer call did not transfer expected amount");
        }
    }

    /**
     * @dev Given an amount and a currency, transfer the currency from this contract.
     */
    function _handleOutgoingFund(address to, uint256 amount, address currency) internal {
        // If the auction is in ETH, try to send it to the recipient.
        if(currency == address(0)) {
            (bool success, ) = to.call{value: amount}(new bytes(0));
            require(success, "Cannot transfer ETH");
        } else {
            IERC20Upgradeable(currency).safeTransfer(to, amount);
        }
    }

    receive() external payable {}
    fallback() external payable {}
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
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
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

import "./ERC1155ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155HolderUpgradeable is Initializable, ERC1155ReceiverUpgradeable {
    function __ERC1155Holder_init() internal initializer {
        __ERC165_init_unchained();
        __ERC1155Receiver_init_unchained();
        __ERC1155Holder_init_unchained();
    }

    function __ERC1155Holder_init_unchained() internal initializer {
    }
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
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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

import "../IERC1155ReceiverUpgradeable.sol";
import "../../../utils/introspection/ERC165Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155ReceiverUpgradeable is Initializable, ERC165Upgradeable, IERC1155ReceiverUpgradeable {
    function __ERC1155Receiver_init() internal initializer {
        __ERC165_init_unchained();
        __ERC1155Receiver_init_unchained();
    }

    function __ERC1155Receiver_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
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

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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