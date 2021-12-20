/**
 *Submitted for verification at BscScan.com on 2021-12-19
*/

// SPDX-License-Identifier: Unlicensed 
// Unlicensed SPDX-License-Identifier is not Open Source 
// This contract can not be used/forked without permission 
// Contract created specifically for iPAY by https://gentokens.com/ 

/*

Name: iPay
Symbol: iPay

Initial Total Supply: 1,000,000,000,000 (1 Trillion)

iPay token is deflationary. So the supply will reduce over time if tokens are burned.

10% Transactions fee on buy / sell

2% Auto Liquidity
2% Reflection to holders
6% Marketing

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






contract iPAY is Context, IERC20 { 
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public _isExcludedFromFee; 
    mapping (address => bool) public _isExcluded; 
    mapping (address => bool) public _isSnipe;
    mapping (address => bool) public _preLaunchAccess;
    mapping (address => bool) public _limitExempt; 


    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   
    
    function owner() public view virtual returns (address) {
        return _owner;
    }


    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }


    // Safe launch protocols
    bool public launchPhase = true;
    bool public TradeOpen;


    

    address[] private _excluded; // Excluded from rewards
    address payable public Wallet_Marketing = payable(0x06376fF13409A4c99c8d94A1302096CB4dC7c07e); // 3
    address payable public Wallet_BUSD_LP = payable(0x7D15025D421c5fF186017e8809C584De9036772A); // 6
    address payable public constant Wallet_Burn = payable(0x000000000000000000000000000000000000dEaD);

    // XXXX BUSD TESTNET
    address private BUSD_T = address(0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7);
    
   




    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _decimals = 9;

    uint256 private _tTotal = 10**12 * 10**_decimals;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    uint256 private _tFeeTotal;
    string  private constant _name = "iPAY"; 
    string  private constant _symbol = "iPAY";  

    // Counter for liquify trigger
    uint256 private txCount = 0;
    uint256 private swapTrigger = 10; 

    // Setting the initial fees
    uint256 public _FeeReflection_Buy = 2;
    uint256 public _FeeReflection_Sell = 2;
    uint256 public _Total_Buy_Fee = 10;
    uint256 public _Total_Sell_Fee = 10;

    // Buyer protection - Max possible fee is hardcoded!
    uint256 public _Tax_On_Buy_MAX = 12;
    uint256 public _Tax_On_Sell_MAX = 12;

    // Collected fee allocation percent
    uint256 public Percent_Liquidity = 25;
    uint256 public Percent_Marketing = 75;

    /*

    Wallets are limited during the initial LaunchPhase

    */

    // Max wallet holding (0.05% at launch)
    uint256 public _maxWalletToken = _tTotal.mul(5).div(10000);
    uint256 private _previousMaxWalletToken = _maxWalletToken;

    // Maximum transaction amount (0.05% at launch)
    uint256 public _maxTxAmount = _tTotal.mul(5).div(10000); 
    uint256 private _previousMaxTxAmount = _maxTxAmount;
                                     
    IUniswapV2Router02 public uniswapV2Router;
    address public BUSD_Pair;
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


        _owner = 0x627C95B6fD9026E00Ab2c373FB08CC47E02629a0;
        emit OwnershipTransferred(address(0), _owner);

        _rOwned[owner()] = _rTotal;
        
        //IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); 
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); // TESTNET BSC
        //IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); //  ETH 
      
        BUSD_Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), address(BUSD_T));
        uniswapV2Router = _uniswapV2Router;

           // .createPair(address(this), BUSD_T); /// XXXXXX THIS ONE NOT THE ABOVE ONE?  -- SET AS PAIR!


