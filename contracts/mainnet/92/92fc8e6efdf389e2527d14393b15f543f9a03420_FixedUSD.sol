/**
 *Submitted for verification at Etherscan.io on 2021-07-02
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

library Math {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function decimals() external view returns (uint256);
    function symbol() external view returns (string memory);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface Oracle {
    struct ReferenceData {
        uint256 rate; // base/quote exchange rate, multiplied by 1e18.
        uint256 lastUpdatedBase; // UNIX epoch of the last time when base price gets updated.
        uint256 lastUpdatedQuote; // UNIX epoch of the last time when quote price gets updated.
    }
    
    function getReferenceData(string memory _base, string memory _quote)
        external
        view
        returns (ReferenceData memory);
}

interface cToken {
    function underlying() external view returns (address);
}

interface comptroller {
    function getAllMarkets() external view returns (address[] memory);
    function markets(address _market) external view returns (bool isListed, uint256 collateralFactorMantissa, bool isComped);
}

interface ibtroller {
    function getAllMarkets() external view returns (address[] memory);
    function markets(address _market) external view returns (bool isListed, uint256 collateralFactorMantissa);
}

interface aavecore {
    struct ReserveConfigurationMap {
        //bit 0-15: LTV
        //bit 16-31: Liq. threshold
        //bit 32-47: Liq. bonus
        //bit 48-55: Decimals
        //bit 56: Reserve is active
        //bit 57: reserve is frozen
        //bit 58: borrowing is enabled
        //bit 59: stable rate borrowing enabled
        //bit 60-63: reserved
        //bit 64-79: reserve factor
        uint256 data;
    }
    function getReserveConfiguration(address _market) external view returns (uint, uint, uint, bool);
    function getConfiguration(address _market) external view returns (ReserveConfigurationMap memory);
}

interface vaultparams {
    function initialCollateralRatio(address _token) external view returns (uint);
}

interface SushiswapV2Router02 {
    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
}

contract FixedUSD {
    string public constant name = "Fixed USD";
    string public constant symbol = "USDF";
    uint8 public constant decimals = 18;
    
    address constant _oracle = 0xDA7a001b254CD22e46d3eAB04d937489c93174C3;
    address constant _stable = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant _router = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    string constant _quote = "USD";
    
    uint constant _BASE = 100;
    uint constant _LIQUIDITY_THRESHOLD = 5;
    uint constant _LIQUIDATION_VALUE = 90;
    uint constant _CACHE = 1 days;
    uint constant _minLiquidity = 500000e18;
    
    /// @notice Total number of tokens in circulation
    uint public totalSupply = 0;
    
    mapping(address => mapping (address => uint)) internal allowances;
    mapping(address => uint) internal balances;
    
    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);
    
    mapping(address => mapping(address => uint)) public credit;
    mapping(address => mapping(address => uint)) public collateral;
    
    mapping(address => uint) public credits;
    mapping(address => uint) public collaterals;
    
    mapping(address => uint) public ltvs;
    mapping(address => uint) _ltvCaches;
    
    mapping(address => uint) public liquidities;
    mapping(address => uint) _liquidityCaches;
    
    mapping(address => uint) public fallbackQuote;
    
    uint public arb;
    
    event Mint(address indexed from, address indexed asset, address indexed to, uint amount);
    event Burn(address indexed from, address indexed asset, address indexed to, uint amount);
    event Liquidate(address indexed from, address indexed asset, address indexed to, uint amount);
    
    
    function validateLTV(uint __ltv) public pure returns (bool) {
        if ((__ltv == 60) || (__ltv == 65) || (__ltv == 70) || (__ltv == 75)) {
            return true;
        } else if ((__ltv == 80) || (__ltv == 85) || __ltv >= 90) {
            return true;
        } else {
            return false;
        }
    }
    
    function gentleRepaymentCalculator(uint __ltv, uint debt, uint value) public pure returns (uint repayment) {
        if (__ltv == 60) {
            return Math.min((debt - value) * 310 / _BASE, debt);
        } else if (__ltv == 65) {
            return Math.min((debt - value) * 370 / _BASE, debt);
        } else if (__ltv == 70) {
            return Math.min((debt - value) * 460 / _BASE, debt);
        } else if (__ltv == 75) {
            return Math.min((debt - value) * 610 / _BASE, debt);
        } else if (__ltv == 80) {
            return Math.min((debt - value) * 910 / _BASE, debt);
        } else if (__ltv == 85) {
            return Math.min((debt - value) * 1810 / _BASE, debt);
        } else if (__ltv >= 90) {
            return debt;
        }
    }
    
    function _lookup(address quoted, uint amount) internal returns (uint) {
        uint _quoted = Oracle(_oracle).getReferenceData(IERC20(quoted).symbol(), _quote).rate;
        if (_quoted == 0 && fallbackQuote[quoted] != 0) {
            _quoted = fallbackQuote[quoted];
        } else {
            fallbackQuote[quoted] = _quoted;
        }
        return  _quoted * (amount * _ltv(quoted) / _BASE) / 10 ** IERC20(quoted).decimals();
    }
    
    function lookup(address quoted, uint amount) public view returns (uint) {
        uint _quoted = Oracle(_oracle).getReferenceData(IERC20(quoted).symbol(), _quote).rate;
        if (_quoted == 0 && fallbackQuote[quoted] != 0) {
            _quoted = fallbackQuote[quoted];
        }
        return _quoted * (amount * ltvs[quoted] / _BASE) / 10 ** IERC20(quoted).decimals();
    }
    
    function lookup(address quoted) external view returns (uint) {
        return Oracle(_oracle).getReferenceData(IERC20(quoted).symbol(), _quote).rate;
    }
    
    function lookupLiq(address quoted, uint amount) public view returns (uint) {
        return Oracle(_oracle).getReferenceData(IERC20(quoted).symbol(), _quote).rate * (amount * _LIQUIDATION_VALUE / _BASE) / 10 ** IERC20(quoted).decimals();
    }
    
    function mintArb(uint amount) external {
        _mintArb(amount, msg.sender);
    }
    
    function mintArb(uint amount, address recipient) external {
        _mintArb(amount, recipient);
    }
    
    function _mintArb(uint amount, address recipient) internal {
        _safeTransferFrom(_stable, msg.sender, address(this), amount);
        _mint(recipient, amount);
        arb += amount;
        emit Mint(msg.sender, _stable, recipient, amount);
    }
    
    function burnArb(uint amount) external {
        _burnArb(amount, msg.sender);
    }
    
    function burnArb(uint amount, address recipient) external {
        _burnArb(amount, recipient);
    }
    
    function _burnArb(uint amount, address recipient) internal {
        _burn(msg.sender, amount);
        _safeTransfer(_stable, recipient, amount);
        arb -= amount;
        emit Burn(msg.sender, _stable, recipient, amount);
    }
    
    function mint(address asset, uint amount, uint minted) external {
        _mint(asset, amount, minted, msg.sender);
    }
    
    function mint(address asset, uint amount, uint minted, address recipient) external {
        _mint(asset, amount, minted, recipient);
    }
    
    function _mint(address asset, uint amount, uint minted, address recipient) internal {
        if (amount > 0) {
            _safeTransferFrom(asset, msg.sender, address(this), amount);
        }
        
        collateral[msg.sender][asset] += amount;
        collaterals[asset] += amount;
        
        credit[msg.sender][asset] += minted;
        credits[asset] += minted;
        
        require(_liquidity(asset, collaterals[asset]) >= credits[asset]);
        require(_lookup(asset, collateral[msg.sender][asset]) >= credit[msg.sender][asset]);
        _mint(recipient, minted);
        emit Mint(msg.sender, asset, recipient, amount);
    }
    
    function burn(address asset, uint amount, uint burned) external {
        _burn(asset, amount, burned, msg.sender);
    }
    
    function burn(address asset, uint amount, uint burned, address recipient) external {
        _burn(asset, amount, burned, recipient);
    }
    
    function _burn(address asset, uint amount, uint burned, address recipient) internal {
        _burn(msg.sender, burned);
        
        credit[msg.sender][asset] -= burned;
        credits[asset] -= burned;
        collateral[msg.sender][asset] -= amount;
        collaterals[asset] -= amount;
        
        require(lookup(asset, collateral[msg.sender][asset]) >= credit[msg.sender][asset]);
        
        if (amount > 0) {
            _safeTransfer(asset, recipient, amount);
        }
        emit Burn(msg.sender, asset, recipient, amount);
    }
    
    function repaymentCalculator(address owner, address asset) external view returns (uint) {
        uint _nominal = collateral[owner][asset];
        
        uint _backed = lookup(asset, _nominal);
        uint _debt = credit[owner][asset];
        if (_backed < _debt) {
            return gentleRepaymentCalculator(ltvs[asset], _debt, _backed);
        } else {
            return 0;
        }
    }
    
    function paymentCalculator(address owner, address asset) external view returns (uint) {
        uint _nominal = collateral[owner][asset];
        
        uint _backed = lookup(asset, _nominal);
        uint _debt = credit[owner][asset];
        if (_backed < _debt) {
            uint _repayment = gentleRepaymentCalculator(ltvs[asset], _debt, _backed);
            return Math.min(_nominal * _repayment / lookupLiq(asset, _nominal), _nominal);
        } else {
            return 0;
        }
    }
    
    function liquidate(address owner, address asset, uint max) external {
        uint _nominal = collateral[owner][asset];
        
        uint _backed = _lookup(asset, _nominal);
        uint _debt = credit[owner][asset];
        require(_backed < _debt);
        
        uint _repayment = gentleRepaymentCalculator(_ltv(asset), _debt, _backed);
        require(_repayment <= max);
        uint _payment = Math.min(_nominal * _repayment / lookupLiq(asset, _nominal), _nominal);
        
        _burn(msg.sender, _repayment);
        
        credit[owner][asset] -= _repayment;
        credits[asset] -= _repayment;
        collateral[owner][asset] -= _payment;
        collaterals[asset] -= _payment;
        
        require(_lookup(asset, collateral[owner][asset]) >= credit[owner][asset]);
        
        _safeTransfer(asset, msg.sender, _payment);
        emit Liquidate(msg.sender, asset, owner, _repayment);
    }
    
    function _mint(address dst, uint amount) internal {
        // mint the amount
        totalSupply += amount;
        // transfer the amount to the recipient
        balances[dst] += amount;
        emit Transfer(address(0), dst, amount);
    }
    
    function _burn(address dst, uint amount) internal {
        // burn the amount
        totalSupply -= amount;
        // transfer the amount from the recipient
        balances[dst] -= amount;
        emit Transfer(dst, address(0), amount);
    }
    
    function allowance(address account, address spender) external view returns (uint) {
        return allowances[account][spender];
    }

    function approve(address spender, uint amount) external returns (bool) {
        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function balanceOf(address account) external view returns (uint) {
        return balances[account];
    }

    function transfer(address dst, uint amount) external returns (bool) {
        _transferTokens(msg.sender, dst, amount);
        return true;
    }

    function transferFrom(address src, address dst, uint amount) external returns (bool) {
        address spender = msg.sender;
        uint spenderAllowance = allowances[src][spender];

        if (spender != src && spenderAllowance != type(uint).max) {
            uint newAllowance = spenderAllowance - amount;
            allowances[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }

    function _transferTokens(address src, address dst, uint amount) internal {
        balances[src] -= amount;
        balances[dst] += amount;
        
        emit Transfer(src, dst, amount);
    }
    
    function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
    
    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
    
    address constant _aavev2 = address(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
    address constant _ib = address(0xAB1c342C7bf5Ec5F02ADEA1c2270670bCa144CbB);
    address constant _unit = address(0x203153522B9EAef4aE17c6e99851EE7b2F7D312E);
    address constant _weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    
    uint256 constant _LTV_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000;
    
    function _getParamsMemory(aavecore.ReserveConfigurationMap memory self) internal pure returns (uint256) { 
        return (self.data & ~_LTV_MASK);
    }
    
    function _lookupMarket(address _core, address _token) internal view returns (address) {
        address[] memory _list = comptroller(_core).getAllMarkets();
        for (uint i = 0; i < _list.length; i++) {
            if (_list[i] != address(0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5) && _list[i] != address(0xD06527D5e56A3495252A528C4987003b712860eE)) {
                if (cToken(_list[i]).underlying() == _token) {
                    return _list[i];
                }
            }
        }
        return address(0x0);
    }
    
    function _liquidityV(address token, uint amount) internal view returns (uint, bool) {
        if (block.timestamp > _liquidityCaches[token]) {
            if (token == _weth) {
                return (_liquidityVWETH(amount), true);
            } else {
                address[] memory _path = new address[](3);
                _path[0] = token;
                _path[1] = _weth;
                _path[2] = _stable;
                uint _liq = SushiswapV2Router02(_router).getAmountsOut(amount, _path)[2];
                uint _liquid = liquidities[token];
                if (_liq > _liquid) {
                    _liquid += _liquid * _LIQUIDITY_THRESHOLD / _BASE;
                    _liq = Math.min(_liq, _liquid);
                    _liq = _liq < _minLiquidity ? _minLiquidity : _liq;
                }
                return (_liq, true);
            }
        } else {
            return (liquidities[token], false);
        }
    }
    
    function _liquidityVWETH(uint amount) internal view returns (uint) {
        address[] memory _path = new address[](2);
        _path[0] = _weth;
        _path[1] = _stable;
        uint _liq = SushiswapV2Router02(_router).getAmountsOut(amount, _path)[1];
        uint _liquid = liquidities[_weth];
        if (_liq > _liquid) {
            _liquid += _liquid * _LIQUIDITY_THRESHOLD / _BASE;
            _liq = Math.min(_liq, _liquid);
            _liq = _liq < _minLiquidity ? _minLiquidity : _liq;
        }
        return _liq;
    }
    
    function _liquidity(address token, uint amount) internal returns (uint) {
        if (_liquidityCaches[token] == 0) {
            liquidities[token] = _minLiquidity;
        }
        (uint _val, bool _updated) = _liquidityV(token, amount);
        if (_updated) {
            _liquidityCaches[token] = block.timestamp + _CACHE;
            liquidities[token] = _val;
        }
        return _val;
    }
    
    function liquidity(address token, uint amount) external view returns (uint val) {
        (val,) = _liquidityV(token, amount);
    }
    
    function _getLTVIB(address token) internal view returns (uint ib) {
        (,ib) = ibtroller(_ib).markets(_lookupMarket(_ib, token));
        ib = ib / 1e16;
    }
    
    function _getLTVUnit(address _token) internal view returns (uint unit) {
        unit = vaultparams(_unit).initialCollateralRatio(_token);
    }
    
    function _getLTVAaveV2(address token) internal view returns (uint aavev2) {
        (aavev2) = _getParamsMemory(aavecore(_aavev2).getConfiguration(token));
        aavev2 = aavev2 / 1e2;
    }
    
    function _ltv(address token) internal returns (uint) {
        (uint _val, bool _updated) = _ltvV(token);
        if (_updated) {
            _ltvCaches[token] = block.timestamp + _CACHE;
            ltvs[token] = _val;
        }
        return _val;
    }
    
    function ltv(address token) external view returns (uint val) {
        (val,) = _ltvV(token);
    }
    
    function _ltvV(address token) internal view returns (uint, bool) {
        if (block.timestamp > _ltvCaches[token]) {
            uint _max = 0;
            uint _tmp =  _getLTVIB(token);
            if (_tmp > _max) {
                _max = _tmp;
            }
            _tmp = _getLTVAaveV2(token);
            if (_tmp > _max) {
                _max = _tmp;
            }
            _tmp = _getLTVUnit(token);
            if (_tmp > _max) {
                _max = _tmp;
            }
            _max = _max / 5 * 5;
            if (_max < 60) {
                _max = 0;
            }
            return (_max, true);
        } else {
            return (ltvs[token], false);
        }
    }
}