/**
 *Submitted for verification at Etherscan.io on 2021-09-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 *
 *        -
 *   ___/   \___
 *   Gaussian Timepieces
 *     by Takens Theorem
 *
 *   Coded mostly by someone named 'OpenZeppelin' + some twists by Takens
 * 
 *   Terms, conditions: Experimental, use at your own risk. Each token provided 
 *   as-is and as-available without any and all warranty. By using this contract 
 *   you accept sole responsibility for any and all transactions involving 
 *   Gaussian Timepieces. 
 * 
 * 
 */

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
        buffer[0] = "";
        buffer[1] = "";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4; 
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
    
    // adapted from tkeber solution: https://ethereum.stackexchange.com/a/8447
    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(s);
    }
    
    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }    
    
    // adapted from t-nicci solution https://ethereum.stackexchange.com/a/31470
    function subString(string memory str, uint startIndex, uint endIndex) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = strBytes[i];
        }
        return string(result);
    }    
    
    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
    
    // nice solution: https://ethereum.stackexchange.com/questions/56319/how-to-convert-bytes32-to-string
    function toShortString(bytes32 _data) internal pure returns (string memory) {
      bytes memory _bytesContainer = new bytes(32);
      uint256 _charCount = 0;
      // loop through every element in bytes32
      for (uint256 _bytesCounter = 0; _bytesCounter < 32; _bytesCounter++) {
        bytes1 _char = bytes1(bytes32(uint256(_data) * 2 ** (8 * _bytesCounter)));
        if (_char != 0) {
          _bytesContainer[_charCount] = _char;
          _charCount++;
        }
      }
    
      bytes memory _bytesContainerTrimmed = new bytes(_charCount);
    
      for (uint256 _charCounter = 0; _charCounter < _charCount; _charCounter++) {
        _bytesContainerTrimmed[_charCounter] = _bytesContainer[_charCounter];
      }
    
      return string(_bytesContainerTrimmed);
    }    
    
}

contract externalNft {function balanceOf(address owner) external view returns (uint256 balance) {}}

