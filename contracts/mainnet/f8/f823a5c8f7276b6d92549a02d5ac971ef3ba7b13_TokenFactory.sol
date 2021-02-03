/**
 *Submitted for verification at Etherscan.io on 2021-02-01
*/

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/access/Authorizable.sol

pragma solidity ^0.5.8;


contract Authorizable is Ownable {

    mapping(address => bool) private authorized;

    modifier onlyAuthorized() {
        require(authorized[msg.sender], "Authorizable: Address is not authorized");
        _;
    }

    event AddressEnabled(address enabledAddress);
    event AddressDisabled(address disabledAddress);

    function enableAddress(address _address) public onlyOwner {
        authorized[_address] = true;
        emit AddressEnabled(_address);
    }

    function disableAddress(address _address) public onlyOwner {
        authorized[_address] = false;
        emit AddressDisabled(_address);
    }

    function isAuthorized(address _address) public view returns (bool) {
        return authorized[_address];
    }

}

// File: contracts/access/TokenAccessList.sol

pragma solidity ^0.5.8;


contract TokenAccessList is Ownable {

    string public identifier;
    mapping(address => bool) private accessList;

    event WalletEnabled(address indexed wallet);
    event WalletDisabled(address indexed wallet);

    constructor(string memory _identifier) public {
        identifier = _identifier;
    }

    function enableWallet(address _wallet)
        public
        onlyOwner
        {
            require(_wallet != address(0), "Invalid wallet");
            accessList[_wallet] = true;
            emit WalletEnabled(_wallet);
    }

    function disableWallet(address _wallet)
        public
        onlyOwner
        {
            accessList[_wallet] = false;
            emit WalletDisabled(_wallet);
    }

    function enableWalletList(address[] calldata _walletList)
        external
        onlyOwner {
            for(uint i = 0; i < _walletList.length; i++) {
                enableWallet(_walletList[i]);
            }
    }

    function disableWalletList(address[] calldata _walletList)
        external
        onlyOwner {
            for(uint i = 0; i < _walletList.length; i++) {
                disableWallet(_walletList[i]);
            }
    }

    function checkEnabled(address _wallet)
        public
        view
        returns (bool) {
            return _wallet == address(0) || accessList[_wallet];
    }

    function checkEnabledList(address _w1, address _w2, address _w3)
        external
        view
        returns (bool) {
            return checkEnabled(_w1)
                && checkEnabled(_w2)
                && checkEnabled(_w3);
    }

}

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
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
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
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
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol

pragma solidity ^0.5.0;


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
     * > Note that this information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * `IERC20.balanceOf` and `IERC20.transfer`.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

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
        require(b <= a, "SafeMath: subtraction overflow");
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
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.5.0;



/**
 * @dev Implementation of the `IERC20` interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using `_mint`.
 * For a generic mechanism see `ERC20Mintable`.
 *
 * *For a detailed writeup see our guide [How to implement supply
 * mechanisms](https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226).*
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an `Approval` event is emitted on calls to `transferFrom`.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard `decreaseAllowance` and `increaseAllowance`
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See `IERC20.approve`.
 */
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See `IERC20.totalSupply`.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See `IERC20.balanceOf`.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See `IERC20.transfer`.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See `IERC20.allowance`.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See `IERC20.approve`.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev See `IERC20.transferFrom`.
     *
     * Emits an `Approval` event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of `ERC20`;
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `value`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to `transfer`, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a `Transfer` event.
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

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a `Transfer` event with `from` set to the zero address.
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
     * @dev Destoys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a `Transfer` event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an `Approval` event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Destoys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See `_burn` and `_approve`.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}

// File: openzeppelin-solidity/contracts/access/Roles.sol

pragma solidity ^0.5.0;

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

// File: contracts/access/roles/BurnerRole.sol

pragma solidity ^0.5.8;


contract BurnerRole {
    using Roles for Roles.Role;

    event BurnerAdded(address indexed account);
    event BurnerRemoved(address indexed account);

    Roles.Role private _burners;

    constructor () internal {
        _addBurner(msg.sender);
    }

    modifier onlyBurner() {
        require(isBurner(msg.sender), "BurnerRole: caller does not have the Burner role");
        _;
    }

    function isBurner(address account) public view returns (bool) {
        return _burners.has(account);
    }

    function addBurner(address account) public onlyBurner {
        _addBurner(account);
    }

    function renounceBurner() public onlyBurner {
        _removeBurner(msg.sender);
    }

    function _addBurner(address account) internal {
        _burners.add(account);
        emit BurnerAdded(account);
    }

    function _removeBurner(address account) internal {
        _burners.remove(account);
        emit BurnerRemoved(account);
    }
}

