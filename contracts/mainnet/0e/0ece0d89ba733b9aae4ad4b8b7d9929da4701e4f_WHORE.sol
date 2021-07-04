/**
 *Submitted for verification at Etherscan.io on 2021-07-03
*/

pragma solidity ^0.6.0;
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes memory) {
        this; 
        return msg.data;
    }
}
pragma solidity ^0.6.0;
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
pragma solidity ^0.6.0;
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
pragma solidity ^0.6.2;
library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
        return _functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }
    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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
pragma solidity ^0.6.0;
contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal {
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
pragma solidity ^0.6.2;
contract WHORE is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    mapping (address => uint256) private _cOwned;
    mapping (address => uint256) private _xOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _xTotal = 5 * 10**4 * 10**9;
    uint256 private _cTotal = (MAX - (MAX % _xTotal));
    uint256 private _xFeeTotal;
    string private _name = 'WHORE.FINANCE';
    string private _symbol = 'WHORE';
    uint8 private _decimals = 9;
    constructor () public {
        _cOwned[_msgSender()] = _cTotal;
        emit Transfer(address(0), _msgSender(), _xTotal);
    }
    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    function totalSupply() public view override returns (uint256) {
        return _xTotal;
    }
    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _xOwned[account];
        return tokenFromRefund(_cOwned[account]);
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
    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }
    function totalFees() public view returns (uint256) {
        return _xFeeTotal;
    }
    function refund(uint256 xAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 cAmount,,,,) = _getValues(xAmount);
        _cOwned[sender] = _cOwned[sender].sub(cAmount);
        _cTotal = _cTotal.sub(cAmount);
        _xFeeTotal = _xFeeTotal.add(xAmount);
    }
    function RefundFromToken(uint256 xAmount, bool deductTransferFee) public view returns(uint256) {
        require(xAmount <= _xTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 cAmount,,,,) = _getValues(xAmount);
            return cAmount;
        } else {
            (,uint256 cTransferAmount,,,) = _getValues(xAmount);
            return cTransferAmount;
        }
    }
    function tokenFromRefund(uint256 cAmount) public view returns(uint256) {
        require(cAmount <= _cTotal, "Amount must be less than total refunds");
        uint256 currentRate = _getRate();
        return cAmount.div(currentRate);
    }
    function excludeAccount(address account) external onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_cOwned[account] > 0) {
            _cOwned[account] = tokenFromRefund(_cOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }
    function includeAccount(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _xOwned[account] = 0;
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
    function _transferStandard(address sender, address recipient, uint256 xAmount) private {
        (uint256 cAmount, uint256 cTransferAmount, uint256 cFee, uint256 xTransferAmount, uint256 xFee) = _getValues(xAmount);
        _cOwned[sender] = _cOwned[sender].sub(cAmount);
        _cOwned[recipient] = _cOwned[recipient].add(cTransferAmount);
        _refundFee(cFee, xFee);
        emit Transfer(sender, recipient, xTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 xAmount) private {
        (uint256 cAmount, uint256 cTransferAmount, uint256 cFee, uint256 xTransferAmount, uint256 xFee) = _getValues(xAmount);
        _cOwned[sender] = _cOwned[sender].sub(cAmount);
        _xOwned[recipient] = _xOwned[recipient].add(xTransferAmount);
        _cOwned[recipient] = _cOwned[recipient].add(cTransferAmount);
        _refundFee(cFee, xFee);
        emit Transfer(sender, recipient, xTransferAmount);
    }
    function _transferFromExcluded(address sender, address recipient, uint256 xAmount) private {
        (uint256 cAmount, uint256 cTransferAmount, uint256 cFee, uint256 xTransferAmount, uint256 xFee) = _getValues(xAmount);
        _xOwned[sender] = _xOwned[sender].sub(xAmount);
        _cOwned[sender] = _cOwned[sender].sub(cAmount);
        _cOwned[recipient] = _cOwned[recipient].add(cTransferAmount);
        _refundFee(cFee, xFee);
        emit Transfer(sender, recipient, xTransferAmount);
    }
    function _transferBothExcluded(address sender, address recipient, uint256 xAmount) private {
        (uint256 cAmount, uint256 cTransferAmount, uint256 cFee, uint256 xTransferAmount, uint256 xFee) = _getValues(xAmount);
        _xOwned[sender] = _xOwned[sender].sub(xAmount);
        _cOwned[sender] = _cOwned[sender].sub(cAmount);
        _xOwned[recipient] = _xOwned[recipient].add(xTransferAmount);
        _cOwned[recipient] = _cOwned[recipient].add(cTransferAmount);
        _refundFee(cFee, xFee);
        emit Transfer(sender, recipient, xTransferAmount);
    }
    function _refundFee(uint256 cFee, uint256 xFee) private {
        _cTotal = _cTotal.sub(cFee);
        _xFeeTotal = _xFeeTotal.add(xFee);
    }
    function _getValues(uint256 xAmount) private view returns (uint256, uint256, uint256, uint256, uint256) {
        (uint256 xTransferAmount, uint256 xFee) = _getXValues(xAmount);
        uint256 currentRate = _getRate();
        (uint256 cAmount, uint256 cTransferAmount, uint256 cFee) = _getCValues(xAmount, xFee, currentRate);
        return (cAmount, cTransferAmount, cFee, xTransferAmount, xFee);
    }
    function _getXValues(uint256 xAmount) private pure returns (uint256, uint256) {
        uint256 xFee = xAmount.mul(50).div(100);
        uint256 xTransferAmount = xAmount.sub(xFee);
        return (xTransferAmount, xFee);
    }
    function _getCValues(uint256 xAmount, uint256 xFee, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 cAmount = xAmount.mul(currentRate);
        uint256 cFee = xFee.mul(currentRate);
        uint256 cTransferAmount = cAmount.sub(cFee);
        return (cAmount, cTransferAmount, cFee);
    }
    function _getRate() private view returns(uint256) {
        (uint256 cSupply, uint256 xSupply) = _getCurrentSupply();
        return cSupply.div(xSupply);
    }
    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 cSupply = _cTotal;
        uint256 xSupply = _xTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_cOwned[_excluded[i]] > cSupply || _xOwned[_excluded[i]] > xSupply) return (_cTotal, _xTotal);
            cSupply = cSupply.sub(_cOwned[_excluded[i]]);
            xSupply = xSupply.sub(_xOwned[_excluded[i]]);
        }
        if (cSupply < _cTotal.div(_xTotal)) return (_cTotal, _xTotal);
        return (cSupply, xSupply);
    }
}