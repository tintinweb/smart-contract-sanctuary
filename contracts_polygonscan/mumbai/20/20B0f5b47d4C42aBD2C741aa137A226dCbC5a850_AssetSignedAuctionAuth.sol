//SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "@openzeppelin/contracts-0.8/token/ERC20/IERC20.sol";
import "../common/Libraries/SigUtil.sol";
import "../common/Libraries/PriceUtil.sol";
import "../asset/AssetV2.sol";
import "../common/Base/TheSandbox712.sol";
import "../common/BaseWithStorage/MetaTransactionReceiver.sol";
import "../common/interfaces/ERC1271.sol";
import "../common/interfaces/ERC1271Constants.sol";
import "../common/interfaces/ERC1654.sol";
import "../common/interfaces/ERC1654Constants.sol";

contract AssetSignedAuctionAuth is ERC1654Constants, ERC1271Constants, TheSandbox712, MetaTransactionReceiver {
    struct ClaimSellerOfferRequest {
        address buyer;
        address payable seller;
        address token;
        uint256[] purchase;
        uint256[] auctionData;
        uint256[] ids;
        uint256[] amounts;
        bytes signature;
    }

    enum SignatureType {DIRECT, EIP1654, EIP1271}

    bytes32 public constant AUCTION_TYPEHASH =
        keccak256(
            "Auction(address from,address token,uint256 offerId,uint256 startingPrice,uint256 endingPrice,uint256 startedAt,uint256 duration,uint256 packs,bytes ids,bytes amounts)"
        );

    event OfferClaimed(
        address indexed seller,
        address indexed buyer,
        uint256 indexed offerId,
        uint256 amount,
        uint256 pricePaid,
        uint256 feePaid
    );
    event OfferCancelled(address indexed seller, uint256 indexed offerId);

    uint256 public constant MAX_UINT256 = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    // Stack too deep, grouping parameters
    // AuctionData:
    uint256 public constant AuctionData_OfferId = 0;
    uint256 public constant AuctionData_StartingPrice = 1;
    uint256 public constant AuctionData_EndingPrice = 2;
    uint256 public constant AuctionData_StartedAt = 3;
    uint256 public constant AuctionData_Duration = 4;
    uint256 public constant AuctionData_Packs = 5;

    mapping(address => mapping(uint256 => uint256)) public claimed;

    AssetV2 public _asset;
    uint256 public _fee10000th = 0;
    address payable public _feeCollector;

    event FeeSetup(address feeCollector, uint256 fee10000th);

    constructor(
        AssetV2 asset,
        address admin,
        address initialMetaTx,
        address payable feeCollector,
        uint256 fee10000th
    ) TheSandbox712() {
        _asset = asset;
        _feeCollector = feeCollector;
        _fee10000th = fee10000th;
        emit FeeSetup(feeCollector, fee10000th);
        _admin = admin;
        _setMetaTransactionProcessor(initialMetaTx, true);
    }

    /// @notice set fee parameters
    /// @param feeCollector address receiving the fee
    /// @param fee10000th fee in 10,000th
    function setFee(address payable feeCollector, uint256 fee10000th) external {
        require(msg.sender == _admin, "only admin can change fee");
        _feeCollector = feeCollector;
        _fee10000th = fee10000th;
        emit FeeSetup(feeCollector, fee10000th);
    }

    function _verifyParameters(
        address buyer,
        address payable seller,
        address token,
        uint256 buyAmount,
        uint256[] memory auctionData,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal view {
        require(ids.length == amounts.length, "ids and amounts length not matching");
        require(
            buyer == msg.sender || (token != address(0) && _metaTransactionContracts[msg.sender]),
            "not authorized"
        );
        uint256 amountAlreadyClaimed = claimed[seller][auctionData[AuctionData_OfferId]];
        require(amountAlreadyClaimed != MAX_UINT256, "Auction cancelled");

        uint256 total = amountAlreadyClaimed + buyAmount;
        require(total >= amountAlreadyClaimed, "overflow");
        require(total <= auctionData[AuctionData_Packs], "Buy amount exceeds sell amount");

        require(auctionData[AuctionData_StartedAt] <= block.timestamp, "Auction didn't start yet");
        require(
            auctionData[AuctionData_StartedAt] + auctionData[AuctionData_Duration] > block.timestamp,
            "Auction finished"
        );
    }

    /// @notice claim offer using EIP712
    /// @param input Claim Seller Offer Request
    function claimSellerOffer(ClaimSellerOfferRequest memory input) external payable {
        _verifyParameters(
            input.buyer,
            input.seller,
            input.token,
            input.purchase[0],
            input.auctionData,
            input.ids,
            input.amounts
        );
        _ensureCorrectSigner(
            input.seller,
            input.token,
            input.auctionData,
            input.ids,
            input.amounts,
            input.signature,
            SignatureType.DIRECT,
            true
        );
        _executeDeal(
            input.token,
            input.purchase,
            input.buyer,
            input.seller,
            input.auctionData,
            input.ids,
            input.amounts
        );
    }

    /// @notice claim offer using EIP712 and EIP1271 signature verification scheme
    /// @param input Claim Seller Offer Request
    function claimSellerOfferViaEIP1271(ClaimSellerOfferRequest memory input) external payable {
        _verifyParameters(
            input.buyer,
            input.seller,
            input.token,
            input.purchase[0],
            input.auctionData,
            input.ids,
            input.amounts
        );
        _ensureCorrectSigner(
            input.seller,
            input.token,
            input.auctionData,
            input.ids,
            input.amounts,
            input.signature,
            SignatureType.EIP1271,
            true
        );
        _executeDeal(
            input.token,
            input.purchase,
            input.buyer,
            input.seller,
            input.auctionData,
            input.ids,
            input.amounts
        );
    }

    /// @notice claim offer using EIP712 and EIP1654 signature verification scheme
    /// @param input Claim Seller Offer Request
    function claimSellerOfferViaEIP1654(ClaimSellerOfferRequest memory input) external payable {
        _verifyParameters(
            input.buyer,
            input.seller,
            input.token,
            input.purchase[0],
            input.auctionData,
            input.ids,
            input.amounts
        );
        _ensureCorrectSigner(
            input.seller,
            input.token,
            input.auctionData,
            input.ids,
            input.amounts,
            input.signature,
            SignatureType.EIP1654,
            true
        );
        _executeDeal(
            input.token,
            input.purchase,
            input.buyer,
            input.seller,
            input.auctionData,
            input.ids,
            input.amounts
        );
    }

    /// @notice claim offer using Basic Signature
    /// @param input Claim Seller Offer Request
    function claimSellerOfferUsingBasicSig(ClaimSellerOfferRequest memory input) external payable {
        _verifyParameters(
            input.buyer,
            input.seller,
            input.token,
            input.purchase[0],
            input.auctionData,
            input.ids,
            input.amounts
        );
        _ensureCorrectSigner(
            input.seller,
            input.token,
            input.auctionData,
            input.ids,
            input.amounts,
            input.signature,
            SignatureType.DIRECT,
            false
        );
        _executeDeal(
            input.token,
            input.purchase,
            input.buyer,
            input.seller,
            input.auctionData,
            input.ids,
            input.amounts
        );
    }

    /// @notice claim offer using Basic Signature and EIP1271 signature verification scheme
    /// @param input Claim Seller Offer Request
    function claimSellerOfferUsingBasicSigViaEIP1271(ClaimSellerOfferRequest memory input) external payable {
        _verifyParameters(
            input.buyer,
            input.seller,
            input.token,
            input.purchase[0],
            input.auctionData,
            input.ids,
            input.amounts
        );
        _ensureCorrectSigner(
            input.seller,
            input.token,
            input.auctionData,
            input.ids,
            input.amounts,
            input.signature,
            SignatureType.EIP1271,
            false
        );
        _executeDeal(
            input.token,
            input.purchase,
            input.buyer,
            input.seller,
            input.auctionData,
            input.ids,
            input.amounts
        );
    }

    /// @notice claim offer using Basic Signature and EIP1654 signature verification scheme
    /// @param input Claim Seller Offer Request
    function claimSellerOfferUsingBasicSigViaEIP1654(ClaimSellerOfferRequest memory input) external payable {
        _verifyParameters(
            input.buyer,
            input.seller,
            input.token,
            input.purchase[0],
            input.auctionData,
            input.ids,
            input.amounts
        );
        _ensureCorrectSigner(
            input.seller,
            input.token,
            input.auctionData,
            input.ids,
            input.amounts,
            input.signature,
            SignatureType.EIP1654,
            false
        );
        _executeDeal(
            input.token,
            input.purchase,
            input.buyer,
            input.seller,
            input.auctionData,
            input.ids,
            input.amounts
        );
    }

    function _executeDeal(
        address token,
        uint256[] memory purchase,
        address buyer,
        address payable seller,
        uint256[] memory auctionData,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal {
        uint256 offer =
            PriceUtil.calculateCurrentPrice(
                auctionData[AuctionData_StartingPrice],
                auctionData[AuctionData_EndingPrice],
                auctionData[AuctionData_Duration],
                block.timestamp - auctionData[AuctionData_StartedAt]
            ) * purchase[0];
        claimed[seller][auctionData[AuctionData_OfferId]] =
            claimed[seller][auctionData[AuctionData_OfferId]] +
            purchase[0];

        uint256 fee = 0;
        if (_fee10000th > 0) {
            fee = PriceUtil.calculateFee(offer, _fee10000th);
        }

        uint256 total = offer + fee;
        require(total <= purchase[1], "offer exceeds max amount to spend");

        if (token != address(0)) {
            require(IERC20(token).transferFrom(buyer, seller, offer), "failed to transfer token price");
            if (fee > 0) {
                require(IERC20(token).transferFrom(buyer, _feeCollector, fee), "failed to collect fee");
            }
        } else {
            require(msg.value >= total, "ETH < total");
            if (msg.value > total) {
                payable(msg.sender).transfer(msg.value - total);
            }
            seller.transfer(offer);
            if (fee > 0) {
                _feeCollector.transfer(fee);
            }
        }

        uint256[] memory packAmounts = new uint256[](amounts.length);
        for (uint256 i = 0; i < packAmounts.length; i++) {
            packAmounts[i] = amounts[i] * purchase[0];
        }
        _asset.safeBatchTransferFrom(seller, buyer, ids, packAmounts, "");
        emit OfferClaimed(seller, buyer, auctionData[AuctionData_OfferId], purchase[0], offer, fee);
    }

    /// @notice cancel a offer previously signed, new offer need to use a id not used yet
    /// @param offerId offer to cancel
    function cancelSellerOffer(uint256 offerId) external {
        claimed[msg.sender][offerId] = MAX_UINT256;
        emit OfferCancelled(msg.sender, offerId);
    }

    function _ensureCorrectSigner(
        address from,
        address token,
        uint256[] memory auctionData,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory signature,
        SignatureType signatureType,
        bool eip712
    ) internal view returns (address) {
        bytes memory dataToHash;
        address signer;

        if (eip712) {
            dataToHash = abi.encodePacked(
                "\x19\x01",
                _DOMAIN_SEPARATOR,
                _hashAuction(from, token, auctionData, ids, amounts)
            );
        } else {
            dataToHash = _encodeBasicSignatureHash(from, token, auctionData, ids, amounts);
        }

        if (signatureType == SignatureType.EIP1271) {
            require(
                ERC1271(from).isValidSignature(dataToHash, signature) == ERC1271_MAGICVALUE,
                "invalid 1271 signature"
            );
        } else if (signatureType == SignatureType.EIP1654) {
            require(
                ERC1654(from).isValidSignature(keccak256(dataToHash), signature) == ERC1654_MAGICVALUE,
                "invalid 1654 signature"
            );
        } else {
            signer = SigUtil.recover(keccak256(dataToHash), signature);
            require(signer == from, "signer != from");
        }

        return signer;
    }

    function _encodeBasicSignatureHash(
        address from,
        address token,
        uint256[] memory auctionData,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal view returns (bytes memory) {
        return
            SigUtil.prefixed(
                keccak256(
                    abi.encodePacked(
                        address(this),
                        AUCTION_TYPEHASH,
                        from,
                        token,
                        auctionData[AuctionData_OfferId],
                        auctionData[AuctionData_StartingPrice],
                        auctionData[AuctionData_EndingPrice],
                        auctionData[AuctionData_StartedAt],
                        auctionData[AuctionData_Duration],
                        auctionData[AuctionData_Packs],
                        keccak256(abi.encodePacked(ids)),
                        keccak256(abi.encodePacked(amounts))
                    )
                )
            );
    }

    function _hashAuction(
        address from,
        address token,
        uint256[] memory auctionData,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    AUCTION_TYPEHASH,
                    from,
                    token,
                    auctionData[AuctionData_OfferId],
                    auctionData[AuctionData_StartingPrice],
                    auctionData[AuctionData_EndingPrice],
                    auctionData[AuctionData_StartedAt],
                    auctionData[AuctionData_Duration],
                    auctionData[AuctionData_Packs],
                    keccak256(abi.encodePacked(ids)),
                    keccak256(abi.encodePacked(amounts))
                )
            );
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

pragma solidity 0.8.2;

library SigUtil {
    function recover(bytes32 hash, bytes memory sig) internal pure returns (address recovered) {
        require(sig.length == 65, "incorrect signature length");

        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }
        require(v == 27 || v == 28, "version of signature should be 27 or 28");

        recovered = ecrecover(hash, v, r, s);
        require(recovered != address(0), "incorrect address");
    }

    function recoverWithZeroOnFailure(bytes32 hash, bytes memory sig) internal pure returns (address) {
        if (sig.length != 65) {
            return (address(0));
        }

        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            return ecrecover(hash, v, r, s);
        }
    }

    // Builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 hash) internal pure returns (bytes memory) {
        return abi.encodePacked("\x19Ethereum Signed Message:\n32", hash);
    }
}

