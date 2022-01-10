// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./Governable.sol";
import "./interface/IERC721Enhanced.sol";
import "./interface/IMarketplaceManager.sol";
import "./interface/IRegistry.sol";

/**
 * @title MarketplaceManager
 * @author softtech
 * @notice Isbank marketplace manager to manage nft market items.
*/
contract MarketplaceManager is IMarketplaceManager, Governable, ReentrancyGuard {
    using Address for address;
    using Counters for Counters.Counter;

    /***************************************
    STATE VARIABLES
    ***************************************/

    /// @notice The registry contract.
    IRegistry public registry;

    /// @notice Defines whether or not to create new tokens.
    bool public paused;

    /// @notice The total marketplace item count.
    Counters.Counter public marketItemCount;

    /// @notice The market items.
    mapping(uint256 => MarketItem) private _marketItems;

    /***************************************
    MODIFIERS
    ***************************************/

    modifier whileNotPaused() {
        require(!paused, "paused!");
        _;
    }

    /**
     * @notice The constructor that constructs the marketplace manager.
     * @param _governance The governor address.
     * @param _registry   The registry contract address.
    */
    constructor(address _governance, address _registry) Governable(_governance) {
        require(_registry != address(0x0), "zero address registry");
        registry = IRegistry(_registry);
        require(registry.getToken() != address(0x0), "zero address token");
    }

    /***************************************
    MUTUATOR FUNCTIONS
    ***************************************/

    /**
     * @notice Creates a new market for given token id.
     * @param tokenId The token id to create market item from.
     * @param price The market item price in `wei`.
     * @return itemId The id of the market item.
    */
    function createMarketItem(uint256 tokenId, uint256 price) external override whileNotPaused nonReentrant returns (uint256 itemId) {
        require(IERC721Enhanced(registry.getToken()).exists(tokenId), "invalid token");
        require(IERC721Enhanced(registry.getToken()).ownerOf(tokenId) == msg.sender, "invalid owner");
        require(_marketItems[tokenId].id == 0, "already exists");

        marketItemCount.increment();
        uint256 id = marketItemCount.current();
        _marketItems[id] = MarketItem(
            id,
            tokenId,
            block.timestamp,
            price
        );
        emit MarketItemCreated(id);
        return id;
    }

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice Information about a market item.
     * @param marketItemId The market item id to return info.
     * @return id The market item id.
     * @return tokenId The market item token's id.
     * @return timestamp The market item's created time.
     * @return price The market item price.
    */
    function getMarketItemInfo(uint256 marketItemId) external view override returns (uint256 id, uint256 tokenId, uint256 timestamp, uint256 price) {
        MarketItem memory item = _marketItems[marketItemId];
        return (item.id, item.tokenId, item.timestamp, item.price);
    }

    /***************************************
    GOVERNANCE FUNCTIONS
    ***************************************/

    /**
     * @notice Sets the [`Registry`](./Registry) contract address.
     * Can only be called by the current governor.
     * @param _registry The address of `Registry` contract.
    */
    function setRegistry(address _registry) external override onlyGovernance {
        require(_registry != address(0x0), "zero address registry");
        registry = IRegistry(_registry);
        emit RegistrySet(_registry);
    }

    /**
     * @notice Pauses or unpauses for creating new tokens..
     * Can only be called by the current governor..
     * @param _paused True to pause, false to unpause.
    */
    function setPaused(bool _paused) external override onlyGovernance {
        paused = _paused;
        emit PauseSet(_paused);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
     * by making the `nonReentrant` function external, and making it call a
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./interface/IGovernable.sol";

/**
 * @title Governable
 * @author softtech
 * @notice Enforces access control for importan functions to governor.
*/
contract Governable is IGovernable {

    /***************************************
    STATE VARIABLES
    ***************************************/
    
    /// @notice governor.
    address private _governance;

    /// @notice governance to take over
    address private _pendingGovernance;

    /// @notice governance locking status.
    bool private _locked;

    /***************************************
    MODIFIERS
    ***************************************/

    /** 
     * Can only be called by governor.
     * Can only be called while unlocked.
    */
    modifier onlyGovernance() {
        require(!_locked, "governance locked");
        require(msg.sender == _governance, "!governance");
        _;
    }

    /** 
     * Can only be called by pending governor.
     * Can only be called while unlocked.
    */
    modifier onlyPendingGovernance() {
        require(!_locked, "governance locked");
        require(msg.sender == _pendingGovernance, "!pending governance");
        _;
    }

    /**
     * @notice Contructs the governable constract.
     * @param governance The address of the governor.
    */
    constructor(address governance) {
        require(governance != address(0x0), "zero address governance");
        _governance = governance;
        _pendingGovernance = address(0x0);
        _locked = false;
    }

    /***************************************
    MUTATOR FUNCTIONS
    ***************************************/

    /**
     * @notice Initiates transfer of the governance role to a new governor.
     * Transfer is not complete until the new governor accepts the role.
     * Can only be called by the current governance.
     * @param pendingGovernance The new governor.
    */
    function setPendingGovernance(address pendingGovernance) external override onlyGovernance {
        _pendingGovernance = pendingGovernance;
        emit GovernancePending(pendingGovernance);
    }

    /**
     * @notice Accepts the governance role.
     * Can only be called by the new governor.
    */
    function acceptGovernance() external override onlyPendingGovernance {
        require(_pendingGovernance != address(0x0), "zero governance");
        address oldGovernance = _governance;
        _governance = _pendingGovernance;
        _pendingGovernance = address(0x0);
        emit GovernanceTransferred(oldGovernance, _governance);
    }

    /**
     * @notice Permanently locks this contracts's governance role and any of its functions that require the role.
     * This action cannot be reversed. Think twice before calling it.
     * Can only be called by the current governor.
    */
    function lockGovernance() external override onlyGovernance {
        _locked = true;
        _governance = address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);
        _pendingGovernance = address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);
        emit GovernanceTransferred(msg.sender, address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF));
        emit GovernanceLocked();
    }

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice Returns current address of the current governor.
     * @return governor The current governor address.
    */
    function getGovernance() external view override returns (address) {
        return _governance;
    }

    /**
     * @notice Returns the address of the pending governor.
     * @return pendingGovernor The address of the pending governor.
    */
    function getPendingGovernance() external view override returns (address) {
        return _pendingGovernance;
    }

    /**
     * @notice Returns true if the governance is locked.
     * @return status True if the governance is locked.
    */
    function governanceIsLocked() external view override returns (bool) {
        return _locked;
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later
// code borrowed from OpenZeppelin and @uniswap/v3-periphery
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

/**
 * @title ERC721Enhanced
 * @author softtech
 * @notice An extension of `ERC721`.
 * @dev The base is OpenZeppelin's `ERC721Enumerable` which also includes the `Metadata` extension. This extension includes simpler transfers, gasless approvals, and better enumeration.
 */
interface IERC721Enhanced is IERC721Enumerable {

    /***************************************
    SIMPLER TRANSFERS
    ***************************************/

    /**
     * @notice Transfers `tokenID` from `msg.sender` to `to`.
     * @dev This was excluded from the official `ERC721` standard in favor of `transferFrom(address from, address to, uint256 tokenID)`. We elect to include it.
     * @param to The receipient of the token.
     * @param tokenID The token to transfer.
     */
    function transfer(address to, uint256 tokenID) external;

    /**
     * @notice Safely transfers `tokenID` from `msg.sender` to `to`.
     * @dev This was excluded from the official `ERC721` standard in favor of `safeTransferFrom(address from, address to, uint256 tokenID)`. We elect to include it.
     * @param to The receipient of the token.
     * @param tokenID The token to transfer.
     */
    function safeTransfer(address to, uint256 tokenID) external;

    /***************************************
    GASLESS APPROVALS
    ***************************************/

    /**
     * @notice Approve of a specific `tokenID` for spending by `spender` via signature.
     * @param spender The account that is being approved.
     * @param tokenID The ID of the token that is being approved for spending.
     * @param deadline The deadline timestamp by which the call must be mined for the approve to work.
     * @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`.
     * @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`.
     * @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`.
     */
    function permit(
        address spender,
        uint256 tokenID,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @notice Returns the current nonce for `tokenID`. This value must be
     * included whenever a signature is generated for `permit`.
     * Every successful call to `permit` increases ``tokenID``'s nonce by one. This
     * prevents a signature from being used multiple times.
     * @param tokenID ID of the token to request nonce.
     * @return nonce Nonce of the token.
     */
    function nonces(uint256 tokenID) external view returns (uint256 nonce);

    /**
     * @notice The permit typehash used in the `permit` signature.
     * @return typehash The typehash for the `permit`.
     */
    // solhint-disable-next-line func-name-mixedcase
    function PERMIT_TYPEHASH() external view returns (bytes32 typehash);

    /**
     * @notice The domain separator used in the encoding of the signature for `permit`, as defined by `EIP712`.
     * @return seperator The domain seperator for `permit`.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32 seperator);

    /***************************************
    BETTER ENUMERATION
    ***************************************/

    /**
     * @notice Lists all tokens.
     * Order not specified.
     * @dev This function is more useful off chain than on chain.
     * @return tokenIDs The list of token IDs.
     */
    function listTokens() external view returns (uint256[] memory tokenIDs);

    /**
     * @notice Lists the tokens owned by `owner`.
     * Order not specified.
     * @dev This function is more useful off chain than on chain.
     * @return tokenIDs The list of token IDs.
     */
    function listTokensOfOwner(address owner) external view returns (uint256[] memory tokenIDs);

    /**
     * @notice Determines if a token exists or not.
     * @param tokenID The ID of the token to query.
     * @return status True if the token exists, false if it doesn't.
     */
    function exists(uint256 tokenID) external view returns (bool status);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

/**
 * @title MarketplaceManager
 * @author softtech
 * @notice The interface for the marketplace manager.
*/
interface IMarketplaceManager {

    /***************************************
    STRUCTS
    ***************************************/

    /// @notice Market item object.
    struct MarketItem {
        uint256 id;
        uint256 tokenId;
        uint256 timestamp;
        uint256 price;
    }

    /***************************************
    EVENTS
    ***************************************/

    /// @notice Emitted when a market item is created.
    event MarketItemCreated(uint256 id);

    /// @notice Emitted when registry address is set.
    event RegistrySet(address registry);

    /// @notice Emitted when pause is set.
    event PauseSet(bool paused);

    /***************************************
    MUTUATOR FUNCTIONS
    ***************************************/

    /**
     * @notice Creates a new market for given token id.
     * @param tokenId The token id to create market item from.
     * @param price The market item price in `wei`.
     * @return itemId The id of the market item.
    */
    function createMarketItem(uint256 tokenId, uint256 price) external returns (uint256 itemId);

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice Information about a market item.
     * @param marketItemId The market item id to return info.
     * @return id The market item id.
     * @return tokenId The market item token's id.
     * @return timestamp The market item's created time.
     * @return price The market item price.
    */
    function getMarketItemInfo(uint256 marketItemId) external view returns (uint256 id, uint256 tokenId, uint256 timestamp, uint256 price);


    /***************************************
    GOVERNANCE FUNCTIONS
    ***************************************/

    /**
     * @notice Sets the [`Registry`](./Registry) contract address.
     * Can only be called by the current governor.
     * @param registry The address of `Registry` contract.
    */
    function setRegistry(address registry) external;

    /**
     * @notice Pauses or unpauses for creating new tokens..
     * Can only be called by the current governor..
     * @param paused True to pause, false to unpause.
    */
    function setPaused(bool paused) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

/**
 * @title IRegistry
 * @author softtech
 * @notice Tracks the contracts of the Is marketplace.
*/
interface IRegistry {

    /***************************************
    EVENTS
    ***************************************/

    /// @notice Emitted when Is NFT token is set.
    event TokenSet(address token);
    
    /// @notice Emitted when Marketplace manager is set.
    event MarketplaceManagerSet(address marketplace);

    /***************************************
    GOVERNANCE FUNCTIONS
    ***************************************/
    
    /**
     * @notice Sets the Is NFT marketplace token.
     * @param token The address of the [`Is NFT Token`](../Token) contract.
    */
    function setToken(address token) external;

    /**
     * @notice Sets the marketplace manager.
     * @param marketplace The address of the [`Marketplace Manager`](../MarketplaceManager) contract.
    */
    function setMarketplaceManager(address marketplace) external;

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice Gets the [`Is NFT Token`](../Token) contract.
     * @return token The address of the [`Is NFT Token`](../Token).
    */
    function getToken() external view returns (address token);

    /**
     * @notice Returns the [`Marketplace Manager`](../MarketplaceManager) contract.
     * @return marketplace The address of the marketplace manager contract.
    */
    function getMarketplaceManager() external view returns (address marketplace);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;


/**
 * @title IGovernable
 * @author softtech
 * @notice Enforces access control for important functions to governance.
*/
interface IGovernable {

    /***************************************
    EVENTS
    ***************************************/

    /// @notice Emitted when pending Governance is set.
    event GovernancePending(address pendingGovernance);

    /// @notice Emitted when Governance is set.
    event GovernanceTransferred(address oldGovernance, address newGovernance);

    /// @notice Emitted when Governance is locked.
    event GovernanceLocked();

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice Returns current address of the current governor.
     * @return governor The current governor address.
    */
    function getGovernance() external view returns (address governor);

    /**
     * @notice Returns the address of the pending governor.
     * @return pendingGovernor The address of the pending governor.
    */
    function getPendingGovernance() external view returns (address pendingGovernor);

    /**
     * @notice Returns true if the governance is locked.
     * @return status True if the governance is locked.
    */
    function governanceIsLocked() external view returns (bool status);

    /***************************************
    MUTATOR FUNCTIONS
    ***************************************/

    /**
     * @notice Initiates transfer of the governance role to a new governor.
     * Transfer is not complete until the new governor accepts the role.
     * Can only be called by the current governance.
     * @param pendingGovernance The new governor.
    */
    function setPendingGovernance(address pendingGovernance) external;

    /**
     * @notice Accepts the governance role.
     * Can only be called by the new governor.
    */
    function acceptGovernance() external;

    /**
     * @notice Permanently locks this contracts's governance role and any of its functions that require the role.
     * This action cannot be reversed. Think twice before calling it.
     * Can only be called by the current governor.
    */
    function lockGovernance() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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