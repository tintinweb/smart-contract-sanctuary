/**
 *Submitted for verification at Etherscan.io on 2021-12-11
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

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
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

contract YeagerInu is Context, IERC20Metadata, Ownable {
    
    struct governingTaxes{
        uint32 _split0;
        uint32 _split1;
        uint32 _split2;
        uint32 _split3;
        address _wallet1;
        address _wallet2;
    }

    struct Fees {
        uint256 _fee0;
        uint256 _fee1;
        uint256 _fee2;
        uint256 _fee3;
    }
    
    uint32 private _totalTaxPercent;
    governingTaxes private _governingTaxes;
    
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isLiquidityPool;

    mapping (address => bool) private _isBlacklisted;
    uint256 public _maxTxAmount;
    uint256 private _maxHoldAmount;

    bool private _tokenLock = true; //Locking the token until Liquidty is added
    bool private _taxReverted = false;
    uint256 public _tokenCommenceTime;

    uint256 private constant _startingSupply = 100_000_000_000_000_000; //100 Quadrillion
    
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = _startingSupply * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    
    string private constant _name = "Yeager Inu";
    string private constant _symbol = "YEAGER";
    uint8 private constant _decimals = 9;

    address public constant burnAddress = 0x000000000000000000000000000000000000dEaD; 

    constructor (address wallet1_,  address wallet2_) {
        _rOwned[_msgSender()] = _rTotal;

        /*
            Total Tax Percentage per Transaction : 10%
            Tax Split:
                > Burn (burnAddress): 10%
                > Dev Wallet (wallet1): 20% 
                > Marketing Wallet (wallet2): 50%
                > Holders (reflect): 20%
        */

        /*
            >>> First 24 hour Tax <<<

            Total Tax Percentage per Transaction : 25%
            Tax Split:
                > Burn (burnAddress): 4%
                > Dev Wallet (wallet1): 40% 
                > Marketing Wallet (wallet2): 40%
                > Holders (reflect): 16%
        */
        _totalTaxPercent = 25;  
        _governingTaxes = governingTaxes(4, 40, 40, 16, wallet1_, wallet2_); 
        

        //Max TX amount is 100% of the total supply, will be updated when token gets into circulation (anti-whale)
        _maxTxAmount = (_startingSupply * 10**9); 
        //Max Hold amount is 2% of the total supply. (Only for first 24 hours) (anti-whale) 
        _maxHoldAmount = ((_startingSupply * 10**9) * 2) / 100;

        //Excluding Owner and Other Governing Wallets From Reward System;
        excludeFromFee(owner());
        excludeFromReward(owner());
        excludeFromReward(burnAddress);
        excludeFromReward(wallet1_);
        excludeFromReward(wallet2_);

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public pure override returns (string memory) {
        return _name;
    }

    function symbol() public pure override returns (string memory) {
        return _symbol;
    }

    function decimals() public pure override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
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

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
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

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function currentTaxes() public view 
    returns (
        uint32 total_Tax_Percent,
        uint32 burn_Split,
        uint32 governingSplit_Wallet1,
        uint32 governingSplit_Wallet2,
        uint32 reflect_Split
    ) {
        return (
            _totalTaxPercent,
            _governingTaxes._split0,
            _governingTaxes._split1,
            _governingTaxes._split2,
            _governingTaxes._split3
        );
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function isBlacklisted(address account) public view returns (bool) {
        return _isBlacklisted[account];
    }

    function isLiquidityPool(address account) public view returns (bool) {
        return _isLiquidityPool[account];
    }

    function _hasLimits(address from, address to) private view returns (bool) {
        return from != owner()
            && to != owner()
            && to != burnAddress;
    }

    function setBlacklistAccount(address account, bool enabled) external onlyOwner() {
        _isBlacklisted[account] = enabled;
    }

    function setLiquidityPool(address account, bool enabled) external onlyOwner() {
        _isLiquidityPool[account] = enabled;
    }

    function setMaxTxAmount(uint256 maxTxAmount) external onlyOwner() {
        require(maxTxAmount >= (_tTotal / 1000), "Max Transaction amt must be above 0.1% of total supply"); // Cannot set lower than 0.1%
        _maxTxAmount = maxTxAmount;
    }

    function unlockToken() external onlyOwner() {
        _tokenLock = false;
        _tokenCommenceTime = block.timestamp;
    }

    function revertTax() external {
        require(!_tokenLock, "Token is Locked for Liquidty to be added");
        require(block.timestamp - _tokenCommenceTime > 86400, "Tax can be reverted only after 24hrs"); //check for 24 hours timeperiod
        require(!_taxReverted, "Tax had been Reverted!"); //To prevent taxRevert more than once 

        _totalTaxPercent = 10;
        _governingTaxes._split0 = 10;
        _governingTaxes._split1 = 20;
        _governingTaxes._split2 = 50;
        _governingTaxes._split3 = 20;

        _maxHoldAmount = _tTotal; //Removing the max hold limit of 2%
        _taxReverted = true;
    }

    function setTaxes(
        uint32 totalTaxPercent_, 
        uint32 split0_, 
        uint32 split1_, 
        uint32 split2_, 
        uint32 split3_, 
        address wallet1_, 
        address wallet2_
    ) external onlyOwner() {
        require(wallet1_ != address(0) && wallet2_ != address(0), "Tax Wallets assigned zero address !");
        require(totalTaxPercent_ <= 10, "Total Tax Percent Exceeds 10% !"); // Prevents owner from manipulating Tax.
        require(split0_+split1_+split2_+split3_ == 100, "Split Percentages does not sum upto 100 !");

        _totalTaxPercent = totalTaxPercent_;
        _governingTaxes._split0 = split0_;
        _governingTaxes._split1 = split1_;
        _governingTaxes._split2 = split2_;
        _governingTaxes._split3 = split3_;
        _governingTaxes._wallet1 = wallet1_;
        _governingTaxes._wallet2 = wallet2_;
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
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

    function reflect(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rTotal = _rTotal - rAmount;
        _tFeeTotal = _tFeeTotal + tAmount;
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
        return rAmount / currentRate;
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

    function _transfer(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require((!_tokenLock) || (!_hasLimits(sender, recipient))  , "Token is Locked for Liquidty to be added");

        if(_hasLimits(sender, recipient)) {
            require(tAmount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount");
            require(!isBlacklisted(sender) || !isBlacklisted(recipient), "Sniper Rejected");
            if(!_taxReverted && !_isLiquidityPool[recipient]) {
                require(balanceOf(recipient)+tAmount <= _maxHoldAmount, "Receiver address exceeds the maxHoldAmount");
            }
        }

        uint32 _previoustotalTaxPercent;
        if(_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) //checking if Tax should be deducted from transfer
        {
            _previoustotalTaxPercent = _totalTaxPercent;
            _totalTaxPercent = 0; //removing Taxes
        }
        else if(!_taxReverted && _isLiquidityPool[sender]) {
            _previoustotalTaxPercent = _totalTaxPercent;
            _totalTaxPercent = 10; //Liquisity pool Buy tax reduced to 10% from 25%
        }

        (uint256 rAmount, uint256 rTransferAmount, Fees memory rFee, uint256 tTransferAmount, Fees memory tFee) = _getValues(tAmount);

        if(_isExcludedFromFee[sender] || _isExcludedFromFee[recipient] || 
          (!_taxReverted && _isLiquidityPool[sender])) _totalTaxPercent = _previoustotalTaxPercent; //restoring Taxes

        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;

        _rOwned[burnAddress] += rFee._fee0;
        _rOwned[_governingTaxes._wallet1] += rFee._fee1;
        _rOwned[_governingTaxes._wallet2] += rFee._fee2;
        _reflectFee(rFee._fee3, tFee._fee0+tFee._fee1+tFee._fee2+tFee._fee3);

        if (_isExcluded[sender]) _tOwned[sender] = _tOwned[sender] - tAmount;
        if (_isExcluded[recipient]) _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
        if (_isExcluded[burnAddress]) _tOwned[burnAddress] += tFee._fee0;
        if (_isExcluded[_governingTaxes._wallet1]) _tOwned[_governingTaxes._wallet1] += tFee._fee1;
        if (_isExcluded[_governingTaxes._wallet2])_tOwned[_governingTaxes._wallet2] += tFee._fee2;
        
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal - rFee;
        _tFeeTotal = _tFeeTotal + tFee;
    }

    function _getValues(uint256 tAmount) private view returns (uint256 rAmount, uint256 rTransferAmount, Fees memory rFee, uint256 tTransferAmount, Fees memory tFee) {
        (tTransferAmount, tFee) = _getTValues(tAmount);
        uint256 currentRate =  _getRate();
        (rAmount, rTransferAmount, rFee) = _getRValues(tAmount, tFee, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, Fees memory) {
        Fees memory tFee;
        tFee._fee0 = (tAmount * _totalTaxPercent * _governingTaxes._split0) / 10**4;
        tFee._fee1 = (tAmount * _totalTaxPercent * _governingTaxes._split1) / 10**4;
        tFee._fee2 = (tAmount * _totalTaxPercent * _governingTaxes._split2) / 10**4;
        tFee._fee3 = (tAmount * _totalTaxPercent * _governingTaxes._split3) / 10**4;
        uint256 tTransferAmount = tAmount - tFee._fee0 - tFee._fee1 - tFee._fee2 - tFee._fee3;
        return (tTransferAmount, tFee);
    }

    function _getRValues(uint256 tAmount, Fees memory tFee, uint256 currentRate) private pure returns (uint256, uint256, Fees memory) {
        uint256 rAmount = tAmount * currentRate;
        Fees memory rFee;
        rFee._fee0 = tFee._fee0 * currentRate;
        rFee._fee1 = tFee._fee1 * currentRate;
        rFee._fee2 = tFee._fee2 * currentRate;
        rFee._fee3 = tFee._fee3 * currentRate;
        uint256 rTransferAmount = rAmount - rFee._fee0 - rFee._fee1 - rFee._fee2 - rFee._fee3;
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
            rSupply = rSupply - _rOwned[_excluded[i]];
            tSupply = tSupply - _tOwned[_excluded[i]];
        }
        if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
}