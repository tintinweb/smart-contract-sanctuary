/**
 *Submitted for verification at BscScan.com on 2021-07-16
*/

// SPDX-License-Identifier: MTI
	//Walter Smart Contract
	
	pragma solidity 0.8.6;
	
	
	abstract contract Context {
        function _msgSender() internal view virtual returns (address) {
            return msg.sender;
        }
    
        function _msgData() internal view virtual returns (bytes calldata) {
            return msg.data;
        }
    }
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
library Address {
	    function isContract(address account) internal view returns (bool) {
            uint256 size;
            assembly {
                size := extcodesize(account)
            }
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
            (bool success, bytes memory returndata) = target.call{value: value}(data);
            return _verifyCallResult(success, returndata, errorMessage);
        }
function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns (bytes memory) {
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
	
	contract Ownable is Context {
	    address private _owner;
	    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
        constructor() {
                _setOwner(_msgSender());
}
	    function owner() public view returns (address) {
	        return _owner;
	    }
	    modifier onlyOwner() {
            require(owner() == _msgSender(), "Ownable: caller is not the owner");
            _;
        }
	    function renounceOwnership() public virtual onlyOwner {
            _setOwner(address(0));
        }
	    function transferOwnership(address newOwner) public virtual onlyOwner {
            require(newOwner != address(0), "Ownable: new owner is the zero address");
            _setOwner(newOwner);
        }
        function _setOwner(address newOwner) private {
            address oldOwner = _owner;
            _owner = newOwner;
            emit OwnershipTransferred(oldOwner, newOwner);
        }
	}
contract Walter is Context, IERC20, Ownable {
	    using Address for address;
	    mapping (address => uint256) private _rOwned;
	    mapping (address => uint256) private _tOwned;
	    mapping (address => mapping (address => uint256)) private _allowances;
	    mapping (address => bool) private _isExcluded;
	    address[] private _excluded;
	    uint8 private constant _decimals = 8;
	    uint256 private constant MAX = ~uint256(0);
	    uint256 private _tTotal = 1000000000000000 * 10 ** uint256(_decimals);
        uint256 private _rTotal = (MAX - (MAX % _tTotal));
	    uint256 private _tFeeTotal;
	    uint256 private _tBurnTotal;
	    string private constant _name = 'SaveWalterWhite';
	    string private constant _symbol = 'SVWW';
	    uint256 private _taxFee = 300;
	    uint256 private _burnFee = 300;
	    uint private _max_tx_size = 10000000000000 * 10 ** uint256(_decimals);
	    bool private _hasMax = true;
	    constructor ()
{
	        _rOwned[_msgSender()] = _rTotal;
	        emit Transfer(address(0), _msgSender(), _tTotal);
	    }
	    function name() public pure returns (string memory) {
	        return _name;
	    }
	    function symbol() public pure returns (string memory) {
	        return _symbol;
	    }
	    function decimals() public pure returns (uint8) {
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
	         require(amount <= _allowances[sender][_msgSender()], "ERC20: transfer amount exceeds allowance");
	        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
	        return true;
	    }
	    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
	        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
	        return true;
	    }
	    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
	        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
	        return true;
	    }
	    function isExcluded(address account) public view returns (bool) {
	        return _isExcluded[account];
	    }
	    function totalFees() public view returns (uint256) {
	        return _tFeeTotal;
	    }
	    function totalBurn() public view returns (uint256) {
	        return _tBurnTotal;
	    }
	    function deliver(uint256 tAmount) public {
	        address sender = _msgSender();
	        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
	        (uint256 rAmount,,,,,) = _getValues(tAmount);
	        _rOwned[sender] = _rOwned[sender] - rAmount;
	        _rTotal = _rTotal - rAmount;
	        _tFeeTotal = _tFeeTotal + tAmount;
	    }
function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
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
	        return rAmount / currentRate;
	    }
	    function excludeAccount(address account) external onlyOwner() {
	        require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Uniswap router.');
	        require(!_isExcluded[account], "Account is already excluded");
	        if(_rOwned[account] > 0) {
	            _tOwned[account] = tokenFromReflection(_rOwned[account]);
	        }
	        _isExcluded[account] = true;
	        _excluded.push(account);
	    }
	    function includeAccount(address account) external onlyOwner() {
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
function _approve(address owner, address spender, uint256 amount) private {
	        require(owner != address(0), "ERC20: approve from the zero address");
	        require(spender != address(0), "ERC20: approve to the zero address");
	        _allowances[owner][spender] = amount;
	        emit Approval(owner, spender, amount);
	    }
	    function _transfer(address sender, address recipient, uint256 amount) private {
	        require(sender != address(0), "ERC20: transfer from the zero address");
	        require(recipient != address(0), "ERC20: transfer to the zero address");
	        require(amount > 0, "Transfer amount must be greater than zero");
	        if(sender != owner() && recipient != owner() && _hasMax)
	            require(amount <= _max_tx_size, "Transfer amount exceeds 1% of Total Supply.");
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
	    }
	    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
	        uint256 currentRate =  _getRate();
	        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn) = _getValues(tAmount);
	        uint256 rBurn =  tBurn * currentRate;
	        _rOwned[sender] = _rOwned[sender] - rAmount;
	        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;       
	        _reflectFee(rFee, rBurn, tFee, tBurn);
	        emit Transfer(sender, recipient, tTransferAmount);
	    }
	    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
	        uint256 currentRate =  _getRate();
	        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn) = _getValues(tAmount);
	        uint256 rBurn =  tBurn * currentRate;
	        _rOwned[sender] = _rOwned[sender] - rAmount;
	        _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
	        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;           
	        _reflectFee(rFee, rBurn, tFee, tBurn);
	        emit Transfer(sender, recipient, tTransferAmount);
	    }
