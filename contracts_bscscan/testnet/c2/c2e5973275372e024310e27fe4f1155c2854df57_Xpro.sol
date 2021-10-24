/**
 *Submitted for verification at BscScan.com on 2021-10-23
*/

/** 
 update 9 -

 TRADING ON/OFF -OK
 BUY FEE -OK
 SELL FEE -OK
 MAX WALLET -OK
 MAX BUY -OK
 MAX SELL -OK
 MIN WALLET -OK
 EXCLUDE ADDRESS FROM MAX TX -OK
 SWAP TOKEN MUST BELOW MAX SELL TXN -OK
 SWAP BNB -OK
 ADD LIQUIDITY FROM OTHER WALLET WHILE TRADING OFF CANNOT -OK
 OWNER & PRESALE WALLET CAN TRANSFER BEFORE TRADING-ON -OK
 TRNSFR CONTRACT TOKEN TO OTHER WALLET NO FEE -OK
 TRNSFR FROM OWNER TO BURN ADDRESS NO FEE -OK
 TRNSFR FROM OWNER TO OTHER WALLET NO FEE & NO MAX WALLET -OK
 LIMIT SELL LOCK TIME CAN BUY, CAN TRANSFER, CANT SELL & GOT MAX WALLET AMOUNT -OK
 LOCK WALLET CAN BUY, CANT SELL, CANT TRANSFER TO OTHER WALLET -OK
 TRNSFR FROM OTHER WALLET TO OTHER WALLET CANNOT WHILE TRADING OFF -OK
 TRNSFR FROM OTHER WALLET TO OTHER WALLET GOT BUY FEE & NO MIN WALLET -OK
 TRNSFR FROM OTHER WALLET TO OTHER WALLET GOT MAX WALLET AMOUNT -OK

 ALL FINISHED LOUD & CLEAR

 
*/

pragma solidity 0.8.9;
// SPDX-License-Identifier: Unlicense

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
	
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
        if (a == 0) { return 0; }

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

interface IPancakeSwapV2Factory {
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

interface IPancakeSwapV2Pair {
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

interface IPancakeSwapV2Router01 {
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

interface IPancakeSwapV2Router02 is IPancakeSwapV2Router01 {
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

contract Xpro is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    using Address for address;
	
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => uint256) private _transactionCheckpoint;
    mapping (address => uint256) private _transactionCheckpointAmt;  
    mapping (address => bool) private _isExcludedFromFee;
	mapping (address => bool) private _isExcludeAddressFromMaxTx;
	mapping (address => bool) private _isLockedWallet;
    mapping (address => bool) private _isExcluded;
    mapping (address => bool) private _isExcludedFromTxlock;
    mapping (address => bool) private canTransferBeforeTradingOn;
    mapping (address => mapping (address => uint256)) private _allowances;
       
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1000000000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private constant _name    = "X-Pro";
    string private constant _symbol  = "XPRO";
    uint8 private constant _decimals = 9;
    
    uint256 public taxFee       = 100; // Fee that gets re-distributed to holders.
    uint256 public liquidityFee = 200;
    uint256 public buybackFee   = 100;
    uint256 public marketingFee = 300;
    uint256 public researchFee  = 300;

    uint256 private _buyTaxFee       = 100;
    uint256 private _buyLiquidityFee = 200;
    uint256 private _buyBuybackFee   = 100;
    uint256 private _buyMarketingFee = 300;
    uint256 private _buyResearchFee  = 300;
    
    uint256 private _sellTaxFee       = 300;
    uint256 private _sellLiquidityFee = 400;
    uint256 private _sellBuybackFee   = 400;
    uint256 private _sellMarketingFee = 700;
    uint256 private _sellResearchFee  = 700;

    uint256 private totalLiqFee = liquidityFee.add(buybackFee).add(marketingFee).add(researchFee);
    uint256 private totalBuyFee = _buyLiquidityFee.add(_buyBuybackFee).add(_buyMarketingFee).add(_buyResearchFee);
    uint256 private totalSellFee = _sellLiquidityFee.add(_sellBuybackFee).add(_sellMarketingFee).add(_sellResearchFee);
	
