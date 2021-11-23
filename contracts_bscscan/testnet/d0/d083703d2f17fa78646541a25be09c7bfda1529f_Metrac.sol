/**
 *Submitted for verification at BscScan.com on 2021-11-22
*/

pragma solidity ^0.8.4;

// SPDX-License-Identifier: MIT
// Name: Metrac
// Symbol: MTRC
// Decimals: 18


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IBEP20 {
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
        if (a == 0) { return 0; }

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

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor (address initialOwner) {
        _owner = initialOwner;
        emit OwnershipTransferred(address(0), initialOwner);
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

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is still locked");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

contract Metrac is Context, IBEP20, Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => bool)    private _isExcludedFromFee;
    mapping (address => bool)    private _isExcluded;
    mapping (address => mapping (address => uint256)) private _allowances;

    address[] private _excluded;
    address public _marketingWallet;
    address public _charityWallet;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1000000000000 * 10**18;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private constant _name     = "Metrac Ermordo";
    string private constant _symbol   = "MTRC";
    uint8  private constant _decimals = 18;
    
    uint256 private _taxFee       = 2500; // Unused
    uint256 public _marketingFee = 2500; // 10% of every transaction is sent to marketing wallet
    uint256 public _charityFee   = 2500;//; // 10% of every transaction is sent to charity wallet

    uint256 private _previousTaxFee       = _taxFee;
    uint256 private _previousMarketingFee = _marketingFee;
    uint256 private _previousCharityFee   = _charityFee;

    uint256 public _maxTxAmount = _tTotal / 2;
    
    constructor (address cOwner, address marketingWallet, address charityWallet) Ownable(cOwner) {
        _marketingWallet = marketingWallet;
        _charityWallet   = charityWallet;

        _rOwned[cOwner] = _rTotal;

        // exclude system addresses from fee
        _isExcludedFromFee[owner()]          = true;
        _isExcludedFromFee[address(this)]    = true;
        _isExcludedFromFee[_marketingWallet] = true;
        _isExcludedFromFee[_charityWallet]   = true;
        
        emit Transfer(address(0), cOwner, _tTotal);
    }

    receive() external payable {}

    // BEP20
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
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }

    // REFLECTION
    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");

        (, uint256 tFee, uint256 tMarketing, uint256 tCharity) = _getTValues(tAmount);
        uint256 currentRate = _getRate();
        (uint256 rAmount,,) = _getRValues(tAmount, tFee, tMarketing, tCharity, currentRate);

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal         = _rTotal.sub(rAmount);
        _tFeeTotal      = _tFeeTotal.add(tAmount);
    }
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");

        if (!deductTransferFee) {
            (, uint256 tFee, uint256 tMarketing, uint256 tCharity) = _getTValues(tAmount);
            uint256 currentRate = _getRate();
            (uint256 rAmount,,) = _getRValues(tAmount, tFee, tMarketing, tCharity, currentRate);

            return rAmount;

        } else {
            (, uint256 tFee, uint256 tMarketing, uint256 tCharity) = _getTValues(tAmount);
            uint256 currentRate = _getRate();
            (, uint256 rTransferAmount,) = _getRValues(tAmount, tFee, tMarketing, tCharity, currentRate);

            return rTransferAmount;
        }
    }
    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");

        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }
    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");

        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }
    function includeInReward(address account) external onlyOwner {
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
    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    function setTaxFeePercent(uint256 taxFee) external onlyOwner {
        _taxFee         = taxFee;
        _previousTaxFee = taxFee;
    }
    function setMarketingFeePercent(uint256 marketingFee) external onlyOwner {
        _marketingFee         = marketingFee;
        _previousMarketingFee = marketingFee;
    }
    function setCharityFeePercent(uint256 charityFee) external onlyOwner {
        _charityFee         = charityFee;
        _previousCharityFee = charityFee;
    }
    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner {
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(100);
    }
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }
    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }
    function setMarketingWallet(address marketingWallet) external onlyOwner {
        _marketingWallet = marketingWallet;
    }
    function setCharityWallet(address charityWallet) external onlyOwner {
        _charityWallet = charityWallet;
    }

    // TRANSFER
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (from != owner() && to != owner()) {
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }
        
        bool takeFee = true;
        // if sender or recipient is excluded from fees, remove fees
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }
        
        _tokenTransfer(from, to, amount, takeFee);
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee) {
            removeAllFee();
        }
        
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
        
        if (!takeFee) {
            restoreAllFee();
        }
    }
    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 tTransferAmount, uint256 tFee, uint256 tMarketing, uint256 tCharity) = _getTValues(tAmount);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tMarketing, tCharity, currentRate);

        _rOwned[sender]    = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        takeTransactionFee(address(_marketingWallet), tMarketing, currentRate);
        takeTransactionFee(address(_charityWallet), tCharity, currentRate);
        reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 tTransferAmount, uint256 tFee, uint256 tMarketing, uint256 tCharity) = _getTValues(tAmount);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tMarketing, tCharity, currentRate);

        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        takeTransactionFee(address(_marketingWallet), tMarketing, currentRate);
        takeTransactionFee(address(_charityWallet), tCharity, currentRate);
        reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 tTransferAmount, uint256 tFee, uint256 tMarketing, uint256 tCharity) = _getTValues(tAmount);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tMarketing, tCharity, currentRate);

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        takeTransactionFee(address(_marketingWallet), tMarketing, currentRate);
        takeTransactionFee(address(_charityWallet), tCharity, currentRate);
        reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 tTransferAmount, uint256 tFee, uint256 tMarketing, uint256 tCharity) = _getTValues(tAmount);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tMarketing, tCharity, currentRate);

        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        takeTransactionFee(address(_marketingWallet), tMarketing, currentRate);
        takeTransactionFee(address(_charityWallet), tCharity, currentRate);
        reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal    = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }
    function removeAllFee() private {
        if (_taxFee == 0 && _marketingFee == 0 && _charityFee == 0) return;
        
        _previousTaxFee       = _taxFee;
        _previousMarketingFee = _marketingFee;
        _previousCharityFee   = _charityFee;
        
        _taxFee       = 0;
        _marketingFee = 0;
        _charityFee   = 0;
    }
    function restoreAllFee() private {
        _taxFee       = _previousTaxFee;
        _marketingFee = _previousMarketingFee;
        _charityFee   = _previousCharityFee;
    }
    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
        uint256 tFee       = tAmount.mul(_taxFee).div(100);
        uint256 tMarketing = tAmount.mul(_marketingFee).div(100);
        uint256 tCharity   = tAmount.mul(_charityFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tFee);
        tTransferAmount = tTransferAmount.sub(tMarketing);
        tTransferAmount = tTransferAmount.sub(tCharity);
        return (tTransferAmount, tFee, tMarketing, tCharity);
    }
    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tMarketing, uint256 tCharity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount     = tAmount.mul(currentRate);
        uint256 rFee        = tFee.mul(currentRate);
        uint256 rMarketing  = tMarketing.mul(currentRate);
        uint256 rCharity    = tCharity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee);
        rTransferAmount = rTransferAmount.sub(rMarketing);
        rTransferAmount = rTransferAmount.sub(rCharity);
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
    function takeTransactionFee(address to, uint256 tAmount, uint256 currentRate) private {
        if (tAmount <= 0) { return; }

        uint256 rAmount = tAmount.mul(currentRate);
        _rOwned[to] = _rOwned[to].add(rAmount);
        if (_isExcluded[to]) {
            _tOwned[to] = _tOwned[to].add(tAmount);
        }
    }
}