// SPDX-License-Identifier: MIT

//
// $DHNETWORK proposes an innovative feature in its contract.
//
// DIVIDEND YIELD PAID IN Cummunity voted token! With the auto-claim feature,
// simply hold $DHNETWORK and you'll receive the token the Cummunity decides automatically in your wallet.
//
// Hold DHNET and get rewarded in the token the community decides on every transaction!
//
//
// 📱 Telegram: https://t.me/Diamondhandsnetwork
// 🌎 Website: https://diamondhandsnetwork.app
// 🌐 Twitter: https://twitter.com/D_H_Network
//

//pragma solidity 0.8.4;
pragma solidity ^0.6.2;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";
import "./DHNDividendTracker.sol";


contract DimaondHandsNetworkToken is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public  uniswapV2Pair;

    bool private swapping;

    bool public projectWalletsFounded;

    DHNDividendTracker public dividendTracker;

    address public constant DEAD_WALLET = 0x000000000000000000000000000000000000dEaD;

    uint256 private constant START_TIMEOUT = 300;

    //address public _rewardsTokenAddress = address(0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82); // Rewards token

    address public _rewardsTokenAddress = address(0xF9f93cF501BFaDB6494589Cb4b4C15dE49E85D0e); // Rewards token TESTNET

    uint256 public _swapTokensAtAmount = 10000 * (10**18);

    mapping(address => bool) public _isBlacklisted;

    mapping(address => bool) public _isSniperBot;

    uint256 public _maxDailyTxPercentage = 10;

    uint256 public TOKENRewardsFee = 4;
    uint256 public liquidityFee = 6;
    uint256 public marketingFee = 5;
    uint256 public totalFees = TOKENRewardsFee.add(liquidityFee).add(marketingFee);

    uint256 private launchedAt;

    // test marketing wallet
    //address payable public _marketingWalletAddress = payable(0x3d291865C135aD8c9146978467063b754d197729);

    //multisig marketing wallet
    address payable public _marketingWalletAddress = payable(0xDEC550DFE34a56E0804B733fFE3b09CE7Bed1e9F);

    // test treasury wallet
    //address payable public _treasuryWalletAddress = payable(0x692E2d33b80c17D7d2562B1c0745DC390a21a2d8);

    //multisig treasury wallet
    address payable public _treasuryWalletAddress = payable(0x56819053E939F264bdFEE89F7E3bE95BA54175Dc);

    address[] public _teamWallets =  [0x1a544081E970C31cFBfdA443eB390d5746A27E0F, //
        0x9A63ccE0001Bb761576ca645ecC61C0275cEd868, //
        0x6099BF2eC6424Ae44D196Ad1094967ED66AaCfF5, //
        0xD73faCBb9329977C942E0BE5a418f9b755546b88, //
        0x67e0Fd55D625f920004649020eb04B2992bf099f, //
        0xE249c6f118750B3c2cBE00FE2A9A09f791864E57]; //

    // use by default 300,000 gas to process auto-claiming dividends
    uint256 public gasForProcessing = 300000;

     // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;


    mapping (address => bool) private _isExcludedFromTransferLimits;


    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    uint256 private constant TOKENS_MKT = 200000 * (10**18);

    uint256 public _sellWait = 86400;

    uint256 public _maxWalletSize = 15000 * (10**18);
    uint256 public _maxTxAmount = 1000 * (10**18);

    uint256 public lockPeriod = 7889238;

    struct SellsHistory {
        uint256 sellTime;
        uint256 salesAmount;
    }

    mapping (address => SellsHistory) public _sellsHistoryPerAddress;

    mapping (address => uint256) public _teamWalletsLockTime;


    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event ExcludeFromTransferLimits(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);

    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event SellWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

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

    event SwapTokensForETH(
        uint256 amountIn,
        address[] path
    );

    //constructor() ERC20("Diamond Hands Network", "DHNETWORK") {
    constructor() public ERC20("DHNTests-3", "DHNT3") {

    	dividendTracker = new DHNDividendTracker();

        //Pancakeswap bsc mainnet
    	//IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);

        //Pancakeswap bsc testnet kiemtienonline360
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);

        // Create a uniswap pair for this new token
        IUniswapV2Factory _uniswapV2Factory = IUniswapV2Factory(_uniswapV2Router.factory());
        address _uniswapV2Pair = _uniswapV2Factory.createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        // exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(owner());
        dividendTracker.excludeFromDividends(DEAD_WALLET);
        dividendTracker.excludeFromDividends(_marketingWalletAddress);
        dividendTracker.excludeFromDividends(_treasuryWalletAddress);
        dividendTracker.excludeFromDividends(address(_uniswapV2Router));

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(_marketingWalletAddress, true);
        excludeFromFees(_treasuryWalletAddress, true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0), true);
        //excludeFromFees(address(_uniswapV2Router), true);

        excludeFromTransferLimits(address(dividendTracker), true);
        excludeFromTransferLimits(address(this), true);
        excludeFromTransferLimits(owner(), true);
        excludeFromTransferLimits(DEAD_WALLET, true);
        excludeFromTransferLimits(_marketingWalletAddress, true);
        excludeFromTransferLimits(_treasuryWalletAddress, true);
        excludeFromTransferLimits(address(_uniswapV2Router), true);

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), 1000000 * (10**18));
        fundAndLockTeamAndMarketingWallets();
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "DHNET#1");
        automatedMarketMakerPairs[pair] = value;

        if(value) {
            dividendTracker.excludeFromDividends(pair);
            excludeFromTransferLimits(pair, true);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }


    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 500000, "DHNET#2");
        require(newValue != gasForProcessing, "DHNET#3");
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
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

    function isExcludedFromTransferLimits(address account) public view returns(bool) {
        return _isExcludedFromTransferLimits[account];
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
	    dividendTracker.processAccount(payable(msg.sender), false);
    }

    function getLastProcessedIndex() external view returns(uint256) {
    	return dividendTracker.getLastProcessedIndex();
    }

    function getNumberOfDividendTokenHolders() external view returns(uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }


    function _canSell(address from, uint256 amount) external view returns(bool){
        return canSell(from, amount);
    }


    function canSell(address from, uint256 amount) private view returns(bool){
        // If address is excluded from fees or is the owner of the contract or is the contract we allow all transfers to avoid probles with liquidity or dividends
        if (_isExcludedFromFees[from]){
            return true;
        }

        uint256 walletBalance = balanceOf(from);
        // If wallet balance in less or 1000 tokens let them sell all.
        if(walletBalance <= 1000){
            return true;
        }
        // If wallet is trying to sell more than 10% of it's balance we won't allow the transfer
        if(walletBalance > 0 && amount > walletBalance.mul(_maxDailyTxPercentage).div(100)){
            return false;
        }
        // If time of last sell plus waiting time is greater than actual time we need to check if addres is trying to sell more than 10%
        if(_sellsHistoryPerAddress[from].sellTime.add(_sellWait) >= block.timestamp){
            uint256 maxSell = walletBalance.add(_sellsHistoryPerAddress[from].salesAmount).mul(_maxDailyTxPercentage).div(100);
            return _sellsHistoryPerAddress[from].salesAmount.add(amount) < maxSell;
        }
        if(_sellsHistoryPerAddress[from].sellTime.add(_sellWait) < block.timestamp){
            return true;
        }
        return false;
    }

    function getTimeUntilNextTransfer(address from) external view returns(uint256){
        if(_sellsHistoryPerAddress[from].sellTime.add(_sellWait) > block.timestamp){
            return _sellsHistoryPerAddress[from].sellTime.add(_sellWait).sub(block.timestamp);
        }
        return 0;
    }

    function updateAddressLastSellData(address from, uint256 amount) private {
        // If tiem of last sell plus waiting time is lower than the actual time is either a first sale or waiting time has expired
        // We can reset all struct values for this address
        if(_sellsHistoryPerAddress[from].sellTime.add(_sellWait) < block.timestamp){
            _sellsHistoryPerAddress[from].salesAmount = amount;
            _sellsHistoryPerAddress[from].sellTime = block.timestamp;
            return;
        }
        _sellsHistoryPerAddress[from].salesAmount += amount;
    }



    // This should limit the wallet tokens to _maxWalletSize
    function _maxWalletReached(address to) external view returns (bool) {
        return maxWalletReached(to, 0);
    }

    // This should limit the wallet tokens to _maxWalletSize
    function maxWalletReached(address to, uint256 amount) private view returns (bool) {
        if(_isExcludedFromTransferLimits[to]){
            return false;
        }
        uint256 amountToBuy = amount;
        if (!_isExcludedFromFees[to]){
        	uint256 fees = amount.mul(totalFees).div(100);
            amountToBuy = amount.sub(fees);
        }
        return balanceOf(to).add(amountToBuy) >= _maxWalletSize;
    }

    function _isTeamWalletLocked(address who) external view returns (bool){
        return isTeamWalletLocked(who);
    }

    function isTeamWalletLocked(address who) private view returns (bool){
        bool isTeamWallet = false;
        for (uint i = 0; i < _teamWallets.length; i++){
            if(_teamWallets[i] == who){
                isTeamWallet = true;
                break;
            }
        }
        return isTeamWallet && _teamWalletsLockTime[who] > block.timestamp;
    }

    function cloneSellDataToTransferWallet(address to, address from) private {
        _sellsHistoryPerAddress[to].salesAmount = _sellsHistoryPerAddress[from].salesAmount;
        _sellsHistoryPerAddress[to].sellTime = _sellsHistoryPerAddress[from].sellTime;

    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "DHNET#4");
        require(to != address(0), "DHNET#5");
        require(!_isBlacklisted[from] && !_isBlacklisted[to], "DHNET#6");
        //require(_firstTransferTime.add(START_TIMEOUT) < block.timestamp, "Transfers not allowed yet");
        require(!isTeamWalletLocked(to) && !isTeamWalletLocked(from), "DHNET#7");

        if(launchedAt == 0 && from == owner() && automatedMarketMakerPairs[to]) {
			launchedAt = block.number;
		}

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        bool isTransferBetweenWallets = to != address(this) && from != address(this) && !automatedMarketMakerPairs[to]
            && !automatedMarketMakerPairs[from] && to != owner() && from != owner()
            && from != address(dividendTracker) && to != address(dividendTracker);

        if (isTransferBetweenWallets){
            cloneSellDataToTransferWallet(to, from);
            super._transfer(from, to, amount);
            return;
        }

        bool isLiqTrans = (automatedMarketMakerPairs[to] && from == owner())
            || (automatedMarketMakerPairs[from] && to == address(uniswapV2Router));

        if(!_isExcludedFromFees[to] && !_isExcludedFromFees[from] && !isLiqTrans ) {
            require(amount <= _maxTxAmount, "DHNET#8");
        }

        if (automatedMarketMakerPairs[from]){
            require(!maxWalletReached(to, amount), "DHNET#9");
        }

        if(automatedMarketMakerPairs[to] && !_isExcludedFromTransferLimits[from]){
            require(canSell(from, amount), "DHNET#10");
            /*
            if(!canSell(from, amount)){
                revert("You can only sell 10% of your total tokens per day.");
            }
            */
            updateAddressLastSellData(from, amount);
        }

	    uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= _swapTokensAtAmount;

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

        // if any account belongs to _isExcludedFromFees account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to] || isLiqTrans) {
            takeFee = false;
        }

        if(takeFee) {

        	if(block.number <= (launchedAt + 2) && automatedMarketMakerPairs[from] && to != address(uniswapV2Router) && to != address(this) && to != owner()) {
        	    totalFees += 75;
        	    _isSniperBot[to] = true;
        	}

        	uint256 fees = amount.mul(totalFees).div(100);
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


    function swapAndSendToFee(uint256 tokens) private {

        uint256 initialTOKENBalance = IERC20(_rewardsTokenAddress).balanceOf(address(this));

        //swapTokensForRewardToken(tokens);
        swapTokensForEth(tokens);
        uint256 newBalance = (IERC20(_rewardsTokenAddress).balanceOf(address(this))).sub(initialTOKENBalance);
        //IERC20(_rewardsTokenAddress).transfer(_marketingWalletAddress, newBalance);
        transferToAddressETH(_marketingWalletAddress, newBalance);
    }

    function transferToAddressETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }

    function swapAndLiquify(uint256 tokens) private{
       // split the contract balance into halves
        uint256 half = tokens.div(2);
        //uint256 otherHalf = tokens.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(half, newBalance);

        emit SwapAndLiquify(half, newBalance, half);
    }

    function swapTokensForEth(uint256 tokenAmount)  private{

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

    function swapTokensForRewardToken(uint256 tokenAmount) private {

        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        path[2] = _rewardsTokenAddress;

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
            //address(0),
	        owner(),
            block.timestamp
        );

    }

    function swapAndSendDividends(uint256 tokens) private{
        swapTokensForRewardToken(tokens);
        uint256 dividends = IERC20(_rewardsTokenAddress).balanceOf(address(this));
        bool success = IERC20(_rewardsTokenAddress).transfer(address(dividendTracker), dividends);

        if (success) {
            dividendTracker.distributeDividends(dividends);
            emit SendDividends(tokens, dividends);
        }
    }

    function setMaxTxAmount(uint256 maxTxAmount) external onlyOwner() {
        _maxTxAmount = maxTxAmount;
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        dividendTracker.updateClaimWait(claimWait);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "DHNET#11");

        _setAutomatedMarketMakerPair(pair, value);
    }
    function crateUniswapV2Pair() public onlyOwner {
        address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);
        uniswapV2Pair = _uniswapV2Pair;
    }


    function _fundAndLockTeamAndMarketingWallets() public onlyOwner {
        require(!projectWalletsFounded, "DHNET#12");
        fundAndLockTeamAndMarketingWallets();
    }

    function fundAndLockTeamAndMarketingWallets() private {
        require(!projectWalletsFounded, "DHNET#13");
        super._transfer(owner(), address(_marketingWalletAddress), TOKENS_MKT);
        super._transfer(owner(), address(_treasuryWalletAddress), TOKENS_MKT);
        uint256 lockUntil = block.timestamp.add(lockPeriod);
        for (uint i = 0; i < _teamWallets.length; i++){
            excludeFromFees(_teamWallets[i], true);
            super._transfer(owner(), _teamWallets[i], _maxWalletSize);
            _teamWalletsLockTime[_teamWallets[i]] = lockUntil;
            excludeFromFees(_teamWallets[i], false);
        }
        projectWalletsFounded = true;
    }

    receive() external payable {

  	}


    function updateSellWait(uint256 newSellWait) external onlyOwner {
        require(newSellWait != _sellWait, "DHNET#14");
        emit SellWaitUpdated(newSellWait, _sellWait);
        _sellWait = newSellWait;
    }

    function updateDividendTracker(address newAddress) public onlyOwner {
        require(newAddress != address(dividendTracker), "DHNET#15");

        DHNDividendTracker newDividendTracker = DHNDividendTracker(payable(newAddress));

        require(newDividendTracker.owner() == address(this), "DHNET#16");

        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(owner());
        newDividendTracker.excludeFromDividends(address(uniswapV2Router));

        emit UpdateDividendTracker(newAddress, address(dividendTracker));

        dividendTracker = newDividendTracker;
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "DHNET#17");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
        address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
        excludeFromTransferLimits(address(_uniswapV2Pair), true);
        uniswapV2Pair = _uniswapV2Pair;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "DHNET#18");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeFromTransferLimits(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromTransferLimits[account] != excluded, "DHNET#19");
        _isExcludedFromTransferLimits[account] = excluded;

        emit ExcludeFromTransferLimits(account, excluded);
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

    function setTreasuryWallet(address payable wallet) external onlyOwner{
        _treasuryWalletAddress = wallet;
    }

    function setRewardsTokenAddress(address newAddress) external onlyOwner{
        dividendTracker.setRewardsTokenAddress(newAddress);
        _rewardsTokenAddress = newAddress;
    }

    function setTOKENRewardsFee(uint256 value) external onlyOwner{
        TOKENRewardsFee = value;
        totalFees = TOKENRewardsFee.add(liquidityFee).add(marketingFee);
    }

    function setLiquiditFee(uint256 value) external onlyOwner{
        liquidityFee = value;
        totalFees = TOKENRewardsFee.add(liquidityFee).add(marketingFee);
    }

    function setMarketingFee(uint256 value) external onlyOwner{
        marketingFee = value;
        totalFees = TOKENRewardsFee.add(liquidityFee).add(marketingFee);

    }

    function blacklistAddress(address account, bool value) external onlyOwner{
        _isBlacklisted[account] = value;
    }
}