// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DividendPayingToken.sol";
import "./SafeMath.sol";
import "./IterableMapping.sol";
import "./Ownable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";


contract TinyTokens is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public  uniswapV2Pair;

    bool private swapping;
    
    enum ReflectionToken{ ETH, BUSD, ADA }
    
    ETHTracker public dividendTrackerETH;
    BUSDTracker public dividendTrackerBUSD;
    ADATracker public dividendTrackerADA;
    
    address public deadWallet = 0x000000000000000000000000000000000000dEaD;

   
    address private  BUSD = address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    address private  BETH = address(0x2170Ed0880ac9A755fd29B2688956BD959F933F8);
    address private  BADA = address(0x3EE2200Efb3400fAbB9AacF31297cBdD1d435D47);
    //address private  BXRP = address(0x1d2f0da169ceb9fc7b3144628db156f3f6c60dbe);
    //address public WBNB = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    
    address[] public reflectionTokensAddresses = [BETH, BUSD, BADA];
    uint256 public swapTokensAtAmount = 2000 * (10**18);
    uint256 private totalSuppl = 1000000 * (10**18);
    mapping(address => bool) public _isBlacklisted;

    uint256 public rewardsFee = 5;
    uint256 public liquidityFee = 1;
    uint256 public marketingFee = 3;
    uint256 public totalFees = rewardsFee.add(liquidityFee).add(marketingFee);

    address public _marketingWalletAddress = 0x4e6C00e734b944482eBC5E715E020ea55f72ca10;

    

    uint256 public gasForProcessing = 300000;

     // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;
   

  
    mapping (address => bool) public automatedMarketMakerPairs;

    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    event ExcludeFromMaxTransferAmount(address indexed account, bool isExcluded);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);

    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
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

    constructor()  ERC20("TinyTokens", "TINY") {

        dividendTrackerETH = new ETHTracker();
        dividendTrackerBUSD = new BUSDTracker();
        dividendTrackerADA = new ADATracker();

        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
         // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        // exclude from receiving dividends
        dividendTrackerETH.excludeFromDividends(address(dividendTrackerETH));
        dividendTrackerETH.excludeFromDividends(address(this));
        dividendTrackerETH.excludeFromDividends(owner());
        dividendTrackerETH.excludeFromDividends(deadWallet);
        dividendTrackerETH.excludeFromDividends(address(_uniswapV2Router));
        
        dividendTrackerBUSD.excludeFromDividends(address(dividendTrackerBUSD));
        dividendTrackerBUSD.excludeFromDividends(address(this));
        dividendTrackerBUSD.excludeFromDividends(owner());
        dividendTrackerBUSD.excludeFromDividends(deadWallet);
        dividendTrackerBUSD.excludeFromDividends(address(_uniswapV2Router));
        
        dividendTrackerADA.excludeFromDividends(address(dividendTrackerADA));
        dividendTrackerADA.excludeFromDividends(address(this));
        dividendTrackerADA.excludeFromDividends(owner());
        dividendTrackerADA.excludeFromDividends(deadWallet);
        dividendTrackerADA.excludeFromDividends(address(_uniswapV2Router));

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(_marketingWalletAddress, true);
        excludeFromFees(address(this), true);
        
       

        _mint(owner(), totalSuppl);
    }

    receive() external payable {

      }

    function updateDividendETHTracker(address newAddress) public onlyOwner {
        require(newAddress != address(dividendTrackerETH), "TinyTokens: The dividend tracker already has that address");
        
        ETHTracker newDividendTracker = ETHTracker(payable(newAddress));

        require(newDividendTracker.owner() == address(this), "TinyTokens: The new dividend tracker must be owned by the TinyTokens token contract");

        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(owner());
        newDividendTracker.excludeFromDividends(address(uniswapV2Router));

        emit UpdateDividendTracker(newAddress, address(dividendTrackerETH));

        dividendTrackerETH = newDividendTracker;
    }
     function updateDividendBUSDTracker(address newAddress) public onlyOwner {
        require(newAddress != address(dividendTrackerBUSD), "TinyTokens: The dividend tracker already has that address");
        
        BUSDTracker newDividendTracker = BUSDTracker(payable(newAddress));

        require(newDividendTracker.owner() == address(this), "TinyTokens: The new dividend tracker must be owned by the TinyTokens token contract");

        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(owner());
        newDividendTracker.excludeFromDividends(address(uniswapV2Router));

        emit UpdateDividendTracker(newAddress, address(dividendTrackerBUSD));

        dividendTrackerBUSD = newDividendTracker;
    }
    
    function updateDividendADATracker(address newAddress) public onlyOwner {
        require(newAddress != address(dividendTrackerADA), "TinyTokens: The dividend tracker already has that address");
        
        ADATracker newDividendTracker = ADATracker(payable(newAddress));

        require(newDividendTracker.owner() == address(this), "TinyTokens: The new dividend tracker must be owned by the TinyTokens token contract");

        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(owner());
        newDividendTracker.excludeFromDividends(address(uniswapV2Router));

        emit UpdateDividendTracker(newAddress, address(dividendTrackerADA));

        dividendTrackerADA = newDividendTracker;
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "TinyTokens: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
        address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Pair = _uniswapV2Pair;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "TinyTokens: Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }
    
  

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function setMarketingWallet(address payable wallet) external onlyOwner{
        _marketingWalletAddress = wallet;
    }


    function setRewardsFee(uint256 value) external onlyOwner{
        rewardsFee = value;
        totalFees = rewardsFee.add(liquidityFee).add(marketingFee);
    }

    function setLiquiditFee(uint256 value) external onlyOwner{
        liquidityFee = value;
        totalFees = rewardsFee.add(liquidityFee).add(marketingFee);
    }

    function setMarketingFee(uint256 value) external onlyOwner{
        marketingFee = value;
        totalFees = rewardsFee.add(liquidityFee).add(marketingFee);

    }
    
    function calculatePercentOfFees(uint256 amountTokens) view private  returns (uint256) {
        
        
        
        uint256 intCorrection = 1000000000000;
        uint256 tinyTokenBalance = returnUniswapPairTTBalance();
        tinyTokenBalance = tinyTokenBalance.mul(intCorrection);
        uint256 wbnbTokenBalance = returnUniswapPairWBNBBalance();
        uint256 bnbValue = tinyTokenBalance.div(wbnbTokenBalance);
        amountTokens = amountTokens.mul(intCorrection);
        bnbValue = amountTokens.div(bnbValue);
        uint256 a = 7142857142857143000;
        uint256 b = 500000000000000000000;
        uint256 xsquare = bnbValue.mul(bnbValue);
        xsquare = xsquare.mul(intCorrection);
        bnbValue = bnbValue.mul(intCorrection);
        b = bnbValue.div(b);
        a = xsquare.div(a);
        uint256 c = 12000000000000000000;
        c= c.mul(intCorrection);
        a = a.add(b).add(c);
        a = a.div(intCorrection);
        return a;

    }

     function returnUniswapPairWBNBBalance() public view returns (uint256) {
        return IERC20(uniswapV2Router.WETH()).balanceOf(uniswapV2Pair);
    }
    function returnUniswapPairTTBalance() public view returns (uint256) {
        return IERC20(address(this)).balanceOf(uniswapV2Pair);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "TinyTokens: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }
    
    function blacklistAddress(address account, bool value) external onlyOwner{
        _isBlacklisted[account] = value;
    }


    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "TinyTokens: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        if(value) {
            dividendTrackerETH.excludeFromDividends(pair);
            dividendTrackerBUSD.excludeFromDividends(pair);
            dividendTrackerADA.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }


    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 500000, "TinyTokens: gasForProcessing must be between 200,000 and 500,000");
        require(newValue != gasForProcessing, "TinyTokens: Cannot update gasForProcessing to same value");
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        dividendTrackerETH.updateClaimWait(claimWait);
        dividendTrackerBUSD.updateClaimWait(claimWait);
        dividendTrackerADA.updateClaimWait(claimWait);
    }

    function getClaimWait() external view returns(uint256) {
        return dividendTrackerETH.claimWait();
    }

    function getTotalETHDividendsDistributed() external view returns (uint256) {
        return dividendTrackerETH.totalDividendsDistributed();
    }
    function getTotalBUSDDividendsDistributed() external view returns (uint256) {
        return dividendTrackerBUSD.totalDividendsDistributed();
    }
    function getTotalADADividendsDistributed() external view returns (uint256) {
        return dividendTrackerADA.totalDividendsDistributed();
    }
    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function withdrawableETHDividendOf(address account) public view returns(uint256) {
        return dividendTrackerETH.withdrawableDividendOf(account);
      }
      function withdrawableBUSDDividendOf(address account) public view returns(uint256) {
        return dividendTrackerBUSD.withdrawableDividendOf(account);
      }
      function withdrawableADADividendOf(address account) public view returns(uint256) {
        return dividendTrackerADA.withdrawableDividendOf(account);
      }
      function withdrawnETHDividendOf(address account) public view returns(uint256) {
        return dividendTrackerETH.withdrawnDividendOf(account);
      }
      function withdrawnBUSDDividendOf(address account) public view returns(uint256) {
        return dividendTrackerBUSD.withdrawnDividendOf(account);
      }
      function withdrawnADADividendOf(address account) public view returns(uint256) {
        return dividendTrackerADA.withdrawnDividendOf(account);
      }

    function dividendETHTokenBalanceOf(address account) public view returns (uint256) {
        return dividendTrackerETH.balanceOf(account);
    }
    function dividendBUSDTokenBalanceOf(address account) public view returns (uint256) {
        return dividendTrackerBUSD.balanceOf(account);
    }
    function dividendADATokenBalanceOf(address account) public view returns (uint256) {
        return dividendTrackerADA.balanceOf(account);
    }
    function excludeFromDividends(address account) external onlyOwner{
        dividendTrackerETH.excludeFromDividends(account);
        dividendTrackerBUSD.excludeFromDividends(account);
        dividendTrackerADA.excludeFromDividends(account);
    }

    function getAccountDividendsInfo(address account, ReflectionToken reflectionToken)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        if (reflectionToken == ReflectionToken.ETH) {
            return dividendTrackerETH.getAccount(account);
        } else if(reflectionToken == ReflectionToken.BUSD) {
            return dividendTrackerBUSD.getAccount(account);
        } else {
            return dividendTrackerADA.getAccount(account);
        }
        
    }

    function getAccountDividendsInfoAtIndex(uint256 index, ReflectionToken reflectionToken)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        if (reflectionToken == ReflectionToken.ETH) {
            return dividendTrackerETH.getAccountAtIndex(index);
        } else if(reflectionToken == ReflectionToken.BUSD) {
            return dividendTrackerBUSD.getAccountAtIndex(index);
        } else {
            return dividendTrackerADA.getAccountAtIndex(index);
        }
    }

    function processDividendTracker(uint256 gas) external {
        (uint256 iterationsETH, uint256 claimsETH, uint256 lastProcessedIndexETH) = dividendTrackerETH.process(gas);
        (uint256 iterationsBUSD, uint256 claimsBUSD, uint256 lastProcessedIndexBUSD) = dividendTrackerBUSD.process(gas);
        (uint256 iterationsADA, uint256 claimsADA, uint256 lastProcessedIndexADA) = dividendTrackerADA.process(gas);
        emit ProcessedDividendTracker(iterationsETH, claimsETH, lastProcessedIndexETH, false, gas, tx.origin);
        emit ProcessedDividendTracker(iterationsBUSD, claimsBUSD, lastProcessedIndexBUSD, false, gas, tx.origin);
        emit ProcessedDividendTracker(iterationsADA, claimsADA, lastProcessedIndexADA, false, gas, tx.origin);
    }

    function claim() external {
        dividendTrackerETH.processAccount(payable(msg.sender), false);
        dividendTrackerBUSD.processAccount(payable(msg.sender), false);
        dividendTrackerADA.processAccount(payable(msg.sender), false);
    }

    function getLastProcessedIndex() external view returns(uint256) {
        return dividendTrackerETH.getLastProcessedIndex();
    }

    function getNumberOfDividendTokenHolders() external view returns(uint256) {
        return dividendTrackerETH.getNumberOfTokenHolders();
    }


    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!_isBlacklisted[from] && !_isBlacklisted[to], 'Blacklisted address');
        
        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if( canSwap &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            from != owner() &&
            to != owner()
        ) {
            swapping = true;

            uint256 marketingTokens = contractTokenBalance.mul(marketingFee).div(totalFees);
            swapAndSendToFee(marketingTokens);

            uint256 swapTokens = contractTokenBalance.mul(liquidityFee).div(totalFees);
            swapAndLiquify(swapTokens);

            uint256 sellTokens = balanceOf(address(this));
            swapAndSendDividends(sellTokens);

            swapping = false;
        }


        bool takeFee = !swapping;

    
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if(takeFee) {
            //Hier max transfer Require reinhauen
            require(amount <= totalSuppl.div(200), 'Amount is too high!');
            uint256 percentOfTotalFees = calculatePercentOfFees(amount);
            uint256 fees = amount.mul(percentOfTotalFees).div(100000000000000000000);
            if(automatedMarketMakerPairs[to]){
                fees += amount.mul(1).div(100);
            }
            amount = amount.sub(fees);

            super._transfer(from, address(this), fees);
        }

        super._transfer(from, to, amount);

        try dividendTrackerETH.setBalance(payable(from), balanceOf(from)) {} catch {}
        try dividendTrackerETH.setBalance(payable(to), balanceOf(to)) {} catch {}
        
        try dividendTrackerBUSD.setBalance(payable(from), balanceOf(from)) {} catch {}
        try dividendTrackerBUSD.setBalance(payable(to), balanceOf(to)) {} catch {}
        
        try dividendTrackerADA.setBalance(payable(from), balanceOf(from)) {} catch {}
        try dividendTrackerADA.setBalance(payable(to), balanceOf(to)) {} catch {}

        if(!swapping) {
            uint256 gas = gasForProcessing;

            try dividendTrackerETH.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
            }
            catch {

            }
            
            try dividendTrackerBUSD.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
            }
            catch {

            }
            
            try dividendTrackerADA.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
            }
            catch {

            }
        }
    }
    
    

    function swapAndSendToFee(uint256 tokens) private  {

        uint256 initialBUSDBalance = IERC20(BUSD).balanceOf(address(this));

        swapTokensForReflectionToken(tokens, ReflectionToken.BUSD);
        uint256 newBalance = (IERC20(BUSD).balanceOf(address(this))).sub(initialBUSDBalance);
        IERC20(BUSD).transfer(_marketingWalletAddress, newBalance);
    }

    function swapAndLiquify(uint256 tokens) private {
       // split the contract balance into halves
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);

   
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

    function swapTokensForReflectionToken(uint256 tokenAmount, ReflectionToken reflectionToken) private {
        
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        path[2] = reflectionTokensAddresses[uint(reflectionToken)];

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
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
            address(0),
            block.timestamp
        );

    }

    function swapAndSendDividends(uint256 tokens) private{
        uint256 ethTokens = tokens.div(reflectionTokensAddresses.length);
        uint256 adaTokens = tokens.div(reflectionTokensAddresses.length);
        uint256 busdTokens = tokens.sub(ethTokens).sub(adaTokens);
        
        swapTokensForReflectionToken(ethTokens, ReflectionToken.ETH);
        swapTokensForReflectionToken(adaTokens, ReflectionToken.ADA);
        swapTokensForReflectionToken(busdTokens, ReflectionToken.BUSD);
        uint256 dividendsETH = IERC20(reflectionTokensAddresses[uint(ReflectionToken.ETH)]).balanceOf(address(this));
        uint256 dividendsADA = IERC20(reflectionTokensAddresses[uint(ReflectionToken.ADA)]).balanceOf(address(this));
        uint256 dividendsBUSD = IERC20(reflectionTokensAddresses[uint(ReflectionToken.BUSD)]).balanceOf(address(this));
        bool successETH = IERC20(reflectionTokensAddresses[uint(ReflectionToken.ETH)]).transfer(address(dividendTrackerETH), dividendsETH);
        bool successADA = IERC20(reflectionTokensAddresses[uint(ReflectionToken.ADA)]).transfer(address(dividendTrackerADA), dividendsADA);
        bool successBUSD = IERC20(reflectionTokensAddresses[uint(ReflectionToken.BUSD)]).transfer(address(dividendTrackerBUSD), dividendsBUSD);
        
        if (successETH) {
            dividendTrackerETH.distributeDividends(dividendsETH);
            emit SendDividends(ethTokens, dividendsETH);
        }
        if (successADA) {
            dividendTrackerADA.distributeDividends(dividendsADA);
            emit SendDividends(adaTokens, dividendsADA);
        }
        if (successBUSD) {
            dividendTrackerBUSD.distributeDividends(dividendsBUSD);
            emit SendDividends(busdTokens, dividendsBUSD);
        }
    }
}