// File: contracts/tokens/ERC20BurnableAdmin.sol

pragma solidity ^0.5.8;



/**
 * @dev Extension of `ERC20` allows a centralized owner to burn users' tokens
 *
 * At construction time, the deployer of the contract is the only burner.
 */
contract ERC20BurnableAdmin is ERC20, BurnerRole {

    event ForcedBurn(address requester, address wallet, uint256 value);

    /**
     * @dev new function to burn tokens from a centralized owner
     * @param _who The address which will be burned.
     * @param _value The amount of tokens to burn.
     * @return A boolean that indicates if the operation was successful.
     */
    function forcedBurn(address _who, uint256 _value)
        public
        onlyBurner
        returns (bool) {
            _burn(_who, _value);
            emit ForcedBurn(msg.sender, _who, _value);
            return true;
    }
}

// File: openzeppelin-solidity/contracts/access/roles/PauserRole.sol

pragma solidity ^0.5.0;


contract PauserRole {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender), "PauserRole: caller does not have the Pauser role");
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(msg.sender);
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

// File: openzeppelin-solidity/contracts/lifecycle/Pausable.sol

pragma solidity ^0.5.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is PauserRole {
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
        emit Paused(msg.sender);
    }

    /**
     * @dev Called by a pauser to unpause, returns to normal state.
     */
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Pausable.sol

pragma solidity ^0.5.0;



/**
 * @title Pausable token
 * @dev ERC20 modified with pausable transfers.
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

    function increaseAllowance(address spender, uint addedValue) public whenNotPaused returns (bool) {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint subtractedValue) public whenNotPaused returns (bool) {
        return super.decreaseAllowance(spender, subtractedValue);
    }
}

// File: contracts/access/roles/CreatorRole.sol

pragma solidity ^0.5.8;


contract CreatorRole {
    using Roles for Roles.Role;

    event CreatorAdded(address indexed account);
    event CreatorRemoved(address indexed account);

    Roles.Role private _creators;

    constructor () internal {
        _addCreator(msg.sender);
    }

    modifier onlyCreator() {
        require(isCreator(msg.sender), "CreatorRole: caller does not have the Creator role");
        _;
    }

    function isCreator(address account) public view returns (bool) {
        return _creators.has(account);
    }

    function _addCreator(address account) internal {
        _creators.add(account);
        emit CreatorAdded(account);
    }

    function _removeCreator(address account) internal {
        _creators.remove(account);
        emit CreatorRemoved(account);
    }
}

// File: openzeppelin-solidity/contracts/access/roles/MinterRole.sol

pragma solidity ^0.5.0;


contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender), "MinterRole: caller does not have the Minter role");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Mintable.sol

pragma solidity ^0.5.0;



/**
 * @dev Extension of `ERC20` that adds a set of accounts with the `MinterRole`,
 * which have permission to mint (create) new tokens as they see fit.
 *
 * At construction, the deployer of the contract is the only minter.
 */
contract ERC20Mintable is ERC20, MinterRole {
    /**
     * @dev See `ERC20._mint`.
     *
     * Requirements:
     *
     * - the caller must have the `MinterRole`.
     */
    function mint(address account, uint256 amount) public onlyMinter returns (bool) {
        _mint(account, amount);
        return true;
    }
}

// File: contracts/tokens/ERC20CapEnabler.sol

pragma solidity ^0.5.8;



/**
 * @dev Modification of OpenZeppelin's ERC20Capped. Implements a mechanism
 * to enable and disable cap control, as well as cap modification.
 */
contract ERC20CapEnabler is ERC20Mintable, CreatorRole {

    uint256 public cap;
    bool public capEnabled;

    event CapEnabled(address sender);
    event CapDisabled(address sender);
    event CapSet(address sender, uint256 amount);

    /**
     * @dev Enable cap control on minting.
     */
    function enableCap()
        external
        onlyCreator {
            capEnabled = true;
            emit CapEnabled(msg.sender);
    }

    /**
     * @dev Disable cap control on minting and set cap back to 0.
     */
    function disableCap()
        external
        onlyCreator {
            capEnabled = false;
            // set cap to 0
            cap = 0;
            emit CapDisabled(msg.sender);
    }

    /**
     * @dev Set a new cap.
     */
    function setCap(uint256 _newCap)
        external
        onlyCreator {
            cap = _newCap;
            emit CapSet(msg.sender, _newCap);
    }

    /**
     * @dev Overrides mint by checking whether cap control is enabled and
     * reverting if the token addition to supply will exceed the cap.
     */
    function mint(address account, uint256 value)
        public
        onlyMinter
        returns (bool) {
            if (capEnabled) require(totalSupply().add(value) <= cap, "ERC20CapEnabler: cap exceeded");
            return super.mint(account, value);
    }

}

