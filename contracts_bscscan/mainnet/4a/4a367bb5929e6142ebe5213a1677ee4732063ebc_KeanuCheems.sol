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
interface IPancakeERC20 {
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
abstract contract Ownable {
    address private _owner;
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
library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}
library EnumerableSet {
    struct Set {
        bytes32[] _values;
        mapping (bytes32 => uint256) _indexes;
    }
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];
        if (valueIndex != 0) {
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;
            bytes32 lastvalue = set._values[lastIndex];
            set._values[toDeleteIndex] = lastvalue;
            set._indexes[lastvalue] = valueIndex;
            set._values.pop();
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
    struct Bytes32Set {
        Set _inner;
    }
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }
    struct AddressSet {
        Set _inner;
    }
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }
    struct UintSet {
        Set _inner;
    }
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

//Contract
contract KeanuCheems is IBEP20, Ownable {
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    EnumerableSet.AddressSet private _excluded;
    EnumerableSet.AddressSet private _excludedFromStaking;

    string private constant _name = 'KeanuCheems';  
    string private constant _symbol = 'KCM';    
    uint8 private constant _decimals = 18;
    uint256 public constant _totalSupply= 1000000000 * 10**_decimals;
    uint256 public _circulatingSupply=_totalSupply;    
    uint8 private constant MaxWalletDivider=100; //1%% = 10,000,000
    uint16 private constant SellLimitDivider=50; //2% = 20,000,000
    uint8 public constant MaxTax=20;        //This is the max tax that can be set by a user - prevents honeypot
    //tax distribution
    uint8 private _devTax=10;
    uint8 private _burnTax=10;
    uint8 private _marketingTax=65;
    uint8 private _liquidityTax=25;
    uint8 private _stakingTax=0;  
    uint8 private _buyBackTax=0; 
    //buy, sell and transfer tax
    uint8 private _buyTax=10;
    uint8 private _sellTax=10;
    uint8 private _transferTax=15;
    //starting reward split percentages
    uint8 private _MainRewardSplit=50;
    uint8 private _MiscRewardSplit=50;
    uint256 public  MaxWallet;
    uint256 public  sellLimit;
    address public MarketingWallet;     //This wallet has authorization and access to marketing funds
    address private Developer;      //This is set to deployer and has access to developer funds
    address public BurnAddress=0x000000000000000000000000000000000000dEaD;  //address used for burns
    
    //TestNet
    //address private constant PancakeRouter=0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    //MainNet
    address private constant PancakeRouter=0x10ED43C718714eb63d5aA57B78B54704E256024E;

    address public MainReward=0x3EE2200Efb3400fAbB9AacF31297cBdD1d435D47;   //change this address to desired reward token
    address public MiscReward=0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;   //Only MiscReward can be changed to BNB

    address private _pancakePairAddress; 
    IPancakeRouter02 private  _pancakeRouter;

    //authorized: owner, marketing, Developer
    modifier authorized() {
        require(_authorized(msg.sender), "Caller not authorized");
        _;
    }
    function _authorized(address addr) private view returns (bool){
        return addr==owner()||addr==MarketingWallet||addr==Developer;
    }

//constructor
    constructor () {
        _pancakeRouter = IPancakeRouter02(PancakeRouter);
        _pancakePairAddress = IPancakeFactory(_pancakeRouter.factory()).createPair(address(this), _pancakeRouter.WETH());
        _addToken(msg.sender,_totalSupply);
        emit Transfer(address(0), msg.sender, _totalSupply);
        
        
        //set MarketingWallet and Developer as deployer by default
        MarketingWallet=msg.sender;
        Developer=msg.sender;
        
        sellLimit=_totalSupply/SellLimitDivider;
        MaxWallet=_totalSupply/MaxWalletDivider;
        
        _excluded.add(msg.sender);
        _excluded.add(MarketingWallet);
        _excluded.add(Developer);    
        _excluded.add(address(this));
        _excludedFromStaking.add(address(this));
        _excludedFromStaking.add(BurnAddress);
        _excludedFromStaking.add(address(_pancakeRouter));
        _excludedFromStaking.add(_pancakePairAddress);
        _approve(address(this), address(_pancakeRouter), type(uint256).max);        
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
    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "<0 allowance");

        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    } 
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }    
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "Transfer > allowance");

        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }

