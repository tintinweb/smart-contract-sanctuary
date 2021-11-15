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

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

/**
 * @dev Required interface of an EaselyRegistry compliant contract.
 */
interface IEaselyRegistry {
    /**
     * @dev Emitted when `CREATOR_ROLE` has registered a new creatorAddress with a BPS fee
     */
    event CreatorRegistered(address creatorAddress);

    /**
     * @dev Emitted when `CREATOR_ROLE` or owner needs to pause all sales on our Marketplaces
     */
    event CreatorPaused(address creatorAddress);

    /**
     * @dev Emitted when `CREATOR_ROLE` or owner wants to resume all sales on our Marketplaces
     */
    event CreatorUnpaused(address creatorAddress);

    /**
     * @dev Calculates for a certain creator and payin amount, how much the creator receives.
     * This value is always greater than 95% since the BPS fee cap is 500.
     *
     * Requirements:
     * - Creator cannot be paused
     */
    function calculateCreatorPayout(address creatorAddress, uint256 payin) external view returns (uint256);

    /**
     * @dev Returns if a creator is registered or has the default BPS fee.
     */
    function isCreatorRegistered(address creatorAddress) external view returns (bool);

    /**
     * @dev Returns if a creator is paused on our marketplaces or not.
     */
    function isCreatorPaused(address creatorAddress) external view returns (bool);
}

/** 
 * @dev Required interface of a SimpleMarketplace that sells bundles
 */
interface ISimpleMarketplace {
    /**
     * @dev Emitted when a bundle is created and includes the contractAddress, 
     * tokenIds involved in the bundle, the price, and the creatorAddress who needs 
     * to own the tokens as well as receive the majority of the proceeds of the sale.
     */
    event BundleCreated(
        uint256 bundleId, 
        address contractAddress, 
        address creatorAddress, 
        uint256[] tokenIds, 
        uint256 price
    );

    /**
     * @dev Emitted when a created bundle is withdrawn from the marketplace
     * and can no longer be bought.
     */
    event BundleWithdrawn(uint256 bundleId);

    /**
     * @dev Emitted when a created bundle is sold from the marketplace and 
     * the related tokens have successfully transferred to the buyer.
     */
    event BundleBought(uint256 bundleId);

    /**
     * @dev Information that the marketplace needs in order to put a bundle of
     * tokens relating to a contract up for sale
     *
     * Requirements:
     * - contractAddress must support IERC721
     * - sender must be contractAddress or creatorAddress
     * - creatorAddress must grant this contract permission
     * - bundle cannot exceed a certain size
     * - price must be valid (at least 0.000001 ETH)
     */
    function sellBundle(
        address contractAddress, 
        address creatorAddress, 
        uint256[] memory tokenIds, 
        uint256 price
    ) external;

    /**
     * @dev Returns the bundleId that a specific token belongs to. Will throw
     * if token is not part of a bundle.
     */
    function getBundleId(address contractAddress, uint256 tokenId) external view returns (uint256);

    /**
     * @dev Because token ownership can change outside the marketplace contract, a created bundled
     * that is not withdrawn or bought cannot determine alone if the bundle is still buyable.
     * 
     * This function will check if the owner still has the tokens for a bundle and if this marketplace
     * still has the permissions to transfer the tokens.
     */
    function isBuyable(uint256 bundleId) external view returns (bool);

    /**
     * @dev Allows a bundle to be taken off the market and can no longer by bought by buyBundle.
     * The bundle is deleted in the process.
     *
     * Can only be called by the contract or creator who is marked on the bundleId.
     */
    function withdrawBundle(uint256 bundleId) external;

    /**
     * @dev Allows any user to buy a bundle of tokens and will be transferred from
     * the creatorAddress into the payer's address. The bundle is deleted after the transfer.
     *
     * Requirements:
     * - buyerAddress must be a safeTransfer location
     * - creatorAddress still has all the tokenIds in the bundle
     */
    function buyBundle(uint256 bundleId) external payable;
}

