/**
TG: https://t.me/GLOW_Token_Official
Website: https://glowtoken.online/
Author: @DaisyOfficialTG
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
 
import "./Libraries.sol";
 
contract GlowTokenV2 is Ownable, IBEP20{
    using Address for address;
 
    // Basic Contract Info
    uint256 private constant _totalSupply = 1_000_000_000_000_000*10**9; // 1 Quad
    uint8 private constant _tokenDecimals=9;
    string private constant _tokenName="Glow Token V2";
    string private constant _tokenSymbol="Glow V2";
    //Liquidity Variables
    uint256 public liquidityUnlockSeconds;
    uint256 private _fixedLPLockTime=60 days;
    // Boolean variables
    bool private _tradingEnabled;
    bool private _inSwap;
    bool public swapEnabled;
    bool public lotteryEnabled;
    bool public rewardsEnabled;
    bool private _addingLP;
    bool private _removingLP;
    // Team Addresses
    address public coFounder_1=0x8e68D30Ae71E32bA1e13cDce606838f70ca83C3C;
    address public coFounder_2=0xf545d69BC89711CA855e6c24fd7fC935ce5B604B;
    address public coFounder_3=0x09B658C800Bb644a51A3d6eA88D5714eb4ACe4E7;
    address public VPCustomerRelations=0x999C8324f34b40437d2625ad4f79D801F15138Cf;
    address public VPOperations=0xC5D74A9bA8ba15e62c1d5C814ce3b8aC0dA686f7;
    address public headDevelopment=0x0209564AcaF3c354BB681E27b018fdcFD8E109d3;
    address public developer_1=0xB4e06da1aB74E1742b73Da6a1B9D0eFBb761119b;
    address public developer_2=0x66FF2BF3937b4a196479Df61235f3Ed4118C2bD7;
    address public leadDeveloper=0x4f509E30853F77b03a45f6e41F8273e82B55C174;
    // Public Addresses
    address public defaultRewardToken=0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56; // BUSD
    address public _pancakeRouterAddress=0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address public burnWallet = 0x000000000000000000000000000000000000dEaD;
    address public airDropper;
    // Router addresses
    IPancakeRouter02 private _pancakeRouter;
    address public pancakePairAddress;
    // Events
    event OwnerUpdateDefaultRewardToken(address defaultRewardToken);
    event OwnerUpdatePancakePair(address pair,address router);
    event OwnerUpdateAMM(address AMM,bool enabled);
    event OwnerLockTeamWallet(address account,bool locked);
    event OwnerExcludeFromFees(address account,bool enabled);
    event OwnerBlacklistWallet(address account,bool enabled);
    event OwnerFixStuckBNB(uint256 amountWei);
    event OwnerExtendLPLock(uint256 timeSeconds);
    event OwnerBoostContract(uint256 amountWei);
    event OwnerSetIncludedToLottery(address account);
    event OwnerSetExcludedFromLottery(address account);
    event OwnerSetIncludedToRewards(address account);
    event OwnerSetExcludedFromRewards(address account);
    event OwnerSetRewardSetting(uint256 minPeriod,uint256 minDistribution);
    event OwnerSetLotterySetting(uint256 minPeriod,uint256 percentage,uint256 minBalance);
    event OwnerSwitchRewardsEnabled(bool enabled);
    event OwnerSwitchLotteryEnabled(bool enabled);
    event OwnerSwitchSwapEnabled(bool enabled);
    event OwnerTriggerSwap(uint256 swapThreshold,bool ignoreLimits);
    event OwnerTriggerLottery(uint256 percentage);
    event OwnerUpdateSwapThreshold(uint256 swapThreshold);
    event OwnerUpdateSecondaryTaxes(uint256 liquidity,uint256 lottery,uint256 charity,uint256 rewards,uint256 marketing);
    event OwnerUpdateTaxes(uint256 buyTax,uint256 sellTax);
    event OwnerEnableTrading(uint256 timestamp);
    event OwnerRemoveLPPercent(uint256 LPPercent);
    event OwnerReleaseLP(uint256 LPPercent);
    event OwnerCreateLP(uint256 amountTokens,uint256 amountBNB);
    event OwnerSetAirDropper(address airDropper);
    event LiquidityAdded(uint256 amountTokens,uint256 amountBNB);
    event SetCustomRewardToken(address account,address rewardToken);
    // Mappings
    address[] holders; // Store lottery users
    address[] shareholders; // Store reward users
    mapping(address => uint256) holderIndexes; 
    mapping(address => uint256) shareholderIndexes;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address=>bool) private _excludeFromFees;
    mapping(address=>bool) private _excludeFromRewards;
    mapping(address=>bool) private _excludeFromLottery;
    mapping(address=>bool) private _automatedMarketMakers;
    mapping(address=>Holder) private _holders;
    mapping(address=>bool) private _blacklisted;
    // Lock & unlock team wallets only
    mapping(address=>bool) private _teamWalletLock;
    uint256 private _nonce;
    uint256 currentIndex;
    // Structs
    Tax private _tax;
    Limit private _limit;
    Tracker private _tracker;
    Lottery private _lottery;
    Rewards private _rewards;
    struct Tracker {
        uint256 profitPerToken;
        uint256 totalTokensHeld;
        uint256 totalMarketingBNB;
        uint256 totalLotteryBNB;
        uint256 totalCharityBNB;
        uint256 totalLiquidityBNB;
        uint256 totalRewardBNB;
        uint256 totalRewardBNBPayout;
    }
    struct Limit {
        // Tax limits
        uint8 maxBuyTax;
        uint8 maxSellTax;
        // Swap variables
        uint8 maxSwapThreshold;
        uint8 swapThreshold;
        // Transaction limits
        uint256 maxWalletSize;
        uint256 maxSellSize;
    }
    struct Tax {
        // Primary Taxes
        uint8 buyTax;
        uint8 sellTax;
        // Secondary Taxes
        uint8 liquidityTax;
        uint8 lotteryTax;
        uint8 charityTax;
        uint8 rewardsTax;
        uint8 marketingTax;
    }
    struct Holder {
        bool hasCustomRewardToken;
        address customRewardToken;
        uint256 alreadyPaid;
        uint256 toBePaid;
        uint256 tokenLock;
        uint256 lotteryAmount;
        uint256 rewardsAmount;
        uint256 lastClaim;
    }
    struct Lottery{
        uint256 percentage;
        uint256 lastLottery;
        uint256 minPeriod;
        uint256 minBalance;
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
        // Mint _totalSupply to address
        _updateBalance(address(this),_totalSupply);
        emit Transfer(address(0),address(this),_totalSupply);
        // Exclude from fees & rewards
        _excludeFromFees[address(this)]=_excludeFromFees[msg.sender]=true;
        _excludeFromRewards[address(this)]=_excludeFromRewards[pancakePairAddress]=_excludeFromRewards[burnWallet]=true;
        _excludeFromLottery[address(this)]=_excludeFromLottery[pancakePairAddress]=_excludeFromLottery[burnWallet]=true;
        // Initialize Pancake Pair
        _pancakeRouter=IPancakeRouter02(_pancakeRouterAddress);
        pancakePairAddress=IPancakeFactory(_pancakeRouter.factory()).createPair(address(this),_pancakeRouter.WETH());
        _approve(address(this),address(_pancakeRouter),type(uint256).max);
        _automatedMarketMakers[pancakePairAddress]=true;
        // Set initial taxes
        _tax.buyTax=_limit.maxBuyTax=15;
        _tax.sellTax=_limit.maxSellTax=15;
        _tax.liquidityTax=_tax.lotteryTax=_tax.charityTax=_tax.rewardsTax=_tax.marketingTax=20;
        _limit.swapThreshold=_limit.maxSwapThreshold=50;
        // Set initial lottery & reward settings
        _lottery.percentage=100;
        _lottery.minPeriod=_rewards.minPeriod=1 hours;
        lotteryEnabled=rewardsEnabled=swapEnabled=true;
        _rewards.gas=500000;
        // Set transaction limits
        _limit.maxWalletSize=_limit.maxSellSize=_totalSupply/100; // 1 %
    }
///////// Transfer Functions \\\\\\\\\
    function _transfer(address sender,address recipient,uint256 amount) private {
        require(sender!=address(0)&&recipient!=address(0),"Cannot be address(0).");
        bool isBuy=_automatedMarketMakers[sender];
        bool isSell=_automatedMarketMakers[recipient];
        bool isExcluded=_excludeFromFees[sender]||_excludeFromFees[recipient]||_addingLP||_removingLP;
        if(isExcluded)_transferExcluded(sender,recipient,amount);
        else {
            require(_tradingEnabled);
            if(isBuy)_buyTokens(sender,recipient,amount);
            else if(isSell) {
                // Swap & Liquify
                if(!_inSwap&&swapEnabled)_swapAndLiquify(_limit.swapThreshold,false);
                // Lottery
                if(_shouldSendLottery())_sendLotteryReward(_lottery.percentage);
                // Rewards
                if(_shouldProcessRewards())_processRewards(_rewards.gas);
                _sellTokens(sender,recipient,amount);
            } else {
                // P2P Transfer
                require(!_blacklisted[sender]&&!_blacklisted[recipient]);
                require(!_teamWalletLock[sender]&&!_teamWalletLock[recipient]);
                require(_balances[recipient]+amount<=_limit.maxWalletSize);
                _transferExcluded(sender,recipient,amount);
            }
        }
    }
    function _buyTokens(address sender,address recipient,uint256 amount) private {
        require(!_blacklisted[recipient]);
        // Team wallet must be unlocked to buy.
        require(!_teamWalletLock[recipient]);
        require(_balances[recipient]+amount<=_limit.maxWalletSize);
        uint256 tokenTax=amount*_tax.buyTax/100;
        _transferIncluded(sender,recipient,amount,tokenTax);
    }
    function _sellTokens(address sender,address recipient,uint256 amount) private {
        require(!_blacklisted[sender]);
        // Team wallet must be unlocked to sell.
        require(!_teamWalletLock[sender]);
        require(amount<=_limit.maxSellSize);
        uint256 tokenTax=amount*_tax.sellTax/100;
        _transferIncluded(sender,recipient,amount,tokenTax);
    }
    function _updateBalance(address account,uint256 newBalance) private {
        _balances[account]=newBalance;
        if(!_excludeFromRewards[account])_setShareholder(account,_balances[account]);
        if(!_excludeFromLottery[account])_setHolder(account,_balances[account]);
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
    function _swapAndLiquify(uint8 swapThreshold,bool ignoreLimits) private LockTheSwap{
        uint256 contractTokens=_balances[address(this)];
        uint256 toSwap=swapThreshold*_balances[pancakePairAddress]/1000;
        if(contractTokens<toSwap)
            if(ignoreLimits)
                toSwap=contractTokens;
            else return;
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
        uint256 charityBNB=amountWei*_tax.charityTax/100;
        uint256 lotteryBNB=amountWei*_tax.lotteryTax/100;
        uint256 rewardBNB=amountWei*_tax.marketingTax/100;
        uint256 marketingBNB=amountWei-(charityBNB+lotteryBNB+rewardBNB);
        if(_tracker.totalTokensHeld==0)_tracker.totalMarketingBNB+=(charityBNB+lotteryBNB+rewardBNB+marketingBNB);
        else {
            _tracker.totalCharityBNB+=charityBNB;
            _tracker.totalLotteryBNB+=lotteryBNB;
            _tracker.totalRewardBNB+=rewardBNB;
            _tracker.totalMarketingBNB+=marketingBNB;
            _tracker.profitPerToken+=(_tracker.totalRewardBNB*(2**64))/_tracker.totalTokensHeld;
        }
    }
    function _swapBNBtoRWRD(address account, uint256 amountWei) private {
        bool swapSuccess;bool buyNoFeesSuccess;
        IBEP20 RWRD = IBEP20(defaultRewardToken);
        // check if holder has a custom reward set
        if(_holders[account].hasCustomRewardToken){
            RWRD = IBEP20(_holders[account].customRewardToken);
        }
        address[] memory path = new address[](2);
        path[0] = address(_pancakeRouter.WETH());
        path[1] = address(RWRD);
        if(RWRD == IBEP20(address(this))){ // If reward is this token, buy with no fees
            bool prevExclusion = _excludeFromFees[account]; // ensure we don't remove exclusions if the current wallet is already excluded
            _excludeFromFees[msg.sender] = true;
            //try to swap for tokens, if it fails (bad contract, or whatever other reason, send BNB)
            try _pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountWei}(
                0,
                path,
                account,
                block.timestamp
            ){buyNoFeesSuccess = true;}
            catch {buyNoFeesSuccess = false;}
            _excludeFromFees[msg.sender] = prevExclusion; // set value to match original value
            // if the swap failed, send them their BNB instead
            if(!buyNoFeesSuccess){(bool success,) = account.call{value: amountWei, gas: 3000}("");
                if(!success) {_holders[account].alreadyPaid = _holders[account].alreadyPaid-(amountWei);}
                }
        }else { //
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
    }
///////// Lottery Functions \\\\\\\\\
    function _shouldSendLottery() private view returns (bool) {
        return msg.sender!=pancakePairAddress
        && !_inSwap
        && lotteryEnabled
        && _lottery.lastLottery+_lottery.minPeriod<=block.timestamp
        && _tracker.totalLotteryBNB>0;
    }
    function _excludeAccountFromLottery(address account) private {
        require(!_excludeFromLottery[account],"Already excluded");
        _excludeFromLottery[account]=true;
        _setHolder(account,0);
    } 
    function _includeAccountToLottery(address account) private {
        require(_excludeFromLottery[account],"Address is not excluded");
        _excludeFromLottery[account]=false;
        _setHolder(account,_balances[account]);
    }
    function _random() public view returns (uint) {
        uint r=uint(uint256(keccak256(abi.encodePacked(block.difficulty,block.timestamp,_nonce)))%holders.length);
        return r;
    }
    function _sendLotteryReward(uint256 percentage) private returns (bool) {
        uint rand = _random();
        while(_balances[holders[rand]]< _lottery.minBalance){
            rand = _random();
        }
        address payable winningAddress = payable(holders[rand]);
        uint256 amountWei = _tracker.totalLotteryBNB*percentage/100;
        _swapBNBtoRWRD(winningAddress, amountWei);
        _tracker.totalLotteryBNB-=amountWei;
        _lottery.lastLottery = block.timestamp;
        return true;
    }
    function _setHolder(address account, uint256 amount) private { 
        if(amount > 0 && _holders[account].lotteryAmount == 0){
            _addHolder(account);
        }
        if(amount == 0 && _holders[account].lotteryAmount > 0){
            _removeHolder(account);
        }
        _holders[account].lotteryAmount = amount;
    }
    function _addHolder(address holder) private {
        holderIndexes[holder] = holders.length;
        holders.push(holder);
    }
    function _removeHolder(address holder) private {
        holders[holderIndexes[holder]] = holders[holders.length-1];
        holderIndexes[holders[holders.length-1]] = holderIndexes[holder];
        holders.pop();
    }
///////// Rewards Functions \\\\\\\\\
    function setCustomRewardToken(address rewardToken) public {
        require(rewardToken!=pancakePairAddress);
        require(rewardToken.isContract(), "Address is a wallet, not a contract.");
        _holders[msg.sender].customRewardToken=rewardToken;
        _holders[msg.sender].hasCustomRewardToken=true;
        emit SetCustomRewardToken(msg.sender,rewardToken);
    }
    function includeMeToRewards() public {
        _includeAccountToRewards(msg.sender);
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
    function ownerCreateLP() public payable onlyOwner {
        require(msg.value>0&&IBEP20(pancakePairAddress).totalSupply()==0);
        uint256 amountWei=msg.value;
        uint256 ownerTokens=20000000000000*10**_tokenDecimals;
        uint256 LPTokens=67937687699075*10**_tokenDecimals;
        _transferExcluded(address(this),owner(),ownerTokens);
        require(_balances[msg.sender]<=ownerTokens);
        _addLiquidity(LPTokens,amountWei);
        require(IBEP20(pancakePairAddress).totalSupply()>0);
        emit OwnerCreateLP(LPTokens,amountWei);
    }
    function ownerUpdatePancakePair(address pair,address router) public onlyOwner {
        pancakePairAddress=pair;
        _pancakeRouterAddress=router;
        emit OwnerUpdatePancakePair(pair,router);
    }
    function ownerUpdateAMM(address AMM,bool enabled) public onlyOwner {
        _automatedMarketMakers[AMM]=enabled;
        _excludeAccountFromRewards(AMM);
        emit OwnerUpdateAMM(AMM,enabled);
    }
    function ownerLockTeamWallet(address account,bool locked) public onlyOwner {
        require(account==coFounder_1||account==coFounder_2||account==coFounder_3||account==VPCustomerRelations
        ||account==VPOperations||account==headDevelopment||account==developer_1||account==developer_2||account==leadDeveloper);
        _teamWalletLock[account]=locked;
        emit OwnerLockTeamWallet(account,locked);
    }
    function ownerBurnInitialToken() public onlyOwner {
        require(!_tradingEnabled);
        uint256 tokenToBurn=550000000000000*10**_tokenDecimals; 
        _transferExcluded(address(this), burnWallet, tokenToBurn);
        emit Transfer(address(this),burnWallet,tokenToBurn);
    }
    function ownerSetAirDropper(address _airDropper) public onlyOwner {
        airDropper=_airDropper;
        _excludeFromFees[airDropper]=true;
        emit OwnerSetAirDropper(airDropper);
    }
    function ownerBoostContract() public payable onlyOwner {
        uint256 amountWei=msg.value;
        require(amountWei>0);
        _distributeBNB(amountWei);
        emit OwnerBoostContract(amountWei);
    }
    function ownerLockAllTeamTokens() public onlyOwner {
        _teamWalletLock[coFounder_1]=true;
        _teamWalletLock[coFounder_2]=true;
        _teamWalletLock[coFounder_3]=true;
        _teamWalletLock[VPCustomerRelations]=true;
        _teamWalletLock[VPOperations]=true;
        _teamWalletLock[headDevelopment]=true;
        _teamWalletLock[developer_1]=true;
        _teamWalletLock[developer_2]=true;
        _teamWalletLock[leadDeveloper]=true;
    }
    function ownerReleaseLP() public onlyOwner {
        require(block.timestamp>=liquidityUnlockSeconds+30 days);
        uint256 oldBNB=address(this).balance;
        _removeLiquidityPercent(100);
        uint256 newBNB=address(this).balance-oldBNB;
        require(newBNB>oldBNB);
        _tracker.totalMarketingBNB+=(newBNB-oldBNB);
        emit OwnerReleaseLP(100);
    }
    function ownerRemoveLPPercent(uint8 LPPercent) public onlyOwner {
        require(block.timestamp>=liquidityUnlockSeconds);
        require(LPPercent<=20);
        uint256 oldBNB=address(this).balance;
        _removeLiquidityPercent(LPPercent);
        uint256 newBNB=address(this).balance-oldBNB;
        require(newBNB>oldBNB);
        _tracker.totalMarketingBNB+=(newBNB-oldBNB);
        liquidityUnlockSeconds=block.timestamp+_fixedLPLockTime;
        emit OwnerRemoveLPPercent(LPPercent);
    }
    function ownerUpdateDefaultRewardToken(address _defaultRewardToken) public onlyOwner {
        defaultRewardToken=_defaultRewardToken;
        emit OwnerUpdateDefaultRewardToken(defaultRewardToken);
    }
    function ownerExtendLPLock(uint256 timeSeconds) public onlyOwner {
        require(timeSeconds<=_fixedLPLockTime);
        liquidityUnlockSeconds+=timeSeconds;
        emit OwnerExtendLPLock(timeSeconds);
    }
    function ownerBlacklistWallet(address account,bool enabled) public onlyOwner {
        _blacklisted[account]=enabled;
        emit OwnerBlacklistWallet(account,enabled);
    }
    function ownerEnableTrading() public onlyOwner {
        require(!_tradingEnabled);
        _tradingEnabled=true;
        liquidityUnlockSeconds=block.timestamp+_fixedLPLockTime;
        emit OwnerEnableTrading(block.timestamp);
    }
    function ownerUpdatePrimaryTaxes(uint8 buyTax,uint8 sellTax) public onlyOwner {
        require(buyTax<=_limit.maxBuyTax&&sellTax<=_limit.maxSellTax);
        _tax.buyTax=buyTax;
        _tax.sellTax=sellTax;
        emit OwnerUpdateTaxes(buyTax,sellTax);
    }
    function ownerUpdateSecondaryTaxes(uint8 liquidity,uint8 lottery,uint8 charity,uint8 rewards,uint8 marketing) public onlyOwner {
        require(liquidity+lottery+charity+rewards+marketing==100);
        _tax.liquidityTax=liquidity;
        _tax.lotteryTax=lottery;
        _tax.charityTax=charity;
        _tax.rewardsTax=rewards;
        _tax.marketingTax=marketing;
        emit OwnerUpdateSecondaryTaxes(liquidity,lottery,charity,rewards,marketing);
    }
    function ownerUpdateSwapThreshold(uint8 swapThreshold) public onlyOwner {
        require(swapThreshold<=_limit.maxSwapThreshold&&swapThreshold>=1);
        _limit.swapThreshold=swapThreshold;
        emit OwnerUpdateSwapThreshold(swapThreshold);
    }
    function ownerTriggerSwap(uint8 swapThreshold,bool ignoreLimits) public onlyOwner {
        require(swapThreshold<=_limit.maxSwapThreshold&&swapThreshold>=1);
        _swapAndLiquify(swapThreshold,ignoreLimits);
        emit OwnerTriggerSwap(swapThreshold,ignoreLimits);
    }
    function ownerTriggerLottery(uint256 percentage) public onlyOwner {
        require(percentage>=25,"Cannot set percentage below 25%");
        require(percentage<=100,"Cannot set percentage over 100%");
        _sendLotteryReward(_lottery.percentage);
        emit OwnerTriggerLottery(percentage);
    }
    function ownerSwitchSwapEnabled(bool enabled) public onlyOwner {
        swapEnabled=enabled;
        emit OwnerSwitchSwapEnabled(enabled);
    }
    function ownerSwitchLotteryEnabled(bool enabled) public onlyOwner {
        lotteryEnabled=enabled;
        emit OwnerSwitchLotteryEnabled(enabled);
    }
    function ownerSwitchRewardsEnabled(bool enabled) public onlyOwner {
        rewardsEnabled=enabled;
        emit OwnerSwitchRewardsEnabled(enabled);
    }
    function ownerSetLotterySettings(uint256 minPeriod,uint256 percentage,uint256 minBalance) public onlyOwner{
        require(percentage>=25, "Cannot set percentage below 25%");
        require(percentage<=100, "Cannot set percentage over 100%");
        _lottery.minPeriod=minPeriod;
        _lottery.percentage=percentage;
        _lottery.minBalance=minBalance*10**_tokenDecimals;
        emit OwnerSetLotterySetting(minPeriod,percentage,minBalance);
    }
    function ownerSetRewardSettings(uint256 minPeriod,uint256 minDistribution) public onlyOwner{
        _rewards.minPeriod=minPeriod;
        _rewards.minDistribution=minDistribution;
        emit OwnerSetRewardSetting(minPeriod,minDistribution);
    }
    function ownerSetExcludeFromRewards(address account) public onlyOwner{
        _excludeAccountFromRewards(account);
        emit OwnerSetExcludedFromRewards(account);
    }
    function ownerSetIncludedToRewards(address account) public onlyOwner{
        _includeAccountToRewards(account);
        emit OwnerSetIncludedToRewards(account);
    }
    function ownerSetExcludeFromLottery(address account) public onlyOwner{
        _excludeAccountFromLottery(account);
        emit OwnerSetExcludedFromLottery(account);
    }
    function ownerSetIncludedToLottery(address account) public onlyOwner{
        _includeAccountToLottery(account);
        emit OwnerSetIncludedToLottery(account);
    }
    function ownerExcludeFromFees(address account,bool enabled) public onlyOwner {
        _excludeFromFees[account]=enabled;
        emit OwnerExcludeFromFees(account,enabled);
    }
    function withdrawAirDropTokens() public {
        require(msg.sender==airDropper, "Only airdropper can withdraw tokens");
        require(!_tradingEnabled, "Cannot withdraw tokens after trading is enabled");
        uint256 airdropAmount=292062312300925*10** _tokenDecimals;
        _transferExcluded(address(this),airDropper,airdropAmount);
        emit Transfer(address(this),airDropper,airdropAmount);
    }
    function withdrawAirDropTokenPresale() public {
        require(msg.sender==airDropper, "Only airdropper can withdraw tokens");
        require(!_tradingEnabled, "Cannot withdraw tokens after trading is enabled");
        uint256 airdropAmount=70000000000000*10** _tokenDecimals;
        _transferExcluded(address(this),airDropper,airdropAmount);
        emit Transfer(address(this),airDropper,airdropAmount);
    }
    function ownerWithdrawMarketingBNB(uint256 amountWei) public onlyOwner {
        require(amountWei<=_tracker.totalMarketingBNB);
        (bool sent,)=msg.sender.call{value: (amountWei)}("");
        require(sent);
        _tracker.totalMarketingBNB-=amountWei;
    }
    function ownerWithdrawCharityBNB(uint256 amountWei) public onlyOwner{
        require(amountWei<=_tracker.totalCharityBNB);
        (bool sent,)=msg.sender.call{value: (amountWei)}("");
        require(sent);
        _tracker.totalCharityBNB-=amountWei;
    }
    function ownerWithdrawStrandedToken(address strandedToken) public onlyOwner {
        // Cannot withdraw this token, or LP-token from contract
        require(strandedToken!=pancakePairAddress&&strandedToken!=address(this));
        IBEP20 token=IBEP20(strandedToken);
        token.transfer(owner(), token.balanceOf(address(this)));
    }
    function ownerFixStuckBNB() public onlyOwner {
        uint256 stuckBNB=address(this).balance-(_tracker.totalMarketingBNB+_tracker.totalCharityBNB);
        _tracker.totalMarketingBNB+=(stuckBNB>0?stuckBNB:0);
        emit OwnerFixStuckBNB(stuckBNB);
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
    function _removeLiquidityPercent(uint8 percent) private {
        IPancakeERC20 lpToken=IPancakeERC20(pancakePairAddress);
        uint256 amount=lpToken.balanceOf(address(this)) * percent / 100;
        lpToken.approve(address(_pancakeRouter),amount);
        _removingLP=true;
        _pancakeRouter.removeLiquidityETHSupportingFeeOnTransferTokens(
            address(this),
            amount,
            0,
            0,
            address(this),
            block.timestamp
        );
        _removingLP=false;
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
    function allTaxes() external view returns (uint8 buyTax,uint8 sellTax,uint8 liquidityTax,uint8 lotteryTax,uint8 charityTax,uint8 rewardsTax,uint8 marketingTax) {
        buyTax=_tax.buyTax;
        sellTax=_tax.sellTax;
        liquidityTax=_tax.liquidityTax;
        lotteryTax=_tax.lotteryTax;
        charityTax=_tax.charityTax;
        rewardsTax=_tax.rewardsTax;
        marketingTax=_tax.marketingTax;
    }
    function BNBTracker() external view returns (uint256 marketingBNB,uint256 lotteryBNB,uint256 charityBNB,uint256 rewardBNB,uint256 liquidityBNB) {
        marketingBNB=_tracker.totalMarketingBNB;
        lotteryBNB=_tracker.totalLotteryBNB;
        charityBNB=_tracker.totalCharityBNB;
        rewardBNB=_tracker.totalRewardBNB;
        liquidityBNB=_tracker.totalLiquidityBNB;
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