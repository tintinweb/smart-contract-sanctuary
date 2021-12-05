/**
 *Submitted for verification at BscScan.com on 2021-12-04
*/

/**


*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
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
    function Z_transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }
}

// pragma solidity >=0.5.0;

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

// pragma solidity >=0.5.0;

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

// pragma solidity >=0.6.2;

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

// pragma solidity >=0.6.2;

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

contract META100 is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
   
    address public _marketingWallet;
    address public _productDevelopmentWallet;
    address public _communityWallet;
    address public _devWallet;
   
    uint8 private _decimals = 7;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1000000000 * 10**_decimals; // 1 Billlion
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "META100";
    string private _symbol = "META100";

    uint256 public _impact1 = 100; // Price impact: 100 = 1%
    uint256 public _impact2 = 500; // Price impact: 500 = 5%

    // All fees are a percentage number

    //Project funding fee
    uint256 public _projectFee = 10; // this will change in sell and buy functions
    uint256 private _previousProjectFee = _projectFee;
 
    //Project funding split 
    //The total must be 100
    uint256 public _marketingFee = 60; //  60% of _projectFee, or 6% of total
    uint256 public _productDevelopmentFee = 30; // 30% of _projectFee, or 3% of total
    uint256 public _devFee = 10; // 10% of _projectFee, or 1% of total

    //Reflections - free tokens distribution to
    //              holders (a.k.a passive income)
    uint256 public _reflectionsFee = 1; // this will change in sell and buy functions
    uint256 private _previousReflectionsFee = _reflectionsFee;
    
    uint256 public _buyProjectFee = 10;
    uint256 public _buyReflectionsFee = 0;
    uint256 public _sellProjectFeeA = 10; // Normal fee up to price impact1
    uint256 public _sellProjectFeeB = 20; // Higher fee up to price impact2
    uint256 public _sellProjectFeeC = 30; // Highest fee above price impact2 (anti-dump)
    uint256 public _sellReflectionsFeeA = 1;
    uint256 public _sellReflectionsFeeB = 1;
    uint256 public _sellReflectionsFeeC = 1;
    uint256 public _transferProjectFee = 5;
    uint256 public _transferReflectionsFee = 0;
    uint256 public _exchangeProjectFee = 0;
    uint256 public _exchangeReflectionsFee = 0;

    mapping(address => bool) private isBlacklisted;
    mapping(address => bool) private AllowedExchanges;
    mapping(address => bool) private AllowedBridges;
    mapping(address => uint256) private BridgeProjectFee;
    mapping(address => uint256) private BridgeReflectionsFee;

    mapping(address => bool) public Managers;
    mapping(address => bool) public Admins;
    mapping(address => bool) public Devs;

    mapping(address => uint256) private sell_AllowedTime;
    uint256 public sell_AntiDump_WaitSecs = 60;
    bool private antiDumpEnabled = false;

    uint256 public _maxTokensAmount = _tTotal;
    uint256 public _minTokensAmount = 0;
                
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    bool public feesEnabled = false;
    bool private isTrade = true;
    
    bool ProjectFundingSwapMode;
    bool public ProjectFundingEnabled = false;
    bool public tradingEnabled = false;
    uint256 private minTokensBeforeSwap = 100000 * 10**_decimals; // 0.01%

    event ProjectFundingEnablingUpdated(bool enabled);
    event ProjectFundingDone(
        uint256 tokensSwapped,
        address indexed address01,
		uint256 amount01,
		address indexed address02,
		uint256 amount02
    );
    event TokensSentToCommunityWallet (
		address indexed recipient,
		uint256  amount
	);
    event ManagerAdded(address indexed account);
    event ManagerRemoved(address indexed account);
    event AdminAdded(address indexed account);
    event AdminRemoved(address indexed account);
    event DevAdded(address indexed account);
    event DevRemoved(address indexed account);
    event MaxTokensAmountUpdated(uint256 _maxTokensAmount);
    event MinTokensAmountUpdated(uint256 _minTokensAmount);

    modifier lockTheSwap {
        ProjectFundingSwapMode = true;
        _;
        ProjectFundingSwapMode = false;
    }
    modifier onlyManager() {
       require(Managers[msg.sender] || msg.sender == owner(), "Not Manager");
        _;
    }
    modifier onlyAdmin() {
       require(Managers[msg.sender] || Admins[msg.sender] || msg.sender == owner(), "Not Admin");
        _;
    }
    modifier onlyDev() {
       require(Devs[msg.sender], "Not Dev");
        _;
    }

    constructor () {
        _rOwned[_msgSender()] = _rTotal;
        
        // PancakeSwap V2 Router
        //IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        // On BSC Testnet:
         IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);  
        
            
         // Create a pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // Set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;
        
        // Exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        _marketingWallet = msg.sender;
        _productDevelopmentWallet = msg.sender;
        _communityWallet = msg.sender;
        _devWallet = msg.sender;
        
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "Transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "Decreased allowance below zero"));
        return true;
    }
    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }
    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
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
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "Approve from the zero address is not allowed");
        require(spender != address(0), "Approve to the zero address is not allowed");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "Transfer from the zero address is not allowed");
        require(to != address(0), "Transfer to the zero address is not allowed");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!isBlacklisted[from], "Sender address is blacklisted");
		require(!isBlacklisted[to], "Recipient address is blacklisted");
        
        if (from != owner() && !tradingEnabled) {
            require(tradingEnabled, "Trading disabled");
        }
        if (from != owner() && to != owner() && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
            
            if (from != address(this) && to != address(this) && from != address(uniswapV2Router) && to != address(uniswapV2Router)) {
                require(amount <= _maxTokensAmount, "Anti-Dump measure. Token amount exceeds the max amount.");
                require(amount >= _minTokensAmount, "Anit-Bot measure. Token amount insufficient.");            
            }
            if (to != address(uniswapV2Router)) {
                require(amount <= _maxTokensAmount, "Anti-Dump measure. Token amount exceeds the max amount.");
                require(amount >= _minTokensAmount, "Anit-Bot measure. Token amount insufficient.");
                isTrade = true;
                _projectFee = _buyProjectFee; 
                _reflectionsFee = _buyReflectionsFee;
            }
            if (from != uniswapV2Pair && to != address(uniswapV2Pair)) {
                require(amount <= _maxTokensAmount, "Anti-Dump measure. Token amount exceeds the max amount.");
                require(amount >= _minTokensAmount, "Anit-Bot measure. Token amount insufficient.");
                isTrade = false;

                if (AllowedExchanges[from] || AllowedExchanges[to]) {
                    _projectFee = _exchangeProjectFee; 
                    _reflectionsFee = _exchangeReflectionsFee;
                }
                else if (AllowedBridges[from]) {
                        _projectFee = BridgeProjectFee[from];
                        _reflectionsFee = BridgeReflectionsFee[from];
                }
                else if (AllowedBridges[to]) {
                        _projectFee = BridgeProjectFee[to];
                        _reflectionsFee = BridgeReflectionsFee[to];
                }
                else {
                        _projectFee = _transferProjectFee; 
                        _reflectionsFee = _transferReflectionsFee;
                }            
            }
            if (from != uniswapV2Pair && to == address(uniswapV2Pair)) {
                require(amount <= _maxTokensAmount, "Anti-Dump measure. Token amount exceeds the max amount.");
                require(amount >= _minTokensAmount, "Anit-Bot measure. Token amount insufficient.");
                isTrade = true;

                if (antiDumpEnabled) {
                    require(block.timestamp > sell_AllowedTime[from]);
                }

                if (amount <= balanceOf(uniswapV2Pair).div(10000).mul(_impact1)) {
                    require (amount <= balanceOf(uniswapV2Pair).div(10000).mul(_impact1));
                    _projectFee = _sellProjectFeeA;
                    _reflectionsFee = _sellReflectionsFeeA;

                } else if (amount <= balanceOf(uniswapV2Pair).div(10000).mul(_impact2)) {
                    require (amount <= balanceOf(uniswapV2Pair).div(10000).mul(_impact2));
                    _projectFee = _sellProjectFeeB;
                    _reflectionsFee = _sellReflectionsFeeB;
                    
                } else {
                    _projectFee = _sellProjectFeeC;
                    _reflectionsFee = _sellReflectionsFeeC;

                }   
            }           
        }
        uint256 contractTokenBalance = balanceOf(address(this));
        
        if (contractTokenBalance >= _maxTokensAmount)
        {
           contractTokenBalance = _maxTokensAmount;
        }

        bool overMinTokenBalance = contractTokenBalance >= minTokensBeforeSwap;
        if (
            overMinTokenBalance &&
            !ProjectFundingSwapMode &&
            from != uniswapV2Pair &&
            ProjectFundingEnabled
        ) {
            projectFundingSwap(contractTokenBalance);
        }
        
        //indicates if fee should be deducted from transfer
        bool takeFee = true;
        
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to] || !feesEnabled){
            takeFee = false;
        }
        
        _tokenTransfer(from,to,amount,takeFee);
        restoreAllFee;

        if (isTrade && antiDumpEnabled) {
            sell_AllowedTime[from] = block.timestamp + sell_AntiDump_WaitSecs;
        }
    }
    function projectFundingSwap(uint256 contractTokenBalance) private lockTheSwap {
        
        // check tokens in contract
        uint256 tokensbeforeSwap = contractTokenBalance;
        
        // swap tokens for BNB
        swapTokensForBNB(tokensbeforeSwap);
        
        uint256 BalanceBNB = address(this).balance;

        // calculate the percentages
        uint256 marketingBNB = BalanceBNB.div(100).mul(_marketingFee);
        uint256 productDevelopmentBNB = BalanceBNB.div(100).mul(_productDevelopmentFee);
        uint256 devBNB = BalanceBNB.div(100).mul(_devFee);   

        //pay the Marketing wallet
        payable(_marketingWallet).transfer(marketingBNB);

        //pay the Product Development wallet
        payable(_productDevelopmentWallet).transfer(productDevelopmentBNB);

        //pay the SolidityDevs wallet
        payable(_devWallet).transfer(devBNB); 

        emit ProjectFundingDone(tokensbeforeSwap, _marketingWallet, marketingBNB, _productDevelopmentWallet, productDevelopmentBNB);  
    }
    function swapTokensForBNB(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
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
            owner(),
            block.timestamp
        );
    }
    //this method is responsible for taking all fee, if takeFee is true
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
        uint256 tFee = calculateReflectionsFee(tAmount);
        uint256 tLiquidity = calculateProjectFee(tAmount);
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
        if (isTrade) {
            _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
            if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity); 
        } else {
            _rOwned[address(_communityWallet)] = _rOwned[address(_communityWallet)].add(rLiquidity);
            emit TokensSentToCommunityWallet(_communityWallet, rLiquidity);

            if(_isExcluded[address(_communityWallet)])
            _tOwned[address(_communityWallet)] = _tOwned[address(_communityWallet)].add(tLiquidity); 
            emit TokensSentToCommunityWallet(_communityWallet, tLiquidity);
        }
    }
    function calculateReflectionsFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_reflectionsFee).div(100);
    }    
    function calculateProjectFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_projectFee).div(100);
    }    
    function removeAllFee() private {
        if(_reflectionsFee == 0 && _projectFee == 0) return;
        
        _previousReflectionsFee = _reflectionsFee;
        _previousProjectFee = _projectFee;
        
        _reflectionsFee = 0;
        _projectFee = 0;
    }    
    function restoreAllFee() private {
        _reflectionsFee = _previousReflectionsFee;
        _projectFee = _previousProjectFee;
    }   

    // Security

    function A1_addToBlacklist_BadActor(address account) public onlyAdmin {
        require(account != 0x10ED43C718714eb63d5aA57B78B54704E256024E, "PancakeSwap cannot be blacklisted");      
     	require(account != owner(), "Owner cannot be blacklisted");
		require(!Managers[account], "Manager cannot be blacklisted");
        require(!Admins[account], "Admin cannot be blacklisted");
		require(!Devs[account], "Devs cannot be blacklisted");		
        require(account != address(this), "Token contract cannot be blacklisted");	
		require(!isBlacklisted[account], "Address is already blacklisted");	
		
        isBlacklisted[account] = true;
    }
    function A2_removeFromBlacklist(address account) public onlyAdmin {
        require(isBlacklisted[account], "Address is already whitelisted");
        isBlacklisted[account] = false;
    }
	function A3_checkBlacklisted(address account) public view onlyAdmin returns (bool) {   
        return isBlacklisted[account];
    }
    
    // Anti-Dump settings

    function B1_check_AntiDump_Enabled() public view onlyAdmin returns (bool) {
        return antiDumpEnabled;
    }
    function B2_enable_AntiDump(bool true_false) external onlyManager() {
        antiDumpEnabled = true_false;
    }    
    function B3_set_AntiDump_SellWait(uint256 Wait_Secs) external onlyManager() {
        sell_AntiDump_WaitSecs = Wait_Secs;
    }
    function B4_get_AntiDump_SellWait() public view returns (uint256) {
        return sell_AntiDump_WaitSecs;
    }
    function B5_set_MaxTokensAmount(uint256 maxPercent) external onlyManager() { 
        _maxTokensAmount = _tTotal.mul(maxPercent).div(100);
        emit MaxTokensAmountUpdated(_maxTokensAmount);
    }
    function B6_set_MinTokensAmount(uint256 minTokensAmount) external onlyManager() { 
        _minTokensAmount = minTokensAmount;
        emit MinTokensAmountUpdated(_minTokensAmount);
    }

    // Trading, price impact and fees

    function C01_enable_Trading(bool true_false) external onlyManager() {
        tradingEnabled = true_false;
    }
    function C02_set_PriceImpact1(uint256 impact1) external onlyManager {
        // Example: 100 = 1% Price Impact
        _impact1 = impact1;
    }
    function C03_set_PriceImpact2(uint256 impact2) external onlyManager {
        // Example: 500 = 5% Price Impact
        _impact2 = impact2;
    }
    function C04_enableFees(bool true_false) external onlyManager() {
        feesEnabled = true_false;
    }
    function C05_enable_ProjectFunding(bool true_false) public onlyManager {
        ProjectFundingEnabled = true_false;
        emit ProjectFundingEnablingUpdated(true_false);
    }
    function C06_set_ProjectFundingFee(uint256 FeePercent) external onlyManager() {
        _projectFee = FeePercent;
    }
    function C07_set_MarketingFee(uint256 FeePercent) external onlyManager() {
        _marketingFee = FeePercent;
    }
    function C08_set_ProductDevelopmentFee(uint256 FeePercent) external onlyManager() {
        _productDevelopmentFee = FeePercent;
    }
    function C09_set_BuyReflectionsFee(uint256 FeePercent) external onlyManager() {
        _buyReflectionsFee = FeePercent;
    }
    function C10_set_DefaultReflectionsFee(uint256 FeePercent) external onlyManager() {
        _reflectionsFee = FeePercent;
    }
    function C11_set_SellReflectionsFeeA(uint256 FeePercent) external onlyManager() {
        _sellReflectionsFeeA = FeePercent;
    }
    function C12_set_SellReflectionsFeeB(uint256 FeePercent) external onlyManager() {
        _sellReflectionsFeeB = FeePercent;
    }
    function C13_set_SellReflectionsFeeC(uint256 FeePercent) external onlyManager() {
        _sellReflectionsFeeC = FeePercent;
    }
    function C14_set_TransferReflectionsFee(uint256 FeePercent) external onlyManager() {
        _transferReflectionsFee = FeePercent;
    }
    function C15_set_BuyProjectFee(uint256 FeePercent) external onlyManager() {
        _buyProjectFee = FeePercent;
    }
    function C16_set_SellProjectFeeA(uint256 FeePercent) external onlyManager() {
        _sellProjectFeeA = FeePercent;
    }
    function C17_set_SellProjectFeeB(uint256 FeePercent) external onlyManager() {
        _sellProjectFeeB = FeePercent;
    }
    function C18_set_SellProjectFeeC(uint256 FeePercent) external onlyManager() {
        _sellProjectFeeC = FeePercent;
    }
    function C19_set_TransferProjectFee(uint256 FeePercent) external onlyManager() {
        _transferProjectFee = FeePercent;
    }

    function C20_includeInFee(address account) public onlyManager {
        _isExcludedFromFee[account] = false;
    }
    function C21_excludeFromFee(address account) public onlyManager {
        _isExcludedFromFee[account] = true;
    }
    function C22_check_ExcludedFromFee(address account) public view onlyManager returns(bool) {
        return _isExcludedFromFee[account];
    }
    function C23_includeInReward(address account) external onlyManager() {
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
    function C24_excludeFromReward(address account) public onlyManager() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }   

    // Project wallets

    function D1_set_MarketingWallet(address account) public onlyManager() {
        _marketingWallet = account;
    }
    function D2_set_ProductDevelopmentWallet(address account) public onlyManager() {
        _productDevelopmentWallet = account;
    }
    function D3_set_CommunityWallet(address account) public onlyManager() {
        _communityWallet = account;
    }
    function D4_set_DevWallet(address account) public onlyDev() {
        _devWallet = account;
    }

    // Managers, Admins, Devs

    function E1_add_Manager(address account) external onlyOwner {
        require(account != address(0) && !Managers[account] && account != owner(),"Cannot add Manager");
        Managers[account] = true;
        emit ManagerAdded(account);
    }
    function E2_add_Admin(address account) external onlyManager {
        require(account != address(0) && !Admins[account] && account != owner(),"Cannot add Admin");
        Admins[account] = true;
        emit AdminAdded(account);
    }
    function E3_add_Dev(address account) external onlyDev {
        require(account != address(0) && !Devs[account],"Cannot add Dev");
        Devs[account] = true;
        emit DevAdded(account);
    }
    function E4_remove_Manager(address account) external onlyOwner {
        require(account != address(0) && Managers[account] && account != owner(),"Cannot remove Manager");
        Managers[account] = false;
        emit ManagerRemoved(account);
    }
    function E5_remove_Admin(address account) external onlyManager {
        require(account != address(0) && Admins[account] && account != owner(),"Cannot remove Admin");
        Admins[account] = false;
        emit AdminRemoved(account);
    }
    function E6_remove_Dev(address account) external onlyDev {
        require(account != address(0) && Devs[account] && account != owner(),"Cannot remove Dev");
        Devs[account] = false;
        emit DevRemoved(account);
    }
	function E7_check_Manager(address account) public view returns (bool) {   
        return Managers[account];
    }
    function E8_check_Admin(address account) public view returns (bool) {   
        return Admins[account];
    }	
    function E9_check_Dev(address account) public view returns (bool) {   
        return Devs[account];
    }

    // Exchanges

    function F1_addAllowedExchange(address account) public onlyManager {
        require(!AllowedExchanges[account], "Cannot add Exchange, it is already in the list");
        AllowedExchanges[account] = true;
    }
    function F2_removeAllowedExchange(address account) public onlyManager {
        require(AllowedExchanges[account], "Cannot remove Exchange, it is not in the list ");
        AllowedExchanges[account] = false;
    }
    function F3_getAllowedExchange(address account) public view returns(bool) {
        return AllowedExchanges[account];
    }
    function F5_setExchangeProjectFee(uint256 FeePercent) external onlyManager() {
        _exchangeProjectFee = FeePercent;
    }
    function F4_setExchangeReflectionsFee(uint256 FeePercent) external onlyManager() {
        _exchangeReflectionsFee = FeePercent;
    }

    // Bridges

    function G1_addBridge(address account, uint256 proj_fee, uint256 reflections_fee) public onlyManager {
        AllowedBridges[account] = true;
        BridgeProjectFee[account] = proj_fee;
        BridgeReflectionsFee[account] = reflections_fee;
    }
    function G2_removeBridge(address account) public onlyManager {
        delete AllowedBridges[account];
        delete BridgeProjectFee[account];
        delete BridgeReflectionsFee[account];
    }
    function G3_getAllowedBridges(address account) public view onlyManager returns(bool) {
        return AllowedBridges[account];
    }
    function G4_getBridgeProjectFee(address account) public view onlyManager returns(uint256) {
        return BridgeProjectFee[account];
    }
    function G5_getBridgeReflectionsFee(address account) public view onlyManager returns(uint256) {
        return BridgeReflectionsFee[account];
    }

     //To recieve BNB from PancakeSwap V2 Router when swaping
    receive() external payable {}
}