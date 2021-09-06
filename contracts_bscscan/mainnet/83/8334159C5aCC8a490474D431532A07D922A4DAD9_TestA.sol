/**
 *Submitted for verification at BscScan.com on 2021-09-06
*/

pragma solidity ^0.8.5;

// SPDX-License-Identifier: Unlicensed

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data; // msg.data is used to handle array, bytes, string 
    }
}

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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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
    
    function geUnlockTime() public view returns (uint256) {
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
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
        _previousOwner = address(0);
    }
}

// pragma solidity >=0.5.0;

interface IPancakeFactory {
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


// pragma solidity >=0.5.0;

interface IPancakePair {
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

// pragma solidity >=0.6.2;

interface IPancakeRouter01 {
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



// pragma solidity >=0.6.2;

interface IPancakeRouter02 is IPancakeRouter01 {
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


contract TestA is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => uint256) private _transactionCheckpoint;

    mapping (address => bool) public _isExcludedFromAntiWhale;
    mapping (address => bool) public _isExcludeFromExternalTokenMinAmount;
    
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    mapping (address => bool) private _isBlacklisted;
    mapping (address => bool) private _isExcludedFromTransactionlock;
    mapping (address => bool) private _isExcludedFromMaxTxAmount;

    mapping (address => mapping (address => uint256)) private _allowances;

    address[] private _excluded;
   
    address payable public _externalAddress  = payable(0xCa9cb6Fa442003754AA3726672A72EB7D87Eb3d0);
    address payable public _burnAddress      = payable(0x000000000000000000000000000000000000dEaD);

    string private _name    = "TestA";
    string private _symbol  = "TestA";
    uint8 private _decimals = 9;
    
    uint256 private constant MAX    = ~uint256(0);
    uint256 private _tTotal         = 1000000000 * 10**6 * 10**_decimals;
    uint256 private _rTotal         = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    
    uint256 public _burnFee                 = 140;
    uint256 private _previousBurnFee        = _burnFee;

    uint256 public _reflectionFee           = 0;
    uint256 private _previousReflectionFee  = _reflectionFee;

    uint256 public _externalFee             = 70;
    uint256 private _previousExternalFee    = _externalFee;
    
    uint256 public _liquidityFee            = 40;
    uint256 private _previousLiquidityFee   = _liquidityFee;

    uint256 private _totalLiquidityFee      = _externalFee.add(_liquidityFee);
    uint256 private _previousTLiquidityFee  = _totalLiquidityFee;

	uint256 private _transactionLockTime    = 10;

    IPancakeRouter02 public pancakeRouter;
    address public pancakePair;

    bool public isExternalTokenHoldEnabled;
    IBEP20 public _externalToken;
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled       = true;
    