/////////////////////////////   CLAIMS  /////////////////////////////////////////

    //claim reward token - differentiates between main/misc
    event OnWithdrawToken(uint256 amount, address token, address recipient);
    function claimToken(address addr, address token, uint256 payableAmount) private{
        require(!_isWithdrawing);
        _isWithdrawing=true;
        uint256 amount;
        if(isExcludedFromStaking(addr)){
            if(token==MainReward){
                amount=toBePaidMain[addr];
                toBePaidMain[addr]=0;
            } else{
                amount=toBePaidMisc[addr];
                toBePaidMisc[addr]=0;
            }
        }
        else{
            if(token==MainReward){
                uint256 newAmount=_newDividentsOf(addr, true);
                alreadyPaidMain[addr] = mainRewardShare * _balances[addr];
                amount=toBePaidMain[addr]+newAmount;
                toBePaidMain[addr]=0;
            } else {
                uint256 newAmount=_newDividentsOf(addr, false);
                alreadyPaidMisc[addr] = miscRewardShare * _balances[addr];
                amount=toBePaidMisc[addr]+newAmount;
                toBePaidMisc[addr]=0;                
            }
        }
        if(amount==0&&payableAmount==0){
            _isWithdrawing=false;
            return;
        }

        totalPayouts+=amount;
        amount+=payableAmount;
        address[] memory path = new address[](2);
        path[0] = _pancakeRouter.WETH();
        path[1] = token;

        _pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
        0,
        path,
        addr,
        block.timestamp);
        
        emit OnWithdrawToken(amount,token, addr);
        _isWithdrawing=false;
    }
    
    //ClaimMainReward token
    function ClaimMainReward() public {
        claimToken(msg.sender,MainReward,0);
    }
    
    //ClaimMiscReward differentiates between BNB or another rewardToken
    function ClaimMiscReward() public {
        if(MiscReward==_pancakeRouter.WETH()){
            _claimBNBTo(msg.sender,msg.sender,getDividents(msg.sender, false));
        } else {claimToken(msg.sender,MiscReward,0);}
    }    
    
    //function to claim BNB if misc reward set to BNB
    event OnClaimBNB(address AddressFrom,address AddressTo, uint256 amount);    
    function _claimBNBTo(address from, address to,uint256 amountWei) private{
        require(!_isWithdrawing);
        {require(amountWei!=0,"=0");        
        _isWithdrawing=true;
        _subtractDividents(from, amountWei);
        totalPayouts+=amountWei;
        (bool sent,) =to.call{value: (amountWei)}("");
        require(sent,"withdraw failed");}
        _isWithdrawing=false;
        emit OnClaimBNB(from,to,amountWei);
    }   
    
    function _subtractDividents(address addr,uint256 amount) private{
        if(amount==0) return;
        require(amount<=getDividents(addr, false),"exceeds divident");

        if(_excludedFromStaking.contains(addr)){
            toBePaidMisc[addr]-=amount;
        }
        else{
            uint256 newAmount=_newDividentsOf(addr, false);
            alreadyPaidMisc[addr] = miscRewardShare * _balances[addr];
            toBePaidMisc[addr]+=newAmount;
            toBePaidMisc[addr]-=amount;
        }
    }   
    
    function getDividents(address addr, bool main) private view returns (uint256){
        if(main){
            if(isExcludedFromStaking(addr)) return toBePaidMain[addr];
            return _newDividentsOf(addr, true)+toBePaidMain[addr];
        } else{
            if(isExcludedFromStaking(addr)) return toBePaidMisc[addr];
            return _newDividentsOf(addr, false)+toBePaidMisc[addr];            
        }
    }
    
    //gets balance of claimable MainReward
    function getMainBalance(address addr) public view returns (uint256){
        uint256 amount=getDividents(addr, true);
        return amount;
    }

    //gets balance of claimable MiscReward
    function getMiscBalance(address addr) public view returns (uint256){
        uint256 amount=getDividents(addr, false);
        return amount;
    }    
    
    //Switch reward to new token. Cannot set newReward BNB to prevent claim function from breaking.
    event OnChangeMainReward (address NewMainReward);
    function ChangeMainReward(address newReward) public authorized{
        require(newReward != _pancakeRouter.WETH(), "newReward cannot be BNB");
        MainReward=newReward;
        emit OnChangeMainReward(newReward);
    }
    
    //Switch reward to new token. Only Misc reward can be changed to bnb
    event OnChangeMiscReward (address NewMiscReward);
    function ChangeMiscReward(address newReward) public authorized{
        MiscReward=newReward;
        emit OnChangeMiscReward(newReward);
    }
    
