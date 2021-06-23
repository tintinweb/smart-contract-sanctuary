/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

pragma solidity ^0.6.12;

 

// $$\      $$\ $$$$$$\  $$$$$$\  $$\   $$\ $$\   $$\  $$$$$$\  
// $$$\    $$$ |\_$$  _|$$  __$$\ $$ |  $$ |$$ | $$  |$$  __$$\ 
// $$$$\  $$$$ |  $$ |  $$ /  \__|$$ |  $$ |$$ |$$  / $$ /  $$ |
// $$\$$\$$ $$ |  $$ |  \$$$$$$\  $$$$$$$$ |$$$$$  /  $$$$$$$$ |
// $$ \$$$  $$ |  $$ |   \____$$\ $$  __$$ |$$  $$<   $$  __$$ |
// $$ |\$  /$$ |  $$ |  $$\   $$ |$$ |  $$ |$$ |\$$\  $$ |  $$ |
// $$ | \_/ $$ |$$$$$$\ \$$$$$$  |$$ |  $$ |$$ | \$$\ $$ |  $$ |
// \__|     \__|\______| \______/ \__|  \__|\__|  \__|\__|  \__|

// MishkaToken.com ($MISHKA): The Inu Killer
// $MISHKA is a deflationary defi meme token that donates teddy bears to children.
// For every transaction, 2.5% goes to holders,  0.1% goes to our teddy bear charity wallet, and 0.4% goes to our marketing wallet.
// https://mishkatoken.com
// https://t.me/mishkatoken
// Let's Feed This Bear

// SPDX-License-Identifier: Unlicensed


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

