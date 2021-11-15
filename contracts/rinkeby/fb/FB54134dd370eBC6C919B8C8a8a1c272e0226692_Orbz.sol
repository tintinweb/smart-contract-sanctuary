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
                return retval == IERC721Receiver(to).onERC721Received.selector;
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
        return msg.data;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

library PlanetCounter {
    function planetCount(bytes32 _sysMap) internal pure returns (uint _count) {
        uint prevPosition;
        while(_sysMap > 0) {
            require(uint(_sysMap) & 255 == 5, "Invalid planet {type}{color}{hp}");
            uint position = (uint(_sysMap) >> 8) & 255;
            require(_count == 0 || position < prevPosition, "Invalid planet position");
            prevPosition = position;
            _count++;
            _sysMap >>= 16;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "./StarSystems.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StarSystemData is Ownable {

    StarSystems public starSystems;
    mapping(address => bool) public mapEditors;
    mapping(uint => bytes32) public maps; // [sysId]

    event MapSet(uint indexed _sysId, bytes32 indexed _prevMap, bytes32 indexed _sysMap);

    constructor(StarSystems _starSystems) {
        starSystems = _starSystems;
    }

    function numSystems() public view returns (uint256) {
        return starSystems.numSystems();
    }

    function ownerOf(uint _sysId) public view returns (address) { 
        return starSystems.ownerOf(_sysId); 
    } 

    function mapOf(uint _sysId) external view returns (bytes32) { 
        return maps[_sysId]; 
    }

    function setMap(uint _sysId, bytes32 _sysMap) external {
        require(mapEditors[msg.sender], "Unauthorised to change system map");
        require(_sysMap > 0 && uint(_sysMap) < 2**253, "Invalid system map"); // _sysMap must be smaller than snark scalar field (=> have first 3 bits empty)
        bytes32 prevMap = maps[_sysId];
        maps[_sysId] = _sysMap;
        emit MapSet(_sysId, prevMap, _sysMap);
    }

    function setMapEditor(address _editor, bool _added) external onlyOwner { 
        mapEditors[_editor] = _added; 
    }

    function setStarSystems(StarSystems _starSystems) external onlyOwner { 
        starSystems = _starSystems; 
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StarSystems is ERC721("Star System", "STARSYS"), Ownable {

    uint public numSystems;
    address public minter;

    modifier onlyMinter() {
        require(msg.sender == minter, "Only minter can mint");
        _;
    }

    function setMinter(address _minter) external onlyOwner { minter = _minter; }

    function mint(address _recipient) external onlyMinter returns (uint _sysId) {
        _sysId = ++numSystems;
        _mint(_recipient, _sysId);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library Utils {
    using SafeERC20 for IERC20;

    address constant internal ETH_TOKEN_ADDRESS = address(0);

    function pullToken(address _token, uint256 _wei) internal {
        if (_token == ETH_TOKEN_ADDRESS) {
            require(msg.value == _wei, "Incorrect value sent");
        } else {
            IERC20(_token).safeTransferFrom(msg.sender, address(this), _wei);
        }
    }

    function pushToken(address _to, address _token, uint256 _wei) internal {
        if (_token == ETH_TOKEN_ADDRESS) {
            // `_to.transfer(_wei)` should be avoided, see https://diligence.consensys.net/blog/2019/09/stop-using-soliditys-transfer-now/
            // solium-disable-next-line security/no-call-value
            (bool success,) = _to.call{value: _wei}("");
            require(success, "ETH transfer failed");
        } else {
            IERC20(_token).safeTransfer(_to, _wei);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

interface IAuthoriser {
    function isAuthorised(address _delegator, address _delegate, address _to, bytes calldata _data) external view returns (bool authorised);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "./IAuthoriser.sol";

interface INftAuthoriser is IAuthoriser {
    function isAuthorisedForToken(address _token, uint _tokenId, address _delegate, address _to, bytes calldata _data) external view returns (bool authorised);
    function isAuthorisedForTokenAndCurrentOwner(address _token, uint _tokenId, address _delegate, address _to, bytes calldata _data) external view returns (bool authorised);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract EmergencyShutdown is Ownable {
    bool public isShutdown;

    event Shutdown();

    function shutdown() external onlyOwner {
        isShutdown = true;
        emit Shutdown();
    }

    modifier whenNotShutdown() {
        require(!isShutdown, "shutdown");
        _;
    }

    modifier whenShutdown() {
        require(isShutdown, "!shutdown");
        _;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "../Utils.sol";
import "./StarSystemConfigs.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract GameBase is Ownable {
    enum ActionType { NONE, CREDIT, NUKE, INTERCEPTOR, JUMP, GAIN, DETONATE, DEFUSE }
    enum Withdrawal { NONE, CREDITS, POT }

    struct Game {
        uint8 numPlayers;
        uint8 numSurvivors; // number of players who proved they have survived. These are the players entitled to claim a share of the pot.
        uint24 creditsWithdrawn; // total amount (in ticks) of credits redeemed by survivors from their personal items + gains
        uint24 potShareWithdrawn; // total amount (in ticks) of pot share withdrawn by survivors + fees paid to governance and system owner. Up to {numPlayers * TICKS - creditsWithdrawn} can be withdrawn as pot share and fees
        uint64 startTime;
        bytes32 configId;
        bytes32 sysMap;
    }

    struct Ransom {
        uint16 requested;
        uint16 paid;
        uint64 destructionTime;
    }

    struct PlayerInfo {
        address account;
        Withdrawal withdrawal; // phase of withdrawal
        uint24 withdrawn; // total amount withdrawn, in credits
    }

    // {contractId:64} = {chainId:32}{versionId:32}
    bytes4 constant internal version = 0x00000001; // v0.0.1
    bytes8 immutable internal contractId = bytes8(bytes32(block.chainid << 224)) | (bytes8(version) >> 32);

    uint16 constant internal TICKS = 10000; // The budget, in credits; also the maximum qty of any item.
    uint256 constant internal NUM_ACTIONS = 7; // Total number of possible ActionTypes, excluding ActionType.NONE
    
    StarSystemConfigs internal configs;

    mapping(bytes32 => Game) public games; // [gameId]
    mapping(uint256 => bytes32) public lastGameIds; // [sysId]

    mapping(bytes32 => mapping(address => uint256)) public commitments; // [gameId][player]
    mapping(bytes32 => mapping(address => uint256)) public playerIds; // [gameId][player]
    mapping(bytes32 => mapping(uint256 => PlayerInfo)) public players; // [gameId][playerId]
    mapping(bytes32 => mapping(uint256 => mapping(uint256 => Ransom))) public ransoms; // [gameId][targetId][playerId]
    // Player gains in ticks (stake unit)
    mapping(bytes32 => mapping(uint256 => uint256)) public gains; // [gameId][playerId]

    constructor(StarSystemConfigs _cfg) {
        configs = _cfg;
    }

    function getGameId(uint _sysId, uint _gameCount) public view returns (bytes32 _gameId) {
        return bytes32(bytes32(contractId) | bytes32(_sysId << 128) | bytes32(_gameCount)); // {gameId:256} = {chainId:32}{versionId:32}{sysId:64}{gameCount:128}
    }

    function getSysId(bytes32 _gameId) internal pure returns (uint _sysId) {
        return uint(_gameId >> 128) & 0xFFFFFFFFFFFFFFFF;  // {gameId:256} = {chainId:32}{versionId:32}{sysId:64}{gameCount:128}
    }

    function verifyTargetIsPlanet(uint256 _targetId, bytes32 _sysMap)
        internal
        pure
    {
        require((uint(_sysMap) >> (_targetId * 16)) & 3 > 0, "!planet"); // Check if there is a planet at target
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "../Utils.sol";
import "./GameBase.sol";
import "./Hasher.sol";
import "./EmergencyShutdown.sol";
import "../auth/INftAuthoriser.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

abstract contract GameExit is GameBase, Hasher, EmergencyShutdown {

    IERC721 internal immutable starSystems;
    INftAuthoriser internal immutable authoriser;
    // Fee balances of system owners and governance
    mapping(address => mapping(address => uint)) public feeBalances; // [recipient][token]
    mapping(uint => address) feeCollectors; // [sysId]
    mapping(bytes32 => bool) feePaid; // [gameId]

    event FeeCollectorSet(uint indexed _sysId, address _collector);
    event CreditsWithdrawn(bytes32 indexed _gameId, address indexed _player, address indexed _token, uint _amount, uint _planetId, uint _itemsLeft);
    event PotShareWithdrawn(bytes32 indexed _gameId, address indexed _player, address indexed _token, uint _amount);
    event EmergencyWithdrawn(bytes32 indexed _gameId, address indexed _player, address indexed _token, uint _amount);
    event FeeReceived(bytes32 indexed _gameId, address indexed _recipient, address indexed _token, uint _amount);
    event FeeWithdrawn(address indexed _recipient, address indexed _token, uint _amount);

    constructor(IERC721 _sys, INftAuthoriser _auth) {
        starSystems = _sys;
        authoriser = _auth;
    }

    function setFeeCollector(
        uint _sysId,
        address _collector
    ) external {
        if(_sysId == 0) {
            require(authoriser.isAuthorised(owner(), msg.sender, address(this), msg.data), "!auth");
        } else {
            require(authoriser.isAuthorisedForTokenAndCurrentOwner(address(starSystems), _sysId, msg.sender, address(this), msg.data), "!auth");
        }
        feeCollectors[_sysId] = _collector;
        emit FeeCollectorSet(_sysId, _collector);
    }

    function getFeeCollector(
        uint _sysId
    ) public view returns (address feeCollector) {
        feeCollector = feeCollectors[_sysId];
        if(feeCollector == address(0)) {
            feeCollector = (_sysId == 0) ? owner() : starSystems.ownerOf(_sysId);
        }
    }

    function withdrawFeeBalance(
        address _recipient,
        address _token
    ) external {
        uint withdrawn = feeBalances[_recipient][_token];
        if (withdrawn > 0) {
            feeBalances[_recipient][_token] = 0;
            Utils.pushToken(_recipient, _token, withdrawn);
            emit FeeWithdrawn(_recipient, _token, withdrawn);
        }
    }

    function withdrawCredits(
        bytes32 _gameId,
        uint _itemsLeft,
        uint _planetId,
        uint _secret
    )
        external
        whenNotShutdown
    {
        Game memory game = games[_gameId];
        _verifyDuringExit(game);
        uint playerId = playerIds[_gameId][msg.sender];
        require(playerId > 0 && players[_gameId][playerId].withdrawal == Withdrawal.NONE, "!player");
        require(hash3(_itemsLeft, uint(_planetId), _secret) == commitments[_gameId][msg.sender], "!secret");
        verifyTargetIsPlanet(_planetId, game.sysMap); // _planetId could have been nuked
        uint credits = (_itemsLeft >> 16 * uint(ActionType.CREDIT)) & 65535;
        (address stakeToken, uint stakeInWei) = configs.stakeConfigs(game.configId);
        uint withdrawn = credits + gains[_gameId][playerId];
        games[_gameId].numSurvivors = game.numSurvivors + 1;
        games[_gameId].creditsWithdrawn = game.creditsWithdrawn + uint24(withdrawn);
        uint withdrawnInWei = withdrawn * stakeInWei / TICKS;
        if(withdrawnInWei > 0) {
            Utils.pushToken(msg.sender, stakeToken, withdrawnInWei);
        }
        // delete gains[_gameId][playerId];
        // delete commitments[_gameId][msg.sender];
        players[_gameId][playerId].withdrawal = Withdrawal.CREDITS; // mark the player as a survivor
        players[_gameId][playerId].withdrawn += uint24(withdrawn);
        emit CreditsWithdrawn(_gameId, msg.sender, stakeToken, withdrawnInWei, _planetId, _itemsLeft);
    }

    function withdrawPotShareOnBehalf(
        bytes32 _gameId,
        address _player
    )
        public
        whenNotShutdown
    {
        Game memory game = games[_gameId];
        _verifyAfterExit(game);
        (address stakeToken, uint stakeInWei) = configs.stakeConfigs(game.configId);
        (uint potFee, uint potShare) = _collectFees(_gameId, game, stakeToken, stakeInWei);
        if(_player != address(0)) {
            _payPotShare(_gameId, potShare, _player, stakeToken, stakeInWei);
        } else {
            potShare = 0;
        }
        games[_gameId].potShareWithdrawn = game.potShareWithdrawn + uint24(potFee + potShare);
    }

    function withdrawPotShare(
        bytes32 _gameId
    )
        external
    {
        withdrawPotShareOnBehalf(_gameId, msg.sender);
    }

    function withdrawPotShareForAll(
        bytes32 _gameId
    )
        external
        whenNotShutdown
    {
        Game memory game = games[_gameId];
        _verifyAfterExit(game);
        (address stakeToken, uint stakeInWei) = configs.stakeConfigs(game.configId);
        (uint potFee, uint potShare) = _collectFees(_gameId, game, stakeToken, stakeInWei);
        uint8 numWithdrawals;
        for(uint playerId = 1; playerId <= game.numPlayers; playerId++) {
            PlayerInfo memory player = players[_gameId][playerId];
            if(player.withdrawal == Withdrawal.CREDITS) {
                _payPotShare(_gameId, potShare, player.account, stakeToken, stakeInWei);
                numWithdrawals++;
            }
        }
        games[_gameId].potShareWithdrawn = game.potShareWithdrawn + uint24(potFee + numWithdrawals * potShare);
    }

    function withdrawInEmergency(
        bytes32 _gameId
    )
        external 
        whenShutdown 
    {
        uint playerId = playerIds[_gameId][msg.sender];
        require(playerId > 0, "!player");

        Game memory game = games[_gameId];
        uint share = (game.numPlayers * TICKS - game.creditsWithdrawn - game.potShareWithdrawn) / game.numPlayers;
        uint withdrawn = players[_gameId][playerId].withdrawn;

        if(withdrawn < share) {
            (address stakeToken, uint stakeInWei) = configs.stakeConfigs(games[_gameId].configId);
            uint refundInWei = (share - withdrawn) * stakeInWei / TICKS;
            Utils.pushToken(msg.sender, stakeToken, refundInWei);
            players[_gameId][playerId].withdrawn = uint24(share);
            // players[_gameId][playerId].withdrawal = Withdrawal.POT;
            // delete players[_gameId][playerId];
            // delete playerIds[_gameId][msg.sender];
            emit EmergencyWithdrawn(_gameId, msg.sender, stakeToken, refundInWei);
        }
    }

    ///////////////////////////////////
    // Private/Internal functions
    ///////////////////////////////////

    function _verifyDuringExit(
        Game memory _game
    ) 
        private
        view
    {
        (, uint64 playPeriod, uint64 exitPeriod,,) = configs.timeConfigs(_game.configId);
        (uint minPlayers,) = configs.playerConfigs(_game.configId);
        require(
            _game.numPlayers >= minPlayers && block.timestamp >= _game.startTime + playPeriod &&
            block.timestamp < _game.startTime + playPeriod + exitPeriod,
            "!during exit"
        );
    }

    function _verifyAfterExit(
        Game memory _game
    ) 
        private
        view
    {
        (, uint64 playPeriod, uint64 exitPeriod,,) = configs.timeConfigs(_game.configId);
         (uint minPlayers,) = configs.playerConfigs(_game.configId);
        require(_game.numPlayers >= minPlayers && block.timestamp >= _game.startTime + playPeriod + exitPeriod, "!post exit");
    }

    function _collectFees(
        bytes32 _gameId,
        Game memory _game,
        address _stakeToken,
        uint _stakeInWei
    )
        private     
        returns (uint potFee, uint potShare)
    {
        uint pot = _game.numPlayers * TICKS - _game.creditsWithdrawn;
        if(!feePaid[_gameId]) {
            uint govFee = pot * ((_game.numSurvivors == 0) ? 10000 : configs.feesPer10000(_game.configId)) / 20000;
            uint dust = (_game.numSurvivors == 0) ? (pot - 2 * govFee) : ((pot - 2 * govFee) % _game.numSurvivors);
            uint sysFee = govFee + dust;
            if(govFee > 0) {
                address feeCollector = getFeeCollector(0);
                uint govFeeInWei = govFee * _stakeInWei / TICKS;
                feeBalances[feeCollector][_stakeToken] += govFeeInWei;
                emit FeeReceived(_gameId, feeCollector, _stakeToken, govFeeInWei);
            }
            if(sysFee > 0) {
                address feeCollector = getFeeCollector(getSysId(_gameId));
                uint sysFeeInWei = sysFee * _stakeInWei / TICKS;
                feeBalances[feeCollector][_stakeToken] += sysFeeInWei ;
                emit FeeReceived(_gameId, feeCollector, _stakeToken, sysFeeInWei);
            }
            potFee = govFee + sysFee;
            feePaid[_gameId] = true;
        }
        potShare = (_game.numSurvivors > 0) ? ((pot - potFee) / _game.numSurvivors) : 0;
    }

    function _payPotShare(
        bytes32 _gameId,
        uint _potShare,
        address _player,
        address _stakeToken,
        uint _stakeInWei
    ) 
        private     
    {
        uint potShareInWei = _potShare * _stakeInWei / TICKS;
        uint256 playerId = playerIds[_gameId][_player];
        require(players[_gameId][playerId].withdrawal == Withdrawal.CREDITS, "!player"); // Check player is eligible to claim pot share
        if(potShareInWei > 0) {
            Utils.pushToken(_player, _stakeToken, potShareInWei);    
        }
        players[_gameId][playerId].withdrawal = Withdrawal.POT; // Mark the player as having claimed their pot share
        players[_gameId][playerId].withdrawn += uint24(_potShare);
        emit PotShareWithdrawn(_gameId, _player, _stakeToken, potShareInWei);
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./GameBase.sol";
import "../Utils.sol";
import "../StarSystemData.sol";

abstract contract GameJoin is GameBase, Pausable {

    StarSystemData internal starSystemData;
    IERC721 internal tags;

    event GameJoined(address indexed _player, bytes32 indexed _gameId, uint _playerId, uint _commitment, bytes32 _tagId);
    event GameUnjoined(address indexed _player, bytes32 indexed _gameId);

    constructor(StarSystemData _data, IERC721 _tags) {
        starSystemData = _data;
        tags = _tags;
    }

    function pause(bool _enabled) external onlyOwner {
        if(_enabled) _pause();
        else _unpause();
    }

    function joinGame(
        uint _sysId,
        bytes32 _gameId,
        uint _commitment,
        uint _tagId
    )
        external
        payable
        whenNotPaused
    {
        require(_commitment > 0, "!comm");
        require(_tagId == 0 || tags.ownerOf(_tagId) == msg.sender, "!tag");

        bytes32 lastGameIdInSys = lastGameIds[_sysId];
        Game storage lastGame = games[lastGameIdInSys];
        uint8 numPlayers = lastGame.numPlayers;
        bytes32 configId = lastGame.configId;
        (uint minPlayers, uint maxPlayers) = configs.playerConfigs(configId);

        // solium-disable-next-line security/no-block-members
        if(lastGameIdInSys == 0 || (block.timestamp >= lastGame.startTime && numPlayers >= minPlayers)) {
            // lastGame has already started, so let's create a new game to join
            lastGameIdInSys = (lastGameIdInSys == 0) ? getGameId(_sysId, 0) : bytes32(uint(lastGameIdInSys) + 1); // {gameId:256} = {chainId:32}{versionId:32}{sysId:64}{gameCount:128}
            lastGameIds[_sysId] = lastGameIdInSys;
            configId = configs.configIds(_sysId);
            (minPlayers, maxPlayers) = configs.playerConfigs(configId);
            numPlayers = 0;
            lastGame = games[lastGameIdInSys];
            lastGame.configId = configId;
            lastGame.sysMap = starSystemData.mapOf(_sysId);
            (uint64 joinPeriod,,,,) = configs.timeConfigs(configId);
            // solium-disable-next-line security/no-block-members
            lastGame.startTime = uint64(block.timestamp) + joinPeriod;
        }

        // If _gameId is specified, make sure that it maches the id of the game
        // that the player is about to join.
        require(_gameId == 0 || _gameId == lastGameIdInSys, "!gameId");

        uint8 playerId;
        if(commitments[lastGameIdInSys][msg.sender] == 0) {
            (address stakeToken, uint stakeInWei) = configs.stakeConfigs(configId);
            Utils.pullToken(stakeToken, stakeInWei);
            assert(numPlayers < maxPlayers && maxPlayers <= 255);
            playerId = ++numPlayers;
            lastGame.numPlayers = numPlayers;
            playerIds[lastGameIdInSys][msg.sender] = playerId;
            players[lastGameIdInSys][playerId].account = msg.sender;
            if(
                // condition1: we are past the join time but were waiting for one more player to join
                // condition2: this is the last player that can join
                // in both case, we wish to start the game right now.
                // solium-disable-next-line security/no-block-members
                (block.timestamp >= lastGame.startTime && numPlayers == minPlayers) || numPlayers == maxPlayers
            ) {
                // solium-disable-next-line security/no-block-members
                lastGame.startTime = uint64(block.timestamp);
            }
        } else {
            require(msg.value == 0, "!value");
            playerId = uint8(playerIds[lastGameIdInSys][msg.sender]);
        }

        commitments[lastGameIdInSys][msg.sender] = _commitment;
        emit GameJoined(msg.sender, lastGameIdInSys, playerId, _commitment, bytes32(_tagId));
    }

    function cancelJoinGame(
        uint _sysId
    )
        external
    {
        bytes32 lastGameIdInSys = lastGameIds[_sysId];
        Game storage lastGame = games[lastGameIdInSys];
        uint8 numPlayers = lastGame.numPlayers;
        bytes32 configId = lastGame.configId;
        (uint minPlayers,) = configs.playerConfigs(configId);
        require(
            // solium-disable-next-line security/no-block-members
            numPlayers < minPlayers || block.timestamp < lastGame.startTime,
            "!pre start");

        require(commitments[lastGameIdInSys][msg.sender] > 0, "!joined");
        delete commitments[lastGameIdInSys][msg.sender];

        uint256 playerId = playerIds[lastGameIdInSys][msg.sender];
        if(playerId < numPlayers) { // swap lastJoiner and msg.sender
            PlayerInfo memory lastJoiner = players[lastGameIdInSys][numPlayers];
            playerIds[lastGameIdInSys][lastJoiner.account] = playerId;
            players[lastGameIdInSys][playerId] = lastJoiner;
        }
        delete playerIds[lastGameIdInSys][msg.sender];
        delete players[lastGameIdInSys][numPlayers];

        (address stakeToken, uint stakeInWei) = configs.stakeConfigs(configId);
        lastGame.numPlayers--;
        Utils.pushToken(msg.sender, stakeToken, stakeInWei);
        emit GameUnjoined(msg.sender, lastGameIdInSys);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "./MiMC.sol";

contract Hasher {
    function hash3(uint256 _a, uint256 _b, uint256 _c) public pure returns (uint256 out) {
        uint256 k = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        uint256 R;
        uint256 C;

        R = addmod(R, _a, k);
        (R, C) = MiMC.MiMCSponge(R, C, 0);

        R = addmod(R, _b, k);
        (R, C) = MiMC.MiMCSponge(R, C, 0);

        R = addmod(R, _c, k);
        (R, C) = MiMC.MiMCSponge(R, C, 0);

        out = R;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

library MiMC {
    // The code of this function is generated in assembly by circomlib/src/mimcsponge_gencontract.js
    function MiMCSponge(uint256 in_xL, uint256 in_xR, uint256 in_k) public pure returns (uint256 xL, uint256 xR) {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "./GameJoin.sol";
// import "./GamePlay.sol";
import "./GameExit.sol";

contract Orbz is GameJoin,GameExit {//, GamePlay{//}, GameExit {
    constructor(
        IERC721 _tags,
        IERC721 _sys,
        StarSystemConfigs _configs,
        StarSystemData _data,
        INftAuthoriser _auth
    )
        GameBase(_configs)
        GameJoin(_data, _tags)
        GameExit(_sys, _auth)
    {
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "./StarSystemMapEditor.sol";

contract StarSystemConfigs is StarSystemMapEditor {
    struct PlayerConfig {
        uint8 minPlayers; // >= 2, <= 255
        uint8 maxPlayers; // >= 2, <= 255
    }

    struct ItemConfig {
        uint256 itemPrices;
        uint256 itemMaxQuantities;
    }

    struct TimeConfig {
        uint64 joinPeriod;
        uint64 playPeriod;
        uint64 exitPeriod;
        uint64 ransomPeriod;
        uint64 gracePeriod;
    }

    struct StakeConfig {
        address stakeToken;
        uint256 stakeInWei; // amount of tokens (in wei) staked by each player
    }

    mapping(uint => bytes32) public configIds; // [sysId] => [configId]
    mapping(bytes32 => TimeConfig) public timeConfigs; // [configId]
    mapping(bytes32 => uint16) public feesPer10000; // [configId]
    mapping(bytes32 => StakeConfig) public stakeConfigs; // [configId]
    mapping(bytes32 => ItemConfig) public itemConfigs; // [configId]
    mapping(bytes32 => PlayerConfig) public playerConfigs; // [configId]

    event ConfigCreated(address indexed _creator, bytes32 indexed _configId);
    event ConfigSet(uint indexed _sysId, bytes32 indexed _prevConfigId, bytes32 indexed _configId);

    constructor(StarSystemData _starSystemData, INftAuthoriser _authoriser) StarSystemMapEditor(_starSystemData, _authoriser) {}

    function createConfig(
        PlayerConfig memory _players,
        TimeConfig memory _times,
        ItemConfig memory _items,
        StakeConfig memory _stake,
        uint16 _feePer10000
    )
        public 
        returns (bytes32 configId)
    {
        configId = keccak256(abi.encodePacked(
            _stake.stakeToken, _stake.stakeInWei, 
            _times.joinPeriod, _times.playPeriod, _times.exitPeriod, _times.ransomPeriod, _times.gracePeriod,
            _items.itemPrices, _items.itemMaxQuantities,
            _players.minPlayers, _players.maxPlayers,
            _feePer10000
        ));

        if(playerConfigs[configId].minPlayers == 0) {
            require(_players.minPlayers >= 2 && _players.maxPlayers <= 255 && _players.minPlayers <= _players.maxPlayers, "bad player limit");
            require(_feePer10000 <= 10000, "fee too big");
            require(_times.playPeriod > _times.ransomPeriod, "playPeriod too small");
            require(_items.itemPrices <= 2**253 && _items.itemMaxQuantities <= 2**253, "item param too big"); // need to be < than snark field

            stakeConfigs[configId].stakeToken = _stake.stakeToken;
            stakeConfigs[configId].stakeInWei = _stake.stakeInWei;

            timeConfigs[configId].joinPeriod = _times.joinPeriod;
            timeConfigs[configId].playPeriod = _times.playPeriod;
            timeConfigs[configId].exitPeriod = _times.exitPeriod;
            timeConfigs[configId].ransomPeriod = _times.ransomPeriod;
            timeConfigs[configId].gracePeriod = _times.gracePeriod;

            itemConfigs[configId].itemPrices = _items.itemPrices;
            itemConfigs[configId].itemMaxQuantities = _items.itemMaxQuantities;

            playerConfigs[configId].minPlayers = _players.minPlayers;
            playerConfigs[configId].maxPlayers = _players.maxPlayers;

            feesPer10000[configId] = _feePer10000;

            emit ConfigCreated(msg.sender, configId);
        }
    }

    function setConfigId(
        uint _sysId, 
        bytes32 _configId
    ) 
        public 
        onlyAuthorised(_sysId)
    {
        require(playerConfigs[_configId].minPlayers > 0, "Invalid config");
        bytes32 prevConfigId = configIds[_sysId];
        configIds[_sysId] = _configId;
        emit ConfigSet(_sysId, prevConfigId, _configId);
    }

    function setConfig(
        uint _sysId, 
        PlayerConfig memory _players,
        TimeConfig memory _times,
        ItemConfig memory _items,
        StakeConfig memory _stake,
        uint16 _feePer10000
    ) 
        public 
        onlyAuthorised(_sysId)
    {
        bytes32 configId = createConfig(_players, _times, _items, _stake, _feePer10000);
        bytes32 prevConfigId = configIds[_sysId];
        configIds[_sysId] = configId;
        emit ConfigSet(_sysId, prevConfigId, configId);
    }

    function setMapAndConfigId(
        uint _sysId,
        bytes32 _sysMap,
        bytes32 _configId
    ) external {
        setConfigId(_sysId, _configId);
        setMap(_sysId, _sysMap);
    }

    function setMapAndConfig(
        uint _sysId,
        bytes32 _sysMap,
        PlayerConfig memory _players,
        TimeConfig memory _times,
        ItemConfig memory _items,
        StakeConfig memory _stake,
        uint16 _feePer10000
    ) external {
        setConfig(_sysId, _players, _times, _items, _stake, _feePer10000);
        setMap(_sysId, _sysMap);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "../StarSystemData.sol";
import "../PlanetCounter.sol";
import "../auth/INftAuthoriser.sol";

abstract contract StarSystemMapEditor {
    using PlanetCounter for bytes32;

    StarSystemData public immutable starSystemData;
    StarSystems public immutable starSystems;
    INftAuthoriser public immutable authoriser;
    address immutable THIS = address(this);

    event MapSet(uint indexed _sysId, bytes32 indexed _prevMap, bytes32 indexed _sysMap);

    modifier onlyAuthorised(uint _sysId) {
        require(authoriser.isAuthorisedForToken(address(starSystems), _sysId, msg.sender, THIS, msg.data), "Unauthorised by system owner");
        _;
    }

    constructor(StarSystemData _starSystemData, INftAuthoriser _authoriser) { 
        starSystemData = _starSystemData;
        starSystems = _starSystemData.starSystems();
        authoriser = _authoriser;
    }

    function setMap(
        uint _sysId,
        bytes32 _sysMap
    ) 
        public 
        onlyAuthorised(_sysId)
    {
        require(_sysMap.planetCount() == starSystemData.mapOf(_sysId).planetCount(), "Map should keep same planet count");
        bytes32 prevMap = starSystemData.mapOf(_sysId);
        starSystemData.setMap(_sysId, _sysMap);
        emit MapSet(_sysId, prevMap, _sysMap);
    }
}

