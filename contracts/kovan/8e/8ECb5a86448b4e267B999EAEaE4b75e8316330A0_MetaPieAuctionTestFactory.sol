/**
 *Submitted for verification at Etherscan.io on 2021-10-15
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.0;


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
}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

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

    constructor () internal {
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


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
    constructor () internal {
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
}
/**
 * @dev Interface of the Auction.
 */
interface IAuction {
    event AuctionStarted(uint256 startTime);
    // event AuctionFailed();
    event NewBidding(address bidder, uint256 amount);
    event AuctionEnded(address winner, uint256 amount, bool successfulBid);
    event AuctionUpdated(
        uint256 startTime,
        uint256 endTime,
        uint256 startPrice
    );
    event AuctionCreated(
        address _assetAddress,
        uint256 _assetId,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _startPrice,
        address _seller,
        address _NFTCreator,
        address _platform,
        uint256 _creatorRoyaltyRatio,
        uint256 _platformFeeRatio,
        address _whitelist,
        address _blacklist
    );

    event ReturnBid(address prebidder, uint256 amount);
    // event SendFee(address platform, uint256 amount);
    // event SendCreatorRoyalty(address creator, uint256 amount);
    // event FinalizeBid(address seller, uint256 amount);

    event FinalizeBid(address seller, uint256 amount, address creator, uint256 creatorRoyalty, address platform, uint256 platformFee);

    /**
     * @dev When the first bid occurs, the auction status changes to a start.
     */
    function started() external view returns (bool);

    function ended() external view returns (bool);

    function bid() external payable;

    function auctionUpdate(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _startPrice
    ) external;

    function auctionEnd() external;
}

/**
 * @dev Interface of the Auction.
 */
interface IAuctionCancelable {

    event AuctionCanceled(uint256 cancelTime, uint256 startTime);

    function auctionCancel() external;
    function canceled() external view returns (bool);
}

interface IWhitelist {

    event Whitelisted(address indexed account, bool listed);

    function whitelisted(address _address) external view returns (bool);

    function listAddress(address _address) external;

    function delistAddress(address _address) external;

}

interface IBlacklist {

    event Blacklisted(address indexed account, bool listed);

    function blacklisted(address _address) external view returns (bool);

    function listAddress(address _address) external;

    function delistAddress(address _address) external;

}

