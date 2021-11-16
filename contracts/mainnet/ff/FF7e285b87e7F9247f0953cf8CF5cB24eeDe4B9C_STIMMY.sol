/**
 *Submitted for verification at Etherscan.io on 2021-11-16
*/

//            __      ______   ________  ______  __       __  __       __  __      __ 
//          _/  |_   /      \ /        |/      |/  \     /  |/  \     /  |/  \    /  |
//         / $$   \ /$$$$$$  |$$$$$$$$/ $$$$$$/ $$  \   /$$ |$$  \   /$$ |$$  \  /$$/ 
//        /$$$$$$  |$$ \__$$/    $$ |     $$ |  $$$  \ /$$$ |$$$  \ /$$$ | $$  \/$$/  
//        $$ \__$$/ $$      \    $$ |     $$ |  $$$$  /$$$$ |$$$$  /$$$$ |  $$  $$/   
//        $$      \  $$$$$$  |   $$ |     $$ |  $$ $$ $$/$$ |$$ $$ $$/$$ |   $$$$/    
//         $$$$$$  |/  \__$$ |   $$ |    _$$ |_ $$ |$$$/ $$ |$$ |$$$/ $$ |    $$ |    
//        /  \__$$ |$$    $$/    $$ |   / $$   |$$ | $/  $$ |$$ | $/  $$ |    $$ |    
//        $$    $$/  $$$$$$/     $$/    $$$$$$/ $$/      $$/ $$/      $$/     $$/     
//         $$$$$$/                                                                    
//           $$/                    


// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]


pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/token/ERC20/[email protected]


pragma solidity ^0.8.0;



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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
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


// File @openzeppelin/contracts/utils/introspection/[email protected]


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


// File @openzeppelin/contracts/token/ERC721/[email protected]


pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]


pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/access/[email protected]


pragma solidity ^0.8.0;

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

                                                  


