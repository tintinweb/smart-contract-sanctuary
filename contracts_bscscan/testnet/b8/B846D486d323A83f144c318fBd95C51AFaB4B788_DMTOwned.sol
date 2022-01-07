pragma solidity 0.8.11;
// SPDX-License-Identifier: Unlicensed

library DMTOwned{
  
  struct Owned {
  uint256 _r;
  uint256 _t;
  bool _isExcluded ;
  bool _isWhitelisted;
}

function _burn(Owned storage owned, uint256 amount,uint256 accountBalance ) public {
        require(accountBalance >= amount, "ERC20:amount exceeds balance");
        if (owned._isExcluded){ owned._t = accountBalance - amount; }
        else { owned._r = accountBalance - amount; } 
}
function balanceOf(Owned storage owned, uint256 rate) public view returns (uint256) {
        if (owned._isExcluded) return owned._t;
        return owned._r / rate;
    }

    function includeAccount(Owned storage owned , address[] storage _excluded , address account ) public returns (address[] storage)  {
        require(owned._isExcluded, "Account already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                owned._t = 0;
                owned._isExcluded = false;
                _excluded.pop();
                break;
            }
        }
        return _excluded;
    }

function excludeAccount(Owned storage owned , address[] storage _excluded , address account, uint256 rate ) public returns (address[] storage)  {
        
        if(owned._r > 0) {
            owned._t = owned._r/rate;
        }
        owned._isExcluded = true;
        _excluded.push(account);
        return _excluded;
    }

    function _reflectBurn(Owned storage owned,uint256 tBurn , uint256 rate) public {
        owned._r = owned._r + (tBurn * rate);
        if(owned._isExcluded)
            owned._t = owned._t + tBurn;
    }

    function _reflectPerformanceFee(Owned storage owned,uint256 tPerformanceFee,uint256 rate) internal {
        //_t._tPerformancePending = _t._tPerformancePending + tPerformanceFee;
        uint256 rPerformanceFee = tPerformanceFee * rate;
        owned._r = owned._r + rPerformanceFee;
        if(owned._isExcluded)
            owned._t = owned._t + tPerformanceFee;
    }
    function _reflectLiquidity(Owned storage owned, uint256 tLiquidityFee, uint256 rate) internal {  
        //_t._tLiquidityPending += tLiquidityFee;
        uint256 rLiquidityFee = tLiquidityFee *  rate;
        owned._r +=rLiquidityFee;
        if(owned._isExcluded)
            owned._t +=tLiquidityFee;
    }
}