pragma solidity 0.8.2;

import "./SafeMathWithRequire.sol";
import "@openzeppelin/contracts-0.8/utils/math/SafeMath.sol";

library PriceUtil {
    using SafeMathWithRequire for uint256;
    using SafeMath for uint256;

    function calculateCurrentPrice(
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 duration,
        uint256 secondsPassed
    ) internal pure returns (uint256) {
        if (secondsPassed > duration) {
            return endingPrice;
        }
        if (endingPrice == startingPrice) {
            return endingPrice;
        } else if (endingPrice > startingPrice) {
            return startingPrice.add((endingPrice.sub(startingPrice)).mul(secondsPassed).div(duration));
        } else {
            return startingPrice.sub((startingPrice.sub(endingPrice)).mul(secondsPassed).div(duration));
        }
    }

    function calculateFee(uint256 price, uint256 fee10000th) internal pure returns (uint256) {
        // _fee < 10000, so the result will be <= price
        return (price.mul(fee10000th)) / 10000;
    }
}

//SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

import "./ERC1155ERC721.sol";
import "../common/interfaces/IAssetAttributesRegistry.sol";
import "./libraries/AssetHelper.sol";

// solhint-disable-next-line no-empty-blocks
contract AssetV2 is ERC1155ERC721 {
    AssetHelper.AssetRegistryData private assetRegistryData;

    /// @notice fulfills the purpose of a constructor in upgradeable contracts
    function initialize(
        address trustedForwarder,
        address admin,
        address bouncerAdmin,
        address predicate,
        uint8 chainIndex,
        address assetRegistry
    ) external {
        initV2(trustedForwarder, admin, bouncerAdmin, predicate, chainIndex);
        assetRegistryData.assetRegistry = IAssetAttributesRegistry(assetRegistry);
    }

    /// @notice called by predicate to mint tokens transferred from L2
    /// @param to address to mint to
    /// @param ids ids to mint
    /// @param amounts supply for each token type
    /// @param data extra data to accompany the minting call
    function mintBatch(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external {
        require(_msgSender() == _predicate, "!PREDICATE");
        bytes32[] memory hashes = AssetHelper.decodeAndSetCatalystDataL2toL1(assetRegistryData, data);
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 uriId = ids[i] & ERC1155ERC721Helper.URI_ID;
            _metadataHash[uriId] = hashes[i];
            _rarityPacks[uriId] = "0x00";
            uint16 numNFTs = 0;
            if ((ids[i] & ERC1155ERC721Helper.IS_NFT) > 0) {
                numNFTs = 1;
            }
            uint256[] memory singleId = new uint256[](1);
            singleId[0] = ids[i];
            uint256[] memory singleAmount = new uint256[](1);
            singleAmount[0] = amounts[i];
            _mintBatches(singleAmount, to, singleId, numNFTs);
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

contract TheSandbox712 {
    bytes32 internal constant EIP712DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,address verifyingContract)");
    // solhint-disable-next-line var-name-mixedcase
    bytes32 public immutable _DOMAIN_SEPARATOR;

    constructor() {
        _DOMAIN_SEPARATOR = keccak256(
            abi.encode(EIP712DOMAIN_TYPEHASH, keccak256("The Sandbox"), keccak256("1"), address(this))
        );
    }
}

pragma solidity 0.8.2;

import "./WithAdmin.sol";

contract MetaTransactionReceiver is WithAdmin {
    mapping(address => bool) internal _metaTransactionContracts;
    event MetaTransactionProcessor(address metaTransactionProcessor, bool enabled);

    /// @notice Enable or disable the ability of `metaTransactionProcessor` to perform meta-tx (metaTransactionProcessor rights).
    /// @param metaTransactionProcessor address that will be given/removed metaTransactionProcessor rights.
    /// @param enabled set whether the metaTransactionProcessor is enabled or disabled.
    function setMetaTransactionProcessor(address metaTransactionProcessor, bool enabled) public {
        require(msg.sender == _admin, "only admin can setup metaTransactionProcessors");
        _setMetaTransactionProcessor(metaTransactionProcessor, enabled);
    }

    function _setMetaTransactionProcessor(address metaTransactionProcessor, bool enabled) internal {
        _metaTransactionContracts[metaTransactionProcessor] = enabled;
        emit MetaTransactionProcessor(metaTransactionProcessor, enabled);
    }

    /// @notice check whether address `who` is given meta-transaction execution rights.
    /// @param who The address to query.
    /// @return whether the address has meta-transaction execution rights.
    function isMetaTransactionProcessor(address who) external view returns (bool) {
        return _metaTransactionContracts[who];
    }
}

pragma solidity 0.8.2;

interface ERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param data Arbitrary length data signed on the behalf of address(this)
     * @param signature Signature byte array associated with _data
     *
     * MUST return the bytes4 magic value 0x20c13b0b when function passes.
     * MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
     * MUST allow external calls
     */
    function isValidSignature(bytes memory data, bytes memory signature) external view returns (bytes4 magicValue);
}

pragma solidity 0.8.2;

contract ERC1271Constants {
    bytes4 internal constant ERC1271_MAGICVALUE = 0x20c13b0b;
}

pragma solidity 0.8.2;

interface ERC1654 {
    /**
     * @dev Should return whether the signature provided is valid for the provided hash
     * @param hash 32 bytes hash to be signed
     * @param signature Signature byte array associated with hash
     * @return magicValue - 0x1626ba7e if valid else 0x00000000
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

pragma solidity 0.8.2;

contract ERC1654Constants {
    bytes4 internal constant ERC1654_MAGICVALUE = 0x1626ba7e;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts-0.8/utils/math/SafeMath.sol";

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert
 */
library SafeMathWithRequire {
    using SafeMath for uint256;

    uint256 private constant DECIMALS_18 = 1000000000000000000;
    uint256 private constant DECIMALS_12 = 1000000000000;
    uint256 private constant DECIMALS_9 = 1000000000;
    uint256 private constant DECIMALS_6 = 1000000;

    function sqrt6(uint256 a) internal pure returns (uint256 c) {
        a = a.mul(DECIMALS_12);
        uint256 tmp = a.add(1) / 2;
        c = a;
        // tmp cannot be zero unless a = 0 which skip the loop
        while (tmp < c) {
            c = tmp;
            tmp = ((a / tmp) + tmp) / 2;
        }
    }

    function sqrt3(uint256 a) internal pure returns (uint256 c) {
        a = a.mul(DECIMALS_6);
        uint256 tmp = a.add(1) / 2;
        c = a;
        // tmp cannot be zero unless a = 0 which skip the loop
        while (tmp < c) {
            c = tmp;
            tmp = ((a / tmp) + tmp) / 2;
        }
    }

    function cbrt6(uint256 a) internal pure returns (uint256 c) {
        a = a.mul(DECIMALS_18);
        uint256 tmp = a.add(2) / 3;
        c = a;
        // tmp cannot be zero unless a = 0 which skip the loop
        while (tmp < c) {
            c = tmp;
            uint256 tmpSquare = tmp**2;
            require(tmpSquare > tmp, "overflow");
            tmp = ((a / tmpSquare) + (tmp * 2)) / 3;
        }
        return c;
    }

    function cbrt3(uint256 a) internal pure returns (uint256 c) {
        a = a.mul(DECIMALS_9);
        uint256 tmp = a.add(2) / 3;
        c = a;
        // tmp cannot be zero unless a = 0 which skip the loop
        while (tmp < c) {
            c = tmp;
            uint256 tmpSquare = tmp**2;
            require(tmpSquare > tmp, "overflow");
            tmp = ((a / tmpSquare) + (tmp * 2)) / 3;
        }
        return c;
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

//SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

import "@openzeppelin/contracts-0.8/utils/Address.sol";
import "../common/interfaces/IERC1155.sol";
import "../common/interfaces/IERC1155TokenReceiver.sol";
import "../common/Libraries/ObjectLib32.sol";
import "../common/interfaces/IERC721.sol";
import "../common/interfaces/IERC721TokenReceiver.sol";
import "../common/BaseWithStorage/WithSuperOperators.sol";
import "../common/BaseWithStorage/ERC2771Handler.sol";
import "./libraries/ERC1155ERC721Helper.sol";

// solhint-disable max-states-count

contract ERC1155ERC721 is WithSuperOperators, IERC1155, IERC721, ERC2771Handler {
    using Address for address;
    using ObjectLib32 for ObjectLib32.Operations;
    using ObjectLib32 for uint256;

    bytes4 private constant ERC1155_IS_RECEIVER = 0x4e2312e0;
    bytes4 private constant ERC1155_RECEIVED = 0xf23a6e61;
    bytes4 private constant ERC1155_BATCH_RECEIVED = 0xbc197c81;
    bytes4 private constant ERC721_RECEIVED = 0x150b7a02;

    mapping(address => uint256) private _numNFTPerAddress; // erc721
    mapping(uint256 => uint256) private _owners; // erc721
    mapping(address => mapping(uint256 => uint256)) private _packedTokenBalance; // erc1155
    mapping(address => mapping(address => bool)) private _operatorsForAll; // erc721 and erc1155
    mapping(uint256 => address) private _erc721operators; // erc721
    mapping(uint256 => bytes32) internal _metadataHash; // erc721 and erc1155
    mapping(uint256 => bytes) internal _rarityPacks; // rarity configuration per packs (2 bits per Asset)
    mapping(uint256 => uint32) private _nextCollectionIndex; // extraction

    mapping(address => address) private _creatorship; // creatorship transfer

    mapping(address => bool) private _bouncers; // the contracts allowed to mint
    // @note : Deprecated.
    mapping(address => bool) private _metaTransactionContracts;

    address private _bouncerAdmin;

    bool internal _init;

    bytes4 internal constant ERC165ID = 0x01ffc9a7;

    uint256 internal _initBits;
    address internal _predicate; // used in place of polygon's `PREDICATE_ROLE`

    uint8 internal _chainIndex; // modify this for l2
    uint256 private constant CHAIN_INDEX_OFFSET_MULTIPLIER = uint256(2)**(256 - 160 - 1 - 32);
    uint256 private constant CHAIN_INDEX_MASK = 0x00000000000000000000000000000000000000000000007F8000000000000000;

    uint256[20] private __gap;
    // solhint-enable max-states-count

    event BouncerAdminChanged(address oldBouncerAdmin, address newBouncerAdmin);
    event Bouncer(address bouncer, bool enabled);
    event MetaTransactionProcessor(address metaTransactionProcessor, bool enabled);
    event CreatorshipTransfer(address indexed original, address indexed from, address indexed to);
    event Extraction(uint256 indexed fromId, uint256 toId);
    event AssetUpdate(uint256 indexed fromId, uint256 toId);

    function initV2(
        address trustedForwarder,
        address admin,
        address bouncerAdmin,
        address predicate,
        uint8 chainIndex
    ) public {
        // one-time init of bitfield's previous versions
        _checkInit(0);
        _admin = admin;
        _bouncerAdmin = bouncerAdmin;
        _predicate = predicate;
        ERC2771Handler.__ERC2771Handler_initialize(trustedForwarder);
        _chainIndex = chainIndex;
    }

    /// @notice Change the minting administrator to be `newBouncerAdmin`.
    /// @param newBouncerAdmin address of the new minting administrator.
    function changeBouncerAdmin(address newBouncerAdmin) external {
        require(_msgSender() == _bouncerAdmin, "!BOUNCER_ADMIN");
        emit BouncerAdminChanged(_bouncerAdmin, newBouncerAdmin);
        _bouncerAdmin = newBouncerAdmin;
    }

    /// @notice Enable or disable the ability of `bouncer` to mint tokens (minting bouncer rights).
    /// @param bouncer address that will be given/removed minting bouncer rights.
    /// @param enabled set whether the address is enabled or disabled as a minting bouncer.
    function setBouncer(address bouncer, bool enabled) external {
        require(_msgSender() == _bouncerAdmin, "!BOUNCER_ADMIN");
        _bouncers[bouncer] = enabled;
        emit Bouncer(bouncer, enabled);
    }

    /// @notice Mint a token type for `creator` on slot `packId`.
    /// @param creator address of the creator of the token.
    /// @param packId unique packId for that token.
    /// @param hash hash of an IPFS cidv1 folder that contains the metadata of the token type in the file 0.json.
    /// @param supply number of tokens minted for that token type.
    /// @param rarity rarity power of the token.
    /// @param owner address that will receive the tokens.
    /// @param data extra data to accompany the minting call.
    /// @return id the id of the newly minted token type.
    function mint(
        address creator,
        uint40 packId,
        bytes32 hash,
        uint256 supply,
        uint8 rarity,
        address owner,
        bytes calldata data
    ) external returns (uint256 id) {
        require(hash != 0, "HASH==0");
        require(_bouncers[_msgSender()], "!BOUNCER");
        require(owner != address(0), "TO==0");
        id = _generateTokenId(creator, supply, packId, supply == 1 ? 0 : 1, 0);
        _mint(hash, supply, rarity, _msgSender(), owner, id, data, false);
    }

    /// @notice Mint multiple token types for `creator` on slot `packId`.
    /// @param creator address of the creator of the tokens.
    /// @param packId unique packId for the tokens.
    /// @param hash hash of an IPFS cidv1 folder that contains the metadata of each token type in the files: 0.json, 1.json, 2.json, etc...
    /// @param supplies number of tokens minted for each token type.
    /// @param rarityPack rarity power of each token types packed into 2 bits each.
    /// @param owner address that will receive the tokens.
    /// @param data extra data to accompany the minting call.
    /// @return ids the ids of each newly minted token types.
    function mintMultiple(
        address creator,
        uint40 packId,
        bytes32 hash,
        uint256[] calldata supplies,
        bytes calldata rarityPack,
        address owner,
        bytes calldata data
    ) external returns (uint256[] memory ids) {
        require(hash != 0, "HASH==0");
        require(_bouncers[_msgSender()], "!BOUNCER");
        require(owner != address(0), "TO==0");
        uint16 numNFTs;
        (ids, numNFTs) = _allocateIds(creator, supplies, rarityPack, packId, hash);
        _mintBatches(supplies, owner, ids, numNFTs);
        _completeMultiMint(_msgSender(), owner, ids, supplies, data);
    }

    /// @notice Transfers `value` tokens of type `id` from  `from` to `to`  (with safety call).
    /// @param from address from which tokens are transfered.
    /// @param to address to which the token will be transfered.
    /// @param id the token type transfered.
    /// @param value amount of token transfered.
    /// @param data aditional data accompanying the transfer.
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override {
        if (id & ERC1155ERC721Helper.IS_NFT > 0) {
            require(_ownerOf(id) == from, "OWNER!=FROM");
        }
        bool metaTx = _transferFrom(from, to, id, value);
        require(
            _checkERC1155AndCallSafeTransfer(metaTx ? from : msg.sender, from, to, id, value, data, false, false),
            "1155_TRANSFER_REJECTED"
        );
    }

    /// @notice Transfers `values` tokens of type `ids` from  `from` to `to` (with safety call).
    /// @dev call data should be optimized to order ids so packedBalance can be used efficiently.
    /// @param from address from which tokens are transfered.
    /// @param to address to which the token will be transfered.
    /// @param ids ids of each token type transfered.
    /// @param values amount of each token type transfered.
    /// @param data aditional data accompanying the transfer.
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override {
        // @review should we also check the length of data.URIs[] if we use something like that?
        // not sure if we want to try to set/update all URIs at once(both for newly-minted tokens & unlock tokens? Or do we rely on a second TX to update URIs for tokens that were locked in the predicate and may have new metaData from L2 to be set?)
        // metadataHash updates only applicable to erc721 tokens
        require(ids.length == values.length, "MISMATCHED_ARR_LEN");
        require(to != address(0), "TO==0");
        require(from != address(0), "FROM==0");
        bool metaTx = isTrustedForwarder(msg.sender);
        bool authorized = from == _msgSender() || isApprovedForAll(from, _msgSender());

        _batchTransferFrom(from, to, ids, values, authorized);
        emit TransferBatch(metaTx ? from : _msgSender(), from, to, ids, values);
        require(
            _checkERC1155AndCallSafeBatchTransfer(metaTx ? from : _msgSender(), from, to, ids, values, data),
            "1155_TRANSFER_REJECTED"
        );
    }

    /// @notice Transfers creatorship of `original` from `sender` to `to`.
    /// @param sender address of current registered creator.
    /// @param original address of the original creator whose creation are saved in the ids themselves.
    /// @param to address which will be given creatorship for all tokens originally minted by `original`.
    function transferCreatorship(
        address sender,
        address original,
        address to
    ) external {
        require(sender == _msgSender() || _superOperators[_msgSender()], "!AUTHORIZED");
        require(sender != address(0), "SENDER==0");
        require(to != address(0), "TO==0");
        address current = _creatorship[original];
        if (current == address(0)) {
            current = original;
        }
        require(current != to, "CURRENT==TO");
        require(current == sender, "CURRENT!=SENDER");
        if (to == original) {
            _creatorship[original] = address(0);
        } else {
            _creatorship[original] = to;
        }
        emit CreatorshipTransfer(original, current, to);
    }

    /// @notice Enable or disable approval for `operator` to manage all `sender`'s tokens.
    /// @dev used for Meta Transaction (from metaTransactionContract).
    /// @param sender address which grant approval.
    /// @param operator address which will be granted rights to transfer all token owned by `sender`.
    /// @param approved whether to approve or revoke.
    function setApprovalForAllFor(
        address sender,
        address operator,
        bool approved
    ) external {
        require(sender == _msgSender() || _superOperators[_msgSender()], "!AUTHORIZED");
        _setApprovalForAll(sender, operator, approved);
    }

    /// @notice Enable or disable approval for `operator` to manage all of the caller's tokens.
    /// @param operator address which will be granted rights to transfer all tokens of the caller.
    /// @param approved whether to approve or revoke
    function setApprovalForAll(address operator, bool approved) external override(IERC1155, IERC721) {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /// @notice Change or reaffirm the approved address for an NFT.
    /// @param operator the address to approve as NFT controller.
    /// @param id the id of the NFT to approve.
    function approve(address operator, uint256 id) external override {
        require(_ownerOf(id) != address(0), "NFT_!EXIST");
        require(_ownerOf(id) == _msgSender() || isApprovedForAll(_ownerOf(id), _msgSender()), "!AUTHORIZED");
        _erc721operators[id] = operator;
        emit Approval(_ownerOf(id), operator, id);
    }

    /// @notice Transfers ownership of an NFT.
    /// @param from the current owner of the NFT.
    /// @param to the new owner.
    /// @param id the NFT to transfer.
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) external override {
        require(_ownerOf(id) == from, "OWNER!=FROM");
        bool metaTx = _transferFrom(from, to, id, 1);
        require(
            _checkERC1155AndCallSafeTransfer(metaTx ? from : _msgSender(), from, to, id, 1, "", true, false),
            "1155_TRANSFER_REJECTED"
        );
    }

    /// @notice Transfers the ownership of an NFT from one address to another address.
    /// @param from the current owner of the NFT.
    /// @param to the new owner.
    /// @param id the NFT to transfer.
    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) external override {
        safeTransferFrom(from, to, id, "");
    }

    /// @notice Burns `amount` tokens of type `id` from `from`.
    /// @param from address whose token is to be burnt.
    /// @param id token type which will be burnt.
    /// @param amount amount of token to burn.
    function burnFrom(
        address from,
        uint256 id,
        uint256 amount
    ) external {
        require(from == _msgSender() || isApprovedForAll(from, _msgSender()), "!AUTHORIZED");
        _burn(from, id, amount);
    }

    /// @notice Upgrades an NFT with new metadata and rarity.
    /// @param from address which own the NFT to be upgraded.
    /// @param id the NFT that will be burnt to be upgraded.
    /// @param packId unqiue packId for the token.
    /// @param hash hash of an IPFS cidv1 folder that contains the metadata of the new token type in the file 0.json.
    /// @param newRarity rarity power of the new NFT.
    /// @param to address which will receive the NFT.
    /// @param data bytes to be transmitted as part of the minted token.
    /// @return the id of the newly minted NFT.
    function updateERC721(
        address from,
        uint256 id,
        uint40 packId,
        bytes32 hash,
        uint8 newRarity,
        address to,
        bytes calldata data
    ) external returns (uint256) {
        require(hash != 0, "HASH==0");
        require(_bouncers[_msgSender()], "!BOUNCER");
        require(to != address(0), "TO==0");
        require(from != address(0), "FROM==0");

        _burnERC721(_msgSender(), from, id);

        uint256 newId = _generateTokenId(from, 1, packId, 0, 0);
        _mint(hash, 1, newRarity, _msgSender(), to, newId, data, false);
        emit AssetUpdate(id, newId);
        return newId;
    }

    /// @notice Extracts an EIP-721 NFT from an EIP-1155 token.
    /// @param sender address which own the token to be extracted.
    /// @param id the token type to extract from.
    /// @param to address which will receive the token.
    /// @return newId the id of the newly minted NFT.
    function extractERC721From(
        address sender,
        uint256 id,
        address to
    ) external returns (uint256 newId) {
        bool metaTx = isTrustedForwarder(msg.sender);
        require(sender == _msgSender() || isApprovedForAll(sender, _msgSender()), "!AUTHORIZED");
        return _extractERC721From(metaTx ? sender : _msgSender(), sender, id, to);
    }

    /// @notice Returns the current administrator in charge of minting rights.
    /// @return the current minting administrator in charge of minting rights.
    function getBouncerAdmin() external view returns (address) {
        return _bouncerAdmin;
    }

    /// @notice check whether address `who` is given minting bouncer rights.
    /// @param who The address to query.
    /// @return whether the address has minting rights.
    function isBouncer(address who) external view returns (bool) {
        return _bouncers[who];
    }

    /// @notice Get the balance of `owners` for each token type `ids`.
    /// @param owners the addresses of the token holders queried.
    /// @param ids ids of each token type to query.
    /// @return the balance of each `owners` for each token type `ids`.
    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        external
        view
        override
        returns (uint256[] memory)
    {
        require(owners.length == ids.length, "ARG_LENGTH_MISMATCH");
        uint256[] memory balances = new uint256[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            balances[i] = balanceOf(owners[i], ids[i]);
        }
        return balances;
    }

    /// @notice Get the creator of the token type `id`.
    /// @param id the id of the token to get the creator of.
    /// @return the creator of the token type `id`.
    function creatorOf(uint256 id) external view returns (address) {
        require(wasEverMinted(id), "TOKEN_!MINTED");
        address newCreator = _creatorship[address(uint160(id / ERC1155ERC721Helper.CREATOR_OFFSET_MULTIPLIER))];
        if (newCreator != address(0)) {
            return newCreator;
        }
        return address(uint160(id / ERC1155ERC721Helper.CREATOR_OFFSET_MULTIPLIER));
    }

    /// @notice Count all NFTs assigned to `owner`.
    /// @param owner address for whom to query the balance.
    /// @return balance the number of NFTs owned by `owner`, possibly zero.
    function balanceOf(address owner) external view override returns (uint256 balance) {
        require(owner != address(0), "OWNER==0");
        return _numNFTPerAddress[owner];
    }

    /// @notice Find the owner of an NFT.
    /// @param id the identifier for an NFT.
    /// @return owner the address of the owner of the NFT.
    function ownerOf(uint256 id) external view override returns (address owner) {
        owner = _ownerOf(id);
        require(owner != address(0), "NFT_!EXIST");
    }

    /// @notice Get the approved address for a single NFT.
    /// @param id the NFT to find the approved address for.
    /// @return operator the approved address for this NFT, or the zero address if there is none.
    function getApproved(uint256 id) external view override returns (address operator) {
        require(_ownerOf(id) != address(0), "NFT_!EXIST");
        return _erc721operators[id];
    }

    /// @notice check whether a packId/numFT tupple has been used
    /// @param creator for which creator
    /// @param packId the packId to check
    /// @param numFTs number of Fungible Token in that pack (can reuse packId if different)
    /// @return whether the pack has already been used
    function isPackIdUsed(
        address creator,
        uint40 packId,
        uint16 numFTs
    ) external view returns (bool) {
        return
            _metadataHash[
                uint256(uint160(creator)) *
                    ERC1155ERC721Helper.CREATOR_OFFSET_MULTIPLIER + // CREATOR
                    uint256(packId) *
                    ERC1155ERC721Helper.PACK_ID_OFFSET_MULTIPLIER + // packId (unique pack) // ERC1155ERC721Helper.URI_ID
                    numFTs *
                    ERC1155ERC721Helper.PACK_NUM_FT_TYPES_OFFSET_MULTIPLIER
            ] != 0;
    }

    /// @notice A descriptive name for the collection of tokens in this contract.
    /// @return _name the name of the tokens.
    function name() external pure returns (string memory _name) {
        return "Sandbox's ASSETs";
    }

    /// @notice An abbreviated name for the collection of tokens in this contract.
    /// @return _symbol the symbol of the tokens.
    function symbol() external pure returns (string memory _symbol) {
        return "ASSET";
    }

    /// @notice Query if a contract implements interface `id`.
    /// @param id the interface identifier, as specified in ERC-165.
    /// @return `true` if the contract implements `id`.
    function supportsInterface(bytes4 id) external pure override returns (bool) {
        return
            id == 0x01ffc9a7 || //ERC165
            id == 0xd9b67a26 || // ERC1155
            id == 0x80ac58cd || // ERC721
            id == 0x5b5e139f || // ERC721 metadata
            id == 0x0e89341c; // ERC1155 metadata
    }

    /// @notice Transfers the ownership of an NFT from one address to another address.
    /// @param from the current owner of the NFT.
    /// @param to the new owner.
    /// @param id the NFT to transfer.
    /// @param data additional data with no specified format, sent in call to `to`.
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public override {
        require(_ownerOf(id) == from, "OWNER!=FROM");
        bool metaTx = _transferFrom(from, to, id, 1);
        require(
            _checkERC1155AndCallSafeTransfer(metaTx ? from : _msgSender(), from, to, id, 1, data, true, true),
            "721/1155_TRANSFER_REJECTED"
        );
    }

    /// @notice Gives the collection a specific token belongs to.
    /// @param id the token to get the collection of.
    /// @return the collection the NFT is part of.
    function collectionOf(uint256 id) public view returns (uint256) {
        require(_ownerOf(id) != address(0), "NFT_!EXIST");
        uint256 collectionId = id & ERC1155ERC721Helper.NOT_NFT_INDEX & ERC1155ERC721Helper.NOT_IS_NFT;
        require(wasEverMinted(collectionId), "UNMINTED_COLLECTION");
        return collectionId;
    }

    /// @notice Return wether the id is a collection
    /// @param id collectionId to check.
    /// @return whether the id is a collection.
    function isCollection(uint256 id) public view returns (bool) {
        uint256 collectionId = id & ERC1155ERC721Helper.NOT_NFT_INDEX & ERC1155ERC721Helper.NOT_IS_NFT;
        return wasEverMinted(collectionId);
    }

    /// @notice Gives the index at which an NFT was minted in a collection : first of a collection get the zero index.
    /// @param id the token to get the index of.
    /// @return the index/order at which the token `id` was minted in a collection.
    function collectionIndexOf(uint256 id) public view returns (uint256) {
        collectionOf(id); // this check if id and collection indeed was ever minted
        return uint32((id & ERC1155ERC721Helper.NFT_INDEX) >> ERC1155ERC721Helper.NFT_INDEX_OFFSET);
    }

    function wasEverMinted(uint256 id) public view returns (bool) {
        if ((id & ERC1155ERC721Helper.IS_NFT) > 0) {
            return _owners[id] != 0;
        } else {
            return
                ((id & ERC1155ERC721Helper.PACK_INDEX) <
                    ((id & ERC1155ERC721Helper.PACK_NUM_FT_TYPES) /
                        ERC1155ERC721Helper.PACK_NUM_FT_TYPES_OFFSET_MULTIPLIER)) &&
                _metadataHash[id & ERC1155ERC721Helper.URI_ID] != 0;
        }
    }

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// This supports both erc721 & erc1155 tokens.
    /// @param id token to get the uri of.
    /// @return URI string
    function tokenURI(uint256 id) public view returns (string memory) {
        require(_ownerOf(id) != address(0) || wasEverMinted(id), "NFT_!EXIST_||_FT_!MINTED");
        return ERC1155ERC721Helper.toFullURI(_metadataHash[id & ERC1155ERC721Helper.URI_ID], id);
    }

    /// @notice Get the balance of `owner` for the token type `id`.
    /// @param owner The address of the token holder.
    /// @param id the token type of which to get the balance of.
    /// @return the balance of `owner` for the token type `id`.
    function balanceOf(address owner, uint256 id) public view override returns (uint256) {
        // do not check for existence, balance is zero if never minted
        // require(wasEverMinted(id), "token was never minted");
        if (id & ERC1155ERC721Helper.IS_NFT > 0) {
            if (_ownerOf(id) == owner) {
                return 1;
            } else {
                return 0;
            }
        }
        (uint256 bin, uint256 index) = id.getTokenBinIndex();
        return _packedTokenBalance[owner][bin].getValueInBin(index);
    }

    /// @notice Queries the approval status of `operator` for owner `owner`.
    /// @param owner the owner of the tokens.
    /// @param operator address of authorized operator.
    /// @return isOperator true if the operator is approved, false if not.
    function isApprovedForAll(address owner, address operator)
        public
        view
        override(IERC1155, IERC721)
        returns (bool isOperator)
    {
        require(owner != address(0), "OWNER==0");
        require(operator != address(0), "OPERATOR==0");
        return _operatorsForAll[owner][operator] || _superOperators[operator];
    }

    function _setApprovalForAll(
        address sender,
        address operator,
        bool approved
    ) internal {
        require(sender != address(0), "SENDER==0");
        require(sender != operator, "SENDER==OPERATOR");
        require(operator != address(0), "OPERATOR==0");
        require(!_superOperators[operator], "APPR_EXISTING_SUPEROPERATOR");
        _operatorsForAll[sender][operator] = approved;
        emit ApprovalForAll(sender, operator, approved);
    }

    /* solhint-disable code-complexity */
    function _batchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bool authorized
    ) internal {
        uint256 numItems = ids.length;
        uint256 bin;
        uint256 index;
        uint256 balFrom;
        uint256 balTo;

        uint256 lastBin;
        uint256 numNFTs = 0;
        for (uint256 i = 0; i < numItems; i++) {
            if (ids[i] & ERC1155ERC721Helper.IS_NFT > 0) {
                require(authorized || _erc721operators[ids[i]] == _msgSender(), "OPERATOR_!AUTH");
                if (values[i] > 0) {
                    require(values[i] == 1, "NFT!=1");
                    require(_ownerOf(ids[i]) == from, "OWNER!=FROM");
                    numNFTs++;
                    _owners[ids[i]] = uint256(uint160(to));
                    if (_erc721operators[ids[i]] != address(0)) {
                        // TODO operatorEnabled flag optimization (like in ERC721BaseToken)
                        _erc721operators[ids[i]] = address(0);
                    }
                    emit Transfer(from, to, ids[i]);
                }
            } else {
                require(authorized, "OPERATOR_!AUTH");
                if (from == to) {
                    _checkEnoughBalance(from, ids[i], values[i]);
                } else if (values[i] > 0) {
                    (bin, index) = ids[i].getTokenBinIndex();
                    if (lastBin == 0) {
                        lastBin = bin;
                        balFrom = ObjectLib32.updateTokenBalance(
                            _packedTokenBalance[from][bin],
                            index,
                            values[i],
                            ObjectLib32.Operations.SUB
                        );
                        balTo = ObjectLib32.updateTokenBalance(
                            _packedTokenBalance[to][bin],
                            index,
                            values[i],
                            ObjectLib32.Operations.ADD
                        );
                    } else {
                        if (bin != lastBin) {
                            _packedTokenBalance[from][lastBin] = balFrom;
                            _packedTokenBalance[to][lastBin] = balTo;
                            balFrom = _packedTokenBalance[from][bin];
                            balTo = _packedTokenBalance[to][bin];
                            lastBin = bin;
                        }

                        balFrom = balFrom.updateTokenBalance(index, values[i], ObjectLib32.Operations.SUB);
                        balTo = balTo.updateTokenBalance(index, values[i], ObjectLib32.Operations.ADD);
                    }
                }
            }
        }
        if (numNFTs > 0 && from != to) {
            _numNFTPerAddress[from] -= numNFTs;
            _numNFTPerAddress[to] += numNFTs;
        }

        if (bin != 0 && from != to) {
            _packedTokenBalance[from][bin] = balFrom;
            _packedTokenBalance[to][bin] = balTo;
        }
    }

    /* solhint-enable code-complexity */

    function _checkERC1155AndCallSafeTransfer(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes memory data,
        bool erc721,
        bool erc721Safe
    ) internal returns (bool) {
        if (!to.isContract()) {
            return true;
        }
        if (erc721) {
            if (!_checkIsERC1155Receiver(to)) {
                if (erc721Safe) {
                    return _checkERC721AndCallSafeTransfer(operator, from, to, id, data);
                } else {
                    return true;
                }
            }
        }
        return IERC1155TokenReceiver(to).onERC1155Received(operator, from, id, value, data) == ERC1155_RECEIVED;
    }

    function _checkERC1155AndCallSafeBatchTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) internal returns (bool) {
        if (!to.isContract()) {
            return true;
        }
        bytes4 retval = IERC1155TokenReceiver(to).onERC1155BatchReceived(operator, from, ids, values, data);
        return (retval == ERC1155_BATCH_RECEIVED);
    }

    function _checkERC721AndCallSafeTransfer(
        address operator,
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) internal returns (bool) {
        // following not required as this function is always called as part of ERC1155 checks that include such check already
        // if (!to.isContract()) {
        //     return true;
        // }
        return (IERC721TokenReceiver(to).onERC721Received(operator, from, id, data) == ERC721_RECEIVED);
    }

    function _burnERC1155(
        address operator,
        address from,
        uint256 id,
        uint32 amount
    ) internal {
        (uint256 bin, uint256 index) = (id).getTokenBinIndex();
        _packedTokenBalance[from][bin] = _packedTokenBalance[from][bin].updateTokenBalance(
            index,
            amount,
            ObjectLib32.Operations.SUB
        );
        emit TransferSingle(operator, from, address(0), id, amount);
    }

    function _burnERC721(
        address operator,
        address from,
        uint256 id
    ) internal {
        require(from == _ownerOf(id), "OWNER!=FROM");
        _owners[id] = 2**160; // equivalent to zero address when casted but ensure we track minted status
        _numNFTPerAddress[from]--;
        emit Transfer(from, address(0), id);
        emit TransferSingle(operator, from, address(0), id, 1);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal {
        address sender = _msgSender();
        if ((id & ERC1155ERC721Helper.IS_NFT) > 0) {
            require(amount == 1, "AMOUNT!=1");
            _burnERC721(isTrustedForwarder(msg.sender) ? from : sender, from, id);
        } else {
            require(amount > 0 && amount <= ERC1155ERC721Helper.MAX_SUPPLY, "INVALID_AMOUNT");
            _burnERC1155(isTrustedForwarder(msg.sender) ? from : sender, from, id, uint32(amount));
        }
    }

    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal {
        address operator = isTrustedForwarder(msg.sender) ? from : _msgSender();
        for (uint256 i = 0; i < ids.length; i++) {
            if ((ids[i] & ERC1155ERC721Helper.IS_NFT) > 0) {
                require(amounts[i] == 1, "amounts[i]!=1");
                require(from == _ownerOf(ids[i]), "OWNER!=FROM");
                _owners[ids[i]] = 2**160; // equivalent to zero address when casted but ensure we track minted status
                _numNFTPerAddress[from]--;
                emit Transfer(from, address(0), ids[i]);
            } else {
                require(amounts[i] > 0 && amounts[i] <= ERC1155ERC721Helper.MAX_SUPPLY, "INVALID_AMOUNT");
                (uint256 bin, uint256 index) = (ids[i]).getTokenBinIndex();
                _packedTokenBalance[from][bin] = _packedTokenBalance[from][bin].updateTokenBalance(
                    index,
                    amounts[i],
                    ObjectLib32.Operations.SUB
                );
            }
        }
        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    function _allocateIds(
        address creator,
        uint256[] memory supplies,
        bytes memory rarityPack,
        uint40 packId,
        bytes32 hash
    ) internal returns (uint256[] memory ids, uint16 numNFTs) {
        require(supplies.length > 0, "SUPPLIES<=0");
        require(supplies.length <= ERC1155ERC721Helper.MAX_PACK_SIZE, "BATCH_TOO_BIG");
        (ids, numNFTs) = _generateTokenIds(creator, supplies, packId);

        require(uint256(_metadataHash[ids[0] & ERC1155ERC721Helper.URI_ID]) == 0, "ID_TAKEN");
        _metadataHash[ids[0] & ERC1155ERC721Helper.URI_ID] = hash;
        _rarityPacks[ids[0] & ERC1155ERC721Helper.URI_ID] = rarityPack;
    }

    function _completeMultiMint(
        address operator,
        address owner,
        uint256[] memory ids,
        uint256[] memory supplies,
        bytes memory data
    ) internal {
        emit TransferBatch(operator, address(0), owner, ids, supplies);
        require(
            _checkERC1155AndCallSafeBatchTransfer(operator, address(0), owner, ids, supplies, data),
            "TRANSFER_REJECTED"
        );
    }

    function _mintBatches(
        uint256[] memory supplies,
        address owner,
        uint256[] memory ids,
        uint16 numNFTs
    ) internal {
        uint16 offset = 0;
        while (offset < supplies.length - numNFTs) {
            _mintBatch(offset, supplies, owner, ids);
            offset += 8;
        }
        // deal with NFT last. they do not care of balance packing
        if (numNFTs > 0) {
            _mintNFTs(uint16(supplies.length - numNFTs), numNFTs, owner, ids);
        }
    }

    function _mintNFTs(
        uint16 offset,
        uint16 numNFTs,
        address owner,
        uint256[] memory ids
    ) internal {
        for (uint256 i = 0; i < numNFTs; i++) {
            uint256 id = ids[i + offset];
            _owners[id] = uint256(uint160(owner));
            emit Transfer(address(0), owner, id);
        }
        _numNFTPerAddress[owner] += numNFTs;
    }

    function _mintBatch(
        uint16 offset,
        uint256[] memory supplies,
        address owner,
        uint256[] memory ids
    ) internal {
        (uint256 bin, uint256 index) = ids[offset].getTokenBinIndex();
        for (uint256 i = 0; i < 8 && offset + i < supplies.length; i++) {
            uint256 j = offset + i;
            if (supplies[j] > 1) {
                _packedTokenBalance[owner][bin] = _packedTokenBalance[owner][bin].updateTokenBalance(
                    index + i,
                    supplies[j],
                    ObjectLib32.Operations.ADD
                );
            } else {
                break;
            }
        }
    }

    function _transferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value
    ) internal returns (bool metaTx) {
        require(to != address(0), "TO==0");
        require(from != address(0), "FROM==0");
        address sender = _msgSender();
        metaTx = isTrustedForwarder(msg.sender);
        bool authorized = from == sender || isApprovedForAll(from, sender);

        if (id & ERC1155ERC721Helper.IS_NFT > 0) {
            require(authorized || _erc721operators[id] == sender, "OPERATOR_!AUTH");
            if (value > 0) {
                require(value == 1, "NFT!=1");
                _numNFTPerAddress[from]--;
                _numNFTPerAddress[to]++;
                _owners[id] = uint256(uint160(to));
                if (_erc721operators[id] != address(0)) {
                    _erc721operators[id] = address(0);
                }
                emit Transfer(from, to, id);
            }
        } else {
            require(authorized, "OPERATOR_!AUTH");
            if (value > 0) {
                // if different owners it will fails
                (uint256 bin, uint256 index) = id.getTokenBinIndex();
                _packedTokenBalance[from][bin] = _packedTokenBalance[from][bin].updateTokenBalance(
                    index,
                    value,
                    ObjectLib32.Operations.SUB
                );
                _packedTokenBalance[to][bin] = _packedTokenBalance[to][bin].updateTokenBalance(
                    index,
                    value,
                    ObjectLib32.Operations.ADD
                );
            }
        }

        emit TransferSingle(metaTx ? from : sender, from, to, id, value);
    }

    function _extractERC721From(
        address operator,
        address sender,
        uint256 id,
        address to
    ) internal returns (uint256 newId) {
        require(to != address(0), "TO==0");
        require(id & ERC1155ERC721Helper.IS_NFT == 0, "!1155");
        uint32 tokenCollectionIndex = _nextCollectionIndex[id];
        newId = id + ERC1155ERC721Helper.IS_NFT + (tokenCollectionIndex) * 2**ERC1155ERC721Helper.NFT_INDEX_OFFSET;
        _nextCollectionIndex[id] = tokenCollectionIndex + 1;
        _burnERC1155(operator, sender, id, 1);
        _mint(_metadataHash[id & ERC1155ERC721Helper.URI_ID], 1, 0, operator, to, newId, "", true);
        emit Extraction(id, newId);
    }

    function _mint(
        bytes32 hash,
        uint256 supply,
        uint8 rarity,
        address operator,
        address owner,
        uint256 id,
        bytes memory data,
        bool extraction
    ) internal {
        uint256 uriId = id & ERC1155ERC721Helper.URI_ID;
        if (!extraction) {
            require(uint256(_metadataHash[uriId]) == 0, "ID_TAKEN");
            _metadataHash[uriId] = hash;
            require(rarity < 4, "RARITY>=4");
            bytes memory pack = new bytes(1);
            pack[0] = bytes1(rarity * 64);
            _rarityPacks[uriId] = pack;
        }
        if (supply == 1) {
            // ERC721
            _numNFTPerAddress[owner]++;
            _owners[id] = uint256(uint160(owner));
            emit Transfer(address(0), owner, id);
        } else {
            (uint256 bin, uint256 index) = id.getTokenBinIndex();
            _packedTokenBalance[owner][bin] = _packedTokenBalance[owner][bin].updateTokenBalance(
                index,
                supply,
                ObjectLib32.Operations.REPLACE
            );
        }

        emit TransferSingle(operator, address(0), owner, id, supply);
        require(
            _checkERC1155AndCallSafeTransfer(operator, address(0), owner, id, supply, data, false, false),
            "TRANSFER_REJECTED"
        );
    }

    /// @dev Allows the use of a bitfield to track the initialized status of the version `v` passed in as an arg.
    /// If the bit at the index corresponding to the given version is already set, revert.
    /// Otherwise, set the bit and return.
    /// @param v The version of this contract.
    function _checkInit(uint256 v) internal {
        require((_initBits >> v) & uint256(1) != 1, "ALREADY_INITIALISED");
        _initBits = _initBits | (uint256(1) << v);
    }

    function _checkIsERC1155Receiver(address _contract) internal view returns (bool) {
        bool success;
        bool result;
        bytes memory callData = abi.encodeWithSelector(ERC165ID, ERC1155_IS_RECEIVER);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let call_ptr := add(0x20, callData)
            let call_size := mload(callData)
            let output := mload(0x40) // Find empty storage location using "free memory pointer"
            mstore(output, 0x0)
            success := staticcall(10000, _contract, call_ptr, call_size, output, 0x20) // 32 bytes
            result := mload(output)
        }
        // (10000 / 63) "not enough for supportsInterface(...)" // consume all gas, so caller can potentially know that there was not enough gas
        assert(gasleft() > 158);
        return success && result;
    }

    function _checkEnoughBalance(
        address from,
        uint256 id,
        uint256 value
    ) internal view {
        (uint256 bin, uint256 index) = id.getTokenBinIndex();
        require(_packedTokenBalance[from][bin].getValueInBin(index) >= value, "BALANCE_TOO_LOW");
    }

    function _ownerOf(uint256 id) internal view returns (address) {
        return address(uint160(_owners[id]));
    }

    function _generateTokenId(
        address creator,
        uint256 supply,
        uint40 packId,
        uint16 numFTs,
        uint16 packIndex
    ) internal view returns (uint256) {
        require(supply > 0 && supply <= ERC1155ERC721Helper.MAX_SUPPLY, "SUPPLY_OUT_OF_BOUNDS");
        return
            uint256(uint160(creator)) *
            ERC1155ERC721Helper.CREATOR_OFFSET_MULTIPLIER + // CREATOR
            (supply == 1 ? uint256(1) * ERC1155ERC721Helper.IS_NFT_OFFSET_MULTIPLIER : 0) + // minted as NFT(1)|FT(0) // ERC1155ERC721Helper.IS_NFT
            uint256(_chainIndex) *
            CHAIN_INDEX_OFFSET_MULTIPLIER + // mainnet = 0, polygon = 1
            uint256(packId) *
            ERC1155ERC721Helper.PACK_ID_OFFSET_MULTIPLIER + // packId (unique pack) // ERC1155ERC721Helper.URI_ID
            numFTs *
            ERC1155ERC721Helper.PACK_NUM_FT_TYPES_OFFSET_MULTIPLIER + // number of fungible token in the pack // ERC1155ERC721Helper.URI_ID
            packIndex; // packIndex (position in the pack) // PACK_INDEX
    }

    function _generateTokenIds(
        address creator,
        uint256[] memory supplies,
        uint40 packId
    ) internal view returns (uint256[] memory, uint16) {
        uint16 numTokenTypes = uint16(supplies.length);
        uint256[] memory ids = new uint256[](numTokenTypes);
        uint16 numNFTs = 0;
        for (uint16 i = 0; i < numTokenTypes; i++) {
            if (numNFTs == 0) {
                if (supplies[i] == 1) {
                    numNFTs = uint16(numTokenTypes - i);
                }
            } else {
                require(supplies[i] == 1, "NFTS_MUST_BE_LAST");
            }
        }
        uint16 numFTs = numTokenTypes - numNFTs;
        for (uint16 i = 0; i < numTokenTypes; i++) {
            ids[i] = _generateTokenId(creator, supplies[i], packId, numFTs, i);
        }
        return (ids, numNFTs);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;
pragma experimental ABIEncoderV2;

interface IAssetAttributesRegistry {
    struct GemEvent {
        uint16[] gemIds;
        bytes32 blockHash;
    }

    struct AssetGemsCatalystData {
        uint256 assetId;
        uint16 catalystContractId;
        uint16[] gemContractIds;
    }

    function getRecord(uint256 assetId)
        external
        view
        returns (
            bool exists,
            uint16 catalystId,
            uint16[] memory gemIds
        );

    function getAttributes(uint256 assetId, GemEvent[] calldata events) external view returns (uint32[] memory values);

    function setCatalyst(
        uint256 assetId,
        uint16 catalystId,
        uint16[] calldata gemIds
    ) external;

    function setCatalystWhenDepositOnOtherLayer(
        uint256 assetId,
        uint16 catalystId,
        uint16[] calldata gemIds
    ) external;

    function setCatalystWithBlockNumber(
        uint256 assetId,
        uint16 catalystId,
        uint16[] calldata gemIds,
        uint64 blockNumber
    ) external;

    function addGems(uint256 assetId, uint16[] calldata gemIds) external;

    function setMigrationContract(address _migrationContract) external;

    function getCatalystRegistry() external view returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "../../common/interfaces/IAssetAttributesRegistry.sol";

// used to reduce PolygonAssetV2 contract code size
library AssetHelper {
    struct AssetRegistryData {
        IAssetAttributesRegistry assetRegistry;
    }

    function setCatalystDatas(
        AssetRegistryData storage self,
        IAssetAttributesRegistry.AssetGemsCatalystData[] memory assetGemsCatalystData
    ) public {
        for (uint256 i = 0; i < assetGemsCatalystData.length; i++) {
            require(assetGemsCatalystData[i].catalystContractId > 0, "WRONG_catalystContractId");
            require(assetGemsCatalystData[i].assetId != 0, "WRONG_assetId");
            self.assetRegistry.setCatalystWhenDepositOnOtherLayer(
                assetGemsCatalystData[i].assetId,
                assetGemsCatalystData[i].catalystContractId,
                assetGemsCatalystData[i].gemContractIds
            );
        }
    }

    function decodeAndSetCatalystDataL1toL2(AssetRegistryData storage self, bytes calldata depositData)
        public
        returns (
            uint256[] memory ids,
            uint256[] memory amounts,
            bytes32[] memory hashes
        )
    {
        bytes memory data;
        IAssetAttributesRegistry.AssetGemsCatalystData[] memory catalystDatas;
        (ids, amounts, data) = abi.decode(depositData, (uint256[], uint256[], bytes));
        (hashes, catalystDatas) = abi.decode(data, (bytes32[], IAssetAttributesRegistry.AssetGemsCatalystData[]));

        setCatalystDatas(self, catalystDatas);
    }

    function decodeAndSetCatalystDataL2toL1(AssetRegistryData storage self, bytes calldata data)
        public
        returns (bytes32[] memory hashes)
    {
        IAssetAttributesRegistry.AssetGemsCatalystData[] memory catalystDatas;

        (hashes, catalystDatas) = abi.decode(data, (bytes32[], IAssetAttributesRegistry.AssetGemsCatalystData[]));

        setCatalystDatas(self, catalystDatas);
    }

    function getGemsAndCatalystData(AssetRegistryData storage self, uint256[] calldata assetIds)
        public
        view
        returns (IAssetAttributesRegistry.AssetGemsCatalystData[] memory)
    {
        uint256 count = getGemsCatalystDataCount(self, assetIds);
        uint256 indexInCatalystArray;

        IAssetAttributesRegistry.AssetGemsCatalystData[] memory gemsCatalystDatas =
            new IAssetAttributesRegistry.AssetGemsCatalystData[](count);

        for (uint256 i = 0; i < assetIds.length; i++) {
            (bool isDataFound, uint16 catalystId, uint16[] memory gemIds) = self.assetRegistry.getRecord(assetIds[i]);
            if (isDataFound) {
                IAssetAttributesRegistry.AssetGemsCatalystData memory data;
                data.assetId = assetIds[i];
                data.catalystContractId = catalystId;
                data.gemContractIds = gemIds;
                require(indexInCatalystArray < count, "indexInCatalystArray out of bound");
                gemsCatalystDatas[indexInCatalystArray] = data;
                indexInCatalystArray++;
            }
        }

        return gemsCatalystDatas;
    }

    function getGemsCatalystDataCount(AssetRegistryData storage self, uint256[] calldata assetIds)
        internal
        view
        returns (uint256)
    {
        uint256 count;

        for (uint256 i = 0; i < assetIds.length; i++) {
            (bool isDataFound, , ) = self.assetRegistry.getRecord(assetIds[i]);
            if (isDataFound) {
                count++;
            }
        }
        return count;
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

//SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

/**
    @title ERC-1155 Multi Token Standard
    @dev See https://eips.ethereum.org/EIPS/eip-1155
    Note: The ERC-165 identifier for this interface is 0xd9b67a26.
 */
interface IERC1155 {
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /**
        @notice Transfers `value` amount of an `id` from  `from` to `to`  (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `from` account (see "Approval" section of the standard).
        MUST revert if `to` is the zero address.
        MUST revert if balance of holder for token `id` is lower than the `value` sent.
        MUST revert on any other error.
        MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
        After the above conditions are met, this function MUST check if `to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param from    Source address
        @param to      Target address
        @param id      ID of the token type
        @param value   Transfer amount
        @param data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `to`
    */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external;

    /**
        @notice Transfers `values` amount(s) of `ids` from the `from` address to the `to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `from` account (see "Approval" section of the standard).
        MUST revert if `to` is the zero address.
        MUST revert if length of `ids` is not the same as length of `values`.
        MUST revert if any of the balance(s) of the holder(s) for token(s) in `ids` is lower than the respective amount(s) in `values` sent to the recipient.
        MUST revert on any other error.
        MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
        Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
        After the above conditions for the transfer(s) in the batch are met, this function MUST check if `to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param from    Source address
        @param to      Target address
        @param ids     IDs of each token type (order and length must match _values array)
        @param values  Transfer amounts per token type (order and length must match _ids array)
        @param data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `to`
    */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external;

    /**
        @notice Get the balance of an account's tokens.
        @param owner  The address of the token holder
        @param id     ID of the token
        @return        The _owner's balance of the token type requested
     */
    function balanceOf(address owner, uint256 id) external view returns (uint256);

    /**
        @notice Get the balance of multiple account/token pairs
        @param owners The addresses of the token holders
        @param ids    ID of the tokens
        @return        The _owner's balance of the token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
        @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
        @dev MUST emit the ApprovalForAll event on success.
        @param operator  Address to add to the set of authorized operators
        @param approved  True if the operator is approved, false to revoke approval
    */
    function setApprovalForAll(address operator, bool approved) external;

    /**
        @notice Queries the approval status of an operator for a given owner.
        @param owner     The owner of the tokens
        @param operator  Address of authorized operator
        @return           True if the operator is approved, false if not
    */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

//SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

/**
    Note: The ERC-165 identifier for this interface is 0x4e2312e0.
*/
interface IERC1155TokenReceiver {
    /**
        @notice Handle the receipt of a single ERC1155 token type.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated.
        This function MUST return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` (i.e. 0xf23a6e61) if it accepts the transfer.
        This function MUST revert if it rejects the transfer.
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param operator  The address which initiated the transfer (i.e. msg.sender)
        @param from      The address which previously owned the token
        @param id        The ID of the token being transferred
        @param value     The amount of tokens being transferred
        @param data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @notice Handle the receipt of multiple ERC1155 token types.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated.
        This function MUST return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` (i.e. 0xbc197c81) if it accepts the transfer(s).
        This function MUST revert if it rejects the transfer(s).
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param operator  The address which initiated the batch transfer (i.e. msg.sender)
        @param from      The address which previously owned the token
        @param ids       An array containing ids of each token being transferred (order and length must match _values array)
        @param values    An array containing amounts of each token being transferred (order and length must match _ids array)
        @param data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

//SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

library ObjectLib32 {
    enum Operations {ADD, SUB, REPLACE}
    // Constants regarding bin or chunk sizes for balance packing
    uint256 internal constant TYPES_BITS_SIZE = 32; // Max size of each object
    uint256 internal constant TYPES_PER_UINT256 = 256 / TYPES_BITS_SIZE; // Number of types per uint256

    //
    // Objects and Tokens Functions
    //

    /// @dev Return the bin number and index within that bin where ID is
    /// @param tokenId Object type
    /// @return bin Bin number.
    /// @return index ID's index within that bin.
    function getTokenBinIndex(uint256 tokenId) internal pure returns (uint256 bin, uint256 index) {
        unchecked {bin = (tokenId * TYPES_BITS_SIZE) / 256;}
        index = tokenId % TYPES_PER_UINT256;
        return (bin, index);
    }

    /**
     * @dev update the balance of a type provided in binBalances
     * @param binBalances Uint256 containing the balances of objects
     * @param index Index of the object in the provided bin
     * @param amount Value to update the type balance
     * @param operation Which operation to conduct :
     *     Operations.REPLACE : Replace type balance with amount
     *     Operations.ADD     : ADD amount to type balance
     *     Operations.SUB     : Substract amount from type balance
     */
    function updateTokenBalance(
        uint256 binBalances,
        uint256 index,
        uint256 amount,
        Operations operation
    ) internal pure returns (uint256 newBinBalance) {
        uint256 objectBalance = 0;
        if (operation == Operations.ADD) {
            objectBalance = getValueInBin(binBalances, index);
            newBinBalance = writeValueInBin(binBalances, index, objectBalance + amount);
        } else if (operation == Operations.SUB) {
            objectBalance = getValueInBin(binBalances, index);
            require(objectBalance >= amount, "can't substract more than there is");
            newBinBalance = writeValueInBin(binBalances, index, objectBalance - amount);
        } else if (operation == Operations.REPLACE) {
            newBinBalance = writeValueInBin(binBalances, index, amount);
        } else {
            revert("Invalid operation"); // Bad operation
        }

        return newBinBalance;
    }

    /*
     * @dev return value in binValue at position index
     * @param binValue uint256 containing the balances of TYPES_PER_UINT256 types
     * @param index index at which to retrieve value
     * @return Value at given index in bin
     */
    function getValueInBin(uint256 binValue, uint256 index) internal pure returns (uint256) {
        // Mask to retrieve data for a given binData
        uint256 mask = (uint256(1) << TYPES_BITS_SIZE) - 1;

        // Shift amount
        uint256 rightShift = 256 - TYPES_BITS_SIZE * (index + 1);
        return (binValue >> rightShift) & mask;
    }

    /**
     * @dev return the updated binValue after writing amount at index
     * @param binValue uint256 containing the balances of TYPES_PER_UINT256 types
     * @param index Index at which to retrieve value
     * @param amount Value to store at index in bin
     * @return Value at given index in bin
     */
    function writeValueInBin(
        uint256 binValue,
        uint256 index,
        uint256 amount
    ) internal pure returns (uint256) {
        require(amount < 2**TYPES_BITS_SIZE, "Amount to write in bin is too large");

        // Mask to retrieve data for a given binData
        uint256 mask = (uint256(1) << TYPES_BITS_SIZE) - 1;

        // Shift amount
        uint256 leftShift = 256 - TYPES_BITS_SIZE * (index + 1);
        return (binValue & ~(mask << leftShift)) | (amount << leftShift);
    }
}

//SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

import "./IERC165.sol";
import "./IERC721Events.sol";

/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
/*interface*/
interface IERC721 is IERC165, IERC721Events {
    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    //   function exists(uint256 tokenId) external view returns (bool exists);

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

//SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 *
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */

interface IERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

//SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

import "./WithAdmin.sol";

contract WithSuperOperators is WithAdmin {
    mapping(address => bool) internal _superOperators;

    event SuperOperator(address superOperator, bool enabled);

    /// @notice Enable or disable the ability of `superOperator` to transfer tokens of all (superOperator rights).
    /// @param superOperator address that will be given/removed superOperator right.
    /// @param enabled set whether the superOperator is enabled or disabled.
    function setSuperOperator(address superOperator, bool enabled) external {
        require(msg.sender == _admin, "only admin is allowed to add super operators");
        _superOperators[superOperator] = enabled;
        emit SuperOperator(superOperator, enabled);
    }

    /// @notice check whether address `who` is given superOperator rights.
    /// @param who The address to query.
    /// @return whether the address has superOperator rights.
    function isSuperOperator(address who) public view returns (bool) {
        return _superOperators[who];
    }
}

// SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/// @dev minimal ERC2771 handler to keep bytecode-size down.
/// based on: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/metatx/ERC2771Context.sol

contract ERC2771Handler {
    address internal _trustedForwarder;

    function __ERC2771Handler_initialize(address forwarder) internal {
        _trustedForwarder = forwarder;
    }

    function isTrustedForwarder(address forwarder) public view returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function getTrustedForwarder() external view returns (address trustedForwarder) {
        return _trustedForwarder;
    }

    function _msgSender() internal view virtual returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return msg.sender;
        }
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

library ERC1155ERC721Helper {
    bytes32 private constant base32Alphabet = 0x6162636465666768696A6B6C6D6E6F707172737475767778797A323334353637;

    uint256 public constant CREATOR_OFFSET_MULTIPLIER = uint256(2)**(256 - 160);
    uint256 public constant IS_NFT_OFFSET_MULTIPLIER = uint256(2)**(256 - 160 - 1);
    uint256 public constant PACK_ID_OFFSET_MULTIPLIER = uint256(2)**(256 - 160 - 1 - 32 - 40);
    uint256 public constant PACK_NUM_FT_TYPES_OFFSET_MULTIPLIER = uint256(2)**(256 - 160 - 1 - 32 - 40 - 12);
    uint256 public constant NFT_INDEX_OFFSET = 63;

    uint256 public constant IS_NFT = 0x0000000000000000000000000000000000000000800000000000000000000000;
    uint256 public constant NOT_IS_NFT = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7FFFFFFFFFFFFFFFFFFFFFFF;
    uint256 public constant NFT_INDEX = 0x00000000000000000000000000000000000000007FFFFFFF8000000000000000;
    uint256 public constant NOT_NFT_INDEX = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF800000007FFFFFFFFFFFFFFF;
    uint256 public constant URI_ID = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000007FFFFFFFFFFFF800;
    uint256 public constant PACK_ID = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000007FFFFFFFFF800000;
    uint256 public constant PACK_INDEX = 0x00000000000000000000000000000000000000000000000000000000000007FF;
    uint256 public constant PACK_NUM_FT_TYPES = 0x00000000000000000000000000000000000000000000000000000000007FF800;

    uint256 public constant MAX_SUPPLY = uint256(2)**32 - 1;
    uint256 public constant MAX_PACK_SIZE = uint256(2)**11;

    function toFullURI(bytes32 hash, uint256 id) public pure returns (string memory) {
        return string(abi.encodePacked("ipfs://bafybei", hash2base32(hash), "/", uint2str(id & PACK_INDEX), ".json"));
    }

    // solium-disable-next-line security/no-assign-params
    function hash2base32(bytes32 hash) public pure returns (string memory _uintAsString) {
        uint256 _i = uint256(hash);
        uint256 k = 52;
        bytes memory bstr = new bytes(k);
        bstr[--k] = base32Alphabet[uint8((_i % 8) << 2)]; // uint8 s = uint8((256 - skip) % 5);  // (_i % (2**s)) << (5-s)
        _i /= 8;
        while (k > 0) {
            bstr[--k] = base32Alphabet[_i % 32];
            _i /= 32;
        }
        return string(bstr);
    }

    // solium-disable-next-line security/no-assign-params
    function uint2str(uint256 _i) public pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }

        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }

        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            bstr[--k] = bytes1(uint8(48 + uint8(_i % 10)));
            _i /= 10;
        }

        return string(bstr);
    }
}

//SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

/**
 * @title ERC165
 * @dev https://eips.ethereum.org/EIPS/eip-165
 */
interface IERC165 {
    /**
     * @notice Query if a contract implements interface `interfaceId`
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @dev Interface identification is specified in ERC-165. This function
     * uses less than 30,000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

//SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Events {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    // Duplicate event, ERC1155 ApprovalForAll
    // event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
}

//SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

contract WithAdmin {
    address internal _admin;

    /// @dev Emits when the contract administrator is changed.
    /// @param oldAdmin The address of the previous administrator.
    /// @param newAdmin The address of the new administrator.
    event AdminChanged(address oldAdmin, address newAdmin);

    modifier onlyAdmin() {
        require(msg.sender == _admin, "ADMIN_ONLY");
        _;
    }

    /// @dev Get the current administrator of this contract.
    /// @return The current administrator of this contract.
    function getAdmin() external view returns (address) {
        return _admin;
    }

    /// @dev Change the administrator to be `newAdmin`.
    /// @param newAdmin The address of the new administrator.
    function changeAdmin(address newAdmin) external {
        require(msg.sender == _admin, "ADMIN_ACCESS_DENIED");
        emit AdminChanged(_admin, newAdmin);
        _admin = newAdmin;
    }
}