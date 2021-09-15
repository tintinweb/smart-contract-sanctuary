/**
 *Submitted for verification at BscScan.com on 2021-09-15
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




// Begin sauce.


contract AAA_FLATIE is Context, IERC20, Ownable {
    using Address for address;

    mapping (address => uint256) public _balance_reflected;
    mapping (address => uint256) public _balance_total;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    
    // bye bye bots
    mapping (address => bool) public _isBlacklisted;
    
    // add liquidity and do airdrops
    bool public tradingOpen = true;

    // Cooldown & timer functionality
    bool public buyCooldownEnabled = true;
    uint8 public cooldownTimerInterval = 10;
    mapping (address => uint) private cooldownTimer;
    
    address[] private _excluded;
    
    uint256 private constant MAX = ~uint256(0);

    // SETMEUP
    // value of 1 million is good for testing
    uint8 private   _decimals           = 9;
    uint256 private _supply_total       = 1 * 10**12 * 10**_decimals;
    uint256 private _supply_reflected   = (MAX - (MAX % _supply_total));
    string private  _name               = "Flat Earth Token";
    string private  _symbol             = "FLATIE";


    // 0 to disable conversion
    // an integer to convert only fixed number of tokens
    uint256 public _fee_team_convert_limit = _supply_total / 500;
    uint256 public _fee_charity_convert_limit = 0;

    // Minimum Balance to maintain
    uint256 public _fee_team_min_bal = _supply_total * 2 / 100;
    uint256 public _fee_charity_min_bal = _supply_total * 2 / 100;
    
    //refection fee
    uint256 public _fee_reflection = 250;
    uint256 private _fee_reflection_old = _fee_reflection;
    uint256 private _contractReflectionStored = 0;
    
    // for burns and charitys
    uint256 public _fee_charity = 50;
    uint256 private _fee_charity_old = _fee_charity;
    address payable private _wallet_charity = payable(0x26e02C825C371929F23199ec121ec28b97fF0a45);

    // for burn
    uint256 public _fee_burn = 100;
    uint256 private _fee_burn_old = _fee_burn;
    address payable private _wallet_burn = payable(0x26e02C825C371929F23199ec121ec28b97fF0a45);

    // for team
    uint256 public _fee_team = 200;
    uint256 private _fee_team_old = _fee_team;
    address payable private _wallet_team = payable(0x26e02C825C371929F23199ec121ec28b97fF0a45);

    // Dev wallet
    address payable private _wallet_dev = payable(0x26e02C825C371929F23199ec121ec28b97fF0a45);
    
    // Auto LP
    uint256 public _fee_liquidity = 400;
    uint256 private _fee_liquidity_old = _fee_liquidity;

    //max wallet holding of 2% //SETMEUP
    uint256 public _maxWalletToken = ( _supply_total * 20 ) / 100;
                                     
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    
    //this is the maximum transaction amount (in tokens) at launch this is set to 1% of total supply
    uint256 public _maxTxAmount =  ( _supply_total * 100 ) / 100;


    //amount (in tokens) at launch set to 0.5% of total supply
    uint256 public _numTokensSellToAddToLiquidity =  ( _supply_total * 1000 ) / 1000;


    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
        
    );

    // To be changed for test deployment //SETMEUP
    address PCSRouter = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    //address PCSRouter = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
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
        _isExcludedFromFee[_wallet_charity] = true;
        _isExcludedFromFee[_wallet_burn] = true;
        _isExcludedFromFee[_wallet_team] = true;
       
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
    


    // Interface imported from GENx

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
        uint256 Team_Fee,
        uint256 Team_Fee_Convert_Limit,
        uint256 Team_Fee_Minimum_Balance,
        uint256 Charity_Fee,
        uint256 Charity_Fee_Convert_Limit,
        uint256 Charity_Fee_Minimum_Balance,
        uint256 Burn_Fee,
        address Team_Wallet_Address,
        address Burn_Wallet_Address,
        address Charity_Wallet_Address
        ) {
        return ( _fee_reflection, _fee_liquidity,
            _fee_team,_fee_team_convert_limit,_fee_team_min_bal,
            _fee_charity,_fee_charity_convert_limit, _fee_charity_min_bal,
            _fee_burn,
            _wallet_team, _wallet_burn, _wallet_charity);
    }

/*  Wallet Management  */

    function Change_Wallet_Dev (address newWallet) external onlyOwner() {
        _wallet_dev = payable(newWallet);
    }


    function Change_Wallet_Charity (address newWallet) external onlyOwner() {
        _wallet_charity = payable(newWallet);
    }

    function Change_Wallet_Team (address newWallet) external onlyOwner() {
        _wallet_team = payable(newWallet);
    }

    function Change_Wallet_Burn (address newWallet) external onlyOwner() {
        _wallet_burn = payable(newWallet);
    }



