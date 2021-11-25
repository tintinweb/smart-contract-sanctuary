/**
 *Submitted for verification at BscScan.com on 2021-11-25
*/

pragma solidity = 0.8.10;
// SPDX-License-Identifier: Unlicensed
interface IERC20 {
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}
library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}
contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner {
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


contract eEatsTest is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    
    string private _name = "eEatsTest";
    string private _symbol = "$eEatsTest";
    uint8 private _decimals = 18;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isMaxTxExempt;
    mapping (address => bool) private _isMaxWalExempt;
    mapping (address => bool) private _tradingOpenExempt;
    mapping (address => bool) private _isTimelockExempt;

    mapping (address => bool) private _isExcluded;   // reflections
    address[] private _excluded;  // reflections
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 2000000000000 * 10 ** _decimals;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    
    uint256 public _reflectionFee = 4;
    uint256 private _previousTaxFee = _reflectionFee;
    
    uint256 public _adminSplit = 4;
    uint256 public _liquiditySplit = 4;
    uint256 public _otherFee = 8;
    uint256 private _previousOtherFee = _otherFee;
    
    uint256 public totalBuyFee = 12;
    uint256 public totalSellFee = 12;
    bool private differentSellFee = false;
    
    bool public tradingOpen = false;
    uint256 public deadBlocks;
    uint256 public launchedBlock;
    bool private earlyTrading = true;
    
    mapping (address => bool) private _isBlackListed;
    address[] private _blackListed;

    address public adminFeeReceiver;
    
    address public DEAD = 0x000000000000000000000000000000000000dEaD;
    address public WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    IUniswapV2Router02 public  uniswapV2Router;
    address public  uniswapV2Pair;
    
    bool public inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    
    uint8 public cooldownTimerInterval = 45;
    mapping (address => uint) private cooldownTimer;
    
    uint256 public _maxTxAmount = _tTotal * 1 / 2 / 100  ;
    uint256 public _maxWalletAmount =  20000000000 * 10**18;
    
    uint256 private minTokensBeforeSwap = _tTotal  / 5000; // .05% of supply
    
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
    
    constructor ()  {
        _rOwned[msg.sender] = _rTotal;
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
         // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;
        
        //exclude owner and this contract from fee
        _isExcludedFromFee[msg.sender] = true;
        _isExcludedFromFee[address(this)] = true;
        
        _isExcluded[uniswapV2Pair] = true;
        
        _isMaxTxExempt[address(this)] = true;
        _isMaxTxExempt[msg.sender] = true;
        
        _isTimelockExempt[address(this)] = true;
        _isTimelockExempt[msg.sender] = true;
        
        _tradingOpenExempt[msg.sender] = true;
        
        adminFeeReceiver = msg.sender;
        
        
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function addToBlackList(address account) external onlyOwner() {
        require(account != 0x10ED43C718714eb63d5aA57B78B54704E256024E, 'We can not blacklist Pancake router.');
        require(!_isBlackListed[account], "Account is already blacklisted");
        _isBlackListed[account] = true;
        _blackListed.push(account);
    }

        function removeFromBlackList(address account) external onlyOwner() {
        require(_isBlackListed[account], "Account is not blacklisted");
        for (uint256 i = 0; i < _blackListed.length; i++) {
            if (_blackListed[i] == account) {
                _blackListed[i] = _blackListed[_blackListed.length - 1];
                _isBlackListed[account] = false;
                _blackListed.pop();
                break;
            }
        }
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

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function deliver(uint256 tAmount, bool isSell) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,) = _getValues(tAmount, isSell);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }
    
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee, bool isSell) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,) = _getValues(tAmount, isSell);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,) = _getValues(tAmount, isSell);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner {
        require(account != 0x10ED43C718714eb63d5aA57B78B54704E256024E, 'We can not exclude Pancake router.');
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner {
        require(_isExcluded[account], "Account is already excluded");
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
    
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount, bool isSell) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount, isSell);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    
    function openTrading (uint256 _deadBlocks) external onlyOwner {
        deadBlocks = _deadBlocks;
        tradingOpen = true;
        launchedBlock = block.number;
        earlyTrading = true;
    }
    
    function setFees (uint256 _reflections, uint256 _admin, uint256 _liquidity, uint256 _sellTotal) external onlyOwner {
        _reflectionFee = _reflections;
        _adminSplit = _admin;
        _liquiditySplit = _liquidity;
        _otherFee = _admin.add(_liquidity);

        uint256 amountBuy = _reflections.add(_admin).add(_liquidity);

        require(amountBuy <= 25, "You can't set Buy tax this high!");
        require(_sellTotal <= 35, "You can't set Sell tax this high!");
        
        totalBuyFee = amountBuy;
        totalSellFee = _sellTotal;
        
        if(totalBuyFee != totalSellFee){ 
            differentSellFee = true;
        }
        else{
            differentSellFee = false;
        }
    }
   
    function setMaxTxPercent(uint256 _Num, uint256 _Den) external onlyOwner {
       uint256 amount = _tTotal.mul(_Num).div(_Den).div(
            10**2
        );
        require(amount >= _tTotal.div(1000), "You can't set the Max TX this low!");
        _maxTxAmount = amount;
    }
    
    function setMaxWalletAmount(uint256 _maxToken) external onlyOwner {
  	    _maxWalletAmount = _maxToken * (10**18);
  	}
    
    function setMaxTxExempt (address _holder, bool _exempt) external onlyOwner {
        _isMaxTxExempt[_holder] = _exempt;
    }
    
    function setMaxWalExempt (address _holder, bool _exempt) external onlyOwner {
        _isMaxWalExempt[_holder] = _exempt;
    }
    
    
    function setIsTradingOpenExempt (address _holder, bool _exempt) external onlyOwner {
        _tradingOpenExempt[_holder] = _exempt;
    }
    
    function setIsTimelockExempt (address _holder, bool _exempt) external onlyOwner {
        _isTimelockExempt[_holder] = _exempt;
    }
    
    function setFeeReceivers (address _admin) external onlyOwner{
        adminFeeReceiver = _admin;
    }

    function setSwapAndLiquifyVar(bool _enabled, uint256 _threshold) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        minTokensBeforeSwap = _threshold;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount, bool isSell) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount, isSell);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
    }

    function _getTValues(uint256 tAmount, bool isSell) private view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount, isSell);
        uint256 tLiquidity = calculateLiquidityFee(tAmount, isSell);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
        return (rAmount, rTransferAmount, rFee);
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
    
    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }
    
    function calculateTaxFee(uint256 _amount, bool isSell) private view returns (uint256) {
            if (differentSellFee && isSell) {
                return _amount.mul(_reflectionFee).mul(totalSellFee).div(totalBuyFee).div(
                    10**2
                    );
            
            }
            else{
                return _amount.mul(_reflectionFee).div(
                    10**2
                );
            }
        
    }

    function calculateLiquidityFee(uint256 _amount, bool isSell) private view returns (uint256) {
        if (differentSellFee && isSell) {
            return _amount.mul(_otherFee).mul(totalSellFee).div(totalBuyFee).div(
                10**2
                );
        
        }
        else{
            return _amount.mul(_otherFee).div(
                10**2
            );
        }
    }
    
    function removeAllFee() private {
        if(_reflectionFee == 0 && _otherFee == 0) return;
        
        _previousTaxFee = _reflectionFee;
        _previousOtherFee = _otherFee;
        
        _reflectionFee = 0;
        _otherFee = 0;
    }
    
    function restoreAllFee() private {
        _reflectionFee = _previousTaxFee;
        _otherFee = _previousOtherFee;
    }
    
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!_isBlackListed[from], "Account is blacklisted and can't trade");
        require(!_isBlackListed[to], "Account is blacklisted and can't trade");
        require(!_isBlackListed[tx.origin], "Origin Account is blacklisted");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(tradingOpen || _tradingOpenExempt[from] , "You can't trade yet");
        if(earlyTrading){
            require(launchedBlock + deadBlocks <= block.number || _tradingOpenExempt[from], "How tf did you buy so fast");
            if(launchedBlock + 5 <= block.number){
                require(tx.gasprice <= 12000000000, "Your gwei is too high");
            }
            if (from == uniswapV2Pair &&
                !_isTimelockExempt[to]) {
                require(cooldownTimer[to] < block.timestamp,"Please wait for 45 sec between two buys");
                cooldownTimer[to] = block.timestamp + cooldownTimerInterval;
            }
            if(launchedBlock + 20 >= block.number){
                earlyTrading = false;
            }
        }
        
        if (!_isMaxWalExempt[from] && to != address(this)  && to != address(DEAD) && to != uniswapV2Pair && to != adminFeeReceiver ){
            uint256 heldTokens = balanceOf(to);
            require((heldTokens + amount) <= _maxWalletAmount,"Total Holding is currently limited, you can not buy that much.");
            
        }
        
        require(amount <= _maxTxAmount || _isMaxTxExempt[to] || _isMaxTxExempt[from] , "Transfer amount exceeds the maxTxAmount.");
            
        uint256 contractTokenBalance = balanceOf(address(this));
        
        bool isSell = to == uniswapV2Pair;
        
        
        bool overMinTokenBalance = contractTokenBalance >= minTokensBeforeSwap;
        if (!inSwapAndLiquify && from != uniswapV2Pair && swapAndLiquifyEnabled && overMinTokenBalance){
            contractTokenBalance = minTokensBeforeSwap;
            swapAndLiquify(contractTokenBalance);
        }
        
        bool takeFee = true;
        
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to] || inSwapAndLiquify ){
            takeFee = false;
        }
        _tokenTransfer(from,to,amount,takeFee, isSell);
        
    }
    
    
    function getStuckBalance() external onlyOwner {
        uint256 contractETHBalance = address(this).balance;
        payable(adminFeeReceiver).transfer(contractETHBalance);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 amountToLiquify = contractTokenBalance.mul(_liquiditySplit).div(_otherFee).div(2);
        uint256 amountToSwap = contractTokenBalance.sub(amountToLiquify);

        uint256 initialBalance = address(this).balance;

        swapTokensForEth(amountToSwap); 

        uint256 newBalance = address(this).balance.sub(initialBalance);
        uint256 totalBNBFee = _otherFee.sub(_liquiditySplit.div(2));
        uint256 amountBNBLiquidity = newBalance.mul(_liquiditySplit).div(totalBNBFee).div(2);
        uint256 amountBNBAdmin = newBalance.mul(_adminSplit).div(totalBNBFee);
        
        (bool success2, /* bytes memory data */) = payable(adminFeeReceiver).call{value: amountBNBAdmin, gas: 30000}("");
        require(success2, "receiver rejected ETH transfer");

        addLiquidity(amountToSwap, amountBNBLiquidity);
        
        emit SwapAndLiquify(amountToSwap, amountBNBLiquidity, amountToSwap);
    }

    function swapTokensForEth(uint256 tokenAmount) private {

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
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
            address(this),
            block.timestamp
        );
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee, bool isSell) private {
        if(!takeFee)
            removeAllFee();
        
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount, isSell);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount, isSell);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount, isSell);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount, isSell);
        } else {
            _transferStandard(sender, recipient, amount, isSell);
        }
        
        if(!takeFee)
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount, bool isSell) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount, isSell);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount, bool isSell) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount, isSell);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount, bool isSell) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount, isSell);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }


    

}