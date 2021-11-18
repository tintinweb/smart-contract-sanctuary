// SPDX-License-Identifier: NOLICENSE
pragma solidity ^0.8.0;

/* BTCEN Token
* fees on transfer:
* 1% rfi 
* 1% burn 
* 1% charity
*/

//"ETH" symb is used for better uniswap-core integration
//uniswap is use due to their better repo management
import "./Ownable.sol";
import "./IERC20.sol";

contract BTCEN is IERC20, Ownable {

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;

    uint8 private constant _decimals = 9;
    uint256 private constant MAX = ~uint256(0);

    uint256 private _tTotal = 333* 10**6 * 10**_decimals;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tRfiFeeTotal;
    uint256 private _tBurnFeeTotal;
    uint256 private _tCharityFeeTotal;

    address public charityAddress;

    string private constant _name = "BTCEN";
    string private constant _symbol = "BTCEN";

    struct feeRatesStruct {
      uint8 rfi;
      uint8 burn;
      uint8 charity;
    }

    feeRatesStruct public feeRates = feeRatesStruct(
     {rfi: 1,         //autoreflection rate, in %
      burn: 1,   //burn fee in %
      charity: 1  //charity fee in %
    });

    struct valuesFromGetValues{
      uint256 rAmount;
      uint256 rTransferAmount;
      uint256 rRfi;
      uint256 rBurn;
      uint256 rCharity;
      uint256 tTransferAmount;
      uint256 tRfi;
      uint256 tBurn;
      uint256 tCharity;
    }

    event FeesChanged();

    constructor () {
        _rOwned[owner()] = _rTotal;
        _isExcludedFromFee[owner()] = true;
        charityAddress= 0x9962e04AD0714F2F6f62Be831ABFB92901400D02;
        _isExcludedFromFee[charityAddress]=true;
        emit Transfer(address(0), owner(), _tTotal);
    }

    //std ERC20:
    function name() public pure returns (string memory) {
        return _name;
    }
    function symbol() public pure returns (string memory) {
        return _symbol;
    }
    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    //override ERC20:
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
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender]+addedValue);
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

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalRfiFees() public view returns (uint256) {
        return _tRfiFeeTotal;
    }

    function totalBurnFees() public view returns (uint256) {
        return _tBurnFeeTotal;
    }

    function totalCharityFees() public view returns (uint256) {
        return _tCharityFeeTotal;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferRfi) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferRfi) {
            valuesFromGetValues memory s = _getValues(tAmount, true);
            return s.rAmount;
        } else {
            valuesFromGetValues memory s = _getValues(tAmount, true);
            return s.rTransferAmount;
        }
    }


    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount/currentRate;
    }

    //@dev kept original RFI naming -> "reward" as in reflection
    function excludeFromReward(address account) public onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is not excluded");
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


    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function setFeeRates(uint8 _rfi, uint8 _burn, uint8 _charity) public onlyOwner {
      feeRates.rfi = _rfi;
      feeRates.burn = _burn;
      feeRates.charity = _charity;
      emit FeesChanged();
    }

    function _reflectRfi(uint256 rRfi, uint256 tRfi) private {
        _rTotal -=  rRfi;
        _tRfiFeeTotal += tRfi;
    }

    function _takeBurn(uint256 rBurn, uint256 tBurn) private {
        _tBurnFeeTotal+= tBurn;
        _tTotal -= tBurn;
        _rTotal -= rBurn;
    }

    function _takeCharity(uint256 rCharity, uint256 tCharity) private {
        _tCharityFeeTotal+=tCharity;
        if(_isExcluded[charityAddress])
        {
            _tOwned[charityAddress]+= tCharity;
        }
        _rOwned[charityAddress] += rCharity;
    }

    function _getValues(uint256 tAmount, bool takeFee) private view returns (valuesFromGetValues memory to_return) {
        to_return = _getTValues(tAmount, takeFee);
        (to_return.rAmount, to_return.rTransferAmount, to_return.rRfi,to_return.rBurn, to_return.rCharity) = _getRValues(to_return, tAmount, takeFee, _getRate());
        return to_return;
    }

    function _getTValues(uint256 tAmount, bool takeFee) private view returns (valuesFromGetValues memory s) {

        if(!takeFee) {
          s.tTransferAmount = tAmount;
          return s;
        }
        s.tRfi = tAmount*feeRates.rfi/100;
        s.tBurn = tAmount*feeRates.burn/100;
        s.tCharity = tAmount*feeRates.charity/100;
        s.tTransferAmount = tAmount-s.tRfi-s.tBurn-s.tCharity;
        return s;
    }

    function _getRValues(valuesFromGetValues memory s, uint256 tAmount, bool takeFee, uint256 currentRate) private pure returns (uint256 rAmount, uint256 rTransferAmount, uint256 rRfi, uint256 rBurn,uint256 rCharity) {
        rAmount = tAmount*currentRate;

        if(!takeFee) {
          return(rAmount, rAmount, 0,0,0);
        }

        rRfi = s.tRfi*currentRate;
        rBurn = s.tBurn*currentRate;
        rCharity = s.tCharity*currentRate;
        rTransferAmount =  rAmount-rRfi-rBurn-rCharity;
        return (rAmount, rTransferAmount, rRfi,rBurn,rCharity);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply/tSupply;
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply-_rOwned[_excluded[i]];
            tSupply = tSupply-_tOwned[_excluded[i]];
        }
        if (rSupply < _rTotal/_tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }


    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(amount <= balanceOf(from),"You are trying to transfer more than your balance");
        _tokenTransfer(from, to, amount, !(_isExcludedFromFee[from] || _isExcludedFromFee[to]));
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 tAmount, bool takeFee) private {

        valuesFromGetValues memory s = _getValues(tAmount, takeFee);

        if (_isExcluded[sender]) {
            _tOwned[sender] -= tAmount;
        } 
        if (_isExcluded[recipient]) {
            _tOwned[recipient] += s.tTransferAmount;
        }

        _rOwned[sender] -= s.rAmount;
        _rOwned[recipient] += s.rTransferAmount;
        if(takeFee)
        {
         _takeCharity(s.rCharity,s.tCharity);
         _reflectRfi(s.rRfi, s.tRfi);
         _takeBurn(s.rBurn,s.tBurn);
         emit Transfer(sender, address(0), s.tBurn);
         emit Transfer(sender, charityAddress, s.tCharity);
        }
        
        emit Transfer(sender, recipient, s.tTransferAmount);

    }
}