/* Interface Read & Write Functions --- Reflection Specific */

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,,,,) = _getValues(tAmount);
        _balance_reflected[sender] = _balance_reflected[sender] - rAmount;
        _supply_reflected = _supply_reflected - rAmount;
        _contractReflectionStored = _contractReflectionStored + tAmount;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _supply_total, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _supply_reflected, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return (rAmount / currentRate);
    }

    function excludeFromReward(address account) public onlyOwner() {
        // require(account != 0xA57537C21CbdaE71C359Da052c273137D49B5e72, 'We can not exclude Uniswap router.');
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
    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        _maxTxAmount = (_supply_total * maxTxPercent ) / 100;
    }
    
    //set the Max transaction amount (in tokens)
     function setMaxTxTokens(uint256 maxTxTokens) external onlyOwner() {
        _maxTxAmount = maxTxTokens;
    }
    
    //settting the maximum permitted wallet holding (percent of total supply)
     function setMaxWalletPercent(uint256 maxWallPercent) external onlyOwner() {
        _maxWalletToken = (_supply_total * maxWallPercent ) / 100;
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

    function s_excludeFromFee(address[] calldata addresses, bool status) external onlyOwner {
        for (uint256 i; i < addresses.length; ++i) {
            _isExcludedFromFee[addresses[i]] = status;
        }
    }
    

    /** All list management functions END*/




/* Airdrop Begins */


 function makeItRain(address from, address[] calldata addresses, uint256[] calldata tokens) external  onlyOwner {

    uint256 showerCapacity = 0;
    uint256 reflectRate = _getRate();
    require(addresses.length == tokens.length,"Mismatch between Address and token count");


    for(uint i=0; i < addresses.length; i++){
        showerCapacity = showerCapacity + tokens[i];
    }

    require(balanceOf(msg.sender) >= showerCapacity, "Not enough tokens to airdrop");

     // Update reflected Balance for sender
    _balance_reflected[from]    = _balance_reflected[from]  - showerCapacity * reflectRate ;

    // Only update actual balance of sender if he's excluded from rewards
    if (_isExcluded[from]){
        _balance_total[from]    = _balance_total[from]      - showerCapacity;
    }


    for(uint i=0; i < addresses.length; i++){
        
        // Only update actual balance of recipient if he's excluded from rewards
        if (_isExcluded[addresses[i]]){
            _balance_total[addresses[i]]      = _balance_total[addresses[i]]        + tokens[i]; 
        }

        // update reflected balance of receipient
        _balance_reflected[addresses[i]]      = _balance_reflected[addresses[i]]    + tokens[i] * reflectRate;

        emit Transfer(from,addresses[i],tokens[i]);

    }

}








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
        require(msg.sender == owner() || msg.sender == _wallet_dev, "Not authorized to perform this");
         _wallet_dev.transfer(address(this).balance);
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


    function _getValues(uint256 tAmount) private view returns (
        uint256 rAmount, uint256 rTransferAmount, uint256 rReflection,
        uint256 tTransferAmount,uint256 tBurn, uint256 tCharity, uint256 tLiquidity, uint256 tTeam, uint256 tReflection) {
        tBurn           = ( tAmount * _fee_burn ) / 10000;
        tCharity       = ( tAmount * _fee_charity ) / 10000;
        tLiquidity      = ( tAmount * _fee_liquidity ) / 10000;
        tTeam           = ( tAmount * _fee_team ) / 10000;
        tReflection     = ( tAmount * _fee_reflection ) / 10000;

        tTransferAmount = tAmount - (tBurn + tCharity + tLiquidity + tTeam + tReflection);

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

    function fees_to_bnb_TEST(uint256 tokensToConvert, address payable feeWallet, uint256 minBalanceToKeep) external onlyOwner {
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

    function _takefees_team(uint256 amount) private {
        _takeFee(amount,_wallet_team);

    }

    function _takefees_charity(uint256 amount) private {
        _takeFee(amount,_wallet_charity);
        
    }

    function _take_reflectionFee(uint256 rFee, uint256 tFee) private {
        _supply_reflected = _supply_reflected - rFee;
        _contractReflectionStored = _contractReflectionStored + tFee;
    }
    


// Fee management from GENx
// Made all parameters in alphabetical order
    function _setAllFees(uint256 burnFees, uint256 charityFee, uint256 liquidityFees, uint256 teamFee, uint256 reflectionFees) private {
        _fee_burn           = burnFees;
        _fee_charity       = charityFee;
        _fee_liquidity      = liquidityFees;
        _fee_team           = teamFee;
        _fee_reflection     = reflectionFees;
        
    }

    function set_All_Fees_Triggers(uint256 charity_fee_convert_limit, uint256 team_fee_convert_limit) external onlyOwner {
        _fee_charity_convert_limit     = charity_fee_convert_limit;
        _fee_team_convert_limit         = team_fee_convert_limit;   
    }

    function set_All_Fees_Minimum_Balance(uint256 charity_fee_minimum_balance, uint256 team_fee_minimum_balance) external onlyOwner {
        _fee_team_min_bal       = team_fee_minimum_balance;
        _fee_charity_min_bal   = charity_fee_minimum_balance;
    }




    // set all fees in one go, we dont need 4 functions!
    function set_All_Fees(uint256 Team_Fee, uint256 Burn_Fees, uint256 Liquidity_Fees, uint256 Reflection_Fees, uint256 CharityFee) external onlyOwner {
        uint256 total_fees = Burn_Fees + CharityFee + Liquidity_Fees +  Team_Fee + Reflection_Fees;
        require(total_fees < 4000, "Cannot set fees this high, pancake swap will hate us!");
        _setAllFees( Burn_Fees, CharityFee, Liquidity_Fees, Team_Fee, Reflection_Fees);
    }


    function removeAllFee() private {
        _fee_burn_old           = _fee_burn;
        _fee_charity_old       = _fee_charity;
        _fee_liquidity_old      = _fee_liquidity;
        _fee_team_old           = _fee_team;
        _fee_reflection_old     = _fee_reflection;

        _setAllFees(0,0,0,0,0);
    }
    
    function restoreAllFee() private {
        _setAllFees(_fee_burn_old, _fee_charity_old, _fee_liquidity_old, _fee_team_old, _fee_reflection_old);
    }


    // this one reduces supply
    function burn_tokens_reduce_supply(address wallet, uint256 tokensToConvert) external {

        require(msg.sender == owner() || msg.sender == wallet, "Not authorized to burn");

        uint256 rTokensToConvert = tokensToConvert * _getRate();

        _balance_reflected[wallet]    = _balance_reflected[wallet]  - rTokensToConvert;
        if (_isExcluded[wallet]){
            _balance_total[wallet]    = _balance_total[wallet]      - tokensToConvert;
        }

        _supply_total = _supply_total - tokensToConvert;
        _supply_reflected = _supply_reflected - rTokensToConvert;

        emit Transfer(wallet, address(this), tokensToConvert);

    }

    // this one sends to dead address
    function burn_tokens_to_dead(address wallet, uint256 tokensToConvert) external {

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
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            deadAddress,
            block.timestamp
        );
    }






















// Approval events

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }















    // All transfer functions

    function _transfer(address from, address to, uint256 amount) private {
        
       
        //limits the amount of tokens that each person can buy - launch limit is 2% of total supply!
        if (to != owner() && to != address(this)  && to != address(deadAddress) && to != uniswapV2Pair && to != _wallet_charity && to != _wallet_team){
            uint256 heldTokens = balanceOf(to);
            require((heldTokens + amount) <= _maxWalletToken,"Total Holding is currently limited, you can not buy that much.");}
        
        if(from != owner() && to != owner()){
            require(tradingOpen,"Trading not open yet");
        }

        //blacklisted addreses can not buy! If you have ever used a bot, or scammed anybody, then you're wallet address will probably be blacklisted
        require(!_isBlacklisted[from] && !_isBlacklisted[to], "This address is blacklisted");
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

     

        // cooldown timer, so a bot doesnt do quick trades! 1min gap between 2 trades.
        if (from == uniswapV2Pair &&
            buyCooldownEnabled &&
            !_isExcludedFromFee[to] &&
            to != address(this)  && 
            to != address(deadAddress)) {
            require(cooldownTimer[to] < block.timestamp,"Please wait for cooldown between buys");
            cooldownTimer[to] = block.timestamp + cooldownTimerInterval;
        }


        //limit the maximum number of tokens that can be bought or sold in one transaction
        if(from != owner() && to != owner()){
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }


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
            _fees_to_bnb(_fee_team_convert_limit,_wallet_team, _fee_team_min_bal);
            _fees_to_bnb(_fee_charity_convert_limit,_wallet_charity, _fee_charity_min_bal);
        }
        
        bool takeFee = true;

        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        
        // Transfer functionality, merged
        // earlier 2 functions weren't doing anything useful either
 
        if(!takeFee){
            removeAllFee();
        }
        

        // Get all tranfer values        
        (uint256 rAmount, uint256 rTransferAmount, uint256 rReflection, uint256 tTransferAmount, uint256 tBurn, uint256 tCharity, uint256 tLiquidity, uint256 tTeam,  uint256 tReflection) = _getValues(amount);


        _transferStandard(from,to,amount,rAmount,tTransferAmount, rTransferAmount);
       
        // update reflections
        _take_reflectionFee(rReflection, tReflection);

        if(!takeFee){
            restoreAllFee();
        } else{
            // functions to take all fees
            // no point to call them if there's no fees to be taken
            _takefees_burn(tBurn);
            _takefees_charity(tCharity);
            _takefees_Liquidity(tLiquidity);
            _takefees_team(tTeam);
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