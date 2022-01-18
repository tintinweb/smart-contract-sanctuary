/**
 *Submitted for verification at BscScan.com on 2022-01-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
  interface IBEP20 {
  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function getOwner() external view returns (address);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
interface IPancakeFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
interface IDEXRouter {
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactTokensForETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}
abstract contract Ownable {
    address internal _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
    contract Arenaverse is Ownable, IBEP20{
    //shares represent the token someone with reflections turned on has.
    //over time each share becomes worth more tokens so the tokens someone holds grow
    mapping (address=>uint) public Shares;
    //excluded from Reflection accounts just track the exact amount of tokens
    mapping (address=>uint) public ExcludedBalances;
    mapping (address=>bool) public ExcludedFromReflection;
    mapping (address=>bool) public ExcludedFromFees;
    mapping (address => mapping (address => uint256)) private _allowances;
    //Market makers have different Fees for Buy/Sell
    mapping (address => bool) public _isMarketMaker;

    uint _buyTax=1000;
    uint _sellTax=1200;
    uint _transferTax=0;
    //The taxes are split into different uses and need to add up to "TAX_DENOMINATOR"
    uint _marketingTax=2500;
    uint _developementTax=1500;
    uint _reflectionTax=1000;
    uint _liquidityTax=5000;
    uint _contractTax=TAX_DENOMINATOR-_reflectionTax;
    //percentage of pancakePair that should be swapped with each contract swap (15=0.15%)
    uint _swapTreshold=15;
    //If liquidity is greater than treshold, stop creating AutoLP(15%)
    uint _liquifyTreshold=1500;
    //Manual swap disables auto swap, should there be a problem
    bool _manualSwap;
    uint launchTimestamp=type(uint).max;
    uint _liquidityUnlockTime;
    uint public MaxWalletDenominator=100;
    uint constant AntiBotBuyTax=9999;
    uint constant BotBuyTaxDuration=2 minutes;
    uint constant AntiPaperhandSellTax=2500;
    uint constant PaperhandSellDuration=24 hours;

    uint constant TAX_DENOMINATOR=10000;
    //DividentMagnifier to make Reflection more accurate
    uint constant DividentMagnifier=2**128;
    uint TokensPerShare=DividentMagnifier;
    uint8 constant _decimals=9;
    uint constant  InitialSupply=10**9*10**_decimals;
    //All non excluded tokens get tracked here as shares
    uint _totalShares;
    //All excluded tokens get tracked here as tokens
    uint _totalExcludedTokens;
    function symbol() external pure override returns (string memory){return "AVERSE";}
    function name() external pure override returns (string memory){return "Arenaverse";}
    
    address public marketingWallet;
    address public devWallet;

    address pancakePair;
        //TestNet
    //address private constant pancakeRouterAddress=0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    //MainNet
    address private constant pancakeRouterAddress=0x10ED43C718714eb63d5aA57B78B54704E256024E;
    IDEXRouter pancakeRouter=IDEXRouter(pancakeRouterAddress);

    event onSetManualSwap(bool manual);
    event OnSetOverLiquifyTreshold(uint amount);
    event OnSetSwapTreshold(uint treshold);
    event OnSetAMM(address AMM, bool add);
    event OnSetTaxes(uint Buy, uint Sell, uint Transfer, uint Reflection, uint Liquidity, uint Marketing, uint Dev);
    event OnSetExcludedFromFee(address account, bool exclude);
    event OnSetLaunchTimestamp(uint Timestamp);
    event  OnSetExcludedFromReflection(address account, bool exclude);
    event OnSetDevWallet(address wallet);
    event OnSetMarketingWallet(address wallet);
    event OnProlongLPLock(uint UnlockTimestamp);
    event OnReleaseLP();
    event OnChangeMaxWalletDenominator(uint Denominator);

    constructor(){
        pancakePair = IPancakeFactory(pancakeRouter.factory()).createPair(address(this), pancakeRouter.WETH());
        _isMarketMaker[pancakePair]=true;
        //Contract creator gets 100% of the supply to create LP
       addTokens(msg.sender,InitialSupply*99/100);
       addTokens(address(0xdead),InitialSupply/100);
        emit Transfer(address(0),address(0xdead),InitialSupply/100);      
       emit Transfer(address(0),msg.sender,InitialSupply/2);
        //Pancake pair and contract never get reflections and can't be included
       _excludeFromReflection(address(this),true);
       _excludeFromReflection(pancakePair,true);
       //Contract never pays fees and can't be included
       ExcludedFromFees[msg.sender]=true;
       ExcludedFromFees[address(this)]=true;
        //Dev and marketing wallet are by default the contract wallet and need to be set later
       marketingWallet=msg.sender;
       devWallet=msg.sender;
    }

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///Transfer/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    function _transfer(address sender, address recipient, uint amount) private{
        require(sender != address(0), "transfer from zero");
        require(recipient != address(0), "transfer to zero");
        require(amount>0,"amount zero");
        if(ExcludedFromFees[sender]||ExcludedFromFees[recipient])
            transferFeeless(sender,recipient,amount);
        else transferWithFee(sender,recipient,amount);
        
        emit Transfer(sender,recipient,amount);
    }
    function transferFeeless(address sender, address recipient, uint amount) private{
        removeTokens(sender,amount);
        addTokens(recipient,amount);
    }
    function transferWithFee(address sender, address recipient, uint amount) private{
        require(block.timestamp>=launchTimestamp);
        bool isBuy=_isMarketMaker[sender];
        bool isSell=_isMarketMaker[recipient];
        uint tax;
        if(isBuy)
        {
            require((balanceOf(recipient)+amount)<=(InitialSupply/MaxWalletDenominator),"Max Wallet");
            if(block.timestamp<launchTimestamp+BotBuyTaxDuration)
                tax=_getStartTax(BotBuyTaxDuration,AntiBotBuyTax,_buyTax);
            else
                tax=_buyTax;
        }
        else if(isSell)
        {
            if(block.timestamp<launchTimestamp+PaperhandSellDuration)
                tax=_getStartTax(PaperhandSellDuration,AntiPaperhandSellTax,_sellTax);
            else
                tax=_sellTax;
        }
        else tax=_transferTax;
        if(!_isSwappingContractModifier&&sender!=pancakePair&&!_manualSwap)
            _swapContractToken(false);

        uint TaxedAmount=amount*tax/TAX_DENOMINATOR;
        uint ContractToken=TaxedAmount*_contractTax/TAX_DENOMINATOR;
        uint ReflectToken=TaxedAmount-ContractToken;
        removeTokens(sender,amount);
        addTokens(recipient,amount-TaxedAmount); 
        if(ContractToken>0) addTokens(address(this),ContractToken);
        if(ReflectToken>0) reflectTokens(ReflectToken);

    }
    //Start tax drops depending on the time since launch, enables bot protection and Dump protection
    function _getStartTax(uint duration, uint maxTax, uint minTax) private view returns (uint){
        uint timeSinceLaunch=block.timestamp-launchTimestamp;
        return maxTax-((maxTax-minTax)*timeSinceLaunch/duration);
    }
    //Adds token respecting reflection
    function addTokens(address account, uint tokens) private{
        uint Balance=balanceOf(account);
        uint newBalance=Balance+tokens;
        if(ExcludedFromReflection[account]){
            ExcludedBalances[account]=newBalance;
            _totalExcludedTokens+=tokens;
        }else{
            uint oldShares=SharesFromTokens(Balance);
            uint newShares=SharesFromTokens(newBalance);
            Shares[account]=newShares;
            _totalShares+=(newShares-oldShares);
        }
    }
    //Removes token respecting reflection
    function removeTokens(address account, uint tokens) private{
        uint Balance=balanceOf(account);
        require(tokens<=Balance,"Transfer exceeds Balance");
        uint newBalance=Balance-tokens;
        if(ExcludedFromReflection[account]){
            ExcludedBalances[account]=newBalance;
            _totalExcludedTokens-=(Balance-newBalance);
        }else{
            uint oldShares=SharesFromTokens(Balance);
            uint newShares=SharesFromTokens(newBalance);
            Shares[account]=newShares;
            _totalShares-=(oldShares-newShares);
        }
    }

    //Handles reflection of already substracted token
    function reflectTokens(uint tokens) private {
        if(_totalShares==0) return;//if total shares=0 reflection dissapears into nothing
        TokensPerShare+=tokens*DividentMagnifier/_totalShares;
    }

    function TokensFromShares(uint shares) public view returns(uint){
       return shares*TokensPerShare/DividentMagnifier;
    }
    function SharesFromTokens(uint tokens) public view returns(uint){
        return tokens*DividentMagnifier/TokensPerShare;
    }




////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///SwapContractToken////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    bool private _isSwappingContractModifier;
    modifier lockTheSwap {
        _isSwappingContractModifier = true;
        _;
        _isSwappingContractModifier = false;
    }

    function _swapContractToken(bool ignoreLimits) private lockTheSwap{
        uint256 contractBalance=ExcludedBalances[address(this)];
        if(_contractTax==0) return;

            
        uint256 tokenToSwap=ExcludedBalances[pancakePair]*_swapTreshold/TAX_DENOMINATOR;
        
        //only swap if contractBalance is larger than tokenToSwap or ignore limits
        if(contractBalance<tokenToSwap){
            if(ignoreLimits)
                tokenToSwap=contractBalance;
            else return;
        }


        //splits the token in TokenForLiquidity and tokenForMarketing
        uint256 tokenForLiquidity=isOverLiquified()?0:(tokenToSwap*_liquidityTax)/_contractTax;
        uint256 tokenForMarketing= tokenToSwap-tokenForLiquidity;

        //splits tokenForLiquidity in 2 halves
        uint256 liqToken=tokenForLiquidity/2;

        //swaps marktetingToken and the liquidity token half for BNB
        uint256 swapToken=liqToken+tokenForMarketing;
        if(swapToken==0) return;
        _swapTokenForBNB(swapToken);
        uint256 newBNB=address(this).balance;
        //calculates the amount of BNB belonging to the LP-Pair and converts them to LP
        uint256 liqBNB = (newBNB*liqToken)/swapToken;
        if(liqBNB>0) 
            _addLiquidity(liqToken, liqBNB);

        (bool sent,)=marketingWallet.call{value:address(this).balance*_marketingTax/(_marketingTax+_developementTax)}("");
        (sent,)=devWallet.call{value:address(this).balance}("");  
        sent=true;    
        
    }
    function _swapTokenForBNB(uint256 tokens) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeRouter.WETH();
        _allowances[address(this)][address(pancakeRouter)] = tokens;
        pancakeRouter.swapExactTokensForETH(
            tokens,
            0,
            path,
            address(this),
            block.timestamp
        );
    }





    function _addLiquidity(uint256 tokenamount, uint256 bnbamount) private {
        _allowances[address(this)][address(pancakeRouter)] = tokenamount;
        try pancakeRouter.addLiquidityETH{value: bnbamount}(
            address(this),
            tokenamount,
            0,
            0,
            address(this),
            block.timestamp
        ){}
        catch{}
    }
    function isOverLiquified() public view returns (bool){
       return ExcludedBalances[pancakePair]>totalSupply()*_liquifyTreshold/TAX_DENOMINATOR;
    }
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///Settings/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    function ReflectOwnerTokens(uint amount) public onlyOwner{
        removeTokens(msg.sender,amount);
        reflectTokens(amount);
        emit Transfer(msg.sender,address(0),amount);
    }
    function setMaxWalletDenominator(uint Denominator) public onlyOwner{
        require(Denominator<200);
        MaxWalletDenominator=Denominator;
        emit OnChangeMaxWalletDenominator(Denominator);
    }
    function swapContractToken(uint treshold)public onlyOwner{
        uint prevTreshold=_swapTreshold;
        _swapTreshold=treshold;
        _swapContractToken(true);
        _swapTreshold=prevTreshold;
    }
    function setManualSwap(bool manual) public onlyOwner{
        _manualSwap=manual;
        emit onSetManualSwap(manual);
    }

    function setOverLiquifyTreshold(uint amount) public onlyOwner{
        require(amount<TAX_DENOMINATOR);
        _liquifyTreshold=amount;
        emit OnSetOverLiquifyTreshold(amount);
    }

    function setSwapTreshold(uint treshold) public onlyOwner{
        require(treshold<=TAX_DENOMINATOR/100);
        _swapTreshold=treshold;
        emit OnSetSwapTreshold(treshold);
    }

    function setAMM(address AMM, bool add) public onlyOwner{
        require(AMM!=pancakePair);
        _isMarketMaker[AMM]=add;
        emit OnSetAMM(AMM,add);
    }

    function setTaxes(uint Buy, uint Sell, uint Transfer, uint Reflection, uint Liquidity, uint Marketing, uint Dev) public onlyOwner{
        uint maxTax=TAX_DENOMINATOR/4;
        require(Buy<=maxTax&&Sell<=maxTax&&Transfer<=maxTax);
        require(Reflection+Liquidity+Marketing+Dev==TAX_DENOMINATOR);
        _buyTax=Buy;
        _sellTax=Sell;
        _transferTax=Transfer;
        _reflectionTax=Reflection;
        _liquifyTreshold=Liquidity;
        _marketingTax=Marketing;
        _developementTax=Dev;
        _contractTax=TAX_DENOMINATOR-_reflectionTax;
        emit OnSetTaxes(Buy, Sell, Transfer, Reflection, Liquidity, Marketing, Dev);
    }

    function setExcludedFromFee(address account, bool exclude) public onlyOwner{
        require(exclude||account!=address(this));
        ExcludedFromFees[account]=exclude;
        emit OnSetExcludedFromFee(account,exclude);
    }

    function setLaunchInSeconds(uint secondsUntilLaunch) public onlyOwner{
        setLaunchTimestamp(block.timestamp+secondsUntilLaunch);
    }
    function setLaunchTimestamp(uint Timestamp) public onlyOwner{
        require(block.timestamp<launchTimestamp);
        require(Timestamp>=block.timestamp);
        launchTimestamp=Timestamp;
        emit OnSetLaunchTimestamp(Timestamp);
    }


    function setExcludedFromReflection(address account, bool exclude) public onlyOwner{
        //Contract and PancakePair never can receive reflections
        require(account!=address(this)&&account!=pancakePair);
        //Burn wallet always receives reflections
        require(account!=address(0xdead));
        _excludeFromReflection(account,exclude);
        emit OnSetExcludedFromReflection(account,exclude);
    }
    function _excludeFromReflection(address account, bool exclude) private{
        require(ExcludedFromReflection[account]!=exclude);
        uint tokens=balanceOf(account);
        ExcludedFromReflection[account]=exclude;
        if(exclude){
            uint shares=Shares[account];
            _totalShares-=shares;
            Shares[account]=0;
            ExcludedBalances[account]=tokens;
            _totalExcludedTokens+=tokens;
        }else{
            ExcludedBalances[account]=0;
            _totalExcludedTokens-=tokens;
            uint shares=SharesFromTokens(tokens);
            Shares[account]=shares;
            _totalShares+=shares;
        }
    }

    function SetDevWallet(address newWallet) public onlyOwner{
        devWallet=newWallet;
        emit OnSetDevWallet(newWallet);
    }

    function SetMarketingWallet(address newMarketingWallet) public onlyOwner{
        marketingWallet=newMarketingWallet;
        emit OnSetMarketingWallet(newMarketingWallet);
    }


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///View/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function getTaxes() public view returns (uint Buy, uint Sell, uint Transfer, uint Reflection, uint LP, uint Marketing, uint Dev){
    Buy=_buyTax;
    Sell=_sellTax;
    Transfer=_transferTax;
    Reflection=_reflectionTax;
    LP=_liquidityTax;
    Marketing=_marketingTax;
    Dev=_developementTax;
}
function getInfo() public view returns(uint SwapTreshold, uint LiquifyTreshold,uint LaunchTimestamp, uint TotalShares, uint TotalExcluded, bool ManualSwap){
    SwapTreshold=_swapTreshold;
    LiquifyTreshold=_liquifyTreshold;
    LaunchTimestamp=launchTimestamp;
    TotalExcluded=_totalExcludedTokens;
    TotalShares=_totalShares;
    ManualSwap=_manualSwap;
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///Liquidity Lock///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    function LockLiquidityForSeconds(uint secondsUntilUnlock) public onlyOwner{
        SetUnlockTimestamp(secondsUntilUnlock+block.timestamp);
    }

    function SetUnlockTimestamp(uint newUnlockTime) public onlyOwner{
        // require new unlock time to be longer than old one
        require(newUnlockTime>_liquidityUnlockTime);
        _liquidityUnlockTime=newUnlockTime;
        emit OnProlongLPLock(_liquidityUnlockTime);
    }

    //Release Liquidity Tokens once unlock time is over
    function LiquidityRelease() public onlyOwner {
        //Only callable if liquidity Unlock time is over
        require(block.timestamp >= _liquidityUnlockTime, "Not yet unlocked");

        IBEP20 liquidityToken = IBEP20(pancakePair);
        uint amount = liquidityToken.balanceOf(address(this));
        liquidityToken.transfer(msg.sender, amount);
        emit OnReleaseLP();
    }
    function RescueTokens(address token) public onlyOwner{
        require(token!=address(this)&&token!=pancakePair);
        IBEP20(token).transfer(msg.sender,IBEP20(token).balanceOf(address(this)));
    }
    function getLiquidityLockSeconds() public view returns (uint256 LockedSeconds){
        if(block.timestamp<_liquidityUnlockTime)
            return _liquidityUnlockTime-block.timestamp;
        return 0;
    }


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///BEP20 Implementation/////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    receive() external payable{}
    function  decimals() external override pure returns (uint8){
        return _decimals;
    }
    function  getOwner() external override view returns (address){
        return owner();
    }
    function balanceOf(address account) public view override returns (uint256) {
        if(ExcludedFromReflection[account])
            return ExcludedBalances[account];
        return TokensFromShares(Shares[account]);
    }
    function totalSupply() public view override returns (uint256) {
        return _totalExcludedTokens+TokensFromShares(_totalShares);
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

    function transfer(address recipient, uint amount) external override returns(bool){
        _transfer(msg.sender,recipient,amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint amount) external override returns(bool){
        _transfer(sender,recipient,amount);
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount,"Transfer exceeds allowance");
        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }
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