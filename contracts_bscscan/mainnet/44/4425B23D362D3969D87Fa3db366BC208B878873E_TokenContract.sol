// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;
 
import "./Libraries.sol";
 
contract TokenContract is Ownable, IBEP20{

    // Basic Contract Info
    uint256 private constant _totalSupply = 1000000000000*10**_tokenDecimals; // 1 Trillion
    uint8 private constant _tokenDecimals=9;
    string private constant _tokenName="Name";
    string private constant _tokenSymbol="Symbol";
    // Boolean variables
    bool private _tradingEnabled;
    bool private _inSwap;
    bool public swapEnabled;
    bool public rewardsEnabled;
    bool private _addingLP;
    // Public Addresses
    address public defaultRewardToken=0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c; // BTC
    address public _pancakeRouterAddress=0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address public burnWallet = 0x000000000000000000000000000000000000dEaD;
    // Router addresses
    IPancakeRouter02 private _pancakeRouter;
    address public pancakePairAddress;
    // Events
    event OwnerExcludeFromFees(address account,bool enabled);
    event OwnerBlacklistWallet(address account,bool enabled);
    event OwnerFixStuckBNB(uint256 amountWei);
    event OwnerSetIncludedToRewards(address account);
    event OwnerSetExcludedFromRewards(address account);
    event OwnerSetRewardSetting(uint256 minPeriod,uint256 minDistribution);
    event OwnerSetRewardToken(address newReward);
    event OwnerSwitchRewardsEnabled(bool enabled);
    event OwnerSwitchSwapEnabled(bool enabled);
    event OwnerUpdateSwapThreshold(uint256 swapThreshold);
    event OwnerUpdateSecondaryTaxes(uint256 liquidity,uint256 rewards,uint256 marketing);
    event OwnerUpdateTaxes(uint256 buyTax,uint256 sellTax);
    event OwnerEnableTrading(uint256 timestamp);
    event LiquidityAdded(uint256 amountTokens,uint256 amountBNB);
    // Mappings
    address[] shareholders; // Store reward users
    mapping(address => uint256) shareholderIndexes;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address=>bool) private _excludeFromFees;
    mapping(address=>bool) private _excludeFromRewards;
    mapping(address=>bool) private _automatedMarketMakers;
    mapping(address=>Holder) private _holders;
    mapping(address=>bool) private _blacklisted;
    uint256 private _nonce;
    uint256 currentIndex;
    // Structs
    Tax private _tax;
    Limit private _limit;
    Tracker private _tracker;
    Rewards private _rewards;
    struct Tracker {
        uint256 profitPerToken;
        uint256 totalTokensHeld;
        uint256 totalMarketingBNB;
        uint256 totalLiquidityBNB;
        uint256 totalRewardBNB;
        uint256 totalRewardBNBPayout;
    }
    struct Limit {
        // Tax limits
        uint8 maxBuyTax;
        uint8 maxSellTax;
        // Swap variables
        uint256 maxSwapThreshold;
        uint256 swapThreshold;
        // Transaction limits
        uint256 maxWalletSize;
        uint256 maxTxSize;
    }
    struct Tax {
        // Primary Taxes
        uint8 buyTax;
        uint8 sellTax;
        // Secondary Taxes
        uint8 liquidityTax;
        uint8 rewardsTax;
        uint8 marketingTax;
    }
    struct Holder {
        uint256 alreadyPaid;
        uint256 toBePaid;
        uint256 rewardsAmount;
        uint256 lastClaim;
    }
    struct Rewards{
        uint256 minPeriod;
        uint256 minDistribution;
        uint256 gas;
    }
    modifier LockTheSwap {
        _inSwap=true;
        _;
        _inSwap=false;
    }
    constructor() {
         // Initialize Pancake Pair
        _pancakeRouter=IPancakeRouter02(_pancakeRouterAddress);
        pancakePairAddress=IPancakeFactory(_pancakeRouter.factory()).createPair(address(this),_pancakeRouter.WETH());
        _approve(address(this),address(_pancakeRouter),type(uint256).max);
        _automatedMarketMakers[pancakePairAddress]=true;
        // Exclude from fees & rewards
        _excludeFromFees[address(this)]=_excludeFromFees[msg.sender]=true;
        _excludeFromRewards[address(this)]=_excludeFromRewards[pancakePairAddress]=_excludeFromRewards[burnWallet]=true;
        // Mint _totalSupply to owner address
        _updateBalance(owner(),_totalSupply);
        emit Transfer(owner(),address(this),_totalSupply);
        // Set initial taxes
        _tax.buyTax=12; _limit.maxBuyTax=20;
        _tax.sellTax=15; _limit.maxSellTax=33;
        _tax.liquidityTax=20; _tax.rewardsTax=50; _tax.marketingTax=30;
        _limit.swapThreshold=_totalSupply/1000; _limit.maxSwapThreshold=_totalSupply/100;
        // Set initial reward settings
        _rewards.minPeriod=1 hours;
        rewardsEnabled=swapEnabled=true;
        _rewards.gas=500000;
        // Set transaction limits
        _limit.maxWalletSize=_totalSupply/100*3; _limit.maxTxSize=_totalSupply/100; // 3% maxWallet  1% maxTx
    }
