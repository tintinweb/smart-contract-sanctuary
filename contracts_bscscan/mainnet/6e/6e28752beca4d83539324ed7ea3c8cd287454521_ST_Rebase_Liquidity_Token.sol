/**
 *Submitted for verification at BscScan.com on 2021-12-26
*/

// SPDX-License-Identifier: MIT
 
pragma solidity ^0.8.4;

interface IST20 {
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
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
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

abstract contract Ownable is Context {
    address private _owner;
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
}

interface STPayable {
    function pay(string memory serviceName) external payable;
}

abstract contract TokenGenerator {
    constructor (address payable receiver, string memory serviceName) payable {
        STPayable(receiver).pay{value: msg.value}(serviceName);
    }
}

contract ST_Rebase_Liquidity_Token is Context, IST20, Ownable, TokenGenerator {
    using SafeMath for uint256;
    using Address for address;
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
    address public mktAddress;
    address public burnAddress;
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal;
    uint256 private _rTotal;
    uint256 private _tFeeTotal;
    string private _name;
    string private _symbol;
    uint256 private _decimals;
    uint256 public taxFee;
    uint256 private _previousTaxFee;
    uint256 public mktFee;
    uint256 private _previousMktFee;
    uint256 public burnFee;
    uint256 private _previousBurnFee;
    uint256 public maxTxAmount;
 
    constructor (string memory name, string memory symbol, uint256 decimals, uint256 totalSupply, uint256 _taxFee, uint256 _mktFee, uint256 _burnFee, address _mktAddress, address _burnAddress, address payable feeReceiver) 
    TokenGenerator (feeReceiver, "ST_Rebase_Liquidity_Token") payable {
        
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        _tTotal = totalSupply;
        _rTotal = MAX - (MAX % _tTotal);
        _rOwned[owner()] = _rTotal;
        taxFee = _taxFee;
        _previousTaxFee = _taxFee;
        mktFee = _mktFee;
        _previousMktFee = _mktFee;
        burnFee = _burnFee;
        _previousBurnFee = _burnFee;
        maxTxAmount = _tTotal/100;
        mktAddress = _mktAddress;
        burnAddress = _burnAddress;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        emit Transfer(address(0), owner(), _tTotal);
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "IST20: transfer amount exceeds allowance."));
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "IST20: decreased allowance below zero."));
        return true;
    }
    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }
    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }
    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(taxFee).div(10**2);
    }
    function calculateMktFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(mktFee).div(10**2);
    }
    function calculateBurnFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(burnFee).div(10**2);
    }
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "IST20: Amount must be less than supply.");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }
    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "IST20: Amount must be less than total reflections.");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    // ------------------------------------------------------------------------
    // Function to exclude addresses from receiving the reflection rewards.
    // This function can be used to exclude hacker addresses, centralized exchange addresses, or other addresses from receiving the reflection rewards.
    // Only the Contract owner can exclude the addresses.
    // ------------------------------------------------------------------------
    function excludeFromReward(address account) public onlyOwner() {
        require(!_isExcluded[account], "IST20: Account is already excluded.");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    // ------------------------------------------------------------------------
    // Function to include addresses for receiving the reflection rewards.
    // This function can be used to include, already excluded addresses for receiving the reflection rewards.
    // Only the Contract owner can include the addresses.
    // ------------------------------------------------------------------------
    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "IST20: Account is already included.");
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

    // ------------------------------------------------------------------------
    // Function to exclude addresses from paying the transfer/ transaction fees.
    // This function can be used to project addresses, centralized exchange addresses, or other addresses from paying the transfer/ transaction fees.
    // Only the Contract owner can exclude the addresses.
    // ------------------------------------------------------------------------
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    // ------------------------------------------------------------------------
    // Function to include addresses for paying the transfer/ transaction fees.
    // This function can be used to include, already excluded addresses for paying the transfer/ transaction fees.
    // Only the Contract owner can include the addresses.
    // ------------------------------------------------------------------------
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    // ------------------------------------------------------------------------
    // Function to change reflection reward to holders fees in %.
    // The fees can not be higher than 30%, to protect the interest of token holders.
    // Enter only numbers and not the % sign.
    // Only the Contract owner can change the fees.
    // ------------------------------------------------------------------------
    function setTaxFee(uint256 _taxFee) external onlyOwner() {
        require(_taxFee <= 30, "IST20: Tax fees can not be higher than 30%.");
        taxFee = _taxFee;
    }

    // ------------------------------------------------------------------------
    // Function to change mkt fees in %.
    // The fees can not be higher than 30%, to protect the interest of token holders.
    // Enter only numbers and not the % sign.
    // Only the Contract owner can change the fees.
    // ------------------------------------------------------------------------
    function setMktFee(uint256 _mktFee) external onlyOwner() {
        require(_mktFee <= 30, "IST20: Mkt fees can not be higher than 30%.");
        mktFee = _mktFee;
    }

    // ------------------------------------------------------------------------
    // Function to change burn fees in %.
    // The fees can not be higher than 30%, to protect the interest of token holders.
    // Enter only numbers and not the % sign.
    // Only the Contract owner can change the fees.
    // ------------------------------------------------------------------------
    function setBurnFee(uint256 _burnFee) external onlyOwner() {
        require(_burnFee <= 30, "IST20: Mkt fees can not be higher than 30%.");
        burnFee = _burnFee;
    }

    // ------------------------------------------------------------------------
    // Function to change mkt address.
    // Only the Contract owner can change the address.
    // ------------------------------------------------------------------------
    function setMktAddress(address _mktAddress) external onlyOwner() {
        mktAddress = _mktAddress;
    }

    // ------------------------------------------------------------------------
    // Function to change burn address.
    // Only the Contract owner can change the address.
    // ------------------------------------------------------------------------
    function setBurnAddress(address _burnAddress) external onlyOwner() {
        burnAddress = _burnAddress;
    }

    // ------------------------------------------------------------------------
    // Function to change maximum transfer/ transaction amount (in tokens).
    // The amount can not be less than 1 (one) token, to protect the interest of token holders.
    // Enter the amount followed by the token decimals.
    // Only the Contract owner can change the amount.
    // ------------------------------------------------------------------------
    function setMaxTxAmount(uint256 _maxTxAmount) public onlyOwner {
        require(_maxTxAmount >= 1, "IST20: Maximum transaction amount should be higher than 1.");
        maxTxAmount = _maxTxAmount;
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }
    struct TData {
        uint256 tAmount;
        uint256 tFee;
        uint256 tMkt;
        uint256 tBurn;
        uint256 currentRate;
    }
    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, TData memory data) = _getTValues(tAmount);
        data.tAmount = tAmount;
        data.currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(data);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, data.tFee, data.tMkt, data.tBurn);
    }
    function _getTValues(uint256 tAmount) private view returns (uint256, TData memory) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tMkt = calculateMktFee(tAmount);
        uint256 tBurn = calculateBurnFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tMkt).sub(tBurn);
        return (tTransferAmount, TData(0, tFee, tMkt, tBurn, 0));
    }
    function _getRValues(TData memory _data) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = _data.tAmount.mul(_data.currentRate);
        uint256 rFee = _data.tFee.mul(_data.currentRate);
        uint256 rMkt = _data.tMkt.mul(_data.currentRate);
        uint256 rBurn = _data.tBurn.mul(_data.currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rMkt).sub(rBurn);
        return (rAmount, rTransferAmount, rFee);
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
    function _takeMkt(uint256 tMkt, address sender) private {
        uint256 currentRate =  _getRate();
        uint256 rMkt = tMkt.mul(currentRate);
        _rOwned[mktAddress] = _rOwned[mktAddress].add(rMkt);
        if(_isExcluded[mktAddress])
            _tOwned[mktAddress] = _tOwned[mktAddress].add(tMkt);
        emit Transfer(sender, mktAddress, tMkt);
    }
    function _takeBurn(uint256 tBurn, address sender) private {
        uint256 currentRate =  _getRate();
        uint256 rBurn = tBurn.mul(currentRate);
        _rOwned[burnAddress] = _rOwned[burnAddress].add(rBurn);
        if(_isExcluded[burnAddress])
            _tOwned[burnAddress] = _tOwned[burnAddress].add(tBurn);
        emit Transfer(sender, burnAddress, tBurn);
    }
    function removeAllFee() private {
        if(taxFee == 0 && mktFee == 0 && burnFee == 0) return;
        _previousTaxFee = taxFee;
        _previousMktFee = mktFee;
        _previousBurnFee = burnFee;
        taxFee = 0;
        mktFee = 0;
        burnFee = 0;
    }
    function restoreAllFee() private {
        taxFee = _previousTaxFee;
        mktFee = _previousMktFee;
        burnFee = _previousBurnFee;
    }
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "IST20: approve from the zero address.");
        require(spender != address(0), "IST20: approve to the zero address.");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "IST20: transfer from the zero address.");
        require(to != address(0), "IST20: transfer to the zero address.");
        require(amount > 0, "IST20: Transfer amount must be greater than zero.");
        if(from != owner() && to != owner())
            require(amount <= maxTxAmount, "IST20: Transfer amount exceeds the Max transaction amount.");
        uint256 contractTokenBalance = balanceOf(address(this));
        if(contractTokenBalance >= maxTxAmount) {
            contractTokenBalance = maxTxAmount;
        }
        bool takeFee = true;
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
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
    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tMkt, uint256 tBurn) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeMkt(tMkt, sender);
        _takeBurn(tBurn, sender);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
    (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tMkt, uint256 tBurn) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _takeMkt(tMkt, sender);
        _takeBurn(tBurn, sender);
        _reflectFee(rFee, tFee);
    emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tMkt, uint256 tBurn) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _takeMkt(tMkt, sender);
        _takeBurn(tBurn, sender);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tMkt, uint256 tBurn) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _takeMkt(tMkt, sender);
        _takeBurn(tBurn, sender);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    // ------------------------------------------------------------------------
    // Function to Withdraw Tokens sent by mistake to the Token Contract Address.
    // Only the Contract owner can withdraw the Tokens.
    // ------------------------------------------------------------------------
    function WithdrawTokens(address tokenAddress, uint256 tokenAmount) public virtual onlyOwner {
        IST20(tokenAddress).transfer(owner(), tokenAmount);
    }
}