/**
 *Submitted for verification at Etherscan.io on 2021-02-28
*/

/**
 *Submitted for verification at Etherscan.io on 2021-02-27
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
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
contract ERC20 is Context, IERC20 {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overloaded;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
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
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
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
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}


/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        _approve(account, _msgSender(), currentAllowance - amount);
        _burn(account, amount);
    }
}


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
    constructor () {
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
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {setOwner}.
 *
 * This module is used through inheritance. It will make available the modifiers
 * `onlyOwner`/`onlyOperator`, which can be applied to your functions to
 * restrict their use to the owner.
 *
 * Operator account can be set to MultiSig contract.
 *
 * In case someone mistakenly sent other tokens to the contract, or ETH,
 * there are functions to transfer those funds to a different address.
 */
contract AccessControl
{
    mapping (address=>bool) ownerAddress;
    mapping (address=>bool) operatorAddress;

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        ownerAddress[msg.sender] = true;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(ownerAddress[msg.sender], "Access denied");
        _;
    }

    /**
     * @dev Checks if provided address has owner permissions.
     */
    function isOwner(address _addr) public view returns (bool) {
        return ownerAddress[_addr];
    }

    /**
     * @dev Grants owner permission to new account.
     * Can only be called by the current owner.
     */
    function addOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "New owner is empty");

        ownerAddress[_newOwner] = true;
    }

    /**
     * @dev Replaces owner permission to new account.
     * Can only be called by the current owner.
     */
    function setOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "New owner is empty");

        ownerAddress[_newOwner] = true;
        delete(ownerAddress[msg.sender]);
    }

    /**
     * @dev Revokes owner permission from account.
     * Can only be called by the current owner.
     */
    function removeOwner(address _oldOwner) external onlyOwner {
        delete(ownerAddress[_oldOwner]);
    }

    /**
     * @dev Throws if called by any account other than the operator.
     */
    modifier onlyOperator() {
        require(isOperator(msg.sender), "Access denied");
        _;
    }

    /**
     * @dev Checks if provided address has operator or owner permissions.
     */
    function isOperator(address _addr) public view returns (bool) {
        return operatorAddress[_addr] || ownerAddress[_addr];
    }

    /**
     * @dev Grants operator permission to new account.
     * Can only be called by the current owner.
     */
    function addOperator(address _newOperator) external onlyOwner {
        require(_newOperator != address(0), "New operator is empty");

        operatorAddress[_newOperator] = true;
    }

    /**
     * @dev Revokes operator permission from account.
     * Can only be called by the current owner.
     */
    function removeOperator(address _oldOperator) external onlyOwner {
        delete(operatorAddress[_oldOperator]);
    }

    /**
     * @dev Transfers to _withdrawToAddress all tokens controlled by
     * contract _tokenContract.
     */
    function withdrawERC20(
        IERC20 _tokenContract,
        address _withdrawToAddress
    )
        external
        onlyOperator
    {
        uint256 balance = _tokenContract.balanceOf(address(this));
        _tokenContract.transfer(_withdrawToAddress, balance);
    }

    /**
     * @dev Allow to withdraw ERC721 tokens from contract itself
     */
    function approveERC721(IERC721 _tokenContract, address _approveToAddress)
        external
        onlyOperator
    {
        _tokenContract.setApprovalForAll(_approveToAddress, true);
    }

    /**
     * @dev Allow to withdraw ERC1155 tokens from contract itself
     */
    function approveERC1155(IERC1155 _tokenContract, address _approveToAddress)
        external
        onlyOperator
    {
        _tokenContract.setApprovalForAll(_approveToAddress, true);
    }

    /**
     * @dev Allow to withdraw ETH from contract itself (only by owner)
     */
    function withdrawEth(address payable _withdrawToAddress)
        external
        onlyOperator
    {
        if (address(this).balance > 0) {
            _withdrawToAddress.transfer(address(this).balance);
        }
    }
}


