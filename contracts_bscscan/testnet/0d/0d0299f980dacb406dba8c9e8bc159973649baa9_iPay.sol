/**
 *Submitted for verification at BscScan.com on 2022-01-04
*/

// SPDX-License-Identifier: Unlicensed 
// Unlicensed SPDX-License-Identifier is not Open Source 
// This contract can not be used/forked without permission 
// Contract created for iPay https://ipaytoken.com by https://gentokens.com/ 

/*

Name: iPay
Symbol: iPay
Decimals: 9
Total Supply: 1B (1,000,000,000)

https://ipaytoken.com
https://t.me/iPayToken
https://twitter.com/ipay_token/
https://www.reddit.com/r/iPayToken/
https://discord.gg/b5hyzjAVH7
https://instagram.com/ipaytoken

*/


pragma solidity 0.8.10;


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
        _owner = 0x627C95B6fD9026E00Ab2c373FB08CC47E02629a0;
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






contract iPay is Context, IERC20, Ownable { 
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public _isExcludedFromFee; 
    mapping (address => bool) public _isExcluded; 
    mapping (address => bool) public _preLaunchAccess;
    mapping (address => bool) public _limitExempt; 


    // AntiDump Setup


    mapping (address => bool) public _DumpExempt;
    mapping (address => uint256) private _Dump_SellTime; // only if over x amount - update and check if over max whale sell
    bool public antiDump = true; // xxx on off
    uint256 public antiDump_Max_Sell = 500000; // Decimals on require! xxxx
    uint256 public antiDump_Repeat_Trigger = 200000; // Decimals on require! xxxx
    uint256 public antiDump_Wait_Time = 60 * 5; // 5 minutes
    uint256 public antiDump_Tax_Increase = 2;


  

    // xxx update wallets! LP wallet etc

    address[] private _excluded; // Excluded from rewards
    address payable public Wallet_Market_Develop = payable(0x06376fF13409A4c99c8d94A1302096CB4dC7c07e); //3 xxx
    address payable public Wallet_LP = payable(0x06376fF13409A4c99c8d94A1302096CB4dC7c07e);  // 3 xxx
    address payable public constant Wallet_Burn = payable(0x000000000000000000000000000000000000dEaD); 


    // Main NET - Updated post launch xxxxx
    // address payable public TeamTokenDistribution = payable(0x6ca8316df1ef1dbb916d8695bb2fd1b1343f5b4c); // Contract for Marketing and Team Splits

    // TEST NET 
    address payable public TeamTokenDistribution = payable(0x02e9Ff63A56F251680C25512cBe39E9879167F42); // Contract for Marketing and Team Splits



    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _decimals = 9;
    uint256 private _tTotal = 10**9 * 10**_decimals;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    string private constant _name = "iPay"; 
    string private constant _symbol = "iPay"; 


    // Fees

    uint256 _FeeTeamTokens  = 0;     // Tokens to team
    uint256 _FeeReflection  = 0;     // Refleciton to holders
    uint256 _FeeMarDev      = 0;     // MarDev to Marketing/Development
    uint256 _FeeLiquidity   = 0;     // Added to BUSD Liquidity Pair on PCS

    
    // Buy Fees

    uint256 _FeeTeamTokens_Buy  = 2; 
    uint256 _FeeReflection_Buy  = 2; 
    uint256 _FeeLiquidity_Buy   = 1;
    uint256 _FeeMarDev_Buy      = 6;



    // Sell Fees

    uint256 _FeeTeamTokens_Sell = 2;
    uint256 _FeeReflection_Sell = 2; 
    uint256 _FeeLiquidity_Sell  = 1; 
    uint256 _FeeMarDev_Sell     = 6;

  
    uint256 public _Total_Fee_On_Buys = _FeeTeamTokens_Buy + _FeeReflection_Buy + _FeeLiquidity_Buy + _FeeMarDev_Buy;
    uint256 public _Total_Fee_On_Sells = _FeeTeamTokens_Sell + _FeeReflection_Sell + _FeeLiquidity_Sell + _FeeMarDev_Sell;

   
    uint256 private rTeamTokens;
    uint256 private rReflect;
    uint256 private rMarDevLiq;
    uint256 private rTransferAmount; 
    uint256 private rAmount; 

    uint256 private tTeamTokens;
    uint256 private tReflect; 
    uint256 private tMarDevLiq;
    uint256 private tTransferAmount; 

    uint256 private swapBlock;
    bool public TradeOpen = false;


    // Counter for liquify trigger
    uint256 private txCount = 0;
    uint256 private swapTrigger = 10; 



   

    // Wallet limits 
    

    // Max wallet holding 2%
    uint256 public _maxWalletToken = _tTotal/50;
    uint256 private _previousMaxWalletToken = _maxWalletToken;

    // Maximum transaction amount 2%
    uint256 public _maxTxAmount = _tTotal/50; 
    uint256 private _previousMaxTxAmount = _maxTxAmount;
                                     
                                     
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    bool public inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    
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
        
      //  IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); 
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); // TESTNET BSC

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;


        /*

        Set initial wallet mappings

        */

        // Wallet that are excluded from fees
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[Wallet_Burn] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[TeamTokenDistribution] = true;

        // Wallets that are not restricted by transaction and holding limits
        _limitExempt[owner()] = true;
        _limitExempt[Wallet_Burn] = true;
        _limitExempt[Wallet_Market_Develop] = true;
        _limitExempt[TeamTokenDistribution] = true; 

        // Wallets granted access before trade is oopen
        _preLaunchAccess[owner()] = true;





        
        emit Transfer(address(0), owner(), _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint256) {
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
   
    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");

        rAmount = tAmount.mul(_getRate()); 
        
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }



    function tokenFromReflection(uint256 _rAmount) public view returns(uint256) {
        require(_rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return _rAmount.div(currentRate);
    }



    /*
    
    When sending tokens to another wallet (not buying or selling) if noFeeToTransfer is true there will be no fee

    */

    bool public noFeeToTransfer = true;

    // Option to set fee or no fee for transfer (just in case the no fee transfer option is exploited in future!)
    // True = there will be no fees when moving tokens around or giving them to friends! (There will only be a fee to buy or sell)
    // False = there will be a fee when buying/selling/tranfering tokens
    // Default is true
    function set_Transfers_Without_Fees(bool true_or_false) external onlyOwner {
        noFeeToTransfer = true_or_false;
    }

    
    // isPair - Add to pair (set to true) OR Remove from pair (set to false)
    mapping (address => bool) public _isPair;

    /*

    Setting as a pair indicates that it is an address used by an exchange to buy or sell tokens. 
    This setting is used so that we can have no-fee transfers between wallets but new
    pairings will take a fee on buys and sell

    */


    /*


    AntiDump Functions

    */


    // Turn AntiDump Protection on or off
    function antiDump_Switch(bool true_or_false) external onlyOwner {
        antiDump = true_or_false;
    }

    // Add or remove a wallet from AntiDump restrictions - default: false
    function AntiDump_Exclude_Wallet(address account, bool true_or_false) external onlyOwner() {    
        _DumpExempt[account] = true_or_false;
    }

    // Set max sell for anti dump
    function AntiDump_Set_Max_Sell(uint256 Number_of_tokens) external onlyOwner() {
        antiDump_Max_Sell = Number_of_tokens;
    }

    // Set repeat dump trigger amount
    function AntiDump_Repeat_Selling_Trigger(uint256 Number_of_tokens) external onlyOwner() {
        antiDump_Repeat_Trigger = Number_of_tokens;
    }

    // Set wait time between dumps
    function AntiDump_Repeat_Selling_Wait_Time(uint256 Number_of_Seconds) external onlyOwner() {
        antiDump_Wait_Time = Number_of_Seconds;
    }

    // Set tax increase % for dumps
    function AntiDump_Tax_Percent_Increase(uint256 Tax_Increase) external onlyOwner() {
        antiDump_Tax_Increase = Tax_Increase;
    }





















    





    /*

    SET MAPPINGS

    */


    // Pre Launch Access - able to buy and sell before the trade is open 
    function mapping_preLaunchAccess(address account, bool true_or_false) external onlyOwner() {    
        _preLaunchAccess[account] = true_or_false;
    }

    // Exempt from holding limits
    function mapping_Limit_Exempt(address account, bool true_or_false) external onlyOwner() {  
        _limitExempt[account] = true_or_false;
    }

    // Set address is a liquidity pair
    function set_as_Pair(address wallet, bool true_or_false) external onlyOwner {
        _isPair[wallet] = true_or_false;
    }

    // Set a wallet address so that it does not have to pay transaction fees
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    // Set a wallet address so that it has to pay transaction fees
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    // Add wallet to RFI rewards - Default
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


    /*

    *** !WARNING! excludeFromReward !WARNING! ****

    Wallets must be pushed to an aray.
    Limit excluded wallets to avoid out of gas errors during loops!

    */


    // Exclude a wallet from RFI rewards
    function excludeFromReward(address account) public onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }



    








    
    /*

    SET BUY AND SELL FEES  

    */



    function _set_Fees(uint256 TeamTokens_Buy,
                       uint256 TeamTokens_Sell,
                       uint256 Reflection_Buy,
                       uint256 Reflection_Sell,
                       uint256 Liquidity_Buy,
                       uint256 Liquidity_Sell,
                       uint256 Dev_Buy,
                       uint256 Dev_Sell
                       ) external onlyOwner() {


                       _FeeTeamTokens_Buy   = TeamTokens_Buy;
                       _FeeTeamTokens_Sell  = TeamTokens_Sell;
                       _FeeReflection_Buy   = Reflection_Buy;
                       _FeeReflection_Sell  = Reflection_Sell;
                       _FeeLiquidity_Buy    = Liquidity_Buy;
                       _FeeLiquidity_Sell   = Liquidity_Sell;
                       _FeeMarDev_Buy       = Dev_Buy;
                       _FeeMarDev_Sell      = Dev_Sell;

                       _Total_Fee_On_Buys   = _FeeTeamTokens_Buy + _FeeReflection_Buy + _FeeMarDev_Buy + Liquidity_Buy;
                       _Total_Fee_On_Sells  = _FeeTeamTokens_Sell + _FeeReflection_Sell + _FeeMarDev_Sell + Liquidity_Sell;

                       }






    /*

    Updating Wallets

    */

   
    //Update the TeamTokenDistribution address
    function Update_TeamTokenDistribution(address payable contract_address) external onlyOwner() {
        // Can't be zero address
        require(contract_address != address(0), "new contract address is the zero address");

        // Update mapping on old contract
        _isExcludedFromFee[TeamTokenDistribution] = false; 

        // Update to new contract
        TeamTokenDistribution = contract_address;

        // Update mapping on new contract
        _isExcludedFromFee[TeamTokenDistribution] = true;
    }
   

    //Update the marketing wallet
    function Update_MarTeamDev_Wallet(address payable wallet) external onlyOwner() {
        // Can't be zero address
        require(wallet != address(0), "new wallet is the zero address");

        // Update mapping on old wallet
        _isExcludedFromFee[Wallet_Market_Develop] = false; 

        // Swap wallet to new one
        Wallet_Market_Develop = wallet;

        // Update mapping on new wallet
        _isExcludedFromFee[Wallet_Market_Develop] = true;
    }

   
    //Update the LP wallet
    function Update_CakeLP_Wallet(address payable wallet) external onlyOwner() {

        Wallet_LP = wallet;
    }
   



    
    /*

    SwapAndLiquify Switches

    */
    
    // Toggle on and off to activate auto liquidity and the promo wallet 
    function set_Swap_And_Liquify_Enabled(bool true_or_false) public onlyOwner {
        swapAndLiquifyEnabled = true_or_false;
        emit SwapAndLiquifyEnabledUpdated(true_or_false);
    }

    // This will set the number of transactions required before the 'swapAndLiquify' function triggers
    function set_Number_Of_Transactions_Before_Liquify_Trigger(uint256 number_of_transactions) public onlyOwner {
        swapTrigger = number_of_transactions;
    }
    


    // This function is required so that the contract can receive BNB from pancakeswap
    receive() external payable {}




    /*

    SafeLaunch Features

    Wallet Limits

    Wallets are limited in two ways. The amount of tokens that can be purchased in one transaction
    and the total amount of tokens a wallet can buy. Limiting a wallet prevents one wallet from holding too
    many tokens, which can scare away potential buyers that worry that a whale might dump!

    Wallet limits must be a whole number.

    */




    // Set Wallet Limits as Percent of Total Supply
    function set_Wallet_Max_Percent(uint256 max_Transaction_Percent, uint256 max_Wallet_Holding_Percent) external onlyOwner() {

        // Buyer protection - Max can never be set to 0
        require(max_Transaction_Percent > 0, "Max transaction must be greater than zero!");
        require(max_Wallet_Holding_Percent > 0, "Max transaction must be greater than zero!");
        _maxTxAmount = _tTotal*max_Transaction_Percent/100;
        _maxWalletToken = _tTotal*max_Wallet_Holding_Percent/100;

    }
    
    

    // Set Wallet Limits in Tokens
    function set_Wallet_Max_Tokens(uint256 max_Transaction_Tokens, uint256 max_Wallet_Holding_Tokens) external onlyOwner() {

        // Buyer protection - Max can never be set to 0
        require(max_Transaction_Tokens > 0, "Max transaction must be greater than zero!");
        require(max_Wallet_Holding_Tokens > 0, "Max transaction must be greater than zero!");
        _maxTxAmount = max_Transaction_Tokens *10**_decimals;
        _maxWalletToken = max_Wallet_Holding_Tokens *10**_decimals;
    }
  


    
    // Open Trade 
    function openTrade(bool true_or_false) external onlyOwner() {
        TradeOpen = true_or_false;
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
    

    // Take MarDevLiq - Includes all fees to be processed (Marketing, Liquidity, Development)
    function _takeMarDevLiq(uint256 _tMarDevLiq, uint256 _rMarDevLiq) private {

        _rOwned[address(this)] = _rOwned[address(this)].add(_rMarDevLiq);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(_tMarDevLiq);
    }


    // Take the tokens for the team and send to the TeamTokenDistribution where they will be forwarded to the team members
    function _takeTeamTokens(uint256 _tTeamTokens, uint256 _rTeamTokens) private {
  
        _rOwned[TeamTokenDistribution] = _rOwned[TeamTokenDistribution].add(_rTeamTokens);
        if(_isExcluded[TeamTokenDistribution]){
            _tOwned[TeamTokenDistribution] = _tOwned[TeamTokenDistribution].add(_tTeamTokens);
        }
    }


    // Take Reflection using RFI
    function _takeReflection(uint256 _rReflect, uint256 _tReflect) private {
        _rTotal = _rTotal.sub(_rReflect);
        _tFeeTotal = _tFeeTotal.add(_tReflect);
    }
    





    function _approve(address owner, address spender, uint256 amount) private {

        require(owner != address(0) && spender != address(0), "ERR: zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);

    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {


                if (!TradeOpen){

                    require(_preLaunchAccess[from] || _preLaunchAccess[to], "Trade is not open yet, please come back later");
                    
                    }
                
       


        /*

        TRANSACTION AND WALLET LIMITS

        */



        // Limit wallet total
        if (to != address(this) &&
            !_limitExempt[to] &&
            from != owner()){
            uint256 heldTokens = balanceOf(to);
            require((heldTokens + amount) <= _maxWalletToken,"You are trying to buy too many tokens. You have reached the limit for one wallet.");}


        // Limit the maximum number of tokens that can be bought or sold in one transaction
        if (!_limitExempt[to] && !_limitExempt[from])
            require(amount <= _maxTxAmount, "You are trying to buy more than the max transaction limit.");




        require(from != address(0) && to != address(0), "ERR: Using 0 address!");
        require(amount > 0, "Token value must be higher than zero.");


        // SwapAndLiquify is triggered after every X transactions - this number can be adjusted using swapTrigger
        

        if(
            txCount >= swapTrigger && 
            !inSwapAndLiquify &&
            _isPair[to] &&
            swapAndLiquifyEnabled &&
            block.number > swapBlock
            )
        {  
            
            
            uint256 contractTokenBalance = balanceOf(address(this));
            if(contractTokenBalance > _maxTxAmount) {contractTokenBalance = _maxTxAmount;}
            txCount = 0;
            swapAndLiquify(contractTokenBalance);
            swapBlock = block.number;
        }
        



        
        bool takeFee = true;

        // Do we need to charge a fee? No fee to transfer tokens, only on buys and sells
         
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to] || (noFeeToTransfer && !_isPair[to] && !_isPair[from])){
            takeFee = false;
        }
        
        _tokenTransfer(from,to,amount,takeFee);

    }   




    /*

    Processing Fees

    */


    
    function sendToWallet(address payable wallet, uint256 amount) private {
            wallet.transfer(amount);
        }



    function precDiv(uint a, uint b, uint precision) internal pure returns (uint) {
     return a*(10**precision)/b;
         
    }



    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        
       
       uint256 splitPromo;
       uint256 tokensToPromo;
       uint256 totalBNB;
       

        // Marketing to Liquidity ratio is based on Sell!


        if (_FeeMarDev_Sell != 0 && _FeeLiquidity_Sell != 0){


            // Calculate the correct ratio splits for marketing and developer
            splitPromo = precDiv(_FeeMarDev_Sell,(_FeeLiquidity_Sell+_FeeMarDev_Sell),2);
            tokensToPromo = contractTokenBalance*splitPromo/100;


        uint256 Half = (contractTokenBalance-tokensToPromo)/2;
        uint256 balanceBeforeSwap = address(this).balance;
        swapTokensForEth(Half+tokensToPromo);
        totalBNB = address(this).balance - balanceBeforeSwap;
        uint256 promoBNB = totalBNB*splitPromo/100;
        addLiquidity(Half, (totalBNB-promoBNB));
        emit SwapAndLiquify(Half, (totalBNB-promoBNB), Half);

        // Purge remaining BNB into Marketing and Development Wallet
        totalBNB = address(this).balance;
        sendToWallet(Wallet_Market_Develop, totalBNB);

    } else if (_FeeMarDev_Sell != 0 && _FeeLiquidity_Sell == 0){

        swapTokensForEth(contractTokenBalance);

        // Purge remaining BNB into Marketing and Development Wallet
        totalBNB = address(this).balance;
        sendToWallet(Wallet_Market_Develop, totalBNB);


    } else if (_FeeMarDev_Sell == 0 && _FeeLiquidity_Sell != 0){

        // Process everything into Liquidity
        uint256 Half = contractTokenBalance/2;
        uint256 balanceBeforeSwap = address(this).balance;
        swapTokensForEth(Half);
        totalBNB = address(this).balance - balanceBeforeSwap;
        addLiquidity(Half, totalBNB);
        emit SwapAndLiquify(Half, totalBNB, Half);

        // Purge accumulated dust from rounding errors if > 0.1 BNB
        if (balanceBeforeSwap > 10**17)
        totalBNB = address(this).balance;
        sendToWallet(Wallet_Market_Develop, totalBNB);

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


    /*

    Creating Auto Liquidity

    */

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {

        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, 
            0,
            Wallet_LP,
            block.timestamp
        );
    } 





    /*

    PURGE RANDOM TOKENS - Add the random token address and a wallet to send them to

    */

    // Remove random tokens from the contract and send to a wallet
    function remove_Random_Tokens(address random_Token_Address, address send_to_wallet, uint256 percent_of_Tokens) public onlyOwner returns(bool _sent){
        require(random_Token_Address != address(this), "Can not remove native token");
        uint256 totalRandom = IERC20(random_Token_Address).balanceOf(address(this));
        uint256 removeRandom = totalRandom*percent_of_Tokens/100;
        _sent = IERC20(random_Token_Address).transfer(send_to_wallet, removeRandom);

       
    }





    /*
    
    UPDATE PANCAKESWAP ROUTER AND LIQUIDITY PAIRING

    */


    // Set new router and make the new pair address
    function set_New_Router_and_Make_Pair(address newRouter) public onlyOwner() {
        IUniswapV2Router02 _newPCSRouter = IUniswapV2Router02(newRouter);
        uniswapV2Pair = IUniswapV2Factory(_newPCSRouter.factory()).createPair(address(this), _newPCSRouter.WETH());
        uniswapV2Router = _newPCSRouter;
    }
   
    // Set new router
    function set_New_Router_Address(address newRouter) public onlyOwner() {
        IUniswapV2Router02 _newPCSRouter = IUniswapV2Router02(newRouter);
        uniswapV2Router = _newPCSRouter;
    }
    
    // Set new address - This will be the 'Cake LP' address for the token pairing
    function set_New_Pair_Address(address newPair) public onlyOwner() {
        uniswapV2Pair = newPair;
    }
   

    // Manual 'swapAndLiquify' Trigger (Enter the percent of the tokens that you'd like to send to swap and liquify)
    function process_SwapAndLiquify_Now (uint256 percent_Of_Tokens_To_Liquify) public onlyOwner {
        // Do not trigger if already in swap
        require(!inSwapAndLiquify, "Currently processing liquidity, try later."); 
        if (percent_Of_Tokens_To_Liquify > 100){percent_Of_Tokens_To_Liquify == 100;}
        uint256 tokensOnContract = balanceOf(address(this));
        uint256 sendTokens = tokensOnContract*percent_Of_Tokens_To_Liquify/100;
        swapAndLiquify(sendTokens);
    }

  
    /*

    Transfer Functions

    */


    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {

            // Update the fees if the transaciton is a buy or sell

            if (_isPair[recipient] && takeFee) {

                // SELL - Fees in tokens
                _FeeTeamTokens  = _FeeTeamTokens_Sell;
                _FeeReflection  = _FeeReflection_Sell;
                _FeeLiquidity   = _FeeLiquidity_Sell;
                _FeeMarDev      = _FeeMarDev_Sell;

                // AntiDump Checks
                if (antiDump && amount > (antiDump_Max_Sell * 10**_decimals) && !_DumpExempt[sender]){
            
                    // Increase the tax due to the sell being over Max permitted
                    _FeeLiquidity = _FeeLiquidity + antiDump_Tax_Increase;

                }

                if (antiDump && amount > (antiDump_Repeat_Trigger * 10**_decimals) && !_DumpExempt[sender]){

                            // Further increase the tax if they dumped recently
                            if(block.timestamp < _Dump_SellTime[recipient]){

                            _FeeLiquidity = _FeeLiquidity + antiDump_Tax_Increase;

                            }

                    // Set the new Sell Time for the Dump!
                    _Dump_SellTime[sender] = block.timestamp + antiDump_Wait_Time;

                }

                // Increase trigger counter
                txCount++; 
            
            } else if (_isPair[sender] && takeFee) {

                // BUY - Fees in tokens
                _FeeTeamTokens  = _FeeTeamTokens_Buy;
                _FeeReflection  = _FeeReflection_Buy;
                _FeeLiquidity   = _FeeLiquidity_Buy;
                _FeeMarDev      = _FeeMarDev_Buy;

                // Increase trigger counter
                txCount++; 

            } else if (!noFeeToTransfer && !_isPair[recipient] && !_isPair[sender]) {

                // Wallet to wallet transfers without fees off - transfers taxed as sells
                _FeeTeamTokens  = _FeeTeamTokens_Sell;
                _FeeReflection  = _FeeReflection_Sell;
                _FeeLiquidity   = _FeeLiquidity_Sell;
                _FeeMarDev      = _FeeMarDev_Sell;

                // Increase trigger counter
                txCount++; 
            
            } else {

                // Set all fees to zero percent if not a buy or sell or wallet is excluded from fee
                _FeeTeamTokens  = 0; 
                _FeeReflection  = 0; 
                _FeeLiquidity   = 0;
                _FeeMarDev      = 0; 

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

        
    }




   function _transferStandard(address sender, address recipient, uint256 tAmount) private {

        tMarDevLiq = tAmount*(_FeeMarDev+_FeeLiquidity)/100;
        tTeamTokens = tAmount*_FeeTeamTokens/100;
        tReflect = tAmount*_FeeReflection/100;

        rAmount = tAmount.mul(_getRate());
        rMarDevLiq = tMarDevLiq.mul(_getRate());
        rTeamTokens = tTeamTokens.mul(_getRate());
        rReflect = tReflect.mul(_getRate());

        tTransferAmount = tAmount-(tTeamTokens+tReflect+tMarDevLiq);
        rTransferAmount = rAmount-(rTeamTokens+rReflect+rMarDevLiq);

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        _takeMarDevLiq(tMarDevLiq, rMarDevLiq);
        _takeTeamTokens(tTeamTokens, rTeamTokens);
        _takeReflection(rReflect, tReflect);

        if(recipient == Wallet_Burn){

        _tTotal = _tTotal.sub(tTransferAmount);
        _rTotal = _rTotal.sub(rTransferAmount);

        }

        emit Transfer(sender, recipient, tTransferAmount);
    }

    

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {

        tMarDevLiq = tAmount*(_FeeMarDev+_FeeLiquidity)/100;
        tTeamTokens = tAmount*_FeeTeamTokens/100;
        tReflect = tAmount*_FeeReflection/100;

        rAmount = tAmount.mul(_getRate());
        rMarDevLiq = tMarDevLiq.mul(_getRate());
        rTeamTokens = tTeamTokens.mul(_getRate());
        rReflect = tReflect.mul(_getRate());

        tTransferAmount = tAmount-(tTeamTokens+tReflect+tMarDevLiq);
        rTransferAmount = rAmount-(rTeamTokens+rReflect+rMarDevLiq);

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount); 

        _takeMarDevLiq(tMarDevLiq, rMarDevLiq);
        _takeTeamTokens(tTeamTokens, rTeamTokens);
        _takeReflection(rReflect, tReflect);

        if(recipient == Wallet_Burn){

        _tTotal = _tTotal.sub(tTransferAmount);
        _rTotal = _rTotal.sub(rTransferAmount);

        }

        emit Transfer(sender, recipient, tTransferAmount);
    }


    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {

        tMarDevLiq = tAmount*(_FeeMarDev+_FeeLiquidity)/100;
        tTeamTokens = tAmount*_FeeTeamTokens/100;
        tReflect = tAmount*_FeeReflection/100;

        rAmount = tAmount.mul(_getRate());
        rMarDevLiq = tMarDevLiq.mul(_getRate());
        rTeamTokens = tTeamTokens.mul(_getRate());
        rReflect = tReflect.mul(_getRate());

        tTransferAmount = tAmount-(tTeamTokens+tReflect+tMarDevLiq);
        rTransferAmount = rAmount-(rTeamTokens+rReflect+rMarDevLiq);

        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount); 

        _takeMarDevLiq(tMarDevLiq, rMarDevLiq);
        _takeTeamTokens(tTeamTokens, rTeamTokens);
        _takeReflection(rReflect, tReflect);

        if(recipient == Wallet_Burn){

        _tTotal = _tTotal.sub(tTransferAmount);
        _rTotal = _rTotal.sub(rTransferAmount);

        }

        emit Transfer(sender, recipient, tTransferAmount);
    }


     function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {

        tMarDevLiq = tAmount*(_FeeMarDev+_FeeLiquidity)/100;
        tTeamTokens = tAmount*_FeeTeamTokens/100;
        tReflect = tAmount*_FeeReflection/100;

        rAmount = tAmount.mul(_getRate());
        rMarDevLiq = tMarDevLiq.mul(_getRate());
        rTeamTokens = tTeamTokens.mul(_getRate());
        rReflect = tReflect.mul(_getRate());

        tTransferAmount = tAmount-(tTeamTokens+tReflect+tMarDevLiq);
        rTransferAmount = rAmount-(rTeamTokens+rReflect+rMarDevLiq);

        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount); 

        _takeMarDevLiq(tMarDevLiq, rMarDevLiq);
        _takeTeamTokens(tTeamTokens, rTeamTokens);
        _takeReflection(rReflect, tReflect);

        if(recipient == Wallet_Burn){

        _tTotal = _tTotal.sub(tTransferAmount);
        _rTotal = _rTotal.sub(rTransferAmount);

        }
        
        emit Transfer(sender, recipient, tTransferAmount);
    }




    /*

    AIRDROP!

    */


    function _TransferTokens_AirDrop(address[] calldata Wallets, uint256[] calldata Tokens)  external onlyOwner(){

        require(Wallets.length <= 500, "Limit sending to 500 to reduce errors"); 
        require(Wallets.length == Tokens.length, "Token and Wallet count missmatch!");

        uint256 checkQuantity;

        for(uint i=0; i < Wallets.length; i++){
        checkQuantity = checkQuantity + Tokens[i];
        }

        require(balanceOf(msg.sender) >= checkQuantity, "You do not have enough tokens!");

        for (uint i=0; i < Wallets.length; i++) {
            transfer(Wallets[i], Tokens[i]*10**_decimals);
        }
    }


}







// This contract can not be used/forked without permission