/**
 *Submitted for verification at BscScan.com on 2022-01-21
*/

// SPDX-License-Identifier: MIT License
pragma solidity ^0.6.2;

abstract contract Context {

    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}
interface IERC20Metadata is IERC20 {
   
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}
contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}
library SafeMath {
 
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

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

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
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
library IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint) values;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) public view returns (uint) {
        return map.values[key];
    }

    function getIndexOfKey(Map storage map, address key) public view returns (int) {
        if(!map.inserted[key]) {
            return -1;
        }
        return int(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint index) public view returns (address) {
        return map.keys[index];
    }



    function size(Map storage map) public view returns (uint) {
        return map.keys.length;
    }

    function set(Map storage map, address key, uint val) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }
    
    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint index = map.indexOf[key];
        uint lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];
        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     * 初始化契约，将部署人员设置为初始所有者
     */
    constructor () public {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     * 返回当前所有者的地址。
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
/// @title Dividend-Paying Token Interface
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev An interface for a dividend-paying token contract.
interface DividendPayingTokenInterface {
    /// @notice View the amount of dividend in wei that an address can withdraw.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` can withdraw.
    function dividendOf(address _owner) external view returns(uint256);
    /// @notice Withdraws the ether distributed to the sender.
    /// @dev SHOULD transfer `dividendOf(msg.sender)` wei to `msg.sender`, and `dividendOf(msg.sender)` SHOULD be 0 after the transfer.
    ///  MUST emit a `DividendWithdrawn` event if the amount of ether transferred is greater than 0.
    function withdrawDividend() external;

    /// @dev This event MUST emit when ether is distributed to token holders.
    /// @param from The address which sends ether to this contract.
    /// @param weiAmount The amount of distributed ether in wei.
    event DividendsDistributed(
        address indexed from,
        uint256 weiAmount
    );

    /// @dev This event MUST emit when an address withdraws their dividend.
    /// @param to The address which withdraws ether from this contract.
    /// @param weiAmount The amount of withdrawn ether in wei.
    event DividendWithdrawn(
        address indexed to,
        uint256 weiAmount
    );
}
/// @title Dividend-Paying Token Optional Interface
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev OPTIONAL functions for a dividend-paying token contract.
interface DividendPayingTokenOptionalInterface {
    /// @notice View the amount of dividend in wei that an address can withdraw.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` can withdraw.
    function withdrawableDividendOf(address _owner) external view returns(uint256);

    /// @notice View the amount of dividend in wei that an address has withdrawn.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` has withdrawn.
    function withdrawnDividendOf(address _owner) external view returns(uint256);

    /// @notice View the amount of dividend in wei that an address has earned in total.
    /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` has earned in total.
    function accumulativeDividendOf(address _owner) external view returns(uint256);
}
contract DividendPayingToken is ERC20, Ownable, DividendPayingTokenInterface, DividendPayingTokenOptionalInterface {
    using SafeMath for uint256;
    using SafeMathUint for uint256;
    using SafeMathInt for int256;

    // With `magnitude`, we can properly distribute dividends even if the amount of received ether is small.
    // For more discussion about choosing the value of `magnitude`,
    //  see https://github.com/ethereum/EIPs/issues/1726#issuecomment-472352728
    uint256 constant internal magnitude = 2**128;

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

    constructor(string memory _name, string memory _symbol) public ERC20(_name, _symbol) {

    }

    receive() external payable {
        distributeBNBDividends();
    }


    function distributeBNBDividends() public payable {
        require(totalSupply() > 0);

        if (msg.value > 0) {
            magnifiedDividendPerShare = magnifiedDividendPerShare.add(
                (msg.value).mul(magnitude) / totalSupply()
            );
            emit DividendsDistributed(msg.sender, msg.value);

            totalDividendsDistributed = totalDividendsDistributed.add(msg.value);
        }
    }

    /// @notice Withdraws the ether distributed to the sender.
    /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
    function withdrawDividend() public virtual override {
        _withdrawDividendOfUser(msg.sender);
    }

    /// @notice Withdraws the ether distributed to the sender.
    /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
    function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
        uint256 _withdrawableDividend = withdrawableDividendOf(user);
        if (_withdrawableDividend > 0) {
            withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
            emit DividendWithdrawn(user, _withdrawableDividend);

            (bool success, ) = address(user).call{value: _withdrawableDividend}("");

            if(!success) {
                withdrawnDividends[user] = withdrawnDividends[user].sub(_withdrawableDividend);
                return 0;
            }

            return _withdrawableDividend;
        }

        return 0;
    }


    /// @notice View the amount of dividend in wei that an address can withdraw.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` can withdraw.
    function dividendOf(address _owner) public view override returns(uint256) {
        return withdrawableDividendOf(_owner);
    }

    /// @notice View the amount of dividend in wei that an address can withdraw.  查看一个地址可以收回分红的数量。
    /// @param _owner The address of a token holder.                         //这个币持有者的地址             
    /// @return The amount of dividend in wei that `_owner` can withdraw.          返回持有者分红撤回的数量
    function withdrawableDividendOf(address _owner) public view override returns(uint256) {
        return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);        //持有者的总分红-要撤回的分红
    }

    /// @notice View the amount of dividend in wei that an address has withdrawn.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` has withdrawn.
    function withdrawnDividendOf(address _owner) public view override returns(uint256) {
        return withdrawnDividends[_owner];
    }


    /// @notice View the amount of dividend in wei that an address has earned in total.            查看一个地址累计获得的分红数量。
    /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)            
    /// = (magnifiedDividendPerShare * balanceOf(_owner) + magnifiedDividendCorrections[_owner]) / magnitude
    /// @param _owner The address of a token holder.                                          //币拥有者的地址
    /// @return The amount of dividend in wei that `_owner` has earned in total.                   //返回持有者总分红数量
    function accumulativeDividendOf(address _owner) public view override returns(uint256) {
        return magnifiedDividendPerShare.mul(balanceOf(_owner)).toInt256Safe()                         
        .add(magnifiedDividendCorrections[_owner]).toUint256Safe() / magnitude;
    }

    /// @dev Internal function that transfer tokens from one address to another.
    /// Update magnifiedDividendCorrections to keep dividends unchanged.
    /// @param from The address to transfer from.
    /// @param to The address to transfer to.
    /// @param value The amount to be transferred.
    function _transfer(address from, address to, uint256 value) internal virtual override {
        require(false);

        int256 _magCorrection = magnifiedDividendPerShare.mul(value).toInt256Safe();
        magnifiedDividendCorrections[from] = magnifiedDividendCorrections[from].add(_magCorrection);
        magnifiedDividendCorrections[to] = magnifiedDividendCorrections[to].sub(_magCorrection);
    }

    /// @dev Internal function that mints tokens to an account.
    /// Update magnifiedDividendCorrections to keep dividends unchanged.
    /// @param account The account that will receive the created tokens.
    /// @param value The amount that will be created.
    function _mint(address account, uint256 value) internal override {
        super._mint(account, value);

        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
        .sub( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
    }

    /// @dev Internal function that burns an amount of the token of a given account.
    /// Update magnifiedDividendCorrections to keep dividends unchanged.
    /// @param account The account whose tokens will be burnt.
    /// @param value The amount that will be burnt.
    //内部函数，用于烧录给定帐户的一定数量的令牌
    //更新magnieddividendcorrections以保持股息不变。
    //account账号的的币将会被销毁
    //value是销毁的数量
    function _burn(address account, uint256 value) internal override {
        super._burn(account, value);

        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
        .add( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
    }
    //设置余额
    function _setBalance(address account, uint256 newBalance) internal {
        uint256 currentBalance = balanceOf(account);   //返回目前的余额
        if(newBalance > currentBalance) {      
            uint256 mintAmount = newBalance.sub(currentBalance);          //铸币数量=新余额-旧余额
            _mint(account, mintAmount);                                //给该账号铸mintAmount个币
        } else if(newBalance < currentBalance) {                
            uint256 burnAmount = currentBalance.sub(newBalance);     //销毁数量=旧-新余额
            _burn(account, burnAmount);                           //销毁代币
        }
    }
}
contract DividendTracker is Ownable, DividendPayingToken {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping(address => bool) public excludedFromDividends;

    mapping(address => uint256) public lastClaimTimes;

    uint256 public claimWait;
    uint256 public immutable minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor() public DividendPayingToken("RedCheCoin_Dividend_Tracker", "RedCheCoin_Dividend_Tracker") {
        claimWait = 1200;
        minimumTokenBalanceForDividends = 10000 * (10 ** 18);
        //must hold 10000+ tokens
    }

    function _transfer(address, address, uint256) internal override {
        require(false, "RedCheCoin_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() public override {
        require(false, "RedCheCoin_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main RedCheCoin contract.");
    }
    //此函数用于account形参地址不在分红内
    function excludeFromDividends(address account) external onlyOwner {
        //false就执行，否则退出此函数，主要检测有没有执行过此函数
        require(!excludedFromDividends[account]);
        excludedFromDividends[account] = true;      //设置分红账号为true
        _setBalance(account, 0);                    //设置目前的余额
        tokenHoldersMap.remove(account);             

        emit ExcludeFromDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait != claimWait, "RedCheCoin_Dividend_Tracker: Cannot update claimWait to same value");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }

    function getLastProcessedIndex() external view returns (uint256) {
        return lastProcessedIndex;
    }

    function getNumberOfTokenHolders() external view returns (uint256) {
        return tokenHoldersMap.keys.length;
    }


    function getAccount(address _account)
    public view returns (
        address account,
        int256 index,
        int256 iterationsUntilProcessed,
        uint256 withdrawableDividends,
        uint256 totalDividends,
        uint256 lastClaimTime,
        uint256 nextClaimTime,
        uint256 secondsUntilAutoClaimAvailable) {
        account = _account;

        index = tokenHoldersMap.getIndexOfKey(account);

        iterationsUntilProcessed = - 1;

        if (index >= 0) {
            if (uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
            }
            else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ?
                tokenHoldersMap.keys.length.sub(lastProcessedIndex) :
                0;


                iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
            }
        }


        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);

        lastClaimTime = lastClaimTimes[account];

        nextClaimTime = lastClaimTime > 0 ?
        lastClaimTime.add(claimWait) :
        0;

        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ?
        nextClaimTime.sub(block.timestamp) :
        0;
    }

    function getAccountAtIndex(uint256 index)
    public view returns (
        address,
        int256,
        int256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256) {
        if (index >= tokenHoldersMap.size()) {
            return (0x0000000000000000000000000000000000000000, - 1, - 1, 0, 0, 0, 0, 0);
        }

        address account = tokenHoldersMap.getKeyAtIndex(index);

        return getAccount(account);
    }

    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
        if (lastClaimTime > block.timestamp) {
            return false;
        }

        return block.timestamp.sub(lastClaimTime) >= claimWait;
    }

    function setBalance(address payable account, uint256 newBalance) external onlyOwner {
        if (excludedFromDividends[account]) {
            return;
        }

        if (newBalance >= minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance);
            tokenHoldersMap.set(account, newBalance);
        }
        else {
            _setBalance(account, 0);
            tokenHoldersMap.remove(account);
        }

        processAccount(account, true);
    }

    function process(uint256 gas) public returns (uint256, uint256, uint256) {
        uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

        if (numberOfTokenHolders == 0) {
            return (0, 0, lastProcessedIndex);
        }

        uint256 _lastProcessedIndex = lastProcessedIndex;

        uint256 gasUsed = 0;

        uint256 gasLeft = gasleft();

        uint256 iterations = 0;
        uint256 claims = 0;

        while (gasUsed < gas && iterations < numberOfTokenHolders) {
            _lastProcessedIndex++;

            if (_lastProcessedIndex >= tokenHoldersMap.keys.length) {
                _lastProcessedIndex = 0;
            }

            address account = tokenHoldersMap.keys[_lastProcessedIndex];

            if (canAutoClaim(lastClaimTimes[account])) {
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

    function processAccount(address payable account, bool automatic) public onlyOwner returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);

        if (amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, automatic);
            return true;
        }

        return false;
    }
}