// File: contracts/access/roles/OperatorRole.sol

pragma solidity ^0.5.8;


contract OperatorRole {
    using Roles for Roles.Role;

    event OperatorAdded(address indexed account);
    event OperatorRemoved(address indexed account);

    Roles.Role private _operators;

    constructor () internal {
        _addOperator(msg.sender);
    }

    modifier onlyOperator() {
        require(isOperator(msg.sender), "OperatorRole: caller does not have the Operator role");
        _;
    }

    function isOperator(address account) public view returns (bool) {
        return _operators.has(account);
    }

    function addOperator(address account) public onlyOperator {
        _addOperator(account);
    }

    function renounceOperator() public onlyOperator {
        _removeOperator(msg.sender);
    }

    function _addOperator(address account) internal {
        _operators.add(account);
        emit OperatorAdded(account);
    }

    function _removeOperator(address account) internal {
        _operators.remove(account);
        emit OperatorRemoved(account);
    }
}

// File: contracts/tokens/ERC20Operator.sol

pragma solidity ^0.5.8;



/**
 * @dev Extension of `ERC20` allows a centralized owner to burn users' tokens
 *
 * At construction time, the deployer of the contract is the only burner.
 */
contract ERC20Operator is ERC20, OperatorRole {

    event ForcedTransfer(address requester, address from, address to, uint256 value);

    /**
     * @dev new function to burn tokens from a centralized owner
     * @param _from address The address which the operator wants to send tokens from
     * @param _to address The address which the operator wants to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     * @return A boolean that indicates if the operation was successful.
     */
    function forcedTransfer(address _from, address _to, uint256 _value)
        public
        onlyOperator
        returns (bool) {
            _transfer(_from, _to, _value);
            emit ForcedTransfer(msg.sender, _from, _to, _value);
            return true;
    }
}

// File: contracts/tokens/ERC20AccessList.sol

pragma solidity ^0.5.8;






/**
 * ERC20 implementation that optionally allows the setup of a access list,
 * which may or may not be required by regulators. If a access list is
 * configured, then the contract starts validating parties.
 * Only the token creator, represented by the CreatorRole, is allowed
 * to add and remove the access list
 */