contract Auction is
    IAuction,
    IAuctionCancelable,
    IERC721Receiver,
    Ownable,
    ReentrancyGuard
{
    using SafeMath for uint256;
    using Address for address;

    struct Asset {
        address assetAddress;
        uint256 assetId;
        address owner;
    }

    struct AuctionSetting {
        uint256 startTime;
        uint256 endTime;
        uint256 startPrice;
        address payable NFTCreator; //NFT Creator address
        uint256 creatorRoyaltyRatio; //NFT Creator's royalty fee
        uint256 platformServiceRatio; //Platform service fee
    }

    address payable public seller; //Auction creator
    Asset public asset;
    AuctionSetting public setting;

    // Current state of the auction.
    address payable public highestBidder;
    uint256 public highestBid;
    uint256 public bidCount;

    bool private _started;
    bool private _ended;
    bool private _canceled;

    address public NFTCreator; //NFT Creator
    address public factory;
    address payable public platform;

    uint256 public MAX_FEE = 10000;

    // IWhitelist public whitelist;
    address public whitelist;
    address public blacklist;

    uint256 private platformFee = 0;
    uint256 private royalty = 0;

    uint256 public unitPrice = 1 ether;



    modifier beforeStarted() {
        require(!started(), "Already started");
        _;
    }

    modifier onlySellerOrOwner() {
        require(
            _msgSender() == seller || _msgSender() == owner(),
            "caller is not the seller"
        );
        _;
    }

    modifier onlyListed() {
        if(whitelist != address(0x0)){
            require(IWhitelist(whitelist).whitelisted(_msgSender()), "caller is not whitelisted");
        }
        if(blacklist != address(0x0)){
            require(!IBlacklist(blacklist).blacklisted(_msgSender()), "caller is blacklisted");
        }
        _;
    }

    constructor(
        address _assetAddress,
        uint256 _assetId,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _startPrice,
        address payable _seller,
        address payable _NFTCreator,
        address payable _platform,
        uint256 _creatorRoyaltyRatio,
        uint256 _platformFeeRatio,
        address _whitelist,
        address _blacklist
    ) public {
        require(now <= _startTime && _startTime < _endTime, "Invalid Time");
        require(1 ether <= _startPrice, "startPrice must be at least 1META");

        factory = _msgSender();
        whitelist = _whitelist; //IWhitelist(AuctionFactory(factory).whitelist());
        blacklist = _blacklist;

        seller = _seller;
        NFTCreator = _NFTCreator;

        address assetOwner = IERC721(_assetAddress).ownerOf(_assetId);
        asset = Asset(_assetAddress, _assetId, assetOwner);

        // FeeTable feeTable = FeeTable(AuctionFactory(factory).feeTable());
        // MAX_FEE = feeTable.MAX_FEE();
        // treasury = feeTable.treasury();

        //platform collects fee
        platform = _platform;

        // address payable creatorRoyaltyBeneficiary = feeTable.creatorRoyaltyBeneficiary(_assetAddress, _assetId);
        // uint256 creatorRoyaltyRatio = 
        // feeTable.creatorRoyaltyFee(
        //     _assetAddress,
        //     _assetId
        // );
        // uint256 platformServiceFee = isFirstSale()
        //     ? feeTable.platformServiceFirstFee(_beneficiary)
        //     : feeTable.platformServiceFee(_beneficiary);

        setting = AuctionSetting(
            _startTime,
            _endTime,
            _startPrice,
            _NFTCreator,
            _creatorRoyaltyRatio,
            _platformFeeRatio
        );

        transferOwnership(AuctionFactory(factory).owner());

        AuctionCreated(
            _assetAddress, _assetId, _startTime, _endTime, _startPrice, 
            _seller, _NFTCreator, _platform,
            _creatorRoyaltyRatio, _platformFeeRatio,
            _whitelist, _blacklist
        );
    }

    // function isFirstSale() internal view returns (bool) {
    //     return
    //         IAuctionViewer(factory).auctionCountOfToken(
    //             asset.assetAddress,
    //             asset.assetId
    //         ) == 0;
    // }

    function tokenURI() public view returns (string memory) {
        Asset memory a = asset;
        return IERC721Metadata(a.assetAddress).tokenURI(a.assetId);
    }

    function auctionUpdate(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _startPrice
    ) public virtual override onlySellerOrOwner {
        // AuctionSetting storage s = setting;

        // condition check
        // now < _startTime < _endTime
        // 
        require(now <= _startTime, "Start time must be later than current." );
        require(_startTime < _endTime, "Start time must be earier than End time.");
        AuctionSetting storage s = setting;
        if (s.endTime != _endTime) {
            // AuctionUpdatedEndTime(_endTime);
            s.endTime = _endTime;
        }
        if (s.startTime != _startTime){
            // AuctionUpdatedStartTime(_startTime);
            s.startTime = _startTime;
        }
        if (s.startPrice != _startPrice){
            // updateStartPrice(_startPrice);
            require(1 ether <= _startPrice, "startPrice is smaller than 1 META");
            s.startPrice = _startPrice;
        } 
        

        emit AuctionUpdated(s.startTime, _endTime, _startPrice);
    }

    // function AuctionUpdatedStartTime(uint256 _startTime)
    //     internal
    //     beforeStarted
    //     onlySellerOrOwner
    // {
    //     AuctionSetting storage s = setting;
    //     // require(now < s.startTime);

    //     s.startTime = _startTime;
    // }

    // function AuctionUpdatedEndTime(uint256 _endTime)
    //     internal
    //     beforeStarted
    //     onlySellerOrOwner
    // {
    //     AuctionSetting storage s = setting;

    //     s.endTime = _endTime;
    // }

    // function updateStartPrice(uint256 _startPrice)
    //     internal
    //     beforeStarted
    //     onlySellerOrOwner
    // {
    //     require(1 ether <= _startPrice);

    //     AuctionSetting storage s = setting;

    //     s.startPrice = _startPrice;
    // }

    function started() public view virtual override returns (bool) {
        return _started;
    }

    function ended() public view virtual override returns (bool) {
        return _ended;
    }

    function canceled() public view virtual override returns (bool) {
        return _canceled;
    }

    function currentHighestBid() public view returns (uint256, address) {
        return (highestBid, highestBidder);
    }

    function bid() public payable virtual override onlyListed nonReentrant {
        address sender = _msgSender();
        require(!sender.isContract(), "Contract can't bid");
        require(!canceled(), "Already canceled");
        require(!ended(), "Already ended");

        Asset memory a = asset;
        require(
            IERC721(a.assetAddress).ownerOf(a.assetId) == address(this),
            "The assets have not yet been entrusted"
        );

        AuctionSetting memory s = setting;
        require(
            s.startTime <= now && now <= s.endTime,
            "Not time for the auction"
        );
        require(msg.value >= s.startPrice, "Must be higher than startPrice");
        require(
            msg.value >= highestBid.add(unitPrice), // 1 ether -> parameter
            "The Bidding price is too low."
        );

        if (!started()){
            _started = true;
            emit AuctionStarted(uint256(now));
        }

        address payable previousBidder = highestBidder;
        uint256 previousBid = highestBid;

        highestBidder = payable(sender);
        highestBid = msg.value;
        bidCount = bidCount.add(1);

        emit NewBidding(highestBidder, highestBid);

        if (previousBid > 0) {
            //previousBidder.transfer(previousBid);
            (bool sent, ) = previousBidder.call{value: previousBid}("");
            require(sent, "Failed to send Meta");
            emit ReturnBid(previousBidder, previousBid);
        }
    }

    function auctionEnd() public virtual override nonReentrant {
        require(!canceled(), "Already canceled");
        require(!ended(), "Already ended");

        AuctionSetting memory s = setting;
        require(now >= s.endTime, "Not In time.");

        _ended = true;
        bool successfulBidding = (bidCount == 0) ? false : true;

        Asset memory a = asset;
        if (successfulBidding)
            IERC721(a.assetAddress).transferFrom(
                address(this),
                highestBidder,
                a.assetId
            );
        else
            IERC721(a.assetAddress).transferFrom(
                address(this),
                a.owner,
                a.assetId
            );

        emit AuctionEnded(highestBidder, highestBid, successfulBidding);

        if (highestBid > 0) {
            uint256 amountWithoutFee = takeFee(highestBid);

            //beneficiary.transfer(highestBid);
            (bool sent, ) = seller.call{value: amountWithoutFee}("");
            require(sent, "Failed to send");
            ///TODO change event
            emit FinalizeBid(seller, amountWithoutFee, NFTCreator, royalty, platform, platformFee);
        }
    }

    function takeFee(uint256 value) internal returns (uint256) {
        AuctionSetting memory s = setting;
        //Take Playform ServiceFee
        platformFee = (value.mul(s.platformServiceRatio)).div(MAX_FEE);

        (bool sentPaltformFee, ) = platform.call{value: platformFee}("");

        require(sentPaltformFee, "Failed to send");

        //Take Creator Royalty
        if (s.NFTCreator != address(0)) {
            royalty = (value.mul(s.creatorRoyaltyRatio)).div(MAX_FEE);

            (bool sentRoyalty, ) = NFTCreator.call{
                value: royalty
            }("");
            require(sentRoyalty, "Failed to send");

            return (value.sub(platformFee)).sub(royalty);
        }

        return value.sub(platformFee);
    }

    function auctionCancel()
        public
        virtual
        override
        onlySellerOrOwner
        beforeStarted
        nonReentrant
    {
        require(!canceled(), "Already canceled");
        require(!ended(), "Already ended");

        _canceled = true;

        Asset memory a = asset;
        IERC721(a.assetAddress).transferFrom(address(this), a.owner, a.assetId);

        AuctionSetting memory s = setting;
        emit AuctionCanceled(uint256(now), s.startTime);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function setUnitPrice(uint256 _unitPrice) external onlyOwner{
        unitPrice = _unitPrice;
    }
}


contract AuctionFactory is Ownable {
    using Address for address;

    address public whitelist;
    address public blacklist;
    // address public feeTable;

    event NewWhitelist(address previousWhitelist, address newWhitelist);
    event NewBlacklist(address previousBlacklist, address newBlacklist);
    // event NewFeeTable(address previousFeeTable, address newFeeTable);

    event AuctionCreated(
        address _assetAddress,
        uint256 _assetId,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _startPrice,
        address _seller,
        address _NFTCreator,
        address _platform,
        uint256 _creatorRoyaltyRatio,
        uint256 _platformFeeRatio,
        address _whitelist,
        address _blacklist,
        address _newAuction
    );
    constructor(
        address _whitelist,
        address _blacklist
    ) public {
        setWhitelist(_whitelist);
        setBlacklist(_blacklist);
        // setFeeTable(_feeTable);
    }

    function setWhitelist(address _whitelist) public onlyOwner {
        // require(_whitelist != address(0), "whitelist can't be 0x0");
        NewWhitelist(whitelist, _whitelist);
        whitelist = _whitelist;
    }

    function setBlacklist(address _blacklist) public onlyOwner {
        // require(_blacklist != address(0), "blacklist can't be 0x0");
        NewBlacklist(blacklist, _blacklist);
        blacklist = _blacklist;
    }

    // function setFeeTable(address _feeTable) public onlyOwner {
    //     require(_feeTable != address(0), "feeTable can't be 0x0");
    //     NewFeeTable(feeTable, _feeTable);
    //     feeTable = _feeTable;
    // }

    function createAuction(
        address _assetAddress,
        uint256 _assetId,
        uint256[] memory _time,
        uint256 _startPrice,
        address payable _seller,
        address payable _NFTCreator,
        address payable _platform,
        uint256 _creatorRoyaltyRatio,
        uint256 _platformFeeRatio
    ) public onlyOwner returns (address) {
        if(whitelist != address(0x0)){
            require(IWhitelist(whitelist).whitelisted(_seller), "seller is not whitelisted");
        }
        if(blacklist != address(0x0)){
            require(!IBlacklist(blacklist).blacklisted(_seller), "seller is blacklisted");
        }
        address newAuctionAddress;
        
        IERC721 asset = IERC721(_assetAddress);
        // address assetOwner = asset.ownerOf(_assetId);
        // address spender = _msgSender();

        // require(assetOwner == _msgSender(); || asset.getApproved(_assetId) == _msgSender || asset.isApprovedForAll(assetOwner, _msgSender), "Not Approved");
        require(asset.getApproved(_assetId) == address(this) || asset.isApprovedForAll(_seller, address(this)), "Not approved");
    
        Auction newAuction =
            new Auction(
                _assetAddress, _assetId, _time[0], _time[1], _startPrice, 
                _seller, _NFTCreator, _platform,
                _creatorRoyaltyRatio, _platformFeeRatio,
                whitelist, blacklist
            );

        newAuctionAddress = address(newAuction);
        // _whenAuctionCreated(_assetAddress, _assetId, newAuctionAddress);

        asset.transferFrom(_seller, newAuctionAddress, _assetId);
        
        emit AuctionCreated(
            _assetAddress, _assetId, _time[0], _time[1], _startPrice, 
            _seller, _NFTCreator, _platform,
            _creatorRoyaltyRatio, _platformFeeRatio,
            whitelist, blacklist,
            newAuctionAddress
        );

        return newAuctionAddress;
    }

    function _whenAuctionCreated(address assetAddress, uint256 assetId, address auctionAddress) internal virtual { }
}

// contract MetaPieAuctionFactory is AuctionFactory {
//     constructor(
//         address _whitelist,
//         address _blacklist
//     ) public AuctionFactory(_whitelist, _blacklist) {
        
//     }
// }

contract MetaPieAuctionTestFactory is AuctionFactory {
    constructor(
    ) public AuctionFactory(0x0000000000000000000000000000000000000000,0x0000000000000000000000000000000000000000) {
        
    }
}