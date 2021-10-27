/**
 *Submitted for verification at BscScan.com on 2021-10-26
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IBEP20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}

contract Context {
    constructor () { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}



contract BEP20Detailed {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory tname, string memory tsymbol, uint8 tdecimals) {
        _name = tname;
        _symbol = tsymbol;
        _decimals = tdecimals;
        
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
}



library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
}

library SafeBEP20 {
    using SafeMath for uint;
    using Address for address;

    function safeTransfer(IBEP20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IBEP20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IBEP20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function callOptionalReturn(IBEP20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeBEP20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeBEP20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
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


contract TEST is BEP20Detailed, Context, Ownable, IBEP20{
  using SafeBEP20 for IBEP20;
  using Address for address;
  using SafeMath for uint256;
  uint256 public _maxTxAmount;
  
  
  address public _owner;
  



    mapping (address => uint) internal _balances;

    mapping (address => mapping (address => uint)) internal _allowances;
    mapping (address => bool) public _isBlacklisted; 

    uint internal _totalSupply;
    
    mapping (address => bool) private _isExcludedFromFee;

    mapping (address => uint256) private purchaseTime;
    
    
    uint256 public _taxFee = 12;
    uint256 private _previousTaxFee = _taxFee;
    
    uint256 public _marketingFee = 7;
    uint256 private _previousMarketingFee = _marketingFee;
    
    uint256 public _liquidityFee = 1;
    uint256 private _previousLiquidityFee = _liquidityFee;
    
    uint256 public _devFee = 18;
    uint256 private _previousDevFee = _devFee;
    
    uint256 public _privateInvestorsFee = 12;
    uint256 private _previousPrivateInvestorsFee = _privateInvestorsFee;
    
    uint256 public _lotteryFee = 1;
    uint256 private _previousLotteryFee = _lotteryFee;
    
    uint256 public _NFTTaxFee = 0;
    uint256 private _previousNFTTaxFee = _NFTTaxFee;
    
    uint256 private liquidityFee;
    uint256 private devFee;
    uint256 private privateInvastorsFee;
    uint256 private lotteryFee;
    uint256 private NFTFee;
    
    uint256 private marketingAmount;
    uint256 private liquidityAmount;
    uint256 private devAmount;
    uint256 private privateInvestorsAmount;
    uint256 private lotteryAmount;
    uint256 private NFTAmount;
    
    address public marketingWallet = 0x8948473B44D02b7Db7BeD73547a6Fc22Df572753;
    address public devWallet = 0x0077E0dd51642315e6B48FCEffC4C353F01413Cc;
    address public PrivateInvestorsWallet = 0xAD017dAefDb8477B407d5819e5a7c36a68971BBD;
    address public lotteryWallet = 0x8715266aEd32127Bf9C16E2a02B3cD3FEB6e4a42;
    address public NFTWallet = 0x31fD21d8C28c9595DE0683e5b678dfA1203aF7D1;
    
    uint256 public _minimumTokensToQualify;
    uint256 public _rolledNumber;
    uint256 private _nonce;
    
    
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    
    uint256 public blockNumberAtLaunchTime;
     // use by default 300,000 gas to process auto-claiming dividends
    uint256 public gasForProcessing = 300000;
   
    uint256 private numTokensSellToAddToLiquidity = 5000000  * 10**9;
    uint256 public maxWalletAmount;
    
    uint256 public TokenDefinedAmount;
    uint256 public variableTaxAmount;
    address public winner;
    address public _previousWinner;
    uint256 public _previousWonAmount;
    uint256 public _previousWinTime;
    uint256 public _lastRoll;
    uint256 public lotteryThresholdAmount;
    
    event LotteryAward(
        address winner,
        uint256 amount,
        uint time
    );
    
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
     constructor () BEP20Detailed("iWin", "iWin", 9) {
      _owner = msg.sender;
    _totalSupply = 1000000000 * (10**9);
    
     
    _maxTxAmount = (_totalSupply .mul(5)).div(1000);
    maxWalletAmount = (_totalSupply.mul(2)).div(100);
    
	_balances[_owner] = _totalSupply;
	emit Transfer(address(0), _msgSender(), _totalSupply);
	
	 
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
         // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;
        
        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        
        blockNumberAtLaunchTime = block.number;
  }
	
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    
  
    function totalSupply() public view override returns (uint) {
        return _totalSupply;
    }
    function balanceOf(address account) public view override returns (uint) {
        return _balances[account];
    }
    function transfer(address recipient, uint amount) public override  returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address towner, address spender) public view override returns (uint) {
        return _allowances[towner][spender];
    }
    function approve(address spender, uint amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender, uint addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }
    function _transfer(address sender, address recipient, uint amount) internal
    {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(gasForProcessing <= 300000, "Not Allowed");
      
        require(!_isBlacklisted[sender] && !_isBlacklisted[recipient], "This address is blacklisted");
        
         //indicates if fee should be deducted from transfer
        bool takeFee = true;
        if(sender != owner() && recipient != owner())
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            
        if(sender != owner() && block.number - blockNumberAtLaunchTime <= 2){
            _taxFee = 29;}
        
        if(recipient == uniswapV2Pair){
            if(block.timestamp <= purchaseTime[sender] + 1 days)
            {
                _taxFee = variableTaxAmount;
                amount = TokenDefinedAmount;
            }
        }
        
        if(recipient != address(this) || recipient != uniswapV2Pair )
        {
              require(_balances[recipient] <= maxWalletAmount, "Recipient is already holding enough tokens");
        }
        
        if(sender == owner() || recipient == owner())
        {
            _taxFee = 0;
            takeFee = false;
        }
        else
        {
            _taxFee = _previousTaxFee;
        }
        uint256 taxTotal = amount.mul(_taxFee).div(100);
        uint256 netAmountToBeTransferred = amount - taxTotal;
        if(takeFee == true)
        {
        marketingAmount = calculateMarketingAmount(taxTotal);
        liquidityAmount = calculateLiquidityAmount(taxTotal);
        devAmount = calculateDevAmount(taxTotal);
        privateInvestorsAmount = calculatePrivateInvestorsAmount(taxTotal);
        lotteryAmount = calculateLotteryAmount(taxTotal);
        NFTAmount = calculateNFTAmount(taxTotal);
        
        sendToMarketingWallet(marketingAmount);
        sendToLiquidity(liquidityAmount);
        sendToDevWallet(devAmount);
        sendToPriavteInvestorsWallet(privateInvestorsAmount);    
        sendToLotteryWallet(lotteryAmount);
        sendToNFTWallet(NFTAmount);
        
        }
       // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniswap pair.
        uint256 contractTokenBalance = balanceOf(address(this));
        
        if(contractTokenBalance >= _maxTxAmount)
        {
            contractTokenBalance = _maxTxAmount;
        }
        
        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            sender != uniswapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity;
            //add liquidity
            swapAndLiquify(contractTokenBalance);
        }
        
       
        
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]){
            takeFee = false;
        }
        
        _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(netAmountToBeTransferred);
        emit Transfer(sender, recipient, netAmountToBeTransferred);
        
        if(sender == uniswapV2Pair){
        purchaseTime[recipient] = block.timestamp;}
       
    }
 
    function _approve(address towner, address spender, uint amount) internal {
        require(towner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[towner][spender] = amount;
        emit Approval(towner, spender, amount);
    }
    
     function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        _maxTxAmount = totalSupply().mul(maxTxPercent).div(
            10**2
        );
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
     //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}
    
    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
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
    
    function sendToLiquidity(uint256 tLiquidity) private {
       
        _balances[address(this)] = _balances[address(this)].add(tLiquidity);
    }
    
    function sendToMarketingWallet(uint256 tMarketing) private {
       
        _balances[marketingWallet] = _balances[marketingWallet].add(tMarketing);
    }
     
    function sendToDevWallet(uint256 tDev) private {
       
        _balances[devWallet] = _balances[devWallet].add(tDev);
    }
    
    function sendToPriavteInvestorsWallet(uint256 tPriavteInvestors) private {
       
        _balances[PrivateInvestorsWallet] = _balances[PrivateInvestorsWallet].add(tPriavteInvestors);
    }
    
    function sendToLotteryWallet(uint256 tLottery) private {
       
        _balances[lotteryWallet] = _balances[lotteryWallet].add(tLottery);
    }
    
    function sendToNFTWallet(uint256 tNFT) private {
       
        _balances[NFTWallet] = _balances[NFTWallet].add(tNFT);
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
    
      
    function removeAllFee() private {
        if(_taxFee == 0 && _liquidityFee == 0) return;
        
        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;
        
        _taxFee = 0;
        _liquidityFee = 0;
    }
    
    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
    }
    
       function manageBlackList(address[] calldata addresses, bool status) external onlyOwner {
        for (uint256 i; i < addresses.length; ++i) {
            _isBlacklisted[addresses[i]] = status;
        }
    }
    
    function addSingleBlackList(address wallet) public onlyOwner
    {
        _isBlacklisted[wallet] = true;
    }
    
    function removeSingleFromBlackList(address wallet) public onlyOwner
    {
        _isBlacklisted[wallet] = false;
    }
    
      
    function setTaxFeePercent(uint256 taxFee) external onlyOwner() {
        _taxFee = taxFee;
    }
    
    function setLiquidityFeePercent(uint256 LiquidityFee) external onlyOwner() {
        _liquidityFee = LiquidityFee;
    }
    
     
    function setMarketingFeePercent(uint256 MarketingFee) external onlyOwner() {
        _marketingFee = MarketingFee;
    }
    
     
    function setDevFeePercent(uint256 DevFee) external onlyOwner() {
        _devFee = DevFee;
    }
    
     
    function setPrivateInvestorsFeePercent(uint256 PrivateInvestorsFee) external onlyOwner() {
        _privateInvestorsFee = PrivateInvestorsFee;
    }
    
     
    function setLotteryFeePercent(uint256 LotteryFee) external onlyOwner() {
        _lotteryFee = LotteryFee;
    }
    
     
    function setNFTFeePercent(uint256 NFT_Fee) external onlyOwner() {
        _NFTTaxFee = NFT_Fee;
    }
    
    function calculateMarketingAmount(uint256 amount) internal view returns(uint256)
    {
        uint256 marketingPercentageInTotalTax = (_marketingFee.mul(100)).div(_taxFee);
        uint256 marketing_Amount = amount.mul(marketingPercentageInTotalTax).div(100);
        return marketing_Amount;
        
    }
    
    function calculateLiquidityAmount(uint256 amount) internal view returns(uint256)
    {
        uint256 liquidityPercentageInTotalTax = (_liquidityFee.mul(100)).div(_taxFee);
        uint256 liquidity_Amount = amount.mul(liquidityPercentageInTotalTax).div(100);
        return liquidity_Amount;
        
    }
    
    function calculateDevAmount(uint256 amount) internal view returns(uint256)
    {
        uint256 devPercentageInTotalTax = (_devFee.mul(100).div(_taxFee)).div(10);
        uint256 dev_Amount = amount.mul(devPercentageInTotalTax).div(100);
        return dev_Amount;
        
    }
    
    function calculatePrivateInvestorsAmount(uint256 amount) internal view returns(uint256)
    {
        uint256 PrivateInvestorsPercentageInTotalTax = (_privateInvestorsFee.mul(100).div(_taxFee)).div(10);
        uint256 privateInvestors_Amount = amount.mul(PrivateInvestorsPercentageInTotalTax).div(100);
        return privateInvestors_Amount;
        
    }
    
    function calculateLotteryAmount(uint256 amount) internal view returns(uint256)
    {
        uint256 lotteryPercentageInTotalTax = (_lotteryFee.mul(100)).div(_taxFee);
        uint256 lottery_Amount = amount.mul(lotteryPercentageInTotalTax).div(100);
        return lottery_Amount;
        
    }
    
    function calculateNFTAmount(uint256 amount) internal view returns(uint256)
    {
        uint256 NFTPercentageInTotalTax = (_NFTTaxFee.mul(100).div(_taxFee));
        uint256 NFT_Amount = amount.mul(NFTPercentageInTotalTax).div(100);
        return NFT_Amount;
        
    }
    
    function VariableTaxTokenAmount(uint256 amount) public onlyOwner
    {
        TokenDefinedAmount = amount;
    }
    
    function variableTax(uint256 taxAmount) public onlyOwner
    {
        variableTaxAmount = taxAmount;
    }
    
    function minimumTokensToQualify(uint256 amount) external onlyOwner
    {
        _minimumTokensToQualify = amount;
    }
    
    function rolllednumbertoWin(uint256 number) external onlyOwner
    {
        _rolledNumber = number;
    }
    
      /**
     * @notice Generates a random number between 1 and 1000
     */
    function random() private returns (uint) {
        uint r = uint(uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _nonce))) % _rolledNumber);
        r = r.add(1);
        _nonce++;
        return r;
    }
    
    function SetLotteryThreshold(uint256 amount) external onlyOwner
    {
        lotteryThresholdAmount = amount;
    }
    
    function lottery() public 
    {
        require(_balances[msg.sender] >= lotteryThresholdAmount, "STOP!!. You don't have enough tokens");
        require(block.timestamp >= _previousWinTime + 1 days, "NOT ALLOWED: It's less than an hour since last lottery.");
        uint256 _random = random();
        require(_random == _rolledNumber, "You Lost!!");
        
        winner = msg.sender;
            
        uint256 _lotteryAmount = _balances[lotteryWallet].div(2);
        
        _balances[winner] = _balances[winner].add(_lotteryAmount); 
        _balances[lotteryWallet] = _balances[lotteryWallet].sub(_lotteryAmount);
        _previousWinner = winner;
        _previousWonAmount = _lotteryAmount;
        _lotteryAmount = 0;
        _previousWinTime = block.timestamp;
        emit LotteryAward(winner, _lotteryAmount, block.timestamp);
        emit Transfer(lotteryWallet, winner, _lotteryAmount);
    }
  }