contract Token is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public immutable uniswapV2Pair;
    bool private swapping;
    bool public swapEnabled = true;
    DividendTracker public dividendTracker;          //分红对象
    address public liquidityWallet;          //流动性钱包
    address private _marketingWalletAddress;         //营销钱包，收手续费的
    address public deadWallet = 0x000000000000000000000000000000000000dEaD;        //销毁钱包，也就是把钱打进这里。
    uint256 public maxSellTransactionAmount = 10000000000000 * (10 ** 16);              //最大卖出数量
    uint256 public swapTokensAtAmount = 1000000000 * (10 ** 18);                      
    uint256  BNBRewardsFee = 3;                                                     //分红每次交易百分之7的bnb
    uint256  liquidityFee = 2;                                                      //流动性手续费
    uint256  marketingFee = 5;                                                       //营销钱包收进的手续费

    uint256 public totalFees = BNBRewardsFee.add(liquidityFee).add(marketingFee);               //总手续费用
    uint256 public tradingEnabledTimestamp = 1628258400; //10:00pm                     //2021-08-06 22:00:00的时间戳          

    // sells have fees of 12 and 6 (10 * 1.2 and 5 * 1.2)           
    uint256 public immutable sellFeeIncreaseFactor = 120;

    // use by default 300,000 gas to process auto-claiming dividends
    //默认使用300000 gas 处理自动申请分红
    uint256 public gasForProcessing = 800000;

    mapping(address => bool) private _isExcludedFromFees;          //判断是否此账号需要手续费，true为不需要手续费
    mapping(address => bool) public automatedMarketMakerPairs;        //判断是否卖出
    mapping(address => bool) public _isBlacklisted;    //是否是黑名单,true表示这个地址是黑名单

    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);     //监听更新分红跟踪事件

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);            //监听更新周边路由事件

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);

    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event SendDividends(
        uint256 tokensSwapped,
        uint256 amount
    );

    event ProcessedDividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        uint256 gas,
        address indexed processor
    );

    constructor(address _ma) public ERC20("man", "man") {

        dividendTracker = new DividendTracker();   

        liquidityWallet = owner();          //流动性钱包=msg.sender.也就是部署这个合约的钱包
        _marketingWalletAddress = _ma;          //营销钱包=_ma
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);  //构造测试网的_uniswapV2Router对象
        // Create a uniswap pair for this new token
        //为这个新币创建一个uniswap pair  也就是uniswap的核心合约
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())     //factory 返回地址也就是0x9Ac64那个
        .createPair(address(this), _uniswapV2Router.WETH());   //createPair创建交易对 .该函数接受任意两个代币地址为参数，用来创建一个新的交易对合约并返回新合约的地址。
        //createPair的第一个地址是这个合约的地址，第二个地址是0x9Ac64Cc6e地址
        uniswapV2Router = _uniswapV2Router;     
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        // exclude from receiving dividends  不在分红范围内的
        dividendTracker.excludeFromDividends(address(dividendTracker));            
        dividendTracker.excludeFromDividends(address(this));                 //这个合约地址
        dividendTracker.excludeFromDividends(owner());                        //msg.sender地址,也就铸币接收者
        dividendTracker.excludeFromDividends(deadWallet);                     //销毁地址
        dividendTracker.excludeFromDividends(address(_uniswapV2Router));

        // exclude from paying fees or having max transaction amount 排除支付费用或拥有最大交易金额
        excludeFromFees(liquidityWallet, true);        //排除流动性钱包的支付手续费和最大交易金额
        excludeFromFees(address(this), true);              //排除铸币钱包的支付手续费和最大交易金额
        excludeFromFees(_marketingWalletAddress, true);      //排除营销钱包的支付手续费和最大交易金额

        _mint(owner(), 10000000000000 * (10 ** 18));            //铸币给msg.ssender于10000000000000个币；
    }                  
    //外部合约调用接收方法
    receive() external payable {

    }
    //改变最大卖出额度
    function changeMaxSellTransactionAmount(uint amount) external onlyOwner {
        maxSellTransactionAmount = amount;
    }
    //更新分红合约对象
    function updateDividendTracker(address newAddress) public onlyOwner {
        //如果新地址==adaddress(ddividendTracker)则跳出函数
        require(newAddress != address(dividendTracker), "RedCheCoin The dividend tracker already has that address");
        
        DividendTracker newDividendTracker = DividendTracker(payable(newAddress));

        require(newDividendTracker.owner() == address(this), "RedCheCoin The new dividend tracker must be owned by the RedCheCoin token contract");

        newDividendTracker.excludeFromDividends(address(newDividendTracker));       //newDividendTracker地址不分红
        newDividendTracker.excludeFromDividends(address(this));                    //这个合约地址不分红
        newDividendTracker.excludeFromDividends(owner());                           //msg.sender地址
        newDividendTracker.excludeFromDividends(address(uniswapV2Router));          //代币对地址

        emit UpdateDividendTracker(newAddress, address(dividendTracker));   

        dividendTracker = newDividendTracker;                     
    }
    //更新周边路由事件
    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "RedCheCoin The router already has that address");  //如果新的地址是原来的周边路由地址则跳出
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));         
        uniswapV2Router = IUniswapV2Router02(newAddress);      //把新的周边路由地址赋值给旧的
    }
    //排除手续费
    function excludeFromFees(address account, bool excluded) public onlyOwner {   //onlyOwner判断是不是msg.sender
        require(_isExcludedFromFees[account] != excluded, "RedCheCoin Account is already the value of 'excluded'");   //如果已经排除就跳出
        _isExcludedFromFees[account] = excluded;                 //设置是否排除的布尔值

        emit ExcludeFromFees(account, excluded);
    }
    //排除多个地址账号的手续费
    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }
    //设置lp流动性地址
    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "RedCheCoin The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");
        
        _setAutomatedMarketMakerPair(pair, value);
    }
    //设置黑名单地址
    function blacklistAddress(address account, bool value) external onlyOwner {
        _isBlacklisted[account] = value;   //如果是true就是黑名单
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        //做一个判断如果已经赋了布尔值就跳出函数
        require(automatedMarketMakerPairs[pair] != value, "RedCheCoin Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;     
        if (value) {
            dividendTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    //更新流动池钱包
    function updateLiquidityWallet(address newLiquidityWallet) public onlyOwner {
        require(newLiquidityWallet != liquidityWallet, "RedCheCoin The liquidity wallet is already this address");
        _isExcludedFromFees[newLiquidityWallet] = true;          //设置新的流动池钱包
        emit LiquidityWalletUpdated(newLiquidityWallet, liquidityWallet);        
        liquidityWallet = newLiquidityWallet;          //旧流动池钱包=新流动池钱包             
    }
    //更新营销钱包
    function updateMarketingWallet(address newMarkting) public onlyOwner {
        require(newMarkting != _marketingWalletAddress, "RedCheCoin The Markting wallet is already this address");  //如果新营销钱包=旧营销钱包则跳出
        _isExcludedFromFees[newMarkting] = true;                                                    //设置新营销钱包除外手续费
        _marketingWalletAddress = newMarkting;                                                       //旧营销钱包=新营销钱包
    }
    //更新gas费用
    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 500000, "RedCheCoin gasForProcessing must be between 200,000 and 500,000");    //非200000到500000则跳出
        require(newValue != gasForProcessing, "RedCheCoin Cannot update gasForProcessing to same value");       //如果和旧的值一样就跳出
        emit GasForProcessingUpdated(newValue, gasForProcessing);   
        gasForProcessing = newValue;                                      //旧的gas=新的gas
    }
    
    function updateClaimWait(uint256 claimWait) external onlyOwner {
        dividendTracker.updateClaimWait(claimWait);
    }

    function getClaimWait() external view returns (uint256) {
        return dividendTracker.claimWait();
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }
    //block.timestamp (uint):当前块的时间戳
    //此函数通过到达开盘时间才能交易
    function getTradingIsEnabled() public view returns (bool) {
        return block.timestamp >= tradingEnabledTimestamp;
    }
    //返回是否除外手续费的布尔值
    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }
    //应该是取回分红？？？
    function withdrawableDividendOf(address account) public view returns (uint256) {
        return dividendTracker.withdrawableDividendOf(account);
    }
    //取的分红的地址
    function dividendTokenBalanceOf(address account) public view returns (uint256) {
        return dividendTracker.balanceOf(account);
    }
    
    function getAccountDividendsInfo(address account)
    external view returns (
        address,
        int256,
        int256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256) {
        return dividendTracker.getAccount(account);
    }

    function getAccountDividendsInfoAtIndex(uint256 index)
    external view returns (
        address,
        int256,
        int256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256) {
        return dividendTracker.getAccountAtIndex(index);
    }

    function processDividendTracker(uint256 gas) external {
        (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = dividendTracker.process(gas);
        emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, false, gas, tx.origin);
    }

    function claim() external {
        dividendTracker.processAccount(msg.sender, false);
    }

    function getLastProcessedIndex() external view returns (uint256) {
        return dividendTracker.getLastProcessedIndex();
    }

    function getNumberOfDividendTokenHolders() external view returns (uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }
    //交易函数
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");    //如果发送方是空地址则跳出
        require(!_isBlacklisted[from], 'Blacklisted address');                        //如果接收方是空地址则跳出


        if (amount == 0) {                              //转0个币则直接转
            super._transfer(from, to, 0);
            return;
        }

        if (swapping) {
            super._transfer(from, to, amount);
            return;
        }

        bool isMng = _isExcludedFromFees[from] || _isExcludedFromFees[to];      //判断是否非手续费
        bool tradingIsEnabled = getTradingIsEnabled();               //判断是到开盘时间，true表示到了          

        // add liqiud
        if (!tradingIsEnabled) {                  //判断是否到开盘时间
            require(isMng, "This account cannot send tokens until trading is enabled");   //判断是否添加流动池账号，如果不是则跳出此函数
        }

        if (
            tradingIsEnabled &&                  //到达开盘时间
            balanceOf(uniswapV2Pair) > 0 &&                 //流动池大于0
            automatedMarketMakerPairs[from] &&         //li流动性可用          
            !isMng &&                           //是否排除手续费
            tradingIsEnabled &&                         
            block.timestamp <= tradingEnabledTimestamp + 9 seconds) {  //当前块的时间戳小于等于 可交易时间戳+9秒。如果是在9秒内抢到
            addBot(to);                                 //则添加黑名单
        }

        if (
            !swapping &&                        
        from != address(uniswapV2Router) &&
        to != address(uniswapV2Router) &&
        !isMng
        ) {
            require(amount <= maxSellTransactionAmount, "Sell transfer amount exceeds the maxSellTransactionAmount.");  //判断是否超出最大可卖出数量
        }

        uint256 contractTokenBalance = balanceOf(address(this));          //获得该代币余额

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;        //是否可以交易

        if (
            swapEnabled &&
            canSwap &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            from != liquidityWallet &&
            to != liquidityWallet
        ) {
            swapping = true;

            uint256 marketingTokens = contractTokenBalance.mul(marketingFee).div(totalFees);    //营销钱包的币=该合约代币余额*营销手续费/总手续费
            swapAndSendToFee(marketingTokens);                                          //发送给营销钱包手续费用的币

            uint256 swapTokens = contractTokenBalance.mul(liquidityFee).div(totalFees);               //添加流动性的币=该合约代币余额*流动性手续费/总手续费
            swapAndLiquify(swapTokens);                                    //添加流动性

            uint256 sellTokens = balanceOf(address(this));                                //卖的币=该合约代币余额
            swapAndSendDividends(sellTokens);                                           //分红卖的币
            swapping = false;
        }


        bool takeFee = !swapping;                   

        // if any account belongs to _isExcludedFromFee account then remove the fee 如果任何帐户属于_isExcludedFromFee帐户，那么删除费用
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;                                   //设置无手续费
        }

        if (takeFee) {
            uint256 fees = amount.mul(totalFees).div(100);           //手续费=币数量*总手续费/100;

            // if sell, multiply by 1.2
            if (automatedMarketMakerPairs[to]) {
                fees = fees.mul(sellFeeIncreaseFactor).div(100);            //如果卖出的话手续费*1.2
            }

            amount = amount.sub(fees);             //币数量=币数量-手续费

            super._transfer(from, address(this), fees);            //转账msg.sender到合约地址，手续费用的币
        }

        super._transfer(from, to, amount);                  //转账实际已经扣除手续的币

        try dividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

        if (!swapping) {
            uint256 gas = gasForProcessing;       

            try dividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
            }
            catch {
            }
        }
    }
    //设置是否可交易
    function setSwapEnabled(bool _enabled) external onlyOwner {
        swapEnabled = _enabled;
    }
    //设置手续费用
    function setF(uint _BNBRewardsFee, uint _liquidityFee, uint _marketingFee) external onlyOwner {
        BNBRewardsFee = _BNBRewardsFee;
        liquidityFee = _liquidityFee;
        marketingFee = _marketingFee;
    }
    //添加黑名单的函数
    function addBot(address recipient) private {
        if (!_isBlacklisted[recipient]) _isBlacklisted[recipient] = true;
    }
    //发送给营销钱包手续费用
    function swapAndSendToFee(uint256 tokens) private {
        uint256 initialBNBBalance = address(this).balance;
        swapTokensForEth(tokens);   
        uint256 newBalance = address(this).balance.sub(initialBNBBalance);
        payable(_marketingWalletAddress).transfer(newBalance);
    }
    //交易流动性
    function swapAndLiquify(uint256 tokens) private {
        // split the contract balance into halves 把该合同余额平分，分成一半
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);

        // capture the contract's current ETH balance.   获取合同当前ETH余额。
        // this is so that we can capture exactly the amount of ETH that the   这样我们就能准确地捕获ETH的数量
        // swap creates, and not make the liquidity event include any ETH that    交换产生，而不使流动性事件包括任何ETH
        // has been manually sent to the contract    手动发送给合约地址
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH  ETH交换代币
        swapTokensForEth(half);
        // <- this breaks the ETH -> HATE swap when swap+liquify is triggered  当swap+liquify被触发时，这会打破ETH ->HATE swap

        // how much ETH did we just swap into?   我们刚才换了多少ETH ?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap      为uniswap增加流动性
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }
    //交换代币
    function swapTokensForEth(uint256 tokenAmount) private {


        // generate the uniswap pair path of token -> weth  生成unswap pair周边合约代币路径 -> 用eth位来表示
        address[] memory path = new address[](2);   
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);    

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );

    }
    //添加流动性
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {

        // approve token transfer to cover all possible scenarios      批准代币转账以覆盖所有可能的场景
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity           添加流动性
        uniswapV2Router.addLiquidityETH{value : ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable     //滑点是不可避免的
            0, // slippage is unavoidable   //滑点是不可避免的
            liquidityWallet,                     //流动性钱包;
            block.timestamp                  //当块的时间戳
        );

    }
    //交易分红
    function swapAndSendDividends(uint256 tokens) private {
        swapTokensForEth(tokens);
        uint256 dividends = address(this).balance;
        (bool success,) = address(dividendTracker).call{value : dividends}("");

        if (success) {
            emit SendDividends(tokens, dividends);
        }
    }
}