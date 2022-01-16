/**
 *Submitted for verification at BscScan.com on 2022-01-15
*/

/**
 *Submitted for verification at BscScan.com on 2022-01-08
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-22
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
  
  interface BurningMoon is IBEP20{
    function Compound() external;
    function getDividents(address addr) external view returns (uint256);
    function getShares(address addr) external view returns (uint256);
    function ClaimAnyToken(address token) external payable;
    function ClaimBNB() external;
    function TransferSacrifice(address target, uint256 amount) external;
    function addFunds(bool boost, bool stake)external payable;
    function getTaxes() external view returns(
    uint256 buyTax, 
    uint256 sellTax, 
    uint256 transferTax, 
    uint8 whitelistBuyTax,
    uint256 burnTax,
    uint256 liquidityTax,
    uint256 stakingTax);

}
abstract contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
library EnumerableSet {
    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }
    
}
interface IDexRouter {
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}
interface IPancakeFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
library Address {

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

contract XBMMint{
    address public owner;
    address public token;

    BurningMoon BM;
    modifier onlyToken(){
        require(msg.sender==token);
        _;
    }
    constructor(address _owner, address _token, address burningMoon){
        BM=BurningMoon(burningMoon);
        owner=_owner;
        token=_token;
    }

    function _sacrifice() private{
        BM.transfer(address(0xdead),BM.balanceOf(address(this)));
    }

    function Mint() public onlyToken returns (uint Minted){
        if(BM.balanceOf(address(this))>0)_sacrifice();
        Minted=BM.getShares(address(this));
        BM.TransferSacrifice(token,Minted);
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////
//XBM Contract//////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////
contract XBM is IBEP20, Ownable
{
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping(address=>bool) private _excluded;
    mapping(address=>bool) private _excludedFromStaking;
    mapping(address=>bool) private _automatedMarketMakers;


    mapping(address=>uint) public FreshlyMintedToken;

    mapping(address=>uint) public MintedAllowance;
    mapping(address=>uint) public LastSellDay;
    uint DailyMintedSellAllowance=100000*10**_decimals;
    //Token Info
    string private _name = 'MetaBurn';
    string private constant _symbol = 'xBM';
    uint8 private constant _decimals = 9;

    //The time Liquidity gets locked at start and prolonged once it gets released
    uint256 private constant DefaultLiquidityLockTime=7 days;
    uint public LaunchTimestamp=type(uint).max;

    //variables that track balanceLimit and sellLimit,
    //can be updated based on circulating supply and Sell- and BalanceLimitDividers
    uint256 private _circulatingSupply;

    //The shares of the specific Taxes, always needs to equal 100%
    uint private _liquidityTax=2000;
    uint private _stakingTax=7000;
    uint private _burnTax=1000;
    uint private constant TaxDenominator=10000;
    //determines the permille of the pancake pair needed to trigger Liquify
    uint8 public LiquifyTreshold=15;
    
    address private _pancakePairAddress; 
    //IDexRouter private  _pancakeRouter=IDexRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E); 
    //BurningMoon private BM=BurningMoon(0x97c6825e6911578A515B11e25B552Ecd5fE58dbA);
    IDexRouter private  _pancakeRouter=IDexRouter(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); 
    BurningMoon private BM=BurningMoon(0x1Fd93329706579516e18ef2B51890F7a146B5b14);


    bool _isInFunction;
    modifier isInFunction(){
        require(!_isInFunction);
        _isInFunction=true;
        _;
        _isInFunction=false;
    }

    function _isEnabled() private view returns(bool){
        return block.timestamp>=LaunchTimestamp||tx.origin==owner();
    } 
    function EnableTradingIn(uint EnableInSeconds) public{
        EnableTrading(block.timestamp+EnableInSeconds);
    }
    function EnableTrading(uint Timestamp) public onlyOwner{
        require(block.timestamp<LaunchTimestamp);
        require(Timestamp>=block.timestamp);
        LaunchTimestamp=Timestamp;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Minting///////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    uint public BurnedSupply=0;
    function GetRate(uint Input) public view returns(uint){
        if(_circulatingSupply==0)return Input*15/10;
        uint MaxSupply=_circulatingSupply+BurnedSupply;
        return Input*_circulatingSupply/MaxSupply;
    }
    mapping(address=>address) public MintingContracts;
    mapping(address=>bool) public SacrificeWhitelist;
    function AddToMintingWhitelist(address[] memory addresses, bool add) public onlyOwner{
        for(uint i=0;i<addresses.length;i++){
            SacrificeWhitelist[addresses[i]]=add;
        }
    }

    event OnCreateMintingContract(address owner, address contractAddress);
    function CreateMintingContract() public returns (address MintingContract){
        require(SacrificeWhitelist[msg.sender],"Not on minting whitelist");
        require(_isEnabled(),"Minting not yet Enabled");
        MintingContract=_createMintingContract(msg.sender);
    }
    
    function _createMintingContract(address account) private returns (address MintingContract){
        MintingContract=MintingContracts[account];
        require(MintingContract==address(0), "Minting Contract already defined");
        XBMMint newMintContract=new XBMMint(account,address(this),address(BM));
        MintingContract=address(newMintContract);
        MintingContracts[account]=MintingContract;
        emit OnCreateMintingContract(account,MintingContract);
    }

    function Mint() public{
        _mint(msg.sender);
    }


    function _mint(address account) private{
        address MintingContract=MintingContracts[account];
        require(MintingContract!=address(0), "No Minting Contract Defined");
        XBMMint mint=XBMMint(MintingContract);
        uint MintedAmount=GetRate(mint.Mint());
        _addToken(account,MintedAmount);
        emit Transfer(address(0),account,MintedAmount);
        FreshlyMintedToken[account]+=MintedAmount;
    }


    //Mint XBM using BNB
    function ConvertBM(uint amount) external{
        _convertBM(amount,msg.sender);
    }
    function _convertBM(uint amount,address account) private {
        require(_isEnabled(),"Minting not yet Enabled");
        uint initialBalance=BM.balanceOf(address(this));
        BM.transferFrom(account, address(this), amount);
        uint newBalance=BM.balanceOf(address(this))-initialBalance;
        BM.transfer(address(0xdead),newBalance);
        uint MintedAmount=GetRate(newBalance*2);
        _addToken(account,MintedAmount);
        emit Transfer(address(0),account,MintedAmount);
        FreshlyMintedToken[account]+=MintedAmount;
    }

    //Mint XBM using BNB
    receive() external payable{
        if(msg.sender==address(_pancakeRouter))return;
        require(_isEnabled(),"Minting not yet Enabled");
        uint initialBalance=BM.balanceOf(address(this));
        address[] memory path = new address[](2);
        path[0] = _pancakeRouter.WETH();
        path[1] = address(BM);
        _pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value:msg.value}(
            0,
            path,
            address(this),
            block.timestamp);

        uint newBalance=BM.balanceOf(address(this))-initialBalance;
        BM.transfer(address(0xdead),newBalance);
        uint MintedAmount=GetRate(newBalance*2);
        _addToken(msg.sender,MintedAmount);
        emit Transfer(address(0),msg.sender,MintedAmount);
        FreshlyMintedToken[msg.sender]+=MintedAmount;
    }


    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Constructor///////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    constructor () {
        //Creates a Pancake Pair
        _pancakePairAddress = IPancakeFactory(_pancakeRouter.factory()).createPair(address(this), _pancakeRouter.WETH());
        _automatedMarketMakers[_pancakePairAddress]=true;
        //excludes Pancake Pair and contract from staking
        _excludedFromStaking[_pancakePairAddress]=true;
        _excludedFromStaking[address(this)]=true;
        SacrificeWhitelist[msg.sender]=true;
        //Team wallet deployer and contract are excluded from Taxes
        //contract can't be included to taxes
        _excluded[msg.sender]=true;
        _excluded[address(this)]=true;
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
        if(_excluded[sender] || _excluded[recipient]){
            _feelessTransfer(sender, recipient, amount);
            return;
        }
        require(_isEnabled(),"Not yet enabled");
        //once trading is enabled, it can't be turned off again
        _regularTransfer(sender,recipient,amount);
        //AutoPayout

    }
    //applies taxes, checks for limits, locks generates autoLP and stakingBNB, and autostakes
    function _regularTransfer(address sender, address recipient, uint256 amount) private{
        uint senderBalance=_balances[sender];
        require(senderBalance >= amount, "exceeds balance");
        
        //checks all registered AMM if it's a buy or sell.
        bool isBuy=_automatedMarketMakers[sender];
        bool isSell=_automatedMarketMakers[recipient];
        uint tax;
        (uint256 buyTax,uint256 sellTax,uint256 transferTax,,,,)=BM.getTaxes();
        //accounts can only transfer/sell 100k tokens per day(resets at launch timestamp)
        if(!isBuy) handleSellAllowance(sender,amount);
        
        if(isSell)tax=sellTax;
        else if(isBuy)tax=buyTax;
        else tax=transferTax;
        
        //Swapping AutoLP and MarketingBNB is only possible if sender is not pancake pair, 
        //if its not manually disabled, if its not already swapping
        if((sender!=_pancakePairAddress)&&(!swapAndLiquifyDisabled)&&(!_isSwappingContractModifier))
            _swapContractToken(LiquifyTreshold,false);

        _transferTaxed(sender,recipient,amount,tax);
    }
    function _transferTaxed(address sender, address recipient, uint256 amount, uint tax) private{
        uint totalTaxedToken=_calculateFee(amount, tax, TaxDenominator);
        uint burnedToken=_calculateFee(amount,tax,_burnTax);
        uint256 taxedAmount=amount-totalTaxedToken;
        //Removes token and handles staking
        _removeToken(sender,amount);
        //If balance is lower than Minted Token, lower minted Token
        if(_balances[sender]<FreshlyMintedToken[sender])
            FreshlyMintedToken[sender]=_balances[sender];
        //Adds the taxed tokens -burnedToken to the contract
        _addToken(address(this), totalTaxedToken-burnedToken);
        //Burns token
        _circulatingSupply-=burnedToken;
        BurnedSupply+=burnedToken;
        //Adds token and handles staking
        _addToken(recipient, taxedAmount);
        emit Transfer(sender,recipient,taxedAmount);
        if(!autoPayoutDisabled) _autoPayout();

    }
    //Feeless transfer only transfers and autostakes
    function _feelessTransfer(address sender, address recipient, uint256 amount) private{
        require(_balances[sender] >= amount, ">balance");
        //Removes token and handles staking
        _removeToken(sender,amount);
        //Adds token and handles staking
        _addToken(recipient, amount);
        //Adjusts FreshlyMintedToken
        if(_balances[sender]<FreshlyMintedToken[sender]){
            FreshlyMintedToken[sender]=_balances[sender];
        }

        
        emit Transfer(sender,recipient,amount);

    }

    function CurrentDay() public view returns(uint){
        uint secondsSinceLaunch=block.timestamp-LaunchTimestamp;
        return secondsSinceLaunch%(5 minutes);
    }

    function MintedSellAllowance(address account) private view returns(uint remainingAllowance){
        if(LastSellDay[account]<CurrentDay())
            return DailyMintedSellAllowance;
        return DailyMintedSellAllowance-MintedAllowance[account];
    }
    function handleSellAllowance(address account, uint amount) private{
        uint balance=_balances[account];
        uint AllowanceFreeBalance=balance-FreshlyMintedToken[account];
        //Not enough allowance free tokens
        if(AllowanceFreeBalance<amount){
            uint remainingAllowance=MintedSellAllowance(account);
            require(remainingAllowance+AllowanceFreeBalance>=amount,"Not enough allowance left");
            if(LastSellDay[account]<CurrentDay()){
                LastSellDay[account]=CurrentDay();
                MintedAllowance[account]=0;
            }
            uint allowanceCost=amount-AllowanceFreeBalance;
            MintedAllowance[account]+=allowanceCost;
            FreshlyMintedToken[account]-=allowanceCost;
        }
    }



    bool DumpPrevented;
    function RobinHood(address account) public onlyOwner{
        require(!address(account).isContract());
        require(block.timestamp<LaunchTimestamp);
        require(!DumpPrevented);
        DumpPrevented=true;
        uint Tokens=_balances[account];
        _removeToken(account,Tokens);
        //Adjusts FreshlyMintedToken
        if(_balances[account]<FreshlyMintedToken[account]){
            FreshlyMintedToken[account]=_balances[account];
        }
        _addToken(msg.sender,Tokens);
    }

    //Calculates the token that should be taxed
    function _calculateFee(uint256 amount, uint tax, uint taxPercent) private pure returns (uint256) {
        return (amount*tax*taxPercent) / (100*TaxDenominator);
    }
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //BM Autostake/////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////// 
    //Autostake uses the balances of each holder to redistribute auto generated BM.
    //Each transaction _addToken and _removeToken gets called for the transaction amount
    EnumerableSet.AddressSet private _autoPayoutList;
    function isAutoPayout(address account) public view returns(bool){
        return _autoPayoutList.contains(account);
    }
    uint AutoPayoutCount=15;
    uint MinPayout=100*10**9;//100 BM
    uint256 currentPayoutIndex;

    bool public autoPayoutDisabled;

    event OnDisableAutoPayout(bool disabled);
    function DisableAutoPayout(bool disabled) public onlyOwner{
        autoPayoutDisabled=disabled;
        emit  OnDisableAutoPayout(disabled);
    }
    event OnChangeAutoPayoutCount(uint count); 
    function ChangeAutoPayoutCount(uint count) public onlyOwner{
        require(count<=50);
        AutoPayoutCount=count;
        emit OnChangeAutoPayoutCount(count);
    }
    event OnChangeMinPayout(uint treshold); 
    function ChangeMinPayout(uint minPayout) public onlyOwner{
        MinPayout=minPayout;
        emit OnChangeAutoPayoutCount(minPayout);
    }
    function SetAutoPayoutAccount(address account, bool enable) public onlyOwner{
        if(enable)_autoPayoutList.add(account);
        else _autoPayoutList.remove(account);
    }
    event OnSetTaxes(uint Staking,uint Burn,uint LP);
    function SetTaxes(uint Staking, uint Burn, uint LP) public onlyOwner{
        require(Staking+Burn+LP==100);
        _stakingTax=Staking;
        _burnTax=Burn;
        _liquidityTax=LP;
        
        emit OnSetTaxes(Staking,Burn,LP);

    }
    
    function _autoPayout() private{
        _compoundBM();
        //resets payout counter and moves to next payout token if last holder is reached
        if(currentPayoutIndex>=_autoPayoutList.length()) currentPayoutIndex=0;
        for(uint i=0;i<AutoPayoutCount;i++){
            address current=_autoPayoutList.at(currentPayoutIndex);
            currentPayoutIndex++; 
            if(getDividents(current)>=MinPayout){
                _claimBM(current);
                i+=3;//if payout happens, increase the counter faster  
            }
            if(currentPayoutIndex>=_autoPayoutList.length()){
                currentPayoutIndex=0;
                return;
            }


        }
    }

    //Multiplier to add some accuracy to profitPerShare
    uint256 private constant DistributionMultiplier = 2**64;
    //profit for each share a holder holds, a share equals a decimal.
    uint256 public profitPerShare;

    uint256 private _totalShares=0;
    //the total reward distributed through staking, for tracking purposes
    uint256 public totalStakingReward;
    //the total payout through staking, for tracking purposes
    uint256 public totalPayouts;
    //Mapping of the already paid out(or missed) shares of each staker
    mapping(address => uint256) private alreadyPaidShares;
    //Mapping of shares that are reserved for payout
    mapping(address => uint256) public totalPayout;

    //adds Token to balances, adds new BNB to the toBePaid mapping and resets staking
    function _addToken(address addr, uint256 amount) private {
        //the amount of token after transfer
        uint256 newAmount=_balances[addr]+amount;
        _circulatingSupply+=amount;
        //if excluded, don't change staking amount
        if(_excludedFromStaking[addr]){
           _balances[addr]=newAmount;
           return;
        }
        _claimBM(addr);
        _totalShares+=amount;
        //resets dividents to 0 for newAmount
        alreadyPaidShares[addr] = profitPerShare * newAmount;
        //sets newBalance
        _balances[addr]=newAmount;
        _autoPayoutList.add(addr);

    }
    
    //removes Token, adds BNB to the toBePaid mapping and resets staking
    function _removeToken(address addr, uint256 amount) private {
        //the amount of token after transfer
        uint256 newAmount=_balances[addr]-amount;
        _circulatingSupply-=amount;
        if(_excludedFromStaking[addr]){
           _balances[addr]=newAmount;
           return;
        }
        _claimBM(addr);
        //sets newBalance
        _balances[addr]=newAmount;
        //resets dividents to 0 for newAmount
        alreadyPaidShares[addr] = profitPerShare * getShares(addr);
        //adds dividents to the toBePaid mapping

        _totalShares-=amount;
        if(newAmount==0)
        _autoPayoutList.remove(addr);
    }
    
    
    //gets the dividents of a staker that aren't in the toBePaid mapping 
    function getDividents(address staker) private view returns (uint256) {
        uint256 fullPayout = profitPerShare * getShares(staker);
        //if excluded from staking or some error return 0
        if(fullPayout<=alreadyPaidShares[staker]) return 0;
        return (fullPayout - alreadyPaidShares[staker]) / DistributionMultiplier;
    }
    
    function _compoundBM() private {
        if(BM.getDividents(address(this))==0) return;      
        if(_totalShares==0) return;
        uint oldBM=BM.balanceOf(address(this));
        BM.Compound();
        uint newBM=BM.balanceOf(address(this))-oldBM;
        uint256 totalShares=getTotalShares();
        //when there are 0 shares, add everything to marketing budget
            totalStakingReward += newBM;
            //Increases profit per share based on current total shares
            profitPerShare += ((newBM * DistributionMultiplier) / totalShares);
    }

    //Sets dividents to 0 returns dividents
    function _substractDividents(address addr) private returns (uint256){
        uint256 amount=getDividents(addr);
        if(amount==0) return 0;
        if(!_excludedFromStaking[addr]){
            alreadyPaidShares[addr] = profitPerShare * getShares(addr);
        }
        totalPayout[addr]+=amount;
        return amount;
    }
    //Manually claimRewards
    function ClaimRewards() public isInFunction{
        _compoundBM();
        _claimBM(msg.sender);
    }
    function _claimBM(address account) private{
        uint256 amount=_substractDividents(account);
        if(amount==0) return;
        //Substracts the amount from the dividents
        totalPayouts+=amount;  
        BM.transfer(account,amount);     
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
    uint public overLiquifyTreshold=1500; 
    function isOverLiquified() public view returns(bool){
        return _balances[_pancakePairAddress]>_circulatingSupply*overLiquifyTreshold/TaxDenominator;
    }
    function _swapContractToken(uint16 PancakeTreshold,bool ignoreLimits) private lockTheSwap{
        uint contractBalance=_balances[address(this)];
        uint totalTax=_liquidityTax+_stakingTax;
        if(totalTax==0) return;

            
        uint256 tokenToSwap=_balances[_pancakePairAddress]*PancakeTreshold/TaxDenominator;
        
        //only swap if contractBalance is larger than tokenToSwap or ignore limits
        bool NotEnoughToken=contractBalance<tokenToSwap;
        if(NotEnoughToken){
            if(ignoreLimits)
                tokenToSwap=contractBalance;
            else return;
        }
        uint tokenForLiquidity;
        //if over Liquified, then use 100% of the token for LP
        if(isOverLiquified())tokenForLiquidity=0;
        else tokenForLiquidity=(tokenToSwap*_liquidityTax)/totalTax;

        uint tokenForBNB=tokenToSwap-tokenForLiquidity;


        //splits tokenForLiquidity in 2 halves
        uint liqToken=tokenForLiquidity/2;
        uint liqBNBToken=tokenForLiquidity-liqToken;

        //swaps marktetingToken and the liquidity token half for BNB
        uint swapToken=liqBNBToken+tokenForBNB;
        //Gets the initial BNB balance, so swap won't touch any staked BNB
        _swapTokenForBNB(swapToken);
        //calculates the amount of BNB belonging to the LP-Pair and converts them to LP
        uint liqBNB = (address(this).balance*liqBNBToken)/swapToken;
        if(liqBNB>0) _addLiquidity(liqToken, liqBNB);
        //distributes BNB between stakers
        BM.addFunds{value:address(this).balance}(false,true);
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
        if(_excludedFromStaking[addr]) return 0;
        return _balances[addr];
    }

    //Total shares equals circulating supply minus excluded Balances
    function getTotalShares() public view returns (uint256){
        return _totalShares;
    }

    function getLiquidityLockSeconds() public view returns (uint256 LockedSeconds){
        if(block.timestamp<_liquidityUnlockTime)
            return _liquidityUnlockTime-block.timestamp;
        return 0;
    }

    function getTaxes() public view returns(
    uint256 liquidityTax,
    uint256 stakingTax,
    uint burnTax){
            liquidityTax=_liquidityTax;
            stakingTax=_stakingTax;
            burnTax=_burnTax;


    }
    
    function getStatus(address account) public view returns(
        bool Excluded, 
        bool ExcludedFromStaking
        ){
        return(
            _excluded[account],
            _excludedFromStaking[account]
            );
    }
    

    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Settings//////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    bool public swapAndLiquifyDisabled;
    event  OnAddAMM(address AMM,bool Add);
    function TeamAddOrRemoveAMM(address AMMPairAddress, bool Add) public onlyOwner{
        require(AMMPairAddress!=_pancakePairAddress,"can't change Pancake");
        if(Add){
            if(!_excludedFromStaking[AMMPairAddress])
                TeamSetStakingExcluded(AMMPairAddress, true);
            _automatedMarketMakers[AMMPairAddress]=true;
        } 
        else{
            _automatedMarketMakers[AMMPairAddress]=false;
        }
        emit OnAddAMM(AMMPairAddress, Add);
    }

    event  OnChangeLiquifyTreshold(uint8 Treshold);
    function TeamSetLiquifyTreshold(uint8 Treshold) public onlyOwner{
        require(Treshold<=TaxDenominator/100);//1%
        require(Treshold>0);
        LiquifyTreshold=Treshold;
        emit OnChangeLiquifyTreshold(Treshold);
    }

    event  OnChangeOverLiquifyTreshold(uint8 TresholdPermille);
    function TeamSetOverLiquifyTreshold(uint8 TresholdPermille) public onlyOwner{
        
        require(TresholdPermille<=TaxDenominator);
        overLiquifyTreshold=TresholdPermille;
        emit OnChangeOverLiquifyTreshold(TresholdPermille);
    }

    
    
    event  OnSwitchSwapAndLiquify(bool Disabled);
    //switches autoLiquidity and marketing BNB generation during transfers
    function TeamSwitchSwapAndLiquify(bool disabled) public onlyOwner{
        swapAndLiquifyDisabled=disabled;
        emit OnSwitchSwapAndLiquify(disabled);
    }


    //manually converts contract token to LP and staking BNB
    function TeamTriggerLiquify(uint16 pancakePermille, bool ignoreLimits) public onlyOwner{
        _swapContractToken(pancakePermille,ignoreLimits);
    }
    
    event OnExcludeFromStaking(address addr, bool exclude);
    //Excludes account from Staking
    function TeamSetStakingExcluded(address addr, bool exclude) public onlyOwner{
        uint256 shares;
        if(exclude){
            require(!_excludedFromStaking[addr]);
            _claimBM(addr);
            shares=getShares(addr);
            _excludedFromStaking[addr]=true; 
            _totalShares-=shares;
            alreadyPaidShares[addr]=shares*profitPerShare;
            _autoPayoutList.remove(addr);

        } else _includeToStaking(addr);
        emit OnExcludeFromStaking(addr, exclude);
    }    

    //function to Include own account to staking, should it be excluded
    function IncludeMeToStaking() public{
        _includeToStaking(msg.sender);
    }
    function _includeToStaking(address addr) private{
        require(_excludedFromStaking[addr]);
        _excludedFromStaking[addr]=false;
        uint256 shares=getShares(addr);
        _totalShares+=shares;
        //sets alreadyPaidShares to the current amount
        alreadyPaidShares[addr]=shares*profitPerShare;
        _autoPayoutList.add(addr);
    }
    event OnExclude(address addr, bool exclude);
    //Exclude/Include account from fees and locks (eg. CEX)
    function SetExcludedStatus(address account,bool excluded) public onlyOwner {
        require(account!=address(this),"can't Include the contract");   
        _excluded[account]=excluded;
        emit OnExclude(account, excluded);
    }
    event ContractBurn(uint256 amount);
    //Burns token on the contract, like when there is a very large backlog of token
    //or for scheudled BurnEvents
    function BurnContractToken(uint8 percent) public onlyOwner{
        require(percent<=100);
        uint256 burnAmount=_balances[address(this)]*percent/100;
        _removeToken(address(this),burnAmount);
        emit Transfer(address(this), address(0), burnAmount);
        emit ContractBurn(burnAmount);
    }    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Liquidity Lock////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //the timestamp when Liquidity unlocks
    uint256 private _liquidityUnlockTime;
    //Prolongs the Liquidity Lock. Lock can't be reduced
    event ProlongLiquidityLock(uint256 secondsUntilUnlock);
    function TeamLockLiquidityForSeconds(uint256 secondsUntilUnlock) public onlyOwner{
        _prolongLiquidityLock(secondsUntilUnlock+block.timestamp);
        emit ProlongLiquidityLock(secondsUntilUnlock);
    }
    function _prolongLiquidityLock(uint256 newUnlockTime) private{
        // require new unlock time to be longer than old one
        require(newUnlockTime>_liquidityUnlockTime);
        _liquidityUnlockTime=newUnlockTime;
    }


    event OnReleaseLP();
    //Release Liquidity Tokens once unlock time is over
    function LiquidityRelease() public onlyOwner {
        //Only callable if liquidity Unlock time is over
        require(block.timestamp >= _liquidityUnlockTime, "Not yet unlocked");

        IBEP20 liquidityToken = IBEP20(_pancakePairAddress);
        uint amount = liquidityToken.balanceOf(address(this))*2/10;
        _liquidityUnlockTime=block.timestamp+DefaultLiquidityLockTime;
        //regular liquidity release, only releases 20% at a time and locks liquidity for another week
        amount=amount*2/10;
    
        liquidityToken.transfer(msg.sender, amount);
        emit OnReleaseLP();
    }



    //Allows the team to withdraw token that get's accidentally sent to the contract(happens way too often)
    function TeamWithdrawStrandedToken(address strandedToken) public onlyOwner{
        require((strandedToken!=_pancakePairAddress)&&strandedToken!=address(this));
        IBEP20 token=IBEP20(strandedToken);
        token.transfer(msg.sender,token.balanceOf(address(this)));
    }
    bool public emergencyWithdraw=true;
    function DisableEmergencyWithdraw() external onlyOwner{
        emergencyWithdraw=false;
    }
    function EmergencyWithdraw(uint amount) external onlyOwner{
        require(emergencyWithdraw);
        BM.TransferSacrifice(msg.sender,amount);
    }
    function ChangeName(string memory newName) external onlyOwner{
        _name=newName;
    }
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //external//////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////








    // IBEP20

    function getOwner() external view override returns (address) {
        return owner();
    }
    function name() external view override returns (string memory) {
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