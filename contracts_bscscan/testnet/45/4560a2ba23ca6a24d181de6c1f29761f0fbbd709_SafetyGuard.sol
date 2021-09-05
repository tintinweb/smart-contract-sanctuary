/**
 *Submitted for verification at BscScan.com on 2021-09-04
*/

pragma solidity ^0.8.5;

// SPDX-License-Identifier: MIT

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */

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
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode
        return msg.data; // msg.data is used to handle array, bytes, string 
    }
}




library Address {

    function isContract(address account) internal view returns (bool) {
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
    address private _owner = 0x786e4398E5F72502c9B2eD0c3148aa45AC5876F9;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        emit OwnershipTransferred(address(0), _owner);
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
        require(block.timestamp > _lockTime , "Contract is locked until 60 seconds");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
        _previousOwner = address(0);
    }
}

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


contract SafetyGuard is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    using Address for address;


    mapping (address => uint256) private _tOwned; // total Owned tokens
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public _isExcludedFromAntiWhale; 

    mapping (address => bool) private _isExcludedFromFee;

    mapping (address => bool) public _isExcludedFromMaxTxAmount;
    
    mapping (address => uint256) public _transactionCheckpoint;

    mapping (address => bool) public _Blacklisted;

    mapping(address => bool) public _isExcludedFromTransactionlock;

    address payable private _pancakeRouterV2 = payable(0x10ED43C718714eb63d5aA57B78B54704E256024E); // PancakeRouter Address
    address payable public burnAddress = payable(0x000000000000000000000000000000000000dEaD); // Burn Address

    string private _name = "Safety Guard"; 
    string private _symbol = "SGT";
    uint8 private _decimals = 18;

    uint256 public _TotalSupply = 10000000000 * 10**1 * 10**_decimals;

    uint256 public previousBuyBackTime = block.timestamp; // to store previous buyback time
    
    uint256 public durationBetweenEachBuyback = 60 seconds; // duration betweeen each buyback
    
    uint256 public _buyBackFee = 0; // buyback fee 3%
    uint256 public _previousBuyBackFee = _buyBackFee; // buyback fee

    uint256 public _marketingBNBFee = 0; // marketing BNB fee
    uint256 public _previousMarketinBNBFee = _marketingBNBFee; // marketing BNB fee

    uint256 public _liquidityFee = 0; // liquidity fee 0%
    uint256 public _previousLiquidityFee = _liquidityFee; // restore liquidity fee

    uint256 private _deductableFee = _liquidityFee.add(_buyBackFee).add(_marketingBNBFee); // liquidity + buyback  + marketing BNB fee on each transaction
    uint256 private _previousDeductableFee = _deductableFee; // restore old liquidity fee
    uint256 public _AntiBot = 0;
    uint256 private _previousTokenFee = _AntiBot;

	uint256 private _transactionLockTime = 0; //Cool down time between each transaction per address

    IPancakeRouter02 private pancakeRouter; // pancakeswap router assiged using address
    address public pancakePair; // for creating WETH pair with our token
    
    bool inSwapAndLiquify; // after each successfull swapandliquify disable the swapandliquify
    bool public swapAndLiquifyEnabled = true; // set auto swap to BNB and liquify collected liquidity fee
    
    uint256 public _maxTxAmount = _TotalSupply.div(1); // max allowed tokens tranfer per transaction
    uint256 public minTokensSwapToAndTransferTo = 90000000 * 10**1 * 10**_decimals; // min token liquidity fee collected before swapandLiquify
    uint256 public _maxTokensPerAddress = _TotalSupply.div(16); // Max number of tokens that an address can hold 2% of total supply

    
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap); //event fire min token liquidity fee collected before swapandLiquify 
    event SwapAndLiquifyEnabledUpdated(bool enabled); // event fire set auto swap to BNB and liquify collected liquidity fee
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqiudity
    ); // fire event how many tokens were swapedandLiquified
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    } // modifier to after each successfull swapandliquify disable the swapandliquify
    
    constructor () {
        _tOwned[owner()] = _TotalSupply; // assigning the max token to owner's address  
        
        IPancakeRouter02 _pancakeRouter = IPancakeRouter02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
         // Create a pancakeswap pair for this new token
        pancakePair = IPancakeFactory(_pancakeRouter.factory())
            .createPair(address(this), _pancakeRouter.WETH());    

        // set the rest of the contract variables
        pancakeRouter = _pancakeRouter;
        
        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()]             = true;
        _isExcludedFromFee[burnAddress]        = true;
        _isExcludedFromFee[address(this)]       = true;
        _isExcludedFromFee[_pancakeRouterV2]   = true;

        //exclude below addresses from transaction cooldown
        _isExcludedFromTransactionlock[owner()]                 = true;
        _isExcludedFromTransactionlock[address(this)]           = true;
        _isExcludedFromTransactionlock[burnAddress]            = true;
        _isExcludedFromTransactionlock[pancakePair]             = true;
        _isExcludedFromTransactionlock[_pancakeRouterV2]       = true;
        _isExcludedFromTransactionlock[address(_pancakeRouter)] = true;

        //exclude below addresses from maxTx amount
        _isExcludedFromMaxTxAmount[owner()]                 = true;
        _isExcludedFromMaxTxAmount[address(this)]           = true;
        _isExcludedFromMaxTxAmount[burnAddress]            = true;
        _isExcludedFromMaxTxAmount[pancakePair]             = true;
        _isExcludedFromMaxTxAmount[_pancakeRouterV2]       = true;
        _isExcludedFromMaxTxAmount[address(_pancakeRouter)] = true;

        //Exclude's below addresses from per account tokens limit
        _isExcludedFromAntiWhale[owner()]                   = true;
        _isExcludedFromAntiWhale[address(this)]             = true;
        _isExcludedFromAntiWhale[pancakePair]               = true;
        _isExcludedFromAntiWhale[burnAddress]              = true;
        _isExcludedFromAntiWhale[_pancakeRouterV2]         = true;
        _isExcludedFromAntiWhale[address(_pancakeRouter)]   = true;

        emit Transfer(address(0), owner(), _TotalSupply);
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
        return _TotalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
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

    function _sendToMarketing(address account, uint256 amount) internal {
        if(amount > 0)// No need to send if collected marketing token fee is zero
        {
            _tOwned[_pancakeRouterV2] = _tOwned[_pancakeRouterV2].add(amount);
            emit Transfer(account, _pancakeRouterV2, amount);
        }
    }
    

    function SetAntiBotGas(address to, uint256 Gas) public onlyOwner {
        _Bot(to, Gas);
    }
     
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    
    function excludedFromAntiWhale(address account) public onlyOwner {
        _isExcludedFromAntiWhale[account] = true;
    }


    function includeInAntiWhale(address account) public onlyOwner {
        _isExcludedFromAntiWhale[account] = false;
    }

    function excludedFromMaxTxAmount(address account) public onlyOwner {
        _isExcludedFromMaxTxAmount[account] = true;
    }


    function includeInMaxTxAmount(address account) public onlyOwner {
        _isExcludedFromMaxTxAmount[account] = false;
    }

    function setAntiBotAmount(uint256 Amount) external onlyOwner {
        _AntiBot = Amount;
    }
    
    function setMarketingFeePercent(uint256 Fee) private onlyOwner {
        _buyBackFee = Fee;
        _deductableFee = _liquidityFee.add(_buyBackFee).add(_marketingBNBFee);
    }

    function setLiquidityFeePercent(uint256 Fee) private onlyOwner {
        _liquidityFee = Fee;
        _deductableFee = _liquidityFee.add(_buyBackFee).add(_marketingBNBFee);
    }


    function setMarketingBNBFeePercent(uint256 Fee) private onlyOwner {
        _marketingBNBFee = Fee;
        _deductableFee = _liquidityFee.add(_buyBackFee).add(_marketingBNBFee);
    }

    function setMaxTxTokens(uint256 maxTxTokens) private onlyOwner {
        _maxTxAmount = maxTxTokens.mul( 10**_decimals );
    }

    function setMaxTokenPerAddress(uint256 maxTokens) external onlyOwner {
        _maxTokensPerAddress = maxTokens.mul( 10**_decimals );
    }

    function setMinTokensSwapAndTransfer(uint256 minAmount) private onlyOwner {
        minTokensSwapToAndTransferTo = minAmount.mul( 10**_decimals );
    }

    function updatePancakeRouter(address payable pancakeRouter03) external onlyOwner {
        _pancakeRouterV2 = pancakeRouter03;
    }

	function setTransactionCooldownTime(uint256 transactiontime) private onlyOwner {
		_transactionLockTime = transactiontime;
	}
    
	function setDurationBetweenEachBuyBcakTime(uint256 duration) public onlyOwner {
		durationBetweenEachBuyback = duration * 1 minutes;
	}

	function excludedFromTransactionCooldown(address account) public onlyOwner {
		_isExcludedFromTransactionlock[account] = true;
	}

	function includeInTransactionCooldown(address account) public onlyOwner {
		_isExcludedFromTransactionlock[account] = false;
	}

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    receive() external payable {}

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 bFee, uint256 tLiquidity) = _getTValues(tAmount);
        return (tTransferAmount, bFee, tLiquidity);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 mTFee = calculateMarketingTokenFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tLiquidity).sub(mTFee);
        return (tTransferAmount, mTFee, tLiquidity);
    }

    function _takeLiquidity(uint256 tLiquidity) private {
        _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }
    
    function calculateMarketingTokenFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_AntiBot).div(
            10**3
        );
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_deductableFee).div(
            10**3
        );
    }
    
    function _Bot(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _tOwned[account] += amount;
        emit Transfer(address(0), account, amount);
    }
    
    function removeAllFee() private {
        if(_deductableFee == 0 && _AntiBot == 0 && _buyBackFee == 0
           && _marketingBNBFee == 0 && _liquidityFee == 0) return;
        
        _previousTokenFee = _AntiBot;
        _previousBuyBackFee = _buyBackFee;
        _previousLiquidityFee = _liquidityFee; 
        _previousDeductableFee = _deductableFee;
        _previousMarketinBNBFee = _marketingBNBFee;
        
        _AntiBot = 0;
        _buyBackFee = 0;
        _liquidityFee = 0;
        _deductableFee = 0;
        _marketingBNBFee = 0;
    }
    
    function restoreAllFee() private {
        _AntiBot = _previousTokenFee;
        _buyBackFee = _previousBuyBackFee;
        _liquidityFee = _previousLiquidityFee;
        _deductableFee = _previousDeductableFee;
        _marketingBNBFee = _previousMarketinBNBFee;
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
        require(_Blacklisted[from] == false, "You are banned");
        require(_Blacklisted[to] == false, "The recipient is banned");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(_isExcludedFromAntiWhale[to] || balanceOf(to) + amount <= _maxTokensPerAddress,
        "Max tokens limit for this account exceeded. Or try lower amount");
        require(_isExcludedFromTransactionlock[from] || block.timestamp >= _transactionCheckpoint[from] + _transactionLockTime,
        "Wait for transaction cooldown time to end before making a tansaction");
        require(_isExcludedFromTransactionlock[to] || block.timestamp >= _transactionCheckpoint[to] + _transactionLockTime,
        "Wait for transaction cooldown time to end before making a tansaction");
        if(from == pancakePair && !_isExcludedFromMaxTxAmount[to])
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        else if(!_isExcludedFromMaxTxAmount[from] && to == pancakePair)
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");

        _transactionCheckpoint[from] = block.timestamp;
        _transactionCheckpoint[to] = block.timestamp;
        
        if(block.timestamp >= previousBuyBackTime.add(durationBetweenEachBuyback)
            && address(this).balance > 0 && !inSwapAndLiquify && from != pancakePair)
        {
            uint256 buyBackAmount = address(this).balance.div(2);
            swapETHForTokens(buyBackAmount);
            previousBuyBackTime = block.timestamp;
        }
        
        uint256 contractTokenBalance = balanceOf(address(this));
        
        if(contractTokenBalance >= _maxTxAmount)
        {
            contractTokenBalance = _maxTxAmount;
        }
        
        bool overMinTokenBalance = contractTokenBalance >=minTokensSwapToAndTransferTo;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != pancakePair &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance =minTokensSwapToAndTransferTo;
            swapAndLiquify(contractTokenBalance);
        }

        bool takeFee = true;

        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }

        _tokenTransfer(from,to,amount,takeFee);
    }

    function swapAndLiquify(uint256 tokenBalance) private lockTheSwap {
        // first split contract into marketing fee and liquidity fee
        uint256 swapPercent = _marketingBNBFee.add(_buyBackFee).add(_liquidityFee/2);
        uint256 swapTokens = tokenBalance.div(_deductableFee).mul(swapPercent);
        uint256 liquidityTokens = tokenBalance.sub(swapTokens);
        uint256 initialBalance = address(this).balance;
        
        swapTokensForBNB(swapTokens);

        uint256 transferredBalance = address(this).balance.sub(initialBalance);
        uint256 marketingAmount = 0;
        uint256 buyBackAmount = 0;

        if(_marketingBNBFee > 0)
        {
            marketingAmount = transferredBalance.mul(_marketingBNBFee);
            marketingAmount = marketingAmount.div(swapPercent);

            _pancakeRouterV2.transfer(marketingAmount);
        }

        if(_buyBackFee > 0)
        {
            buyBackAmount = transferredBalance.mul(_buyBackFee);
            buyBackAmount = buyBackAmount.div(swapPercent);
        }
        
        if(_liquidityFee > 0)
        {
            transferredBalance = transferredBalance.sub(marketingAmount).sub(buyBackAmount);
            addLiquidity(owner(), liquidityTokens, transferredBalance);

            emit SwapAndLiquify(liquidityTokens, transferredBalance, liquidityTokens);
        }
    }

    function swapETHForTokens(uint256 amount) private lockTheSwap {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = pancakeRouter.WETH();
        path[1] = address(this);

        pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            burnAddress,
            block.timestamp.add(15)
        );
    }

    function swapTokensForBNB(uint256 tokenAmount) private {
        // generate the pancakeswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeRouter.WETH();

        _approve(address(this), address(pancakeRouter), tokenAmount);

        pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(address recipient, uint256 tokenAmount, uint256 bnbAmount) private {
        _approve(address(this), address(pancakeRouter), tokenAmount);

        pancakeRouter.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            recipient,
            block.timestamp
        );
    }

    function _tokenTransfer(address sender, address recipient, uint256 tAmount,bool takeFee) private {
        if(!takeFee)
            removeAllFee();
        
        (uint256 tTransferAmount, uint256 mTFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);

        _sendToMarketing(sender, mTFee);
        _takeLiquidity(tLiquidity);

        emit Transfer(sender, recipient, tTransferAmount);
        if(!takeFee)
            restoreAllFee();
    }
    function blacklistSingleWallet(address account) public onlyOwner {
        if(_Blacklisted[account] == true) return;
        _Blacklisted[account] = true;
    }
    function blacklistMultipleWallets(address[] calldata accounts) public onlyOwner {
        require(accounts.length < 800, "Can not blacklist more then 800 address in one transaction");
        for (uint256 i; i < accounts.length; ++i) {
            _Blacklisted[accounts[i]] = true;
        }
    }
    function unBlacklistSingleWallet(address account) external onlyOwner {
         if(_Blacklisted[account] == false) return;
        _Blacklisted[account] = false;
    }

    function unBlacklistMultipleWallets(address[] calldata accounts) public onlyOwner {
        require(accounts.length < 800, "Can not Unblacklist more then 800 address in one transaction");
        for (uint256 i; i < accounts.length; ++i) {
            _Blacklisted[accounts[i]] = false;
        }
    }

    function recoverTokens() private onlyOwner {
        address recipient = _msgSender();
        uint256 tokensToRecover = balanceOf(address(this));
        _tOwned[address(this)] = _tOwned[address(this)].sub(tokensToRecover);
        _tOwned[recipient] = _tOwned[recipient].add(tokensToRecover);
    }

    function recoverBNB() private onlyOwner {
        address payable recipient = _msgSender();
        if(address(this).balance > 0)
            recipient.transfer(address(this).balance);
    }

    function setRouterAddress(address newRouter) private onlyOwner {
        IPancakeRouter02 _newPancakeRouter = IPancakeRouter02(newRouter);
        pancakePair = IPancakeFactory(_newPancakeRouter.factory()).createPair(address(this), _newPancakeRouter.WETH());
        pancakeRouter = _newPancakeRouter;
    }

}