/////////////////////////////   LP LOCK  ///////////////////////////////////////// 

//OnlyOwner has control of LP functions
    uint256 private _liquidityUnlockTime;

    //Prolongs LP lock time    
    event ExtendLiquidityLock(uint256 extendedLockTime);
    function LockLiquidityTokens(uint256 lockTimeInSeconds) public onlyOwner{
        _lockLiquidityTokens(lockTimeInSeconds+block.timestamp);
        emit ExtendLiquidityLock(lockTimeInSeconds);
    }
    function _lockLiquidityTokens(uint256 newUnlockTime) private{
        // require new unlock time to be longer than old one
        require(newUnlockTime>_liquidityUnlockTime);
        _liquidityUnlockTime=newUnlockTime;
    }

    //Impossible to release LP unless LP lock time is zero
    function ReleaseLP() public onlyOwner {
        require(block.timestamp >= _liquidityUnlockTime, "Not yet unlocked");
        IPancakeERC20 liquidityToken = IPancakeERC20(_pancakePairAddress);
        uint256 amount = liquidityToken.balanceOf(address(this));
            liquidityToken.transfer(msg.sender, amount);
    }

    //Impossible to remove LP unless lock time is zero
    function RemoveLP() public onlyOwner {
        require(block.timestamp >= _liquidityUnlockTime, "Not yet unlocked");
        _liquidityUnlockTime=block.timestamp;
        IPancakeERC20 liquidityToken = IPancakeERC20(_pancakePairAddress);
        uint256 amount = liquidityToken.balanceOf(address(this));
        liquidityToken.approve(address(_pancakeRouter),amount);
        _pancakeRouter.removeLiquidityETHSupportingFeeOnTransferTokens(
            address(this),
            amount,
            0,
            0,
            address(this),
            block.timestamp
            );
        (bool sent,) =msg.sender.call{value: (address(this).balance)}("");
        require(sent);            
    }
    
    //Can only be called when LP lock time is zero. Recovers any stuck BNB in the contract
    function RecoverBNB() public onlyOwner {
        require(block.timestamp >= _liquidityUnlockTime, "Not yet unlocked");
        _liquidityUnlockTime=block.timestamp;
        (bool sent,) =msg.sender.call{value: (address(this).balance)}("");
        require(sent);
    }
    
