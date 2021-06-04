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

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

contract YearnV1 is Storage, Constants, IO {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // Match
    address constant ZERO_X = 0xDef1C0ded9bec7F1a1670819833240f027b25EfF;

    // 1inch
    address constant ONE_SPLIT = 0xC586BeF4a0992C495Cf22e1aeEE4E446CECDee0E;

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
    address constant yveCRV = 0xc5bDdf9843308380375a611c18B50Fb9341f502A;
    address constant yvBOOST = 0x9d409a0A012CFbA9B15F6D4B36Ac57A46966Ab9a;
    address constant yLinkCRV = 0xf2db9a7c0ACd427A680D640F02d90f6186E71725;

    // Curve Tokens
    address constant threeCRV = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;
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
    address constant KNC = 0xdd974D5C2e2928deA5F71b9825b8b646686BD200;
    address constant LRC = 0xBBbbCA6A901c926F240b89EacB641d8Aec7AEafD;
    address constant BAL = 0xba100000625a3754423978a60c9317c58a424e3D;
    address constant AAVE = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;
    address constant MTA = 0xa3BeD4E1c75D00fa6f4E5E6922DB7261B5E9AcD2;
    address constant SUSHI = 0x6B3595068778DD592e39A122f4f5a5cF09C90fE2;

    // **** Rebalance ****

    function recoverERC20(address _token, address _destination) external {
        require(!_hasAssetData(_token));
        IERC20(_token).safeTransfer(_destination, IERC20(_token).balanceOf(address(this)));
    }

    function toYvBoost() external {
        _requireAssetData(yveCRV);
        uint256 _balance = IERC20(yveCRV).balanceOf(address(this));
        _toYveBoost(_balance);
        _overrideAssetData(yveCRV, yvBOOST);
    }

    function fromGaugeLinkCRV() external {
        _requireAssetData(gaugeLinkCRV);
        uint256 _balance = IERC20(gaugeLinkCRV).balanceOf(address(this));
        _fromGaugeLinkCRV(_balance);
        _overrideAssetData(gaugeLinkCRV, linkCRV);
    }

    function toYearnLinkCRV() external {
        _requireAssetData(linkCRV);
        IERC20(linkCRV).approve(yLinkCRV, uint256(-1));
        IYearn(yLinkCRV).deposit();
        _overrideAssetData(linkCRV, yLinkCRV);
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
        ILinkGauge(gaugeLinkCRV).claim_rewards();
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
            return KNC;
        }

        if (_derivative == yveCRV || _derivative == yvBOOST) {
            return CRV;
        }

        if (_derivative == linkCRV) {
            return LINK;
        }

        return _derivative;
    }

    function _isCTokenUnderlying(address _token) internal pure returns (bool) {
        return (_token == UNI || _token == COMP);
    }

    function _isCToken(address _token) internal pure returns (bool) {
        return (_token == CUNI || _token == CCOMP);
    }

    function _isATokenV1(address _token) internal pure returns (bool) {
        return (_token == AYFIv1 || _token == ASNXv1 || _token == AMKRv1 || _token == ARENv1 || _token == AKNCv1);
    }

    function _isATokenV1Underlying(address _token) internal pure returns (bool) {
        return (_token == YFI || _token == SNX || _token == MKR || _token == REN || _token == KNC);
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