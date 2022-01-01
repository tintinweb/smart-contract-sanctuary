/**
 *Submitted for verification at Etherscan.io on 2021-12-31
*/

/**********************************************************************************************
 $$$$$$\             $$$$$$\        $$$$$$$\  $$$$$$$$\ $$\   $$\  $$$$$$\  $$$$$$\ $$\
$$  __$$\    $$\    $$  __$$\       $$  __$$\ $$  _____|$$$\  $$ |$$  __$$\ \_$$  _|$$ |
\__/  $$ |   $$ |   \__/  $$ |      $$ |  $$ |$$ |      $$$$\ $$ |$$ /  \__|  $$ |  $$ |
 $$$$$$  |$$$$$$$$\  $$$$$$  |      $$$$$$$  |$$$$$\    $$ $$\$$ |$$ |        $$ |  $$ |
$$  ____/ \__$$  __|$$  ____/       $$  ____/ $$  __|   $$ \$$$$ |$$ |        $$ |  $$ |
$$ |         $$ |   $$ |            $$ |      $$ |      $$ |\$$$ |$$ |  $$\   $$ |  $$ |
$$$$$$$$\    \__|   $$$$$$$$\       $$ |      $$$$$$$$\ $$ | \$$ |\$$$$$$  |$$$$$$\ $$$$$$$$\
\________|          \________|      \__|      \________|\__|  \__| \______/ \______|\________|
**********************************************************************************************/

// Powered by NFT Artisans (nftartisans.io) - [email protected]
// Sources flattened with hardhat v2.6.8 https://hardhat.org
// SPDX-License-Identifier: MIT


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

// File @openzeppelin/contracts/token/ERC20/[email protected]
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


// File contracts/Pencil.sol
pragma solidity ^0.8.4;


interface TPT {
    function balanceOf(address owner) external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}

interface TPTM is TPT {
    function balancesOfOwnerByRarity(address owner) external view returns (uint8[] memory);
}

/**
 * $PENCIL utility token for 2+2 ecosystem.
 *
 * Rewards system based on 2+2 Genesis NFT (addition) rarity levels and Gen2 (subtraction) NFT ownership.
 * When Gen3 (multiplication) NFT is deployed, multipliers will be applied based upon those rarity levels.
 * Future 2+2 ecosystem contracts will be authorized to burn tokens as part of the claiming process.
 *
 * We have followed the Solidity general layout of state variables in storage to compact the data and reduce gas.
 * Multiple, contiguous items that need less than 256 bits are packed into single storage slots when possible.
 */
