// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

import './Ownable.sol';
import './libraries/SafeMath.sol';
import './libraries/Address.sol';
import './interfaces/IERC20.sol';

contract SkizmCoin is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => uint256) public totalTokensTransferred;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;

    mapping (address => bool) private _isExcluded;
    address[] private _excluded;

    struct ValuesResult {
        uint256 tTransferAmount;
        uint256 tFee;
        uint256 tLiquidity;
        uint256 tTribute;
        uint256 tMarketing;
        uint256 tMaintenance;
        uint256 tLiquidityWallet;
        uint256 rAmount;
        uint256 rTransferAmount;
        uint256 rFee;
        uint256 rLiquidity;
        uint256 rTribute;
        uint256 rMarketing;
        uint256 rMaintenance;
        uint256 rLiquidityWallet;
    }

    /*
    Tokenomics:
        - Max Supply: 1,000,000,000
        - Max TX: 10,000,000 (1%)
        - 3% fee - automatically redistributed to all holders
        - 3% fee - liquidity pool
        - 3% fee - marketing
        - 2% fee - project development
        - 2% fee - team
        Total fees = 13%
    */

    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1 * 10**9 * 10**18;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private constant _name = "SkizmCoin";
    string private constant _symbol = "Skizm";
    uint8 private constant _decimals = 18;

    // fees
    uint256 public _taxFee = 300; // reflection
    uint256 private _previousTaxFee = _taxFee;

    uint256 public _tributeFee = 200; // team
    uint256 private _previousTributeFee = _tributeFee;

    uint256 public _marketingFee = 300; // marketing
    uint256 private _previousMarketingFee = _marketingFee;

    uint256 public _maintenanceFee = 200; // development
    uint256 private _previousMaintenanceFee = _maintenanceFee;

    uint256 public _liquidityWalletFee = 300; // liquidity pool
    uint256 private _previousliquidityWalletFee = _liquidityWalletFee;

    uint256 public _maxTxAmount = 1 * 10**7 * 10**18; // 0.01
    uint256 private constant _TIMELOCK = 0; //31536000 1 year
