////////////////////////////////////////////////////////////////////////////////////////////////////////
//MoonX Contract ////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./Libraries.sol";


contract MoonX is IBEP20, Ownable
{
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    EnumerableSet.AddressSet private _excluded;
    //Token Info
    string private constant _name = 'MoonX';
    string private constant _symbol = 'MoonX';
    uint8 private constant _decimals = 18;
    uint256 public immutable InitialSupply;

    //Divider for the MaxBalance based on circulating Supply (2.5%)
    uint8 public constant MaxBalanceDivider=100;
    //The time Liquidity gets locked at start and prolonged once it gets released
    uint256 private constant DefaultLiquidityLockTime=7 days;

    //TestNet
    //address private constant PancakeRouter=0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    //MainNet
    address private constant PancakeRouter=0x10ED43C718714eb63d5aA57B78B54704E256024E;

    //variables that track balanceLimit and sellLimit,
    //can be updated based on circulating supply and Sell- and BalanceLimitDividers
    uint256 private _circulatingSupply;
    uint256 public  balanceLimit = _circulatingSupply;
    
    //Tracks the current Taxes, different Taxes can be applied for buy/sell/transfer
    uint256 private _buyTax =1900;
    uint256 private _sellTax =2500;
    uint256 private _transferTax=0;

    uint256 private BurnTax=0;
    uint256 private LiquidityTax=6000;
    uint256 private MarketingTax=4000;
    uint256 private constant _TaxDivider=10000;
    
    address public marketingWallet=0xcF9F96213Ef763F311714AbAE29ff2A258101092;
    
    address private _pancakePairAddress; 
    IPancakeRouter02 private  _pancakeRouter;
    uint256 BotProtectionDuration=60 seconds;

    //modifier for functions only the team can call
    modifier onlyTeam() {
        require(isTeam(msg.sender), "Caller not Team");
        _;
    }
    //Checks if address is in Team, is needed to give Team access even if contract is renounced
    //Team doesn't have access to critical Functions that could turn this into a Rugpull(Exept liquidity unlocks)
    function isTeam(address addr) private view returns (bool){
        return addr==owner()||addr==marketingWallet;
    }
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Constructor///////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    constructor () {
        //contract creator gets 90% of the token to create LP-Pair
        uint ContractToken=TokenForPresale+TokenInLiquidity;
        uint BurnToken=5000000*10**_decimals;
        uint TeamToken=2000000*10**_decimals;
        _balances[address(this)] = ContractToken;
        _balances[address(0xdead)]=BurnToken;
        _balances[msg.sender]=TeamToken;

        emit Transfer(address(0), address(this), ContractToken);
        emit Transfer(address(0), address(0xdead), BurnToken);
        emit Transfer(address(0), msg.sender, TeamToken);

        _circulatingSupply=ContractToken+BurnToken+TeamToken;
        InitialSupply=_circulatingSupply;


        // Pancake Router
        _pancakeRouter = IPancakeRouter02(PancakeRouter);
        //Creates a Pancake Pair
        _pancakePairAddress = IPancakeFactory(_pancakeRouter.factory()).createPair(address(this), _pancakeRouter.WETH());
        
        //Sets Buy/Sell limits
        balanceLimit=_circulatingSupply/MaxBalanceDivider;
        
        //owner is excluded from Taxes
        _excluded.add(msg.sender);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Transfer functionality////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    //transfer function, every transfer runs through this function
    function _transfer(address sender, address recipient, uint256 amount) private{
        require(sender != address(0), "Transfer from zero");
        require(recipient != address(0), "Transfer to zero");
        
        //Manually Excluded adresses are transfering tax and lock free
        bool isExcluded = (_excluded.contains(sender) || _excluded.contains(recipient));
        
        //Transactions from and to the contract are always tax and lock free
        bool isContractTransfer=(sender==address(this) || recipient==address(this));
        
        //transfers between PancakeRouter and PancakePair are tax free
        address pancakeRouter=address(_pancakeRouter);
        bool isLiquidityTransfer = ((sender == _pancakePairAddress && recipient == pancakeRouter) 
        || (recipient == _pancakePairAddress && sender == pancakeRouter));

        //differentiate between buy/sell/transfer to apply different taxes/restrictions
        bool isBuy=sender==_pancakePairAddress;
        bool isSell=recipient==_pancakePairAddress;

        //Pick transfer
        if(isContractTransfer || isLiquidityTransfer || isExcluded)
            _feelessTransfer(sender, recipient, amount);
        else{ 
            _taxedTransfer(sender,recipient,amount,isBuy,isSell);                  
        }
    }
    //applies taxes, checks for limits, locks generates autoLP and stakingBNB, and autostakes
    function _taxedTransfer(address sender, address recipient, uint256 amount,bool isBuy,bool isSell) private{
        uint256 recipientBalance = _balances[recipient];
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer exceeds balance");
        //once trading is enabled, it can't be turned off again
        require(LaunchTimestamp!=0&&block.timestamp>LaunchTimestamp,"Trading not yet enabled");
        uint256 tax;
        if(isSell){
            if(block.timestamp<LaunchTimestamp+1 minutes)
                tax=_TaxDivider*75/100;
            else tax=_sellTax;
        }else if(isBuy){
            require(recipientBalance+amount<=balanceLimit,"whale protection");
            if(LaunchWhitelist[recipient]) tax=_buyTax;
            else tax=_getBuyTax();

        } else {//Transfer
            require(recipientBalance+amount<=balanceLimit,"whale protection");
            tax=_transferTax;
        }     

        if((sender!=_pancakePairAddress)&&(!manualConversion)&&(!_isSwappingContractModifier)&&isSell)
            _swapContractToken();

        //Calculates the exact token amount for each tax
        uint256 tokensToBeBurnt=_calculateFee(amount, tax, BurnTax);
        //staking and liquidity Tax get treated the same, only during conversion they get split
        uint256 contractToken=_calculateFee(amount, tax, MarketingTax+LiquidityTax);
        //Subtract the Taxed Tokens from the amount
        uint256 taxedAmount=amount-(tokensToBeBurnt + contractToken);

        _balances[sender]-=amount;
        //Adds the taxed tokens to the contract wallet
        _balances[address(this)] += contractToken;
        //Burns tokens
        _circulatingSupply-=tokensToBeBurnt;
        _balances[recipient]+=taxedAmount;
        
        emit Transfer(sender,recipient,taxedAmount);
    }
    //Feeless transfer only transfers and autostakes
    function _feelessTransfer(address sender, address recipient, uint256 amount) private{
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer exceeds balance");
        _balances[sender]-=amount;
        _balances[recipient]+=amount;      
        emit Transfer(sender,recipient,amount);
    }


    function _getBuyTax() private view returns(uint256){
        if(block.timestamp>=LaunchTimestamp+BotProtectionDuration) return _buyTax;
        uint256 timeSinceLaunch=block.timestamp-LaunchTimestamp;
        return _TaxDivider-((_TaxDivider-_buyTax)*timeSinceLaunch/BotProtectionDuration);
    }


    //Calculates the token that should be taxed
    function _calculateFee(uint256 amount, uint256 tax, uint256 taxPercent) private pure returns (uint256) {
        return (amount*tax*taxPercent) / (_TaxDivider*_TaxDivider);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Swap Contract Tokens//////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    //Locks the swap if already swapping
    bool private _isSwappingContractModifier;
    modifier lockTheSwap {
        _isSwappingContractModifier = true;
        _;
        _isSwappingContractModifier = false;
    }

    //swaps the token on the contract for Marketing BNB and LP Token.
    //always swaps the sellLimit of token to avoid a large price impact
    function _swapContractToken() private lockTheSwap{
        uint256 contractBalance=_balances[address(this)];
        uint256 totalTax=LiquidityTax+MarketingTax;
        //swaps each time it reaches 0.2% of pancake pair to avoid large prize impact
        uint256 tokenToSwap=_balances[_pancakePairAddress]*2/1000;
        //only swap if contractBalance is larger than tokenToSwap, and totalTax is unequal to 0
        if(contractBalance<tokenToSwap||totalTax==0)
            return;

        //splits the token in TokenForLiquidity and tokenForMarketing
        uint256 tokenForLiquidity=(tokenToSwap*LiquidityTax)/totalTax;
        uint256 tokenForMarketing= tokenToSwap-tokenForLiquidity;

        //splits tokenForLiquidity in 2 halves
        uint256 liqToken=tokenForLiquidity/2;
        uint256 liqBNBToken=tokenForLiquidity-liqToken;

        //swaps marktetingToken and the liquidity token half for BNB
        uint256 swapToken=liqBNBToken+tokenForMarketing;
        //Gets the initial BNB balance, so swap won't touch any contract BNB
        uint256 initialBNBBalance = address(this).balance;
        _swapTokenForBNB(swapToken);
        uint256 newBNB=(address(this).balance - initialBNBBalance);
        //calculates the amount of BNB belonging to the LP-Pair and converts them to LP
        if(liqToken!=0&&swapToken!=0){
            uint256 liqBNB = (newBNB*liqBNBToken)/swapToken;
            _addLiquidity(liqToken, liqBNB);
        }

    }
    //swaps tokens on the contract for BNB
    function _swapTokenForBNB(uint256 amount) private {
        _approve(address(this), address(_pancakeRouter), amount);
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
        _approve(address(this), address(_pancakeRouter), tokenamount);
        _pancakeRouter.addLiquidityETH{value: bnbamount}(
            address(this),
            tokenamount,
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //public functions /////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////// 
    function getLiquidityReleaseTimeInSeconds() public view returns (uint256){
        if(block.timestamp<_liquidityUnlockTime)
            return _liquidityUnlockTime-block.timestamp;
        return 0;
    }
    function getLaunchSeconds() public view returns (uint256){
        if(LaunchTimestamp==0) return 10**30;
        if(block.timestamp>=LaunchTimestamp) return 0;
        return LaunchTimestamp-block.timestamp;
    }
    function getBurnedTokens() public view returns(uint256){
        return (InitialSupply-_circulatingSupply)+_balances[address(0xdead)];
    }
    
    function getTaxes() public view returns(uint256 buy_, uint256 sell_, uint256 transfer_, uint256 burn_, uint256 liquidity_, uint256 marketing_){
        require(block.timestamp>=LaunchTimestamp&&LaunchTimestamp!=0,"not yet Launched");
        buy_=_getBuyTax();
        if(block.timestamp<LaunchTimestamp+1 minutes)
            sell_=_TaxDivider*75/100;
        else sell_=_sellTax;
        
        transfer_=_transferTax;
        burn_=BurnTax;
        liquidity_=LiquidityTax;
        marketing_=MarketingTax;
    }
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Settings//////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    bool public manualConversion;
    function ClaimMarketingBNB() public onlyTeam{
        uint256 amount;
        if(LaunchTimestamp==0)
            amount=address(this).balance-BNBInLiquidity; 
        else amount=address(this).balance;
            
        require(amount>0,"Nothing to claim");
        (bool sent,) =marketingWallet.call{value: (amount)}("");
        require(sent,"withdraw failed");  
    } 
    function ClaimMarketingBUSD() public onlyTeam{
        uint256 amount;
        if(LaunchTimestamp==0)
            amount=address(this).balance-BNBInLiquidity; 
        else amount=address(this).balance;
            
        require(amount>0,"Nothing to claim");

        address[] memory path = new address[](2);
        path[0] = _pancakeRouter.WETH(); //BNB
        path[1] = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;  //Binance-Peg BUSD Token

        _pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
        0,
        path,
        marketingWallet,
        block.timestamp);
    }

    function SetTaxes(
        uint Buy, 
        uint Sell, 
        uint Transfer, 
        uint Marketing, 
        uint LP, 
        uint Burn) public onlyTeam
    {
        uint256 Limit=_TaxDivider/4;
        require(Buy<Limit&&Sell<Limit&&Transfer<Limit);
        require(Marketing+LP+Burn==_TaxDivider);
        _buyTax=Buy;
        _sellTax=Sell;
        _transferTax=Transfer;
        MarketingTax=Marketing;
        LiquidityTax=LP;
        BurnTax=Burn;
    }
    //switches autoLiquidity and marketing BNB generation during transfers
    function SwitchManualBNBConversion(bool manual) public onlyTeam{
        manualConversion=manual;
    }
    //manually converts contract token to LP and staking BNB
    function SwapContractToken() public onlyTeam{
    require(isLaunched());
    _swapContractToken();
    }
    function isLaunched() public view returns(bool){
        return LaunchTimestamp!=0&&block.timestamp>LaunchTimestamp;
    } 
    //Exclude/Include account from fees (eg. CEX)
    function ExcludeAccountFromFees(address account, bool exclude) public onlyTeam {
        if(exclude)_excluded.add(account);
        else _excluded.remove(account);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Liquidity Lock////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //the timestamp when Liquidity unlocks
    uint256 private _liquidityUnlockTime;
    bool public LPReleaseLimitedTo20Percent;
    //Sets Liquidity Release to 20% at a time and prolongs liquidity Lock for a Week after Release. 
    //Should be called once start was successful.

    function limitLiquidityReleaseTo20Percent() public onlyTeam{
        LPReleaseLimitedTo20Percent=true;
    }

    function LockLiquidityForSeconds(uint256 secondsUntilUnlock) public onlyTeam{
        _prolongLiquidityLock(secondsUntilUnlock+block.timestamp);
    }
    function _prolongLiquidityLock(uint256 newUnlockTime) private{
        // require new unlock time to be longer than old one
        require(newUnlockTime>_liquidityUnlockTime);
        _liquidityUnlockTime=newUnlockTime;
    }

    //Release Liquidity Tokens once unlock time is over
    function LiquidityRelease() public onlyTeam {
        //Only callable if liquidity Unlock time is over
        require(block.timestamp >= _liquidityUnlockTime, "Not yet unlocked");
        _liquidityUnlockTime=block.timestamp+DefaultLiquidityLockTime;
        IPancakeERC20 liquidityToken = IPancakeERC20(_pancakePairAddress);
        uint256 amount = liquidityToken.balanceOf(address(this));
        if(LPReleaseLimitedTo20Percent) amount=amount*2/10;
        
        liquidityToken.transfer(marketingWallet, amount);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //external//////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    bool public PresaleActive;
    bool public PresaleFailed;
    uint256 public HardCap=250*10**18;
    uint256 public BNBInLiquidity=150*10**18;
    uint256 public MinContribution=10**17;
    uint256 public MaxContribution=10**18;

    uint256 public TokenInLiquidity=1500000*10**_decimals;
    uint256 public TokenForPresale= 1500000*10**_decimals;
    uint256 public TotalRaised;
    mapping(address=>uint256) public contributions;
    mapping(address=>bool) public presaleWhitelist;
    bool public PresaleWhitelistDisabled;
    mapping(address=>bool) public LaunchWhitelist;
    uint256 public LaunchTimestamp;
    function Finalize(uint LaunchInSeconds) public onlyTeam{
        require(LaunchInSeconds<7 days);
        require(TotalRaised>=BNBInLiquidity);
        require(LaunchTimestamp==0&&!PresaleFailed);
        _liquidityUnlockTime=block.timestamp+DefaultLiquidityLockTime;
        PresaleActive=false;
        LaunchTimestamp=block.timestamp+LaunchInSeconds;
        _addLiquidity(TokenInLiquidity, BNBInLiquidity);
        require(IBEP20(_pancakePairAddress).totalSupply()>0);
        uint256 remainingBalance=_balances[address(this)];
        _balances[address(this)]=0;
        _balances[address(0xdead)]+=remainingBalance;
        emit Transfer(address(this),address(0xdead),remainingBalance);
    }
    
    
    
    function SetupWhitelist(address[] memory addresses, bool Add, bool Presale) public onlyTeam{
        for(uint i=0;i<addresses.length;i++){
            if(Presale)
                presaleWhitelist[addresses[i]]=Add;
            else LaunchWhitelist[addresses[i]]=Add;
        }
    }


    function EnablePresale() public onlyTeam{
        require(LaunchTimestamp==0&&!PresaleFailed);
        PresaleActive=true;
    }
    function DisablePresaleWhitelist(bool Disable) public onlyTeam{
        PresaleWhitelistDisabled=Disable;
    }
    receive() external payable {
        if(msg.sender==address(_pancakeRouter)) return; 
        require(LaunchTimestamp==0);
        PresalePurchase();
    }


    function getTokenForAmount(uint256 amount) public view returns(uint256){
        return TokenForPresale*amount/HardCap;
    }
    bool inPresale;
    modifier inPresalePurchase{
        require(!inPresale);
        inPresale=true;
        _;
        inPresale=false;
    }
    function PresalePurchase() public payable inPresalePurchase{
        require(PresaleWhitelistDisabled||presaleWhitelist[msg.sender]);
        require(PresaleActive&&!PresaleFailed);
        require(msg.value>=MinContribution,"<MinContribution");
        require(TotalRaised<HardCap,"HardCap reached");
        
        uint256 value=msg.value;
        if(msg.value+TotalRaised>HardCap)
            value=HardCap-TotalRaised;
    
        uint256 alreadyContributed=contributions[msg.sender];
        if(alreadyContributed+value>MaxContribution)
            value=(MaxContribution-alreadyContributed);
        require(value>0,"MaxContribution reached");
        contributions[msg.sender]+=value;
        TotalRaised+=value;
        _feelessTransfer(address(this),msg.sender,getTokenForAmount(value));
        if(value<msg.value){
            (bool sent,)=msg.sender.call{value:msg.value-value}("");
            require(sent);
        }
        require(_balances[address(this)]>TokenInLiquidity);
    }
    function SetPresaleFailed() public onlyOwner{
        PresaleFailed=true;
        PresaleActive=false;
    }
    function WithdrawFailedPresale() public inPresalePurchase {
        require(PresaleFailed);
        uint256 contributon=contributions[msg.sender];
        contributions[msg.sender]=0;
        TotalRaised-=contributon;
        (bool sent,)=msg.sender.call{value:contributon}("");
        require(sent);
    }


    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //external//////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////





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
        require(owner != address(0), "Approve from zero");
        require(spender != address(0), "Approve to zero");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "Transfer > allowance");

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
        require(currentAllowance >= subtractedValue, "<0 allowance");

        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }

}