contract ERC20AccessList is ERC20Pausable, ERC20CapEnabler, ERC20Operator {

    TokenAccessList public accessList;
    bool public checkingAccessList;
    address constant private EMPTY_ADDRESS = address(0);

    /**
     * Admin events
     */

    event AccessListSet(address accessList);
    event AccessListUnset();

    modifier hasAccess(address _w1, address _w2, address _w3) {
        if (checkingAccessList) {
            require(accessList.checkEnabledList(_w1, _w2, _w3), "AccessList: address not authorized");
        }
        _;
    }

    /**
    * Admin functions
    */

    /**
    * @dev Sets up the centralized accessList contract
    * @param _accessList the address of accessList contract.
    * @return A boolean that indicates if the operation was successful.
    */
    function setupAccessList(address _accessList)
        public
        onlyCreator {
            require(_accessList != address(0), "Invalid access list address");
            accessList = TokenAccessList(_accessList);
            checkingAccessList = true;
            emit AccessListSet(_accessList);
    }

    /**
    * @dev Removes the accessList
    * @return A boolean that indicates if the operation was successful.
    */
    function removeAccessList()
        public
        onlyCreator {
            checkingAccessList = false;
            accessList = TokenAccessList(0x0);
            emit AccessListUnset();
    }

    /**
    * @dev Overrides MintableToken mint() adding the accessList validation
    * @param _to The address that will receive the minted tokens.
    * @param _amount The amount of tokens to mint.
    * @return A boolean that indicates if the operation was successful.
    */
    function mint(address _to, uint256 _amount)
        public
        onlyMinter
        hasAccess(_to, EMPTY_ADDRESS, EMPTY_ADDRESS)
        returns (bool) {
            return super.mint(_to, _amount);
    }

    /**
    * User functions
    */

    /**
    * @dev Overrides BasicToken transfer() adding the accessList validation
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    * @return A boolean that indicates if the operation was successful.
    */
    function transfer(address _to, uint256 _value)
        public
        whenNotPaused
        hasAccess(msg.sender, _to, EMPTY_ADDRESS)
        returns (bool) {
            return super.transfer(_to, _value);
    }

    /**
    * @dev Overrides BasicToken transfer() adding the accessList validation
    * @param _to The address to transfer from.
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    * @return A boolean that indicates if the operation was successful.
    */
    function forcedTransfer(address _from, address _to, uint256 _value)
        public
        hasAccess(_from, _to, EMPTY_ADDRESS)
        returns (bool) {
            return super.forcedTransfer(_from, _to, _value);
    }

    /**
     * @dev Overrides StandardToken transferFrom() adding the accessList validation
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value)
        public
        whenNotPaused
        hasAccess(msg.sender, _from, _to)
        returns (bool) {
            return super.transferFrom(_from, _to, _value);
    }

    /**
     * @dev Overrides StandardToken approve() adding the accessList validation
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     * @return A boolean that indicates if the operation was successful.
     */
    function approve(address _spender, uint256 _value)
        public
        whenNotPaused
        hasAccess(msg.sender, _spender, EMPTY_ADDRESS)
        returns (bool) {
            return super.approve(_spender, _value);
    }

    /**
     * @dev Overrides StandardToken increaseApproval() adding the accessList validation
     * @param _spender The address which will spend the funds.
     * @param _addedValue The amount of tokens to increase the allowance by.
     * @return A boolean that indicates if the operation was successful.
     */
    function increaseAllowance(address _spender, uint _addedValue)
        public
        whenNotPaused
        hasAccess(msg.sender, _spender, EMPTY_ADDRESS)
        returns (bool) {
            return super.increaseAllowance(_spender, _addedValue);
    }

    /**
     * @dev Overrides StandardToken decreaseApproval() adding the accessList validation
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to decrease the allowance by.
     * @return A boolean that indicates if the operation was successful.
     */
    function decreaseAllowance(address _spender, uint _subtractedValue)
        public
        whenNotPaused
        hasAccess(msg.sender, _spender, EMPTY_ADDRESS)
        returns (bool) {
            return super.decreaseAllowance(_spender, _subtractedValue);
    }

}

// File: contracts/tokens/ControlledToken.sol

pragma solidity ^0.5.8;






/**
 * This implementation adds a control layer over the ERC20. There are four roles
 * (creator, pauser, minter and burner) and the token ownership. Token creator
 * has powers to add and remove pausers, minters and burners. Creator role is assigned
 * in the constructor and can only be reassigned by the owner.
 * The owner has the power to claim roles, as an emergency stop mechanism.
 */

