// SPDX-License-Identifier: Unlicensed

/* 
WELCOME TO TWITTER INU

MEET THE ONLY DEFLATIONARY INU TOKEN THAT GIVES YOU AN INSANE AMOUNT OF ETHEREUM REWARDS

DEFI, MEME, DEFI 3.0 , FAAS, DAAS , NFT, FARMING, PASSIVE INCOME... EVERYTHING YOU ARE LOOKING FOR IS HERE.

Its very simple, TWITTERINU need to go viral in the crypto space!!! Buy a bag, claim anytime, enjoy the ETH rewards, use every social network you know (Twitter especially) and share the hashtag #TWITTERINU everywhere, anywhere.
    Always like, comment and retweet our tweets. 
    Dont waste time on Telegram asking when 100x, when binance, when moon. You ask when calls, when marketing? This is the answer: Twitter is free and is the biggest tool for marketing in the Crypto world.

 BUY, SHILL, CLAIM, REPEAT.

 LETS GO VIRAL

 LIQUIDITY LOCKED 1 YEAR, DYNAMIC FEES BASED ON THE MARKET SENTIMENT, NO FEES ON TRANSFER.

 https://t.me/TwitterInu (At launch the only way to communicate with us in on twitter, every comment, every post you make need to have the hashtag #TWITTERINU
 https://twitter.com/TwInuProject


*/

pragma solidity ^0.8.6;

import "./DividendPayingToken.sol";
import "./IterableMapping.sol";
import "./Ownable.sol";
import "./IDex.sol";
import "./SafeMath.sol";

library Address{
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

contract TWITTERINU is ERC20, Ownable {
    using Address for address payable;

    IRouter public router;
    address public  pair;
        
    bool private swapping;
    bool public swapEnabled = true;

    mapping (address=> bool) public isBot;

    TWITTERINUDividendTracker public dividendTracker;

    uint256 public swapTokensAtAmount = 500_000_000 * (10**9);
    uint256 public maxTxAmount = 10000000000 * 10**9;
    uint256 public maxWalletBalance = 50000000000 * 10**9;

    uint256 public  ETHRewardsFee = 0;
    uint256 public  treasuryFee = 20;
    uint256 public  liquidityFee = 0;
    uint256 public  totalFees = ETHRewardsFee + treasuryFee + liquidityFee;

    uint256 public sellETHRewardsFee = 20;
    uint256 public sellTreasuryFee = 0;
    uint256 public sellLiquidityFee = 20;
    uint256 public sellTotalFees = sellETHRewardsFee + sellLiquidityFee + sellTreasuryFee;
    
    address public treasuryWallet = 0x775D05a72504cD751Ac25Fa298443E688dAA0d5a;


    mapping (address => bool) private _isExcludedFromFees;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);

    event Updaterouter(address indexed newAddress, address indexed oldAddress);

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);


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

     modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }

    constructor()  ERC20("TWITTER INU", "TWITTERINU") {
        
    	dividendTracker = new TWITTERINUDividendTracker();

    	IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
         // Create a uniswap pair for this new token
        address _pair = IFactory(_router.factory())
            .createPair(address(this), _router.WETH());

        router = _router;
        pair = _pair;

        _setAutomatedMarketMakerPair(_pair, true);

        // exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(owner());
        dividendTracker.excludeFromDividends(0x000000000000000000000000000000000000dEaD);
        dividendTracker.excludeFromDividends(address(_router));

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(treasuryWallet, true);

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), 1e12 * (10**9));
    }

    receive() external payable {

  	}


    function updateDividendTracker(address newAddress) public onlyOwner {
        require(newAddress != address(dividendTracker), "TWITTERINU: The dividend tracker already has that address");

        TWITTERINUDividendTracker newDividendTracker = TWITTERINUDividendTracker(payable(newAddress));

        require(newDividendTracker.owner() == address(this), "TWITTERINU: The new dividend tracker must be owned by the TWITTERINU token contract");

        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(owner());
        newDividendTracker.excludeFromDividends(address(router));

        emit UpdateDividendTracker(newAddress, address(dividendTracker));

        dividendTracker = newDividendTracker;
    }

    function updateRouter(address newAddress) public onlyOwner {
        require(newAddress != address(router), "TWITTERINU: The router already has that address");
        emit Updaterouter(newAddress, address(router));
        router = IRouter(newAddress);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "TWITTERINU: Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function setSwapTokensAtAmount(uint256 amount) external onlyOwner{
        swapTokensAtAmount = amount * 10**9;
    }

    function setAutomatedMarketMakerPair(address newPair, bool value) public onlyOwner {
        require(newPair != pair, "TWITTERINU: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(newPair, value);
    }

    function excludeFromDividends(address account) external onlyOwner{
        dividendTracker.excludeFromDividends(account);
    }

    function _setAutomatedMarketMakerPair(address newPair, bool value) private {
        require(automatedMarketMakerPairs[newPair] != value, "TWITTERINU: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[newPair] = value;

        if(value) {
            dividendTracker.excludeFromDividends(newPair);
        }

        emit SetAutomatedMarketMakerPair(newPair, value);
    }

    function setMaxtxAmount(uint256 amount) external onlyOwner{
        maxTxAmount = amount * 10**9;
    }

    function setMaxWalletBalance(uint256 amount) external onlyOwner{
        maxWalletBalance = amount * 10**9;
    }

    /// @notice Withdraw tokens sent by mistake.
    /// @param tokenAddress The address of the token to withdraw
    function rescueBEP20Tokens(address tokenAddress) external onlyOwner{
        IERC20(tokenAddress).transfer(msg.sender, IERC20(tokenAddress).balanceOf(address(this)));
    }
    
    function forceSend() external {
        uint256 ETHbalance = address(this).balance;
        payable(owner()).sendValue(ETHbalance);
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

    function getAccountInfo(address account)
        external view returns (
             address,
            uint256,
            uint256,
            uint256,
            uint256){
        return dividendTracker.getAccount(account);
    }

    function claim() external {
		dividendTracker.processAccount(payable(msg.sender), false);
    }

    function setBuyFees(uint256 _rewards, uint256 _liquidity, uint256 _treasury) external onlyOwner{
        require(_rewards + _liquidity + _treasury <= 40, "max fee is 40%");
        ETHRewardsFee = _rewards;
        liquidityFee = _liquidity;
        treasuryFee = _treasury;
        totalFees = ETHRewardsFee + liquidityFee + treasuryFee;
    }

    function setSellFees(uint256 _rewards, uint256 _liquidity, uint256 _treasury) external onlyOwner{
        require(_rewards + _liquidity + _treasury <= 40, "max fee is 40%");
        sellETHRewardsFee = _rewards;
        sellLiquidityFee = _liquidity;
        sellTreasuryFee = _treasury;
        sellTotalFees = sellETHRewardsFee + sellLiquidityFee + sellTreasuryFee;
    }
    
    function setTreasuryWallet(address newWallet) external onlyOwner{
        treasuryWallet = newWallet;
    }

    function setSwapEnabled(bool value) external onlyOwner{
        swapEnabled = value;
    }

    function setBot(address account, bool state) external onlyOwner{
        isBot[account] = state;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!isBot[from] && !isBot[to], "You are a bot");

        if(!_isExcludedFromFees[from] && !_isExcludedFromFees[to]){
           require(amount <= maxTxAmount ,"You are exceeding maxTxAmount");
           if(!automatedMarketMakerPairs[to]){
               require(balanceOf(to) + amount <= maxWalletBalance ,"You are exceeding maxWalletBalance");
           }
        }
        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;
        if(canSwap && swapEnabled && !swapping && from != pair && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            if(totalFees > 0){
                swapAndLiquify(swapTokensAtAmount);
            }
        }

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to] && (!automatedMarketMakerPairs[from] && !automatedMarketMakerPairs[to])) {
            takeFee = false;
        }

        if(takeFee) {
        	uint256 fees;
            if(automatedMarketMakerPairs[from]) fees = amount * (totalFees) / (100);
            else if(automatedMarketMakerPairs[to]) fees  = amount * sellTotalFees / 100;
        	amount = amount - fees;
            super._transfer(from, address(this), fees);
        }

        super._transfer(from, to, amount);

        dividendTracker.setBalance(payable(from), balanceOf(from));
        dividendTracker.setBalance(payable(to), balanceOf(to));
    }

    function swapAndLiquify(uint256 tokens) private lockTheSwap{
        // Split the contract balance into halves
        uint256 denominator= (sellTotalFees) * 2;
        uint256 tokensToAddLiquidityWith = tokens * sellLiquidityFee / denominator;
        uint256 toSwap = tokens - tokensToAddLiquidityWith;

        uint256 initialBalance = address(this).balance;

        swapTokensForETH(toSwap);

        uint256 deltaBalance = address(this).balance - initialBalance;
        uint256 unitBalance= deltaBalance / (denominator - sellLiquidityFee);
        uint256 ethToAddLiquidityWith = unitBalance * sellLiquidityFee;

        if(ethToAddLiquidityWith > 0){
            // Add liquidity to pancake
            addLiquidity(tokensToAddLiquidityWith, ethToAddLiquidityWith);
        }

        // Send ETH to treasury
        uint256 treasuryAmt = (unitBalance * 2 * sellTreasuryFee);
        if(treasuryAmt > 0){
            payable(treasuryWallet).sendValue(treasuryAmt);
        }

        // Send ETH to rewards
        uint256 dividends = unitBalance * 2 * ETHRewardsFee;
        if(dividends > 0){
            (bool success,) = address(dividendTracker).call{value: dividends}("");
            if(success)emit SendDividends(tokens, dividends);
        }
        
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
            address(0), 
            block.timestamp
        );

    }

    function swapTokensForETH(uint256 tokenAmount) private {

        // generate the uniswap pair path of token -> weth
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
}

