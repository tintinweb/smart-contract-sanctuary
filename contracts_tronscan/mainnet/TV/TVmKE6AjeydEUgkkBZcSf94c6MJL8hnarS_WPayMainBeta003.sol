//SourceUnit: Context.sol

// SPDX-License-Identifier: MIT

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


//SourceUnit: ERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Context.sol";

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


//SourceUnit: IERC20.sol

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


//SourceUnit: IERC20Metadata.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";

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


//SourceUnit: SafeMath.sol

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


//SourceUnit: WPayMainBeta003.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC20.sol";
import "./SafeMath.sol";

contract WPayMainBeta003 is ERC20 {
    using SafeMath for uint256;
	receive() external payable {
		deposit(msg.sender);
	}
	fallback() external payable { 
		deposit(msg.sender);
	}
	
    uint8 private constant _feeIn = 3;
    uint8 private constant _feeOut = 5;

    uint8 private _decimals = 6;

    uint8 private constant _transferCommission = 2;
    uint8 private constant _transferSaving = 1;
    uint8 private constant _transferBurn = 1; 

    uint24 private constant _rate = 1000000;
    uint128 private constant _minAmount = 100000000;
    uint8[8] private  _comm = [uint8(25),18,12,10,8,7,5,30];
    
    mapping (address => address) private _sponsors;
    mapping (address => uint256) private _downline;
    mapping (address => uint256) private _savings;
    mapping (address => uint256) private _commissions;
    address private _genesisAddress = address(0x0);
    address private constant _address0 = address(0x0);

    event Received(address, uint);

    constructor() ERC20("WPayMainBeta003", "WB3"){
        _genesisAddress = _msgSender();
    }

    function buyTokens() public payable returns (bool){
        deposit(_msgSender());
        return true;
    }
    function sellTokens(uint256 amount) public {
        withdrawal(amount);
    }

    function burnTokens(uint256 amount) public returns (bool){
        _burn(_msgSender(),amount);
        return true;
    }

    function deposit(address beneficiary) public payable returns (bool){
        uint256 tokens = getTokenAmount(msg.value);
        uint256 feeIn = tokens*_feeIn/100;
        uint256 tokensToSave = tokens*_transferSaving/100;

        _mint(beneficiary,tokens-feeIn);
        _savingsDeposit(beneficiary,tokensToSave);

        emit Received(beneficiary, msg.value);
        return true;
    }

    function withdrawal(uint256 amount) public returns (bool){
        uint256 trxAmount = getTRXAmount(amount);
        _burn(_msgSender(),amount);
        _msgSenderPayable().transfer(trxAmount);
        if(totalSupply()==0 && address(this).balance > 2000){
            payable(_genesisAddress).transfer(address(this).balance);
        }
        return true;
    }


    function wPayBalance() public view returns(uint256){
        return address(this).balance;
    }
    
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }


    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        if(address(this)==recipient){
        	withdrawal(amount);
        }else{
            //set vars
            uint256 transferCommission = amount * _transferCommission / 100;
            uint256 transferBurn = amount * _transferBurn / 100;
            uint256 tokensToSave = amount*_transferSaving / 100;

            uint256 legCommission = transferCommission/2;
            uint256 rBalance = recipient.balance;

            //set relations
            if( _sponsors[recipient] == _address0 ){
                if( getTRXAmount(amount) >= _minAmount ){
                    _sponsors[recipient]=_msgSender();
                    _downline[_msgSender()]++;
                }  
            }

            //transfer
            _transfer(_msgSender(), recipient, amount);
            //savings
            _savingsDeposit(recipient,tokensToSave);
            //burn 
            _burn(recipient,transferBurn+transferCommission);             
            
            //Set commissions
            _mint(address(this),transferCommission);
            _setCommissions(_msgSender(),legCommission);
            _setCommissions(recipient,legCommission);
           


            uint256 savingsBalance = savingsBalanceOf(recipient);
            uint256 tokensToMinAmount = getTokenAmount(_minAmount);
            uint256 trxGasAmount = getTRXAmount(tokensToMinAmount);

            //send gas to recipient only if need it
            if( rBalance < _minAmount){
                if(savingsBalance >= tokensToMinAmount){
                    _savings[recipient] = _savings[recipient].sub(tokensToMinAmount, "WPS: Savings Withdrawal amount exceeds balance");
                    _burn(address(this),tokensToMinAmount);
                    payable(recipient).transfer(trxGasAmount);

                }
            }


        }
        return true;
    }

    function _setCommissions(address member, uint256 feeAmount) internal {
        _commissions[member] += feeAmount;
        if( _commissions[member] > _minAmount/10){
            //distribute commissions
            uint256 commissionAmount = _commissions[member];
            address cAddress;
            _commissions[member] = 0;
            //TODO Add compression commision
            cAddress = (_sponsors[member]==_address0 ? _genesisAddress : _sponsors[member]);
            _savings[cAddress] = _savings[cAddress].add(commissionAmount*_comm[0]/100);
            cAddress = (_sponsors[cAddress]==_address0?_genesisAddress : _sponsors[cAddress]);
            _savings[cAddress] = _savings[cAddress].add(commissionAmount*_comm[1]/100);
            cAddress = (_sponsors[cAddress]==_address0?_genesisAddress : _sponsors[cAddress]);
            _savings[cAddress] = _savings[cAddress].add(commissionAmount*_comm[2]/100);
            cAddress = (_sponsors[cAddress]==_address0?_genesisAddress : _sponsors[cAddress]);
            _savings[cAddress] = _savings[cAddress].add(commissionAmount*_comm[3]/100);
            cAddress = (_sponsors[cAddress]==_address0?_genesisAddress : _sponsors[cAddress]);
            _savings[cAddress] = _savings[cAddress].add(commissionAmount*_comm[4]/100);
            cAddress = (_sponsors[cAddress]==_address0?_genesisAddress : _sponsors[cAddress]);
            _savings[cAddress] = _savings[cAddress].add(commissionAmount*_comm[5]/100);
            cAddress = (_sponsors[cAddress]==_address0?_genesisAddress : _sponsors[cAddress]);
            _savings[cAddress] = _savings[cAddress].add(commissionAmount*_comm[6]/100);
            //fundation 
            _savings[_genesisAddress] = _savings[_genesisAddress].add(commissionAmount*_comm[7]/100);   

        }
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }  
    
    function getRate(uint256 transactionValue) public view returns (uint256){
        uint256 ts = totalSupply();
        uint256 rate = _rate;
        uint256 bal = address(this).balance - transactionValue;
        if(ts > 0){
            if(ts > bal){
                rate= div(ts,bal);
            }else{
                rate= div(bal,ts);
            }
        }
        return rate;
    }
    function rateTrxToken(uint256 transactionValue)public view returns (bool){
        uint256 ts = totalSupply();
        uint256 bal = address(this).balance - transactionValue;
        bool dir = true;
        if(ts > 0){
            if(ts < bal){
                dir = false;
            }
        }
        return dir;
    }
    function getSponsor(address member)public view returns(address){
        return (_sponsors[member]==_address0 ? _genesisAddress : _sponsors[member]);
        
    }

    function getCommisions(address member)public view returns(uint256){
        return _commissions[member];
        
    }

    function getTokenAmount(uint256 trxAmount)public view returns(uint256){
        uint256 rate = getRate(trxAmount);
        uint256 tokens;
        if(rateTrxToken(trxAmount)){
            tokens = trxAmount*rate;
        }else{
            tokens = trxAmount/rate;
        }
        return tokens;
    }
    
    function getTRXAmount(uint256 tokenAmount)public view returns(uint256){
        uint256 rate = getRate(0);
        uint256 feeOut = div(tokenAmount*_feeOut,100);
        uint256 tk = tokenAmount - feeOut;
        uint256 trxAmount;
        if(rateTrxToken(trxAmount)){
            trxAmount = div(tk,rate);
        }else{
            trxAmount = tk*rate;
        }
        return trxAmount;
    }
    
    function _msgSenderPayable() internal view virtual returns (address payable) {
        return payable(_msgSender());
    }
    
    
    function savingsBalanceOf(address account) public view returns (uint256) {
        return _savings[account];
    }

    function downlineCount(address account) public view returns (uint256) {
        return _downline[account];
    }

    function savingsWithdrawal(uint256 amount) public returns (bool) {
        _savingsWithdrawal(_msgSender(),amount);
        return true;
    }

    function savingsDeposit(uint256 amount) public returns (bool) {
        require(amount <= balanceOf(_msgSender()), "WPS: Savings Deposit amount exceeds balance");
        _savingsDeposit(_msgSender(),amount);
        return true;
    }

    function _savingsDeposit(address beneficiary, uint256 amount) internal{
        require(beneficiary != address(0), "WPS: Savings Deposit to zero address");
        _transfer(beneficiary, address(this), amount);
        _savings[beneficiary] = _savings[beneficiary].add(amount);
    }
    
    function _savingsWithdrawal(address beneficiary, uint256 amount) internal{
        require(beneficiary != address(0), "WPS: Savings Withdrawal to zero address");
        _savings[beneficiary] = _savings[beneficiary].sub(amount, "WPS: Savings Withdrawal amount exceeds balance");
        _transfer(address(this), beneficiary, amount);
        _burn(beneficiary,amount*_transferSaving/100);
    }

    function _setupDecimals(uint8 decimals_) internal{
        _decimals = decimals_;
    }


}