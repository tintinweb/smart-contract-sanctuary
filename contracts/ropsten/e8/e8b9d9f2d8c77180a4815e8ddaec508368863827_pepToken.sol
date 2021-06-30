/**
 *Submitted for verification at Etherscan.io on 2021-06-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }


    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract Pausable is Context {

    event Paused(address account);

    event Unpaused(address account);

    bool private _paused;

    constructor() {
        _paused = false;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}


contract pepToken is Ownable, IERC20, IERC20Metadata, Pausable{
    using Address for address;
   event Sign_Up (address indexed from, address indexed recommader, uint256 value);
    mapping(address => uint256) public _balances;
    
    mapping(address => uint256) public _Peoplebalances;
    
    mapping(address => people) private _isPeople;
   
    mapping(address => mapping(address => uint256)) private _allowances;
   
   address CEO = msg.sender; // 회원
   address CFO = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2; // 회원 X
   address CMO = 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db; // 회원
   address Sign_balance = 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB; // pair address
   /* 
   발행량 10억개
   역할
   CEO - 대표
   CFO - 유동성공급 / 회원모집시 이더리움 관리 ( 회원 x )
   CMO - 회원시 토큰 공급 및 마케팅
   sign_balance는 유니스왑 페어 어드레스
   
   토큰 분배
   CEO - 5천만개
   CFO - 5억 (유동성 공급)
   CMO - 4.5억
   1 : 1000 비율
   */
    struct people{
        bool people;
        address recommend;
    }
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1000000000 * 10**18; 
    uint256 public _rTotal = (MAX - (MAX % _tTotal));
   uint256 public _excludbalance = 0;
   uint256 public _excludpeople = 0;
    uint256 private _tFeeTotal;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
   
    constructor() {
        _name = "People";
        _symbol = "PEP";
        _Peoplebalances[CEO] = _rTotal;
        _isPeople[CEO] = people(true,CEO);
        _mint(msg.sender, 1000000000 * 10 ** 18);
        _balances[msg.sender] = 0;
    }
    

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
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
   
       function pause() onlyOwner() public {

        _pause();

        }

       function unpause() onlyOwner() public {

        _unpause();

    }

 
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        if(_isPeople[account].people) return tokenFromPeople(_Peoplebalances[account]);
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }


    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }


    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function tokenFromPeople(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        uint256 result;
        unchecked{
            result = rAmount / currentRate;
        }
        return result;
    }
    
       function tokenFromPeople_view(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        uint256 result;
        unchecked{
            result = rAmount * currentRate;
        }
        return result;
    }
    
  
  function add_sign(address _Addr) public onlyOwner {
    require(!_isPeople[_Addr].people,"already registered");
    require(_balances[_Addr] == 0,"Sorry balances Not zero");
          if(_Peoplebalances[_Addr] != 0){
      uint256 P_bal = _Peoplebalances[_Addr];
         unchecked{
         _excludpeople -= _Peoplebalances[_Addr];
         _Peoplebalances[_Addr] -= P_bal;
         _rTotal -= P_bal;
         }
      }
         _isPeople[_Addr] = people(true,CEO);
    }
    
    
   function SignUp(address recommander) public payable{
   require(!_isPeople[msg.sender].people,"already registered");
   require(_isPeople[recommander].people,"The wallet address you entered is not a subscriber");
   require(msg.value == 1000000000000000000,"You need to pay 1 Ethereum");
   require(Sign_balance.balance >= 1000000000000000000,"Sorry, Ethereum owned by the pair must be at least 1 ETH");
   uint256 result = Sign_reward();
   require(balanceOf(CMO) >= result,"Sorry, you don't have enough tokens to send");
   payable (CFO).transfer(900000000000000000);
   payable (recommander).transfer(100000000000000000);
    uint256 bal = _balances[msg.sender];
      uint256 P_bal = _Peoplebalances[msg.sender] - tokenFromPeople_view(bal);
  unchecked{
        _excludbalance -= bal;
        _excludpeople -= _Peoplebalances[msg.sender];
    }
  if(_balances[msg.sender] != 0) _balances[msg.sender] = 0;
  if(_Peoplebalances[msg.sender] != 0){
     unchecked{
     _Peoplebalances[msg.sender] -= P_bal;
     _rTotal -= P_bal;
     }
  }
      _isPeople[msg.sender] = people(true,recommander);
      uint256 reward_transpep = tokenFromPeople_view(result);
      unchecked{
         _Peoplebalances[CMO] -= reward_transpep;
         _Peoplebalances[msg.sender] += reward_transpep;
      }
      emit Sign_Up(msg.sender,recommander,result);
   }

   function Sign_reward() public view returns(uint256){ 
      uint256 ETH = Sign_balance.balance;
      uint256 balance_ = balanceOf(Sign_balance);
      uint256 K = (ETH * balance_);
      uint256 result;
      K = K / (10 ** 18);
      ETH += 1000000000000000000;
      result = (K / ETH) * (10 ** 18);
      result = balance_ - result;
      result = (result * 90) / 100;
      return result;
   }
   
 
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
      if(_isPeople[sender].people){
        uint256 people_amount = tokenFromPeople(_Peoplebalances[sender]);
        require(people_amount >= amount, "ERC20: transfer amount exceeds balance");
        }
      else require(_balances[sender] >= amount,"ERC20: transfer amount exceeds balance");
        if(_isPeople[sender].people && _isPeople[recipient].people) {
            _transferBothPeople(sender, recipient, amount);
        } else if(_isPeople[sender].people && !_isPeople[recipient].people) {
            _transferToNotPeople(sender, recipient, amount);
        } else if(!_isPeople[sender].people && _isPeople[recipient].people) {
            _transferToPeople(sender, recipient, amount);
        } else if(!_isPeople[sender].people && !_isPeople[recipient].people) {
            _transferstandard(sender, recipient, amount);
        }
    }

     function _transferBothPeople(address sender, address recipient, uint256 amount) private{
       _beforeTokenTransfer(sender, recipient, amount);
               (uint256 rAmount, uint256 rTransferAmount,, uint256 r_memberFee, uint256 r_recommandFee, uint256 t_memberFee) = _getReValues(amount);
       unchecked{
        _Peoplebalances[sender] -= rAmount;
        _Peoplebalances[recipient] += rTransferAmount;
      _Peoplebalances[_isPeople[sender].recommend] += r_recommandFee;
        _rTotal -= r_memberFee;
        _tFeeTotal += t_memberFee;
       }
       emit Transfer(sender, recipient, amount);
    }
    
    function _transferToNotPeople(address sender,address recipient, uint256 amount) private {
       _beforeTokenTransfer(sender, recipient, amount);
       unchecked{
        (uint256 rAmount, uint256 rTransferAmount, uint256 tTransferAmount, uint256 r_memberFee, uint256 r_recommandFee, uint256 t_memberFee) = _getReValues(amount);
        _Peoplebalances[sender] -= rAmount;
        _balances[recipient] += tTransferAmount;
        _Peoplebalances[recipient] += rTransferAmount;
      _Peoplebalances[_isPeople[sender].recommend] += r_recommandFee;
      _excludbalance += tTransferAmount;
      _excludpeople += rTransferAmount;
        _rTotal -= r_memberFee;
        _tFeeTotal += t_memberFee;
       }
       emit Transfer(sender, recipient, amount);
    }
    
    function _transferToPeople(address sender,address recipient, uint256 amount) private{
       _beforeTokenTransfer(sender, recipient, amount);
       unchecked{
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee,, uint256 tFee) = _getValues(amount);
        _balances[sender] -= amount;
        _Peoplebalances[sender] -= rAmount;
        _Peoplebalances[recipient] += rTransferAmount;
      _excludbalance -= amount;
      _excludpeople -= rAmount;
        _rTotal -= rFee;
        _tFeeTotal += tFee;
       }
       emit Transfer(sender, recipient, amount);
    }
    
    function _transferstandard(address sender,address recipient, uint256 amount) private {
        _beforeTokenTransfer(sender, recipient, amount);
        unchecked{
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(amount);
        _balances[sender] -= amount;
        _Peoplebalances[sender] -= rAmount;
        _balances[recipient] += tTransferAmount;
        _Peoplebalances[recipient] += rTransferAmount;
        _rTotal -= rFee;
        _tFeeTotal += tFee;
      _excludbalance -= amount;
      _excludpeople -= rAmount;
      _excludbalance += tTransferAmount;
      _excludpeople += rTransferAmount;
        }
        emit Transfer(sender, recipient, amount);
    } 
    
     function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee) = _getTValues(tAmount);
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee);
    }
    
    function _getTValues(uint256 tAmount) private pure returns (uint256, uint256) {
        uint256 tFee;
        uint256 tTransferAmount;
        unchecked{
         tFee = (tAmount / 100) * 5;
         
         tTransferAmount = tAmount - tFee;
        }
        return (tTransferAmount, tFee);
    }
    
    function _getRValues(uint256 tAmount, uint256 tFee, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount;
        uint256 rFee;
        uint256 rTransferAmount;
        unchecked{
        rAmount = tAmount*currentRate;
        rFee = tFee*currentRate;
        rTransferAmount = rAmount - rFee;
        }
        return (rAmount, rTransferAmount, rFee);
    }
   
   function _getReValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 t_memberFee, uint256 t_recommandFee) = _getReTValues(tAmount);
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 r_memberFee, uint256 r_recommandFee) = _getReRValues(tAmount, currentRate, t_memberFee, t_recommandFee);
        return (rAmount, rTransferAmount, tTransferAmount, r_memberFee, r_recommandFee, t_memberFee);
    }
    
    function _getReTValues(uint256 tAmount) private pure returns (uint256, uint256, uint256) {
      uint256 t_memberFee;
      uint256 t_recommandFee;
        uint256 tTransferAmount;
        unchecked{
       t_memberFee = (tAmount / 100) * 3;
       t_recommandFee = (tAmount / 100) * 2;
         tTransferAmount = tAmount - t_memberFee - t_recommandFee ;
        }
        return (tTransferAmount, t_memberFee, t_recommandFee);
    }
    
    function _getReRValues(uint256 tAmount, uint256 currentRate, uint256 t_memberFee, uint256 t_recommandFee) private pure returns (uint256, uint256, uint256, uint256) {
        uint256 rAmount;
        uint256 rTransferAmount;
      uint256 r_memberFee;
      uint256   r_recommandFee;
        unchecked{
        rAmount = tAmount*currentRate;
      r_memberFee = t_memberFee*currentRate;
      r_recommandFee = t_recommandFee*currentRate;
        rTransferAmount = rAmount - r_memberFee - r_recommandFee;
        }
        return (rAmount, rTransferAmount, r_memberFee, r_recommandFee);
    }
    
    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        uint256 result;
        unchecked {
           result =  rSupply / tSupply;
        }
        return result;
    }
    
     function _getCurrentSupply() public view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;   
        uint256 _vrTotal;
      if(_excludpeople > rSupply || _excludbalance > tSupply) return (_rTotal,_tTotal);
        unchecked {
      rSupply -= _excludpeople;
      tSupply -= _excludbalance;
        _vrTotal = _rTotal / _tTotal;
        }
        if (rSupply < _vrTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }


    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
}