/**
 *Submitted for verification at polygonscan.com on 2021-10-27
*/

// SPDX-License-Identifier: MIT

// File: solidity-bytes-utils/contracts/BytesLib.sol


/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.0 <0.9.0;


library BytesLib {
    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol



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

// File: WertTokenPayment.sol


pragma solidity ^0.8.3;



library LibOrder {
    using LibOrder for Order;

    // A valid order remains fillable until it is expired, fully filled, or cancelled.
    // An order's status is unaffected by external factors, like account balances.
    enum OrderStatus {
        INVALID,                     // Default value
        INVALID_MAKER_ASSET_AMOUNT,  // Order does not have a valid maker asset amount
        INVALID_TAKER_ASSET_AMOUNT,  // Order does not have a valid taker asset amount
        FILLABLE,                    // Order is fillable
        EXPIRED,                     // Order has already expired
        FULLY_FILLED,                // Order is fully filled
        CANCELLED                    // Order has been cancelled
    }

    // solhint-disable max-line-length
    struct Order {
        address payable makerAddress;           // Address that created the order.
        address payable takerAddress;           // Address that is allowed to fill the order. If set to 0, any address is allowed to fill the order.
        address payable feeRecipientAddress;    // Address that will recieve fees when order is filled.
        address senderAddress;          // Address that is allowed to call Exchange contract methods that affect this order. If set to 0, any address is allowed to call these methods.
        uint256 makerAssetAmount;       // Amount of makerAsset being offered by maker. Must be greater than 0.
        uint256 takerAssetAmount;       // Amount of takerAsset being bid on by maker. Must be greater than 0.
        uint256 makerFee;               // Fee paid to feeRecipient by maker when order is filled.
        uint256 takerFee;               // Fee paid to feeRecipient by taker when order is filled.
        uint256 expirationTimeSeconds;  // Timestamp in seconds at which order expires.
        uint256 salt;                   // Arbitrary number to facilitate uniqueness of the order's hash.
        bytes makerAssetData;           // Encoded data that can be decoded by a specified proxy contract when transferring makerAsset. The leading bytes4 references the id of the asset proxy.
        bytes takerAssetData;           // Encoded data that can be decoded by a specified proxy contract when transferring takerAsset. The leading bytes4 references the id of the asset proxy.
        bytes makerFeeAssetData;        // Encoded data that can be decoded by a specified proxy contract when transferring makerFeeAsset. The leading bytes4 references the id of the asset proxy.
        bytes takerFeeAssetData;        // Encoded data that can be decoded by a specified proxy contract when transferring takerFeeAsset. The leading bytes4 references the id of the asset proxy.
    }
    // solhint-enable max-line-length

    struct OrderInfo {
        uint8 orderStatus;                    // Status that describes order's validity and fillability.
        bytes32 orderHash;                    // EIP712 typed data hash of the order (see LibOrder.getTypedDataHash).
        uint256 orderTakerAssetFilledAmount;  // Amount of order that has already been filled.
    }
}

interface IExchange {
    /// @dev Gets information about an order: status, hash, and amount filled.
    /// @param order Order to gather information on.
    /// @return orderInfo Information about the order and its state.
    /// See LibOrder.OrderInfo for a complete description.
    function getOrderInfo(LibOrder.Order memory order)
        external
        view
        returns (LibOrder.OrderInfo memory orderInfo);
        
    /// @dev Verifies that a signature for an order is valid.
    /// @param order The order.
    /// @param signature Proof that the order has been signed by signer.
    /// @return isValid true if the signature is valid for the given order and signer.
    function isValidOrderSignature(
        LibOrder.Order memory order,
        bytes memory signature
    )
        external
        view
        returns (bool isValid);
}

interface IERC721 {
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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

contract WertTokenPayment is ReentrancyGuard {
    using BytesLib for bytes;
    
    // 0x protocol exchange contract address
    address constant private EXCHANGE_ADDRESS = 0x533Dc89624DCc012C7323B41F286bD2df478800B;
    // Wrapped Matic contract address
    address constant private WRAPPED_MATIC_ADDRESS = 0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889;
    
    function buyToken(
      LibOrder.Order memory order,
      bytes memory signature,
      address takerAddress
    ) public payable nonReentrant {
        // Check exchange tokens
        address takerTokenAddress = order.takerAssetData.toAddress(16);
        address takerFeeTokenAddress = order.takerFeeAssetData.toAddress(16);
        require(order.makerFeeAssetData.length == 0, "The maker token fee must be none");
        require(takerTokenAddress == WRAPPED_MATIC_ADDRESS, "The taker token must be Wrapped Matic");
        require(takerFeeTokenAddress == WRAPPED_MATIC_ADDRESS, "The taker token fee must be Wrapped Matic");
        // Validate order signature
        bool isValidOrderSignature = IExchange(EXCHANGE_ADDRESS).isValidOrderSignature(order, signature);
        require(isValidOrderSignature, "The order signature is not valid");
        // Check order status
        LibOrder.OrderInfo memory orderInfo = IExchange(EXCHANGE_ADDRESS).getOrderInfo(order);
        require(orderInfo.orderStatus == uint8(LibOrder.OrderStatus.FILLABLE), "The order status is not fillable");
        // Check payment price
        require(msg.value == (order.takerAssetAmount + order.takerFee), "The payment price is not equal to the order price");
        
        // Transfer token from maker to taker
        address makerTokenAddress = order.makerAssetData.toAddress(16);
        uint256 makerTokenId = order.makerAssetData.toUint256(36);
        IERC721(makerTokenAddress).safeTransferFrom(order.makerAddress, takerAddress, makerTokenId);
        // Transfer funds from taker to maker
        (bool makerSent,) = order.makerAddress.call{value: order.takerAssetAmount}("");
        require(makerSent, "Failed to transfer funds to maker");
        // Transfer funds from taker to fee recipient
        (bool feeRecipientSent,) = order.feeRecipientAddress.call{value: order.takerFee}("");
        require(feeRecipientSent, "Failed to transfer funds to fee recipient");
    }
}