/////////////////////////////   STAKING REWARDS  /////////////////////////////////////////
    bool private _isWithdrawing;
    uint256 private constant DistributionMultiplier = 2**64;
    uint256 private _totalShares=_totalSupply;
    uint256 private mainRewardShare;
    uint256 private miscRewardShare;
    uint256 public totalRewards;
    uint256 public totalPayouts;
    uint256 public MarketingBalance;
    uint256 public DevBalance;
    uint256 public BuyBackBalance;    
    uint16 public AutoLPThreshold=50;
    mapping(address => uint256) private alreadyPaidMain;
    mapping(address => uint256) private toBePaidMain;    
    mapping(address => uint256) private alreadyPaidMisc;
    mapping(address => uint256) private toBePaidMisc;    
    
    //update contract token swap percentage
    event onUpdateLPThreshold(uint16 newThreshold);
    function UpdateAutoLPThreshold(uint16 Threshold) public authorized{
        require(Threshold>0,"Threshold needs to be more than 0");
        require(Threshold<=50,"Threshold needs to be below 50");
        AutoLPThreshold=Threshold;
        emit onUpdateLPThreshold(Threshold);
    }
    
    //Manual contract token swap for LP and BNB
    function CreateLPandBNB(uint16 PermilleOfPancake, bool ignoreLimits) public authorized{
    _swapContractToken(PermilleOfPancake, ignoreLimits);
    }    
    
    function getTotalShares() public view returns (uint256){
        return _totalShares-_totalSupply;
    }

    function isExcludedFromStaking(address addr) public view returns (bool){
        return _excludedFromStaking.contains(addr);
    }

    function _addToken(address addr, uint256 amount) private {
        uint256 newAmount=_balances[addr]+amount;
        
        if(isExcludedFromStaking(addr)){
           _balances[addr]=newAmount;
           return;
        }
        _totalShares+=amount;
        uint256 mainPayment=_newDividentsOf(addr, true);
        uint256 miscPayment=_newDividentsOf(addr, false);
        _balances[addr]=newAmount;
        alreadyPaidMain[addr] = mainRewardShare * newAmount;
        toBePaidMain[addr]+=mainPayment;
        alreadyPaidMisc[addr] = miscRewardShare * newAmount;
        toBePaidMisc[addr]+=miscPayment; 
        _balances[addr]=newAmount;
    }

    function _removeToken(address addr, uint256 amount) private {
        uint256 newAmount=_balances[addr]-amount;
        
        if(isExcludedFromStaking(addr)){
           _balances[addr]=newAmount;
           return;
        }
        _totalShares-=amount;
        uint256 mainPayment=_newDividentsOf(addr, true);
        uint256 miscPayment=_newDividentsOf(addr, false);
        _balances[addr]=newAmount;
        alreadyPaidMain[addr] = mainRewardShare * newAmount;
        toBePaidMain[addr]+=mainPayment;
        alreadyPaidMisc[addr] = miscRewardShare * newAmount;
        toBePaidMisc[addr]+=miscPayment; 
    }
    
    function _newDividentsOf(address staker, bool main) private view returns (uint256) {
        if(main){
        uint256 fullPayout = mainRewardShare * _balances[staker];
        if(fullPayout<alreadyPaidMain[staker]) return 0;
        return (fullPayout - alreadyPaidMain[staker]) / DistributionMultiplier;}  
        else{
        uint256 fullPayout = miscRewardShare * _balances[staker];
        if(fullPayout<alreadyPaidMisc[staker]) return 0;
        return (fullPayout - alreadyPaidMisc[staker]) / DistributionMultiplier;}        
    }

    //This deals with splitting the taxes
    function _distributeStake(uint256 BNBamount,bool newStakingReward) private {
        uint256 MarketingSplit = (BNBamount * _marketingTax) / 100;
        uint256 DevSplit = (BNBamount * _devTax) / 100;
        uint256 BuyBackSplit = (BNBamount * _buyBackTax) / 100;        
        uint256 amount = BNBamount - (MarketingSplit+DevSplit+BuyBackSplit);
        uint256 MainAmount = (amount * _MainRewardSplit) / 100;
        uint256 MiscAmount = (amount * _MiscRewardSplit) / 100;
       MarketingBalance+=MarketingSplit;
       DevBalance+=DevSplit;
       BuyBackBalance+=BuyBackSplit; 
        if (amount > 0) {
            if(newStakingReward){
                totalRewards += amount;
            }
            uint256 totalShares=getTotalShares();
            if (totalShares == 0) {
                MarketingBalance += amount;
            }else{
                mainRewardShare += ((MainAmount * DistributionMultiplier) / totalShares);
                miscRewardShare += ((MiscAmount * DistributionMultiplier) / totalShares);
            }
        }
    }

    uint256 public totalLPBNB;
    bool private _isSwappingContractModifier;
    modifier lockTheSwap {
        _isSwappingContractModifier = true;
        _;
        _isSwappingContractModifier = false;
    }

    function _swapContractToken(uint16 permilleOfPancake,bool ignoreLimits) private lockTheSwap{
        require(permilleOfPancake<=500);
        uint256 contractBalance=_balances[address(this)];
        uint16 totalTax=_liquidityTax+_stakingTax+_marketingTax+_devTax+_buyBackTax;
        if(totalTax==0) return;

        uint256 tokenToSwap=_balances[_pancakePairAddress]*permilleOfPancake/1000;
        if(tokenToSwap>sellLimit&&!ignoreLimits) tokenToSwap=sellLimit;
        
        bool NotEnoughToken=contractBalance<tokenToSwap;
        if(NotEnoughToken){
            if(ignoreLimits)
                tokenToSwap=contractBalance;
            else return;
        }
        if(_allowances[address(this)][address(_pancakeRouter)]<tokenToSwap)
            _approve(address(this), address(_pancakeRouter), type(uint256).max);        
        uint256 tokenForLiquidity=(tokenToSwap*_liquidityTax)/totalTax;
        uint256 remainingToken= tokenToSwap-tokenForLiquidity;
        uint256 liqToken=tokenForLiquidity/2;
        uint256 liqBNBToken=tokenForLiquidity-liqToken;
        uint256 swapToken=liqBNBToken+remainingToken;
        uint256 initialBNBBalance = address(this).balance;
        _swapTokenForBNB(swapToken);
        uint256 newBNB=(address(this).balance - initialBNBBalance);
        uint256 liqBNB = (newBNB*liqBNBToken)/swapToken;
        _addLiquidity(liqToken, liqBNB);
        uint256 distributeBNB=(address(this).balance - initialBNBBalance);
        _distributeStake(distributeBNB,true);
    }
    
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
 
    //switch contract auto sells on and off
    bool private manualSwap;
    function ManualBNBSwap(bool manual) public authorized{
        manualSwap=manual;
    }   