    IPancakeSwapV2Router02 public pancakeSwapV2Router;
    address public pancakeSwapV2Pair;
    address payable public _buybackWallet;
    address payable public _marketingWallet;
    address payable public _researchWallet;
    address constant public _burnAddress = 0x000000000000000000000000000000000000dEaD;
    address[] private _excluded;
        
    bool inSwapAndLiquify;
    bool public lockTime = false;
    bool public tradingOn = false;
    bool public swapAndLiquifyEnabled = false;
    
    uint256 public _buyMaxTxAmount  = 2000000 * 10**9; // 0.2% percent of total supply per buy transaction
    uint256 private _sellMaxTxAmount = 550000 * 10**9; // 0.05% percent of total supply per sell transaction
    uint256 public _sellMaxTxAmount2 = 500000 * 10**9;
    uint256 public _maxWalletAmount = 5000000 * 10**9; // 0.5% of total supply  
    uint256 public _minWalletAmount = 100000 * (10**9); // 0.01% of total supply for safety
    uint256 private numTokensSellToAddToLiquidity = 500000 * 10**9; // 0.05% tx amount will trigger swap and add liquidity
    uint256 private _txLockTime = 24 * 1 hours; // 1 Day

    event TradingOn();
    event SetPreSaleWallet(address wallet);
    event LockedWallet(address indexed wallet, bool locked);
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event UpdatePancakeswapV2Router(address indexed newAddress, address indexed oldAddress);
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
    
