// SPDX-License-Identifier: MIT

/**

                                    BitcoMine Project
               First of its own yet the most profitable Multi rewarding mechanisms
              were adopted to make sure that the community will benefit from holding $BME.

BTC daily rewards:
11% of each successful transaction sell/buy will be re-allocated and distributed to $BME community holders.

$BME daily rewards:
1% of each successful transaction sell/buy will be re-allocated and distributed to $BME community holders.

Long/short Investment:
High profitable and stable program that aims to support our community expectations, It stops when rewarding pool reaches ZERO.

Website: https://bitcominetoken.com
Twitter: https://twitter.com/BitcoMineToken
Telegram group: https://t.me/BitcoMine

*/

// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@/....    ...,,,,****/////(,@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@****@@@@@@@,    ...,,,,****////(((//*@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@***,,..,@@@@@@@....,,,,****////(((///.,@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@***,,....../@@@@@@@@@@@@@**////(((///*[email protected]@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@**,,,.......  .&@@@@@@@@@@#////(((///*..#@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@**,,,.......   [email protected]@@@@@@@@@////(((///*[email protected]@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@**,,,....... .  [email protected]@@@@@@@@*////(((///  [email protected]@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@**,,,.....*   @@@@..&%.****////(((// ./@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@**,,*../@@@@@@* ...,,,,****////(([email protected]@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@**,,,[email protected]@@@@(    ...,,,,****,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@**,,*,@@@@@@@@# ...,,,,****////((,@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@&***,,.....,%@@@@@@**/@@@@@/////(((//*@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@%**,,,........./@@@@@@@@@@@@@@//(((/////@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@(**,,,.......  //@@@@@@@@@@@@@@/(((///*//@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@,**,,,.......  ((@@@@@@@@@@@@@@/(((///*((@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@,**,,,.......  */@@@@@@@@@@@@@//(((///*//@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@.**,,,.......    /&@@@@@@@@@////(((///**@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@.**,,,.......    ....,,,***/////(((/,**@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@.**,,,.......    ...,,,,****////(.,,,@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@%[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

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

    IUniswapV2Router02 public uniswapV2Router;
    address public immutable uniswapV2Pair;
    address public immutable BTC = address(0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c);

    bool private swapping;
    BBTracking public dBTCTracker;
    address public Lwallet;

    uint256 public STatAmt    = 2000000 * (10**18);
    uint256 public GFProcess  = 300000;
    uint256 public TenabledTS = 100;
    uint256 public MtotalS    = 1 * (10**10) * (10**18);

    uint256 private  BTCRFee;
    uint256 private  TokenRFee;
    uint256 private  BuyLFee;
    uint256 private  SellLFee;
    uint256 public   BuyTFees;
    uint256 public   SellTFees;

    uint256 private  BuyFee;
    uint256 private  SellFee;

    mapping (address => bool) private _isExlFFees;
    mapping (address => bool) public AMMPairs;

    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);
    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event SwapAndLiquify(uint256 tokensSwapped,  uint256 ethReceived,uint256 tokensIntoLiqudity);
    event SendBTCAndBMEDividends(uint256 BTCamount,uint256 BMEamount);
    event ProcessedBTCDividendTracker(uint256 iterations,uint256 claims,uint256 lastProcessedIndex,bool indexed automatic,uint256 gas,address indexed processor);
    event BurnedTokens(address burnfrom ,uint256 tokens);

    constructor() public ERC20("BitcoMine", "BME") {

        uint256 _BTCRFee   = 11;
        uint256 _TokenRFee = 1;
        uint256 _BuyLFee   = 1;
        uint256 _SellLFee  = 6;

        BTCRFee   = _BTCRFee;
        TokenRFee = _TokenRFee;
        BuyLFee   = _BuyLFee;
        SellLFee  = _SellLFee;

        BuyTFees  = _BTCRFee.add(_BuyLFee.add(_TokenRFee));
        SellTFees = _BTCRFee.add(_SellLFee.add(_TokenRFee));

    	 dBTCTracker = new BBTracking();

    	  IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
         // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        Lwallet = owner();

        _setAMMPairs(_uniswapV2Pair, true);

        // exclude from receiving BTC dividends
        dBTCTracker.ExlFromD(address(dBTCTracker));
        dBTCTracker.ExlFromD(address(this));
        dBTCTracker.ExlFromD(owner());
        dBTCTracker.ExlFromD(address(_uniswapV2Router));

        // exclude from paying fees or having max transaction amount
        ExlFromF(owner(), true);
        ExlFromF(address(this), true);
        ExlFromF(address(dBTCTracker),true);
        ExlFromF(address(_uniswapV2Router),true);

        dBTCTracker.setBMEadd(address(this));

        // mint just for 1 time ..
        _mint(owner(), 1 * (10**12) * (10**18));
    }

    receive() external payable {
  	}

    function isExlFFees(address account) public view returns(bool) {
        return _isExlFFees[account];
    }

    function _setAMMPairs(address pair, bool value) private {
        require(AMMPairs[pair] != value, "BME: Automated market maker pair is already set to that value");
        AMMPairs[pair] = value;

        if(value) {
            dBTCTracker.ExlFromD(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateGFProcess(uint256 newValue) public onlyOwner {
        require(newValue >= 100000 && newValue <= 500000, "BME: gasForProcessing must be between 200,000 and 500,000");
        require(newValue != GFProcess, "BME: Cannot update gasForProcessing to same value");
        emit GasForProcessingUpdated(newValue, GFProcess);
        GFProcess = newValue;
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "BME: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }

    function ExlFromF(address account, bool excluded) public onlyOwner {
        _isExlFFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function setAMMPairs(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "BME: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAMMPairs(pair, value);
    }

    function MaxSA() public view returns(uint256) {
        return totalSupply().div(1000);
    }

    // start  Dividend BTC Tracker functions

    function getTotaldd() external view returns (uint256) {
        return dBTCTracker.totalBTCDividendsDistributed();
    }

    function getTotalddBME() external view returns (uint256) {
        return dBTCTracker.totalBMEDividendsDistributed();
    }

    function getTlSBTC() external view returns (uint256) {
        return dBTCTracker.CurrentSupplyBTC();
    }

    function getTlSBME() external view returns (uint256) {
        return dBTCTracker.CurrentSupplyBME();
    }

    function getTotalNoH() external view returns (uint256) {
        return dBTCTracker.getNumberOfTokenHolders();
    }

    function WblDofBTC(address account) public view returns(uint256) {
    	return dBTCTracker.withdrawableDividendOf(account);
  	}

  	function WblDofBME(address account) public view returns(uint256) {
    	return dBTCTracker.withdrawableDividendOfBME(account);
  	}

    function getAccountdI(address account)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        return dBTCTracker.getAccount(account);
    }

	function ProcessDT(uint256 gas) external {
		(uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = dBTCTracker.process(gas);
		emit ProcessedBTCDividendTracker(iterations, claims, lastProcessedIndex, false, gas, tx.origin);
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

    function setMinTtoGetR(uint256 amountBTC ,uint256 amountBME) external onlyOwner{
        dBTCTracker.setMinTtoGetR( amountBTC , amountBME );
    }

    function ExlFromD(address account) external onlyOwner{
        dBTCTracker.ExlFromD(account);
    }


    // end  Dividend BTC Tracker functions

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

        bool tradingIsEnabled = getTIsEnabled();

        // no one can transfer before trading Is Enabled
        // and before the public presale is over
        if(!tradingIsEnabled){
            require(_isExlFFees[from], "BME: cannot send tokens when trading is disable");
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
            require( amount <= MaxSA() , "Sell transfer total day amount exceeds the maxSellTransactionAmount.");
        }

        bool canSwap = SellFee.add(BuyFee) >= STatAmt;

        if(
            canSwap &&
            !swapping &&
            AMMPairs[to] &&
            from != Lwallet &&
            to != Lwallet
        ) {
            swapping = true;

            // Calculet Liquidity tokens
            uint256 LSF = SellFee.mul(SellLFee).div(SellTFees);
            uint256 LBF = BuyFee.mul(BuyLFee).div(BuyTFees);
            uint256 swapTokens = LSF.add(LBF);
            // Calculet Burn tokens
            uint256 tokenstoBurn = swapTokens.mul(50).div(100);

            if (totalSupply().sub(tokenstoBurn) > 1 * (10**10) * (10**18)){
                Burn(address(this),tokenstoBurn);
                swapTokens = swapTokens.sub(tokenstoBurn);
            }

            swapAndLiquify(swapTokens);

            // Calculet tokens rewards
            uint256 RSF = SellFee.mul(TokenRFee).div(SellTFees);
            uint256 RBF = BuyFee.mul(TokenRFee).div(BuyTFees);

            // Calculet BTC rewards
            uint256 BBF = BuyFee.mul(BTCRFee).div(BuyTFees);
            uint256 BSF = SellFee.mul(BTCRFee).div(SellTFees);

            uint256 BMETokens =  RSF.add(RBF);
            uint256 BTCTokens = BSF.add(BBF);

            SWandSendBTCd(BTCTokens , BMETokens);

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

          Fees = amount.mul(SellTFees).div(100);
          SellFee  = SellFee.add(Fees);

          super._transfer(from, address(this), Fees);

          }else if( AMMPairs[from] ){

          Fees = amount.mul(BuyTFees).div(100);
          BuyFee  = BuyFee.add(Fees);

          super._transfer(from, address(this), Fees);

          }else{

          Fees = amount.mul(SellTFees).div(100);
          super._transfer(from, address(this), Fees);
          swapAndLiquify(Fees);

          }
          amount = amount.sub(Fees);
        }

        super._transfer(from, to, amount);

        try dBTCTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try dBTCTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

        if( !swapping && AMMPairs[from]) {

	    	uint256 gas = GFProcess;
          try dBTCTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
	    		emit ProcessedBTCDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);} catch {}
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

    function Burn(address account,uint256 amount) public {
        require( account == Lwallet || account == address(this) , "Burn should be from liquidity wallet or contract .");
        require( totalSupply().sub(amount) >= 1 * (10**10) * (10**18) , "Total Supply should be more than 10B token.");

         _burn( account , amount );

        emit BurnedTokens( account , amount );
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

    function SwapTFBTC(uint256 tokenAmount) private {
         // generate the uniswap pair path of weth -> BTC
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        path[2] = BTC;

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BTC
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

    function SWandSendBTCd(uint256 BTCtokens , uint256 BMEtokens) public {

        SwapTFBTC(BTCtokens);
        uint256 swapedBTCtokens = IERC20(BTC).balanceOf(address(this));  // chack the balance of BTC

        _approve(address(this), address(dBTCTracker), BMEtokens);
        IERC20(BTC).transfer(address(dBTCTracker), swapedBTCtokens);
        _transfer(address(this),address(dBTCTracker), BMEtokens);

        dBTCTracker.distributeDividends(swapedBTCtokens , BMEtokens); // add the balance of BTC to the total

        emit SendBTCAndBMEDividends(swapedBTCtokens,BMEtokens);
    }

}
contract BBTracking is DividendPayingToken, Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;

    mapping (address => bool) public isExlFromD;
    mapping (address => uint256) public lastClaimBME;
    mapping (address => uint256) public lastClaimBTC;
    uint256 public lastProcessedIndex;
    uint256 public claimWaitBME;
    uint256 public claimWaitBTC;
    uint256 public minimumTokenBalanceForBTC;
    uint256 public minimumTokenBalanceForBME;

    event ExcludeFromDividends(address indexed account);
    event ClaimBTC(address indexed account, uint256 BTCamount, bool indexed automatic);
    event ClaimBME(address indexed account, uint256 BMEamount, bool indexed automatic);

    constructor() public DividendPayingToken("BMEBTC", "BMEB") {
    	// User options for receiving Dividends

      claimWaitBME = 600;
      claimWaitBTC = 600;
      minimumTokenBalanceForBTC = 37500000 * (10**18);
      minimumTokenBalanceForBME  = 3750000 * (10**18);
    }

    function _transfer(address, address, uint256) internal override {
        require(false, "BMEBTC: No transfers allowed");
    }

    function withdrawDividend() public override {
        require(false, "BMEBTC: withdrawDividend disabled. Use the 'claim' function on the main BME contract.");
    }

    function isExlFromDa(address account) public view returns(bool){
        return isExlFromD[account];
    }

    function balanceofD(address account) public view returns(uint256,uint256){
        return ( HolderTokensBTC[account] , HolderTokensBME[account] );
    }

    function setMinTtoGetR(uint256 amountBTC , uint256 amountBME) external onlyOwner{
        minimumTokenBalanceForBTC = amountBTC * (10**18);
        minimumTokenBalanceForBME  = amountBME * (10**18);
    }

    function ExlFromD(address account) external onlyOwner {
    	require(!isExlFromD[account]);
    	isExlFromD[account] = true;

    	_setBalance(account, 0);
    	_setBalanceBME(account, 0);
    	tokenHoldersMap.remove(account);

    	emit ExcludeFromDividends(account);
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
            uint256 withdrawableDividendsBME,
            uint256 totalDividendsBME,
            uint256 lastClaimTimeBTC,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable,
            uint256 lastClaimTimeBME,
            uint256 nextClaimTimeBME,
            uint256 secondsUntilAutoClaimAvailableBME) {

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

        withdrawableDividendsBME = withdrawableDividendOfBME(account);

        totalDividendsBME = accumulativeDividendOfBME(account);

        lastClaimTimeBTC = lastClaimBTC[account];

        nextClaimTime = lastClaimTimeBTC > 0 ?
                                      lastClaimTimeBTC.add(claimWaitBTC) :
                                      0;

        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ?
                                                    nextClaimTime.sub(block.timestamp) :
                                                    0;

        lastClaimTimeBME  = lastClaimBME[account];

        nextClaimTimeBME = lastClaimTimeBME > 0 ?
                                      lastClaimTimeBME.add(claimWaitBME) :
                                      0;

        secondsUntilAutoClaimAvailableBME = nextClaimTimeBME > block.timestamp ?
                                                    nextClaimTimeBME.sub(block.timestamp) :
                                                    0;
    }



    function setBalance(address payable account, uint256 newBalance) external onlyOwner {
    	if(!isExlFromD[account]) {

    	if( minimumTokenBalanceForBTC > newBalance  && newBalance >= minimumTokenBalanceForBME ){

        	    _setBalance(account, 0);
        		_setBalanceBME(account, newBalance);
        		lastClaimBME[account]  = block.timestamp;
        		lastClaimBTC[account] = 0;
            tokenHoldersMap.set(account);

    	}else if(newBalance >= minimumTokenBalanceForBTC) {

            _setBalance(account, newBalance);
            _setBalanceBME(account, 0);
            lastClaimBTC[account] = block.timestamp;
            lastClaimBME[account]  = 0;
            tokenHoldersMap.set(account);

    	}else{

            _setBalance(account, 0);
            _setBalanceBME(account, 0);
            tokenHoldersMap.remove(account);
            lastClaimBTC[account] = 0;
            lastClaimBME[account]  = 0;

    	    }
        processAccount(account, true);
        }
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


    			if(processAccount(payable(account), true)) {
    			    claims++;
    			}


    		iterations++;

    		uint256 newGasLeft = gasleft();

    		if(gasLeft > newGasLeft) {
    			gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
    		}

    		gasLeft = newGasLeft;
    	}

    	lastProcessedIndex = _lastProcessedIndex;

    	return (iterations , claims ,  lastProcessedIndex);
    }

    function processAccount(address payable account, bool automatic) public onlyOwner returns (bool) {
         uint256 BTCamount = withdrawableDividendOf(account);
         uint256 BMEamount = withdrawableDividendOfBME(account);

    	if(BTCamount > 0 && lastClaimBTC[account].add(claimWaitBTC) <= block.timestamp) {
    	    _withdrawDividendOfUser(account);
    		lastClaimBTC[account] = block.timestamp;
            emit ClaimBTC(account, BMEamount , automatic);
    		return true;
    	}

    	if(BMEamount > 0 && lastClaimBME[account].add(claimWaitBME) <= block.timestamp) {
    	    _withdrawDividendOfUserBME(account);
    		lastClaimBME[account] = block.timestamp;
            emit ClaimBME(account, BMEamount , automatic);
    		return true;
    	}

    	return false;
    }


}