/////////////////////////////   TRANSFERS  /////////////////////////////////////////

    function _calculateFee(uint256 amount, uint8 tax, uint8 taxPercent) private pure returns (uint256) {
        return (amount*tax*taxPercent) / 10000;
    }
    
    function _feelessTransfer(address sender, address recipient, uint256 amount) private{
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer exceeds balance");
        _removeToken(sender,amount);
        _addToken(recipient, amount);
        if(recipient==BurnAddress){
            _circulatingSupply-=amount;
        }
        emit Transfer(sender,recipient,amount);
    }  

    function _taxedTransfer(address sender, address recipient, uint256 amount,bool isBuy,bool isSell) private{
        uint256 recipientBalance = _balances[recipient];
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer exceeds balance");

        uint8 tax;
        if(isSell){
            require(amount<=sellLimit,"Dump protection");
             tax=_sellTax;

        } else if(isBuy){
            if(amount<=10**(_decimals)) claimToken(recipient,MainReward,0);   //buy less than 1 token to ClaimRewardToken         
            require(recipientBalance+amount<=MaxWallet,"whale protection");
            tax=_buyTax;

        } else {
            if(amount<=10**(_decimals)){    //transfer less than 1 token to ClaimBNB
                if(MiscReward==_pancakeRouter.WETH()){
                    _claimBNBTo(msg.sender,msg.sender,getDividents(msg.sender, false));
                } else {claimToken(msg.sender,MiscReward,0);}
                return;}
            require(recipientBalance+amount<=MaxWallet,"whale protection");            
            tax=_transferTax;
        }     
        if((sender!=_pancakePairAddress)&&(!manualSwap)&&(!_isSwappingContractModifier)&&isSell)
            _swapContractToken(AutoLPThreshold,false);
        uint256 tokensToBeBurnt=_calculateFee(amount, tax, _burnTax);
        uint256 contractToken=_calculateFee(amount, tax, _stakingTax+_liquidityTax+_marketingTax+_devTax+_buyBackTax);
        uint256 taxedAmount=amount-(tokensToBeBurnt+contractToken);
        _removeToken(sender,amount);
       _addToken(address(this), contractToken);
       _circulatingSupply-=tokensToBeBurnt;
        _addToken(recipient, taxedAmount);
        emit Transfer(sender,recipient,taxedAmount);
    }
    
    function _transfer(address sender, address recipient, uint256 amount) private{
        require(sender != address(0), "Transfer from zero");
        require(recipient != address(0), "Transfer to zero");
        bool isExcluded = (_excluded.contains(sender) || _excluded.contains(recipient));

        bool isContractTransfer=(sender==address(this) || recipient==address(this));
        address pancakeRouter=address(_pancakeRouter);
        bool isLiquidityTransfer = ((sender == _pancakePairAddress && recipient == pancakeRouter) 
        || (recipient == _pancakePairAddress && sender == pancakeRouter));
        bool isSell=recipient==_pancakePairAddress|| recipient == pancakeRouter;
        bool isBuy=sender==_pancakePairAddress|| sender == pancakeRouter;

        if(isContractTransfer || isLiquidityTransfer || isExcluded){
            _feelessTransfer(sender, recipient, amount);
        }
        else{ 
            _taxedTransfer(sender,recipient,amount,isBuy,isSell);                  
        }
    }

    //Buy back function that burns the bought tokens immediately
    event Buyback(uint256 BuybackAmount);
    function TriggerBuyBack(uint256 amount) public authorized{
        require(amount<=BuyBackBalance, "Amount exceeds BuyBackBalance!");
        BuyBackBalance-=amount;
        
        address[] memory path = new address[](2);
        path[0] = _pancakeRouter.WETH();
        path[1] = address(this);

        _pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
        0,
        path,
        BurnAddress,
        block.timestamp);  
        emit Buyback(amount);
    }
    
    //burning can be done via direct transfer to BurnAddress. Burn function gives transparency
    event onBurnTokens(uint256 TokensBurnt);
    function BurnTokens (uint256 amount) public{
        uint256 convertedAmount = amount * 10**_decimals;
        uint256 senderBalance = _balances[msg.sender];
        require(senderBalance >= convertedAmount, "Burn amount exceed user's balance");
        _removeToken(msg.sender,convertedAmount);
        _addToken(BurnAddress, convertedAmount);
        _circulatingSupply-=convertedAmount;
        emit Transfer(msg.sender,BurnAddress,convertedAmount);
        emit onBurnTokens(convertedAmount);
    }
    
    //Withdraw all bnb in DevBalance
    function WithdrawAllDev() public authorized{
        uint256 amount=DevBalance;
        DevBalance=0;
        (bool sent,) =Developer.call{value: (amount)}("");
        require(sent,"withdraw failed");
    } 
    
    //Withdraw desired amount in wei
    function WithdrawDev(uint256 amount) public authorized{
        require(amount<=DevBalance);
        DevBalance-=amount;
        (bool sent,) =Developer.call{value: (amount)}("");
        require(sent,"withdraw failed");
    } 

    //Withdraw all bnb in MarketingBalance
    function WithdrawAllMarketing() public authorized{
        uint256 amount=MarketingBalance;
        MarketingBalance=0;
        (bool sent,) =MarketingWallet.call{value: (amount)}("");
        require(sent,"withdraw failed");
    } 
    
    //Withdraw desired amount in wei
    function WithdrawMarketing(uint256 amount) public authorized{
        require(amount<=MarketingBalance);
        MarketingBalance-=amount;
        (bool sent,) =MarketingWallet.call{value: (amount)}("");
        require(sent,"withdraw failed");
    }     
