/**
 *Submitted for verification at Etherscan.io on 2020-09-03
*/

/* solhint-disable no-mix-tabs-and-spaces */
/* solhint-disable indent */

pragma solidity 0.5.15;



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
contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of NFTs in `owner`'s account.
     */
    function balanceOf(address owner) public view returns (uint256 balance);

    /**
     * @dev Returns the owner of the NFT specified by `tokenId`.
     */
    function ownerOf(uint256 tokenId) public view returns (address owner);

    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     *
     *
     * Requirements:
     * - `from`, `to` cannot be zero.
     * - `tokenId` must be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this
     * NFT by either {approve} or {setApprovalForAll}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * Requirements:
     * - If the caller is not `from`, it must be approved to move this NFT by
     * either {approve} or {setApprovalForAll}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
contract IERC721Receiver {
    /**
     * @notice Handle the receipt of an NFT
     * @dev The ERC721 smart contract calls this function on the recipient
     * after a {IERC721-safeTransferFrom}. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onERC721Received.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the ERC721 contract address is always the message sender.
     * @param operator The address which called `safeTransferFrom` function
     * @param from The address which previously owned the token
     * @param tokenId The NFT identifier which is being transferred
     * @param data Additional data with no specified format
     * @return bytes4 `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
/* solhint-disable no-mix-tabs-and-spaces */
/* solhint-disable indent */




/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}




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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
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
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
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
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}


/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

