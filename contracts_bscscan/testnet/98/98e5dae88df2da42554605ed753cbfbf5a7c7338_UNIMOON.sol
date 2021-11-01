/**
 *Submitted for verification at BscScan.com on 2021-11-01
*/

/*

UNIMOON:Live without Limits, The First L1 Blockchain Built To Decentralize Social Media For Everyone, Tokenized on BSC migrating to UNIMOON L1
UNIMOON.io

*/
// SPDX-License-Identifier: Unlicensed

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

    event TransferDetails(address indexed from, address indexed to, uint256 total_Amount, uint256 reflected_amount, uint256 total_TransferAmount, uint256 reflected_TransferAmount);
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
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }
    
    function owner() public view virtual returns (address) {
        return _owner;
    }
    
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// Begin sauce.
contract UNIMOON is Context, IERC20, Ownable {
    using Address for address;

    mapping (address => uint256) public _balance_reflected;
    mapping (address => uint256) public _balance_total;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    
    // bye bye bots
    mapping (address => bool) public _isBlacklisted;

    // for presale and airdrop
    mapping (address => bool) public _isWhitelisted;
    
    // add liquidity and do airdrops
    bool public tradingOpen = false;

    // Cooldown & timer functionality
    bool public buyCooldownEnabled = true;
    uint8 public cooldownTimerInterval = 60;
    mapping (address => uint) private cooldownTimer;
    
    address[] private _excluded;
    
    uint256 private constant MAX = ~uint256(0);

    uint8 private   _decimals           = 9;
    uint256 private _supply_total       = 2 * 10**15 * 10**_decimals;
    uint256 private _supply_reflected   = (MAX - (MAX % _supply_total));
    string private  _name               = "UNIMOON";
    string private  _symbol             = "UNIMOON";

    // 0 to disable conversion
    // an integer to convert only fixed number of tokens
    uint256 public _fee_buyback_convert_limit = _supply_total * 1 / 10000;
    uint256 public _fee_marketing_convert_limit = _supply_total * 1 / 10000;

    // Minimum Balance to maintain
    uint256 public _fee_buyback_min_bal = 0;
    uint256 public _fee_marketing_min_bal = _supply_total * 1 / 100;
    
    //refection fee
    uint256 public _fee_reflection = 0;
    uint256 private _fee_reflection_old = _fee_reflection;
    uint256 private _contractReflectionStored = 0;
    
    // marketing
    uint256 public _fee_marketing = 0;
    uint256 private _fee_marketing_old = _fee_marketing;
    address payable public _wallet_marketing = payable(0x4E23980bf2f4AF53de77FC90FD072cc621A8E6e5);

    // for burn
    uint256 public _fee_burn = 0;
    uint256 private _fee_burn_old = _fee_burn;
    address payable public _wallet_burn = payable(0x000000000000000000000000000000000000dEaD);

    // for development, however labeled as "buyback"
    uint256 public _fee_buyback = 0;
    uint256 private _fee_buyback_old = _fee_buyback;
    address payable public _wallet_buyback = payable(0xF72c8D74fE0940d9e4F8be09b617431896b7288D);

    // Auto LP
    uint256 public _fee_liquidity = 0;
    uint256 private _fee_liquidity_old = _fee_liquidity;

    uint256 public _fee_denominator = 10000;

                                     
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

    uint256 public _maxWalletToken = _supply_total;
    uint256 public _maxTxAmount = _supply_total;

    uint256 public _numTokensSellToAddToLiquidity =  ( _supply_total * 2 ) / 1000;

    uint256 public sellMultiplier = 200;


    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
        
    );
    //  PCSRouter Mainnet = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    // PCSRouter Testnet = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
    address PCSRouter = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    address deadAddress = 0x000000000000000000000000000000000000dEaD;
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    constructor () {
        _balance_reflected[owner()] = _supply_reflected;
        
        // Pancakeswap Router Initialization & Pair creation
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(PCSRouter);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[deadAddress] = true;
        _isExcludedFromFee[_wallet_marketing] = true;
        _isExcludedFromFee[_wallet_burn] = true;
        _isExcludedFromFee[_wallet_buyback] = true;
       
        emit Transfer(address(0), owner(), _supply_total);
    }

