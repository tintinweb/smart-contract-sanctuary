// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract qMarket is PausableUpgradeable, OwnableUpgradeable {
  function initialize() public initializer {
    __Ownable_init();
  }
  using AddressUpgradeable for address;

  struct MarketItem {
    bytes32 item_id; // market item id
    uint256 token_id; // nft token id
    address token_address; // nft erc721 address
    address owner_of; // nft owner
    uint256 askingPrice; // asking price in wei
    uint256 expiresAt; // time in hours when sale end
  }

  mapping (address => mapping(uint256 => MarketItem)) public marketItemByTokenId; // store MarketItems by address>id

  bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd; // ERC721 standard
  bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a; // NFT Royalty Standard ERC2981

  event ItemAdded(bytes32 item_id, uint256 token_id, address token_address, address owner_of, uint256 askingPrice, uint256 expiresAt);
  event ItemRemoved(bytes32 item_id, uint256 token_id, address token_address, address owner_of);
  event ItemSold(bytes32 item_id, uint256 token_id, address token_address, address seller, uint256 price, address buyer, uint256 royaltiesPaid, address royaltiesReceiver);

  // verify owner
  modifier OnlyItemHolder(uint256 token_id, address token_address){
    require(IERC721Upgradeable(token_address).ownerOf(token_id) == msg.sender);
    _;
  }

  // verify transfer approval
  modifier hasTransferApproval(uint256 token_id, address token_address){
    require(IERC721Upgradeable(token_address).getApproved(token_id) == address(this));
    _;
  }

  // verify the item exists on the market
  modifier ItemExists(uint256 token_id, address token_address){
    MarketItem memory item = marketItemByTokenId[token_address][token_id];
    require(item.item_id != 0, "Item is not listed");
    _;
  }

  // verify the item does not exist on the market
  modifier ItemNotExists(uint256 token_id, address token_address){
    MarketItem memory item = marketItemByTokenId[token_address][token_id];
    require(item.item_id == 0, "Item is already listed");
    _;
  }

  // verify the token_address is a contract and ERC721 compatible
  modifier CompatibleERC721(address token_address) {
    require(token_address.isContract(), "The NFT Address should be a contract");
    require(
      IERC721Upgradeable(token_address).supportsInterface(_INTERFACE_ID_ERC721),
      "The NFT contract has an invalid ERC721 implementation"
    );
    _;
  }

  /**
    * @dev Adds a new item to the market
    * @param token_address - nft erc721 address
    * @param token_id - nft token id
    * @param askingPrice - asking price in wei
    * @param expiresAt - time in hours when sale end
    */
  function addItemToMarket(
    address token_address,
    uint256 token_id,
    uint256 askingPrice,
    uint256 expiresAt
  )
    public
    whenNotPaused
    CompatibleERC721(token_address)
    ItemNotExists(token_id,token_address)
    OnlyItemHolder(token_id,token_address)
    hasTransferApproval(token_id,token_address)
  {
    _addItemToMarket(
      token_address,
      token_id,
      askingPrice,
      expiresAt
    );
  }

  /**
    * @dev Remove a listed item from the market
    *  can only be removed by owner_of or the contract owner
    * @param token_address - nft erc721 address
    * @param token_id - nft token id
    */
  function removeItemFromMarket(
    address token_address,
    uint256 token_id
  )
    public
    whenNotPaused
    CompatibleERC721(token_address)
    ItemExists(token_id,token_address)
  {
    _removeItemFromMarket(token_address, token_id);
  }

  /**
    * @dev Executes a buy order for listed NFT
    * @param token_address - Address of the NFT registry
    * @param token_id - ID of the published NFT
    * @param price - Order price
    */
  function buyItem(
    address token_address,
    uint256 token_id,
    uint256 price
  )
    whenNotPaused
    CompatibleERC721(token_address)
    ItemExists(token_id,token_address)
    public
    payable
  {
    _buyItem(
      token_address,
      token_id,
      price
    );
  }

  /**
    * @dev Adds a new item to the market
    * @param token_address - nft erc721 address
    * @param token_id - nft token id
    * @param askingPrice - asking price in wei
    * @param expiresAt - time in hours when sale end
    */
  function _addItemToMarket(
    address token_address,
    uint256 token_id,
    uint256 askingPrice,
    uint256 expiresAt
  ) 
    internal
  {
    require(askingPrice > 0, "Price should be greater than 0");
    if (expiresAt != 0) require(expiresAt > block.timestamp + 1 minutes, "Listing should be more than 1 minute in the future");
    address owner_of = IERC721Upgradeable(token_address).ownerOf(token_id);
    bytes32 item_id = keccak256(
      abi.encodePacked(
        block.timestamp,
        owner_of,
        token_id,
        token_address,
        askingPrice
      )
    );
    marketItemByTokenId[token_address][token_id] = MarketItem({
      item_id: item_id,
      token_id: token_id,
      token_address: token_address,
      owner_of: owner_of,
      askingPrice: askingPrice,
      expiresAt: expiresAt
    });


    emit ItemAdded(
      item_id,
      token_id,
      token_address,
      owner_of,
      askingPrice,
      expiresAt
    );
  }

  /**
    * @dev Remove a listed item from the market
    *  can only be removed by owner_of the item or owner() of this contract
    * @param token_address - nft erc721 address
    * @param token_id - nft token id
    */
  function _removeItemFromMarket(
    address token_address, uint256 token_id
  )
    internal
    returns (MarketItem memory)
  {
    address sender = _msgSender();
    require(IERC721Upgradeable(token_address).ownerOf(token_id) == sender || sender == owner(), "You are not the owner");
    MarketItem memory item = marketItemByTokenId[token_address][token_id];
    require(item.item_id != 0, "Item not listed");
    require(item.owner_of == sender || sender == owner(), "Unauthorized");

    bytes32 item_id = item.item_id;
    address owner_of = item.owner_of;
    delete marketItemByTokenId[token_address][token_id];

    emit ItemRemoved(
      item_id,
      token_id,
      token_address,
      owner_of
    );

    return item;
  }

  /**
    * @dev Executes a buy order for listed NFT
    * @param token_address - Address of the NFT registry
    * @param token_id - ID of the published NFT
    * @param price - Order price
    */
  function _buyItem(
    address token_address,
    uint256 token_id,
    uint256 price
  )
    internal returns (MarketItem memory)
  {
    address owner_of = IERC721Upgradeable(token_address).ownerOf(token_id);

    address buyer = _msgSender();

    MarketItem memory item = marketItemByTokenId[token_address][token_id];
    require(item.item_id != 0, "Item not listed");

    address payable seller = payable(item.owner_of);
    require(msg.value >= item.askingPrice, "Not enough funds sent");
    require(seller == owner_of, "You are not the owner of this item");

    require(seller != address(0), "Invalid address");
    require(seller != buyer, "You cannot buy from yourself");
    require(item.askingPrice == price, "The price is not correct");
    if (item.expiresAt != 0) require(block.timestamp < item.expiresAt, "The listing expired");
    require(seller == IERC721Upgradeable(token_address).ownerOf(token_id), "The seller is no longer the owner");

    uint256 royaltiesPaid = 0;
    address payable royaltiesReceiver;
    if (checkRoyalties(item.token_address)) {
      // contract supports ERC2981 Royalties
      (address recipient, uint256 royalty1) = getRoyalties(item.token_id, item.token_address, msg.value);
      // transfer value to seller
      seller.transfer(msg.value-royalty1);
      // transfer value to royalty receiver
      royaltiesReceiver = payable(recipient);
      royaltiesReceiver.transfer(royalty1);
      royaltiesPaid = royalty1;
    } else {
      // no royalties transfer value to seller
      seller.transfer(msg.value);
    }

    bytes32 item_id = item.item_id;
    delete marketItemByTokenId[token_address][token_id];

    // transfer nft token to new owner
    IERC721Upgradeable(token_address).safeTransferFrom(
      seller,
      buyer,
      token_id
    );

    emit ItemSold(
      item_id,
      token_id,
      token_address,
      seller,
      price,
      buyer,
      royaltiesPaid,
      royaltiesReceiver
    );
    return item;
  }

  function checkRoyalties(address _contract) internal view returns (bool) {
      (bool success) = IERC721Upgradeable(_contract).supportsInterface(_INTERFACE_ID_ERC2981);
      return success;
  }

  function getRoyalties(uint256 token_id, address token_address, uint256 _salePrice) internal view returns (address, uint256) {
      return IERC2981(token_address).royaltyInfo(token_id, _salePrice);
  }

  function getMarketItem(uint256 token_id, address token_address) external view returns (address) {
    MarketItem memory item = marketItemByTokenId[token_address][token_id];
    require(item.item_id != 0, "Item is not listed");
    return item.owner_of;
  }

  // pause all market transactions
  function pause() public virtual onlyOwner {
    _pause();
  }

  // unpause all market transactions
  function unpause() public virtual onlyOwner {
    _unpause();
  }

}

///
/// @dev Interface for the NFT Royalty Standard
///
interface IERC2981 is IERC165Upgradeable {
    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _token_id - the NFT asset queried for royalty information
    /// @param _salePrice - the sale price of the NFT asset specified by _token_id
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _salePrice
    function royaltyInfo(
        uint256 _token_id,
        uint256 _salePrice
    ) external view returns (
        address receiver,
        uint256 royaltyAmount
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
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
        return msg.data;
    }
    uint256[50] private __gap;
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

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}