    constructor (address payable buybackWallet, address payable marketingWallet, address payable researchWallet, address pancakeSwapRouter) {
        _rOwned[_msgSender()] = _rTotal;
		
        _buybackWallet = buybackWallet;
	    _marketingWallet = marketingWallet;
        _researchWallet = researchWallet;

        IPancakeSwapV2Router02 _pancakeSwapV2Router = IPancakeSwapV2Router02(pancakeSwapRouter);

        pancakeSwapV2Pair = IPancakeSwapV2Factory(_pancakeSwapV2Router.factory())
            .createPair(address(this), _pancakeSwapV2Router.WETH());

        pancakeSwapV2Router = _pancakeSwapV2Router;

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[address(_burnAddress)] = true;
        _isExcludedFromFee[address(_buybackWallet)] = true;
        _isExcludedFromFee[address(_marketingWallet)] = true;
        _isExcludedFromFee[address(_researchWallet)] = true;

        _isExcludeAddressFromMaxTx[owner()] = true;
        _isExcludeAddressFromMaxTx[address(this)] = true;
        _isExcludeAddressFromMaxTx[address(_burnAddress)] = true;
        _isExcludeAddressFromMaxTx[address(_buybackWallet)] = true;
        _isExcludeAddressFromMaxTx[address(_marketingWallet)] = true;
        _isExcludeAddressFromMaxTx[address(_researchWallet)] = true;
        _isExcludeAddressFromMaxTx[address(pancakeSwapV2Router)] = true;

        _isExcludedFromTxlock[owner()] = true;
        _isExcludedFromTxlock[address(this)] = true;
        _isExcludedFromTxlock[address(_burnAddress)] = true;
        _isExcludedFromTxlock[address(_buybackWallet)] = true;
        _isExcludedFromTxlock[address(_marketingWallet)] = true;
        _isExcludedFromTxlock[address(_researchWallet)] = true;
        _isExcludedFromTxlock[address(pancakeSwapV2Router)] = true;

        canTransferBeforeTradingOn[owner()] = true;
        canTransferBeforeTradingOn[address(this)] = true;

        _isExcluded[address(_burnAddress)] = true;      
		
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

    function SetLockTime(uint32 newHours) external onlyOwner {
        _txLockTime = newHours * 1 hours;
    }

    function StartLockTime() public onlyOwner() {
        lockTime = true;
    }
    
    function StopLockTime() public onlyOwner() {
        lockTime = false;
    }

    function swapBnb() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    function swapTokens() external onlyOwner() {
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

    function transferTokens(address token, address recipient, uint256 amount) public onlyOwner returns(bool _send) {
        _send = IBEP20(token).transfer(recipient, amount);
    }

    function TradingOFF() external onlyOwner {
        tradingOn = false;
    }

    function TradingON() external onlyOwner {
        require(!tradingOn);

        tradingOn = true;
        emit TradingOn();
    }

    function lockWallet(address account) external onlyOwner {
        _isLockedWallet[account] = true;
        emit LockedWallet(account, true);
    }

    function unLockWallet(address account) external onlyOwner {
        _isLockedWallet[account] = false;
        emit LockedWallet(account, false);
    }
    
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
	
	function excludeAddressFromMaxTx(address account) public onlyOwner {
        _isExcludeAddressFromMaxTx[account] = true;
    }
    
    function includeAddressFromMaxTx(address account) public onlyOwner {
        _isExcludeAddressFromMaxTx[account] = false;
    }
    
    function setNumTokensSellToAddToLiquidity(uint256 amount) external onlyOwner() {
        numTokensSellToAddToLiquidity = amount.mul(10**_decimals);
    }

    function setFee(uint256 fee, uint256 BbFee, uint256 LqFee, uint256 MktFee, uint256 RFee) external onlyOwner() {
        taxFee = fee;
        buybackFee = BbFee;
        liquidityFee = LqFee;
        marketingFee = MktFee;
        researchFee = RFee;
    }

    function setBuyFee(uint256 Taxfee, uint256 BuybackFee, uint256 LiquidityFee, uint256 MarketingFee, uint256 ResearchFee) external onlyOwner() {
        _buyTaxFee = Taxfee;
        _buyBuybackFee = BuybackFee;
        _buyLiquidityFee = LiquidityFee;
        _buyMarketingFee = MarketingFee;
        _buyResearchFee = ResearchFee;
    }

    function setSellFee(uint256 SellTaxfee, uint256 SellBuybackFee, uint256 SellLiquidityFee, uint256 SellMarketingFee, uint256 SellResearchFee) external onlyOwner() {
        _sellTaxFee = SellTaxfee;
        _sellBuybackFee = SellBuybackFee;
        _sellLiquidityFee = SellLiquidityFee;
        _sellMarketingFee = SellMarketingFee;
        _sellResearchFee = SellResearchFee;
    }
    
    function setMaxTxAmount(uint256 buyTxAmount, uint256 sellTxAmount, uint256 sellTxAmount2, uint256 maxWalletAmount, uint256 minWalletAmount) external onlyOwner() {
        _buyMaxTxAmount = buyTxAmount.mul(10**_decimals);
        _sellMaxTxAmount = sellTxAmount.mul(10**_decimals);
        _sellMaxTxAmount2 = sellTxAmount2.mul(10**_decimals);
        _maxWalletAmount = maxWalletAmount.mul(10**_decimals);
        _minWalletAmount = minWalletAmount.mul(10**_decimals);
    }
	
	function setWalletAddress(address payable buybackWallet, address payable marketingWallet, address payable researchWallet) external onlyOwner() {
         _buybackWallet = buybackWallet;
         _marketingWallet = marketingWallet;
         _researchWallet = researchWallet;
    }

    function setPresaleWallet(address wallet) external onlyOwner {
        canTransferBeforeTradingOn[wallet] = true;
        _isExcludeAddressFromMaxTx[wallet] = true;
        _isExcludedFromFee[wallet] = true;
        _isExcludedFromTxlock[wallet] = true;

        emit SetPreSaleWallet(wallet);
    }
	
    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
    receive() external payable {}

    function GetLockTime() public view returns(uint256) {
        return _txLockTime.mul(1);
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function isLockedWallet(address account) public view returns(bool) {
        return _isLockedWallet[account];
    }
	
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }
	
	function isExcludeAddressFromMaxTx(address account) public view returns(bool) {
        return _isExcludeAddressFromMaxTx[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(tradingOn || canTransferBeforeTradingOn[from], "Trading has not yet been ON");
        require(!_isLockedWallet[from], "Locked addresses cannot call this function");
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if(!(_isExcludeAddressFromMaxTx[from] || _isExcludeAddressFromMaxTx[to])) {
            require(amount <= _buyMaxTxAmount, "Transfer amount exceeds the maxTxAmount");
            if (to != pancakeSwapV2Pair) {		            
                require(balanceOf(to).add(amount) <= _maxWalletAmount, "Exceeds max wallet amount");
            } else if (from != pancakeSwapV2Pair) {
		        require(amount <= _sellMaxTxAmount2, "Transfer amount exceeds the maxTxAmount");
                require(balanceOf(from).sub(amount) >= _minWalletAmount, "Exceeds min wallet amount");
            }

            if (!_isExcludedFromTxlock[from] && lockTime && (to == pancakeSwapV2Pair) && (from != pancakeSwapV2Pair) && from != owner() && to != owner()) {
                if( !(_transactionCheckpoint[from] >= 1) ) {
                    _transactionCheckpointAmt[from] = 1;
                }
                else if(block.timestamp - _transactionCheckpoint[from] >= _txLockTime) {
                    _transactionCheckpointAmt[from] = 1;
                }
                
                _transactionCheckpoint[from] = block.timestamp;
                
                require(_isExcludedFromTxlock[from] || (_transactionCheckpointAmt[from].add(amount) <= _sellMaxTxAmount), "Please wait for transaction cooldown time to finish");
    		    
                if(_transactionCheckpointAmt[from] > 1) {
                    _transactionCheckpointAmt[from] = _transactionCheckpointAmt[from].add(amount);
                } else {
                    _transactionCheckpointAmt[from] = amount;
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        
        if(contractTokenBalance >= _buyMaxTxAmount)
        {
            contractTokenBalance = _buyMaxTxAmount;
        }
		
        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        if (overMinTokenBalance && !inSwapAndLiquify && from != pancakeSwapV2Pair && swapAndLiquifyEnabled) {
            contractTokenBalance = numTokensSellToAddToLiquidity;
            swapAndLiquify(contractTokenBalance);
        }
        
        bool takeFee = true;
        
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        _tokenTransfer(from, to, amount, takeFee);
    }
	
    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);
        
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(half);
        uint256 balanceDiff = address(this).balance.sub(initialBalance);
        
        uint256 ethForBuyback = balanceDiff.mul(buybackFee).div(totalLiqFee);
        uint256 ethForMarketing = balanceDiff.mul(marketingFee).div(totalLiqFee);
        uint256 ethForResearch = balanceDiff.mul(researchFee).div(totalLiqFee);
        uint256 ethForLiquidity = balanceDiff.sub(ethForBuyback.add(ethForMarketing).add(ethForResearch));        
        addLiquidity(otherHalf, ethForLiquidity);
		emit SwapAndLiquify(half, ethForLiquidity, otherHalf);
		
        _buybackWallet.transfer(ethForBuyback);
		_marketingWallet.transfer(ethForMarketing);
        _researchWallet.transfer(ethForResearch);
    }
	
    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeSwapV2Router.WETH();

        _approve(address(this), address(pancakeSwapV2Router), tokenAmount);

        pancakeSwapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(pancakeSwapV2Router), tokenAmount);

        pancakeSwapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        uint256 _previousTaxFee      = taxFee;
        uint256 _previousTotalLiqFee = totalLiqFee;

        bool isBuy  = sender == pancakeSwapV2Pair && recipient != address(pancakeSwapV2Router);
        bool isSell = recipient == pancakeSwapV2Pair;

        if (!takeFee) {
            taxFee      = 0;
            totalLiqFee = 0;

        } else if (isBuy) { 
            taxFee      = _buyTaxFee;
            totalLiqFee = totalBuyFee;

        } else if (isSell) { 
            taxFee      = _sellTaxFee;
            totalLiqFee = totalSellFee;
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
        
        if (!takeFee || isBuy || isSell) {
            taxFee      = _previousTaxFee;
            totalLiqFee = _previousTotalLiqFee;
        }
    }
    
    function updatePCSRouter(address newAddress) public onlyOwner {
        require(newAddress != address(pancakeSwapV2Router), "The router already has that address");
        emit UpdatePancakeswapV2Router(newAddress, address(pancakeSwapV2Router));
        pancakeSwapV2Router = IPancakeSwapV2Router02(newAddress);
        
        pancakeSwapV2Pair = IPancakeSwapV2Factory(pancakeSwapV2Router.factory())
            .getPair(address(this), pancakeSwapV2Router.WETH());
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
	
	function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = tAmount.mul(taxFee).div(10000);
        uint256 tLiquidity = tAmount.mul(totalLiqFee).div(10000);
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
}     // TAMAT... KODINGAN KONTRAKNYA DAH SAMPE DISINI AJA YEEEE.... Contract created by @VhanzVJRS