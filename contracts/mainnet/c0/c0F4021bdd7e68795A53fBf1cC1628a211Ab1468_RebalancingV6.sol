// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "./IO.sol";
import "./Storage.sol";
import "./Constants.sol";

import "./IveCurveVault.sol";
import "./IOneInch.sol";
import "./ICurve.sol";
import "./IATokenV1.sol";
import "./ICToken.sol";
import "./IComptroller.sol";
import "./ISushiBar.sol";
import "./ILendingPoolV1.sol";
import "./ICompoundLens.sol";
import "./IYearn.sol";
import "./IKNC.sol";

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";


contract RebalancingV6 is Storage, Constants, IO {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // Match
    address constant ZERO_X = 0xDef1C0ded9bec7F1a1670819833240f027b25EfF;

    // 1inch
    address constant ONE_INCH = 0x11111112542D85B3EF69AE05771c2dCCff4fAa26;

    // Aave
    address constant LENDING_POOL_V1 = 0x398eC7346DcD622eDc5ae82352F02bE94C62d119;
    address constant LENDING_POOL_CORE_V1 = 0x3dfd23A6c5E8BbcFc9581d2E864a68feb6a076d3;

    // Sushi
    address constant XSUSHI = 0x8798249c2E607446EfB7Ad49eC89dD1865Ff4272;

    // Curve
    address constant CURVE_LINK = 0xF178C0b5Bb7e7aBF4e12A4838C7b7c5bA2C623c0;

    // CTokens
    address constant CUNI = 0x35A18000230DA775CAc24873d00Ff85BccdeD550;
    address constant CCOMP = 0x70e36f6BF80a52b3B46b3aF8e106CC0ed743E8e4;

    // ATokens v1
    address constant AYFIv1 = 0x12e51E77DAAA58aA0E9247db7510Ea4B46F9bEAd;
    address constant ASNXv1 = 0x328C4c80BC7aCa0834Db37e6600A6c49E12Da4DE;
    address constant AMKRv1 = 0x7deB5e830be29F91E298ba5FF1356BB7f8146998;
    address constant ARENv1 = 0x69948cC03f478B95283F7dbf1CE764d0fc7EC54C;
    address constant AKNCv1 = 0x9D91BE44C06d373a8a226E1f3b146956083803eB;

    // Yearn tokens
    address constant yvCurveLink = 0xf2db9a7c0ACd427A680D640F02d90f6186E71725;
    address constant yveCRV = 0xc5bDdf9843308380375a611c18B50Fb9341f502A;
    address constant yvBOOST = 0x9d409a0A012CFbA9B15F6D4B36Ac57A46966Ab9a;
    address constant yvUNI = 0xFBEB78a723b8087fD2ea7Ef1afEc93d35E8Bed42;
    address constant yvYFI = 0xE14d13d8B3b85aF791b2AADD661cDBd5E6097Db1;
    address constant yvSNX = 0xF29AE508698bDeF169B89834F76704C3B205aedf;

    // Curve Tokens
    address constant linkCRV = 0xcee60cFa923170e4f8204AE08B4fA6A3F5656F3a;
    address constant gaugeLinkCRV = 0xFD4D8a17df4C27c1dD245d153ccf4499e806C87D;

    // Underlyings
    address constant LINK = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
    address constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address constant UNI = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
    address constant COMP = 0xc00e94Cb662C3520282E6f5717214004A7f26888;
    address constant YFI = 0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e;
    address constant SNX = 0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F;
    address constant MKR = 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2;
    address constant REN = 0x408e41876cCCDC0F92210600ef50372656052a38;
    address constant KNC_LEGACY = 0xdd974D5C2e2928deA5F71b9825b8b646686BD200;
    address constant KNC = 0xdeFA4e8a7bcBA345F687a2f1456F5Edd9CE97202;
    address constant LRC = 0xBBbbCA6A901c926F240b89EacB641d8Aec7AEafD;
    address constant BAL = 0xba100000625a3754423978a60c9317c58a424e3D;
    address constant AAVE = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;
    address constant MTA = 0xa3BeD4E1c75D00fa6f4E5E6922DB7261B5E9AcD2;
    address constant SUSHI = 0x6B3595068778DD592e39A122f4f5a5cF09C90fE2;
    address constant ZRX = 0xE41d2489571d322189246DaFA5ebDe1F4699F498;

    // **** Rebalance ****

    function rebalance(
        address _from,
        address _to,
        uint256 _amount,
        uint256 _minRecvAmount,
        address _aggregator,
        bytes calldata _data
    ) external returns (uint256) {
        assert(_aggregator == ZERO_X || _aggregator == ONE_INCH);
        _requireAssetData(_from);

        // Limit number of 'to' assets
        require(_hasAssetData(_to), "!to");

        address fromUnderlying = _from;
        uint256 fromUnderlyingAmount = _amount;

        address toUnderlying = _getUnderlying(_to);

        // Unwrap to underlying
        if (_isCToken(_from)) {
            (fromUnderlying, fromUnderlyingAmount) = _fromCToken(_from, _amount);
        } else if (_isATokenV1(_from)) {
            (fromUnderlying, fromUnderlyingAmount) = _fromATokenV1(_from, _amount);
        } else if (_isYearnV2(_from)) {
            (fromUnderlying, fromUnderlyingAmount) = _fromYearnV2Vault(_from, _amount);
        } else if (_from == yvCurveLink) {
            (, fromUnderlyingAmount) = _fromYearnV2Vault(_from, _amount);
            (fromUnderlying, fromUnderlyingAmount) = _fromLinkCRV(fromUnderlyingAmount);
        } else if (_from == linkCRV) {
            // Unwrap from CURVE to LINK
            (fromUnderlying, fromUnderlyingAmount) = _fromLinkCRV(_amount);
        } else if (_from == XSUSHI) {
            (fromUnderlying, fromUnderlyingAmount) = _fromXSushi(_amount);
        } else if (_from == yveCRV) {
            // Wrap to BOOST and then swap cuz there's more liquidity that way
            (fromUnderlying, fromUnderlyingAmount) = _toYveBoost(_amount);
        }

        uint256 _before = IERC20(toUnderlying).balanceOf(address(this));

        IERC20(fromUnderlying).safeApprove(_aggregator, 0);
        IERC20(fromUnderlying).safeApprove(_aggregator, fromUnderlyingAmount);
        (bool success, ) = _aggregator.call(_data);
        require(success, "!swap");

        // Re-wrap to derivative
        uint256 _after = IERC20(toUnderlying).balanceOf(address(this));
        uint256 _toAmount = _after.sub(_before);
        require(_toAmount >= _minRecvAmount, "!min-amount");

        if (_isCToken(_to)) {
            _toCToken(toUnderlying, _toAmount);
        } else if (_isATokenV1(_to)) {
            _toATokenV1(toUnderlying, _toAmount);
        } else if (_isYearnV2(_to)) {
            _toYearnV2Vault(_to, _toAmount);
        } else if (_to == XSUSHI) {
            _toXSushi(_toAmount);
        } else if (_to == yveCRV) {
            // Should have CRV
            _toYveCRV(_toAmount);
        } else if (_to == linkCRV) {
            _toLinkCRV(_toAmount);
        } else if (_to == yvBOOST) {
            (, _toAmount) = _toYveCRV(_toAmount);
            _toYveBoost(_toAmount);
        } else if (_to == yvCurveLink) {
            (, _toAmount) = _toLinkCRV(_toAmount);
            _toYearnV2Vault(yvCurveLink, _toAmount);
        }
    }

    function migrateKNC() external {
        _requireAssetData(KNC_LEGACY);
        uint256 _balance = IERC20(KNC_LEGACY).balanceOf(address(this));
        IERC20(KNC_LEGACY).approve(KNC, _balance);
        IKNC(KNC).mintWithOldKnc(_balance);
        _overrideAssetData(KNC_LEGACY, KNC);
    }

    // **** Internal ****

    /// @notice Supplies assets to the Compound market
    /// @param  _token  Underlying token to supply to Compound
    function _toCToken(address _token, uint256 _amount) internal returns (address, uint256) {
        address _ctoken = _getTokenToCToken(_token);
        uint256 _before = IERC20(_ctoken).balanceOf(address(this));

        IERC20(_token).safeApprove(_ctoken, 0);
        IERC20(_token).safeApprove(_ctoken, _amount);
        require(ICToken(_ctoken).mint(_amount) == 0, "!ctoken-mint");

        uint256 _after = IERC20(_ctoken).balanceOf(address(this));

        return (_ctoken, _after.sub(_before));
    }

    /// @notice Redeems assets from the Compound market
    /// @param  _ctoken  CToken to redeem from Compound
    function _fromCToken(address _ctoken, uint256 _amount) internal returns (address, uint256) {
        address _token = ICToken(_ctoken).underlying();
        uint256 _before = IERC20(_token).balanceOf(address(this));
        require(ICToken(_ctoken).redeem(_amount) == 0, "!ctoken-redeem");
        uint256 _after = IERC20(_token).balanceOf(address(this));
        return (_token, _after.sub(_before));
    }

    /// @notice Supplies assets to the Aave market
    /// @param  _token  Underlying to supply to Aave
    function _toATokenV1(address _token, uint256 _amount) internal returns (address, uint256) {
        (, , , , , , , , , , , address _atoken, ) = ILendingPoolV1(LENDING_POOL_V1).getReserveData(_token);
        uint256 _before = IERC20(_atoken).balanceOf(address(this));
        IERC20(_token).safeApprove(LENDING_POOL_CORE_V1, 0);
        IERC20(_token).safeApprove(LENDING_POOL_CORE_V1, _amount);
        ILendingPoolV1(LENDING_POOL_V1).deposit(_token, _amount, 0);

        // Redirect Interest
        address feeRecipient = _readSlotAddress(FEE_RECIPIENT);
        require(feeRecipient != address(0), "!fee-recipient");

        if (feeRecipient != IATokenV1(_atoken).getInterestRedirectionAddress(address(this))) {
            IATokenV1(_atoken).redirectInterestStream(feeRecipient);
        }

        uint256 _after = IERC20(_atoken).balanceOf(address(this));

        return (_atoken, _after.sub(_before));
    }

    /// @notice Redeems assets from the Aave market
    /// @param  _atoken  AToken to redeem from Aave
    function _fromATokenV1(address _atoken, uint256 _amount) internal returns (address, uint256) {
        address _token = IATokenV1(_atoken).underlyingAssetAddress();
        uint256 _before = IERC20(_token).balanceOf(address(this));
        IATokenV1(_atoken).redeem(_amount);
        uint256 _after = IERC20(_token).balanceOf(address(this));
        return (_token, _after.sub(_before));
    }

    /// @notice Converts sushi to xsushi
    function _toXSushi(uint256 _amount) internal returns (address, uint256) {
        uint256 _before = ISushiBar(XSUSHI).balanceOf(address(this));
        IERC20(SUSHI).safeApprove(XSUSHI, 0);
        IERC20(SUSHI).safeApprove(XSUSHI, _amount);
        ISushiBar(XSUSHI).enter(_amount);
        uint256 _after = ISushiBar(XSUSHI).balanceOf(address(this));
        return (XSUSHI, _after.sub(_before));
    }

    /// @notice Goes from xsushi to sushi
    function _fromXSushi(uint256 _amount) internal returns (address, uint256) {
        uint256 _before = IERC20(SUSHI).balanceOf(address(this));
        ISushiBar(XSUSHI).leave(_amount);
        uint256 _after = IERC20(SUSHI).balanceOf(address(this));
        return (SUSHI, _after.sub(_before));
    }

    /// @notice Converts link to linkCRV
    function _toLinkCRV(uint256 _amount) internal returns (address, uint256) {
        // Deposit into gauge
        uint256 _before = IERC20(linkCRV).balanceOf(address(this));
        IERC20(LINK).safeApprove(CURVE_LINK, 0);
        IERC20(LINK).safeApprove(CURVE_LINK, _amount);
        ICurveLINK(CURVE_LINK).add_liquidity([_amount, uint256(0)], 0);
        uint256 _after = IERC20(linkCRV).balanceOf(address(this));
        return (linkCRV, _after.sub(_before));
    }

    /// @notice Converts linkCRV to GaugeLinkCRV
    function _toGaugeLinkCRV(uint256 _amount) internal returns (address, uint256) {
        // Deposit into gauge
        uint256 _before = IERC20(gaugeLinkCRV).balanceOf(address(this));
        IERC20(linkCRV).safeApprove(gaugeLinkCRV, 0);
        IERC20(linkCRV).safeApprove(gaugeLinkCRV, _amount);
        ILinkGauge(gaugeLinkCRV).deposit(_amount);
        uint256 _after = IERC20(gaugeLinkCRV).balanceOf(address(this));
        return (gaugeLinkCRV, _after.sub(_before));
    }

    /// @notice Converts GaugeLinkCRV to linkCRV
    function _fromGaugeLinkCRV(uint256 _amount) internal returns (address, uint256) {
        // Deposit into gauge
        uint256 _before = IERC20(linkCRV).balanceOf(address(this));
        ILinkGauge(gaugeLinkCRV).withdraw(_amount);
        uint256 _after = IERC20(linkCRV).balanceOf(address(this));
        return (linkCRV, _after.sub(_before));
    }

    /// @notice Converts linkCRV to link
    function _fromLinkCRV(uint256 _amount) internal returns (address, uint256) {
        uint256 _before = IERC20(LINK).balanceOf(address(this));
        ICurveLINK(CURVE_LINK).remove_liquidity_one_coin(_amount, 0, 0);
        uint256 _after = IERC20(LINK).balanceOf(address(this));
        return (linkCRV, _after.sub(_before));
    }

    /// @notice Converts from crv to yveCRV
    function _toYveCRV(uint256 _amount) internal returns (address, uint256) {
        uint256 _before = IERC20(yveCRV).balanceOf(address(this));
        IERC20(CRV).safeApprove(yveCRV, 0);
        IERC20(CRV).safeApprove(yveCRV, _amount);
        IveCurveVault(yveCRV).deposit(_amount);
        uint256 _after = IERC20(yveCRV).balanceOf(address(this));
        return (yveCRV, _after.sub(_before));
    }

    /// @notice Converts from yveCRV to yvBOOST
    function _toYveBoost(uint256 _amount) internal returns (address, uint256) {
        uint256 _before = IERC20(yvBOOST).balanceOf(address(this));
        IERC20(yveCRV).safeApprove(yvBOOST, 0);
        IERC20(yveCRV).safeApprove(yvBOOST, _amount);
        IYearn(yvBOOST).deposit(_amount);
        uint256 _after = IERC20(yvBOOST).balanceOf(address(this));
        return (yvBOOST, _after.sub(_before));
    }

    /// @notice Converts from yveCRV to yvBOOST
    function _fromYveBoost(uint256 _amount) internal returns (address, uint256) {
        uint256 _before = IERC20(yveCRV).balanceOf(address(this));
        IYearn(yvBOOST).withdraw(_amount);
        uint256 _after = IERC20(yveCRV).balanceOf(address(this));
        return (yveCRV, _after.sub(_before));
    }

    /// @notice Converts to Yearn Vault
    function _toYearnV2Vault(address _vault, uint256 _amount) internal returns (address, uint256) {
        address _underlying = IYearn(_vault).token();
        uint256 _before = IERC20(_vault).balanceOf(address(this));
        IERC20(_underlying).safeApprove(_vault, 0);
        IERC20(_underlying).safeApprove(_vault, _amount);
        IYearn(_vault).deposit(_amount);
        uint256 _after = IERC20(_vault).balanceOf(address(this));
        return (_vault, _after.sub(_before));
    }

    /// @notice Converts from Yearn Vault
    function _fromYearnV2Vault(address _vault, uint256 _amount) internal returns (address, uint256) {
        address _underlying = IYearn(_vault).token();
        uint256 _before = IERC20(_underlying).balanceOf(address(this));
        IYearn(_vault).withdraw(_amount);
        uint256 _after = IERC20(_underlying).balanceOf(address(this));
        return (_underlying, _after.sub(_before));
    }

    /// @dev Token to CToken mapping
    /// @param  _token Token address
    function _getTokenToCToken(address _token) internal pure returns (address) {
        if (_token == UNI) {
            return CUNI;
        }
        if (_token == COMP) {
            return CCOMP;
        }
        revert("!supported-token-to-ctoken");
    }

    /// @dev Get wrapped token underlying
    /// @param  _derivative Derivative token address
    function _getUnderlying(address _derivative) internal pure returns (address) {
        if (_derivative == CUNI) {
            return UNI;
        }

        if (_derivative == CCOMP) {
            return COMP;
        }

        if (_derivative == XSUSHI) {
            return SUSHI;
        }

        if (_derivative == AYFIv1) {
            return YFI;
        }

        if (_derivative == ASNXv1) {
            return SNX;
        }

        if (_derivative == AMKRv1) {
            return MKR;
        }

        if (_derivative == ARENv1) {
            return REN;
        }

        if (_derivative == AKNCv1) {
            return KNC_LEGACY;
        }

        if (_derivative == yveCRV || _derivative == yvBOOST) {
            return CRV;
        }

        if (_derivative == linkCRV || _derivative == yvCurveLink) {
            return LINK;
        }

        if (_derivative == yvUNI) {
            return UNI;
        }

        if (_derivative == yvYFI) {
            return YFI;
        }

        if (_derivative == yvSNX) {
            return SNX;
        }

        return _derivative;
    }

    function _isCToken(address _token) internal pure returns (bool) {
        return (_token == CUNI || _token == CCOMP);
    }

    function _isATokenV1(address _token) internal pure returns (bool) {
        return (_token == AYFIv1 || _token == ASNXv1 || _token == AMKRv1 || _token == ARENv1 || _token == AKNCv1);
    }

    function _isYearnV2(address _token) internal pure returns (bool) {
        return (_token == yvYFI || _token == yvUNI || _token == yvSNX);
    }

    /// @dev Requires `_from` to be present in the `assets` variable in `Storage.sol`
    /// @param  _from Token address
    function _hasAssetData(address _from) internal view returns (bool) {
        for (uint256 i = 0; i < assets.length; i++) {
            if (assets[i] == _from) {
                return true;
            }
        }
        return false;
    }

    /// @dev Requires `_from` to be present in the `assets` variable in `Storage.sol`
    /// @param  _from Token address
    function _requireAssetData(address _from) internal view {
        require(_hasAssetData(_from), "!asset");
    }

    /// @dev Changes `_from` to `_to` in the `assets` variable in `Storage.sol`
    /// @param  _from Token address to change from
    /// @param  _to Token address to change to
    function _overrideAssetData(address _from, address _to) internal {
        // Override asset data
        for (uint256 i = 0; i < assets.length; i++) {
            if (assets[i] == _from) {
                assets[i] = _to;
                return;
            }
        }
    }
}