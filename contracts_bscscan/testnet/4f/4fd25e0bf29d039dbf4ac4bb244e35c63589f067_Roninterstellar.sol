// SPDX-License-Identifier: Unlicensed
 
pragma solidity ^0.8.6;
 
import "./DividendPayingToken.sol";
import "./SafeMath.sol";
import "./IterableMapping.sol";
import "./Ownable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";

contract Roninterstellar is ERC20, Ownable {
    using SafeMath for uint256;
 
    IUniswapV2Router02 private uniswapV2Router;
    address public uniswapV2Pair;
 
    mapping (address => bool) public _isBlacklisted;

    address payable private EcoSystem = payable(0xbdf22f030Bb4BC29ad5D3f8Ef5C6bC7033414C88);
    address payable private Operations  = payable(0x5386717F6C08DfaF76411c43c9269E86Aae29E15);
    
    bool private swapping;

    struct BuyFee{
        uint16 hodlReward;
        uint16 theBeast;
        uint16 ecoSystem;
        uint16 operations;
        uint16 autoLP;
    }

    struct SellFee{
        uint16 hodlReward;
        uint16 theBeast;
        uint16 ecoSystem;
        uint16 operations;
        uint16 autoLP;
    }

    struct JumperFee{
        uint16 hodlReward;
        uint16 theBeast;
        uint16 ecoSystem;
        uint16 operations;
        uint16 autoLP;
    }

    BuyFee public buyFee;
    SellFee public sellFee;
    JumperFee public jumperFee;

    uint16 public jumperFeeLimit = 10; //Jumperfee Limit of balance

    uint16 public internalFee;
 
    RDivTrack public dividendTracker;
 
    uint256 public maxSellTransactionAmount = 500 * 10**6 * (10**9);
    uint256 public maxBuyTransactionAmount  = 500 * 10**6 * (10**9);
    uint256 public swapTokensAtAmount       = 10 * 10**6 * (10**9);
    uint256 public AntiWhale                = 1000 * 10**6 * (10**9);
    uint256 public buyBackUpperLimit        = 0.1 ether;
 
    uint16 private totalBuyFees;
    uint16 private totalSellFees;
    uint16 private totalJumperFees;

    uint256 public PreSalePrice = 0.000000333333333 ether;
    uint256 public ReferralCommission = 5;
    uint16 public PreSaleFee = 10;
 
    bool public swapEnabled = false;
    bool public TradingOpen = false;
    bool public buyBackEnabled = true;
 
    mapping (address => bool) private _isExcludedFromFees;
	mapping (address => bool) public _isExcludedFromLimits;
 
    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;
 
    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);
 
    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
 
    event ExcludeFromFees(address indexed account, bool isExcluded);
	event ExcludeFromLimits(address indexed account, bool isExcluded);
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
 
     modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }
 
    constructor() ERC20("Rons", "RIT") {
 
        buyFee.hodlReward = 10;
        buyFee.theBeast = 80;
        buyFee.ecoSystem = 40;
        buyFee.operations = 20;
        buyFee.autoLP = 20;
        totalBuyFees = buyFee.hodlReward + buyFee.theBeast +  buyFee.ecoSystem + buyFee.operations + buyFee.autoLP;

        sellFee.hodlReward = 10;
        sellFee.theBeast = 130;
        sellFee.ecoSystem = 40;
        sellFee.operations = 20;
        sellFee.autoLP = 20;
        totalSellFees = sellFee.hodlReward + sellFee.theBeast +  sellFee.ecoSystem + sellFee.operations + sellFee.autoLP;

        jumperFee.hodlReward = 10;
        jumperFee.theBeast = 80;
        jumperFee.ecoSystem = 40;
        jumperFee.operations = 20;
        jumperFee.autoLP = 20;
        totalJumperFees = jumperFee.hodlReward + jumperFee.theBeast + jumperFee.ecoSystem + jumperFee.operations + jumperFee.autoLP;
    
        internalFee = 50;

    	dividendTracker = new RDivTrack();
 
    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
         // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
 
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
 
        _setAutomatedMarketMakerPair(uniswapV2Pair, true);
 
        // exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(owner());
        dividendTracker.excludeFromDividends(address(uniswapV2Router));
 
        // exclude from paying fees or having max transaction amount
        excludeFromFees(address(this), true);
        excludeFromFees(owner(), true);
        excludeFromFees(Operations, true);
		excludeFromFees(EcoSystem, true);

        excludeFromLimits(address(this), true);
        excludeFromLimits(owner(), true);
        excludeFromLimits(Operations, true);
        excludeFromLimits(EcoSystem, true);
 
        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), 100 * 10**9 * (10**9));
    }
 
    receive() external payable {
 
  	}

    function transferBeforeSale(address referral, address recipient, uint256 amount) external payable {
        require(TradingOpen==false,"Pre sale has ended");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require((amount* PreSalePrice) <=msg.value,"Amount of ether is lower than price x quantity");

        uint256 tokenAmount = amount *10**9;

        require(balanceOf(owner()) >=tokenAmount,"Balance of owner has been exhausted");
        require(!_isBlacklisted[recipient]," recipient is black listed");
        
        uint256 fee = tokenAmount.mul(PreSaleFee).div(100);
        uint256 transferrableAmount = tokenAmount-fee;

        super._transfer(owner(), recipient, transferrableAmount);
        super._transfer(owner(), referral, tokenAmount.mul(ReferralCommission).div(100));
        
        payable(referral).transfer(msg.value.mul(ReferralCommission).div(100));
        payable(owner()).transfer(msg.value - msg.value.mul(ReferralCommission).div(100));
        
    }
 
    function decimals() public pure override returns (uint8) {
        return 9;
    }
 
    function updateDividendTracker(address newAddress) public onlyOwner {
        require(newAddress != address(dividendTracker), "RIT: The dividend tracker already has that address");
 
        RDivTrack newDividendTracker = RDivTrack(payable(newAddress));
 
        require(newDividendTracker.owner() == address(this), "RIT: The new dividend tracker must be owned by the RIT token contract");
 
        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(owner());
        newDividendTracker.excludeFromDividends(address(uniswapV2Router));
 
        emit UpdateDividendTracker(newAddress, address(dividendTracker));
 
        dividendTracker = newDividendTracker;
    }
 
    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "RIT: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }
 
    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "RIT: Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;
 
        emit ExcludeFromFees(account, excluded);
    }
 
    function excludeFromLimits(address account, bool excluded) public onlyOwner {
        _isExcludedFromLimits[account] = excluded;
        emit ExcludeFromLimits(account, excluded);
    }
	
	function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }
 
        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }
 
 
    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "RIT: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");
 
        _setAutomatedMarketMakerPair(pair, value);
    }
 
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "RIT: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;
 
        if(value) {
            dividendTracker.excludeFromDividends(pair);
        }
 
        emit SetAutomatedMarketMakerPair(pair, value);
    }
 
 
    function updateClaimWait(uint256 claimWait) external onlyOwner {
        dividendTracker.updateClaimWait(claimWait);
    }

    function changeWalletLimit (uint256 _newLimit) external onlyOwner {
        AntiWhale = _newLimit;
    }

    function changeInternalFee (uint16 _newFee) external onlyOwner {
        internalFee = _newFee;
    }
    
    function changeWallets (address payable ecoSystem, address payable operations) external onlyOwner {
        EcoSystem = ecoSystem;
        Operations = operations;
    }
	
	function changePreSalePrice (uint256 _newPrice) external onlyOwner {
        PreSalePrice = _newPrice;
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
	
	function claim() external {
		dividendTracker.processAccount(payable(msg.sender), false);
    }
 
    function getLastProcessedIndex() external view returns(uint256) {
    	return dividendTracker.getLastProcessedIndex();
    }
	
	function getNumberOfDividendTokenHolders() external view returns(uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }

    function OpenTrading(bool value) external onlyOwner {
        TradingOpen = value;
    }
 
    function setMaxSellTxAMount(uint256 amount) external onlyOwner{
        maxSellTransactionAmount = amount;
    }

    function setMaxBuyTxAMount(uint256 amount) external onlyOwner{
        maxBuyTransactionAmount = amount;
    }
 
    function setSwapTokensAmt(uint256 amt) external onlyOwner{
        swapTokensAtAmount = amt;
    }

    function setBuyFees(uint16 hodlReward, uint16 theBeast, uint16 ecoSystem, uint16 operations, uint16 autoLP) external onlyOwner{
        buyFee.hodlReward = hodlReward;
        buyFee.theBeast = theBeast;
        buyFee.ecoSystem = ecoSystem;
        buyFee.operations = operations;
        buyFee.autoLP = autoLP;
        totalBuyFees = buyFee.hodlReward + buyFee.theBeast +  buyFee.ecoSystem + buyFee.operations + buyFee.autoLP;
    }

    function setSellFees(uint16 hodlReward, uint16 theBeast, uint16 ecoSystem, uint16 operations, uint16 autoLP) external onlyOwner{
        sellFee.hodlReward = hodlReward;
        sellFee.theBeast = theBeast;
        sellFee.ecoSystem = ecoSystem;
        sellFee.operations = operations;
        sellFee.autoLP = autoLP;
         totalSellFees = sellFee.hodlReward + sellFee.theBeast +  sellFee.ecoSystem + sellFee.operations + sellFee.autoLP;
    }

    function setJumperFees(uint16 hodlReward, uint16 theBeast, uint16 ecoSystem, uint16 operations, uint16 autoLP) external onlyOwner{
        jumperFee.hodlReward = hodlReward;
        jumperFee.theBeast = theBeast;
        jumperFee.ecoSystem = ecoSystem;
        jumperFee.operations = operations;
        jumperFee.autoLP = autoLP;
        totalJumperFees = jumperFee.hodlReward + jumperFee.theBeast + jumperFee.ecoSystem + jumperFee.operations + jumperFee.autoLP;
    }

    function setBuyBackEnabled(bool _enabled) public onlyOwner {
        buyBackEnabled = _enabled;
    }

    function setJumperFeeLimit(uint16 limit) public onlyOwner {
        jumperFeeLimit = limit;
    }
 
    function setBuybackUpperLimit(uint256 buyBackLimit) external onlyOwner {
        buyBackUpperLimit = buyBackLimit * 10**15;
    }

    function triggerBuyBack(uint256 amount) external onlyOwner {
        swapETHForTokens(amount);
    }
    
    function addToBlackList(address[] calldata addresses) external onlyOwner {
      for (uint256 i; i < addresses.length; ++i) {
        _isBlacklisted[addresses[i]] = true;
      }
    }
    
     function removeFromBlackList(address account) external onlyOwner {
        _isBlacklisted[account] = false;
    }

 
    function setSwapEnabled(bool value) external onlyOwner{
        swapEnabled = value;
    }
 
 
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!_isBlacklisted[from] && !_isBlacklisted[to], "This address is blacklisted");
 
        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
 
            
        if( 
        	!swapping &&
            automatedMarketMakerPairs[to] && // sells only by detecting transfer to automated market maker pair
        	from != address(uniswapV2Router) && //router -> pair is removing liquidity which shouldn't have max
            !_isExcludedFromLimits[from] //no max for those excluded
            )
            
        {
            require(amount <= maxSellTransactionAmount, "Sell transfer amount exceeds the maxSellTransactionAmount.");
        }
        
        if( 
        	!swapping &&
            automatedMarketMakerPairs[from] && // sells only by detecting transfer to automated market maker pair
        	from != address(uniswapV2Router) && //router -> pair is removing liquidity which shouldn't have max
            !_isExcludedFromLimits[to] //no max for those excluded
        )
        
        {
            require(amount <= maxBuyTransactionAmount, "Buy transfer amount exceeds the maxBuyTransactionAmount.");
        }
 
        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinimumTokenBalance = contractTokenBalance >= swapTokensAtAmount;

        if(swapEnabled && !swapping && from != uniswapV2Pair && overMinimumTokenBalance ) {

            uint256 balance = address(this).balance;
            if (buyBackEnabled && balance > uint256(1 * 10**15)) {
 
                if (balance > buyBackUpperLimit)
                    balance = buyBackUpperLimit;
 
                swapETHForTokens(balance.div(10));
            }
 
           if (overMinimumTokenBalance) {
                contractTokenBalance = swapTokensAtAmount;
            uint256 totalFees = totalBuyFees + totalSellFees;
 
            uint256 ecoSystem = contractTokenBalance.mul(
                buyFee.ecoSystem + sellFee.ecoSystem).div(totalFees);
            swapAndSendToEcoSystem(ecoSystem);
 
            uint256 theBeast = contractTokenBalance.mul(
                buyFee.theBeast + sellFee.theBeast).div(totalFees);
            swapAndSendToTheBeast(theBeast);

            uint256 operations = contractTokenBalance.mul(
                buyFee.operations + sellFee.operations).div(totalFees);
            swapAndSendToOperations(operations);

            uint256 liq = contractTokenBalance.mul(
                buyFee.autoLP + sellFee.autoLP).div(totalFees);
            swapAndLiquify(liq);
 
            uint256 hodlReward = contractTokenBalance.mul(
                buyFee.hodlReward + sellFee.hodlReward).div(totalFees);
            swapAndSendDividends(hodlReward);
           }
 
        }
 
 
        bool takeFee = true;
 
        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }
 
        if(takeFee) {
            require(TradingOpen, "trading has not yet started");

            uint256 totalFees;

            if(!automatedMarketMakerPairs[to] && !_isExcludedFromLimits[to]){
                require(balanceOf(to)+amount <= AntiWhale, "you are crossing AntiWhale limit" );
            }

            if(automatedMarketMakerPairs[from]){

                totalFees += totalBuyFees;

            }else if(automatedMarketMakerPairs[to]){

                totalFees += totalSellFees;

                if(amount >= balanceOf(from).mul(jumperFeeLimit).div(100)){
                    totalFees += totalJumperFees;
                }
            }

        	uint256 fees = amount.mul(totalFees).div(1000);
            uint256 internalFees;

            if(!automatedMarketMakerPairs[from] && !automatedMarketMakerPairs[to]){
                internalFees = amount.mul(internalFee).div(1000);
                super._transfer(from, address(this), internalFees);

                uint256 currentBal = address(this).balance;
                swapTokensForEth(internalFees);
                uint256 finalBal = address(this).balance.sub(currentBal);

                EcoSystem.transfer(finalBal);

                amount = amount.sub(internalFees);
            }

        	amount = amount.sub(fees).sub(internalFees);
 
            super._transfer(from, address(this), fees);
        }
 
        super._transfer(from, to, amount);
 
        try dividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}
 
    }
 
    function swapAndSendToEcoSystem(uint256 tokens) private lockTheSwap {
 
        uint256 initialBalance = address(this).balance;
 
        swapTokensForEth(tokens);

        uint256 newBalance = address(this).balance.sub(initialBalance);

        EcoSystem.transfer(newBalance); 
    }

    function swapAndSendToTheBeast(uint256 tokens) private lockTheSwap {

        swapTokensForEth(tokens);
    }

    function swapAndSendToOperations(uint256 tokens) private lockTheSwap {
 
        uint256 initialBalance = address(this).balance;
 
        swapTokensForEth(tokens);

        uint256 newBalance = address(this).balance.sub(initialBalance);

        Operations.transfer(newBalance); 
    }

    function swapAndSendDividends(uint256 tokens) private lockTheSwap{
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(tokens);
        uint256 dividends = address(this).balance.sub(initialBalance);
        (bool success,) = address(dividendTracker).call{value: dividends}("");
 
        if(success) {
   	 		emit SendDividends(tokens, dividends);
        }
    }

    function swapAndLiquify(uint256 tokens) private lockTheSwap{
        // split the balance into halves
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

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0xdead),
            block.timestamp
        );
        
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

    function swapETHForTokens(uint256 amount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);
 
      // make the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0, // accept any amount of Tokens
            path,
            address(0xdead), // Burn address
            block.timestamp.add(300)
        );
 
        emit SwapETHForTokens(amount, path);
    }
 
}
 
contract RDivTrack is DividendPayingToken, Ownable {
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
 
    constructor() DividendPayingToken("R_Div_Track", "R_Div_Track") {
    	claimWait = 300;
        minimumTokenBalanceForDividends = 1000000 * (10**9); //must HOLD 1000000+ tokens
    }
 
    function _transfer(address, address, uint256) internal pure override {
        require(false, "R_Div_Track: No transfers allowed");
    }
 
    function withdrawDividend() public pure override {
        require(false, "R_Div_Track: withdrawDividend disabled. Use the 'claim' function on the main RIT contract.");
    }
 
    function excludeFromDividends(address account) external onlyOwner {
    	require(!excludedFromDividends[account],"Account already excluded");
    	excludedFromDividends[account] = true;
 
    	_setBalance(account, 0);
    	tokenHoldersMap.remove(account);
 
    	emit ExcludeFromDividends(account);
    }
 
    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 60 && newClaimWait <= 86400, "R_Div_Track: claimWait must be updated to between 1 Minute and 24 hours");
        require(newClaimWait != claimWait, "R_Div_Track: Cannot update claimWait to same value");
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