interface IERC827  {
    function approveAndCall(address _spender, uint256 _value, bytes memory _data)
        external
        returns (bool);
}


interface IERC223  {
    function transfer(address _to, uint _value, bytes calldata _data)
        external
        returns (bool success);
}


interface IERC20Bulk  {
    function transferBulk(address[] calldata to, uint[] calldata tokens) external;
    function approveBulk(address[] calldata spender, uint[] calldata tokens) external;
}


interface IFungibleToken is IERC20, IERC827, IERC223, IERC20Bulk {

    function mint(address target, uint256 mintedAmount) external;

    function mintBulk(address[] calldata target, uint256[] calldata mintedAmount) external;

    function mintAddDecimals(address target, uint256 mintedAmountWithoutDecimals) external;

    function mintAddDecimalsBulk(
        address[] calldata targets,
        uint256[] calldata mintedAmountWithoutDecimals
    )
        external;
}


/// Contract function to receive approval and execute function in one call
interface TokenRecipientInterface {
    function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external;
}


/// https://github.com/ethereum/EIPs/issues/223
interface TokenFallback {
    function tokenFallback(address _from, uint _value, bytes calldata _data) external;
}


/**
 * @title Blockchain Cuties Universe fungible token base contract
 * @author Andrey Pelipenko - <[email protected]>
 * @dev Implementation of the {IERC20}, {IERC827} and {IERC223} interfaces.
 *
 * Implementation is based on OpenZeppelin contracts.
 * Modules:
 * *** ERC20 ***
 *
 * *** Mint/Burn module ***
 * Admins can mint tokens. Token holders can burn their tokens.
 *
 * *** Pause/Freeze module ***
 * It is possible to pause contract transfers in case an exchange is hacked and
 * there is a risk for token holders to lose their tokens, delegated to an
 * exchange. After freezing suspicious accounts the contract can be unpaused.
 * Admins can burn tokens on frozen accounts to mint new tokens to holders as a
 * recovery after a successful hacking attack. Admin can disable the
 * pause/freeze module without possibility to enable this functionality after
 * that.
 *
 * *** Bulk operations ***
 * Bulk operations are added to save on gas.
 * Admin operations: mint tokens and burn frozen tokens
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
contract FungibleToken is ERC20Burnable, IFungibleToken, AccessControl, Pausable
{
    bool public allowPause = true;
    bool public allowFreeze = true;
    mapping (address => bool) private _frozen;

    event Frozen(address target);
    event Unfrozen(address target);
    event FreezeDisabled();
    event PauseDisabled();

    constructor (string memory name_, string memory symbol_)
        ERC20(name_, symbol_)
    {
    }

    /// --------------------------- Admin functions ----------------------------

    /**
     * @dev Mint some tokens to target account.
     * There is a check for the cap inside.
     */
    function mint(address target, uint256 mintedAmount)
        external
        override
        onlyOperator
    {
        _mint(target, mintedAmount);
    }

    /**
     * @dev Mint some tokens to target account.
     * mintedAmountWithoutDecimals is in human readable format (will be multiplied with 10^decimals)
     * Argument 123 will become 123 000 000 000 000 000 000 tokens.
     */
    function mintAddDecimals(address target, uint256 mintedAmountWithoutDecimals)
        external
        override
        onlyOperator
    {
        _mint(target, mintedAmountWithoutDecimals * (10**decimals()));
    }

    /**
     * @dev Bulk operation to mint tokens to target accounts.
     * There is a check for the cap inside.
     */
    function mintBulk(
        address[] calldata targets,
        uint256[] calldata mintedAmount
    )
        external
        override
        onlyOperator
    {
        require(
            targets.length == mintedAmount.length,
            "mintBulk: targets.length != mintedAmount.length"
        );
        for (uint i = 0; i < targets.length; i++) {
            _mint(targets[i], mintedAmount[i]);
        }
    }

    /**
     * @dev Bulk operation to mint tokens to target accounts.
     * There is a check for the cap inside.
     * mintedAmountWithoutDecimals is in human readable format (will be multiplied with 10^decimals)
     * Argument 123 will become 123 000 000 000 000 000 000 tokens.
     */
    function mintAddDecimalsBulk(
        address[] calldata targets,
        uint256[] calldata mintedAmountWithoutDecimals
    )
        external
        override
        onlyOperator
    {
        require(
            targets.length == mintedAmountWithoutDecimals.length,
            "mintAddDecimalsBulk: targets.length != mintedAmountWithoutDecimals.length"
        );
        for (uint i = 0; i < targets.length; i++) {
            _mint(targets[i], mintedAmountWithoutDecimals[i] * (10**decimals()));
        }
    }

    /// ---------------------------- Freeze module ----------------------------

    /**
     * @dev Disable freeze forever. There is no enableFreeze function.
     */
    function disableFreezeForever() external onlyOwner {
        require(allowFreeze, "disableFreezeForever: Freeze not allowed");
        allowFreeze = false;
        emit FreezeDisabled();
    }

    /**
     * @dev Mark target account as frozen.
     * Frozen accounts can't perform transfers.
     * Admins can burn the tokens on frozen accounts later.
     */
    function freeze(address target) external onlyOperator {
        _freeze(target);
    }

    function _freeze(address target) internal {
        require(allowFreeze, "FungibleToken: Freeze not allowed");
        require(
            !_frozen[target],
            "FungibleToken: Target account is already frozen"
        );
        _frozen[target] = true;
        emit Frozen(target);
    }

    /**
     * @dev Returns true if the target account is frozen.
     */
    function isFrozen(address target) view external returns (bool) {
        return _frozen[target];
    }

    /**
     * @dev Mark target account as unfrozen.
     * Can be called even if the contract doesn't allow to freeze accounts.
     */
    function unfreeze(address target) external onlyOperator {
        require(_frozen[target], "FungibleToken: Target account is not frozen");
        delete _frozen[target];
        emit Unfrozen(target);
    }

    /**
     * @dev Burn tokens on frozen account.
     */
    function burnFrozenTokens(address target) external onlyOperator {
        require(_frozen[target], "FungibleToken: Target account is not frozen");
        _burn(target, balanceOf(target));
    }

    /**
     * @dev Freeze and burn tokens in a single transaction.
     */
    function freezeAndBurnTokens(address target) external onlyOperator {
        _freeze(target);
        _burn(target, balanceOf(target));
    }

    /// ---------------------------- Pause module ----------------------------

    /**
     * @dev Disable pause forever.
     * Noone can enable pause after it has been disabled.
     * Admin will only be able to unpause the contract.
     */
    function disablePauseForever() external onlyOwner {
        require(allowPause, "Pausable: Pause was already disabled");
        allowPause = false;
        emit PauseDisabled();
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused and pause should be allowed.
     */
    function pause() external onlyOperator {
        require(allowPause, "Pausable: Pause not allowed");
        _pause();
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpause() external onlyOperator {
        _unpause();
    }

    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - do not allow the transfer of funds to the token contract itself (
     *                                   Usually such a call is a mistake).
     * - do not allow transfers when contract is paused.
     * - only allow to burn frozen tokens.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        virtual
        override
    {
        super._beforeTokenTransfer(from, to, amount);

        require(
            to != address(this),
            "FungibleToken: can't transfer to token contract self"
        );
        require(!paused(), "ERC20Pausable: token transfer while paused");
        require(
            !_frozen[from] || to == address(0x0),
            "FungibleToken: source address was frozen"
        );
    }


    /// --------------------------- ERC827 approveAndCall ----------------------


    /**
    * Token owner can approve for `spender` to transferFrom(...) `tokens`
    * from the token owner's account. The `spender` contract function
    * `receiveApproval(...)` is then executed
    */
    function approveAndCall(address spender, uint tokens, bytes calldata data)
        external
        override
        returns (bool success)
    {
        _approve(msg.sender, spender, tokens);
        TokenRecipientInterface(spender).receiveApproval(
            msg.sender,
            tokens,
            address(this),
            data
        );
        return true;
    }

    // ---------------------------- ERC20 Bulk Operations ----------------------

    function transferBulk(address[] calldata to, uint[] calldata tokens)
        external
        override
    {
        require(
            to.length == tokens.length,
            "transferBulk: to.length != tokens.length"
        );
        for (uint i = 0; i < to.length; i++) {
            _transfer(msg.sender, to[i], tokens[i]);
        }
    }

    function approveBulk(address[] calldata spender, uint[] calldata tokens)
        external
        override
    {
        require(
            spender.length == tokens.length,
            "approveBulk: spender.length != tokens.length"
        );
        for (uint i = 0; i < spender.length; i++) {
            _approve(msg.sender, spender[i], tokens[i]);
        }
    }

    /// ---------------------------- ERC223 ----------------------------
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value,
        bytes data
    );

    /**
     * @dev Function that is called when a user or another contract wants to
     * transfer funds with custom data, that is passed to receiver contract.
     */
    function transfer(address _to, uint _value, bytes calldata _data)
        external
        override
        returns (bool success)
    {
        return transferWithData(_to, _value, _data);
    }

    /**
     * @dev Alias to {transfer} with 3 arguments.
     */
    function transferWithData(address _to, uint _value, bytes calldata _data)
        public
        returns (bool success)
    {
        if (_isContract(_to)) {
            return transferToContract(_to, _value, _data);
        }
        else {
            return transferToAddress(_to, _value, _data);
        }
    }

    /**
    * @dev function that is called when transaction target is a contract
    */
    function transferToContract(address _to, uint _value, bytes calldata _data)
        public
        returns (bool success)
    {
        _transfer(msg.sender, _to, _value);
        emit Transfer(msg.sender, _to, _value, _data);
        TokenFallback receiver = TokenFallback(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        return true;
    }

    /**
    * @dev function that is called when transaction target is an address
    */
    function transferToAddress(address _to, uint tokens, bytes calldata _data)
        public
        returns (bool success)
    {
        _transfer(msg.sender, _to, tokens);
        emit Transfer(msg.sender, _to, tokens, _data);
        return true;
    }

    /**
    * @dev Assemble the given address bytecode.
    * If bytecode exists then the _addr is a contract.
    */
    function _isContract(address _addr) private view returns (bool is_contract) {
        uint length;
        assembly {
        //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
        }
        return length > 0;
    }
}


/**
 * @dev Extension of {ERC20} that adds a cap to the supply of tokens.
 */
contract ERC20Capped is FungibleToken {
    uint256 private _cap;

    /**
     * @dev Sets the value of the `cap`. This value is immutable, it can only be
     * set once during construction.
     */
    constructor (string memory _name, string memory _symbol, uint256 cap_)
    FungibleToken(_symbol, _name) {
        require(cap_ > 0, "ERC20Capped: cap is 0");
        _cap = cap_;
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view virtual returns (uint256) {
        return _cap;
    }

    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - minted tokens must not cause the total supply to go over the cap.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        if (from == address(0)) { // When minting tokens
            require(totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        }
    }
}


/**
* @title Blockchain Cuties Universe Governance Token contract
* @author Andrey Pelipenko - <[email protected]>
* @dev Implementation of the {IERC20}, {IERC827} and {IERC223} interfaces.
*
* Implementation is based on {FungibleToken} and {ERC20Capped}.
* Max supply is limited to 1000000 tokens.
*/
contract BCUG is ERC20Capped
{
    constructor()
        ERC20Capped(
            "BCUG",
            "Blockchain Cuties Universe Governance Token",
            1000000 ether)
    {
    }
}