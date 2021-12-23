// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "./interfaces/IRadNFTMarket.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title RAD NFT Market
 *
 * @notice A RAD non-fungible token market contract that includes the following functionality:
 *
 *  - A NFT owner can put a NFT up for sale in this market at the desired price in Wei. (A NFT must be allowed to move
 *    for this contract by either `approve` or `setApprovalForAll` (ERC721)).
 *  - All NFTs added for sale are listed. The complete list can be obtained by calling `getTokenList` function. It is
 *    possible to use `tokenMarketIDs` mapping to check for the presence of a specific NFT.
 *  - A NFT owner can set a new price with `setPrice` and refund his NFT by calling `refund` function.
 *  - A user can purchase the listed NFTs. If a user has sent more ETH than necessary for purchasing, the balance more
 *    than `DUST` will be refunded.
 *
 * @dev Warning. This contract is not intended for inheritance. In case of inheritance, it is recommended to change
 * the access of all storage variables, except `DUST`, from public to private in order to avoid violating
 * the integrity of the storage. In addition, you will need to add functions for them to get values.
 */
contract RadNFTMarket is IRadNFTMarket, Context {
    using Address for address payable;
    using Counters for Counters.Counter;

    /**
     * Storage
     */
    /// @notice If a user has sent more ETH than necessary when purchasing a NFT on this market, the balance more
    /// than `DUST` will be refunded
    uint256 public constant DUST = 1e12; // 10 ** 12

    /// @dev (Number of offers for sale for all time) - 1
    Counters.Counter public newTokenMarketID;

    /// @notice Can be used to verify the availability of the NFT in this market (0 means no)
    /// @dev A zero value means that the token is not for sale in this market
    /// collection => (token ID => token ID in this market)
    mapping(address => mapping(uint256 => uint256)) public tokenMarketIDs;

    /// @notice Can be used to get the address of the NFT owner (access by ID from `tokenMarketIDs`)
    /// @dev token ID in this market => owner
    mapping(uint256 => address) public tokenOwners;

    /// @notice Can be used to get the current price of the NFT (access by ID from `tokenMarketIDs`)
    /// @dev token ID in this market => price in Wei
    mapping(uint256 => uint256) public tokenPrices;

    /// @notice Can be used to get the NFT position in `tokenList` (access by ID from `tokenMarketIDs`)
    /// @dev In order to know the position of the token in the array and not iterate over it
    /// ! Position of the value in the `tokenList` array, plus 1 because index 0 means a value is not in the mapping
    /// token ID in this market => (token position in the array) + 1
    mapping(uint256 => uint256) public tokenListPoses;

    /// @notice Can be used to obtain info about the NFT in an aggregated form (access by a position from
    /// `tokenListPoses`).
    /// @dev List of all NFTs that are in this market at the moment
    NFT[] public tokenList;

    /**
     * Events
     */
    /// @notice Emitted when `_tokenID` from `_collection` was put up for sale for `_price` (in Wei) on this market
    /// @param _collection ERC721 contract address that NFT belong to
    /// @param _tokenID NFT ID on its ERC721 contract
    /// @param _price NFT price (in Wei) on this market contract (> 0)
    event PutOnSale(address indexed _collection, uint256 indexed _tokenID, uint256 _price);

    /// @notice Emitted when the NFT owner withdrew `_tokenID` from `_collection` from sale
    /// @param _collection ERC721 contract address that NFT belong to
    /// @param _tokenID NFT ID on its ERC721 contract
    event Refunded(address indexed _collection, uint256 indexed _tokenID);

    /// @notice Emitted when `_tokenID` from `_collection` was purchased for `_price` (in Wei)
    /// @param _collection ERC721 contract address that NFT belong to
    /// @param _tokenID NFT ID on its ERC721 contract
    /// @param _price NFT price (in Wei) on this market contract (> 0)
    event Purchased(address indexed _collection, uint256 indexed _tokenID, uint256 _price);

    /// @notice Emitted when the NFT owner has set the new price at `_price` (in Wei) for `_tokenID` from `_collection`
    /// @param _collection ERC721 contract address that NFT belong to
    /// @param _tokenID NFT ID on its ERC721 contract
    /// @param _price NFT price (in Wei) on this market contract (> 0)
    event PriceSet(address indexed _collection, uint256 indexed _tokenID, uint256 _price);

    /**
     * Constructor
     */
    constructor() {
        newTokenMarketID.increment(); // Because the zero is used for NFTs that are not offered for sale in this market
    }

    /**
     * Modifiers
     */
    /// @dev Checking that the collection address is not null
    /// @param _collection ERC721 contract address that NFT belong to
    modifier nonNullCollectionAddr(address _collection) {
        require(_collection != address(0), "Collection address must not be null");
        _;
    }

    /// @dev Checking for a non-zero NFT price
    /// @param _price NFT price (in Wei) on this market contract (> 0)
    modifier nonzeroPrice(uint256 _price) {
        require(_price != 0, "Zero price of NFT");
        _;
    }

    /**
     * External functions
     */
    /// @notice Putting an NFT up for sale in this market
    /// Requirements:
    /// - A `_collection` must not be the null address.
    /// - A `_price` must not be zero.
    /// - The NFT must not be for sale in this market at the moment.
    /// - The `_tokenID` must exist in the `_collection` and be owned by the caller and be allowed to move for this
    ///   contract by either `approve` or `setApprovalForAll` (ERC721).
    /// @param _collection ERC721 contract address that NFT belong to
    /// @param _tokenID NFT ID on its ERC721 contract
    /// @param _price NFT price (in Wei) on this market contract (> 0)
    function putOnSale(
        address _collection,
        uint256 _tokenID,
        uint256 _price
    ) external nonNullCollectionAddr(_collection) nonzeroPrice(_price) {
        require(tokenMarketIDs[_collection][_tokenID] == 0, "Already for sale in this market");

        uint256 tokenMarketID = newTokenMarketID.current();
        tokenMarketIDs[_collection][_tokenID] = tokenMarketID;
        tokenPrices[tokenMarketID] = _price;
        tokenListPoses[tokenMarketID] = tokenList.length + 1; // + 1, see `tokenListPoses` mapping description
        tokenList.push(NFT(_collection, _tokenID, _price));

        newTokenMarketID.increment();

        // It is here, because of Checks-Effects-Interactions Pattern (see Solitity docs)
        tokenOwners[tokenMarketID] = IERC721(_collection).ownerOf(_tokenID);

        IERC721(_collection).transferFrom(_msgSender(), address(this), _tokenID);
        emit PutOnSale(_collection, _tokenID, _price);
    }

    /// @notice Refund of the NFT to its owner
    /// Requirements:
    /// - A `_collection` must not be the null address.
    /// - The NFT must be offered for sale in this market.
    /// - The caller should be the owner of the NFT.
    /// @param _collection ERC721 contract address that NFT belong to
    /// @param _tokenID NFT ID on its ERC721 contract
    function refund(address _collection, uint256 _tokenID) external nonNullCollectionAddr(_collection) {
        uint256 tokenMarketID = tokenMarketIDs[_collection][_tokenID];
        require(tokenMarketID != 0, "Unknown token");
        require(_msgSender() == tokenOwners[tokenMarketID], "Only NFT owner can refund");

        _removeToken(_collection, _tokenID);

        IERC721(_collection).safeTransferFrom(address(this), _msgSender(), _tokenID);
        emit Refunded(_collection, _tokenID);
    }

    /// @notice Purchase of the NFT at the specified price
    /// Requirements:
    /// - The NFT must be offered for sale in this market.
    /// - A sufficient amount of ETH must be transferred when calling.
    /// @notice If a caller has sent more ETH than necessary for purchasing, the balance more than `DUST` (1e12) will
    /// be refunded.
    /// @param _collection ERC721 contract address that NFT belong to
    /// @param _tokenID NFT ID on its ERC721 contract
    function purchase(address _collection, uint256 _tokenID) external payable {
        uint256 tokenMarketID = tokenMarketIDs[_collection][_tokenID];
        require(tokenMarketID != 0, "Unknown token");
        require(msg.value >= tokenPrices[tokenMarketID], "Not enough ETH");

        // Saving values for transfer ETH to the NFT owner. For Checks-Effects-Interactions Pattern (see Solitity docs)
        address payable tokenOwner = payable(tokenOwners[tokenMarketID]);
        uint256 tokenPrice = tokenPrices[tokenMarketID];

        _removeToken(_collection, _tokenID);

        IERC721(_collection).safeTransferFrom(address(this), _msgSender(), _tokenID);
        emit Purchased(_collection, _tokenID, tokenPrice);

        // Transfer ETH to the NFT owner
        tokenOwner.sendValue(tokenPrice);

        // Transfer a change to the caller. The change should be equal to `msg.value - tokenPrice` or a little more
        // because of the dust from the previous purchases
        uint256 change = address(this).balance;
        if (change > DUST) payable(_msgSender()).sendValue(change);
    }

    /// @notice Setting a new price for an NFT on this market
    /// Requirements:
    /// - A `_collection` must not be the null address.
    /// - A `_price` must not be zero.
    /// - The NFT must be offered for sale in this market.
    /// - The caller should be the owner of the NFT.
    /// @param _collection ERC721 contract address that NFT belong to
    /// @param _tokenID NFT ID on its ERC721 contract
    /// @param _price NFT price (in Wei) on this market contract (> 0)
    function setPrice(
        address _collection,
        uint256 _tokenID,
        uint256 _price
    ) external nonNullCollectionAddr(_collection) nonzeroPrice(_price) {
        uint256 tokenMarketID = tokenMarketIDs[_collection][_tokenID];
        require(tokenMarketID != 0, "Unknown token");
        require(_msgSender() == tokenOwners[tokenMarketID], "Only NFT owner can refund");

        tokenPrices[tokenMarketID] = _price;
        uint256 tokenListPos = tokenListPoses[tokenMarketID] - 1; // - 1, see `tokenListPoses`
        tokenList[tokenListPos].price = _price;
        emit PriceSet(_collection, _tokenID, _price);
    }

    /// @notice Returning a list of all NFTs in this market
    /// @return An array of all tokens
    function getTokenList() external view returns (NFT[] memory) {
        return tokenList;
    }

    /**
     * Private functions
     */
    /// @dev Deletion of the purchased NFT from this market
    /// @param _collection ERC721 contract address that NFT belong to
    /// @param _tokenID NFT ID on its ERC721 contract
    function _removeToken(address _collection, uint256 _tokenID) private {
        uint256 tokenMarketID = tokenMarketIDs[_collection][_tokenID];
        delete tokenMarketIDs[_collection][_tokenID]; // Reset the token market ID
        delete tokenOwners[tokenMarketID];
        delete tokenPrices[tokenMarketID];

        // Deletion of the purchased NFT from the array and writing down the position in the `tokenListPoses` mapping
        // Current position of the token in the `tokenList` array
        uint256 tokenListPos = tokenListPoses[tokenMarketID] - 1; // - 1, see `tokenListPoses` mapping description
        // Replacing the deleted element with the last one
        tokenList[tokenListPos] = tokenList[tokenList.length - 1];
        NFT storage elem = tokenList[tokenListPos];
        // Writing down the new position of the "last" element
        tokenListPoses[tokenMarketIDs[elem.collection][elem.tokenID]] = tokenListPos + 1; // + 1, see `tokenListPoses`
        tokenList.pop(); // Cutting off the last element

        delete tokenListPoses[tokenMarketID]; // Reset the list position of the purchased token
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

/**
 * @dev Required interface of an RadNFTMarket compliant contract.
 */
interface IRadNFTMarket {
    /// @notice Token data
    /// @dev It is used to store the token in the array, which uses to output the list of all the NFTs offered for sale
    struct NFT {
        address collection; // ERC721 contract address that NFT belong to
        uint256 tokenID; // NFT ID on its ERC721 contract
        uint256 price; // NFT price (in ETH) on this market contract
    }

    /**
     * Functions
     */
    function putOnSale(
        address _collection,
        uint256 _tokenID,
        uint256 _price
    ) external;

    function refund(address _collection, uint256 _tokenID) external;

    function purchase(address _collection, uint256 _tokenID) external payable;

    function setPrice(
        address _collection,
        uint256 _tokenID,
        uint256 _price
    ) external;

    /**
     * View functions
     */
    function getTokenList() external view returns (NFT[] memory);

    function tokenMarketIDs(address _collection, uint256 _tokenID) external view returns (uint256);

    function tokenOwners(uint256 _tokenMarketID) external view returns (address);

    function tokenPrices(uint256 _tokenMarketID) external view returns (uint256);

    // Returns (token position in the array) + 1
    function tokenListPoses(uint256 _tokenMarketID) external view returns (uint256);

    function tokenList(uint256 _pos)
        external
        view
        returns (
            address,
            uint256,
            uint256
        );

    function DUST() external view returns (uint256);

    function newTokenMarketID() external view returns (uint256);
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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