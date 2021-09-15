/**
 *Submitted for verification at BscScan.com on 2021-09-15
*/

pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed
interface IERC20 {

    function totalSupply() external view returns (uint256);

   
    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address recipient, uint256 amount) external returns (bool);


    function allowance(address owner, address spender) external view returns (uint256);


    function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    
    event Transfer(address indexed from, address indexed to, uint256 value);


    event Approval(address indexed owner, address indexed spender, uint256 value);
}
 
library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

   
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

   
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

   
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

   
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }


    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; 
        return msg.data;
    }
}

contract Ownable is Context {
    address public _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
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

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = now + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(now > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}


contract UILToken is Context, IERC20, Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;

    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 2100000000 * 10 **8;
    uint256 private _rTotal;
    uint256 private _tFeeTotal;

    string private _name = "UIL";
    string private _symbol = "UIL";
    uint256 private _decimals = 8;
    
    uint256 public _taxFee = 2;
    uint256 private _previousTaxFee = 2;
    
    uint256 public _burnFee = 5;
    uint256 private _previousBurnFee = 5;
    
    uint256 public _recommendFee = 3;
    uint256 private _previousRecommendFee = 3;
    
    address internal constant burnAddress = address(0);
    
    mapping( address => address ) public recommers;
    
    constructor () public {
        _rTotal = (MAX - (MAX % _tTotal));

        _rOwned[msg.sender] = _rTotal;
       
        _isExcludedFromFee[msg.sender] = true;
        _isExcludedFromFee[address(this)] = true;
    
        _owner = msg.sender;
        emit Transfer(address(0), msg.sender, _tTotal);
    }
    
  
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        
        address from = _msgSender();
        
        if( !_isContract(from) 
            && !_isContract(recipient) 
            && recommers[recipient] == address(0) ){
                
            recommers[recipient] = from;
        }   
        
        _transfer(from, recipient, amount);

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

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
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
   
    
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    
    function setTaxFeePercent(uint256 taxFee) external onlyOwner() {
        _taxFee = taxFee;
    }
    
     function setBurnFeePercent(uint256 burnFee) external onlyOwner() {
        _burnFee = burnFee;
    }
    
    function setRecommendFeePercent(uint256 recommendFee) external onlyOwner() {
        _recommendFee = recommendFee;
    }
    
    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }


    function _getValues(uint256 tAmount) private view returns (
        uint256 rAmount, 
        uint256 rTransferAmount, 
        uint256 tTransferAmount, 
        uint256 rFee, 
        uint256 tFee, 
        uint256 rRecommend,
        uint256 tRecommend,
        uint256 rBurnFee,
        uint256 tBurnFee) {
            
        (tTransferAmount,tFee,tRecommend,tBurnFee) = _getTValues(tAmount);
        
        
        (rAmount,rTransferAmount,rFee,rRecommend,rBurnFee) = _getRValues(tAmount, tFee, tRecommend,tBurnFee, _getRate());
    
        return (rAmount, rTransferAmount, tTransferAmount,rFee, tFee, rRecommend, tRecommend,rBurnFee,tBurnFee);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256,uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tBurnFee = calculateBurnFee(tAmount);
        uint256 tRecommend = calculateRecommendFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tRecommend).sub(tBurnFee);
        return (tTransferAmount, tFee, tRecommend,tBurnFee);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tRecommend,uint256 tBurnFee, uint256 currentRate) private pure returns (
        uint256, uint256, uint256,uint256,uint256) {
            
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rBurnFee = tBurnFee.mul(currentRate);
        uint256 rRecommend = tRecommend.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rRecommend).sub(rBurnFee);
        return (rAmount, rTransferAmount, rFee,rRecommend,rBurnFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
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
    
    function _takeRecommend(uint256 tRecommend,uint256 rRecommend,address parent) private {

        _rOwned[parent] = _rOwned[parent].add(rRecommend);
        if(_isExcluded[parent])
            _tOwned[parent] = _tOwned[parent].add(tRecommend);
    }
    
    function _takeBurn(uint256 tBurnFee,uint256 rBurnFee) private {
       address _burnAddress = burnAddress;
        _rOwned[_burnAddress] = _rOwned[_burnAddress].add(rBurnFee);
        if(_isExcluded[_burnAddress])
            _tOwned[_burnAddress] = _tOwned[_burnAddress].add(tBurnFee);
    }
    
    
    function claimTokens() public onlyOwner {
        payable(_owner).transfer(address(this).balance);
    }
    
    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(
            10**2
        );
    }
    
    function calculateBurnFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_burnFee).div(
            10**2
        );
    }

    function calculateRecommendFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_recommendFee).div(
            10**2
        );
    }
    
    function removeAllFee() private {
        if(_taxFee == 0 && _recommendFee == 0 && _burnFee == 0) return;
        
        _previousTaxFee = _taxFee;
        _previousBurnFee = _burnFee;
        _previousRecommendFee = _recommendFee;
        
        _taxFee = 0;
        _recommendFee = 0;
        _burnFee = 0;
    }
    
    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _recommendFee = _previousRecommendFee;
        _burnFee = _previousBurnFee;
    }
    
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
            
        bool takeFee = true;
        
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to] ){
            takeFee = false;
        }
        
        _tokenTransfer(from,to,amount,takeFee);
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
    
    
    function _handleFee(address sender,uint tRecommend,uint rRecommend,uint tBurnFee,uint rBurnFee,uint tFee,uint rFee ) internal{
         if(tRecommend > 0){
            address parent = recommers[sender];
            if( parent == address(0)){
                _takeBurn(tRecommend,rRecommend);
                emit Transfer(sender, burnAddress, tRecommend);
            }else{
                 _takeRecommend(tRecommend,rRecommend,parent);
                emit Transfer(sender, parent, tRecommend);
            }
        }
        if(tBurnFee > 0){
            _takeBurn(tBurnFee,rBurnFee);
            emit Transfer(sender, burnAddress, tBurnFee);
        }
        
        if( rFee > 0 || tFee > 0){
            _reflectFee(rFee, tFee);
        }
    }
    
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (
            uint256 rAmount, 
            uint256 rTransferAmount, 
            uint256 tTransferAmount,
            uint256 rFee, 
            uint256 tFee, 
            uint256 rRecommend, 
            uint256 tRecommend,
            uint256 rBurnFee,
            uint256 tBurnFee) = _getValues(tAmount);
            
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount); 
        
        _handleFee(sender,tRecommend,rRecommend,tBurnFee,rBurnFee,tFee,rFee);
       
       
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (
            uint256 rAmount, 
            uint256 rTransferAmount, 
            uint256 tTransferAmount,
            uint256 rFee, 
            uint256 tFee, 
            uint256 rRecommend, 
            uint256 tRecommend,
            uint256 rBurnFee,
            uint256 tBurnFee) = _getValues(tAmount);
            
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        
        _handleFee(sender,tRecommend,rRecommend,tBurnFee,rBurnFee,tFee,rFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (
            uint256 rAmount, 
            uint256 rTransferAmount, 
            uint256 tTransferAmount,
            uint256 rFee, 
            uint256 tFee, 
            uint256 rRecommend, 
            uint256 tRecommend,
            uint256 rBurnFee,
            uint256 tBurnFee) = _getValues(tAmount);
            
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        
        _handleFee(sender,tRecommend,rRecommend,tBurnFee,rBurnFee,tFee,rFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (
            uint256 rAmount, 
            uint256 rTransferAmount, 
            uint256 tTransferAmount,
            uint256 rFee, 
            uint256 tFee, 
            uint256 rRecommend, 
            uint256 tRecommend,
            uint256 rBurnFee,
            uint256 tBurnFee) = _getValues(tAmount);
            
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        
        _handleFee(sender,tRecommend,rRecommend,tBurnFee,rBurnFee,tFee,rFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
   function _isContract(address a) internal view returns(bool){
        uint256 size;
        assembly {size := extcodesize(a)}
        return size > 0;
    }
}