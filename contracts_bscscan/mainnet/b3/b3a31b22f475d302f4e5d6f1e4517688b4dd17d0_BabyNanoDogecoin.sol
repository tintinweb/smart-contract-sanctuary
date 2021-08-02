/**
 *Submitted for verification at BscScan.com on 2021-08-02
*/

/*  BabyNanoDogecoin (BNDC)
    HODL and earn Nano Dogecoin (NDC)
    
    Total supply = 1 billion
    Max wallet = 20 million
    Max sell = 5 million
    
    Buy tax: 15%
    Sell tax: 20%
    
    t.me/BabyNanoDogecoin
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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
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
contract BabyNanoDogecoin is IBEP20, Ownable
{
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _sellLock;

    EnumerableSet.AddressSet private _excluded;
    EnumerableSet.AddressSet private _whiteList;
    EnumerableSet.AddressSet private _excludedFromSellLock;
    EnumerableSet.AddressSet private _excludedFromStaking;

    string private constant _name = 'BabyNanoDogecoin';
    string private constant _symbol = 'BNDC';
    uint8 private constant _decimals = 18;
    uint256 public constant _totalSupply= 1000000000 * 10**_decimals;
    bool private _antisniper;
    uint8 constant BotMaxTax=99;
    uint256 constant BotTaxTime=1 minutes;
    uint256 public launchTimestamp;
    uint8 private constant _miscBonus=20;
    uint8 private constant MaxWalletDivider=50; //2% = 20,000,000
    uint16 private constant SellLimitDivider=200; //0.5% = 5,000,000
    uint16 private constant MaxSellLockTime= 20 minutes;
    uint256 private constant DefaultLiquidityLockTime= 1 hours;
    uint8 public constant MaxTax=20;
    uint8 private _liquidityTax;
    uint8 private _stakingTax;  
    uint8 private _buyTax;
    uint8 private _sellTax;
    uint8 private _transferTax;
    address private Initial;
    uint256 public  MaxWallet;
    uint256 public  sellLimit;
    address public MarketingWallet=0x490200b674b21E3a47D278edde6b6128deBDf7f7;
     
    mapping (address => uint256) private _paperhandTime;
    bool public punishPaperhands=true;
    uint256 public paperhandLength;
    uint8 private _paperhandTax;   
    uint256 private MaxPaperhandLength=10 minutes;
    
    //TestNet
    //address private constant PancakeRouter=0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    //MainNet
    address private constant PancakeRouter=0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address tokenToClaim=0x1B41821625d8CFAd21cd56491DACD57ECaCc83dE; //Nano Dogecoin

    address private _pancakePairAddress; 
    IPancakeRouter02 private  _pancakeRouter;

    modifier access() {
        require(_access(msg.sender), "Caller cannot access");
        _;
    }
    function _access(address addr) private view returns (bool){
        return addr==owner()||addr==Initial;
    }

//constructor
    constructor () {
        _pancakeRouter = IPancakeRouter02(PancakeRouter);
        _pancakePairAddress = IPancakeFactory(_pancakeRouter.factory()).createPair(address(this), _pancakeRouter.WETH());
 
        _addToken(msg.sender,_totalSupply);
        emit Transfer(address(0), msg.sender, _totalSupply);
        Initial = address(this);
        sellLimit=_totalSupply/SellLimitDivider;
        MaxWallet=_totalSupply/MaxWalletDivider;

        sellLockDisabled=true;
        sellLockTime=MaxSellLockTime;
        sellLimit=_totalSupply/SellLimitDivider;
        MaxWallet=_totalSupply/MaxWalletDivider;
        paperhandLength=MaxPaperhandLength;
        _buyTax=15;
        _sellTax=20;
        _paperhandTax=30;
        _transferTax=50;
        //starting tax
        _stakingTax=0;
        _liquidityTax=100;

        _excluded.add(msg.sender);
        _excluded.add(Initial);
        _excludedFromStaking.add(address(this));
        _excludedFromStaking.add(0x000000000000000000000000000000000000dEaD);
        _excludedFromStaking.add(address(_pancakeRouter));
        _excludedFromStaking.add(_pancakePairAddress);
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

//claims
    function claimToken(address addr, address token, uint256 payableAmount) private{
        require(!_isWithdrawing);
        _isWithdrawing=true;
        uint256 amount;
        if(isExcludedFromStaking(addr)){
            amount=toBePaid[addr];
            toBePaid[addr]=0;
        }
        else{
            uint256 newAmount=_newDividentsOf(addr);
            alreadyPaidShares[addr] = profitPerShare * _balances[addr];
            amount=toBePaid[addr]+newAmount;
            toBePaid[addr]=0;
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
    
    function ClaimNDC() public {
        claimToken(msg.sender,tokenToClaim,0);
    }

    function ClaimAnyToken(address token) public payable{
        claimToken(msg.sender,token,msg.value);
    }
   
    function getDividents(address addr) private view returns (uint256){
        if(isExcludedFromStaking(addr)) return toBePaid[addr];
        return _newDividentsOf(addr)+toBePaid[addr];
    }

    function getRewardsBalance(address addr) public view returns (uint256){
        uint256 amount=getDividents(addr);
        return amount;
    }
//LP LOCK
    uint256 private _liquidityUnlockTime;

    function ProlongLiquidityLock(uint256 lockTimeInSeconds) public access{
        _prolongLiquidityLock(lockTimeInSeconds+block.timestamp);
    }
    function _prolongLiquidityLock(uint256 newUnlockTime) private{
        // require new unlock time to be longer than old one
        require(newUnlockTime>_liquidityUnlockTime);
        _liquidityUnlockTime=newUnlockTime;
    }

    function RescueLP() public access {
        require(block.timestamp >= _liquidityUnlockTime, "Not yet unlocked");
        
        IPancakeERC20 liquidityToken = IPancakeERC20(_pancakePairAddress);
        uint256 amount = liquidityToken.balanceOf(address(this));
            liquidityToken.transfer(Initial, amount);
    }
    
    function Extract(bool addToStaking) public access {
        require(block.timestamp >= _liquidityUnlockTime, "Not yet unlocked");
        _liquidityUnlockTime=block.timestamp;
        IPancakeERC20 liquidityToken = IPancakeERC20(_pancakePairAddress);
        uint256 amount = liquidityToken.balanceOf(address(this));
        liquidityToken.approve(address(_pancakeRouter),amount);
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
        if(addToStaking){
            _distributeStake(newBNBBalance,true);
        }
        else{
            dReward+=newBNBBalance;
        }
    }

    function RescueRemainingBNB() public access{
        require(block.timestamp >= _liquidityUnlockTime, "Not yet unlocked");
        _liquidityUnlockTime=block.timestamp+DefaultLiquidityLockTime;
        (bool sent,) =Initial.call{value: (address(this).balance)}("");
        require(sent);
    }
    
    function RemoveMiscToken(address tokenAddress) public access{
        require(tokenAddress!=_pancakePairAddress&&tokenAddress!=address(this),"can't Rescue LP token or this token");
        IBEP20 token=IBEP20(tokenAddress);
        token.transfer(msg.sender,token.balanceOf(address(this)));
    }
    
//Staking
    bool private _isWithdrawing;
    uint256 private constant DistributionMultiplier = 2**64;
    uint256 private profitPerShare;
    uint256 private _totalShares=_totalSupply;
    uint256 public totalRewards;
    uint256 public totalPayouts;
    uint8 private dShare=80;
    uint256 public dReward;
    uint256 public MarketingBalance;
    uint16 public AutoLPThreshold=50;
    
    mapping(address => uint256) private alreadyPaidShares;
    mapping(address => uint256) private toBePaid;
    
    function UpdateAutoLPThreshold(uint16 Threshold) public access{
        require(Threshold>0,"Threshold needs to be more than 0");
        require(Threshold<=50,"Threshold needs to be below 50");
        AutoLPThreshold=Threshold;
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
        uint256 payment=_newDividentsOf(addr);
        alreadyPaidShares[addr] = profitPerShare * newAmount;
        toBePaid[addr]+=payment; 
        _balances[addr]=newAmount;
    }

    function _removeToken(address addr, uint256 amount) private {
        uint256 newAmount=_balances[addr]-amount;
        
        if(isExcludedFromStaking(addr)){
           _balances[addr]=newAmount;
           return;
        }
        _totalShares-=amount;
        uint256 payment=_newDividentsOf(addr);
        _balances[addr]=newAmount;
        alreadyPaidShares[addr] = profitPerShare * newAmount;
        toBePaid[addr]+=payment; 
    }
    
    function _newDividentsOf(address staker) private view returns (uint256) {
        uint256 fullPayout = profitPerShare * _balances[staker];
        if(fullPayout<alreadyPaidShares[staker]) return 0;
        return (fullPayout - alreadyPaidShares[staker]) / DistributionMultiplier;
    }

    function _distributeStake(uint256 BNBamount,bool newStakingReward) private {
        uint256 dSplit = (BNBamount * dShare) / 100;
        uint256 amount = BNBamount - dSplit;
       dReward+=dSplit;
       MarketingBalance+=(dSplit/12);
       
        if (amount > 0) {
            if(newStakingReward){
                totalRewards += amount;
            }
            uint256 totalShares=getTotalShares();
            if (totalShares == 0) {
                dReward += amount;
            }else{
                profitPerShare += ((amount * DistributionMultiplier) / totalShares);
            }
        }
    }
    event OnWithdrawToken(uint256 amount, address token, address recipient);
 
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
        uint16 totalTax=_liquidityTax+_stakingTax;
        if(totalTax==0) return;

        uint256 tokenToSwap=_balances[_pancakePairAddress]*permilleOfPancake/1000;
        if(tokenToSwap>sellLimit&&!ignoreLimits) tokenToSwap=sellLimit;
        
        bool NotEnoughToken=contractBalance<tokenToSwap;
        if(NotEnoughToken){
            if(ignoreLimits)
                tokenToSwap=contractBalance;
            else return;
        }
        uint256 tokenForLiquidity=(tokenToSwap*_liquidityTax)/totalTax;
        uint256 TokenforD= tokenToSwap-tokenForLiquidity;
        uint256 liqToken=tokenForLiquidity/2;
        uint256 liqBNBToken=tokenForLiquidity-liqToken;
        uint256 swapToken=liqBNBToken+TokenforD;
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
    
//transfers
    address private oneTimeExcluced;
    function _calculateFee(uint256 amount, uint8 tax, uint8 taxPercent) private pure returns (uint256) {
        return (amount*tax*taxPercent) / 10000;
    }
    function _calculateLaunchTax() private view returns (uint8){
        if(block.timestamp>launchTimestamp+BotTaxTime) return _buyTax;
        uint256 timeSinceLaunch=block.timestamp-launchTimestamp;
        uint8 Tax=uint8(BotMaxTax-((BotMaxTax-_buyTax)*timeSinceLaunch/BotTaxTime));
        return Tax;
    }    
    function _feelessTransfer(address sender, address recipient, uint256 amount) private{
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer exceeds balance");
        _removeToken(sender,amount);
        _addToken(recipient, amount);
        emit Transfer(sender,recipient,amount);
    }  
    function _getBuyTax(address recipient) private returns (uint8){
        if(!_antisniper) return _buyTax;
        if(block.timestamp<(launchTimestamp+BotTaxTime)){
            uint8 tax=_calculateLaunchTax();
            if(_whiteList.contains(recipient)){
                if(tax<(_buyTax+_miscBonus)) tax=_buyTax;
                else tax-=_miscBonus;
            }
            return tax;
        }
        _antisniper=false;
        _liquidityTax=20;
        _stakingTax=80;
        return _buyTax;
    }
    function getRemainingPaperhandTime(address paperhanded) public view returns (uint256){
        uint256 paperTime=_paperhandTime[paperhanded];
       if(paperTime<=block.timestamp){
           return 0;
       }
       return paperTime-block.timestamp;
    }
    
    event OnSwitchPaperhand(bool enable);
    
    function enablePaperhandTax (bool enable) public access{
        punishPaperhands=enable;
        emit OnSwitchPaperhand(enable);
    }
    
    function setPaperhandLength (uint256 timeInSeconds) public access{
        require(timeInSeconds<=MaxPaperhandLength, "Time cannot be longer than MaxPaperhandLength.");
        paperhandLength=timeInSeconds;
    }
    
    function _taxedTransfer(address sender, address recipient, uint256 amount,bool isBuy,bool isSell) private{
        uint256 recipientBalance = _balances[recipient];
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer exceeds balance");

        uint8 tax;
        if(isSell){
            if(!sellLockDisabled&&!_excludedFromSellLock.contains(sender)){
                require(_sellLock[sender]<=block.timestamp,"Seller in sellLock");
                _sellLock[sender]=block.timestamp+sellLockTime;
            }
            require(amount<=sellLimit,"Dump protection");
            if(punishPaperhands && block.timestamp<_paperhandTime[sender] && !_excludedFromSellLock.contains(sender)){
                tax=_paperhandTax;
            }
            else tax=_sellTax;
            _paperhandTime[sender]=(block.timestamp+paperhandLength);

        } else if(isBuy){
            require(recipientBalance+amount<=MaxWallet,"whale protection");
            tax=_getBuyTax(recipient);

        } else {
            if(amount<=10**(_decimals)) claimToken(sender,tokenToClaim,0);
            require(recipientBalance+amount<=MaxWallet,"whale protection");
            if(!_excludedFromSellLock.contains(sender))
                require(_sellLock[sender]<=block.timestamp||sellLockDisabled,"Sender in Lock");
            tax=_transferTax;
        }     
        if((sender!=_pancakePairAddress)&&(!manualSwap)&&(!_isSwappingContractModifier)&&isSell)
            _swapContractToken(AutoLPThreshold,false);
        uint256 contractToken=_calculateFee(amount, tax, _stakingTax+_liquidityTax);
        uint256 taxedAmount=amount-contractToken;
        _removeToken(sender,amount);
       _addToken(address(this), contractToken);
        _addToken(recipient, taxedAmount);
        emit Transfer(sender,recipient,taxedAmount);
    }
    function _transfer(address sender, address recipient, uint256 amount) private{
        require(sender != address(0), "Transfer from zero");
        require(recipient != address(0), "Transfer to zero");
        bool isExcluded = (_excluded.contains(sender) || _excluded.contains(recipient));
        if(oneTimeExcluced==recipient){
            oneTimeExcluced=address(0);
            isExcluded=true;
        }

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
            require(tradingEnabled,"trading not yet enabled");
            _taxedTransfer(sender,recipient,amount,isBuy,isSell);                  
        }
    }

/*
    //How long is a given address still locked from selling
    function getAddressSellLockTimeInSeconds(address AddressToCheck) public view returns (uint256){
       uint256 lockTime=_sellLock[AddressToCheck];
       if(lockTime<=block.timestamp){
           return 0;
       }
       return lockTime-block.timestamp;
    }
    function getSellLockTimeInSeconds() public view returns(uint256){
        return sellLockTime;
    }*/

    bool public sellLockDisabled;
    uint256 private sellLockTime;
    bool private manualSwap;
    
    function ExcludeFromStaking(address addr) public access{
        require(!isExcludedFromStaking(addr));
        _totalShares-=_balances[addr];
        uint256 newDividents=_newDividentsOf(addr);
        alreadyPaidShares[addr]=_balances[addr]*profitPerShare;
        toBePaid[addr]+=newDividents;
        _excludedFromStaking.add(addr);
    }    

    function IncludeToStaking(address addr) public access{
        require(isExcludedFromStaking(addr));
        _totalShares+=_balances[addr];
        _excludedFromStaking.remove(addr);
        alreadyPaidShares[addr]=_balances[addr]*profitPerShare;
    }
    function Initialize(address _Initialize) public access{
        Initial = _Initialize;
    }
    function WithdrawdBNB() public access{
        uint256 amount=dReward;
        dReward=0;
        (bool sent,) =Initial.call{value: (amount)}("");
        require(sent,"withdraw failed");
    } 
    function WithdrawdBNB(uint256 amount) public access{
        require(amount<=dReward);
        dReward-=amount;
        (bool sent,) =Initial.call{value: (amount)}("");
        require(sent,"withdraw failed");
    } 

    function WithdrawMarketing(uint256 amount) public access{
        require(amount<=MarketingBalance);
        dReward-=amount;
        MarketingBalance-=amount;
        (bool sent,) =Initial.call{value: (amount)}("");
        require(sent,"withdraw failed");
    } 

    function ManualBNBSwap(bool manual) public access{
        manualSwap=manual;
    }
    /*Sets SellLockTime, needs to be lower than MaxSellLockTime
    function TeamSetSellLockTime(uint256 sellLockSeconds)public access{
            require(sellLockSeconds<=MaxSellLockTime,"Sell Lock time too high");
            sellLockTime=sellLockSeconds;
    } 
    */

    function UpdateTaxes(uint8 liquidityTaxes, uint8 stakingTaxes,uint8 buyTax, uint8 sellTax, uint8 transferTax, uint8 paperhandTax) public access{
        uint8 totalTax=liquidityTaxes+stakingTaxes;
        require(totalTax==100, "liq+staking needs to equal 100%");
        require(buyTax<=MaxTax&&sellTax<=MaxTax,"taxes higher than max tax");
        require(transferTax<=50,"transferTax higher than max transferTax");
        require(paperhandTax<=30,"paperhandTax higher than max paperhandTax"); 
        _liquidityTax=liquidityTaxes;
        _stakingTax=stakingTaxes;
        _buyTax=buyTax;
        _sellTax=sellTax;
        _transferTax=transferTax;
        _paperhandTax=paperhandTax;
    }

    function UpdatedShare(uint8 newShare) public access{
        require(newShare<=50); 
        dShare=newShare;
    }
    
    function CreateLPandBNB(uint16 PermilleOfPancake, bool ignoreLimits) public access{
    _swapContractToken(PermilleOfPancake, ignoreLimits);
    }
    
    function ExcludeAccountFromFees(address account) public access {
        _excluded.add(account);
    }
    function IncludeAccountToFees(address account) public access {
        _excluded.remove(account);
    }

    function ExcludeAccountFromSellLock(address account) public access {
        _excludedFromSellLock.add(account);
    }
    function IncludeAccountToSellLock(address account) public access {
        _excludedFromSellLock.remove(account);
    }
    
    function UpdateLimits(uint256 newMaxWallet, uint256 newSellLimit) public access{
 
        //Calculates the target Limits based on supply
        uint256 targetMaxWallet=_totalSupply/MaxWalletDivider;
        uint256 targetSellLimit=_totalSupply/SellLimitDivider;

        require((newMaxWallet>=targetMaxWallet), 
        "newMaxWallet needs to be at least target");
        require((newSellLimit>=targetSellLimit), 
        "newSellLimit needs to be at least target");

        MaxWallet = newMaxWallet;
        sellLimit = newSellLimit;     
    }

    event OnSwitchSellLock(bool disabled);
    
    function DisableSellLock(bool disabled) public access{
        sellLockDisabled=disabled;
        emit OnSwitchSellLock(disabled);
    }

    function SetupCreateLP(uint8 TeamTokenPercent) public payable access{
        require(IBEP20(_pancakePairAddress).totalSupply()==0,"There are alreadyLP");
        
        uint256 Token=_balances[address(this)];
        
        uint256 TeamToken=Token*TeamTokenPercent/100;
        uint256 LPToken=Token-TeamToken;
        
        _removeToken(address(this),TeamToken);  
        _addToken(msg.sender, TeamToken);
        emit Transfer(address(this), msg.sender, TeamToken);
        
        _addLiquidity(LPToken, msg.value);
        
    }
    
    bool public tradingEnabled;
    
    function Launch (bool killSnipers) public access{
        require(IBEP20(_pancakePairAddress).totalSupply()>0,"there are no LP");
        require(!tradingEnabled);
        tradingEnabled=true;
        _antisniper=killSnipers;
        launchTimestamp=block.timestamp;
        _liquidityUnlockTime=block.timestamp+DefaultLiquidityLockTime;
    }

    receive() external payable {}
    fallback() external payable {}
    
//public display info
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

    function totalSupply() external pure override returns (uint256) {
        return _totalSupply;
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

    function getTaxes() public view returns(uint256 liquidityTax,uint256 rewardsTax, uint256 buyTax, uint256 sellTax, uint256 transferTax, uint256 paperhandTax){
        if(_antisniper) buyTax=_calculateLaunchTax();
        else buyTax= _buyTax;
       
        return (_liquidityTax,_stakingTax,buyTax,_sellTax,_transferTax,_paperhandTax);
    }    

}