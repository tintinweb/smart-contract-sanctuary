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
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
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
import "../proxy/utils/Initializable.sol";

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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

interface ITransferProxy {
    function erc721SafeTransferFrom(
        address token,
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function erc1155SafeTransferFrom(
        address token,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';

import '../Proxys/Transfer/ITransferProxy.sol';
import '../Security/MessageSigning.sol';
import '../Tokens/ERC2981/IERC2981Royalties.sol';

contract BaseExchange is OwnableUpgradeable, MessageSigning {
    address payable public beneficiary;
    ITransferProxy public transferProxy;

    struct OrderTransfers {
        /* total order value */
        uint256 total;
        /* total value for seller (total - sellerServiceFees - royalties) */
        uint256 sellerEndValue;
        /* total transaction */
        uint256 totalTransaction;
        /* all service fees */
        uint256 serviceFees;
        /* royalties amount to transfer */
        uint256 royaltiesAmount;
        /* royalties recipient */
        address royaltiesRecipient;
    }

    function __BaseExchange_init(
        address payable _beneficiary,
        address _transferProxy
    ) internal initializer {
        __Ownable_init();

        setBeneficiary(_beneficiary);
        setTransferProxy(_transferProxy);
    }

    function setTransferProxy(address transferProxy_) public virtual onlyOwner {
        require(transferProxy_ != address(0));
        transferProxy = ITransferProxy(transferProxy_);
    }

    function setBeneficiary(address payable beneficiary_)
        public
        virtual
        onlyOwner
    {
        require(beneficiary_ != address(0));
        beneficiary = beneficiary_;
    }

    function _computeValues(
        uint256 unitPrice,
        address token,
        uint256 tokenId,
        uint256 amount,
        uint256 buyerServiceFee,
        uint256 sellerServiceFee
    ) internal view returns (OrderTransfers memory orderTransfers) {
        orderTransfers.total = unitPrice * amount;
        uint256 buyerFee = (orderTransfers.total * buyerServiceFee) / 10000;
        uint256 sellerFee = (orderTransfers.total * sellerServiceFee) / 10000;

        // total of transaction value (price + buyerFee)
        orderTransfers.totalTransaction = orderTransfers.total + buyerFee;
        // seller end value: price - sellerFee
        orderTransfers.sellerEndValue = orderTransfers.total - sellerFee;
        // all fees
        orderTransfers.serviceFees = sellerFee + buyerFee;

        (address royaltiesRecipient, uint256 royaltiesAmount) = _getRoyalties(
            token,
            tokenId,
            orderTransfers.total
        );

        // if there are royalties
        if (
            royaltiesAmount > 0 &&
            royaltiesAmount <= orderTransfers.sellerEndValue
        ) {
            orderTransfers.royaltiesRecipient = royaltiesRecipient;
            orderTransfers.royaltiesAmount = royaltiesAmount;
            // substract royalties to end value
            orderTransfers.sellerEndValue =
                orderTransfers.sellerEndValue -
                royaltiesAmount;
        }
    }

    function _getRoyalties(
        address token,
        uint256 tokenId,
        uint256 saleValue
    )
        internal
        view
        virtual
        returns (address royaltiesRecipient, uint256 royaltiesAmount)
    {
        IERC2981Royalties withRoyalties = IERC2981Royalties(token);
        if (
            withRoyalties.supportsInterface(type(IERC2981Royalties).interfaceId)
        ) {
            (royaltiesRecipient, royaltiesAmount) = withRoyalties.royaltyInfo(
                tokenId,
                saleValue
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';

import '../Proxys/Transfer/ITransferProxy.sol';

import './BaseExchange.sol';
import './ExchangeStorage.sol';

contract Exchange is BaseExchange, ReentrancyGuardUpgradeable, ExchangeStorage {
    function initialize(
        address payable beneficiary_,
        address transferProxy_,
        address exchangeSigner_
    ) public initializer {
        __BaseExchange_init(beneficiary_, transferProxy_);

        __ReentrancyGuard_init_unchained();

        setExchangeSigner(exchangeSigner_);
    }

    /// @dev Allows owner to set the address used to sign the sales Metadata
    /// @param exchangeSigner_ address of the signer
    function setExchangeSigner(address exchangeSigner_) public onlyOwner {
        require(exchangeSigner_ != address(0), 'Exchange signer must be valid');
        exchangeSigner = exchangeSigner_;
    }

    function prepareOrderMessage(OrderData memory order)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(order));
    }

    function prepareOrderMetaMessage(
        Signature memory orderSig,
        OrderMeta memory saleMeta
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(orderSig, saleMeta));
    }

    /**
     * @dev this function computes all the values that we need for the exchange.
     * this can be called off-chain before buying so all values can be computed easily
     *
     * It will also help when we introduce tokens for payment
     */
    function computeValues(
        OrderData memory order,
        uint256 amount,
        OrderMeta memory saleMeta
    ) public view returns (OrderTransfers memory orderTransfers) {
        return
            _computeValues(
                order.inAsset.quantity,
                order.outAsset.token,
                order.outAsset.tokenId,
                amount,
                saleMeta.buyerFee,
                saleMeta.sellerFee
            );
    }

    function buy(
        OrderData memory order,
        Signature memory sig,
        uint256 amount, // quantity to buy
        OrderMeta memory saleMeta,
        Signature memory saleMetaSignature
    ) external payable nonReentrant {
        // verify that order is for this contract
        require(order.exchange == address(this), 'Sale: Wrong exchange.');

        // verify if this order is for a specific address
        if (order.taker != address(0)) {
            require(msg.sender == order.taker, 'Sale: Wrong user.');
        }

        require(
            // amount must be > 0
            (amount > 0) &&
                // and amount must be <= at maxPerBuy
                (order.maxPerBuy == 0 || amount <= order.maxPerBuy),
            'Sale: Wrong amount.'
        );

        // verify exchange meta for buy
        _verifyOrderMeta(sig, saleMeta, saleMetaSignature);

        // verify order signature
        _validateOrderSig(order, sig);

        // update order state
        bool closed = _verifyOpenAndModifyState(order, amount);

        // transfer everything
        OrderTransfers memory orderTransfers = _doTransfers(
            order,
            amount,
            saleMeta
        );

        // emit buy
        emit Buy(
            order.orderNonce,
            order.outAsset.token,
            order.outAsset.tokenId,
            amount,
            order.maker,
            order.inAsset.token,
            order.inAsset.tokenId,
            order.inAsset.quantity,
            msg.sender,
            orderTransfers.total,
            orderTransfers.serviceFees
        );

        // if order is closed, emit close.
        if (closed) {
            emit CloseOrder(
                order.orderNonce,
                order.outAsset.token,
                order.outAsset.tokenId,
                order.maker
            );
        }
    }

    function cancelOrder(
        address token,
        uint256 tokenId,
        uint256 quantity,
        uint256 orderNonce
    ) public {
        bytes32 orderId = _getOrderId(
            token,
            tokenId,
            quantity,
            msg.sender,
            orderNonce
        );
        completed[orderId] = quantity;
        emit CloseOrder(orderNonce, token, tokenId, msg.sender);
    }

    function _validateOrderSig(OrderData memory order, Signature memory sig)
        public
        pure
    {
        require(
            recoverMessageSignature(prepareOrderMessage(order), sig) ==
                order.maker,
            'Sale: Incorrect order signature'
        );
    }

    // returns orderId for completion
    function _getOrderId(
        address token,
        uint256 tokenId,
        uint256 quantity,
        address maker,
        uint256 orderNonce
    ) internal pure returns (bytes32) {
        return
            keccak256(abi.encode(token, tokenId, quantity, maker, orderNonce));
    }

    function _verifyOpenAndModifyState(
        OrderData memory order,
        uint256 buyingAmount
    ) internal returns (bool) {
        bytes32 orderId = _getOrderId(
            order.outAsset.token,
            order.outAsset.tokenId,
            order.outAsset.quantity,
            order.maker,
            order.orderNonce
        );
        uint256 comp = completed[orderId] + buyingAmount;

        // makes sure order is not already closed
        require(
            comp <= order.outAsset.quantity,
            'Sale: Order already closed or quantity too high'
        );

        // update order completion amount
        completed[orderId] = comp;

        // returns if order is closed or not
        return comp == order.outAsset.quantity;
    }

    /// @dev This function verifies meta for an order
    ///      We use meta to have buyerFee and sellerFee per transaction instead of global
    ///      this also allows to not have open ended orders that could be reused months after it was made
    /// @param orderSig the signature of the order
    /// @param saleMeta the meta for this sale
    /// @param saleSig signature for this sale
    function _verifyOrderMeta(
        Signature memory orderSig,
        OrderMeta memory saleMeta,
        Signature memory saleSig
    ) internal {
        require(
            saleMeta.expiration == 0 || saleMeta.expiration >= block.timestamp,
            'Sale: Buy Order expired'
        );

        require(saleMeta.buyer == msg.sender, 'Sale Metadata not for operator');

        // verifies that saleSig is right
        bytes32 message = prepareOrderMetaMessage(orderSig, saleMeta);
        require(
            recoverMessageSignature(message, saleSig) == exchangeSigner,
            'Sale: Incorrect order meta signature'
        );

        require(usedSaleMeta[message] == false, 'Sale Metadata already used');

        usedSaleMeta[message] = true;
    }

    function _doTransfers(
        OrderData memory order,
        uint256 amount,
        OrderMeta memory saleMeta
    ) internal returns (OrderTransfers memory orderTransfers) {
        // get all values into a struct
        // it will help later when we introduce token payments
        orderTransfers = computeValues(order, amount, saleMeta);

        // this here is because we're not using tokens
        // verify that msg.value is right
        require(
            // total = (unitPrice * amount) + buyerFee
            msg.value == orderTransfers.totalTransaction,
            'Sale: Sent value is incorrect'
        );

        // transfer ethereum
        if (orderTransfers.totalTransaction > 0) {
            // send service fees (buyerFee + sellerFees) to beneficiary
            if (orderTransfers.serviceFees > 0) {
                beneficiary.transfer(orderTransfers.serviceFees);
            }

            if (orderTransfers.royaltiesAmount > 0) {
                payable(orderTransfers.royaltiesRecipient).transfer(
                    orderTransfers.royaltiesAmount
                );
            }

            // send what is left to seller
            if (orderTransfers.sellerEndValue > 0) {
                payable(order.maker).transfer(orderTransfers.sellerEndValue);
            }
        }

        // send token to buyer
        if (order.outAsset.tokenType == TokenType.ERC1155) {
            transferProxy.erc1155SafeTransferFrom(
                order.outAsset.token,
                order.maker,
                msg.sender,
                order.outAsset.tokenId,
                amount,
                ''
            );
        } else {
            transferProxy.erc721SafeTransferFrom(
                order.outAsset.token,
                order.maker,
                msg.sender,
                order.outAsset.tokenId,
                ''
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';

import '../Proxys/Transfer/ITransferProxy.sol';
import '../Tokens/ERC2981/IERC2981Royalties.sol';

contract ExchangeStorage {
    enum TokenType {
        ETH,
        ERC20,
        ERC1155,
        ERC721
    }

    event Buy(
        uint256 indexed orderNonce,
        address indexed token,
        uint256 indexed tokenId,
        uint256 amount,
        address maker,
        address buyToken,
        uint256 buyTokenId,
        uint256 buyAmount,
        address buyer,
        uint256 total,
        uint256 serviceFee
    );

    event CloseOrder(
        uint256 orderNonce,
        address indexed token,
        uint256 indexed tokenId,
        address maker
    );

    struct Asset {
        /* asset type, erc721 or erc1155 */
        TokenType tokenType;
        /* asset contract  */
        address token;
        /* asset id */
        uint256 tokenId;
        /* asset quantity */
        uint256 quantity;
    }

    struct OrderData {
        /* Exchange address - should be current contract */
        address exchange;
        /* maker of the order */
        address maker;
        /* taker of the order */
        address taker;
        /* out asset */
        Asset outAsset;
        /* in asset: this is the UNIT PRICE; which means amount bought must be multiplicated by quantity here */
        Asset inAsset;
        /* Max items by each buy. Allow to create one big order, but to limit how many can be bought at once */
        uint256 maxPerBuy;
        /* OrderNonce so we can have different order for the same tokenId */
        uint256 orderNonce;
        /* expiration date for this order - usually 1 month | 0 means never expires */
        uint256 expiration;
    }

    struct OrderMeta {
        /* buyer */
        address buyer;
        /* seller fee for the sale */
        uint256 sellerFee;
        /* buyer fee for the sale */
        uint256 buyerFee;
        /* expiration for this sale - usually 24h | 0 means never expires */
        uint256 expiration;
        /* Order Meta nonce so it can only be used once */
        uint256 nonce;
    }

    // signer used to sign "buys"
    // this allows to have buyer and sellerFee per tx and not global
    // this also allows to invalidate orders without needed them to be canceled
    // in the contract since a buy can't be done without being signed
    address public exchangeSigner;

    // To register saleMeta that were already used
    mapping(bytes32 => bool) public usedSaleMeta;

    // orderId => completed amount
    mapping(bytes32 => uint256) public completed;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract MessageSigning {
    /* An ECDSA signature. */
    struct Signature {
        /* v parameter */
        uint8 v;
        /* r parameter */
        bytes32 r;
        /* s parameter */
        bytes32 s;
    }

    /**
     * @dev verifies signature
     */
    function recoverMessageSignature(
        bytes32 message,
        Signature memory signature
    ) public pure returns (address) {
        uint8 v = signature.v;
        if (v < 27) {
            v += 27;
        }

        return
            ecrecover(
                keccak256(
                    abi.encodePacked(
                        '\x19Ethereum Signed Message:\n32',
                        message
                    )
                ),
                v,
                signature.r,
                signature.s
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol';

/**
 * Early implementation of EIP-2981 as of comment
 * https://github.com/ethereum/EIPs/issues/2907#issuecomment-831352868
 *
 * Interface ID:
 *
 * bytes4(keccak256('royaltyInfo(uint256,uint256,bytes)')) == 0xc155531d
 *
 * =>  0xc155531d
 */
interface IERC2981Royalties is IERC165Upgradeable {
    /**
     * @dev Returns an NFTs royalty payment information
     *
     * @param tokenId  The identifier for an NFT
     * @param value Purchase price of NFT
     *
     * @return receiver The royalty recipient address
     * @return royaltyAmount Amount to be paid to the royalty recipient
     */
    function royaltyInfo(uint256 tokenId, uint256 value)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