//    uint256 private constant _TIMELOCK = 31536000; // 1 year

    event TaxFeePercentChanged(uint256 oldValue, uint256 newValue);
    event TributeFeePercentChanged(uint256 oldValue, uint256 newValue);
    event MarketingFeePercentChanged(uint256 oldValue, uint256 newValue);
    event MaintenanceFeePercentChanged(uint256 oldValue, uint256 newValue);
    event LiquidityWalletFeePercentChanged(uint256 oldValue, uint256 newValue);
    event MaxTxPermillChanged(uint256 oldValue, uint256 newValue);

    constructor (address payable tributeAddress, address payable marketingAddress, address payable maintenanceAddress, address payable liquidityWalletAddress) {
        _rOwned[owner()] = _rTotal;

        // exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        setTributeAddress(tributeAddress);
        setMarketingAddress(marketingAddress);
        setMaintenanceAddress(maintenanceAddress);
        setLiquidityWalletAddress(liquidityWalletAddress);

        increaseTimeLockBy(_TIMELOCK);

        emit Transfer(address(0), owner(), _tTotal);
    }

    function name() external pure returns (string memory) {
        return _name;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() external pure override returns (uint256) {
        return _tTotal;
    }

    function totalRSupply() external view onlyOwner() returns (uint256) {
        return _rTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function balanceOfT(address account) external view onlyOwner() returns (uint256) {
        return _tOwned[account];
    }

    function balanceOfR(address account) external view onlyOwner() returns (uint256) {
        return _rOwned[account];
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferOwnership(address newOwner) external virtual onlyOwner() onlyUnlocked() {
        emit OwnershipTransferred(owner(), newOwner);
        _transfer(owner(), newOwner, balanceOf(owner()));
        updateOwner(newOwner);
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
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

    function isExcludedFromReward(address account) external view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() external view returns (uint256) {
        return _tFeeTotal;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) external view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public override onlyOwner() onlyUnlocked(){
        // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Uniswap router.');
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already included");
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

    function excludeFromFee(address account) public override onlyOwner onlyUnlocked(){
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setTaxFeePercent(uint256 taxFee) external onlyOwner() onlyUnlocked(){
        require(taxFee <= 300, "Cannot set percentage over 3.00%");
        emit TaxFeePercentChanged(_taxFee, taxFee);
        _taxFee = taxFee;
    }

    function setTributeFeePercent(uint256 tributeFee) external onlyOwner() onlyUnlocked(){
        require(tributeFee <= 200, "Cannot set percentage over 2.00%");
        emit TributeFeePercentChanged(_tributeFee, tributeFee);
        _tributeFee = tributeFee;
    }

    function setMarketingFeePercent(uint256 marketingFee) external onlyOwner() onlyUnlocked(){
        require(marketingFee <= 300, "Cannot set percentage over 3.00%");
        emit MarketingFeePercentChanged(_marketingFee, marketingFee);
        _marketingFee = marketingFee;
    }

    function setMaintenanceFeePercent(uint256 maintenanceFee) external onlyOwner() onlyUnlocked(){
        require(maintenanceFee <= 200, "Cannot set percentage over 2.00%");
        emit MaintenanceFeePercentChanged(_maintenanceFee, maintenanceFee);
        _maintenanceFee = maintenanceFee;
    }

    function setLiquidityWalletFeePercent(uint256 liquidityWalletFee) external onlyOwner() onlyUnlocked(){
        require(liquidityWalletFee <= 300, "Cannot set percentage over 3.00%");
        emit LiquidityWalletFeePercentChanged(_liquidityWalletFee, liquidityWalletFee);
        _liquidityWalletFee = liquidityWalletFee;
    }

    function setMaxTxPermill(uint256 maxTxPermill) external onlyOwner() onlyUnlocked(){
        emit LiquidityWalletFeePercentChanged(_maxTxAmount, _tTotal.mul(maxTxPermill).div(10**3));
        _maxTxAmount = _tTotal.mul(maxTxPermill).div(
            10**3
        );
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        ValuesResult memory valuesResult = ValuesResult(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

        _getTValues(tAmount, valuesResult);
        _getRValues(tAmount, valuesResult, _getRate());

        return (valuesResult.rAmount, valuesResult.rTransferAmount, valuesResult.rFee, valuesResult.tTransferAmount, valuesResult.tFee, valuesResult.tLiquidity, valuesResult.tTribute, valuesResult.tMarketing, valuesResult.tMaintenance, valuesResult.tLiquidityWallet);
    }

    // Getting values as struct to avoid "Stack too deep" issue in _transferType functions
    function _getValuesStruct(uint256 tAmount) private view returns (ValuesResult memory) {
        ValuesResult memory valuesResult = ValuesResult(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

        _getTValues(tAmount, valuesResult);
        _getRValues(tAmount, valuesResult, _getRate());

        return (valuesResult);
    }

    function _getTValues(uint256 tAmount, ValuesResult memory valuesResult) private view returns (ValuesResult memory) {
        {
            uint256 tFee = calculateTaxFee(tAmount);
            valuesResult.tFee = tFee;
        }
        {
            uint256 tTribute = calculateTributeFee(tAmount);
            valuesResult.tTribute = tTribute;
        }
        {
            uint256 tMarketing = calculateMarketingFee(tAmount);
            valuesResult.tMarketing = tMarketing;
        }
        {
            uint256 tMaintenance = calculateMaintenanceFee(tAmount);
            valuesResult.tMaintenance = tMaintenance;
        }
        {
            uint256 tLiquidityWallet = calculateLiquidityWalletFee(tAmount);
            valuesResult.tLiquidityWallet = tLiquidityWallet;
        }

        valuesResult.tTransferAmount = tAmount.sub(valuesResult.tFee).sub(valuesResult.tTribute).sub(valuesResult.tMarketing).sub(valuesResult.tMaintenance).sub(valuesResult.tLiquidityWallet);
        return valuesResult;
    }

    function _getRValues(uint256 tAmount, ValuesResult memory valuesResult, uint256 currentRate) private pure returns (ValuesResult memory) {
        {
            uint256 rAmount = tAmount.mul(currentRate);
            valuesResult.rAmount = rAmount;
        }
        {
            uint256 rFee = valuesResult.tFee.mul(currentRate);
            valuesResult.rFee = rFee;
        }
        {
            uint256 rTribute = valuesResult.tTribute.mul(currentRate);
            valuesResult.rTribute = rTribute;
        }
        {
            uint256 rMarketing = valuesResult.tMarketing.mul(currentRate);
            valuesResult.rMarketing = rMarketing;
        }
        {
            uint256 rMaintenance = valuesResult.tMaintenance.mul(currentRate);
            valuesResult.rMaintenance = rMaintenance;
        }
        {
            uint256 rLiquidityWallet = valuesResult.tLiquidityWallet.mul(currentRate);
            valuesResult.rLiquidityWallet = rLiquidityWallet;
        }

        valuesResult.rTransferAmount = valuesResult.rAmount.sub(valuesResult.rFee).sub(valuesResult.rTribute).sub(valuesResult.rMarketing).sub(valuesResult.rMaintenance).sub(valuesResult.rLiquidityWallet);
        return (valuesResult);
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

    function _takeValue(uint256 tValue, address payable from) private {
        uint256 currentRate =  _getRate();
        uint256 rValue = tValue.mul(currentRate);
        _rOwned[from] = _rOwned[from].add(rValue);
        if(_isExcluded[from])
            _tOwned[from] = _tOwned[from].add(tValue);
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(
            10**4
        );
    }

    function calculateTributeFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_tributeFee).div(
            10**4
        );
    }

    function calculateMarketingFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_marketingFee).div(
            10**4
        );
    }

    function calculateMaintenanceFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_maintenanceFee).div(
            10**4
        );
    }

    function calculateLiquidityWalletFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityWalletFee).div(
            10**4
        );
    }

    function removeAllFee() private {
        if(_taxFee == 0) return;

        _previousTaxFee = _taxFee;
        _previousTributeFee = _tributeFee;
        _previousMarketingFee = _marketingFee;
        _previousMaintenanceFee = _maintenanceFee;
        _previousliquidityWalletFee = _liquidityWalletFee;

        _taxFee = 0;
        _tributeFee = 0;
        _marketingFee = 0;
        _maintenanceFee = 0;
        _liquidityWalletFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _tributeFee = _previousTributeFee;
        _marketingFee = _previousMarketingFee;
        _maintenanceFee = _previousMaintenanceFee;
        _liquidityWalletFee = _previousliquidityWalletFee;
    }

    function isExcludedFromFee(address account) external view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function addTokensTransferred(address wallet, uint256 amount) private {
        uint256 rate = _taxFee.add(_tributeFee).add(_marketingFee).add(_maintenanceFee).add(_liquidityWalletFee);
        totalTokensTransferred[wallet] = totalTokensTransferred[wallet].add(amount.mul(rate).div(10**4));
    }

    function getTotalTokensTransferredHistory(address wallet) external view returns(uint256 amount){
        amount = totalTokensTransferred[wallet];
        return amount;
    }

    /**
    * TRANSFER
    */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if(from != owner() && to != owner())
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }

        // if fees are calculated, then these amounts will be tracked in totalTokensTransferred[sender]
        if(takeFee){
            addTokensTransferred(from, amount);
        }

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from,to,amount,takeFee);
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        if(!takeFee)
            removeAllFee();

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }

        if(!takeFee)
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        ValuesResult memory valuesResult = _getValuesStruct(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(valuesResult.rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(valuesResult.rTransferAmount);
        _takeValues(valuesResult);
        emit Transfer(sender, recipient, valuesResult.tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        ValuesResult memory valuesResult = _getValuesStruct(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(valuesResult.rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(valuesResult.tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(valuesResult.rTransferAmount);
        _takeValues(valuesResult);
        emit Transfer(sender, recipient, valuesResult.tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        ValuesResult memory valuesResult = _getValuesStruct(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(valuesResult.rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(valuesResult.rTransferAmount);
        _takeValues(valuesResult);
        emit Transfer(sender, recipient, valuesResult.tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        ValuesResult memory valuesResult = _getValuesStruct(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(valuesResult.rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(valuesResult.tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(valuesResult.rTransferAmount);
        _takeValues(valuesResult);
        emit Transfer(sender, recipient, valuesResult.tTransferAmount);
    }

    function _takeValues(ValuesResult memory valuesResult) private {
        _takeValue(valuesResult.tLiquidity, payable(address(this)));
        _takeValue(valuesResult.tTribute, tribute());
        _takeValue(valuesResult.tMarketing, marketing());
        _takeValue(valuesResult.tMaintenance, maintenance());
        _takeValue(valuesResult.tLiquidityWallet, liquidityWallet());
        _reflectFee(valuesResult.rFee, valuesResult.tFee);
    }
    /**
    * TRANSFER (END)
    */
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
 
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

interface IERC20 {

    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

import "./Context.sol";
import './libraries/SafeMath.sol';

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    using SafeMath for uint256;
    address private _owner;
    address payable private _tributeWalletAddress;
    address payable private _marketingWalletAddress;
    address payable private _maintenanceWalletAddress;
    address payable private _liquidityWalletAddress;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event TributeAddressChanged(address oldAddress, address newAddress);
    event MarketingAddressChanged(address oldAddress, address newAddress);
    event MaintenanceAddressChanged(address oldAddress, address newAddress);
    event LiquidityWalletAddressChanged(address oldAddress, address newAddress);
    event TimeLockChanged(uint256 previousValue, uint256 newValue);

    // set timelock
    enum Functions { excludeFromFee }
    uint256 public timelock = 0;
//    uint256 public timelock = 31536000; // 1 year

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    modifier onlyUnlocked() {
        require(timelock <= block.timestamp, "Function is timelocked");
        _;
    }

    //lock timelock
    function increaseTimeLockBy(uint256 _time) public onlyOwner onlyUnlocked {
        uint256 _previousValue = timelock;
        timelock = block.timestamp.add(_time);
        emit TimeLockChanged(_previousValue ,timelock);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function lockDue() public view returns (uint256) {
        return timelock;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function updateOwner(address newOwner) internal onlyOwner() onlyUnlocked() {
        _owner = newOwner;
    }
    
    function tribute() public view returns (address payable)
    {
        return _tributeWalletAddress;
    }

    function marketing() public view returns (address payable)
    {
        return _marketingWalletAddress;
    }

    function maintenance() public view returns (address payable)
    {
        return _maintenanceWalletAddress;
    }

    function liquidityWallet() public view returns (address payable)
    {
        return _liquidityWalletAddress;
    }
    
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    modifier onlyTribute() {
        require(_tributeWalletAddress == _msgSender(), "Caller is not the tribute address");
        _;
    }

    modifier onlyMarketing() {
        require(_marketingWalletAddress == _msgSender(), "Caller is not the marketing address");
        _;
    }

    modifier onlyMaintenance() {
        require(_maintenanceWalletAddress == _msgSender(), "Caller is not the maintenance address");
        _;
    }

     /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function excludeFromReward(address account) public virtual onlyOwner() onlyUnlocked() {
    }

    function excludeFromFee(address account) public virtual onlyOwner() onlyUnlocked(){
    }
    
    function setTributeAddress(address payable tributeAddress) public virtual onlyOwner onlyUnlocked()
    {
        //require(_tribute == address(0), "Tribute address cannot be changed once set");
        emit TributeAddressChanged(_tributeWalletAddress, tributeAddress);
        _tributeWalletAddress = tributeAddress;
        excludeFromReward(tributeAddress);
        excludeFromFee(tributeAddress);
    }

    function setMarketingAddress(address payable marketingAddress) public virtual onlyOwner onlyUnlocked()
    {
        //require(_marketing == address(0), "Marketing address cannot be changed once set");
        emit MarketingAddressChanged(_marketingWalletAddress, marketingAddress);
        _marketingWalletAddress = marketingAddress;
        excludeFromReward(marketingAddress);
        excludeFromFee(marketingAddress);
    }

    function setMaintenanceAddress(address payable maintenanceAddress) public virtual onlyOwner onlyUnlocked()
    {
        //require(_maintenance == address(0), "Maintenance address cannot be changed once set");
        emit MaintenanceAddressChanged(_maintenanceWalletAddress, maintenanceAddress);
        _maintenanceWalletAddress = maintenanceAddress;
        excludeFromReward(maintenanceAddress);
        excludeFromFee(maintenanceAddress);
    }

    function setLiquidityWalletAddress(address payable liquidityWalletAddress) public virtual onlyOwner onlyUnlocked()
    {
        //require(_maintenance == address(0), "Liquidity address cannot be changed once set");
        emit LiquidityWalletAddressChanged(_liquidityWalletAddress, liquidityWalletAddress);
        _liquidityWalletAddress = liquidityWalletAddress;
        excludeFromReward(liquidityWalletAddress);
        excludeFromFee(liquidityWalletAddress);
    }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}