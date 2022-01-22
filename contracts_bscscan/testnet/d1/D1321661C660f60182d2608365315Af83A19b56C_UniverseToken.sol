/**
 *Submitted for verification at Etherscan.io on 2021-12-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeMath {

   function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
       uint256 c = a + b;
       if (c < a) return (false, 0);
       return (true, c);
   }

   function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
       if (b > a) return (false, 0);
       return (true, a - b);
   }

   function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
       if (a == 0) return (true, 0);
       uint256 c = a * b;
       if (c / a != b) return (false, 0);
       return (true, c);
   }


   function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
       if (b == 0) return (false, 0);
       return (true, a / b);
   }

   function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
       if (b == 0) return (false, 0);
       return (true, a % b);
   }

   function add(uint256 a, uint256 b) internal pure returns (uint256) {
       uint256 c = a + b;
       require(c >= a, "SafeMath: addition overflow");
       return c;
   }

   function sub(uint256 a, uint256 b) internal pure returns (uint256) {
       require(b <= a, "SafeMath: subtraction overflow");
       return a - b;
   }


   function mul(uint256 a, uint256 b) internal pure returns (uint256) {
       if (a == 0) return 0;
       uint256 c = a * b;
       require(c / a == b, "SafeMath: multiplication overflow");
       return c;
   }

   function div(uint256 a, uint256 b) internal pure returns (uint256) {
       require(b > 0, "SafeMath: division by zero");
       return a / b;
   }

   function mod(uint256 a, uint256 b) internal pure returns (uint256) {
       require(b > 0, "SafeMath: modulo by zero");
       return a % b;
   }


   function sub(
       uint256 a,
       uint256 b,
       string memory errorMessage
   ) internal pure returns (uint256) {
       require(b <= a, errorMessage);
       return a - b;
   }


   function div(
       uint256 a,
       uint256 b,
       string memory errorMessage
   ) internal pure returns (uint256) {
       require(b > 0, errorMessage);
       return a / b;
   }

   function mod(
       uint256 a,
       uint256 b,
       string memory errorMessage
   ) internal pure returns (uint256) {
       require(b > 0, errorMessage);
       return a % b;
   }
}

interface IERC20 {
   function totalSupply() external view returns (uint256);
   function balanceOf(address account) external view returns (uint256);
   function transfer(address recipient, uint256 amount) external returns (bool);
   function allowance(address owner, address spender) external view returns (uint256);
   function approve(address spender, uint256 amount) external returns (bool);
   function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
   function getOwner() external view returns (address);
   event Transfer(address indexed from, address indexed to, uint256 value);
   event Approval(address indexed owner, address indexed spender, uint256 value);
}
 
interface IERC20Metadata is IERC20 {
   function name() external view returns (string memory);
   function symbol() external view returns (string memory);
   function decimals() external view returns (uint8);
}

abstract contract Context {
   function _msgSender() internal view virtual returns (address) {return msg.sender;}
   function _msgData() internal view virtual returns (bytes calldata) {this; return msg.data;}
}

library Address {
   function isContract(address account) internal view returns (bool) {
       uint256 size; assembly { size := extcodesize(account) } return size > 0;
   }
   function sendValue(address payable recipient, uint256 amount) internal {
       require(address(this).balance >= amount, "Address: insufficient balance");(bool success, ) = recipient.call{ value: amount }("");
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
       if (success) { return returndata; } else {
           if (returndata.length > 0) {
               assembly {
                   let returndata_size := mload(returndata)
                   revert(add(32, returndata), returndata_size)
               }
           } else {revert(errorMessage);}
       }
   }
}

abstract contract Ownable is Context {
   address private _owner;
   address private _previousOwner;
   uint256 private _lockTime;

   event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   constructor () {
       address msgSender = _msgSender();
       _owner = msgSender;
       emit OwnershipTransferred(address(0), msgSender);
   }

   function owner() public view returns (address) {
       return _owner;
   }

   modifier onlyOwner() {
       require(_owner == _msgSender(), "Ownable: caller is not the owner");
       _;
   }

   function renounceOwnership() public virtual onlyOwner {
       emit OwnershipTransferred(_owner, address(0));
       _owner = address(0);
   }

   function transferOwnership(address newOwner) public virtual onlyOwner {
       require(newOwner != address(0), "Ownable: new owner is the zero address");
       emit OwnershipTransferred(_owner, newOwner);
       _owner = newOwner;
   }

   function getUnlockTime() public view returns (uint256) {
       return _lockTime;
   }

   function getTime() public view returns (uint256) {
       return block.timestamp;
   }

   function lock(uint256 time) public virtual onlyOwner {
       _previousOwner = _owner;
       _owner = address(0);
       _lockTime = block.timestamp + time;
       emit OwnershipTransferred(_owner, address(0));
   }

   function unlock() public virtual {
       require(_previousOwner == msg.sender, "You don't have permission to unlock");
       require(block.timestamp > _lockTime , "Contract is locked until 7 days");
       emit OwnershipTransferred(_owner, _previousOwner);
       _owner = _previousOwner;
       _previousOwner = address(0);
   }
}

contract UniverseToken is IERC20Metadata, Context, Ownable {
    using SafeMath for uint256;
    using Address for address;

    address public marketingFeeReceiver = 0xe0b66F4550C5aa4dc4dF333529Ce4932389d1d36;
    address public developmentwallet = 0xe0b66F4550C5aa4dc4dF333529Ce4932389d1d36;
    address public deadAddress = 0x000000000000000000000000000000000000dEaD;

    string constant _name = "Universe";
    string constant _symbol = "UNIV";
    uint8 constant _decimals = 18;

    uint256 private constant MAX = ~uint256(0);
    uint256 internal constant _tTotal = 5 * 10**8 * 10**9;
    uint256 internal _rTotal = (MAX - (MAX % _tTotal));

    uint256 public _tFeeTotal;
    
    uint256 public tFeePercent = 100;
    uint256 public marektingFeePercent = 100;

    uint256 public _tFee = 3;
    uint256 internal _previoustFee = _tFee;
    
    uint256 public _marketingFee =10;
    uint256 internal _previousmaketingFee = _marketingFee;

    mapping (address => uint256) internal _rOwned;
    mapping (address => uint256) internal _tOwned;
    mapping (address => mapping (address => uint256)) internal _allowances;

    mapping (address => bool) internal _isExcludedFromFee;
    mapping (address => bool) internal _isExcluded;
    address[] private _excluded;
    
    constructor () {
        _rOwned[msg.sender] = _rTotal;      
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[marketingFeeReceiver] = true;
        _isExcludedFromFee[developmentwallet] = true;
        emit Transfer(address(0), _msgSender(), _tTotal);
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
        return _tTotal;
    }
    
    function getOwner() external view override returns (address) { 
        return owner(); 
        
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) external view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }
    
    function setMarketingFeeReceiver(address _marketingFeeReceiver) external onlyOwner() {
        marketingFeeReceiver = _marketingFeeReceiver;
    }
    

    function excludeFromReward(address account) public onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
       (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 marketingFee) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _takeFee(marketingFee, marketingFeeReceiver);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function excludeFromFee(address account) public onlyOwner() {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner() {
        _isExcludedFromFee[account] = false;
    }
    
    function setReflectionFeePercent(uint256 _tFeePercent) external onlyOwner() {
        require(_tFeePercent >= 0, "_tFeePercent should be same or bigger than 0");
        require(_tFeePercent <= 100, "_tFeePercent should be same or smaller than 100");
        tFeePercent = _tFeePercent;
    }
    
    function setMarketingFeePercent(uint256 _marektingFeePercent) external onlyOwner() {
        require(_marektingFeePercent >= 0, "_marektingFeePercent should be same or bigger than 0");
        require(_marektingFeePercent <= 100, "_marektingFeePercent should be same or smaller than 100");
        marektingFeePercent = _marektingFeePercent;
    } 

    function _reflectFee(uint256 rFee, uint256 tFee) internal {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) internal view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 marketingFee) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, marketingFee, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, marketingFee);
    }

    function _getTValues(uint256 tAmount) internal view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateReflectionFee(tAmount);
        uint256 marketingFee = calculateMarketingFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(marketingFee);
        return (tTransferAmount, tFee, marketingFee);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 marketingFee, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rmarketingFee = marketingFee.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rmarketingFee);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() internal view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() internal view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    
    function calculateReflectionFee(uint256 _amount) internal view returns (uint256) {
        return _amount.mul(_tFee).mul(tFeePercent).div(
            10**4
        );
    }

    function calculateMarketingFee(uint256 _amount) internal view returns (uint256) {
        return _amount.mul(_marketingFee).mul(marektingFeePercent).div(
            10**4
        );
    }
    
    function removeAllFee() internal {
        if(_tFee == 0 && _marketingFee == 0) return;
        
        _previoustFee = _tFee;
        _previousmaketingFee = _marketingFee;
        
        _tFee = 0;
        _marketingFee = 0;
    }
    
    function restoreAllFee() internal {
       _tFee = _previoustFee;
       _marketingFee = _previousmaketingFee;
    }
    
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }
    

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(from != address(deadAddress), "Token: transfer from the burn address");
        require(amount > 0, "Transfer amount must be greater than zero");
        bool takeFee = true;
        
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }         
        _tokenTransfer(from,to,amount,takeFee);
    }

    function _takeFee(uint256 fee, address feeRecevier) internal {
       uint256 currentRate =  _getRate();
       uint256 rFee = fee.mul(currentRate);
       _rOwned[feeRecevier] = _rOwned[feeRecevier].add(rFee);
       if(_isExcluded[feeRecevier])
           _tOwned[feeRecevier] = _tOwned[feeRecevier].add(rFee);

    }

    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        if(!takeFee)
            removeAllFee();
        
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        
        if(!takeFee)
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 marketingFee) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeFee(marketingFee, marketingFeeReceiver);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
       (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 marketingFee) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _takeFee(marketingFee, marketingFeeReceiver);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
       (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 marketingFee) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _takeFee(marketingFee, marketingFeeReceiver);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    receive() external payable {}
}