function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
	        uint256 currentRate =  _getRate();
	        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn) = _getValues(tAmount);
	        uint256 rBurn =  tBurn * currentRate;
	        _tOwned[sender] = _tOwned[sender] - tAmount;
	        _rOwned[sender] = _rOwned[sender] - rAmount;
	        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;   
            _reflectFee(rFee, rBurn, tFee, tBurn);
	        emit Transfer(sender, recipient, tTransferAmount);
	    }
	    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
	        uint256 currentRate =  _getRate();
	        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn) = _getValues(tAmount);
	        uint256 rBurn =  tBurn * currentRate;
	        _tOwned[sender] = _tOwned[sender] - tAmount;
	        _rOwned[sender] = _rOwned[sender] - rAmount;
	        _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
	        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;        
	        _reflectFee(rFee, rBurn, tFee, tBurn);
	        emit Transfer(sender, recipient, tTransferAmount);
	    }
	    function _reflectFee(uint256 rFee, uint256 rBurn, uint256 tFee, uint256 tBurn) private {
	        _rTotal = (_rTotal - rFee) - rBurn;
	        _tFeeTotal = _tFeeTotal + tFee;
	        _tBurnTotal = _tBurnTotal + tBurn;
	        _tTotal = _tTotal - tBurn;
	    }
	    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
	        (uint256 tTransferAmount, uint256 tFee, uint256 tBurn) = _getTValues(tAmount, _taxFee, _burnFee);
	        uint256 currentRate =  _getRate();
	        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tBurn, currentRate);
	        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tBurn);
	    }
function _getTValues(uint256 tAmount, uint256 taxFee, uint256 burnFee) private pure returns (uint256, uint256, uint256) {
	        uint256 tFee = ((tAmount * taxFee) / 100) / 100;
	        uint256 tBurn = ((tAmount * burnFee) / 100) / 100;
	        uint256 tTransferAmount = (tAmount - tFee) - tBurn;
	        return (tTransferAmount, tFee, tBurn);
	    }
function _getRValues(uint256 tAmount, uint256 tFee, uint256 tBurn, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
	        uint256 rAmount = tAmount * currentRate;
	        uint256 rFee = tFee * currentRate;
	        uint256 rBurn = tBurn * currentRate;
	        uint256 rTransferAmount = (rAmount - rFee) - rBurn;
	        return (rAmount, rTransferAmount, rFee);
	    }
	    function _getRate() private view returns(uint256) {
	        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
	        return rSupply / tSupply;
	    }
function _getCurrentSupply() private view returns(uint256, uint256) {
	        uint256 rSupply = _rTotal;
	        uint256 tSupply = _tTotal;      
	        for (uint256 i = 0; i < _excluded.length; i++) {
	            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
	            rSupply = rSupply - (_rOwned[_excluded[i]]);
	            tSupply = tSupply - (_tOwned[_excluded[i]]);
	        }
	        if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);
	        return (rSupply, tSupply);
	    }
	    function _getTaxFee() public view returns(uint256) {
	        return _taxFee;
	    }
	    function _getBurnFee() public view returns(uint256) {
	        return _burnFee;
	    }
	    function _setTaxFee(uint256 taxFee) external onlyOwner() {
	        _taxFee = taxFee;
	    }
	    function _setBurnFee(uint256 burnFee) external onlyOwner() {
	        _burnFee = burnFee;
	    }
function _getMaxTxAmount() public view returns(uint256){
	        return _max_tx_size;
	    }
	    function _setMaxTxAmount(uint256 maxTxAmount) external onlyOwner() {
	        require(maxTxAmount >= 10**9 , 'maxTxAmount should be greater than total 1e9');
	        _max_tx_size = maxTxAmount * 10 ** uint256(_decimals);
	    }
	    function _setMaxTx(bool activate) external onlyOwner() {
	        _hasMax = activate;
	    }
	}