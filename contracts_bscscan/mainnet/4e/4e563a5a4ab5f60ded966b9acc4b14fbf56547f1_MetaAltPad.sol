/**
 *Submitted for verification at BscScan.com on 2021-11-26
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

library IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint256) values;
        mapping(address => uint256) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) internal view returns (uint256) {
        return map.values[key];
    }

    function getIndexOfKey(Map storage map, address key)
        internal
        view
        returns (int256)
    {
        if (!map.inserted[key]) {
            return -1;
        }
        return int256(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint256 index)
        internal
        view
        returns (address)
    {
        return map.keys[index];
    }

    function size(Map storage map) internal view returns (uint256) {
        return map.keys.length;
    }

    function set(
        Map storage map,
        address key,
        uint256 val
    ) internal {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) internal {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint256 index = map.indexOf[key];
        uint256 lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

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

contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;

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
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
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
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
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
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
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
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
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
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
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
     * - `account` cannot be the zero address.
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

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
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
     * will be to transferred to `to`.
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
}

interface DividendPayingTokenOptionalInterface {
    /// @notice View the amount of dividend in wei that an address can withdraw.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` can withdraw.
    function withdrawableDividendOf(address _owner)
        external
        view
        returns (uint256);

    /// @notice View the amount of dividend in wei that an address has withdrawn.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` has withdrawn.
    function withdrawnDividendOf(address _owner)
        external
        view
        returns (uint256);

    /// @notice View the amount of dividend in wei that an address has earned in total.
    /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` has earned in total.
    function accumulativeDividendOf(address _owner)
        external
        view
        returns (uint256);
}

interface DividendPayingTokenInterface {
    /// @notice View the amount of dividend in wei that an address can withdraw.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` can withdraw.
    function dividendOf(address _owner) external view returns (uint256);

    /// @notice Distributes ether to token holders as dividends.
    /// @dev SHOULD distribute the paid ether to token holders as dividends.
    ///  SHOULD NOT directly transfer ether to token holders in this function.
    ///  MUST emit a `DividendsDistributed` event when the amount of distributed ether is greater than 0.
    function distributeDividends() external payable;

    /// @notice Withdraws the ether distributed to the sender.
    /// @dev SHOULD transfer `dividendOf(msg.sender)` wei to `msg.sender`, and `dividendOf(msg.sender)` SHOULD be 0 after the transfer.
    ///  MUST emit a `DividendWithdrawn` event if the amount of ether transferred is greater than 0.
    function withdrawDividend() external;

    /// @dev This event MUST emit when ether is distributed to token holders.
    /// @param from The address which sends ether to this contract.
    /// @param weiAmount The amount of distributed ether in wei.
    event DividendsDistributed(address indexed from, uint256 weiAmount);

    /// @dev This event MUST emit when an address withdraws their dividend.
    /// @param to The address which withdraws ether from this contract.
    /// @param weiAmount The amount of withdrawn ether in wei.
    event DividendWithdrawn(address indexed to, uint256 weiAmount);
}

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }

    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

library SafeMathUint {
    function toInt256Safe(uint256 a) internal pure returns (int256) {
        int256 b = int256(a);
        require(b >= 0);
        return b;
    }
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract DividendPayingToken is
    ERC20,
    DividendPayingTokenInterface,
    DividendPayingTokenOptionalInterface
{
    using SafeMath for uint256;
    using SafeMathUint for uint256;
    using SafeMathInt for int256;

    // With `magnitude`, we can properly distribute dividends even if the amount of received ether is small.
    // For more discussion about choosing the value of `magnitude`,
    //  see https://github.com/ethereum/EIPs/issues/1726#issuecomment-472352728
    uint256 internal constant magnitude = 2**128;

    uint256 internal magnifiedDividendPerShare;

    // About dividendCorrection:
    // If the token balance of a `_user` is never changed, the dividend of `_user` can be computed with:
    //   `dividendOf(_user) = dividendPerShare * balanceOf(_user)`.
    // When `balanceOf(_user)` is changed (via minting/burning/transferring tokens),
    //   `dividendOf(_user)` should not be changed,
    //   but the computed value of `dividendPerShare * balanceOf(_user)` is changed.
    // To keep the `dividendOf(_user)` unchanged, we add a correction term:
    //   `dividendOf(_user) = dividendPerShare * balanceOf(_user) + dividendCorrectionOf(_user)`,
    //   where `dividendCorrectionOf(_user)` is updated whenever `balanceOf(_user)` is changed:
    //   `dividendCorrectionOf(_user) = dividendPerShare * (old balanceOf(_user)) - (new balanceOf(_user))`.
    // So now `dividendOf(_user)` returns the same value before and after `balanceOf(_user)` is changed.
    mapping(address => int256) internal magnifiedDividendCorrections;
    mapping(address => uint256) internal withdrawnDividends;

    uint256 public totalDividendsDistributed;

    constructor(string memory _name, string memory _symbol)
        ERC20(_name, _symbol)
    {}

    /// @dev Distributes dividends whenever ether is paid to this contract.
    receive() external payable {
        distributeDividends();
    }

    /// @notice Distributes ether to token holders as dividends.
    /// @dev It reverts if the total supply of tokens is 0.
    /// It emits the `DividendsDistributed` event if the amount of received ether is greater than 0.
    /// About undistributed ether:
    ///   In each distribution, there is a small amount of ether not distributed,
    ///     the magnified amount of which is
    ///     `(msg.value * magnitude) % totalSupply()`.
    ///   With a well-chosen `magnitude`, the amount of undistributed ether
    ///     (de-magnified) in a distribution can be less than 1 wei.
    ///   We can actually keep track of the undistributed ether in a distribution
    ///     and try to distribute it in the next distribution,
    ///     but keeping track of such data on-chain costs much more than
    ///     the saved ether, so we don't do that.
    function distributeDividends() public payable override {
        require(totalSupply() > 0);

        if (msg.value > 0) {
            magnifiedDividendPerShare = magnifiedDividendPerShare.add(
                (msg.value).mul(magnitude) / totalSupply()
            );
            emit DividendsDistributed(msg.sender, msg.value);

            totalDividendsDistributed = totalDividendsDistributed.add(
                msg.value
            );
        }
    }

    /// @notice Withdraws the ether distributed to the sender.
    /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
    function withdrawDividend() public virtual override {
        _withdrawDividendOfUser(payable(msg.sender));
    }

    /// @notice Withdraws the ether distributed to the sender.
    /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
    function _withdrawDividendOfUser(address payable user)
        internal
        virtual
        returns (uint256)
    {
        uint256 _withdrawableDividend = withdrawableDividendOf(user);
        if (_withdrawableDividend > 0) {
            withdrawnDividends[user] = withdrawnDividends[user].add(
                _withdrawableDividend
            );
            emit DividendWithdrawn(user, _withdrawableDividend);
            (bool success, ) = user.call{
                value: _withdrawableDividend,
                gas: 3000
            }("");

            if (!success) {
                withdrawnDividends[user] = withdrawnDividends[user].sub(
                    _withdrawableDividend
                );
                return 0;
            }

            return _withdrawableDividend;
        }

        return 0;
    }

    /// @notice View the amount of dividend in wei that an address can withdraw.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` can withdraw.
    function dividendOf(address _owner) public view override returns (uint256) {
        return withdrawableDividendOf(_owner);
    }

    /// @notice View the amount of dividend in wei that an address can withdraw.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` can withdraw.
    function withdrawableDividendOf(address _owner)
        public
        view
        override
        returns (uint256)
    {
        return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
    }

    /// @notice View the amount of dividend in wei that an address has withdrawn.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` has withdrawn.
    function withdrawnDividendOf(address _owner)
        public
        view
        override
        returns (uint256)
    {
        return withdrawnDividends[_owner];
    }

    /// @notice View the amount of dividend in wei that an address has earned in total.
    /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
    /// = (magnifiedDividendPerShare * balanceOf(_owner) + magnifiedDividendCorrections[_owner]) / magnitude
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` has earned in total.
    function accumulativeDividendOf(address _owner)
        public
        view
        override
        returns (uint256)
    {
        return
            magnifiedDividendPerShare
                .mul(balanceOf(_owner))
                .toInt256Safe()
                .add(magnifiedDividendCorrections[_owner])
                .toUint256Safe() / magnitude;
    }

    /// @dev Internal function that transfer tokens from one address to another.
    /// Update magnifiedDividendCorrections to keep dividends unchanged.
    /// @param from The address to transfer from.
    /// @param to The address to transfer to.
    /// @param value The amount to be transferred.
    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal virtual override {
        require(false);

        int256 _magCorrection = magnifiedDividendPerShare
            .mul(value)
            .toInt256Safe();
        magnifiedDividendCorrections[from] = magnifiedDividendCorrections[from]
            .add(_magCorrection);
        magnifiedDividendCorrections[to] = magnifiedDividendCorrections[to].sub(
            _magCorrection
        );
    }

    /// @dev Internal function that mints tokens to an account.
    /// Update magnifiedDividendCorrections to keep dividends unchanged.
    /// @param account The account that will receive the created tokens.
    /// @param value The amount that will be created.
    function _mint(address account, uint256 value) internal override {
        super._mint(account, value);

        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[
            account
        ].sub((magnifiedDividendPerShare.mul(value)).toInt256Safe());
    }

    /// @dev Internal function that burns an amount of the token of a given account.
    /// Update magnifiedDividendCorrections to keep dividends unchanged.
    /// @param account The account whose tokens will be burnt.
    /// @param value The amount that will be burnt.
    function _burn(address account, uint256 value) internal override {
        super._burn(account, value);

        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[
            account
        ].add((magnifiedDividendPerShare.mul(value)).toInt256Safe());
    }

    function _setBalance(address account, uint256 newBalance) internal {
        uint256 currentBalance = balanceOf(account);

        if (newBalance > currentBalance) {
            uint256 mintAmount = newBalance.sub(currentBalance);
            _mint(account, mintAmount);
        } else if (newBalance < currentBalance) {
            uint256 burnAmount = currentBalance.sub(newBalance);
            _burn(account, burnAmount);
        }
    }
}

contract MetaAltPad is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;

    address public uniswapV2Pair;

    bool private swapping;
    bool private stakingEnabled = false;
    bool public tradingEnabled = false;

    MAPDividendTracker public dividendTracker;

    address public liquidityWallet;

    address payable public marketingAddress = payable(0x9cf5D7b3AF1E834AEE1B525DAfe45B50e4414255);

    uint256 public maxSellTransactionAmount = 1000000000 * (10**18);
    uint256 public swapTokensAtAmount = 200000 * (10**18);
    uint256 public swapTokensAtAmountMax = 5000000 * (10**18);


    uint256 public devFees = 4;
    uint256 public devSellFees = 4;
    uint256 public devFeesReferred = 4;
    uint256 public liquidityFee = 2;
    uint256 public liquiditySellFee = 3;
    uint256 public liquidityFeeReferred = 2;
    uint256 public BNBRewardsBuyFee = 7;
    uint256 public BNBRewardsBuyFeeReferred = 1;
    uint256 public BNBRewardsSellFee = 6;    
    
    uint256 private countDevFees = 0;
    uint256 private countLiquidityFees = 0;
    uint256 private countBNBRewardsFee = 0;
    
    mapping (address => mapping (int256 => address)) public referrerTree;
    

    uint256 public referralFee; // referral fees are split up by the referralTreeFees
    mapping(int256 => uint256) public referralTreeFees;
    int256 private referralTreeFeesLength;
    
    mapping (address => uint256) public referralCount;
    mapping (address => uint256) public referralCountBranched;
    mapping (address => uint256) public referralEarnings;

    uint256 public totalReferralsDistributed;

    bool public swapAndLiquifyEnabled = true;
    
    // use by default 300,000 gas to process auto-claiming dividends
    uint256 public gasForProcessing = 300000;

    // exlcude from fees and max transaction amount
    mapping(address => bool) private _isExcludedFromFees;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping(address => bool) public automatedMarketMakerPairs;

    mapping(address => bool) private canTransferBeforeTradingIsEnabled;


    event EnableSwapAndLiquify(bool enabled);

    event SetPreSaleWallet(address wallet);

    event UpdateDividendTracker(
        address indexed newAddress,
        address indexed oldAddress
    );

    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );

    event TradingEnabled();

    event UpdateFees(
        uint256 dev,
        uint256 liquidity,
        uint256 BNBRewardsBuy,
        uint256 BNBRewardsSell,
        uint256 referralFee
    );
    
    event UpdateFeesReferred(
        uint256 dev,
        uint256 liquidity,
        uint256 BNBRewardsBuy
    );
    
    event UpdateReferralTreeFees(
        int256 index,
        uint256 fee
    );
    
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event LiquidityWalletUpdated(
        address indexed newLiquidityWallet,
        address indexed oldLiquidityWallet
    );

    event GasForProcessingUpdated(
        uint256 indexed newValue,
        uint256 indexed oldValue
    );

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity,
        bool success
    );

    event SendDividends(uint256 dividends, uint256 marketing, bool success);

    event ProcessedDividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        uint256 gas,
        address indexed processor
    );

    event UpdatePayoutToken(address account, address token);
    event UpdateAllowTokens(address token, bool allow);
    
    event ReferralRewards(address from, address indexed to, uint256 indexed amount, uint256 iterationDaily, uint256 iterationWeekly, uint256 iterationMonthly, int256 treePosition, int256 indexed bnbAmount);
    event ReferredBy(address indexed by, address indexed referree, uint256 iterationDaily, uint256 iterationWeekly, uint256 iterationMonthly);

    event LeaderboardCompletion(uint8 leaderboardCase, uint256 iteration);

    constructor() ERC20("MetaAltPad", "MAP") {
        dividendTracker = new MAPDividendTracker(payable(this));

        liquidityWallet = owner();

        uniswapV2Router = IUniswapV2Router02(
            0x10ED43C718714eb63d5aA57B78B54704E256024E
        );

        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
                address(this),
                uniswapV2Router.WETH()
            );

        _setAutomatedMarketMakerPair(uniswapV2Pair, true);

        // exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(
            0x000000000000000000000000000000000000dEaD
        );
        dividendTracker.excludedFromDividends(address(0));
        dividendTracker.excludeFromDividends(owner());
        dividendTracker.excludeFromDividends(address(uniswapV2Router));

        // exclude from paying fees or having max transaction amount
        _isExcludedFromFees[liquidityWallet] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(dividendTracker)] = true;

        referralTreeFees[0] = 200; // 2% to primary referrer
        referralTreeFees[1] = 150; // 1.5% to secondary referrer
        referralTreeFees[2] =  50; // 0.5% to tertiary referrer
        referralTreeFeesLength = 3;

        calculateReferralFee();

        canTransferBeforeTradingIsEnabled[owner()] = true;
        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */

        _mint(owner(), 1000000000 * (10**18));
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    receive() external payable {}

    function enableTrading() external onlyOwner {
        require(!tradingEnabled);

        tradingEnabled = true;
        emit TradingEnabled();
    }

    function setPresaleWallet(address wallet) external onlyOwner {
        canTransferBeforeTradingIsEnabled[wallet] = true;
        _isExcludedFromFees[wallet] = true;
        dividendTracker.excludeFromDividends(wallet);

        emit SetPreSaleWallet(wallet);
    }

    function updateMaxAmount(uint256 newNum) public onlyOwner {
        require(maxSellTransactionAmount != newNum);
        maxSellTransactionAmount = newNum * (10**18);
    }

    function updateDividendTracker(address newAddress) public onlyOwner {
        require(newAddress != address(dividendTracker));

        MAPDividendTracker newDividendTracker = MAPDividendTracker(
            payable(newAddress)
        );

        require(newDividendTracker.owner() == address(this));

        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(owner());
        newDividendTracker.excludeFromDividends(address(uniswapV2Router));

        emit UpdateDividendTracker(newAddress, address(dividendTracker));

        dividendTracker = newDividendTracker;
    }

    function setMarketingAddress(address payable newAddress)
        public
        onlyOwner
    {
        marketingAddress = newAddress;
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router));
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
        dividendTracker.excludeFromDividends(newAddress);
        dividendTracker.updateUniswapV2Router(newAddress);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded);
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }
    
    function excludeFromDividends(address account) public onlyOwner {
        dividendTracker.excludeFromDividends(account);

    }

    function enableSwapAndLiquify(bool enabled) public onlyOwner {
        require(swapAndLiquifyEnabled != enabled);
        swapAndLiquifyEnabled = enabled;

        emit EnableSwapAndLiquify(enabled);
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        public
        onlyOwner
    {
        require(pair != uniswapV2Pair);

        _setAutomatedMarketMakerPair(pair, value);
    }

    function setAllowCustomTokens(bool allow) public onlyOwner {
        dividendTracker.setAllowCustomTokens(allow);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        if (value) {
            dividendTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateLiquidityWallet(address newLiquidityWallet)
        public
        onlyOwner
    {
        excludeFromFees(newLiquidityWallet, true);
        emit LiquidityWalletUpdated(newLiquidityWallet, liquidityWallet);
        liquidityWallet = newLiquidityWallet;
    }

    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 500000);
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function updateFees(
        uint256 dev,
        uint256 liquidity,
        uint256 BNBRewardsBuy,
        uint256 BNBRewardsSell,
        uint256 referral
    ) public onlyOwner {
        devFees = dev;
        liquidityFee = liquidity;
        BNBRewardsBuyFee = BNBRewardsBuy;
        BNBRewardsSellFee = BNBRewardsSell;
        referralFee = referral;

        emit UpdateFees(dev, liquidity, BNBRewardsBuy, BNBRewardsSell, referralFee);
    }
    
    function updateFeesReferred(
        uint256 devReferred,
        uint256 liquidityReferred,
        uint256 BNBRewardsBuyReferred
    ) public onlyOwner {
        devFeesReferred = devReferred;
        liquidityFeeReferred = liquidityReferred;
        BNBRewardsBuyFeeReferred = BNBRewardsBuyReferred;

        emit UpdateFeesReferred(devReferred, liquidityReferred, BNBRewardsBuyReferred);
    }
    
    // returns with two decimals of precision. i.e. "123" == "1.23%"
    function getReferralTreeFees(int256 index) public view returns (uint256) {
        return referralTreeFees[index];
    }
    
    function getReferralTreeFeesLength() public view returns (int256){
        return referralTreeFeesLength;
    }
    
    function calculateReferralFee() private {
        uint256 referralTreeFeesAdded;
        for(int i = 0; i < referralTreeFeesLength; i++){
            referralTreeFeesAdded += referralTreeFees[i];
        }
        referralFee = referralTreeFeesAdded / 100;
    }
    
    function setReferralTreeFeesLength(int256 length) public onlyOwner {
        referralTreeFeesLength = length;
        calculateReferralFee();
    }
    
    function updateReferralTreeFees(int256 index, uint256 fee) public onlyOwner {
        referralTreeFees[index] = fee;
        calculateReferralFee();
        emit UpdateReferralTreeFees(index, fee);
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function withdrawableDividendOf(address account)
        public
        view
        returns (uint256)
    {
        return dividendTracker.withdrawableDividendOf(account);
    }

    function dividendTokenBalanceOf(address account)
        public
        view
        returns (uint256)
    {
        return dividendTracker.balanceOf(account);
    }

    function getAccountDividendsInfo(address account)
        external
        view
        returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256
        )
    {
        return dividendTracker.getAccount(account);
    }

    function getAccountDividendsInfoAtIndex(uint256 index)
        external
        view
        returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256
        )
    {
        return dividendTracker.getAccountAtIndex(index);
    }

    function processDividendTracker(uint256 gas) external {
        (
            uint256 iterations,
            uint256 claims,
            uint256 lastProcessedIndex
        ) = dividendTracker.process(gas);
        emit ProcessedDividendTracker(
            iterations,
            claims,
            lastProcessedIndex,
            false,
            gas,
            tx.origin
        );
    }

    function claim() external {
        dividendTracker.processAccount(payable(msg.sender), false);
    }

    function getLastProcessedIndex() external view returns (uint256) {
        return dividendTracker.getLastProcessedIndex();
    }

    function getNumberOfDividendTokenHolders() external view returns (uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }

    function setAutoClaim(bool value) external {
        dividendTracker.setAutoClaim(msg.sender, value);
    }

    function setDividendsPaused(bool value) external onlyOwner {
        dividendTracker.setDividendsPaused(value);
    }

    function isExcludedFromAutoClaim(address account)
        external
        view
        returns (bool)
    {
        return dividendTracker.isExcludedFromAutoClaim(account);
    }
    
    function getBNBBalance() external view returns (uint256){
        return address(this).balance;
    }
    
    function transferBNB(address destination, uint256 bnb) external onlyOwner{
        payable(destination).transfer(bnb);
    }
    
    function getNativeBalance() external view returns (uint256){
        return balanceOf(address(this));
    }
    
    function getCountOfFeesToSwap() external view returns (uint256, uint256, uint256){
        return (countBNBRewardsFee, countDevFees, countLiquidityFees);
    }
    
    function transferERC20Token(address tokenAddress, uint256 amount, address destination) external onlyOwner{
        ERC20(tokenAddress).transfer(destination, amount);
    }

    uint256 private originalAmountBeforeFees;

    uint256 private devFeeActual;
    uint256 private liquidityFeeActual;
    uint256 private BNBRewardsBuyFeeActual;
    uint256 private BNBRewardsSellFeeActual;
    uint256 private totalBuyFeesActual;
    uint256 private totalSellFeesActual;
    
    
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(
            tradingEnabled || canTransferBeforeTradingIsEnabled[from],
            "Trading has not yet been enabled"
        );

        if(from != uniswapV2Pair){
            require(to != address(this), "You cannot send tokens to the contract address!");
        }

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        } else if (
            !swapping && !_isExcludedFromFees[from] && !_isExcludedFromFees[to] && (to == address(uniswapV2Pair) || from == address(uniswapV2Pair))
        ) {
            bool isSelling = automatedMarketMakerPairs[to];

            
            devFeeActual = devFees;
            liquidityFeeActual = liquidityFee;
            BNBRewardsBuyFeeActual = BNBRewardsBuyFee;
            BNBRewardsSellFeeActual = BNBRewardsSellFee;

            bool isReferredOnBuy = false;
            address referrer = address(0x0000000000000000000000000000000000000000);
            
            // if the user has been referred by someone and is buying, change to special fees
            if((getReferrerOf(to) != referrer) && !isSelling){
                isReferredOnBuy = true;
                referrer = getReferrerOf(to);
                devFees = devFeesReferred;
                liquidityFee = liquidityFeeReferred;
                BNBRewardsBuyFee = BNBRewardsBuyFeeReferred;
                BNBRewardsSellFee = BNBRewardsSellFee;
            }

            if (
                maxSellTransactionAmount != 0 &&
                isSelling && // sells only by detecting transfer to automated market maker pair
                from != address(uniswapV2Router) //router -> pair is removing liquidity which shouldn't have max
            ) {
                require(
                    amount <= maxSellTransactionAmount,
                    "maxSellTransactionAmount."
                );
                
                devFees = devSellFees;
                liquidityFee = liquiditySellFee; 
            }

            uint256 contractTokenBalance = balanceOf(address(this));

            bool canSwap = contractTokenBalance >= swapTokensAtAmount;
            
            if (canSwap && !automatedMarketMakerPairs[from]) {
                swapping = true;

                if (swapAndLiquifyEnabled) {
                    swapAndLiquify(countLiquidityFees);
                }

                swapAndSendDividendsAndMarketingFunds(countBNBRewardsFee, countDevFees);

                swapping = false;
            }

            originalAmountBeforeFees = amount;

            /*
                Referral System
            */
            uint256 referralFeeTxn = amount.mul(referralFee).div(100);
            
            if(isReferredOnBuy){
                for(int i = 0; i < referralTreeFeesLength; i++){
                    address treePayoutTo = referrerTree[to][i];
                    uint256 adjustedTax = originalAmountBeforeFees.mul(referralTreeFees[i]).div(10000);
                    
                    if(treePayoutTo == address(0x0000000000000000000000000000000000000000)){
                        break;
                    }

                    amount = amount.sub(adjustedTax);

                    super._transfer(from, treePayoutTo, adjustedTax);
                    dividendTracker.setBalance(treePayoutTo, balanceOf(treePayoutTo));
                    referralEarnings[treePayoutTo] += adjustedTax;
                    totalReferralsDistributed += adjustedTax;
                    referralFeeTxn -= adjustedTax;
                    
                    
                }
                
                if(referralFeeTxn > 0){
                    amount = amount.sub(referralFeeTxn);
                    super._transfer(from, address(this), referralFeeTxn);
                    countBNBRewardsFee += referralFeeTxn;
                }
            }
            /*
            
            */

            uint256 BNBRewardsFee = isSelling ? BNBRewardsSellFee : BNBRewardsBuyFee;

            uint256 devFeeAmount = originalAmountBeforeFees.mul(devFees).div(100);
            uint256 liquidityFeeAmount = originalAmountBeforeFees.mul(liquidityFee).div(100);
            uint256 BNBRewardsFeeAmount = originalAmountBeforeFees.mul(BNBRewardsFee).div(100);
            
            countDevFees += devFeeAmount;
            countLiquidityFees += liquidityFeeAmount;
            countBNBRewardsFee += BNBRewardsFeeAmount;

            uint256 fees = devFeeAmount + liquidityFeeAmount + BNBRewardsFeeAmount;
            amount = amount.sub(fees);
            super._transfer(from, address(this), fees);

            uint256 gas = gasForProcessing;

            try dividendTracker.process(gas) returns (
                uint256 iterations,
                uint256 claims,
                uint256 lastProcessedIndex
            ) {
                emit ProcessedDividendTracker(
                    iterations,
                    claims,
                    lastProcessedIndex,
                    true,
                    gas,
                    tx.origin
                );
            } catch { }
            
            // set fees back to normal values
            if(isReferredOnBuy){
                devFees = devFeeActual;
                liquidityFee = liquidityFeeActual;
                BNBRewardsBuyFee = BNBRewardsBuyFeeActual;
                BNBRewardsSellFee = BNBRewardsSellFeeActual;
            }
        }

        super._transfer(from, to, amount);

        dividendTracker.setBalance(from, balanceOf(from));
        dividendTracker.setBalance(to, balanceOf(to));
        
    }

    function swapAndLiquify(uint256 tokens) private {
        if(tokens > balanceOf(address(this))){
            emit SwapAndLiquify(0, 0, 0, false);
            return;
        }
        
        // avoid price impact errors with large transactions
        if(tokens > swapTokensAtAmountMax){
            tokens = swapTokensAtAmountMax;
        }
        
        // split the contract balance into halves
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);
        
        if(half <= 0 || otherHalf <= 0){
            return;
        }

        // capture the contract's current BNB balance.
        // this is so that we can capture exactly the amount of BNB that the
        // swap creates, and not make the liquidity event include any BNB that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for BNB
        swapTokensForBNB(half, payable(address(this)));
        
        countLiquidityFees -= half;

        // how much BNB did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);
        
        countLiquidityFees -= otherHalf;
        
        emit SwapAndLiquify(half, newBalance, otherHalf, true);
    }
    
    function setSwapTokensAmount(uint256 amount) public onlyOwner {
        swapTokensAtAmount = amount;
    }
    
    function setSwapTokensAmountMax(uint256 amount) public onlyOwner {
        require(amount > swapTokensAtAmount, "Max amount must be greater than minimum");
        swapTokensAtAmountMax = amount;
    }

    function swapTokensForBNB(uint256 tokenAmount, address payable account) private {
        if(tokenAmount <= 0){
            return;
        }
        if(balanceOf(address(this)) < tokenAmount){
            tokenAmount = balanceOf(address(this));
        }
        
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            account,
            block.timestamp
        );
    }

    function updatePayoutToken(address token) public {
        require(balanceOf(msg.sender) > 0, "You must own more than zero $ShibRef tokens to switch your payout token!");
        require(token != address(this));

        dividendTracker.updatePayoutToken(msg.sender, token);
        emit UpdatePayoutToken(msg.sender, token);
    }

    function getPayoutToken(address account) public view returns (address) {
        return dividendTracker.getPayoutToken(account);
    }

    function updateAllowTokens(address token, bool allow) public onlyOwner {
        require(token != address(this));

        dividendTracker.updateAllowTokens(token, allow);
        emit UpdateAllowTokens(token, allow);
    }

    function getAllowTokens(address token) public view returns (bool) {
        return dividendTracker.getAllowTokens(token);
    }
    
    function setReferrer(address _referrer) public {
        require(_referrer != address(0),"Not a valid referrer");
        require(_referrer != msg.sender, "You cannot refer yourself");
        require(referrerTree[msg.sender][0] == address(0), "Referrer cannot be changed!");

        // add the direct referrer to the user's payout tree
        referrerTree[msg.sender][0] = _referrer;
        referralCount[_referrer] = referralCount[_referrer] + 1;

        // check if the referrer was referred through a tree of their own;
        // set payout tree accordingly if so
        for(int i = 0; i < referralTreeFeesLength - 1; i++){
            address treeAddress = referrerTree[_referrer][i];
            
            if(treeAddress == address(0x0000000000000000000000000000000000000000)){
                break;
            }
            
            referrerTree[msg.sender][i + 1] = treeAddress;
            referralCountBranched[treeAddress] = referralCountBranched[treeAddress] + 1;
        }
        
        
    }
    
    function getReferrer() public view returns (address) {
        return referrerTree[msg.sender][0];
    }
    
    function getReferrerOf(address account) public view returns (address) {
        return referrerTree[account][0];
    }
    
    function getReferralCount(address account) public view returns (uint256) {
        return referralCount[account];
    }
    
    function getReferralCountBranched(address account) public view returns (uint256) {
        return referralCountBranched[account];
    }
    
    function getReferralEarnings(address account) public view returns (uint256) {
        return referralEarnings[account];
    }
    
    function getReferralTree(address account, int index) public view returns (address) {
        return referrerTree[account][index];
    }
    
    function setReferralTreeAtIndex(address account, int index, address accountToInsert) public onlyOwner{
        referrerTree[account][index] = accountToInsert;
    }
    
    function getReferralTreeLength(address account) public view returns (int256) {
        for(int i = 0; i < referralTreeFeesLength; i++){
            if(referrerTree[account][i] == address(0x0000000000000000000000000000000000000000)){
                return i;
            }
        }
        
        return -1;
    }
    
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liquidityWallet,
            block.timestamp
        );
    }

    function forceSwapAndSendDividendsAndMarketingFundsAndLiquidity(uint256 dividends, uint256 marketing, uint256 liquidity) public onlyOwner {
        swapAndLiquify(liquidity);
        swapAndSendDividendsAndMarketingFunds(dividends, marketing);
    }

    function swapAndSendDividendsAndMarketingFunds(uint256 dividends, uint256 marketing) private {
        if(dividends + marketing > balanceOf(address(this))){
            emit SendDividends(
                dividends,
                marketing,
                false
            );
            return;
        }
        
        uint256 beforeSwap;
        uint256 afterSwapDelta;
        
        // avoid price impact errors with large transactions
        if(dividends > swapTokensAtAmountMax){
            dividends = swapTokensAtAmountMax;
        }
        beforeSwap = address(this).balance;
        swapTokensForBNB(dividends, payable(address(this)));
        afterSwapDelta = address(this).balance - beforeSwap;
        countBNBRewardsFee -= dividends;
        uint256 BNBRewardsFeeBNB = afterSwapDelta;
        if(dividends <= 0){
            BNBRewardsFeeBNB = 0;
        }

        (bool success, ) = address(dividendTracker).call{value: BNBRewardsFeeBNB}("");

        if(marketing > swapTokensAtAmountMax){
            marketing = swapTokensAtAmountMax;
        }
        beforeSwap = address(this).balance;
        swapTokensForBNB(marketing, payable(address(this)));
        afterSwapDelta = address(this).balance - beforeSwap;
        countDevFees -= marketing;
        uint256 devFeesBNB = afterSwapDelta;
        if(marketing <= 0){
            devFeesBNB = 0;
        }
        
        (bool successMarketing, ) = address(marketingAddress).call{value: devFeesBNB}("");

        emit SendDividends(
            BNBRewardsFeeBNB,
            devFeesBNB,
            success && successMarketing
        );
    }
}

