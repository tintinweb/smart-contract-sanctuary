/**
 *Submitted for verification at BscScan.com on 2021-11-17
*/

/*
// SPDX-License-Identifier: Unlicensed


Real GenshinElon V2

Telegram: https://t.me/REALGENSHINN
*/


pragma solidity ^0.8.3;


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
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
    
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


library Address {
    
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
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



abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        _owner = 0x6f89CD9b4D09240b644936c3398dF945eB61Dc84;
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

contract RGMORA is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    
    
    //_isBlacklisted = Can not buy or sell or transfer tokens at all <-----for bots! 
    mapping (address => bool) public _isBlacklisted;
    
   
   

    address[] private _excluded;
    address payable private Wallet_Burn = payable(0x000000000000000000000000000000000000dEaD);
    address payable private Wallet_Dev = payable(0x1eFc086b39Fa491d5E8f7DD36B13dE8500559d9b); 





    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 100000000 * 10**6 * 10**9;  
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    string private _name = "Real GenshinElon";
    string private _symbol = "RGMORA";
    uint8 private _decimals = 9;




    //Fees!
    uint256 public _FeeReflection = 5;
    uint256 public _FeeLiquidity = 5;
    uint256 public _FeeBurn = 0;
    uint256 public _FeeDev = 5; 

    //Fee Setting!
    uint256 private _previousFeeReflection = _FeeReflection;
    uint256 private _previousFeeLiquidity = _FeeLiquidity;
    uint256 private _previousFeeBurn = _FeeBurn;
    uint256 private _previousFeeDev = _FeeDev; 

    //Total Fees!
    uint256 public _FeesTotal = _FeeLiquidity+_FeeBurn+_FeeDev+_FeeReflection;
    uint256 private _previousFeesTotal = _FeesTotal;
      

    //Fees for processin BNB!
    uint256 private _liquidityAndPromoFee = _FeeLiquidity+_FeeDev;
    uint256 private _previousLiquidityAndPromoFee = _liquidityAndPromoFee;
    
    //Max Wallet Holding Limit! - 1% at launch
    uint256 public _maxWalletToken = 1000000 * 10**6 * 10**9; 
                                     
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    
    //Max Transaction Amount!
    uint256 public _maxTxAmount = 1000000 * 10**6 * 10**9; 

    // Number of tokens required to trigger LP 
    uint256 public _numTokensSellToAddToLiquidity = 100000 * 10**6 * 10**9; 
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
    
    constructor () {
        _rOwned[owner()] = _rTotal;
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[Wallet_Burn] = true; 
        _isExcludedFromFee[Wallet_Dev] = true; 
        
      
        
        emit Transfer(address(0), owner(), _tTotal);
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

    //Make it fair and add a delay between buys (preventing bots)
    bool public slowFairBuys = true;
    uint8 public buy_buy_delay = 10;
    uint8 public buy_sell_delay = 5;
    mapping (address => uint) private buy_buy;
    mapping (address => uint) private buy_sell;

    
    //Time delay between buys to prevent bots
    function sefeLaunch_buy_buy_delay(bool setBool, uint8 numSeconds) public onlyOwner {
        slowFairBuys = setBool;
        buy_buy_delay = numSeconds;
    }

    //Time delay between buys and sell 
    function sefeLaunch_buy_sell_delay(bool setBool, uint8 numSeconds) public onlyOwner {
        slowFairBuys = setBool;
        buy_sell_delay = numSeconds;
    }


    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
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

    function excludeFromReward(address account) public onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already included");
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
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tDev) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _takeLiquidity(tLiquidity);
        _takeDev(tDev);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    
    //Remove fee from wallet address
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    //Include wallet address in fee
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    
    // Set number of tokens to trigger auto LP 
    function process_setNumTokensSellToAddToLiquidity(uint256 numTokensSellToAddToLiquidity) external onlyOwner() {
        _numTokensSellToAddToLiquidity = numTokensSellToAddToLiquidity;
    }


    //Set Reflection fee
    function fees_setFeeReflectionPercent(uint256 FeeReflection) external onlyOwner() {
        if (FeeReflection < 11) {_FeeReflection = FeeReflection;}
        
    }

    //Set burn fee
    function fees_setFeeBurnPercent(uint256 FeeBurn) external onlyOwner() {
        if (FeeBurn < 11) {_FeeBurn = FeeBurn;}
    }
    
    //Set Auto LP fee
    function fees_setFeeLiquidityPercent(uint256 FeeLiquidity) external onlyOwner() {
        if (FeeLiquidity < 11) {_FeeLiquidity = FeeLiquidity;}
    }
    
    //Set the dev wallet fee
    function fees_setFeeDev(uint256 FeeDev) external onlyOwner() {
        if (FeeDev < 11) {_FeeDev = FeeDev;}
    }
    


    //Changing dev wallet address
    function Wallet_Update_Dev(address payable wallet) public onlyOwner() {
        Wallet_Dev = wallet;
        _isExcludedFromFee[Wallet_Dev] = true;
    }
       
   
    //Set max transaction (in percent)
    function safeLaunch_setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(
            10**2
        );
    }
    
    //Set max transaction in tokens
     function safeLaunch_setMaxTxTokens(uint256 maxTxTokens) external onlyOwner() {
        _maxTxAmount = maxTxTokens;
    }
    
    
    
    //Set max wallet as a percent of total
     function safeLaunch_setMaxWalletPercent(uint256 maxWallPercent) external onlyOwner() {
        _maxWalletToken = _tTotal.mul(maxWallPercent).div(
            10**2
        );
    }
    
    //Set max wallet in tokens 
     function safeLaunch_setMaxWalletTokens(uint256 maxWallTokens) external onlyOwner() {
        _maxWalletToken = maxWallTokens;
    }
    
    
    
    //Set swap and liquify on or off
    function process_setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
    //allow bnb into contract from PCS
    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }
    
    
    //Remove from blacklist
    function safeLaunch_removeFromBlackList(address account) external onlyOwner {
        _isBlacklisted[account] = false;
    }
    
    
    //Add to black list
    function safeLaunch_addToBlackList(address[] calldata addresses) external onlyOwner {
      for (uint256 i; i < addresses.length; ++i) {
        _isBlacklisted[addresses[i]] = true;
      }
    }
    
   
    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tDev) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, tDev, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity, tDev);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
        uint256 tFee = calculateFeeReflection(tAmount);
        uint256 tLiquidity = calculateLiquidityAndPromoFee(tAmount);
        uint256 tDev = calculateFeeBurn(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity).sub(tDev);
        return (tTransferAmount, tFee, tLiquidity, tDev);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 tDev, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rDev = tDev.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity).sub(rDev);
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
    
    function _takeDev(uint256 tDev) private {
        uint256 currentRate =  _getRate();
        uint256 rDev = tDev.mul(currentRate);
        _rOwned[Wallet_Burn] = _rOwned[Wallet_Burn].add(rDev);
        if(_isExcluded[Wallet_Burn])
            _tOwned[Wallet_Burn] = _tOwned[Wallet_Burn].add(tDev);
    }
    
    function calculateFeeReflection(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_FeeReflection).div(
            10**2
        );
    }

    function calculateFeeBurn(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_FeeBurn).div(
            10**2
        );
    }

    function calculateLiquidityAndPromoFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityAndPromoFee).div(
            10**2
        );
    }
    
    function removeAllFee() private {
        
        _previousFeeReflection = _FeeReflection;
        _previousFeeBurn = _FeeBurn;
        _previousLiquidityAndPromoFee = _liquidityAndPromoFee;
        _previousFeeLiquidity = _FeeLiquidity;
        _previousFeeDev = _FeeDev;
        
        _FeeReflection = 0;
        _FeeBurn = 0;
        _liquidityAndPromoFee = 0;
        _FeeLiquidity = 0;
        _FeeDev = 0;


    }
    
    function restoreAllFee() private {


         _FeeReflection = _previousFeeReflection;
         _FeeBurn = _previousFeeBurn;
         _liquidityAndPromoFee = _previousLiquidityAndPromoFee;
         _FeeLiquidity = _previousFeeLiquidity;
         _FeeDev = _previousFeeDev;
    }
    
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "Err owner 0 address");
        require(spender != address(0), "Err spender 0 address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {

        
        
        //Check not over max balance
        if (from != owner() && to != owner() && to != address(this)  && to != address(0x000000000000000000000000000000000000dEaD) && to != uniswapV2Pair){
            uint256 heldTokens = balanceOf(to);
            require((heldTokens + amount) <= _maxWalletToken,"You are trying to buy over the max wallet limit.");}
        
        //No blacklisted peple or bots can buy or sell 
        require(!_isBlacklisted[from] && !_isBlacklisted[to], "To or from address is blacklisted");
        require(from != address(0), "from 0 address");
        require(to != address(0), "to 0 address");
        require(amount > 0, "must be more than 0 tokens");


       //Time delay to stop bots and to make buys fair for all 
        if (from == uniswapV2Pair &&
            slowFairBuys &&
            !_isExcludedFromFee[to] &&
            to != address(this)  && 
            to != address(0x000000000000000000000000000000000000dEaD)) {
            require(buy_buy[to] < block.timestamp,"Need to wait a few seconds before you can buy again.");
            buy_buy[to] = block.timestamp + buy_buy_delay;
            buy_sell[to] = block.timestamp + buy_sell_delay;

        }



        if (from != uniswapV2Pair &&
            slowFairBuys &&
            !_isExcludedFromFee[to] &&
            to != address(this)  && 
            to != address(0x000000000000000000000000000000000000dEaD)) {
            require(buy_sell[from] < block.timestamp,"Need to wait a few seconds before selling.");
        }




        
        //Transaction limits
        if(from != owner() && to != owner())
            require(amount <= _maxTxAmount, "You are trying to buy/sell move tokens that the max transaction permits");

        uint256 contractTokenBalance = balanceOf(address(this));
        
        if(contractTokenBalance >= _maxTxAmount)
        {
            contractTokenBalance = _maxTxAmount;
        }
        
        bool overMinTokenBalance = contractTokenBalance >= _numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = _numTokensSellToAddToLiquidity;
            swapAndLiquify(contractTokenBalance);
        }
        
        bool takeFee = true;
        
       
         require(to != address(0), "Transfer to the zero address");
         
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        
        _tokenTransfer(from,to,amount,takeFee);
    }
    
     function sendToWallet(address payable wallet, uint256 amount) private {
            wallet.transfer(amount);
        }


    function precDiv(uint a, uint b, uint precision) internal pure returns ( uint) {
     return a*(10**precision)/b;
         
    } 

     function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        
       uint256 __splitPromo = 0;
       uint256 __tokensToPromo = 0;
       

        if (_FeeDev != 0){


             __splitPromo = precDiv(_FeeDev,_liquidityAndPromoFee,2);
             __tokensToPromo = contractTokenBalance*__splitPromo/100;


                   
        //Send BNB to dev wallet for marketing and development 
        uint256 balanceBeforePromoWallet = address(this).balance;
        swapTokensForEth(__tokensToPromo);
        uint256 balanceToSendPromo = address(this).balance - balanceBeforePromoWallet;
        sendToWallet(Wallet_Dev, balanceToSendPromo);
}

             
        if (_FeeLiquidity != 0){
        uint256 __tokenstoLP = contractTokenBalance-__tokensToPromo;
        uint256 firstHalf = __tokenstoLP.div(2);
        uint256 secondHalf = __tokenstoLP.sub(firstHalf);
        uint256 balanceBeforeLP = address(this).balance;
        swapTokensForEth(firstHalf); 
        uint256 swappedLP = address(this).balance.sub(balanceBeforeLP);
        addLiquidity(secondHalf, swappedLP);
        emit SwapAndLiquify(firstHalf, swappedLP, secondHalf);
        }
    
}

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, 
            0, 
            owner(),
            block.timestamp
        );
    }    
    
    //Process tokens on contract into BNB and send to wallet
    function process_TokensFromContract(address payable wallet, uint256 tokenAmount) public onlyOwner {
        uint256 tokensOnWallet = balanceOf(address(this));
        if (tokenAmount > tokensOnWallet) {tokenAmount = tokensOnWallet;}
        uint256 balanceBefore = address(this).balance;
        swapTokensForEth(tokenAmount);
        uint256 balanceToSend = address(this).balance - balanceBefore;
        sendToWallet(wallet, balanceToSend);
    }

    //Send BNB from contract to wallet
    function process_BNBFromContract(address payable wallet, uint256 bnbAmount) public onlyOwner {
        uint256 contractBNB = address(this).balance;
        if (contractBNB > 0) {
        if (bnbAmount > contractBNB) {bnbAmount = contractBNB;}
        sendToWallet(wallet, bnbAmount);
    }
    }



    //Transfer functions
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
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tDev) = _getValues(tAmount);
                
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _takeDev(tDev);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tDev) = _getValues(tAmount);
        
        
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _takeLiquidity(tLiquidity);
        _takeDev(tDev);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tDev) = _getValues(tAmount);
       
       
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _takeLiquidity(tLiquidity);
        _takeDev(tDev);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    

}