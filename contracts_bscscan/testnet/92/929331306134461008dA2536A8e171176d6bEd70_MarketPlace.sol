// SPDX-License-Identifier: MIT
pragma solidity <=0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MarketPlace {
    // event
    event ORDER(address indexed ct, uint256 indexed tokenId, address indexed who, address unit, uint256 openPrice, uint256 closePrice, uint256 startTime, uint256 duration, bool keep, uint256 timestamp);
    event MATCH(address indexed ct, uint256 indexed tokenId, address buyer, address seller, address unit, uint256 matchPrice, string data, uint256 timestamp);
    event OFFERS(address indexed ct, uint256 indexed tokenId, address indexed who, address unit, uint offersPrice, uint256 startTime, uint256 duration, uint timestamp);
    event UPDATE(address indexed ct, uint256 indexed tokenId, address indexed who, uint256 price, string data, uint256 timestamp);
    // struct down auction
    struct Order {
        address seller; // seller's address
        address unit; // unit's address. e.g UCC's address
        uint256 openPrice; // open price
        uint256 closePrice; // close price
        uint256 startTime; // start time
        uint256 duration; // duration
        bool keep; // keep sale or stop when out of time
    }
    // struct up auction
    struct Offers {
        address unit; // unit's address. e.g UCC's address
        uint256 offersPrice; // offers's price
        uint256 startTime; // start time
        uint256 duration; // duration
    }
    // NFT's info
    struct Path {
        uint256 ver; // 721 || 1155
        address ct; // NFT's contract address
        uint256 tokenId; // NFT's ID
    }
    // get user's order. Call: myOrder[user's address]
    mapping(address => Path[]) public myOrder;
    // private. get pushedorder of user for a NFT. call: pushedOrder[user's address][nft's contract address][NFT's ID]
    mapping(address => mapping(address => mapping(uint256 => bool))) private pushedOrder;
    // get orders of NFT. Call: order[NFT's contract address][NFT's ID]
    mapping(address => mapping(uint256 => Order)) public order;
    // get my NFT path. Call: myOffers[user's address] 
    mapping(address => Path[]) public myOffers;
    // Private. Get pushed Offers of user for a token. Call: pushedOffers[user's address][NFT's contract address][NFT's ID]
    mapping(address => mapping(address => mapping(uint256 => bool))) private pushedOffers;
    // Get user's offers. call: offers[user's address][NFT's contract address][NFT's ID]
    mapping(address => mapping(address => mapping(uint256 => Offers))) public offers;
    // get offers list of a NFT. Call: listOffers[NFT's contract address][NFT's ID]
    mapping(address => mapping(uint256 => address[])) public listOffers;
    // check sale status: sale or not sale
    // _ver: 721 || 1155
    // _ct: NFT's contract address
    // _tokenId: NFT's ID
    modifier isSale(uint _ver, address _ct, uint _tokenId) {
        require(!owner(_ver, _ct, msg.sender, _tokenId), "");
        require(order[_ct][_tokenId].openPrice > 0, "Not Sale");
        _;
    }
    // check NFT's owner
    // _ver: 721 || 1155
    // _ct: NFT's contract address
    // _user: user's address
    // _tokenId: token's ID
    function owner(uint _ver, address _ct, address _user, uint _tokenId) public view returns(bool isOwner){
        if (_ver == 721) return IERC721(_ct).ownerOf(_tokenId) == _user;
        return IERC1155(_ct).balanceOf(_user, _tokenId) == 1;
    }

    // check NFT's owner on martket
    // _ver: 721 || 1155
    // _ct: NFT's contract address
    // _user: user's address
    // _tokenId: token's ID
    function isOwnerNFTOnMarket(address _ct, address _user, uint _tokenId) public view returns(bool isOwner){
        return order[_ct][_tokenId].seller == _user;
    }
    // auction and market
    // _ver: 721 || 1155
    // _ct: NFT's contract address
    // _tokenId: token's ID
    // _unit: unit's address ( BUSD, UCC...)
    // _openPrice: open price
    // _closePrice: close price
    // _startTime: start time
    // _duration: duration of auction
    // _keep: keep auction when out of auction's time
    function sell(uint _ver, address _ct, uint256 _tokenId, address _unit, uint256 _openPrice, uint256 _closePrice, uint256 _startTime, uint256 _duration, bool _keep) public {
        require(owner(_ver, _ct, msg.sender, _tokenId), "Error, you are not the owner");
        order[_ct][_tokenId] = Order(msg.sender, _unit, _openPrice, _closePrice, _startTime, _duration, _keep);

        if (!pushedOrder[msg.sender][_ct][_tokenId]){
            pushedOrder[msg.sender][_ct][_tokenId] = true;
            myOrder[msg.sender].push(Path(_ver, _ct, _tokenId));
        }

        if (listOffers[_ct][_tokenId].length > 0){
            listOffers[_ct][_tokenId] = new address[](0);
        }
        emit ORDER(_ct , _tokenId, msg.sender, _unit,_openPrice, _closePrice, _startTime, _duration, _keep, block.timestamp);
    }
    // Update order
    // _ver: 721 || 1155
    // _ct: NFT's contract address
    // _tokenId: token's ID
    // _openPrice: open price
    function updateOrder(uint _ver, address _ct, uint256 _tokenId, uint256 _openPrice) public {
        require(owner(_ver, _ct, msg.sender, _tokenId), "Error, you are not the owner");
        order[_ct][_tokenId].openPrice = _openPrice;
        emit UPDATE(_ct , _tokenId, msg.sender, _openPrice, "order", block.timestamp);
    }
    // buyer buy NFT of down auction and market
    // _ver: 721 || 1155
    // _ct: NFT's contract address
    // _tokenId: token's ID
    function buy(uint _ver, address _ct, uint256 _tokenId) public isSale(_ver, _ct, _tokenId) {
        Order memory _order = order[_ct][_tokenId];
        require(owner(_ver, _ct, _order.seller, _tokenId), "");

        uint256 t = block.timestamp;

        require(t >= _order.startTime && (t <= _order.startTime + _order.duration || _order.keep), "");
        require(_order.closePrice != ~uint(0) && _order.openPrice != ~uint(0), "");

        uint256 rPrice = _order.openPrice;
        if (_order.openPrice >= _order.closePrice) {
            if (_order.duration > 0) {
                if (t >= _order.startTime + _order.duration) {
                    rPrice = _order.closePrice;
                } else {
                    rPrice = _order.openPrice - ((t - _order.startTime) * (_order.openPrice - _order.closePrice) / _order.duration);
                }
            }
        } else {
            rPrice = _order.closePrice;
        }
        swap(_ver, _ct, _tokenId, msg.sender, _order.seller, _order.unit, rPrice, "buy");
    }
    // buyer set an offer for up auction
    // _ver: 721 || 1155
    // _ct: NFT's contract address
    // _tokenId: token's ID
    // _unit: unit's address ( BUSD, UCC...)
    // _offersPrice: offers price
    // _startTime: start time
    // _duration: duration of auction
    function setOffers(uint _ver, address _ct, uint256 _tokenId, address _unit, uint _offersPrice, uint256 _startTime, uint256 _duration) public isSale(_ver, _ct, _tokenId) {
        if (!pushedOffers[msg.sender][_ct][_tokenId]){
            pushedOffers[msg.sender][_ct][_tokenId] = true;
            myOffers[msg.sender].push(Path(_ver, _ct, _tokenId));
        }

        offers[msg.sender][_ct][_tokenId] = Offers(_unit, _offersPrice, _startTime, _duration);
        
        if (_offersPrice != 0){
            listOffers[_ct][_tokenId].push(msg.sender);
        }
        emit OFFERS(_ct, _tokenId, msg.sender, _unit, _offersPrice, _startTime, _duration, block.timestamp);
    }
    // buyer update an offer for up auction
    // _ver: 721 || 1155
    // _ct: NFT's contract address
    // _tokenId: token's ID
    // _unit: unit's address ( BUSD, UCC...)
    // _offersPrice: offers price
    // _startTime: start time
    // _duration: duration of auction
    function updateOffers(address _ct, uint256 _tokenId, uint256 _offersPrice) public {
        require(offers[msg.sender][_ct][_tokenId].duration > 0 && offers[msg.sender][_ct][_tokenId].startTime > 0, "");
        offers[msg.sender][_ct][_tokenId].offersPrice = _offersPrice;
        emit UPDATE(_ct , _tokenId, msg.sender, _offersPrice, "offers", block.timestamp);
    }
    // owner accept an offers
    function accept(uint _ver, address _ct, uint256 _tokenId, address _buyer) public {
        require(owner(_ver, _ct, msg.sender, _tokenId), "Error, you are not the owner");
        require(order[_ct][_tokenId].openPrice > 0, "Not Sale");
        require(offers[_buyer][_ct][_tokenId].offersPrice > 0 && offers[_buyer][_ct][_tokenId].duration > 0, "");
        uint256 start = offers[_buyer][_ct][_tokenId].startTime;
        require(block.timestamp >= start && block.timestamp <= start + offers[_buyer][_ct][_tokenId].duration, "");

        swap(_ver, _ct, _tokenId, _buyer, msg.sender, offers[_buyer][_ct][_tokenId].unit, offers[_buyer][_ct][_tokenId].offersPrice, "accept");
    }
    // private function, swap nft
    function swap(uint _ver, address _ct, uint256 _tokenId, address _buyer, address _seller, address _unit, uint256 _matchPrice, string memory _data) private {
        SafeERC20.safeTransferFrom(IERC20(_unit), _buyer, _seller, _matchPrice);
        emit MATCH(_ct, _tokenId, _buyer, _seller, _unit, _matchPrice, _data, block.timestamp);
        transferNFT(_ver, _ct, _tokenId, _buyer, _seller);
    }

    function transferNFT(uint _ver, address _ct, uint256 _tokenId, address _buyer, address _seller) private {
        if (_ver == 721)return IERC721(_ct).transferFrom(_seller, _buyer, _tokenId);
        return IERC1155(_ct).safeTransferFrom(_seller, _buyer, _tokenId, 1, "");
    }

    // user send NFT to martketplace
    function userTransferNFT(uint _ver, address _ct, uint256 _tokenId, address _buyer, address _seller) public {
        require(owner(_ver, _ct, msg.sender, _tokenId), "Error, you are not the owner");
        transferNFT(_ver, _ct, _tokenId, _buyer, _seller);
    }

    function userWithdrawNFT(uint _ver, address _ct, uint256 _tokenId, address _buyer, address _seller) public {
        require(isOwnerNFTOnMarket(_ct, msg.sender, _tokenId), "Error, you are not the owner");
        transferNFT(_ver, _ct, _tokenId, _buyer, _seller);
    }

    // get user's order
    function getOrder() public view returns (Path[] memory _filtedPath){
        Path[] memory path = myOrder[msg.sender];
        uint256 resultCount;

        for (uint i = 0; i < path.length; i++){
            if (order[path[i].ct][path[i].tokenId].openPrice > 0){
                resultCount++;
            }
        }
        
        Path[] memory filtedPath = new Path[](resultCount);
        uint256 j;
        
        for (uint i = 0; i < path.length; i++){
            if (order[path[i].ct][path[i].tokenId].openPrice > 0){
                filtedPath[j] = path[i];
                j++;
            }
        }
        return filtedPath;
    }
    // get user's offers
    function getOffers() public view returns (Path[] memory _filtedPath) {
        Path[] memory path = myOffers[msg.sender];
        uint256 resultCount;

        for (uint i = 0; i < path.length; i++){
            if (offers[msg.sender][path[i].ct][path[i].tokenId].offersPrice > 0){
                resultCount++;
            }
        }
        
        Path[] memory filtedPath = new Path[](resultCount);
        uint256 j;
        
        for (uint i = 0; i < path.length; i++){
            if (offers[msg.sender][path[i].ct][path[i].tokenId].offersPrice > 0){
                filtedPath[j] = path[i];
                j++;
            }
        }
        return filtedPath;
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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