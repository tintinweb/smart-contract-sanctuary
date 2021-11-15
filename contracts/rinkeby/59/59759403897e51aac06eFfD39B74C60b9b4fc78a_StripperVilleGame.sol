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

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;
import "@openzeppelin/contracts/access/Ownable.sol";

contract Administration is Ownable {
    
    event SetAdmin(address indexed admin, bool active);
    
    mapping (address => bool) private admins;
    
    modifier onlyAdmin(){
        require(admins[_msgSender()] || owner() == _msgSender(), "Admin: caller is not an admin");
        _;
    }
    
    function setAdmin(address admin, bool active) external onlyOwner {
        admins[admin] = active;
        emit SetAdmin(admin, active);
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./Administration.sol";
import "./NFTEvents.sol";
import "./interface/IStrip.sol";

contract Assets is Administration, NFTEvents {
    
    uint public strippersCount = 0;
    uint public clubsCount = 0;
    uint public namePriceStripper = 200 ether;
    uint public stripperSupply = 3000;
    uint8 public STRIPPER = 0;
    uint8 public CLUB = 1;
    
    IStrip public COIN;
    
    struct Asset {
        uint id;
        uint tokenType;
        uint earn;
        uint withdraw;
        uint born;
        string name;
        bool active;
    }
    
    Asset[] public assets;
    
    function setCoinAddress(address addr) public onlyAdmin {
        COIN = IStrip(addr);
    }
    
    function getAssetByTokenId(uint tokenId) public view returns(Asset memory, uint idx) {
        uint i = 0;
        Asset memory asset;
        while(i < assets.length){
            if(assets[i].id == tokenId){
                asset = assets[i];
                return(assets[i],i);
            }
            i++;
        }
        revert("tokenId not found");
    }
    
    function setNamePriceStripper(uint newPrice) external onlyAdmin {
        namePriceStripper = newPrice;
    }
    
    function adminSetAssetName(uint tokenId, string calldata name) external onlyAdmin {
        (,uint idx) = getAssetByTokenId(tokenId);
        assets[idx].name = name;
        emit NewAssetName(_msgSender(), tokenId, name);
    }
    
    function setStripperSupply(uint supply) external onlyAdmin {
        stripperSupply = supply;
        emit NewTotalSupply(_msgSender(), supply);
    }
    
    function totalSupply() external view returns (uint) {
        return stripperSupply + clubsCount;
    }
    
    function withdraw() external onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

contract NFTEvents {
    event NewTotalSupply(address indexed caller, uint newSupply);
    event NewStripperPrice(address indexed caller, uint newPrice);
    event NewMaxMint(address indexed caller, uint newMaxMint);
    event MintStripper(address indexed buyer, uint qty);
    event MintClub(address indexed caller, string clubName);
    event CloseClub(address indexed caller, uint tokenId);
    event ReopenClub(address indexed caller, uint tokenId);
    event NewAssetName(address indexed caller, uint indexed tokenId, string newName);
    event Giveaway(address indexed from, address indexed to, uint qty);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Administration.sol";

contract Strip is ERC20, Administration {

    uint256 private _initialTokens = 500000000 ether;
    address public game;
    
    constructor() ERC20("STRIP", "STRIP") {
        
    }
    
    function setGameAddress(address game_) external onlyAdmin {
        game = game_;
    }
    
    function buy(uint price) external onlyAdmin {
        _burn(tx.origin, price);
    }
    
    function initialMint() external onlyAdmin {
        require(totalSupply() == 0, "ERROR: Assets found");
        _mint(owner(), _initialTokens);
    }

    function mintTokens(uint amount) public onlyAdmin {
        _mint(owner(), amount);
    }
    
    function burnTokens(uint amount) external onlyAdmin {
        _burn(tx.origin, amount);
    }
    
    function approveOwnerTokensToGame() external onlyAdmin {
        _approve(owner(), game, _initialTokens);
    }
    
    function approveHolderTokensToGame(uint amount) external {
       _approve(tx.origin, game, amount);
    }

    function withdraw() external onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./Assets.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract StripperVille is Assets, ERC721 {
    
    uint public stripperPrice = 0.095 ether;
    uint private _maxMint = 0;
    string public baseTokenURI = 'https://strippervillebackend.herokuapp.com/';
    
    constructor() ERC721("StripperVille", "SpV") {}
    
    modifier isMine(uint tokenId){
        require(_msgSender() == ownerOf(tokenId), "OWNERSHIP: sender is not the owner");
        _;
    }
    
    modifier canMint(uint qty){
        require((qty + strippersCount) <= stripperSupply, "SUPPLY: qty exceeds total suply");
        _;
    }
    
    function setStripperPrice(uint newPrice) external onlyAdmin {
        stripperPrice = newPrice;
        emit NewStripperPrice(_msgSender(), newPrice);
    }
    
    function setMaxMint(uint newMaxMint) external onlyAdmin {
        _maxMint = newMaxMint;
        emit NewMaxMint(_msgSender(), newMaxMint);
    }
    
    function buyStripper(uint qty) external payable canMint(qty) {
        require((msg.value == stripperPrice * qty),"BUY: wrong value");
        require((qty <= _maxMint), "MINT LIMIT: cannot mint more than allowed");
        for(uint i=0; i < qty; i++) {
            _mintTo(_msgSender());
        }
        emit MintStripper(_msgSender(), qty);
    }
    
    function giveaway(address to, uint qty) external onlyOwner canMint(qty) {
        for(uint i=0; i < qty; i++) {
            _mintTo(to);
        }
        emit Giveaway(_msgSender(), to, qty);
    }
    
    function _mintTo(address to) internal {
        require(strippersCount < stripperSupply, "SUPPLY: qty exceeds total suply");
        uint rand = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, msg.sender, assets.length)));
        uint earn = ((rand % 31) + 70)  * (10 ** 18);
        uint tokenId = strippersCount + 1;
        assets.push(Asset(tokenId, STRIPPER, earn, 0, block.timestamp, "", true));
        _safeMint(to, tokenId);
        strippersCount++;
    }
    
    function createClub(string calldata clubName) external onlyAdmin {
        uint tokenId = clubsCount + 1000000;
        assets.push(Asset(tokenId, CLUB, 0, 0, block.timestamp, clubName, true));
        _safeMint(owner(), tokenId);
        clubsCount++;
        emit MintClub(_msgSender(), clubName);
    }
    
    function closeClub(uint tokenId) external onlyAdmin {
        require(ownerOf(tokenId) == owner(), "Ownership: Cannot close this club");
        (Asset memory asset, uint i) = getAssetByTokenId(tokenId);
        require(asset.tokenType == CLUB, "CLUB: asset is not a club");
        assets[i].active = false;
        emit CloseClub(_msgSender(), tokenId);
    }
    
    function reopenClub(uint tokenId) external onlyAdmin {
        (Asset memory asset, uint i) = getAssetByTokenId(tokenId);
        require(asset.tokenType == CLUB, "CLUB: asset is not a club");
        assets[i].active = true;
        emit ReopenClub(_msgSender(), tokenId);
    }
    
    function setStripperName(uint tokenId, string calldata name) external isMine(tokenId) {
        (Asset memory asset, uint i) = getAssetByTokenId(tokenId);
        require(asset.tokenType == STRIPPER, "ASSET: Asset is not a stripper");
        require(COIN.balanceOf(_msgSender()) >= namePriceStripper, "COIN: Insuficient funds");
        COIN.buy(namePriceStripper);
        assets[i].name = name;
        emit NewAssetName(_msgSender(), tokenId, name);
    }
    
    function withdrawAsset(uint tokenId, uint amount) external onlyAdmin {
        require(tx.origin == ownerOf(tokenId),  "OWNERSHIP: sender is not the owner");
        (, uint i) = getAssetByTokenId(tokenId);
        assets[i].withdraw += amount;
    }
    
    function getAssetsByOwner(address owner) public view returns (Asset[] memory) {
        uint balance = balanceOf(owner);
        Asset[] memory assets_ = new Asset[](balance);
        uint j = 0;
        for(uint i = 0; i < assets.length; i++){
            if(ownerOf(assets[i].id) == owner){
                assets_[j] = assets[i];
                j++;
                if(balance == j){
                 break;
                }
            }
            i++;
        }
        return assets_;
    }
    
    function setBaseTokenURI(string calldata uri) external onlyOwner {
        baseTokenURI = uri;
    }

    function _baseURI() internal override view returns (string memory) {
        return baseTokenURI;
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./Administration.sol";
import "./StripperVille.sol";
import "./Strip.sol";
import "./Assets.sol";

contract StripperVilleGame is Administration {
    
    event Claim(address indexed caller, uint tokenId, uint qty);
    event Work(uint tokenId, uint gameId);
    event BuyWorker(address indexed to, uint gameId, bool isThief);
    event WorkerAction(address indexed owner, uint gameId);
    event BuyWearable(uint stripper, uint wearable);
    
    mapping(uint => mapping (uint => uint)) private _poolStripClub;
    mapping(uint => mapping (uint => uint)) private _poolClubEarn;
    mapping(uint => mapping (uint => uint)) public poolClubPercentage;
    mapping(uint => mapping (uint => uint)) private _poolClubStrippersCount;
    mapping(uint => uint) public stripperWearable;
    mapping(uint => Worker[]) private _poolThieves;
    mapping(uint => Worker[]) private _poolCustomers;
    mapping(address => uint) private _addressWithdraw;

    Wearable[] public wearables;
    Strip public COIN;
    StripperVille public NFT;
    Game[] public games;
    uint public weeklyPrize = 250000 ether;
    uint public gamePrize = 250000 ether;
    uint public thiefPrice = 100 ether;
    uint public customerPrice = 100 ether;
    uint constant WEEK = 604800;
    
    modifier ownerOf(uint tokenId) {
        require(NFT.ownerOf(tokenId) == _msgSender(), "OWNERSHIP: Sender is not onwer");
        _;
    }
    
    modifier gameOn(uint gameId){
        require(games[gameId].paused == false && games[gameId].endDate == 0, "GAME FINISHED");
        _;
    }
    
    struct Worker {
        address owner;
        uint tokenId;
    }
    
    struct Game {
        uint prize;
        uint startDate;
        uint endDate;
        uint price;
        uint maxThieves;
        uint maxCustomers;
        uint customerMultiplier;
        bool paused;
    }
    
    struct Wearable {
        string name;
        uint price;
        uint increase;
        bool canBuy;
    }
    
    constructor(){
        wearables.push(Wearable('', 0, 0, false));
    }
    
    function giveawayWorker(uint gameId, address to, bool thief) external onlyAdmin gameOn(gameId) {
        _worker(gameId, to, thief);
    }
    
    function buyWorker(uint gameId, bool thief) external gameOn(gameId) {
        if(thief){
            require(COIN.balanceOf(_msgSender()) >= thiefPrice, "BALANCE: insuficient funds");
        } else {
             require(COIN.balanceOf(_msgSender()) >= customerPrice, "BALANCE: insuficient funds");
        }
        _worker(gameId, _msgSender(), thief);
    }
    
    function _worker(uint gameId, address to, bool thief) internal {
        (, uint index) = _getWorker(gameId,to,thief);
        require(index == 9999, "already had this worker type for this game");
        if(thief){
            require(_poolThieves[gameId].length < games[gameId].maxThieves, "MAX THIEVES REACHED");
            _poolThieves[gameId].push(Worker(to, 0));
        } else {
            require(_poolCustomers[gameId].length < games[gameId].maxCustomers, "MAX CUSTOMERS REACHED");
            _poolCustomers[gameId].push(Worker(to, 0));
        }
        emit BuyWorker(to,gameId, thief);
    }
    
    function putThief(uint gameId, uint clubId) external {
        _workerAction(gameId, clubId, true);
    }
    
    function putCustomer(uint gameId, uint stripperId) external {
        _workerAction(gameId,  stripperId, false);
    }
    
    function _workerAction(uint gameId, uint tokenId, bool thief) internal gameOn(gameId) {
        (Assets.Asset memory asset,) = NFT.getAssetByTokenId(tokenId);
        require((thief && asset.tokenType == 1) || (!thief && asset.tokenType == 0), "Incompatible");
        (, uint index) = thief ?  getMyThief(gameId) : getMyCustomer(gameId);
        require(index != 9999, "NOT OWNER");
        if(thief){
            _poolThieves[gameId][index].tokenId = tokenId;
        } else {
            _poolCustomers[gameId][index].tokenId = tokenId;
        }
        emit WorkerAction(_msgSender(), gameId);
    }
    
    function getMyThief(uint gameId) public view returns (Worker memory,uint) {
        return _getWorker(gameId, _msgSender(), true);
    }
    
    function getMyCustomer(uint gameId) public view returns (Worker memory,uint) {
        return _getWorker(gameId, _msgSender(), false);
    }
    
    function _getWorker(uint gameId, address owner, bool thief) internal view returns (Worker memory,uint) {
        Worker memory worker;
        uint index = 9999;
        Worker[] memory workers = thief ? _poolThieves[gameId] : _poolCustomers[gameId];
        for(uint i=0; i< workers.length; i++){
            if(workers[i].owner == owner){
                worker = workers[i];
                index = i;
                break;
            }
        }
        return (worker, index);
    }
    
    function _getThievesByClubId(uint gameId, uint clubId) public view returns (uint) {
        Worker[] memory workers = _poolThieves[gameId];
        uint total = 0;
        for(uint i=0; i< workers.length; i++){
            if(workers[i].tokenId == clubId){
                total++;
            }
        }
        return total;
    }
    
    function wearablesCount() public view returns (uint){
        return wearables.length;
    }
    
    function addWearable(string calldata name, uint price, uint increase, bool canBuy) external onlyAdmin {
        wearables.push(Wearable(name, price, increase, canBuy));
    }
    
    function updateWearable(uint index, bool canBuy) external onlyAdmin {
        wearables[index].canBuy = canBuy;
    }
    
    function buyWearable(uint stripperId, uint wearableId) external ownerOf(stripperId) {
        Wearable memory wearable = wearables[wearableId];
        require(COIN.balanceOf(_msgSender()) >= wearable.price, "BALANCE: insuficient funds");
        require(wearable.canBuy, "WEARABLE: cannot buy this");
        if(wearable.price > 0) {
            COIN.burnTokens(wearable.price);
        }
        stripperWearable[stripperId] = wearableId;
        emit BuyWearable(stripperId, wearableId);
    }
    
    function setGamePrize(uint newPrize) public onlyAdmin {
        gamePrize = newPrize;
    }
    
    function setWeeklyPrize(uint newPrize) public onlyAdmin {
        weeklyPrize = newPrize;
    }
    
    function setCustomerThiefPrices(uint customer, uint thief) external onlyAdmin {
        thiefPrice = thief;
        customerPrice = customer;
    }
    
    function createGame(uint price, uint maxThieves, uint maxCustomers, uint customersMultiply) external onlyAdmin {
        games.push(Game(gamePrize, block.timestamp, 0, price, maxThieves, maxCustomers, customersMultiply, false));
    }
    
    function pauseGame(uint index) public onlyAdmin {
        games[index].paused = true;
    }
    
    function getActiveGame() public view returns (uint) {
        uint active;
        for(uint i=0; i< games.length; i++){
            Game memory game = games[i];
            if(game.endDate == 0 && !game.paused){
                active = i;
                break;
            }
        }
        return active;
    }
    
    function setStripAddress(address newAddress) public onlyAdmin {
        COIN = Strip(newAddress);
    }
    
    function setStripperVilleAddress(address newAddress) public onlyAdmin {
        NFT = StripperVille(newAddress);
    }
    
    function setContracts(address coin, address nft) public onlyAdmin {
        setStripAddress(coin);
        setStripperVilleAddress(nft);
    }
    
    function nftsBalance() external view returns (uint){
        StripperVille.Asset[] memory assets = NFT.getAssetsByOwner(_msgSender());
        uint balance = 0;
        uint withdrawals = 0;
        if(assets.length == 0){
            return balance;
        }
        for(uint i = 0; i < assets.length; i++){
            balance += assets[i].earn;
            withdrawals += assets[i].withdraw;
        }
        if(withdrawals > balance){
            return 0;
        }
        return balance - withdrawals;
    }
    
    function work(uint stripperId, uint clubId, uint gameId) public ownerOf(stripperId) {
        require(_poolStripClub[gameId][stripperId] < 100000, "GAME: already set for this game");
        (Assets.Asset memory club,) = NFT.getAssetByTokenId(clubId);
        (Assets.Asset memory stripper,) = NFT.getAssetByTokenId(stripperId);
        require(club.tokenType == 1 && club.active, "CLUB: token is not a club or is not active");
        Game memory game = games[gameId];
        require(game.endDate == 0 && !game.paused, "GAME: closed or invalid");
        require(COIN.balanceOf(_msgSender()) >= game.price, "BALANCE: insuficient funds");
        if(game.price > 0) {
            COIN.burnTokens(game.price);
        }
        uint earn = stripper.earn;
        Worker[] memory workers = _poolCustomers[gameId];
        for(uint i=0; i< workers.length; i++){
            if(workers[i].tokenId == stripperId){
                earn = earn * game.customerMultiplier;
                break;
            }
        }
        _poolStripClub[gameId][stripperId] = clubId;
        _poolClubEarn[gameId][clubId] += earn; 
        _poolClubStrippersCount[gameId][clubId]++;
        emit Work(stripperId, gameId);
    }
    
    function getClubStrippersCount(uint gameId, uint clubId) public view returns (uint) {
        Game memory game = games[gameId];
        require(game.endDate > 0, "GAME: not closed");
        return  _poolClubStrippersCount[gameId][clubId];
    }
    
    function closeGame(uint index) public onlyAdmin {
        Game storage game = games[index];
        game.endDate = block.timestamp;
        uint[] memory clubIds = getClubIds();
        for(uint i=0; i < clubIds.length; i++){
            uint one = clubIds[i];
            uint position = 1;
            uint thievesOne = _getThievesByClubId(index, one);
            uint totalOne = thievesOne > 0 ? thievesOne > 9 ? 0 : (_poolClubEarn[index][one] / 10) * (10 - thievesOne) : _poolClubEarn[index][one];
            if(totalOne > 0){
                for(uint j=0; j < clubIds.length; j++){
                    uint two = clubIds[j];
                    if(one != two){
                        uint thievesTwo = _getThievesByClubId(index, two);
                        uint totalTwo = thievesTwo > 0 ? thievesTwo > 9 ? 0 : (_poolClubEarn[index][two] / 10) * (10 - thievesTwo) : _poolClubEarn[index][two];
                        if(totalOne < totalTwo){
                            position++;
                        }
                    }
                }
            } else {
                position = 6;
            }
            if(position < 6){
                uint earn = 5;
                if(position > 2){
                    earn = earn * (6 - position);
                } else if(position == 2){
                    earn = 30;
                } else {
                    earn = 40;
                }
                poolClubPercentage[index][one] = earn;
            }
        }
    }
    
    function getClubIds() public view  returns (uint[] memory){
        uint[] memory ids = new uint[](NFT.clubsCount());
        uint j=0;
        uint initial = 1000000;
        for(uint i=0;i<ids.length;i++){
            ids[j] = i + initial;
            j++;
        }
        return ids;
    }
    
    
    function getWeeklyEarnings(uint earn, uint born) public view returns (uint) {
         return getWeeks(born) * getEarn(earn);
    }
    
    function getWeeks(uint born) public view returns (uint) {
        return ((block.timestamp - born) / WEEK) + 1;
    }
    
    function getEarn(uint value) public view returns (uint) {
        if(value > 100 ether){
            value = 100 ether;
        }
        return ((weeklyPrize / NFT.stripperSupply()) / 100) * (value / 10 ** 18);
    }
    
    function getCustomerMultiply(uint gameId, uint stripperId) public view returns(uint){
        (Worker memory worker, uint index) = getMyCustomer(gameId);
        if(index != 9999 && worker.tokenId == stripperId && games[gameId].customerMultiplier > 1){
            return games[gameId].customerMultiplier;
        }
        return 1;
    }  
    
    function getClaimableTokens(uint tokenId) public view returns (uint) {
        (Assets.Asset memory asset,) = NFT.getAssetByTokenId(tokenId);
        uint earn=0;
        if(asset.tokenType == 0){
            uint  wearableEarn = 0;
            if(stripperWearable[tokenId] > 0){
                Wearable memory wearable = wearables[stripperWearable[tokenId]];
                wearableEarn += wearable.increase;
            }
            uint totalEarn = asset.earn + wearableEarn > 100 ether ? 100 ether : asset.earn + wearableEarn;
            for(uint i=0;i<games.length;i++){
                uint baseEarn = poolClubPercentage[i][_poolStripClub[i][tokenId]];
                uint gameEarn= 0;
                if(games[i].endDate > 0 && baseEarn > 0){
                    gameEarn += (gamePrize / baseEarn) - ((gamePrize / baseEarn) / 10);
                    earn += ((gameEarn / _poolClubStrippersCount[i][_poolStripClub[i][tokenId]] / 100) * (totalEarn / 10 ** 18) * getCustomerMultiply(i, tokenId));
                }
            }
            return earn + getWeeklyEarnings(totalEarn, asset.born) - asset.withdraw;
        } else {
            for(uint i=0;i<games.length;i++){
                uint baseEarn = poolClubPercentage[i][tokenId];
                if(games[i].endDate > 0 && baseEarn > 0){
                    earn += (gamePrize / baseEarn) / 10;
                }
            }
            return earn - asset.withdraw;
        }
    }
    
    function claimTokens(uint tokenId) public ownerOf(tokenId) {
        uint balance = getClaimableTokens(tokenId);
        COIN.approveHolderTokensToGame(balance);
        COIN.transferFrom(COIN.owner(), _msgSender(), balance);
        NFT.withdrawAsset(tokenId, balance);
        emit Claim(_msgSender(), tokenId, balance);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IStrip {
    function balanceOf(address account) external view returns (uint256);
    function buy(uint price) external;
    function decimals() external view returns (uint);
}

