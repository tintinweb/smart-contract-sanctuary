/**
 *Submitted for verification at BscScan.com on 2021-07-27
*/

// SPDX-License-Identifier: Unlicensed



pragma solidity ^0.8.4; 

library Address {

    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
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

//pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
} 

// pragma solidity ^0.8.4;

contract Ownable is Context {
    address private _owner;
    address private _burningMan;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event BurningManSelected(address indexed previousBurningMan, address indexed newBurningMan);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }   
    
    function getburningMan() public view returns (address) {
        return _burningMan;
    }
    
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
   
    modifier onlyAuthorized() {
        require(
        _msgSender() == _owner  || 
        _msgSender() == _burningMan || 
        _msgSender() == address(this) , "Ownable: caller is not authorized");
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
    
    function selectBurningMan(address burningMan) public virtual onlyOwner {
        _burningMan = burningMan;
        emit BurningManSelected(_burningMan, burningMan);
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
        require(block.timestamp > _lockTime , "Contract is still time-locked");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

//pragma solidity ^0.8.4;

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

//pragma solidity >=0.5.0;

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

//pragma solidity >=0.5.0;

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

    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
} 

//pragma solidity >=0.6.2;

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

//pragma solidity >=0.6.2;

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

contract TestDoge is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant  _tTotal = 1000000000 * 10**6 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private constant _name = "TestDoge";
    string private constant _symbol = "TEST";
    uint8 private constant _decimals = 9;

    struct AddressFee {
        bool enable;
        uint256 _reflectionFee;
        uint256 _LPMarketingFee;
        uint256 _buyReflectionFee;
        uint256 _buyLPMarketingFee;
        uint256 _sellReflectionFee;
        uint256 _sellLPMarketingFee;
    }

    address payable public _marketingAddress = payable(0x579e7889ee18882ECD32c910340CCE7E032ffC9C);
    address public constant deadAddress = 0x000000000000000000000000000000000000dEaD;
    
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    mapping (address => AddressFee) public _addressFees;
    
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
   
    
    uint256 public _reflectionFee = 5;
    uint256 private _previousReflectionFee = _reflectionFee;
    
    uint256 public _LPMarketingFee = 7;
    uint256 private _previousLPMarketingFee = _LPMarketingFee;
    
    uint256 public _marketingFee = 2;
    uint256 public _liquidityFee = 5;
    
    
    uint256 public _buyReflectionFee = 5;
    uint256 public _buyLPMarketingFee = 7;
    
    uint256 public _sellReflectionFee = 8;
    uint256 public _sellLPMarketingFee = 10;
    uint256 public _sellBurnModeFeeIncrease = 5;

    uint256 public _startTimeForSwap;
    uint256 public launchTime;
    bool public tradingEnabled;
    bool public justLaunched;
    uint256 public _intervalMinutesForSwap = 1 * 1 minutes;

    // Parameters relate either to starting or circulating supply due to hyper-deflation
    uint256 private _maxTxAmount = 300000 * 10**6 * 10**9;            //300 Billion 
    uint256 private _maxTxDivisor = 3333;                             //300 Billion at launch
    uint256 private _maxWalletAmount = 10000000 * 10**6 * 10**9;      //10 Trillion 
    uint256 private _maxWalletDivisor = 100;                          //10 Trillion at launch
    bool private _useConstantMaxTxAmount;
    bool private _useConstantMaxWalletAmount;
    
    uint256 private _minimumTokensBeforeSwap = 1000 * 10**6 * 10**9;  //1 Billion 
    uint256 private _minimumTokensBeforeSwapDivisor = 1000000;        //1 Billion at launch
    bool private _useConstantMinTokensBeforeSwap;
    
    uint256 private _bigBurnAmount = 1;
    uint256 private _burnModeAmount = 1;
    uint256 private _preparationRatePercent = 1;
    uint256 private _bigBurnBufferPercent= 1;
    uint256 private _memeBurnAmount = 420 * 10**9;
    uint256 private _memeBurnBuffer = 100;
    uint256 private _maxBurnMatchingContractPercent = 10; 
    
    uint256 private burnModeEnd;
    uint256 private _minBurnTime = 3 minutes;
    uint256 private _burnTimeExtensionFactor = 120;
    
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    address public _DXLockerAddress;
    
    bool _automaticBigBurn;
    bool inSwapAndLiquify;
    bool inBuyBack;
    bool private _accumulatingForBurn;
    bool private _burnModeActive;
    bool public swapAndLiquifyEnabled = false;
      
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    
    event SwapETHForTokens(
        uint256 amountIn,
        address[] path
    );
    
    event SwapTokensForETH(
        uint256 amountIn,
        address[] path
    );
    
    event AddLiquidity(
        uint256 tokenAmount,
        uint256 ethAmount
    );
     
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    modifier lockTheBuyBack {
        inBuyBack = true;
        _;
        inBuyBack = false;
    }
    
    constructor () {

        _rOwned[_msgSender()] = _rTotal;
        
        //Pancake Router Testnet
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        //Pancake Router Mainnet
        //IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[deadAddress] = true;
        excludeFromReward(deadAddress);
        
        preLaunch();
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
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
    
    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }
  
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
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
        require(_isExcluded[account], "Account is not excluded");
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
        require(amount > 0, "Transfer amount must be greater than zero");
        require(tradingEnabled || tx.origin == owner(), "Trading disabled" ); 
        
        
        (, uint256 currentSupply) = _getCurrentSupply();
        uint256 walletTokens = balanceOf(to);
        uint256 maxTxAmount;
        uint256 maxWalletAmount;
        if (justLaunched){
            if (block.timestamp <= launchTime.add(900)){          // minutes [0,15]
                maxTxAmount = 200000000000 * 10 ** 9;             // 200 billion max tx
                maxWalletAmount = _tTotal.div(1000);              // 0.1% max wallet, 1 trillion
            }
            else if (block.timestamp <= launchTime.add(1800)){    // minutes (15,30]
                maxTxAmount = 250000000000 * 10 ** 9;              // 250 billion max tx
                maxWalletAmount = _tTotal.div(333);              // 0.3% max wallet, 3 trillion
            }
            else if (block.timestamp <= launchTime.add(3600)){    // minutes (30,60]
                maxTxAmount = 300000000000 * 10 ** 9;             // 300 billion max tx
                maxWalletAmount = _tTotal.div(200);              // 0.5% max wallet, 5 trillion
            }
            else{
                justLaunched = false;
                maxTxAmount = 300000000000 * 10 ** 9;             // 300 billion max tx
                maxWalletAmount = _tTotal.div(100);               // 1.0% max wallet, 10 trillion
            }
        }
        else{
            maxTxAmount = _useConstantMaxTxAmount ? _maxTxAmount : currentSupply.div(_maxTxDivisor);        
            maxWalletAmount = _useConstantMaxWalletAmount ? _maxWalletAmount : currentSupply.div(_maxWalletDivisor); 
        }
        if(from != owner() && to != owner() && 
            from != address(this)) {   
            require(amount <= maxTxAmount, "Maximum allowable transfer amount exceeded.");
            if(from == uniswapV2Pair){
                require(walletTokens.add(amount) <= maxWalletAmount, "Maximum allowable wallet amount exceeded.");
            }
        }
        /*
        if(from != owner() && to != owner() && 
            from != address(this)) {   
            require(amount <= maxTxAmount, "Maximum allowable transfer amount exceeded.");
            if(from == uniswapV2Pair){
                require(walletTokens.add(amount) <= maxWalletAmount, "Maximum allowable wallet amount exceeded.");
            }
        }
        */
        
        // Contract-sell for liquidity, marketing and buy-back
        // The condition for and amount of swapping may relate to circulating supply due to hyper-deflation
        if (!inSwapAndLiquify && to == uniswapV2Pair && 
        balanceOf(uniswapV2Pair) > 0 && swapAndLiquifyEnabled) {
                uint256 contractTokenSupply = balanceOf(address(this));
                uint256 minimumTokensBeforeSwap = _useConstantMinTokensBeforeSwap ?  
                _minimumTokensBeforeSwap : currentSupply.div(_minimumTokensBeforeSwapDivisor);
                if (contractTokenSupply >= minimumTokensBeforeSwap && _startTimeForSwap + _intervalMinutesForSwap <= block.timestamp) {
                    _startTimeForSwap = block.timestamp;
                    swapTokens(minimumTokensBeforeSwap);    
                }  
        }
        
        // Checks for Big-Burn condition and Burn-Mode termination
        if (_accumulatingForBurn && _automaticBigBurn && bigBurnReady()){
            this.bigBurn();
            _automaticBigBurn = false;
        }
        else if(_burnModeActive && block.timestamp > burnModeEnd){
            _burnModeActive = false;
        }
        
        
        bool takeFee = true;
        if(  (_isExcludedFromFee[from] || _isExcludedFromFee[to])){
            takeFee = false;
        }
        else{
            // Buy
            if(from == uniswapV2Pair){
                removeAllFee();
                if (_burnModeActive){
                    _reflectionFee = 0;
                    _LPMarketingFee = 0;
                    // Parameterized burn-matching during BurnMode
                    uint256 maxBurn = balanceOf(address(this)).mul(_maxBurnMatchingContractPercent).div(100);
                    uint256 amountToBurn = amount > maxBurn ? maxBurn : amount;
                    burn(amountToBurn); 
                }
                else{
                    _reflectionFee = _buyReflectionFee;
                    _LPMarketingFee = _buyLPMarketingFee;    
                }
            }
            // Sell
            if(to == uniswapV2Pair){
                uint256 memeBurnCost = estimateEthCost(_memeBurnAmount);
                removeAllFee();
                if (_burnModeActive){
                    /*
                    if (_flagA && address(this).balance > memeBurnCost && !inBuyBack){ 
                        ; 
                    }
                    //else if (_flagA && address(this).balance > memeBurnCost && !inBuyBack){
                    // swapETHForTokensB(memeBurnCost);    
                    //}
                    else{
                    try this.swapETHForExactTokensTests(_memeBurnAmount) {} catch{}
                    }
                    */
                    if (!inBuyBack && 
                    address(this).balance > memeBurnCost &&
                    amount > _memeBurnAmount){ 
                    swapETHForExactTokens(_memeBurnAmount); 
                    }
                     // Further increased sell-tax dring BurnMode
                    _reflectionFee = _sellReflectionFee.add(_sellBurnModeFeeIncrease);
                    _LPMarketingFee = _sellLPMarketingFee.add(_sellBurnModeFeeIncrease);  
                     
                    
                }
                else{
                    /*
                    if(_flagB){
                      swapETHForExactTokens(_memeBurnAmount); 
                    }
                     else if(_flagC){
                      swapETHForTokensB(memeBurnCost); 
                     }
                     
                    else if (_flagD){
                    }
                    */
                    if (!inBuyBack && 
                    address(this).balance > memeBurnCost &&
                    amount > _memeBurnAmount){
                    swapETHForExactTokens(uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)))
                    .mod(_memeBurnAmount)); 
                    }
                    _reflectionFee = _sellReflectionFee;
                    _LPMarketingFee = _sellLPMarketingFee;
                        
                } 
            }
            // If sender has a special fee 
            if(_addressFees[from].enable){
                removeAllFee();
                _reflectionFee = _addressFees[from]._reflectionFee;
                _LPMarketingFee = _addressFees[from]._LPMarketingFee;
                
                // Sell
                if(to == uniswapV2Pair){
                    _reflectionFee = _addressFees[from]._sellReflectionFee;
                    _LPMarketingFee = _addressFees[from]._sellLPMarketingFee;
                }
            }
            else{
                // If receiver has a special fee
                if(_addressFees[to].enable){
                    //buy
                    removeAllFee();
                    if(from == uniswapV2Pair){
                        _reflectionFee = _addressFees[to]._buyReflectionFee;
                        _LPMarketingFee = _addressFees[to]._buyLPMarketingFee;
                    }
                }
            }
        }
        _tokenTransfer(from,to,amount,takeFee);
    }
    
    /*
    bool public _flagA;
    bool public _flagB;
    bool public _flagC;
    bool public _flagD;
    function deBug(bool flagA, bool flagB, bool flagC, bool flagD) public {
        _flagA = flagA;
        _flagB = flagB;
        _flagC = flagC;
        _flagD = flagD;
    }
    */
    
    function swapTokens(uint256 tokenAmountCandidate) private lockTheSwap {
       
        // Always keeps a buffer for buy-backs
        // If buffer filled, then allocates resources to liqiduity and marketing
        //while possibly accumulating for BurnMode and or BigBurn
        uint256 initialBalance = address(this).balance;
        uint256 memeBurnCost = estimateEthCost(_memeBurnAmount);
        if (initialBalance < memeBurnCost.mul(_memeBurnBuffer)){
            swapTokensForEth(tokenAmountCandidate);
        }
        else{
            uint256 tokensToSwap;
            if (_accumulatingForBurn){
                uint256 currentTokenBalance = balanceOf(address(this));
                // Total amount for BigBurn and subsequent BurnMode
                uint256 totalBurnBuffer =  _bigBurnAmount.mul(_bigBurnBufferPercent).div(100); 
                tokensToSwap = currentTokenBalance > totalBurnBuffer ? 
                (currentTokenBalance.sub(totalBurnBuffer)) : currentTokenBalance.mul(_preparationRatePercent).div(100);
                
            }
            else{
                tokensToSwap = tokenAmountCandidate;
            }
            
            uint256 tokensToLP = tokensToSwap.mul(_liquidityFee).div(_liquidityFee.add(_marketingFee)).div(2);
            swapTokensForEth(tokensToSwap.sub(tokensToLP));
            uint256 ethToTransfer = address(this).balance.sub(initialBalance);
            uint256 ethToLP = estimateEthCost(tokensToLP);
            transferToAddressETH(_marketingAddress, ethToTransfer.sub(ethToLP));
            if(tokensToLP > 0){
                addLiquidity(tokensToLP, ethToLP);
            }
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
            payable(address(this)), 
            block.timestamp.add(30)
        );
        emit SwapTokensForETH(tokenAmount, path);
    }
    
    function swapETHForExactTokens(uint256 tokenAmount) private lockTheBuyBack{       
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);
        
        uint256 costEstimate = estimateEthCost(tokenAmount).mul(10);
        
        uniswapV2Router.swapETHForExactTokens{value : costEstimate}(
            tokenAmount,
            path,
            deadAddress,              
            block.timestamp.add(30)
        );
        emit SwapETHForTokens(tokenAmount, path);
    }
    
    /*
    function swapETHForExactTokensTests(uint256 tokenAmount) external lockTheBuyBack{       
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);
        
        uint256 costEstimate = estimateEthCost(tokenAmount).mul(10);
        
        uniswapV2Router.swapETHForExactTokens{value : costEstimate}(
            tokenAmount,
            path,
            deadAddress,              
            block.timestamp.add(30)
        );
        emit SwapETHForTokens(tokenAmount, path);
    }
    
    function swapETHForTokensA(uint256 amount) private {
        // Generate the uniswap pair path of token -> WETH
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);

      // Make the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: address(this).balance}(
            amount,  
            path,
            deadAddress, // Burn address
            block.timestamp.add(300)
        );
        
        emit SwapETHForTokens(amount, path);
    }
    
    function swapETHForTokensB(uint256 amount) private {
        // Generate the uniswap pair path of token -> WETH
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);

      // Make the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            _memeBurnAmount,  
            path,
            deadAddress, // Burn address
            block.timestamp.add(300)
        );
        
        emit SwapETHForTokens(amount, path);
    }
    */
    
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // Approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, 
            0,  
            deadAddress,                     
            block.timestamp.add(30)
        );
        emit AddLiquidity(tokenAmount, ethAmount);
    }
    
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        if(!takeFee)
            removeAllFee();
        
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        
        if(!takeFee)
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, 
        uint256 tTransferAmount, uint256 tFee, uint256 tLPMarketing) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLPMarketing(tLPMarketing);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee,
        uint256 tTransferAmount, uint256 tFee, uint256 tLPMarketing) = _getValues(tAmount);
	    _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _takeLPMarketing(tLPMarketing);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee,
        uint256 tTransferAmount, uint256 tFee, uint256 tLPMarketing) = _getValues(tAmount);
    	_tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _takeLPMarketing(tLPMarketing);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee,
        uint256 tTransferAmount, uint256 tFee, uint256 tLPMarketing) = _getValues(tAmount);
    	_tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _takeLPMarketing(tLPMarketing);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLPMarketing) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLPMarketing, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLPMarketing);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateReflectionFee(tAmount);
        uint256 tLPMarketing = calculateLPMarketingFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLPMarketing);
        return (tTransferAmount, tFee, tLPMarketing);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLPMarketing, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLPMarketing = tLPMarketing.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLPMarketing);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() public view returns(uint256, uint256) {
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
    
    function _takeLPMarketing(uint256 tLPMarketing) private {
        uint256 currentRate =  _getRate();
        uint256 rLPMarketing = tLPMarketing.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLPMarketing);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLPMarketing);
    }
    
    function calculateReflectionFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_reflectionFee).div(
            10**2
        );
    }
    
    function calculateLPMarketingFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_LPMarketingFee).div(
            10**2
        );
    }
    
    function removeAllFee() private {
        if(_reflectionFee == 0 && _LPMarketingFee == 0) return;
        
        _previousReflectionFee = _reflectionFee;
        _previousLPMarketingFee = _LPMarketingFee;
        
        _reflectionFee = 0;
        _LPMarketingFee = 0;
    }
    
    function restoreAllFee() private {
        _reflectionFee = _previousReflectionFee;
        _LPMarketingFee = _previousLPMarketingFee;
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }
    
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    
    function estimateEthCost(uint256 tokenAmount) private view returns(uint256) {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);
        
        uint[] memory amounts = uniswapV2Router.getAmountsIn(tokenAmount, path);
        return amounts[0];
    }

    function burn(uint256 tAmount) private {
        uint256 rAmount = tAmount.mul(_getRate());
        if (_rOwned[address(this)] < rAmount ){
            return;
        }
        _rOwned[address(this)] = _rOwned[address(this)].sub(rAmount);
        _tOwned[deadAddress] = _tOwned[deadAddress].add(tAmount);
        _rOwned[deadAddress] = _rOwned[deadAddress].add(rAmount);     
        emit Transfer(address(this), deadAddress, tAmount);
    }
    
    function prepareForBurn(bool automaticBigBurn, uint256 burnAmount, uint256 bigBurnBufferPercent, 
    uint256 preparationRatePercent, uint256 maxBurnMatchingContractPercent) external onlyAuthorized {
        _automaticBigBurn = automaticBigBurn; 
        _bigBurnAmount = burnAmount;
        _bigBurnBufferPercent = bigBurnBufferPercent;
        _preparationRatePercent = preparationRatePercent;
        _maxBurnMatchingContractPercent = maxBurnMatchingContractPercent;
        _accumulatingForBurn = true;
    }
    
    function bigBurnReady() public view returns(bool){
        return balanceOf(address(this)) >= _bigBurnAmount.mul(_bigBurnBufferPercent).div(100);
    }
    
    function bigBurn() external onlyAuthorized {
        if (_accumulatingForBurn){
            _accumulatingForBurn = false;
        }
        burn(_bigBurnAmount);
        this.burnMode(true);
    }
    
    function burnMode(bool burnModeActive) external onlyAuthorized {
        if (_accumulatingForBurn){
            _accumulatingForBurn = false;
        }
        _burnModeActive = burnModeActive;
        if (_burnModeActive){
        burnModeEnd = block.timestamp.add(_minBurnTime).add(  
        uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _maxBurnMatchingContractPercent))) %
        _burnTimeExtensionFactor);
        }
    }
    
    function getMemeBurnBuffer() public view returns(uint256){
        return address(this).balance.div(estimateEthCost(_memeBurnAmount));
    }
    
    function getBurnModeActive() external view onlyAuthorized returns(bool) {
        return _burnModeActive;
    }
    
    function getAccumulatingForBurn() external view onlyAuthorized returns(bool) {
        return _accumulatingForBurn;
    }
    
    function setMemeBurnAmount(uint256 memeBurnAmount) external onlyOwner{
        _memeBurnAmount = memeBurnAmount;
    }
    function setMemeBurnBuffer(uint256 memeBurnBuffer) external onlyOwner{
        _memeBurnBuffer = memeBurnBuffer;
    }
    function setBurnModeParameters(uint256 minBurnTime, uint256 burnTimeExtensionFactor) external onlyOwner{
        _minBurnTime = minBurnTime;
        _burnTimeExtensionFactor = burnTimeExtensionFactor;
    }
    
    function preLaunch() private {
        _reflectionFee = 0;
        _LPMarketingFee = 0;
        _maxTxAmount = 1000000000 * 10**6 * 10**9; //1 Quadrillion, whole token supply
        setSwapAndLiquifyEnabled(false);
        tradingEnabled = false;
    }
    
    function launch() external onlyOwner {
        require(tradingEnabled != true, "Token already launched");
        
        _reflectionFee = 5;
        _LPMarketingFee = 7;
        
        setSwapAndLiquifyEnabled(true);
        tradingEnabled = true; 
        _startTimeForSwap = block.timestamp;
        launchTime = block.timestamp;
        justLaunched = true;
    }
    
    function setSwapMinutes(uint256 newMinutes) external onlyOwner {
        _intervalMinutesForSwap = newMinutes * 1 minutes;
    }
    
    function setReflectionFeePercent(uint256 reflectionFee) external onlyOwner() {
        _reflectionFee = reflectionFee;
    }
        
    function setBuyFee(uint256 buyReflectionFee, uint256 buyLPMarketingFee) external onlyOwner {
        _buyReflectionFee = buyReflectionFee;
        _buyLPMarketingFee = buyLPMarketingFee;
    }
   
    function setSellFee(uint256 sellReflectionFee, uint256 sellLPMarketingFee) external onlyOwner {
        _sellReflectionFee = sellReflectionFee;
        _sellLPMarketingFee = sellLPMarketingFee;
    }
    
    function setAddressFee(address addr, bool enable, uint256 addressReflectionFee, uint256 addressLPMarketingFee) external onlyOwner {
        _addressFees[addr].enable = enable;
        _addressFees[addr]._reflectionFee = addressReflectionFee;
        _addressFees[addr]._LPMarketingFee = addressLPMarketingFee;
    }
    
    function setBuyAddressFee(address addr, bool enable, uint256 addressReflectionFee, uint256 addressLPMarketingFee) external onlyOwner {
        _addressFees[addr].enable = enable;
        _addressFees[addr]._buyReflectionFee = addressReflectionFee;
        _addressFees[addr]._buyLPMarketingFee = addressLPMarketingFee;
    }
    
    function setSellAddressFee(address addr, bool enable, uint256 addressReflectionFee, uint256 addressLPMarketingFee) external onlyOwner {
        _addressFees[addr].enable = enable;
        _addressFees[addr]._sellReflectionFee = addressReflectionFee;
        _addressFees[addr]._sellLPMarketingFee = addressLPMarketingFee;
    }
    
    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner {
        require(_marketingFee.add(liquidityFee) != 0, "Division by zero in TokenSwap!");
        _liquidityFee = liquidityFee;
        _LPMarketingFee = liquidityFee.add(_marketingFee);
    }
    
    function setMarketingFee(uint256 marketingFee) external onlyOwner {
        require(marketingFee.add(_liquidityFee) != 0, "Division by zero in TokenSwap!");
        _marketingFee = marketingFee;
        _LPMarketingFee = marketingFee.add(_liquidityFee);
    }

    function setMaxTxAmount(bool useConstantMaxTxAmount, uint256 maxTxAmount, uint256 maxTxDivisor ) external onlyOwner {
        _useConstantMaxTxAmount = useConstantMaxTxAmount;
        _maxTxAmount = maxTxAmount;
        _maxTxDivisor = maxTxDivisor;
    }
    function setMaxWalletAmount(bool useConstantMaxWalletAmount, uint256 maxWalletAmount, uint256 maxWalletDivisor) external onlyOwner {
        _useConstantMaxWalletAmount = useConstantMaxWalletAmount;
        _maxWalletAmount = maxWalletAmount;
        _maxWalletDivisor = maxWalletDivisor;
    }
    
    function setMinTokensBeforeSwap(
        bool useConstantMinTokensBeforeSwap, uint256 minimumTokensBeforeSwap, uint256 minimumTokensBeforeSwapDivisor) external onlyOwner {
        _useConstantMinTokensBeforeSwap = useConstantMinTokensBeforeSwap;
        _minimumTokensBeforeSwap = minimumTokensBeforeSwap;
        _minimumTokensBeforeSwapDivisor = minimumTokensBeforeSwapDivisor;
    }
    
    function getMaxTxAmount() public view returns(uint256) {
        (, uint256 currentSupply) = _getCurrentSupply();
        return _useConstantMaxTxAmount ? _maxTxAmount : currentSupply.div(_maxTxDivisor);
    }
    
    function getMaxWalletAmount() public view returns(uint256) {
        (, uint256 currentSupply) = _getCurrentSupply();
        return _useConstantMaxWalletAmount ? _maxWalletAmount : currentSupply.div(_maxWalletDivisor);
    }
    function getMinTokensBeforeSwap() public view returns(uint256) {
        (, uint256 currentSupply) = _getCurrentSupply();
        return _useConstantMinTokensBeforeSwap ? _minimumTokensBeforeSwap : currentSupply.div(_minimumTokensBeforeSwapDivisor);
    }
    
    function setMarketingAddress(address marketingAddress) external onlyOwner {
        _marketingAddress = payable(marketingAddress);
    }
    
    function setRouter(address _router) external onlyOwner {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_router);
        
       address _pair = IUniswapV2Factory(_uniswapV2Router.factory()).getPair(address(this), _uniswapV2Router.WETH());
        if(_pair == address(0)){
            // Pair doesn't exist
            _pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        }
        uniswapV2Pair = _pair;
        uniswapV2Router = _uniswapV2Router;
    }
    
    function setDXLocker(address DXLockerAddress) external onlyOwner {
        _DXLockerAddress = DXLockerAddress;
        excludeFromFee(DXLockerAddress);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
     
   function transferToAddressETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }
       
    function transferForeignToken(address _token, address _to) external onlyOwner returns(bool _sent){
        require(_token != address(this), "Can't let you take all native token");
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);
    }
    
    function sweep() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    receive() external payable {}
    fallback() external {}
    
}