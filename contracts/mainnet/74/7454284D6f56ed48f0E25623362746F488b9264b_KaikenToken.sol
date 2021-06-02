/**
 *Submitted for verification at Etherscan.io on 2021-06-02
*/

// File: @openzeppelin/contracts/utils/math/SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol

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

// File: /verified-sources/0x5b982018545ff26f0cf2e3CdA8aeD859e3072e07/sources/github/kaikendev/kaikenCoin/contracts/mock/KaikenToken.sol

pragma solidity 0.8.4;



contract KaikenToken is ERC20 {
    using SafeMath for uint;

    // Addresses 
    address owner; // dev
    address private investors = 0x456ee95063e52359530b9702C9A3d1EEB46864A7;
    address private exchanges = 0xa611d21b868f2A1d9Cfb383152DC3483Ea15F81F;
    address private marketing = 0x085BA6bef0b3fEACf2D4Cb3Dba5CA11520E2AD01;
    address private reserve = 0xFe76451745386702e091113170b703096dC9E024;
    
    //structs 
    struct TaxRecord {
        uint timestamp;
        uint tax;
        uint balance;
    }
    
    struct GenesisRecord {
        uint timestamp;
        uint balance;
    }

    uint transferMode;
    uint[] startingTaxes = [
        5,
        8,
        10,
        15,
        20,
        25,
        30
    ];

     uint[] thresholds = [
        5,
        10,
        20,
        30,
        40,
        50
    ];

    // constants 
    uint private constant BPS = 100;
    uint private constant ONE_YEAR = 365;
    uint private constant TRANSFER = 0;
    uint private constant TRANSFER_FROM = 1;
    
    // constants for tokenomics (%)
    uint private OWNER = 20000000000;
    uint private RESERVE = 30000000000;
    uint private INVESTORS = 15000000000;
    uint private EXCHANGES = 20000000000;
    uint private MARKETING = 15000000000;

    // mappings
    mapping(address => bool) exempts;
    mapping(address => bool) totalExempts;
    mapping(address => TaxRecord[]) accountTaxMap;
    mapping(address => TaxRecord[]) sandboxAccountTaxMap;
    mapping(address => GenesisRecord) genesis;
    

    //modifiers
    modifier onlyOwner {
        require(msg.sender == owner, 'Only the owner can invoke this call.');
        _;
    }
    // events
    event AddedExempt(address exempted);
    event RemovedExempt(address exempted);
    event RemovedTotalExempt(address exempted);
    event UpdatedExempt(address exempted, bool isValid);
    event UpdatedTotalExempt(address exempted, bool isValid);
    event UpdatedReserve(address reserve);
    event TaxRecordSet(address _addr, uint timestamp, uint balance, uint tax);
    event UpdatedStartingTaxes(uint[] startingTaxes);
    event UpdatedThresholds(uint[] thresholds);
    event InitializedExempts(uint initialized);
    event InitializedTotalExempts(uint initialized);

    // sandbox events
    event SandboxTaxRecordSet(address addr, uint timestamp, uint balance, uint tax);

    constructor(
        string memory _name,
        string memory _symbol
    ) public ERC20(_name, _symbol) {
        owner = msg.sender;
        _mint(owner, OWNER * (10 ** uint256(decimals())));
        _mint(reserve, RESERVE * (10 ** uint256(decimals())));
        _mint(exchanges, EXCHANGES * (10 ** uint256(decimals())));
        _mint(investors, INVESTORS * (10 ** uint256(decimals())));
        _mint(marketing, MARKETING * (10 ** uint256(decimals())));
        
        _initializeExempts();
        _initializeTotalExempts();
    }

    // Overrides
    function transfer(
        address to,
        uint amount
    ) public virtual override returns (bool){
        transferMode = TRANSFER;
        return _internalTransfer(msg.sender, to, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint amount
    ) public virtual override returns (bool success) {
        transferMode = TRANSFER_FROM;
        return _internalTransfer(from, to, amount);
    }

    // Reads
    function getStartingTaxes() public view returns(uint[] memory) {
        return startingTaxes;
    }

    function getThresholds() public view returns(uint[] memory){
        return thresholds;
    }

    function getExempt(address _addr) public view returns(bool){
        return exempts[_addr];
    }

    function getTotalExempt(address _addr) public view returns(bool){
        return totalExempts[_addr];
    }
    
    function getTaxRecord(address _addr) public view returns(TaxRecord[] memory){
        return accountTaxMap[_addr];
    }
    
    function getGenesisRecord(address _addr) public view returns(GenesisRecord memory){
        return genesis[_addr];
    }

    function getReserve() public view returns(address) {
        return reserve;
    }

    // Writes
    function updateStartingTaxes(uint[] memory _startingTaxes) public onlyOwner {
        startingTaxes = _startingTaxes;
        emit UpdatedStartingTaxes(startingTaxes);
    }

    function updateThresholds(uint[] memory _thresholds) public onlyOwner {
        thresholds = _thresholds;
        emit UpdatedThresholds(thresholds);
    }

    function updateReserve(address _reserve) public onlyOwner {
        reserve = _reserve;
        emit UpdatedReserve(reserve);
    }

    function addExempt(address _exempted, bool totalExempt) public onlyOwner {
        require(_exempted != owner, 'Cannot tax exempt the owner');
        _addExempt(_exempted, totalExempt);
    }

    function updateExempt(address _exempted, bool isValid) public onlyOwner {
        require(_exempted != owner, 'Can not update Owners tax exempt status');
        exempts[_exempted] = isValid;
        emit UpdatedExempt(_exempted, isValid);
    }

    function updateTotalExempt(address _exempted, bool isValid) public onlyOwner {
        require(_exempted != owner, 'Can not update Owners tax exempt status');
        totalExempts[_exempted] = isValid;
        if(isValid) {
            exempts[_exempted] = false;
        }
        emit UpdatedTotalExempt(_exempted, isValid);
    }

    function removeExempt(address _exempted) public onlyOwner {
        require(exempts[_exempted], 'Exempt address is not existent'); 

        exempts[_exempted] = false;
        emit RemovedExempt(_exempted);
    }

    function removeTotalExempt(address _exempted) public onlyOwner {
        require(totalExempts[_exempted], 'Total Exempt address is not existent'); 

        totalExempts[_exempted] = false;
        emit RemovedTotalExempt(_exempted);
    }

    // internal functions
    function _addExempt(address _exempted, bool totalExempt) internal {
        require(!exempts[_exempted] || !totalExempts[_exempted], 'Exempt address already existent'); 

        if(totalExempt == false) {
            exempts[_exempted] = true;
        } else {
            totalExempts[_exempted] = true;
            exempts[_exempted] = false;
        }
        emit AddedExempt(_exempted);    
    }
    
    function _initializeExempts() internal {
        // initialize the following exempts: 
        // These accounts are exempted from taxation
        exempts[exchanges] = true;
        exempts[investors] = true;
        exempts[marketing] = true;
        exempts[0xf164fC0Ec4E93095b804a4795bBe1e041497b92a] = true; // UniswapV1Router01
        exempts[0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D] = true; // UniswapV2Router02
        exempts[0xE592427A0AEce92De3Edee1F18E0157C05861564] = true; // UniswapV3Router03
        exempts[0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F] = true; // Sushiswap: Router
        exempts[0xdb38ae75c5F44276803345f7F02e95A0aeEF5944] = true; // 1inch
        exempts[0xBA12222222228d8Ba445958a75a0704d566BF2C8] = true; // Balancer Vault

        emit InitializedExempts(1);
    } 

    function _initializeTotalExempts() internal {
        // initialize the following total exempts: 
        // These accounts are exempt the to and from accounts that 
        // interact with them. This is for certain exchanges that fail 
        // with any forms of taxation. 
        totalExempts[reserve] = true;
        totalExempts[0xCCE8D59AFFdd93be338FC77FA0A298C2CB65Da59] = true; // Bilaxy1
        totalExempts[0xB5Ef14898928FDCE71b54Ea80350B76F9a3617a6] = true; // Bilaxy2
        totalExempts[0x9BA3560231e3E0aD7dde23106F5B98C72E30b468] = true; // Bilaxy3
        
        emit InitializedTotalExempts(1);
    } 

    function _getTaxPercentage(
        address _from,
        address _to,
        uint _sentAmount
    ) internal returns (uint tax) {
        uint taxPercentage = 0;
        uint balanceOfSenderOrFrom = balanceOf(_from);
        uint noww = block.timestamp;

        require(
            balanceOfSenderOrFrom > 0 && _sentAmount > 0,
            'Intangible balance or amount to send'
        );

        address accountLiable = transferMode == TRANSFER_FROM
            ? _from
            : msg.sender;

        bool isDueForTaxExemption =
            !exempts[accountLiable] &&
            !totalExempts[accountLiable] &&
            genesis[accountLiable].timestamp > 0 &&
            genesis[accountLiable].balance > 0 &&
            balanceOf(accountLiable) >= genesis[accountLiable].balance && 
            noww - genesis[accountLiable].timestamp >= ONE_YEAR * 1 days;

        if(isDueForTaxExemption) _addExempt(accountLiable, false);
        
        // Do not tax any transfers associated with total exemptions
        // Do not tax any transfers from exempted accounts
        if (
            exempts[accountLiable] || 
            totalExempts[accountLiable] || 
            totalExempts[_to]
        ) return taxPercentage;

        uint percentageTransferred = _sentAmount.mul(100).div(balanceOfSenderOrFrom);

        if (percentageTransferred <= thresholds[0]) {
            taxPercentage = startingTaxes[0];
        } else if (percentageTransferred <= thresholds[1]) {
            taxPercentage = startingTaxes[1];
        } else if (percentageTransferred <= thresholds[2]) {
            taxPercentage = startingTaxes[2];
        } else if (percentageTransferred <= thresholds[3]) {
            taxPercentage = startingTaxes[3];
        } else if (percentageTransferred <= thresholds[4]) {
            taxPercentage = startingTaxes[4];
        } else if (percentageTransferred <= thresholds[5]) {
            taxPercentage = startingTaxes[5];
        } else {
            taxPercentage = startingTaxes[6];
        }
        
        _setTaxRecord(accountLiable, taxPercentage);
        return taxPercentage;
    }

    function _getReceivedAmount(
        address _from,
        address _to,
        uint _sentAmount
    ) internal returns (uint receivedAmount, uint taxAmount) {
        uint taxPercentage = _getTaxPercentage(_from, _to, _sentAmount);
        receivedAmount = _sentAmount.sub(_sentAmount.div(BPS).mul(taxPercentage));
        taxAmount = _sentAmount.sub(receivedAmount);
    }

    function _setTaxRecord(
        address _addr, 
        uint _tax
        ) internal {
        uint timestamp = block.timestamp;
        accountTaxMap[_addr].push(TaxRecord({ 
            timestamp: timestamp,
            tax: _tax,
            balance: balanceOf(_addr)
        }));
        emit TaxRecordSet(_addr, timestamp, balanceOf(_addr), _tax);
    }

    function _internalTransfer(
        address _from, // `msg.sender` || `from`
        address _to,
        uint _amount
    ) internal returns (bool success){
        uint noww = block.timestamp;
        
        if(_from == owner && !exempts[owner]) {
            // timelock owner-originated transfers for a year. 
            require(noww >= 1654048565, 'Owner is timelocked for 1 year');
            _addExempt(owner, false);
        }
        
        (, uint taxAmount) = _getReceivedAmount(_from, _to, _amount);
        require(
            balanceOf(_from) >= _amount.add(taxAmount),
            'Exclusive taxation: Cannot afford to pay tax'
        ); 
        
        if(taxAmount > 0) {
            _burn(_from, taxAmount);
            _mint(reserve, taxAmount);
        }
        
        transferMode == TRANSFER 
            ? super.transfer(_to, _amount) 
            : super.transferFrom(_from, _to, _amount);
            
        if (genesis[_to].timestamp == 0) {
            genesis[_to].timestamp = noww;
        }
    
        genesis[_to].balance = balanceOf(_to);
        genesis[_from].balance = balanceOf(_from);
        genesis[_from].timestamp = noww;

        return true;
    }

    // Sandbox functions
    function sandboxSetTaxRecord(
        address addr, 
        uint _tax
        ) public {
        uint noww = block.timestamp;
        sandboxAccountTaxMap[addr].push(TaxRecord({ 
            timestamp: noww,
            tax: _tax,
            balance: balanceOf(addr)
        }));
        emit SandboxTaxRecordSet(addr, noww, balanceOf(addr), _tax);
    }
    
     function sandboxGetTaxRecord(
        address addr
        ) public view returns (TaxRecord[] memory tr){
        tr = sandboxAccountTaxMap[addr];
    }
}