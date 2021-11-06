//                                                                                                                                                      
//                                                                                                                                                      
//                                                                                                                                                      
//                                                                       #. .../                                                                        
//                                                                     #...(.....*                                                                      
//                                                              %####%#/*,/./..%,*%%%%%%#%                                                              
//                                                         ###(%%%%%%%%%(/%*/*%#/((%&%%%%%%####.                                                        
//                                             ..%%     ##%%%%%%((//////**#(((((***////(((#%#%%%#%%                                                     
//                                           # ...,,**(%%%%%(//***(*,,,/*,,,,,,,,,,,///****/((#%#%%%%,...,*,                                            
//                                          #.#%#%/,(#*(#///*****..,,,,,,*****,*,*,,,.,(/(*,***(((%  .##/,/*/                                           
//                                          %/*/(*((%((%**,,,,********,***//*******,,,,,,,********,.,(/.%(/*(%                                          
//          %#(((/(%%%%%%%%*                  /(***/((***,,,,*,******////*(////*****///(/////*,,,*%*/#/,,*/((                                           
//             %%&&%%(*,. ,&&&&&&&&&&&&&&%%%%##%%##//******,***////////*//*//(///***/(//((((//*/,,,**%((((%%%                                           
//        #%&&&&&%%%&&%%%%%%%%%%%%%##...,,,,****%&&.*,****,,,/(#%#%&&&&&&&&&&&&&&&&/(((///(((((*******/((%#%%%%%%%(%#%##%%%%#%%%##%%####%%&&&&&&&%%     
//          %%&&.*****,,,....###.,,,,,,,..#%,,,,%%&,***%%%%%%%%%%%%%%%%%%%%%%%%%%%%&&&&&&&&&&&&&&&&&&&&&&&&%%&&%%&........&&%%,,,,%&&.,,....&&%#        
//             %%&****,,,,,...%%,*,*,,,,,*%%,.,,%&%,,,,&%**,,,,,,..(##... ######**,*&&&....,%,,,,,,,,,,.%%,,,.&&%,,,,,,,,,.&&%,,,,,#&(,,..&&%%          
//             %#&****%&&,,,,,%%.,,*%&%%%%%#.,,,%%,,,,%&.,*,#%%.,,,(&(,,..&&##%&,..,%&%,,,..%%%%**,**%%%&&,***#%#,,**%&%**,,&&,,,,,,,%,*,,&%%           
//             #&/****%&&,****&%,,.,%%%%#(((,   %% ...%%....%%#.....%%....%&**(&....#&%(...,###&#....##%&&.....&(..,,%%&****&% ,,,,,,*****&%%           
//            (%&.,*,*%%%....%%   .......%%&    #,   ,%%   .%%&....,%%....&&**/&    (&%#....&&&&%  ..&&%%%.....%%    &&&....,%%   %  .....&&%           
//            %%&    ,%%#....%%    %%%%%%%%%    #    %%%    %#& ...##&    &&**/&    .&%* ...&#&%%    &&%%%/    %%    #%%/ ...%%    &%     .&%%          
//            /&%    ###    .##    %%%%#((((        ,##%    %%&    #%%    &&/*/&     &%*    &#&%%    %&%%%&    #%     ##.    %%    %%%     &%%          
//            %&             %(         %%&&        ###&           %%          &            &(&##    #&&###    %%#           ##    %%%%    %&%          
//           %%&           *%%          %%%%        ###&&.       .%%&.         &%%        #&((&##    ,&&###    %%%&          ##.   ,####(   &%#         
//           (%&%%%%%%%%%%%%%%##%%%%%%%%%###&      %%##&(&&########%&&#########&&(########&(*/&#####%&%&###%%%&###%%%%%%%%#####%%%##(((###%#&%%         
//             %%%%&&&&&&&&&&&&&&&&&&&&&&&&&&&   (%%%%&#,,*#%&&&&%%#/#%%%%%#####(%%#####%#(**/###%%%(/%&&&&&&%&&&&&&&&&&&&&&&&&&&&&&&&&&&&%%%           
//                   %%%%%%%%/              %%& ####&&#**,,////*/////*****//*/*********/***,*,,******(#%#%(#       ##*      /#%   %%%%%                 
//                                           %%%&&#&&&**,,*,(/((((/***///****/**********,,,,,,,,,**/#%(%%%%                                             
//                                               %%&#%%%/***,,,*/////**************,*,,,*((//////(###%#%%                                               
//                                                  %#%%%%%(*****,,,,,/*******,,,.,,,(/(//**//(#%(###%,                                                 
//                                                     %%%#%%%%(//***,**,,,,,/(*,,,,*/////(#%###%##%                                                    
//                                                        *#%%%%%%#%%((/*, .,,,,*%((##%%###%%%%%                                                        
//                                                             %%###%%%%,/,,.,,*(//%%%%%%%%#                                                            
//                                                                     #/*/(*/((///                                                                     
//                                                                      %//////(((                                                                      
//                                                                           ,.                                                                         
//                                                                                                                                                      
//                                                                                                                                                      
//www.devolution-world.com
//
//https://twitter.com/Game_Devolution
//
//https://t.me/DevolutionOfficial
//
//https://www.instagram.com/devolutionofficial/