/*
           

            // XXXXX can we remove the create pair for BNB? So it only has BUSD? - live test needed! 

            
        // Create Pair
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        
        */
            




        /*

        Set initial wallet mappings

        */

        // Wallet that are excluded from fees
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[Wallet_Marketing] = true; 
        _isExcludedFromFee[Wallet_BUSD_LP] = true; 
        _isExcludedFromFee[Wallet_Burn] = true;


        // Wallets that are not restricted by transaction and holding limits
        _limitExempt[owner()] = true;
        _limitExempt[Wallet_Burn] = true;
        _limitExempt[Wallet_Marketing] = true; 
        _limitExempt[Wallet_BUSD_LP] = true; 


        // Wallets granted access before trade is oopen
        _preLaunchAccess[owner()] = true;
        _preLaunchAccess[Wallet_BUSD_LP] = true; 

        // Exclude burn address from rewards - Rewards sent to burn are not deflationary! 
        _isExcluded[Wallet_Burn] = true;
        _isExcluded[Wallet_BUSD_LP] = true; 
        _isExcluded[address(this)] = true;

        // Setting up the BUSD pair  // XXXXX fix this later!
        _isExcluded[BUSD_Pair] = true; 
        _limitExempt[BUSD_Pair] = true;
        _isPair[BUSD_Pair] = true;


        
        
        emit Transfer(address(0), owner(), _tTotal);
    }


    function name() external pure returns (string memory) {
        return _name;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint256) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
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

    function allowance(address theOwner, address spender) external view override returns (uint256) {
        return _allowances[theOwner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function isExcludedFromReward(address account) external view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() external view returns (uint256) {
        return _tFeeTotal;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {

        // can't be zero address
        require(newOwner != address(0), "Ownable: new owner is the zero address");

        // remove old mappings
        _isExcludedFromFee[owner()] = false;
        _limitExempt[owner()] = false;
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;

        // Update new mappings
        _isExcludedFromFee[owner()] = false;
        _limitExempt[owner()] = false;
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

    function set_as_Pair(address wallet, bool true_or_false) external onlyOwner {
        _isPair[wallet] = true_or_false;
    }


    function tokenFromReflection(uint256 _rAmount) public view returns(uint256) {
        require(_rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return _rAmount.div(currentRate);
    }


    /*

    Manually set mappings

    */


    // Limit except - used to allow a wallet to hold more than the max limit - for locking tokens etc
    function mapping_limitExempt(address account, bool true_or_false) external onlyOwner() {    
        _limitExempt[account] = true_or_false;
    }

    // Pre Launch Access - able to buy and sell before the trade is open 
    function mapping_preLaunchAccess(address account, bool true_or_false) external onlyOwner() {    
        _preLaunchAccess[account] = true_or_false;
    }

    // Add wallet to snipe list 
    function mapping_isSnipe(address account, bool true_or_false) external onlyOwner() {  
        _isSnipe[account] = true_or_false;
    }






    // Wallet will not get reflections
    function Rewards_Exclude_Wallets(address account) external onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }





    // Wallet will get reflections - DEFAULT
    function Rewards_Include_Wallets(address account) external onlyOwner() {
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
    




    

    // Set a wallet address so that it does not have to pay transaction fees
    function Fees_Exclude_Wallet(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    // Set a wallet address so that it has to pay transaction fees - DEFAULT
    function Fees_Include_Wallet(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
    }




    /*

    FEES  

    */

    // Setting the TOTAL FEE on buy and sell - The Reflection fee is taken from the total! 
    event setting_fees(uint256 Total_Tax_On_Buy, uint256 Total_Tax_On_Sell, uint256 Reflection_On_Buy, uint256 Reflection_On_Sell);
    function _set_Fees(uint256 Total_Tax_On_Buy, uint256 Total_Tax_On_Sell, uint256 Reflection_On_Buy, uint256 Reflection_On_Sell) external onlyOwner() {

  
        require(Total_Tax_On_Buy <= _Tax_On_Buy_MAX, "Buy fee too high!");
        require(Total_Tax_On_Sell <= _Tax_On_Sell_MAX, "Sell fee too high!");

        _Total_Buy_Fee = Total_Tax_On_Buy;
        _Total_Sell_Fee = Total_Tax_On_Sell;

        _FeeReflection_Buy = Reflection_On_Buy;
        _FeeReflection_Sell = Reflection_On_Sell;


        emit setting_fees(Total_Tax_On_Buy, Total_Tax_On_Sell, Reflection_On_Buy, Reflection_On_Sell);

    }

    // This must add up to 100! Setting the percent of the accumulated fees that go to Marketing and Liquidity
    function _set_Marketing_Liquidity_Split(uint256 Marketing, uint256 Liquidity) external onlyOwner() {

        require((Marketing + Liquidity) == 100, "Must add up to 100!");
   
        Percent_Marketing = Marketing;
        Percent_Liquidity = Liquidity;
        
    }



    /*

    Updating Wallets

    */

    

    //Update the marketing wallet
    function Wallet_Update_Marketing(address payable wallet) external onlyOwner() {
        // Can't be zero address
        require(wallet != address(0), "new wallet is the zero address");

        // Update mapping on old wallet
        _isExcludedFromFee[Wallet_Marketing] = false; 
        _limitExempt[Wallet_Marketing] = false;

        Wallet_Marketing = wallet;
        // Update mapping on new wallet
        _isExcludedFromFee[Wallet_Marketing] = true;
        _limitExempt[Wallet_Marketing] = true;
    }

    //Update the BUSD LP wallet
    function Wallet_Update_BUSD_LP(address payable wallet) external onlyOwner() {

        require(wallet != address(0), "new wallet is the zero address");

        // Update mapping on old wallet
        _isExcludedFromFee[Wallet_BUSD_LP] = false; 
        _limitExempt[Wallet_BUSD_LP] = false;

        Wallet_BUSD_LP = wallet;
        // Update mapping on new wallet
        _isExcludedFromFee[Wallet_BUSD_LP] = true;
        _limitExempt[Wallet_BUSD_LP] = true;

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
    function set_Number_Of_Transactions_Before_Liquify_Trigger(uint256 number_of_transactions) external onlyOwner {
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

    To allow for decimals Max Wallet and Max Holding are a factor of 100

    Example: for 2% enter 200, for 0.25% enter 25, for 0.1% enter 10

    */


    // Set the Max transaction amount (percent of total supply x 100)
    function set_Max_Transaction_Percent_X100(uint256 max_Transaction_Percent) external onlyOwner() {
        // Buyer protection - Max transaction can never be set to 0
        require(max_Transaction_Percent > 0, "Max transaction must be greater than zero!");
        _maxTxAmount = _tTotal * max_Transaction_Percent / 10000;
    }
    
    
    // Set the maximum permitted wallet holding (percent of total supply x 100)
     function set_Max_Wallet_Holding_Percent_X100(uint256 max_Wallet_Holding_Percent) external onlyOwner() {
        _maxWalletToken = _tTotal * max_Wallet_Holding_Percent / 10000;
    }
  

    uint256 private launchBlock;
    uint256 private swapBlock;
    
    // Open Trade - ONE WAY SWITCH! - Buyer Protection! 
    function openTrade() external onlyOwner() {
        TradeOpen = true;
        launchBlock = block.number;
    }


    // End Launch Phase - ONE WAY SWITCH - Buyer Protection!
    function end_LaunchPhase() external onlyOwner() {
        launchPhase = false;
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
    

    function _takeReflection(uint256 _rReflect, uint256 _tReflect) private {
        _rTotal = _rTotal - _rReflect;
        _tFeeTotal = _tFeeTotal + _tReflect;
    }

    function _takeOtherFees(uint256 _tOtherFees, uint256 _rOtherFees) private {
        
        _rOwned[address(this)] = _rOwned[address(this)] + _rOtherFees;
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)] + _tOtherFees;
    }


    

    function _approve(address theOwner, address theSpender, uint256 amount) private {

        require(theOwner != address(0) && theSpender != address(0), "ERR: zero address");
        _allowances[theOwner][theSpender] = amount;
        emit Approval(theOwner, theSpender, amount);

    }



    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {


          if (launchPhase){

                if (!TradeOpen){

                    require(_preLaunchAccess[from] || _preLaunchAccess[to], "Trade is not open yet, please come back later");
                    }
                
                if(TradeOpen){

                        // Block snipebots for approx 30 seconds 
                        if (launchBlock + 10 > block.number){
                        require((!_isSnipe[to] && !_isSnipe[from]), 'You tried to snipe, now you need to wait.');
                        }

                        // Buy in first block = snipe
                        if (launchBlock + 1 > block.number){

                            // Check if buy and permissions 
                            if(!_isPair[to] && to != address(this) && !_preLaunchAccess[to]){
                            _isSnipe[to] = true;
                            }
                        }

                        if ((block.number > launchBlock + 2) && (_maxTxAmount != _tTotal / 100)){

                            // Increase max transaction to 1%
                            _maxTxAmount = _tTotal / 100;
                            // Increase max wallet to 2%
                            _maxWalletToken = _tTotal * 2 / 100; 

                        }

                        if ((block.number > launchBlock + 5) && (_maxTxAmount != _tTotal * 2 / 100)){

                            // Increase max transaction to 2%
                            _maxTxAmount = _tTotal * 2 / 100; 

                            // Increase max wallet to 4%
                            _maxWalletToken = _tTotal * 4 / 100; 
                        }

                        if (block.number > launchBlock + 10){

                            // End Launch Phase
                            launchPhase = false;

                        }

                }

        }




    

        /*

        TRANSACTION AND WALLET LIMITS

        */
        

        // Limit wallet total - must be limited on buys and movement of tokens between wallets
        if (to != address(this) &&
            !_limitExempt[to] &&
            from != owner()){
            uint256 heldTokens = balanceOf(to);
            require((heldTokens + amount) <= _maxWalletToken, "You are trying to buy too many tokens.");}


        // Limit the maximum number of tokens that can be bought or sold in one transaction
        if (!_limitExempt[to] && !_limitExempt[from])
            require(amount <= _maxTxAmount, "You can not exceed the max transaction limit.");


        require(from != address(0) && to != address(0), "ERR: Using 0 address!");
        require(amount > 0, "Token value must be higher than zero.");


        // SwapAndLiquify is triggered after every X transactions - this number can be adjusted using swapTrigger
        

        if(
            txCount >= swapTrigger && 
            !inSwapAndLiquify &&
            !_isPair[from] &&
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

        // Do we need to charge a fee?
         
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to] || (noFeeToTransfer && !_isPair[to] && !_isPair[from])){
            takeFee = false;
        }
         

        _tokenTransfer(from,to,amount,takeFee);
    }



    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {


        if (Percent_Liquidity != 0){

            // Calculate how many tokens need to be swapped for BUSD (Marketing BUSD and 1/2 Auto Liquidity)

            uint256 tokens_to_M = contractTokenBalance * Percent_Marketing / 100;
            uint256 tokens_to_LP_Half = contractTokenBalance * Percent_Liquidity / 200;

            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = BUSD_T;
            _approve(address(this), address(uniswapV2Router), (tokens_to_LP_Half + tokens_to_M));
            uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            (tokens_to_LP_Half + tokens_to_M),
            0,
            path,
            Wallet_BUSD_LP,
            block.timestamp
            );

            // Remove iPAY Tokens from Contract
            _tOwned[address(this)] = _tOwned[address(this)] - tokens_to_LP_Half; 

            // Send iPAY Tokens To the BUSD LP Wallet
            _tOwned[Wallet_BUSD_LP] = _tOwned[Wallet_BUSD_LP] + tokens_to_LP_Half;
 

        } else if (Percent_Liquidity == 0){

            // Swap tokens for BUSD and send to Marketing Wallet if Auto LP is 0
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = BUSD_T;
            _approve(address(this), address(uniswapV2Router), contractTokenBalance);
            uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            contractTokenBalance,
            0,
            path,
            Wallet_BUSD_LP,
            block.timestamp
            );

        }

    }


    /*

    PURGE RANDOM TOKENS - Add the random token address and a wallet to send them to

    */

    // Remove random tokens from the contract and send to a wallet

    function remove_Random_Tokens(address random_Token_Address, address send_to_wallet, uint256 percent_of_Tokens) public onlyOwner returns(bool _sent){
        require(random_Token_Address != address(this), "Can not remove native token");
        require(random_Token_Address != address(BUSD_T), "Can not remove the designated liquidity token");
        uint256 totalRandom = IERC20(random_Token_Address).balanceOf(address(this));
        uint256 removeRandom = totalRandom*percent_of_Tokens/100;
        _sent = IERC20(random_Token_Address).transfer(send_to_wallet, removeRandom);

    }


    /*
    
    UPDATE ROUTER AND LIQUIDITY PAIRING

    */


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

    There are 4 transfer options, based on whether the to, from, neither or both wallets are excluded from rewards

    */


    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        
        if(takeFee)
            txCount++;
            
        _transferTokens(sender, recipient, amount, takeFee);

        }
    

    uint256 private rReflect; // Reflections
    uint256 private rOtherFees; // All other fees
    uint256 private rTransferAmount; // After deducting fees
    uint256 private rAmount; // Total tokens sent for transfer
    uint256 private tReflect; // Reflections
    uint256 private tOtherFees; // All other fees
    uint256 private tTransferAmount; // After deducting fees


   function _transferTokens(address sender, address recipient, uint256 tAmount, bool takeFee) private {


        // Calculate rAmount from initial tAmount - used on all transitions
        rAmount = tAmount.mul(_getRate());

        if (!takeFee){


                if (_isExcluded[sender] && !_isExcluded[recipient]) {

                                _tOwned[sender] = _tOwned[sender] - tAmount;
                                _rOwned[sender] = _rOwned[sender] - rAmount;
                                _rOwned[recipient] = _rOwned[recipient] + rAmount; 

                        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
        
                                _rOwned[sender] = _rOwned[sender] - rAmount;
                                _tOwned[recipient] = _tOwned[recipient] + tAmount;
                                _rOwned[recipient] = _rOwned[recipient] + rAmount;

                        } else if (_isExcluded[sender] && _isExcluded[recipient]) {

                                _tOwned[sender] = _tOwned[sender] - tAmount;
                                _rOwned[sender] = _rOwned[sender] - rAmount;
                                _tOwned[recipient] = _tOwned[recipient] + tAmount;
                                _rOwned[recipient] = _rOwned[recipient] + rAmount;  

                        } else {

                        _rOwned[sender] = _rOwned[sender] - rAmount;
                        _rOwned[recipient] = _rOwned[recipient] + rAmount;

                        }


            emit Transfer(sender, recipient, tAmount);


        } else {

            // Check if buy or sell
            if (_isPair[sender]) {

                // Transaction is a buy
                tReflect = tAmount * _FeeReflection_Buy / 100;
                tOtherFees = tAmount * (_Total_Buy_Fee - _FeeReflection_Buy) / 100;

            } else {

                // Transaction is a sell
                tReflect = tAmount * _FeeReflection_Sell / 100;
                tOtherFees = tAmount * (_Total_Sell_Fee - _FeeReflection_Sell) / 100;

            }

            
            // Calculate R Values for the fees
            rReflect = tReflect.mul(_getRate());
            rOtherFees = tOtherFees.mul(_getRate());

            // Calculate Transfer Amounts
            tTransferAmount = tAmount - (tReflect + tOtherFees);
            rTransferAmount = rAmount - (rReflect + rOtherFees);


                        if (_isExcluded[sender] && !_isExcluded[recipient]) {

                                _tOwned[sender] = _tOwned[sender].sub(tAmount);
                                _rOwned[sender] = _rOwned[sender].sub(rAmount);
                                _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount); 

                        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
        
                                _rOwned[sender] = _rOwned[sender].sub(rAmount);
                                _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
                                _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

                        } else if (_isExcluded[sender] && _isExcluded[recipient]) {

                                _tOwned[sender] = _tOwned[sender].sub(tAmount);
                                _rOwned[sender] = _rOwned[sender].sub(rAmount);
                                _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
                                _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);  

                        } else {

                        _rOwned[sender] = _rOwned[sender].sub(rAmount);
                        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

                        }


            _takeReflection(tReflect, rReflect);
            _takeOtherFees(tOtherFees, rOtherFees);

           

        emit Transfer(sender, recipient, tTransferAmount);

    }

    if(recipient == Wallet_Burn){

        _tTotal = _tTotal.sub(tAmount);
        _rTotal = _rTotal.sub(rAmount);

        }
    }

}


/*

Unlicensed SPDX-License-Identifier is not Open Source 
This contract can not be used/forked without permission 
Contract created for iPAY by https://gentokens.com/ 

*/