contract MAPDividendTracker is DividendPayingToken, Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping(address => bool) public excludedFromDividends;
    mapping(address => bool) public excludedFromAutoClaim;
    mapping(address => address) public payoutToken;
    mapping(address => bool) public allowTokens;
    
    bool public allowCustomTokens;
    bool public dividendsPaused = false;

    IUniswapV2Router02 public uniswapV2Router;

    MetaAltPad public MAP;

    mapping(address => uint256) public lastClaimTimes;

    uint256 public immutable minimumTokenBalanceForAutoDividends;
    uint256 public immutable minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event DividendReinvested(
        address indexed acount,
        uint256 value,
        bool indexed automatic
    );
    event Claim(
        address indexed account,
        uint256 amount,
        bool indexed automatic
    );
    event DividendsPaused(bool paused);
    event SetAllowCustomTokens(bool allow);

    constructor(address payable mainContract)
        DividendPayingToken(
            "MAP_Dividend_Tracker",
            "MAP_Dividend_Tracker"
        )
    {
        MAP = MetaAltPad(mainContract);
        minimumTokenBalanceForAutoDividends = 10000 * (10**18);
        minimumTokenBalanceForDividends = 1 * (10**18);

        uniswapV2Router = IUniswapV2Router02(
            0x10ED43C718714eb63d5aA57B78B54704E256024E 
        );
        allowCustomTokens = true;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function _transfer(
        address,
        address,
        uint256
    ) internal pure override {
        require(false, "MAP_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() public pure override {
        require(
            false,
            "MAP_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main MetaAltPad contract."
        );
    }

    function isExcludedFromAutoClaim(address account)
        external
        view
        onlyOwner
        returns (bool)
    {
        return excludedFromAutoClaim[account];
    }

    function getAllowCustomTokens() public view returns (bool) {
        return(allowCustomTokens);
    }

    function setAllowCustomTokens(bool allow) external onlyOwner {
        require(allowCustomTokens != allow);
        allowCustomTokens = allow;
        emit SetAllowCustomTokens(allow);
    }

    function excludeFromDividends(address account) external onlyOwner {
        require(!excludedFromDividends[account]);
        excludedFromDividends[account] = true;

        _setBalance(account, 0);
        tokenHoldersMap.remove(account);

        emit ExcludeFromDividends(account);
    }

    function setAutoClaim(address account, bool value) external onlyOwner {
        excludedFromAutoClaim[account] = value;
    }

    function setDividendsPaused(bool value) external onlyOwner {
        require(dividendsPaused != value);
        dividendsPaused = value;
        emit DividendsPaused(value);
    }

    function getLastProcessedIndex() external view returns (uint256) {
        return lastProcessedIndex;
    }

    function getNumberOfTokenHolders() external view returns (uint256) {
        return tokenHoldersMap.keys.length;
    }

    function getAccount(address _account)
        public
        view
        returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 lastClaimTime
        )
    {
        account = _account;

        index = tokenHoldersMap.getIndexOfKey(account);

        iterationsUntilProcessed = -1;

        if (index >= 0) {
            if (uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(
                    int256(lastProcessedIndex)
                );
            } else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length >
                    lastProcessedIndex
                    ? tokenHoldersMap.keys.length.sub(lastProcessedIndex)
                    : 0;

                iterationsUntilProcessed = index.add(
                    int256(processesUntilEndOfArray)
                );
            }
        }

        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);

        lastClaimTime = lastClaimTimes[account];
    }

    function getAccountAtIndex(uint256 index)
        public
        view
        returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256
        )
    {
        if (index >= tokenHoldersMap.size()) {
            return (
                0x0000000000000000000000000000000000000000,
                -1,
                -1,
                0,
                0,
                0
            );
        }

        address account = tokenHoldersMap.getKeyAtIndex(index);

        return getAccount(account);
    }

    function setBalance(address account, uint256 newBalance)
        external
        onlyOwner
    {
        if (excludedFromDividends[account]) {
            return;
        }

        if (newBalance < minimumTokenBalanceForDividends) {
            tokenHoldersMap.remove(account);
            _setBalance(account, 0);

            return;
        }

        _setBalance(account, newBalance);

        if (newBalance >= minimumTokenBalanceForAutoDividends) {
            tokenHoldersMap.set(account, newBalance);
        } else {
            tokenHoldersMap.remove(account);
        }
    }

    function process(uint256 gas)
        public
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

        if (numberOfTokenHolders == 0 || dividendsPaused) {
            return (0, 0, lastProcessedIndex);
        }

        uint256 _lastProcessedIndex = lastProcessedIndex;

        uint256 gasUsed = 0;

        uint256 gasLeft = gasleft();

        uint256 iterations = 0;
        uint256 claims = 0;

        while (gasUsed < gas && iterations < numberOfTokenHolders) {
            _lastProcessedIndex++;

            if (_lastProcessedIndex >= numberOfTokenHolders) {
                _lastProcessedIndex = 0;
            }

            address account = tokenHoldersMap.keys[_lastProcessedIndex];

            if (!excludedFromAutoClaim[account]) {
                if (processAccount(payable(account), true)) {
                    claims++;
                }
            }

            iterations++;

            uint256 newGasLeft = gasleft();

            if (gasLeft > newGasLeft) {
                gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
            }

            gasLeft = newGasLeft;
        }

        lastProcessedIndex = _lastProcessedIndex;

        return (iterations, claims, lastProcessedIndex);
    }

    function processAccount(address payable account, bool automatic)
        public
        onlyOwner
        returns (bool)
    {
        if (dividendsPaused) {
            return false;
        }


        uint256 amount = _withdrawDividendOfUser(account);

        if (amount > 0) {
            lastClaimTimes[account] = block.timestamp;
        
            emit Claim(account, amount, automatic);
            
            return true;
        }

        return false;
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }

    function updatePayoutToken(address account, address token)
        public
        onlyOwner
    {
        require(
            allowTokens[token] || token == address(0),
            "Token not in allow list"
        );
        payoutToken[account] = token;
    }

    function getPayoutToken(address account) public view returns (address) {
        return payoutToken[account];
    }

    function updateAllowTokens(address token, bool allow) public onlyOwner {
        allowTokens[token] = allow;
    }

    function getAllowTokens(address token) public view returns (bool) {
        return allowTokens[token];
    }

    function _withdrawDividendOfUser(address payable user)
        internal
        override
        returns (uint256)
    {
        uint256 _withdrawableDividend = withdrawableDividendOf(user);
        if (_withdrawableDividend > 0) {
            withdrawnDividends[user] = withdrawnDividends[user].add(
                _withdrawableDividend
            );

            address tokenAddress = payoutToken[user];
            bool success;

            // if no tokenAddress assume bnb payout
            if (
                !allowCustomTokens ||
                tokenAddress == address(0) ||
                !allowTokens[tokenAddress]
            ) {
                (success, ) = user.call{
                    value: _withdrawableDividend,
                    gas: 3000
                }("");
            } else {
                //investor wants to be payed out in a custom token
                address[] memory path = new address[](2);
                path[0] = uniswapV2Router.WETH();
                path[1] = tokenAddress;

                try
                    uniswapV2Router
                        .swapExactETHForTokensSupportingFeeOnTransferTokens{
                        value: _withdrawableDividend
                    }(
                        0, // accept any amount of Tokens
                        path,
                        user,
                        block.timestamp
                    )
                {
                    success = true;
                } catch {
                    success = false;
                }
            }

            if (!success) {
                withdrawnDividends[user] = withdrawnDividends[user].sub(
                    _withdrawableDividend
                );
                return 0;
            } else {
                emit DividendWithdrawn(user, _withdrawableDividend);
            }

            return _withdrawableDividend;
        }

        return 0;
    }
}