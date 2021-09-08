// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


import "./Address.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./SwapInterfaces.sol";
import "./RoninShared.sol";

contract Ronin is ERC20, Ownable, RoninShared {
    using Address for address;
    using Address for address payable;

    ISwapRouter02 public uniswapV2Router;
    address public  uniswapV2Pair;

    bool private swapping;

    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    
    uint256 public swapTokensAtAmount = 100_000 * (10**18);
    uint256 public blacklistTimeout = 30 minutes;
    
    mapping(address => uint256) public isBlacklistedUntil;
    mapping(address => uint256) public lastSellTime;
    mapping(address => uint256) public lastBuyTime;
    mapping(address => uint256) public lastSellTimeBalance;
    
    uint8 public maxSellPercentage = 20;
    uint256 public sellDelay = 2 hours;
    uint256 public buyDelay = 10 minutes;
    uint256 public totalHoldingsToExempt = 5 * 10**17; // 0.5BNB

    uint256 public liquidityFee = 2;
    uint256 public marketingFee = 4;
    uint256 public feeDenominator = 100;

    uint256 public maxTxAmount;
    uint256 private launchedAt;
    bool public tradingOpened;
    
    address public marketingWalletAddress = 0x98D440bd56431Ea662f2017be32D6a86D4782A30;

     // exlcude from fees and max transaction amount
    mapping (address => bool) private isExcludedFromFees;


    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    constructor() ERC20("RNTest3", "RNT3") {
        ISwapRouter02 _uniswapV2Router = ISwapRouter02(ROUTER);
         // Create a uniswap pair for this new token
        address _uniswapV2Pair = ISwapFactory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(marketingWalletAddress, true);
        excludeFromFees(BURN_ADDRESS, true);
        excludeFromFees(address(this), true);

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), 10_000_000_000 * 10**18);
         maxTxAmount = totalSupply() / 500; // 0.2%
    }

    receive() external payable {}
    
    function airdrop (address airdropWallet, address[] calldata airdropRecipients, uint256[] calldata airdropAmounts) external onlyOwner {
        excludeFromFees(airdropWallet, true);
        require (airdropRecipients.length == airdropAmounts.length, "Length of recipient and amount arrays must be the same");
        
        // airdropWallet needs to have approved the contract address to spend at least the sum of airdropAmounts
        for (uint256 i = 0; i < airdropRecipients.length; i++)
            _transfer (airdropWallet, airdropRecipients[i], airdropAmounts[i]);
    }
    
    function airdrop (address airdropWallet, address[] calldata airdropRecipients, uint256 airdropAmount) external onlyOwner {
        excludeFromFees(airdropWallet, true);
        // airdropWallet needs to have approved the contract address to spend at least airdropAmount * number of recipients
        for (uint256 i = 0; i < airdropRecipients.length; i++)
            _transfer (airdropWallet, airdropRecipients[i], airdropAmount);
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "Ronin: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = ISwapRouter02(newAddress);
        address _uniswapV2Pair = ISwapFactory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Pair = _uniswapV2Pair;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(isExcludedFromFees[account] != excluded, "Ronin: Account is already the value of 'excluded'");
        isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function setMarketingWallet(address payable wallet) external onlyOwner{
        require(marketingWalletAddress != address(0), "Ronin: Can't set marketing wallet to the zero address");
        marketingWalletAddress = wallet;
    }
    
    function setMaxSellPercentage (uint8 value) external onlyOwner {
        require (value >= 10, "Ronin: Can't set sell percentage < 10%");
        maxSellPercentage = value;
    }

    function setSellDelay (uint256 valueInSeconds) external onlyOwner {
        require (valueInSeconds <= 8 hours, "Ronin: Can't set sell delay > 8 hours");
        sellDelay = valueInSeconds;
    }

    function setBuyDelay (uint256 valueInSeconds) external onlyOwner {
        require (valueInSeconds <= 8 hours, "Ronin: Can't set buy delay > 8 hours");
        buyDelay = valueInSeconds;
    }

    function setTotalHoldingsToExempt (uint256 valueInWei) external onlyOwner {
        totalHoldingsToExempt = valueInWei;
    }

    function setLiquidityFee(uint256 value) external onlyOwner {
        liquidityFee = value;
    }

    function setMarketingFee(uint256 value) external onlyOwner {
        marketingFee = value;
    }
    
    function setBlacklistTimeout(uint256 value) external onlyOwner{
        blacklistTimeout = value;
    }
    
    function setMaxTxPermille(uint256 maxTxPermille) external onlyOwner {
        require (maxTxPermille > 0, "Ronin: Can't set max Tx to 0");
        maxTxAmount = totalSupply() * maxTxPermille / 1000;
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "Ronin: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }
    
    function blacklistAddress(address account, bool value) external onlyOwner {
        require (block.timestamp < launchedAt + 30 minutes, "Ronin: Can't blacklist, out of time");
        isBlacklistedUntil[account] = block.timestamp + (value ? blacklistTimeout : 0);
    }
    
    function launch() external onlyOwner {
        launchedAt = block.timestamp;
        tradingOpened = true;
    }
    
    function toggleTrading (bool _tradingOpened) external onlyOwner {
        require (launchedAt + 1 days < block.timestamp && !_tradingOpened, "Ronin: Cannot pause trading"); //CHANGEME Comment this line out to be able to pause forever, else the ability to pause is limited to first 24 hours only
        tradingOpened = _tradingOpened;
    }


    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "Ronin: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function excludedFromFees (address account) public view onlyOwner returns (bool) {
        return isExcludedFromFees[account];
    }
    
    function isExemptFromSellPercentage (address account) private view returns (bool) {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        uint256[] memory valueOfHoldingsInBnb = uniswapV2Router.getAmountsOut (balanceOf (account), path);
        return valueOfHoldingsInBnb[1] >= totalHoldingsToExempt ? false : true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require (tradingOpened || isExcludedFromFees[from], "Ronin: Trading paused");
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(isBlacklistedUntil[from] < block.timestamp && isBlacklistedUntil[to] < block.timestamp, "Ronin: Blacklisted address");

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
        
        if (automatedMarketMakerPairs[to]) { //Selling
            if (!isExcludedFromFees[from] && (!isExemptFromSellPercentage (from) || block.timestamp - lastSellTime[from] <= sellDelay)) {
                uint256 maxAllowedToSell = balanceOf(from) * maxSellPercentage / 100;
                require (amount <= maxAllowedToSell, "Ronin: Sell amount too high"); // Catches sells > maxSellPercentage
                
                if (block.timestamp - lastSellTime[from] <= sellDelay) {
                    maxAllowedToSell = lastSellTimeBalance[from] * maxSellPercentage / 100;
                    require (balanceOf(from) - amount >= lastSellTimeBalance[from] - maxAllowedToSell, "Ronin: Wait until sell delay is up to sell again"); // Catches multiple sells > maxSellPercentage within sellDelay
                } else {
                    lastSellTime[from] = block.timestamp;
                    lastSellTimeBalance[from] = balanceOf(from);
                }
            }
        } else if (automatedMarketMakerPairs[from]) {
            if (!isExcludedFromFees[to]) {
                require (block.timestamp - lastBuyTime[to] >= buyDelay, "Ronin: Wait until buy delay is up to buy again");
                lastBuyTime[to] = block.timestamp;
            }
        }

		uint256 contractTokenBalance = balanceOf(address(this));
		uint256 totalFees = liquidityFee + marketingFee;

        bool canSwap = contractTokenBalance >= swapTokensAtAmount && launchedAt + 10 < block.timestamp && !!tradingOpened;

        if( canSwap &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            from != owner() &&
            to != owner()
        ) {
            swapping = true;

            uint256 swapTokens = contractTokenBalance * liquidityFee / totalFees;
            swapAndLiquify(swapTokens);

            uint256 marketingTokens = balanceOf(address(this));
            swapAndSendToFee(marketingTokens, marketingWalletAddress);

            swapping = false;
        }


        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (isExcludedFromFees[from] || isExcludedFromFees[to])
            takeFee = false;

        if (takeFee) {
        	uint256 fees = amount * (launchedAt + 10 < block.timestamp ? totalFees : feeDenominator - 1) / feeDenominator;
        	
        	if (automatedMarketMakerPairs[to])
        	    fees += amount / 100;
        	
        	amount = amount - fees;
            super._transfer (from, address(this), fees);
        }

        super._transfer (from, to, amount);
    }

    function swapAndSendToFee(uint256 tokens, address feeAddress) private  {
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(tokens);
        uint256 newBalance = address(this).balance - initialBalance;
        (bool success, ) = feeAddress.call{ value: newBalance }("");
        require (success, "Ronin: Payment to marketing wallet failed");
    }

    function swapAndLiquify(uint256 tokens) private {
       // split the contract balance into halves
        uint256 half = tokens / 2;
        uint256 otherHalf = tokens - half;

        // swap tokens for ETH
        uint256 newBalance = swapTokensForEth(half); 

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {

        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        (,uint256 ethFromLiquidity,) = uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0),
            block.timestamp
        );
        if (ethAmount - ethFromLiquidity > 0)
            payable(marketingWalletAddress).sendValue(ethAmount - ethFromLiquidity);
    }

    function swapTokensForEth(uint256 tokenAmount) private returns (uint256) {
        uint256 initialBalance = address(this).balance;
        
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
        
        return (address(this).balance - initialBalance);
    }
}