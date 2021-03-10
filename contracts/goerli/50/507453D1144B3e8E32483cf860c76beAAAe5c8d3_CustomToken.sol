// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

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

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.7.4;

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
     *
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
     *
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
     *
     * - Subtraction cannot overflow.
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
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
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
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
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

pragma solidity ^0.7.4;

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
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /* Added by CryptoTask */
    address private _owner;
    bool private _locked = false;
    bool private _lockFixed = false;
    address private _saleContract = address(0);

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
        _owner = msg.sender;  //added by CryptoTask
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
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
        require(!_locked || msg.sender == _saleContract, "Transfers locked"); //added by CryptoTask
        _transfer(msg.sender, recipient, amount);
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
        _approve(msg.sender, spender, amount);
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
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        require(!_locked, "Transfers locked");  //added by CryptoTask
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
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
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }


    /**
     * @dev Set the address of the sale contract.
     * `saleContract` can make token transfers
     * even when the token contract state is locked.
     * Transfer lock serves the purpose of preventing
     * the creation of fake Uniswap pools.
     *
     * Added by CryptoTask.
     *
     */
    function setSaleContract(address saleContract) public {
        require(msg.sender == _owner && _saleContract == address(0), "Caller must be owner and _saleContract yet unset");
        _saleContract = saleContract;
    }

    /**
     * @dev Lock token transfers.
     *
     * Added by CryptoTask.
     *
     */
    function lockTransfers() public {
        require(msg.sender == _owner && !_lockFixed, "Caller must be owner and _lockFixed false");
        _locked = true;
    }

    /**
     * @dev Unlock token transfers.
     *
     * Added by CryptoTask.
     *
     */
    function unlockTransfers() public {
        require(msg.sender == _owner && !_lockFixed, "Caller must be owner and _lockFixed false");
        _locked = false;
    }

    /**
     * @dev Permanently unlock token transfers.
     * After this, further locking is impossible.
     *
     * Added by CryptoTask.
     *
     */
    function unlockTransfersPermanent() public {
        require(msg.sender == _owner && !_lockFixed, "Caller must be owner and _lockFixed false");
        _locked = false;
        _lockFixed = true;
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
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

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
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
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
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
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

// File: contracts/CustomToken.sol

pragma solidity ^0.7.4;

contract CustomToken is ERC20 {

    constructor(
        address initialAccount,
        uint256 initialBalance
    ) ERC20("CustomToken", "TokenSYM") {
        _mint(initialAccount, initialBalance);
    }
}

// File: contracts/TokenSale.sol

pragma solidity ^0.7.4;

import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import './IUniswapV2Locker.sol';
import './Whitelisted.sol';


contract TokenSale is Whitelisted {
    using SafeMath for uint256;

    address private _owner;
    CustomToken private _token;

    address payable public _vault1;
    address payable public _vault2;
    address payable public _vault3;

    uint256 public _cap1;
    uint256 public _cap2;
    uint256 public _cap3;

    /*stage 0 = deployed, 1 = tier1 in progress, 2 = tier1 finished, 3 = tier2 in progress,
    4 = tier2 finished and funds withdrawn*/
    uint8 public _stage = 0;
    bool public _whitelistEnabled = false;
    uint256 public _maxAmount = 10 * (1 ether);
    uint256 public _swapRatio1 = 800;
    uint256 public _swapRatio2 = 550;
    uint256 public _swapRatio3 = 450;
    uint256 public _amountRaisedTier1 = 0;
    uint256 public _amountRaisedTier2 = 0;
    uint256 public _amountRaisedTier3 = 0;
    uint256 public _amountRaised = 0;
    uint256 public _liquidityReserved = 0;
    uint256 public _liquiditySwapRatio = 450;
    
    uint8 private _VaultLP_Percentage = 3; // 30%
    uint8 private _Vault2_Percentage = 3; // 30%
    uint8 private _Vault3_Percentage = 3; // 30%
    uint8 private _Vault4_Percentage = 1;  // 10%


    event LockedLiquidity(address owner, uint lpAmount, address pair);

    constructor (address tokenAddress, address vault1, address vault2, address vault3, uint cap1, uint cap2, uint cap3) {
        // Check if percentage set in the right amounts
        require(_VaultLP_Percentage + _Vault2_Percentage + _Vault3_Percentage + _Vault4_Percentage == 10, "Vault ratio");

        _owner = msg.sender;
        _token = CustomToken(tokenAddress);

        _vault1 = payable(vault1);
        _vault2 = payable(vault2);
        _vault3 = payable(vault3);

        _cap1 = cap1;
        _cap2 = cap2;
        _cap3 = cap3;
    }

    fallback() external payable {
        require(msg.value <= _maxAmount, "Investment too large");
        require(
            (_stage == 1  && _amountRaisedTier1 + msg.value <= _cap1)
              ||
            (_stage == 3  && _amountRaisedTier2 + msg.value <= _cap2)
            ||
            (_stage == 5  && _amountRaisedTier3 + msg.value <= _cap3)
        , "Cap reached");

        if (_whitelistEnabled) {
            require(isWhitelisted(msg.sender), "Not whitelisted");
        }

        if(_stage == 1) {
            _amountRaisedTier1 += msg.value;
            _amountRaised += msg.value;
            _token.transfer(msg.sender, msg.value * _swapRatio1);
        } else if (_stage == 3) {
            _amountRaisedTier2 += msg.value;
            _amountRaised += msg.value;
            _token.transfer(msg.sender, msg.value * _swapRatio2);
        } else if (_stage == 5) {
            _amountRaisedTier3 += msg.value;
            _amountRaised += msg.value;
            _token.transfer(msg.sender, msg.value * _swapRatio3);
        } else {
            revert();
        }
    }

    function toggleWhitelisting() external {
        require(msg.sender == _owner);
        _whitelistEnabled = !_whitelistEnabled;
    }

    function changeSwapRatio1(uint256 newSwapRatio) external {
        require(msg.sender == _owner && _stage == 0);
        _swapRatio1 = newSwapRatio;
    }

    function changeSwapRatio2(uint256 newSwapRatio) external {
        require(msg.sender == _owner && (_stage == 0 || _stage == 2));
        _swapRatio2 = newSwapRatio;
    }

    function changeSwapRatio3(uint256 newSwapRatio) external {
        require(msg.sender == _owner && (_stage == 0 || _stage == 4));
        _swapRatio3 = newSwapRatio;
    }

    function openTier1() external {
        require(msg.sender == _owner && _stage == 0);
        _stage = 1;
    }

    function closeTier1() external {
        require(msg.sender == _owner && _stage == 1);
        _stage = 2;
    }

    function openTier2() external {
        require(msg.sender == _owner && _stage == 2);
        _stage = 3;
    }

    function closeTier2() external {
        require(msg.sender == _owner && _stage == 3);
        _stage = 4;
    }

    function openTier3() external {
        require(msg.sender == _owner && _stage == 4);
        _stage = 5;
    }

    function createUniswapLiquidityPoolAndLock(
        address routerAddress,
        address lockerAddress,
        address payable withdrawer
    ) public {
        require(msg.sender == _owner, "Not an owner");

        address tokenAddress = address(_token);
        uint liqidityTokensAmount = _createUniswapLiquidityPool(routerAddress, tokenAddress);
        
        address factoryAddress = IUniswapV2Router02(routerAddress).factory();
        address WETH = IUniswapV2Router02(routerAddress).WETH();
        // Alternative (if WETH not used): use token1() call on pair to read the address
        address pairAddress = IUniswapV2Factory(factoryAddress).getPair(tokenAddress, WETH);
        _lockLPtokens(lockerAddress, liqidityTokensAmount, withdrawer, pairAddress);

        emit LockedLiquidity(withdrawer, liqidityTokensAmount, pairAddress);
    }

    function closeTier3(address routerAddress, address lockerAddress, address payable withdrawer) external {
        require(msg.sender == _owner && _stage == 5);
        _stage = 6;

        // Create liquidity reserve with raised capital
        if (routerAddress != address(0) && lockerAddress != address(0)) {
            require(withdrawer != address(0), "Withdrawer address missing");
            createUniswapLiquidityPoolAndLock(routerAddress, lockerAddress, withdrawer);
        }

        uint remainingAmount = address(this).balance - _liquidityReserved;

        _vault1.transfer(remainingAmount.mul(_Vault2_Percentage)/10);
        _vault2.transfer(remainingAmount.mul(_Vault3_Percentage)/10);
        _vault3.transfer(remainingAmount.mul(_Vault4_Percentage)/10);
    }

    function withdrawRaised() external {
        require(msg.sender == _owner, "Not an owner");

        // LP vault percentage should always be left for LP
        uint amountToWithdraw = address(this).balance - _liquidityReserved;
        require(amountToWithdraw != 0, "Withdrawing more than reserved");

        _vault1.transfer(amountToWithdraw.mul(_Vault2_Percentage)/10);
        _vault2.transfer(amountToWithdraw.mul(_Vault3_Percentage)/10);
        _vault3.transfer(amountToWithdraw.mul(_Vault4_Percentage)/10);

        _liquidityReserved += amountToWithdraw.mul(_VaultLP_Percentage)/10;
    }

    function _lockLPtokens(address lockerAddress, uint amount, address payable withdrawer, address pairAddress) internal {
        IUniswapV2Pair(pairAddress).approve(lockerAddress, amount);
        uint unlockDate = block.timestamp + 31556926; // 1 year in seconds

        IUniswapV2Locker(lockerAddress)
        .lockLPToken{value: 1e18}(  // using constant Unicrypt fee
            pairAddress,
            amount,
            unlockDate,
            address(0), // referral
            true,
            withdrawer
        );
    }

    function _createUniswapLiquidityPool(address routerAddress, address tokenAddress) internal returns(uint) {
        uint256 amountOfETHForLP = _amountRaised.mul(_VaultLP_Percentage)/10;

        uint256 amountOfTokensForLP = amountOfETHForLP.mul(_liquiditySwapRatio);
        _token.approve(routerAddress, amountOfTokensForLP);
        require(_token.balanceOf(address(this)) >= amountOfTokensForLP, "Contract doesn't have enough tokens");

        (uint amountToken,, uint liquidity) = IUniswapV2Router02(routerAddress)
        .addLiquidityETH{value: amountOfETHForLP}(
            tokenAddress,
            amountOfTokensForLP,
            amountOfTokensForLP, // no slippage
            amountOfETHForLP, // no slippage
            address(this),
            block.timestamp + 1200 // 20 minutes deadline
        );

        require(amountToken == amountOfTokensForLP, "Not all tokens sent to LP");
        require(liquidity > 0, "Liquity should not be 0");

        return liquidity;
    }
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity ^0.7.4;

interface IUniswapV2Locker {
    function lockLPToken (address _lpToken, uint256 _amount, uint256 _unlock_date, address payable _referral, bool _fee_in_eth, address payable _withdrawer) external payable;
}

pragma solidity ^0.7.4;

import './Administrable.sol';

contract Whitelisted is Administrable {
    mapping (address => bool) _whitelisted;

    function isWhitelisted(address account) public view onlyAdmin returns (bool) {
        return _whitelisted[account];
    }

    function addWhitelisted(address account) external onlyAdmin {
        _whitelisted[account] = true;
    }

    function addWhitelistedMultiple(address[] calldata accounts) external onlyAdmin {
        for (uint256 i = 0; i < accounts.length; i++) {
            _whitelisted[accounts[i]] = true;
        }
    }
    
    function removeWhitelisted(address account) external onlyAdmin {
        _whitelisted[account] = false;
    }
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity ^0.7.4;

contract Administrable {
    mapping(address => bool) internal _admins;

    constructor() public {
        _admins[msg.sender] = true;
    }

    modifier onlyAdmin() {
        require(isAdmin(msg.sender) == true, "Not an admin");
        _;
    }

    event AdminAdded(address account);
    event AdminRemoved(address account);

    function addAdmin(address account) public onlyAdmin {
        _admins[account] = true;
        emit AdminAdded(account);
    }

    function removeAdmin(address account) public onlyAdmin {
        _admins[account] = false;
        emit AdminRemoved(account);
    }

    function isAdmin(address account) public view returns (bool) {
        return _admins[account];
    }
}