/**
 *Submitted for verification at BscScan.com on 2021-12-09
*/

//SPDX-License-Identifier: Unlicensed
/*
                                                                             
*/
pragma solidity ^0.8.10;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; 
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

interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
    // Set original owner
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        _owner = _msgSender();
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
    function renounceOwnership() external virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    // Transfer the contract to to a new owner
    function transferOwnership(address newOwner) external virtual onlyOwner {
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

contract PleaseBuy is Context, IERC20, Ownable { 
    using SafeMath for uint256;
    using Address for address;
  
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) public ItsActivedFees ; 
    bool public takeFee = false;
    mapping (address => bool) private _isExcluded;
    mapping (address => bool) public _isBlacklisted;
    bool public noBlackList;
    
    address payable private wallet_Dev = payable(0x97DE9ca9ac792a2446058FEF59cE35AdE180619a);
    address payable private wallet_Burn = payable(0x000000000000000000000000000000000000dEaD); 
    address payable private wallet_team = payable(0x4BbA7EF72bF0196FEF5db0695933e32f61bF98fA);     

    address constant routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    string private _name = "PleaseBuy"; 
    string private _symbol = "PleaseBuy";  
    uint8 private _decimals = 18;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 100 * 10 ** 12 * 1e18;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    address[] private _excluded;
    
    //number of tokens set to issue SwapAndLiquify
    uint256 public swapTokensAtAmount = 1000000000 * 10**18; //1B 
 
    //Tax configuration
    uint256 private maxPossibleFee = 25; 
    uint256 private _TotalFee;
    uint256 public _buyFee = 2;
    uint256 public _sellFee = 2;
    uint256 public _burnFee = 0; 
    uint256 public _devFee = 7;
    uint256 public _teamFee = 1;
    
    //Previous fees' are used to keep track of fee settings when removing and restoring fees
    uint256 private _previousTotalFee = _TotalFee; 
    uint256 private _previousBuyFee = _buyFee; 
    uint256 private _previousSellFee = _sellFee; 
    uint256 private _previousBurnFee = _burnFee;
    uint256 private _previousDevFee = _devFee;
    uint256 private _previousTeamFee = _teamFee;
    
    //WALLET LIMITS 
    uint256 public _maxWalletToken = _tTotal.mul(4).div(100);
    uint256 private _previousMaxWalletToken = _maxWalletToken;
    // Maximum transaction amount (4% at launch)
    uint256 public _maxTxAmount = _tTotal.mul(4).div(100); 
    uint256 private _previousMaxTxAmount = _maxTxAmount;

    //PANCAKESWAP SET UP
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    bool public inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool private swapping;
    bool public enableSwap = false;

    //Events 
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event EnableSwap(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    //Prevent processing while already processing! 
    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }
  
    constructor () {

        _tOwned[owner()] = _tTotal;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(routerAddress); 
        // Create pair address for PancakeSwap
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        //Read  array of Wallets excluded on the fees
        emit Transfer(address(0), owner(), _tTotal);
    }
    //STANDARD ERC20 COMPLIANCE FUNCTIONS
    function name() external view returns (string memory) {
        return _name;
    }
    function symbol() external view returns (string memory) {
        return _symbol;
    }
    function decimals() external view returns (uint8) {
        return _decimals;
    }
    function totalSupply() external view override returns (uint256) {
        return _tTotal;
    }
    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
    }
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
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
    //Add and remove Tax Wallet settings.
    function removeFeeFromAddress(address account) external onlyOwner {
         ItsActivedFees[account] = false;
    }
    function removeFeeFromMultiplesAddress(address[] calldata account) external  onlyOwner {
            for (uint i=0; i<account.length; i++){
                 ItsActivedFees[account[i]] = false;
            }
    }
    function add_addressToFees(address account) external onlyOwner {
         ItsActivedFees[account] = true;
    }
    function add_multiplesFeesToAddress(address[] calldata _address ) external onlyOwner {
        for (uint i=0; i<_address.length; i++) {
               ItsActivedFees[_address[i]] = true;
        }
    }
    //SETTING FEES
    function _set_Fees(uint256 Buy_Fee, uint256 Sell_Fee, uint Dev_Fee, uint256 Burn_Fee, uint256 Team_Fee) external onlyOwner() {
        require((Buy_Fee + Sell_Fee + Dev_Fee + Burn_Fee + Team_Fee ) <= maxPossibleFee, "Fee is too high!");
        _sellFee = Sell_Fee;
        _buyFee = Buy_Fee;
        _devFee = Dev_Fee;
        _burnFee = Burn_Fee;
        _teamFee = Team_Fee;
    }
    //On/Off All Rates | takeFee = true all rates will be active.
    function setTakeFee(bool _true_or_false) external onlyOwner  {
        takeFee = _true_or_false;
    }
    //WALLET UPDATES
    event WalletUpdateDev(address indexed oldWallet, address indexed newWallet); 
    function Wallet_Update_Dev(address payable wallet) public onlyOwner() {
      require(wallet != address(0), "new wallet is the zero address");
      wallet_Dev = wallet; 
     ItsActivedFees[wallet_Dev] = false;
    }
    event WalletUpdateTeam(address indexed oldWallet, address indexed newWallet); 
    function walletUpdateTeam(address payable wallet) public onlyOwner() {
      require(wallet != address(0), "new wallet is the zero address");
      wallet_team = wallet; 
     ItsActivedFees[wallet_team] = false;
    }

   //Sets Processing Tokens - Set up
    
    function set_Swap_And_Liquify_Enabled(bool true_or_false) external onlyOwner {
        swapAndLiquifyEnabled = true_or_false;
        emit SwapAndLiquifyEnabledUpdated(true_or_false);
    }

    function setEnableSwap(bool true_or_false) external onlyOwner {
        if (true_or_false == true){
            ItsActivedFees[uniswapV2Pair] = true;
        }else{
            ItsActivedFees[uniswapV2Pair] = false;
        }
        enableSwap = true_or_false;
        emit EnableSwap(true_or_false);
    }

    function updateSwapTokensAtAmount(uint256 amount) external onlyOwner{
        swapTokensAtAmount = amount * 10**_decimals;
    }
    
    // This function is required so that the contract can receive BNB from pancakeswap
    receive() external payable {}
    /*
    BlackList 
    This feature is used to block a person from buying - known bot users are added to this
    list prior to launch. We also check for people using snipe bots on the contract before we
    add liquidity and block these wallets. We like all of our buys to be natural and fair.
    */
    function blacklist_Add_Wallets(address[] calldata addresses) external onlyOwner {
        uint256 startGas;
        uint256 gasUsed;

    for (uint256 i; i < addresses.length; ++i) {
        if(gasUsed < gasleft()) {
        startGas = gasleft();
        if(!_isBlacklisted[addresses[i]]){
        _isBlacklisted[addresses[i]] = true;}
        gasUsed = startGas - gasleft();
    }
    }
    }
    // Blacklist - block wallets (REMOVE - COMMA SEPARATE MULTIPLE WALLETS)
    function blacklist_Remove_Wallets(address[] calldata addresses) external onlyOwner {
       
        uint256 startGas;
        uint256 gasUsed;

    for (uint256 i; i < addresses.length; ++i) {
        if(gasUsed < gasleft()) {
        startGas = gasleft();
        if(_isBlacklisted[addresses[i]]){
        _isBlacklisted[addresses[i]] = false;}
        gasUsed = startGas - gasleft();
    }
    }
    }
    /*
    You can turn the blacklist restrictions on and off.
    During launch, it's a good idea to block known bot users from buying. But these are real people, so 
    when the contract is safe (and the price has increased) you can allow these wallets to buy/sell by setting
    noBlackList to false
    */
    function blacklist_Switch(bool true_or_false) public onlyOwner {
        noBlackList = true_or_false;
    }
    // Max Transaction per Wallet
    function set_Max_Transaction_Percent(uint256 maxTxPercent_x100) external onlyOwner() {
        _maxTxAmount = _tTotal*maxTxPercent_x100/10000;
    }    

    function set_Max_Wallet_Percent(uint256 maxWallPercent_x100) external onlyOwner() {
        _maxWalletToken = _tTotal*maxWallPercent_x100/10000;
    }

    // Remove all fees
    function removeAllFee() private {
        if(_TotalFee == 0 && _buyFee == 0 && _sellFee == 0 && _devFee == 0 && _teamFee == 0 && _burnFee == 0 ) return;
        _previousBuyFee = _buyFee; 
        _previousSellFee = _sellFee; 
        _previousTotalFee = _TotalFee;
        _previousBurnFee = _burnFee;
        _previousDevFee = _devFee;
        _previousTeamFee = _teamFee;
        _buyFee = 0;
        _sellFee = 0;
        _TotalFee = 0;
        _devFee = 0;
        _burnFee = 0;
        _teamFee = 0; 
    }
    // Restore all fees
    function restoreAllFee() private {
        _TotalFee = _previousTotalFee;
        _buyFee = _previousBuyFee; 
        _sellFee = _previousSellFee; 
        _burnFee = _previousBurnFee;
        _devFee  = _previousDevFee;
        _teamFee = _previousTeamFee;

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
    
        // Limit wallet total
        if (to != owner() &&
            to != wallet_Dev &&
            to != address(this) &&
            to != uniswapV2Pair &&
            to != wallet_Burn &&
            from != owner()){
            uint256 heldTokens = balanceOf(to);
            require((heldTokens + amount) <= _maxWalletToken,"You are trying to buy too many tokens. You have reached the limit for one wallet.");}


        // Limit the maximum number of tokens that can be bought or sold in one transaction
        if (from != owner() && to != owner())
            require(amount <= _maxTxAmount, "You are trying to buy more than the max transaction limit.");
        /*
        BLACKLIST RESTRICTIONS
        */
        if (noBlackList){
        require(!_isBlacklisted[from] && !_isBlacklisted[to], "This address is blacklisted. Transaction reverted.");
        }
        require(from != address(0) && to != address(0), "ERR: Using 0 address!");
        require(amount > 0, "Token value must be higher than zero.");
        /*
        PROCESSING
        */
        // SwapAndLiquify is triggered after every X transactions - this number can be adjusted using swapTrigger

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;
        if(
           //autoSwap and liquefy only if transferring from wallet to wallet
           !swapping  
           && canSwap &&  
           ItsActivedFees[msg.sender] == false)
        {
            swapAndLiquify(contractTokenBalance);
        }
        /*
        REMOVE FEES IF REQUIRED
        Fee removed if the to or from address is excluded from fee.
        Fee removed if the transfer is NOT a buy or sell.
        Change fee amount for buy or sell.
        */
        
        takeFee = false;
         _TotalFee = _sellFee+_devFee+_burnFee+_teamFee+_buyFee;   
         
        if (
            ItsActivedFees[msg.sender] == true || 
            from == uniswapV2Pair || 
            to == uniswapV2Pair && 
            ItsActivedFees[uniswapV2Pair] == true)
            {

            takeFee = true;
         }
        else if (from == uniswapV2Pair){
        _TotalFee = _buyFee+_devFee+_burnFee;
        
        } else if (to == uniswapV2Pair){
        _TotalFee = _sellFee+_devFee+_burnFee;     
        }
        _tokenTransfer(from,to,amount,takeFee);
    }
    // Processing tokens from contract
    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 liquidtyFees = _buyFee + _sellFee;
        uint256 amountTokensliquidity = contractTokenBalance.div(100).mul(liquidtyFees); // % liquiditys Fees 
        uint256 amountTokensDev = contractTokenBalance.div(100).mul(_devFee); // % devFee 
        uint256 amountswapToBNB = contractTokenBalance.sub(amountTokensliquidity).sub(amountTokensDev); 
        uint256 initialBalance = address(this).balance;
        // swap tokens for ETH
        swapTokensForBNB(amountswapToBNB); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(amountTokensliquidity, newBalance);
        sendToWallet(amountTokensDev);
        
        emit SwapAndLiquify(amountTokensliquidity, newBalance, amountTokensDev);
    }
    // Manual Swap
    function processTokensForSwap (uint256 percentualToProcess) external onlyOwner {
        require(!inSwapAndLiquify, "Currently processing, try later."); 
        if (percentualToProcess > 100){percentualToProcess == 100;}
        uint256 tokensOnContract = balanceOf(address(this));
        uint256 sendTokens = tokensOnContract*percentualToProcess/100;
        swapAndLiquify(sendTokens);
    }
    function sendToWallet(uint256 amount) private { 
       require(balanceOf(address(this))>0, "You need to have more than 1000 tokens for this operation."); 
        swapTokensForBNB(amount); 
        wallet_Dev.transfer(address(this).balance);
    }
    function burn(address sender, uint256 amount) private  {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = amount.mul(currentRate);
        _rOwned[address(0)] = _rOwned[address(0)].add(rLiquidity);
        if(_isExcluded[address(0)])
            _tOwned[address(0)] = _tOwned[address(0)].add(amount);

        if(_burnFee > 0){
          emit Transfer(sender, wallet_Burn, amount);
        }

    }
    function teamTX(address sender, uint256 amount) private  {
        if(_teamFee > 0){
          emit Transfer(sender, wallet_team, amount);
        }
        
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
    // Add liquidity 
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
    // Remove random tokens from the contract and send to a wallet
    function remove_Random_Tokens(address random_Token_Address, address send_to_wallet, uint256 number_of_tokens) public onlyOwner returns(bool _sent){
        require(random_Token_Address != address(this), "Can not remove native token");
        uint256 randomBalance = IERC20(random_Token_Address).balanceOf(address(this));
        if (number_of_tokens > randomBalance){number_of_tokens = randomBalance;}
        _sent = IERC20(random_Token_Address).transfer(send_to_wallet, number_of_tokens);
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

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }
    // Remove BNB from the contract
    function withdrawBNB(address payable to) external onlyOwner {
         require(address(this).balance > 0,"Balance > 0 ! ");
         to.transfer(address(this).balance);
    }
    // Set new router and make the new pair address
    function set_New_Router_and_Make_Pair(address newRouter) external onlyOwner() {
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
    // Check if token transfer needs to process fees
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool _takeFee) private {
        if(!_takeFee){
            removeAllFee();
            } 
            _transferTokens(sender, recipient, amount);
        
        if(!takeFee)
            restoreAllFee();
    }
    // Redistributing tokens and adding the fee to the contract address
    function _transferTokens(address sender, address recipient, uint256 tAmount) 
    private {(uint256 tTransferAmount, uint256 tDev, uint256 tBurn, uint256 tTeam ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        if(_buyFee >0) {burn(sender, tBurn);}
        if(_teamFee>0){teamTX(sender,tTeam);}
        _tOwned[address(this)] = _tOwned[address(this)].add(tDev);   
        emit Transfer(sender, recipient, tTransferAmount);
    }
    // Calculating the fee in tokens
    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
        uint256 tDev = tAmount*_TotalFee/100;
        uint256 tBurn = tAmount*_burnFee/100;
        uint256 tTeam = tAmount*_teamFee/100;
        uint256 tTransferAmount = tAmount.sub(tDev).sub(tBurn).sub(tTeam);
        return (tTransferAmount, tDev, tBurn, tTeam);
    }
    // AirDrop Function
    function airdropsSenders(address payable[] memory addrs, uint[] memory amount)  payable public onlyOwner(){
        for (uint i=0; i < addrs.length; i++) {
            transfer(addrs[i], amount[i]*10**18);
        }
    }
}