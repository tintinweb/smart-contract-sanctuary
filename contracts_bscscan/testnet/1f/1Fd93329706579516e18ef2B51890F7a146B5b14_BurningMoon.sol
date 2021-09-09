//                                                                  %%%%%%%%%%                                                                          
//                                                      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                                                              
//                                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                                                        
//                                           %%%%%%%%%%%%%%%%%%             %%%%%%%%%%%%%%%%%%%%%%%%%                                                   
//                                       %%%%%%%%%%%                                  %%%%%%%%%%%%%%%%%%%                                               
//                                    %%%%%%%%%                                             %%%%%%%%%%%%%%%%                                            
//                                 %%%%%%%                        ///                            %%%%%%%%%%%%%%                                         
//                               %%%%%%                            /////                            %%%%%%%%%%%%%                                       
//                            %%%%%                  ***            //////                             %%%%%%%%%%%%%                                    
//                           %%%%               ***                 ////////                              %%%%%%%%%%%                                   
//                         %%%%             ***                     //////////                              %%%%%%%%%%%                                 
//                       %%%%            ***                       ////////////              %%               %%%%%%%%%%%                               
//                      %%%           ****                         ////////////             %%%                 %%%%%%%%%%                              
//                     %%           ****                          //////////////            %%%                   %%%%%%%%%                             
//                    %%          ****                           ///////////////            %%%%                   %%%%%%%%%                            
//                   %%         *****                            ///////////////            %%%%%                   %%%%%%%%%                           
//                  %%         *****                            ///////////////              %%%%%%                  %%%%%%%%%                          
//                  %         *****           *                /////// ////////               %%%%%%                  %%%%%%%%                          
//                 %         *****             ***           ///////   ///////                 %%%%%%%                 %%%%%%%%                         
//                          *****              ****         ///////   ///////        (           %%%%%%                %%%%%%%%                         
//                %        ,*****              ****       ///////    ///////          ((          %%%%%%                %%%%%%%%                        
//                %        *****              ******   **//////     ///////            ((((         %%%%%      #        %%%%%%%%                        
//                         *****              ***********////      ///////             (((((         %%%%      #        %%%%%%%%                        
//                       ,*****             ***********///       ///////              (((((((        %%%      #         %%%%%%%                        
//                       ,*****            ************         ///////               ((((((((       %%%      #         %%%%%%%                        
//                       ,******          ***********          ///////                (((((((((      %%       #        %%%%%%%                         
//                        ******          **********           //////                (((((((((((     %       ##        %%%%%%%                         
//                        *******        *********             ///////             ((((((((((((((           ###        %%%%%%                          
//                        ,*******       ********              /////////////////////(((( ((((((((           ##        %%%%%%%                          
//                         ********      ********              ////////////////////((((  ((((((((          ##        %%%%%%%                           
//                          ********      *******                //////////////////(((   ((((((((        ((##        %%%%%%                            
//                           ********     *******                  ////////////////      ((((((((       ((((        %%%%%%                             
//                            *********     ******                     /////////        ((((((((      ((((         %%%%%%                              
//                             **********     *****                                    ((((((((     (((((        %%%%%%                                
//                               **********     ****                                  ((((((((    (((((         %%%%%%                                 
//                                 ***********      **                               ((((((((  ((((((         %%%%%%                                   
//                                   ************                                  ((((((((((((((((         %%%%%%                                     
//                                       **************                         ////((((((((((((((         %%%%%%                                       
//                                         *************/////            //////////(((((((((((          %%%%%                                          
//                                             *********///////////////////////////(((((((           %%%%%                                             
//                                                    ****//////////////////////////((             %%%%%                                                
//                                                            //////////////                  %%%%%                                                    
//                                                                                      %%%%%                                                         
//                                                                                %%%%                                                                 
//
//                  ██████╗ ██╗   ██╗██████╗ ███╗   ██╗██╗███╗   ██╗ ██████╗ ███╗   ███╗ ██████╗  ██████╗ ███╗   ██╗
//                  ██╔══██╗██║   ██║██╔══██╗████╗  ██║██║████╗  ██║██╔════╝ ████╗ ████║██╔═══██╗██╔═══██╗████╗  ██║
//                  ██████╔╝██║   ██║██████╔╝██╔██╗ ██║██║██╔██╗ ██║██║  ███╗██╔████╔██║██║   ██║██║   ██║██╔██╗ ██║
//                  ██╔══██╗██║   ██║██╔══██╗██║╚██╗██║██║██║╚██╗██║██║   ██║██║╚██╔╝██║██║   ██║██║   ██║██║╚██╗██║
//                  ██████╔╝╚██████╔╝██║  ██║██║ ╚████║██║██║ ╚████║╚██████╔╝██║ ╚═╝ ██║╚██████╔╝╚██████╔╝██║ ╚████║
//                  ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝     ╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝

