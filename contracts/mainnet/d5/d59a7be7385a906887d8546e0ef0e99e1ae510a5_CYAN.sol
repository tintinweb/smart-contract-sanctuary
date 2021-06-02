/**
 *Submitted for verification at Etherscan.io on 2021-06-01
*/

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
    mapping (address => uint256) public _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 public _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
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
        return 12;
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
     * - `account` cannot be the zero address.
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


abstract contract GlobalsAndUtility is ERC20 {

    uint32 public constant minBurnAmount = 5000000;
    uint256 public constant INTEREST_INTERVAL = 7 days;
    uint256 public constant INTEREST_MULTIPLIER = 1612;
    uint256 public constant MINIMUM_INTEREST_DENOMINATOR = 1612;
    uint256 public constant BURN_TIME_UNIT = 1 days;
    uint256 public constant CYANIDE_PER_CYAN = 1000000000000; // 1 CYAN = 1e12 CYANIDE

}


contract CYAN is GlobalsAndUtility {

    address private FLUSH_ADDR; //Address that ETH/CYN is flushed to
    uint256 public _totalBurntSupply = 0; //The total amount of CYAN burnt by everyone
    uint256 public deployBlockTimestamp; //Unix time of when the contract was deployed
    uint256 public deployBlockInterval; // deployBlockTimestamp / INTEREST_INTERVAL
    uint256 public currentInterestDenominator; //The reciprocal of the current interval interest rate
    uint256 public burnStartDay; //The first day of the first interest interval.

    //Information stored for each address
    mapping (address => uint256) public _burntBalances;
    mapping (address => uint256) public _unclaimedBalances;
    mapping (address => uint256) public _timeOfLastBurnChange;

    //Stores supply information for given interest intervals
    mapping (uint256 => uint256) public intervalsTotalSupply;
    mapping (uint256 => uint256) public intervalsTotalBurntSupply;

    event BurntCyan(address burner, uint256 amount);
    event ClaimedInterest(address claimer, uint256 amount);
    event CheckedUnclaimedBalance(address checker, address checked);
    event FlushedCYN(uint amount);
    event FlushedETH(uint amount);

    //Function that is only called once when the contract is deployed
    constructor(uint256 initialSupply, uint256 _burnStartDay) ERC20("CYAN", "CYN") {

        _mint(msg.sender, initialSupply); //ERC20 initialization function

        deployBlockTimestamp = block.timestamp;
        deployBlockInterval = block.timestamp / (INTEREST_INTERVAL);
        burnStartDay = _burnStartDay;

        FLUSH_ADDR = msg.sender; //Set ETH flush address to contract deployer

    }

    //Get how much CYAN a certain address has burnt
    function burntBalanceOf(address account) public view returns (uint256) {
        return _burntBalances[account];
    }

    //Get the unclaimed balance of a certain address. Requires gas.
    //There are only minor differences between calling this function and "updateUnclaimedBalance()"
    //Differences: This function check if current time is pre burn period. This function also called the CheckUnclaimedBalance event.
    function unclaimedBalanceOf(address account) public returns (uint256) {

        //Return 0 if burn start time is still in the future
        if ((block.timestamp / (BURN_TIME_UNIT)) < burnStartDay) {
            return 0;
        }
        else {

            updateUnclaimedBalance(account);
            CheckedUnclaimedBalance(msg.sender, account);
            return _unclaimedBalances[account];

        }

    }

    //Probably the most complicated function in the CYAN contract
    //Updates the unclaimed balance of a given address/user
    function updateUnclaimedBalance(address account) internal {

        uint256 currentTime = (block.timestamp / (INTEREST_INTERVAL)); //Get current interval

        updateIntervals(currentTime); //Update interval data

        //Initialize some loop variables
        uint256 amountToAddToBalance = 0; //Interest from all intervals combined
        uint256 lastAmount = 0; //Keeps track of how much was added for last interval's calculation

        //Set time of last burn change to now if it is not already set
        if (_timeOfLastBurnChange[account] == 0) {
            _timeOfLastBurnChange[account] = block.timestamp / (INTEREST_INTERVAL);
        }

        if (currentTime - _timeOfLastBurnChange[account] > 0) { // Checks if it has been 1 or more intervals since last unclaimed balance update

            for (uint256 i = _timeOfLastBurnChange[account]; i < currentTime; i++) { //Runs 1 iteration for every interval since last unclaimed balance update

                if (intervalsTotalBurntSupply[i] > 0) { //Checks if anybody burnt or claimed CYAN during interval "i"

                    if (intervalsTotalSupply[i] > 0) {

                        uint256 thisIntervalDenominator =  (INTEREST_MULTIPLIER * intervalsTotalBurntSupply[i]) / intervalsTotalSupply[i]; //Get the reciprocal of interval "i" interest rate. This uses the weekly interest equation seen in the green paper and blue paper.

                        if (thisIntervalDenominator < 1) {

                            lastAmount = _burntBalances[account]; //Maximum weekly interest is 100%;
                            amountToAddToBalance += lastAmount;

                        }

                        else if (thisIntervalDenominator < MINIMUM_INTEREST_DENOMINATOR) { //Check if current equation interest is greater than minimum interest.

                            lastAmount = _burntBalances[account] / thisIntervalDenominator; //Divide by reciprocal is same as multiplying by interest rate
                            amountToAddToBalance += lastAmount;

                            continue;

                        }

                        //Use minimum interest if equation interest is less.
                        else {

                            lastAmount = _burntBalances[account] / MINIMUM_INTEREST_DENOMINATOR;
                            amountToAddToBalance += lastAmount;

                            continue;

                        }

                    }

                    else {

                        //Use minimum interest if equation interest is less.
                        lastAmount = _burntBalances[account] / MINIMUM_INTEREST_DENOMINATOR;
                        amountToAddToBalance += lastAmount;

                        continue;

                    }

                }

                else { //If nobody burnt or claimed any CYAN during interval "i", the ratio will be the same as interval "i" - 1, so we can just add lastAmount to amountToAddToBalance

                    amountToAddToBalance += lastAmount;

                    //Since none was burnt or claimed, total supplies are same as last interval
                    intervalsTotalSupply[i] = intervalsTotalSupply[i - 1];
                    intervalsTotalBurntSupply[i] = intervalsTotalBurntSupply[i - 1];

                    continue;

                }

            }

        }

        _unclaimedBalances[account] += amountToAddToBalance; //Update the uncaimed balance
        _timeOfLastBurnChange[account] = currentTime; //Change the last update time

    }

    //Second most complicated function
    //Allows user to burn cyan
    function burnCyan(uint256 amount) public {

        require ((block.timestamp / (BURN_TIME_UNIT)) >= burnStartDay, "Cyan can not be burned yet. Try again on or after the burn start day."); //Check that current time is not before the burn start time.
        require (amount >= minBurnAmount, "You have not entered an amount greater than or equal to the minimum."); //Check if user is trying to burn at least the minimum burn amount.
        require (_balances[msg.sender] >= amount, "You have attempted to burn more CYAN than you own."); //Check if user has enough CYAN to burn.

        //Set time of last burn change to now if it is not already set
        if (_timeOfLastBurnChange[msg.sender] == 0) {
            _timeOfLastBurnChange[msg.sender] = block.timestamp / (INTEREST_INTERVAL);
        }

        //Update balances
        _balances[msg.sender] -= amount;
        updateUnclaimedBalance(msg.sender);
        _burntBalances[msg.sender] += amount;

        //Update total supplies
        _totalSupply -= amount;
        _totalBurntSupply += amount;
        updateIntervals(block.timestamp / (INTEREST_INTERVAL)); //Update supplies for this interval

        BurntCyan(msg.sender, amount); //Call burnt cyan event

    }

    //Allows user to add their unclaimed balance to their balance.
    function claimInterest() public returns (uint256) {

        require ((block.timestamp / (BURN_TIME_UNIT)) > burnStartDay, "It is before the burn start time"); //Make sure burning has started.
        require (_burntBalances[msg.sender] > 0, "You have no burnt CYAN."); //Only let them claim if they have burnt CYAN.

        updateUnclaimedBalance(msg.sender); //Update the unclaimed balance
        _balances[msg.sender] += _unclaimedBalances[msg.sender]; //Add unclaimed CYAN to balance
        _totalSupply += _unclaimedBalances[msg.sender]; //Update total supply
        intervalsTotalSupply[(block.timestamp - deployBlockTimestamp) / (INTEREST_INTERVAL)] += _unclaimedBalances[msg.sender]; //Update total supply without updating burnt supply

        ClaimedInterest(msg.sender, _unclaimedBalances[msg.sender]);

        uint256 amountClaimed = _unclaimedBalances[msg.sender];
        _unclaimedBalances[msg.sender] = 0; //Reset unclaimed balance

        return amountClaimed;

    }

    //Sets total supplies of given interval to current total supplies
    function updateIntervals(uint256 interval) internal {

        intervalsTotalSupply[interval] = _totalSupply;
        intervalsTotalBurntSupply[interval] = _totalBurntSupply;

        updateCurrentInterestDenominator();

    }

    //Updates the vallu of currentInterestDenominator
    function updateCurrentInterestDenominator() internal {

        uint256 timeNow = block.timestamp / (INTEREST_INTERVAL); //Use some memory so division doesn't need to happen twice.
        uint256 currentInterestEquation = (INTEREST_MULTIPLIER * intervalsTotalBurntSupply[timeNow]) / intervalsTotalSupply[timeNow];

        if (currentInterestEquation < 1) {
            currentInterestDenominator = 1;
        }
        else {
            currentInterestDenominator = currentInterestEquation;
        }

    }

    //Send ETH that is trapped in the contract to the flush address
    function flushETH() external {

        require(address(this).balance != 0, "Currently no ETH in CYAN.");

        uint256 bal = address(this).balance;
        payable(FLUSH_ADDR).transfer(bal);

        FlushedETH(bal);

    }

    //Send CYN that is trapped in the contract to the flush address
    function flushCYN() public {

        FlushedCYN(balanceOf(address(this)));
        _transfer(address(this), FLUSH_ADDR, balanceOf(address(this)));

    }

    //Backup functions
    receive() external payable {}
    fallback() external payable {}

}