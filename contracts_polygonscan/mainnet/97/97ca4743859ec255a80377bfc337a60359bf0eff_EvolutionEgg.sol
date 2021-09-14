/**
 *Submitted for verification at polygonscan.com on 2021-09-14
*/

pragma solidity 0.8.6;


// SPDX-License-Identifier: MIT
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

    constructor () {
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


// solhint-disable-next-line compiler-version
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


interface ITinyHeroNFT is IERC721 {
    function getStats(uint256 tokenId) external view returns (uint16[] memory pvpStats);

    function totalBurned() external view returns (uint256);

    function exists(uint256 tokenId) external view returns (bool);

    function burn(uint256 tokenId) external;
}


interface IEggStats {
    enum EggRarity {
        COMMON,
        RARE,
        EPIC
    }

    enum EggType {
        STRENGTH,
        AGILITY,
        INTELLIGENCE
    }
    struct EggInfo {
        EggRarity Rarity;
        EggType Type;
        uint16 Luck;
    }

    /**
     * @dev Returns game info.
     */
    function info() external view returns (uint256 totalSupply, uint256 totalBurned);

    /**
     * @dev Returns TinyHero stats from the token ID
     */
    function stats(uint256 tokenId) external view returns (EggInfo memory eggStats);

    /**
     * @dev Returns TinyHero card details from the token ID
     */
    function details(uint256 tokenId) external view returns (EggInfo memory info);

    /**
     * @dev Returns expected price (in TINY) from the token ID
     */
    function expectedPrice(uint256 tokenId) external view returns (uint256);

    function setInfo(uint256 tokenId, EggInfo memory newInfo) external;
}


interface IEggNFT is IERC721 {
    function getInfos(uint256 tokenId) external view returns (IEggStats.EggInfo memory eggStats);

    function totalBurned() external view returns (uint256);

    function exists(uint256 tokenId) external view returns (bool);

    function burn(uint256 tokenId) external;
}


interface ITinyHeroStats {
     enum TinyRarity {
        COMMON,
        RARE,
        EPIC
    }

    enum TinyType {
        STRENGTH,
        AGILITY,
        INTELLIGENCE
    }

    struct TinyInfo {
        string Name;
        uint16 Level;
        TinyRarity Rarity;
        TinyType Type;
    }

    struct TinyAttribute {
        uint16 Strength;
        uint16 Agility;
        uint16 Intelligence;
        uint16 HP;
        uint16 Armor;
        uint16 Mana;
        uint16 Atk;
        uint16 Exp;
        uint16 Skills;
        uint16 Productivity;
    }

    /**
     * @dev Returns game info.
     */
    function info() external view returns (uint256 totalSupply, uint256 totalBurned, uint256 totalFusion, uint256[] memory otherInfo);

    /**
     * @dev Returns TinyHero stats from the token ID
     */
    function stats(uint256 tokenId) external view returns (uint16[] memory pvpStats);

    /**
     * @dev Returns TinyHero card details from the token ID
     */
    function details(uint256 tokenId) external view returns (TinyInfo memory info, TinyAttribute memory attribute);

    /**
     * @dev Returns expected price (in TINY) from the token ID
     */
    function expectedPrice(uint256 tokenId) external view returns (uint256);

    function setInfo(uint256 tokenId, TinyInfo memory newInfo) external;

    function setAttributes(uint256 tokenId, TinyAttribute memory attribute) external;

    function setDetails(uint256 tokenId, TinyInfo memory newInfo, TinyAttribute memory attribute) external;
}


interface IEggFactory {
    function nft() external view returns (address);

    function stats() external view returns (address);

    function totalBurned() external view returns (uint256);

    function mintedTokens() external view returns (uint256);

    function tokenMintedIndex(uint256 tokenId) external view returns (uint256 index);

    function tokenByIndex(uint256 index) external view returns (uint256 tokenId);

    function tokenInfo(uint256 tokenId) external view returns (uint256 mintedFee, uint256 birthDate, uint256 deathDate);

    function mintToken(address receiver, uint256 tokenId, IEggStats.EggInfo memory info) external;

    function mintMultiTokens(address receiver, uint256[] memory tokenId, IEggStats.EggInfo[] memory info) external;

    function burnToken(uint256 tokenId) external;
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}


/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 * add admin user.
 * rewrite ownerOf(uint256) token not mint yet will belong to admin user by default.
 * rewrite tokenURI(uint256) always return _baseURI() + tokenId; metadata sever will handle no-mint token.
 * rewrite balanceOf(address), if is admin, return 999999999.
 * rewrite transferFrom&safeTransferFrom, no-mint token will _mint before transfer, only admin user.
 */
contract BRC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    address private _admin;

    mapping (address => bool) _minters;

    // Mapping from token ID to owner address
    mapping (uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping (address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (address admin_, string memory name_, string memory symbol_) {
        _admin = admin_;
        _name = name_;
        _symbol = symbol_;
    }

    modifier onlyAdmin() {
        require(msg.sender == _admin, "restrict to admin");
        _;
    }

    modifier onlyMinter() {
        require(_minters[msg.sender], "restrict to minter");
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
        || interfaceId == type(IERC721Metadata).interfaceId
        || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     * return magic balance value if is admin user
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     * return admin user address is not mint yet.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        if (owner == address(0)) {
            return _admin;
        }
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString()))
        : '';
    }

    /**
     * return admin user;
     */
    function admin() public view virtual returns (address) {
        return _admin;
    }

    /**
     * return if the account has minter right;
     */
    function isMinter(address account) public view virtual returns (bool) {
        return _minters[account];
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = BRC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     * if msg.sender is admin, mint before transfer
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        _mintIfNotExist(tokenId);
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     * if msg.sender is admin, mint before transfer
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        _mintIfNotExist(tokenId);
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = BRC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");
        require(tokenId > 0, "ERC721: zero id");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = _owners[tokenId];

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(BRC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(BRC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
    private returns (bool)
    {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /*
    * mint if msg.sender is admin && tokenId not mint.
    */
    function _mintIfNotExist(uint256 tokenId) private {
        if (_minters[msg.sender] || msg.sender == _admin) {
            if (!_exists(tokenId)) {
                _mint(msg.sender, tokenId);
            }
        }
    }

    function mint(address to, uint256 tokenId) external onlyMinter {
        _mint(to, tokenId);
    }

    function safeMint(address to, uint256 tokenId) external onlyMinter {
        _safeMint(to, tokenId);
    }

    function changeAdmin(address newAdmin) external onlyAdmin {
        _admin = newAdmin;
    }

    function setMinterStatus(address account, bool _isMinter) external onlyAdmin {
        _minters[account] = _isMinter;
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}


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


abstract contract BRC721Enumerable is BRC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, BRC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId
        || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < BRC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < BRC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = BRC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = BRC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}


contract EvolutionEgg is IERC721Receiver, OwnableUpgradeable, ReentrancyGuard {
    address public nftEgg_;
    address public nftTiny_;

    address public statsEgg_;
    address public statsTiny_;

    address public factoryEgg_;

    uint256 private currentSeed = 0;


    mapping(address => bool) private _admin;

    struct SaleInfo {
        uint256 tokenId;
        address owner;
        address opener;
        uint256 openDate;
        uint8 status; // 1: UNLISTED , 2: SOLD, 3: AVAILABLE
    }

    /*
        0 - Rarity COMMON Type STRENGTH
        1 - Rarity COMMON Type AGILITY
        2 - Rarity COMMON Type INTELLIGENCE
        3 - Rarity RARE Type STRENGTH
        4 - Rarity RARE Type AGILITY
        5 - Rarity RARE Type INTELLIGENCE
        6 - Rarity EPIC Type STRENGTH
        7 - Rarity EPIC Type AGILITY
        8 - Rarity EPIC Type INTELLIGENCE
    */
    uint256[9] public lastIndex_;

    // Common Hero
    mapping(uint256 => uint256) private saleCommonIndex_;
    SaleInfo[] public saleCommonInfo;

    // Rare Hero
    mapping(uint256 => uint256) private saleRareIndex_;
    SaleInfo[] public saleRareInfo;

    // Epic Hero
    mapping(uint256 => uint256) private saleEpicIndex_;
    SaleInfo[] public saleEpicInfo;

    // The distribution for Probability
    // 95, 89, 29 -> 4% epic , 6% rare, 60% common
    // 93, 69, 19 -> 2% epic, 90 % rare
    // 91, 59, 9 -> 30% epic, 60% rare
    uint256[9] public odds_;

    /* ========== EVENTS ========== */
    event OnERC721Received(address operator, address from, uint256 tokenId, bytes data);
    event AdminUpdate(address indexed account, bool isAdmin);
    event StatsUpdate(address oldStatsEgg, address newStatsEgg, address oldStatsTiny, address newStatsTiny);
    event FactoryEggUpdate(address oldFactoryEgg, address newFactoryEgg);
    event OnSale(uint256 indexed tokenId);
    event OffSale(uint256 indexed tokenId);
    event SuccessOpen(uint256 indexed tokenId);
    event FailOpen(uint256 indexed tokenId);

    /* ========== Modifiers =============== */

    modifier onlyAdmin() {
        require(_admin[msg.sender] || owner() == msg.sender, "!admin");
        _;
    }

    /* ========== GOVERNANCE ========== */

    function initialize(address _nftTiny, address _nftEgg, address _statsTiny, address _statsEgg, address _factoryEgg, uint256[9] memory _odds) external initializer {
        require(_nftTiny != address(0), "zero");
        require(_nftEgg != address(0), "zero");
        require(_statsTiny != address(0), "zero");
        require(_statsEgg != address(0), "zero");
        require(_factoryEgg != address(0), "zero");
        __Ownable_init();
        nftTiny_ = _nftTiny;
        nftEgg_ = _nftEgg;
        statsEgg_ = _statsEgg;
        statsTiny_ = _statsTiny;
        factoryEgg_ = _factoryEgg;
        odds_ = _odds;
    }

    function setAdmin(address _account, bool _isAdmin) external onlyOwner {
        require(_account != address(0), "zero");
        emit AdminUpdate(_account, _isAdmin);
        _admin[_account] = _isAdmin;
    }

    function setStats(address _statsEgg, address _statsTiny) external onlyOwner {
        require(_statsEgg != address(0), "zero");
        require(_statsTiny != address(0), "zero");
        emit StatsUpdate(statsEgg_, _statsEgg, statsTiny_, _statsTiny);
        statsEgg_ = _statsEgg;
        statsTiny_ = _statsTiny;
    }

    function setFactoryEgg(address _factoryEgg) external onlyOwner {
        require(_factoryEgg != address(0), "zero");
        factoryEgg_ = _factoryEgg;
        emit FactoryEggUpdate(factoryEgg_, _factoryEgg);
    }

    function setOdds(uint256[9] memory _odds) external onlyOwner {
        odds_ = _odds;
    }


    function setLastIndex(uint256[3] memory _lastIndex) external onlyOwner {
        lastIndex_ = _lastIndex;
    }

    /* ========== VIEW FUNCTIONS ========== */

    function isAdmin(address _account) external view returns (bool) {
        return _admin[_account];
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4) {
        if (msg.sender == nftTiny_ || msg.sender == nftEgg_) {
            emit OnERC721Received(operator, from, tokenId, data);
            return this.onERC721Received.selector;
        } else revert();
    }

    // List Hero
    function _listForSale(uint256 _tokenId) internal {
        BRC721 _nft = BRC721(nftTiny_);
        require(_nft.ownerOf(_tokenId) == msg.sender, "!own");
        _nft.safeTransferFrom(msg.sender, address(this), _tokenId);
        (ITinyHeroStats.TinyInfo memory info,) = ITinyHeroStats(statsTiny_).details(_tokenId);
        ITinyHeroStats.TinyRarity _tinyRarity = info.Rarity;
        if (_tinyRarity == ITinyHeroStats.TinyRarity.COMMON) {
            // Common
            saleCommonIndex_[_tokenId] = saleCommonInfo.length;
            saleCommonInfo.push(
                SaleInfo({
                    tokenId : _tokenId,
                    owner : msg.sender,
                    opener : address(0),
                    openDate : 0,
                    status : 3
                })
            );
        } else if (_tinyRarity ==  ITinyHeroStats.TinyRarity.RARE) {
            // Rare
            saleRareIndex_[_tokenId] = saleRareInfo.length;
            saleRareInfo.push(
                SaleInfo({
                    tokenId : _tokenId,
                    owner : msg.sender,
                    opener : address(0),
                    openDate : 0,
                    status : 3
                })
            );
        } else {
            // EPIC
            saleEpicIndex_[_tokenId] = saleEpicInfo.length;
            saleEpicInfo.push(
                SaleInfo({
                    tokenId : _tokenId,
                    owner : msg.sender,
                    opener : address(0),
                    openDate : 0,
                    status : 3
                })
            );
        }
        emit OnSale(_tokenId);
    }

    function listForSale(uint256[] memory _tokenIds) external onlyAdmin {
        uint256 length = _tokenIds.length;
        for (uint256 i = 0; i < length; i++) {
            _listForSale(_tokenIds[i]);
        }
    }

    function unlistItem(uint256 _tokenId) public nonReentrant {
        (ITinyHeroStats.TinyInfo memory info,) = ITinyHeroStats(statsTiny_).details(_tokenId);
        ITinyHeroStats.TinyRarity _tinyRarity = info.Rarity;
        if (_tinyRarity == ITinyHeroStats.TinyRarity.COMMON) {
            // Common
            SaleInfo storage sale = saleCommonInfo[saleCommonIndex_[_tokenId]];
            require(sale.owner == msg.sender, "!own");
            require(sale.status != 1, "UNLISTED");
            require(sale.status != 2, "SOLD");
            sale.status = 1;
            BRC721(nftTiny_).safeTransferFrom(address(this), msg.sender, _tokenId);
        } else if (_tinyRarity == ITinyHeroStats.TinyRarity.RARE) {
            // Rare
            SaleInfo storage sale = saleRareInfo[saleRareIndex_[_tokenId]];
            require(sale.owner == msg.sender, "!own");
            require(sale.status != 1, "UNLISTED");
            require(sale.status != 2, "SOLD");
            sale.status = 1;
            BRC721(nftTiny_).safeTransferFrom(address(this), msg.sender, _tokenId);
        } else {
            // EPIC
            SaleInfo storage sale = saleEpicInfo[saleEpicIndex_[_tokenId]];
            require(sale.owner == msg.sender, "!own");
            require(sale.status != 1, "UNLISTED");
            require(sale.status != 2, "SOLD");
            sale.status = 1;
            BRC721(nftTiny_).safeTransferFrom(address(this), msg.sender, _tokenId);
        }
        emit OffSale(_tokenId);
    }

    function unlistItems(uint256[] memory tokenIds) external {
        uint256 length = tokenIds.length;
        for (uint256 i = 0; i < length; i++) {
            unlistItem(tokenIds[i]);
        }
    }

    function _findTokenIdByType(ITinyHeroStats.TinyType _tinyType,  ITinyHeroStats.TinyRarity _tinyRarity) internal returns (uint256 _tokenTinyId, uint256 _indexId) {
        if (_tinyRarity == ITinyHeroStats.TinyRarity.COMMON) {
            // Common
            uint256 length = saleCommonInfo.length;
            uint256 index_ = 0; // Default STRENGTH
            if (_tinyType == ITinyHeroStats.TinyType.AGILITY) {
                index_ = 1;
            } else if (_tinyType == ITinyHeroStats.TinyType.INTELLIGENCE) {
                index_ = 2;
            }
            for (uint256 i = lastIndex_[index_]; i < length; i++) {
                SaleInfo storage sale = saleCommonInfo[i];
                (ITinyHeroStats.TinyInfo memory info,) = ITinyHeroStats(statsTiny_).details(sale.tokenId);
                if (sale.status == 3 && info.Type == _tinyType) {
                    _tokenTinyId = sale.tokenId;
                    _indexId = i;
                    lastIndex_[index_] = i;
                    return (_tokenTinyId, _indexId);
                }
            }
        } else if (_tinyRarity == ITinyHeroStats.TinyRarity.RARE) {
            // Rare
            uint256 length = saleRareInfo.length;
            uint256 index_ = 3; // Default STRENGTH
            if (_tinyType == ITinyHeroStats.TinyType.AGILITY) {
                index_ = 4;
            } else if (_tinyType == ITinyHeroStats.TinyType.INTELLIGENCE) {
                index_ = 5;
            }
            for (uint256 i = lastIndex_[index_]; i < length; i++) {
                SaleInfo storage sale = saleRareInfo[i];
                (ITinyHeroStats.TinyInfo memory info,) = ITinyHeroStats(statsTiny_).details(sale.tokenId);
                if (sale.status == 3 && info.Type == _tinyType) {
                    _tokenTinyId = sale.tokenId;
                    _indexId = i;
                    lastIndex_[index_] = i;
                    return (_tokenTinyId, _indexId);
                }
            }
        } else {
            // Epic
            uint256 length = saleEpicInfo.length;
            uint256 index_ = 6; // Default STRENGTH
            if (_tinyType == ITinyHeroStats.TinyType.AGILITY) {
                index_ = 7;
            } else if (_tinyType == ITinyHeroStats.TinyType.INTELLIGENCE) {
                index_ = 8;
            }
            for (uint256 i = lastIndex_[index_]; i < length; i++) {
                SaleInfo storage sale = saleEpicInfo[i];
                (ITinyHeroStats.TinyInfo memory info,) = ITinyHeroStats(statsTiny_).details(sale.tokenId);
                if (sale.status == 3 && info.Type == _tinyType) {
                    _tokenTinyId = sale.tokenId;
                    _indexId = i;
                    lastIndex_[index_] = i;
                    return (_tokenTinyId, _indexId);
                }
            }
        }
    }

    function _open(uint256 _tokenEggId, ITinyHeroStats.TinyType _tinyType, ITinyHeroStats.TinyRarity _tinyRarity, address receiver) internal {
        currentSeed = _genNextSeed(0);
        IEggFactory _factoryEgg = IEggFactory(factoryEgg_);
        (uint256 _tokenTinyId, uint256 _indexId) = _findTokenIdByType(_tinyType, _tinyRarity);
        if (_tinyRarity == ITinyHeroStats.TinyRarity.COMMON) {
            // Common
            SaleInfo storage sale = saleCommonInfo[_indexId];
            sale.status = 2;
            sale.opener = receiver;
            BRC721(nftTiny_).safeTransferFrom(address(this), receiver, _tokenTinyId);
        } else if (_tinyRarity == ITinyHeroStats.TinyRarity.RARE) {
            // Rare
            SaleInfo storage sale = saleRareInfo[_indexId];
            sale.status = 2;
            sale.opener = receiver;
            BRC721(nftTiny_).safeTransferFrom(address(this), receiver, _tokenTinyId);
        } else {
            // EPIC
            SaleInfo storage sale = saleEpicInfo[_indexId];
            sale.status = 2;
            sale.opener = receiver;
            BRC721(nftTiny_).safeTransferFrom(address(this), receiver, _tokenTinyId);
        }
        _factoryEgg.burnToken(_tokenEggId);
        emit SuccessOpen(_tokenTinyId);
    }

    function _genNextSeed(uint256 _newHash) internal view returns (uint256) {
        return currentSeed ^ _newHash ^ uint256(blockhash(block.number - 1));
    }

    function getLuckyNumber(uint256 _randomNumber) private pure returns (uint256) {
        uint256 maxRanger = 100;
        return uint256(keccak256(abi.encodePacked(_randomNumber, maxRanger))) % 100;
    }

    function evolutionEgg(uint256 _tokenId, uint256 _userRandomHash) external nonReentrant {
        bool canOpen = false;
        IEggFactory _factoryEgg = IEggFactory(factoryEgg_);
        BRC721 _nftEgg = BRC721(nftEgg_);
        require(_nftEgg.ownerOf(_tokenId) == msg.sender, "!own");
        _nftEgg.safeTransferFrom(msg.sender, address(this), _tokenId);
        _nftEgg.approve(factoryEgg_, _tokenId);
        (IEggStats.EggInfo memory infoEgg) = IEggStats(statsEgg_).details(_tokenId);
        IEggStats.EggRarity _rarityEgg = infoEgg.Rarity;
        IEggStats.EggType _typeEgg = infoEgg.Type;
        currentSeed = _genNextSeed(_userRandomHash);
        uint256 _luckyNumber = getLuckyNumber(currentSeed);
        ITinyHeroStats.TinyType _futureTinyType = ITinyHeroStats.TinyType.STRENGTH ; // Default STRENGTH
        ITinyHeroStats.TinyRarity _futureTinyRarity; // Default Common;
        if (_rarityEgg ==  IEggStats.EggRarity.COMMON) {
            // 60% common hero, 6% rare hero , 4% epic hero
            if (_luckyNumber > odds_[0]) {
                _futureTinyRarity = ITinyHeroStats.TinyRarity.EPIC; // Epic
                canOpen = true;
            } else if (_luckyNumber > odds_[1] ) {
                _futureTinyRarity = ITinyHeroStats.TinyRarity.RARE; // Rare
                canOpen = true;
            } else if (_luckyNumber > odds_[2] ) {
                _futureTinyRarity = ITinyHeroStats.TinyRarity.COMMON; // Common
                canOpen = true;
            }
        } else  if (_rarityEgg == IEggStats.EggRarity.RARE) {
            // 55% common hero, 24% rare hero , 6% epic hero
            if (_luckyNumber > odds_[3]) {
                _futureTinyRarity = ITinyHeroStats.TinyRarity.EPIC; // Epic
                canOpen = true;
            } else if (_luckyNumber > odds_[4]) {
                _futureTinyRarity = ITinyHeroStats.TinyRarity.RARE; // Rare
                canOpen = true;
            } else if (_luckyNumber > odds_[5]) {
                _futureTinyRarity = ITinyHeroStats.TinyRarity.COMMON; // Common
                canOpen = true;
            }
        } else {
            // 50% common hero, 32% rare hero , 8% epic hero
            if (_luckyNumber > odds_[6]) {
                _futureTinyRarity = ITinyHeroStats.TinyRarity.EPIC; // Epic
                canOpen = true;
            } else if (_luckyNumber > odds_[7]) {
                _futureTinyRarity = ITinyHeroStats.TinyRarity.RARE; // Rare
                canOpen = true;
            } else if (_luckyNumber > odds_[8]) {
                _futureTinyRarity = ITinyHeroStats.TinyRarity.COMMON; // Common
                canOpen = true;
            }
        }
        if (_typeEgg == IEggStats.EggType.AGILITY) {
            _futureTinyType = ITinyHeroStats.TinyType.AGILITY ;
        } else if (_typeEgg == IEggStats.EggType.INTELLIGENCE) {
            _futureTinyType = ITinyHeroStats.TinyType.INTELLIGENCE ;
        }
        if (canOpen) {
            _open(_tokenId, _futureTinyType, _futureTinyRarity, msg.sender);
        } else {
            // burn
            _factoryEgg.burnToken(_tokenId);
            emit FailOpen(_tokenId);
        }
    }

    function evolutionEggs(uint256[] memory tokenIds, uint256 _userRandomHash) external {
        uint256 length = tokenIds.length;
        for (uint256 i = 0; i < length; i++) {
            this.evolutionEgg(tokenIds[i], _userRandomHash);
        }
    }
}