///////// Transfer Functions \\\\\\\\\
    function _transfer(address sender,address recipient,uint256 amount) private {
        require(sender!=address(0)&&recipient!=address(0),"Cannot be address(0).");
        bool isBuy=_automatedMarketMakers[sender];
        bool isSell=_automatedMarketMakers[recipient];
        bool isExcluded=_excludeFromFees[sender]||_excludeFromFees[recipient]||_addingLP;
        if(isExcluded)_transferExcluded(sender,recipient,amount);
        else {
            require(_tradingEnabled);
            if(isBuy)_buyTokens(sender,recipient,amount);
            else if(isSell) {
                // Swap & Liquify
                if(!_inSwap&&swapEnabled)_swapAndLiquify();
                // Rewards
                if(_shouldProcessRewards())_processRewards(_rewards.gas);
                _sellTokens(sender,recipient,amount);
            } else {
                // P2P Transfer
                require(_balances[recipient]+amount<=_limit.maxWalletSize);
                _transferExcluded(sender,recipient,amount);
            }
        }
    }
    function _buyTokens(address sender,address recipient,uint256 amount) private {
        require(amount<=_limit.maxTxSize);
        require(_balances[recipient]+amount<=_limit.maxWalletSize);
        uint256 tokenTax=amount*_tax.buyTax/100;
        _transferIncluded(sender,recipient,amount,tokenTax);
    }
    function _sellTokens(address sender,address recipient,uint256 amount) private {
        require(amount<=_limit.maxTxSize);
        uint256 tokenTax=amount*_tax.sellTax/100;
        _transferIncluded(sender,recipient,amount,tokenTax);
    }
    function _updateBalance(address account,uint256 newBalance) private {
        _balances[account]=newBalance;
        if(!_excludeFromRewards[account])_setShareholder(account,_balances[account]);
        else return;
    }
    function _transferExcluded(address sender,address recipient,uint256 amount) private {
        _updateBalance(sender,_balances[sender]-amount);
        _updateBalance(recipient,_balances[recipient]+amount);
        emit Transfer(sender,recipient,amount);
    }
    function _transferIncluded(address sender,address recipient,uint256 amount,uint256 tokenTax) private {
        uint256 newAmount=amount-tokenTax;
        _updateBalance(sender,_balances[sender]-amount);
        _updateBalance(address(this),_balances[address(this)]+tokenTax);
        _updateBalance(recipient,_balances[recipient]+newAmount);
        emit Transfer(sender,recipient,newAmount);
    }
    function _swapAndLiquify() private LockTheSwap{
        uint256 contractTokenBalance=_balances[address(this)];
        uint256 toSwap;
        if(contractTokenBalance >= _limit.maxSwapThreshold){
            toSwap = _limit.maxSwapThreshold;            
        }else{
            toSwap = contractTokenBalance;
        }
        
        uint256 totalLPTokens=toSwap*_tax.liquidityTax/100;
        uint256 tokensLeft=toSwap-totalLPTokens;
        uint256 LPTokens=totalLPTokens/2;
        uint256 LPBNBTokens=totalLPTokens-LPTokens;
        toSwap=tokensLeft+LPBNBTokens;
        uint256 oldBNB=address(this).balance;
        _swapTokensForBNB(toSwap);
        uint256 newBNB=address(this).balance-oldBNB;
        uint256 LPBNB=(newBNB*LPBNBTokens)/toSwap;
        _addLiquidity(LPTokens,LPBNB);
        uint256 remainingBNB=address(this).balance-oldBNB;
        _distributeBNB(remainingBNB);
    }
    function _distributeBNB(uint256 amountWei) private {
        uint256 rewardBNB=amountWei*_tax.rewardsTax/100;
        uint256 marketingBNB=amountWei-rewardBNB;
            _tracker.totalRewardBNB+=rewardBNB;
            _tracker.totalMarketingBNB+=marketingBNB;
            _tracker.profitPerToken+=(_tracker.totalRewardBNB*(2**64))/_tracker.totalTokensHeld;
        (bool success, /* bytes memory data */) = payable(owner()).call{value: marketingBNB, gas: 30000}("");
        require(success, "receiver rejected BNB transfer");
    }
    function _swapBNBtoRWRD(address account, uint256 amountWei) private {
        bool swapSuccess;
        IBEP20 RWRD = IBEP20(defaultRewardToken);
        
        address[] memory path = new address[](2);
        path[0] = address(_pancakeRouter.WETH());
        path[1] = address(RWRD);

            //try to swap for tokens, if it fails (bad contract, or whatever other reason, send BNB)
            try _pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountWei}(
                0,
                path,
                account,
                block.timestamp
                ){swapSuccess = true;}
            catch {swapSuccess = false;}
            // if the swap failed, send them their BNB instead
            if(!swapSuccess){(bool success,) = account.call{value: amountWei, gas: 3000}("");
                if(!success) {_holders[account].alreadyPaid = _holders[account].alreadyPaid-(amountWei);}
        
        }
    }

