/**
 *Submitted for verification at snowtrace.io on 2021-12-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

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

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

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
contract ERC20 is Context, IERC20, IERC20Metadata, Ownable {
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
    
    mapping (address => bool) receiverWhitelisted;
    bool whitelistActive = false;
    uint initiated;

    function whitelistTo(address _addy) public onlyOwner {
        receiverWhitelisted[_addy] = true;
    }

    function flipWhitelist() public onlyOwner {
        require(initiated < 2);

        whitelistActive = !whitelistActive;
        initiated += 1;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        if (whitelistActive) {
            require(receiverWhitelisted[to] == true);
        }
    }

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

library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferAVAX(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper: AVAX_TRANSFER_FAILED');
    }
}

interface NODEON_Interface {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface MIM_Interface {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface WAVAX_Interface {
    function deposit() external payable;
    function transferFrom(address src, address dst, uint wad)
        external
        returns (bool);
    function withdraw(uint) external;
}

interface DATA_Interface {
    function getAVAXPrice() external view returns (uint price_18);
    function getNEONPrice() external view returns (uint price_18);
}

interface DAPP_Interface {
    function addNode(address _user, uint _amount) external;
    function removeNode(address _user, uint _amount) external;
    function claim() external;
    function setLastClaim(address _user, uint _value) external;
    function getNodeCount(address _user) external view returns (uint);
    function getPending(address _user) external view returns (uint);
    function giveNode(address _user, uint _amount) external;
}

interface DEX_Interface {
    function addLiquidityAVAX(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountAVAX, uint liquidity);

    function swapExactAVAXForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function swapExactTokensForAVAX(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract Nodeon is ERC20 {
    constructor(address _start) ERC20("Nodeon", "NEON") {
        _mint(_start, 1_000_000e18);
    }
}

contract NodeonDapp is Ownable {
    constructor() {
        app = msg.sender;
        temp = msg.sender;
    }

    address nodeDistributor;
    address app;
    address temp;

    address NODEON = 0xAD4715E16aBe7FdB93750788957C061FEDc4850C;
    NODEON_Interface public nodeon = NODEON_Interface(NODEON);
    
    address multisig = 0x656F762083DBCDC0D0386e46D79d5297687e04A6;

    bool nodeCreationOn = true;
    bool claimOn = true;

    mapping (address => uint) public nodeCount;
    mapping (address => uint) public lastClaim;

    uint public totalNodes;
    uint public reward = 0;

    function initSnapshot(address[] memory _users, uint[] memory _amounts, uint start, uint end) public onlyAppOrNodeDistributor {
        for (uint i = start; i < end + 1; i += 1) {
            nodeCount[_users[i]] = _amounts[i];
            lastClaim[_users[i]] = block.timestamp;
            totalNodes += _amounts[i];
        } 
    }

    function claim() public {
        require(claimOn, "Claim off");

        nodeon.approve(address(this), getPending(msg.sender));
        nodeon.transferFrom(address(this), msg.sender, getPending(msg.sender));

        lastClaim[msg.sender] = block.timestamp;
    }

    function claimFor(address _user) public onlyAppOrNodeDistributor {
        require(claimOn, "Claim off");

        nodeon.approve(address(this), getPending(_user));
        nodeon.transferFrom(address(this), _user, getPending(_user));

        lastClaim[_user] = block.timestamp;
    }

    function setLastClaim(address _user, uint _value) public onlyAppOrNodeDistributor {
        lastClaim[_user] = _value;
    }

    function addNode(address _user, uint _amount) public onlyAppOrNodeDistributor {
        require (nodeCreationOn, "Node creation off");
        claimFor(_user);

        nodeCount[_user] += _amount;
        totalNodes += _amount;
    }

    function removeNode(address _user, uint _amount) public onlyAppOrNodeDistributor {
        claimFor(_user);

        nodeCount[_user] -= _amount;
        totalNodes -= _amount;
    }

    function sendNode(address _from, address _to, uint _amount) public onlyApp {
        require(getNodeCount(_from) >= _amount, "You don't have enough nodes.");

        removeNode(_from, _amount);
        addNode(_to, _amount);
    }

    function giveNode(address _user, uint _amount) public onlyApp {
        addNode(_user, _amount);
    }

    //VIEW

    function getReward() public view returns (uint) {
        return reward;
    }

    function getTotalNodes() public view returns (uint) {
        return totalNodes;
    }

    function getPending(address _user) public view returns (uint) {
        
        uint time = block.timestamp - lastClaim[_user];
        uint total = nodeCount[_user] * time * getReward();

        return total;
    }

    function getNodeCount(address _user) public view returns (uint) {
        return nodeCount[_user];
    }

    function getLastClaim(address _user) public view returns (uint) {
        return lastClaim[_user];
    }

    //OWNER

    function flipNodesCreation() public onlyOwner {
        nodeCreationOn = !nodeCreationOn;
    }

    function flipClaim() public onlyOwner {
        claimOn = !claimOn;
    }

    function setReward(uint _value) public onlyOwner {
        reward = _value;
    }

    function setMultisig(address _addy) public onlyOwner {
        multisig = _addy;
    }

    function setNodeDistributor(address _addy) public onlyOwner {
        nodeDistributor = _addy;
    }
    
    function setApp(address _addy) public onlyOwner {
        app = _addy;
    }
    
    function setTemp(address _addy) public onlyTemp {
        temp = _addy;
    }

    modifier onlyAppOrNodeDistributor() {
        require (msg.sender == nodeDistributor || msg.sender == app, "onlyAppOrNodeDistributor");
        _;
    }

    modifier onlyApp() {
        require (msg.sender == app, "onlyApp");
        _;
    }

    modifier onlyTemp() {
        require (msg.sender == temp, "onlyTemp");
        _;
    }
}

contract NodeonDistributor is Ownable {

    event Received(address, uint);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
    
    address NODEON = 0xAD4715E16aBe7FdB93750788957C061FEDc4850C;
    NODEON_Interface public nodeon = NODEON_Interface(NODEON);
    
    address MIM = 0x130966628846BFd36ff31a822705796e8cb8C18D;
    MIM_Interface public mim = MIM_Interface(MIM);

    address DAPP = 0x471ec75689c3C6F17370AA57bb8B8897Ff86C87a;
    DAPP_Interface public dapp = DAPP_Interface(DAPP);

    address DATA = 0x23741f02e6A3f7B1b00e64d94153645C7554753a;
    DATA_Interface public data = DATA_Interface(DATA);

    address DEX = 0xE54Ca86531e17Ef3616d22Ca28b0D458b6C89106;
    DEX_Interface public dex = DEX_Interface(DEX);

    address WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    WAVAX_Interface public wavax = WAVAX_Interface(WAVAX);

    address multisig = 0x656F762083DBCDC0D0386e46D79d5297687e04A6;

    uint nodePrice = 10 * 1e18;
    uint percentReserve = 70;
    uint percentLiquidity = 20;
    uint percentTreasury = 10;

    function buyNodeNEON(uint _amount) public {
        uint value = nodePrice*_amount;

        nodeon.transferFrom(msg.sender, DAPP, value * percentReserve / 100);
        nodeon.transferFrom(msg.sender, multisig, value * percentTreasury / 100);

        address[] memory path = new address[](2);
        path[0] = NODEON;
        path[1] = WAVAX;
        nodeon.transferFrom(msg.sender, address(this), value * percentLiquidity / 100);
        nodeon.approve(DEX, value);
        dex.swapExactTokensForAVAX(
            value * percentLiquidity / 200,
            0,
            path,
            address(this),
            block.timestamp+900);

        uint valueAVAX = data.getNEONPrice() * value / 1e18;
        dex.addLiquidityAVAX{value: valueAVAX * percentLiquidity * 99 / 20000}(
            NODEON,
            value * percentLiquidity / 200,
            0,
            0,
            address(0),
            block.timestamp+900);

        dapp.addNode(msg.sender, _amount);
    }

    function buyNodeAVAX(uint _amount) public payable {
        require(_amount <= 10, "You can't buy more than 10 nodes in a single tx.");

        //Node price in token
        uint value = nodePrice*_amount;

        //Node price in AVAX
        uint priceAVAX = data.getNEONPrice() * value / 1e18;

        //Check sent amount
        require(msg.value >= priceAVAX, "Wrong value.");

        //Send in the treasury in the treasury (10%)
        TransferHelper.safeTransferAVAX(multisig, priceAVAX * percentTreasury / 100);

        //Check if msg.value is higher than expected and send funds back
        if (msg.value > priceAVAX) {
            TransferHelper.safeTransferAVAX(msg.sender, msg.value - priceAVAX);
        }

        //Swap reserve percentage from AVAX to tokens (70%)
        address[] memory path = new address[](2);
        path[0] = WAVAX;
        path[1] = NODEON;
        dex.swapExactAVAXForTokens{value: priceAVAX * percentReserve / 100}(
            0,
            path,
            DAPP,
            block.timestamp+900
        );

        //Swap half of the liquidity percentage from AVAX to tokens (half of 20%)
        dex.swapExactAVAXForTokens{value: priceAVAX * percentLiquidity / 200}(
            0,
            path,
            address(this),
            block.timestamp+900
        );

        //Approve the DEX to transfer tokens from this contract
        nodeon.approve(DEX, value);

        //Add AVAX and tokens to liquidity
        dex.addLiquidityAVAX{value: priceAVAX * percentLiquidity / 200}(
            NODEON,
            value * percentLiquidity / 205,
            0,
            0,
            address(0),
            block.timestamp+900);

        //Add node to user
        dapp.addNode(msg.sender, _amount);
    }

    function buyNodeMIM(uint _amount) public {
        uint priceMIM = getNodePriceUSD() * _amount;

        mim.transferFrom(msg.sender, address(this), priceMIM);

        mim.approve(DEX, priceMIM);
        address[] memory path = new address[](2);
        path[0] = MIM;
        path[1] = NODEON;
        dex.swapExactTokensForTokens(
            priceMIM,
            0,
            path,
            msg.sender,
            block.timestamp+900
        );

        buyNodeNEON(_amount);

        dapp.addNode(msg.sender, _amount);
    }

    function setPercentages(uint reserve, uint liquidity, uint treasury) public onlyOwner {
        require(reserve + liquidity + treasury == 100);
        require(treasury <= 25);

        percentReserve = reserve;
        percentLiquidity = liquidity;
        percentTreasury = treasury;

    }

    function getNodePrice() public view returns (uint) {
        return nodePrice;
    }

    function getNodePriceAVAX() public view returns (uint) {
        return nodePrice * data.getNEONPrice() / 1e18;
    }

    function getNodePriceUSD() public view returns (uint) {
        return getNodePriceAVAX() * data.getAVAXPrice();
    }

    function withdraw() public onlyOwner {
        payable(multisig).transfer(address(this).balance);
    }

    function withdrawTokens() public onlyOwner {
        nodeon.transfer(multisig, nodeon.balanceOf(address(this)));
    }
}

contract NodeonPresale is Ownable {

    address DAPP = 0x471ec75689c3C6F17370AA57bb8B8897Ff86C87a;
    DAPP_Interface public dapp = DAPP_Interface(DAPP);

    address DATA = 0x870E03a00fa94094aEbc70A000E5a119EbA37A1F;
    DATA_Interface public data = DATA_Interface(DATA);

    address multisig = 0x656F762083DBCDC0D0386e46D79d5297687e04A6;

    uint presaleNodePriceUSD = 20 * 1e18;
    uint nextStep = 250;
    uint presaleNodeSold;
    uint opening;

    bool presaleOn = true;

    function mintPresaleNodeAVAX(uint _amount) public payable {
        require(presaleNodeSold < 1500);
        require(_amount > 0 && _amount <= 3, "You have to mint at least 1 node and 3 nodes max.");
        require(msg.value >= getPresaleNodePrice() * _amount);
        require(presaleOn == true, "Presale closed.");
        require(block.timestamp >= opening, "Wait.");

        for (uint i; i < _amount; i += 1) {
            dapp.addNode(msg.sender, 1);
            presaleNodeSold += 1;

            if (presaleNodeSold == 1000) {
                opening = block.timestamp + 300;
                presaleNodePriceUSD = 100 * 1e18;
            } else if (presaleNodeSold == nextStep) {
                opening = block.timestamp + 300;
                nextStep += 250;
                presaleNodePriceUSD += (20 * 1e18);
            }
        }
        
    }

    function flipPresaleOn() public onlyOwner returns (bool) {
        presaleOn = !presaleOn;

        return presaleOn;
    }

    function withdraw() public onlyOwner {
        (bool sent, bytes memory datta) = multisig.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    function getPresaleNodePrice() public view returns (uint value) {
        return presaleNodePriceUSD * 1e18 / data.getAVAXPrice();
    }

    function getPresaleNodeSold() public view returns (uint) {
        return presaleNodeSold;
    }

    function getOpening() public view returns (uint) {
        return opening;
    }

    function getTimestamp() public view returns (uint) {
        return block.timestamp;
    }
}

interface LP1_Interface {
    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
}

interface LP2_Interface {
    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
}

contract Data {

    address LP1 = 0xeD8CBD9F0cE3C6986b22002F03c6475CEb7a6256;
    LP1_Interface public lp1 = LP1_Interface(LP1);

    address LP2 = 0x0B5f2628C51a5d5ED4AE625f375AE80C3Ec55619;
    LP2_Interface public lp2 = LP2_Interface(LP2);

    function getAVAXPrice() public view returns (uint price_18) {
        (uint r0, uint r1, ) = lp1.getReserves();
        price_18 = (r1 * 1e30) / r0;
        return price_18;
    }

    function getNEONPrice() public view returns (uint price_18) {
        (uint r0, uint r1, ) = lp2.getReserves();
        price_18 = (r1 * 1e18) / r0;
    }

    function getNEON_USD() public view returns (uint price_18) {
        return getAVAXPrice() * getNEONPrice() / 1e18;
    }
}