// SPDX-License-Identifier: MIT                                                                               
pragma solidity 0.8.9;
import "./Libraries.sol";
contract DeVolution is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool private swapping;

    address public marketingWallet;
    address public liquidityWallet;
    address public buybackWallet;
    address public burnWallet;
    address public ingameWallet;
    address public teamWallet;
    
    uint256 public maxTransactionAmount;
    uint256 public swapTokensAtAmount;

    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;

    // sell fees
    uint256 public sellIngameFee;
    uint256 public sellLiquidityFee;
    uint256 public sellOperationsFee;
    uint256 public sellBuybackFee;
    uint256 public sellTeamFee;
    uint256 public sellBurnFee;
    uint256 public sellTotalFees;
    
   // sell fees
    uint256 public buyIngameFee;
    uint256 public buyLiquidityFee;
    uint256 public buyOperationsFee;
    uint256 public buyBuybackFee;
    uint256 public buyTeamFee;
    uint256 public buyBurnFee;
    uint256 public buyTotalFees;
    
    uint256 public feeDivisor;
    
    uint256 private _liquidityTokensToSwap;
    uint256 private _marketingTokensToSwap;
    uint256 private _buyBackTokensToSwap;
    uint256 private _teamTokensToSwap;
    
    /******************/

    // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) public _isExcludedMaxTransactionAmount;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event marketingWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    constructor() ERC20("DeVolution", "DEVO") payable {

        uint256 totalSupply = 1 * 1e9 * 1e18;
        
        maxTransactionAmount = totalSupply * 5 / 1000; // 0.5% maxTransactionAmountTxn
        swapTokensAtAmount = totalSupply * 5 / 10000; // 0.05% swap tokens amount

        // sell fees
        sellTeamFee = 5;
        sellLiquidityFee = 20;
        sellOperationsFee = 60;
        sellBuybackFee = 20;
        sellBurnFee = 10;
        sellIngameFee = 25;
        sellTotalFees = sellTeamFee + sellLiquidityFee + sellOperationsFee + sellBuybackFee + sellBurnFee + sellIngameFee; // 18%
        
        // buy fees
        buyTeamFee = 5;
        buyLiquidityFee = 30;
        buyOperationsFee = 60;
        buyBuybackFee = 0;
        buyBurnFee = 10;
        buyIngameFee = 25;
        buyTotalFees = buyTeamFee + buyLiquidityFee + buyOperationsFee + buyBuybackFee + buyBurnFee + buyIngameFee; // 18%
        
        feeDivisor = 1000;

    	marketingWallet = address(0xb9F23aD895aF02296892723aBf9eE3dBbF4C536c); // set as marketing wallet
    	buybackWallet = address(0xE7d51662039D4e60B87bc8b33845BfD206405E85); // set as buyback wallet
        liquidityWallet = address(owner()); // set as owner to start, can change to whatever later, but keep this as owner so the liquidity tokens go into the owner's wallet.
        ingameWallet = address(0xa9F16136E2faccb4aE4AB82424f5AA1E46E25563);
        teamWallet = address(0x139e08aF313d062869f52e83ec2E5BF21dC098Cb);
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            // ROPSTEN or HARDHAT
            0x10ED43C718714eb63d5aA57B78B54704E256024E
        );

        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
        
        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
        
        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        
        excludeFromMaxTransaction(address(0xdead), true);
        
        /*liquidityWallet
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(address(owner()), totalSupply);
    }

    receive() external payable {

  	}

    // once enabled, can never be turned off (can be called automatically by launching, but use this with a manual Uniswap add if needed)
    function enableTrading() public onlyOwner {
        tradingActive = true;
        swapEnabled = true;
    }
    
    // remove limits after token is stable
    function removeLimits() external onlyOwner returns (bool){
        limitsInEffect = false;
        return true;
    }
    
     // change the minimum amount of tokens to sell from fees
    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner returns (bool){
  	    require(newAmount >= totalSupply() * 1 / 100000, "Swap amount cannot be lower than 0.001% total supply.");
  	    require(newAmount <= totalSupply() * 5 / 1000, "Swap amount cannot be higher than 0.5% total supply.");
  	    swapTokensAtAmount = newAmount;
  	    return true;
  	}
    
    function updateMaxAmount(uint256 newNum) external onlyOwner {
        require(newNum >= (totalSupply() * 5 / 1000)/1e18, "Cannot set maxTransactionAmount lower than 0.5%");
        maxTransactionAmount = newNum * (10**18);
    }
    
    
    function updateBuyFees(uint256 _operationsFee, uint256 _teamFee, uint256 _liquidityFee, uint256 _buybackFee, uint256 _burnFee, uint256 _ingameFee) external onlyOwner {
        buyOperationsFee = _operationsFee;
        buyTeamFee = _teamFee;
        buyLiquidityFee = _liquidityFee;
        buyBuybackFee = _buybackFee;
        buyBurnFee = _burnFee;
        buyIngameFee = _ingameFee;
        buyTotalFees = buyTeamFee + buyLiquidityFee + buyOperationsFee + buyBuybackFee + buyBurnFee + buyIngameFee;
        require(buyTotalFees <= 200, "Must keep fees at 20% or less");
    }
    
    function updateSellFees(uint256 _operationsFee, uint256 _teamFee, uint256 _liquidityFee, uint256 _buybackFee, uint256 _burnFee, uint256 _ingameFee) external onlyOwner {
        sellOperationsFee = _operationsFee;
        sellTeamFee = _teamFee;
        sellLiquidityFee = _liquidityFee;
        sellBuybackFee = _buybackFee;
        sellBurnFee = _burnFee;
        sellIngameFee = _ingameFee;
        sellTotalFees = sellTeamFee + sellLiquidityFee + sellOperationsFee + sellBuybackFee + sellBurnFee + sellIngameFee; 
        require(sellTotalFees <= 200, "Must keep fees at 20% or less");
    }
    
    function excludeFromMaxTransaction(address updAds, bool isEx) public onlyOwner {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }
    
    // only use to disable contract sales if absolutely necessary (emergency use only)
    function updateSwapEnabled(bool enabled) external onlyOwner(){
        swapEnabled = enabled;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "The Uniswap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
        excludeFromMaxTransaction(pair, value);
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateMarketingWallet(address newMarketingWallet) external onlyOwner {
        excludeFromFees(newMarketingWallet, true);
        emit marketingWalletUpdated(newMarketingWallet, marketingWallet);
        marketingWallet = newMarketingWallet;
    }
    
    function updateLiquidityWallet(address newLiquidityWallet) external onlyOwner {
        excludeFromFees(newLiquidityWallet, true);
        liquidityWallet = newLiquidityWallet;
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        
         if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
        
        if(!tradingActive){
            require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is not active.");
        }
        
        if(limitsInEffect){
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !swapping
            ){
                
                //when buy
                if (automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[to]) {
                        require(amount <= maxTransactionAmount, "Buy transfer amount exceeds the maxTransactionAmount.");
                } 
                //when sell
                else if (automatedMarketMakerPairs[to] && !_isExcludedMaxTransactionAmount[from]) {
                        require(amount <= maxTransactionAmount, "Sell transfer amount exceeds the maxTransactionAmount.");
                }
            }
        }
        
		uint256 contractTokenBalance = balanceOf(address(this));
        
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if( 
            canSwap &&
            swapEnabled &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;
            swapBack();
            swapping = false;
        }

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        // only take fees on buys/sells, do not take on wallet transfers
        if(takeFee){
            uint256 fees;
            uint256 burnAmt;
            uint256 ingameAmt;
            uint256 totalFees;
            //buy
        	if(automatedMarketMakerPairs[from]) {
        	    if(buyBurnFee > 0){
            	    burnAmt = amount * buyBurnFee / feeDivisor;
            	    super._transfer(from, address(0xdead), burnAmt);
        	    }
        	    if(buyIngameFee > 0){
            	    ingameAmt = amount * buyIngameFee / feeDivisor;
            	    super._transfer(from, address(ingameWallet), ingameAmt);
        	    }
        	    totalFees = buyTotalFees - buyBurnFee - buyIngameFee;
                fees = amount.mul(totalFees).div(feeDivisor);
                _liquidityTokensToSwap += fees * buyLiquidityFee / totalFees;
                _marketingTokensToSwap += fees * buyOperationsFee / totalFees;
                _buyBackTokensToSwap += fees * buyBuybackFee / totalFees;
                _teamTokensToSwap += fees * buyTeamFee / totalFees;
            }

            //sell
            if(automatedMarketMakerPairs[to]) {
                if(sellBurnFee > 0){
            	    burnAmt = amount * sellBurnFee / feeDivisor;
            	    super._transfer(from, address(0xdead), burnAmt);
        	    }
        	    if(sellIngameFee > 0){
            	    ingameAmt = amount * sellIngameFee / feeDivisor;
            	    super._transfer(from, address(ingameWallet), ingameAmt);
        	    }
        	    totalFees = sellTotalFees - sellBurnFee - sellIngameFee;
                fees = amount.mul(totalFees).div(feeDivisor);
                _liquidityTokensToSwap += fees * sellLiquidityFee / totalFees;
                _marketingTokensToSwap += fees * sellOperationsFee / totalFees;
                _buyBackTokensToSwap += fees * sellBuybackFee / totalFees;
                _teamTokensToSwap += fees * sellTeamFee / totalFees;
            }
            
            if(fees > 0){
            	amount = amount.sub(fees + burnAmt + ingameAmt);
    
                super._transfer(from, address(this), fees);
            }

        }

        super._transfer(from, to, amount);
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
    
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(liquidityWallet),
            block.timestamp
        );
    }
    
    function setRouterVersion(address _router) public onlyOwner {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_router);

        uniswapV2Router = _uniswapV2Router;
        // Set the router of the contract variables
        uniswapV2Router = _uniswapV2Router;
        excludeFromMaxTransaction(address(_uniswapV2Router), true);
    }
    
    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = _liquidityTokensToSwap + _buyBackTokensToSwap + _marketingTokensToSwap + _teamTokensToSwap;
        
        // Halve the amount of liquidity tokens
        uint256 tokensForLiquidity = _liquidityTokensToSwap / 2;
        uint256 amountToSwapForBNB = contractBalance - tokensForLiquidity;
        
        uint256 initialBNBBalance = address(this).balance;

        swapTokensForEth(amountToSwapForBNB); 
        
        uint256 bnbBalance = address(this).balance.sub(initialBNBBalance);
        
        uint256 bnbForMarketing = bnbBalance.mul(_marketingTokensToSwap).div(totalTokensToSwap);
        uint256 bnbForBuyBack = bnbBalance.mul(_buyBackTokensToSwap).div(totalTokensToSwap);
        uint256 bnbForTeam = bnbBalance.mul(_teamTokensToSwap).div(totalTokensToSwap);
        
        uint256 bnbForLiquidity = bnbBalance - bnbForMarketing - bnbForBuyBack - bnbForTeam;
        
        _liquidityTokensToSwap = 0;
        _marketingTokensToSwap = 0;
        _buyBackTokensToSwap = 0;
        _teamTokensToSwap = 0;
        
        (bool success,) = address(marketingWallet).call{value: bnbForMarketing}("");
        (success,) = address(teamWallet).call{value: bnbForTeam}("");
        (success,) = address(buybackWallet).call{value: bnbForBuyBack}("");
        
        addLiquidity(tokensForLiquidity, bnbForLiquidity);
        emit SwapAndLiquify(amountToSwapForBNB, bnbForLiquidity, tokensForLiquidity);
    }
    
    // useful for buybacks or to reclaim any BNB on the contract in a way that helps holders.
    function buyBackTokens(uint256 bnbAmountInWei) external onlyOwner {
        // generate the uniswap pair path of weth -> eth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);

        // make the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: bnbAmountInWei}(
            0, // accept any amount of Ethereum
            path,
            address(0xdead),
            block.timestamp
        );
    }

    // withdraw ETH if stuck before launch
    function withdrawStuckETH() external onlyOwner {
        require(!tradingActive, "Can only withdraw if trading hasn't started");
        bool success;
        (success,) = address(msg.sender).call{value: address(this).balance}("");
    }
}