// https://www.burningmoon.xyz
// https://t.me/BurningMoonBSC
// https://t.me/BurningMoonBSC_ann
// https://twitter.com/BurningMoonBSC

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./Libraries.sol";



////////////////////////////////////////////////////////////////////////////////////////////////////////
//BURNINGMOON Contract /////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////
contract BurningMoon is IBEP20, Ownable
{
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _sellLock;

    EnumerableSet.AddressSet private _excluded;
    EnumerableSet.AddressSet private _excludedFromLocks;
    EnumerableSet.AddressSet private _excludedFromStaking;
    EnumerableSet.AddressSet private _whiteList;
    EnumerableSet.AddressSet private _automatedMarketMakers;
    
    //Token Info
    string private constant _name = 'BurningMoon';
    string private constant _symbol = 'BM';
    uint8 private constant _decimals = 9;
    uint256 public constant InitialSupply= 1200 * 10**6 * 10**_decimals;//equals 1,200,000,000 token

    //Lower limit for the balance Limit, can't be set lower
    uint8 public constant BalanceLimitDivider=100;
    //Lower limit for the sell Limit, can't be set lower
    uint16 public constant MinSellLimitDivider=2000;
    //Sellers get locked for sellLockTime so they can't dump repeatedly
    uint16 public constant MaxSellLockTime= 2 hours;
    //The time Liquidity gets locked at start and prolonged once it gets released
    uint256 private constant DefaultLiquidityLockTime=7 days;
    //The Team Wallet is a Multisig wallet that reqires 3 signatures for each action
    address public TeamWallet=0xcA3D0E9359a85409B8EC4b9954079Ee2EfaaD779;

    address private constant SacrificeAddress=0x000000000000000000000000000000000000dEaD;
    address private constant lotteryAddress=0x7777777777777777777777777777777777777777;

    //variables that track balanceLimit and sellLimit,
    //can be updated based on circulating supply and Sell- and BalanceLimitDividers
    uint256 private _circulatingSupply;
    uint256 private balanceLimit=InitialSupply/BalanceLimitDivider;
    uint256 private sellLimit=InitialSupply/MinSellLimitDivider;

    //Limits max tax, only gets applied for tax changes, doesn't affect inital Tax
    uint8 public constant MaxTax=25;
    uint256 public sellLockTime=MaxSellLockTime;
    //Tracks the current Taxes, different Taxes can be applied for buy/sell/transfer
    //Taxes can never exceed MaxTax
    uint8 private _buyTax=10;
    uint8 private _sellTax=20;
    //Transfer tax starts at 50%. this is to stop whitelisted from transfering.
    //will later be capped at 25%
    uint8 private _transferTax=50;
    //The shares of the specific Taxes, always needs to equal 100%
    uint8 private _burnTax=5;
    uint8 private _liquidityTax=95;
    uint8 private _stakingTax=0;
    //The shares of the staking Tax that get used for Marketing/lotterySplit
    uint8 public marketingShare=50;
    //Lottery share is used for Lottery draws, addresses can buy lottery tickets for Token
    uint8 public LotteryShare=10;
    //determines the permille of the pancake pair needed to trigger Liquify
    uint8 public LiquifyTreshold=50;

    //BotProtection values
    bool private _botProtection;
    uint8 constant BotMaxTax=100;
    uint256 constant BotTaxTime=10 minutes;
    uint256 constant WLTaxTime=4 minutes;
    uint256 public launchTimestamp;
    
    //_pancakePairAddress is also equal to the liquidity token address
    //LP token are locked in the contract
    address private _pancakePairAddress; 
    IPancakeRouter02 private  _pancakeRouter; 
    //TODO: Change to Mainnet
    //TestNet
    address private constant PancakeRouter=0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    //MainNet
    //address private constant PancakeRouter=0x10ED43C718714eb63d5aA57B78B54704E256024E;
    
    //modifier for functions only the team can call
    modifier onlyTeam() {
        require(_isTeam(msg.sender), "Caller not in Team");
        _;
    }
    //Checks if address is in Team, is needed to give Team access even if contract is renounced
    //Team doesn't have access to critical Functions that could turn this into a Rugpull(Exept liquidity unlocks)
    function _isTeam(address addr) private view returns (bool){
        return addr==owner()||addr==TeamWallet;
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
        //contract gets 100% of the supply to create LP
        _addToken(address(this),InitialSupply);
        emit Transfer(address(0), address(this), InitialSupply);
        //Team wallet deployer and contract are excluded from Taxes
        //contract can't be included to taxes
        _excluded.add(TeamWallet);
        _excluded.add(msg.sender);
        _excluded.add(address(this));
        _approve(address(this), address(_pancakeRouter), type(uint256).max);
    }
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Transfer functionality////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    address oneTimeExcluded;
    //picks the transfer function
    function _transfer(address sender, address recipient, uint256 amount) private{
        require(sender != address(0), "from zero");
        require(recipient != address(0), "to zero");
        //If recipient is SacrificeAddress, token will be sacrificed, resulting in 2x rewards, but burned token
        if(recipient==SacrificeAddress){
            _sacrifice(sender,amount);
            return;
        }
        //If recipient is lotteryAddress, token will be used to buy lottery tickets
        if(recipient==lotteryAddress){
            _buyLotteryTickets(sender,amount);
            return;
        }
        //Burn Token if recipient is address(1) 0x000..0001
        if(recipient==address(1)){
            require(_balances[sender]>=amount);
            _removeToken(sender, amount);
            emit Transfer(sender,address(1),amount);
            return;
        }

        bool isExcluded=_excluded.contains(sender) || _excluded.contains(recipient);
        //one time excluded (compound) transfer without limits
        if(oneTimeExcluded==recipient){
            isExcluded=true;
            oneTimeExcluded=address(0);
        }

        //excluded adresses are transfering tax and lock free
        if(isExcluded){
            _feelessTransfer(sender, recipient, amount);
            return;
        }
        //once trading is enabled, it can't be turned off again
        require(tradingEnabled,"trading not yet enabled"); 
        _regularTransfer(sender,recipient,amount);
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

            tax=_getTaxWithBonus(sender,_sellTax);

        } else if(isBuy){
            //Checks If the recipient balance(excluding Taxes) would exceed Balance Limit
            require(_excludedFromLocks.contains(recipient)||(recipientBalance+amount<=balanceLimit),"whale");
            tax=_getBuyTax(recipient);

        } else {//Transfer
            //withdraws BNB when sending to yourself
            //if sender and recipient are the same address initiate BNB claim
            if(sender==recipient){
                _claimBNBTo(sender,sender,getDividents(sender));
                return;}
            
            //Checks If the recipient balance(excluding Taxes) would exceed Balance Limit
            require(_excludedFromLocks.contains(recipient)||recipientBalance+amount<=balanceLimit,"whale");
            tax=_getTaxWithBonus(sender,_transferTax);

        }     
        
        //Swapping AutoLP and MarketingBNB is only possible if sender is not pancake pair, 
        //if its not manually disabled, if its not already swapping
        if((sender!=_pancakePairAddress)&&(!swapAndLiquifyDisabled)&&(!_isSwappingContractModifier))
            _swapContractToken(LiquifyTreshold,false);
            
        _transferTaxed(sender,recipient,amount,tax);
    }
    function _transferTaxed(address sender, address recipient, uint256 amount, uint8 tax) private{
        uint256 totalTaxedToken=_calculateFee(amount, tax, 100);
        uint256 tokenToBeBurnt=_calculateFee(amount, tax, _burnTax);
        uint256 taxedAmount=amount-totalTaxedToken;
        //Removes token and handles staking
        _removeToken(sender,amount);
        //Adds the taxed tokens -burnedToken to the contract
        _addToken(address(this), (totalTaxedToken-tokenToBeBurnt));
        //Adds token and handles staking
        _addToken(recipient, taxedAmount);
        emit Transfer(sender,recipient,taxedAmount);
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
    function _getBuyTax(address recipient) private returns (uint8){
        //returns the Tax subtracting promotion Bonus
        if(!_botProtection) return _getTaxWithBonus(recipient,_buyTax);
        bool isWhitelisted=_whiteList.contains(recipient);
        uint256 duration;
        //Whitelist has a shorter Bot Protection Time
        if(isWhitelisted) duration=WLTaxTime;
        else duration=BotTaxTime;
        uint8 Tax;
        if(block.timestamp>launchTimestamp+duration){
            Tax=_buyTax;
            if(!isWhitelisted){
                _burnTax=25;
                _liquidityTax=25;
                _stakingTax=50;
                _botProtection=false;
            }
        }
        else Tax=_getBotTax(duration);
        //returns the Tax subtracting promotion Bonus
        return _getTaxWithBonus(recipient, Tax);

    }
    
    function _getBotTax(uint256 duration) private view returns (uint8){
        uint256 timeSinceLaunch=block.timestamp-launchTimestamp;
        return uint8(BotMaxTax-((BotMaxTax-_buyTax)*timeSinceLaunch/duration));
    }
    //Gets the promotion Bonus if enough promotion Token are held
    function _getTaxWithBonus(address bonusFor, uint8 tax) private view returns(uint8){
        if(_isEligibleForPromotionBonus(bonusFor)){
            if(tax<=promotionTaxBonus) return 0;
            return tax-promotionTaxBonus;
        }
        return tax;
    }
    function _isEligibleForPromotionBonus(address bonusFor)private view returns(bool){
        //if promotion token isn't set, return false
        if(address(promotionToken) == address(0)) return false;
        uint256 tokenBalance;
        //tries to get the balance of the address the bonus is for, catches possible errors that could make the token untradeable
        //token has to implement "balanceOf" gets checked when setting the token
        try promotionToken.balanceOf(bonusFor) returns (uint256 promotionTokenBalance){ 
            tokenBalance=promotionTokenBalance;
        }catch{return false;}
        //If holder holds more than min hold, holder is eligible
        return (tokenBalance>=promotionMinHold);
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
    
    //lock for the withdraw, only one withdraw can happen at a time
    bool private _isWithdrawing;
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
    //The current Lottery Balance
    uint256 public lotteryBNB;
    //If someone sacrifices their BurningMoon, they receive additionalShares
    mapping(address => uint256) private additionalShares;   
    //Mapping of the already paid out(or missed) shares of each staker
    mapping(address => uint256) private alreadyPaidShares;
    //Mapping of shares that are reserved for payout
    mapping(address => uint256) private toBePaid;
    
    uint256 public sacrificedToken;
    bool private isSacrificing;
    event OnSacrifice(uint256 amount, address sender);
    //Sacrifices BurningMoon, BurningMoon get burned, nothing remains exept 2x rewards for the one bringing the sacrifice
    function _sacrifice(address account,uint256 amount) private{
        require(!_excludedFromStaking.contains(account), "Excluded!");
        require(amount<=_balances[account]);
        require(!isSacrificing);
        isSacrificing=true;
        //Removes token and burns them
        _removeToken(account, amount);
        sacrificedToken+=amount;
        //The new shares will be 2x the burned shares
        uint256 newShares=amount*2;
        _totalShares+=newShares;

        additionalShares[account]+=newShares;
        //Resets the paid mapping to the new amount
        alreadyPaidShares[account] = profitPerShare * getShares(account);
        emit Transfer(account,SacrificeAddress,amount);
        emit OnSacrifice(amount, account);
        isSacrificing=false;
    }
    function Sacrifice(uint256 amount) public{
        _sacrifice(msg.sender,amount);
    }
    //Transfers the sacrifice to another account
    event OnTransferSacrifice(uint256 amount, address sender,address recipient);
    function TransferSacrifice(address target, uint256 amount) public{
        require(!_excludedFromStaking.contains(target)&&!_excludedFromStaking.contains(msg.sender));
        uint256 senderShares=additionalShares[msg.sender];
        require(amount<=senderShares,"exceeds shares");
        require(!isSacrificing);
        isSacrificing=true;
        
        //Handles the removal of the shares from the sender
        uint256 paymentSender=_newDividentsOf(msg.sender);
        additionalShares[msg.sender]=senderShares-amount;
        alreadyPaidShares[msg.sender] = profitPerShare * getShares(msg.sender);
        toBePaid[msg.sender]+=paymentSender;
        
        //Handles the addition of the shares to the recipient
        uint256 paymentReceiver=_newDividentsOf(target);
        uint256 newAdditionalShares=additionalShares[target]+amount;
        alreadyPaidShares[target] = profitPerShare * (_balances[target]+newAdditionalShares);
        toBePaid[target]+=paymentReceiver;
        additionalShares[target]=newAdditionalShares;
        
        emit OnTransferSacrifice(amount, msg.sender, target);
        isSacrificing=false;
    }



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
        alreadyPaidShares[addr] = profitPerShare * (newAmount+additionalShares[addr]);
        //adds dividents to the toBePaid mapping
        toBePaid[addr]+=payment; 
        //sets newBalance
        _balances[addr]=newAmount;


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
        uint256 lotterySplit = (AmountWei*LotteryShare) / 100;
        uint256 amount = AmountWei - (marketingSplit+lotterySplit);

        lotteryBNB+=lotterySplit;
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
            alreadyPaidShares[addr] = profitPerShare * getShares(addr);
            //the amount to be paid 
            toBePaid[addr]+=newAmount;
            toBePaid[addr]-=amount;
        }
    }
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Claim Functions///////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////// 

    //PromotionToken
    IBEP20 public promotionToken;
    //Boost BNB are added to the dividents based on the Boost Percentage
    uint256 public BoostBNB;
    uint8 public promotionBNBBoostPercentage;
    //Boost Token are sent after transfer, based on the Percentage and the amount received
    uint8 public promotionTokenBoostPercentage;
    //Allows to claim token via the contract. this makes it possible To
    //make special Rules for the Promotion token
    bool public ClaimPromotionTokenViaContract;
    //Holders of the promotion token get a Tax bonus
    uint8 public promotionTaxBonus;
    uint256 public promotionMinHold;
    event SetPromotionToken(address token);
    //Sets new promotion Token, checks if the token implements "BalanceOf".
    function TeamSetPromotionToken (
        address token, 
        uint8 BNBboostPercentage,
        uint8 TokenBoostPercentage, 
        bool claimViaContract, 
        uint8 TaxBonus,
        uint256 MinHold) public onlyTeam{
        require(token!=address(this)&&token!=_pancakePairAddress,"Invalid token");
        promotionToken=IBEP20(token);
        //check if token implements balanceOf
        promotionToken.balanceOf(address(this));
        
        promotionBNBBoostPercentage=BNBboostPercentage;
        promotionTokenBoostPercentage=TokenBoostPercentage;
        //claim via contract makes it possible to make special offers for the contract
        ClaimPromotionTokenViaContract=claimViaContract;
        promotionMinHold=MinHold;
        promotionTaxBonus=TaxBonus;
        emit SetPromotionToken(token);
    }
    event OnClaimPromotionToken(address AddressTo, uint256 amount);
    //Claims the promotion Token with 100% of the dividents
    function ClaimPromotionToken() public payable{
        ClaimPromotionToken(getDividents(msg.sender));
    }
    //Claims the promotion token, boost and special rules Apply to promotion token
    //No boost does apply to payable amount
    bool private _isClaimingPromotionToken;
    function ClaimPromotionToken(uint256 amountWei) public payable{
        require(!_isClaimingPromotionToken,"already Claiming Token");
        _isClaimingPromotionToken=true;
        uint256 totalAmount=amountWei+msg.value;
        require(totalAmount>0,"Nothing to claim");
        //Gets the token and the initial balance
        IBEP20 tokenToClaim=IBEP20(promotionToken);
        uint256 initialBalance=tokenToClaim.balanceOf(msg.sender);
        //Claims token using dividents
        if(amountWei>0){
            //only boosts the amount, not the payable amount
            uint256 boost=amountWei*promotionBNBBoostPercentage/100;
            //if boost exceeds boost funds, clamp the boost
            if(boost>BoostBNB) boost=BoostBNB;
            BoostBNB-=boost;
            //if token allows it, can claim via contract to enable things like tax free claim
            if(ClaimPromotionTokenViaContract){
                _claimTokenViaContract(msg.sender, address(promotionToken), amountWei,boost);
            }else _claimToken(msg.sender, address(promotionToken), amountWei,boost);
            
            //Apply the tokenBoost
            uint256 contractBalance=tokenToClaim.balanceOf(address(this));
            if(promotionTokenBoostPercentage>0&&contractBalance>0)
            {
                //the actual amount of claimed token
                uint256 claimedToken=tokenToClaim.balanceOf(msg.sender)-initialBalance;
                //calculates the tokenBoost
                uint256 tokenBoost=claimedToken*promotionTokenBoostPercentage/100;
                if(tokenBoost>contractBalance)tokenBoost=contractBalance;
                //transfers the tokenBoost
                tokenToClaim.transfer(msg.sender,tokenBoost);   
            }
        }
        //claims promotion Token with the payable amount, no boost applies
        if(msg.value>0)_claimToken(msg.sender,address(promotionToken),0,msg.value);
        
        //gets the total claimed token and emits the event
        uint256 totalClaimed=tokenToClaim.balanceOf(msg.sender)-initialBalance;
        emit OnClaimPromotionToken(msg.sender,totalClaimed);
        _isClaimingPromotionToken=false;
    }
    
    event OnCompound(address AddressTo, uint256 amount);
    //Compounds BNB to buy BM, Compound is tax free
    function Compound() public{
        uint256 initialBalance=_balances[msg.sender];
        //Compound is tax free and can exceed max hold
        oneTimeExcluded=msg.sender;
        _claimToken(msg.sender, address(this), getDividents(msg.sender),0);
        uint256 claimedToken=_balances[msg.sender]-initialBalance;
        emit OnCompound(msg.sender,claimedToken);
    }
    
    event OnClaimBNB(address AddressFrom,address AddressTo, uint256 amount);
    function ClaimBNB() public{
        _claimBNBTo(msg.sender,msg.sender,getDividents(msg.sender));
    }
    function ClaimBNBTo(address to) public{
         _claimBNBTo(msg.sender,to,getDividents(msg.sender));
    }

    event OnClaimToken(address AddressTo,address Token, uint256 amount);
    //Claims any token can add BNB to purchase more
    function ClaimAnyToken(address token) public payable{
        ClaimAnyToken(token,getDividents(msg.sender));
    }
    function ClaimAnyToken(address tokenAddress,uint256 amountWei) public payable{
        IBEP20 token=IBEP20(tokenAddress);
        uint256 initialBalance=token.balanceOf(msg.sender);
        _claimToken(msg.sender, tokenAddress,amountWei,msg.value);
        uint256 claimedToken=token.balanceOf(msg.sender)-initialBalance;
        emit OnClaimToken(msg.sender,tokenAddress,claimedToken);
    }
    
    //Helper functions to claim Token or BNB
    //claims the amount of BNB from "from" and withdraws them "to"
    function _claimBNBTo(address from, address to,uint256 amountWei) private{
        require(!_isWithdrawing);
        require(amountWei!=0,"=0");    
        _isWithdrawing=true;
        //Substracts the amount from the dividents
        _substractDividents(from, amountWei);
        totalPayouts+=amountWei;
        (bool sent,) =to.call{value: (amountWei)}("");
        require(sent,"withdraw failed");
        _isWithdrawing=false;
        emit OnClaimBNB(from,to,amountWei);
    }
 
 
    
    //claims any token and sends it to addr for the amount in BNB
    function _claimToken(address addr, address token, uint256 amountWei,uint256 boostWei) private{
        require(!_isWithdrawing);
        require(amountWei!=0||boostWei!=0,"=0");        
        _isWithdrawing=true;
        //Substracts the amount from the dividents
        _substractDividents(addr, amountWei);
        uint256 totalAmount=amountWei+boostWei;
        totalPayouts+=amountWei;
        address[] memory path = new address[](2);
        path[0] = _pancakeRouter.WETH(); //BNB
        path[1] = token;  
        
        //purchases token and sends them to the target address
        _pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: totalAmount}(
        0,
        path,
        addr,
        block.timestamp);
        
        _isWithdrawing=false;
    }

    //Claims token via the contract, enables to make special offers for the contract
    function _claimTokenViaContract(address addr, address token, uint256 amountWei,uint256 boostWei) private{
        require(!_isWithdrawing);
        require(amountWei!=0||boostWei!=0,"=0");      
        _isWithdrawing=true;
        //Substracts the amount from the dividents
        _substractDividents(addr, amountWei);
        //total amount is amount+boost
        uint256 totalAmount=amountWei+boostWei;
        totalPayouts+=amountWei;
        
        //Purchases token and sends them to the contract
        address[] memory path = new address[](2);
        path[0] = _pancakeRouter.WETH(); //BNB
        path[1] = token;  
        IBEP20 claimToken=IBEP20(token);
        uint256 initialBalance=claimToken.balanceOf(address(this));
        _pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: totalAmount}(
        0,
        path,
        address(this),
        block.timestamp);
        //newBalance captures only new token
        uint256 newBalance=claimToken.balanceOf(address(this))-initialBalance;
        //transfers all new token from the contract to the address
        claimToken.transfer(addr, newBalance);
        _isWithdrawing=false;
    }
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Lottery///////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    uint256 public lotteryTicketPrice=1000*(10**_decimals); //StartPrize Lottery 1000 token
    //The Lottery tickets array, each address stored is a ticket
    address[] private lotteryTickets;
    //The Amount of Lottery tickets in the current round
    uint256 public LotteryParticipants;
    uint256 lastLotteryDraw;
    event OnBuyLotteryTickets(uint256 FirstTicketID, uint256 LastTicketID, address account);
    //Buys entry to the Lottery, burns token
    function _buyLotteryTickets(address account,uint256 token) private{
        uint256 tickets=token/lotteryTicketPrice;
        require(tickets<500);

        uint256 totalPrice=tickets*lotteryTicketPrice;
        require(block.timestamp>lastLotteryDraw+30 minutes);        
        require(_balances[account]>=totalPrice,">Balance");
        require(tickets>0,"<1 ticket");
        uint256 FirstTicketID=LotteryParticipants;
        //Removes the token from the sender
        _removeToken(account,totalPrice);
        //Adds tickets to the tickets array
        for(uint256 i=0; i<tickets; i++){
            if(lotteryTickets.length>LotteryParticipants)
                lotteryTickets[LotteryParticipants]=account;
            else lotteryTickets.push(account);    
            LotteryParticipants++;
        }        
        emit Transfer(account,lotteryAddress,totalPrice);
        emit  OnBuyLotteryTickets(FirstTicketID,LotteryParticipants-1,account);
    }
    function BuyLotteryTickets(uint256 token) public{
        _buyLotteryTickets(msg.sender,token);
    }
    
    function _getPseudoRandomNumber(uint256 modulo) private view returns(uint256) {
        //uses WBNB-Balance to add a bit unpredictability
        uint256 WBNBBalance = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c).balance;
        
        //generates a PseudoRandomNumber
        uint256 randomResult = uint256(keccak256(abi.encodePacked(
            _circulatingSupply +
            _balances[_pancakePairAddress] +
            WBNBBalance + 
            block.timestamp + 
            block.difficulty +
            block.gaslimit
            ))) % modulo;
            
        return randomResult;    
    }
    event DrawLotteryWinner(address winner, uint256 amount);
    function TeamDrawLotteryWinner(uint256 newLotteryTicketPrice) public onlyTeam{
        require(LotteryParticipants>0);
        uint256 prize=lotteryBNB;
        lastLotteryDraw=block.timestamp;
        lotteryBNB=0;
        uint256 winner=_getPseudoRandomNumber(LotteryParticipants);
        address winnerAddress=lotteryTickets[winner];
        LotteryParticipants=0;
        lotteryTicketPrice=newLotteryTicketPrice;

       (bool sent,) = winnerAddress.call{value: (prize)}("");
        require(sent);
        emit DrawLotteryWinner(winnerAddress, prize);
    }

    function getLotteryTicketHolder(uint256 TicketID) public view returns(address){
        require(TicketID<LotteryParticipants,"Doesn't exist");
        return lotteryTickets[TicketID];
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
        if(_allowances[address(this)][address(_pancakeRouter)]<tokenToSwap)
            _approve(address(this), address(_pancakeRouter), type(uint256).max);
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
        return (_balances[addr]+additionalShares[addr]);
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
    
    function getBurnedTokens() public view returns(uint256){
        return (InitialSupply-_circulatingSupply);
    }

    function getTaxes() public view returns(
    uint256 buyTax, 
    uint256 sellTax, 
    uint256 transferTax, 
    uint8 whitelistBuyTax,
    uint256 burnTax,
    uint256 liquidityTax,
    uint256 stakingTax){
            if(block.timestamp>launchTimestamp+BotTaxTime)
            buyTax=_buyTax;
            else buyTax=_getBotTax(BotTaxTime);

            if(block.timestamp>launchTimestamp+WLTaxTime)
            whitelistBuyTax=_buyTax;
            else whitelistBuyTax=_getBotTax(WLTaxTime);

            sellTax=_sellTax;
            transferTax=_transferTax;

            burnTax=_burnTax;
            liquidityTax=_liquidityTax;
            stakingTax=_stakingTax;


    }
    
    function getStatus(address AddressToCheck) public view returns(
        bool Whitelisted, 
        bool Excluded, 
        bool ExcludedFromLock, 
        bool ExcludedFromStaking, 
        uint256 SellLock,
        bool eligibleForPromotionBonus,
        uint256 additionalShare){
        uint256 lockTime=_sellLock[AddressToCheck];
       if(lockTime<=block.timestamp) lockTime=0;
       else lockTime-=block.timestamp;
       uint256 shares=additionalShares[AddressToCheck];
        return(
            _whiteList.contains(AddressToCheck),
            _excluded.contains(AddressToCheck),
            _excludedFromLocks.contains(AddressToCheck),
            _excludedFromStaking.contains(AddressToCheck),
            lockTime,
            _isEligibleForPromotionBonus(AddressToCheck),
            shares
            );
    }
    
    //Returns the not paid out dividents of an address in wei
    function getDividents(address addr) public view returns (uint256){
        return _newDividentsOf(addr)+toBePaid[addr];
    }
    
    //Adds BNB to the contract to either boost the Promotion Token, or add to stake, everyone can add Funds
    function addFunds(bool boost, bool stake)public payable{
        require(!_isWithdrawing);
        if(boost) BoostBNB+=msg.value;
        else if(stake) _distributeStake(msg.value);
        else marketingBalance+=msg.value;
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
        require(msg.sender==TeamWallet);
        TeamWallet=newTeamWallet;
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
        (bool sent,) =TeamWallet.call{value: (amount)}("");
        require(sent,"withdraw failed");
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
    event OnChangeTaxes(uint8 burnTaxes, uint8 liquidityTaxes, uint8 stakingTaxes,uint8 buyTax, uint8 sellTax, uint8 transferTax, uint8 marketing,uint8 lottery);
    //Sets Taxes, is limited by MaxTax(25%) to make it impossible to create honeypot
    function TeamSetTaxes(uint8 burnTaxes, uint8 liquidityTaxes, uint8 stakingTaxes,uint8 buyTax, uint8 sellTax, uint8 transferTax, uint8 marketing,uint8 lottery) public onlyTeam{
        uint8 totalTax=burnTaxes+liquidityTaxes+stakingTaxes;
        require(totalTax==100);
        require(buyTax<=MaxTax&&sellTax<=MaxTax&&transferTax<=MaxTax);
        require(marketing+lottery<=50); 
    
        marketingShare=marketing;
        LotteryShare=lottery;
    
        _burnTax=burnTaxes;
        _liquidityTax=liquidityTaxes;
        _stakingTax=stakingTaxes;
        
        _buyTax=buyTax;
        _sellTax=sellTax;
        _transferTax=transferTax;
        emit OnChangeTaxes(burnTaxes, liquidityTaxes, stakingTaxes, buyTax, sellTax,  transferTax, marketing, lottery);
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
    function SetupCreateLP(uint8 ContractTokenPercent, uint8 TeamTokenPercent) public payable onlyTeam{
        require(IBEP20(_pancakePairAddress).totalSupply()==0);
        
        uint256 Token=_balances[address(this)];
        
        uint256 TeamToken=Token*TeamTokenPercent/100;
        uint256 ContractToken=Token*ContractTokenPercent/100;
        uint256 LPToken=Token-(TeamToken+ContractToken);
        
        _removeToken(address(this),TeamToken);  
        _addToken(msg.sender, TeamToken);
        emit Transfer(address(this), msg.sender, TeamToken);
        
        _addLiquidity(LPToken, msg.value);
        require(IBEP20(_pancakePairAddress).totalSupply()>0);
        
    }
    
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
    
    //Adds or removes a List of addresses to Whitelist
    function SetupWhitelist(address[] memory addresses, bool Add) public onlyTeam{
        if(Add)
            for(uint i=0; i<addresses.length; i++)
                _whiteList.add(addresses[i]);
        else
            for(uint i=0; i<addresses.length; i++)
                _whiteList.remove(addresses[i]);
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


    event OnReleaseLiquidity();
    //Release Liquidity Tokens once unlock time is over
    function TeamReleaseLiquidity() public onlyTeam {
        //Only callable if liquidity Unlock time is over
        require(block.timestamp >= _liquidityUnlockTime, "Locked");
        _liquidityUnlockTime=block.timestamp+DefaultLiquidityLockTime;       
        IPancakeERC20 liquidityToken = IPancakeERC20(_pancakePairAddress);
        uint256 amount = liquidityToken.balanceOf(address(this));
        if(liquidityRelease20Percent) amount=amount*2/10;
        liquidityToken.transfer(TeamWallet, amount);
        emit OnReleaseLiquidity();
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
    //Releases all remaining BNB on the contract wallet, so BNB wont be burned
    //Can only be called 30 days after Liquidity unlocks so staked BNB stay safe
    //Once called it breaks staking
    function TeamRemoveRemainingBNB() public onlyTeam{
        require(block.timestamp >= _liquidityUnlockTime+30 days, "Locked");
        _liquidityUnlockTime=block.timestamp+DefaultLiquidityLockTime;
        (bool sent,) =TeamWallet.call{value: (address(this).balance)}("");
        require(sent);
        emit OnRemoveRemainingBNB();
    }
    
    //Allows the team to withdraw token that get's accidentally sent to the contract(happens way too often)
    //Can't withdraw the LP token, this token or the promotion token
    function TeamWithdrawStrandedToken(address strandedToken) public onlyTeam{
        require((strandedToken!=_pancakePairAddress)&&strandedToken!=address(this)&&strandedToken!=address(promotionToken));
        IBEP20 token=IBEP20(strandedToken);
        token.transfer(TeamWallet,token.balanceOf(address(this)));
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