/**
 * @title GTPTT1 contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract GTPTT1 is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string private constant svg_start = "<?xml version='1.0' encoding='UTF-8'?><svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' height='1000' width='1000' viewBox='-1000 -1000 2000 2000'><rect x='-1000' y='-1000' width='2000' height='2000' fill='#ffffff' /><style>";

    // attributes json for opensea
    function makeAttributes(uint256 tokenId) private view returns (string memory) {
        (uint256 period, uint256 color, uint256 shape) = getAttributes(tokenId);
        (uint256 totToks, uint256 totProjs) = getNftBalance(ownerOf(tokenId));
        string memory colorNm = color == 0 ? 'Dark' : 'Light';
        string memory shapeNm = shape == 0 ? 'Circles' : 'Blocks';
        string memory content = string(abi.encodePacked(
            '{"trait_type":"Period","value":"', Strings.toString(period), ' blocks"},',
            '{"trait_type":"Theme","value":"', colorNm, '"},',
            '{"trait_type":"Shapes","value":"', shapeNm, '"},',
            '{"trait_type":"On-Chain Items (Owner)","value":', Strings.toString(totToks), '},',
            '{"trait_type":"On-Chain Projects (Owner)","value":', Strings.toString(totProjs), '}'
        ));
        return content; 
    }

    // render one circle svg object
    function makeCircle(uint256 i, uint256 tokenId) private view returns (string memory) {
        string memory sz = Strings.toString((vl(i, tokenId) % 128+10)*10);
        string memory fill = cl(i, tokenId);
        // 0 = filled; else ring
        if (vl(i, tokenId) % 2 == 0) {
            return string(abi.encodePacked(c[0], sz, "px' fill='#",
                    fill, "' id='c", Strings.toString(i), "' />"));        
        } 
        return string(abi.encodePacked(c[0], sz, "px' stroke='#",
                fill, "' fill='none' stroke-width='", Strings.toString(vl(i, tokenId) % 28+4),
                "pt' id='c", Strings.toString(i), "' />"));        
    }
    
    // render one rect svg object
    function makeRect(uint256 i, uint256 tokenId) private view returns (string memory) {
        uint256 sz = (vl(i, tokenId) % 128+10)*10;
        string memory fill = cl(i, tokenId);
        string memory sz_str = Strings.toString(sz);
        string memory sz2_str = Strings.toString(sz*2);
        // 0 = filled; else ring
        if (vl(i,tokenId) % 2 == 0) {
            return string(abi.encodePacked("<rect x='-",
                    sz_str, "px' y='-",
                    sz_str, "px' width='",
                    sz2_str, "px' height='",
                    sz2_str, "px' fill='#",
                    fill, "' id='c", Strings.toString(i), "' />"));        
        } 
        return string(abi.encodePacked("<rect x='-",
                sz_str, "px' y='-",
                sz_str, "px' width='",
                sz2_str, "px' height='",
                sz2_str, "px' fill='none' stroke='#",
                fill, "' stroke-width='", Strings.toString(vl(i, tokenId) % 28+4),
                "pt' id='c", Strings.toString(i), "' />"));       
    }    
    
    // define animation; clunky, but to avoid stack depth issues
    function animDefine(uint256 i, string memory x, string memory y, string memory sign1, 
                                    string memory sign2) private view returns (string memory) {
        
        string memory content = string(abi.encodePacked( // swing of a pendulum, back
            "@keyframes mv", Strings.toString(i), c[1],
            (bytes(sign1).length==0 ? "" : "-"), x, "px,",
            (bytes(sign2).length==0 ? "" : "-"), y, "px",
            ");opacity:0.25;}50%{transform:translate(0px,0px);opacity:1.0;}60%{transform:translate("
        ));
        content = string(abi.encodePacked(content, // and forth
            (bytes(sign1).length==0 ? "-" : ""), x, "px,",
            (bytes(sign2).length==0 ? "-" : ""), y, "px",
            ");opacity:0.25;}100%{transform:translate(0px,0px);opacity:1.0;}}"
        ));
        
        return content;        
    }

    // assign animation
    function animAssign(uint256 i, uint256 tm) private pure returns (string memory) {
        string memory content = string(abi.encodePacked("#c", Strings.toString(i),
            "{animation:mv", Strings.toString(i), " ", Strings.toString(tm), "s infinite ease-in-out;}"));
        return content;
    }
    
    // create style tag content for circle/rects
    function makeStyle(uint256 i, uint256 tokenId) private view returns (string memory) {
        
        (uint256 period,, uint256 shape) = getAttributes(tokenId);
        
        string memory sign1 = vl(i+1, tokenId) % 2==0 ? "-" : "";
        string memory sign2 = vl(i+2, tokenId) % 2==0 ? "-" : "";
        string memory x;
        string memory y;
        uint256 tm = period*26;
        
        if (shape == 0) { // circles
            x = Strings.toString((vl(i, tokenId) % 64)*28);
            y = Strings.toString((vl(i+1, tokenId) % 64)*28);
        } else { // rects
            uint256 f1 = i % 2;
            uint256 f2 = 1 - f1;
            x = Strings.toString(f1*(vl(i, tokenId) % 64)*28);
            y = Strings.toString(f2*(vl(i+1, tokenId) % 64)*28);
        }
        return string(abi.encodePacked(animDefine(i, x, y, sign1, sign2), animAssign(i, tm)));    
    }

    // real time marker
    function realTimeHand(uint256 tokenId, uint256 timeZone) private view returns (string memory) {
        uint256 deg = ((block.timestamp - timeZone*60*60) % 43200)/120;
        string memory content = string(abi.encodePacked("<path d='M -30 -1090 L 0 -940 L 30 -1090' stroke-width='0px' style='transform:rotate(",
            Strings.toString(deg), "deg);' id='clock' fill='#", fcl(tokenId), "' />"));
        return content;
    }

    // real time style tag
    function realTimeAnim(uint256 timeZone) private view returns (string memory) {
        uint256 deg = ((block.timestamp - timeZone*60*60) % 43200)/120;
        string memory content = string(abi.encodePacked("@keyframes clockrot{0%{transorm:rotate(",
            Strings.toString(deg), "deg);}100%{transform:rotate(",
            Strings.toString(deg+360), "deg);}}#clock{animation:clockrot 43200s linear infinite;}"));
        return content;
    }

    // hand, distribution, empirical arc, circle frames...
    function frames(uint256 tokenId) private view returns (string memory) {
        (uint256 period,,) = getAttributes(tokenId);
        
        string memory content = string(abi.encodePacked(
            
            "<circle cx='0px' cy='-", 
                Strings.toString(10+period), "px' r='",
                Strings.toString(1240+period), "px' style='transform:rotate(-",
                Strings.toString(2000/period/period),
                "deg);' id='numerarc' fill='none' stroke='#000000' stroke-width='500pt' />",

            "<circle cx='0px' cy='0px' r='1250px' id='inside' fill='none' stroke='#",
                bcl(3, tokenId), "' stroke-width='500pt' />",
                
            "<circle cx='0px' cy='0px' r='1350px' id='outside' fill='none' stroke='#",
                bcl(5, tokenId), "' stroke-width='400pt' />"
        ));
        
        content = string(abi.encodePacked(content,
        
            ticks(tokenId),
                
            "<circle cx='0px' cy='900px' r='100px' id='hand' fill='#",
                fcl(tokenId), "' />",
                
            "<path d='M-500 961 C -250 961, -250 700, 0 700, 250 700, 250 961, 500 961, A1000 1000 1 0 1 -500 961' id='gauss' fill='#",
                bcl(7, tokenId), "' />"             
                
        ));

        return content;
    }
    
    // attribs determined by tokenId
    function getAttributes(uint256 tokenId) private pure returns (uint256, uint256, uint256) {
        // period / color / shape
        return(
                2**((tokenId - 1) % 5 + 1),
                tokenId % 2 == 0 ? 1 : 0,
                tokenId % 3 == 0 ? 1 : 0
            );
    }
    
    // text adornments; awkward concatenation due to stack depth
    function accessories(uint256 tokenId) private view returns (string memory) {
        (uint256 totToks,) = getNftBalance(ownerOf(tokenId));
        (uint256 period,,) = getAttributes(tokenId);
        
        string memory content = string(abi.encodePacked(
            
            "<text x='-980px' y='920px' font-size='.8em' id='tokenId' fill='#",
                fcl(tokenId), "55'>Timepiece #", Strings.toString(tokenId), "</text>",
            
            "<text x='-980px' y='940px' font-size='.8em' id='ownerCnt' fill='#",
                fcl(tokenId), "55'>Owner on-chain count: ",
                Strings.toString(totToks), "</text>"
                
        ));
        
        content = string(abi.encodePacked(content,
        
            "<text x='-980px' y='960px' font-size='.8em' id='signat' fill='#",
                fcl(tokenId), "55'>takenstheorem 2021 | Gaussian Timepieces</text>",
        
            "<text x='-980px' y='980px' font-size='.8em' id='owner' fill='#",
                fcl(tokenId), "55'>Owner: 0x", Strings.toAsciiString(ownerOf(tokenId)), "</text>"
                
        ));        
        
        content = string(abi.encodePacked(content,
        
            "<text x='0px' y='860px' font-size='5em' fill='#",
                fcl(tokenId), "66' text-anchor='middle' dominant-baseline='central' id='blockPeriod'>+",
                Strings.toString(period), "</text>",
        
            "<text x='0px' y='770px' font-size='2.8em' fill='#",
                fcl(tokenId), "aa' text-anchor='middle' dominant-baseline='central' id='gasPrice'>",
                rep(2, tokenId), "</text>"
                
        ));
        
        content = string(abi.encodePacked(content,
        
            "<text x='-180px' y='940px' font-size='2.1em' fill='#",
                fcl(tokenId), "66' text-anchor='middle' dominant-baseline='central' id='blockSt'>",
                Strings.toString(block.number), "</text>",    
                
            "<text x='+180px' y='940px' font-size='2.1em' fill='#",
                fcl(tokenId), "66' text-anchor='middle' dominant-baseline='central' id='blockEnd'>",
                Strings.toString(block.number+period), "</text>"
            
        ));

        return content;
    }
    
    string ncp = 'WAIT';
    string[] private c = ['', ''];
    function setStr(string memory val) public onlyOwner {
        require(bytes(ncp).length > 0, 'ERROR: Already configured');
        if (bytes(c[0]).length == 0) {
            c[0] = val;
        } else if (bytes(c[1]).length == 0) {
            c[1] = val;
        } else if (bytes(ncp).length > 0) {
            ncp = val;        
        }
    }    
    
    // repeat chars; used for bezel and gas price
    function rep(uint256 char, uint256 tokenId) private view returns (string memory) {
        
        if (char == 2) {
            uint256 gasVal = (block.basefee / 1000000000) / 25;
            if (gasVal > 12) {
                gasVal = 12;
            }
            return Strings.subString("****************", 0, gasVal+1);
        }
        
        (uint256 totToks,uint256 totProjs) = getNftBalance(ownerOf(tokenId));
        if (totToks > 30) {
            totToks = 30;
        }
        
        if (char == 0) { 
            return Strings.subString("|||||||||||||||||||||||||||||||||||", 0, totToks);
        } else {
            return Strings.subString("|||||||||||||||||||||||||||||||||||", 0, 2*totProjs);
        }
    }
    
    // ticks of ownership on-chain on left/right bezel
    function ticks(uint256 tokenId) private view returns (string memory) {
        
        string memory content = string(abi.encodePacked(
            
            "<path d='M400 920 A950 950 180 0 0 -400 -920' stroke='none' fill='none' id='numProjPath' />",
            
            "<text font-size='3em' id='numProjOn' fill='#",
                fcl(tokenId), "'><textPath textLength='2600' href='#numProjPath'>",
                rep(0, tokenId), "</textPath></text>"    
            
        ));
        
        content = string(abi.encodePacked(content,
            
            "<path d='M-400 920 A950 950 -180 1 1 400 -920' stroke='none' fill='none' id='numNftPath' />",
            
            "<text font-size='3em' id='numNftOn' fill='#",
                fcl(tokenId), "' dominant-baseline='hanging' ><textPath textLength='2600' href='#numNftPath'>",
                rep(1, tokenId), "</textPath></text>"
        
        ));
        
        return content;
        
    }

    // compute # of on-chain nfts and # of projects owned
    function getNftBalance(address addr) private view returns (uint256, uint256) { // totTok,totProjs
        uint256[] memory projCounts = new uint256[](15);
        projCounts[0] = externalNft(0x31C70e9a1BAb16f47710E4B302c49998Cfb36ef9).balanceOf(addr); // CryptoSketches
        projCounts[1] = externalNft(0xd4e4078ca3495DE5B1d4dB434BEbc5a986197782).balanceOf(addr); // Autoglyphs
        projCounts[2] = externalNft(0x60F3680350F65Beb2752788cB48aBFCE84a4759E).balanceOf(addr); // Colorglyphs
        projCounts[3] = externalNft(0x91047Abf3cAb8da5A9515c8750Ab33B4f1560a7A).balanceOf(addr); // ChainFaces
        projCounts[4] = externalNft(0xF3E778F839934fC819cFA1040AabaCeCBA01e049).balanceOf(addr); // Avastars
        projCounts[5] = externalNft(0x36F379400DE6c6BCDF4408B282F8b685c56adc60).balanceOf(addr); // Squiggly
        projCounts[6] = externalNft(0xB2D6fb1Dc231F97F8cC89467B52F7C4F78484044).balanceOf(addr); // Neolastics
        projCounts[7] = externalNft(0x46F9A4522666d2476a5F5Cd51ea3E0b5800E7f98).balanceOf(addr); // TinyBoxes
        projCounts[8] = externalNft(0x8FdDE660C3cCAb82756AcC5233687a4CeB4B8f30).balanceOf(addr); // Etherpoems
        projCounts[9] = externalNft(0x8d04a8c79cEB0889Bdd12acdF3Fa9D207eD3Ff63).balanceOf(addr); // Blitmap
        projCounts[10] = externalNft(0xDaCa87395f3b1Bbc46F3FA187e996E03a5dCc985).balanceOf(addr); // Mandala
        projCounts[11] = externalNft(0x5D4683bA64Ee6283bB7FDB8A91252F6aAB32A110).balanceOf(addr); // Genesis [sol]Seedlings
        projCounts[12] = externalNft(0xEA61926B4C8B5f8E2bC6f85C0BD800969dc79fcf).balanceOf(addr); // 512 [sol]Seedlings
        projCounts[13] = externalNft(0xd31fC221D2b0E0321C43E9F6824b26ebfFf01D7D).balanceOf(addr); // Brotchain
        projCounts[14] = externalNft(0xf76c5d925b27a63a3745A6b787664A7f38fA79bd).balanceOf(addr); // the_coin
        
        uint256 totToks = 0;
        uint256 totProjs = 0;
        for (uint256 i = 0; i < 15; i++){
            totToks = totToks + projCounts[i];
            if (projCounts[i] > 0) {
                totProjs = totProjs + 1;    
            }
        }
        
        return(totToks, totProjs);
    }

    // build all style tag contents
    function buildAllStyles(uint256 tokenId, uint256 nEls) private view returns (string memory) {
        string memory content = '';
        for (uint256 i = 0; i < nEls; i++) {
            content = string(abi.encodePacked(content, makeStyle(i,tokenId)));
        }        
        return content;
    }
    
    // build all svg elements
    function buildAllEls(uint256 tokenId, uint256 nEls) private view returns (string memory) {
        (,,uint256 shape) = getAttributes(tokenId);
        string memory content = '';
        uint256 i = nEls;
        while (i != 0) { // decouple colors/locs
            i = i - 1;
            if (shape == 0) {
                content = string(abi.encodePacked(content, makeCircle(i, tokenId)));        
            } else {
                content = string(abi.encodePacked(content, makeRect(i, tokenId)));        
            }
        }        
        return content;
    }
    
    // raw svg
    function reveal(uint256 tokenId, uint256 timeZone) public view returns (string memory) {
        require(bytes(ncp).length == 0, "ERROR: Misconfigured");
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        (uint256 totToks,) = getNftBalance(ownerOf(tokenId));
        (uint256 period,,) = getAttributes(tokenId);
        
        uint256 nEls = period/2 + ownerOf(tokenId).balance / 1000000000000000000 + totToks;
        if (nEls > 16) {
            nEls = 16;
        }
        
        string memory content = buildAllStyles(tokenId, nEls);

        content = string(abi.encodePacked(content, "@keyframes handrot{0%{transorm:rotate(0deg);}100%{transform:rotate(360deg);}}#hand{animation:handrot ",
             Strings.toString(period*13), "s linear infinite;}", realTimeAnim(timeZone),"</style>"));

        content = string(abi.encodePacked(content, buildAllEls(tokenId, nEls)));

        bytes memory _img = abi.encodePacked(svg_start, content,
                frames(tokenId), accessories(tokenId), realTimeHand(tokenId, timeZone),
                 '</svg>'
             );
        return string(_img);
    }

    function mintNFT_n(uint256 n) public onlyOwner {
        require(_tokenIds.current() < 100,'ERROR: minting complete');
        for (uint i = 0; i < n; i++) {
            if (_tokenIds.current() == 100) { // avoid accidental overring
                break;
            }
            _tokenIds.increment();
            uint256 newItemId = _tokenIds.current();
            _mint(msg.sender, newItemId);
        }
    }

    // to single string
    function ts1(address addr, uint256 i1) private pure returns (string memory) {
        return Strings.subString(Strings.toAsciiString(addr), i1, i1+1); 
    }
    
    // to double string
    function ts2(address addr, uint256 i1) private pure returns (string memory) {
        return Strings.subString(Strings.toAsciiString(addr), i1, i1+2); 
    }
    
    // make random color
    function cl(uint256 i, uint256 tokenId) private view returns (string memory) {
        address baseContent = address(getRandBase(tokenId));
        return Strings.subString(Strings.toAsciiString(baseContent), i, i+6);    
    }
    
    // get bg color byte
    function gbcl(string memory cols, uint256 i, uint256 tokenId) private view returns (string memory) {
        return Strings.subString(cols, vl(i,tokenId)%5, vl(i,tokenId)%5+1);
    }
    
    // get random base for vl and other pseudorandom functions
    function getRandBase(uint256 tokenId) private view returns (bytes20) {
        (uint256 period,,) = getAttributes(tokenId);
        return bytes20(keccak256(abi.encodePacked(ownerOf(tokenId), block.number / period, tokenId)));
    }
    
    // background color
    function bcl(uint256 i, uint256 tokenId) private view returns (string memory) {
        (,uint256 color,) = getAttributes(tokenId);
        address baseContent = address(getRandBase(tokenId));
        string[] memory bgc = new string[](3);
        if (color == 0) { // dark mode
            bgc[0] = gbcl("1234567", i, tokenId); 
            bgc[1] = gbcl("1234567", i+1, tokenId);
            bgc[2] = gbcl("1234567", i+2, tokenId);
            return string(abi.encodePacked(
                bgc[0], ts1(baseContent, i),
                bgc[1], ts1(baseContent, i+2),
                bgc[2], ts1(baseContent, i+4)));
        } else { // light mode
            bgc[0] = gbcl("9abcde", i, tokenId);
            bgc[1] = gbcl("9abcde", i+1, tokenId);
            bgc[2] = gbcl("9abcde", i+2, tokenId);
            return string(abi.encodePacked(
                bgc[0], ts1(baseContent, i),
                bgc[1], ts1(baseContent, i+2),
                bgc[2], ts1(baseContent, i+4)));
        }
    }
    
    // foreground
    function fcl(uint256 tokenId) private pure returns (string memory) {
        (,uint256 color,) = getAttributes(tokenId);
        if (color == 0) {
            return 'ffffff';
        } 
        return '000000';
    }    
    
    // pseudorandom value
    function vl(uint256 i, uint256 tokenId) private view returns (uint256) {
        bytes20 baseContent = getRandBase(tokenId);
        return uint256(uint8(baseContent[i]));
    }
    
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(bytes(ncp).length==0, "ERROR: Misconfigured");
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        
        bytes memory json = abi.encodePacked('{"name":"', string(abi.encodePacked('Timepiece #', Strings.toString(tokenId))),
                                            '", "description":"Transitions across stochasticity towards another inevitable block height.',
                                            '", "attributes":[', makeAttributes(tokenId),
                                            '], "created_by":"Takens Theorem", "image":"',
            reveal(tokenId, 0), '"}');
        
        return string(abi.encodePacked('data:text/plain,', json));
        
    }
     
    constructor() ERC721("Gaussian Timepieces by Takens Theorem", "GTPTT1") {}    
}