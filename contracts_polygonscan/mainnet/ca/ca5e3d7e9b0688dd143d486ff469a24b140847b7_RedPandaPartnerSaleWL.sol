/**
 *Submitted for verification at polygonscan.com on 2021-12-16
*/

// Dependency file: @openzeppelin/contracts/utils/Address.sol

// SPDX-License-Identifier: MIT

// pragma solidity ^0.8.0;

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


// Dependency file: @openzeppelin/contracts/utils/introspection/IERC165.sol


// pragma solidity ^0.8.0;

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


// Dependency file: @openzeppelin/contracts/token/ERC721/IERC721.sol


// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

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


// Dependency file: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol


// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

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


// Dependency file: contracts/interfaces/ICollectible.sol


// pragma solidity >=0.8.0 <1.0.0;

// import "/mnt/c/Users/piron/Desktop/RedPanda/node_modules/@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface ICollectible is IERC721Enumerable {
    function mint(address to, uint256 amount) external;
}

// Dependency file: @openzeppelin/contracts/utils/Context.sol


// pragma solidity ^0.8.0;

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


// Dependency file: @openzeppelin/contracts/access/Ownable.sol


// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/Context.sol";

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


// Dependency file: contracts/Whitelist.sol


// pragma solidity >=0.8.0 <1.0.0;

// import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Whitelist is Ownable {
    event MemberAdded(address member);
    event MemberRemoved(address member);

    mapping(address => bool) private _members;

    /**
     * @dev A method to verify whether an address is a member of the whitelist
     * @param _account The address to verify.
     * @return Whether the address is a member of the whitelist.
     */
    function isMember(address _account) public view returns (bool) {
        return _members[_account];
    }

    /**
     * @dev A method to add a member to the whitelist
     * @param _account The member to add as a member.
     */
    function addMember(address _account) external onlyOwner {
        require(!isMember(_account), "Whitelist: Address is member already");

        _members[_account] = true;
        emit MemberAdded(_account);
    }

    /**
     * @dev A method to add a member to the whitelist
     * @param _accounts The _members to add as a member.
     */
    function addMembers(address[] calldata _accounts) external onlyOwner {
        _addMembers(_accounts);
    }

    /**
     * @dev A method to remove a member from the whitelist
     * @param _account The member to remove as a member.
     */
    function removeMember(address _account) external onlyOwner {
        require(isMember(_account), "Whitelist: Not member of whitelist");

        delete _members[_account];
        emit MemberRemoved(_account);
    }

    /**
     * @dev A method to remove a _members from the whitelist
     * @param _accounts The _members to remove as a member.
     */
    function removeMembers(address[] calldata _accounts) external onlyOwner {
        _removeMembers(_accounts);
    }

    function _addMembers(address[] memory _accounts) internal {
        uint256 l = _accounts.length;
        uint256 i;
        for (i; i < l; i++) {
            require(
                !isMember(_accounts[i]),
                "Whitelist: Address is member already"
            );

            _members[_accounts[i]] = true;
            emit MemberAdded(_accounts[i]);
        }
    }

    function _removeMembers(address[] memory _accounts) internal {
        uint256 l = _accounts.length;
        uint256 i;
        for (i; i < l; i++) {
            require(
                isMember(_accounts[i]),
                "Whitelist: Address is no member"
            );

            delete _members[_accounts[i]];
            emit MemberRemoved(_accounts[i]);
        }
    }
}

// Root file: contracts/RedPandaPartnerSaleWL.sol


pragma solidity >=0.8.0 <1.0.0;

// import { Address } from "/mnt/c/Users/piron/Desktop/RedPanda/node_modules/@openzeppelin/contracts/utils/Address.sol";
// import { ICollectible } from "contracts/interfaces/ICollectible.sol";
// import { Whitelist } from "contracts/Whitelist.sol";

contract RedPandaPartnerSaleWL is Whitelist {

    uint256 public tokenPrice = 125e18; // 125 MATIC
    uint256 public maxTokenPurchase = 15;
    uint256 public constant maxTokens = 4500;
    uint256 public constant maxBonusTokens = 500;
    uint256 public minted;
    uint256 public mintedBonus; // amount paid bonus tokens

    address public fund;

    bool public saleIsActive;
    bool public isWhitelistOn;

    ICollectible public immutable nft;

    mapping (address => bool) public bonusPaid;

    event TokenPriceChanged(uint256 price);
    event MaxPurchaseChanged(uint256 value);
    event FundSet(address fund);
    event RolledOver(bool status);
    event WhitelistFlipped(bool status);

    constructor(ICollectible _nft, address _fund) {
        require(
            address(_nft) != address(0) &&
            _fund != address(0),
            "Unacceptable address set"
        );

        nft = _nft;
        fund = _fund;
    }

    // @dev Buy some `_amount` tokens.
    function buy(uint _amount) external payable {
        require(
            (isWhitelistOn) ? isMember(msg.sender) : true,
            "Collection: only whitelisted"
        );
        require(_amount != 0, "Collection: zero amount buy");
        require(saleIsActive, "Collection: sale is not active");
        require(
            _amount <= maxTokenPurchase,
            "Collection: exceeds max number of Tokens in one transaction"
        );

        uint mintAmount = _amount;

        require(
            minted + mintAmount <= maxTokens,
            "Collection: purchase would exceed max supply of Tokens"
        );

        uint256 deposit = msg.value;

        require(tokenPrice * _amount == deposit,
            "Collection: ether value sent is not correct"
        );

        if (fund != address(this)) {
            Address.sendValue(payable(fund), deposit);
        }

        minted += mintAmount;

        // bonus pay
        if (mintedBonus < maxBonusTokens) {
            if (!bonusPaid[_msgSender()]) {
                bonusPaid[_msgSender()] = true;
                mintAmount += 1;
                mintedBonus++;
            }
        }

        nft.mint(msg.sender, mintAmount);
    }

    // @dev Changes sale status.
    // Permission: only owner
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
        emit RolledOver(saleIsActive);
    }

    // @dev Enable/disable whitelist support.
    // Permission: only owner
    function flipWhitelist() public onlyOwner {
        isWhitelistOn = !isWhitelistOn;
        emit WhitelistFlipped(isWhitelistOn);
    }

    // @dev Setup new token sale price.
    // Permission: only owner
    function setPrice(uint256 _price) external onlyOwner {
        require(_price != 0, "Zero price");

        tokenPrice = _price;
        emit TokenPriceChanged(_price);
    }

    // @dev Setup max tokens purchase per transaction.
    // Permission: only owner
    function setMaxPurchase(uint256 _value) external onlyOwner {
        require(_value != 0, "Very low value");

        maxTokenPurchase = _value;
        emit MaxPurchaseChanged(_value);
    }

    // @dev Setup new bank account.
    // Permission: only owner
    function setFund(address _account) external onlyOwner {
        require(
            _account != address(0) &&
            _account != address(this),
            "Unacceptable address set"
        );

        fund = _account;
        emit FundSet(_account);
    }
}