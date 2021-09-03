// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./Libraries.sol";



////////////////////////////////////////////////////////////////////////////////////////////////////////
//WenPump Contract /////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////
contract WP is IBEP20, Ownable
{
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _sellLock;

    EnumerableSet.AddressSet private _excluded;
    EnumerableSet.AddressSet private _excludedFromLocks;
    EnumerableSet.AddressSet private _excludedFromStaking;

    EnumerableSet.AddressSet private _automatedMarketMakers;
    
    //Token Info
    string private constant _name = 'WP';
    string private constant _symbol = 'WPT';
    uint8 private constant _decimals = 9;
    uint256 public constant InitialSupply= 1000 * 10**6 * 10**_decimals;//equals 1,200,000,000 token

    //Lower limit for the balance Limit, can't be set lower
    uint8 public constant BalanceLimitDivider=100;
    //Lower limit for the sell Limit, can't be set lower
    uint16 public constant MinSellLimitDivider=1000;
    //Sellers get locked for sellLockTime so they can't dump repeatedly
    uint16 public constant MaxSellLockTime= 1 hours;
    //The time Liquidity gets locked at start and prolonged once it gets released
    uint256 private constant DefaultLiquidityLockTime=7 days;
    //Main Team wallet
    address public TeamWallet1 = 0xDaA7dd8f8dED51eeb26392907aF60896846300A4;
    //other team wallets
    address public TeamWallet2 = 0xf430fd172a3d9738fdA5B5356addBa719164befc;
    address public TeamWallet3 = 0x1AAf19570DAAA82748097A2f77E3796D91F56ead;
    address public TeamWallet4 = 0x02f9DF96eaafc9d3dE4faF14792b29fDB0505AF3;
    address public TeamWallet5 = 0xF1C6e2254351bd3A7E6599F011026E29344C0542;

    //variables that track balanceLimit and sellLimit,
    //can be updated based on circulating supply and Sell- and BalanceLimitDividers
    uint256 private _circulatingSupply;
    uint256 private balanceLimit=InitialSupply/BalanceLimitDivider;
    uint256 private sellLimit=InitialSupply/MinSellLimitDivider;

    //Limits max tax, only gets applied for tax changes, doesn't affect inital Tax
    uint8 public constant MaxTax=20;
    uint256 public sellLockTime=MaxSellLockTime;
    //Tracks the current Taxes, different Taxes can be applied for buy/sell/transfer
    //Taxes can never exceed MaxTax
    uint8 private _buyTax=17;
    uint8 private _sellTax=17;
    //Transfer tax starts at 50%. this is to stop whitelisted from transfering.
    //will later be capped at 25%
    uint8 private _transferTax=50;
    //The shares of the specific Taxes, always needs to equal 100%
    uint8 private _liquidityTax=12;
    uint8 private _stakingTax=88;
    //The shares of the staking Tax that get used for Marketing/Team
    uint8 public marketingShare=66;
    //determines the permille of the pancake pair needed to trigger Liquify
    uint8 public LiquifyTreshold=5;

    //BotProtection values
    bool private _botProtection;
    uint8 constant BotMaxTax=100;
    uint256 constant BotBuyTaxTime=30 seconds;
    uint256 constant BotSellTaxTime=2 minutes;

    uint256 public launchTimestamp;
    
    //_pancakePairAddress is also equal to the liquidity token address
    //LP token are locked in the contract
    address private _pancakePairAddress; 
    IPancakeRouter02 private  _pancakeRouter; 
    //TODO: Change to Mainnet
    //TestNet
    //address private constant PancakeRouter=0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    //MainNet
    address private constant PancakeRouter=0x10ED43C718714eb63d5aA57B78B54704E256024E;
    
    //modifier for functions only the team can call
    modifier onlyTeam() {
        require(_isTeam(msg.sender), "Caller not in Team");
        _;
    }
    //Checks if address is in Team, is needed to give Team access even if contract is renounced
    //Team doesn't have access to critical Functions that could turn this into a Rugpull(Exept liquidity unlocks)
    function _isTeam(address addr) private view returns (bool){
        return addr==owner()||addr==TeamWallet1;
    }
    

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Constructor///////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    constructor () {
        //Creates a Pancake Pair
        _pancakeRouter = IPancakeRouter02(PancakeRouter);
        _pancakePairAddress = IPancakeFactory(_pancakeRouter.factory()).createPair(address(this), _pancakeRouter.WETH());
        _automatedMarketMakers.add(_pancakePairAddress);
        //excludes Pancake Pair and contract from staking
        _excludedFromStaking.add(_pancakePairAddress);
        _excludedFromStaking.add(address(this));
        //deployer gets 100% of the supply to create LP
        _addToken(msg.sender,InitialSupply);
        emit Transfer(address(0), msg.sender, InitialSupply);
        //Team wallet deployer and contract are excluded from Taxes
        //contract can't be included to taxes
        _excluded.add(TeamWallet1);
        _excluded.add(msg.sender);
        _excluded.add(address(this));
        _approve(address(this), address(_pancakeRouter), type(uint256).max);
    }
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Transfer functionality////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    //picks the transfer function
    function _transfer(address sender, address recipient, uint256 amount) private{
        require(sender != address(0), "from zero");
        require(recipient != address(0), "to zero");

        //excluded adresses are transfering tax and lock free
        if(_excluded.contains(sender) || _excluded.contains(recipient)){
            _feelessTransfer(sender, recipient, amount);
            return;
        }
        //once trading is enabled, it can't be turned off again
        require(tradingEnabled,"trading not yet enabled"); 
        _regularTransfer(sender,recipient,amount);
        //AutoPayout
        if(!autoPayoutDisabled) _autoPayout();
    }
    //applies taxes, checks for limits, locks generates autoLP and stakingBNB, and autostakes
    function _regularTransfer(address sender, address recipient, uint256 amount) private{
        uint256 recipientBalance = _balances[recipient];
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "exceeds balance");
        //checks all registered AMM if it's a buy or sell.
        bool isBuy=_automatedMarketMakers.contains(sender);
        bool isSell=_automatedMarketMakers.contains(recipient);
        uint8 tax;
        if(isSell){
            if(!_excludedFromLocks.contains(sender)&&!sellLockDisabled){
                //If seller sold less than sellLockTime(2h) ago, sell is declined, can be disabled by Team         
                require(_sellLock[sender]<=block.timestamp,"sellLock");
                //Sets the time sellers get locked(2 hours by default)
                _sellLock[sender]=block.timestamp+sellLockTime;
                //Sells can't exceed the sell limit(50.000 Tokens at start, can be updated to circulating supply)
                require(amount<=sellLimit,"Dump");
            }

            tax=_getTax(false);

        } else if(isBuy){
            //Checks If the recipient balance(excluding Taxes) would exceed Balance Limit
            require(_excludedFromLocks.contains(recipient)||(recipientBalance+amount<=balanceLimit),"whale");
            tax=_getTax(true);

        } else {//Transfer
            //Checks If the recipient balance(excluding Taxes) would exceed Balance Limit
            require(_excludedFromLocks.contains(recipient)||recipientBalance+amount<=balanceLimit,"whale");
            tax=_transferTax;
        }     
        
        //Swapping AutoLP and MarketingBNB is only possible if sender is not pancake pair, 
        //if its not manually disabled, if its not already swapping
        if((sender!=_pancakePairAddress)&&(!swapAndLiquifyDisabled)&&(!_isSwappingContractModifier))
            _swapContractToken(LiquifyTreshold,false);
            
        _transferTaxed(sender,recipient,amount,tax);
    }
    function _transferTaxed(address sender, address recipient, uint256 amount, uint8 tax) private{
        uint256 totalTaxedToken=_calculateFee(amount, tax, 100);
        uint256 taxedAmount=amount-totalTaxedToken;
        //Removes token and handles staking
        _removeToken(sender,amount);
        //Adds the taxed tokens -burnedToken to the contract
        _addToken(address(this), totalTaxedToken);
        //Adds token and handles staking
        _addToken(recipient, taxedAmount);
        emit Transfer(sender,recipient,taxedAmount);
        //if last payout was at least payoutFrequency ago, do auto payout

    }
    //Feeless transfer only transfers and autostakes
    function _feelessTransfer(address sender, address recipient, uint256 amount) private{
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, ">balance");
        //Removes token and handles staking
        _removeToken(sender,amount);
        //Adds token and handles staking
        _addToken(recipient, amount);
        
        emit Transfer(sender,recipient,amount);

    }
    //gets the tax for buying, tax is different during the bot protection
    function _getTax(bool buy) private returns (uint8){
        //returns the Tax subtracting promotion Bonus
        if(!_botProtection){
         if(buy) return _buyTax;
         return _sellTax;
        }
        uint256 duration;
        if(buy) duration=BotBuyTaxTime;
        else duration=BotSellTaxTime;
        
        if(block.timestamp>launchTimestamp+duration){
            if(buy) return _buyTax;
            _botProtection=false;
            return _sellTax;
        }
        return _getBotTax(duration, buy);
    }
    
    function _getBotTax(uint256 duration,bool buy) private view returns (uint8){
        uint8 tax;
        if(buy) tax=_buyTax;
        else tax=_sellTax;
        uint256 timeSinceLaunch=block.timestamp-launchTimestamp;
        return uint8(BotMaxTax-((BotMaxTax-tax)*timeSinceLaunch/duration));
    }

    //Calculates the token that should be taxed
    function _calculateFee(uint256 amount, uint8 tax, uint8 taxPercent) private pure returns (uint256) {
        return (amount*tax*taxPercent) / 10000;
    }
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //BNB Autostake/////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////// 
    //Autostake uses the balances of each holder to redistribute auto generated BNB.
    //Each transaction _addToken and _removeToken gets called for the transaction amount
    //Min hold is 10000 token
    uint256 autoPayoutMinHold=10000*10**_decimals;
    EnumerableSet.AddressSet private _autoPayoutList;

    uint256 GasforAutoPayout=300000;
    
    uint256 currentPayoutIndex;
    uint256 payoutTokenID;

    uint256 lastPayoutTimestamp;
    bool autoPayoutDisabled;

    event  OnChangeRewardsList(address[] Token);
    function TeamChangeRewardsList(address[] memory tokenList) public onlyTeam{
        require(tokenList.length>0,"need to add at least 1 token");
        require(tokenList[0]==address(0),"token 0 needs to be address 0");
        PayoutTokens=tokenList;
        payoutTokenID=0;
        emit  OnChangeRewardsList(tokenList);
    }
    event OnDisableAutoPayout(bool disabled);
    function TeamDisableAutoPayout(bool disabled) public onlyTeam{
        autoPayoutDisabled=disabled;
        emit  OnDisableAutoPayout(disabled);
    }
    event OnChangeAutoPayoutGas(uint256 gas); 
    function TeamChangeAutoPayoutGas(uint256 gas) public onlyTeam{
        require(gas>=300000&&gas<=1000000);
        GasforAutoPayout=gas;
        emit OnChangeAutoPayoutGas(gas);
    }
    
    //Mainnet
    address[] PayoutTokens=[
    address(0),
    //Bitcoin
    0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c, 
    //Ethereum
    0x2170Ed0880ac9A755fd29B2688956BD959F933F8, 
    //ADA
    0x3EE2200Efb3400fAbB9AacF31297cBdD1d435D47,
    //USDT
    0x55d398326f99059fF775485246999027B3197955];
    
    //Testnet
    /* 
    address[] public PayoutTokens=[
    address(0),
    //USDT
    0x7ef95a0FEE0Dd31b22626fA2e10Ee6A223F8a684, 
    //ETH
    0x8BaBbB98678facC7342735486C851ABD7A0d17Ca, 
    //BUSD
    0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7,
    //DAI
    0x8a9424745056Eb399FD19a0EC26A14316684e274];
    */
    
    function getCurrentPayoutToken() public view returns(address){
        return PayoutTokens[payoutTokenID];
    }
    function _autoPayout() private{
        //resets payout counter and moves to next payout token if last holder is reached
        if(currentPayoutIndex>=_autoPayoutList.length()) _resetPayoutCounter();
        address[] memory path = new address[](2);
        path[0] = _pancakeRouter.WETH(); //BNB
        path[1] = PayoutTokens[payoutTokenID];  
        uint256 gasUsed=0;
        uint256 oldGas=gasleft();
        while(gasUsed<GasforAutoPayout){
            address current=_autoPayoutList.at(currentPayoutIndex);
            //index 0 is BNB
            if(payoutTokenID==0||payoutTokenID>=PayoutTokens.length){
                _claimBNB(current);
            }
            else{
                //claims token for current address in payout list
                _claimToken(current, path);  
            }

            //increses the payout counter
            currentPayoutIndex++;
            if(currentPayoutIndex>=_autoPayoutList.length()){
                _resetPayoutCounter();
                return;
            }
            gasUsed+=oldGas-gasleft();
            oldGas=gasleft();
        }
    }
    
    function _resetPayoutCounter() private{
        currentPayoutIndex=0;
        payoutTokenID++;
        payoutTokenID=payoutTokenID%PayoutTokens.length;
        lastPayoutTimestamp=block.timestamp;
    }

    //Multiplier to add some accuracy to profitPerShare
    uint256 private constant DistributionMultiplier = 2**64;
    //profit for each share a holder holds, a share equals a decimal.
    uint256 public profitPerShare;
    //totalShares in circulation +InitialSupply to avoid underflow 
    //getTotalShares returns the correct amount
    uint256 private _totalShares=InitialSupply;
    //the total reward distributed through staking, for tracking purposes
    uint256 public totalStakingReward;
    //the total payout through staking, for tracking purposes
    uint256 public totalPayouts;
    //balance that is claimable by the team
    uint256 public marketingBalance;
    //Mapping of the already paid out(or missed) shares of each staker
    mapping(address => uint256) private alreadyPaidShares;
    //Mapping of shares that are reserved for payout
    mapping(address => uint256) private toBePaid;

    //adds Token to balances, adds new BNB to the toBePaid mapping and resets staking
    function _addToken(address addr, uint256 amount) private {
        //the amount of token after transfer
        uint256 newAmount=_balances[addr]+amount;
        _circulatingSupply+=amount;
        //if excluded, don't change staking amount
        if(_excludedFromStaking.contains(addr)){
           _balances[addr]=newAmount;
           return;
        }
        _totalShares+=amount;
        //gets the payout before the change
        uint256 payment=_newDividentsOf(addr);
        //resets dividents to 0 for newAmount
        alreadyPaidShares[addr] = profitPerShare * newAmount;
        //adds dividents to the toBePaid mapping
        toBePaid[addr]+=payment; 
        //sets newBalance
        _balances[addr]=newAmount;
        if(newAmount>=autoPayoutMinHold)
            _autoPayoutList.add(addr);

    }
    
    //removes Token, adds BNB to the toBePaid mapping and resets staking
    function _removeToken(address addr, uint256 amount) private {
        //the amount of token after transfer
        uint256 newAmount=_balances[addr]-amount;
        _circulatingSupply-=amount;
        if(_excludedFromStaking.contains(addr)){
           _balances[addr]=newAmount;
           return;
        }

        //gets the payout before the change
        uint256 payment=_newDividentsOf(addr);
        //sets newBalance
        _balances[addr]=newAmount;
        //resets dividents to 0 for newAmount
        alreadyPaidShares[addr] = profitPerShare * getShares(addr);
        //adds dividents to the toBePaid mapping
        toBePaid[addr]+=payment; 
        _totalShares-=amount;
        if(newAmount<autoPayoutMinHold)
            _autoPayoutList.remove(addr);
    }
    
    
    //gets the dividents of a staker that aren't in the toBePaid mapping 
    function _newDividentsOf(address staker) private view returns (uint256) {
        uint256 fullPayout = profitPerShare * getShares(staker);
        //if excluded from staking or some error return 0
        if(fullPayout<=alreadyPaidShares[staker]) return 0;
        return (fullPayout - alreadyPaidShares[staker]) / DistributionMultiplier;
    }
    
    //distributes bnb between marketing share and dividents 
    function _distributeStake(uint256 AmountWei) private {
        // Deduct marketing Tax
        if(AmountWei==0) return;
        uint256 marketingSplit = (AmountWei * marketingShare) / 100;
        uint256 amount = AmountWei - marketingSplit;

        marketingBalance+=marketingSplit;       

        totalStakingReward += amount;
        uint256 totalShares=getTotalShares();
        //when there are 0 shares, add everything to marketing budget
        if (totalShares == 0) {
            marketingBalance += amount;
        }else{
            //Increases profit per share based on current total shares
            profitPerShare += ((amount * DistributionMultiplier) / totalShares);
        }
    }
    //Substracts the amount from dividents, fails if amount exceeds dividents
    function _substractDividents(address addr,uint256 amount) private{
        if(amount==0) return;
        require(amount<=getDividents(addr),"exceeds divident");

        if(_excludedFromStaking.contains(addr)){
            //if excluded just withdraw remaining toBePaid BNB
            toBePaid[addr]-=amount;
        }
        else{
            uint256 newAmount=_newDividentsOf(addr);
            //sets payout mapping to current amount
            alreadyPaidShares[addr] = profitPerShare * newAmount;
            //the amount to be paid 
            toBePaid[addr]+=newAmount;
            toBePaid[addr]-=amount;
        }
    }
    
    function ClaimRewards() public{
        uint256 amount=getDividents(msg.sender);
        require (amount>0,"Amount=0");
        _claimBNB(msg.sender);
    }
    function _claimBNB(address account) private{
        uint256 amount=getDividents(msg.sender);
        if(amount==0) return;
        //Substracts the amount from the dividents
        _substractDividents(msg.sender, amount);
        totalPayouts+=amount;
        (bool sent,)=msg.sender.call{value:amount}("");
        if(!sent){
            //if rewards not sent, reset payout
            totalPayouts-=amount;
            toBePaid[account]+=amount;
        }
    }
    //claims any token and sends it to addr for the amount in BNB
    function _claimToken(address addr, address[] memory path) private{     
        uint256 amount=getDividents(addr);
        if(amount==0) return;
        //Substracts the amount from the dividents
        _substractDividents(addr, amount);
        totalPayouts+=amount;
        //purchases token and sends them to the target address
        try _pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
        0,
        path,
        addr,
        block.timestamp){}
        catch{
            //Resets the payout should it fail
            toBePaid[addr]=amount;
            totalPayouts-=amount;
        }
    }
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Swap Contract Tokens//////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    //tracks auto generated BNB, useful for ticker etc
    uint256 public totalLPBNB;
    //Locks the swap if already swapping
    bool private _isSwappingContractModifier;
    modifier lockTheSwap {
        _isSwappingContractModifier = true;
        _;
        _isSwappingContractModifier = false;
    }

    function _swapContractToken(uint16 permilleOfPancake,bool ignoreLimits) private lockTheSwap{
        uint256 contractBalance=_balances[address(this)];
        uint16 totalTax=_liquidityTax+_stakingTax;
        if(totalTax==0) return;

            
        uint256 tokenToSwap=_balances[_pancakePairAddress]*permilleOfPancake/1000;
        if(tokenToSwap>sellLimit&&!ignoreLimits) tokenToSwap=sellLimit;
        
        //only swap if contractBalance is larger than tokenToSwap or ignore limits
        bool NotEnoughToken=contractBalance<tokenToSwap;
        if(NotEnoughToken){
            if(ignoreLimits)
                tokenToSwap=contractBalance;
            else return;
        }
        //splits the token in TokenForLiquidity and tokenForMarketing
        uint256 tokenForLiquidity=(tokenToSwap*_liquidityTax)/totalTax;
        uint256 tokenForMarketing= tokenToSwap-tokenForLiquidity;

        //splits tokenForLiquidity in 2 halves
        uint256 liqToken=tokenForLiquidity/2;
        uint256 liqBNBToken=tokenForLiquidity-liqToken;

        //swaps marktetingToken and the liquidity token half for BNB
        uint256 swapToken=liqBNBToken+tokenForMarketing;
        //Gets the initial BNB balance, so swap won't touch any staked BNB
        uint256 initialBNBBalance = address(this).balance;
        _swapTokenForBNB(swapToken);
        uint256 newBNB=(address(this).balance - initialBNBBalance);
        //calculates the amount of BNB belonging to the LP-Pair and converts them to LP
        uint256 liqBNB = (newBNB*liqBNBToken)/swapToken;
        _addLiquidity(liqToken, liqBNB);
        //Get the BNB balance after LP generation to get the
        //exact amount of token left for Staking, as LP generation leaves some BNB untouched
        uint256 distributeBNB=(address(this).balance - initialBNBBalance);
        //distributes remaining BNB between stakers and Marketing
        _distributeStake(distributeBNB);
    }
    //swaps tokens on the contract for BNB
    function _swapTokenForBNB(uint256 amount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _pancakeRouter.WETH();

        _pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    //Adds Liquidity directly to the contract where LP are locked(unlike safemoon forks, that transfer it to the owner)
    function _addLiquidity(uint256 tokenamount, uint256 bnbamount) private {
        totalLPBNB+=bnbamount;
        try _pancakeRouter.addLiquidityETH{value: bnbamount}(
            address(this),
            tokenamount,
            0,
            0,
            address(this),
            block.timestamp
        ){}
        catch{}
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //public functions /////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
        //gets shares of an address, returns 0 if excluded
    function getShares(address addr) public view returns(uint256){
        if(_excludedFromStaking.contains(addr)) return 0;
        return _balances[addr];
    }

    //Total shares equals circulating supply minus excluded Balances
    function getTotalShares() public view returns (uint256){
        return _totalShares-InitialSupply;
    }

    function getLiquidityLockSeconds() public view returns (uint256 LockedSeconds){
        if(block.timestamp<_liquidityUnlockTime)
            return _liquidityUnlockTime-block.timestamp;
        return 0;
    }

    function getTaxes() public view returns(
    uint256 buyTax, 
    uint256 sellTax, 
    uint256 transferTax, 
    uint256 liquidityTax,
    uint256 stakingTax){
            if(block.timestamp>launchTimestamp+BotBuyTaxTime)
            buyTax=_buyTax;
            else buyTax=_getBotTax(BotBuyTaxTime,true);

            if(block.timestamp>launchTimestamp+BotSellTaxTime)
            sellTax=_sellTax;
            else sellTax=_getBotTax(BotSellTaxTime,false);
            transferTax=_transferTax;

            liquidityTax=_liquidityTax;
            stakingTax=_stakingTax;


    }
    
    function getStatus(address AddressToCheck) public view returns(
        bool Excluded, 
        bool ExcludedFromLock, 
        bool ExcludedFromStaking, 
        uint256 SellLock
        ){
        uint256 lockTime=_sellLock[AddressToCheck];
       if(lockTime<=block.timestamp) lockTime=0;
       else lockTime-=block.timestamp;
       
        return(
            _excluded.contains(AddressToCheck),
            _excludedFromLocks.contains(AddressToCheck),
            _excludedFromStaking.contains(AddressToCheck),
            lockTime
            );
    }
    
    //Returns the not paid out dividents of an address in wei
    function getDividents(address addr) public view returns (uint256){
        return _newDividentsOf(addr)+toBePaid[addr];
    }
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Settings//////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    bool public sellLockDisabled;
    bool public swapAndLiquifyDisabled;
    event  OnAddAMM(address AMM,bool Add);
    function TeamAddOrRemoveAMM(address AMMPairAddress, bool Add) public onlyTeam{
        require(AMMPairAddress!=_pancakePairAddress,"can't change Pancake");
        if(Add){
            if(!_excludedFromStaking.contains(AMMPairAddress))
                TeamSetStakingExcluded(AMMPairAddress, true);
            _automatedMarketMakers.add(AMMPairAddress);
        } 
        else{
            _automatedMarketMakers.remove(AMMPairAddress);
        }
        emit OnAddAMM(AMMPairAddress, Add);
    }
    function TeamChangeTeamWallet(address newTeamWallet) public{
        require(msg.sender==TeamWallet1);
        TeamWallet1=newTeamWallet;
    }
    event  OnChangeLiquifyTreshold(uint8 TresholdPermille);
    function TeamSetLiquifyTreshold(uint8 TresholdPermille) public onlyTeam{
        require(TresholdPermille<=50);
        require(TresholdPermille>0);
        LiquifyTreshold=TresholdPermille;
        emit OnChangeLiquifyTreshold(TresholdPermille);
    }
    function TeamWithdrawMarketingBNB() public onlyTeam{
        uint256 amount=marketingBalance;
        marketingBalance=0;
        _distributeMarketingBNB(amount);
    } 
    
    
    function _distributeMarketingBNB(uint256 amount) private{
        uint256 Share1=amount*333/1000;
        (bool sent,) =TeamWallet1.call{value: (Share1)}("");  
        require(sent);
        uint256 RemainingShare=amount-Share1;
        uint256 SharePerWallet=RemainingShare*30/100;
        (sent,) =TeamWallet2.call{value: (SharePerWallet)}("");
        require(sent);
        (sent,) =TeamWallet3.call{value: (SharePerWallet)}("");
        require(sent);
        (sent,) =TeamWallet4.call{value: (SharePerWallet)}("");
        require(sent);
        (sent,) =TeamWallet4.call{value: (RemainingShare-(3*SharePerWallet))}("");    
        require(sent);
    }
    
    event  OnSwitchSwapAndLiquify(bool Disabled);
    //switches autoLiquidity and marketing BNB generation during transfers
    function TeamDisableSwapAndLiquify(bool disabled) public onlyTeam{
        swapAndLiquifyDisabled=disabled;
        emit OnSwitchSwapAndLiquify(disabled);
    }
    event OnChangeSellLock(uint256 newSellLockTime,bool disabled);
    //Sets SellLockTime, needs to be lower than MaxSellLockTime
    function TeamChangeSellLock(uint256 sellLockSeconds,bool disabled)public onlyTeam{
        require(sellLockSeconds<=MaxSellLockTime,"Sell Lock time too high");
        sellLockTime=sellLockSeconds;
        sellLockDisabled=disabled;
        emit OnChangeSellLock(sellLockSeconds,disabled);
    } 
    event OnChangeTaxes(uint8 liquidityTaxes, uint8 stakingTaxes,uint8 buyTax, uint8 sellTax, uint8 transferTax, uint8 marketing);
    //Sets Taxes, is limited by MaxTax(25%) to make it impossible to create honeypot
    function TeamSetTaxes(uint8 liquidityTaxes, uint8 stakingTaxes,uint8 buyTax, uint8 sellTax, uint8 transferTax, uint8 marketing) public onlyTeam{
        uint8 totalTax=liquidityTaxes+stakingTaxes;
        require(totalTax==100);
        require(buyTax<=MaxTax&&sellTax<=MaxTax&&transferTax<=MaxTax);
    
        marketingShare=marketing;
    
        _liquidityTax=liquidityTaxes;
        _stakingTax=stakingTaxes;
        
        _buyTax=buyTax;
        _sellTax=sellTax;
        _transferTax=transferTax;
        emit OnChangeTaxes(liquidityTaxes, stakingTaxes, buyTax, sellTax, transferTax, marketing);
    }

    //manually converts contract token to LP and staking BNB
    function TeamTriggerLiquify(uint16 pancakePermille, bool ignoreLimits) public onlyTeam{
        _swapContractToken(pancakePermille,ignoreLimits);
    }
    
    event OnExcludeFromStaking(address addr, bool exclude);
    //Excludes account from Staking
    function TeamSetStakingExcluded(address addr, bool exclude) public onlyTeam{
        uint256 shares;
        if(exclude){
            require(!_excludedFromStaking.contains(addr));
            uint256 newDividents=_newDividentsOf(addr);
            shares=getShares(addr);
            _excludedFromStaking.add(addr); 
            _totalShares-=shares;
            alreadyPaidShares[addr]=shares*profitPerShare;
            toBePaid[addr]+=newDividents;
            _autoPayoutList.remove(addr);

        } else _includeToStaking(addr);
        emit OnExcludeFromStaking(addr, exclude);
    }    

    //function to Include own account to staking, should it be excluded
    function IncludeMeToStaking() public{
        _includeToStaking(msg.sender);
    }
    function _includeToStaking(address addr) private{
        require(_excludedFromStaking.contains(addr));
        _excludedFromStaking.remove(addr);
        uint256 shares=getShares(addr);
        _totalShares+=shares;
        //sets alreadyPaidShares to the current amount
        alreadyPaidShares[addr]=shares*profitPerShare;
        if(shares>autoPayoutMinHold) _autoPayoutList.add(addr);
    }
    event OnExclude(address addr, bool exclude);
    //Exclude/Include account from fees and locks (eg. CEX)
    function TeamSetExcludedStatus(address account,bool excluded) public onlyTeam {
        if(excluded){
            _excluded.add(account);
        }
        else{
            require(account!=address(this),"can't Include the contract");
            _excluded.remove(account);
        }

        emit OnExclude(account, excluded);
    }
    event OnExcludeFromSellLock(address addr, bool exclude);
    //Exclude/Include account from fees (eg. CEX)
    function TeamSetExcludedFromSellLock(address account,bool excluded) public onlyTeam {
        if(excluded) _excludedFromLocks.add(account);
        else _excludedFromLocks.remove(account);
       emit OnExcludeFromSellLock(account, excluded);
    }
    event OnChangeLimits(uint256 newBalanceLimit, uint256 newSellLimit);
     //Limits need to be at least target, to avoid setting value to 0(avoid potential Honeypot)
    function TeamChangeLimits(uint256 newBalanceLimit, uint256 newSellLimit) public onlyTeam{
        require((newBalanceLimit>=_circulatingSupply/BalanceLimitDivider)
            &&(newSellLimit>=_circulatingSupply/MinSellLimitDivider));
        balanceLimit = newBalanceLimit;
        sellLimit = newSellLimit;     
        emit OnChangeLimits(newBalanceLimit, newSellLimit);
    }
    event ContractBurn(uint256 amount);
    //Burns token on the contract, like when there is a very large backlog of token
    //or for scheudled BurnEvents
    function TeamBurnContractToken(uint8 percent) public onlyTeam{
        require(percent<=100);
        uint256 burnAmount=_balances[address(this)]*percent/100;
        _removeToken(address(this),burnAmount);
        emit Transfer(address(this), address(0), burnAmount);
        emit ContractBurn(burnAmount);
    }
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Setup Functions///////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    //Creates LP using Payable Amount, LP automatically land on the contract where they get locked
    //once Trading gets enabled
    bool public tradingEnabled;    
    event OnTradingOpen();
    //Enables trading. Turns on bot protection and Locks LP for default Lock time
    function SetupEnableTrading() public onlyTeam{
        require(IBEP20(_pancakePairAddress).totalSupply()>0);
        require(!tradingEnabled);
        tradingEnabled=true;
        _liquidityUnlockTime=block.timestamp+DefaultLiquidityLockTime; 
        
        launchTimestamp=block.timestamp;
        _botProtection=true;
        emit OnTradingOpen();
    }
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Liquidity Lock////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //the timestamp when Liquidity unlocks
    uint256 private _liquidityUnlockTime;
    bool public liquidityRelease20Percent;
    event  LimitReleaseTo20Percent();
    //Sets Liquidity Release to 20% at a time and prolongs liquidity Lock for a Week after Release. 
    //Should be called once start was successful.
    function TeamlimitLiquidityReleaseTo20Percent() public onlyTeam{
        liquidityRelease20Percent=true;
        emit LimitReleaseTo20Percent();
    }
    
    //Prolongs the Liquidity Lock. Lock can't be reduced
    event ProlongLiquidityLock(uint256 secondsUntilUnlock);
    function TeamLockLiquidityForSeconds(uint256 secondsUntilUnlock) public onlyTeam{
        _prolongLiquidityLock(secondsUntilUnlock+block.timestamp);
        emit ProlongLiquidityLock(secondsUntilUnlock);
    }
    function _prolongLiquidityLock(uint256 newUnlockTime) private{
        // require new unlock time to be longer than old one
        require(newUnlockTime>_liquidityUnlockTime);
        _liquidityUnlockTime=newUnlockTime;
    }

    event OnRemoveLiquidity(bool AddToStaking);
    //Removes Liquidity once unlock Time is over, can add LP to staking or to Marketing
    //Add to staking can be used as promotion, or as reward/refund for good holders if Project dies.
    function TeamRemoveLiquidity(bool addToStaking) public onlyTeam {
        //Only callable if liquidity Unlock time is over
        require(block.timestamp >= _liquidityUnlockTime, "Locked");
        _liquidityUnlockTime=block.timestamp+DefaultLiquidityLockTime;
        IPancakeERC20 liquidityToken = IPancakeERC20(_pancakePairAddress);
        uint256 amount = liquidityToken.balanceOf(address(this));
        if(liquidityRelease20Percent) amount=amount*2/10; //only remove 20% each
        liquidityToken.approve(address(_pancakeRouter),amount);
        //Removes Liquidity and either distributes liquidity BNB to stakers, or 
        // adds them to marketing Balance
        //Token will be converted
        //to Liquidity and Staking BNB again
        uint256 initialBNBBalance = address(this).balance;
        _pancakeRouter.removeLiquidityETHSupportingFeeOnTransferTokens(
            address(this),
            amount,
            0,
            0,
            address(this),
            block.timestamp
            );
        uint256 newBNBBalance = address(this).balance-initialBNBBalance;
        if(addToStaking) _distributeStake(newBNBBalance);
        else marketingBalance+=newBNBBalance;
        
        emit OnRemoveLiquidity(addToStaking);
    }
    event OnRemoveRemainingBNB();
    function TeamRemoveRemainingBNB() public onlyTeam{
        require(block.timestamp >= _liquidityUnlockTime+30 days, "Locked");
        _liquidityUnlockTime=block.timestamp+DefaultLiquidityLockTime;
        _distributeMarketingBNB(address(this).balance);
        emit OnRemoveRemainingBNB();
    }
    //Allows the team to withdraw token that get's accidentally sent to the contract(happens way too often)
    //Can't withdraw the LP token, this token or the promotion token
    function TeamWithdrawStrandedToken(address strandedToken) public onlyTeam{
        require((strandedToken!=_pancakePairAddress)&&strandedToken!=address(this));
        IBEP20 token=IBEP20(strandedToken);
        token.transfer(TeamWallet1,token.balanceOf(address(this)));
    }

    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //external//////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    receive() external payable {
        //only allow pancakeRouter to send BNB
        require(msg.sender==address(PancakeRouter));
    }
    // IBEP20

    function getOwner() external view override returns (address) {
        return owner();
    }
    function name() external pure override returns (string memory) {
        return _name;
    }
    function symbol() external pure override returns (string memory) {
        return _symbol;
    }
    function decimals() external pure override returns (uint8) {
        return _decimals;
    }
    function totalSupply() external view override returns (uint256) {
        return _circulatingSupply;
    }
    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    function allowance(address _owner, address spender) external view override returns (uint256) {
        return _allowances[_owner][spender];
    }
    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0));
        require(spender != address(0));

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount);

        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }
    // IBEP20 - Helpers
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue);

        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }
}