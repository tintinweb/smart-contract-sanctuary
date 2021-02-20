/**
 *Submitted for verification at Etherscan.io on 2021-02-19
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.6.0;

/*
 * Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.6.0;

/**
 * Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * Sets `amount` as the allowance of `spender` over the caller's tokens.
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
     * Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.6.0;

/**
 * Wrappers over Solidity's arithmetic operations with added overflow
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
     * Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
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
     * Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.6.0;

/**
 * Implementation of the {IERC20} interface.
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
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    address public claimerAddress = address(0);

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    
    event ClaimerChanged(address indexed claimer);

    /**
     * Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * See {IERC20-transfer}.
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
     * See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * See {IERC20-approve}.
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
     * See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * Atomically increases the allowance granted to `spender` by the caller.
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * Atomically decreases the allowance granted to `spender` by the caller.
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * Moves tokens `amount` from `sender` to `recipient`.
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

        amount = _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    
    function _setClaimer(address newClaimer) internal virtual {
        require(newClaimer != address(0), "Claimer address must be set to something");
        claimerAddress = newClaimer;
        emit ClaimerChanged(claimerAddress);
    }

    /**
     * Tax `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _tax(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: tax from the zero address");
        require(claimerAddress != address(0), "Claimer address must be set to something");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _balances[claimerAddress] = _balances[claimerAddress].add(amount);
        emit Transfer(account, claimerAddress, amount);
    }

    /**
     * Sets `amount` as the allowance of `spender` over the `owner`s tokens.
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * Hook that is called before any transfer of tokens.
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual returns (uint256) { }
}

// File: @openzeppelin/contracts/access/Ownable.sol

pragma solidity ^0.6.0;

/**
 * Contract module which provides a basic access control mechanism, where
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
contract Ownable is Context {
    address private _owner;

    event GovernanceTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit GovernanceTransferred(address(0), msgSender);
    }

    /**
     * Returns the address of the current owner.
     */
    function governance() public view returns (address) {
        return _owner;
    }

    /**
     * Throws if called by any account other than the owner.
     */
    modifier onlyGovernance() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function _transferGovernance(address newOwner) internal virtual onlyGovernance {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit GovernanceTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/StabinolToken.sol

pragma solidity =0.6.6;

// Stabilize Token with Governance.
contract StabinolToken is ERC20("Stabinol Token", "STOL"), Ownable {
    using SafeMath for uint256;

    // Variables
    uint256 constant DIVISION_FACTOR = 100000;
    uint256 constant TAX_EFFECTIVE = 500000e18; // The threshold at which the tax kicks in
    uint256 private effectiveMaxSupply = 1000000e18; // The default max supply of tokens
    uint256 public taxRate = 0; // Governance can update the tax rate as it gets closer to the max supply
    
    mapping (address => bool) public taxExemptAccounts; // Addresses that will not have a sender tax
    
    constructor() public {
        // We will mint 350,000 tokens to the deployer to use for the merkle airdrop, team and liquidity
        _mint(_msgSender(), 350000e18);
    }

    modifier onlyClaimer() {
        require(claimerAddress == _msgSender(), "Ownable: caller is not the claimer");
        _;
    }

    function getMaxSupply() external view returns (uint256) {
        return effectiveMaxSupply;
    }
    
    /// @notice Creates `_amount` token to `_to`. Must only be called by the claimer.
    function mint(address _to, uint256 _amount) external onlyClaimer returns (bool) {
        _mint(_to, _amount);
        require(totalSupply() <= effectiveMaxSupply, "Cannot mint any more tokens"); // After max supply is reached, claimer cannot claim anymore
        return true;
    }

    // This function will tax each non-exempt address the transfer fee
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override returns (uint256) {
        super._beforeTokenTransfer(from, to, amount); // Call parent hook
        if(taxExemptAccounts[from] == true){ return amount; } // No fee for certain accounts
        if(taxRate > 0 && totalSupply() > TAX_EFFECTIVE){
            // Tax is taken from sender balance. If sender balance not enough to cover transfer, tax taken from transferred amount
            // For contracts to calculate ideal fee when sending this token, use this equation: taxRate / (1 + taxRate) = withdrawFeeRate
            uint256 taxAmount = amount.mul(taxRate).div(DIVISION_FACTOR);
            if(taxAmount.add(amount) > balanceOf(from)){
                uint256 overage = taxAmount.add(amount).sub(balanceOf(from)); // The overage for the fee
                amount = amount.sub(overage);
            }
            _tax(from,taxAmount);
        }
        return amount;
    }
    
    // Now add some governance functions behind 24 hour timelock
    
    // Timelock variables
    // Timelock doesn't activate until claimer is set to a non-zero account
    
    uint256 private _timelockStart; // The start of the timelock to change governance variables
    uint256 private _timelockType; // The function that needs to be changed
    uint256 constant TIMELOCK_DURATION = 86400; // Timelock is 24 hours
    
    // Reusable timelock variables
    uint256 private _timelock_data;
    address private _timelock_address;
    
    modifier timelockConditionsMet(uint256 _type) {
        require(_timelockType == _type, "Timelock not acquired for this function");
        _timelockType = 0; // Reset the type once the timelock is used
        if(claimerAddress != address(0)){
            require(now >= _timelockStart + TIMELOCK_DURATION, "Timelock time not met");
        }
        _;
    }
    
    // Change the governance
    // --------------------
    function startChangeGovernance(address _address) external onlyGovernance {
        _timelockStart = now;
        _timelockType = 1;
        _timelock_address = _address;       
    }
    
    function finishChangeGovernance() external onlyGovernance timelockConditionsMet(1) {
        _transferGovernance(_timelock_address);
    }
    // --------------------
    
    // Used to change tax rate
    // --------------------
    function startChangeTaxRate(uint256 _percent) external onlyGovernance {
        _timelockStart = now;
        _timelockType = 2;
        _timelock_data = _percent;
    }
    
    function finishChangeTaxRate() external onlyGovernance timelockConditionsMet(2) {
        taxRate = _timelock_data;
    }
    // --------------------
    
    // Change the claimer address
    // --------------------
    function startChangeClaimer(address _address) external onlyGovernance {
        _timelockStart = now;
        _timelockType = 3;
        _timelock_address = _address;       
    }
    
    function finishChangeClaimer() external onlyGovernance timelockConditionsMet(3) {
        taxExemptAccounts[_timelock_address] = true;
        _setClaimer(_timelock_address);
    }
    // --------------------
    
    // Toggle whether an account is tax exempt or not
    // --------------------
    function startToggleTaxExempt(address _address) external onlyGovernance {
        _timelockStart = now;
        _timelockType = 4;
        _timelock_address = _address;       
    }
    
    function finishToggleTaxExempt() external onlyGovernance timelockConditionsMet(4) {
        if(taxExemptAccounts[_timelock_address] == true){
            taxExemptAccounts[_timelock_address] = false;
        }else{
            taxExemptAccounts[_timelock_address] = true;
        }
    }
    // --------------------
    
    // Used to change the effective max supply
    // --------------------
    function startChangeEffectiveSupply(uint256 _supply) external onlyGovernance {
        _timelockStart = now;
        _timelockType = 5;
        _timelock_data = _supply;
    }
    
    function finishChangeEffectiveSupply() external onlyGovernance timelockConditionsMet(5) {
        effectiveMaxSupply = _timelock_data;
    }
    // --------------------
}