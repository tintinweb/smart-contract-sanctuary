// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

contract ExchangeDomainV1 {

    enum AssetType {ETH, ERC20, ERC1155, ERC721}

    struct Asset {
        address token;
        uint tokenId;
        AssetType assetType;
    }

    struct OrderKey {
        /* who signed the order */
        address owner;
        /* random number */
        uint salt;

        /* what has owner */
        Asset sellAsset;

        /* what wants owner */
        Asset buyAsset;
    }

    struct Order {
        OrderKey key;

        /* how much has owner (in wei, or UINT256_MAX if ERC-721) */
        uint selling;
        /* how much wants owner (in wei, or UINT256_MAX if ERC-721) */
        uint buying;

        /* fee for selling */
        uint sellerFee;
    }

    /* An ECDSA signature. */
    struct Sig {
        /* v parameter */
        uint8 v;
        /* r parameter */
        bytes32 r;
        /* s parameter */
        bytes32 s;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "./exchange/ExchangeDomainV1.sol";
import "./exchange/ExchangeStateV1.sol";
import "./exchange/ExchangeOrdersHolderV1.sol";
import "./utils/Bytes.sol";
import "./utils/String.sol";
import "./utils/Uint.sol";
import "./proxy/ERC20TransferProxy.sol";
import "./proxy/TransferProxy.sol";

contract ExchangeV1 is Ownable, ExchangeDomainV1 {
    using SafeMath for uint;
    using UintLibrary for uint;
    using StringLibrary for string;
    using BytesLibrary for bytes32;

    enum FeeSide {NONE, SELL, BUY}

    event Buy(
        address indexed sellToken, uint256 indexed sellTokenId, uint256 sellValue,
        address owner,
        address buyToken, uint256 buyTokenId, uint256 buyValue,
        address buyer,
        uint256 amount,
        uint256 salt
    );

    event Cancel(
        address indexed sellToken, uint256 indexed sellTokenId,
        address owner,
        address buyToken, uint256 buyTokenId,
        uint256 salt
    );

    uint256 private constant UINT256_MAX = 2 ** 256 - 1;

    address payable public beneficiary;
    address public buyerFeeSigner;

    TransferProxy public transferProxy;
    ERC20TransferProxy public erc20TransferProxy;
    ExchangeStateV1 public state;
    ExchangeOrdersHolderV1 public ordersHolder;

    constructor(
        TransferProxy _transferProxy, ERC20TransferProxy _erc20TransferProxy, ExchangeStateV1 _state,
        ExchangeOrdersHolderV1 _ordersHolder, address payable _beneficiary, address _buyerFeeSigner
    ) {
        transferProxy = _transferProxy;
        erc20TransferProxy = _erc20TransferProxy;
        state = _state;
        ordersHolder = _ordersHolder;
        beneficiary = _beneficiary;
        buyerFeeSigner = _buyerFeeSigner;
    }

    function setBeneficiary(address payable newBeneficiary) external onlyOwner {
        beneficiary = newBeneficiary;
    }

    function setBuyerFeeSigner(address newBuyerFeeSigner) external onlyOwner {
        buyerFeeSigner = newBuyerFeeSigner;
    }

    function exchange(
        Order calldata order,
        Sig calldata sig,
        uint buyerFee,
        Sig calldata buyerFeeSig,
        uint amount,
        address buyer
    ) payable external {
        validateOrderSig(order, sig);
        validateBuyerFeeSig(order, buyerFee, buyerFeeSig);
        uint paying = order.buying.mul(amount).div(order.selling);
        verifyOpenAndModifyOrderState(order.key, order.selling, amount);
        require(order.key.sellAsset.assetType != AssetType.ETH, "ETH is not supported on sell side");
        if (order.key.buyAsset.assetType == AssetType.ETH) {
            validateEthTransfer(paying, buyerFee);
        }
        FeeSide feeSide = getFeeSide(order.key.sellAsset.assetType, order.key.buyAsset.assetType);
        if (buyer == address(0x0)) {
            buyer = msg.sender;
        }
        transferWithFeesPossibility(order.key.sellAsset, amount, order.key.owner, buyer, feeSide == FeeSide.SELL, buyerFee, order.sellerFee);
        transferWithFeesPossibility(order.key.buyAsset, paying, msg.sender, order.key.owner, feeSide == FeeSide.BUY, order.sellerFee, buyerFee);
        emitBuy(order, amount, buyer);
    }

    function validateEthTransfer(uint value, uint buyerFee) internal view {
        uint256 buyerFeeValue = value.bp(buyerFee);
        require(msg.value == value + buyerFeeValue, "msg.value is incorrect");
    }

    function cancel(OrderKey calldata key) external {
        require(key.owner == msg.sender, "not an owner");
        state.setCompleted(key, UINT256_MAX);
        emit Cancel(key.sellAsset.token, key.sellAsset.tokenId, msg.sender, key.buyAsset.token, key.buyAsset.tokenId, key.salt);
    }

    function validateOrderSig(
        Order memory order,
        Sig memory sig
    ) internal view {
        if (sig.v == 0 && sig.r == bytes32(0x0) && sig.s == bytes32(0x0)) {
            require(ordersHolder.exists(order), "incorrect signature");
        } else {
            require(prepareMessage(order).recover(sig.v, sig.r, sig.s) == order.key.owner, "incorrect signature");
        }
    }

    function validateBuyerFeeSig(
        Order memory order,
        uint buyerFee,
        Sig memory sig
    ) internal view {
        require(prepareBuyerFeeMessage(order, buyerFee).recover(sig.v, sig.r, sig.s) == buyerFeeSigner, "incorrect buyer fee signature");
    }

    function prepareBuyerFeeMessage(Order memory order, uint fee) public pure returns (string memory) {
        return keccak256(abi.encode(order, fee)).toString();
    }

    function prepareMessage(Order memory order) public pure returns (string memory) {
        return keccak256(abi.encode(order)).toString();
    }

    function transferWithFeesPossibility(Asset memory firstType, uint value, address from, address to, bool hasFee, uint256 sellerFee, uint256 buyerFee) internal {
        if (!hasFee) {
            transfer(firstType, value, from, to);
        } else {
            transferWithFees(firstType, value, from, to, sellerFee, buyerFee);
        }
    }

    function transfer(Asset memory asset, uint value, address from, address to) internal {
        if (asset.assetType == AssetType.ETH) {
            payable(to).transfer(value);
        } else if (asset.assetType == AssetType.ERC20) {
            require(asset.tokenId == 0, "tokenId should be 0");
            erc20TransferProxy.erc20safeTransferFrom(IERC20(asset.token), from, to, value);
        } else if (asset.assetType == AssetType.ERC721) {
            require(value == 1, "value should be 1 for ERC-721");
            transferProxy.erc721safeTransferFrom(IERC721(asset.token), from, to, asset.tokenId);
        } else {
            transferProxy.erc1155safeTransferFrom(IERC1155(asset.token), from, to, asset.tokenId, value, "");
        }
    }

    function transferWithFees(Asset memory firstType, uint value, address from, address to, uint256 sellerFee, uint256 buyerFee) internal {
        uint restValue = transferFeeToBeneficiary(firstType, from, value, sellerFee, buyerFee);
        transfer(firstType, restValue, from, to);
    }

    function transferFeeToBeneficiary(Asset memory asset, address from, uint total, uint sellerFee, uint buyerFee) internal returns (uint) {
        (uint restValue, uint sellerFeeValue) = subFeeInBp(total, total, sellerFee);
        uint buyerFeeValue = total.bp(buyerFee);
        uint beneficiaryFee = buyerFeeValue.add(sellerFeeValue);
        if (beneficiaryFee > 0) {
            transfer(asset, beneficiaryFee, from, beneficiary);
        }
        return restValue;
    }

    function emitBuy(Order memory order, uint amount, address buyer) internal {
        emit Buy(order.key.sellAsset.token, order.key.sellAsset.tokenId, order.selling,
            order.key.owner,
            order.key.buyAsset.token, order.key.buyAsset.tokenId, order.buying,
            buyer,
            amount,
            order.key.salt
        );
    }

    function subFeeInBp(uint value, uint total, uint feeInBp) internal pure returns (uint newValue, uint realFee) {
        return subFee(value, total.bp(feeInBp));
    }

    function subFee(uint value, uint fee) internal pure returns (uint newValue, uint realFee) {
        if (value > fee) {
            newValue = value - fee;
            realFee = fee;
        } else {
            newValue = 0;
            realFee = value;
        }
    }

    function verifyOpenAndModifyOrderState(OrderKey memory key, uint selling, uint amount) internal {
        uint completed = state.getCompleted(key);
        uint newCompleted = completed.add(amount);
        require(newCompleted <= selling, "not enough stock of order for buying");
        state.setCompleted(key, newCompleted);
    }

    function getFeeSide(AssetType sellType, AssetType buyType) internal pure returns (FeeSide) {
        if (sellType == AssetType.ERC721 && buyType == AssetType.ERC721) {
            return FeeSide.NONE;
        }
        if (uint(sellType) > uint(buyType)) {
            return FeeSide.BUY;
        }
        return FeeSide.SELL;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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

pragma solidity =0.8.4;
pragma experimental ABIEncoderV2;

import "../role/OwnableOperatorRole.sol";
import "./ExchangeDomainV1.sol";

contract ExchangeStateV1 is OwnableOperatorRole {

    // keccak256(OrderKey) => completed
    mapping(bytes32 => uint256) public completed;

    function getCompleted(ExchangeDomainV1.OrderKey calldata key) view external returns (uint256) {
        return completed[getCompletedKey(key)];
    }

    function setCompleted(ExchangeDomainV1.OrderKey calldata key, uint256 newCompleted) external onlyOperator {
        completed[getCompletedKey(key)] = newCompleted;
    }

    function getCompletedKey(ExchangeDomainV1.OrderKey memory key) pure public returns (bytes32) {
        return keccak256(abi.encodePacked(key.owner, key.sellAsset.token, key.sellAsset.tokenId, key.buyAsset.token, key.buyAsset.tokenId, key.salt));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;
pragma experimental ABIEncoderV2;

import "./ExchangeDomainV1.sol";

contract ExchangeOrdersHolderV1 {

    mapping(bytes32 => OrderParams) internal orders;

    struct OrderParams {
        /* how much has owner (in wei, or UINT256_MAX if ERC-721) */
        uint selling;
        /* how much wants owner (in wei, or UINT256_MAX if ERC-721) */
        uint buying;

        /* fee for selling */
        uint sellerFee;
    }

    function add(ExchangeDomainV1.Order calldata order) external {
        require(msg.sender == order.key.owner, "order could be added by owner only");
        bytes32 key = prepareKey(order);
        orders[key] = OrderParams(order.selling, order.buying, order.sellerFee);
    }

    function exists(ExchangeDomainV1.Order calldata order) external view returns (bool) {
        bytes32 key = prepareKey(order);
        OrderParams memory params = orders[key];
        return params.buying == order.buying && params.selling == order.selling && params.sellerFee == order.sellerFee;
    }

    function prepareKey(ExchangeDomainV1.Order memory order) internal pure returns (bytes32) {
        return keccak256(abi.encode(
                order.key.sellAsset.token,
                order.key.sellAsset.tokenId,
                order.key.owner,
                order.key.buyAsset.token,
                order.key.buyAsset.tokenId,
                order.key.salt
            ));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

library BytesLibrary {
    function toString(bytes32 value) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(64);
        for (uint256 i = 0; i < 32; i++) {
            str[i*2] = alphabet[uint8(value[i] >> 4)];
            str[1+i*2] = alphabet[uint8(value[i] & 0x0f)];
        }
        return string(str);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

import "./Uint.sol";

library StringLibrary {
    using UintLibrary for uint256;

    function append(string memory a, string memory b) internal pure returns (string memory) {
        bytes memory ba = bytes(a);
        bytes memory bb = bytes(b);
        bytes memory bab = new bytes(ba.length + bb.length);
        uint k = 0;
        for (uint i = 0; i < ba.length; i++) bab[k++] = ba[i];
        for (uint i = 0; i < bb.length; i++) bab[k++] = bb[i];
        return string(bab);
    }

    function append(string memory a, string memory b, string memory c) internal pure returns (string memory) {
        bytes memory ba = bytes(a);
        bytes memory bb = bytes(b);
        bytes memory bc = bytes(c);
        bytes memory bbb = new bytes(ba.length + bb.length + bc.length);
        uint k = 0;
        for (uint i = 0; i < ba.length; i++) bbb[k++] = ba[i];
        for (uint i = 0; i < bb.length; i++) bbb[k++] = bb[i];
        for (uint i = 0; i < bc.length; i++) bbb[k++] = bc[i];
        return string(bbb);
    }

    function recover(string memory message, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        bytes memory msgBytes = bytes(message);
        bytes memory fullMessage = concat(
            bytes("\x19Ethereum Signed Message:\n"),
            bytes(msgBytes.length.toString()),
            msgBytes,
            new bytes(0), new bytes(0), new bytes(0), new bytes(0)
        );
        return ecrecover(keccak256(fullMessage), v, r, s);
    }

    function concat(bytes memory ba, bytes memory bb, bytes memory bc, bytes memory bd, bytes memory be, bytes memory bf, bytes memory bg) internal pure returns (bytes memory) {
        bytes memory resultBytes = new bytes(ba.length + bb.length + bc.length + bd.length + be.length + bf.length + bg.length);
        uint k = 0;
        for (uint i = 0; i < ba.length; i++) resultBytes[k++] = ba[i];
        for (uint i = 0; i < bb.length; i++) resultBytes[k++] = bb[i];
        for (uint i = 0; i < bc.length; i++) resultBytes[k++] = bc[i];
        for (uint i = 0; i < bd.length; i++) resultBytes[k++] = bd[i];
        for (uint i = 0; i < be.length; i++) resultBytes[k++] = be[i];
        for (uint i = 0; i < bf.length; i++) resultBytes[k++] = bf[i];
        for (uint i = 0; i < bg.length; i++) resultBytes[k++] = bg[i];
        return resultBytes;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library UintLibrary {
    using SafeMath for uint;

    function toString(uint256 i) internal pure returns (string memory) {
        if (i == 0) {
            return "0";
        }
        uint j = i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (i != 0) {
            bstr[k--] = bytes1(uint8(48 + i % 10));
            i /= 10;
        }
        return string(bstr);
    }

    function bp(uint value, uint bpValue) internal pure returns (uint) {
        return value.mul(bpValue).div(10000);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../role/OwnableOperatorRole.sol";

contract ERC20TransferProxy is OwnableOperatorRole {

    function erc20safeTransferFrom(IERC20 token, address from, address to, uint256 value) external onlyOperator {
        require(token.transferFrom(from, to, value), "failure while transferring");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "../role/OwnableOperatorRole.sol";

contract TransferProxy is OwnableOperatorRole {

    function erc721safeTransferFrom(IERC721 token, address from, address to, uint256 tokenId) external onlyOperator {
        token.safeTransferFrom(from, to, tokenId);
    }

    function erc1155safeTransferFrom(IERC1155 token, address from, address to, uint256 id, uint256 value, bytes calldata data) external onlyOperator {
        token.safeTransferFrom(from, to, id, value, data);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

pragma solidity =0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./OperatorRole.sol";

contract OwnableOperatorRole is Ownable, OperatorRole {
    function addOperator(address account) external onlyOwner {
        _addOperator(account);
    }

    function removeOperator(address account) external onlyOwner {
        _removeOperator(account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

import "@openzeppelin/contracts/utils/Context.sol";

import "../utils/Roles.sol";

contract OperatorRole is Context {
    using Roles for Roles.Role;

    event OperatorAdded(address indexed account);
    event OperatorRemoved(address indexed account);

    Roles.Role private _operators;

    modifier onlyOperator() {
        require(isOperator(_msgSender()), "OperatorRole: caller does not have the Operator role");
        _;
    }

    function isOperator(address account) public view returns (bool) {
        return _operators.has(account);
    }

    function _addOperator(address account) internal {
        _operators.add(account);
        emit OperatorAdded(account);
    }

    function _removeOperator(address account) internal {
        _operators.remove(account);
        emit OperatorRemoved(account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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