contract MinterRole is Context {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(_msgSender());
    }

    modifier onlyMinter() {
        require(isMinter(_msgSender()), "MinterRole: caller does not have the Minter role");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(_msgSender());
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

/**
 * @dev Extension of {ERC20} that adds a set of accounts with the {MinterRole},
 * which have permission to mint (create) new tokens as they see fit.
 *
 * At construction, the deployer of the contract is the only minter.
 */
contract ERC20Mintable is ERC20, MinterRole {
    /**
     * @dev See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the {MinterRole}.
     */
    function mint(address account, uint256 amount) public onlyMinter returns (bool) {
        _mint(account, amount);
        return true;
    }
}

/**
 * @dev Extension of {ERC20Mintable} that adds a cap to the supply of tokens.
 */
contract ERC20Capped is ERC20Mintable {
    uint256 private _cap;

    /**
     * @dev Sets the value of the `cap`. This value is immutable, it can only be
     * set once during construction.
     */
    constructor (uint256 cap) public {
        require(cap > 0, "ERC20Capped: cap is 0");
        _cap = cap;
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view returns (uint256) {
        return _cap;
    }

    /**
     * @dev See {ERC20Mintable-mint}.
     *
     * Requirements:
     *
     * - `value` must not cause the total supply to go over the cap.
     */
    function _mint(address account, uint256 value) internal {
        require(totalSupply().add(value) <= _cap, "ERC20Capped: cap exceeded");
        super._mint(account, value);
    }
}


/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev See {ERC20-_burnFrom}.
     */
    function burnFrom(address account, uint256 amount) public {
        _burnFrom(account, amount);
    }
}




contract PauserRole is Context {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(_msgSender());
    }

    modifier onlyPauser() {
        require(isPauser(_msgSender()), "PauserRole: caller does not have the Pauser role");
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(_msgSender());
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
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
contract Pausable is Context, PauserRole {
    /**
     * @dev Emitted when the pause is triggered by a pauser (`account`).
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by a pauser (`account`).
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state. Assigns the Pauser role
     * to the deployer.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Called by a pauser to pause, triggers stopped state.
     */
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Called by a pauser to unpause, returns to normal state.
     */
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

/**
 * @title Pausable token
 * @dev ERC20 with pausable transfers and allowances.
 *
 * Useful if you want to stop trades until the end of a crowdsale, or have
 * an emergency switch for freezing all token transfers in the event of a large
 * bug.
 */
contract ERC20Pausable is ERC20, Pausable {
    function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
        return super.approve(spender, value);
    }

    function increaseAllowance(address spender, uint256 addedValue) public whenNotPaused returns (bool) {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public whenNotPaused returns (bool) {
        return super.decreaseAllowance(spender, subtractedValue);
    }
}
/* solhint-disable no-mix-tabs-and-spaces */
/* solhint-disable indent */



/**
	* @title Contract managing Shotgun Clause lifecycle
	* @author Joel Hubert (Metalith.io)
	* @dev OpenZeppelin contracts are not ready for 0.6.0 yet, using 0.5.16.
	* @dev This contract is deployed once a Shotgun is initiated by calling the Registry.
	*/

contract ShotgunClause {

	using SafeMath for uint256;

	ShardGovernor private _shardGovernor;
	ShardRegistry private _shardRegistry;

	enum ClaimWinner { None, Claimant, Counterclaimant }
	ClaimWinner private _claimWinner = ClaimWinner.None;

	uint private _deadlineTimestamp;
	uint private _initialOfferInWei;
	uint private _pricePerShardInWei;
	address payable private _initialClaimantAddress;
	uint private _initialClaimantBalance;
	bool private _shotgunEnacted = false;
	uint private _counterWeiContributed;
	address[] private _counterclaimants;
	mapping(address => uint) private _counterclaimContribs;

	event Countercommit(address indexed committer, uint indexed weiAmount);
	event EtherCollected(address indexed collector, uint indexed weiAmount);

	constructor(
		address payable initialClaimantAddress,
		uint initialClaimantBalance,
		address shardRegistryAddress
	) public payable {
		_shardGovernor = ShardGovernor(msg.sender);
		_shardRegistry = ShardRegistry(shardRegistryAddress);
		_deadlineTimestamp = now.add(1 * 14 days);
		_initialClaimantAddress = initialClaimantAddress;
		_initialClaimantBalance = initialClaimantBalance;
		_initialOfferInWei = msg.value;
		_pricePerShardInWei = (_initialOfferInWei.mul(10**18)).div(_shardRegistry.cap().sub(_initialClaimantBalance));
		_claimWinner = ClaimWinner.Claimant;
	}

	/**
		* @notice Contribute Ether to the counterclaim for this Shotgun.
		* @dev Automatically enacts Shotgun once enough Ether is raised and
		returns initial claimant's Ether offer.
		*/
	function counterCommitEther() external payable {
		require(
			_shardRegistry.balanceOf(msg.sender) > 0,
			"[counterCommitEther] Account does not own Shards"
		);
		require(
			msg.value > 0,
			"[counterCommitEther] Ether is required"
		);
		require(
			_initialClaimantAddress != address(0),
			"[counterCommitEther] Initial claimant does not exist"
		);
		require(
			msg.sender != _initialClaimantAddress,
			"[counterCommitEther] Initial claimant cannot countercommit"
		);
		require(
			!_shotgunEnacted,
			"[counterCommitEther] Shotgun already enacted"
		);
		require(
			now < _deadlineTimestamp,
			"[counterCommitEther] Deadline has expired"
		);
		require(
			msg.value + _counterWeiContributed <= getRequiredWeiForCounterclaim(),
			"[counterCommitEther] Ether exceeds goal"
		);
		if (_counterclaimContribs[msg.sender] == 0) {
			_counterclaimants.push(msg.sender);
		}
		_counterclaimContribs[msg.sender] = _counterclaimContribs[msg.sender].add(msg.value);
		_counterWeiContributed = _counterWeiContributed.add(msg.value);
		emit Countercommit(msg.sender, msg.value);
		if (_counterWeiContributed == getRequiredWeiForCounterclaim()) {
			_claimWinner = ClaimWinner.Counterclaimant;
			enactShotgun();
		}
	}

	/**
		* @notice Collect ether from completed Shotgun.
		* @dev Called by Shard Registry after burning caller's Shards.
		* @dev For counterclaimants, returns both the proportional worth of their
		Shards in Ether AND any counterclaim contributions they have made.
		* @dev alternative: OpenZeppelin PaymentSplitter
		*/
	function collectEtherProceeds(uint balance, address payable caller) external {
		require(
			msg.sender == address(_shardRegistry),
			"[collectEtherProceeds] Caller not authorized"
		);
		if (_claimWinner == ClaimWinner.Claimant && caller != _initialClaimantAddress) {
			uint weiProceeds = (_pricePerShardInWei.mul(balance)).div(10**18);
			weiProceeds = weiProceeds.add(_counterclaimContribs[caller]);
			_counterclaimContribs[caller] = 0;
			(bool success, ) = address(caller).call.value(weiProceeds)("");
			require(success, "[collectEtherProceeds] Transfer failed.");
			emit EtherCollected(caller, weiProceeds);
		} else if (_claimWinner == ClaimWinner.Counterclaimant && caller == _initialClaimantAddress) {
			uint amount = (_pricePerShardInWei.mul(_initialClaimantBalance)).div(10**18);
			amount = amount.add(_initialOfferInWei);
			_initialClaimantBalance = 0;
			(bool success, ) = address(caller).call.value(amount)("");
			require(success, "[collectEtherProceeds] Transfer failed.");
			emit EtherCollected(caller, amount);
		}
	}

	/**
		* @notice Use by successful counterclaimants to collect Shards from initial claimant.
		*/
	function collectShardProceeds() external {
		require(
			_shotgunEnacted && _claimWinner == ClaimWinner.Counterclaimant,
			"[collectShardProceeds] Shotgun has not been enacted or invalid winner"
		);
		require(
			_counterclaimContribs[msg.sender] != 0,
			"[collectShardProceeds] Account has not participated in counterclaim"
		);
		uint proportionContributed = (_counterclaimContribs[msg.sender].mul(10**18)).div(_counterWeiContributed);
		_counterclaimContribs[msg.sender] = 0;
		uint shardsToReceive = (proportionContributed.mul(_initialClaimantBalance)).div(10**18);
		_shardGovernor.transferShards(msg.sender, shardsToReceive);
	}

	function deadlineTimestamp() external view returns (uint256) {
		return _deadlineTimestamp;
	}

	function shotgunEnacted() external view returns (bool) {
		return _shotgunEnacted;
	}

	function initialClaimantAddress() external view returns (address) {
		return _initialClaimantAddress;
	}

	function initialClaimantBalance() external view returns (uint) {
		return _initialClaimantBalance;
	}

	function initialOfferInWei() external view returns (uint256) {
		return _initialOfferInWei;
	}

	function pricePerShardInWei() external view returns (uint256) {
		return _pricePerShardInWei;
	}

	function claimWinner() external view returns (ClaimWinner) {
		return _claimWinner;
	}

	function counterclaimants() external view returns (address[] memory) {
		return _counterclaimants;
	}

	function getCounterclaimantContribution(address counterclaimant) external view returns (uint) {
		return _counterclaimContribs[counterclaimant];
	}

	function counterWeiContributed() external view returns (uint) {
		return _counterWeiContributed;
	}

	function getContractBalance() external view returns (uint) {
		return address(this).balance;
	}

	function shardGovernor() external view returns (address) {
		return address(_shardGovernor);
	}

	function getRequiredWeiForCounterclaim() public view returns (uint) {
		return (_pricePerShardInWei.mul(_initialClaimantBalance)).div(10**18);
	}

	/**
		* @notice Initiate Shotgun enactment.
		* @dev Automatically called if enough Ether is raised by counterclaimants,
		or manually called if deadline expires without successful counterclaim.
		*/
	function enactShotgun() public {
		require(
			!_shotgunEnacted,
			"[enactShotgun] Shotgun already enacted"
		);
		require(
			_claimWinner == ClaimWinner.Counterclaimant ||
			(_claimWinner == ClaimWinner.Claimant && now > _deadlineTimestamp),
			"[enactShotgun] Conditions not met to enact Shotgun Clause"
		);
		_shotgunEnacted = true;
		_shardGovernor.enactShotgun();
	}
}

/**
	* @title ERC20 base for Shards with additional methods related to governance
	* @author Joel Hubert (Metalith.io)
	* @dev OpenZeppelin contracts are not ready for 0.6.0 yet, using 0.5.16.
	*/

contract ShardRegistry is ERC20Detailed, ERC20Capped, ERC20Burnable, ERC20Pausable {

	ShardGovernor private _shardGovernor;
	enum ClaimWinner { None, Claimant, Counterclaimant }
	bool private _shotgunDisabled;

	constructor (
		uint256 cap,
		string memory name,
		string memory symbol,
		bool shotgunDisabled
	) ERC20Detailed(name, symbol, 18) ERC20Capped(cap) public {
		_shardGovernor = ShardGovernor(msg.sender);
		_shotgunDisabled = shotgunDisabled;
	}

	/**
		* @notice Called to initiate Shotgun claim. Requires Ether.
		* @dev Transfers claimant's Shards into Governor contract's custody until
		claim is resolved.
		* @dev Forwards Ether to Shotgun contract through Governor contract.
		*/
	function lockShardsAndClaim() external payable {
		require(
				!_shotgunDisabled,
				"[lockShardsAndClaim] Shotgun disabled"
		);
		require(
			_shardGovernor.checkLock(),
			"[lockShardsAndClaim] NFT not locked, Shotgun cannot be triggered"
		);
		require(
			_shardGovernor.checkShotgunState(),
			"[lockShardsAndClaim] Shotgun already in progress"
		);
		require(
			msg.value > 0,
			"[lockShardsAndClaim] Transaction must send ether to activate Shotgun Clause"
		);
		uint initialClaimantBalance = balanceOf(msg.sender);
		require(
			initialClaimantBalance > 0,
			"[lockShardsAndClaim] Account does not own Shards"
		);
		require(
			initialClaimantBalance < cap(),
			"[lockShardsAndClaim] Account owns all Shards"
		);
		transfer(address(_shardGovernor), balanceOf(msg.sender));
		(bool success) = _shardGovernor.claimInitialShotgun.value(msg.value)(
			msg.sender, initialClaimantBalance
		);
		require(
			success,
			"[lockShards] Ether forwarding unsuccessful"
		);
	}

	/**
		* @notice Called to collect Ether from Shotgun proceeds. Burns Shard holdings.
		* @dev can be called in both Shotgun outcome scenarios by:
		- Initial claimant, if they lose the claim to counterclaimants and their
		Shards are bought out
		- Counterclaimants, bought out if initial claimant is successful.
		* @dev initial claimant does not own Shards at this point because they have
		been custodied in Governor contract at start of Shotgun.
		* @param shotgunClause address of the relevant Shotgun contract.
		*/
	function burnAndCollectEther(address shotgunClause) external {
		ShotgunClause _shotgunClause = ShotgunClause(shotgunClause);
		bool enacted = _shotgunClause.shotgunEnacted();
		if (!enacted) {
			_shotgunClause.enactShotgun();
		}
		require(
			enacted || _shotgunClause.shotgunEnacted(),
			"[burnAndCollectEther] Shotgun Clause not enacted"
		);
		uint balance = balanceOf(msg.sender);
		require(
			balance > 0 || msg.sender == _shotgunClause.initialClaimantAddress(),
			"[burnAndCollectEther] Account does not own Shards"
		);
		require(
			uint(_shotgunClause.claimWinner()) == uint(ClaimWinner.Claimant) &&
			msg.sender != _shotgunClause.initialClaimantAddress() ||
			uint(_shotgunClause.claimWinner()) == uint(ClaimWinner.Counterclaimant) &&
			msg.sender == _shotgunClause.initialClaimantAddress(),
			"[burnAndCollectEther] Account does not have right to collect ether"
		);
		burn(balance);
		_shotgunClause.collectEtherProceeds(balance, msg.sender);
	}

	function shotgunDisabled() external view returns (bool) {
		return _shotgunDisabled;
	}
}
/* solhint-disable no-mix-tabs-and-spaces */
/* solhint-disable indent */



/**
	* @title Contract managing Shard Offering lifecycle, similar to a crowdsale.
	* @author Joel Hubert (Metalith.io)
	* @dev OpenZeppelin contracts are not ready for 0.6.0 yet, using 0.5.16.
	* @dev Acts as a wallet containing subscriber Ether.
	*/

contract ShardOffering {

	using SafeMath for uint256;

	ShardGovernor private _shardGovernor;
	uint private _offeringDeadline;
	uint private _pricePerShardInWei;
	uint private _contributionTargetInWei;
	uint private _liqProviderCutInShards;
	uint private _artistCutInShards;
	uint private _offererShardAmount;

	address[] private _contributors;
	mapping(address => uint) private _contributionsinWei;
	mapping(address => uint) private _contributionsInShards;
	mapping(address => bool) private _hasClaimedShards;
	uint private _totalWeiContributed;
	uint private _totalShardsClaimed;
	bool private _offeringCompleted;

	event Contribution(address indexed contributor, uint indexed weiAmount);
	event OfferingWrappedUp();

	constructor(
		uint pricePerShardInWei,
		uint shardAmountOffered,
		uint liqProviderCutInShards,
		uint artistCutInShards,
		uint offeringDeadline,
		uint cap
	) public {
		_pricePerShardInWei = pricePerShardInWei;
		_liqProviderCutInShards = liqProviderCutInShards;
		_artistCutInShards = artistCutInShards;
		_offeringDeadline = offeringDeadline;
		_shardGovernor = ShardGovernor(msg.sender);
		_contributionTargetInWei = (pricePerShardInWei.mul(shardAmountOffered)).div(10**18);
		_offererShardAmount = cap.sub(shardAmountOffered).sub(liqProviderCutInShards).sub(artistCutInShards);
	}

	/**
		* @notice Contribute Ether to offering.
		* @dev Blocks Offerer from contributing. May be exaggerated.
		* @dev if target Ether amount is raised, automatically transfers Ether to Offerer.
		*/
	function contribute() external payable {
		require(
			!_offeringCompleted,
			"[contribute] Offering is complete"
		);
		require(
			msg.value > 0,
			"[contribute] Contribution requires ether"
		);
		require(
			msg.value <= _contributionTargetInWei - _totalWeiContributed,
			"[contribute] Ether value exceeds remaining quota"
		);
		require(
			msg.sender != _shardGovernor.offererAddress(),
			"[contribute] Offerer cannot contribute"
		);
		require(
			now < _offeringDeadline,
			"[contribute] Deadline for offering expired"
		);
		require(
			_shardGovernor.checkLock(),
			"[contribute] NFT not locked yet"
		);
		if (_contributionsinWei[msg.sender] == 0) {
			_contributors.push(msg.sender);
		}
		_contributionsinWei[msg.sender] = _contributionsinWei[msg.sender].add(msg.value);
		uint shardAmount = (msg.value.mul(10**18)).div(_pricePerShardInWei);
		_contributionsInShards[msg.sender] = _contributionsInShards[msg.sender].add(shardAmount);
		_totalWeiContributed = _totalWeiContributed.add(msg.value);
		_totalShardsClaimed = _totalShardsClaimed.add(shardAmount);
		if (_totalWeiContributed == _contributionTargetInWei) {
			_offeringCompleted = true;
			(bool success, ) = _shardGovernor.offererAddress().call.value(address(this).balance)("");
			require(success, "[contribute] Transfer failed.");
		}
		emit Contribution(msg.sender, msg.value);
	}

	/**
		* @notice Prematurely end Offering.
		* @dev Called by Governor contract when Offering deadline expires and has not
		* raised the target amount of Ether.
		* @dev reentrancy is guarded in _shardGovernor.checkOfferingAndIssue() by
		`hasClaimedShards`.
		*/
	function wrapUpOffering() external {
		require(
			msg.sender == address(_shardGovernor),
			"[wrapUpOffering] Unauthorized caller"
		);
		_offeringCompleted = true;
		(bool success, ) = _shardGovernor.offererAddress().call.value(address(this).balance)("");
		require(success, "[wrapUpOffering] Transfer failed.");
		emit OfferingWrappedUp();
	}

	/**
		* @notice Records Shard claim for subcriber.
		* @dev Can only be called by Governor contract on Offering close.
		* @param claimant wallet address of the person claiming the Shards they
		subscribed to.
		*/
	function claimShards(address claimant) external {
		require(
			msg.sender == address(_shardGovernor),
			"[claimShards] Unauthorized caller"
		);
		_hasClaimedShards[claimant] = true;
	}

	function offeringDeadline() external view returns (uint) {
		return _offeringDeadline;
	}

	function getSubEther(address sub) external view returns (uint) {
		return _contributionsinWei[sub];
	}

	function getSubShards(address sub) external view returns (uint) {
		return _contributionsInShards[sub];
	}

	function hasClaimedShards(address claimant) external view returns (bool) {
		return _hasClaimedShards[claimant];
	}

	function pricePerShardInWei() external view returns (uint) {
		return _pricePerShardInWei;
	}

	function offererShardAmount() external view returns (uint) {
		return _offererShardAmount;
	}

	function liqProviderCutInShards() external view returns (uint) {
		return _liqProviderCutInShards;
	}

	function artistCutInShards() external view returns (uint) {
		return _artistCutInShards;
	}

	function offeringCompleted() external view returns (bool) {
		return _offeringCompleted;
	}

	function totalShardsClaimed() external view returns (uint) {
		return _totalShardsClaimed;
	}

	function totalWeiContributed() external view returns (uint) {
		return _totalWeiContributed;
	}

	function contributionTargetInWei() external view returns (uint) {
		return _contributionTargetInWei;
	}

	function getContractBalance() external view returns (uint) {
		return address(this).balance;
	}

	function contributors() external view returns (address[] memory) {
		return _contributors;
	}
}
/* solhint-disable no-mix-tabs-and-spaces */
/* solhint-disable indent */


interface IUniswapExchange {
	function removeLiquidity(
		uint256 uniTokenAmount,
		uint256 minEth,
		uint256 minTokens,
		uint256 deadline
	) external returns(
		uint256, uint256
	);

	function transferFrom(
		address from,
		address to,
		uint256 value
	) external returns (bool);
}

/**
	* @title Contract managing Shard lifecycle (NFT custody + Shard issuance and redemption)
	* @author Joel Hubert (Metalith.io)
	* @dev OpenZeppelin contracts are not ready for 0.6.0 yet, using 0.5.15.
	* @dev This contract owns the Registry, Offering and any Shotgun contracts,
	* making it the gateway for core state changes.
	*/

contract ShardGovernor is IERC721Receiver {

  using SafeMath for uint256;

	// Equals `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
	bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

	ShardRegistry private _shardRegistry;
	ShardOffering private _shardOffering;
	ShotgunClause private _currentShotgunClause;
	address payable private _offererAddress;
	address private _nftRegistryAddress;
	address payable private _niftexWalletAddress;
	address payable private _artistWalletAddress;
	uint256 private _tokenId;

	enum ClaimWinner { None, Claimant, Counterclaimant }
	address[] private _shotgunAddressArray;
	mapping(address => uint) private _shotgunMapping;
	uint private _shotgunCounter;

	event NewShotgun(address indexed shotgun);
	event ShardsClaimed(address indexed claimant, uint indexed shardAmount);
	event NftRedeemed(address indexed redeemer);
	event ShotgunEnacted(address indexed enactor);
	event ShardsCollected(address indexed collector, uint indexed shardAmount, address indexed shotgun);

	/**
		* @dev Checks whether offerer indeed owns the relevant NFT.
		* @dev Offering deadline starts ticking on deployment, but offerer needs to transfer
		* NFT to this contract before anyone can contribute.
		*/
  constructor(
		address nftRegistryAddress,
		address payable offererAddress,
		uint256 tokenId,
		address payable niftexWalletAddress,
		address payable artistWalletAddress,
		uint liqProviderCutInShards,
		uint artistCutInShards,
		uint pricePerShardInWei,
		uint shardAmountOffered,
		uint offeringDeadline,
		uint256 cap,
		string memory name,
		string memory symbol,
		bool shotgunDisabled
	) public {
		require(
			IERC721(nftRegistryAddress).ownerOf(tokenId) == offererAddress,
			"Offerer is not owner of tokenId"
		);
		_nftRegistryAddress = nftRegistryAddress;
		_niftexWalletAddress = niftexWalletAddress;
		_artistWalletAddress = artistWalletAddress;
		_tokenId = tokenId;
		_offererAddress = offererAddress;
		_shardRegistry = new ShardRegistry(cap, name, symbol, shotgunDisabled);
		_shardOffering = new ShardOffering(
			pricePerShardInWei,
			shardAmountOffered,
			liqProviderCutInShards,
			artistCutInShards,
			offeringDeadline,
			cap
		);
  }

	/**
		* @dev Used to receive ether from the pullLiquidity function.
		*/
	function() external payable { }

	/**
		* @notice Issues Shards upon completion of Offering.
		* @dev Cap should equal totalSupply when all Shards have been claimed.
		* @dev The Offerer may close an undersubscribed Offering once the deadline has
		* passed and claim the remaining Shards.
		*/
	function checkOfferingAndIssue() external {
		require(
			_shardRegistry.totalSupply() != _shardRegistry.cap(),
			"[checkOfferingAndIssue] Shards have already been issued"
		);
		require(
			!_shardOffering.hasClaimedShards(msg.sender),
			"[checkOfferingAndIssue] You have already claimed your Shards"
		);
		require(
			_shardOffering.offeringCompleted() ||
			(now > _shardOffering.offeringDeadline() && !_shardOffering.offeringCompleted()),
			"Offering not completed or deadline not expired"
		);
		if (_shardOffering.offeringCompleted()) {
			if (_shardOffering.getSubEther(msg.sender) != 0) {
				_shardOffering.claimShards(msg.sender);
				uint subShards = _shardOffering.getSubShards(msg.sender);
				bool success = _shardRegistry.mint(msg.sender, subShards);
				require(success, "[checkOfferingAndIssue] Mint failed");
				emit ShardsClaimed(msg.sender, subShards);
			} else if (msg.sender == _offererAddress) {
				_shardOffering.claimShards(msg.sender);
				uint offShards = _shardOffering.offererShardAmount();
				bool success = _shardRegistry.mint(msg.sender, offShards);
				require(success, "[checkOfferingAndIssue] Mint failed");
				emit ShardsClaimed(msg.sender, offShards);
			}
		} else {
			_shardOffering.wrapUpOffering();
			uint remainingShards = _shardRegistry.cap().sub(_shardOffering.totalShardsClaimed());
			remainingShards = remainingShards
				.sub(_shardOffering.liqProviderCutInShards())
				.sub(_shardOffering.artistCutInShards());
			bool success = _shardRegistry.mint(_offererAddress, remainingShards);
			require(success, "[checkOfferingAndIssue] Mint failed");
			emit ShardsClaimed(msg.sender, remainingShards);
		}
	}

	/**
		* @notice Used by NIFTEX to claim predetermined amount of shards in offering in order
		* to bootstrap liquidity on Uniswap-type exchange.
		*/
	/* function claimLiqProviderShards() external {
		require(
			msg.sender == _niftexWalletAddress,
			"[claimLiqProviderShards] Unauthorized caller"
		);
		require(
			!_shardOffering.hasClaimedShards(msg.sender),
			"[claimLiqProviderShards] You have already claimed your Shards"
		);
		require(
			_shardOffering.offeringCompleted(),
			"[claimLiqProviderShards] Offering not completed"
		);
		_shardOffering.claimShards(_niftexWalletAddress);
		uint cut = _shardOffering.liqProviderCutInShards();
		bool success = _shardRegistry.mint(_niftexWalletAddress, cut);
		require(success, "[claimLiqProviderShards] Mint failed");
		emit ShardsClaimed(msg.sender, cut);
	} */

	function mintReservedShards(address _beneficiary) external {
		bool niftex;
		if (_beneficiary == _niftexWalletAddress) niftex = true;
		require(
			niftex ||
			_beneficiary == _artistWalletAddress,
			"[mintReservedShards] Unauthorized beneficiary"
		);
		require(
			!_shardOffering.hasClaimedShards(_beneficiary),
			"[mintReservedShards] Shards already claimed"
		);
		_shardOffering.claimShards(_beneficiary);
		uint cut;
		if (niftex) {
			cut = _shardOffering.liqProviderCutInShards();
		} else {
			cut = _shardOffering.artistCutInShards();
		}
		bool success = _shardRegistry.mint(_beneficiary, cut);
		require(success, "[mintReservedShards] Mint failed");
		emit ShardsClaimed(_beneficiary, cut);
	}

	/**
		* @notice In the unlikely case that one account accumulates all Shards,
		* they can be redeemed directly for the underlying NFT.
		*/
	function redeem() external {
		require(
			_shardRegistry.balanceOf(msg.sender) == _shardRegistry.cap(),
			"[redeem] Account does not own total amount of Shards outstanding"
		);
		IERC721(_nftRegistryAddress).safeTransferFrom(address(this), msg.sender, _tokenId);
		emit NftRedeemed(msg.sender);
	}

	/**
		* @notice Creates a new Shotgun claim.
		* @dev This Function is called from the Shard Registry because the claimant's
		* Shards must be frozen until the Shotgun is resolved: if they lose the claim,
		* their Shards are automatically distributed to the counterclaimants.
		* @dev The Registry is paused while an active Shotgun claim exists to
		* let the process work in an orderly manner.
		* @param initialClaimantAddress wallet address of the person who initiated Shotgun.
		* @param initialClaimantBalance Shard balance of the person who initiated Shotgun.
		*/
	function claimInitialShotgun(
		address payable initialClaimantAddress,
		uint initialClaimantBalance
	) external payable returns (bool) {
		require(
			msg.sender == address(_shardRegistry),
			"[claimInitialShotgun] Caller not authorized"
		);
		_currentShotgunClause = (new ShotgunClause).value(msg.value)(
			initialClaimantAddress,
			initialClaimantBalance,
			address(_shardRegistry)
		);
		emit NewShotgun(address(_currentShotgunClause));
		_shardRegistry.pause();
		_shotgunAddressArray.push(address(_currentShotgunClause));
		_shotgunCounter++;
		_shotgunMapping[address(_currentShotgunClause)] = _shotgunCounter;
		return true;
	}

	/**
		* @notice Effects the results of a (un)successful Shotgun claim.
		* @dev This Function can only be called by a Shotgun contract in two scenarios:
		* - Counterclaimants raise enough ether to buy claimant out
		* - Shotgun deadline passes without successful counter-raise, claimant wins
		*/
	function enactShotgun() external {
		require(
			_shotgunMapping[msg.sender] != 0,
			"[enactShotgun] Invalid Shotgun Clause"
		);
		ShotgunClause _shotgunClause = ShotgunClause(msg.sender);
		address initialClaimantAddress = _shotgunClause.initialClaimantAddress();
		if (uint(_shotgunClause.claimWinner()) == uint(ClaimWinner.Claimant)) {
			_shardRegistry.burn(_shardRegistry.balanceOf(initialClaimantAddress));
			IERC721(_nftRegistryAddress).safeTransferFrom(address(this), initialClaimantAddress, _tokenId);
			_shardRegistry.unpause();
			emit ShotgunEnacted(address(_shotgunClause));
		} else if (uint(_shotgunClause.claimWinner()) == uint(ClaimWinner.Counterclaimant)) {
			_shardRegistry.unpause();
			emit ShotgunEnacted(address(_shotgunClause));
		}
	}

	/**
		* @notice Transfer Shards to counterclaimants after unsuccessful Shotgun claim.
		* @dev This contract custodies the claimant's Shards when they claim Shotgun -
		* if they lose the claim these Shards must be transferred to counterclaimants.
		* This process is initiated by the relevant Shotgun contract.
		* @param recipient wallet address of the person receiving the Shards.
		* @param amount the amount of Shards to receive.
		*/
	function transferShards(address recipient, uint amount) external {
		require(
			_shotgunMapping[msg.sender] != 0,
			"[transferShards] Unauthorized caller"
		);
		bool success = _shardRegistry.transfer(recipient, amount);
		require(success, "[transferShards] Transfer failed");
		emit ShardsCollected(recipient, amount, msg.sender);
	}

	/**
		* @notice Allows liquidity providers to pull funds during shotgun.
		* @dev Requires Unitokens to be sent to the contract so the contract can
		* remove liquidity.
		* @param exchangeAddress address of the Uniswap pool.
		* @param liqProvAddress address of the liquidity provider.
		* @param uniTokenAmount liquidity tokens to redeem.
		* @param minEth minimum ether to withdraw.
		* @param minTokens minimum tokens to withdraw.
		* @param deadline deadline for the withdrawal.
		*/
	function pullLiquidity(
		address exchangeAddress,
		address liqProvAddress,
		uint256 uniTokenAmount,
		uint256 minEth,
		uint256 minTokens,
		uint256 deadline
	) public {
		require(msg.sender == _niftexWalletAddress, "[pullLiquidity] Unauthorized call");
		IUniswapExchange uniExchange = IUniswapExchange(exchangeAddress);
		uniExchange.transferFrom(liqProvAddress, address(this), uniTokenAmount);
		_shardRegistry.unpause();
		(uint ethAmount, uint tokenAmount) = uniExchange.removeLiquidity(uniTokenAmount, minEth, minTokens, deadline);
		(bool ethSuccess, ) = liqProvAddress.call.value(ethAmount)("");
		require(ethSuccess, "[pullLiquidity] ETH transfer failed.");
		bool tokenSuccess = _shardRegistry.transfer(liqProvAddress, tokenAmount);
		require(tokenSuccess, "[pullLiquidity] Token transfer failed");
		_shardRegistry.pause();
	}

	/**
		* @dev Utility function to check if a Shotgun is in progress.
		*/
	function checkShotgunState() external view returns (bool) {
		if (_shotgunCounter == 0) {
			return true;
		} else {
			ShotgunClause _shotgunClause = ShotgunClause(_shotgunAddressArray[_shotgunCounter - 1]);
			if (_shotgunClause.shotgunEnacted()) {
				return true;
			} else {
				return false;
			}
		}
	}

	function currentShotgunClause() external view returns (address) {
		return address(_currentShotgunClause);
	}

	function shardRegistryAddress() external view returns (address) {
		return address(_shardRegistry);
	}

	function shardOfferingAddress() external view returns (address) {
		return address(_shardOffering);
	}

	function getContractBalance() external view returns (uint) {
		return address(this).balance;
	}

	function offererAddress() external view returns (address payable) {
		return _offererAddress;
	}

	function shotgunCounter() external view returns (uint) {
		return _shotgunCounter;
	}

	function shotgunAddressArray() external view returns (address[] memory) {
		return _shotgunAddressArray;
	}

	/**
		* @dev Utility function to check whether this contract owns the Sharded NFT.
		*/
	function checkLock() external view returns (bool) {
		address owner = IERC721(_nftRegistryAddress).ownerOf(_tokenId);
		return owner == address(this);
	}

	/**
		* @notice Handle the receipt of an NFT.
		* @dev The ERC721 smart contract calls this function on the recipient
		* after a `safetransfer`. This function MAY throw to revert and reject the
		* transfer. Return of other than the magic value MUST result in the
		* transaction being reverted.
		* Note: the contract address is always the message sender.
		* @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
		*/
	function onERC721Received(address, address, uint256, bytes memory) public returns(bytes4) {
		return _ERC721_RECEIVED;
	}
}