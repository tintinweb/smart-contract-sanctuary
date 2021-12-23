/**
 *Submitted for verification at BscScan.com on 2021-12-23
*/

// File: @openzeppelin/contracts/introspection/IERC165.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol

pragma solidity ^0.6.2;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    function safeMint(address) external;
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.6.0;

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


// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


pragma solidity ^0.6.0;

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
}

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() public {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.6.0;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/lib/BytesLibrary.sol

pragma solidity ^0.6.0;

library BytesLibrary {
    function toString(bytes32 value) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(64);
        for (uint256 i = 0; i < 32; i++) {
            str[i * 2] = alphabet[uint8(value[i] >> 4)];
            str[1 + i * 2] = alphabet[uint8(value[i] & 0x0f)];
        }
        return string(str);
    }

    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        bytes32 fullMessage = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );
        return ecrecover(fullMessage, v, r, s);
    }
}

// File: contracts/lib/IWETH.sol

pragma solidity ^0.6.0;

interface IWETH {
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
}

// File: contracts/Exchange.sol

pragma solidity ^0.6.0;

contract OrderBook is Ownable {
    enum AssetType {
        ERC20,
        ERC721,
        ERC1155
    }

    struct Asset {
        address token;
        uint256 tokenId;
        AssetType assetType;
    }

    struct OrderKey {
        /* who signed the order */
        address payable owner;
        /* what has owner */
        Asset sellAsset;
        /* what wants owner */
        Asset buyAsset;
    }

    struct Order {
        OrderKey key;
        /* how much has owner (in wei, or UINT256_MAX if ERC-721) */
        uint256 selling;
        /* how much wants owner (in wei, or UINT256_MAX if ERC-721) */
        uint256 buying;
        /* fee for selling  secoundary sale*/
        uint256 sellerFee;
        /* random numbers*/
        uint256 salt;
        /* expiry time for order*/
        uint256 expiryTime; // for bid auction auction time + bidexpiry
        /* order Type */
        uint256 orderType; // 1.sell , 2.buy, 3.bid
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

contract OrderState is OrderBook {
    using BytesLibrary for bytes32;

    mapping(bytes32 => bool) public completed; // 1.completed

    function getCompleted(OrderBook.Order calldata order)
        external
        view
        returns (bool)
    {
        return completed[getCompletedKey(order)];
    }

    function setCompleted(OrderBook.Order memory order, bool newCompleted)
        internal
    {
        completed[getCompletedKey(order)] = newCompleted;
    }

    function setCompletedBidOrder(
        OrderBook.Order memory order,
        bool newCompleted,
        address buyer,
        uint256 buyingAmount
    ) internal {
        completed[
            getBidOrderCompletedKey(order, buyer, buyingAmount)
        ] = newCompleted;
    }

    function getCompletedKey(OrderBook.Order memory order)
        public
        pure
        returns (bytes32)
    {
        return prepareOrderHash(order);
    }

    function getBidOrderCompletedKey(
        OrderBook.Order memory order,
        address buyer,
        uint256 buyingAmount
    ) public pure returns (bytes32) {
        return prepareBidOrderHash(order, buyer, buyingAmount);
    }

    function validateOrderSignature(Order memory order, Sig memory sig)
        internal
        view
    {
        require(completed[getCompletedKey(order)] != true, "Signature exist");
        if (sig.v == 0 && sig.r == bytes32(0x0) && sig.s == bytes32(0x0)) {
            revert("incorrect signature");
        } else {
            require(
                prepareOrderHash(order).recover(sig.v, sig.r, sig.s) ==
                    order.key.owner,
                "Incorrect signature"
            );
        }
    }

    function validateOrderSignatureView(Order memory order, Sig memory sig)
        public
        view 
        returns (address)
    {
        require(completed[getCompletedKey(order)] != true, "Signature exist");
        if (sig.v == 0 && sig.r == bytes32(0x0) && sig.s == bytes32(0x0)) {
            revert("Incorrect signature");
        } else {
              return prepareOrderHash(order).recover(sig.v, sig.r, sig.s);
        }
    }

    function prepareOrderHash(OrderBook.Order memory order)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    order.key.owner,
                    abi.encodePacked(
                        order.key.sellAsset.token,
                        order.key.sellAsset.tokenId,
                        order.key.sellAsset.assetType,
                        order.key.buyAsset.token,
                        order.key.buyAsset.tokenId,
                        order.key.buyAsset.assetType
                    ),
                    order.selling,
                    order.buying,
                    order.sellerFee,
                    order.salt,
                    order.expiryTime,
                    order.orderType
                )
            );
    }

    function prepareBidOrderHash(
        OrderBook.Order memory order,
        address bidder,
        uint256 buyingAmount
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    bidder,
                    abi.encodePacked(
                        order.key.buyAsset.token,
                        order.key.buyAsset.tokenId,
                        order.key.buyAsset.assetType,
                        order.key.sellAsset.token,
                        order.key.sellAsset.tokenId,
                        order.key.sellAsset.assetType
                    ),
                    buyingAmount,
                    order.selling,
                    order.sellerFee,
                    order.salt,
                    order.expiryTime,
                    order.orderType
                )
            );
    }

    function prepareBuyerFeeMessage(
        Order memory order
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    abi.encodePacked(
                        order.key.owner,
                        abi.encodePacked(
                            order.key.sellAsset.token,
                            order.key.sellAsset.tokenId,
                            order.key.buyAsset.token,
                            order.key.buyAsset.tokenId
                        ),
                        order.selling,
                        order.buying,
                        order.sellerFee,
                        order.salt,
                        order.expiryTime,
                        order.orderType
                    )
                )
            );
    }
}