contract Mishka is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    address private constant _cBoost = 0xa9C099D50915B44e083BCd4bc6e3E8492A0B5784; // Charity Wallet
    address private constant _mBoost = 0x5985627292600A91321Cee8E0B204333764C94A2; // Marketing Wallet
    mapping(address => bool) private bots;
    mapping (address => bool) private _isExcludedFromRewards;
    address[] private _excludedFromRewards;
    mapping (address => bool) private _isExcludedFromFees;
    address[] private _excludedFromFees;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 100000000000 * 10**6;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 private _tCharityBoostTotal;
    uint256 private _tMarketingBoostTotal;
    string private _name = 'MishTEST3';
    string private _symbol = 'MISHTEST3';
    uint8 private _decimals = 9;
    bool private tradingOpen = false;
    uint256 private _maxTxBasis = 300;
    uint256 private _maxTxAmount = _tTotal.mul(_maxTxBasis).div(10**4);
    mapping(address => uint256) private buycooldown;
    uint256 private _coolDownSeconds = 30;

    constructor () public {
        _rOwned[_msgSender()] = _rTotal;
        
        // Bot Blacklist
        bots[address(0x6299135C830B916a6B46834C3662953566935708)] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
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
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcludedFromRewards[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }
    
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        if (_isExcludedFromFees[recipient]) {
            _transfer(_msgSender(), recipient, amount);
        } else {
            (uint256 _amount, uint256 _charityBoost, uint256 _marketingBoost) = _getUValues(amount);
            _transfer(_msgSender(), recipient, _amount);
            _transfer(_msgSender(), _cBoost, _charityBoost);
            _transfer(_msgSender(), _mBoost, _marketingBoost);
        }
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

    function isExcludedFromRewards(address account) public view returns (bool) {
        return _isExcludedFromRewards[account];
    }
    
    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }
    
    function openTrading() public onlyOwner {
        tradingOpen = true;
    }

    function setMaxTxBasis(uint256 maxTxBasis) external onlyOwner() {
        _maxTxAmount = _tTotal.mul(maxTxBasis).div(10**4);
        _maxTxBasis = maxTxBasis;
    }
    
    function setCoolDownSeconds(uint256 coolDownSeconds) external onlyOwner() {
        _coolDownSeconds = coolDownSeconds;
    }
    
    function getCoolDownSeconds() public view returns (uint256) {
        return _coolDownSeconds;
    }
    
    function totalCharityBoost() public view returns (uint256) {
        return _tCharityBoostTotal;
    }
    
    function totalMarketingBoost() public view returns (uint256) {
        return _tMarketingBoostTotal;
    }

    function reflect(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcludedFromRewards[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }
    
    function isBlackList(address account) public view onlyOwner() returns (bool) {
        return bots[account];
    }
    
    function setBotAddress(address account) external onlyOwner() {
        require(!bots[account], "Account is already identified as a bot");
        bots[account] = true;
    }
    function revertSetBotAddress(address account) external onlyOwner() {
        require(bots[account], "Account is not identified as a bot");
        bots[account] = false;
    }

    function excludeAccountFromRewards(address account) external onlyOwner() {
        require(!_isExcludedFromRewards[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcludedFromRewards[account] = true;
        _excludedFromRewards.push(account);
    }

    function includeAccountFromRewards(address account) external onlyOwner() {
        require(_isExcludedFromRewards[account], "Account is already excluded");
        for (uint256 i = 0; i < _excludedFromRewards.length; i++) {
            if (_excludedFromRewards[i] == account) {
                _excludedFromRewards[i] = _excludedFromRewards[_excludedFromRewards.length - 1];
                _tOwned[account] = 0;
                _isExcludedFromRewards[account] = false;
                _excludedFromRewards.pop();
                break;
            }
        }
    }
    
    function excludeAccountFromFees(address account) external onlyOwner() {
        require(!_isExcludedFromFees[account], "Account is already excluded");
        _isExcludedFromFees[account] = true;
        _excludedFromFees.push(account);
    }

    function includeAccountFromFees(address account) external onlyOwner() {
        require(_isExcludedFromFees[account], "Account is already excluded");
        for (uint256 i = 0; i < _excludedFromFees.length; i++) {
            if (_excludedFromFees[i] == account) {
                _excludedFromFees[i] = _excludedFromFees[_excludedFromFees.length - 1];
                _isExcludedFromFees[account] = false;
                _excludedFromFees.pop();
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
    
     function _getUValues(uint256 amount) private pure returns (uint256, uint256, uint256) {
        uint256 _charityBoost = amount.div(1000);
        uint256 _marketingBoost = amount.div(1000).mul(4);
        uint256 _amount = amount.sub(_charityBoost);
        _amount = amount.sub(_marketingBoost);
        return (_amount, _charityBoost, _marketingBoost);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if(sender != owner() && recipient != owner()) {
            require(tradingOpen);
            require(!bots[sender] && !bots[recipient]);
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            require(buycooldown[recipient] < block.timestamp);
            buycooldown[recipient] = block.timestamp + ( _coolDownSeconds * (1 seconds));
        }
        if (_isExcludedFromRewards[sender] && !_isExcludedFromRewards[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcludedFromRewards[sender] && _isExcludedFromRewards[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcludedFromRewards[sender] && !_isExcludedFromRewards[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcludedFromRewards[sender] && _isExcludedFromRewards[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);      
        _reflectFee(rFee, tFee);
        if (recipient == _cBoost) _reflectCharityBoost(tTransferAmount);
        if (recipient == _mBoost) _reflectMarketingBoost(tTransferAmount);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _reflectFee(rFee, tFee);
        if (recipient == _cBoost) _reflectCharityBoost(tTransferAmount);
        if (recipient == _mBoost) _reflectMarketingBoost(tTransferAmount);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);  
        _reflectFee(rFee, tFee);
        if (recipient == _cBoost) _reflectCharityBoost(tTransferAmount);
        if (recipient == _mBoost) _reflectMarketingBoost(tTransferAmount);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);       
        _reflectFee(rFee, tFee);
        if (recipient == _cBoost) _reflectCharityBoost(tTransferAmount);
        if (recipient == _mBoost) _reflectMarketingBoost(tTransferAmount);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }
    
    function _reflectCharityBoost(uint256 tTransferAmount) private {
        _tCharityBoostTotal = _tCharityBoostTotal.add(tTransferAmount);
    }
    
    function _reflectMarketingBoost(uint256 tTransferAmount) private {
        _tMarketingBoostTotal = _tMarketingBoostTotal.add(tTransferAmount);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee) = _getTValues(tAmount);
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee);
    }

    function _getTValues(uint256 tAmount) private pure returns (uint256, uint256) {
        uint256 tFee = tAmount.mul(25).div(1000);
        uint256 tTransferAmount = tAmount.sub(tFee);
        return (tTransferAmount, tFee);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;     
        for (uint256 i = 0; i < _excludedFromRewards.length; i++) {
            if (_rOwned[_excludedFromRewards[i]] > rSupply || _tOwned[_excludedFromRewards[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excludedFromRewards[i]]);
            tSupply = tSupply.sub(_tOwned[_excludedFromRewards[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
}