pragma solidity ^0.8.0;
contract STIMMY is ERC20, Ownable {
    // token
    string token_name   = "STIMMY";
    string token_symbol = "STIMMY";
    
    // supply
    uint supply_initial  = (100 * 10**12) * 10**decimals();
    uint supply_burn     = ( 99 * 10**12) * 10**decimals();
    uint supply_official = (  1 * 10**12) * 10**decimals();
    
    uint supply_lp       = (400 * 10**9)  * 10**decimals();
    
    uint supply_punks    = (100 * 10**9)  * 10**decimals();
    uint supply_apes     = (100 * 10**9)  * 10**decimals();
    uint supply_coolCats = (100 * 10**9)  * 10**decimals();
    uint supply_doodles  = (100 * 10**9)  * 10**decimals();
    uint supply_beasts   = (100 * 10**9)  * 10**decimals();
    
    uint supply_green    = (100 * 10**9)  * 10**decimals();
    
    // transactions
    uint256 txn_max      = ( 15 * 10**9)  * 10**decimals();
    
    // rewards
    uint reward_punks    = supply_punks    / 10000;
    uint reward_apes     = supply_apes     / 10000;
    uint reward_coolCats = supply_coolCats / 10000;
    uint reward_doodles  = supply_doodles  / 10000;
    uint reward_beasts   = supply_beasts   / 10000;
    
    uint reward_green    = supply_green    / 10000;
    
    // claimed
    uint claimed_official = 0;
    
    uint claimed_lp       = 0;
    
    uint claimed_punks    = 0;
    uint claimed_apes     = 0;
    uint claimed_coolCats = 0;
    uint claimed_doodles  = 0;
    uint claimed_beasts   = 0;
    
    uint claimed_green    = 0;
    
    mapping(uint256 => bool) public claimedByTokenId_punks;
    mapping(uint256 => bool) public claimedByTokenId_apes;
    mapping(uint256 => bool) public claimedByTokenId_coolCats;
    mapping(uint256 => bool) public claimedByTokenId_doodles;
    mapping(uint256 => bool) public claimedByTokenId_beasts;
    
    mapping(uint256 => bool) public claimedBySlotId_green;
    
    // contracts
    address contract_punks    = address(0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB);
    address contract_apes     = address(0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D);
    address contract_coolCats = address(0x1A92f7381B9F03921564a437210bB9396471050C);
    address contract_doodles  = address(0x8a90CAb2b38dba80c64b7734e58Ee1dB38B8992e);
    address contract_beasts   = address(0xA74E199990FF572A320508547Ab7f44EA51e6F28);
    
    address address_uniswap   = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    
    using ECDSA for bytes32;
    
    constructor() ERC20(token_name, token_symbol) {
        _mint(address(this), supply_initial);
        _burn(address(this), supply_burn);
        _safeTransfer_lp(supply_lp);
    }
    
    function claim_punks(uint[] memory nfts) public {
        address user = msg.sender;
        
        CryptoPunks _contract = CryptoPunks(contract_punks);
        
        uint owned = nfts.length;
        uint rewards = 0;
        for (uint256 i = 0; i < owned; ++i) {
            uint256 nft = nfts[i];
            
            if(_contract.punkIndexToAddress(nft) == user && !claimedByTokenId_punks[nft]){
                rewards++;
                claimedByTokenId_punks[nft] = true;
            }
            
        }
        _safeTransfer_punks(reward_punks * rewards);
    }
    
    function claim_apes() public {
        address user = msg.sender;
        
        IERC721Enumerable _contract = IERC721Enumerable(contract_apes);
        
        uint owned = _contract.balanceOf(user);
        uint rewards = 0;
        
        for (uint256 i = 0; i < owned; ++i) {
            uint nft = _contract.tokenOfOwnerByIndex(user, i);
            if(!claimedByTokenId_apes[nft]){
                rewards++;
                claimedByTokenId_apes[nft] = true;
            }
        }
        _safeTransfer_apes(reward_apes * rewards);
    }
    
    function claim_coolCats() public {
        address user = msg.sender;
        
        IERC721Enumerable _contract = IERC721Enumerable(contract_coolCats);
        
        uint owned = _contract.balanceOf(user);
        uint rewards = 0;
        
        for (uint256 i = 0; i < owned; ++i) {
            uint nft = _contract.tokenOfOwnerByIndex(user, i);
            if (!claimedByTokenId_coolCats[nft]){
                rewards++;
                claimedByTokenId_coolCats[nft] = true;
            }
            claimedByTokenId_coolCats[nft] = true;
        }
        _safeTransfer_coolCats(reward_coolCats * rewards);
    }
    
    function claim_doodles() public {
        address user = msg.sender;
        
        IERC721Enumerable _contract = IERC721Enumerable(contract_doodles);
        
        uint owned = _contract.balanceOf(user);
        uint rewards = 0;
        
        for (uint256 i = 0; i < owned; ++i) {
            uint nft = _contract.tokenOfOwnerByIndex(user, i);
            if (!claimedByTokenId_doodles[nft]){
                rewards++;
                claimedByTokenId_doodles[nft] = true;
            }
            
        }
        _safeTransfer_doodles(reward_doodles * rewards);
    }
    
    function claim_beasts() public {
        address user = msg.sender;
        
        IERC721Enumerable _contract = IERC721Enumerable(contract_beasts);
        
        uint owned = _contract.balanceOf(user);
        uint rewards = 0;
        
        for (uint256 i = 0; i < owned; ++i) {
            uint nft = _contract.tokenOfOwnerByIndex(user, i);
            if (!claimedByTokenId_beasts[nft]){
                rewards++;
                claimedByTokenId_beasts[nft] = true;   
            }
        }
        _safeTransfer_beasts(reward_beasts * rewards);
    }
    
    function claim_green(uint slotId, bytes memory sig) public {
        require(_verifySignature(slotId, sig), "Invalid signature.");
        require(slotId >= 0 && slotId <= 9999, "Invalid slot number.");
        require(!claimedBySlotId_green[slotId], "Slot already claimed.");
        claimedBySlotId_green[slotId] = true;
        
        _safeTransfer_green(reward_green);
    }
    
    function _expire_green() public onlyOwner {
        uint remaining_green = supply_green - claimed_green;
        _safeTransfer_green(remaining_green);
    }
    
    function _verifySignature(uint256 slotId, bytes memory sig) internal view returns (bool) {
        bytes32 message = keccak256(abi.encodePacked(slotId, msg.sender)).toHash();
        address signer = message.recover(sig);
        return signer == owner();
    }
    
    function claim_1() public{
        claim_apes();
        claim_coolCats();
        claim_doodles();
        claim_beasts();
    }
    
    function claim_2(uint[] memory punks) public{
        claim_punks(punks);
        claim_apes();
        claim_coolCats();
        claim_doodles();
        claim_beasts();
    }
    
    function claim_3(uint256 slotId, bytes memory sig) public{
        claim_apes();
        claim_coolCats();
        claim_doodles();
        claim_beasts();
        claim_green(slotId, sig);
    }
    
    function claim_4(uint[] memory punks, uint256 slotId, bytes memory sig) public{
        claim_punks(punks);
        claim_apes();
        claim_coolCats();
        claim_doodles();
        claim_beasts();
        claim_green(slotId, sig);
    }
    
    function _safeTransfer_punks(uint amount) internal {
        claimed_punks += amount;
        require(supply_punks >= claimed_punks, "CryptoPunks fund fully claimed.");
        
        _safeTransfer(amount);
    }
    
    function _safeTransfer_apes(uint amount) internal {
        claimed_apes += amount;
        require(supply_apes >= claimed_apes, "Apes fund fully claimed.");
        
        _safeTransfer(amount);
    }
    
    function _safeTransfer_coolCats(uint amount) internal {
        claimed_coolCats += amount;
        require(supply_coolCats >= claimed_coolCats, "Cool Cats fund fully claimed.");
        
        _safeTransfer(amount);
    }
    
    function _safeTransfer_doodles(uint amount) internal {
        claimed_doodles += amount;
        require(supply_doodles >= claimed_doodles, "Doodles fund fully claimed.");
        
        _safeTransfer(amount);
    }
    
    function _safeTransfer_beasts(uint amount) internal {
        claimed_beasts += amount;
        require(supply_beasts >= claimed_beasts, "CryptoBeasts fund fully claimed.");
        
        _safeTransfer(amount);
    }
    
    function _safeTransfer_green(uint amount) internal {
        claimed_green += amount;
        require(supply_green >= claimed_green, "Green fund fully claimed.");
        
        _safeTransfer(amount);
    }
    
    function _safeTransfer_lp(uint amount) internal {
        claimed_lp += amount;
        require(supply_lp >= claimed_lp, "LP fund fully claimed.");
        
        _safeTransfer(amount);
    }
    
    function _safeTransfer(uint amount) internal {
        claimed_official += amount;
        require(supply_official >= claimed_official, "Official fund fully claimed.");
        
        _transfer(address(this), msg.sender, amount);
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override virtual {
        if(from != owner() && to != owner() && from != address(this) && to != address(this) && from != address_uniswap && to != address_uniswap)
            require(amount <= txn_max, "Transfer amount exceeds the maximum transaction amount.");
    }
    
    function _setTxnMax(uint _txn_max) public onlyOwner {
        txn_max = _txn_max;
    }

}

library ECDSA {
    function recover(bytes32 hash, bytes memory sig) internal pure returns (address) {
        uint8 v;
        bytes32 r;
        bytes32 s;

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        return ecrecover(hash, v, r, s);
    }

    function toHash(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

interface CryptoPunks {
    function punkIndexToAddress(uint index) external view returns(address);
}