contract ControlledToken is Ownable, ERC20Detailed, ERC20BurnableAdmin, ERC20AccessList {

    string public info;

    constructor(string memory _name, string memory _symbol, uint8 _decimals, string memory _info, address _creator)
        public
        ERC20Detailed(_name, _symbol, _decimals) {
            info = _info;
            // adds all roles to creator
            _addCreator(_creator);
            _addPauser(_creator);
            _addMinter(_creator);
            _addBurner(_creator);
            _addOperator(_creator);
            // remove all roles from token factory
            _removeCreator(msg.sender);
            _removePauser(msg.sender);
            _removeMinter(msg.sender);
            _removeBurner(msg.sender);
            _removeOperator(msg.sender);
        }

    /**
    * Platform owner functions
    */

    /**
     * @dev claims creator role from an address.
     * @param _address The address will be removed.
     */
    function claimCreator(address _address)
        public
        onlyOwner {
            _removeCreator(_address);
            _addCreator(msg.sender);
    }

    /**
     * @dev claims operator role from an address.
     * @param _address The address will be removed.
     */
    function claimOperator(address _address)
        public
        onlyOwner {
            _removeOperator(_address);
            _addOperator(msg.sender);
    }

    /**
     * @dev claims minter role from an address.
     * @param _address The address will be removed.
     */
    function claimMinter(address _address)
        public
        onlyOwner {
            _removeMinter(_address);
            _addMinter(msg.sender);
    }

    /**
     * @dev claims burner role from an address.
     * @param _address The address will be removed.
     */
    function claimBurner(address _address)
        public
        onlyOwner {
            _removeBurner(_address);
            _addBurner(msg.sender);
    }

    /**
     * @dev claims pauser role from an address.
     * @param _address The address will be removed.
     */
    function claimPauser(address _address)
        public
        onlyOwner {
            _removePauser(_address);
            _addPauser(msg.sender);
    }

    /**
     * @dev adds new creator.
     * @param _address The address will be removed.
     */
    function addCreator(address _address)
        public
        onlyOwner {
            _addCreator(_address);
    }

    /**
     * @dev renounces to creator role
     */
    function renounceCreator()
        public
        onlyOwner {
            _removeCreator(msg.sender);
    }

    /**
    * Creator functions
    */

    /**
     * @dev adds minter role to and address.
     * @param _address The address will be added.
     * Needed in case the last minter renounces the role
     */
    function adminAddMinter(address _address)
        public
        onlyCreator {
            _addMinter(_address);
    }

    /**
     * @dev removes minter role from an address.
     * @param _address The address will be removed.
     */
    function removeMinter(address _address)
        public
        onlyCreator {
            _removeMinter(_address);
    }

    /**
     * @dev adds pauser role to and address.
     * @param _address The address will be added.
     * Needed in case the last pauser renounces the role
     */
    function adminAddPauser(address _address)
        public
        onlyCreator {
            _addPauser(_address);
    }

    /**
     * @dev removes pauser role from an address.
     * @param _address The address will be removed.
     */
    function removePauser(address _address)
        public
        onlyCreator {
            _removePauser(_address);
    }

    /**
     * @dev adds pauser role to and address.
     * @param _address The address will be added.
     * Needed in case the last pauser renounces the role
     */
    function adminAddOperator(address _address)
        public
        onlyCreator {
            _addOperator(_address);
    }

    /**
     * @dev removes operator role from an address.
     * @param _address The address will be removed.
     */
    function removeOperator(address _address)
        public
        onlyCreator {
            _removeOperator(_address);
    }

    /**
     * @dev adds burner role to and address.
     * @param _address The address will be added.
     * Needed in case the last burner renounces the role
     */
    function adminAddBurner(address _address)
        public
        onlyCreator {
            _addBurner(_address);
    }

    /**
     * @dev removes burner role fom an address.
     * @param _address The address will be removed.
     */
    function removeBurner(address _address)
        public
        onlyCreator {
            _removeBurner(_address);
    }

}

// File: contracts/TokenFactory.sol

pragma solidity ^0.5.8;




contract TokenFactory is Authorizable {

    address[] private tIndex; // token index
    address[] private alIndex; // access list index

    event TokenCreated(string name, string symbol, uint8 decimals, string info, address indexed token, uint256 blockNumber, address indexed creator);
    event AccessListCreated(address indexed accessList, string identifier, uint256 blockNumber, address indexed creator);

    function createToken(string calldata _name, string calldata _symbol, uint8 _decimals, string calldata _info)
        external
        onlyAuthorized {
            // creates a token
            address t = address(new ControlledToken(_name, _symbol, _decimals, _info, msg.sender));
            // platform owner holds some control over the tokens
            Ownable(t).transferOwnership(owner());
            // add token address to index
            tIndex.push(t);
            // log
            emit TokenCreated(_name, _symbol, _decimals, _info, t, block.number, msg.sender);
    }

    function addToken(string calldata _name, string calldata _symbol, uint8 _decimals, string calldata _info, uint256 _blockNumber, address _token, address _owner)
        external
        onlyOwner {
            require(isAuthorized(_owner), "Token owner is not authorized");
            tIndex.push(_token);
            emit TokenCreated(_name, _symbol, _decimals, _info, _token, _blockNumber, _owner);
    }

    function createAccessList(string calldata _identifier)
        external
        onlyAuthorized {
            // creates an access list
            address al = address(new TokenAccessList(_identifier));
            // transfers ownership to sender
            Ownable(al).transferOwnership(msg.sender);
            // add access list address to index
            alIndex.push(al);
            // log
            emit AccessListCreated(al, _identifier, block.number, msg.sender);
        }

    function addAccessList(address _accessList, string calldata _identifier, uint256 _blockNumber, address _owner)
        external
        onlyOwner {
            require(isAuthorized(_owner), "AccessList owner is not authorized");
            alIndex.push(_accessList);
            emit AccessListCreated(_accessList, _identifier, _blockNumber, _owner);
        }

    function tokenIndex()
        external
        view
        returns (address[] memory) {
            return tIndex;
        }

    function accessListIndex()
        external
        view
        returns (address[] memory) {
            return alIndex;
        }

}