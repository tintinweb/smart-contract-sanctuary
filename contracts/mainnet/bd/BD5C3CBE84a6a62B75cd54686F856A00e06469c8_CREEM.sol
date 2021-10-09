// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./DividendPayingToken.sol";
import "./SafeMath.sol";
import "./IterableMapping.sol";
import "./Ownable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";
import "./CREEMDividendTracker.sol";

contract CREEM is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool private swapping;

    CREEMDividendTracker public dividendTracker;
    address public peechToken;
    address public liquidityWallet;
    address public devWallet;
    address public rewardsWallet;
    address public immutable deadAddress = address(0x000000000000000000000000000000000000dEaD);
    uint256 public constant maxSellTransactionAmount = 10**7 * (10**18); // 10M
    uint256 public constant maxBuyTransactionAmount = 2 * 10**6 * (10**18); // 2M
    uint256 public constant swapTokensAtAmount = 2 * 10**6 * (10**18); //2M
    uint256 public constant devFee = 2;
    uint256 public constant rewardsFee = 4;
    uint256 public constant buybackFee = 4;
    uint256 public constant liquidityFee = 2;
    uint256 public constant burnFee = 2;
    uint256 public totalFees;

    // it can only be activated, once activated, it can't be disabled
    bool public isTradingEnabled;

    // it can only be disactivated once after the presale;
    bool public buyLimit = true;
    
    // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;

    // addresses that can make transfers before presale is over
    mapping (address => bool) private canTransferBeforeTradingIsEnabled;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event ExcludeFromDividends(address indexed account);

    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    
    event ExcludeMultipleAccountsFromDividends(address[7] accounts);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);

    event DevWalletUpdated(address indexed newDevWallet, address indexed oldDevWallet);

    event RewardsWalletUpdated(address indexed newRewardsWallet, address indexed oldRewardsWallet);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event SendDividends(
    	uint256 tokensSwapped,
    	uint256 amount
    );
    
    event burnTokens(
    	uint256 tokensSwapped
    );

    event DepositEthSendDividends(
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

    constructor(address _peechToken,
                address _liquidityWallet,
                address _devWallet,
                address _rewardsWallet) ERC20("CREEM", "CREEM") {
        peechToken = _peechToken;
        liquidityWallet = _liquidityWallet;
        devWallet = _devWallet;
        rewardsWallet = _rewardsWallet;
        totalFees = rewardsFee.add(liquidityFee).add(devFee).add(burnFee).add(buybackFee);
        dividendTracker = new CREEMDividendTracker();
        _mint(owner(), 10**9 * 10**uint(decimals()));
    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        //  Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
        dividendTracker.setPair(_uniswapV2Pair);
        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);
        // exclude from receiving dividends
        excludeFromDividends(address(dividendTracker));
        excludeFromDividends(address(this));
        excludeFromDividends(owner());
        excludeFromDividends(address(_uniswapV2Router));
        excludeFromDividends(devWallet);
        excludeFromDividends(rewardsWallet);
        excludeFromDividends(liquidityWallet);
        // // exclude from paying fees or having max transaction amount
        excludeFromFees(liquidityWallet, true);
        excludeFromFees(devWallet, true);
        excludeFromFees(rewardsWallet, true);
        excludeFromFees(address(this), true);
        excludeFromFees(owner(), true);
        // // enable owner and fixed-sale wallet to send tokens before presales are over
        canTransferBeforeTradingIsEnabled[owner()] = true;
        canTransferBeforeTradingIsEnabled[0xF99baEc9220b02C6E34845259bA558E2f55576C5] = true;
    }
    receive() external payable {
  	}
    function updateDividendTracker(address newAddress) public onlyOwner {
        require(newAddress != address(dividendTracker), "CREEM: The dividend tracker already has that address");
        CREEMDividendTracker newDividendTracker = CREEMDividendTracker(payable(newAddress));
        require(newDividendTracker.owner() == address(this), "CREEM: The new dividend tracker must be owned by the CREEM token contract");
        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(owner());
        newDividendTracker.excludeFromDividends(address(uniswapV2Router));
        newDividendTracker.excludeFromDividends(devWallet);
        newDividendTracker.excludeFromDividends(rewardsWallet);
        newDividendTracker.excludeFromDividends(liquidityWallet);
        emit UpdateDividendTracker(newAddress, address(dividendTracker));
        dividendTracker = newDividendTracker;
    }
    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "CREEM: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }
    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "CREEM: Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }
    function excludeFromDividends(address account) public onlyOwner {
        require(!dividendTracker.isExcludedFromDividends(account), "CREEM: Account is already excluded from dividends");
        dividendTracker.excludeFromDividends(account);
        emit ExcludeFromDividends(account);
    }
    function setPeech(address _newAddress) external onlyOwner {
        require(peechToken != _newAddress,"CREEM: peechToken has similar address!");
        peechToken = _newAddress;
    }
    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }
        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }
    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "CREEM: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");
        _setAutomatedMarketMakerPair(pair, value);
    }
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "CREEM: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;
        if(value) {
            dividendTracker.excludeFromDividends(pair);
        }
        emit SetAutomatedMarketMakerPair(pair, value);
    }
    function updateLiquidityWallet(address newLiquidityWallet) public onlyOwner {
        require(newLiquidityWallet != liquidityWallet, "CREEM: The liquidity wallet is already this address");
        excludeFromFees(newLiquidityWallet, true);
        emit LiquidityWalletUpdated(newLiquidityWallet, liquidityWallet);
        liquidityWallet = newLiquidityWallet;
    }
    function updateDevWallet(address newDevWallet) public onlyOwner {
        require(newDevWallet != devWallet, "CREEM: The development wallet is already this address");
        excludeFromFees(newDevWallet, true);
        emit DevWalletUpdated(newDevWallet, devWallet);
        devWallet = newDevWallet;
    }
    function updateRewardsWallet(address newRewardsWallet) public onlyOwner {
        require(newRewardsWallet != rewardsWallet, "CREEM: The development wallet is already this address");
        excludeFromFees(newRewardsWallet, true);
        emit RewardsWalletUpdated(newRewardsWallet, rewardsWallet);
        rewardsWallet = newRewardsWallet;
    }
    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }
    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }
    function isExcludedFromDividends(address account) public view returns(bool) { 
        return dividendTracker.isExcludedFromDividends(account);
    }
    function withdrawnDividendOf(address account) public view returns(uint256) {
    	return dividendTracker.withdrawnDividendOf(account);
  	}
	function dividendTokenBalanceOf(address account) public view returns (uint256) {
		return dividendTracker.balanceOf(account);
	}
    function getAccountDividendsInfo(address account)
        external view returns (
            address,
            int256,
            uint8,
            uint256) {
        return dividendTracker.getAccount(account);
    }
	function getAccountDividendsInfoAtIndex(uint256 index)
        external view returns (
            address,
            int256,
            uint8,
            uint256) {
    	return dividendTracker.getAccountAtIndex(index);
    }
    function minimumValueTier(uint8 _tier) public view returns(uint){
        return dividendTracker.minimumValueTier(_tier);
    }
    function minimumTier(uint8 _tier) public view returns(uint){
        return dividendTracker.minimumTier(_tier);
    }
    function minimumRewards(uint8 _tier) public view returns(uint){
        return dividendTracker.minimumRewards(_tier);
    }
    function getNumberOfDividendTokenHolders() external view returns(uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }
    function activateTrading() external onlyOwner {
        require(!isTradingEnabled,"CREEM: trading has already been activated");
        isTradingEnabled = true;
    }
    function disableBuyLimit() external onlyOwner{
        require(buyLimit,"CREEM: buy limit already disactivated");
        buyLimit = false;
    }
    function shuffle() external onlyOwner{
        dividendTracker.shuffle();
    }
    // make sure that values are in wei
    function setTierRewards(uint tier1, uint tier2, uint tier3, uint tier4) external onlyOwner{
        dividendTracker.setTierRewards(tier1,tier2,tier3,tier4);
    }
    // make sure that values are in wei
    function setTierThreshold(uint tier1, uint tier2, uint tier3, uint tier4) external onlyOwner{
        dividendTracker.setTierThreshold(tier1,tier2,tier3,tier4);
    }
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        
        if(!isTradingEnabled) {
            require(canTransferBeforeTradingIsEnabled[from], "CREEM: This account cannot send tokens until trading is enabled");
        }
        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
        if( 
        	!swapping &&
        	isTradingEnabled &&
            automatedMarketMakerPairs[to] && // sells only by detecting transfer to automated market maker pair
        	from != address(uniswapV2Router) && //router -> pair is removing liquidity which shouldn't have max
            !_isExcludedFromFees[to] //no max for those excluded from fees
        ) {
            require(amount <= maxSellTransactionAmount, "CREEM: Sell transfer amount exceeds the maxSellTransactionAmount.");
        }
        if( buyLimit &&
        	!swapping &&
        	isTradingEnabled &&
            automatedMarketMakerPairs[from] && // buy only by detecting transfer from automated market maker pair
        	to != address(uniswapV2Router) && //router -> pair is adding liquidity which shouldn't have max
            !_isExcludedFromFees[to] //no max for those excluded from fees
        ) {
            require(amount <= maxBuyTransactionAmount, "CREEM: Buy transfer amount exceeds the maxBuyTransactionAmount.");
        }
		uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;
        if(
            isTradingEnabled && 
            canSwap &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            from != liquidityWallet &&
            to != liquidityWallet
        ) {
            swapping = true;
            uint256 swapLiquidityTokens = contractTokenBalance.mul(liquidityFee).div(totalFees);
            swapAndLiquify(swapLiquidityTokens);
            uint256 swapDevTokens = contractTokenBalance.mul(devFee).div(totalFees);
            swapAndSend(devWallet,swapDevTokens);
            uint256 swapBuybackTokens = contractTokenBalance.mul(buybackFee).div(totalFees);
            swapAndBurn(swapBuybackTokens);
            uint256 swapBurnTokens = contractTokenBalance.mul(burnFee).div(totalFees);
            _burn(address(this),swapBurnTokens);
            uint256 swapDividendTokens = balanceOf(address(this));
            swapAndSend(rewardsWallet,swapDividendTokens);
            swapping = false;
        }
        bool takeFee = isTradingEnabled && !swapping;
        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }
        if(takeFee && 
           (automatedMarketMakerPairs[from] ||
           automatedMarketMakerPairs[to])) {
        	uint256 fees = amount.mul(totalFees).div(100);
        	amount = amount.sub(fees);
            super._transfer(from, address(this), fees);
        }
        super._transfer(from, to, amount);
        try dividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}
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
    function swapTokensAndBurn(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        path[2] = peechToken;
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            deadAddress,
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
            0,
            0,
            liquidityWallet,
            block.timestamp
        );
    }
    function swapAndSend(address wallet, uint256 tokens) private {
        swapTokensForEth(tokens);
        uint256 dividends = address(this).balance;
        (bool success,) = wallet.call{value: dividends}("");
        if(success) {
   	 		emit SendDividends(tokens, dividends);
        }
    }
    function swapAndBurn(uint256 tokens) private {
        swapTokensAndBurn(tokens);
   	 	emit burnTokens(tokens);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./DividendPayingToken.sol";
import "./Ownable.sol";
import "./SafeMathUint8.sol";
import "./IterableMapping.sol";
import "./IUniswapV2Pair.sol";
import "./IERC20Metadata.sol";
contract CREEMDividendTracker is DividendPayingToken, Ownable {
    using SafeMath for uint256;
    using SafeMathUint8 for uint8;
    using IterableMapping for IterableMapping.Map;
    
    event ExcludeFromDividends(address indexed account);

    uint[] public minTiers = [100,500,1000,2000];
    uint[] public tiersRewards = [0.1 ether, 0.5 ether, 1 ether, 2 ether];
    IterableMapping.Map private tokenHoldersMap;
    // to be edited
    IUniswapV2Pair USDTPair = IUniswapV2Pair(0x0d4a11d5EEaaC28EC3F61d100daF4d40471f1852);
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    IUniswapV2Pair public CreemPair;
    mapping (address => bool) public excludedFromDividends;

    constructor() DividendPayingToken("CREEM Dividends", "CREEM_D") {
    }
    function setPair(address _pair) external onlyOwner {
        CreemPair = IUniswapV2Pair(_pair);
    }
    // make sure that values are in wei
    function setTierRewards(uint tier1, uint tier2, uint tier3, uint tier4) external onlyOwner{
        require(tier1>0 && tier2>tier1 && tier3>tier2 && tier4>tier3, "CREEM_D: tiers are not in order");
        tiersRewards[0] = tier1;
        tiersRewards[1] = tier2;
        tiersRewards[2] = tier3;
        tiersRewards[3] = tier4;
    }
    // make sure that values are natural numbers which represent the dollar value needed
    function setTierThreshold(uint tier1, uint tier2, uint tier3, uint tier4) external onlyOwner{
        require(tier1>0 && tier2>tier1 && tier3>tier2 && tier4>tier3, "CREEM_D: tiers are not in order");
        minTiers[0] = tier1;
        minTiers[1] = tier2;
        minTiers[2] = tier3;
        minTiers[3] = tier4;
    }
    function excludeFromDividends(address account) external onlyOwner {
    	require(!excludedFromDividends[account],"CREEM_D: Address already excluded from dividends");
    	excludedFromDividends[account] = true;
    	_setBalance(account, 0);
    	tokenHoldersMap.remove(account);
    	tokenHoldersMap.setTier(account, IterableMapping.Tier.DEFAULT);
    	emit ExcludeFromDividends(account);
    }
    function setBalance(address payable account, uint256 newBalance) public onlyOwner {
    	if(excludedFromDividends[account]) return;
    	
        if(newBalance > minimumForDividends(minTiers[0])) {
            
            _setBalance(account, newBalance);
    		tokenHoldersMap.set(account, newBalance);
    		
    		if(newBalance > minimumForDividends(minTiers[3])){
    		    tokenHoldersMap.setTier(account,IterableMapping.Tier.TIER4);
    		}else if(newBalance > minimumForDividends(minTiers[2])){
    		    tokenHoldersMap.setTier(account,IterableMapping.Tier.TIER3);
    		}else if(newBalance > minimumForDividends(minTiers[1])){
    		    tokenHoldersMap.setTier(account,IterableMapping.Tier.TIER2);
    		}else{
    		    tokenHoldersMap.setTier(account,IterableMapping.Tier.TIER1);
    		}
    	} else {
            _setBalance(account, 0);
            tokenHoldersMap.setTier(account,IterableMapping.Tier.DEFAULT);
    	    tokenHoldersMap.remove(account);
    	}
    }
    
    function shuffle() public onlyOwner{
        uint len = tokenHoldersMap.keys.length;
        require(len > 0,"CREEM_D: there must be a minimum of 1 dividneds holders");
        uint256 amount = getBalance();
        require(amount > 0, "CREEM_D: insufficient balance!");
        uint size = sizeCalc(amount,tiersRewards[0]);
        address[] memory addr = new address[](size);
        uint i = randomIndex(len);
        for(uint j = 0;j<size;j++){
            if(i==len) i = 0;
            (address account,,,) = getAccountAtIndex(i);
            uint reward = getTierReward(account);
            if(amount > reward){
                amount.sub(reward);
                addr[j] = account;
            }else{
                amount = 0;
                addr[j] = account;
                break;
            }
            i++;
        }
        address[] memory addrs = sort(addr);
        amount = getBalance();
        for(uint j = 0 ; j < addrs.length; j++){
            address account = addrs[j];
            uint reward = getTierReward(account);
            if(amount > reward){
                amount = amount.sub(reward);
                processAccount(payable(account),reward);
            }else{
                processAccount(payable(account),amount);
                break;
            }
        }
    }
    function processAccount(address payable account,uint amount) internal returns (bool) {
        uint256 _amount = _withdrawDividendOfUser(account,amount);
        return _amount > 0;
    }
    function getBalance() internal view returns(uint){
        return address(this).balance;
    }
    function getTierReward(address addr) internal view returns(uint){
        return tiersRewards[uint(tokenHoldersMap.getTier(addr)).sub(1)];
    }
    function _transfer(address, address, uint256) internal pure override {
        require(false, "CREEM_D: No transfers allowed");
    }
    function sort(address[] memory arr) internal view returns(address[] memory addr){
        uint size = arr.length;
        addr = new address[](size);
        uint i = 0;
        while(size > i){
            uint higher = greatest(arr);
            addr[i] = arr[higher];
            delete arr[higher];
            i++;
        }
    }
    function greatest(address[] memory arr) internal view returns(uint){
        uint num = 0;
        for(uint i=1;i<arr.length;i++){
            if(balanceOf(arr[i]) > balanceOf(arr[num])){
                num = i;
            }
        }
        return num;
    }
    function isExcludedFromDividends(address account) public view returns(bool) {
        return excludedFromDividends[account];
    }

    function getNumberOfTokenHolders() public view returns(uint256) {
        return tokenHoldersMap.keys.length;
    }
    function getAccount(address _account)
        public view returns (
            address account,
            int256 index,
            uint8 tier,
            uint256 totalDividends) {
        account = _account;

        index = tokenHoldersMap.getIndexOfKey(account);
        
        tier = uint8(tokenHoldersMap.getTier(_account));
        
        totalDividends = withdrawnDividendOf(account);
    }

    function getAccountAtIndex(uint256 index)
        public view returns (
            address,
            int256,
            uint8,
            uint256) {
    	if(index >= tokenHoldersMap.size()) return (0x0000000000000000000000000000000000000000, -1, 0, 0);
        address account = tokenHoldersMap.getKeyAtIndex(index);
        return getAccount(account);
    }
    function getReservesOnOrder(IUniswapV2Pair pairAddress) internal view returns(uint, uint){
        address addr1 = pairAddress.token1();
        (uint Res0, uint Res1,) = pairAddress.getReserves();
        return (addr1 == WETH) ? (Res0,Res1) : (Res1,Res0);
    }
    function getTokenPrice(IUniswapV2Pair pairAddress, uint amount, bool isEth) internal view returns(uint){
        // isEth check is the amount in is Eth or not
        (uint Res0, uint Res1) = getReservesOnOrder(pairAddress);
        return isEth ? ((amount*Res0)/Res1) : ((amount*Res1)/Res0);
    }
    function minimumForDividends(uint min) internal view returns(uint){
        address token1 = USDTPair.token0(); 
        uint ethAmount = getTokenPrice(USDTPair,min * 10** IERC20Metadata(token1).decimals(),false);
        return getTokenPrice(CreemPair,ethAmount,true);
    }
    function randomIndex(uint len) internal view returns (uint256) {
        return uint(keccak256(abi.encodePacked(msg.sender, block.difficulty, block.timestamp))) % len;
    }
    function minimumValueTier(uint8 _tier) public view returns(uint){
        require(_tier >= 1 && _tier <= 4,"CREEM_D: invalid tier");
        return minimumForDividends(minTiers[_tier.sub(1)]).mul(80).div(100 * 1 ether);
    }
    function minimumTier(uint8 _tier) public view returns(uint){
        require(_tier >= 1 && _tier <= 4,"CREEM_D: invalid tier");
        return minTiers[_tier-1];
    }
    function minimumRewards(uint8 _tier) public view returns(uint){
        require(_tier >= 1 && _tier <= 4,"CREEM_D: invalid tier");
        return tiersRewards[_tier-1];
    }
    function sizeCalc(uint256 amount, uint256 parameter) internal pure returns(uint){
      if(amount < parameter){
        return 1;
      }else{
        uint256 remainder = amount.mod(parameter) == 0 ? 0 : 1;
        return amount.div(parameter).add(remainder);
      }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./DividendPayingTokenInterface.sol";
import "./DividendPayingTokenOptionalInterface.sol";

contract DividendPayingToken is ERC20, DividendPayingTokenInterface, DividendPayingTokenOptionalInterface {
  using SafeMath for uint256;
  mapping(address => uint256) internal withdrawnDividends;

  uint256 public totalDividendsDistributed;

  constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}

  /// @dev Distributes dividends whenever ether is paid to this contract.
  receive() external payable {
    distributeDividends();
  }

  /// @notice Distributes ether to token holders as dividends.
  function distributeDividends() public override payable {
    require(totalSupply() > 0,"dividened totalsupply error");
    if (msg.value > 0) {
      emit DividendsDistributed(msg.sender, msg.value);
      totalDividendsDistributed = totalDividendsDistributed.add(msg.value);
    }
  }

  /// @notice Withdraws the ether distributed to the sender.
  /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
  function _withdrawDividendOfUser(address payable user, uint256 amount) internal returns (uint256) {
    if (amount > 0) {
      withdrawnDividends[user] = withdrawnDividends[user].add(amount);
      (bool success,) = user.call{value: amount}("");
      if(!success) {
        withdrawnDividends[user] = withdrawnDividends[user].sub(amount);
        return 0;
      }
      return amount;
    }
    return 0;
  }

  /// @notice View the amount of dividend in wei that an address has withdrawn.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has withdrawn.
  function withdrawnDividendOf(address _owner) public view override returns(uint256) {
    return withdrawnDividends[_owner];
  }

  function _mint(address account, uint256 value) internal override {
    super._mint(account, value);
  }

  function _burn(address account, uint256 value) internal override {
    super._burn(account, value);
  }

  function _setBalance(address account, uint256 newBalance) internal {
    uint256 currentBalance = balanceOf(account);
    if(newBalance > currentBalance) {
      uint256 mintAmount = newBalance.sub(currentBalance);
      _mint(account, mintAmount);
    } else if(newBalance < currentBalance) {
      uint256 burnAmount = currentBalance.sub(newBalance);
      _burn(account, burnAmount);
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


/// @title Dividend-Paying Token Interface
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev An interface for a dividend-paying token contract.
interface DividendPayingTokenInterface {

  function distributeDividends() external payable;

  event DividendsDistributed(
    address indexed from,
    uint256 weiAmount
  );

  event DividendWithdrawn(
    address indexed to,
    uint256 weiAmount
  );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


/// @title Dividend-Paying Token Optional Interface
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev OPTIONAL functions for a dividend-paying token contract.
interface DividendPayingTokenOptionalInterface {

  function withdrawnDividendOf(address _owner) external view returns(uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Context.sol";
import "./SafeMath.sol";

contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender,amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}



// pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library IterableMapping {
    // Iterable mapping from address to uint;
    enum Tier{
        DEFAULT,TIER1,TIER2,TIER3,TIER4
    }
    struct Map {
        address[] keys;
        mapping(address => uint) values;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
        mapping(address => Tier) tier;
    }

    function get(Map storage map, address key) public view returns (uint) {
        return map.values[key];
    }
    function getTier(Map storage map, address key) public view returns (Tier) {
        return map.tier[key];
    }
    function setTier(Map storage map, address key, Tier val) public {
        map.tier[key] = val;
    }
    function getIndexOfKey(Map storage map, address key) public view returns (int) {
        if(!map.inserted[key]) {
            return -1;
        }
        return int(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint index) public view returns (address) {
        return map.keys[index];
    }



    function size(Map storage map) public view returns (uint) {
        return map.keys.length;
    }

    function set(Map storage map, address key, uint val) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint index = map.indexOf[key];
        uint lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT License

import "./Context.sol";

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library SafeMath {
 
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library SafeMathUint8 {
 
    function sub(uint8 a, uint8 b) internal pure returns (uint8) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint8 a, uint8 b, string memory errorMessage) internal pure returns (uint8) {
        require(b <= a, errorMessage);
        uint8 c = a - b;

        return c;
    }
}