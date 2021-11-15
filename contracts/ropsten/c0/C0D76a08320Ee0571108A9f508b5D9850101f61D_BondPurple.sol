// SPDX-License-Identifier: MIT

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
    constructor () {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

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
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
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
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
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
        address owner = ERC721.ownerOf(tokenId);
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
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
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
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
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
        address owner = ERC721.ownerOf(tokenId);
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
        address owner = ERC721.ownerOf(tokenId);

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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
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
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "./GreenBond_daily.sol"; 

contract BondPurple is GreenBond_daily {
    constructor(
        address company,
        string memory name,
        string memory symbol,
        uint256 numberOfBondsSought,
        uint256 minCoupon,
        uint256 maxCoupon,
        uint256 bidClosingTime,
        uint256 term,
        uint256 couponsPerTerm,
        string memory baseBondURI
    ) GreenBond_daily(company, name, symbol, numberOfBondsSought, minCoupon, maxCoupon,
        bidClosingTime, term, couponsPerTerm, baseBondURI) {

    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract GreenBond_daily is ERC721, Ownable {
    using Counters for Counters.Counter;

    // MODIFIERS
    /**
     * @dev Reverts if bidding time is not open
     */
    modifier onlyWhileBiddingWindowOpen {
        require(biddingWindowisOpen(), "Investment window is not open");
        _;
    }

    /**
     * @dev Reverts if bidding time is still open
     */
    modifier onlyWhileBiddingWindowClosed {
        require(!biddingWindowisOpen(), "Investment window is still open");
        _;
    }

    // STATE VARIABLES
    
    // Bond ID numbers
    Counters.Counter private _bondIdTracker;

    // URI for bond metadata stored on decentralised database or cloud
    string private _baseBondURI;

    // Bond state controllers
    bool private _coupondefined = false;
    bool private _cancelled = false;
    bool private _issued = false;

    // List of initial investors
    address[] private _initialInvestors; 

    // Owner of the contract - Issuing Financial Institution
    address private _owner;
    // Borrowing company
    address payable private _company;

    // Face value of 1 bond
    uint256 private _value;

    // Number of bonds sought by the borrowing company
    uint256 private _numberOfBondsSought;

    // Total amount borrowed. Calculated as number of bonds * face value
    uint256 private _totalDebt;

    // Coupon range
    uint256 private _minCoupon;
    uint256 private _maxCoupon;

    // Final coupon 
    uint256 private _coupon;
    
    // Term of the bond (in years)
    uint256 private _term;

    // Coupon payment schedule (per year)
    uint256 private _couponsPerTerm;

    // Total number of coupons. Calculated as term * number of coupons per year
    uint256 private _totalCouponPayments;

    // Number of coupons paid
    uint256 private _couponsPaid; // Zero in the beginning

    // Closing time for bidding
    uint256 private _bidClosingTime;    

    // Issue Date: bid closing time + 2 days
    uint256 private _issueDate;

    // Maturity Date: issue date + term
    uint256 private _maturityDate;

    // Actual principal payment date
    uint256 private _actualPrincipalPaymentDate; 

    // Coupon payment dates: calculated from issue date onwards
    uint256[] private _couponPaymentDates;

    // Actual coupon payment dates
    uint256[] private _actualCouponPaymentDates;

    // Records for investor bid details
    mapping(address => uint256) private _stakedAmountPerInvestor;
    mapping(address => uint256) private _requestedBondsPerInvestor;
    mapping(address => uint256) private _couponPerInvestor;
    mapping(address => bool) private _investorHasBid;

    // Records for coupon definition
    mapping(uint256 => uint256) private _bidsPerCoupon;
    mapping(uint256 => address[]) private _investorListAtCouponLevel;

    // EVENTS

    /**
     * @dev Emitted when an investor registers a bid
     */
    event Bid(address bidder, uint256 coupon, uint256 numberOfBonds);
    
    /**
     * @dev Emitted when coins are refunded to the investor in case there are
            too many coins for the investment or to the company if they pay too much 
            with coupons / principal repayment
     */
    event CoinRefund(address account, uint256 value);

    /**
     * @dev Emitted when a coupon payment has been made
     */
    event CouponPayment(address investor, uint256 bondId);

    /**
     * @dev Emmitted when the coupon is defined after bidding. 
            Only when there is enough demand and issue will go ahead.
     */
    event CouponSet(uint256 coupon);

    /**
     * @dev Emmitted when there is not enough demand for the bond
            and the issue is cancelled.
     */
    event CancelBondIssue(uint256 actualDemand, uint256 requestedDemand);
      
    /**
     * @dev Emmitted when coupon payment is adjusted
     */
    event CouponAdjustment(uint256 from, uint256 to);
    
    // CONSTRUCTOR
    /**
     * @dev constructor: requires specifying the borrowing company address,
            bond name and symbol, number of bonds sought, coupon range,
            bidding window closing time, term, coupons per year and
            base URI for metadata,
     */
    constructor(
        address company,
        string memory name,
        string memory symbol,
        uint256 numberOfBondsSought,
        uint256 minCoupon,
        uint256 maxCoupon,
        uint256 bidClosingTime,
        uint256 term,
        uint256 couponsPerTerm,
        string memory baseBondURI
    ) ERC721(name, symbol) {
        require(company != address(0), "Company address can not be 0x0");
        require(
            maxCoupon > minCoupon,
            "max coupon needs to be greater than min coupon"
        );
        require(
            bidClosingTime > block.timestamp,
            "Closing time can't be in the past"
        );
        _owner = msg.sender;
        _company = payable(company);
        _numberOfBondsSought = numberOfBondsSought;
        _minCoupon = minCoupon;
        _maxCoupon = maxCoupon;
        _coupon = 0; // by default 0
        _value = 100; // Face value default at 100
        _couponsPaid = 0; // set to 0 
        _bidClosingTime = bidClosingTime;
        _baseBondURI = baseBondURI;
        
        _issueDate = _bidClosingTime + 1 days;
        _term = term;
        _couponsPerTerm = couponsPerTerm;
        _totalCouponPayments = term * _couponsPerTerm;
        _maturityDate = _issueDate + term * 1 days;
        _actualPrincipalPaymentDate = 0; // default to 0
        uint256 timeBetweenpayments = 1 days / couponsPerTerm;

        // Setting up the coupon payment dates
        for (uint256 i = 1; i <= _totalCouponPayments; i++) {
            _couponPaymentDates.push(_issueDate + timeBetweenpayments * i);
            _actualCouponPaymentDates.push(0);
        }
    }

    // FUNCTIONS
    /**
     * @dev Get borrowing company.
     */
    function getCompany() public view returns (address) {
        return _company;
    }

    /**
     * @dev Get bond face value
     */
    function getFaceValue() public view returns (uint256) {
        return _value;
    }

    /**
     * @dev Get coupon bidding range
     */
    function getMinCoupon() public view returns (uint256) {
        return _minCoupon;
    }

    function getMaxCoupon() public view returns (uint256) {
        return _maxCoupon;
    }

    /**
     * @dev Get coupon
     */
    function getCoupon() public view returns (uint256) {
        return _coupon;
    }
 
    /**
     * @dev Get number of bonds sought
     */
    function getNumberOfBondsSought() public view returns (uint256) {
        return _numberOfBondsSought;
    }

    /**
     * @dev Get bond term (days)
     */
    function getTerm() public view returns (uint256) {
        return _term;
    }

    /**
     * @dev Get the total debt borrowed
     */
    function getTotalDebt() public view returns (uint256) {
        return _totalDebt;
    }

    /**
     * @dev Get bid closing time
     */
    function getBidClosingTime() external view returns (uint256) {
        return _bidClosingTime;
    }

    /**
     * @dev Get issue date
     */
    function getIssueDate() public view returns (uint256) {
        return _issueDate;
    }

    /**
     * @dev Get maturity date
     */
    function getMaturityDate() public view returns (uint256) {
        return _maturityDate;
    }

    /**
     * @dev Query bond status (cancelled/coupon defined/issued)
     */
    function couponDefined() public view returns (bool) {
        return _coupondefined;
    }

    function cancelled() public view returns (bool) {
        return _cancelled;
    }

    function issued() public view returns (bool) {
        return _issued;
    }

    /**
     * @dev Get the number of coupon payments for the bond
     */
    function getNumberOfCoupons() public view returns (uint256) {
        return _totalCouponPayments;
    }

    /**
     * @dev Get the number of coupons paid
     */
    function getNumberOfCouponsPaid() public view returns (uint256) {
        return _couponsPaid;
    }

    /**
     * @dev Get the agreed date for a specific coupon
     */
    function getCouponDate(uint256 number) public view returns (uint256) {
        require(
            number > 0 && number <= _totalCouponPayments,
            "No such coupon payment"
        );
        return _couponPaymentDates[number - 1];
    }

    /**
     * @dev Get the actual coupon payment date for a specific coupon
     */
    function getActualCouponDate(uint256 number) public view returns (uint256) {
        require(
            number > 0 && number <= _totalCouponPayments,
            "No such coupon payment"
        );
        return _actualCouponPaymentDates[number - 1];
    }

    /**
     * @dev Get an array containin all agreed coupon dates
     */
    function getCouponDates() public view returns (uint256[] memory) {
        return _couponPaymentDates;
    }

    /**
     * @dev Get actual principal payment date
     */
    function getActualPricipalPaymentDate() public view returns (uint256) {
        return _actualPrincipalPaymentDate;
    }

    /**
     * @dev Get the number of bonds issued
     */
    function bondCount() public view returns (uint256) {
        return _bondIdTracker.current();
    }

    /**
     * @dev Get the base URI for bond metadata
     */
    function getBaseURI() external view returns (string memory) {
        return _baseBondURI;
    }

    /**
     * @dev Get staked amount per investor
     */
    function getStakedAmountPerInvestor(address investor)
        external
        view
        returns (uint256)
    {
        return _stakedAmountPerInvestor[investor];
    }

    /**
     * @dev Get requested bonds per investor
     */
    function getRequestedBondsPerInvestor(address investor)
        external
        view
        returns(uint256)
    {
        return _requestedBondsPerInvestor[investor];
    }

    /**
     * @dev Get the coupon bid per investor
     */
    function getCouponPerInvestor(address investor)
        external
        view
        returns(uint256)
    {
        return _couponPerInvestor[investor];
    }

    /**
     * @dev Get a list of bidders at a specific coupon level
     */
    function getBiddersAtCoupon(uint256 coupon)
        internal
        view
        returns (address[] memory)
    {
        require(
            coupon >= _minCoupon && coupon <= _maxCoupon,
            "Coupon not in range"
        );
        return _investorListAtCouponLevel[coupon];
    }  

    /**
     * @dev Returns true if bidding window is open
     */
    function biddingWindowisOpen() public view returns (bool) {
        return block.timestamp <= _bidClosingTime;
    }

    // Needed to override this function as two parent classes defined the same function
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Function for an investor to register a bid.
            Needs to specify the coupon within the given range (min and max coupon)
            and send enough ether to cover the bid (number of bonds bid * face value of bond).
            Only one bid allowed per investor.    
     */
    function registerBid(uint256 coupon, uint256 numberOfBonds)
        external
        payable
        onlyWhileBiddingWindowOpen
    {
        require(
            coupon >= _minCoupon && coupon <= _maxCoupon,
            "Coupon needs to be between the set range"
        );
        require(
            msg.value >= _value * numberOfBonds,
            "Not enough ether to cover the bid"
        );
        require(
            _investorHasBid[msg.sender] == false,
            "Only one bid per investor"
        );

        // Mark that investor has made a bit
        _investorHasBid[msg.sender] = true;
        // Update bid details
        _requestedBondsPerInvestor[msg.sender] = numberOfBonds;
        _couponPerInvestor[msg.sender] = coupon;

        // Update the demand for the coupon level
        uint256 currentDemand = _bidsPerCoupon[coupon];
        _bidsPerCoupon[coupon] = currentDemand + numberOfBonds;
        
        // Add the investor to the list of investors bidding at this coupon level
        _investorListAtCouponLevel[coupon].push(msg.sender);
        
        // Update the staked amount for the investor
        _stakedAmountPerInvestor[msg.sender] = _value * numberOfBonds;

        // Emit event
        emit Bid(msg.sender, coupon, numberOfBonds);

        // Refund if overpaid
        if (msg.value > _value * numberOfBonds) {
            uint256 extraAmount = msg.value - _value * numberOfBonds;
            payable(msg.sender).transfer(extraAmount);
            emit CoinRefund(msg.sender, extraAmount);
        }
    }

    /**
     * @dev Function for the issuing institution to define the coupon.
            Finds the lowest coupon that covers the number of sought bonds
            and sets the coupon to that level. Refunds unsuccessful bidders.
            If not enough demand, coupon will not be defined and _cancelled
            will be set to false.    
     */
    function defineCoupon()
        public
        onlyWhileBiddingWindowClosed
        onlyOwner
    {
        require(_coupondefined == false, "Can't define coupon more than once");

        // Variable for the total demand for bonds
        uint256 bondDemand = 0;

        // Iterate each coupon level, and count the bonf demand to
        // determine the coupon level which will fulfills the seeked number of bonds
        for (uint256 i = _minCoupon; i <= _maxCoupon; i++) {
            // Increase the tokendemand
            bondDemand += _bidsPerCoupon[i];
            // If enough interest at this coupon level, set coupon and break the loop
            if (bondDemand >= _numberOfBondsSought) {
                _coupon = i;
                _coupondefined = true;
                break;
            }
        }
        // If there was enough demand, emits Coupon set event and
        // sets investor array for token issue
        if (_coupondefined) {
            emit CouponSet(_coupon);
            setInvestorArray();
        // Else bond issue is cancelled
        } else {
            emit CancelBondIssue(bondDemand, _numberOfBondsSought);
            _cancelled = true;
        }

        // Refund unsuccessful investors
        refundBiddersFromCouponLevel(_coupon + 1);
    }

    /**
     * @dev Internal function to set the investor array for token issue.
            Array will include all the investors who bid either at the 
            set coupon rate or lower
     */
    function setInvestorArray() internal {
        for (uint256 i = _minCoupon; i <= _coupon; i++) {
            address[] memory investors = getBiddersAtCoupon(i);
            for (uint256 j = 0; j < investors.length; j++) {
                _initialInvestors.push(investors[j]);
            }
        }
    }

    /**
     * @dev Internal function to refund investors, who bid at specified
            coupon level or above
     */
    function refundBiddersFromCouponLevel(uint256 coupon) internal {
        uint256 min;
        if (coupon < _minCoupon) {
            min = _minCoupon;
        } else {
            min = coupon;
        }

        for (uint256 i = min; i <= _maxCoupon; i++) {
            address[] memory investors = getBiddersAtCoupon(i);
            for (uint256 j = 0; j < investors.length; j++) {
                uint256 amount = _requestedBondsPerInvestor[investors[j]];
                payable(investors[j]).transfer(_value * amount);
                emit CoinRefund(investors[j], amount * _value);
                _stakedAmountPerInvestor[investors[j]] -= amount * _value;
            }
        }
    }

    /**
     * @dev Function to issue bonds for investors who bid successfully.
        Can be called only if coupon has been defined (i.e., issue has not been cancelled).
        Only owner, the issuing institution, can call the function
     */
    function issueBonds()
        public
        onlyOwner
    {
        require(
            _coupondefined == true,
            "Coupon needs to be defined."
        );

        require(_issued == false, "Can only issue bonds once");

        uint256 bondsAvailable = _numberOfBondsSought;

        // Go through the investors
        for (uint256 i = 0; i < _initialInvestors.length; i++) {
            address investor = _initialInvestors[i];
            uint256 numberOfBonds = _requestedBondsPerInvestor[investor];

            // If the demanded amount is more than bonds available
            // Issue only number of bonds available
            if (numberOfBonds > bondsAvailable) {
                // Transfer the value to company
                _company.transfer(_value * bondsAvailable);
                _totalDebt += _value * bondsAvailable;
                _stakedAmountPerInvestor[investor] -= _value * bondsAvailable;

                // Mint the tokens
                for (uint256 j = 0; j < bondsAvailable; j++) {
                    _mint(investor, _bondIdTracker.current());
                    _bondIdTracker.increment();
                }

                // Refund extra amount
                uint256 refund = _stakedAmountPerInvestor[investor]; 
                payable(investor).transfer(refund);
                emit CoinRefund(investor, refund);
                _stakedAmountPerInvestor[investor] -= refund;

                // Set bonds available to 0
                bondsAvailable = 0;

                // Else, fulfill the whole demans
            } else {
                // Transfer the value to the company
                _company.transfer(_value * numberOfBonds);
                _totalDebt += _value * numberOfBonds;
                _stakedAmountPerInvestor[investor] -= _value * numberOfBonds;

                // Mint tokens
                for (uint256 j = 0; j < numberOfBonds; j++) {
                    _mint(investor, _bondIdTracker.current());
                    _bondIdTracker.increment();
                }
                // Update the bonds available
                bondsAvailable -= numberOfBonds;
            }            
        }
        _issued = true;
    }

    /**
     * @dev Function to make a coupon payment.
            Can be called only by the borrowing company.
            Requires sending enough ether to cover a coupon payment
            (total number of bonds * coupon rate)
     */
    function makeCouponPayment() public payable {
        require(
            msg.sender == _company,
            "Only for borrowing company."
        );
        require(
            msg.value >= _coupon * _bondIdTracker.current(),
            "Not enough ether to cover the coupon payment"
        );

        for (uint256 i = 0; i < _bondIdTracker.current(); i++) {
            address payable investor = payable(ownerOf(i));
            investor.transfer(_coupon);
            emit CouponPayment(investor, i);
        }

        // Update the actual coupon payment date for the record
        _actualCouponPaymentDates[_couponsPaid] = block.timestamp;
        _couponsPaid++;

        // Refund extra coins if paid too much
        if (msg.value > _coupon * _bondIdTracker.current()) {
            uint256 extraAmount = msg.value -
                _coupon *
                _bondIdTracker.current();
            payable(msg.sender).transfer(extraAmount);
            emit CoinRefund(msg.sender, extraAmount);
        }
    }

    /**
     * @dev Function to check if a coupon payment was made on time
     */
    function couponPaymentOnTime(uint256 coupon) public view returns (string memory) {
        if(coupon < 1 || coupon > _totalCouponPayments) {
            return "That coupon does not exists.";
        }
        // Query before the due date
        if (block.timestamp < _couponPaymentDates[coupon - 1]) {
            if(_actualCouponPaymentDates[coupon - 1] != 0) {
                return "Coupon has been paid early prior to due date.";
            }
            else {
                return "Coupon not due yet.";
            }
        }
        // Query after the due date
        else {
            if(_actualCouponPaymentDates[coupon - 1] == 0) {
                return "Coupon payment is late.";
            }
            else if(_actualCouponPaymentDates[coupon - 1] <= _couponPaymentDates[coupon - 1]) {
                return "Coupon paid on time.";
            }
            
            else {
                return "Coupon paid late.";
            }
        }
    }

    /**
     * @dev Function to make a principal payment at the maturity
            Can be called only by the borrowing company.
            Requires sending enough ether to cover the full principal
            (facevalue * numer of bonds)
            Transfers the bond tokens back to the issuing company
     */
    function payBackBond() public payable {
        require(
            msg.sender == _company,
            "Only for borrowing company."
        );
        require(
            msg.value >= _totalDebt,
            "Not enough ether to settle the bond at maturity"
        );

        // Interate through the bonds
        uint256 numberOfBonds = _bondIdTracker.current();
        for (uint256 i = 0; i < numberOfBonds; i++) {
            address payable investor = payable(ownerOf(i));
            // Transfer bond token from investor to owner
            _transfer(investor, _owner, i);
            // Return funds
            investor.transfer(_value);
            // Decrement bond count
            _bondIdTracker.decrement();
        }

        // Set the payment date
        _actualPrincipalPaymentDate = block.timestamp;

        // Refund any extra ether on the contract
        if (msg.value > _totalDebt) {
            payable(msg.sender).transfer(msg.value - _totalDebt);
            emit CoinRefund(msg.sender, msg.value - _totalDebt);
        }
        // Update total debt
        _totalDebt = 0;
    }
  
    /**
     * @dev Function to check if the principal payment was made on time
     */
    function principalPaidOnTime() public view returns (string memory) {
        // Querying before the maturity date
        if(block.timestamp < _maturityDate) {
            if (_actualPrincipalPaymentDate == 0) {
                return "Principal Payment is not due yet.";
            } else {
                return "Principal was paid back early.";
            }
        }
        // Querying after the maturity date
        else {
            if(_actualPrincipalPaymentDate == 0) {
                return "Principal payment is late.";
            }
            else if(_actualPrincipalPaymentDate <= _maturityDate) {
                return "Principal was paid back on time.";
            }
            else {
                return "Principal was paid back late.";
            }
        }
    }
  
    /**
     * @dev Function to adjust the coupon
            Can be only called by the owner (issuing institution)
            Need to specify the direction of the adjustment and the amount   
     */
    function adjustCoupon(bool increase, uint256 amount) external onlyOwner {
        require(_issued == true, "Bond not issued yet.");
        uint256 previousCoupon = _coupon;
        if (increase) {
            _coupon = _coupon + amount;
        } else {
            // If adjustement would lead to negative coupon, set coupon to 0
            if (amount > _coupon) {
                _coupon = 0;
            } else {
                _coupon = _coupon - amount;
            }       
        }
        emit CouponAdjustment(previousCoupon, _coupon);
    }
}

