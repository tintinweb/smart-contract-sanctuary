/**
 *Submitted for verification at BscScan.com on 2021-12-19
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
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
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

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
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

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
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
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
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
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
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

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
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
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}
interface IPancakeRouter01 {
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

    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getamountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getamountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getamountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getamountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}
interface IPancakeFactory {
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
interface IPancakeRouter02 is IPancakeRouter01 {
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
//ML Contract /////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////
contract XBM is IBEP20, Ownable
{
    using EnumerableSet for EnumerableSet.AddressSet;
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping(address=>bool) private _excluded;
    mapping(address=>bool) private _excludedFromStaking;
    mapping(address=>bool) private _automatedMarketMakers;
    
    //Token Info
    string private constant _name = 'XBM';
    string private constant _symbol = 'xBM';
    uint8 private constant _decimals = 18;

    //The time Liquidity gets locked at start and prolonged once it gets released
    uint256 private constant DefaultLiquidityLockTime=7 days;

    //variables that track balanceLimit and sellLimit,
    //can be updated based on circulating supply and Sell- and BalanceLimitDividers
    uint256 private _circulatingSupply;

    //The shares of the specific Taxes, always needs to equal 100%
    uint private _liquidityTax=20;
    uint private _stakingTax=40;
    uint private _burnTax=40;
    uint private constant TaxDenominator=100;
    //determines the permille of the pancake pair needed to trigger Liquify
    uint8 public LiquifyTreshold=2;
    
    //_pancakePairAddress is also equal to the liquidity token address
    //LP token are locked in the contract
    address private _pancakePairAddress; 
    IPancakeRouter02 private  _pancakeRouter; 
    //TestNet
    address private constant PancakeRouter=0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    BurningMoon constant BM=BurningMoon(0x1Fd93329706579516e18ef2B51890F7a146B5b14);
    //MainNet
    //address private constant PancakeRouter=0x10ED43C718714eb63d5aA57B78B54704E256024E;
    //BurningMoon constant BM=BurningMoon(0x97c6825e6911578A515B11e25B552Ecd5fE58dbA);
    //modifier for functions only the team can call
    bool _isInFunction;
    modifier isInFunction(){
        require(!_isInFunction);
        _isInFunction=true;
        _;
        _isInFunction=false;

    }
   



    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Minting///////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    uint public BurnedSupply=0;
    function GetRate(uint Input) public view returns(uint){
        if(BurnedSupply==0) return Input;
        uint MaxSupply=_circulatingSupply+BurnedSupply;
        return Input*_circulatingSupply/MaxSupply;
    }
    mapping(address=>address) public MintingContracts;
    mapping(address=>bool) public Authorized;




    event OnCreateMintingContract(address owner, address contractAddress);
    function CreateMintingContract() public returns (address MintingContract){
        MintingContract=CreateMintingContract(msg.sender);
    }
    
    function CreateMintingContract(address account) public returns (address MintingContract){
        MintingContract=MintingContracts[account];
        require(MintingContract==address(0), "Minting Contract already defined");
        XBMMint newMintContract=new XBMMint(account,address(this),address(BM));
        MintingContract=address(newMintContract);
        MintingContracts[account]=MintingContract;
        emit OnCreateMintingContract(account,MintingContract);
    }


    
    function Mint() public{
        require(tradingEnabled||msg.sender==owner());
        address MintingContract=MintingContracts[msg.sender];
        require(MintingContract!=address(0), "No Minting Contract Defined");
        XBMMint mint=XBMMint(MintingContract);
        uint MintedAmount=GetRate(mint.Mint());
        _addToken(msg.sender,MintedAmount);
        emit Transfer(address(0),msg.sender,MintedAmount);
    }


    function _mint(address account) private{

        address MintingContract=MintingContracts[account];
        require(MintingContract!=address(0), "No Minting Contract Defined");
        XBMMint mint=XBMMint(MintingContract);
        uint MintedAmount=GetRate(mint.Mint());
        _addToken(account,MintedAmount);
        emit Transfer(address(0),account,MintedAmount);
    }





    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Constructor///////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    constructor () {
        //Creates a Pancake Pair
        _pancakeRouter = IPancakeRouter02(PancakeRouter);
        _pancakePairAddress = IPancakeFactory(_pancakeRouter.factory()).createPair(address(this), _pancakeRouter.WETH());
        _automatedMarketMakers[_pancakePairAddress]=true;
        //excludes Pancake Pair and contract from staking
        _excludedFromStaking[_pancakePairAddress]=true;
        _excludedFromStaking[address(this)]=true;
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
        //once trading is enabled, it can't be turned off again
        require(tradingEnabled,"trading not yet enabled"); 
        _regularTransfer(sender,recipient,amount);
        //AutoPayout

    }
    //applies taxes, checks for limits, locks generates autoLP and stakingBNB, and autostakes
    function _regularTransfer(address sender, address recipient, uint256 amount) private{
        require(_balances[sender] >= amount, "exceeds balance");
        //checks all registered AMM if it's a buy or sell.
        bool isBuy=_automatedMarketMakers[sender];
        bool isSell=_automatedMarketMakers[recipient];
        uint tax;
        (uint256 buyTax,uint256 sellTax,uint256 transferTax,,,,)=BM.getTaxes();



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
        
        emit Transfer(sender,recipient,amount);

    }

    //Calculates the token that should be taxed
    function _calculateFee(uint256 amount, uint tax, uint taxPercent) private pure returns (uint256) {
        return (amount*tax*taxPercent) / (TaxDenominator*TaxDenominator);
    }
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //BNB Autostake/////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////// 
    //Autostake uses the balances of each holder to redistribute auto generated BNB.
    //Each transaction _addToken and _removeToken gets called for the transaction amount
    EnumerableSet.AddressSet private _autoPayoutList;
    function isAutoPayout(address account) public view returns(bool){
        return _autoPayoutList.contains(account);
    }
    uint AutoPayoutCount=15;
    uint MinPayout=1000*10**9;//1000 BM
    uint256 currentPayoutIndex;

    bool public autoPayoutDisabled;

    event OnDisableAutoPayout(bool disabled);
    function DisableAutoPayout(bool disabled) public onlyOwner{
        autoPayoutDisabled=disabled;
        emit  OnDisableAutoPayout(disabled);
    }
    event OnChangeAutoPayoutCount(uint count); 
    function ChangeAutoPayoutCount(uint count) public onlyOwner{
        require(count<=100);
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
    mapping(address => uint256) private toBePaid;
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
        _totalShares+=amount;
        //gets the payout before the change
        uint256 payment=_newDividentsOf(addr);
        //resets dividents to 0 for newAmount
        alreadyPaidShares[addr] = profitPerShare * newAmount;
        //adds dividents to the toBePaid mapping
        toBePaid[addr]+=payment; 
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

        //gets the payout before the change
        uint256 payment=_newDividentsOf(addr);
        //sets newBalance
        _balances[addr]=newAmount;
        //resets dividents to 0 for newAmount
        alreadyPaidShares[addr] = profitPerShare * getShares(addr);
        //adds dividents to the toBePaid mapping
        toBePaid[addr]+=payment; 
        _totalShares-=amount;
        if(newAmount==0)
        _autoPayoutList.remove(addr);
    }
    
    
    //gets the dividents of a staker that aren't in the toBePaid mapping 
    function _newDividentsOf(address staker) private view returns (uint256) {
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
        toBePaid[addr]=0;
        totalPayout[addr]+=amount;
        return amount;
    }
    //Manually claimRewards
    function ClaimRewards() public isInFunction{
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
    uint public overLiquifyTreshold=100; 
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
    
    //Returns the not paid out dividents of an address in wei
    function getDividents(address addr) public view returns (uint256){
        return _newDividentsOf(addr)+toBePaid[addr];
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

    event  OnChangeLiquifyTreshold(uint8 TresholdPermille);
    function TeamSetLiquifyTreshold(uint8 TresholdPermille) public onlyOwner{
        require(TresholdPermille<=50);
        require(TresholdPermille>0);
        LiquifyTreshold=TresholdPermille;
        emit OnChangeLiquifyTreshold(TresholdPermille);
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
            uint256 newDividents=_newDividentsOf(addr);
            shares=getShares(addr);
            _excludedFromStaking[addr]=true; 
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
    //Setup Functions///////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    //Creates LP using Payable Amount, LP automatically land on the contract where they get locked
    //once Trading gets enabled
    bool public tradingEnabled;    
    event OnTradingOpen();
    //Enables trading. Turns on bot protection and Locks LP for default Lock time
    function SetupEnableTrading() public onlyOwner{
        require(!tradingEnabled);
        tradingEnabled=true;
        _liquidityUnlockTime=block.timestamp+DefaultLiquidityLockTime; 
        emit OnTradingOpen();
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

    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //external//////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    receive() external payable{
        require(tradingEnabled||msg.sender==owner());
        if(msg.sender==address(_pancakeRouter))return;
        address MintingContract=MintingContracts[msg.sender];
        if(MintingContract==address(0)) MintingContract=CreateMintingContract(msg.sender);
        address[] memory path = new address[](2);
        path[1] = address(BM);
        path[0] = _pancakeRouter.WETH();
        _pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value:msg.value}(
            0,
            path,
            MintingContract,
            block.timestamp);
        _mint(msg.sender);
    }

    function ConvertBM(uint amount) external {
        require(tradingEnabled||msg.sender==owner());
        address MintingContract=MintingContracts[msg.sender];
        if(MintingContract==address(0)) MintingContract=CreateMintingContract(msg.sender);
        BM.transferFrom(msg.sender, MintingContract, amount);
        _mint(msg.sender);
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