contract TinyTokensDividendTracker is Ownable, DividendPayingToken {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map internal tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping (address => bool) public excludedFromDividends;

    mapping (address => uint256) public lastClaimTimes;

    uint256 public claimWait;
    uint256 public immutable minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor() DividendPayingToken("TinyTokens_Dividend_Tracker", "TinyTokens_Dividend_Tracker") {
        claimWait = 3600;
        minimumTokenBalanceForDividends = 200 * (10**18);
    }
    
    function _transfer(address, address, uint256) pure internal override {
        require(false, "TinyTokens_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() pure  public override {
        require(false, "TinyTokens_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main TinyTokens contract.");
    }

    function excludeFromDividends(address account) external onlyOwner {
        require(!excludedFromDividends[account]);
        excludedFromDividends[account] = true;

        _setBalance(account, 0);
        tokenHoldersMap.remove(account);

        emit ExcludeFromDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 3600 && newClaimWait <= 86400, "TinyTokens_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "TinyTokens_Dividend_Tracker: Cannot update claimWait to same value");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }

    function getLastProcessedIndex() external view returns(uint256) {
        return lastProcessedIndex;
    }

    function getNumberOfTokenHolders() external view returns(uint256) {
        return tokenHoldersMap.keys.length;
    }



    function getAccount(address _account)
        public view returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable) {
        account = _account;

        index = tokenHoldersMap.getIndexOfKey(account);

        iterationsUntilProcessed = -1;

        if(index >= 0) {
            if(uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
            }
            else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ?
                                                        tokenHoldersMap.keys.length.sub(lastProcessedIndex) :
                                                        0;


                iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
            }
        }


        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);

        lastClaimTime = lastClaimTimes[account];

        nextClaimTime = lastClaimTime > 0 ?
                                    lastClaimTime.add(claimWait) :
                                    0;

        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ?
                                                    nextClaimTime.sub(block.timestamp) :
                                                    0;
    }

    function getAccountAtIndex(uint256 index)
        public view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        if(index >= tokenHoldersMap.size()) {
            return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
        }

        address account = tokenHoldersMap.getKeyAtIndex(index);

        return getAccount(account);
    }

    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
        if(lastClaimTime > block.timestamp)  {
            return false;
        }

        return block.timestamp.sub(lastClaimTime) >= claimWait;
    }

    function setBalance(address payable account, uint256 newBalance) external onlyOwner {
        if(excludedFromDividends[account]) {
            return;
        }

        if(newBalance >= minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance);
            tokenHoldersMap.set(account, newBalance);
        }
        else {
            _setBalance(account, 0);
            tokenHoldersMap.remove(account);
        }

        processAccount(account, true);
    }

    function process(uint256 gas) public returns (uint256, uint256, uint256) {
        uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

        if(numberOfTokenHolders == 0) {
            return (0, 0, lastProcessedIndex);
        }

        uint256 _lastProcessedIndex = lastProcessedIndex;

        uint256 gasUsed = 0;

        uint256 gasLeft = gasleft();

        uint256 iterations = 0;
        uint256 claims = 0;

        while(gasUsed < gas && iterations < numberOfTokenHolders) {
            _lastProcessedIndex++;

            if(_lastProcessedIndex >= tokenHoldersMap.keys.length) {
                _lastProcessedIndex = 0;
            }

            address account = tokenHoldersMap.keys[_lastProcessedIndex];

            if(canAutoClaim(lastClaimTimes[account])) {
                if(processAccount(payable(account), true)) {
                    claims++;
                }
            }

            iterations++;

            uint256 newGasLeft = gasleft();

            if(gasLeft > newGasLeft) {
                gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
            }

            gasLeft = newGasLeft;
        }

        lastProcessedIndex = _lastProcessedIndex;

        return (iterations, claims, lastProcessedIndex);
    }

    function processAccount(address payable account, bool automatic) public onlyOwner returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);

        if(amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, automatic);
            return true;
        }

        return false;
    }
}