contract Pencil is ERC20, Ownable {
    TPT public TPTGen1;
    TPT public TPTGen2;
    TPTM public TPTGen3;

    bool public accumulationActive = false;
    bool public accumulationMultiplier = false;
    uint48 public start;
    uint192 public cap;

    struct Level {
        uint64 dailyReward;
        uint64 multiplier;
        uint128 baseClaim;
    }

    struct TokenLengths {
        uint8 level0;
        uint8 level1;
        uint8 level2;
        uint8 level3;
        uint8 level4;
        uint8 level5;
    }

    bool[1953] private _gen1BaseClaimed;
    bool[1953] private _gen2BaseClaimed;
    uint8[1953] private _rewardLevel = [4,4,3,2,4,5,5,1,1,3,2,5,5,5,3,0,4,5,4,4,5,4,1,4,4,0,2,3,0,3,3,3,2,3,2,5,4,5,5,5,3,3,0,2,1,4,4,2,0,3,4,5,5,0,4,3,5,1,4,3,2,3,5,1,2,5,5,5,3,5,5,1,3,0,5,4,3,2,5,5,5,5,0,5,5,2,2,5,5,4,5,3,3,3,4,3,4,4,1,5,3,4,4,2,1,4,0,3,5,3,2,3,5,4,3,4,3,5,5,2,5,4,4,5,5,4,3,5,3,3,1,1,0,5,5,4,5,3,4,4,5,5,4,5,5,2,3,1,3,1,4,2,1,3,3,5,4,5,3,5,5,2,2,5,3,3,4,4,3,1,4,4,2,4,0,5,3,4,2,0,0,3,5,2,5,5,4,3,5,4,4,4,5,5,5,4,3,5,4,5,5,3,2,1,5,2,3,4,4,2,5,4,4,5,5,3,3,4,5,5,1,1,3,5,4,1,3,4,3,5,3,2,4,1,2,5,4,0,0,4,1,0,0,2,5,5,5,4,2,3,5,5,3,4,5,4,3,2,2,4,4,1,4,3,4,4,3,4,5,3,4,4,3,2,5,2,3,3,4,4,4,4,1,5,4,0,4,4,2,3,1,5,3,5,4,3,1,3,5,2,4,1,5,4,2,5,4,3,3,1,5,1,3,4,3,2,5,2,5,5,3,5,1,3,1,5,4,4,4,5,4,1,5,5,0,4,5,1,3,5,2,3,1,4,4,5,4,4,4,5,4,2,3,1,3,4,2,3,1,5,2,3,1,3,4,1,5,2,4,2,5,5,5,1,4,1,4,5,5,4,2,3,2,4,4,3,4,3,0,2,2,4,1,2,1,3,2,3,1,4,4,4,3,3,3,1,3,4,4,4,1,5,3,2,4,4,3,5,4,1,4,2,2,3,3,0,5,5,4,5,5,4,0,4,5,3,3,3,4,4,5,4,2,2,2,1,2,3,3,5,4,5,3,4,4,5,5,5,3,4,1,4,3,4,4,5,4,5,5,3,3,2,2,5,5,4,2,3,3,4,1,4,4,0,2,3,5,5,3,4,4,3,3,5,5,2,4,0,4,2,2,2,5,2,4,1,5,5,4,5,0,5,5,4,5,5,3,0,4,1,5,3,5,1,3,5,5,5,2,3,1,1,2,3,3,5,4,5,2,5,2,1,1,1,3,2,5,3,1,4,2,5,5,2,5,4,4,5,2,5,5,4,5,5,5,1,4,4,5,3,5,4,3,2,1,2,5,5,2,4,0,3,3,4,1,3,3,4,2,5,5,5,4,5,5,4,4,5,3,4,5,4,2,4,3,3,2,0,5,0,3,5,3,3,5,0,3,2,3,3,5,4,1,2,4,2,5,3,0,4,1,1,5,5,3,5,1,3,5,5,4,3,0,1,5,0,5,2,5,4,1,1,5,4,5,3,1,3,5,5,1,4,4,4,1,2,3,1,3,3,3,4,1,5,0,2,5,2,4,5,5,5,3,4,2,0,2,3,3,2,4,3,3,4,2,0,1,4,5,5,4,4,3,1,1,4,3,5,4,1,5,5,4,0,4,4,2,2,5,4,5,4,5,4,3,2,5,4,2,5,5,3,5,1,1,5,3,4,1,5,2,4,5,2,5,2,2,4,5,5,0,1,3,1,4,5,5,5,4,5,3,2,3,4,3,4,2,3,4,2,5,1,2,4,3,4,4,2,4,4,5,4,2,4,2,4,5,5,4,4,4,1,5,1,1,2,1,2,5,5,4,3,2,5,5,3,4,5,0,1,5,3,4,5,5,2,1,5,4,4,5,3,0,1,2,2,1,5,1,5,4,3,5,5,5,4,2,4,4,1,3,3,5,4,0,5,5,5,4,2,2,1,5,4,2,5,4,3,1,3,3,5,2,4,3,5,2,4,5,5,3,2,4,2,5,3,5,5,4,2,4,3,5,3,5,4,0,3,3,4,3,5,2,5,4,1,3,4,0,4,1,5,5,5,4,3,4,4,0,2,5,5,1,3,4,3,5,4,3,2,3,3,2,4,2,4,4,0,5,2,4,2,5,5,4,2,5,0,3,4,5,5,3,5,2,5,2,5,2,5,5,5,5,2,3,4,4,5,1,5,4,4,5,5,5,1,3,5,4,2,1,5,3,3,2,2,5,2,5,0,3,3,4,3,5,3,4,5,5,0,5,5,2,4,5,5,5,4,1,5,5,4,3,5,3,2,5,5,5,3,2,3,5,3,3,5,2,4,1,5,5,3,3,3,4,4,3,5,1,5,3,5,1,3,5,2,5,1,4,5,2,4,3,3,2,3,4,2,5,4,4,0,4,5,1,3,4,4,0,5,5,4,4,4,4,2,3,4,4,0,5,5,3,2,5,3,1,3,3,5,3,5,4,3,5,2,5,5,1,4,3,5,4,5,4,3,4,3,1,3,2,4,3,4,3,4,2,1,1,1,1,2,1,3,2,5,0,3,4,1,3,2,4,4,4,5,4,5,0,2,4,3,2,4,3,3,4,5,5,2,3,4,2,3,1,3,2,3,2,2,1,2,4,3,4,5,2,5,0,4,2,4,5,1,4,2,5,5,4,0,4,4,4,5,4,3,2,4,5,3,3,2,3,5,5,3,4,5,5,5,5,2,2,1,3,5,2,4,2,3,5,0,4,3,5,0,5,4,3,4,4,1,4,4,5,3,2,2,3,2,5,3,1,5,5,5,1,1,0,1,3,2,1,4,2,2,3,2,1,5,2,4,3,3,2,3,0,5,5,5,0,1,5,5,5,3,5,3,4,5,2,0,4,3,3,5,5,2,4,2,3,4,3,3,2,2,1,5,2,5,4,5,5,5,1,3,4,1,5,2,2,5,2,5,2,4,3,3,3,5,4,2,4,4,3,5,4,5,5,5,1,5,4,4,2,3,4,2,3,5,4,3,1,4,3,3,5,4,4,4,5,3,3,3,4,3,4,3,5,5,5,3,3,2,5,3,3,5,2,4,3,1,0,2,5,2,3,4,5,2,5,3,4,4,2,2,5,1,3,5,4,5,0,5,3,4,4,4,2,2,3,5,5,4,3,3,4,2,3,4,3,2,4,2,4,4,4,2,5,5,4,4,2,1,2,2,3,4,3,1,4,4,5,2,5,3,5,5,4,0,4,5,4,5,4,4,5,4,4,5,1,4,2,4,2,0,2,4,3,3,3,1,2,4,4,4,5,5,5,3,4,4,4,5,5,5,2,3,3,2,3,5,4,4,3,0,3,5,3,2,2,1,1,5,3,4,4,5,5,1,3,5,2,4,2,4,5,3,4,5,4,3,0,2,3,2,1,3,5,2,3,5,5,2,2,4,1,3,4,0,4,4,5,2,4,1,5,4,2,3,2,4,1,2,4,3,4,5,2,1,4,3,3,2,3,4,2,3,0,5,4,5,3,3,0,4,4,5,1,4,2,5,4,1,4,3,3,0,0,3,2,4,1,2,5,5,1,5,1,5,3,4,3,5,5,5,5,4,3,5,5,4,5,3,5,2,5,2,5,5,5,4,3,4,4,4,1,1,5,5,4,4,4,4,5,4,4,1,5,0,5,3,5,4,4,4,4,0,0,4,5,5,4,4,3,4,3,5,5,2,3,3,1,3,5,3,0,1,4,3,0,3,5,1,4,3,5,4,5,5,4,1,5,2,1,5,3,4,4,2,4,1,0,2,0,1,4,4,2,4,2,5,5,1,4,3,4,1,2,3,5,5,4,5,4,3,1,3,5,2,3,2,5,1,3,1,4,5,4,4,4,4,3,0,2,2,0,1,2,0,2,5,4,5,2,1,2,4,3,3,2,0,3,2,2,4,5,2,4,3,2,5,1,4,2,4,4,4,4,2,5,4,5,4,4,3,3,5,5,5,1,4,1,5,2,1,4,3,5,1,3,4,3,4,1,0,3,2,5,3,3,4,5,0,5,5,3,3,5,5,3,5,2,4,3,2,3,5,3,3,4,2,4,5,4,5,5,5,1,5,5,4,2,4,1,5,4,5,3,5,4,4,4,4,3,4,2,5,4,5,5,0,0,2,1,1,2,5,4,3,3,5,4,4,5,4,2,3,2,2,3,4,4,3,5,3,3,5,5,1,1,4,1,2,5,2,2,5,3,3,3,4,4,5,4,5,0,5,5,4,5,5,1,4,0,4,4,3,4,2,4,2,5,3,5,4,4,5,5,3,2,4,5,2,4,1,0,2,4,5,3,3,5,1,5,4,5,3,4,5,2,4,3,5,3,3,5,2,4,3,4,4,4,2,2,4,2,3,4,3,5,3,3,5,4,5,5,5,5,5,0,5,3,2,2,4,4,5,5,4,3,4,1];
    uint48[1953] private _lastClaimed;

    mapping(uint256 => Level) public levels;
    mapping(address => bool) public allowedToBurn;

    event BaseRewardClaimed(uint256 gen1TokenId, uint256 gen2TokenId, uint256 amount);
    event RewardClaimed(uint256 gen1TokenId, uint256 amount);

    constructor(address gen1, address gen2) ERC20("Pencil", "PENCIL") {
        TPTGen1 = TPT(gen1);
        TPTGen2 = TPT(gen2);
        cap = 20000000 * 10 ** 18;

        _setLevel(0, 10, 60, 400);  // Einstein
        _setLevel(1,  9, 50, 360);  // Pythagoras
        _setLevel(2,  8, 40, 320);  // Euclid
        _setLevel(3,  7, 30, 280);  // Archimedes
        _setLevel(4,  6, 20, 240);  // Aristotle
        _setLevel(5,  5, 10, 200);  // Gauss

        _mint(_msgSender(), 20000 * 10 ** 18);
    }

    function burn(address user, uint256 amount) external {
        require(allowedToBurn[msg.sender], "Address does not have permission to burn");
        _burn(user, amount);
    }

    // Checks an address for the total amount of base rewards they can claim for owning one or more Gen1 & Gen2 NFTs.
    // Note these NFTs may have already been claimed by a previous owner, as the base claim is tracked by token id.
    function checkBaseReward(address recipient) external view returns (uint256) {
        uint256 gen1Count = TPTGen1.balanceOf(recipient);
        require(gen1Count > 0, "Wallet must own a Genesis NFT");

        uint256 gen2Count = TPTGen2.balanceOf(recipient);
        require(gen2Count > 0, "Wallet must own a Gen2 NFT");

        uint256[] memory gen2TokenIds = new uint256[](gen2Count);
        uint256 gen2TokenIdsLength;

        for (uint256 i; i < gen2Count; i++) {
            uint256 gen2TokenId = TPTGen2.tokenOfOwnerByIndex(recipient, i);
            if (_gen2BaseClaimed[gen2TokenId] == false) {
                gen2TokenIds[gen2TokenIdsLength] = gen2TokenId;
                gen2TokenIdsLength++;
            }
        }

        require(gen2TokenIdsLength > 0, "No unclaimed Gen2 NFTs available");

        uint256 total;

        for (uint256 i; i < gen1Count; i++) {
            uint256 gen1TokenId = TPTGen1.tokenOfOwnerByIndex(recipient, i);
            if (_gen1BaseClaimed[gen1TokenId] == false && gen2TokenIdsLength > 0) {
                gen2TokenIdsLength--;
                total += levels[_rewardLevel[gen1TokenId]].baseClaim;
            }
        }

        return total;
    }

    // Check if the base reward has been claimed for the given token id on either the gen1 or gen2 NFTs
    function checkBaseRewardByTokenId(uint256 nftId, uint8 gen) external view returns (bool) {
        require(nftId < 1953, "Invalid Token ID");

        if (gen == 2) {
            return _gen1BaseClaimed[nftId];
        }

        return _gen2BaseClaimed[nftId];
    }

    // Checks an address for the total amount of accumulated daily rewards, but without any multipliers added
    function checkReward(address recipient) external view returns (uint256) {
        require(accumulationActive == true, "Reward claiming not active");

        uint256 gen1Count = TPTGen1.balanceOf(recipient);
        require(gen1Count > 0, "Wallet must own a Genesis NFT");

        uint256 total;
        for (uint256 i; i < gen1Count; i++) {
            uint256 gen1TokenId = TPTGen1.tokenOfOwnerByIndex(recipient, i);
            total += levels[_rewardLevel[gen1TokenId]].dailyReward * (block.timestamp - (_lastClaimed[gen1TokenId] > 0 ? _lastClaimed[gen1TokenId] : start)) / 86400;
        }

        return total;
    }

    // Claim the base $PENCIL rewards for all unclaimed Gen1 + Gen2 NFTs owned by the sender. Each NFT token must not
    // have already been claimed, and rewards based on Gen1 rarity level paired with an available Gen2.
    function claimBaseReward() external {
        uint256 gen1Count = TPTGen1.balanceOf(msg.sender);
        require(gen1Count > 0, "Wallet must own a Genesis NFT");

        uint256 gen2Count = TPTGen2.balanceOf(msg.sender);
        require(gen2Count > 0, "Wallet must own a Gen2 NFT");

        uint256[] memory gen2TokenIds = new uint256[](gen2Count);
        uint256 gen2TokenIdsLength;

        for (uint256 i; i < gen2Count; i++) {
            uint256 gen2TokenId = TPTGen2.tokenOfOwnerByIndex(msg.sender, i);
            if (_gen2BaseClaimed[gen2TokenId] == false) {
                gen2TokenIds[gen2TokenIdsLength] = gen2TokenId;
                gen2TokenIdsLength++;
            }
        }

        require(gen2TokenIdsLength > 0, "No unclaimed Gen2 NFTs available");

        bool rewarded;
        for (uint256 i; i < gen1Count; i++) {
            uint256 gen1TokenId = TPTGen1.tokenOfOwnerByIndex(msg.sender, i);
            if (_gen1BaseClaimed[gen1TokenId] == false && gen2TokenIdsLength > 0) {
                gen2TokenIdsLength--;
                uint256 amount = levels[_rewardLevel[gen1TokenId]].baseClaim;

                _mint(_msgSender(), amount);
                _gen1BaseClaimed[gen1TokenId] = true;
                _gen2BaseClaimed[gen2TokenIds[gen2TokenIdsLength]] = true;
                rewarded = true;

                emit BaseRewardClaimed(gen1TokenId, gen2TokenIds[gen2TokenIdsLength], amount);
            }
        }

        require(rewarded == true, "No unclaimed Gen1 NFTs available");
    }

    function claimReward() external {
        require(accumulationActive == true, "Reward claiming not active");

        uint8[] memory multipliers = new uint8[](6);
        TokenLengths memory gen1TokenLengths;
        uint256 gen1Count = TPTGen1.balanceOf(msg.sender);
        uint256 gen3Count;
        uint256 total;

        uint256[] memory gen1TokenIdsLevel0 = new uint256[](gen1Count);
        uint256[] memory gen1TokenIdsLevel1 = new uint256[](gen1Count);
        uint256[] memory gen1TokenIdsLevel2 = new uint256[](gen1Count);
        uint256[] memory gen1TokenIdsLevel3 = new uint256[](gen1Count);
        uint256[] memory gen1TokenIdsLevel4 = new uint256[](gen1Count);
        uint256[] memory gen1TokenIdsLevel5 = new uint256[](gen1Count);

        require(gen1Count > 0, "Wallet must own a Genesis NFT");

        // Capped due to possible stack limitations later on
        if (gen1Count > 40) {
            gen1Count = 40;
        }

        if (accumulationMultiplier == true) {
            gen3Count = TPTGen3.balanceOf(msg.sender);
            if (gen3Count > 0) {
                multipliers = TPTGen3.balancesOfOwnerByRarity(msg.sender);
            }
        }

        for (uint256 i; i < gen1Count; i++) {
            uint256 gen1TokenId = TPTGen1.tokenOfOwnerByIndex(msg.sender, i);

            if (_rewardLevel[gen1TokenId] == 5) {
                gen1TokenIdsLevel5[gen1TokenLengths.level5] = gen1TokenId;
                gen1TokenLengths.level5++;
            }
            else if (_rewardLevel[gen1TokenId] == 4) {
                gen1TokenIdsLevel4[gen1TokenLengths.level4] = gen1TokenId;
                gen1TokenLengths.level4++;
            }
            else if (_rewardLevel[gen1TokenId] == 3) {
                gen1TokenIdsLevel3[gen1TokenLengths.level3] = gen1TokenId;
                gen1TokenLengths.level3++;
            }
            else if (_rewardLevel[gen1TokenId] == 2) {
                gen1TokenIdsLevel2[gen1TokenLengths.level2] = gen1TokenId;
                gen1TokenLengths.level2++;
            }
            else if (_rewardLevel[gen1TokenId] == 1) {
                gen1TokenIdsLevel1[gen1TokenLengths.level1] = gen1TokenId;
                gen1TokenLengths.level1++;
            }
            else {
                gen1TokenIdsLevel0[gen1TokenLengths.level0] = gen1TokenId;
                gen1TokenLengths.level0++;
            }
        }

        // Einstein rewards
        if (gen1TokenLengths.level0 > 0) {
            total += _getClaim(gen1TokenIdsLevel0, multipliers, gen1TokenLengths, gen3Count, 0);
        }

        // Pythagoras rewards
        if (gen1TokenLengths.level1 > 0) {
            total += _getClaim(gen1TokenIdsLevel1, multipliers, gen1TokenLengths, gen3Count, 1);
        }

        // Euclid rewards
        if (gen1TokenLengths.level2 > 0) {
            total += _getClaim(gen1TokenIdsLevel2, multipliers, gen1TokenLengths, gen3Count, 2);
        }

        // Archimedes rewards
        if (gen1TokenLengths.level3 > 0) {
            total += _getClaim(gen1TokenIdsLevel3, multipliers, gen1TokenLengths, gen3Count, 3);
        }

        // Aristotle rewards
        if (gen1TokenLengths.level4 > 0) {
            total += _getClaim(gen1TokenIdsLevel4, multipliers, gen1TokenLengths, gen3Count, 4);
        }

        // Gauss rewards
        if (gen1TokenLengths.level5 > 0) {
            total += _getClaim(gen1TokenIdsLevel5, multipliers, gen1TokenLengths, gen3Count, 5);
        }

        _mint(_msgSender(), total);
    }

    function flipState() external onlyOwner {
        accumulationActive = !accumulationActive;
        if (start == 0) {
            start = uint48(block.timestamp);
        }
    }

    function flipStateMultiplier() external onlyOwner {
        accumulationMultiplier = !accumulationMultiplier;
    }

    function _getClaim(uint256[] memory _gen1TokenIds, uint8[] memory _multipliers, TokenLengths memory _gen1TokenLengths, uint256 _gen3Count, uint256 _levelIdx) internal returns (uint256) {
        uint256 total;
        uint256 gen1Count;
        uint256 multiplierIdx;

        if (_levelIdx == 5) {
            multiplierIdx = _gen1TokenLengths.level4 + _gen1TokenLengths.level3 + _gen1TokenLengths.level2 + _gen1TokenLengths.level1 + _gen1TokenLengths.level0;
            gen1Count = _gen1TokenLengths.level5;
        }
        else if (_levelIdx == 4) {
            multiplierIdx = _gen1TokenLengths.level3 + _gen1TokenLengths.level2 + _gen1TokenLengths.level1 + _gen1TokenLengths.level0;
            gen1Count = _gen1TokenLengths.level4;
        }
        else if (_levelIdx == 3) {
            multiplierIdx = _gen1TokenLengths.level2 + _gen1TokenLengths.level1 + _gen1TokenLengths.level0;
            gen1Count = _gen1TokenLengths.level3;
        }
        else if (_levelIdx == 2) {
            multiplierIdx = _gen1TokenLengths.level1 + _gen1TokenLengths.level0;
            gen1Count = _gen1TokenLengths.level2;
        }
        else if (_levelIdx == 1) {
            multiplierIdx = _gen1TokenLengths.level0;
            gen1Count = _gen1TokenLengths.level1;
        }
        else {
            gen1Count = _gen1TokenLengths.level0;
        }

        for (uint256 i; i < gen1Count; i++) {
            uint256 amount = levels[_levelIdx].dailyReward * (block.timestamp - (_lastClaimed[_gen1TokenIds[i]] > 0 ? _lastClaimed[_gen1TokenIds[i]] : start)) / 86400;

            if (multiplierIdx < _gen3Count) {
                for (uint256 l; l < 6; l++) {
                    if (_multipliers[l] > 0) {
                        amount += (amount * uint256(levels[l].multiplier)) / 100;
                        _multipliers[l]--;
                        break;
                    }
                }
                multiplierIdx++;
            }

            total += amount;
            _lastClaimed[_gen1TokenIds[i]] = uint48(block.timestamp);
            emit RewardClaimed(_gen1TokenIds[i], amount);
        }

        return total;
    }

    function _mint(address account, uint256 amount) internal virtual override {
        require(totalSupply() + amount <= cap, "Cap exceeded");
        super._mint(account, amount);
    }

    function setCap(uint192 amount) external onlyOwner {
        require(amount > 0, "Invalid cap");
        cap = amount * 10 ** 18;
    }

    function setAllowedToBurn(address account, bool allowed) public onlyOwner {
        allowedToBurn[account] = allowed;
    }

    function setLevel(uint256 idx, uint64 dailyReward, uint64 multiplier, uint128 baseClaim) external onlyOwner {
        require(idx >= 0 && idx <= 6, "Invalid level index");
        require(baseClaim > 0, "Base claim must be greater than 0");
        require(dailyReward > 0, "Daily reward must be greater than 0");
        require(multiplier >= 0, "Invalid multiplier bonus");
        _setLevel(idx, dailyReward, multiplier, baseClaim);
    }

    function _setLevel(uint256 _idx, uint64 _dailyReward, uint64 _multiplier, uint128 _baseClaim) internal {
        levels[_idx] = Level(_dailyReward * 10 ** 18, _multiplier, _baseClaim * 10 ** 18);
    }

    function setMultiplierAddress(address account) external onlyOwner {
        TPTGen3 = TPTM(account);
        setAllowedToBurn(account, true);
    }
}