///////// Rewards Functions \\\\\\\\\ 
    // allows a user to manually claim their tokens.
    function claim() external {
          _distributeRewards(msg.sender);
    }
    function _excludeAccountFromRewards(address account) private {
        require(!_excludeFromRewards[account], "Already excluded");
        _excludeFromRewards[account]=true;
        _setShareholder(account,0);
    } 
    function _includeAccountToRewards(address account) private {
        require(_excludeFromRewards[account], "Address is not excluded");
        _excludeFromRewards[account]=false;
        _setShareholder(account,_balances[account]);
    } 
    function _setShareholder(address account, uint256 amount) private { 
        if(amount > 0 && _holders[account].rewardsAmount == 0){
            _addShareholder(account);
        }
        if(amount == 0 && _holders[account].toBePaid > 0){
            _removeShareholder(account);
        }
        _tracker.totalTokensHeld = _tracker.totalTokensHeld-(_holders[account].rewardsAmount)+(amount);
        _holders[account].rewardsAmount = amount;
    }
    function _shouldProcessRewards() private view returns (bool) {
        return msg.sender != pancakePairAddress
        && !_inSwap
        && rewardsEnabled
        && _tracker.totalRewardBNB > 0;
    }
    function _processRewards(uint256 gas) private {
        uint256 shareholderCount = shareholders.length;
        if(shareholderCount == 0) { return; }
        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();
        uint256 iterations = 0;
        while(gasUsed < gas && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount) {
                currentIndex = 0;
            }
            if(_shouldDistribute(shareholders[currentIndex])) {
                _distributeRewards(shareholders[currentIndex]);
            }
            gasUsed = gasUsed+(gasLeft-(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }
    function _shouldDistribute(address account) private view returns (bool) {
        return _holders[account].lastClaim + _rewards.minPeriod < block.timestamp
        && _getUnpaidReward(account) > _rewards.minDistribution;
    } 
    function _distributeRewards(address account) private {
        if(_holders[account].rewardsAmount == 0){ return; }
        uint256 amountWei = _getUnpaidReward(account);
        if(amountWei > 0){
            _tracker.totalRewardBNBPayout+=amountWei;
            _holders[account].lastClaim = block.timestamp;
            _holders[account].alreadyPaid+=amountWei;
            _holders[account].toBePaid=_calculateRewards(account,_holders[account].rewardsAmount);
            _tracker.totalRewardBNB-=amountWei;
            _swapBNBtoRWRD(account, amountWei);
        }
    }
    function _getUnpaidReward(address account) private view returns (uint256) {
        if(_holders[account].rewardsAmount == 0){ return 0; }
        uint256 toBePaid = _calculateRewards(account,_holders[account].rewardsAmount);
        uint256 alreadyPaid = _holders[account].alreadyPaid;
        if(toBePaid <= alreadyPaid){ return 0; }
        return toBePaid-(alreadyPaid);
    }
    function _calculateRewards(address account,uint256 amount) private view returns (uint256) {
        return _excludeFromRewards[account]?0:amount*_tracker.profitPerToken/(2**64);
    }
    function _addShareholder(address shareholder) private {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }
    function _removeShareholder(address shareholder) private {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
///////// Owner Functions \\\\\\\\\
    function ownerEnableTrading() public onlyOwner {
        require(!_tradingEnabled);
        _tradingEnabled=true;
        emit OwnerEnableTrading(block.timestamp);
    }
    function ownerUpdatePrimaryTaxes(uint8 buyTax,uint8 sellTax) public onlyOwner {
        require(buyTax<=_limit.maxBuyTax&&sellTax<=_limit.maxSellTax);
        _tax.buyTax=buyTax;
        _tax.sellTax=sellTax;
        emit OwnerUpdateTaxes(buyTax,sellTax);
    }
    function ownerUpdateSecondaryTaxes(uint8 liquidity,uint8 rewards,uint8 marketing) public onlyOwner {
        require(liquidity+rewards+marketing==100);
        _tax.liquidityTax=liquidity;
        _tax.rewardsTax=rewards;
        _tax.marketingTax=marketing;
        emit OwnerUpdateSecondaryTaxes(liquidity,rewards,marketing);
    }
    function ownerUpdateSwapThreshold(uint256 swapThreshold, uint256 maxSwapThreshold) public onlyOwner {
        require(swapThreshold*10**_tokenDecimals>=1&&maxSwapThreshold*10**_tokenDecimals<=_totalSupply/100);
        _limit.swapThreshold=swapThreshold;
        emit OwnerUpdateSwapThreshold(swapThreshold);
    }
    function ownerSwitchSwapEnabled(bool enabled) public onlyOwner {
        swapEnabled=enabled;
        emit OwnerSwitchSwapEnabled(enabled);
    }
    function ownerSwitchRewardsEnabled(bool enabled) public onlyOwner {
        rewardsEnabled=enabled;
        emit OwnerSwitchRewardsEnabled(enabled);
    }
    function ownerSetRewardSettings(uint256 minPeriod, uint256 minDistribution) public onlyOwner{
        _rewards.minPeriod = minPeriod;
        _rewards.minDistribution = minDistribution;
        emit OwnerSetRewardSetting(minPeriod, minDistribution);
    }
    function ownerSetRewardToken(address newReward) public onlyOwner{
        defaultRewardToken = newReward;
        emit OwnerSetRewardToken(newReward);
    }
    function ownerSetExcludeFromRewards(address account) public onlyOwner{
        _excludeAccountFromRewards(account);
        emit OwnerSetExcludedFromRewards(account);
    }
    function ownerSetIncludedToRewards(address account) public onlyOwner{
        _includeAccountToRewards(account);
        emit OwnerSetIncludedToRewards(account);
    }
    function ownerExcludeFromFees(address account,bool enabled) public onlyOwner {
        _excludeFromFees[account]=enabled;
        emit OwnerExcludeFromFees(account,enabled);
    }
    function ownerWithdrawStrandedToken(address strandedToken) public onlyOwner {
        // Cannot withdraw this token, or LP-token from contract
        require(strandedToken!=pancakePairAddress&&strandedToken!=address(this));
        IBEP20 token=IBEP20(strandedToken);
        token.transfer(owner(), token.balanceOf(address(this)));
    }
    function ownerWithdrawBNB() public onlyOwner {
        (bool success,) = msg.sender.call{value: (address(this).balance)}("");
        require(success);
    }

///////// Liquidity Functions \\\\\\\\\
    function _addLiquidity(uint256 amountTokens,uint256 amountBNB) private {
        _tracker.totalLiquidityBNB+=amountBNB;
        _addingLP=true;
        _pancakeRouter.addLiquidityETH{value: amountBNB}(
            address(this),
            amountTokens,
            0,
            0,
            address(this),
            block.timestamp
        );
        _addingLP=false;
        emit LiquidityAdded(amountTokens,amountBNB);
    }
    function _swapTokensForBNB(uint256 amount) private {
        address[] memory path=new address[](2);
        path[0]=address(this);
        path[1] = _pancakeRouter.WETH();
        _pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
///////// IBEP20 \\\\\\\\\
    function _approve(address owner, address spender, uint256 amount) private {
        require((owner != address(0) && spender != address(0)), "Owner/Spender address cannot be 0.");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        uint256 allowance_ = _allowances[sender][msg.sender];
        _transfer(sender, recipient, amount);
        require(allowance_ >= amount);
        _approve(sender, msg.sender, allowance_ - amount);
            emit Transfer(sender, recipient, amount);
        return true;
    }
    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function allowance(address owner_, address spender) external view override returns (uint256) {
        return _allowances[owner_][spender];
    }
    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }
    function name() external pure override returns (string memory) {
        return _tokenName;
    }
    function symbol() external pure override returns (string memory) {
        return _tokenSymbol;
    }
    function totalSupply() external pure override returns (uint256) {
        return _totalSupply;
    }
    function decimals() external pure override returns (uint8) {
        return _tokenDecimals;
    }
    function getOwner() external view override returns (address) {
        return owner();
    }
    receive() external payable {
        // Only owner & router can send BNB to address
        require(msg.sender==owner()||msg.sender==_pancakeRouterAddress);
    }
}