contract BUSDTracker is TinyTokensDividendTracker {

    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    
    constructor() TinyTokensDividendTracker() {}
    
    function _withdrawDividendOfUser(address payable user) internal override returns (uint256) {

        uint256 _withdrawableDividend = withdrawableDividendOf(user);
        if (_withdrawableDividend > 0) {
          withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
          emit DividendWithdrawn(user, _withdrawableDividend);
          
          bool success = IERC20(BUSD).transfer(user, _withdrawableDividend);
          if(!success) {
            withdrawnDividends[user] = withdrawnDividends[user].sub(_withdrawableDividend);
            return 0;
          }
          return _withdrawableDividend;

        }
        return 0;

    }
}

    
contract ETHTracker is TinyTokensDividendTracker {

    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;
    
    constructor() TinyTokensDividendTracker() {}
    
    function _withdrawDividendOfUser(address payable user) internal override returns (uint256) {

        uint256 _withdrawableDividend = withdrawableDividendOf(user);
        if (_withdrawableDividend > 0) {
          withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
          emit DividendWithdrawn(user, _withdrawableDividend);
          
          bool success = IERC20(BETH).transfer(user, _withdrawableDividend);
          if(!success) {
            withdrawnDividends[user] = withdrawnDividends[user].sub(_withdrawableDividend);
            return 0;
          }
          return _withdrawableDividend;

        }
        return 0;

    }

}

contract ADATracker is TinyTokensDividendTracker {

    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    
    
    constructor() TinyTokensDividendTracker() {}
    
    function _withdrawDividendOfUser(address payable user) internal override returns (uint256) {

        uint256 _withdrawableDividend = withdrawableDividendOf(user);
        if (_withdrawableDividend > 0) {
          withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
          emit DividendWithdrawn(user, _withdrawableDividend);
          
          bool success = IERC20(BADA).transfer(user, _withdrawableDividend);
          if(!success) {
            withdrawnDividends[user] = withdrawnDividends[user].sub(_withdrawableDividend);
            return 0;
          }
          return _withdrawableDividend;

        }
        return 0;

    }

}