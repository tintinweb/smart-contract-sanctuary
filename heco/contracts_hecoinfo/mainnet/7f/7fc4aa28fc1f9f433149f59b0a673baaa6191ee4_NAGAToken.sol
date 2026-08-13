/**
 *Submitted for verification at hecoinfo.com on 2022-05-08
*/

/**
 *Submitted for verification at hecoinfo.com on 2022-04-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


contract Ownable is Context {
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    modifier onlyOwner() {
        require(owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}


library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


interface IUniswapV2Factory {function createPair(address tokenA, address tokenB) external returns (address pair);}

interface IUniswapV2Pair {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {}


contract NAGAToken is Ownable, IERC20 {
    using SafeMath for uint256;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint8 private _decimal = 18;

    string private _name = "NAGA TOKEN";
    string private _symbol = "NAGA";
    address public immutable _burnAddress = 0x000000000000000000000000000000000000dEaD;
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal;
    uint256 private _rTotal;
    uint256 private _tFeeTotal;

    uint256 public _burnMinLimit;
    uint256 public _maxTxAmount;

    uint256 public _tLocalRate;
    uint256 public _tBlackRate;
    uint256 public _tLPRate;

    uint256 public _sLocalRate;
    uint256 public _sBlackRate;
    uint256 public _sLPRate;

    uint256 private _tLocalPreRate;
    uint256 private _tBlackPreRate;
    uint256 private _tLPPreRate;

    uint256 private _sLocalPreRate;
    uint256 private _sBlackPreRate;
    uint256 private _sLPPreRate;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => bool) private _isExcluded;

    IERC20 public uniswapV2Pair;

    address[] private _excluded;


    struct TaxFee {
        uint256 tLocalRate;
        uint256 tBlackRate;
        uint256 tLPRate;
        uint256 sLocalRate;
        uint256 sBlackRate;
        uint256 sLPRate;
    }

    struct TaxFeeReflection {
        uint256 rtLocalRate;
        uint256 rtBlackRate;
        uint256 rtLPRate;
        uint256 rsLocalRate;
        uint256 rsBlackRate;
        uint256 rsLPRate;
    }
    
    constructor() {
        owner = msg.sender;

        _tTotal = 9555_7000_0000_0000 * 10**_decimal;
        _rTotal = (MAX - (MAX % _tTotal));

        _rOwned[owner] = _rTotal;

        _burnMinLimit = 100_0000_0000 * 10**_decimal;
        //_maxTxAmount = 1000_0000_0000 * 10**_decimal;

        _tLocalRate = 2;
        _tBlackRate = 1;
        _tLPRate = 2;

        _sLocalRate = 2;
        _sBlackRate = 3;
        _sLPRate = 3;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xED7d5F38C79115ca12fe6C0041abb22F0A06C300);
        uniswapV2Pair = IERC20(IUniswapV2Factory(_uniswapV2Router.factory()).createPair(0xa71EdC38d189767582C38A3145b5873052c3e47a, address(this)));
        
        excludeFromReward(address(0));
        excludeFromReward(_burnAddress);
        
        excludeFromReward(address(this));
        excludeFromReward(address(owner));
        excludeFromReward(address(uniswapV2Pair));

        excludeLpProvider[address(0)] = true;
        excludeLpProvider[_burnAddress] = true;
        emit Transfer(address(0), owner, _tTotal);
    }


    function name() public view virtual  returns (string memory) {
        return _name;
    }

    function symbol() public view virtual  returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual  returns (uint8) {
        return _decimal;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _tTotal;
    }

    function totalSupplyReflection() public view virtual returns (uint256) {
        return _rTotal;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
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

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
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

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function setBurnMinLimit(uint256 minLimit) external onlyOwner {
        _burnMinLimit = minLimit * 10**_decimal;
    }

    function setMaxTxAmount(uint256 maxTxAmount) public onlyOwner {
        _maxTxAmount = maxTxAmount * 10**_decimal;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        //if(sender != owner && recipient != owner) 
        //    require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");

        if (sender == address(uniswapV2Pair) || recipient == address(uniswapV2Pair)){
            _tokenTransfer(sender, recipient, amount, 2);

            if (sender == address(uniswapV2Pair)){
                addLpProvider(recipient);
            } else {
                addLpProvider(sender);
            }
            
        } else {
            _tokenTransfer(sender, recipient, amount, 1);
        }

       
        //if (sender != address(this)) {
        //    processLP(500000);
        //}
    }

    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
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

    function setTaxFeePercent(
        uint256 tLocalRate_, 
        uint256 tBlackRate_, 
        uint256 tLPRate_, 
        uint256 sLocalRate_, 
        uint256 sBlackRate_, 
        uint256 sLPRate_) external onlyOwner {
        _tLocalRate = tLocalRate_;
        _tBlackRate = tBlackRate_;
        _tLPRate = tLPRate_;
        _sLocalRate = sLocalRate_;
        _sBlackRate = sBlackRate_;
        _sLPRate = sLPRate_;
    }
    
    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function calculateTaxFee(uint256 _amount, uint256 ty) private view returns (TaxFee memory taxFee) {
        if ((_tTotal - _tOwned[_burnAddress]) > _burnMinLimit){
            if (ty == 1){
                taxFee.tLocalRate = _amount.mul(_tLocalRate).div(100);
                taxFee.tLPRate = _amount.mul(_tLPRate).div(100);
                taxFee.tBlackRate = _amount.mul(_tBlackRate).div(100);
            } else {
                taxFee.sLocalRate = _amount.mul(_sLocalRate).div(100);
                taxFee.sLPRate = _amount.mul(_sLPRate).div(100);
                taxFee.sBlackRate = _amount.mul(_sBlackRate).div(100);
            }
        }
    }

    function calculateTaxFeeReflection(uint256 _amount, uint256 currentRate, uint256 ty) private view returns (TaxFeeReflection memory feeRelection) {
        TaxFee memory taxFee = calculateTaxFee(_amount, ty);
        if (taxFee.tLocalRate > 0 || taxFee.sLocalRate > 0){
            if (ty == 1){
                feeRelection.rtLocalRate = taxFee.tLocalRate.mul(currentRate);
                feeRelection.rtBlackRate = taxFee.tBlackRate.mul(currentRate);
                feeRelection.rtLPRate = taxFee.tLPRate.mul(currentRate);
            } else {
                feeRelection.rsLocalRate = taxFee.sLocalRate.mul(currentRate);
                feeRelection.rsBlackRate = taxFee.sBlackRate.mul(currentRate);
                feeRelection.rsLPRate = taxFee.sLPRate.mul(currentRate);
            }
        }   
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
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal); // rTotal - m * (rTotal/tTotal) >= rTotal/tTotal ==> m <= tTotal
        return (rSupply, tSupply);
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, uint256 ty) private {
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount, ty);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount, ty);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount, ty);
        } else {
            _transferStandard(sender, recipient, amount, ty);
        }
    }

    function _reflectFee(uint256 rShareFree, uint256 tShareFree) private {
        if (rShareFree > 0){
            _rTotal = _rTotal.sub(rShareFree);
            _tFeeTotal = _tFeeTotal.add(tShareFree);
        }
    }

    function _getTValues(uint256 tAmount, uint256 ty) private view returns (uint256) {
        TaxFee memory taxFee = calculateTaxFee(tAmount, ty);
        uint256 tTransferAmount;
        if (ty == 1){
            tTransferAmount = tAmount.sub(taxFee.tLocalRate).sub(taxFee.tBlackRate).sub(taxFee.tLPRate);
        } else {
            tTransferAmount = tAmount.sub(taxFee.sLocalRate).sub(taxFee.sBlackRate).sub(taxFee.sLPRate);
        }
        return tTransferAmount;
    }

    function _getRValues(uint256 tAmount, uint256 currentRate, uint256 ty) private view returns (uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        TaxFeeReflection memory feeRelection = calculateTaxFeeReflection(tAmount, currentRate, ty);
        uint256 rTransferAmount;
        if (ty == 1){
            rTransferAmount = rAmount.sub(feeRelection.rtLocalRate).sub(feeRelection.rtBlackRate).sub(feeRelection.rtLPRate);
        } else {
            rTransferAmount = rAmount.sub(feeRelection.rsLocalRate).sub(feeRelection.rsBlackRate).sub(feeRelection.rsLPRate);
        }
        return (rAmount, rTransferAmount);
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount, uint256 ty) private {
        uint256 tTransferAmount = _getTValues(tAmount, ty);
        TaxFee memory taxFee = calculateTaxFee(tAmount, ty);
        (uint256 rAmount, uint256 rTransferAmount) = _getRValues(tAmount, _getRate(), ty);
        TaxFeeReflection memory feeRelection = calculateTaxFeeReflection(tAmount,  _getRate(), ty);

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        _relationShare(sender, taxFee, feeRelection, ty);
        
        if (feeRelection.rtLocalRate > 0 || feeRelection.rsLocalRate > 0){
            if (ty == 1){
                _reflectFee(feeRelection.rtLocalRate, taxFee.tLocalRate);
            } else {
                _reflectFee(feeRelection.rsLocalRate, taxFee.sLocalRate);
            }
        }
        emit Transfer(sender, recipient, tTransferAmount);
    }
    

    function _transferToExcluded(address sender, address recipient, uint256 tAmount, uint256 ty) private {
        uint256 tTransferAmount = _getTValues(tAmount, ty);
        TaxFee memory taxFee = calculateTaxFee(tAmount, ty);
        (uint256 rAmount, uint256 rTransferAmount) = _getRValues(tAmount, _getRate(), ty);
        TaxFeeReflection memory feeRelection = calculateTaxFeeReflection(tAmount,  _getRate(), ty);
        
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        _relationShare(sender, taxFee, feeRelection, ty);

        if (feeRelection.rtLocalRate > 0 || feeRelection.rsLocalRate > 0){
            if (ty == 1){
                _reflectFee(feeRelection.rtLocalRate, taxFee.tLocalRate);
            } else {
                _reflectFee(feeRelection.rsLocalRate, taxFee.sLocalRate);
            }
        }
        
        emit Transfer(sender, recipient, tTransferAmount);
    }


    function _transferFromExcluded(address sender, address recipient, uint256 tAmount, uint256 ty) private {
        uint256 tTransferAmount = _getTValues(tAmount, ty);
        TaxFee memory taxFee = calculateTaxFee(tAmount, ty);
        (uint256 rAmount, uint256 rTransferAmount) = _getRValues(tAmount, _getRate(), ty);
        TaxFeeReflection memory feeRelection = calculateTaxFeeReflection(tAmount,  _getRate(), ty);

        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        
        _relationShare(sender, taxFee, feeRelection, ty);

        if (feeRelection.rtLocalRate > 0 || feeRelection.rsLocalRate > 0){
            if (ty == 1){
                _reflectFee(feeRelection.rtLocalRate, taxFee.tLocalRate);
            } else {
                _reflectFee(feeRelection.rsLocalRate, taxFee.sLocalRate);
            }
        }
        emit Transfer(sender, recipient, tTransferAmount);
    }


    function _transferBothExcluded(address sender, address recipient, uint256 tAmount, uint256 ty) private {
        uint256 tTransferAmount = _getTValues(tAmount, ty);
        TaxFee memory taxFee = calculateTaxFee(tAmount, ty);
        (uint256 rAmount, uint256 rTransferAmount) = _getRValues(tAmount, _getRate(), ty);
        TaxFeeReflection memory feeRelection = calculateTaxFeeReflection(tAmount,  _getRate(), ty);
        
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        
        _relationShare(sender, taxFee, feeRelection, ty);

        if (feeRelection.rtLocalRate > 0 || feeRelection.rsLocalRate > 0){
            if (ty == 1){
                _reflectFee(feeRelection.rtLocalRate, taxFee.tLocalRate);
            } else {
                _reflectFee(feeRelection.rsLocalRate, taxFee.sLocalRate);
            }
        }
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _relationShare(address sender, TaxFee memory taxFee, TaxFeeReflection memory feeRelection, uint ty) private {
        if (taxFee.tLPRate > 0 || taxFee.sLPRate > 0){
            if (ty == 1){
                _tOwned[address(this)] = _tOwned[address(this)].add(taxFee.tLPRate);
                _rOwned[address(this)] = _rOwned[address(this)].add(feeRelection.rtLPRate);
                _tOwned[_burnAddress] = _tOwned[_burnAddress].add(taxFee.tBlackRate);
                _rOwned[_burnAddress] = _rOwned[_burnAddress].add(feeRelection.rtBlackRate);
                emit Transfer(sender, address(this), taxFee.tLPRate);
                emit Transfer(sender, _burnAddress, taxFee.tBlackRate);
            } else {
                _tOwned[address(this)] = _tOwned[address(this)].add(taxFee.sLPRate);
                _rOwned[address(this)] = _rOwned[address(this)].add(feeRelection.rsLPRate);
                _tOwned[_burnAddress] = _tOwned[_burnAddress].add(taxFee.sBlackRate);
                _rOwned[_burnAddress] = _rOwned[_burnAddress].add(feeRelection.rsBlackRate);
                emit Transfer(sender, address(this), taxFee.sLPRate);
                emit Transfer(sender, _burnAddress, taxFee.sBlackRate);
            }
        }
    }

    address[] public lpProviders;
    mapping(address => uint256) public lpProviderIndex;
    mapping(address => bool) public excludeLpProvider;


    function addLpProvider(address adr) private {
        if (lpProviderIndex[adr] == 0) {
            lpProviderIndex[adr] = lpProviders.length;
            lpProviders.push(adr);
        }
    }

    uint256 public currentIndex;
    uint256 public lpRewardCondition = 10;
    uint256 public progressLPBlock=block.number;


    function processLP(uint256 gas) public {

        if (progressLPBlock + 200 > block.number) {
            return;
        }
  
        uint totalPair = uniswapV2Pair.totalSupply();
        if (totalPair == 0) {
            return;
        }

        uint256 balance = balanceOf(address(this));

        if (balance < lpRewardCondition) {
            return;
        }

        address shareHolder;
        uint256 pairBalance;
        uint256 amount;

        uint256 shareholderCount = lpProviders.length;

        uint256 gasUsed = 0;
        uint256 iterations = 0;

        uint256 gasLeft = gasleft();


        while (gasUsed < gas && iterations < shareholderCount) {

            if (currentIndex >= shareholderCount) {
                currentIndex = 0;
            }
            shareHolder = lpProviders[currentIndex];

            pairBalance = uniswapV2Pair.balanceOf(shareHolder);

            if (pairBalance > 0 && !excludeLpProvider[shareHolder]) {
                amount = balance * pairBalance / totalPair;

                if (amount > 0) {
                    _tokenTransfer(address(this), shareHolder, amount, 1);
                }
            }
            uint256 newGasLeft = gasleft();
            if(gasLeft > newGasLeft) {
                gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
            }

            gasLeft = newGasLeft;
            //gasUsed = gasUsed + (gasLeft - gasleft());
            //gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }

        progressLPBlock = block.number;
    }


    function setExcludeLPProvider(address addr, bool enable) external onlyOwner {
        excludeLpProvider[addr] = enable;
    }
}