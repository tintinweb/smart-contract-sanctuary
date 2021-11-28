/**
 *Submitted for verification at Etherscan.io on 2021-11-27
*/

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts v4.4.0 (security/Pausable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC20/ERC20.sol)

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

// File: contracts/rainbows.sol



pragma solidity ^0.8.0;






interface InterfaceNoundles {

    function noundleBalance(address owner) external view returns(uint256);

}



interface InterfaceEvilNoundles {

    function companionBalance(address owner) external view returns(uint256);

    function getEvilNoundleOwners() external view returns (address[] memory);



    function lowLandBalance(address owner) external view returns(uint256);

    function midLandBalance(address owner) external view returns(uint256);

    function highLandBalance(address owner) external view returns(uint256);

}



contract Rainbows is ERC20, Ownable, Pausable {



    InterfaceNoundles public Noundles;

    InterfaceEvilNoundles public EvilNoundles;



    // The starting block.

    uint256 public startBlock;

    uint256 public startBlockCompanion;



    // The maximum that can ever be minted.

    uint256 public maximumSupply     = 33333333 ether;



    // Noundle holders: The interval that the user is paid out.

    uint256 public interval          = 86400;

    uint256 public rate              = 4 ether;

    uint256 public companionInterval = 86400;

    uint256 public companionRate     = 2 ether;



    // Land protection

    uint256 public landPertectionRateLow  = 2;

    uint256 public landPertectionRateMid  = 5;

    uint256 public landPertectionRateHigh = 10;



    // Steal Amount.

    bool public stealingEnabled      = false;

    uint256 public stealPercentage   = 20;



    // The rewards for the user (OG).

    mapping(address => uint256) public rewards;

    mapping(address => uint256) public companionRewards;

    mapping(address => uint256) public evilRewards;



    // The last time they were paid out.

    mapping(address => uint256) public lastUpdate;

    mapping(address => uint256) public lastUpdateCompanion;



    // Extended access

    mapping(address => bool) public extendedAccess;



    // Only allow the contract to interact with it.

    modifier onlyFromNoundles() {

        require(msg.sender == address(Noundles));

        _;

    }

    modifier onlyFromEvilNoundles() {

        require(msg.sender == address(EvilNoundles));

        _;

    }

    modifier onlyFromRestricted() {

        require(extendedAccess[msg.sender], "Your address does not have permission to use.");

        _;

    }



    constructor(address noundlesAddress, address evilNoundlesAddress) ERC20("NoundlesRainbows", "Rainbows") {



        // Set the address to interfaces.

        Noundles     = InterfaceNoundles(noundlesAddress);

        EvilNoundles = InterfaceEvilNoundles(evilNoundlesAddress);



        // Set the starting block.

        startBlock = block.timestamp;

        startBlockCompanion = block.timestamp;



        // Pause the system so no one can interact with it.

        _pause();

    }



    /*

        Admin Utility.

    */



    // Pause it.

    function pause() public onlyOwner { _pause(); }



    // Unpause it.

    function unpause() public onlyOwner { _unpause(); }



    // Set the start block.

    function setStartBlock(uint256 arg) public onlyOwner {

        if(arg == 0){

            startBlock = block.timestamp;

        }else{

            startBlock = arg;

        }

    }

    // Set the start block for companions.

    function setStartBlockCompanion(uint256 arg) public onlyOwner {

        if(arg == 0){

            startBlockCompanion = block.timestamp;

        }else{

            startBlockCompanion = arg;

        }

    }

    // Set the status of stealing.

    function setStealingStatus(bool arg) public onlyOwner {

        stealingEnabled = arg;

    }



    // Set the start block.

    function setIntervalAndRate(uint256 _interval, uint256 _rate) public onlyOwner {

        interval = _interval;

        rate = _rate;

    }



    // Set the steal rate.

    function setStealPercentage(uint256 _arg) public onlyOwner { stealPercentage = _arg; }



    // Set the land protection rate.

    function setLandProtectionRates(uint256 _low, uint256 _mid, uint256 _high) public onlyOwner {

        landPertectionRateLow  = _low;

        landPertectionRateMid  = _mid;

        landPertectionRateHigh = _high;

    }



    // Set the start block.

    function setCompanionIntervalAndRate(uint256 _interval, uint256 _rate) public onlyOwner {

        companionInterval = _interval;

        companionRate = _rate;

    }



    // Set the address for the contract.

    function setNoundlesContractAddress(address _noundles) public onlyOwner {

        Noundles = InterfaceNoundles(_noundles);

    }



    // Set the address for the evil noundles contract.

    function setEvilNoundlesContractAddress(address _noundles) public onlyOwner {

        EvilNoundles = InterfaceEvilNoundles(_noundles);

    }



    // Set the address for the contract.

    function setAddressAccess(address _noundles, bool _value) public onlyOwner {

        extendedAccess[_noundles] = _value;

    }



    // Get the access status for a address.

    function getAddressAccess(address user) external view returns(bool) {

        return extendedAccess[user];

    }



    // Burn the tokens required to evolve.

    function burnMultiple(address [] memory users, uint256 [] memory amount) external onlyFromRestricted {

        for(uint256 i = 0; i < users.length; i += 1){

            _burn(users[i], amount[i]);

        }

    }



    // Burn the tokens required to evolve.

    function burn(address user, uint256 amount) external onlyFromRestricted {

        _burn(user, amount);

    }



    // Mint some tokens for uniswap.

    function adminCreate(address [] memory users, uint256 [] memory amount) public onlyOwner {

        for(uint256 i = 0; i < users.length; i += 1){

            _mint(users[i], amount[i]);

        }

    }



    /*

        Helpers.

    */



    // The rewards to the user.

    function getTotalClaimable(address user) external view returns(uint256) {

        return rewards[user] + getPendingOGReward(user);

    }



    // The rewards to the user.

    function getTotalCompanionClaimable(address user) external view returns(uint256) {

        return companionRewards[user] + getPendingCompanionReward(user);

    }



    function getTotalStolenClaimable(address user) external view returns(uint256) {

        return evilRewards[user];

    }



    // The rewards to the user.

    function getLastUpdate(address user) external view returns(uint256) {

        return lastUpdate[user];

    }



    // The rewards to the user.

    function getLastUpdateCompanion(address user) external view returns(uint256) {

        return lastUpdateCompanion[user];

    }





    // Set the address for the contract.

    function setLastUpdate(address[] memory _noundles, uint256 [] memory values) public onlyOwner {

        for(uint256 i = 0; i < _noundles.length; i += 1){

            lastUpdate[_noundles[i]] = values[i];

        }

    }



     // Set the address for the contract.

    function setLastUpdateCompanion(address[] memory _noundles, uint256 [] memory values) public onlyOwner {

        for(uint256 i = 0; i < _noundles.length; i += 1){

            lastUpdateCompanion[_noundles[i]] = values[i];

        }

    }



    // Update the supply.

    function setMaximumSupply(uint256 _arg) public onlyOwner {

        maximumSupply = _arg;

    }



    /*

        User Utilities.

    */



    // Transfer the tokens (only accessable from the contract).

    function transferTokens(address _from, address _to) onlyFromNoundles whenNotPaused external {



        // Refactor this.

        if(_from != address(0)){

            rewards[_from]            += getPendingOGReward(_from);

            companionRewards[_from]   += getPendingCompanionReward(_from);

            lastUpdate[_from]          = block.timestamp;

            lastUpdateCompanion[_from] = block.timestamp;

        }



        if(_to != address(0)){

            rewards[_to]            += getPendingOGReward(_to);

            companionRewards[_to]   += getPendingCompanionReward(_to);

            lastUpdate[_to]          = block.timestamp;

            lastUpdateCompanion[_to] = block.timestamp;

        }

    }



    // Pay out the holder.

    function claimReward() external whenNotPaused {



        // Make a local copy of the rewards.

        uint256 _ogRewards   = rewards[msg.sender];

        uint256 _compRewards = companionRewards[msg.sender];

        uint256 _evilRewards = evilRewards[msg.sender];



        // Get the rewards.

        uint256 pendingOGRewards        = getPendingOGReward(msg.sender);

        uint256 pendingCompanionRewards = getPendingCompanionReward(msg.sender);



        // Reset the rewards.

        rewards[msg.sender]          = 0;

        companionRewards[msg.sender] = 0;

        evilRewards[msg.sender]      = 0;



        // Reset the block.

        lastUpdate[msg.sender]          = block.timestamp;

        lastUpdateCompanion[msg.sender] = block.timestamp;



        // Add up the totals.

        uint256 totalRewardsWithoutEvil = _ogRewards + _compRewards + pendingOGRewards + pendingCompanionRewards;



        // Block if we hit our limit.

        require(totalSupply() + totalRewardsWithoutEvil < maximumSupply, "No longer able to mint tokens.");



        // How much is one percent worth.

        uint256 percent = totalRewardsWithoutEvil / 100;



        // The calculated steal percentage.

        uint256 calculatedStealPercentage = stealPercentage;



        // If stealing is enabled.

        if(stealingEnabled){



            uint256 landProtection = 0;



            // Calculate how much the land protected.

            if(EvilNoundles.highLandBalance(msg.sender) > 0){

                landProtection = landPertectionRateHigh;

            }else if(EvilNoundles.midLandBalance(msg.sender) > 0){

                landProtection = landPertectionRateMid;

            }else if(EvilNoundles.lowLandBalance(msg.sender) > 0){

                landProtection = landPertectionRateLow;

            }



            if(landProtection < calculatedStealPercentage){

                calculatedStealPercentage -= landProtection;

            }else{

                calculatedStealPercentage = 0;

            }



            // Handle stealing.

            address[] memory evilNoundleLists = EvilNoundles.getEvilNoundleOwners();



            // Cut the total amount stolen into shares for each noundle.

            uint256 rewardPerEvilNoundle = (percent * calculatedStealPercentage) / evilNoundleLists.length;



            // Give each evil noundle holder a cut into their stolen.

            for(uint256 index; index < evilNoundleLists.length; index += 1){

                evilRewards[evilNoundleLists[index]] += rewardPerEvilNoundle;

            }

        }else{

            // If stealing isn't enabled, set it to 0.

            calculatedStealPercentage = 0;

        }



        // The final result after it was stolen from by those evil noundles :(

        uint256 totalRewards = (percent * (100 - calculatedStealPercentage)) + _evilRewards;



        // Mint the user their tokens.

        _mint(msg.sender, totalRewards);

    }



    // Get the total rewards.

    function getPendingOGReward(address user) internal view returns(uint256) {

        return Noundles.noundleBalance(user) * 

               rate *

               (block.timestamp - (lastUpdate[user] >= startBlock ? lastUpdate[user] : startBlock)) /

               interval;

    }



    // Get the total rewards.

    function getPendingCompanionReward(address user) internal view returns(uint256) {

        return EvilNoundles.companionBalance(user) *

               companionRate *

               (block.timestamp - (lastUpdateCompanion[user] >= startBlockCompanion ? lastUpdateCompanion[user] : startBlockCompanion)) /

               companionInterval;

    }

}