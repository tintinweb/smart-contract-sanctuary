// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

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
}
interface SwapFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function migrator() external view returns (address);

    function auro() external view returns (address);

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

    function setMigrator(address) external;

    function setAuroAddress(address) external;
}
interface SwapRouter01 {
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
        uint256 reserveOut,
        uint256 fee
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 fee
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(
        uint256 amountIn,
        address[] calldata path,
        uint256 fee
    ) external view returns (uint256[] memory amounts);

    function getAmountsIn(
        uint256 amountOut,
        address[] calldata path,
        uint256 fee
    ) external view returns (uint256[] memory amounts);
}
interface SwapRouter02 is SwapRouter01 {
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
library SafeMath64 {

    function tryDiv(uint64 a, uint64 b) internal pure returns (bool, uint64) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    function div(uint64 a, uint64 b, string memory errorMessage) internal pure returns (uint64) {
        require(b > 0, errorMessage);
        return a / b;
    }

}
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
abstract contract Ownable is Context {
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

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
    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
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
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

abstract contract VestController is ERC20 {
    using SafeMath64 for uint64;
    using SafeMath for uint256;
    event OwnerVestingReleased(uint64 timestamp, uint256 amount);
    uint64 public _start;
    uint64 public _duration;
    uint64 public _rate;
    uint64 public _rateTracker;
    address public _receiver;
    uint256 public _vestingReleased;
    uint256 public _vestingCount;
    uint256 public _vestAmountPerCount;
    uint256 public _totalTokensVesting;

    function _setupVesting(
        // receiver of vesting
        address receiverAddress,
        // start of vesting period
        uint64 startTimestamp,
        // how long to vest
        uint64 durationSeconds,
        // how often, 0 = anytime
        uint64 rateSeconds,
        // total of tokens to vest
        uint256 totalTokens
    ) internal {
        require(receiverAddress != address(0), "VestingController: Receiver cannot be zero address!");
        uint64 vestingCount;
        uint256 vestAmountPerCount;
        if(rateSeconds > 0){
            require(rateSeconds <= durationSeconds, "VestingController: Rate cannot be greater than duration!");
            vestingCount = durationSeconds.div(rateSeconds,'VestingController: Invalid rate & duration!');
            vestAmountPerCount = totalTokens.div(uint256(vestingCount),'VestingController: Error setting vest count!');
            _rateTracker = startTimestamp + rateSeconds;
        }
        _receiver = receiverAddress;
        _start = startTimestamp;
        _duration = durationSeconds;
        _rate = rateSeconds;
        _vestingCount = vestingCount;
        _vestAmountPerCount = vestAmountPerCount;
        _totalTokensVesting = totalTokens;
    }
    function _vestingSchedule(uint64 timestamp) internal view virtual returns (uint256) {
        // if current time before start
        if (timestamp < _start) {
            return 0;
        } 
        // if current time is past the end
        else if (timestamp > _start + _duration) {
            return _totalTokensVesting;
        }
        // current time within vesting period, calculate 
        else {
            return (_totalTokensVesting * (timestamp - _start)) / _duration;
        }
    }
    function vestedAmount(uint64 timestamp) public view virtual returns (uint256) {
        return _vestingSchedule(timestamp);
    }
    function releaseVesting() public virtual {
        require(_vestingReleased < _totalTokensVesting, "VestingController: No more tokens left to vest!");
        uint64 timestamp = uint64(block.timestamp);
        require(timestamp > _rateTracker, "VestingController: Must wait for the next vesting period!");
        uint256 releasable = vestedAmount(timestamp) - _vestingReleased;
        require(releasable > 0, "VestingController: No tokens available to vest!");
        if(_vestingCount > 0){
            releasable = _vestAmountPerCount;
            _vestingCount -= 1;
            _rateTracker += _rate;
        }
        _vestingReleased += releasable;
        emit OwnerVestingReleased(timestamp,releasable);
        _mint(_receiver,releasable);
    }
}

contract TKN is ERC20, Ownable, VestController {

    using SafeMath for uint256;

    SwapRouter02 public swapV2Router;
    address public immutable swapV2Pair;

    bool private swapping;

    address public burnAddress;

    // limits
    uint256 public maxBuyTransactionAmount;
    uint256 public maxSellTransactionAmount;
    uint256 public swapTokensAtAmount;
    // admin wallets
    address payable public teamAddress;
    // sell fees
    uint256 public sellTeamFee = 2;
    uint256 public sellLiquidityFee = 2;
    uint256 public sellBurnFee = 2;
    uint256 public sellTotalFees = sellTeamFee.add(sellLiquidityFee).add(sellBurnFee);
    // timestamp for when the token can be traded freely on PanackeSwap
    uint256 public tradingEnabledTimestamp = 1635791649;
    // blacklisted from all transfers
    mapping(address => bool) private _isBlacklisted;
    // exlcude from fees and max transaction amount
    mapping(address => bool) private _isExcludedFromFees;
    mapping (address => bool) private _isExcludedFromLimits;
    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping(address => bool) public automatedMarketMakerPairs;
    event UpdateSwapV2Router(address indexed newAddress,address indexed oldAddress);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeFromLimits(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event ExcludedMaxSellTransactionAmount(address indexed account,bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event BurnWalletUpdated(address indexed newBurnWallet,address indexed oldBurnWallet);
    event GasForProcessingUpdated(uint256 indexed newValue,uint256 indexed oldValue);
    event SwapAndLiquify(uint256 tokensSwapped,uint256 ethReceived,uint256 tokensIntoLiqudity);
    constructor(string memory tokenName_,string memory symbol_,uint8 decimals_,uint256 totalSupply_,uint64 vestDuration_,uint64 vestRate_,address swapRouter_) ERC20(tokenName_,symbol_,decimals_) {
        // vest duration - 48 months
        //uint64 _vestTime = 126227664;
        uint64 _vestDuration = vestDuration_;
        // vest rate - once a month
        //uint64 _rateTime = 2629743;
        uint64 _vestRate = vestRate_;
        // LP burn address
        burnAddress = address(0xdead);
        // limits
        maxBuyTransactionAmount = 50000000 * (10**decimals_);
        maxSellTransactionAmount = 10000000 * (10**decimals_);
        swapTokensAtAmount = 200000 * (10**decimals_);
        // dex router
        SwapRouter02 _swapV2Router = SwapRouter02(swapRouter_);
        // Create dex pair for this new token
        address _swapV2Pair = SwapFactory(_swapV2Router.factory()).createPair(address(this), _swapV2Router.WETH());
        // store data
        swapV2Router = _swapV2Router;
        swapV2Pair = _swapV2Pair;
        _setAutomatedMarketMakerPair(_swapV2Pair, true);
        // exclude from paying fees or having max transaction amount
        excludeFromFees(burnAddress, true);
        excludeFromFees(address(this), true);
        excludeFromFees(owner(), true);
        excludeFromLimits(owner(), true);
        excludeFromLimits(address(this), true);
        //mint during deployment & setup vesting
        uint256 _totalSupplyMaster = totalSupply_ * (10**decimals_);
        // if no duration for vesting mint all tokens to owner on deployment
        if(_vestDuration > 0){
            uint256 _totalSupplyDeployPercentage = 90;
            uint256 _totalSupplyDeployAmount = _totalSupplyMaster.mul(_totalSupplyDeployPercentage).div(100);
            uint256 _totalSupplyVesting = _totalSupplyMaster.sub(_totalSupplyDeployAmount);
            _mint(owner(), _totalSupplyDeployAmount);
            _setupVesting(owner(),uint64(block.timestamp),_vestDuration,_vestRate,_totalSupplyVesting);
        }else{
            _mint(owner(), _totalSupplyMaster);
        }
    }

    receive() external payable {}

    function swapAndLiquifyOwner(uint256 _tokens) external onlyOwner {
        swapAndLiquify(_tokens);
    }

    function updateMaxSellTx(uint256 newAmountWithZeros) external onlyOwner {
        maxSellTransactionAmount = newAmountWithZeros;
    }

    function updateMaxBuyTx(uint256 newAmountWithZeros) external onlyOwner {
        maxBuyTransactionAmount = newAmountWithZeros;
    }

    function updateTradingEnabledTime(uint256 newTimeInEpoch)
        external
        onlyOwner
    {
        tradingEnabledTimestamp = newTimeInEpoch;
    }

    function updateSwapAtAmount(uint256 newAmountWithZeros)
        external
        onlyOwner
    {
        swapTokensAtAmount = newAmountWithZeros;
    }

    function updateTeamAddress(address payable newAddress)
        external
        onlyOwner
    {
        teamAddress = newAddress;
        _isExcludedFromFees[newAddress] = true;
    }

    function updateSellFees(
        uint256 _teamFee,
        uint256 _liquidityFee,
        uint256 _burnFee
    ) external onlyOwner {
        sellTeamFee = _teamFee;
        sellLiquidityFee = _liquidityFee;
        sellBurnFee = _burnFee;
        sellTotalFees = _teamFee.add(_liquidityFee).add(_burnFee);
    }

    function updateSwapV2Router(address newAddress) external onlyOwner {
        require(
            newAddress != address(swapV2Router),
            "TKN: The router already has that address"
        );
        emit UpdateSwapV2Router(newAddress, address(swapV2Router));
        swapV2Router = SwapRouter02(newAddress);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }    
    
    function excludeFromLimits(address account, bool excluded) public onlyOwner {
        _isExcludedFromLimits[account] = excluded;
        emit ExcludeFromLimits(account, excluded);
    }

    function blacklistAddress(address account, bool excluded) public onlyOwner {
        _isBlacklisted[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(
        address[] calldata accounts,
        bool excluded
    ) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        external
        onlyOwner
    {
        require(
            pair != swapV2Pair,
            "TKN: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(
            automatedMarketMakerPairs[pair] != value,
            "TKN: Automated market maker pair is already set to that value"
        );
        automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function getTradingIsEnabled() public view returns (bool) {
        return block.timestamp >= tradingEnabledTimestamp;
    }

    function swapAndLiquify(uint256 tokens) private {
        // split the contract balance into halves
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);

        // capture the contract's current ETH balance before swap
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half);
        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        uint256 ethHalf = newBalance;
        uint256 tokenHalf = otherHalf;

        // add to liquidity
        addLiquidity(tokenHalf, ethHalf);
        emit SwapAndLiquify(half, ethHalf, tokenHalf);
    }

    function swapEthForTokens(
        uint256 ethAmount,
        address tokenAddress,
        address receiver
    ) private {
        // generate the uniswap pair path of weth -> token
        address[] memory path = new address[](2);
        path[0] = swapV2Router.WETH();
        path[1] = tokenAddress;

        // make the swap
        swapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: ethAmount
        }(
            0, // accept any amount of ETH
            path,
            receiver,
            block.timestamp
        );
        // flightDev - flysoloDev
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = swapV2Router.WETH();

        _approve(address(this), address(swapV2Router), tokenAmount);

        // make the swap
        swapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) internal {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(swapV2Router), tokenAmount);

        // add the liquidity
        swapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            burnAddress,
            block.timestamp
        );
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(!_isBlacklisted[from], "Transfer: Blacklisted address!");
        require(!_isBlacklisted[to], "Transfer: Blacklisted address!");
        require(from != address(0), "Transfer: Cannot transfer from the zero address!");
        require(to != address(0), "Transfer: Cannot transfer to the zero address!");
        bool tradingIsEnabled = getTradingIsEnabled();
        if (!tradingIsEnabled) {
            revert(
                "TKN: This account cannot send tokens until trading is enabled"
            );
        }

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        // buy controller
        if (
            from != owner() &&
            to != address(0) &&
            to != address(0xdead) &&
            automatedMarketMakerPairs[from]
        ) {
            if(!_isExcludedFromLimits[from]){
                require(amount <= maxBuyTransactionAmount,"Transfer: Buy amount exceeds the maxBuyTxAmount!");
            }
        }

        // sell controller
        bool sellTX;
        if (
            from != owner() &&
            !swapping &&
            tradingIsEnabled &&
            automatedMarketMakerPairs[to] && // sells only by detecting transfer to automated market maker pair
            from != address(swapV2Router) && //router -> pair is removing liquidity which shouldn't have max
            !_isExcludedFromFees[to] //no max for those excluded from fees
        ) {
            if(!_isExcludedFromLimits[from]){
                require(amount <= maxSellTransactionAmount,"Transfer: Sell amount exceeds the maxSellTxAmount!");
            }
            sellTX = true;
        }

        // swap and liquify
        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;
        if (
            tradingIsEnabled &&
            canSwap &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            from != burnAddress &&
            to != burnAddress
        ) {
            swapping = true;
            swapAndLiquify(swapTokensAtAmount);
            swapping = false;
        }

        // take fees
        bool takeFee = tradingIsEnabled && !swapping && sellTX;
        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }
        if (takeFee && sellTotalFees != 0) {

            uint256 teamAmount = amount.mul(sellTeamFee).div(100);
            uint256 liquidityAmount = amount.mul(sellLiquidityFee).div(100);
            uint256 burnAmount = amount.mul(sellBurnFee).div(100);
            if (sellBurnFee == 0) {
                amount = amount.sub(teamAmount).sub(liquidityAmount);
                super._transfer(from, teamAddress, teamAmount);
                super._transfer(from, address(this), liquidityAmount);
            }else if(sellLiquidityFee == 0){
                amount = amount.sub(teamAmount).sub(burnAmount);
                super._transfer(from, teamAddress, teamAmount);
                super._transfer(from, burnAddress, burnAmount);
            }else if(sellTeamFee == 0){
                amount = amount.sub(liquidityAmount).sub(burnAmount);
                super._transfer(from, address(this), liquidityAmount);
                super._transfer(from, burnAddress, burnAmount);
            }else {
                amount = amount.sub(teamAmount).sub(liquidityAmount).sub(burnAmount);
                super._transfer(from, address(this), liquidityAmount);
                super._transfer(from, teamAddress, teamAmount);
                super._transfer(from, burnAddress, burnAmount);
            }

        }
        super._transfer(from, to, amount);
    }
    // flightDev - flysoloDev
}