contract OrenExchange is OrderState,Pausable {
    using SafeMath for uint256;

    address public buyerFeeSigner;
    address public tresuryAddress;

    IERC721 public orenNft;

    // auth token for exchange
    mapping(address => bool) public allowToken;

    event MatchOrder(
        address indexed sellToken,
        uint256 indexed sellTokenId,
        uint256 sellValue,
        address owner,
        address buyToken,
        uint256 buyTokenId,
        uint256 buyValue,
        address buyer,
        uint256 orderType
    );
    event Cancel(
        address indexed sellToken,
        uint256 indexed sellTokenId,
        address owner,
        address buyToken,
        uint256 buyTokenId
    );
    event Beneficiary(address newBeneficiary);
    event BuyerFeeSigner(address newBuyerFeeSigner);
    event BeneficiaryFee(uint256 newbeneficiaryfee);
    event RoyaltyFeeLimit(uint256 newRoyaltyFeeLimit);
    event AllowToken(address token, bool status);
    event SetMintableStore(address newMintableStore);

    constructor(
        address buyerfeesigner,
        address nft
    ) public {
        buyerFeeSigner = buyerfeesigner;
        orenNft = IERC721(nft);
        tresuryAddress = msg.sender;
    }

    receive() external payable {}
        
    function pause() public onlyOwner{
      _pause();
    }
    
    function unpause() public onlyOwner{
      _unpause();
    }

    function sell(
        Order calldata order,
        Sig calldata sig,
        Sig calldata buyerFeeSig
    ) external payable whenNotPaused {
        require((block.timestamp <= order.expiryTime), "Signature expired");
        require(order.orderType == 1, "Invalid order type");
        require(order.key.owner != msg.sender, "Invalid owner");
        require(msg.value >= order.buying, "msg.value is invalid");

        validateOrderSignature(order, sig);
        validateBuyerFeeSig(order, buyerFeeSig);
        setCompleted(order, true);
        orenNft.safeMint(msg.sender);
        payable(tresuryAddress).transfer(msg.value);
        emitMatchOrder(order, msg.sender);
    }

    function emitMatchOrder(Order memory order, address buyer) internal {
        emit MatchOrder(
            order.key.sellAsset.token,
            order.key.sellAsset.tokenId,
            order.selling,
            order.key.owner,
            order.key.buyAsset.token,
            order.key.buyAsset.tokenId,
            order.buying,
            buyer,
            order.orderType
        );
    }

    function cancel(Order calldata order) external whenNotPaused {
        require(order.key.owner == msg.sender, "Not an owner");
        setCompleted(order, true);
        emit Cancel(
            order.key.sellAsset.token,
            order.key.sellAsset.tokenId,
            msg.sender,
            order.key.buyAsset.token,
            order.key.buyAsset.tokenId
        );
    }

    function validateBuyerFeeSig(
        Order memory order,
        Sig memory sig
    ) internal view {
        require(
            prepareBuyerFeeMessage(order).recover(
                sig.v,
                sig.r,
                sig.s
            ) == buyerFeeSigner,
            "Incorrect buyer fee signature"
        );
    }

    function validateBuyerFeeSigView(
        Order memory order,
        Sig memory sig
    ) public pure returns (address) {
        prepareBuyerFeeMessage(order).recover(
            sig.v,
            sig.r,
            sig.s
        ); 
    }

    function toEthSignedMessageHash(bytes32 hash, Sig memory sig)
        public
        pure
        returns (address signer)
    {
        signer = hash.recover(sig.v, sig.r, sig.s);
    }

    function setBuyerFeeSigner(address newBuyerFeeSigner) external onlyOwner {
        require(newBuyerFeeSigner != address(0x00), "Zero address");
        buyerFeeSigner = newBuyerFeeSigner;
        emit BuyerFeeSigner(newBuyerFeeSigner);
    }

    function setTokenStatus(address token, bool status) external onlyOwner {
        require(token != address(0x00), "Zero address");
        allowToken[token] = status;
        emit AllowToken(token, status);
    }

    function setTresuryWallet(address account) external onlyOwner {
        require(account != address(0), "Address can't be zero");
        tresuryAddress = account;
    }

    /**
     * @dev Rescues random funds stuck that the contract can't handle.
     * @param _token address of the token to rescue.
     */
    function inCaseTokensGetStuck(address _token) external onlyOwner {
        if (_token != address(0x000)) {
            uint256 amount = IERC20(_token).balanceOf(address(this));
            IERC20(_token).transfer(msg.sender, amount);
        } else {
            (msg.sender).transfer(address(this).balance);
        }
    }
}