/*  CORE INTERFACE FUNCTION */

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
        return _supply_total;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _balance_total[account];
        return tokenFromReflection(_balance_reflected[account]);
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

        require (_allowances[sender][_msgSender()] >= amount,"ERC20: transfer amount exceeds allowance");
        
        _approve(sender, _msgSender(), (_allowances[sender][_msgSender()]-amount));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, (_allowances[_msgSender()][spender] + addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        require (_allowances[_msgSender()][spender] >= subtractedValue,"ERC20: decreased allowance below zero");

        _approve(_msgSender(), spender, (_allowances[_msgSender()][spender] - subtractedValue));
        return true;
    }

    function totalFees() public view returns (uint256) {
        return _contractReflectionStored;
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    // Interface imported 

        function ___tokenInfo () public view returns(
        uint8 Decimals,
        uint256 MaxTxAmount,
        uint256 MaxWalletToken,
        uint256 TotalSupply,
        uint256 Reflected_Supply,
        uint256 Reflection_Rate,
        bool TradingOpen,
        bool Cooldown_timer_enabled,
        uint8 Cooldown_timer_interval
        ) {
        return (_decimals, _maxTxAmount, _maxWalletToken, _supply_total, _supply_reflected, _getRate(), tradingOpen, buyCooldownEnabled, cooldownTimerInterval  );
    }

    function ___feesInfo () public view returns(
        
        uint256 NumTokensSellToAddToLiquidity,
        uint256 contractTokenBalance,
        uint256 Reflection_tokens_stored
        ) {
        return (_numTokensSellToAddToLiquidity, balanceOf(address(this)), _contractReflectionStored);
    }

    function ___wallets () public view returns(
        uint256 Reflection_Fees,
        uint256 Liquidity_Fee,
        uint256 Buyback_Fee,
        uint256 Buyback_Fee_Convert_Limit,
        uint256 Buyback_Fee_Minimum_Balance,
        uint256 Marketing_Fee,
        uint256 Marketing_Fee_Convert_Limit,
        uint256 Marketing_Fee_Minimum_Balance,
        uint256 Burn_Fee,
        address Buyback_Wallet_Address,
        address Burn_Wallet_Address,
        address Marketing_Wallet_Address
        ) {
        return ( _fee_reflection, _fee_liquidity,
            _fee_buyback,_fee_buyback_convert_limit,_fee_buyback_min_bal,
            _fee_marketing,_fee_marketing_convert_limit, _fee_marketing_min_bal,
            _fee_burn,
            _wallet_buyback, _wallet_burn, _wallet_marketing);
    }

/*  Wallet Management  */

    function Change_Wallet_Marketing (address newWallet) external onlyOwner() {
        _wallet_marketing = payable(newWallet);
    }

    function Change_Wallet_Buyback (address newWallet) external onlyOwner() {
        _wallet_buyback = payable(newWallet);
    }

    function Change_Wallet_Burn (address newWallet) external onlyOwner() {
        _wallet_burn = payable(newWallet);
    }


/* Interface Read & Write Functions --- Reflection Specific */

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,,,,) = _getValues(tAmount,false);
        _balance_reflected[sender] = _balance_reflected[sender] - rAmount;
        _supply_reflected = _supply_reflected - rAmount;
        _contractReflectionStored = _contractReflectionStored + tAmount;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _supply_total, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,,,,) = _getValues(tAmount,false);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,,,,) = _getValues(tAmount,false);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _supply_reflected, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return (rAmount / currentRate);
    }

    function excludeFromReward(address account) public onlyOwner() {
        // require(account != 0xdD5E42E23Dc0e38239A07EA02Fa4f66b64cD7F81, 'We can not exclude Uniswap router.');
        require(!_isExcluded[account], "Account is already excluded");
        if(_balance_reflected[account] > 0) {
            _balance_total[account] = tokenFromReflection(_balance_reflected[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already included");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _balance_total[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

/* Interface Read & Write Functions */

    // switch Trading
    function tradingStatus(bool _status) public onlyOwner {
        tradingOpen = _status;
    }

    // enable cooldown between trades
    function cooldownEnabled(bool _status, uint8 _interval) public onlyOwner {
        buyCooldownEnabled = _status;
        cooldownTimerInterval = _interval;
    }

    //set the number of tokens required to activate auto-liquidity
    function setNumTokensSellToAddToLiquidityt(uint256 numTokensSellToAddToLiquidity) external onlyOwner() {
        _numTokensSellToAddToLiquidity = numTokensSellToAddToLiquidity;
    }
    
    //set the Max transaction amount (percent of total supply)
    function setMaxTxPercent_base1000(uint256 maxTxPercent) external onlyOwner() {
        _maxTxAmount = (_supply_total * maxTxPercent ) / 1000;
    }
    
    //set the Max transaction amount (in tokens)
     function setMaxTxTokens(uint256 maxTxTokens) external onlyOwner() {
        _maxTxAmount = maxTxTokens;
    }
    
    //settting the maximum permitted wallet holding (percent of total supply)
     function setMaxWalletPercent_base1000(uint256 maxWallPercent) external onlyOwner() {
        _maxWalletToken = (_supply_total * maxWallPercent ) / 1000;
    }
    
    //settting the maximum permitted wallet holding (in tokens)
     function setMaxWalletTokens(uint256 maxWallTokens) external onlyOwner() {
        _maxWalletToken = maxWallTokens;
    }
    
    //toggle on and off to activate auto liquidity 
    function setSwapAndLiquifyEnabled(bool _status) public onlyOwner {
        swapAndLiquifyEnabled = _status;
        emit SwapAndLiquifyEnabledUpdated(_status);
    }
    

/** All list management functions BEGIN*/

    function s_manageExcludeFromFee(address[] calldata addresses, bool status) external onlyOwner {
        for (uint256 i; i < addresses.length; ++i) {
            _isExcludedFromFee[addresses[i]] = status;
        }
    }

    function s_manageBlacklist(address[] calldata addresses, bool status) external onlyOwner {
        for (uint256 i; i < addresses.length; ++i) {
            _isBlacklisted[addresses[i]] = status;
        }
    }

    function s_manageWhitelist(address[] calldata addresses, bool status) external onlyOwner {
        for (uint256 i; i < addresses.length; ++i) {
            _isWhitelisted[addresses[i]] = status;
        }
    }

    function s_excludeFromFee(address[] calldata addresses, bool status) external onlyOwner {
        for (uint256 i; i < addresses.length; ++i) {
            _isExcludedFromFee[addresses[i]] = status;
        }
    }
    
    /** All list management functions END*/




// Liquidity and contract Balance functions

// convert all stored tokens for LP into LP Pairs
    function convertLiquidityBalance(uint256 tokensToConvert) public onlyOwner {

        uint256 contractTokenBalance = balanceOf(address(this));

        if(contractTokenBalance >= _maxTxAmount) {
            contractTokenBalance = _maxTxAmount - 1;
        }

        if(tokensToConvert == 0 || tokensToConvert > contractTokenBalance){
            tokensToConvert = contractTokenBalance;
        }
        swapAndLiquify(tokensToConvert);
    }

// convert all stored tokens for LP into LP Pairs
    function purgeContractBalance() public {
        require(msg.sender == owner() || msg.sender == _wallet_marketing, "Not authorized to perform this");
         _wallet_marketing.transfer(address(this).balance);
    }

// Reflect Finance core code

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _supply_reflected;
        uint256 tSupply = _supply_total;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_balance_reflected[_excluded[i]] > rSupply || _balance_total[_excluded[i]] > tSupply) return (_supply_reflected, _supply_total);
            rSupply = rSupply - _balance_reflected[_excluded[i]];
            tSupply = tSupply - _balance_total[_excluded[i]];
        }
        if (rSupply < (_supply_reflected/_supply_total)) return (_supply_reflected, _supply_total);
        return (rSupply, tSupply);
    }
    function _getValues(uint256 tAmount, bool isSell) private view returns (
        uint256 rAmount, uint256 rTransferAmount, uint256 rReflection,
        uint256 tTransferAmount,uint256 tBurn, uint256 tMarketing, uint256 tLiquidity, uint256 tBuyback, uint256 tReflection) {

        uint256 multiplier = isSell ? sellMultiplier : 100;

        tBurn           = ( tAmount * _fee_burn )/ _fee_denominator;
        tMarketing       = ( tAmount * _fee_marketing ) * multiplier / (_fee_denominator * 100);
        tLiquidity      = ( tAmount * _fee_liquidity ) * multiplier / (_fee_denominator * 100);
        tBuyback           = ( tAmount * _fee_buyback ) * multiplier / (_fee_denominator * 100);
        tReflection     = ( tAmount * _fee_reflection ) * multiplier  / (_fee_denominator * 100);

        tTransferAmount = tAmount - (tBurn + tMarketing + tLiquidity + tBuyback + tReflection);

        rReflection     = tReflection * _getRate();

        rAmount         = tAmount * _getRate();

        rTransferAmount = tTransferAmount * _getRate();

    }
    function _fees_to_bnb_process( address payable wallet, uint256 tokensToConvert) private lockTheSwap {

        uint256 rTokensToConvert = tokensToConvert * _getRate();

        _balance_reflected[wallet]    = _balance_reflected[wallet]  - rTokensToConvert;
        if (_isExcluded[wallet]){
            _balance_total[wallet]    = _balance_total[wallet]      - tokensToConvert;
        }
        _balance_reflected[address(this)]      = _balance_reflected[address(this)]    + rTokensToConvert;

        emit Transfer(wallet, address(this), tokensToConvert);

        swapTokensForEthAndSend(tokensToConvert,wallet);

    }

// Fee & Wallet Related

    function fees_to_bnb_manual(uint256 tokensToConvert, address payable feeWallet, uint256 minBalanceToKeep) external onlyOwner {
        _fees_to_bnb(tokensToConvert,feeWallet,minBalanceToKeep);
    }


    function _fees_to_bnb(uint256 tokensToConvert, address payable feeWallet, uint256 minBalanceToKeep) private {
        // case 1: 0 tokens to convert, exit the function
        // case 2: tokens to convert are more than the max limit
        
        if(tokensToConvert == 0){
            return;
        } 

        if(tokensToConvert > _maxTxAmount){
            tokensToConvert = _maxTxAmount;
        }

        if((tokensToConvert+minBalanceToKeep)  <= balanceOf(feeWallet)){
            _fees_to_bnb_process(feeWallet,tokensToConvert);
        }
    }


    function _takeFee(uint256 feeAmount, address receiverWallet) private {
        uint256 reflectedReeAmount = feeAmount * _getRate();
        _balance_reflected[receiverWallet] = _balance_reflected[receiverWallet] + reflectedReeAmount;


        if(_isExcluded[receiverWallet]){
            _balance_total[receiverWallet] = _balance_total[receiverWallet] + feeAmount;
        }

        emit Transfer(msg.sender, receiverWallet, feeAmount);
    }


    function _takefees_Liquidity(uint256 amount) private {
        _takeFee(amount,address(this));
    }
    
    function _takefees_burn(uint256 amount) private {
        _takeFee(amount,_wallet_burn);
        
    }

    function _takefees_buyback(uint256 amount) private {
        _takeFee(amount,_wallet_buyback);

    }

    function _takefees_marketing(uint256 amount) private {
        _takeFee(amount,_wallet_marketing);
        
    }

    function _take_reflectionFee(uint256 rFee, uint256 tFee) private {
        _supply_reflected = _supply_reflected - rFee;
        _contractReflectionStored = _contractReflectionStored + tFee;
    }

// Made all parameters in alphabetical order
    function _setAllFees(uint256 burnFees, uint256 marketingFee, uint256 liquidityFees, uint256 buybackFee, uint256 reflectionFees) private {
        _fee_burn           = burnFees;
        _fee_marketing        = marketingFee;
        _fee_liquidity      = liquidityFees;
        _fee_buyback           = buybackFee;
        _fee_reflection     = reflectionFees;
        
    }

    function set_sell_multiplier(uint256 Multiplier) external onlyOwner{
        sellMultiplier = Multiplier;        
    }

    function set_All_Fees_Triggers(uint256 marketing_fee_convert_limit, uint256 buyback_fee_convert_limit) external onlyOwner {
        _fee_marketing_convert_limit      = marketing_fee_convert_limit;
        _fee_buyback_convert_limit         = buyback_fee_convert_limit;   
    }

    function set_All_Fees_Minimum_Balance(uint256 marketing_fee_minimum_balance, uint256 buyback_fee_minimum_balance) external onlyOwner {
        _fee_buyback_min_bal       = buyback_fee_minimum_balance;
        _fee_marketing_min_bal    = marketing_fee_minimum_balance;
    }




    // set all fees in one go, we dont need 4 functions!
    function set_All_Fees(uint256 Buyback_Fee, uint256 Burn_Fees, uint256 Liquidity_Fees, uint256 Reflection_Fees, uint256 MarketingFee) external onlyOwner {
        uint256 total_fees = Burn_Fees + MarketingFee + Liquidity_Fees +  Buyback_Fee + Reflection_Fees;
        require(total_fees < 4000, "Cannot set fees this high, pancake swap will hate us!");
        _setAllFees( Burn_Fees, MarketingFee, Liquidity_Fees, Buyback_Fee, Reflection_Fees);
    }


    function removeAllFee() private {
        _fee_burn_old           = _fee_burn;
        _fee_marketing_old        = _fee_marketing;
        _fee_liquidity_old      = _fee_liquidity;
        _fee_buyback_old           = _fee_buyback;
        _fee_reflection_old     = _fee_reflection;

        _setAllFees(0,0,0,0,0);
    }
    
    function restoreAllFee() private {
        _setAllFees(_fee_burn_old, _fee_marketing_old, _fee_liquidity_old, _fee_buyback_old, _fee_reflection_old);
    }



    // this one sends to dead address
    function burn_tokens_to_dead(address wallet, uint256 tokensToConvert) external onlyOwner{

        require(msg.sender == owner() || msg.sender == wallet, "Not authorized to burn");

        uint256 rTokensToConvert = tokensToConvert * _getRate();

        _balance_reflected[wallet]          = _balance_reflected[wallet]  - rTokensToConvert;        
        
        if (_isExcluded[wallet]){
            _balance_total[wallet]          = _balance_total[wallet]      - tokensToConvert;
        }

        if (_isExcluded[deadAddress]){
            _balance_total[deadAddress]     = _balance_total[deadAddress]        + tokensToConvert;  
        }

        // update reflected balance of receipient
        _balance_reflected[deadAddress]     = _balance_reflected[deadAddress]    + rTokensToConvert;

        emit Transfer(wallet, deadAddress, tokensToConvert);

    }

// Liquidity functions

    function swapAndLiquify(uint256 tokensToSwap) private lockTheSwap {
        uint256 tokensHalf = tokensToSwap/2;

        uint256 contractBnbBalance = address(this).balance;

        swapTokensForEth(tokensHalf);
        
        uint256 bnbSwapped = address(this).balance - contractBnbBalance;

        addLiquidity(tokensHalf,bnbSwapped);

        emit SwapAndLiquify(tokensToSwap, tokensHalf, bnbSwapped);
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

    function swapTokensForEthAndSend(uint256 tokenAmount, address payable receiverWallet) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            receiverWallet,
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
            0xdD5E42E23Dc0e38239A07EA02Fa4f66b64cD7F81,
            block.timestamp
        );
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // All transfer functions

    function _transfer(address from, address to, uint256 amount) private {

        require(!_isBlacklisted[from] && !_isBlacklisted[to], "This address is blacklisted");
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        // require(amount > 0, "Transfer amount must be greater than zero");


        //max wallet
        if (to != owner() && to != address(this) && to != address(deadAddress) && to != uniswapV2Pair && to != _wallet_marketing && to != _wallet_buyback){
            uint256 heldTokens = balanceOf(to);
            require((heldTokens + amount) <= _maxWalletToken,"Total Holding is currently limited, you can not buy that much.");}
        
        if(from != owner() && to != owner() && !_isWhitelisted[from] && !_isWhitelisted[to]){
            require(tradingOpen,"Trading not open yet");
        }


        // cooldown timer
        if (from == uniswapV2Pair &&
            buyCooldownEnabled &&
            !_isExcludedFromFee[to] &&
            to != address(this)  && 
            to != address(deadAddress)) {
            require(cooldownTimer[to] < block.timestamp,"Please wait for cooldown between buys");
            cooldownTimer[to] = block.timestamp + cooldownTimerInterval;
        }

        if(from != owner() && to != owner()  && !_isWhitelisted[from] && !_isWhitelisted[to]){
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }

        // extra bracket to supress stack too deep error
        {
            uint256 contractTokenBalance = balanceOf(address(this));
        
            if(contractTokenBalance >= _maxTxAmount) {
                contractTokenBalance = _maxTxAmount - 1;
            }
            
            bool overMinTokenBalance = contractTokenBalance >= _numTokensSellToAddToLiquidity;
            if (overMinTokenBalance &&
                !inSwapAndLiquify &&
                from != uniswapV2Pair &&
                swapAndLiquifyEnabled
            ) {
                contractTokenBalance = _numTokensSellToAddToLiquidity;
                swapAndLiquify(contractTokenBalance);
            }

            // Convert fees to BNB
            if(!inSwapAndLiquify && from != uniswapV2Pair){
                _fees_to_bnb(_fee_buyback_convert_limit,_wallet_buyback, _fee_buyback_min_bal);
                _fees_to_bnb(_fee_marketing_convert_limit,_wallet_marketing, _fee_marketing_min_bal);
            }
            
        }
        // extra useless ugly brackets ends
        
        bool takeFee = true;
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        
        if(!takeFee){
            removeAllFee();
        }
        
        // Get all tranfer values        
        (uint256 rAmount, uint256 rTransferAmount, uint256 rReflection, uint256 tTransferAmount, uint256 tBurn, uint256 tMarketing, uint256 tLiquidity, uint256 tBuyback,  uint256 tReflection) = _getValues(amount, (to == uniswapV2Pair));

        _transferStandard(from,to,amount,rAmount,tTransferAmount, rTransferAmount);
       
        // update reflections
        _take_reflectionFee(rReflection, tReflection);

        if(!takeFee){
            restoreAllFee();
        } else{
            // functions to take all fees
            // no point to call them if there's no fees to be taken
            _takefees_burn(tBurn);
            _takefees_marketing(tMarketing);
            _takefees_Liquidity(tLiquidity);
            _takefees_buyback(tBuyback);
        }

    }

    function _transferStandard(address from, address to, uint256 tAmount, uint256 rAmount, uint256 tTransferAmount, uint256 rTransferAmount) private {
         // Update reflected Balance for sender
        _balance_reflected[from]    = _balance_reflected[from]  - rAmount;


        // Only update actual balance of sender if he's excluded from rewards
        if (_isExcluded[from]){
            _balance_total[from]    = _balance_total[from]      - tAmount;
        }

        // Only update actual balance of recipient if he's excluded from rewards
        if (_isExcluded[to]){
            _balance_total[to]      = _balance_total[to]        + tTransferAmount;  
        }

        // update reflected balance of receipient
        _balance_reflected[to]      = _balance_reflected[to]    + rTransferAmount;

        emit Transfer(from, to, tTransferAmount);
        emit TransferDetails(from, to, tAmount, rAmount, tTransferAmount, rTransferAmount);
    }

    //receive BNB from PancakeSwap Router
    receive() external payable {}

}