contract TWITTERINUDividendTracker is DividendPayingToken, Ownable {

    struct AccountInfo {
        address account;
        uint256 withdrawableDividends;
        uint256 totalDividends;
        uint256 lastClaimTime;
    }

    mapping(address => uint256) public lastClaimTimes;

    mapping (address => bool) public excludedFromDividends;

    event ExcludeFromDividends(address indexed account);

    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor()  DividendPayingToken("TWITTERINU_Dividend_Tracker", "TWITTERINU_Dividend_Tracker") { }

    function _transfer(address, address, uint256) internal pure override{
        require(false, "TWITTERINU_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() public pure override {
        require(false, "TWITTERINU_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main TWITTERINU contract.");
    }

    function excludeFromDividends(address account) external onlyOwner {
    	require(!excludedFromDividends[account]);
    	excludedFromDividends[account] = true;

    	_setBalance(account, 0);

    	emit ExcludeFromDividends(account);
    }

    function getAccount(address account) public view returns (address, uint256, uint256, uint256, uint256 ) {
        AccountInfo memory info;
        info.account = account;
        info.withdrawableDividends = withdrawableDividendOf(account);
        info.totalDividends = accumulativeDividendOf(account);
        info.lastClaimTime = lastClaimTimes[account];
        return (
            info.account,
            info.withdrawableDividends,
            info.totalDividends,
            info.lastClaimTime,
            totalDividendsWithdrawn
        );
        
    }

    function setBalance(address payable account, uint256 newBalance) external onlyOwner {
    	if(excludedFromDividends[account]) {
    		return;
    	}
        _setBalance(account, newBalance);    
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