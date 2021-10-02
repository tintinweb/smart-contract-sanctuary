//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC20.sol";
import "Ownable.sol";
import "SafeMath.sol";
import "Address.sol";

contract THR is Context, IERC20, Ownable {

    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
    
    string  private constant _NAME = 'THIRON';
    string  private constant _SYMBOL = 'THR';
    uint8   private constant _DECIMALS = 18;
   
    uint256 private constant _MAX = ~uint256(0);
    uint256 private constant _DECIMALFACTOR = 10 ** uint256(_DECIMALS);
    uint256 private constant _GRANULARITY = 100;
    
    uint256 private _tTotal = 1000000000 * _DECIMALFACTOR;
    uint256 private _rTotal = (_MAX - (_MAX % _tTotal));
    
    uint256 private _tFeeTotal;
    uint256 private _tBurnTotal;
    uint256 private _tideCycle = 0;

    uint256 private _tTradeCycle = 0;
    uint256 private _tBurnCycle = 0;

    uint256 private _BURN_FEE = 300;
    uint256 private _TAX_FEE = 400;
    uint256 private constant _MAX_TX_SIZE = 100000000 * _DECIMALFACTOR;

    // TOTAL_GONS is a multiple of INITIAL_FRAGMENTS_SUPPLY so that _gonsPerFragment is an integer.
    // Use the highest value that fits in a uint256 for max granularity.

    // MAX_SUPPLY = maximum integer < (sqrt(4*TOTAL_GONS + 1) - 1) / 2
    uint256 private constant MAX_SUPPLY = ~uint128(0);  // (2^128) - 1  

    uint256 private _gonsPerFragment;
    mapping(address => uint256) private _gonBalances;

    
    constructor() {
        _rOwned[_msgSender()] = _rTotal;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }


  
    function name() public pure returns (string memory) {
        return _NAME;
    }

    function symbol() public pure returns (string memory) {
        return _SYMBOL;
    }

    function decimals() public pure returns (uint8) {
        return _DECIMALS;
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

    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }
    
    function totalBurn() public view returns (uint256) {
        return _tBurnTotal;
    }

    function payTax(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
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
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function excludeAccount(address account) external onlyOwner() {
        require(account != 0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F, 'We can not exclude Pancakeswap router.');
        require(account != 0x10ED43C718714eb63d5aA57B78B54704E256024E, 'We can not exclude PancakeswapV2 router.');
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeAccount(address account) external onlyOwner() {
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

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
    
        // @dev once all cycles are completed, burn fee will be set to 0 and the protocol 
        // reaches its final phase, in which no further supply elasticity will take place
        // and fees will stay at 0 
        
        if(sender != owner() && recipient != owner())
            require(amount <= _MAX_TX_SIZE, "Transfer amount exceeds the maxTxAmount.");

        if(_BURN_FEE >= 500){
        
            _tTradeCycle = _tTradeCycle.add(amount);

            // @dev adjust current burnFee depending on the traded tokens during th

            if(_tTradeCycle >= (0 * _DECIMALFACTOR) && _tTradeCycle <= (9999999 *_DECIMALFACTOR)){
                _setBurnFee(500);
            } else if(_tTradeCycle >= (10000000 * _DECIMALFACTOR) && _tTradeCycle <= (20000000 * _DECIMALFACTOR)){
                _setBurnFee(550);
            }   else if(_tTradeCycle >= (20000000 * _DECIMALFACTOR) && _tTradeCycle <= (30000000 * _DECIMALFACTOR)){
                _setBurnFee(600);
            }   else if(_tTradeCycle >= (30000000 * _DECIMALFACTOR) && _tTradeCycle <= (40000000 * _DECIMALFACTOR)){
                _setBurnFee(650);
            } else if(_tTradeCycle >= (40000000 * _DECIMALFACTOR) && _tTradeCycle <= (50000000 * _DECIMALFACTOR)){
                _setBurnFee(700);
            } else if(_tTradeCycle >= (50000000 * _DECIMALFACTOR) && _tTradeCycle <= (60000000 * _DECIMALFACTOR)){
                _setBurnFee(750);
            } else if(_tTradeCycle >= (60000000 * _DECIMALFACTOR) && _tTradeCycle <= (70000000 * _DECIMALFACTOR)){
                _setBurnFee(800);
            } else if(_tTradeCycle >= (70000000 * _DECIMALFACTOR) && _tTradeCycle <= (80000000 * _DECIMALFACTOR)){
                _setBurnFee(850);
            } else if(_tTradeCycle >= (80000000 * _DECIMALFACTOR) && _tTradeCycle <= (90000000 * _DECIMALFACTOR)){
                _setBurnFee(900);
            } else if(_tTradeCycle >= (90000000 * _DECIMALFACTOR) && _tTradeCycle <= (100000000 * _DECIMALFACTOR)){
                _setBurnFee(950);
            } else if(_tTradeCycle >= (100000000 * _DECIMALFACTOR) && _tTradeCycle <= (110000000 * _DECIMALFACTOR)){
                _setBurnFee(1000);
            } else if(_tTradeCycle >= (110000000 * _DECIMALFACTOR) && _tTradeCycle <= (120000000 * _DECIMALFACTOR)){
                _setBurnFee(1050);
            } else if(_tTradeCycle >= (120000000 * _DECIMALFACTOR) && _tTradeCycle <= (130000000 * _DECIMALFACTOR)){
                _setBurnFee(1100);
            } else if(_tTradeCycle >= (130000000 * _DECIMALFACTOR) && _tTradeCycle <= (140000000 * _DECIMALFACTOR)){
                _setBurnFee(1150);
            } else if(_tTradeCycle >= (140000000 * _DECIMALFACTOR)){
                _setBurnFee(1200);
            }
            
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
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn) = _getValues(tAmount);
        uint256 rBurn =  tBurn.mul(currentRate);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);       
        _burnAndRebase(rFee, rBurn, tFee, tBurn);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn) = _getValues(tAmount);
        uint256 rBurn =  tBurn.mul(currentRate);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _burnAndRebase(rFee, rBurn, tFee, tBurn);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn) = _getValues(tAmount);
        uint256 rBurn =  tBurn.mul(currentRate);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _burnAndRebase(rFee, rBurn, tFee, tBurn);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn) = _getValues(tAmount);
        uint256 rBurn =  tBurn.mul(currentRate);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _burnAndRebase(rFee, rBurn, tFee, tBurn);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _burnAndRebase(uint256 rFee, uint256 rBurn, uint256 tFee, uint256 tBurn) private {
        _rTotal = _rTotal.sub(rFee).sub(rBurn);
        _tFeeTotal = _tFeeTotal.add(tFee);
        _tBurnTotal = _tBurnTotal.add(tBurn);
        _tBurnCycle = _tBurnCycle.add(tBurn);
        _tTotal = _tTotal.sub(tBurn);


        // @dev after 1,270,500 tokens burnt, supply is expanded by 637,500 tokens 
        if(_tBurnCycle >= (1275000 * _DECIMALFACTOR)){
            uint256 _tRebaseDelta = 637500 * _DECIMALFACTOR;
            _tBurnCycle = _tBurnCycle.sub((1275000 * _DECIMALFACTOR));
            _tTradeCycle = 0;
            _setBurnFee(500);
            _rebase(_tRebaseDelta);
        } 
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tBurn) = _getTValues(tAmount, _TAX_FEE, _BURN_FEE);
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tBurn, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tBurn);
    }

    function _getTValues(uint256 tAmount, uint256 taxFee, uint256 burnFee) private pure returns (uint256, uint256, uint256) {
        uint256 tFee = ((tAmount.mul(taxFee)).div(_GRANULARITY)).div(100);
        uint256 tBurn = ((tAmount.mul(burnFee)).div(_GRANULARITY)).div(100);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tBurn);
        return (tTransferAmount, tFee, tBurn);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tBurn, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rBurn = tBurn.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rBurn);
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
    

    function _setBurnFee(uint256 burnFee) private {
        require(burnFee >= 0 && burnFee <= 1500, 'burnFee should be in 0 - 15');
        _BURN_FEE = burnFee;
    }
    
    function setBurnFee(uint256 burnFee) external onlyOwner() {
        require(burnFee >= 0 && burnFee <= 1500, 'burnFee should be in 0 - 15');
        _setBurnFee(burnFee);
    }

    function setTaxFee(uint256 taxFee) external onlyOwner() {
        require(taxFee >= 0 && taxFee <= 1500, 'taxFee should be in 0 - 15');
        _TAX_FEE = taxFee;
    }

    function getTaxFee() public view returns(uint256)  {
        return _TAX_FEE;
    }

    function getBurnFee() public view returns(uint256)  {
        return _BURN_FEE;
    }

    function getMaxTxSize() private pure returns(uint256) {
        return _MAX_TX_SIZE;
    }

    function getTideCycle() public view returns(uint256) {
        return _tideCycle;
    }

    function getBurnCycle() public view returns(uint256) {
        return _tBurnCycle;
    }

    function getTradedCycle() public view returns(uint256) {
        return _tTradeCycle;
    }
    
    function _rebase(uint256 supplyDelta) internal {
        _tideCycle = _tideCycle.add(1);
        _tTotal = _tTotal.add(supplyDelta);


        // after 148, the protocol reaches its final stage
        // fees will be set to 0 and the remaining total supply will be 5,650,000
        if(_tideCycle > 148 || _tTotal <= 5650000 * _DECIMALFACTOR){
            _initializeFinalStage();
        }
    }

    function _initializeFinalStage() internal {
        _setBurnFee(0);
    } 
    

}