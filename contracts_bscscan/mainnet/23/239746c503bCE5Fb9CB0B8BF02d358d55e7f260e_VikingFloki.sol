/**
 *Submitted for verification at BscScan.com on 2021-10-06
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;



// Part: Address

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

// Part: Context

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// Part: IERC20

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

// Part: IPancakeFactory

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

// Part: IPancakePair

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

// Part: IPancakeRouter01

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

// Part: SafeMath

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

// Part: IPancakeRouter02

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

// Part: Ownable

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
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

    //Added function
    // 1 minute = 60
    // 1h 3600
    // 24h 86400
    // 1w 604800

    function getTime() public view returns (uint256) {
        return now;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = now + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(now > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

// File: VKF.sol

contract VikingFloki is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    
    IPancakeRouter02 public pancakeRouter;
    IPancakePair private pancakePair;
    address public immutable pancakePairAddress;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcludedFromReward;
	
	mapping(uint256 => address) public holderAddressMapping; //to get an address from the index
	mapping(address => bool) public buyerRecorded;
	uint256 public maxHolders;
	
	//Only the lottery manager can change these values
	mapping(address => uint256) public holderAmountOfBNBWonMapping;
	mapping(address => uint256) public holderNumberOfRoundsWonMapping;
	
	uint256 public lastRoundTotalPrize;
	uint256 public lastRoundTimestamp;
	address public biggestWinner;
	uint256 lotteryRounds; 
	address [] public lastRoundWinners;
	
	address [] public winner1ByRound;
	address [] public winner2ByRound;
	address [] public winner3ByRound;
	address [] public winner4ByRound;
	address [] public winner5ByRound;
	address [] public winner6ByRound;
	address [] public winner7ByRound;
	address [] public winner8ByRound;
	address [] public winner9ByRound;
	address [] public winner10ByRound;
	
	uint256 [] public totalRewardByRound;
	uint256 [] public timestampByRound;
	
    address[] private _excluded;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 10**9 * 10**9; // 1 B tokens
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 public _tFeeTotal;
    uint256 public _tBurnTotal;
    uint256 public _lotteryFeesTotal;

    string private _name = "VikingFloki";
    string private _symbol = "VKF";
    uint8 private _decimals = 9;

    uint256 public sumOfAllFees; //change to privvate

    uint256 public _burnFee = 1;
    uint256 private _previousBurnFee = _burnFee;

    uint256 public _taxFee = 2;
    uint256 private _previousTaxFee = _taxFee;

    uint256 public _liquidityFee = 2;
    uint256 private _previousLiquidityFee = _liquidityFee;

    uint256 public _marketingLotteryFee = 5; // 4 + 1%
    uint256 private _previousMarketingLotteryFee = _marketingLotteryFee;
    
    uint256 public sellPenalty = 5;
     uint256 private _previousSellPenalty = sellPenalty;

    uint256 public _maxTxAmount = 10**7 * 10**9; // 1% of supply or 10M tokens
    uint256 public minimumTokensBeforeSwap = 10**7 * 10**9;

    address payable public BNBDistributionAddress; //Forwards marketing funds + lottery

	address DEAD = 0x000000000000000000000000000000000000dEaD;
	address ZERO = 0x0000000000000000000000000000000000000000;
	address lotteryManager;
	
	address private dxSaleLocker = 0x2D045410f002A95EFcEE67759A92518fA3FcE677;
    address private disperseApp = 0xD152f549545093347A162Dce210e7293f1452150;
	address private dxSalePresaleFeeWallet = 0x548E03C19A175A66912685F71e157706fEE6a04D;
	
	address private pinkSalePresaleAddress;
	address private pinkSaleLpRouterAddress;

    bool isSelling;
	bool inSwapAndLiquify;
	bool public swapAndLiquifyEnabled = true; //Has to be disabled prior to finalizing contract
	
    //For potential future use in the DAPP
	bool public placeholderBool1;
	bool public placeholderBool2;
	uint256 public placeholderUint1;
	uint256 public placeholderUint2;
	address public placeholderAddress1;
	address public placeholderAddress2;
											
	event RewardLiquidityProviders(uint256 tokenAmount);
	event SwapAndLiquifyEnabledUpdated(bool enabled);
	event SwapAndLiquify(
	uint256 tokensSwapped,
	uint256 ethReceived,
	uint256 tokensIntoLiqudity);
	
	event LotteryRoundEnd  (
	address winner1, address winner2, address winner3, address winner4, address winner5, 
	address winner6, address winner7, address winner8, address winner9, address winner10, 
	address allTimeBiggestWinnerEvent, uint256 roundRewardTotalEvent, uint256 roundTimestampEvent);

    event BNBTransferError();

modifier lockTheSwap {
	inSwapAndLiquify = true;
	_;
	inSwapAndLiquify = false;
}

constructor () public {
	_rOwned[_msgSender()] = _rTotal;
	lotteryManager = _msgSender();
	holderAddressMapping[0] = _msgSender();
	buyerRecorded[_msgSender()] = true;
	maxHolders = 1;

    IPancakeRouter02 _pancakeRouter = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    
    address _pancakePairAddress = IPancakeFactory(_pancakeRouter.factory())
        .createPair(address(this), _pancakeRouter.WETH());

    pancakeRouter = _pancakeRouter;
    pancakePairAddress = _pancakePairAddress;

	_isExcludedFromFee[owner()] = true;
	_isExcludedFromFee[address(this)] = true;

	BNBDistributionAddress = payable(msg.sender);

	_isExcludedFromReward[_pancakePairAddress] = true;
	_isExcludedFromReward[dxSaleLocker] = true;
	_isExcludedFromReward[dxSalePresaleFeeWallet] = true;
	_isExcludedFromReward[ZERO] = true;
	_isExcludedFromReward[DEAD] = true;

	_isExcludedFromFee[dxSaleLocker] = true;
	
	lastRoundWinners.push(address(0));
	lastRoundWinners.push(address(0));
	lastRoundWinners.push(address(0));
	lastRoundWinners.push(address(0));
	lastRoundWinners.push(address(0));
	lastRoundWinners.push(address(0));
	lastRoundWinners.push(address(0));
	lastRoundWinners.push(address(0));
	lastRoundWinners.push(address(0));
	lastRoundWinners.push(address(0));

    sumOfAllFees = _burnFee.add(_taxFee).add(_liquidityFee).add(_marketingLotteryFee); 

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
	return ((_tTotal - balanceOf(DEAD)) - balanceOf(ZERO));
}

function balanceOf(address account) public view override returns (uint256) {
    if (_isExcludedFromReward[account]) return _tOwned[account];
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
    return _isExcludedFromReward[account];
}

function totalFees() public view returns (uint256) {
    return _tFeeTotal;
}

function totalBurn() public view returns (uint256) {
    return _tBurnTotal;
}

function minimumTokensBeforeSwapAmount() public view returns (uint256) {
    return minimumTokensBeforeSwap;
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
    require(!_isExcludedFromReward[account], "Account is already excluded");
    if(_rOwned[account] > 0) {
    _tOwned[account] = tokenFromReflection(_rOwned[account]);
    }
    _isExcludedFromReward[account] = true;
    _excluded.push(account);
}

function includeInReward(address account) external onlyOwner() {
    require(_isExcludedFromReward[account], "Account is already excluded");
    for (uint256 i = 0; i < _excluded.length; i++) {
        if (_excluded[i] == account) {
        _excluded[i] = _excluded[_excluded.length - 1];
        _tOwned[account] = 0;
        _isExcludedFromReward[account] = false;
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
    require(from != address(0), "ERC20: transfer from the zero address");
    require(to != address(0), "ERC20: transfer to the zero address");
    require(amount > 0, "Transfer amount must be greater than zero");
    
    if ( 
        to == pancakePairAddress && // sells only by detecting transfer to automated market maker pair
    	from != address(pancakeRouter) && //router -> pair is removing liquidity which shouldn't have max
        !_isExcludedFromFee[to] && //no max for those excluded from fees
		!_isExcludedFromFee[from] &&
        from != owner()
    ) { require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount."); }
    		
    
    if (!buyerRecorded[to]) {
        buyerRecorded[to] = true;
    	holderAddressMapping[maxHolders] = to;
    	maxHolders += 1;
    }
    
    uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinimumTokenBalance = contractTokenBalance >= minimumTokensBeforeSwap;
        if (overMinimumTokenBalance && !inSwapAndLiquify && from != pancakePairAddress && swapAndLiquifyEnabled) {
            swapAndLiquify(minimumTokensBeforeSwap);
        }
    
    
    bool takeFee = true;
    
    //if any account belongs to _isExcludedFromFee account then remove the fee
    if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
        takeFee = false;
    }
    
    _tokenTransfer(from,to,amount,takeFee);
}

function swapAndLiquify(uint256 swapTokensAtAmount) private lockTheSwap {
        
    uint256 tokensForLiquidity = ((swapTokensAtAmount.mul(_liquidityFee)).div(sumOfAllFees)).div(2);
    uint256 tokensForSwapping = swapTokensAtAmount.sub(tokensForLiquidity);
    
    uint256 initialBalance = address(this).balance;
    swapTokensForBNB(tokensForSwapping); //Get all the tokens in BNB, converts only the setpoint amount of tokens
    uint256 newBalance = address(this).balance - initialBalance;
    
    
    uint256 hypotheticalFullBNBBalance = (newBalance.mul(sumOfAllFees)).div(sumOfAllFees.sub(_liquidityFee/2)); //BNB if we swapped all tokens
    
    uint256 BNBForLiquidity = (hypotheticalFullBNBBalance.mul(_liquidityFee)).div(sumOfAllFees).div(2); 
    
    addLiquidity(tokensForLiquidity, BNBForLiquidity);
	
	uint256 BNBforTransfer = address(this).balance;
	
			
    (bool sent,) = BNBDistributionAddress.call{value: BNBforTransfer}("");
    	if (!sent) {
    		emit BNBTransferError();
    	}
    	
    	else {
    	    _lotteryFeesTotal.add(BNBforTransfer.div(5));
    	}
    }

function swapTokensForBNB(uint256 tokenAmount) private {
    // generate the uniswap pair path of token -> weth
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = pancakeRouter.WETH();
    
    _approve(address(this), address(pancakeRouter), tokenAmount);
    
    // make the swap
    pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
    tokenAmount,
    0, // accept any amount of ETH
    path,
    address(this), // The contract
    block.timestamp
    );
}

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(pancakeRouter), tokenAmount);

        // add the liquidity
        pancakeRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }


function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
    if(!takeFee)
    removeAllFee();
    
    if (_isExcludedFromReward[sender] && !_isExcludedFromReward[recipient]) {
    _transferFromExcluded(sender, recipient, amount);
    } else if (!_isExcludedFromReward[sender] && _isExcludedFromReward[recipient]) {
    _transferToExcluded(sender, recipient, amount);
    } else if (!_isExcludedFromReward[sender] && !_isExcludedFromReward[recipient]) {
    _transferStandard(sender, recipient, amount);
    } else if (_isExcludedFromReward[sender] && _isExcludedFromReward[recipient]) {
    _transferBothExcluded(sender, recipient, amount);
    } else {
    _transferStandard(sender, recipient, amount);
    }

    if(!takeFee)
    restoreAllFee();
}

function _transferStandard(address sender, address recipient, uint256 tAmount) private {
    if (recipient == pancakePairAddress) {
        isSelling = true;
    }
	uint256 currentRate =  _getRate();
	(uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn, uint256 tLiquidity) = _getValues(tAmount);
	uint256 rBurn =  tBurn.mul(currentRate);
	_rOwned[sender] = _rOwned[sender].sub(rAmount);
	_rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
	_takeLiquidity(tLiquidity);
	_reflectFee(rFee, rBurn, tFee, tBurn);
	emit Transfer(sender, recipient, tTransferAmount);
	isSelling = false;
}

function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
    if (recipient == pancakePairAddress) {
        isSelling = true;
    }
	uint256 currentRate =  _getRate();
	(uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn, uint256 tLiquidity) = _getValues(tAmount);
	uint256 rBurn =  tBurn.mul(currentRate);
	_rOwned[sender] = _rOwned[sender].sub(rAmount);
	_tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
	_rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
	_takeLiquidity(tLiquidity);
	_reflectFee(rFee, rBurn, tFee, tBurn);
	emit Transfer(sender, recipient, tTransferAmount);
	isSelling = false;
}

function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
	uint256 currentRate =  _getRate();
	(uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn, uint256 tLiquidity) = _getValues(tAmount);
	uint256 rBurn =  tBurn.mul(currentRate);
	_tOwned[sender] = _tOwned[sender].sub(tAmount);
	_rOwned[sender] = _rOwned[sender].sub(rAmount);
	_rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
	_takeLiquidity(tLiquidity);
	_reflectFee(rFee, rBurn, tFee, tBurn);
	emit Transfer(sender, recipient, tTransferAmount);
}

function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
	uint256 currentRate =  _getRate();
	(uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn, uint256 tLiquidity) = _getValues(tAmount);
	uint256 rBurn =  tBurn.mul(currentRate);
	_tOwned[sender] = _tOwned[sender].sub(tAmount);
	_rOwned[sender] = _rOwned[sender].sub(rAmount);
	_tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
	_rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
	_takeLiquidity(tLiquidity);
	_reflectFee(rFee, rBurn, tFee, tBurn);
	emit Transfer(sender, recipient, tTransferAmount);
}

function _reflectFee(uint256 rFee, uint256 rBurn, uint256 tFee, uint256 tBurn) private {
	_rTotal = _rTotal.sub(rFee).sub(rBurn);
	_tFeeTotal = _tFeeTotal.add(tFee);
	_tBurnTotal = _tBurnTotal.add(tBurn);
	_tTotal = _tTotal.sub(tBurn);
}

function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
	(uint256 tTransferAmount, uint256 tFee, uint256 tBurn, uint256 tLiquidity) = _getTValues(tAmount);
	(uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tBurn, tLiquidity, _getRate());
	return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tBurn, tLiquidity);
}

function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
	uint256 tFee = calculateTaxFee(tAmount);
	uint256 tBurn = calculateBurnFee(tAmount);
	uint256 tLiquidity = calculateLiquidityFee(tAmount);
	uint256 tTransferAmount = tAmount.sub(tFee).sub(tBurn).sub(tLiquidity);
	return (tTransferAmount, tFee, tBurn, tLiquidity);
}

function _getRValues(uint256 tAmount, uint256 tFee, uint256 tBurn, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
	uint256 rAmount = tAmount.mul(currentRate);
	uint256 rFee = tFee.mul(currentRate);
	uint256 rBurn = tBurn.mul(currentRate);
	uint256 rLiquidity = tLiquidity.mul(currentRate);
	uint256 rTransferAmount = rAmount.sub(rFee).sub(rBurn).sub(rLiquidity);
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
	if(_isExcludedFromReward[address(this)])
	_tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
}

function calculateTaxFee(uint256 _amount) private view returns (uint256) {
	return _amount.mul(_taxFee).div(10**2);
}

function calculateBurnFee(uint256 _amount) private view returns (uint256) {
	return _amount.mul(_burnFee).div(10**2);
}

function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
    if (isSelling) {
        return _amount.mul((_marketingLotteryFee.add(_liquidityFee).add(sellPenalty))).div(10**2);
    }
    
    else {
        return _amount.mul(_marketingLotteryFee.add(_liquidityFee)).div(10**2);
    }

}

function removeAllFee() private {
if(_taxFee == 0 && _burnFee == 0 && _marketingLotteryFee == 0) return;

	_previousTaxFee = _taxFee;
	_previousBurnFee = _burnFee;
	_previousLiquidityFee = _liquidityFee;
	_previousMarketingLotteryFee = _marketingLotteryFee;
	_previousSellPenalty = sellPenalty;

	_taxFee = 0;
	_burnFee = 0;
	_liquidityFee = 0;
	_marketingLotteryFee = 0;
	sellPenalty = 0;
}

function restoreAllFee() private {
	_taxFee = _previousTaxFee;
	_burnFee = _previousBurnFee;
	_liquidityFee = _previousLiquidityFee;
	_marketingLotteryFee = _previousMarketingLotteryFee;
}

function isExcludedFromFee(address account) public view returns(bool) {
	return _isExcludedFromFee[account];
}

function excludeFromFee(address account) public onlyOwner {
	_isExcludedFromFee[account] = true;
}

function includeInFee(address account) public onlyOwner {
	_isExcludedFromFee[account] = false;
}

function setTaxFeePercent(uint256 taxFee) external onlyOwner() {
	_taxFee = taxFee;
	sumOfAllFees = _burnFee.add(_taxFee).add(_liquidityFee).add(_marketingLotteryFee); 
}

function setBurnFeePercent(uint256 burnFee) external onlyOwner() {
	_burnFee = burnFee;
	sumOfAllFees = _burnFee.add(_taxFee).add(_liquidityFee).add(_marketingLotteryFee); 
}

function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {
	_liquidityFee = liquidityFee;
	sumOfAllFees = _burnFee.add(_taxFee).add(_liquidityFee).add(_marketingLotteryFee); 
}


function setMarketingLotteryFeePercent(uint256 MarketingLotteryFee) external onlyOwner() {
	_marketingLotteryFee = MarketingLotteryFee;
	sumOfAllFees = _burnFee.add(_taxFee).add(_liquidityFee).add(_marketingLotteryFee); 
}

function setPenaltyFee(uint256 _sellPenalty) external onlyOwner() {
	sellPenalty = _sellPenalty;
}


function setMaxTxPercent(uint256 maxTxPercent, uint256 maxTxDecimals) external onlyOwner() {
	_maxTxAmount = _tTotal.mul(maxTxPercent).div(10**(uint256(maxTxDecimals) + 2));
}

function setNumTokensSellToAddToLiquidity(uint256 _minimumTokensBeforeSwap) external onlyOwner() {
    minimumTokensBeforeSwap = _minimumTokensBeforeSwap;
}

function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
    swapAndLiquifyEnabled = _enabled;
    emit SwapAndLiquifyEnabledUpdated(_enabled);
}

function setPancakeRouterAddress(address _router) public onlyOwner {
    pancakeRouter = IPancakeRouter02(_router);
}

function whitelistDxSale(address _pinkSalePresaleAddress, address _pinkSaleLpRouterAddress) public onlyOwner {
      pinkSalePresaleAddress = _pinkSalePresaleAddress;
	_isExcludedFromReward[pinkSalePresaleAddress] = true;
	_isExcludedFromFee[pinkSalePresaleAddress] = true;

	pinkSaleLpRouterAddress = _pinkSaleLpRouterAddress;
	_isExcludedFromReward[pinkSaleLpRouterAddress] = true;
	_isExcludedFromFee[pinkSaleLpRouterAddress] = true;
  	}

function setDistributionAddress (address payable newDistributionContract) public onlyOwner {
	BNBDistributionAddress = payable(newDistributionContract);
}

function setLotteryManagerAddress (address newLotteryManager) public onlyOwner {
	lotteryManager = newLotteryManager;
}

function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
    for(uint256 i = 0; i < accounts.length; i++) {
        _isExcludedFromFee[accounts[i]] = excluded;
    }
}
		
function finalizeLotteryRound(address[] calldata accounts, address allTimeBiggestWinner, uint256 roundRewardTotal, uint256 roundTimestamp) public {
	require (msg.sender == lotteryManager);
	lotteryRounds += 1;
	uint256 roundIndividualPrize = roundRewardTotal.div(accounts.length);
	lastRoundTotalPrize = roundRewardTotal;
	lastRoundTimestamp = roundTimestamp;
	biggestWinner = allTimeBiggestWinner;
	
	for(uint256 i = 0; i < accounts.length; i++) {
		holderNumberOfRoundsWonMapping[accounts[i]] += 1;
		holderAmountOfBNBWonMapping[accounts[i]] += roundIndividualPrize;
		lastRoundWinners[i] = accounts[i];
	}
	
	emit LotteryRoundEnd  (accounts[0], accounts[1], accounts[2],  accounts[3], accounts[4], accounts[5], accounts[6], accounts[7], accounts[8], 
			accounts[9], allTimeBiggestWinner, roundRewardTotal, roundTimestamp);
			
	winner1ByRound.push(accounts[0]); winner2ByRound.push(accounts[1]); winner3ByRound.push(accounts[2]); winner4ByRound.push(accounts[3]);
	winner5ByRound.push(accounts[4]); winner6ByRound.push(accounts[5]); winner7ByRound.push(accounts[6]); winner8ByRound.push(accounts[7]);
	winner9ByRound.push(accounts[8]); winner10ByRound.push(accounts[9]);
	
	totalRewardByRound.push(roundRewardTotal);
	timestampByRound.push(roundTimestamp); //
}

function viewWinnersByRound (uint256 round) public view returns(address, address) {
   return(winner1ByRound[round], winner2ByRound[round]);
}

function viewRewardByRound (uint256 round) public view returns (uint256) {
    return totalRewardByRound[round];
}

function viewTimestampByRound (uint256 round) public view returns (uint256) {
    return timestampByRound[round];
}

function setPlaceholderBool1(bool setting) external {
    require (msg.sender == lotteryManager);
	placeholderBool1 = setting;
}

function setPlaceholderBool2(bool setting) external {
    require (msg.sender == lotteryManager);
	placeholderBool2 = setting;
}

function setPlaceholderUint1(uint256 setting) external {
    require (msg.sender == lotteryManager);
	placeholderUint1 = setting;
}

function setPlaceholderUint2(uint256 setting) external {
    require (msg.sender == lotteryManager);
	placeholderUint2 = setting;
}

function setPlaceholderAddress1(address setting) external {
    require (msg.sender == lotteryManager);
	placeholderAddress1= setting;
}

function setPlaceholderAddress2(address setting) external {
    require (msg.sender == lotteryManager);
	placeholderAddress1= setting;
}


//to recieve ETH from pancakeswapV2Router when swaping
receive() external payable {}
}