/////////////////////////////   ADDRESS SETTINGS  /////////////////////////////////////////

    //Excludes an account from being able to receive rewards- exists to exclude address such as dead, pair, contract etc.
    event OnExcludeFromStaking(address excludedAddress);
    function ExcludeFromStaking(address addr) public authorized{
        require(!isExcludedFromStaking(addr));
        _totalShares-=_balances[addr];
        uint256 newDividentsMain=_newDividentsOf(addr, true);
        uint256 newDividentsMisc=_newDividentsOf(addr, false);        
        alreadyPaidMain[addr]=_balances[addr]*mainRewardShare;
        alreadyPaidMisc[addr]=_balances[addr]*miscRewardShare;        
        toBePaidMain[addr]+=newDividentsMain;
        toBePaidMisc[addr]+=newDividentsMisc;        
        _excludedFromStaking.add(addr);
        emit OnExcludeFromStaking(addr);
    }    

    //gives any wallet the ability to include themselves in staking if they were excluded
    function IncludeMeToStaking() public{
        require(isExcludedFromStaking(msg.sender));
        _totalShares+=_balances[msg.sender];
        _excludedFromStaking.remove(msg.sender);
        alreadyPaidMain[msg.sender]=_balances[msg.sender]*mainRewardShare;
        alreadyPaidMisc[msg.sender]=_balances[msg.sender]*miscRewardShare; 
    }
    event OnIncludeToStaking(address includedAddress);
    function IncludeToStaking(address addr) public authorized{
        require(isExcludedFromStaking(addr));
        _totalShares+=_balances[addr];
        _excludedFromStaking.remove(addr);
        alreadyPaidMain[addr]=_balances[addr]*mainRewardShare;
        alreadyPaidMisc[addr]=_balances[addr]*miscRewardShare; 
        emit OnIncludeToStaking(addr);
    }

    //onlyOwner can change MarketingWallet
    event UpdateMarketingWallet(address newMarketingWallet);
    function SetMarketingWallet(address addr) public onlyOwner{
        address prevMarketing=MarketingWallet;
        _excluded.remove(prevMarketing);
        MarketingWallet=addr;
        _excluded.add(MarketingWallet);
        emit UpdateMarketingWallet(addr);
    }

    //onlyOwner can change DevWallet
    event UpdateDevWallet(address newDevWallet);
    function SetDevWallet(address addr) public onlyOwner{
        address prevDev=Developer;
        _excluded.remove(prevDev);
        Developer=addr;
        _excluded.add(Developer);
        emit UpdateDevWallet(addr);
    }
    
    //exclude account from taxes - exists to exclude address such as presale address etc.
    event AccountExcluded(address account);
    function ExcludeAccountFromFees(address account) public authorized {
        _excluded.add(account);
        emit AccountExcluded(account);
    }
    
    event AccountIncluded(address account);
    function IncludeAccountToFees(address account) public authorized {
        _excluded.remove(account);
        emit AccountIncluded(account);
    }    