    uint256 public _externalTokenMinAmount          = 50000 * 10**6 * 10**_decimals;
    uint256 public _maxTxAmountBuy                  = 1000000 * 10**6 * 10**_decimals;
    uint256 public _maxTxAmountSell                 = 1000000 * 10**6 * 10**_decimals;
    uint256 public _numTokensSellToAndTransfer      = 500000 * 10**6 * 10**_decimals;
    uint256 public _maxTokensPerAddress             = 20000000 * 10**6 * 10**_decimals;

    
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqiudity
    );
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    constructor () {
        _rOwned[_msgSender()] = _rTotal; 
        
        IPancakeRouter02 _pancakeRouter = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
         // Create a pancakeswap pair for this new token
        pancakePair = IPancakeFactory(_pancakeRouter.factory())
            .createPair(address(this), _pancakeRouter.WETH());    
            
        pancakeRouter = _pancakeRouter;
        
        _isExcludedFromFee[owner()]             = true;
        _isExcludedFromFee[address(this)]       = true;
        _isExcludedFromFee[_externalAddress]    = true;
        
        _isExcludedFromTransactionlock[owner()]                 = true;
        _isExcludedFromTransactionlock[address(this)]           = true;
        _isExcludedFromTransactionlock[pancakePair]             = true;
        _isExcludedFromTransactionlock[address(_pancakeRouter)] = true;
        _isExcludedFromTransactionlock[_burnAddress]            = true;
        
        _isExcludeFromExternalTokenMinAmount[owner()]                 = true;
        _isExcludeFromExternalTokenMinAmount[address(this)]           = true;
        _isExcludeFromExternalTokenMinAmount[pancakePair]             = true;
        _isExcludeFromExternalTokenMinAmount[address(_pancakeRouter)] = true;
        _isExcludeFromExternalTokenMinAmount[_burnAddress]            = true;
        
        _isExcludedFromMaxTxAmount[owner()]                 = true;
        _isExcludedFromMaxTxAmount[address(this)]           = true;
        _isExcludedFromMaxTxAmount[pancakePair]             = true;
        _isExcludedFromMaxTxAmount[address(_pancakeRouter)] = true;
        _isExcludedFromMaxTxAmount[_burnAddress]            = true;
        
        _isExcludedFromAntiWhale[owner()]                   = true;
        _isExcludedFromAntiWhale[address(this)]             = true;
        _isExcludedFromAntiWhale[pancakePair]               = true;
        _isExcludedFromAntiWhale[address(_pancakeRouter)]   = true;
        _isExcludedFromAntiWhale[_burnAddress]              = true;
        
        _isExcluded[address(0)]     = true;
        _isExcluded[_burnAddress]   = true;
        
        emit Transfer(address(0), _msgSender(), _tTotal);
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
    
    function totalFeesCollected() public view returns (uint256) {
        return _tFeeTotal;
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
        require(account != 0x10ED43C718714eb63d5aA57B78B54704E256024E, 'We can not exclude pancakeswap router.');
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
    
    function _burn(address account, uint256 amount) internal {
        if(amount > 0)// No need to burn if collected burn fee is zero
        {
            require(account != address(0), "BEP20: burn from the zero address");

            //add the reflections of the token to the address(0) balance.
            //This reduces the supply of reflectedTokens
            //without double altering the reflection/token ratio.
            
            _tTotal = _tTotal.sub(amount);
            _rTotal = _rTotal.sub(amount.mul(_getRate()));
            
            emit Transfer(msg.sender, address(this), amount);
        }
    }
    
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    
    function excludedFromMaxTxAmount(address account) public onlyOwner {
        _isExcludedFromMaxTxAmount[account] = true;
    }
    
    function includeInMaxTxAmount(address account) public onlyOwner {
        _isExcludedFromMaxTxAmount[account] = false;
    }
    
    function excludedFromExternalTokenMinAmount(address account) public onlyOwner {
        _isExcludeFromExternalTokenMinAmount[account] = true;
    }
    
    function includeInExternalTokenMinAmount(address account) public onlyOwner {
        _isExcludeFromExternalTokenMinAmount[account] = false;
    }
    
    function excludedFromAntiWhale(address account) public onlyOwner {
        _isExcludedFromAntiWhale[account] = true;
    }
    
    function includeInAntiWhale(address account) public onlyOwner {
        _isExcludedFromAntiWhale[account] = false;
    }
    
    function setBurnFeePercent(uint256 Fee) external onlyOwner() {
        _burnFee = Fee;
    }
    
    function setExternalFeePercent(uint256 Fee) external onlyOwner() {
        _externalFee = Fee;
        _totalLiquidityFee = _liquidityFee.add(_externalFee);
    }
    
    function setReflectFeePercent(uint256 Fee) external onlyOwner() {
        _reflectionFee = Fee;
    }
    
    function setLiquidityFeePercent(uint256 Fee) external onlyOwner() {
        _liquidityFee = Fee;
        _totalLiquidityFee = _liquidityFee.add(_externalFee);
    }
    
    function setMaxTxTokensSell(uint256 maxTxTokens) external onlyOwner() {
        _maxTxAmountSell = maxTxTokens.mul( 10**_decimals );
    }
    
    function setMaxTxTokensBuy(uint256 maxTxTokens) external onlyOwner() {
        _maxTxAmountBuy = maxTxTokens.mul( 10**_decimals );
    }
    
    function setMaxTokenPerAddress(uint256 maxTokens) external onlyOwner() {
        _maxTokensPerAddress = maxTokens.mul( 10**_decimals );
    }
    
    function setExternalTokenMinAmount(uint256 minTokens) external onlyOwner() {
        _externalTokenMinAmount = minTokens.mul( 10**_decimals );
    }
    
    function setExternalAddress(address payable externalAddress) external onlyOwner() {
        _externalAddress = externalAddress;
    }
    
	function setTransactionlockTime(uint256 transactiontime) public onlyOwner() {
		_transactionLockTime = transactiontime;
	}
	
    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
	function excludedFromTransactionlock(address excludeAddress) public onlyOwner(){
		_isExcludedFromTransactionlock[excludeAddress] = true;
	}
	
	function includeInTransactionlock(address excludeAddress) public onlyOwner(){
		_isExcludedFromTransactionlock[excludeAddress] = false;
	}
	
	function getIsExcludedFromTransactionlock(address excludeAddress) public view returns (bool){
		return _isExcludedFromTransactionlock[excludeAddress];
	}
	
    receive() external payable {}
    
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }
    
    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 bFee, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, bFee, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, bFee, tLiquidity);
    }
    
    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
        uint256 tFee = calculateReflectionFee(tAmount);
        uint256 bFee = calculateBurnFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity).sub(bFee);
        return (tTransferAmount, tFee, bFee, tLiquidity);
    }
    
    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 bFee, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rbFee = bFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity).sub(rbFee);
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
    
    function calculateBurnFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_burnFee).div(
            10**3
        );
    }
    
    function calculateReflectionFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_reflectionFee).div(
            10**3
        );
    }
    
    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_totalLiquidityFee).div(
            10**3
        );
    }
    
    function removeAllFee() private {
        if(_totalLiquidityFee == 0 && _burnFee == 0 && _liquidityFee == 0
           && _externalFee == 0 && _reflectionFee == 0 ) return;
        
        _previousLiquidityFee   = _liquidityFee; 
        _previousBurnFee        = _burnFee;
        _previousExternalFee    = _externalFee;
        _previousReflectionFee  = _reflectionFee;
        _previousTLiquidityFee  = _totalLiquidityFee;
        
        _burnFee        = 0;
        _externalFee    = 0;
        _reflectionFee  = 0;
        _liquidityFee   = 0;
        _totalLiquidityFee = 0;
    }
    
    function restoreAllFee() private {
        _liquidityFee       = _previousLiquidityFee;
        _burnFee            = _previousBurnFee;
        _externalFee        = _previousExternalFee;
        _reflectionFee      = _previousReflectionFee;
        _totalLiquidityFee  = _previousTLiquidityFee;
    }
    
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }
    
    function setMinTokensSellToAndTransfer(uint256 minTokensValue) public onlyOwner()
    {
        _numTokensSellToAndTransfer = minTokensValue.mul( 10**_decimals );
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
        require(_isExcludedFromAntiWhale[to] || balanceOf(to) + amount <= _maxTokensPerAddress,
        "Max tokens limit for this account reached. Or try lower amount");
        require(!_isBlacklisted[from], "You are banned");
        require(!_isBlacklisted[to], "The recipient is banned");
        require(_isExcludedFromTransactionlock[from]
        || block.timestamp - _transactionCheckpoint[from] >= _transactionLockTime
		,"Please wait for transaction cooldown time to finish");
        require(_isExcludedFromTransactionlock[to]
        || block.timestamp - _transactionCheckpoint[to] >= _transactionLockTime
		,"Please wait for recepients transaction cooldown time to finish");
        if(from == pancakePair)
        {
            if(isExternalTokenHoldEnabled)
                require(_isExcludeFromExternalTokenMinAmount[to]
                    || _externalToken.balanceOf(to) >= _externalTokenMinAmount
                    ,"Must hold minimum amount of External tokens to buy this tokens");
            if(!_isExcludedFromMaxTxAmount[to])
                require(amount <= _maxTxAmountBuy, "Buy amount exceeds the maxTxAmount.");		    
        }
        else if(!_isExcludedFromMaxTxAmount[from] && to == pancakePair)
        {
            require(amount <= _maxTxAmountSell, "Sell amount exceeds the maxTxAmount.");
        }

        _transactionCheckpoint[to] = block.timestamp;
        _transactionCheckpoint[from] = block.timestamp;

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is pancakeswap pair.
        uint256 contractTokenBalance = balanceOf(address(this));
        
        bool overMinTokenBalance = contractTokenBalance >= _numTokensSellToAndTransfer;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != pancakePair &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = _numTokensSellToAndTransfer;
            //add liquidity
            swapAndLiquify(contractTokenBalance);
        }
        
        //indicates if fee should be deducted from transfer
        bool takeFee = true;
        
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        
        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from,to,amount,takeFee);
    }
    
    function swapAndLiquify(uint256 tokenBalance) private lockTheSwap {
        // first split contract into  fee and liquidity fee
        uint256 liquidityAmount = tokenBalance;
        uint256 initialBalance = address(this).balance;


        if(_externalFee > 0)
        {
            uint256 externalAmount = tokenBalance.mul(_externalFee);
            externalAmount = externalAmount.div(_totalLiquidityFee);
            liquidityAmount = tokenBalance.sub(externalAmount);

            // send tokens to external
            swapTokensForEth(_externalAddress, externalAmount);
            initialBalance = address(this).balance;
        }
        
        if(_liquidityFee > 0)
        {
            // split the liquidity token balance into halves
            uint256 half = liquidityAmount.div(2);
            uint256 otherHalf = liquidityAmount.sub(half);

            // capture the contract's current ETH balance.
            // this is so that we can capture exactly the amount of ETH that the
            // swap creates, and not make the liquidity event include any ETH that
            // has been manually sent to the contract

            // swap half liquidity tokens for ETH
            swapTokensForEth(address(this), half);
            
            // how much ETH did we just swap into?
            uint256 newBalance = address(this).balance.sub(initialBalance);

            // add liquidity to pancakeswap
            addLiquidity(owner(), otherHalf, newBalance);
            
            emit SwapAndLiquify(half, newBalance, otherHalf);
        }
    }
    
    function swapTokensForEth(address recipient, uint256 tokenAmount) private {
        // generate the pancakeswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeRouter.WETH();

        _approve(address(this), address(pancakeRouter), tokenAmount);

        // make the swap
        pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            recipient,
            block.timestamp
        );
    }
    
    function addLiquidity(address recipient, uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(pancakeRouter), tokenAmount);

        // add the liquidity
        pancakeRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            recipient,
            block.timestamp
        );
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
    
    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 bFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        _burn(sender, bFee);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 bFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        _burn(sender, bFee);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 bFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        _burn(sender, bFee);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 bFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        _burn(sender, bFee);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function blacklistSingleWallet(address addresses) public onlyOwner(){
        if(_isBlacklisted[addresses] == true) return;
        _isBlacklisted[addresses] = true;
    }
    
    function blacklistMultipleWallets(address[] calldata addresses) public onlyOwner(){
        require(addresses.length <= 800, "Can only blacklist 800 addresses per transaction");
        for (uint256 i; i < addresses.length; ++i) {
            _isBlacklisted[addresses[i]] = true;
        }
    }
    
    function isBlacklisted(address addresses) public view returns (bool){
        return _isBlacklisted[addresses];
    }
    
    function unBlacklistSingleWallet(address addresses) external onlyOwner(){
         if(_isBlacklisted[addresses] == false) return;
        _isBlacklisted[addresses] = false;
    }
    
    function unBlacklistMultipleWallets(address[] calldata addresses) public onlyOwner(){
        require(addresses.length <= 800, "Can only unblacklist 800 addresses per transaction");
        for (uint256 i; i < addresses.length; ++i) {
            _isBlacklisted[addresses[i]] = false;
        }
    }
    
    function setExternalToken(address externaltoken) external onlyOwner(){
        _externalToken = IBEP20(externaltoken);
    }
    
    function setIsExternalTokenHoldEnabaled(bool enable) external onlyOwner(){
        isExternalTokenHoldEnabled = enable;
    }

    function burnTokens(uint256 tokens) external {
        tokens = tokens.mul( 10**_decimals );
        require(msg.sender != address(0), "BEP20: burn from the zero address");
        require(tokens > 0, "Tokens value should be greater then Zero");
        require(tokens <= balanceOf(msg.sender), "Tokens value should be less then equal to your balance");
        
        uint256 rTokens = tokens.mul(_getRate());
        if(_isExcluded[msg.sender])
            _tOwned[msg.sender] = _tOwned[msg.sender].sub(tokens);
        _rOwned[msg.sender] = _rOwned[msg.sender].sub(rTokens);
        _tTotal = _tTotal.sub(tokens);
        _rTotal = _rTotal.sub(rTokens);

        emit Transfer(msg.sender, address(this), tokens);
    }
    
    function recoverBNB() public onlyOwner()
    {
        address payable recipient = _msgSender();
        if(address(this).balance > 0)
            recipient.transfer(address(this).balance);
    }
    
    //New Pancakeswap router version?
    //No problem, just change it!
    function setRouterAddress(address newRouter) public onlyOwner() {
        IPancakeRouter02 _newPancakeRouter = IPancakeRouter02(newRouter);
        pancakePair = IPancakeFactory(_newPancakeRouter.factory()).createPair(address(this), _newPancakeRouter.WETH());
        pancakeRouter = _newPancakeRouter;
    }

}