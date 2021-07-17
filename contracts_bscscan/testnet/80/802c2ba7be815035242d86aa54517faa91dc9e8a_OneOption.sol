/**
 *Submitted for verification at BscScan.com on 2021-07-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor (address initialOwner) {
        _owner = initialOwner;
        emit OwnershipTransferred(address(0), initialOwner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is still locked");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
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


contract OneOption is Context, IBEP20, Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => uint256) private _aOwned;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public _isExcludedFromAutoLiquidity;

    address[] private _excluded;

    address private _burnWallet = 0x000000000000000000000000000000000000dEaD;

    string private     _name = "TEST0907";
    string private   _symbol = "TEST";
    uint8 private  _decimals = 9;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1000000000000000 * 10 ** _decimals;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    bool public _locked = true;
    uint256 public _devUnlockTime;

    uint256 public          _taxFee = 15;
    uint256 private _previousTaxFee = _taxFee;

    uint256 public          _liquidityFee = 25;
    uint256 private _previousLiquidityFee = _liquidityFee;

    uint256 public          _burnFee = 10;
    uint256 private _previousBurnFee = _burnFee;

    address private _teamWallet = 0xA99fD619Bf98313C03E3B401B58Df06d361E1B8a;

    address private _devWallet = 0x065C468d044C38Ae32089458112d7Ec7bED038bd;

    address private _airdropWallet = 0x72dB0c30F9FBbE76EcEc1E83010193857C931705;

    uint256 private numTokensSellToAddToLiquidity = 5000000000 * 10 **_decimals;

    // auto liquidity
    IUniswapV2Router02 public uniswapV2Router;
    address            public uniswapV2Pair;
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor (address cOwner) Ownable(cOwner) {
        emit Transfer(address(0), address(this), _tTotal);
        uint256 currentRate = _getRate();
        uint256 tBurn = 400000000000000 * 10 ** _decimals;
        uint256 rBurn = tBurn.mul(currentRate);
        _isExcluded[_burnWallet] = true;
        _rOwned[_teamWallet] = (50000000000000 * 10 ** _decimals).mul(currentRate);
        _rOwned[_devWallet] = (30000000000000 * 10 ** _decimals).mul(currentRate);
        _rOwned[_airdropWallet] = (20000000000000 * 10 ** _decimals).mul(currentRate);
        _reflectBurn(rBurn, tBurn, address(this));

        _rOwned[cOwner] = _rTotal.sub(_rOwned[_teamWallet]).sub(_rOwned[_devWallet]).sub(_rOwned[_airdropWallet]).sub(rBurn);
        _devUnlockTime = block.timestamp + (365 * 24 * 60 * 60);
        // uniswap
        //IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;

        // exclude system contracts
        _isExcludedFromFee[owner()]       = true;
        _isExcludedFromFee[_burnWallet]       = true;
        _isExcludedFromFee[_teamWallet]       = true;
        _isExcludedFromFee[_devWallet]       = true;
        _isExcludedFromFee[_airdropWallet]       = true;
        _isExcludedFromFee[address(this)] = true;

        _isExcludedFromAutoLiquidity[uniswapV2Pair]            = true;
        _isExcludedFromAutoLiquidity[address(uniswapV2Router)] = true;
        _isExcludedFromAutoLiquidity[_teamWallet] = true;
        _isExcludedFromAutoLiquidity[_devWallet] = true;
        _isExcludedFromAutoLiquidity[_airdropWallet] = true;
        _isExcludedFromAutoLiquidity[_burnWallet] = true;


        emit Transfer(address(this), _teamWallet, _rOwned[_teamWallet].div(currentRate));
        emit Transfer(address(this), _devWallet, _rOwned[_devWallet].div(currentRate));
        emit Transfer(address(this), _airdropWallet, _rOwned[_airdropWallet].div(currentRate));
        emit Transfer(address(this), cOwner, _rOwned[cOwner].div(currentRate));
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }



    function getAvailable(address account) internal view returns (uint256) {
        uint256 available;
        if (_isExcluded[account]) {
            available = _tOwned[account];
        } else {
            available = tokenFromReflection(_rOwned[account]);
        }
        if (!_locked) {
            return available;
        } else {
            return available.sub(_aOwned[account]);
        }

    }



    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function reflectionFromToken(uint256 tAmount) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        uint256 currentRate = _getRate();
        return tAmount.mul(currentRate);
    }


    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");

        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");

        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner {
        require(_isExcluded[account], "Account is already excluded");
        require(account != _burnWallet, "Burn Address cannot be included in reward distribution.");

        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        require(account != _burnWallet, "Burn Address cannot be included in fee.");
        _isExcludedFromFee[account] = false;
    }


    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    receive() external payable {}

    function setUniswapRouter(address r) external onlyOwner {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(r);
        uniswapV2Router = _uniswapV2Router;
    }

    function setUniswapPair(address p) external onlyOwner {
        uniswapV2Pair = p;
    }

    function setExcludedFromAutoLiquidity(address a, bool b) external onlyOwner {
        if (a == _burnWallet) {
            require(b == true, "Burn Address cannot be included in autoliquidity.");
        }
        _isExcludedFromAutoLiquidity[a] = b;
    }


    function setMinAutoLiquidityAmount(uint256 _amount) external onlyOwner {
        require(_amount <= _tTotal, "Amount cannot exceed total token circulation.");
        require(_amount > 0, "Amount cannot have zero value");
        numTokensSellToAddToLiquidity = _amount;

    }

    function lockAirdrop() external onlyOwner {
        require(!_locked, "Airdrop is already locked");
        _locked = true;
    }


    function unlockAirdrop() external onlyOwner {
        require(_locked, "Airdrop is already unlocked");
        _locked = false;
    }


    function _takeLiquidity(uint256 tLiquidity, address account) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);

        // liquidity to contract
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if (_isExcluded[address(this)]) {
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
        }
        emit Transfer(account, address(this), tLiquidity);

    }


    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal    = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }


    function _reflectBurn(uint256 rBurn, uint256 tBurn, address account) private {
        _rOwned[_burnWallet] = _rOwned[_burnWallet].add(rBurn);
        if (_isExcluded[_burnWallet]) {
            _tOwned[_burnWallet] = _tOwned[_burnWallet].add(tBurn);
        }

        emit Transfer(account, _burnWallet, tBurn);
    }


    function _reflectAirdrop(uint256 tAmount, address account) private {
        if (_aOwned[account] > 0) {
            if (tAmount <= _aOwned[account]) {
                _aOwned[account] = _aOwned[account].sub(tAmount);
            } else {
                _aOwned[account] = 0;
            }
        }
    }



    function _getValues(uint256 tAmount) private view returns
        (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256)
    {
        uint256 currentRate = _getRate();

        uint256[4] memory tvalues;
        uint256[5] memory rvalues;

        tvalues[0] = calculateTaxFee(tAmount);
        tvalues[1] = calculateLiquidityFee(tAmount);
        tvalues[2] = calculateBurnFee(tAmount);
        tvalues[3] = tAmount.sub(tvalues[0].add(tvalues[1]).add(tvalues[2]));
        rvalues[0] = tvalues[0].mul(currentRate);
        rvalues[1] = tvalues[1].mul(currentRate);
        rvalues[2] = tvalues[2].mul(currentRate);
        rvalues[3] = tAmount.mul(currentRate);
        rvalues[4] = rvalues[3].sub(rvalues[0]).sub(rvalues[1]).sub(rvalues[2]);
        return (rvalues[3], rvalues[4], rvalues[0], rvalues[2], tvalues[3], tvalues[0], tvalues[2], tvalues[1]);
    }


    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }



    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(1000);
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee).div(1000);
    }


    function calculateBurnFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_burnFee).div(1000);
    }


    function removeAllFee() private {
        if (_taxFee == 0 && _liquidityFee == 0 && _burnFee == 0) return;

        _previousTaxFee       = _taxFee;
        _previousLiquidityFee = _liquidityFee;
        _previousBurnFee       = _burnFee;

        _taxFee       = 0;
        _liquidityFee = 0;
        _burnFee       = 0;


    }

    function restoreAllFee() private {
        _taxFee       = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
        _burnFee       = _previousBurnFee;


    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require (amount <= getAvailable(from), "Insufficient balance");
        if (from == _devWallet) {
            require(block.timestamp > _devUnlockTime, "Developer's wallet is locked for 1 year.");
        }

        /*
            - swapAndLiquify will be initiated when token balance of this contract
            has accumulated enough over the minimum number of tokens required.
            - don't get caught in a circular liquidity event.
            - don't swapAndLiquify if sender is uniswap pair.
        */
        uint256 contractTokenBalance = balanceOf(address(this));

        bool isOverMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        if (
            isOverMinTokenBalance &&
            !inSwapAndLiquify &&
            !_isExcludedFromAutoLiquidity[from] &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity;
            swapAndLiquify(contractTokenBalance);
        }


        bool takeFee = true;
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }
        _tokenTransfer(from, to, amount, takeFee);


        /*
            anti whale: when buying, check if sender balance will be greater than 1% of total supply
            if greater, throw error
        */

    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split contract balance into halves
        uint256 half      = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        /*
            capture the contract's current BNB balance.
            this is so that we can capture exactly the amount of BNB that
            the swap creates, and not make the liquidity event include any BNB
            that has been manually sent to the contract.
        */
        uint256 initialBalance = address(this).balance;

        // swap tokens for BNB
        swapTokensForBnb(half);

        // this is the amount of BNB that we just swapped into
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForBnb(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }


    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        if (!takeFee) {
            removeAllFee();
        }

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);

        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);

        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);

        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);

        } else {
            _transferStandard(sender, recipient, amount);
        }

        if (!takeFee) {
            restoreAllFee();
        }
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 rBurn,
         uint256 tTransferAmount, uint256 tFee, uint256 tBurn, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender]    = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        if (!_locked) {
            _reflectAirdrop(tAmount, sender);
        }

        if (tLiquidity > 0) {
            _takeLiquidity(tLiquidity, sender);
        }


        if (tFee > 0) {
            _reflectFee(rFee, tFee);
        }

        if (tBurn > 0) {
            _reflectBurn(rBurn, tBurn, sender);
        }

        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 rBurn,
         uint256 tTransferAmount, uint256 tFee, uint256 tBurn, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        if (!_locked) {
            _reflectAirdrop(tAmount, sender);
        }


        if (tLiquidity > 0) {
            _takeLiquidity(tLiquidity, sender);
        }


        if (tFee > 0) {
            _reflectFee(rFee, tFee);
        }

        if (tBurn > 0) {
            _reflectBurn(rBurn, tBurn, sender);
        }

        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 rBurn,
         uint256 tTransferAmount, uint256 tFee, uint256 tBurn, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        if (!_locked) {
            _reflectAirdrop(tAmount, sender);
        }

        if (tLiquidity > 0) {
            _takeLiquidity(tLiquidity, sender);
        }


        if (tFee > 0) {
            _reflectFee(rFee, tFee);
        }

        if (tBurn > 0) {
            _reflectBurn(rBurn, tBurn, sender);
        }

        emit Transfer(sender, recipient, tTransferAmount);
    }


    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 rBurn,
         uint256 tTransferAmount, uint256 tFee, uint256 tBurn, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        if (!_locked) {
            _reflectAirdrop(tAmount, sender);
        }


        if (tLiquidity > 0) {
            _takeLiquidity(tLiquidity, sender);
        }

        if (tFee > 0) {
            _reflectFee(rFee, tFee);
        }

        if (tBurn > 0) {
            _reflectBurn(rBurn, tBurn, sender);
        }

        emit Transfer(sender, recipient, tTransferAmount);
    }


    function retriveBNB(address payable to, uint256 amount) external onlyOwner {
        require(to != address(0), "Zero address prohibited");
        uint256 contractBalance = address(this).balance;
        require(amount <= contractBalance, "Insufficient contract BNB balance");
        to.transfer(amount);
    }


   function sendAirdrop(address[] memory _recipients, uint256 _amount) public onlyOwner returns (bool) {
        uint256 currentRate = _getRate();
        require(_recipients.length.mul(_amount) <= _rOwned[_airdropWallet].div(currentRate),
                "Insufficient airdrop wallet balance to send to all wallets");

        uint256 rTransferAmount = _amount.mul(currentRate);
        for (uint i = 0; i < _recipients.length; i++) {
            _aOwned[_recipients[i]] = _aOwned[_recipients[i]].add(_amount);
            _rOwned[_recipients[i]] = _rOwned[_recipients[i]].add(rTransferAmount);
            if (_isExcluded[_recipients[i]]) {
                _tOwned[_recipients[i]] = _tOwned[_recipients[i]].add(_amount);
            }
            emit Transfer(_airdropWallet, _recipients[i], _amount);
        }
        _rOwned[_airdropWallet] = _rOwned[_airdropWallet].sub(_recipients.length.mul(rTransferAmount));
        if (_isExcluded[_airdropWallet]) {
            _tOwned[_airdropWallet] = _tOwned[_airdropWallet].sub(_recipients.length.mul(_amount));
        }
        return true;
   }

}