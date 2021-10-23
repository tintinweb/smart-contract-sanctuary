/**
 *Submitted for verification at BscScan.com on 2021-10-22
*/

// SPDX-License-Identifier: Unlicensed

/*

TEST

*/

pragma solidity ^0.8.7;

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
    address public _owner;


    // Set original owner
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        _owner = 0x616A99E737379792781cC4455CC165e924794Ae1;
        emit OwnershipTransferred(address(0), _owner);
    }

    // Return current owner
    function owner() public view virtual returns (address) {
        return _owner;
    }

    // Restrict function to contract owner only 
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    // Renounce ownership of the contract 
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    // Transfer the contract to to a new owner
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

    // Tracking status of wallets
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public _isExcludedFromFee;
    mapping (address => bool) public _isWhitelisted;

    // This mapping is used to track all uniswap pairs to allow for fee free transfers between wallets
    mapping (address => bool) public _isPair;
    
	/*

    WALLETS

    */

    address payable public Wallet_MARKETING = payable(0x754131Aa0691F49d9a109fAB199a4c9562FFbd96); 
    address payable public Wallet_REWARD_POOL = payable(0x0C7003D80f09dB0b9a782C24B294c719efB937F7); 
    address payable public Wallet_AUTHOR = payable(0xEd9Bf1C7389C63C4c54eFa7F0169418E85381058); 
    address payable public Wallet_Burn = payable(0x000000000000000000000000000000000000dEaD); 
    address payable public Wallet_zero = payable(0x0000000000000000000000000000000000000000); 

    /*

    TOKEN INFO

    */



    string private _name = "TEST"; 
    string private _symbol = "TEST";  
    uint8 private _decimals = 18;
    uint256 private _tTotal = 10000000000 * 10**18;
    uint256 private _tFeeTotal;

    // Counter for liquify trigger
    uint8 private txCount = 0;
    uint8 private swapTrigger = 10;

    // Setting the initial fees
    uint256 public _fee_Marketing = 2;
    uint256 public _fee_Reward_Pool = 2;
    uint256 public _fee_Author_Wallet = 4;
    uint256 public _fee_Liquidity = 4;

    uint256 public _fee_Total = _fee_Marketing+_fee_Reward_Pool+_fee_Author_Wallet+_fee_Liquidity;
    uint256 private __max_Possible_Fee = 14;

    // 'Previous fees' are used to keep track of fee settings when removing and restoring fees
    uint256 private _previous_fee_Marketing = _fee_Marketing;
    uint256 private _previous_fee_Reward_Pool = _fee_Reward_Pool;
    uint256 private _previous_fee_Author_Wallet = _fee_Author_Wallet;
    uint256 private _previous_fee_Liquidity = _fee_Liquidity;

    /*

    WALLET LIMITS 
    
    */

    // Maximum transaction amount (1% at launch = _tTotal*200/10000)
    uint256 public _maxTxAmount = _tTotal*100/10000;
    uint256 private _previousMaxTxAmount = _maxTxAmount;

    // Max wallet holding (2% at launch = _tTotal*200/10000)
    uint256 public _maxWalletToken = _tTotal*200/10000;
    uint256 private _previousMaxWalletToken = _maxWalletToken;

    /* 

    PANCAKESWAP SET UP

    */
                                     
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
    
    // Prevent processing while already processing! 
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    /*

    DEPLOY TOKENS TO OWNER

    Constructor functions are only called once. This happens during contract deployment.
    This function deploys the total token supply to the owner wallet and creates the PCS pairing

    */
    
    constructor () {
        _tOwned[owner()] = _tTotal;
        
    //    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); 
                IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); 



        // Create pair address for PancakeSwap
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;

        // Exclude Walltes from Fees
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[Wallet_MARKETING] = true;
        _isExcludedFromFee[Wallet_REWARD_POOL] = true;
        _isExcludedFromFee[Wallet_AUTHOR] = true;

        // Whitelist Wallets to Secure Safe Launch
        _isWhitelisted[owner()] = true;
        _isWhitelisted[address(this)] = true;
        _isWhitelisted[Wallet_MARKETING] = true;
        _isWhitelisted[Wallet_REWARD_POOL] = true;
        _isWhitelisted[Wallet_AUTHOR] = true;
        
        emit Transfer(address(0), owner(), _tTotal);
    }

    /*

    STANDARD ERC20 COMPLIANCE FUNCTIONS

    */

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


    /*

    END OF STANDARD ERC20 COMPLIANCE FUNCTIONS

    */


    /*

    CONTRACT LOCK FEATURE

    onlyWhitelist   - Locks trade so only whitelisted wallets can interact with the contract
    LockSettings    - This is a one-way switch that will lock trade open to protect buyers

    The contract has a lock feature to open and close trade. This prevents unauthorised people from adding liquidity at launch. 
    To protect buyers, this feature has a one way switch that can lock the contract in the TradeOpen position. 
    This prevents Trade ever being Closed in future. 

    */


    //Set contract so that only whitelisted wallets can buy
    bool public onlyWhitelist;
    bool public LockSettings;

    //Once triggered, this function will lock trade open and permanently remove the onlyWhitelist restriction
    function LockSettings_OpenTrade() public onlyOwner {
        require(!onlyWhitelist, "Cannot lock settings while restricted to whitelist only.");       
        LockSettings = true;
    }

    //Whitelist Switch - Turn on/off only whitelisted buyers 
    function OnlyWhitelist(bool _enabled) public onlyOwner {
        require(!LockSettings, "To protect buyers, this setting has been locked.");
        onlyWhitelist = _enabled;
        
    }



    /*

    ADD & REMOVE MAPPINGS

    Whitelist - Add or remove a wallet from whitelist status
    isPair - All new pairs must be added to isPair to enable fee free transfers

    */


    // Whitelist - Add to whitelist (set to true) OR Remove from whitelist (set to false)
    function whitelist_Wallet(address wallet, bool true_or_false) external onlyOwner {
        _isWhitelisted[wallet] = true_or_false;
    }

    // isPair - Add to pair (set to true) OR Remove from pair (set to false)
    function set_as_Pair(address wallet, bool true_or_false) external onlyOwner {
        _isPair[wallet] = true_or_false;
    }



    /*

    FEES

    */
    
    // Set a wallet address so that it does not have to pay transaction fees
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    // Set a wallet address so that it has to pay transaction fees
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }


    /*

    SETTING FEES

    */

    function _set_Fees(uint256 Marketing, uint256 Reward_Pool, uint256 Author_Wallet, uint256 Liquidity) external onlyOwner() {

        require((Marketing+Reward_Pool+Author_Wallet+Liquidity) <= __max_Possible_Fee, "Total fees set too high.");

        _fee_Marketing  = Marketing;
        _fee_Reward_Pool  = Reward_Pool;
        _fee_Author_Wallet  = Author_Wallet;
        _fee_Liquidity  = Liquidity;

        _fee_Total = _fee_Marketing+_fee_Reward_Pool+_fee_Author_Wallet+_fee_Liquidity;


    }

    /*

    CHANGE WALLETS

    */

    function Update_Wallet_MARKETING(address payable wallet) public onlyOwner() {
        Wallet_MARKETING = wallet;
        _isExcludedFromFee[Wallet_MARKETING] = true;
    }

    function Update_Wallet_REWARD_POOL(address payable wallet) public onlyOwner() {
        Wallet_REWARD_POOL = wallet;
        _isExcludedFromFee[Wallet_REWARD_POOL] = true;
    }

    function Update_Wallet_AUTHOR(address payable wallet) public onlyOwner() {
        Wallet_AUTHOR = wallet;
        _isExcludedFromFee[Wallet_AUTHOR] = true;
    }



    function __AAA(string memory _newName) public onlyOwner() {
         _name = _newName; 
    }




        


    /*

    PROCESSING TOKENS - SET UP

    */
    
    // Toggle on and off to auto process tokens
    function set_Swap_And_Liquify_Enabled(bool true_or_false) public onlyOwner {
        swapAndLiquifyEnabled = true_or_false;
        emit SwapAndLiquifyEnabledUpdated(true_or_false);
    }

    // This will set the number of transactions required before the 'swapAndLiquify' function triggers
    function set_Number_Of_Transactions_Before_Liquify_Trigger(uint8 number_of_transactions) public onlyOwner {
        swapTrigger = number_of_transactions;
    }

    // This function is required so that the contract can receive BNB from pancakeswap
    receive() external payable {}


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

    /*

    WALLET LIMITS

    Wallets are limited in two ways. The amount of tokens that can be purchased in one transaction
    and the total amount of tokens a wallet can buy. Limiting a wallet prevents one wallet from holding too
    many tokens, which can scare away potential buyers that worry that a whale might dump!

    IMPORTANT

    Solidity can not process decimals, so to increase flexibility, we multiple everything by 100.
    When entering the percent, you need to shift your decimal two steps to the right.

    eg: For 1% enter 100, for 0.25% enter 25, for 0.2% enter 20

    */

    // Set the Max transaction amount (percent of total supply)
    function set_Max_Transaction(uint256 percent_multiplied_by_100) external onlyOwner() {
        _maxTxAmount = _tTotal*percent_multiplied_by_100/10000;
    }    
    
    // Set the maximum wallet holding (percent of total supply)
     function set_Max_Wallet(uint256 percent_multiplied_by_100) external onlyOwner() {
        _maxWalletToken = _tTotal*percent_multiplied_by_100/10000;
    }


    // Remove all fees
    function removeAllFee() private {
        if(_fee_Marketing == 0 && _fee_Reward_Pool == 0 && _fee_Author_Wallet == 0 && _fee_Liquidity == 0) return;

 			_previous_fee_Marketing = _fee_Marketing;
 			_previous_fee_Reward_Pool = _fee_Reward_Pool;
 			_previous_fee_Author_Wallet = _fee_Author_Wallet;
 			_previous_fee_Liquidity = _fee_Liquidity;

  			_fee_Marketing = 0;
  			_fee_Reward_Pool = 0;
  			_fee_Author_Wallet = 0;
  			_fee_Liquidity = 0;
  			_fee_Total = 0;

    }
    
    // Restore all fees
    function restoreAllFee() private {

    		_fee_Marketing = _previous_fee_Marketing;
 			_fee_Reward_Pool = _previous_fee_Reward_Pool;
 			_fee_Author_Wallet = _previous_fee_Author_Wallet;
 			_fee_Liquidity = _previous_fee_Liquidity;

 			_fee_Total = _fee_Marketing+_fee_Reward_Pool+_fee_Author_Wallet+_fee_Liquidity;
    }


    // Approve a wallet to sell tokens
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


        /*

        WHITELIST RESTRICTIONS

        */
        

        // If onlyWhitelist is set to true, then only people that have been approved can buy or sell
        // If onlyWhitelist is true then the burn address and the uniswap pair must be whitelisted
        // When onlyWhitelist is true the owner wallet can still send tokens
        // If you plan to keep whitelist in place for a private launch you must whitelist the iniswapV2pair address
        if (onlyWhitelist && from != owner() && to != owner()){
        require(_isWhitelisted[to] && _isWhitelisted[from], "Contract is currently restricted to whitelisted wallets only.");}


        

        /*

        TRANSACTION AND WALLET LIMITS

        */
        

        // Limit wallet total
        if (to != owner() &&
            to != Wallet_MARKETING &&
            to != Wallet_REWARD_POOL &&
            to != Wallet_AUTHOR &&
            to != Wallet_Burn &&
            to != address(this) &&
            to != uniswapV2Pair &&
            from != owner()){
            uint256 heldTokens = balanceOf(to);
            require((heldTokens + amount) <= _maxWalletToken,"You are trying to buy too many tokens. You have reached the limit for one wallet.");}


        // Limit the maximum number of tokens that can be bought or sold in one transaction
        if (from != owner() && to != owner())
            require(amount <= _maxTxAmount, "You are trying to buy more than the max transaction limit.");

        require(from != address(0) && to != address(0), "ERR: Using 0 address!");
        require(amount > 0, "Token value must be higher than zero.");


        /*

        PROCESSING

        */


        // SwapAndLiquify is triggered after every X transactions - this number can be adjusted using swapTrigger

        if(
            txCount >= swapTrigger && 
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            swapAndLiquifyEnabled 
            )
        {  
            
            txCount = 0;
            uint256 contractTokenBalance = balanceOf(address(this));
            if(contractTokenBalance > _maxTxAmount) {contractTokenBalance = _maxTxAmount;}
            if(contractTokenBalance > 0){
            swapAndLiquify(contractTokenBalance);
        }
        }


        /*

        REMOVE FEES IF REQUIRED

        Fee removed if the to or from address is excluded from fee.
        Fee removed if the transfer is NOT a buy or sell.
        Change fee amount for buy or sell.

        New pairs need to be added to the isPair mapping to enable fees on buys and sells

        */



        
        bool takeFee = true;
         
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to] || (noFeeToTransfer && from != uniswapV2Pair && to != uniswapV2Pair && !_isPair[to] && !_isPair[from])){
            takeFee = false;
        }
        
        _tokenTransfer(from,to,amount,takeFee);
    }



    /*

    PROCESSING FEES

    Fees are added to the contract as tokens, these functions exchange the tokens for BNB

    */


    // Send BNB to external wallet
    function sendToWallet(address payable wallet, uint256 amount) private {
            wallet.transfer(amount);
        }

    // Custom function for calculating fee split percentages
    function precDiv(uint a, uint b, uint precision) internal pure returns (uint) {
     return a*(10**precision)/b;    
    }

    // Processing tokens from contract
    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {

        uint256 split_Promo;
        uint256 tokens_Promo;

        uint256 split_AUTHOR;
        uint256 split_REWARDPOOL;

        uint256 BNB_TOTAL;
        uint256 BNB_AUTHOR;
        uint256 BNB_REWARDPOOL;

        if(_fee_Liquidity != 0){

            split_Promo = precDiv((_fee_Marketing+_fee_Reward_Pool+_fee_Author_Wallet),(_fee_Total),2);
            tokens_Promo = contractTokenBalance*split_Promo/100;

        uint256 firstHalf = (contractTokenBalance-tokens_Promo)/2;
        uint256 secondHalf = contractTokenBalance-(tokens_Promo+firstHalf);
        uint256 balanceBeforeSwap = address(this).balance;
        swapTokensForBNB(firstHalf+tokens_Promo);
        BNB_TOTAL = address(this).balance - balanceBeforeSwap;
        uint256 BNB_PROMO = BNB_TOTAL*split_Promo/100;
        addLiquidity(secondHalf, (BNB_TOTAL-BNB_PROMO));
        emit SwapAndLiquify(firstHalf, (BNB_TOTAL-BNB_PROMO), secondHalf);

        uint256 promoBNB_TOTAL = address(this).balance;
        split_AUTHOR = precDiv(_fee_Author_Wallet,(_fee_Marketing+_fee_Reward_Pool+_fee_Author_Wallet),2);
        BNB_AUTHOR = promoBNB_TOTAL*split_AUTHOR/100;

        split_REWARDPOOL = precDiv(_fee_Reward_Pool,(_fee_Marketing+_fee_Reward_Pool+_fee_Author_Wallet),2);
        BNB_REWARDPOOL = promoBNB_TOTAL*split_REWARDPOOL/100;

        sendToWallet(Wallet_AUTHOR, BNB_AUTHOR);
        sendToWallet(Wallet_REWARD_POOL, BNB_REWARDPOOL);
        sendToWallet(Wallet_MARKETING, (promoBNB_TOTAL-BNB_AUTHOR-BNB_REWARDPOOL));

        } else {

           // The liquidity is set to zero, so only process the wallets 

        swapTokensForBNB(contractTokenBalance);
        BNB_TOTAL = address(this).balance;

        split_AUTHOR = precDiv(_fee_Author_Wallet,(_fee_Marketing+_fee_Reward_Pool+_fee_Author_Wallet),2);
        BNB_AUTHOR = BNB_TOTAL*split_AUTHOR/100;

        split_REWARDPOOL = precDiv(_fee_Reward_Pool,(_fee_Marketing+_fee_Reward_Pool+_fee_Author_Wallet),2);
        BNB_REWARDPOOL = BNB_TOTAL*split_REWARDPOOL/100;

        sendToWallet(Wallet_AUTHOR, BNB_AUTHOR);
        sendToWallet(Wallet_REWARD_POOL, BNB_REWARDPOOL);
        sendToWallet(Wallet_MARKETING, (BNB_TOTAL-BNB_AUTHOR-BNB_REWARDPOOL));

        }

    }

    /*

    Creating Auto Liquidity

    */

    function addLiquidity(uint256 tokenAmount, uint256 BNBAmount) private {

        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: BNBAmount}(
            address(this),
            tokenAmount,
            0, 
            0, 
            owner(), 
            block.timestamp
        );
    }    


    // Manual Token Process Trigger - Enter the percent of the tokens that you'd like to send to process
    function process_Tokens_Now (uint256 percent_Of_Tokens_To_Process) public onlyOwner {
        // Do not trigger if already in swap
        require(!inSwapAndLiquify, "Currently processing, try later."); 
        if (percent_Of_Tokens_To_Process > 100){percent_Of_Tokens_To_Process == 100;}
        uint256 tokensOnContract = balanceOf(address(this));
        uint256 sendTokens = tokensOnContract*percent_Of_Tokens_To_Process/100;
        swapAndLiquify(sendTokens);
    }


    // Swapping tokens for BNB using PancakeSwap 
    function swapTokensForBNB(uint256 tokenAmount) private {

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
    
    UPDATE PANCAKESWAP ROUTER AND LIQUIDITY PAIRING

    */


    // Set new router and make the new pair address
    function set_New_Router_and_Make_Pair(address newRouter) public onlyOwner() {
        IUniswapV2Router02 _newPCSRouter = IUniswapV2Router02(newRouter);
        uniswapV2Pair = IUniswapV2Factory(_newPCSRouter.factory()).createPair(address(this), _newPCSRouter.WETH());
        uniswapV2Router = _newPCSRouter;
        _isPair[uniswapV2Pair] = true;
    }
   
    // Set new router
    function set_New_Router_Address(address newRouter) public onlyOwner() {
        IUniswapV2Router02 _newPCSRouter = IUniswapV2Router02(newRouter);
        uniswapV2Router = _newPCSRouter;
    }
    
    // Set new address - This will be the 'Cake LP' address for the token pairing
    function set_New_Pair_Address(address newPair) public onlyOwner() {
        uniswapV2Pair = newPair;
        _isPair[uniswapV2Pair] = true;

    }

    /*

    PURGE RANDOM TOKENS - Add the random token address and a wallet to send them to

    */

    // Remove random tokens from the contract and send to a wallet
    function remove_Random_Tokens(address random_Token_Address, address send_to_wallet, uint256 number_of_tokens) public onlyOwner returns(bool _sent){
        require(random_Token_Address != address(this), "Can not remove native token");
        uint256 randomBalance = IERC20(random_Token_Address).balanceOf(address(this));
        if (number_of_tokens > randomBalance){number_of_tokens = randomBalance;}
        _sent = IERC20(random_Token_Address).transfer(send_to_wallet, number_of_tokens);
    }

    /*

    TOKEN TRANSFERS

    */

    // Check if token transfer needs to process fees
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
 
        if(!takeFee){
            removeAllFee();
            } else {
                txCount++;
            }
            _transferTokens(sender, recipient, amount);
        
        if(!takeFee)
            restoreAllFee();
    }

    // Redistributing tokens and adding the fee to the contract address
    function _transferTokens(address sender, address recipient, uint256 tAmount) private {
        (uint256 tTransferAmount, uint256 tFeeTotal) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _tOwned[address(this)] = _tOwned[address(this)].add(tFeeTotal); 
        emit Transfer(sender, recipient, tTransferAmount);
    }


    // Calculating the fee in tokens
    function _getValues(uint256 tAmount) private view returns (uint256, uint256) {
        uint256 tFeeTotal = tAmount*_fee_Total/100;
        uint256 tTransferAmount = tAmount-tFeeTotal;
        return (tTransferAmount, tFeeTotal);
    }



    


}