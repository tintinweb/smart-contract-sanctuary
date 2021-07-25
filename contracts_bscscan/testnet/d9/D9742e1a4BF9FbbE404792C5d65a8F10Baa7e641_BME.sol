// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "./DividendPayingToken.sol";
import "./SafeMath.sol";
import "./IterableMapping.sol";
import "./Ownable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";

contract BME is ERC20, Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;

    IUniswapV2Router02 public uniswapV2Router;
    address public immutable uniswapV2Pair;
    address private immutable BTCB = address(0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7);
    
    bool private swapping;
    BBTracking public dBTCTracker;
    address public Lwallet;

    uint256 public MSTAmt = 1* (10**9) * (10**18);
    uint256 public STatAmt = 200000 * (10**18);
    uint256 public GFProcess = 300000;
    uint256 public TenabledTS = 1625947158;

    uint256 private  BTCRewardsFee;
    uint256 private  TokenRewardFee;
    uint256 private  BuyliquidityFee;
    uint256 private  SellliquidityFee;
    uint256 public  BuytotalFees;
    uint256 public  SelltotalFees;

    uint256 private  BuyFee;
    uint256 private  SellFee;
 
    mapping (address => bool) private _isExlFFees;
    mapping (address => bool) public AMMPairs;

    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);
    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);
    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event SwapAndLiquify(uint256 tokensSwapped,  uint256 ethReceived,uint256 tokensIntoLiqudity);
    event SendBTCBDividends(uint256 tokensSwapped,uint256 BTCamount);
    event LastClaims(uint256 claims);
    event ProcessedBTCBDividendTracker(uint256 iterations,uint256 claims,uint256 lastProcessedIndex,bool indexed automatic,uint256 gas,address indexed processor);

    constructor() public ERC20("Test30", "T30") {
        
        uint256 _BTCRewardsFee = 11;
        uint256 _TokenRewardFee = 1;
        uint256 _BuyliquidityFee = 1;
        uint256 _SellLiquidityFee = 3;

        BTCRewardsFee = _BTCRewardsFee;
        TokenRewardFee = _TokenRewardFee;
        BuyliquidityFee = _BuyliquidityFee;
        SellliquidityFee = _SellLiquidityFee;


        BuytotalFees = _BTCRewardsFee.add(_BuyliquidityFee.add(_TokenRewardFee));

        SelltotalFees = _BTCRewardsFee.add(_SellLiquidityFee.add(_TokenRewardFee));

    	 dBTCTracker = new BBTracking();

    	  IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
         // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        Lwallet = owner();

        _setAMMPairs(_uniswapV2Pair, true);

        // exclude from receiving BTCB dividends
        dBTCTracker.excludeFromDividends(address(dBTCTracker));
        dBTCTracker.excludeFromDividends(address(this));
        dBTCTracker.excludeFromDividends(owner());
        dBTCTracker.excludeFromDividends(address(_uniswapV2Router));



        // exclude from paying fees or having max transaction amount
        ExlFromF(owner(), true);
        ExlFromF(address(this), true);
        ExlFromF(address(dBTCTracker),true);
        
        

        dBTCTracker.setBMEToken(address(this));

        // mint just for 1 time ..
        _mint(owner(), 1 * (10**12) * (10**18));
    }

    receive() external payable {
  	}

    function setSTatAmt(uint256 amount) external onlyOwner{
        STatAmt = amount * (10**18);
    }

    function isExlFFees(address account) public view returns(bool) {
        return _isExlFFees[account];
    }
    function _setAMMPairs(address pair, bool value) private {
        require(AMMPairs[pair] != value, "BME: Automated market maker pair is already set to that value");
        AMMPairs[pair] = value;

        if(value) {
            dBTCTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 500000, "BME: gasForProcessing must be between 200,000 and 500,000");
        require(newValue != GFProcess, "BME: Cannot update gasForProcessing to same value");
        emit GasForProcessingUpdated(newValue, GFProcess);
        GFProcess = newValue;
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "BME: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }

    function updateLwallet(address newLwallet) public onlyOwner {
        require(newLwallet != Lwallet, "BME: The liquidity wallet is already this address");
        ExlFromF(newLwallet, true);
        emit LiquidityWalletUpdated(newLwallet, Lwallet);
        Lwallet = newLwallet;
    }

    function ExlFromF(address account, bool excluded) public onlyOwner {
        _isExlFFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function setMSTxAmt(uint256 amount) external onlyOwner{
        MSTAmt = amount * 10**18;
    }

    function setAMMPairs(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "BME: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAMMPairs(pair, value);
    }

    // start  Dividend BTCB Tracker functions

    function getTotaldd() external view returns (uint256) {
        return dBTCTracker.totalDividendsDistributed();
    }

    function WblDof(address account) public view returns(uint256) {
    	return dBTCTracker.withdrawableDividendOf(account);
  	}

	function dTokenBof(address account) public view returns (uint256) {
		return dBTCTracker.balanceOf(account);
	}

    function getAccountDividendsInfo(address account)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        return dBTCTracker.getAccount(account);
    }

	function ProcessDT(uint256 gas) external {
		(uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = dBTCTracker.process(gas);
		emit ProcessedBTCBDividendTracker(iterations, claims, lastProcessedIndex, false, gas, tx.origin);
    }

    function claim() external {
		    dBTCTracker.processAccount(msg.sender, false);
    }

    function getlastProcidx() external view returns(uint256) {
    	return dBTCTracker.getLastProcessedIndex();
    }
    
    function getTIsEnabled() public view returns (bool) {
        return block.timestamp >= TenabledTS;
    }


    function setMinTtoGetR(uint256 amount) external onlyOwner{
        dBTCTracker.setMinTtoGetR(amount);
    }

    // end  Dividend BTCB Tracker functions

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");


        bool tradingIsEnabled = getTIsEnabled();

        // no one can transfer before trading Is Enabled
        // and before the public presale is over
        if(!tradingIsEnabled){
            require(_isExlFFees[from], "BME: cannot send tokens when trading is disable");
        }

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
        if(
        	!swapping &&
            AMMPairs[to] && // sells only by detecting transfer to automated market maker pair
        	from != address(uniswapV2Router) && //router -> pair is removing liquidity which shouldn't have max
            !_isExlFFees[to] && //no max for those excluded from fees
            !_isExlFFees[from] &&
            to != Lwallet &&
            from != Lwallet
        ) {

            require( amount  <= MSTAmt, "Sell transfer total day amount exceeds the maxSellTransactionAmount.");
        }

        bool canSwap = SellFee.add(BuyFee) >= STatAmt;

        if(
            canSwap &&
            !swapping &&
            !AMMPairs[from] &&
            from != Lwallet &&
            to != Lwallet
        ) {
            swapping = true;
            
            uint256 LSF = SellFee.mul(SellliquidityFee).div(SelltotalFees);
            uint256 LBF = BuyFee.mul(BuyliquidityFee).div(BuytotalFees);
            uint256 swapTokens = LSF.add(LBF);
            swapAndLiquify(swapTokens);
            
            uint256 RSF = SellFee.mul(TokenRewardFee).div(SelltotalFees);
            uint256 RBF = BuyFee.mul(TokenRewardFee).div(BuytotalFees);
            
            uint256 BBF = BuyFee.mul(BTCRewardsFee).div(BuytotalFees);
            uint256 BSF = SellFee.mul(BTCRewardsFee).div(SelltotalFees);
            
            uint256 BMETokens =  RSF.add(RBF);
            uint256 BTCBTokens = BSF.add(BBF);
            
            SWandSendBTCd(BTCBTokens , BMETokens);

            BuyFee  = 0;
            SellFee = 0;
            swapping = false;
        }
        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExlFFees[from] || _isExlFFees[to]) {
            takeFee = false;
        }
        if(takeFee) {

          uint256 Fees;
          // check if sell or buy
          if( AMMPairs[to] ) {
              
           Fees = amount.mul(SelltotalFees).div(100);
           SellFee  = SellFee.add(Fees);

          }else{

          Fees = amount.mul(BuytotalFees).div(100);
          BuyFee  = BuyFee.add(Fees);

          }

        amount = amount.sub(Fees);

        super._transfer(from, address(this), Fees);

        }

        super._transfer(from, to, amount);
        
        try dBTCTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try dBTCTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

        if( !swapping && AMMPairs[from] ) {
            
          
	    	uint256 gas = GFProcess;
          try dBTCTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
	    		emit ProcessedBTCBDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);} catch {}
        }
    }



    function swapAndLiquify(uint256 tokens) private {
        // split the contract balance into halves
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        SwapTFETH(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to pancake
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function SwapTFETH(uint256 tokenAmount) private {


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

    function SwapTFBTCB(uint256 tokenAmount) private {
         // generate the uniswap pair path of weth -> BTCB
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        path[2] = BTCB;

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BTCB
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
            Lwallet,
            block.timestamp
        );

    }

    function SWandSendBTCd(uint256 BTCBtokens , uint256 BMEtokens) private {
        SwapTFBTCB(BTCBtokens);
        uint256 dividends = IERC20(BTCB).balanceOf(address(this));  // chack the balance of BTCB
        
        _approve( address(this), address(dBTCTracker), BMEtokens);
        
        bool success = IERC20(BTCB).transfer(address(dBTCTracker), dividends);
                       _transfer(address(this),address(dBTCTracker), BMEtokens);


        if (success) {
            dBTCTracker.distributeBMEBTCBDividends(dividends , BMEtokens); // add the balance of BTCB to the total
        }
    }

        
    
        
}
contract BBTracking is DividendPayingToken, Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;

    mapping (address => bool) public excludedFromDividends;
    mapping (address => uint256) public lastClaimTimes;

    uint256 public lastProcessedIndex;
    uint256 public claimWait;
    address public BMEaddress;

    uint256 public minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event Claim(address indexed account, uint256 BTCBamount,uint256 BMEamount, bool indexed automatic);

    constructor() public DividendPayingToken("BMEBTCB", "BMEB") {
    	// User options for receiving Dividends

      claimWait = 900;

      minimumTokenBalanceForDividends = 5 * (10**7) * (10**18);
    }

    function _transfer(address, address, uint256) internal override {
        require(false, "BMETrackingBTCB: No transfers allowed");
    }

    function withdrawDividend() public override {
        require(false, "BMETrackingBTCB: withdrawDividend disabled. Use the 'claim' function on the main BME contract.");
    }

    function setMinTtoGetR(uint256 amount) external onlyOwner{
        minimumTokenBalanceForDividends = amount * (10**18);
    }

    function excludeFromDividends(address account) external onlyOwner {
    	require(!excludedFromDividends[account]);
    	excludedFromDividends[account] = true;

    	_setBalance(account, 0);
    	tokenHoldersMap.remove(account);

    	emit ExcludeFromDividends(account);
    }

    function getLastProcessedIndex() external view returns(uint256) {
    	return lastProcessedIndex;
    }

    function getNumberOfTokenHolders() external view returns(uint256) {
        return tokenHoldersMap.keys.length;
    }
    
    function setBMEToken(address newaddress) external onlyOwner{
        BMEaddress = newaddress;
         setBMEadd(newaddress);
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



    function canAutoClaim(uint256 lastClaimTime ) private view returns (bool) {
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
         (uint256 BTCBamount,uint256 BMEamount) = _withdrawDividendOfUser(account);

    	if(BTCBamount > 0 && BMEamount > 0) {
    		lastClaimTimes[account] = block.timestamp;
            emit Claim(account, BTCBamount, BMEamount , automatic);
    		return true;
    	}

    	return false;
    }
}