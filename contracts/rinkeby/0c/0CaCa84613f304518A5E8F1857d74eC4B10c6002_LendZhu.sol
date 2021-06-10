// Copyright (c) 2020. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.6;

import '../interfaces/ILendZhu.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '../utils/Governed.sol';
import '../utils/TCPSafeMath.sol';



contract LendZhu is ILendZhu, ERC20('Lend Zhu', 'LENDZHU'), Governed {
    using TCPSafeMath for uint256;

    
    
    function mintTo(address dest, uint count) external override lockContract {
        require(msg.sender == address(governor.lend()), 'Not Authorized');

        _mint(dest, count);
    }

    
    function burnFrom(address account, uint256 amount) external override lockContract {
        uint allowance = allowance(account, msg.sender);
        require(allowance >= amount, 'Burn exceeds allowance');

        _approve(account, _msgSender(), allowance - amount);
        _burn(account, amount);
    }
}

// Copyright (c) 2020. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.6;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';


interface ILendZhu is IERC20 {
    
    function mintTo(address account, uint countTokensToMint) external;
    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

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
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
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
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
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
     * Requirements:
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
     * Requirements:
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
    function _setupDecimals(uint8 decimals_) internal virtual {
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

// Copyright (c) 2020. All Rights Reserved
// adapted from OpenZeppelin v3.1.0 Ownable.sol


pragma solidity =0.7.6;
pragma abicoder v2;

import '../interfaces/IGovernor.sol';



abstract contract Governed {

    
    
    IGovernor public governor;
    
    bool public stopped;
    
    address public deployer;

    
    IAccounting internal accounting;
    
    IZhu internal zhu;
    
    IProtocolLock internal protocolLock;

    event Initialized(address indexed governor);
    event Stopped();

    constructor () {
        deployer = msg.sender;
    }

    
    function init(IGovernor _governor) external {
        require(msg.sender == deployer);
        delete deployer;

        governor = _governor;

        accounting = governor.accounting();
        zhu = governor.zhu();
        protocolLock = governor.protocolLock();

        _initHook();

        emit Initialized(address(_governor));
    }

    
    function _initHook() internal virtual { }

    
    function _stopImpl() internal {
        stopped = true;
        emit Stopped();
    }

    
    
    mapping(bytes4 => bool) public validUpdate;

    
    
    modifier onlyGovernor() {
        _onlyGovernor();
        _;
    }

    function _onlyGovernor() internal view {
        require(msg.sender == address(governor), 'Not Authorized');
    }


    
    modifier runnable() {
        _runnable();
        _;
    }

    function _runnable() internal view {
        _notStopped();
        require(!governor.isShutdown(), 'Protocol shutdown');
    }

    modifier beforePhase(uint8 phase) {
        require(governor.currentPhase() < phase, 'Action window passed');
        _;
    }

    modifier atLeastPhase(uint8 phase) {
        require(phase <= governor.currentPhase(), 'Action available soon');
        _;
    }

    modifier notStopped() {
        _notStopped();
        _;
    }

    function _notStopped() internal view {
        require(!stopped, 'Contract is stopped');
    }

    uint private constant _NOT_ENTERED = 1;
    uint private constant _ENTERED = 2;
    uint private _status = _NOT_ENTERED;

    
    modifier lockContract() {
        _lockContract();
        _;
        _unlockContract();
    }

    function _lockContract() internal {
        require(_status != _ENTERED, 'LC Reentrancy');
        _status = _ENTERED;
    }

    function _unlockContract() internal {
        _status = _NOT_ENTERED;
    }

    
    
    modifier lockProtocol() {
        _lockProtocol();
        _;
        _unlockProtocol();
    }

    function _lockProtocol() internal {
        protocolLock.enter();

        require(_status != _ENTERED, 'LP Reentrancy');
        _status = _ENTERED;
    }

    function _unlockProtocol() internal {
        _status = _NOT_ENTERED;

        protocolLock.exit();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;



library TCPSafeMath {
    
    
    
    
    
    
    
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        
        
        
        
        
        uint256 prod0; 
        uint256 prod1; 
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        
        
        require(denominator > prod1);

        
        
        

        
        
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        
        
        
        uint256 twos = -denominator & denominator;
        
        assembly {
            denominator := div(denominator, twos)
        }

        
        assembly {
            prod0 := div(prod0, twos)
        }
        
        
        
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        
        
        
        
        
        uint256 inv = (3 * denominator) ^ 2;
        
        
        
        inv *= 2 - denominator * inv; 
        inv *= 2 - denominator * inv; 
        inv *= 2 - denominator * inv; 
        inv *= 2 - denominator * inv; 
        inv *= 2 - denominator * inv; 
        inv *= 2 - denominator * inv; 

        
        
        
        
        
        
        result = prod0 * inv;
        return result;
    }


    
    
    uint256 public constant ONE = 1e18;

    
    function _div(uint256 a, uint256 b) internal pure returns (uint256 r) {
        r = mulDiv(a, ONE, b);
    }

    
    function _mul(uint256 a, uint256 b) internal pure returns (uint256 r) {
        r = mulDiv(a, b, ONE);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// Copyright (c) 2020. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.6;
pragma abicoder v2;


import './IAccounting.sol';
import './IAuctions.sol';
import './ITCP.sol';
import './IZhu.sol';
import './IPositionNFT.sol';
import './IEnforcedDecentralization.sol';
import './ILend.sol';
import './ILendZhu.sol';
import './ILiquidations.sol';
import './IMarket.sol';
import './IPrices.sol';
import './IProtocolLock.sol';
import './IRates.sol';
import './IRewards.sol';
import './ISettlement.sol';

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';


interface IGovernor {
    
    function isShutdown() external view returns (bool);
    function shutdownTime() external view returns (uint64);
    function currentDailyRewardCount() external view returns (uint count);
    function distributedTCP() external view returns (uint circulating);
    function protocolDeployer() external view returns (address);
    function currentPhase() external view returns (uint8);
    function requireValidAction(address target, string calldata signature) external view;
    function GENESIS_PERIODS() external view returns (uint64 periods);

    
    function protocolPool() external view returns(IUniswapV3Pool);
    function collateralPool() external view returns(IUniswapV3Pool);
    function getReferencePools() external view returns(IUniswapV3Pool[] memory);

    
    function accounting() external view returns (IAccounting);
    function auctions() external view returns (IAuctions);
    function tcp() external view returns (ITCP);
    function zhu() external view returns (IZhu);
    function zhuPositionNFT() external view returns (IPositionNFT);
    function enforcedDecentralization() external view returns (IEnforcedDecentralization);
    function lend() external view returns (ILend);
    function lendZhu() external view returns (ILendZhu);
    function liquidations() external view returns (ILiquidations);
    function market() external view returns (IMarket);
    function prices() external view returns (IPrices);
    function protocolLock() external view returns (IProtocolLock);
    function rates() external view returns (IRates);
    function rewards() external view returns (IRewards);
    function settlement() external view returns (ISettlement);
    function timelock() external view returns (address);

    
    function requireDecreaseDebtAccess(address caller) external view;
    function requireLentZhuCountAccess(address caller) external view;
    function requirePositionWriteAccess(address caller) external view;
    function requireZhuMintingAccess(address caller) external view;
    function requireZhuReservesBurnAccess(address caller) external view;
    function requireStoredCollateralAccess(address caller) external view;
    function requireUpdatePositionAccess(address caller) external view;

    function getIsGenesisPhaseAndRequireAuthIfSo(address caller, GenesisAuth calldata ga) external view returns (bool isGenesis);

    
    struct GenesisAuth { uint8 v; bytes32 r; bytes32 s; }

    
    function execute(
        address target,
        string memory signature,
        bytes memory data
    ) external returns (bool success, bytes memory returnData);
    function executeShutdown() external;
    function upgradeProtocol(address newGovernor) external;

    function addReferencePoolToProtocol(IUniswapV3Pool pool) external;
    function removeReferencePoolFromProtocol(IUniswapV3Pool pool) external;

    
    function mintTCP(address to, uint count) external;
    function distributeLiquidityRewards(address to, uint count) external;
    function increaseLiquidationAccountRewards(uint count) external;
    function poolRemovalTime(IUniswapV3Pool pool) external returns (uint64);

    
    function upgradeAuctions(IAuctions _auctions) external;
    function upgradeLend(ILend _lend) external;
    function upgradeLiquidations(ILiquidations _liquidations) external;
    function upgradeMarket(IMarket _market) external;
    function upgradePrices(IPrices _prices) external;
    function upgradeRates(IRates _rates) external;
    function upgradeRewards(IRewards _rewards) external;
    function upgradeSettlement(ISettlement _settlement) external;

    
    
    event AdminUpdated(address indexed from, address indexed to);
    
    event ContractUpgraded(string indexed contractName, address indexed contractAddress);
    event ShutdownTokensLocked(address indexed locker, uint count);
    event ShutdownTokensUnlocked(address indexed locker, uint count);
    event EmergencyShutdownExecuted(uint64 shutdownTime);
    event ShutdownExecuted();
    event ProtocolUpgraded(address indexed newGovernor);
}

// Copyright (c) 2020. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.6;
pragma abicoder v2;

import './IGovernor.sol';
import './IRewards.sol';

import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';


interface IAccounting {
    
    function getBasicPositionInfo(uint64 positionID) external view returns (uint debtCount, uint collateralCount);
    function getPosition(uint64 positionID) external view returns (DebtPosition memory acct);
    function setPosition(uint64 positionID, DebtPosition memory dp) external;
    function sendCollateral(address payable account, uint count) external;
    function getParticipatedInMarketGenesis(address account) external view returns (bool participated);
    function setParticipatedInMarketGenesis(address account, bool participated) external;

    
    function lentZhu() external view returns (uint);
    function increaseLentZhu(uint count) external;
    function sendLentZhu(address dest, uint count) external;

    
    function sendOneToOneBackedTokens(IERC20 token, address dest, uint count) external;

    
    function debt() external view returns (uint);
    function getSystemDebtInfo() external view returns (SystemDebtInfo memory);
    function setSystemDebtInfo(SystemDebtInfo memory _systemDebtInfo) external;
    function increaseDebt(uint count) external;
    function decreaseDebt(uint count) external;

    
    function getPoolPosition(uint nftID) external view returns (PoolPosition memory pt);
    function setPoolPosition(uint nftID, PoolPosition memory pt) external;
    function isPositionOwner(uint nftID, address addressToCheck) external view returns (bool);
    function deletePoolPosition(uint nftID) external;

    function setRewardStatus(uint16 poolID, RewardStatus memory rs) external;
    function getRewardStatus(uint16 poolID) external view returns (RewardStatus memory rs);

    function getParticipatedInLiquidityGenesis(address owner, uint16 poolID) external view returns (bool);
    function setParticipatedInLiquidityGenesis(address owner, uint16 poolID, bool participated) external;

    function poolLiquidity(IUniswapV3Pool pool) external view returns (uint liquidity);
    function increasePoolLiquidity(IUniswapV3Pool pool, uint liquidity) external;
    function decreasePoolLiquidity(IUniswapV3Pool pool, uint liquidity) external;

    
    function addPositionToIndex(uint nftID, uint16 poolID, int24 tickLower, int24 tickUpper, address owner) external;

    
    function onRewardsUpgrade(address newRewards) external;


    

    
    struct SystemDebtInfo {
        uint debt;
        uint totalTCPRewards;
        uint cumulativeDebt;
        uint debtExchangeRate;
    }

    struct SystemDebtInfoStorage {
        uint cumulativeDebt;
        uint128 debt;
        uint128 debtExchangeRate;
        uint128 totalTCPRewards;
    }

    
    struct DebtPosition { 
        uint startCumulativeDebt;
        uint collateral;
        uint debt;
        uint startDebtExchangeRate;
        uint startTCPRewards;
        uint64 lastTimeUpdated;
        uint64 lastBorrowTime;
        int24 tick;
        bool tickSet;
        uint64 tickIndex;
    }

    struct DebtPositionStorage {
        uint startCumulativeDebt; 
        uint128 collateral; 
        uint128 debt; 
        uint128 startDebtExchangeRate; 
        uint128 startTCPRewards; 
        uint64 lastTimeUpdated; 
        uint64 lastBorrowTime; 
        int24 tick;
        bool tickSet;
        uint64 tickIndex; 
    }

    
    struct RewardStatus {
        uint totalRewards;
        uint cumulativeLiquidity;
    }

    struct PoolPosition {
        address owner;
        uint16 poolID;
        uint cumulativeLiquidity;
        uint totalRewards;
        uint64 lastTimeRewarded;
        uint lastBlockPositionIncreased;
        int24 tickLower;
        int24 tickUpper;
        uint128 liquidity;
    }

    struct PoolPositionStorage {
        address owner;
        uint16 poolID;
        uint cumulativeLiquidity;
        uint176 totalRewards;
        uint40 lastTimeRewarded;
        uint40 lastBlockPositionIncreased;
    }

    
    event PoolPositionIndexingDisabled();
    event DebtPositionIndexingDisabled();
}

// Copyright (c) 2020. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.6;


interface IAuctions {
    
    function latestAuctionCompletionTime() external view returns (uint64);

    
    struct Auction {
        uint128 count;
        uint128 bid;
        address bidder;
        uint48 endTime;
        uint48 maxEndTime;
    }

    
    function completeSetup() external;
    function stop() external;

    
    event SurplusAuctionStarted(uint64 indexed auctionID, uint indexed count, uint64 maxEndTime);
    event DeficitAuctionStarted(uint64 indexed auctionID, uint indexed count, uint64 maxEndTime);
    event SurplusAuctionBid(uint64 indexed auctionID, address indexed bidder, uint bid);
    event DeficitAuctionBid(uint64 indexed auctionID, address indexed bidder, uint bid);
    event SurplusAuctionSettled(uint64 indexed auctionID, address indexed winner);
    event DeficitAuctionSettled(uint64 indexed auctionID, address indexed winner);
    event ParameterUpdated(string indexed paramName, uint value);
    event ParameterUpdated64(string indexed paramName, uint64 value);
}

// Copyright (c) 2020. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.6;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';


interface ITCP is IERC20 {
    
    function mintTo(address to, uint count) external;
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
    function addGovernor(address newGovernor) external;
}

// Copyright (c) 2020. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.6;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';


interface IZhu is IERC20 {
    
    function reserves() external view returns (uint);

    
    function distributeReserves(address dest, uint count) external;
    function burnReserves(uint count) external;
    function mintTo(address account, uint countTokensToMint) external;
    function burnFrom(address account, uint256 amount) external;

    
    event ParameterUpdated(string indexed paramName, uint value);
}

// Copyright (c) 2020. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.6;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol';



interface IPositionNFT is IERC721, IERC721Metadata {
    
    function mintTo(address to) external returns (uint64 id);
    function burn(uint64 tokenID) external;

    
    function isApprovedOrOwner(address account, uint tokenId) external view returns (bool r);
    function positionIDs(address account) external view returns (uint64[] memory IDs);
    function nextPositionID() external view returns (uint64 ID);
}

// Copyright (c) 2020. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.6;


interface IEnforcedDecentralization {
    function requireValidAction(address target, string memory signature) external view;
    function transferEmergencyShutdownTokens(address dest, uint count) external;
    function currentPhase() external view returns (uint8);

    
    function setPhaseOneStartTime(uint64 phaseOneStartTime) external;

    
    event PhaseOneStartTimeSet(uint64 startTime);
    event PhaseStartDelayed(uint8 indexed phase, uint64 startTime, uint8 delaysRemaining);
    event UpdateLockDelayed(uint64 locktime, uint8 delaysRemaining);
    event ActionBlacklisted(string indexed signature);
}

// Copyright (c) 2020. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.6;

import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';


interface ILend {
    
    function addReferencePool(IUniswapV3Pool pool) external;
    function removeReferencePool(IUniswapV3Pool pool) external;
    function completeSetup() external;
    function stop() external;

    
    event Lend(address indexed account, uint zhuCount, uint lendTokenCount);
    event Unlend(address indexed account, uint zhuCount, uint lendTokenCount);
    event MintZhu(address indexed user, address indexed token, uint count);
    event ReturnZhu(address indexed user, address indexed token, uint count);

    
    event ParameterUpdated(string indexed paramName, uint value);
    event ParameterUpdatedAddress(string indexed paramName, address indexed value);
    event OneToOneMintingDisabled();

}

// Copyright (c) 2020. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.6;


import './IAccounting.sol';
import './IGovernor.sol';
import './IMarket.sol';

interface ILiquidations {
    
    function completeSetup() external;
    function stop() external;

    
    struct LqInfo {
        uint discoverReward;
        uint liquidateReward;
        uint price;
        address discoverer;
        address priceInitializer;
        address account;
        uint8 collateral;
    }

    
    struct DiscoverLiquidationInfo {
        IAccounting.DebtPosition lqAcct;
        uint discoverReward;
        uint rewardsRemaining;
        uint collateralizationRequirement;
        IMarket market;
    }

    
    event UndercollatPositionDiscovered(
        uint64 indexed positionID,
        uint debtCount,
        uint collateralCount,
        uint price);
    event Liquidated(uint baseTokensToRepay, uint collateralToReceive);
    event CoveredUnbackedDebt(uint price, uint amountCovered);
    
    event ParameterUpdated(string indexed paramName, uint value);
    event ParameterUpdated32(string indexed paramName, uint32 value);
}

// Copyright (c) 2020. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.6;
pragma abicoder v2;

import './IGovernor.sol';
import './IAccounting.sol';

import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';


interface IMarket {
    
    function collateralizationRequirement() external view returns (uint ratio);
    function lastPeriodGlobalInterestAccrued() external view returns (uint64 period);

    
    function accrueInterest() external;

    
    function systemGetUpdatedPosition(uint64 positionID) external returns (IAccounting.DebtPosition memory position);

    
    function completeSetup() external;
    function stop() external;

    
    struct CalculatedInterestInfo {
        uint newDebt;
        uint newExchangeRate;
        uint additionalReserves;
        uint additionalLends;
        uint reducedReserves;
    }

    
    
    event NewPositionCreated(address indexed creator, uint64 indexed positionID);
    event PositionAdjusted(uint64 indexed positionID, int debtChange, int collateralChange);

    
    event InterestAccrued(uint64 indexed period, uint64 periods, uint newDebt, uint rewardCount, uint cumulativeDebt, uint debtExchangeRate);
    event PositionUpdated(uint indexed positionID, uint64 indexed period, uint debtAfter, uint tcpRewards);

    
    event ParameterUpdated(string indexed paramName, uint value);
    event ParameterUpdated64(string indexed paramName, uint64 value);
    event ParameterUpdatedAddress(string indexed paramName, address value);
}

// Copyright (c) 2020. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.6;

import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';


interface IPrices {
    
    function calculateTwappedPrice(IUniswapV3Pool pool, bool normalizeDecimals) external view returns (uint price);
    function calculateInstantTwappedPrice(IUniswapV3Pool pool, uint32 twapDuration) external view returns (uint);
    function calculateInstantTwappedTick(IUniswapV3Pool pool, uint32 twapDuration) external view returns (int24 tick);
    function zhuTcpPrice(uint32 twapDuration) external view returns (uint);
    function getRealZhuCountForSinglePoolPosition(
        IUniswapV3Pool pool,
        int24 tickLower,
        int24 tick,
        int24 tickUpper,
        uint128 liquidity,
        uint32 twapDuration
    ) external view returns (uint zhuCount);

    
    function systemObtainReferencePrice(IUniswapV3Pool pool) external returns (uint);

    
    function addReferencePool(IUniswapV3Pool pool) external;
    function completeSetup() external;
    function stop() external;

    
    struct PriceInfo {
        uint64 startTime;
        int56 tickCumulative;
        int24 tick;
        uint8 otherTokenDecimals;
        bool isToken0;
        bool valid;
    }

    
    event PriceUpdated(address indexed pool, uint price, int24 tick);
    event ParameterUpdatedAddress(string indexed paramName, address indexed addr);
}

// Copyright (c) 2020. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.6;


interface IProtocolLock {
    
    function enter() external;
    function exit() external;

    
    function authorizeCaller(address caller) external;
    function unauthorizeCaller(address caller) external;

    
    event CallerAuthorized(address indexed caller);
    event CallerUnauthorized(address indexed caller);
}

// Copyright (c) 2020. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.6;


import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';

interface IRates {
    
    function positiveInterestRate() external view returns (bool);
    function interestRateAbsoluteValue() external view returns (uint);

    
    function setInterestRateStep(uint128 step) external;
    function addReferencePool(IUniswapV3Pool pool) external;
    function removeReferencePool(IUniswapV3Pool pool) external;

    function completeSetup() external;
    function stop() external;

    
    event RateUpdated(int interestRate, uint price, uint rewardCount, uint64 nextUpdateTime);
    event ParameterUpdated64(string indexed paramName, uint64 value);
    event ParameterUpdated128(string indexed paramName, uint128 value);
    event ParameterUpdatedInt128(string indexed paramName, int128 value);
    event ParameterUpdatedAddress(string indexed paramName, address indexed addr);
}

// Copyright (c) 2020. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.6;


import './IGovernor.sol';

import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';

interface IRewards {
    
    function borrowRewardsPortion() external view returns (uint);

    
    function accrueRewards() external;

    
    function addReferencePool(IUniswapV3Pool pool) external;
    function removeReferencePool(IUniswapV3Pool pool) external;
    function completeSetup() external;
    function stop() external;

    
    struct UpdateStatus {
        bool isGenesis;
        bool isShutdown;
        bool isTickSet;
        int24 tick;
    }

    
    
    event LiquidityPositionCreated(address indexed owner, uint16 indexed poolID, uint indexed nftID, int24 tickLower, int24 tickUpper, uint128 liquidity);
    event LiquidityPositionIncreased(uint indexed nftID, uint128 liquidity);
    event LiquidityPositionDecreased(uint indexed nftID, uint amount0, uint amount1);
    event LiquidityPositionRemoved(uint indexed nftID, uint amount0, uint amount1);
    event LiquidityPositionLiquidated(uint indexed nftID, uint amount0, uint amount1);

    
    event ClaimedInflationRewards(address indexed owner, uint indexed nftTokenID);
    event CollectedFees(address indexed owner, uint indexed nftTokenID, uint amount0, uint amount1);

    
    event RewardsAccrued(uint count, uint64 periods);
    event RewardsDistributed(address indexed account, uint64 indexed period, uint tcpRewards);

    
    event ParameterUpdatedAddress(string indexed paramName, address value);
    event ParameterUpdated(string indexed paramName, uint value);
    event ParameterUpdated128(string indexed paramName, uint value);
    event ParameterUpdated64(string indexed paramName, uint value);
    event ParameterUpdated32(string indexed paramName, uint value);

    event RewardsPortionsUpdated(uint protocolPortion, uint collateralPortion, uint referencePortion);
}

// Copyright (c) 2020. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.6;


interface ISettlement {
    
    function stakeTokensForNoPriceConfidence(uint countTCPToStake) external;
    function unstakeTokensForNoPriceConfidence() external;

    
    function setEthPriceProvider(IPriceProvider aggregator) external;
    function stop() external;

    
    
    event SettlementInitialized(uint settlementDiscoveryStartTime);
    event StakedNoConfidenceTokens(address indexed account, uint count);
    event UnstakedNoConfidenceTokens(address indexed account, uint count);
    event NoConfidenceConfirmed(address indexed account);

    
    event SettlementWithdrawCollateral(uint64 indexed positionID, address indexed owner, uint collateralToWithdraw);
    event SettlementCollateralForZhu(uint64 indexed positionID, address indexed caller, uint zhuCount, uint collateralCount);

    
    event ParameterUpdatedAddress(string indexed paramName, address indexed _address);

    
    enum SettlementStage {
        ContractStopped,
        NotShutdown,
        NotInitialized,
        WaitingForPriceTime,
        NoPriceConfidence,
        PriceConfidence,
        PriceConfirmed
    }
}

interface IPriceProvider {
  function decimals() external view returns (uint8);
  function latestRoundData() external view returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './pool/IUniswapV3PoolImmutables.sol';
import './pool/IUniswapV3PoolState.sol';
import './pool/IUniswapV3PoolDerivedState.sol';
import './pool/IUniswapV3PoolActions.sol';
import './pool/IUniswapV3PoolOwnerActions.sol';
import './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../../introspection/IERC165.sol";

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 10000
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}