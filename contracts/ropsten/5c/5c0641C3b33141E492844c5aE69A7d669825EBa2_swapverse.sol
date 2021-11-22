/**
 *Submitted for verification at Etherscan.io on 2021-11-22
*/

// SPDX-License-Identifier: MIT
 pragma solidity ^0.8.6;

 library SafeMath {
 
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }


    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }


    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }


    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

 interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function getOwner() external view returns (address);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
  
interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
 
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {return msg.sender;}
    function _msgData() internal view virtual returns (bytes calldata) {this; return msg.data;}
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size; assembly { size := extcodesize(account) } return size > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");(bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");

    }
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);

    }
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");

    }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) { return returndata; } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {revert(errorMessage);}
        }
    }
}
 
abstract contract Ownable is Context {
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

    function getTime() public view returns (uint256) {
        return block.timestamp;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
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
 
 
 contract swapverse is IERC20Metadata, Context, Ownable {
     using SafeMath for uint256;
     using Address for address;
     address public presaleAddress = 0x7cE4D7946EDE50125396864BB7f162908AC361Ec;
     address public marketingFeeReceiver = 0x0276d02885363Fda45A7d9c37D7757F6dB521501;
     address public developmentwallet = 0x50A304cEF095aC943434B67AF254a8d3Eba1a998;
     address public burnFeeReceiver = 0x3BE05d94c24Fe4404eD261376127cD1814dBAcc8;
     address public deadAddress = 0x000000000000000000000000000000000000dEaD;

     string constant _name = "Swapverse";
     string constant _symbol = "VSWAP";
     uint8 constant _decimals = 9;

     uint256 private constant MAX = ~uint256(0);
     uint256 internal constant _tTotal = 1000000000 * 10**6 * 10**9;
     uint256 internal _rTotal = (MAX - (MAX % _tTotal));

     uint256 public _tFeeTotal;

     uint256 public _tFee = 1;
     uint256 internal _previoustFee = _tFee;
     
     uint256 public _marketingFee =1;
     uint256 internal _previousmaketingFee = _marketingFee;

     uint256 public _burnFee = 1;
     uint256 internal _previousburnFee = _burnFee;

     IUniswapV2Router02 public uniswapV2Router;
     address public  uniswapV2Pair;

     mapping (address => uint256) internal _rOwned;
     mapping (address => uint256) internal _tOwned;
     mapping (address => mapping (address => uint256)) internal _allowances;
 
     mapping (address => bool) internal _isExcludedFromFee;
     mapping (address => bool) internal _isExcluded;
     address[] private _excluded;
     
     constructor () {
         _rOwned[presaleAddress] = _rTotal;
         
         IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

         uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
 
         uniswapV2Router = _uniswapV2Router;
         
         _isExcludedFromFee[owner()] = true;
         _isExcludedFromFee[presaleAddress] = true;
         _isExcludedFromFee[address(this)] = true;
         _isExcludedFromFee[marketingFeeReceiver] = true;
         _isExcludedFromFee[developmentwallet] = true;
         _isExcludedFromFee[burnFeeReceiver] = true;
         _approve(owner(), address(uniswapV2Router), ~uint256(0));
         emit Transfer(address(0), _msgSender(), _tTotal);
     }
     function name() external pure override returns (string memory) {
        return _name;
    }
 
    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }
 
     function totalSupply() external pure override returns (uint256) {
         return _tTotal;
     }
     
     function getOwner() external view override returns (address) { 
         return owner(); 
         
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
 
     function reflectionFromToken(uint256 tAmount, bool deductTransferFee) external view returns(uint256) {
         require(tAmount <= _tTotal, "Amount must be less than supply");
         if (!deductTransferFee) {
             (uint256 rAmount,,,,,,) = _getValues(tAmount);
             return rAmount;
         } else {
             (,uint256 rTransferAmount,,,,,) = _getValues(tAmount);
             return rTransferAmount;
         }
     }
 
     function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
         require(rAmount <= _rTotal, "Amount must be less than total reflections");
         uint256 currentRate =  _getRate();
         return rAmount.div(currentRate);
     }
     
     function setMarketingFeeReceiver(address _marketingFeeReceiver) external onlyOwner() {
         marketingFeeReceiver = _marketingFeeReceiver;
     }
     
     function setBurnFeeReceiver(address _burnFeeReceiver) external onlyOwner() {
         burnFeeReceiver = _burnFeeReceiver;
     }
     
 
     function excludeFromReward(address account) public onlyOwner() {
         require(!_isExcluded[account], "Account is already excluded");
         if(_rOwned[account] > 0) {
             _tOwned[account] = tokenFromReflection(_rOwned[account]);
         }
         _isExcluded[account] = true;
         _excluded.push(account);
     }
 
     function includeInReward(address account) external onlyOwner() {
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
     function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 marketingFee, uint256 burnFee) = _getValues(tAmount);
         _tOwned[sender] = _tOwned[sender].sub(tAmount);
         _rOwned[sender] = _rOwned[sender].sub(rAmount);
         _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
         _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
         _takeFee(marketingFee, marketingFeeReceiver);
         _takeFee(burnFee, burnFeeReceiver);
         _reflectFee(rFee, tFee);
         emit Transfer(sender, recipient, tTransferAmount);
     }
     
     function excludeFromFee(address account) public onlyOwner() {
         _isExcludedFromFee[account] = true;
     }
     
     function includeInFee(address account) public onlyOwner() {
         _isExcludedFromFee[account] = false;
     }
     
     function setReflectionFeePercent(uint256 tFee) external onlyOwner() {
         _tFee = tFee;
     }
     
     function setMarketingFeePercent(uint256 marketingFee) external onlyOwner() {
         _marketingFee = marketingFee;
     }
     function setBurnFeePercent(uint256 burnFee) external onlyOwner() {
         _burnFee = burnFee;
     }   
 
     function _reflectFee(uint256 rFee, uint256 tFee) internal {
         _rTotal = _rTotal.sub(rFee);
         _tFeeTotal = _tFeeTotal.add(tFee);
     }
 
     function _getValues(uint256 tAmount) internal view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
         (uint256 tTransferAmount, uint256 tFee, uint256 marketingFee, uint256 burnFee) = _getTValues(tAmount);
         (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, marketingFee, burnFee, _getRate());
         return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, marketingFee, burnFee);
     }
 
     function _getTValues(uint256 tAmount) internal view returns (uint256, uint256, uint256, uint256) {
         uint256 tFee = calculateReflectionFee(tAmount);
         uint256 marketingFee = calculateMarketingFee(tAmount);
         uint256 burnFee = calculateBurnFee(tAmount);
         uint256 tTransferAmount = tAmount.sub(tFee).sub(marketingFee).sub(burnFee);
         return (tTransferAmount, tFee, marketingFee, burnFee);
     }
 
     function _getRValues(uint256 tAmount, uint256 tFee, uint256 marketingFee, uint256 burnFee, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
         uint256 rAmount = tAmount.mul(currentRate);
         uint256 rFee = tFee.mul(currentRate);
         uint256 rmarketingFee = marketingFee.mul(currentRate);
         uint256 rburnFee = burnFee.mul(currentRate);
         uint256 rTransferAmount = rAmount.sub(rFee).sub(rmarketingFee).sub(rburnFee);
         return (rAmount, rTransferAmount, rFee);
     }
 
     function _getRate() internal view returns(uint256) {
         (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
         return rSupply.div(tSupply);
     }
 
     function _getCurrentSupply() internal view returns(uint256, uint256) {
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
     
     function calculateReflectionFee(uint256 _amount) internal view returns (uint256) {
         return _amount.mul(_tFee).div(
             10**2
         );
     }

     function calculateMarketingFee(uint256 _amount) internal view returns (uint256) {
         return _amount.mul(_marketingFee).div(
             10**2
         );
     }

     function calculateBurnFee(uint256 _amount) internal view returns (uint256) {
         return _amount.mul(_burnFee).div(
             10**2
         );
     }
     
     function removeAllFee() internal {
         if(_tFee == 0 && _marketingFee == 0 &&  _burnFee == 0) return;
         
         _previoustFee = _tFee;
         _previousmaketingFee = _marketingFee;
         _previousburnFee = _burnFee;
         
         _tFee = 0;
         _marketingFee = 0;
         _burnFee = 0;
     }
     
     function restoreAllFee() internal {
        _tFee = _previoustFee;
        _marketingFee = _previousmaketingFee;
        _burnFee = _previousburnFee;
     }
     
     function isExcludedFromFee(address account) public view returns(bool) {
         return _isExcludedFromFee[account];
     }
     
 
     function _approve(address owner, address spender, uint256 amount) internal {
         require(owner != address(0), "ERC20: approve from the zero address");
         require(spender != address(0), "ERC20: approve to the zero address");
 
         _allowances[owner][spender] = amount;
         emit Approval(owner, spender, amount);
     }
 
     function _transfer(address from, address to, uint256 amount) internal {
         require(from != address(0), "ERC20: transfer from the zero address");
         require(to != address(0), "ERC20: transfer to the zero address");
         require(from != address(deadAddress), "Token: transfer from the burn address");
         require(amount > 0, "Transfer amount must be greater than zero");
         bool takeFee = true;
         
         if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
             takeFee = false;
         }
         
         _tokenTransfer(from,to,amount,takeFee);
     }

     function _takeFee(uint256 fee, address feeRecevier) internal {
        uint256 currentRate =  _getRate();
        uint256 rFee = fee.mul(currentRate);
        _rOwned[feeRecevier] = _rOwned[feeRecevier].add(rFee);
        if(_isExcluded[feeRecevier])
            _tOwned[feeRecevier] = _tOwned[feeRecevier].add(rFee);

     }

     function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
         if(!takeFee)
             removeAllFee();
         
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
         
         if(!takeFee)
             restoreAllFee();
     }
 
     function _transferStandard(address sender, address recipient, uint256 tAmount) private {
         (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 marketingFee, uint256 burnFee) = _getValues(tAmount);
         _rOwned[sender] = _rOwned[sender].sub(rAmount);
         _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
         _takeFee(marketingFee, marketingFeeReceiver);
         _takeFee(burnFee, burnFeeReceiver);
         _reflectFee(rFee, tFee);
         emit Transfer(sender, recipient, tTransferAmount);
     }
 
     function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 marketingFee, uint256 burnFee) = _getValues(tAmount);
         _rOwned[sender] = _rOwned[sender].sub(rAmount);
         _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
         _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
         _takeFee(marketingFee, marketingFeeReceiver);
         _takeFee(burnFee, burnFeeReceiver);
         _reflectFee(rFee, tFee);
         emit Transfer(sender, recipient, tTransferAmount);
     }
 
     function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 marketingFee, uint256 burnFee) = _getValues(tAmount);
         _tOwned[sender] = _tOwned[sender].sub(tAmount);
         _rOwned[sender] = _rOwned[sender].sub(rAmount);
         _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
         _takeFee(marketingFee, marketingFeeReceiver);
         _takeFee(burnFee, burnFeeReceiver);
         _reflectFee(rFee, tFee);
         emit Transfer(sender, recipient, tTransferAmount);
     }

     receive() external payable {}
 }