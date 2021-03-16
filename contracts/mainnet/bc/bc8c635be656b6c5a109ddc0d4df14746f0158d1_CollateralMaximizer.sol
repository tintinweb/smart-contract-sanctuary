/**
 *Submitted for verification at Etherscan.io on 2021-03-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

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

contract CollateralMaximizer {
    address constant private _cream = address(0x3d5BC3c8d13dcB8bF317092d84783c2697AE9258);
    address constant private _compound = address(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);
    address constant private _aavev1 = address(0x3dfd23A6c5E8BbcFc9581d2E864a68feb6a076d3);
    address constant private _aavev2 = address(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
    address constant private _ib = address(0xAB1c342C7bf5Ec5F02ADEA1c2270670bCa144CbB);
    address constant private _weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    
    uint256 constant LTV_MASK =                   0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000; // prettier-ignore
    uint256 constant LIQUIDATION_THRESHOLD_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFF; // prettier-ignore
    uint256 constant LIQUIDATION_BONUS_MASK =     0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFF; // prettier-ignore
    uint256 constant DECIMALS_MASK =              0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFF; // prettier-ignore
    uint256 constant ACTIVE_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFF; // prettier-ignore
    uint256 constant FROZEN_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFF; // prettier-ignore
    uint256 constant BORROWING_MASK =             0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFFFFFFFFFFFFFF; // prettier-ignore
    uint256 constant STABLE_BORROWING_MASK =      0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7FFFFFFFFFFFFFF; // prettier-ignore
    uint256 constant RESERVE_FACTOR_MASK =        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFF; // prettier-ignore
    
    /// @dev For the LTV, the start bit is 0 (up to 15), hence no bitshifting is needed
    uint256 constant LIQUIDATION_THRESHOLD_START_BIT_POSITION = 16;
    uint256 constant LIQUIDATION_BONUS_START_BIT_POSITION = 32;
    uint256 constant RESERVE_DECIMALS_START_BIT_POSITION = 48;
    uint256 constant IS_ACTIVE_START_BIT_POSITION = 56;
    uint256 constant IS_FROZEN_START_BIT_POSITION = 57;
    uint256 constant BORROWING_ENABLED_START_BIT_POSITION = 58;
    uint256 constant STABLE_BORROWING_ENABLED_START_BIT_POSITION = 59;
    uint256 constant RESERVE_FACTOR_START_BIT_POSITION = 64;
    
    uint256 constant MAX_VALID_LTV = 65535;
    uint256 constant MAX_VALID_LIQUIDATION_THRESHOLD = 65535;
    uint256 constant MAX_VALID_LIQUIDATION_BONUS = 65535;
    uint256 constant MAX_VALID_DECIMALS = 255;
    uint256 constant MAX_VALID_RESERVE_FACTOR = 65535;
    
    function getParamsMemory(aavecore.ReserveConfigurationMap memory self) internal pure returns (uint256) { 
        return (self.data & ~LTV_MASK);
    }
    function lookupMarket(address _core, address _token) public view returns (address) {
        if (_core == _compound && _token == _weth) {
            return 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;
        } else if (_core == _cream && _token == _weth) {
            return 0xD06527D5e56A3495252A528C4987003b712860eE;
        }
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
    function lookupMarketCompound(address _token) external view returns (address) {
        return lookupMarket(_compound, _token);
    }
    function lookupMarketCream(address _token) external view returns (address) {
        return lookupMarket(_cream, _token);
    }
    function lookupMarketIB(address _token) external view returns (address) {
        return lookupMarket(_ib, _token);
    }
    function getLTVCream(address _token) public view returns (uint cream) {
        (,cream,) = comptroller(_cream).markets(lookupMarket(_cream, _token));
        cream = cream / 1e16;
    }
    function getLTVCompound(address _token) public view returns (uint compound) {
        (,compound,) = comptroller(_compound).markets(lookupMarket(_compound, _token));
        compound = compound / 1e16;
    }
    function getLTVIB(address _token) public view returns (uint ib) {
        (,ib) = ibtroller(_ib).markets(lookupMarket(_ib, _token));
        ib = ib / 1e16;
    }
    function getLTVAaveV1(address _token) public view returns (uint aavev1) {
        (,aavev1,,) = aavecore(_aavev1).getReserveConfiguration(_token);
    }
    function getLTVAaveV2(address _token) public view returns (uint aavev2) {
        (aavev2) = getParamsMemory(aavecore(_aavev2).getConfiguration(_token));
        aavev2 = aavev2 / 1e2;
    }
    function getLTV(address _token) public view returns (uint cream, uint compound, uint ib, uint aavev1, uint aavev2) {
        cream = getLTVCream(_token);
        compound = getLTVCompound(_token);
        ib = getLTVIB(_token);
        aavev1 = getLTVAaveV1(_token);
        aavev2 = getLTVAaveV2(_token);
    }
}