contract SimpleMarketplace is Ownable, ISimpleMarketplace {

    struct Bundle {
        address contractAddress;
        address creatorAddress;
        uint256 price;
        uint256[] tokenIds;
    }

    address public registryAddress;

    /**
     * Setting a min price so that users cannot accidentally
     * sell their tokens at a price that is off by a conversion rate.
     * The min WEI price below is equivalent to ETH 0.000001
     *
     * WEI has a conversion rate of:
     * 1 ETH = 1_000_000_000 GWEI
     * 1 GWEI = 1_000_000_000 WEI
     */
    uint256 public MIN_WEI_PRICE = 1_000_000_000_000;

    uint256 public MAX_BUNDLE_SIZE = 25;

    uint256 private nextBundleId = 1;

    mapping(uint256 => Bundle) private _bundleIdToBundle;
    mapping(address => mapping(uint256 => uint256)) private _tokenToBundleId;

    /**
     * @dev Constructor function
     */
    constructor(address registryAddress_) { 
        registryAddress = registryAddress_;
    }

    /**
     * @dev Verify that the seller is either the contractAddress or the creator.
     * Also ensure that this contract has approval for all tokens for that creator.
     */
    function _verifySeller(address contractAddress, address creatorAddress) internal view {
        address msgSender = _msgSender();

        bool isValidSender = msgSender == contractAddress || msgSender == creatorAddress;
        require(isValidSender, "Seller must be the creator or the contract");

        IERC721 nonFungibleContract = IERC721(contractAddress);
        require(
            nonFungibleContract.isApprovedForAll(creatorAddress, address(this)), 
            "Seller must approve this contract for all tokens"
        );
    }

    /**
     * @dev Valid bundles start with id 1, so tokens with bundleId 0 are not bundled
     */
    function _isBundled(address contractAddress, uint256 tokenId) internal view returns (bool) {
        return _tokenToBundleId[contractAddress][tokenId] != 0;
    }

    /**
     * @dev Valid bundles have a price above minimum and are reset when deleted. So
     * we can use price as a proxy to see if the bundle exists
     */
    function _bundleExists(uint256 bundleId) internal view returns (bool) {
        return _bundleIdToBundle[bundleId].price >= MIN_WEI_PRICE;
    }

    /**
     * @dev See {ISimpleMarketplace-isBuyable}.
     */
    function _isBuyable(uint256 bundleId) internal view returns (bool) {
        // Cannot sell the bundle if it does not exist
        if(!_bundleExists(bundleId)) {
            return false;
        }

        Bundle memory bundle = _bundleIdToBundle[bundleId];
        IERC721 nonFungibleContract = IERC721(bundle.contractAddress);

        // Cannot sell the bundle if we are not approved to transfer all
        if(!nonFungibleContract.isApprovedForAll(bundle.creatorAddress, address(this))) {
            return false; 
        }

        uint256[] memory tokenIds = bundle.tokenIds;
        uint256 numTokens = tokenIds.length;

        // Cannot sell the bundle if the owner no longer owns all the tokens
        for (uint256 i = 0; i < numTokens; i++) {
            if(nonFungibleContract.ownerOf(tokenIds[i]) != bundle.creatorAddress) {
                return false;
            }
        }

        return true;
    }

    /**
     * @dev Returns all pertinent information related to a bundleId
     */
    function getBundle(uint256 bundleId) external view returns (Bundle memory) {
        require(_isBuyable(bundleId), "This bundle is not buyable");
        return _bundleIdToBundle[bundleId];
    }

    /**
     * @dev See {ISimpleMarketplace-isBuyable}.
     */
    function isBuyable(uint256 bundleId) external view override returns (bool) {
        return _isBuyable(bundleId);
    }

    /**
     * @dev See {ISimpleMarketplace-getBundleId}.
     */
    function getBundleId(address contractAddress, uint256 tokenId) external view override returns (uint256) {
        uint256 bundleId = _tokenToBundleId[contractAddress][tokenId];
        require(bundleId != 0, "This token is not part of a bundle");
        
        return bundleId;
    }

    /**
     * @dev After every transaction the marketplace holds a cut. A portion of this
     * accumulated amount can be withdrawn by the owner at anytime.
     *
     * Requirements:
     * - Only Marketplace owner can withdraw balance.
     */
    function withdrawBalance(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Contract balance too low");
        payable(owner()).transfer(amount);
    }

    /**
     * @dev See {ISimpleMarketplace-sellBundle}.
     */
    function sellBundle(
        address contractAddress, 
        address creatorAddress, 
        uint256[] memory tokenIds, 
        uint256 price
    ) external override {
        require(tokenIds.length < MAX_BUNDLE_SIZE, "Too many tokens given");
        require(price >= MIN_WEI_PRICE, "Price given is below minimum");
        require(IERC165(contractAddress).supportsInterface(type(IERC721).interfaceId), "Contract must support IERC721");
        _verifySeller(contractAddress, creatorAddress);

        Bundle memory newBundle;
        newBundle.contractAddress = contractAddress;
        newBundle.creatorAddress = creatorAddress;
        newBundle.tokenIds = tokenIds;
        newBundle.price = price;

        _bundleIdToBundle[nextBundleId] = newBundle;

        uint256 numTokens = tokenIds.length;
        for (uint256 i = 0; i < numTokens; i++) {
            uint256 tokenId = tokenIds[i];
            require(!_isBundled(contractAddress, tokenId), "Token already in bundle");
            _tokenToBundleId[contractAddress][tokenId] = nextBundleId;
        }

        emit BundleCreated(nextBundleId, contractAddress, creatorAddress, tokenIds, price);

        nextBundleId = nextBundleId + 1;
    }

    /**
     * @dev See {ISimpleMarketplace-withdrawBundle}.
     */
    function withdrawBundle(uint256 bundleId) external override {
        require(_bundleExists(bundleId), "Bundle does not exist");

        address msgSender = _msgSender();
        Bundle memory bundle = _bundleIdToBundle[bundleId];
        address contractAddress = bundle.contractAddress;

        bool isValidWithdrawer = msgSender == contractAddress || msgSender == bundle.creatorAddress;
        require(isValidWithdrawer, "Only the contract or bundle creator can withdraw");
        
        uint256[] memory tokenIds = bundle.tokenIds;
        uint256 numTokens = tokenIds.length;

        for (uint256 i = 0; i < numTokens; i++) {
            _tokenToBundleId[contractAddress][tokenIds[i]] = 0;
        }

        delete _bundleIdToBundle[bundleId];

        emit BundleWithdrawn(bundleId);
    }

    /**
     * @dev See {ISimpleMarketplace-buyBundle}.
     */
    function buyBundle(uint256 bundleId) external payable override {
        require(_bundleExists(bundleId), "Bundle does not exist");

        Bundle memory bundle = _bundleIdToBundle[bundleId];

        uint256 msgValue = msg.value;
        address senderAddress = _msgSender();
        address creatorAddress = bundle.creatorAddress;

        require(msgValue >= bundle.price, "Msg value too small");
        
        uint256 creatorPayout = 
            IEaselyRegistry(registryAddress).calculateCreatorPayout(creatorAddress, bundle.price); 

        IERC721 nonFungibleContract = IERC721(bundle.contractAddress);
        uint256[] memory tokenIds = bundle.tokenIds;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = bundle.tokenIds[i];
            
            _tokenToBundleId[bundle.contractAddress][tokenId] = 0;
            nonFungibleContract.safeTransferFrom(creatorAddress, senderAddress, tokenId);
        } 

        // Send back any value greater than the listed price
        payable(creatorAddress).transfer(creatorPayout);
        payable(senderAddress).transfer(msgValue - bundle.price);

        delete _bundleIdToBundle[bundleId];

        emit BundleBought(bundleId);
    }
}

