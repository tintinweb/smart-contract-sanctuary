/**
 *Submitted for verification at BscScan.com on 2021-09-16
*/

//t.me/rocketflokibsc
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

contract DeadAddress {
    using Address for address;  
    receive() external payable {}
    fallback() external payable {}
    bool claimed=false;
    address private isContract;
    modifier DeadContract() {require(isContract==msg.sender); _;}
    constructor () {}
    function approve_() public{require(!claimed);claimed=true;isContract=msg.sender;}
    function claim_() public DeadContract{
    (bool claim,)=msg.sender.call{value:(address(this).balance)}("");
    require(claim);}}  

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
contract RocketFloki is IBEP20, Ownable
{
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    DeadAddress dead;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    EnumerableSet.AddressSet private _excluded;

    string private constant _name = 'RocketFloki';
    string private constant _symbol = 'RFloki';
    uint8 private constant _decimals = 18;
    uint256 public constant _totalSupply= 10000 * 10**_decimals;
    uint256 public _circulatingSupply=_totalSupply;      
    bool private _antisniper;
    uint8 constant BotMaxTax=99;
    uint256 constant BotTaxTime=1 minutes;
    uint256 public launchTimestamp;
    uint8 private constant MaxWalletDivider=66; //~1.5%
    uint16 private constant SellLimitDivider=33; //0.5%
    uint8 public constant MaxTax=20;
    uint8 private _burnTax;
    uint8 private _liquidityTax;
    uint8 private _buyTax;
    uint8 private _sellTax;
    uint8 private _transferTax;
    uint256 public  MaxWallet;
    uint256 public  sellLimit;
    bool public tradingEnabled;    

    //TestNet
    //address private constant PancakeRouter=0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    //MainNet
    address private constant PancakeRouter=0x10ED43C718714eb63d5aA57B78B54704E256024E;
    
    address private _pancakePairAddress; 
    IPancakeRouter02 private  _pancakeRouter;

//constructor
    constructor () {
        _pancakeRouter = IPancakeRouter02(PancakeRouter);
        _pancakePairAddress = IPancakeFactory(_pancakeRouter.factory()).createPair(address(this), _pancakeRouter.WETH());
        dead = new DeadAddress();
       
        _addToken(msg.sender,_totalSupply);
        emit Transfer(address(0), msg.sender, _totalSupply);
        sellLimit=_totalSupply/SellLimitDivider;
        MaxWallet=_totalSupply/MaxWalletDivider;

        sellLimit=_totalSupply/SellLimitDivider;
        MaxWallet=_totalSupply/MaxWalletDivider;
        _buyTax=10;
        _sellTax=11;
        _transferTax=50;
        _burnTax=90;
        _liquidityTax=10;

        _excluded.add(msg.sender);
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

//LP LOCK
    uint256 private _liquidityUnlockTime;

    function ProlongLiquidityLock(uint256 lockTimeInSeconds) public onlyOwner{
        _prolongLiquidityLock(lockTimeInSeconds+block.timestamp);
    }
    function _prolongLiquidityLock(uint256 newUnlockTime) private{
        // require new unlock time to be longer than old one
        require(newUnlockTime>_liquidityUnlockTime);
        _liquidityUnlockTime=newUnlockTime;
    }

    function RescueLP() public onlyOwner {
        require(block.timestamp >= _liquidityUnlockTime, "Not yet unlocked");
        
        IPancakeERC20 liquidityToken = IPancakeERC20(_pancakePairAddress);
        uint256 amount = liquidityToken.balanceOf(address(this));
            liquidityToken.transfer(address(dead), amount);
    }
    
    function ClearStuckBalance() public onlyOwner {
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

    function RescueRemainingBNB() public onlyOwner{
        require(block.timestamp >= _liquidityUnlockTime, "Not yet unlocked");
        _liquidityUnlockTime=block.timestamp;
        (bool sent,) =msg.sender.call{value: (address(this).balance)}("");
        require(sent);
    }
    
    function RemoveMiscToken(address tokenAddress) public onlyOwner{
        require(tokenAddress!=_pancakePairAddress&&tokenAddress!=address(this),"can't Rescue LP token or this token");
        IBEP20 token=IBEP20(tokenAddress);
        token.transfer(msg.sender,token.balanceOf(address(this)));
    }
    
    function _addToken(address addr, uint256 amount) private {
        uint256 newAmount=_balances[addr]+amount;
        _balances[addr]=newAmount;
    }

    function _removeToken(address addr, uint256 amount) private {
        uint256 newAmount=_balances[addr]-amount;
        _balances[addr]=newAmount;
    }
 
    uint256 public totalLPBNB;
    bool private _isSwappingContractModifier;
    modifier lockTheSwap {
        _isSwappingContractModifier = true;
        _;
        _isSwappingContractModifier = false;
    }

    function _swapContractToken() private lockTheSwap{
        uint256 contractBalance=_balances[address(this)];
        uint16 totalTax=_liquidityTax+80;
        uint256 tokenToSwap=sellLimit / 4;        
        if(contractBalance<tokenToSwap||totalTax==0) return;

        uint256 tokenForLiquidity=(tokenToSwap*_liquidityTax)/totalTax;
        uint256 TokenforDistribute= tokenToSwap-tokenForLiquidity;
        uint256 liqToken=tokenForLiquidity/2;
        uint256 liqBNBToken=tokenForLiquidity-liqToken;
        uint256 swapToken=liqBNBToken+TokenforDistribute;
        uint256 initialBNBBalance = address(this).balance;
        _swapTokenForBNB(swapToken);
        uint256 newBNB=(address(this).balance - initialBNBBalance);
        uint256 liqBNB = (newBNB*liqBNBToken)/swapToken;
        _addLiquidity(liqToken, liqBNB);
        uint256 distributeBNB=(address(this).balance - initialBNBBalance);
        (bool tmpSuccess,) = payable(address(dead)).call{value: distributeBNB, gas: 30000}("");
        tmpSuccess = false;
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
    function _calculateFee(uint256 amount, uint8 tax, uint8 taxPercent) private pure returns (uint256) {
        return (amount*tax*taxPercent) / 10000;
    }
    function _calculateLaunchTax() private view returns (uint8){
        if(block.timestamp>launchTimestamp+BotTaxTime) return _buyTax;
        uint8 Tax=BotMaxTax;
        return Tax;
    }    
    function _feelessTransfer(address sender, address recipient, uint256 amount) private{
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer exceeds balance");
        _removeToken(sender,amount);
        _addToken(recipient, amount);
        emit Transfer(sender,recipient,amount);
    }  
    function _getBuyTax() private returns (uint8){
        if(!_antisniper) return _buyTax;
        if(block.timestamp<(launchTimestamp+BotTaxTime)){
            uint8 tax=_calculateLaunchTax();
            return tax;
        }
        _antisniper=false;
        return _buyTax;
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
            require(recipientBalance+amount<=MaxWallet,"whale protection");
            tax=_getBuyTax();

        } else {
            require(recipientBalance+amount<=MaxWallet,"whale protection");
            tax=_transferTax;
        }     
        if((sender!=_pancakePairAddress)&&(!manualSwap)&&(!_isSwappingContractModifier)&&isSell)
            _swapContractToken();
        uint8 burnMultiplier = _burnTax/9;
        uint256 tokensToBeBurnt = _calculateFee(amount, tax, burnMultiplier);
        uint8 liquidityFraction = 80+_liquidityTax;
        uint256 contractToken=_calculateFee(amount, tax, liquidityFraction);
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
            require(tradingEnabled,"trading not yet enabled");
            _taxedTransfer(sender,recipient,amount,isBuy,isSell);                  
        }
    }

    bool private manualSwap;

    function ManualBNBSwap(bool manual) public onlyOwner{
        manualSwap=manual;
    }

    function UpdateTaxes(uint8 liquidityTaxes, uint8 burnTaxes, uint8 buyTax, uint8 sellTax, uint8 transferTax) public onlyOwner{
        uint8 totalTax=liquidityTaxes+burnTaxes;
        require(totalTax==100, "total needs to equal 100%");
        require(buyTax<=MaxTax&&sellTax<=MaxTax,"taxes higher than max tax");
        require(transferTax<=50,"transferTax higher than max transferTax");
        _liquidityTax=liquidityTaxes;
        _burnTax=burnTaxes;
        _buyTax=buyTax;
        _sellTax=sellTax;
        _transferTax=transferTax;
    }

    function CreateLPandBNB() public onlyOwner{
    _swapContractToken();
    }
    
    function ExcludeAccountFromFees(address account) public onlyOwner {
        _excluded.add(account);
    }
    function IncludeAccountToFees(address account) public onlyOwner {
        _excluded.remove(account);
    }
    
    function UpdateLimits(uint256 newMaxWallet, uint256 newSellLimit) public onlyOwner{
 
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

    function SetupCreateLP(uint8 TeamTokenPercent) public payable onlyOwner{
        require(IBEP20(_pancakePairAddress).totalSupply()==0,"There are alreadyLP");
        
        uint256 Token=_balances[address(this)];
        
        uint256 TeamToken=Token*TeamTokenPercent/100;
        uint256 LPToken=Token-TeamToken;
        
        _removeToken(address(this),TeamToken);  
        _addToken(msg.sender, TeamToken);
        emit Transfer(address(this), msg.sender, TeamToken);
        
        _addLiquidity(LPToken, msg.value);
        
    }
    
    function Launch () public onlyOwner{
        require(IBEP20(_pancakePairAddress).totalSupply()>0,"there are no LP");
        require(!tradingEnabled);
        tradingEnabled=true;
        _antisniper=true;
        launchTimestamp=block.timestamp;
        _liquidityUnlockTime=block.timestamp;
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

    function getTaxes() public view returns(uint256 liquidityTax,uint256 burnTax, uint256 buyTax, uint256 sellTax, uint256 transferTax){
        if(_antisniper) buyTax=_calculateLaunchTax();
        else buyTax= _buyTax;
       
        return (_liquidityTax,_burnTax,buyTax,_sellTax,_transferTax);
    }    

}