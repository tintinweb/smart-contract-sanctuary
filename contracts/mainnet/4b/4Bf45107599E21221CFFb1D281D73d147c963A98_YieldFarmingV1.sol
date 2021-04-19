// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "./IO.sol";
import "./Storage.sol";
import "./Constants.sol";

import "./IATokenV1.sol";
import "./ICToken.sol";
import "./IComptroller.sol";
import "./ISushiBar.sol";
import "./ILendingPoolV1.sol";
import "./ICompoundLens.sol";

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

contract YieldFarmingV1 is Storage, Constants, IO {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // Events
    event AssetReplaced(address indexed from, address indexed to);

    // Aave
    address public constant LENDING_POOL_V1 = 0x398eC7346DcD622eDc5ae82352F02bE94C62d119;
    address public constant LENDING_POOL_CORE_V1 = 0x3dfd23A6c5E8BbcFc9581d2E864a68feb6a076d3;

    // Compound
    address public constant COMPTROLLER = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;
    address public constant LENS = 0xd513d22422a3062Bd342Ae374b4b9c20E0a9a074;

    // Sushi
    address public constant XSUSHI = 0x8798249c2E607446EfB7Ad49eC89dD1865Ff4272;

    // CTokens
    address public constant CUNI = 0x35A18000230DA775CAc24873d00Ff85BccdeD550;
    address public constant CCOMP = 0x70e36f6BF80a52b3B46b3aF8e106CC0ed743E8e4;

    // Underlying
    address public constant UNI = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
    address public constant COMP = 0xc00e94Cb662C3520282E6f5717214004A7f26888;
    address public constant YFI = 0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e;
    address public constant SNX = 0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F;
    address public constant MKR = 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2;
    address public constant REN = 0x408e41876cCCDC0F92210600ef50372656052a38;
    address public constant KNC = 0xdd974D5C2e2928deA5F71b9825b8b646686BD200;
    address public constant LRC = 0xBBbbCA6A901c926F240b89EacB641d8Aec7AEafD;
    address public constant BAL = 0xba100000625a3754423978a60c9317c58a424e3D;
    address public constant AAVE = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;
    address public constant MTA = 0xa3BeD4E1c75D00fa6f4E5E6922DB7261B5E9AcD2;
    address public constant SUSHI = 0x6B3595068778DD592e39A122f4f5a5cF09C90fE2;

    /// @notice Enters Compound market. *Must be called before toCToken*
    /// @param  _markets  Compound markets to enter (underlying, not cTokens)
    function enterMarkets(address[] memory _markets) external {
        IComptroller(COMPTROLLER).enterMarkets(_markets);
    }

    /// @notice Redriects interest stream from aTokenV1 to new fee recipient
    function redirectInterestStreams(address[] memory _atokens) external {
        address feeRecipient = _readSlotAddress(FEE_RECIPIENT);

        for (uint256 i = 0; i < _atokens.length; i++) {
            IATokenV1(_atokens[i]).redirectInterestStream(feeRecipient);
        }
    }

    /// @notice Supplies assets to the Compound market
    /// @param  _token  Underlying token to supply to Compound
    function toCToken(address _token) external {
        _requireAssetData(_token);

        // Only doing UNI or COMP for CTokens
        require(_token == UNI || _token == COMP, "!valid-to-ctoken");

        address _ctoken = _getTokenToCToken(_token);
        uint256 balance = IERC20(_token).balanceOf(address(this));

        require(balance > 0, "!token-bal");

        IERC20(_token).safeApprove(_ctoken, 0);
        IERC20(_token).safeApprove(_ctoken, balance);
        require(ICToken(_ctoken).mint(balance) == 0, "!ctoken-mint");
        _overrideAssetData(_token, _ctoken);
    }

    /// @notice Redeems assets from the Compound market
    /// @param  _ctoken  CToken to redeem from Compound
    function fromCToken(address _ctoken) external {
        _requireAssetData(_ctoken);

        // Only doing CUNI or CCOMP
        require(_ctoken == CUNI || _ctoken == CCOMP, "!valid-from-ctoken");

        address _token = ICToken(_ctoken).underlying();
        uint256 balance = ICToken(_ctoken).balanceOf(address(this));

        require(balance > 0, "!ctoken-bal");

        require(ICToken(_ctoken).redeem(balance) == 0, "!ctoken-redeem");
        _overrideAssetData(_ctoken, _token);
    }

    /// @notice Supplies assets to the Aave market
    /// @param  _token  Underlying to supply to Aave
    function toATokenV1(address _token) external {
        _requireAssetData(_token);

        require(_token != UNI && _token != COMP, "no-uni-or-comp");

        uint256 balance = IERC20(_token).balanceOf(address(this));

        require(balance > 0, "!token-bal");

        IERC20(_token).safeApprove(LENDING_POOL_CORE_V1, 0);
        IERC20(_token).safeApprove(LENDING_POOL_CORE_V1, balance);
        ILendingPoolV1(LENDING_POOL_V1).deposit(_token, balance, 0);
        (, , , , , , , , , , , address _atoken, ) = ILendingPoolV1(LENDING_POOL_V1).getReserveData(_token);

        // Redirect Interest
        address feeRecipient = _readSlotAddress(FEE_RECIPIENT);
        require(feeRecipient != address(0), "!fee-recipient");

        IATokenV1(_atoken).redirectInterestStream(feeRecipient);

        _overrideAssetData(_token, _atoken);
    }

    /// @notice Redeems assets from the Aave market
    /// @param  _atoken  AToken to redeem from Aave
    function fromATokenV1(address _atoken) external {
        _requireAssetData(_atoken);

        uint256 balance = IATokenV1(_atoken).balanceOf(address(this));

        require(balance > 0, "!atoken-bal");

        IATokenV1(_atoken).redeem(balance);
        address _token = IATokenV1(_atoken).underlyingAssetAddress();

        _overrideAssetData(_atoken, _token);
    }

    /// @notice Claims accrued COMP tokens
    function claimComp() external {
        address feeRecipient = _readSlotAddress(FEE_RECIPIENT);
        require(feeRecipient != address(0), "!fee-recipient");

        uint256 _before = IERC20(COMP).balanceOf(address(this));

        // Claims comp
        address[] memory cTokens = new address[](2);
        cTokens[0] = CUNI;
        cTokens[1] = CCOMP;
        IComptroller(COMPTROLLER).claimComp(address(this), cTokens);

        // Calculates how much was given
        uint256 _after = IERC20(COMP).balanceOf(address(this));
        uint256 _amount = _after.sub(_before);

        // Transfers to fee recipient
        IERC20(COMP).safeTransfer(feeRecipient, _amount);
    }

    /// @notice Converts sushi to xsushi
    function toXSushi() external {
        _requireAssetData(SUSHI);

        uint256 balance = IERC20(SUSHI).balanceOf(address(this));
        require(balance > 0, "!sushi-bal");

        IERC20(SUSHI).safeApprove(XSUSHI, 0);
        IERC20(SUSHI).safeApprove(XSUSHI, balance);
        ISushiBar(XSUSHI).enter(balance);

        _overrideAssetData(SUSHI, XSUSHI);
    }

    /// @notice Goes from xsushi to sushi
    function fromXSushi() external {
        _requireAssetData(XSUSHI);

        uint256 balance = IERC20(XSUSHI).balanceOf(address(this));
        require(balance > 0, "!xsushi-bal");

        ISushiBar(XSUSHI).leave(balance);
        _overrideAssetData(XSUSHI, SUSHI);
    }

    // **** Pseudo-view functions (Use `callStatic`) ****

    /// @dev Gets claimable comp for certain address
    /// @param  _target Address to check for accrued comp
    function getClaimableComp(address _target) public returns (uint256) {
        (, , , uint256 accrued) = ICompoundLens(LENS).getCompBalanceMetadataExt(COMP, COMPTROLLER, _target);

        return accrued;
    }

    // **** Internal ****

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

    /// @dev Requires `_from` to be present in the `assets` variable in `Storage.sol`
    /// @param  _from Token address
    function _requireAssetData(address _from) internal view {
        bool hasAsset = false;
        for (uint256 i = 0; i < assets.length; i++) {
            if (assets[i] == _from) {
                hasAsset = true;
            }
        }
        require(hasAsset, "!asset");
    }

    /// @dev Changes `_from` to `_to` in the `assets` variable in `Storage.sol`
    /// @param  _from Token address to change from
    /// @param  _to Token address to change to
    function _overrideAssetData(address _from, address _to) internal {
        // Override asset data
        for (uint256 i = 0; i < assets.length; i++) {
            if (assets[i] == _from) {
                assets[i] = _to;

                emit AssetReplaced(_from, _to);

                return;
            }
        }
    }
}