/**
 *Submitted for verification at BscScan.com on 2022-01-21
*/

// SPDX-License-Identifier: Unlicensed 
// Unlicensed SPDX-License-Identifier is not Open Source 
// This contract can not be used/forked without permission 

/*

TEST - DO NOT BUY!




https://t.me/GenCoins_GEN


Name:           TEST
Symbol:         TEST
Supply:         1,000,000,000,000
Decimals:       9

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
        _owner = 0xD05895EDF847e1712721Cc9e0427Aa26289A6Bc5;
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




contract TEST is Context, IERC20, Ownable { 
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public _isExcludedFromFee; 
    mapping (address => bool) public _isExcluded; // Excluded from RFI
    mapping (address => bool) public _isPair;
    mapping (address => bool) public _limitExempt;
    mapping (address => bool) public _preLaunchAccess;

    address[] private _excluded; // Excluded from rewards

    address payable public Wallet_BNB           = payable(0xD05895EDF847e1712721Cc9e0427Aa26289A6Bc5); // 41
    address payable public Wallet_Tokens        = payable(0xf9631AA0eb8b36d64d9b452C5eC743E84A7c16b0); // 9
    address payable public Wallet_LP            = payable(0xD05895EDF847e1712721Cc9e0427Aa26289A6Bc5); // 41
    address payable public constant Wallet_Burn = payable(0x000000000000000000000000000000000000dEaD); // Dead
    
   




    uint256 private constant MAX = ~uint256(0);
    uint8 private constant _decimals = 9;
    uint256 private _tTotal = 10**12 * 10**_decimals; // XXX CHECK TOTAL SUPPLY!
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    string private constant _name = "TEST"; 
    string private constant _symbol = "TEST"; 

    // Fee Processing Counter

    uint256 private txCount = 0;
    uint256 private swapTrigger = 10;               // Number of transactions (with fees) before processing


    // FEES - Initial Settings
  
    uint256 public _FeeBuy_Total        = 12;       // Total Fee on Buys - Includes Reflection
    uint256 public _FeeSell_Total       = 12;       // Total Fee on Sells - Includes Reflection

    uint256 public _FeeBuy_Reflection   = 2;        // RFI to holders on Buys
    uint256 public _FeeSell_Reflection  = 2;        // RFI to holders on Sells
  
    uint256 private _Fee_Total          = 12;       // Total Fee for processing
    uint256 private _Fee_Reflection     = 2;        // RFI for processing

    // Fee Splits, Total Must = 100

    uint256 public _Split_BNB           = 50;       // Percent of fee that goes to external BNB wallet
    uint256 public _Split_Tokens        = 25;       // Percent of fee that goes to external token wallet
    uint256 public _Split_Liquidity     = 25;       // Percent of fee for auto liquididty
    uint256 public _Split_Burn          = 0;        // Percent of fee sent to deflationary burn

    // RFI Calculations

    uint256 private rReflect;
    uint256 private rFees;
    uint256 private rTransferAmount;
    uint256 private rAmount;
    uint256 private tReflect;
    uint256 private tFees;
    uint256 private tTransferAmount;


    bool public freeSwap = true;                    // No fee to transfer between wallets
    bool public TradeOpen = true;                          // Trade Switch XXX




   

    // Set initial limits 

    uint256 public _max_Hold = _tTotal / 50;    // 2% of total supply
    uint256 public _max_Tran = _tTotal / 50;    // 2% of total supply
    uint256 public _max_Swap = _tTotal / 200;   // 0.5% of total supply
//    uint256 public _min_Swap = _tTotal / 10000; // 0.01% of total supply XXXX
    uint256 public _min_Swap = 1; // 0.01% of total supply
                                     
                                     
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
        
        //IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); 
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); // TESTNET BSC

              
        

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;

    


        /*

        Set initial wallet mappings

        */

        // Wallet that are excluded from fees

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[Wallet_BNB] = true;
        _isExcludedFromFee[Wallet_Tokens] = true;
        _isExcludedFromFee[Wallet_Burn] = true;

        // Wallet that are limit exempt

        _limitExempt[owner()] = true;
        _limitExempt[address(this)] = true;
        _limitExempt[Wallet_BNB] = true;
        _limitExempt[Wallet_Tokens] = true;
        _limitExempt[Wallet_Burn] = true;

        // Set Pair Address Mapping

        _isPair[uniswapV2Pair] = true;
        _isExcluded[uniswapV2Pair] = true; // XXX
        _limitExempt[uniswapV2Pair] = true;

        // Wallets granted access before trade is open

        _preLaunchAccess[owner()] = true;



        //Exclude burn address from rewards - Rewards sent to burn are not deflationary! // XXX add manually later!

        _isExcluded[Wallet_Burn] = true;
        _isExcluded[Wallet_BNB] = true;
        _isExcluded[Wallet_Tokens] = true;
        _isExcluded[address(this)] = true;



      
        
        emit Transfer(address(0), owner(), _tTotal);
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

        rAmount = tAmount * _getRate(); 
        
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rTotal = _rTotal - rAmount;
        _tFeeTotal = _tFeeTotal +tAmount;
    }






    function tokenFromReflection(uint256 _rAmount) public view returns(uint256) {
        require(_rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return _rAmount / currentRate;
    }








    






    /*

    Update Mappings

    */


    // Pre Launch Access - able to buy and sell when trade is closed 

    function mapping_PreLaunch_Access(address account, bool true_or_false) external onlyOwner() {    
        _preLaunchAccess[account] = true_or_false;
    }

    // Limit Exempt - Excluded from wallet and transaction limits

    function mapping_Limit_Exempt(address account, bool true_or_false) external onlyOwner() {    
        _limitExempt[account] = true_or_false;
    }


    // Set a wallet address so that it does not have to pay transaction fees

    function mapping_excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    // Set a wallet address so that it has to pay transaction fees
    function mapping_includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    // Exclude wallet from RFI - LOOP RISK OF OUT OF GAS! LIMIT TO ESSENTIAL WALLETS! (Contract, Pair and Burn ONLY!)

    function mapping_excludeFromReward(address account) public onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    // Include wallet in RFI

    function mapping_includeInReward(address account) external onlyOwner() {
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

    FEES  

    */

    function _set_Fees(

                        uint256 Buy_Total, 
                        uint256 Buy_Reflection, 

                        uint256 Sell_Total,
                        uint256 Sell_Reflection

                        ) external onlyOwner() {

                        _FeeBuy_Total       = Buy_Total - Buy_Reflection;
                        _FeeBuy_Reflection  = Buy_Reflection;

                        _FeeSell_Total      = Sell_Total - Sell_Reflection;
                        _FeeSell_Reflection = Sell_Reflection;


    }


    function _set_Fee_Split(

                        uint256 Split_BNB,
                        uint256 Split_Liquidity,
                        uint256 Split_Tokens,
                        uint256 Split_Burn

                        ) external onlyOwner() {


                        require(Split_BNB + Split_Liquidity + Split_Tokens + Split_Burn == 100, "Total fee splits must be 100");


                        _Split_BNB          = Split_BNB;
                        _Split_Liquidity    = Split_Liquidity;
                        _Split_Tokens       = Split_Tokens;
                        _Split_Burn         = Split_Burn;

    }

    function _set_Fee_FreeSwap(bool true_or_false) external onlyOwner() {freeSwap = true_or_false;}









    /*

    Wallets

    */



    // Update the LP wallet

    function Wallet_Update_Cake_LP(address payable wallet) external onlyOwner() {

        // To send the Auto LP tokens to Burn change this to 0x000000000000000000000000000000000000dEaD
        Wallet_LP = wallet;
    }


    // Update the BNB wallet

    function Wallet_Update_BNB(address payable wallet) external onlyOwner() {

        // Can't be zero address
        require(wallet != address(0), "new wallet is the zero address");

        // Update old wallet
        _isExcludedFromFee[Wallet_BNB] = false; 
        _limitExempt[Wallet_BNB] = false;

        Wallet_BNB = wallet;
        
        // Update new wallet
        _isExcludedFromFee[Wallet_BNB] = true;
        _limitExempt[Wallet_BNB] = true;
    }


    // Update the Token wallet

    function Wallet_Update_Tokens(address payable wallet) external onlyOwner() {

        // Can't be zero address
        require(wallet != address(0), "new wallet is the zero address");

        // Update old wallet
        _isExcludedFromFee[Wallet_Tokens] = false;
        _limitExempt[Wallet_Tokens] = false;

        Wallet_Tokens = wallet;
        
        // Update new wallet
        _isExcludedFromFee[Wallet_Tokens] = true;
        _limitExempt[Wallet_Tokens] = true;
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

    Set Limits

    */


    function set_Limits_For_Wallets(

        uint256 max_Tran_Percent,
        uint256 max_Hold_Percent,
        uint256 Divisor

        ) external onlyOwner() {

        require(max_Hold_Percent > 0, "Must be greater than zero!");
        require(max_Tran_Percent > 0, "Must be greater than zero!");
        
        _max_Hold = _tTotal * max_Hold_Percent / Divisor;
        _max_Tran = _tTotal * max_Tran_Percent / Divisor;

    }

    
    function set_Limits_For_Swap_Trigger(

        uint256 min_Swap_Tokens,
        uint256 max_Swap_Tokens

        ) external onlyOwner() {
        
        _min_Swap = min_Swap_Tokens * 10**_decimals;
        _max_Swap = max_Swap_Tokens * 10**_decimals;
    }
    
  
    
    // Trade switch

    function openTrade(bool true_or_false) external onlyOwner() {
        TradeOpen = true_or_false;
    }


    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply - _rOwned[_excluded[i]];
            tSupply = tSupply - _tOwned[_excluded[i]];
        }
        if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    


    function _takeFees(uint256 _tFees) private {
        
        // Address(this) Must be Excluded from Reward
        _tOwned[address(this)] = _tOwned[address(this)] + _tFees;
    }



    function _takeReflection(uint256 _tReflect, uint256 _rReflect) private {
        _rTotal = _rTotal - _rReflect;
        _tFeeTotal = _tFeeTotal + _tReflect;
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







        // Is trade open? 
        
        if (!TradeOpen){

        require(_preLaunchAccess[from] || _preLaunchAccess[to], "Trade is not open yet, please come back later");
       
        }








        // Select correct fee

        if (_isExcludedFromFee[to] || _isExcludedFromFee[from]){

            if (_Fee_Reflection != 0 && _Fee_Total != 0){
            _Fee_Reflection = 0;
            _Fee_Total      = 0;
            }

        } else if (_isPair[to]){

            if (_Fee_Reflection != _FeeSell_Reflection && _Fee_Total != _FeeSell_Total){
            _Fee_Reflection = _FeeSell_Reflection;
            _Fee_Total      = _FeeSell_Total;
            }

        txCount++;

        } else if (_isPair[from]){

            if (_Fee_Reflection != _FeeBuy_Reflection && _Fee_Total != _FeeBuy_Total){
            _Fee_Reflection = _FeeBuy_Reflection;
            _Fee_Total      = _FeeBuy_Total;
            }

        txCount++;

        } else if (!_isPair[to] && !_isPair[from] && freeSwap){

            if (_Fee_Reflection != 0 && _Fee_Total != 0){
            _Fee_Reflection = 0;
            _Fee_Total      = 0;
            }

        } else if (!_isPair[to] && !_isPair[from] && !freeSwap){

        
            if (_Fee_Reflection != _FeeSell_Reflection && _Fee_Total != _FeeSell_Total){
            _Fee_Reflection = _FeeSell_Reflection;
            _Fee_Total      = _FeeSell_Total;
            }

        txCount++;
        
        }





        

        // Wallet Limit

        if (!_limitExempt[to] &&
            from != owner()){
            uint256 heldTokens = balanceOf(to);
            require((heldTokens + amount) <= _max_Hold, "You are trying to buy too many tokens. You have reached the limit for one wallet.");}








        // Transaction limit

        if (!_limitExempt[to] || !_limitExempt[from])
            require(amount <= _max_Tran, "You are trying to transfer more than the max transaction limit.");




        require(from != address(0) && to != address(0), "To/from 0 address");
        require(amount > 0, "Token value must be higher than zero.");


        // Do the transfer

        _tokenTransfer(from,to,amount);


        // Process the fees

        if(
            txCount >= swapTrigger && 
            !inSwapAndLiquify &&
            !_isPair[to] &&
            swapAndLiquifyEnabled
            )
        {  
            
            uint256 contractTokenBalance = balanceOf(address(this));

            if(contractTokenBalance > _min_Swap) {

            if(contractTokenBalance > _max_Swap) {contractTokenBalance = _max_Swap;}
            txCount = 0;
            swapAndLiquify(contractTokenBalance);

            }
        }

    }







    // Process the fees

    function sendToWallet(address payable wallet, uint256 amount) private {
            wallet.transfer(amount);
        }


    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {


        // Process Token Fees - Address(this) & Wallet_BURN Must be Excluded From Reward!

         if (_Split_Liquidity != 0 && _Split_BNB != 0){


            uint256 tokens_to_M = contractTokenBalance * _Split_BNB / 100;
            uint256 tokens_to_LP_Half = contractTokenBalance * _Split_Liquidity / 200;

            uint256 balanceBeforeSwap = address(this).balance;
            swapTokensForEth(tokens_to_LP_Half + tokens_to_M);
            uint256 BNB_Total = address(this).balance - balanceBeforeSwap;


            // Split the total BNB with the correct ratio and create liquidity
            uint256 split_M = _Split_BNB * 100 / (_Split_Liquidity + _Split_BNB);
            uint256 BNB_M = BNB_Total * split_M / 100;

            addLiquidity(tokens_to_LP_Half, (BNB_Total - BNB_M));
            emit SwapAndLiquify(tokens_to_LP_Half, (BNB_Total-BNB_M), tokens_to_LP_Half);

            BNB_Total = address(this).balance;
            sendToWallet(Wallet_BNB, BNB_Total);

          

        } else if (_Split_Liquidity == 0 && _Split_BNB != 0){

            // Swap tokens for BNB

            uint256 tokens_to_BNB = contractTokenBalance * _Split_BNB / 100;
            swapTokensForEth(tokens_to_BNB);

            // Send BNB to Wallet

            uint256 BNB_Total = address(this).balance;
            sendToWallet(Wallet_BNB, BNB_Total);
          


        } else if (_Split_Liquidity != 0 && _Split_BNB == 0){

            // Liquidity

            uint256 tokens_to_LP = contractTokenBalance * _Split_Liquidity / 100;
            uint256 half_LP = tokens_to_LP / 2;
            uint256 balanceBeforeSwap = address(this).balance;
            swapTokensForEth(half_LP);
            uint256 BNB_LP = address(this).balance - balanceBeforeSwap;
            addLiquidity(half_LP, BNB_LP);
            emit SwapAndLiquify(half_LP, BNB_LP, half_LP);

        }

    }


    // Swap tokens to BNB

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


    // Add Liquidity

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {

        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, 
            0, 
            Wallet_Burn,
            block.timestamp
        );
    } 







    // Remove random tokens from the contract

    function remove_Random_Tokens(address random_Token_Address, uint256 percent_of_Tokens) public onlyOwner returns(bool _sent){
        uint256 totalRandom = IERC20(random_Token_Address).balanceOf(address(this));
        uint256 removeRandom = totalRandom * percent_of_Tokens / 100;
        _sent = IERC20(random_Token_Address).transfer(msg.sender, removeRandom);

    }




   

    // Manual 'swapAndLiquify' Trigger (Enter the percent of the tokens that you'd like to send to swap and liquify)

    function process_SwapAndLiquify_Now (uint256 percent_Of_Tokens_To_Liquify) public onlyOwner {
        require(!inSwapAndLiquify, "Currently processing liquidity."); 
        if (percent_Of_Tokens_To_Liquify > 100){percent_Of_Tokens_To_Liquify == 100;}
        uint256 tokensOnContract = balanceOf(address(this));
        uint256 sendTokens = tokensOnContract * percent_Of_Tokens_To_Liquify / 100;
        swapAndLiquify(sendTokens);
        txCount = 0;
    }





  
   

    // Transfer Functions

    function _tokenTransfer(address sender, address recipient, uint256 amount) private {
        
               
        
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

        tReflect    = tAmount * _Fee_Reflection / 100;
        tFees       = tAmount * (_Fee_Total - _Fee_Reflection) / 100;

        rAmount     = tAmount   * _getRate();    
        rReflect    = tReflect  * _getRate();
        rFees       = tFees     * _getRate();

        tTransferAmount     = tAmount - (tReflect + tFees);
        rTransferAmount     = rAmount - (rReflect + rFees);

        _rOwned[sender]     = _rOwned[sender] - rAmount;
        _rOwned[recipient]  = _rOwned[recipient] + rTransferAmount;

        emit Transfer(sender, recipient, tTransferAmount);

        _takeFees(tFees);
        _takeReflection(tReflect, rReflect);

        if(recipient == Wallet_Burn){

        _tTotal = _tTotal - tTransferAmount;
        _rTotal = _rTotal - rTransferAmount;

        }

        
    }


    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {

        tReflect    = tAmount * _Fee_Reflection / 100;
        tFees       = tAmount * (_Fee_Total - _Fee_Reflection) / 100;

        rAmount     = tAmount   * _getRate();    
        rReflect    = tReflect  * _getRate();
        rFees       = tFees     * _getRate();

        tTransferAmount     = tAmount - (tReflect + tFees);
        rTransferAmount     = rAmount - (rReflect + rFees);
        
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount; 

        emit Transfer(sender, recipient, tTransferAmount);

        _takeFees(tFees);
        _takeReflection(tReflect, rReflect);

        if(recipient == Wallet_Burn){

        _tTotal = _tTotal - tTransferAmount;
        _rTotal = _rTotal - rTransferAmount;

        }

        
    }


    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {

        tReflect    = tAmount * _Fee_Reflection / 100;
        tFees       = tAmount * (_Fee_Total - _Fee_Reflection) / 100;

        rAmount     = tAmount   * _getRate();    
        rReflect    = tReflect  * _getRate();
        rFees       = tFees     * _getRate();

        tTransferAmount     = tAmount - (tReflect + tFees);
        rTransferAmount     = rAmount - (rReflect + rFees);

        _tOwned[sender] = _tOwned[sender] - tAmount;
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;

       emit Transfer(sender, recipient, tTransferAmount);

        _takeFees(tFees);
        _takeReflection(tReflect, rReflect);

        if(recipient == Wallet_Burn){

        _tTotal = _tTotal - tTransferAmount;
        _rTotal = _rTotal - rTransferAmount;

        }

        
    }


     function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {

        tReflect    = tAmount * _Fee_Reflection / 100;
        tFees       = tAmount * (_Fee_Total - _Fee_Reflection) / 100;

        rAmount     = tAmount   * _getRate();    
        rReflect    = tReflect  * _getRate();
        rFees       = tFees     * _getRate();

        tTransferAmount     = tAmount - (tReflect + tFees);
        rTransferAmount     = rAmount - (rReflect + rFees);

        _tOwned[sender] = _tOwned[sender] - tAmount;
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;

        emit Transfer(sender, recipient, tTransferAmount);

        _takeFees(tFees);
        _takeReflection(tReflect, rReflect);

        if(recipient == Wallet_Burn){

        _tTotal = _tTotal - tTransferAmount;
        _rTotal = _rTotal - rTransferAmount;

        }

        
    }





    /*

    Airdrop for previous holders

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


// Contract by www.GenTokens.com