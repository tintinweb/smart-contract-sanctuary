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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
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
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
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

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
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
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
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
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
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
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
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
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
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
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

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
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
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
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
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

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "./TokenSale.sol";

contract TokenAuctions is TokenSale {
  using SafeMath for uint256;
  using Counters for Counters.Counter;

  function _resetArtworkAuctionParams(uint256 artworkID) internal {
    artworkOnXYZ[artworkID]
      .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
      .bidType == BidTypes.NONE;
    artworkOnXYZ[artworkID]
      .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
      .minimumValidBid = 0;
    artworkOnXYZ[artworkID]
      .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
      .reserveCheck = "";
    artworkOnXYZ[artworkID]
      .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
      .isReservedPriceReached = false;
    artworkOnXYZ[artworkID]
      .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
      .expiryAuctionTimestamp = 0;
  }

  function _resetArtworkAuctionBidParams(uint256 artworkID, uint256 bidIndex)
    internal
  {
    artworkOnXYZ[artworkID]
      .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
      .bidsOnItem[bidIndex]
      .amount = 0;
    artworkOnXYZ[artworkID]
      .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
      .bidsOnItem[bidIndex]
      .beneficiaryAddress = payable(0x0);
    artworkOnXYZ[artworkID]
      .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
      .bidsOnItem[bidIndex]
      .bidExpiryTimestamp = 0;
  }

  function _setArtworkAuctionParams(
    uint256 artworkID,
    BidTypes bidType,
    uint256 minimumValidBid,
    bytes32 reservePrice,
    uint256 expiryTimestamp
  ) internal {
    artworkOnXYZ[artworkID]
      .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
      .bidType = bidType;
    artworkOnXYZ[artworkID]
      .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
      .minimumValidBid = minimumValidBid;
    artworkOnXYZ[artworkID]
      .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
      .reserveCheck = reservePrice;
    artworkOnXYZ[artworkID]
      .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
      .isReservedPriceReached = false;
    artworkOnXYZ[artworkID]
      .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
      .expiryAuctionTimestamp = expiryTimestamp;
  }

  function enableAuctionOnItem(
    uint256 artworkID,
    BidTypes bidType,
    uint256 minimumValidBid,
    bytes32 reservePrice,
    uint256 expiryTimestamp
  ) external returns (bool) {
    _artworkStatusNotOpenForBid(artworkID);
    _onlyArtworkOwner(artworkID);
    _artworkStatusNotForSale(artworkID);
    _artworkNotPausedForTradeByContractOwner(artworkID);
    _artworkNotPausedForTrade(artworkID);

    if (bidType == BidTypes.TIMEDAUCTION) {
      require(
        expiryTimestamp > block.timestamp,
        "Expiry timestamp should be greater than current time"
      );
    } else if (bidType != BidTypes.UNLIMITEDAUCTION) {
      revert("Invalid Bidding type");
    }

    artworkOnXYZ[artworkID].openForBid = true;

    _setArtworkAuctionParams(
      artworkID,
      bidType,
      minimumValidBid,
      reservePrice,
      expiryTimestamp
    );

    _transfer(msg.sender, address(this), artworkID);

    emit UpdatedArtworkToOpenForAuction(
      artworkID,
      artworkOnXYZ[artworkID].openForBid,
      minimumValidBid,
      expiryTimestamp,
      msg.sender
    );

    return true;
  }

  function cancelAuctionOnItem(uint256 artworkID) external returns (bool) {
    _artworkStatusOpenForBid(artworkID);
    _onlyArtworkOwner(artworkID);
    _artworkStatusNotForSale(artworkID);
    _artworkNotPausedForTrade(artworkID);
    _artworkNotPausedForTradeByContractOwner(artworkID);

    if (
      artworkOnXYZ[artworkID]
        .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
        .bidType == BidTypes.TIMEDAUCTION
    ) {
      _artworkAuctionNotEnded(artworkID);
      _resetArtworkAuctionParams(artworkID);
      if (
        artworkOnXYZ[artworkID]
          .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
          .openBidsOnAuction
          .current() == 1
      ) {
        artworkOnXYZ[artworkID]
          .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
          .bidsOnItem[
            artworkOnXYZ[artworkID]
              .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
              .openBidsOnAuction
              .current()
          ]
          .beneficiaryAddress
          .transfer(
            artworkOnXYZ[artworkID]
              .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
              .bidsOnItem[
                artworkOnXYZ[artworkID]
                  .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
                  .openBidsOnAuction
                  .current()
              ]
              .amount
          );

        emit RefundedBidOnArtwork(
          artworkID,
          artworkOnXYZ[artworkID]
            .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
            .bidsOnItem[
              artworkOnXYZ[artworkID]
                .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
                .openBidsOnAuction
                .current()
            ]
            .beneficiaryAddress,
          artworkOnXYZ[artworkID]
            .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
            .bidsOnItem[
              artworkOnXYZ[artworkID]
                .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
                .openBidsOnAuction
                .current()
            ]
            .amount
        );
        artworkOnXYZ[artworkID]
          .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
          .openBidsOnAuction
          .decrement();
      }

      artworkOnXYZ[artworkID].openForBid = false;
    } else if (
      artworkOnXYZ[artworkID]
        .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
        .bidType == BidTypes.UNLIMITEDAUCTION
    ) {
      uint256 availableBids = artworkOnXYZ[artworkID]
        .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
        .openBidsOnAuction
        .current();

      if (availableBids > 0) {
        for (uint256 index = 1; index <= availableBids; index++) {
          if (
            artworkOnXYZ[artworkID]
              .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
              .bidsOnItem[index]
              .amount != 0
          ) {
            artworkOnXYZ[artworkID]
              .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
              .bidsOnItem[index]
              .beneficiaryAddress
              .transfer(
                artworkOnXYZ[artworkID]
                  .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
                  .bidsOnItem[index]
                  .amount
              );

            emit RefundedBidOnArtwork(
              artworkID,
              artworkOnXYZ[artworkID]
                .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
                .bidsOnItem[index]
                .beneficiaryAddress,
              artworkOnXYZ[artworkID]
                .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
                .bidsOnItem[index]
                .amount
            );

            _resetArtworkAuctionBidParams(artworkID, index);
          }
        }
      }

      _resetArtworkAuctionParams(artworkID);

      artworkOnXYZ[artworkID]
        .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
        .openBidsOnAuction
        ._value = 0;

      artworkOnXYZ[artworkID].openForBid = false;
    } else {
      revert("Invalid Bidding type");
    }

    _transfer(address(this), artworkOnXYZ[artworkID].owner, artworkID);

    emit AuctionCancelled(artworkID, msg.sender);

    return true;
  }

  function encryptData(string memory data) external pure returns (bytes32) {
    return keccak256(abi.encodePacked(data));
  }

  function finalizeTimedAuction(
    uint256 artworkID,
    string memory reservePriceCheck
  ) external returns (bool) {
    _onlyArtworkOwner(artworkID);
    _artworkStatusOpenForBid(artworkID);
    _artworkStatusNotForSale(artworkID);
    _artworkNotPausedForTrade(artworkID);
    _artworkNotPausedForTradeByContractOwner(artworkID);
    _artworkOnTimedAuction(artworkID);
    _artworkAuctionEnded(artworkID);

    if (
      artworkOnXYZ[artworkID]
        .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
        .openBidsOnAuction
        .current() == 0
    ) {
      artworkOnXYZ[artworkID].openForBid = false;

      _resetArtworkAuctionParams(artworkID);

      _transfer(address(this), artworkOnXYZ[artworkID].owner, artworkID);

      emit AuctionReverted(artworkID, msg.sender);
    } else if (
      artworkOnXYZ[artworkID]
        .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
        .reserveCheck == keccak256(abi.encodePacked(reservePriceCheck))
    ) {
      artworkOnXYZ[artworkID]
        .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
        .bidType = BidTypes.NONE;
      artworkOnXYZ[artworkID]
        .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
        .minimumValidBid = 0;
      artworkOnXYZ[artworkID].price = artworkOnXYZ[artworkID]
        .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
        .bidsOnItem[
          artworkOnXYZ[artworkID]
            .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
            .openBidsOnAuction
            .current()
        ]
        .amount;
      artworkOnXYZ[artworkID]
        .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
        .expiryAuctionTimestamp = 0;

      XYZWallet.transfer(artworkOnXYZ[artworkID].price);

      emit TransferredBidToPlatformWallet(
        artworkID,
        address(this),
        XYZWallet,
        artworkOnXYZ[artworkID].price
      );

      artworkOnXYZ[artworkID].ownershipTransferCount.increment();

      artworkOnXYZ[artworkID].owner = artworkOnXYZ[artworkID]
        .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
        .bidsOnItem[
          artworkOnXYZ[artworkID]
            .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
            .openBidsOnAuction
            .current()
        ]
        .beneficiaryAddress;

      artworkOnXYZ[artworkID].openForBid = false;

      _resetArtworkAuctionBidParams(
        artworkID,
        artworkOnXYZ[artworkID]
          .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
          .openBidsOnAuction
          .current()
      );

      artworkOnXYZ[artworkID]
        .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
        .openBidsOnAuction
        .decrement();

      _transfer(address(this), artworkOnXYZ[artworkID].owner, artworkID);

      emit ownershipTransferredOfArtwork(
        artworkID,
        artworkOnXYZ[artworkID].ownershipTransferCount.current(),
        artworkOnXYZ[artworkID].owner,
        artworkOnXYZ[artworkID].price,
        artworkOnXYZ[artworkID].owner
      );
    } else {
      _resetArtworkAuctionParams(artworkID);

      artworkOnXYZ[artworkID]
        .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
        .bidsOnItem[
          artworkOnXYZ[artworkID]
            .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
            .openBidsOnAuction
            .current()
        ]
        .beneficiaryAddress
        .transfer(
          artworkOnXYZ[artworkID]
            .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
            .bidsOnItem[
              artworkOnXYZ[artworkID]
                .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
                .openBidsOnAuction
                .current()
            ]
            .amount
        );

      emit RefundedBidOnArtwork(
        artworkID,
        artworkOnXYZ[artworkID]
          .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
          .bidsOnItem[
            artworkOnXYZ[artworkID]
              .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
              .openBidsOnAuction
              .current()
          ]
          .beneficiaryAddress,
        artworkOnXYZ[artworkID]
          .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
          .bidsOnItem[
            artworkOnXYZ[artworkID]
              .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
              .openBidsOnAuction
              .current()
          ]
          .amount
      );

      artworkOnXYZ[artworkID].openForBid = false;

      _resetArtworkAuctionBidParams(
        artworkID,
        artworkOnXYZ[artworkID]
          .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
          .openBidsOnAuction
          .current()
      );

      artworkOnXYZ[artworkID]
        .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
        .openBidsOnAuction
        .decrement();

      _transfer(address(this), artworkOnXYZ[artworkID].owner, artworkID);

      emit AuctionReverted(artworkID, msg.sender);
    }
    return true;
  }

  function approveAndFinalizeUnlimitedAuction(
    uint256 artworkID,
    uint256 approveBidId
  ) external returns (bool) {
    _onlyArtworkOwner(artworkID);
    _artworkStatusOpenForBid(artworkID);
    _artworkStatusNotForSale(artworkID);
    _artworkNotPausedForTrade(artworkID);
    _artworkNotPausedForTradeByContractOwner(artworkID);
    _artworkOnUnlimitedAuction(artworkID);

    uint256 availableBids = artworkOnXYZ[artworkID]
      .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
      .openBidsOnAuction
      .current();

    if (availableBids > 0) {
      require(
        artworkOnXYZ[artworkID]
          .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
          .bidsOnItem[approveBidId]
          .bidExpiryTimestamp > block.timestamp,
        "Selected bid is expired"
      );

      require(
        artworkOnXYZ[artworkID]
          .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
          .bidsOnItem[approveBidId]
          .amount != 0,
        "Selected bid is 0"
      );

      artworkOnXYZ[artworkID].price = artworkOnXYZ[artworkID]
        .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
        .bidsOnItem[approveBidId]
        .amount;

      artworkOnXYZ[artworkID].owner = artworkOnXYZ[artworkID]
        .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
        .bidsOnItem[approveBidId]
        .beneficiaryAddress;

      _resetArtworkAuctionBidParams(artworkID, approveBidId);

      XYZWallet.transfer(artworkOnXYZ[artworkID].price);

      emit TransferredBidToPlatformWallet(
        artworkID,
        address(this),
        XYZWallet,
        artworkOnXYZ[artworkID].price
      );

      for (uint256 index = 1; index <= availableBids; index++) {
        if (
          artworkOnXYZ[artworkID]
            .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
            .bidsOnItem[index]
            .amount != 0
        ) {
          artworkOnXYZ[artworkID]
            .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
            .bidsOnItem[index]
            .beneficiaryAddress
            .transfer(
              artworkOnXYZ[artworkID]
                .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
                .bidsOnItem[index]
                .amount
            );

          emit RefundedBidOnArtwork(
            artworkID,
            artworkOnXYZ[artworkID]
              .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
              .bidsOnItem[index]
              .beneficiaryAddress,
            artworkOnXYZ[artworkID]
              .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
              .bidsOnItem[index]
              .amount
          );

          _resetArtworkAuctionBidParams(artworkID, approveBidId);
        }
      }

      artworkOnXYZ[artworkID].ownershipTransferCount.increment();

      artworkOnXYZ[artworkID]
        .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
        .openBidsOnAuction
        ._value = 0;

      _transfer(address(this), artworkOnXYZ[artworkID].owner, artworkID);

      emit ownershipTransferredOfArtwork(
        artworkID,
        artworkOnXYZ[artworkID].ownershipTransferCount.current(),
        artworkOnXYZ[artworkID].owner,
        artworkOnXYZ[artworkID].price,
        artworkOnXYZ[artworkID].owner
      );
    } else {
      artworkOnXYZ[artworkID].openForBid = false;

      _resetArtworkAuctionParams(artworkID);
      _transfer(address(this), artworkOnXYZ[artworkID].owner, artworkID);

      emit AuctionReverted(artworkID, msg.sender);
    }

    return true;
  }

  function claimArtworkAfterTimedAuction(uint256 artworkID)
    external
    returns (bool)
  {
    _artworkStatusOpenForBid(artworkID);
    _artworkStatusNotForSale(artworkID);
    _artworkNotPausedForTrade(artworkID);
    _artworkNotPausedForTradeByContractOwner(artworkID);
    _artworkAuctionEnded(artworkID);

    require(
      msg.sender ==
        artworkOnXYZ[artworkID]
          .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
          .bidsOnItem[
            artworkOnXYZ[artworkID]
              .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
              .openBidsOnAuction
              .current()
          ]
          .beneficiaryAddress,
      "You are not the highest bidder"
    );

    if (
      artworkOnXYZ[artworkID]
        .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
        .openBidsOnAuction
        .current() == 0
    ) {
      artworkOnXYZ[artworkID].openForBid = false;
      _resetArtworkAuctionParams(artworkID);

      _transfer(address(this), artworkOnXYZ[artworkID].owner, artworkID);

      emit AuctionReverted(artworkID, msg.sender);
    } else if (
      artworkOnXYZ[artworkID]
        .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
        .isReservedPriceReached
    ) {
      artworkOnXYZ[artworkID]
        .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
        .bidType = BidTypes.NONE;
      artworkOnXYZ[artworkID]
        .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
        .minimumValidBid = 0;
      artworkOnXYZ[artworkID].price = artworkOnXYZ[artworkID]
        .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
        .bidsOnItem[
          artworkOnXYZ[artworkID]
            .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
            .openBidsOnAuction
            .current()
        ]
        .amount;
      artworkOnXYZ[artworkID]
        .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
        .expiryAuctionTimestamp = 0;

      XYZWallet.transfer(artworkOnXYZ[artworkID].price);

      emit TransferredBidToPlatformWallet(
        artworkID,
        address(this),
        XYZWallet,
        artworkOnXYZ[artworkID].price
      );

      artworkOnXYZ[artworkID].ownershipTransferCount.increment();

      artworkOnXYZ[artworkID].owner = artworkOnXYZ[artworkID]
        .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
        .bidsOnItem[
          artworkOnXYZ[artworkID]
            .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
            .openBidsOnAuction
            .current()
        ]
        .beneficiaryAddress;

      _resetArtworkAuctionBidParams(
        artworkID,
        artworkOnXYZ[artworkID]
          .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
          .openBidsOnAuction
          .current()
      );

      artworkOnXYZ[artworkID]
        .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
        .openBidsOnAuction
        .decrement();

      artworkOnXYZ[artworkID].openForBid = false;

      _transfer(address(this), artworkOnXYZ[artworkID].owner, artworkID);

      emit ownershipTransferredOfArtwork(
        artworkID,
        artworkOnXYZ[artworkID].ownershipTransferCount.current(),
        artworkOnXYZ[artworkID].owner,
        artworkOnXYZ[artworkID].price,
        artworkOnXYZ[artworkID].owner
      );
    } else {
      _resetArtworkAuctionParams(artworkID);

      artworkOnXYZ[artworkID]
        .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
        .bidsOnItem[
          artworkOnXYZ[artworkID]
            .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
            .openBidsOnAuction
            .current()
        ]
        .beneficiaryAddress
        .transfer(
          artworkOnXYZ[artworkID]
            .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
            .bidsOnItem[
              artworkOnXYZ[artworkID]
                .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
                .openBidsOnAuction
                .current()
            ]
            .amount
        );

      emit RefundedBidOnArtwork(
        artworkID,
        artworkOnXYZ[artworkID]
          .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
          .bidsOnItem[
            artworkOnXYZ[artworkID]
              .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
              .openBidsOnAuction
              .current()
          ]
          .beneficiaryAddress,
        artworkOnXYZ[artworkID]
          .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
          .bidsOnItem[
            artworkOnXYZ[artworkID]
              .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
              .openBidsOnAuction
              .current()
          ]
          .amount
      );

      _resetArtworkAuctionBidParams(
        artworkID,
        artworkOnXYZ[artworkID]
          .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
          .openBidsOnAuction
          .current()
      );

      artworkOnXYZ[artworkID]
        .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
        .openBidsOnAuction
        .decrement();

      artworkOnXYZ[artworkID].openForBid = false;

      _transfer(address(this), artworkOnXYZ[artworkID].owner, artworkID);

      emit AuctionReverted(artworkID, msg.sender);
    }
    return true;
  }

  function claimBidOnUmlimitedAuctionAfterExpiry(
    uint256 artworkID,
    uint256 claimBidID
  ) external returns (bool) {
    _artworkStatusOpenForBid(artworkID);
    _artworkStatusNotForSale(artworkID);
    _notArtworkOwner(artworkID);
    require(
      msg.sender ==
        artworkOnXYZ[artworkID]
          .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
          .bidsOnItem[claimBidID]
          .beneficiaryAddress,
      "You are not the bidder"
    );

    require(
      block.timestamp >
        artworkOnXYZ[artworkID]
          .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
          .bidsOnItem[claimBidID]
          .bidExpiryTimestamp,
      "Your bid is not expired"
    );

    artworkOnXYZ[artworkID]
      .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
      .bidsOnItem[claimBidID]
      .beneficiaryAddress
      .transfer(
        artworkOnXYZ[artworkID]
          .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
          .bidsOnItem[claimBidID]
          .amount
      );

    emit ClaimedBidOnUnlimitedAuction(
      artworkOnXYZ[artworkID]
        .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
        .bidsOnItem[claimBidID]
        .beneficiaryAddress,
      artworkOnXYZ[artworkID]
        .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
        .bidsOnItem[claimBidID]
        .amount,
      artworkOnXYZ[artworkID]
        .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
        .bidsOnItem[claimBidID]
        .bidExpiryTimestamp
    );

    _resetArtworkAuctionBidParams(artworkID, claimBidID);

    return true;
  }

  function bidOnTimedAuction(uint256 artworkID)
    external
    payable
    returns (bool)
  {
    _artworkStatusOpenForBid(artworkID);
    _notArtworkOwner(artworkID);
    _artworkNotPausedForTrade(artworkID);
    _artworkNotPausedForTradeByContractOwner(artworkID);
    _artworkStatusNotOpenForBid(artworkID);
    _artworkAuctionNotEnded(artworkID);
    _isValidBidAuction(artworkID);

    require(
      msg.value >
        artworkOnXYZ[artworkID]
          .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
          .bidsOnItem[
            artworkOnXYZ[artworkID]
              .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
              .openBidsOnAuction
              .current()
          ]
          .amount,
      "Bid less than other available bid"
    );

    if (
      artworkOnXYZ[artworkID]
        .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
        .openBidsOnAuction
        .current() == 1
    ) {
      refundExistingOffer(artworkID);
    } else {
      artworkOnXYZ[artworkID]
        .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
        .openBidsOnAuction
        .increment();
    }

    artworkOnXYZ[artworkID]
      .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
      .bidsOnItem[
        artworkOnXYZ[artworkID]
          .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
          .openBidsOnAuction
          .current()
      ]
      .beneficiaryAddress = payable(msg.sender);
    artworkOnXYZ[artworkID]
      .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
      .bidsOnItem[
        artworkOnXYZ[artworkID]
          .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
          .openBidsOnAuction
          .current()
      ]
      .amount = msg.value;

    emit NewBidOnArtwork(artworkID, msg.sender, msg.value);

    return true;
  }

  function bidOnUnlimitedAuction(uint256 artworkID, uint256 bidExpiryTime)
    external
    payable
    returns (bool)
  {
    _artworkStatusOpenForBid(artworkID);
    _notArtworkOwner(artworkID);
    _artworkNotPausedForTrade(artworkID);
    _artworkNotPausedForTradeByContractOwner(artworkID);
    _artworkOnUnlimitedAuction(artworkID);
    _isValidBidAuction(artworkID);

    artworkOnXYZ[artworkID]
      .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
      .openBidsOnAuction
      .increment();

    artworkOnXYZ[artworkID]
      .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
      .bidsOnItem[
        artworkOnXYZ[artworkID]
          .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
          .openBidsOnAuction
          .current()
      ]
      .beneficiaryAddress = payable(msg.sender);
    artworkOnXYZ[artworkID]
      .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
      .bidsOnItem[
        artworkOnXYZ[artworkID]
          .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
          .openBidsOnAuction
          .current()
      ]
      .amount = msg.value;
    artworkOnXYZ[artworkID]
      .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
      .bidsOnItem[
        artworkOnXYZ[artworkID]
          .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
          .openBidsOnAuction
          .current()
      ]
      .bidExpiryTimestamp = bidExpiryTime;

    emit NewBidOnArtwork(artworkID, msg.sender, msg.value);

    return true;
  }

  function refundExistingOffer(uint256 artworkID) internal returns (bool) {
    artworkOnXYZ[artworkID]
      .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
      .bidsOnItem[
        artworkOnXYZ[artworkID]
          .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
          .openBidsOnAuction
          .current()
      ]
      .beneficiaryAddress
      .transfer(
        artworkOnXYZ[artworkID]
          .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
          .bidsOnItem[
            artworkOnXYZ[artworkID]
              .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
              .openBidsOnAuction
              .current()
          ]
          .amount
      );

    emit RefundedBidOnArtwork(
      artworkID,
      artworkOnXYZ[artworkID]
        .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
        .bidsOnItem[
          artworkOnXYZ[artworkID]
            .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
            .openBidsOnAuction
            .current()
        ]
        .beneficiaryAddress,
      artworkOnXYZ[artworkID]
        .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
        .bidsOnItem[
          artworkOnXYZ[artworkID]
            .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
            .openBidsOnAuction
            .current()
        ]
        .amount
    );
    return true;
  }

  function updateArtworkAuctionDetails(
    uint256 artworkID,
    uint256 minimumValidBid,
    uint256 expiryTimestamp
  ) external whenNotPaused returns (bool) {
    _onlyArtworkOwner(artworkID);
    _artworkStatusOpenForBid(artworkID);

    artworkOnXYZ[artworkID]
      .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
      .minimumValidBid = minimumValidBid;

    artworkOnXYZ[artworkID]
      .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
      .expiryAuctionTimestamp = expiryTimestamp;

    emit UpdatedAuctionArtworkDetails(
      artworkID,
      minimumValidBid,
      expiryTimestamp,
      msg.sender
    );
    return true;
  }

  function updateReservePriceCheckArtwork(
    uint256 artworkID,
    bool isReservePrice
  ) external whenNotPaused onlyOwner returns (bool) {
    _artworkStatusOpenForBid(artworkID);

    artworkOnXYZ[artworkID]
      .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
      .isReservedPriceReached = isReservePrice;

    emit UpdatedAuctionArtworkReservePriceCheck(
      artworkID,
      isReservePrice,
      msg.sender
    );
    return true;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract TokenCore is ERC721URIStorage, Ownable, Pausable {
  using SafeMath for uint256;
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  enum BidTypes {
    NONE,
    TIMEDAUCTION,
    UNLIMITEDAUCTION
  }

  enum ArtworkStatus {
    NOTFORSALE,
    OPENFORSALE
  }

  struct ArtworkBids {
    address payable beneficiaryAddress;
    uint256 amount;
    uint256 bidExpiryTimestamp;
  }

  struct ArtAuction {
    BidTypes bidType;
    uint256 minimumValidBid;
    bytes32 reserveCheck;
    bool isReservedPriceReached;
    uint256 expiryAuctionTimestamp;
    Counters.Counter openBidsOnAuction;
    mapping(uint256 => ArtworkBids) bidsOnItem;
  }

  struct Artwork {
    address payable owner;
    bytes32 proofOfAuthenticityURL;
    uint256 price;
    ArtworkStatus artworkStatus;
    bool openForBid;
    bool paused;
    bool pausedByContractOwner;
    string tokenMetaData;
    Counters.Counter ownershipTransferCount;
    mapping(bool => ArtAuction) openArtworkAuction;
  }

  address payable internal XYZWallet;

  mapping(uint256 => Artwork) internal artworkOnXYZ;
  mapping(address => bool) internal whitelistedAddresses;

  function _onlyWhitelistedAddresses() internal view {
    require(whitelistedAddresses[msg.sender] == true, "Not whitelisted");
  }

  function _artworkStatusNotOpenForBid(uint256 artworkID) internal view {
    require(
      artworkOnXYZ[artworkID].openForBid == false,
      "Status is open for bid"
    );
  }

  function _artworkOnTimedAuction(uint256 artworkID) internal view {
    require(
      artworkOnXYZ[artworkID]
        .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
        .bidType == BidTypes.TIMEDAUCTION,
      "Not on TimedAuction"
    );
  }

  function _artworkOnUnlimitedAuction(uint256 artworkID) internal view {
    require(
      artworkOnXYZ[artworkID]
        .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
        .bidType == BidTypes.UNLIMITEDAUCTION,
      "Not on UNLIMITEDAUCTION"
    );
  }

  function _artworkAuctionEnded(uint256 artworkID) internal view {
    require(
      artworkOnXYZ[artworkID]
        .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
        .expiryAuctionTimestamp < block.timestamp,
      "Auction is not ended"
    );
  }

  function _artworkAuctionNotEnded(uint256 artworkID) internal view {
    require(
      artworkOnXYZ[artworkID]
        .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
        .expiryAuctionTimestamp > block.timestamp,
      "Auction is ended"
    );
  }

  function _isValidBidAuction(uint256 artworkID) internal view {
    require(
      msg.value >=
        artworkOnXYZ[artworkID]
          .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
          .minimumValidBid,
      "Bid is less than minimum allowed bid"
    );
  }

  function _artworkStatusOpenForBid(uint256 artworkID) internal view {
    require(
      artworkOnXYZ[artworkID].openForBid == true,
      "Status is not for bid"
    );
  }

  function _artworkStatusOpenForSale(uint256 artworkID) internal view {
    require(
      artworkOnXYZ[artworkID].artworkStatus == ArtworkStatus.OPENFORSALE,
      "Status is not for sale"
    );
  }

  function _artworkStatusNotForSale(uint256 artworkID) internal view {
    require(
      artworkOnXYZ[artworkID].artworkStatus == ArtworkStatus.NOTFORSALE,
      "status is open for sale"
    );
  }

  function _notArtworkOwner(uint256 artworkID) internal view {
    require(artworkOnXYZ[artworkID].owner != msg.sender, "You are the owner");
  }

  function _onlyArtworkOwner(uint256 artworkID) internal view {
    require(
      artworkOnXYZ[artworkID].owner == msg.sender,
      "You are not the owner"
    );
  }

  function _artworkNotPausedForTrade(uint256 artworkID) internal view {
    require(artworkOnXYZ[artworkID].paused == false, "Paused for trade");
  }

  function _artworkPausedForTrade(uint256 artworkID) internal view {
    require(artworkOnXYZ[artworkID].paused == true, "Not paused for trade");
  }

  function _artworkNotPausedForTradeByContractOwner(uint256 artworkID)
    internal
    view
  {
    require(
      artworkOnXYZ[artworkID].pausedByContractOwner == false,
      "Paused by contract owner"
    );
  }

  function _artworkPausedForTradeByContractOwner(uint256 artworkID)
    internal
    view
  {
    require(
      artworkOnXYZ[artworkID].pausedByContractOwner == true,
      "Not paused by contract owner"
    );
  }

  event BuyArtwork(
    uint256 artworkID,
    address buyerAddress,
    uint256 purchasedPrice,
    address newOwnerAddress
  );

  event TransferArtworkByContractOwner(
    uint256 artworkID,
    address buyerAddress,
    uint256 purchasedPrice,
    address newOwnerAddress
  );

  event UpdatedAuctionArtworkDetails(
    uint256 artworkID,
    uint256 minimumBid,
    uint256 expiryTimestamp,
    address updatedBy
  );

  event ownershipTransferredOfArtwork(
    uint256 artworkID,
    uint256 transactionID,
    address buyerAddress,
    uint256 purchasedPrice,
    address newOwnerAddress
  );

  event UpdatedAuctionArtworkReservePriceCheck(
    uint256 artworkID,
    bool reservePriceReached,
    address updatedBy
  );

  event RefundedBidOnArtwork(
    uint256 artworkID,
    address bidderAddress,
    uint256 bidPrice
  );

  event TransferredBidToPlatformWallet(
    uint256 artworkID,
    address from,
    address platformWallet,
    uint256 bidPrice
  );

  event UpdatedArtworkAuction(
    uint256 artworkID,
    uint256 minimumBid,
    uint256 reservePrice,
    uint256 expiryTimestamp,
    address updatedBy
  );

  event AuctionReverted(uint256 artworkID, address revertedBy);

  event AuctionCancelled(uint256 artworkID, address cancelledBy);

  event UpdatedPlatformWalletAddress(
    address newPlatformAddress,
    address updatedBy
  );

  event UpdatedArtworkStatusNotForSale(
    uint256 artworkID,
    ArtworkStatus artworkStatus,
    address updatedBy
  );

  event UpdatedArtworkStatusToSale(
    uint256 artworkID,
    uint256 artworkPrice,
    ArtworkStatus artworkStatus,
    address updatedBy
  );

  event UpdatedArtworkPauseStatus(
    uint256 artworkID,
    bool artworkStatus,
    address updatedBy
  );

  event UpdatedArtworkPauseStatusByContractOwner(
    uint256 artworkID,
    bool artworkStatus,
    address updatedBy
  );

  event NewArtworkAdded(
    uint256 artworkID,
    address ownerAddress,
    bytes32 proofOfAuthenticityURL,
    uint256 price,
    ArtworkStatus artworkStatus,
    bool paused,
    bool pausedByContractOwner,
    string tokenMetaData
  );

  event UpdatedArtworkPrice(
    uint256 artworkID,
    uint256 artworkPriceInWei,
    address updatedBy
  );

  event UpdatedArtworkToOpenForAuction(
    uint256 artworkID,
    bool openForBid,
    uint256 minimumValidBid,
    uint256 expiryAuctionTimestamp,
    address addedBy
  );

  event NewBidOnArtwork(
    uint256 artworkID,
    address beneficiary,
    uint256 availableOffer
  );

  event ClaimedBidOnUnlimitedAuction(
    address beneficaryAddress,
    uint256 expiredBidClaimed,
    uint256 expiredBidTimestamp
  );

  event BaseURI(string baseTokenURI, address addedBy);

  event WhitelistAddressUpdated(
    address whitelistedAddress,
    bool status,
    address addedBy
  );

  constructor() ERC721("Token", "TAST") {
    XYZWallet = payable(0xfA13D86F07CA645bfc8ec90C82BdBFde9CbbD52D);

    whitelistedAddresses[msg.sender] = true;
    emit WhitelistAddressUpdated(msg.sender, true, msg.sender);
  }

  function addNewArtwork(
    address owner,
    string memory tokenURI,
    bytes32 poaURL
  ) external returns (uint256) {
    _onlyWhitelistedAddresses();

    _tokenIds.increment();

    uint256 newArtworkId = _tokenIds.current();
    _mint(owner, newArtworkId);
    artworkOnXYZ[newArtworkId].owner = payable(owner);
    artworkOnXYZ[newArtworkId].proofOfAuthenticityURL = poaURL;
    artworkOnXYZ[newArtworkId].price = 0;
    artworkOnXYZ[newArtworkId].artworkStatus = ArtworkStatus.NOTFORSALE;
    artworkOnXYZ[newArtworkId].paused = false;
    artworkOnXYZ[newArtworkId].pausedByContractOwner = false;
    artworkOnXYZ[newArtworkId].tokenMetaData = tokenURI;
    _setTokenURI(newArtworkId, tokenURI);

    emit NewArtworkAdded(
      newArtworkId,
      artworkOnXYZ[newArtworkId].owner,
      artworkOnXYZ[newArtworkId].proofOfAuthenticityURL,
      artworkOnXYZ[newArtworkId].price,
      artworkOnXYZ[newArtworkId].artworkStatus,
      artworkOnXYZ[newArtworkId].paused,
      artworkOnXYZ[newArtworkId].pausedByContractOwner,
      artworkOnXYZ[newArtworkId].tokenMetaData
    );

    return newArtworkId;
  }

  function updatePlatformWalletAddress(address newXYZWallet)
    external
    onlyOwner
    returns (bool)
  {
    XYZWallet = payable(newXYZWallet);

    emit UpdatedPlatformWalletAddress(XYZWallet, msg.sender);
    return true;
  }

  function updateWhitelistAddress(address newAddress, bool status)
    external
    onlyOwner
  {
    whitelistedAddresses[newAddress] = status;
    emit WhitelistAddressUpdated(newAddress, status, msg.sender);
  }

  function updateArtworkPauseStatus(uint256 artworkID, bool status)
    external
    whenNotPaused
    returns (bool)
  {
    _onlyArtworkOwner(artworkID);
    _artworkNotPausedForTradeByContractOwner(artworkID);
    require(artworkOnXYZ[artworkID].paused != status, "same status");
    artworkOnXYZ[artworkID].paused = status;
    emit UpdatedArtworkPauseStatus(
      artworkID,
      artworkOnXYZ[artworkID].paused,
      msg.sender
    );
    return true;
  }

  function updateArtworkPauseStatusByContractOwner(
    uint256 artworkID,
    bool status
  ) external onlyOwner returns (bool) {
    require(
      artworkOnXYZ[artworkID].pausedByContractOwner != status,
      "same status"
    );
    artworkOnXYZ[artworkID].pausedByContractOwner = status;
    emit UpdatedArtworkPauseStatusByContractOwner(
      artworkID,
      artworkOnXYZ[artworkID].pausedByContractOwner,
      msg.sender
    );
    return true;
  }

  function updateArtworkPrice(uint256 artworkID, uint256 artworkPrice)
    external
    whenNotPaused
    returns (bool)
  {
    _onlyArtworkOwner(artworkID);
    artworkOnXYZ[artworkID].price = artworkPrice;
    emit UpdatedArtworkPrice(artworkID, artworkPrice, msg.sender);
    return true;
  }

  // function setBaseTokenURI(string memory baseTokenURI)
  //   external
  //   onlyOwner
  //   returns (bool)
  // {
  //   _setBaseURI(baseTokenURI);
  //   emit BaseURI(baseTokenURI, msg.sender);
  //   return true;
  // }

  function getArtworkDetail(uint256 artworkID)
    public
    view
    returns (
      address,
      bytes32,
      uint256,
      ArtworkStatus,
      string memory,
      uint256
    )
  {
    return (
      artworkOnXYZ[artworkID].owner,
      artworkOnXYZ[artworkID].proofOfAuthenticityURL,
      artworkOnXYZ[artworkID].price,
      artworkOnXYZ[artworkID].artworkStatus,
      artworkOnXYZ[artworkID].tokenMetaData,
      artworkOnXYZ[artworkID].ownershipTransferCount.current()
    );
  }

  function getArtworkBidDetail(uint256 artworkID)
    external
    view
    returns (
      address,
      BidTypes,
      uint256,
      uint256,
      uint256
    )
  {
    return (
      artworkOnXYZ[artworkID].owner,
      artworkOnXYZ[artworkID]
        .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
        .bidType,
      artworkOnXYZ[artworkID]
        .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
        .minimumValidBid,
      artworkOnXYZ[artworkID]
        .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
        .expiryAuctionTimestamp,
      artworkOnXYZ[artworkID]
        .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
        .openBidsOnAuction
        .current()
    );
  }

  function getAvailableTimedBidDetail(uint256 artworkID)
    public
    view
    returns (address, uint256)
  {
    return (
      artworkOnXYZ[artworkID]
        .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
        .bidsOnItem[
          artworkOnXYZ[artworkID]
            .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
            .openBidsOnAuction
            .current()
        ]
        .beneficiaryAddress,
      artworkOnXYZ[artworkID]
        .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
        .bidsOnItem[
          artworkOnXYZ[artworkID]
            .openArtworkAuction[artworkOnXYZ[artworkID].openForBid]
            .openBidsOnAuction
            .current()
        ]
        .amount
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "./TokenCore.sol";

contract TokenSale is TokenCore {
  using SafeMath for uint256;
  using Counters for Counters.Counter;

  function updateArtworkStatusNotForSale(uint256 artworkID)
    external
    whenNotPaused
    returns (bool)
  {
    _artworkStatusOpenForSale(artworkID);
    _artworkNotPausedForTrade(artworkID);
    _artworkNotPausedForTradeByContractOwner(artworkID);
    _onlyArtworkOwner(artworkID);

    artworkOnXYZ[artworkID].artworkStatus = ArtworkStatus.NOTFORSALE;

    emit UpdatedArtworkStatusNotForSale(
      artworkID,
      artworkOnXYZ[artworkID].artworkStatus,
      msg.sender
    );

    return true;
  }

  function updateArtworkStatusToSale(uint256 artworkID, uint256 artworkPrice)
    external
    whenNotPaused
    returns (bool)
  {
    _artworkStatusNotForSale(artworkID);
    _artworkNotPausedForTrade(artworkID);
    _artworkNotPausedForTradeByContractOwner(artworkID);
    _onlyArtworkOwner(artworkID);

    artworkOnXYZ[artworkID].artworkStatus = ArtworkStatus.OPENFORSALE;
    artworkOnXYZ[artworkID].price = artworkPrice;

    emit UpdatedArtworkStatusToSale(
      artworkID,
      artworkPrice,
      artworkOnXYZ[artworkID].artworkStatus,
      msg.sender
    );

    return true;
  }

  function buyArtwork(uint256 artworkID)
    external
    payable
    whenNotPaused
    returns (bool)
  {
    _notArtworkOwner(artworkID);
    _artworkStatusOpenForSale(artworkID);
    _artworkNotPausedForTrade(artworkID);
    _artworkNotPausedForTradeByContractOwner(artworkID);

    require(artworkOnXYZ[artworkID].price == msg.value, "Price is not same");

    XYZWallet.transfer(msg.value);

    _transfer(artworkOnXYZ[artworkID].owner, msg.sender, artworkID);

    artworkOnXYZ[artworkID].ownershipTransferCount.increment();

    artworkOnXYZ[artworkID].artworkStatus = ArtworkStatus.NOTFORSALE;
    artworkOnXYZ[artworkID].owner = payable(msg.sender);

    emit BuyArtwork(artworkID, msg.sender, msg.value, msg.sender);
    emit ownershipTransferredOfArtwork(
      artworkID,
      artworkOnXYZ[artworkID].ownershipTransferCount.current(),
      msg.sender,
      msg.value,
      msg.sender
    );

    return true;
  }

  function transferArtworkByContractOwner(
    uint256 artworkID,
    address newOwner,
    uint256 purchasedPrice
  ) external whenNotPaused returns (bool) {
    _onlyWhitelistedAddresses();
    _artworkStatusOpenForSale(artworkID);
    _artworkPausedForTradeByContractOwner(artworkID);
    _transfer(artworkOnXYZ[artworkID].owner, newOwner, artworkID);

    artworkOnXYZ[artworkID].ownershipTransferCount.increment();

    artworkOnXYZ[artworkID].artworkStatus = ArtworkStatus.NOTFORSALE;
    artworkOnXYZ[artworkID].owner = payable(newOwner);

    emit TransferArtworkByContractOwner(
      artworkID,
      newOwner,
      purchasedPrice,
      newOwner
    );
    emit ownershipTransferredOfArtwork(
      artworkID,
      artworkOnXYZ[artworkID].ownershipTransferCount.current(),
      newOwner,
      purchasedPrice,
      newOwner
    );

    return true;
  }
}

