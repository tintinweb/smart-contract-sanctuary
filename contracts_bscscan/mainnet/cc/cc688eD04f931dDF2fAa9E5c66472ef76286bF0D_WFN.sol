/**
 *Submitted for verification at BscScan.com on 2021-11-26
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);
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
        require(c / a == b, "Multiplication overflow");

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
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

library Address {

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        // solhint-disable-next-line
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "recipient may have reverted");
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
        require(address(this).balance >= value, "Insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");
        // solhint-disable-next-line
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                // solhint-disable-next-line
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

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function owner() public view returns (address) {
        return _owner;
    }

}

contract WFN is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rBalances;
    mapping (address => uint256) private _tBalances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;

    string private _name = "WineFinance";
    string private _symbol = "WFN";
    uint8 private _decimals = 5;

    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _TTOTALSUPPLY = 500000000 * (10**5);
    
    uint256 private _rTotalSupply = (MAX - (MAX % _TTOTALSUPPLY));
    uint256 private _tFeeTotal;

    uint256 private _donationFee = 2;
    address private _donationAddress = 0x923E3EeBf32d136ac7AAFd722dCe5f57C74C291e;

    uint256 private _networkFee = 2;
    
    constructor () {
        _rBalances[_msgSender()] = _rTotalSupply;
        
        address supplyAddress = _msgSender();
        _excludeAccount(supplyAddress);
        _excludeAccount(_donationAddress);
        address airDropAddress = 0x2c0E0856B699B9A435b9A3d9B2720b9F9B5486EE;
        _excludeAccount(airDropAddress);
        address teamLockedAddress = 0xc65dc738DdAA7d2Ee43E8653e94C713BeDCC8A0c;
        _excludeAccount(teamLockedAddress);
        emit Transfer(address(0), _msgSender(), _TTOTALSUPPLY);
    }

    receive() external payable {
        require(false, "Do not send token");
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function balanceOf(address account) external view override returns (uint256) {
        if (_isExcluded[account]) return _tBalances[account];
        return tokenFromReflection(_rBalances[account]);
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) external view returns(uint256) {
        require(tAmount <= _TTOTALSUPPLY, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,,) = _getValues(tAmount, false);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,,) = _getValues(tAmount, false);
            return rTransferAmount;
        }
    }

    function totalSupply() external pure override returns (uint256) {
        return _TTOTALSUPPLY;
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotalSupply, "Amount must be < total reflection");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotalSupply = _rTotalSupply.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _excludeAccount(address account) private {
        if(_rBalances[account] > 0) {
            _tBalances[account] = tokenFromReflection(_rBalances[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _processDonations(address sender, uint256 rDonation, uint256 tDonation) private {
        if(rDonation > 0){
            _tBalances[_donationAddress] = _tBalances[_donationAddress].add(tDonation);
            _rBalances[_donationAddress] = _rBalances[_donationAddress].add(rDonation);  
            emit Transfer(sender, _donationAddress, tDonation);
        }
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");
        require(amount > 0, "Transfer amount must be > than 0");
        
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

    function _transferStandard(address sender, address recipient, uint256 transferAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tDonation, uint256 rDonation) = _getValues(transferAmount, false);
        _rBalances[sender] = _rBalances[sender].sub(rAmount);
        _rBalances[recipient] = _rBalances[recipient].add(rTransferAmount); 
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
        _processDonations(sender, rDonation, tDonation);
    }

    function _transferToExcluded(address sender, address recipient, uint256 transferAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tDonation, uint256 rDonation) = _getValues(transferAmount, false);
        _rBalances[sender] = _rBalances[sender].sub(rAmount);
        _tBalances[recipient] = _tBalances[recipient].add(tTransferAmount);
        _rBalances[recipient] = _rBalances[recipient].add(rTransferAmount);           
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
        _processDonations(sender, rDonation, tDonation);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 transferAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tDonation, uint256 rDonation) = _getValues(transferAmount, false);
        _tBalances[sender] = _tBalances[sender].sub(transferAmount);
        _rBalances[sender] = _rBalances[sender].sub(rAmount);
        _rBalances[recipient] = _rBalances[recipient].add(rTransferAmount);   
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
        _processDonations(sender, rDonation, tDonation);
    }
    
    function _transferBothExcluded(address sender, address recipient, uint256 transferAmount) private {
        bool bothExcluded = true;
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee,,) = _getValues(transferAmount, bothExcluded);
        _tBalances[sender] = _tBalances[sender].sub(transferAmount);
        _rBalances[sender] = _rBalances[sender].sub(rAmount);
        _tBalances[recipient] = _tBalances[recipient].add(tTransferAmount);
        _rBalances[recipient] = _rBalances[recipient].add(rTransferAmount);        
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _getTFeeAmounts(uint256 transferAmount, bool bothExcluded) private view returns (uint256, uint256){
        uint256 networkFee = _networkFee;
        uint256 donationFee = _donationFee;

        if(bothExcluded) {
            networkFee = 0;
            donationFee = 0;
        }
        
        uint256 tFee = transferAmount.div(100).mul(networkFee);
        uint256 tDonation = transferAmount.div(100).mul(donationFee);
        
        return (tFee, tDonation);
    }

    function _getValues(uint256 transferAmount, bool bothExcluded) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tFee, uint256 tDonation) = _getTFeeAmounts(transferAmount, bothExcluded);
        
        uint256 tTransferAmount = transferAmount.sub(tFee).sub(tDonation);

        uint256 currentRate =  _getRate();
        uint256 rAmount = transferAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rDonation = tDonation.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rDonation);
        
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tDonation, rDonation);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotalSupply;
        uint256 tSupply = _TTOTALSUPPLY;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rBalances[_excluded[i]] > rSupply || _tBalances[_excluded[i]] > tSupply) return (_rTotalSupply, _TTOTALSUPPLY);
            rSupply = rSupply.sub(_rBalances[_excluded[i]]);
            tSupply = tSupply.sub(_tBalances[_excluded[i]]);
        }
        if (rSupply < _rTotalSupply.div(_TTOTALSUPPLY)) return (_rTotalSupply, _TTOTALSUPPLY);
        return (rSupply, tSupply);
    }
}