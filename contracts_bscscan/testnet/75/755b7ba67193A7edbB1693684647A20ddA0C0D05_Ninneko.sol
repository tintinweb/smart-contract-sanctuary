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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

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
    function __ERC721_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
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
        address owner = ERC721Upgradeable.ownerOf(tokenId);
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
        address owner = ERC721Upgradeable.ownerOf(tokenId);
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
        address owner = ERC721Upgradeable.ownerOf(tokenId);

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
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
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
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
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
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
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
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
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

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
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
import "../proxy/utils/Initializable.sol";

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
 * @dev String operations.
 */
library StringsUpgradeable {
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

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
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

library Genes {
    uint256 constant sumOfGeneBits = 244;

    function geneBits() private pure returns (uint8[42] memory bits) {
        bits = [
            4,
            4,
            8, // FactionColor, Faction, Clothing
            10,
            2,
            10,
            2,
            10,
            2, // Eyes
            10,
            2,
            10,
            2,
            10,
            2, // Hair
            10,
            2,
            4,
            10,
            2,
            4,
            10,
            2,
            4, // Hand
            10,
            2,
            10,
            2,
            10,
            2, // Ears
            10,
            2,
            10,
            2,
            10,
            2, // Tail
            10,
            2,
            10,
            2,
            10,
            2 // Mouth
        ]; // 42;
    }

    function genePosList() private pure returns (uint8[42] memory list) {
        list = [
            240,
            236,
            228,
            218,
            216,
            206,
            204,
            194,
            192,
            182,
            180,
            170,
            168,
            158,
            156,
            146,
            144,
            140,
            130,
            128,
            124,
            114,
            112,
            108,
            98,
            96,
            86,
            84,
            74,
            72,
            62,
            60,
            50,
            48,
            38,
            36,
            26,
            24,
            14,
            12,
            2,
            0
        ];
    }

    function random(uint256 factor, uint256 _modulus) public view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(factor, block.difficulty, block.timestamp, msg.sender))) % _modulus;
    }

    function packGenes(uint256[42] memory _petProperty) public pure returns (uint256 genes) {
        uint8[42] memory _geneBits = geneBits();
        for (uint256 i = 0; i < _petProperty.length; i++) {
            uint256 item = _petProperty[i];
            uint256 size = _geneBits[i];
            genes = (genes << size) | item;
        }
    }

    function unPackGenes(uint256 _genes) public pure returns (uint256[42] memory petProperty) {
        uint8[42] memory _genePosList = genePosList();
        uint8[42] memory _geneBits = geneBits();
        for (uint256 i = 0; i < _genePosList.length; i++) {
            uint256 bits = _geneBits[i];
            uint256 shiftLeft = 256 - bits - _genePosList[i];
            uint256 shiftRight = 256 - bits;
            uint256 n = (_genes << shiftLeft) >> shiftRight;
            petProperty[i] = n;
        }
    }

    function mix(
        uint256 factor,
        uint256 _genId1,
        uint256 _genId2
    ) public view returns (uint256) {
        uint256[42] memory pet1 = unPackGenes(_genId1);
        uint256[42] memory pet2 = unPackGenes(_genId2);
        uint256[42] memory child = [uint256(0), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

        if (random(factor, 100) < 50) {
            //50/50
            child[1] = pet1[1];
        } else {
            child[1] = pet2[1];
        }

        uint256 r = random(factor, 100);
        if (r < 24) {
            //0-23
            child[0] = 1;
        } else if (r < 48) {
            // 24 -47
            child[0] = 2;
        } else if (r < 72) {
            // 48- 71
            child[0] = 3;
        } else if (r < 96) {
            //72-95
            child[0] = 4;
        } else if (r < 98) {
            //86, 97
            child[0] = 5;
        } else if (r < 100) {
            // 98-99
            child[0] = 6;
        }

        child[2] = random(factor, 5) + 1; //1-> 5
        child = mixGenes(factor, pet1, pet2, child);
        return packGenes(child);
    }

    function pickNFromList(
        uint256 factor,
        uint256 _number,
        uint256[6] memory _list,
        uint256[6] memory _ratio
    ) public view returns (uint256[] memory) {
        uint256[] memory res = new uint256[](_number);
        uint256 indexRes = 0;
        uint256 count = _list.length;

        for (uint256 i = 0; i < _number; i++) {
            uint256 sumRatio = 0;
            uint256[] memory thresholds = new uint256[](count);
            for (uint256 j = 0; j < count; j++) {
                sumRatio += _ratio[j];
                thresholds[j] = sumRatio;
            }

            uint256 r = random(factor + i, sumRatio);
            for (uint256 j = 0; j < count; j++) {
                uint256 threshold = thresholds[j];
                if (r < threshold) {
                    res[indexRes] = _list[j];
                    _list[j] = _list[count - 1];
                    _list[count - 1] = 0;
                    indexRes++;
                    count--;
                    break;
                }
            }
        }
        return res;
    }

    function inArray(uint256[] memory arr, uint256 n) public pure returns (bool) {
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == n) {
                return true;
            }
        }
        return false;
    }

    function notInt(uint256[6] memory _list, uint256[] memory _exclude) public pure returns (uint256[6] memory) {
        uint256[6] memory res = [uint256(0), 0, 0, 0, 0, 0];
        uint256 indexRes = 0;
        for (uint256 i = 0; i < _list.length; i++) {
            bool isIn = false;
            for (uint256 j = 0; j < _exclude.length; j++) {
                if (_list[i] == _exclude[j]) {
                    isIn = true;
                    break;
                }
            }

            if (!isIn) {
                res[indexRes] = _list[i];
                indexRes++;
            }
        }
        return res;
    }

    function beastGenes(uint256[42] memory _pet1, uint256[42] memory _pet2) public pure returns (uint256[] memory) {
        uint256[] memory bGenes = new uint256[](36);

        if (_pet1[4] == 1) bGenes[0] = _pet1[3];
        if (_pet1[6] == 1) bGenes[1] = _pet1[5];
        if (_pet1[8] == 1) bGenes[2] = _pet1[7];
        if (_pet1[10] == 1) bGenes[3] = _pet1[9];
        if (_pet1[12] == 1) bGenes[4] = _pet1[11];
        if (_pet1[14] == 1) bGenes[5] = _pet1[13];
        if (_pet1[16] == 1) bGenes[6] = _pet1[15];
        if (_pet1[19] == 1) bGenes[7] = _pet1[18];
        if (_pet1[22] == 1) bGenes[8] = _pet1[21];
        if (_pet1[25] == 1) bGenes[9] = _pet1[24];
        if (_pet1[27] == 1) bGenes[10] = _pet1[26];
        if (_pet1[29] == 1) bGenes[11] = _pet1[28];
        if (_pet1[31] == 1) bGenes[12] = _pet1[30];
        if (_pet1[33] == 1) bGenes[13] = _pet1[32];
        if (_pet1[35] == 1) bGenes[14] = _pet1[34];
        if (_pet1[37] == 1) bGenes[15] = _pet1[36];
        if (_pet1[39] == 1) bGenes[16] = _pet1[38];
        if (_pet1[41] == 1) bGenes[17] = _pet1[40];

        if (_pet2[4] == 1) bGenes[18] = _pet2[3];
        if (_pet2[6] == 1) bGenes[19] = _pet2[5];
        if (_pet2[8] == 1) bGenes[20] = _pet2[7];
        if (_pet2[10] == 1) bGenes[21] = _pet2[9];
        if (_pet2[12] == 1) bGenes[22] = _pet2[11];
        if (_pet2[14] == 1) bGenes[23] = _pet2[13];
        if (_pet2[16] == 1) bGenes[24] = _pet2[15];
        if (_pet2[19] == 1) bGenes[25] = _pet2[18];
        if (_pet2[22] == 1) bGenes[26] = _pet2[21];
        if (_pet2[25] == 1) bGenes[27] = _pet2[24];
        if (_pet2[27] == 1) bGenes[28] = _pet2[26];
        if (_pet2[29] == 1) bGenes[29] = _pet2[28];
        if (_pet2[31] == 1) bGenes[30] = _pet2[30];
        if (_pet2[33] == 1) bGenes[31] = _pet2[32];
        if (_pet2[35] == 1) bGenes[32] = _pet2[34];
        if (_pet2[37] == 1) bGenes[33] = _pet2[36];
        if (_pet2[39] == 1) bGenes[34] = _pet2[38];
        if (_pet2[41] == 1) bGenes[35] = _pet2[40];

        return bGenes;
    }

    function mixGenes(
        uint256 factor,
        uint256[42] memory _pet1,
        uint256[42] memory _pet2,
        uint256[42] memory child
    ) private view returns (uint256[42] memory) {
        uint256[] memory bGenes = beastGenes(_pet1, _pet2);

        for (uint256 i = 0; i < 6; i++) {
            if (i == 0) {
                //eyes
                uint256[6] memory genes = [_pet1[3], _pet1[5], _pet1[7], _pet2[3], _pet2[5], _pet2[7]];
                uint256[] memory res = remix(factor + i, genes, bGenes);
                child[3] = res[0];
                child[5] = res[1];
                child[7] = res[2];
                if (inArray(bGenes, child[3])) child[4] = 1;
                if (inArray(bGenes, child[5])) child[6] = 1;
                if (inArray(bGenes, child[7])) child[8] = 1;
            } else if (i == 1) {
                //mouth
                uint256[6] memory genes = [_pet1[36], _pet1[38], _pet1[40], _pet2[36], _pet2[38], _pet2[40]];
                uint256[] memory res = remix(factor + i, genes, bGenes);
                child[36] = res[0];
                child[38] = res[1];
                child[40] = res[2];
                if (inArray(bGenes, child[36])) child[37] = 1;
                if (inArray(bGenes, child[38])) child[39] = 1;
                if (inArray(bGenes, child[40])) child[41] = 1;
            } else if (i == 2) {
                //hair
                uint256[6] memory genes = [_pet1[9], _pet1[11], _pet1[13], _pet2[9], _pet2[11], _pet2[13]];
                uint256[] memory res = remix(factor + i, genes, bGenes);
                child[9] = res[0];
                child[11] = res[1];
                child[13] = res[2];
                if (inArray(bGenes, child[9])) child[10] = 1;
                if (inArray(bGenes, child[11])) child[12] = 1;
                if (inArray(bGenes, child[13])) child[14] = 1;
            } else if (i == 3) {
                //hand
                uint256[6] memory genes = [_pet1[15], _pet1[18], _pet1[21], _pet2[15], _pet2[18], _pet2[21]];
                uint256[] memory res = remix(factor + i, genes, bGenes);
                child[15] = res[0];
                child[18] = res[1];
                child[21] = res[2];
                if (inArray(bGenes, child[15])) child[16] = 1;
                if (inArray(bGenes, child[18])) child[19] = 1;
                if (inArray(bGenes, child[21])) child[22] = 1;
                //
                uint8[3] memory bitPos = [15, 18, 21]; // class
                for (uint256 j = 0; j < 3; j++) {
                    uint256 pos1 = bitPos[j];
                    for (uint256 k = 0; k < 3; k++) {
                        uint256 pos2 = bitPos[k];
                        if (child[pos1] == _pet1[pos2]) {
                            child[pos1 + 2] = _pet1[pos2 + 2];
                            break;
                        } else if (child[pos1] == _pet2[pos2]) {
                            child[pos1 + 2] = _pet2[pos2 + 2];
                            break;
                        }
                    }
                }
            } else if (i == 4) {
                //ears
                uint256[6] memory genes = [_pet1[24], _pet1[26], _pet1[28], _pet2[24], _pet2[26], _pet2[28]];
                uint256[] memory res = remix(factor + i, genes, bGenes);
                child[24] = res[0];
                child[26] = res[1];
                child[28] = res[2];
                if (inArray(bGenes, child[24])) child[25] = 1;
                if (inArray(bGenes, child[26])) child[27] = 1;
                if (inArray(bGenes, child[28])) child[29] = 1;
            } else if (i == 5) {
                // tail
                uint256[6] memory genes = [_pet1[30], _pet1[32], _pet1[34], _pet2[30], _pet2[32], _pet2[34]];
                uint256[] memory res = remix(factor + i, genes, bGenes);
                child[30] = res[0];
                child[32] = res[1];
                child[34] = res[2];
                if (inArray(bGenes, child[30])) child[31] = 1;
                if (inArray(bGenes, child[32])) child[33] = 1;
                if (inArray(bGenes, child[34])) child[35] = 1;
            }
        }

        return child;
    }

    function remix(
        uint256 factor,
        uint256[6] memory _genes,
        uint256[] memory _bGenes
    ) private view returns (uint256[] memory) {
        uint256[6] memory geneRatios = [uint256(36), 10, 4, 36, 10, 4];
        uint256[] memory chosen = pickNFromList(factor, 3, _genes, geneRatios);
        if (inArray(_bGenes, chosen[0]) && random(factor, 100) < 98) {
            uint256[6] memory excludes = notInt(_genes, chosen);
            excludes = notInt(excludes, _bGenes);
            uint256 n = excludes.length;
            if (n > 0) {
                for (uint256 i = 0; i < 10; i++) {
                    uint256 r = random(factor + i, n);
                    if (excludes[r] != 0) {
                        chosen[0] = excludes[r];
                        break;
                    }
                }
            }
        }
        return chosen;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./Genes.sol";

contract Ninneko is Initializable, ERC721Upgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IERC20Upgradeable public NINOToken;
    IERC20Upgradeable public MATAToken;

    uint256 private constant FEE_RATIO = 10_000;

    string private _uri;

    uint256 public serviceFee;
    uint256 public breedNINOFee;
    uint256 public minPriceSalePet;

    struct Pet {
        uint8 generation;
        uint16 breedCount;
        uint32 birthTime;
        uint256 matronId;
        uint256 sireId;
        uint256 geneId;
    }

    uint8 public constant MAX_BREED_COUNT = 6;

    Pet[] public pets;
    mapping(uint256 => uint256) public petsOnSale;

    bool public allowBreed;
    uint256 public adulthoodTime;
    address public operator;
    address public ninoReceiver;
    bool public paused;
    bool public pausedBreed;
    uint256[6] public breedCosts;
    uint256 public counter;
    mapping(uint256 => bool) public blackList;

    event PetCreated(address indexed owner, uint256 indexed petId, uint256 matronId, uint256 sireId, uint8 generation, uint256 geneId);
    event PetListed(uint256 indexed petId, address indexed seller, uint256 price);
    event PetDelisted(uint256 indexed petId);
    event PetBought(uint256 indexed petId, address indexed buyer, address indexed seller, uint256 price);
    event SetPaused(bool);
    event SetPausedBreed(bool);
    event BlackList(uint256 nftId, bool isInBlackList);

    function initialize(
        string memory baseUri,
        address addNINOToken,
        address addMATAToken
    ) public initializer {
        __Ownable_init_unchained();
        __ReentrancyGuard_init_unchained();
        __ERC721_init("Ninneko Contract", "NEKO");

        _uri = baseUri;
        _setAcceptedTokenContract(addNINOToken, addMATAToken);

        pets.push(Pet(0, 0, 0, 0, 0, 0)); // Pet #0 belongs to none
        serviceFee = 300;
        breedNINOFee = 3 * 10**18;
        minPriceSalePet = 1 * 10**16;
        breedCosts = [100, 200, 300, 600, 1000, 2000];
        allowBreed = true;
        adulthoodTime = 6 days;
        ninoReceiver = owner();
        operator = owner();
    }

    modifier onlyOperator() {
        require(msg.sender == operator || msg.sender == owner(), "Not the operator or owner");
        _;
    }

    modifier onlyPetOwner(uint256 _petId) {
        require(ownerOf(_petId) == msg.sender, "Not the owner of this one");
        _;
    }

    modifier notInBlackList(uint256 _petId) {
        require(!blackList[_petId], "blacklisted pet");
        _;
    }

    modifier listPetNotInBlackList(uint256[] memory _listPetId) {
        for (uint256 i = 0; i < _listPetId.length; i++) {
            require(!blackList[_listPetId[i]], "blacklisted pet");
        }
        _;
    }

    modifier onlyListPetOwner(uint256[] memory _listPetId) {
        for (uint256 i = 0; i < _listPetId.length; i++) {
            uint256 petId = _listPetId[i];
            require(ownerOf(petId) == msg.sender, "Not the owner of these");
        }
        _;
    }

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenNotPausedBreed() {
        require(!pausedBreed);
        _;
    }

    modifier validateBreed(uint256 _pet1Id, uint256 _pet2Id) {
        require(ownerOf(_pet1Id) == msg.sender && ownerOf(_pet2Id) == msg.sender, "Not the owner of this one");
        require(_pet1Id != _pet2Id, "Use 2 to breed");
        require(pets[_pet1Id].breedCount < MAX_BREED_COUNT && pets[_pet2Id].breedCount < MAX_BREED_COUNT, "Breed reached limit");

        require(block.timestamp >= adulthoodTime + uint256(pets[_pet1Id].birthTime), "pet1 is not mature enough to breed");
        require(block.timestamp >= adulthoodTime + uint256(pets[_pet2Id].birthTime), "pet2 is not mature enough to breed");

        require(pets[_pet1Id].matronId != _pet2Id && pets[_pet1Id].sireId != _pet2Id && pets[_pet2Id].matronId != _pet1Id && pets[_pet2Id].sireId != _pet1Id, "Can't breed between parent and child");

        if (pets[_pet1Id].matronId > 0 || pets[_pet1Id].sireId > 0 || pets[_pet2Id].matronId > 0 || pets[_pet2Id].sireId > 0) {
            // NOT minted one
            require(
                pets[_pet1Id].matronId != pets[_pet2Id].matronId && pets[_pet1Id].matronId != pets[_pet2Id].sireId && pets[_pet2Id].matronId != pets[_pet1Id].sireId,
                "can't breed between ones that have the same parent"
            );
        }
        _;
    }

    function _setAcceptedTokenContract(address addNINO, address addMATA) private {
        require(addNINO != address(0));
        require(addMATA != address(0));
        NINOToken = IERC20Upgradeable(addNINO);
        MATAToken = IERC20Upgradeable(addMATA);
    }

    function setMinPricePetSale(uint256 _minPrice) external onlyOwner {
        minPriceSalePet = _minPrice;
    }

    function setAcceptedTokenContract(address addNINO, address addMATA) external onlyOwner {
        _setAcceptedTokenContract(addNINO, addMATA);
    }

    function setBreedCosts(uint256[6] memory _newBreedCosts) external onlyOwner {
        breedCosts = _newBreedCosts;
    }

    function setBreedNINOFee(uint256 _newFee) external onlyOwner {
        breedNINOFee = _newFee;
    }

    function setServiceFee(uint256 _value) external onlyOwner {
        serviceFee = _value;
    }

    function calculateServiceFee(uint256 _price) private view returns (uint256) {
        return (_price * serviceFee) / FEE_RATIO;
    }

    function setBaseUri(string memory _baseUri) external onlyOwner {
        _uri = _baseUri;
    }

    function setAllowBreed(bool _allowBreed) external onlyOperator {
        allowBreed = _allowBreed;
    }

    function setTimeBreedAfter(uint256 _timer) external onlyOperator {
        adulthoodTime = _timer;
    }

    function setNINOReceiver(address _address) external onlyOwner {
        ninoReceiver = _address;
    }

    function setOperator(address _address) public onlyOwner {
        operator = _address;
    }

    function setPause(bool _pause) external onlyOperator {
        paused = _pause;
    }

    function setPauseBreed(bool _pauseBreed) external onlyOperator {
        pausedBreed = _pauseBreed;
    }

    function setBlackList(uint256[] memory _listId) external onlyOwner {
        for (uint256 i = 0; i < _listId.length; i++) {
            uint256 nftId = _listId[i];
            blackList[nftId] = true;
            emit BlackList(nftId, true);
        }
    }

    function removeFromBlackList(uint256[] memory _listId) external onlyOwner {
        for (uint256 i = 0; i < _listId.length; i++) {
            uint256 nftId = _listId[i];
            blackList[nftId] = false;
            emit BlackList(nftId, false);
        }
    }

    function breed(uint256 _pet1Id, uint256 _pet2Id) external whenNotPausedBreed validateBreed(_pet1Id, _pet2Id) notInBlackList(_pet1Id) notInBlackList(_pet2Id) {
        require(allowBreed, "Breed is not allowed");
        uint256 fee1 = _getBreedPrice(pets[_pet1Id]);
        uint256 fee2 = _getBreedPrice(pets[_pet2Id]);
        uint256 breedMATAFee = fee1 + fee2;
        require(_getNINOBalance() >= breedNINOFee, "Insufficient NINO");
        require(_getMATABalance() >= breedMATAFee, "Insufficient MATA");

        uint256 allowanceNino = NINOToken.allowance(msg.sender, address(this));
        require(allowanceNino >= breedNINOFee, "Check the token NiNo allowance");

        uint256 allowanceMata = MATAToken.allowance(msg.sender, address(this));
        require(allowanceMata >= breedMATAFee, "Check the token Mata allowance");

        NINOToken.safeTransferFrom(msg.sender, ninoReceiver, breedNINOFee);
        MATAToken.safeTransferFrom(msg.sender, address(0xdEaD), breedMATAFee);
        pets[_pet1Id].breedCount++;
        pets[_pet2Id].breedCount++;
        uint256 childGenes = Genes.mix(counter++, pets[_pet1Id].geneId, pets[_pet2Id].geneId);
        uint256 petId = _createPet(_pet1Id, _pet2Id, 2, childGenes); // generation is always = 2
        _safeMint(msg.sender, petId);
    }

    function _getNINOBalance() private view returns (uint256) {
        return NINOToken.balanceOf(msg.sender);
    }

    function _getMATABalance() private view returns (uint256) {
        return MATAToken.balanceOf(msg.sender);
    }

    function putListPetOnSale(uint256[] memory _listPetId, uint256 _petPrice) external whenNotPaused onlyListPetOwner(_listPetId) listPetNotInBlackList(_listPetId) {
        require(_petPrice >= minPriceSalePet, "Invalid price!");

        for (uint256 i = 0; i < _listPetId.length; i++) {
            uint256 petId = _listPetId[i];
            _putOnSale(petId, _petPrice);
        }
    }

    function putOnSale(uint256 _petId, uint256 _price) external whenNotPaused onlyPetOwner(_petId) notInBlackList(_petId) {
        require(_price >= minPriceSalePet, "Invalid price!");
        _putOnSale(_petId, _price);
    }

    function _putOnSale(uint256 _petId, uint256 _price) private {
        petsOnSale[_petId] = _price;
        approve(address(this), _petId);
        emit PetListed(_petId, msg.sender, _price);
    }

    function cancelSale(uint256 _petId) external whenNotPaused onlyPetOwner(_petId) {
        require(petsOnSale[_petId] > 0, "This one is not on sale already!");
        _cancelSale(_petId);
    }

    function _cancelSale(uint256 _petId) private {
        petsOnSale[_petId] = 0;
        emit PetDelisted(_petId);
    }

    function _getBreedPrice(Pet memory _pet) private view returns (uint256) {
        if (_pet.generation == 1) {
            return 0;
        } else {
            return breedCosts[_pet.breedCount];
        }
    }

    function buyPet(uint256 _petId) external payable whenNotPaused nonReentrant notInBlackList(_petId) {
        uint256 price = petsOnSale[_petId];
        address buyer = msg.sender;
        address seller = ownerOf(_petId);

        require(price > 0, "This one is not for sale!");
        require(buyer != seller, "This one is yours already!");
        require(price == msg.value, "The amount is insufficient!");
        require(this.getApproved(_petId) == address(this), "Seller did not give the allowance for us to sell this one.");
        _makeTransaction(_petId, seller, buyer, price);

        emit PetBought(_petId, buyer, seller, price);
    }

    function batchMint(uint8 generation, uint256[] memory listGenId) external onlyOperator {
        for (uint8 i = 0; i < listGenId.length; i++) {
            uint256 petId = _createPet(0, 0, generation, listGenId[i]);
            _safeMint(msg.sender, petId);
        }
    }

    function batchMintToAddress(
        uint8 generation,
        address addTo,
        uint256[] memory listGenId
    ) external onlyOperator {
        for (uint8 i = 0; i < listGenId.length; i++) {
            uint256 petId = _createPet(0, 0, generation, listGenId[i]);
            _safeMint(addTo, petId);
        }
    }

    function burn(uint256 _petId) external whenNotPaused onlyPetOwner(_petId) {
        if (petsOnSale[_petId] > 0) {
            _cancelSale(_petId);
        }
        _burn(_petId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        if (petsOnSale[tokenId] > 0) {
            _cancelSale(tokenId);
        }
        super._transfer(from, to, tokenId);
    }

    function totalSupply() public view returns (uint256) {
        return pets.length;
    }

    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    function petsInfo(uint256[] memory idList) external view returns (Pet[] memory) {
        uint256 len = idList.length;
        Pet[] memory _pets = new Pet[](len);
        for (uint256 i = 0; i < len; i++) {
            uint256 id = idList[i];
            _pets[i] = pets[id];
        }
        return _pets;
    }

    function _createPet(
        uint256 matronId,
        uint256 sireId,
        uint8 generation,
        uint256 geneId
    ) private returns (uint256 _petId) {
        pets.push(Pet(generation, 0, uint32(block.timestamp), matronId, sireId, geneId));
        _petId = pets.length - 1;
        emit PetCreated(msg.sender, _petId, matronId, sireId, generation, geneId);
    }

    function _makeTransaction(
        uint256 _petId,
        address _seller,
        address _buyer,
        uint256 _price
    ) private {
        uint256 fee = calculateServiceFee(_price);
        (bool transferToSeller, ) = _seller.call{value: _price - fee}("");
        require(transferToSeller);

        (bool transferToTreasury, ) = owner().call{value: fee}("");
        require(transferToTreasury);

        _transfer(_seller, _buyer, _petId);
    }
}