/////////////////////////////   SETTINGS  /////////////////////////////////////////


    //total of tax percentages must equal 100.
    event OnUpdateTaxes(uint8 burnTaxes, uint8 buybackTaxes, uint8 devTaxes, uint8 marketingTaxes, uint8 liquidityTaxes, uint8 stakingTaxes,uint8 buyTax, uint8 sellTax, uint8 transferTax);
    function UpdateTaxes(uint8 burnTaxes, uint8 buybackTaxes, uint8 devTaxes, uint8 marketingTaxes, uint8 liquidityTaxes, uint8 stakingTaxes,uint8 buyTax, uint8 sellTax, uint8 transferTax) public authorized{
        uint8 totalTax=liquidityTaxes+stakingTaxes+marketingTaxes+burnTaxes+buybackTaxes+devTaxes;
        
        //buy and sell tax can never be higher than MaxTax set at beginning of contract
        //this prevents owner from setting ridiculous tax or turning contract into honeypot
        require(totalTax==100, "marketing+liq+staking needs to equal 100%");
        require(buyTax<=MaxTax&&sellTax<=MaxTax,"taxes higher than max tax");
        require(transferTax<=50,"transferTax higher than max transferTax");
        _burnTax=burnTaxes;
        _buyBackTax=buybackTaxes;
        _devTax=devTaxes;
        _marketingTax=marketingTaxes;
        _liquidityTax=liquidityTaxes;
        _stakingTax=stakingTaxes;
        _buyTax=buyTax;
        _sellTax=sellTax;
        _transferTax=transferTax;
        emit OnUpdateTaxes(burnTaxes,buybackTaxes,devTaxes,marketingTaxes,liquidityTaxes,stakingTaxes,buyTax,sellTax,transferTax);
    }

    //total split percentages must equal 100
    event OnUpdateRewardSplit (uint8 NewMainSplit, uint8 NewMiscSplit);
    function UpdateRewardSplit (uint8 MainSplit, uint8 MiscSplit) public authorized{
        uint8 totalSplit=MainSplit+MiscSplit;
        require(totalSplit==100, 'MainSplit+MiscSplit needs to equal 100%');
        _MainRewardSplit=MainSplit;
        _MiscRewardSplit=MiscSplit;
        emit OnUpdateRewardSplit(MainSplit,MiscSplit);
    }
    
    event OnUpdateLimits(uint256 newMaxWallet, uint256 newSellLimit);
    function UpdateLimits(uint256 newMaxWallet, uint256 newSellLimit) public authorized{
        //Calculates the target Limits based on supply
        uint256 targetMaxWallet=_totalSupply/MaxWalletDivider;
        uint256 targetSellLimit=_totalSupply/SellLimitDivider;
        
        //MaxWallet and sellLimit can never be lower than original limits - this prevents honeypot
        require((newMaxWallet>=targetMaxWallet), 
        "newMaxWallet needs to be at least target");
        require((newSellLimit>=targetSellLimit), 
        "newSellLimit needs to be at least target");

        MaxWallet = newMaxWallet;
        sellLimit = newSellLimit;    
        emit OnUpdateLimits(newMaxWallet,newSellLimit);
    }

/////////////////////////////   DISPLAY INFO  /////////////////////////////////////////
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
    
    function getLimits() public view returns(uint256 balance, uint256 sell){
        return(MaxWallet/10, sellLimit/10);
    }  
    
    function getLiquidityUnlockInSeconds() public view returns (uint256){
        if(block.timestamp<_liquidityUnlockTime){
            return _liquidityUnlockTime-block.timestamp;
        }
        return 0;
    }

    function getTaxes() public view returns(uint256 burnTax, uint256 buybackTax, uint256 devTax, uint256 marketingTax, uint256 liquidityTax,uint256 rewardsTax, uint256 buyTax, uint256 sellTax, uint256 transferTax){
        return (_burnTax, _buyBackTax, _devTax, _marketingTax,_liquidityTax,_stakingTax,_buyTax,_sellTax,_transferTax);
    }   
    
    receive() external payable {}
}