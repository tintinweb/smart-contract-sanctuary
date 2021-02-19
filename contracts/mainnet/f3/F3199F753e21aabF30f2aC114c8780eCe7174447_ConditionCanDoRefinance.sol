// "SPDX-License-Identifier: UNLICENSED"
pragma solidity >=0.6.10;

import "./IGelatoCondition.sol";

abstract contract GelatoConditionsStandard is IGelatoCondition {
    string internal constant OK = "OK";
}

// "SPDX-License-Identifier: UNLICENSED"
pragma solidity >=0.6.10;
pragma experimental ABIEncoderV2;

/// @title IGelatoCondition - solidity interface of GelatoConditionsStandard
/// @notice all the APIs of GelatoConditionsStandard
/// @dev all the APIs are implemented inside GelatoConditionsStandard
interface IGelatoCondition {

    /// @notice GelatoCore calls this to verify securely the specified Condition securely
    /// @dev Be careful only to encode a Task's condition.data as is and not with the
    ///  "ok" selector or _taskReceiptId, since those two things are handled by GelatoCore.
    /// @param _taskReceiptId This is passed by GelatoCore so we can rely on it as a secure
    ///  source of Task identification.
    /// @param _conditionData This is the Condition.data field developers must encode their
    ///  Condition's specific parameters in.
    /// @param _cycleId For Tasks that are executed as part of a cycle.
    function ok(uint256 _taskReceiptId, bytes calldata _conditionData, uint256 _cycleId)
        external
        view
        returns(string memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

// Aave Lending Pool Addresses Provider
address constant LENDING_POOL_ADDRESSES_PROVIDER = 0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5;
address constant CHAINLINK_ETH_FEED = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
address constant AAVE_PROTOCOL_DATA_PROVIDER = 0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d;

address constant LENDING_POOL_CORE_V1 = 0x3dfd23A6c5E8BbcFc9581d2E864a68feb6a076d3;

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

address constant COMPTROLLER = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

enum PROTOCOL {AAVE, MAKER, COMPOUND, NONE}

function GAS_COSTS_FOR_FULL_REFINANCE_MAKER_TO_MAKER()
    pure
    returns (uint256[4] memory)
{
    return [uint256(2519000), 3140500, 3971000, 4345000];
}

function GAS_COSTS_FOR_FULL_REFINANCE_MAKER_TO_COMPOUND()
    pure
    returns (uint256[4] memory)
{
    return [uint256(2028307), 2626711, 2944065, 3698800];
}

function GAS_COSTS_FOR_FULL_REFINANCE_MAKER_TO_AAVE()
    pure
    returns (uint256[4] memory)
{
    return [uint256(2358534), 2956937, 3381960, 4029400];
}

uint256 constant FAST_TX_FEE = 30;
uint256 constant VAULT_CREATION_COST = 200000;
uint256 constant MAX_INSTA_FEE = 3e15;

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import {
    IGelatoGasPriceOracle
} from "../interfaces/gelato/IGelatoGasPriceOracle.sol";

IGelatoGasPriceOracle constant GELATO_GAS_PRICE_ORACLE = IGelatoGasPriceOracle(
    0x169E633A2D1E6c10dD91238Ba11c4A708dfEF37C
);

address constant GELATO_EXECUTOR_MODULE = 0x98edc8067Cc671BCAE82D36dCC609C3E4e078AC8;

address constant CONDITION_MAKER_VAULT_UNSAFE_OSM = 0xDF3CDd10e646e4155723a3bC5b1191741DD90333;

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

// InstaDapp
address constant INSTA_MEMORY = 0x8a5419CfC711B2343c17a6ABf4B2bAFaBb06957F;

// Connectors
address constant CONNECT_MAKER = 0xac02030d8a8F49eD04b2f52C394D3F901A10F8A9;
address constant CONNECT_COMPOUND = 0x15FdD1e902cAC70786fe7D31013B1a806764B5a2;
address constant INSTA_POOL_V2 = 0xeB4bf86589f808f90EEC8e964dBF16Bd4D284905;
address constant CONNECT_AAVE_V2 = 0xBF6E4331ffd02F7043e62788FD272aeFc712f5ee;
address constant CONNECT_DYDX = 0x6AF6C791c869DfA65f8A2fa042fA47D1535Bef25;
address constant CONNECT_BASIC = 0xe5398f279175962E56fE4c5E0b62dc7208EF36c6;
address constant CONNECT_FEE = 0xB99152F8073033B318C1Bfbfaaa582029e982CE9;

// Insta Pool
address constant INSTA_POOL_RESOLVER = 0xa004a5afBa04b74037E9E52bA1f7eb02b5E61509;
uint256 constant ROUTE_1_TOLERANCE = 1005e15;

// Insta Mapping
address constant INSTA_MAPPING = 0xe81F70Cc7C0D46e12d70efc60607F16bbD617E88;

address constant INSTA_MAKER_RESOLVER = 0x0A7008B38E7015F8C36A49eEbc32513ECA8801E5;

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

address constant MCD_MANAGER = 0x5ef30b9986345249bc32d8928B7ee64DE9435E39;
address constant JUG = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

// ETH
address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

// USD
address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import {
    GelatoConditionsStandard
} from "@gelatonetwork/core/contracts/gelato_conditions/GelatoConditionsStandard.sol";
import {
    _getDebtBridgeRoute
} from "../../../functions/gelato/FGelatoDebtBridge.sol";
import {PROTOCOL} from "../../../constants/CDebtBridge.sol";
import {GelatoBytes} from "../../../lib/GelatoBytes.sol";
import {DebtBridgeInputData} from "../../../structs/SDebtBridge.sol";
import {
    _getMakerVaultDebt,
    _getMakerVaultCollateralBalance
} from "../../../functions/dapps/FMaker.sol";
import {
    _getFlashLoanRoute,
    _getRealisedDebt
} from "../../../functions/gelato/FGelatoDebtBridge.sol";
import {DAI} from "../../../constants/CTokens.sol";
import {
    IInstaFeeCollector
} from "../../../interfaces/InstaDapp/IInstaFeeCollector.sol";

contract ConditionCanDoRefinance is GelatoConditionsStandard {
    address public immutable instaFeeCollector;
    address public immutable oracleAggregator;

    constructor(address _instaFeeCollector, address _oracleAggregator) {
        instaFeeCollector = _instaFeeCollector;
        oracleAggregator = _oracleAggregator;
    }

    function getConditionData(
        address _dsa,
        uint256 _fromVaultId,
        address _colToken,
        uint256 _makerDestVaultId,
        string calldata _makerDestColType
    ) public pure virtual returns (bytes memory) {
        return
            abi.encodeWithSelector(
                this.canDoRefinance.selector,
                _dsa,
                _fromVaultId,
                _colToken,
                _makerDestVaultId,
                _makerDestColType
            );
    }

    function ok(
        uint256,
        bytes calldata _conditionData,
        uint256
    ) public view virtual override returns (string memory) {
        (
            address _dsa,
            uint256 _fromVaultId,
            address _colToken,
            uint256 _makerDestVaultId,
            string memory _makerDestColType
        ) =
            abi.decode(
                _conditionData[4:],
                (address, uint256, address, uint256, string)
            );

        return
            canDoRefinance(
                _dsa,
                _fromVaultId,
                _colToken,
                _makerDestVaultId,
                _makerDestColType
            );
    }

    function canDoRefinance(
        address _dsa,
        uint256 _fromVaultId,
        address _colToken,
        uint256 _makerDestVaultId,
        string memory _makerDestColType
    ) public view returns (string memory) {
        uint256 debtAmt = _getRealisedDebt(_getMakerVaultDebt(_fromVaultId));
        return
            _getDebtBridgeRoute(
                DebtBridgeInputData({
                    dsa: _dsa,
                    colAmt: _getMakerVaultCollateralBalance(_fromVaultId),
                    colToken: _colToken,
                    debtAmt: debtAmt,
                    oracleAggregator: oracleAggregator,
                    makerDestVaultId: _makerDestVaultId,
                    makerDestColType: _makerDestColType,
                    fees: IInstaFeeCollector(instaFeeCollector).fee(),
                    flashRoute: _getFlashLoanRoute(DAI, _fromVaultId, debtAmt)
                })
            ) != PROTOCOL.NONE
                ? OK
                : "CannotDoRefinance";
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import {
    IAaveProtocolDataProvider
} from "../../interfaces/dapps/Aave/IAaveProtocolDataProvider.sol";
import {
    ILendingPoolAddressesProvider
} from "../../interfaces/dapps/Aave/ILendingPoolAddressesProvider.sol";
import {
    ChainLinkInterface
} from "../../interfaces/dapps/Aave/ChainLinkInterface.sol";
import {ILendingPool} from "../../interfaces/dapps/Aave/ILendingPool.sol";
import {WETH, ETH} from "../../constants/CTokens.sol";
import {AaveUserData} from "../../structs/SAave.sol";
import {
    LENDING_POOL_ADDRESSES_PROVIDER,
    CHAINLINK_ETH_FEED,
    AAVE_PROTOCOL_DATA_PROVIDER,
    LENDING_POOL_CORE_V1
} from "../../constants/CAave.sol";
import {ETH, WETH} from "../../constants/CTokens.sol";
import {IERC20} from "../../interfaces/dapps/IERC20.sol";

function _getEtherPrice() view returns (uint256 ethPrice) {
    ethPrice = uint256(ChainLinkInterface(CHAINLINK_ETH_FEED).latestAnswer());
}

function _getUserData(address user)
    view
    returns (AaveUserData memory userData)
{
    (
        uint256 totalCollateralETH,
        uint256 totalDebtETH,
        uint256 availableBorrowsETH,
        uint256 currentLiquidationThreshold,
        uint256 ltv,
        uint256 healthFactor
    ) =
        ILendingPool(
            ILendingPoolAddressesProvider(LENDING_POOL_ADDRESSES_PROVIDER)
                .getLendingPool()
        )
            .getUserAccountData(user);

    userData = AaveUserData(
        totalCollateralETH,
        totalDebtETH,
        availableBorrowsETH,
        currentLiquidationThreshold,
        ltv,
        healthFactor,
        _getEtherPrice()
    );
}

function _getAssetLiquidationThreshold(address _token)
    view
    returns (uint256 liquidationThreshold)
{
    (, , liquidationThreshold, , , , , , , ) = IAaveProtocolDataProvider(
        AAVE_PROTOCOL_DATA_PROVIDER
    )
        .getReserveConfigurationData(_getTokenAddr(_token));
}

function _getTokenAddr(address _token) pure returns (address) {
    return _token == ETH ? WETH : _token;
}

function _getTokenLiquidity(address _token) view returns (uint256) {
    return
        IERC20(_token).balanceOf(
            ILendingPool(
                ILendingPoolAddressesProvider(LENDING_POOL_ADDRESSES_PROVIDER)
                    .getLendingPool()
            )
                .getReserveData(_token)
                .aTokenAddress
        );
}

function _isAaveUnderlyingLiquid(address _debtToken, uint256 _debtAmt)
    view
    returns (bool)
{
    return _getTokenLiquidity(_debtToken) > _debtAmt;
}

function _isAaveUnderlyingLiquidV1(address _debtToken, uint256 _debtAmt)
    view
    returns (bool)
{
    return IERC20(_debtToken).balanceOf(LENDING_POOL_CORE_V1) > _debtAmt;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import {INSTA_MAPPING} from "../../constants/CInstaDapp.sol";
import {COMPTROLLER} from "../../constants/CCompound.sol";
import {InstaMapping} from "../../interfaces/InstaDapp/IInstaDapp.sol";
import {ICToken} from "../../interfaces/dapps/Compound/ICToken.sol";
import {IComptroller} from "../../interfaces/dapps/Compound/IComptroller.sol";
import {IPriceOracle} from "../../interfaces/dapps/Compound/IPriceOracle.sol";

function _getCToken(address _token) view returns (address) {
    return InstaMapping(INSTA_MAPPING).cTokenMapping(_token);
}

function _wouldCompoundAccountBeLiquid(
    address _dsa,
    address _cColToken,
    uint256 _colAmt,
    address _cDebtToken,
    uint256 _debtAmt
) view returns (bool) {
    IComptroller comptroller = IComptroller(COMPTROLLER);
    IPriceOracle priceOracle = IPriceOracle(comptroller.oracle());

    (, uint256 collateralFactor, ) = comptroller.markets(_cColToken);
    (uint256 error, uint256 liquidity, uint256 shortfall) =
        comptroller.getAccountLiquidity(_dsa);

    require(error == 0, "Get Account Liquidity function failed.");

    return
        mulScalarTruncateAddUInt(
            mul_expScale(collateralFactor, _colAmt),
            priceOracle.getUnderlyingPrice(ICToken(_cColToken)),
            liquidity
        ) >
        mulScalarTruncateAddUInt(
            _debtAmt,
            priceOracle.getUnderlyingPrice(ICToken(_cDebtToken)),
            shortfall
        );
}

function _isCompoundUnderlyingLiquidity(address _debtToken, uint256 _debtAmt)
    view
    returns (bool)
{
    return ICToken(_getCToken(_debtToken)).getCash() > _debtAmt;
}

// Compound Math Function

function mulScalarTruncateAddUInt(
    uint256 _a,
    uint256 _b,
    uint256 _addend
) pure returns (uint256) {
    return mul_expScale(_a, _b) + _addend;
}

function mul_expScale(uint256 _a, uint256 _b) pure returns (uint256) {
    return (_a * _b) / 1e18;
}

// Compound Math Function

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import {MCD_MANAGER} from "../../constants/CMaker.sol";
import {INSTA_MAPPING} from "../../constants/CInstaDapp.sol";
import {
    ITokenJoinInterface
} from "../../interfaces/dapps/Maker/ITokenJoinInterface.sol";
import {IMcdManager} from "../../interfaces/dapps/Maker/IMcdManager.sol";
import {InstaMapping} from "../../interfaces/InstaDapp/IInstaDapp.sol";
import {IVat} from "../../interfaces/dapps/Maker/IVat.sol";
import {RAY, add, sub, mul} from "../../vendor/DSMath.sol";
import {_stringToBytes32, _convertTo18} from "../../vendor/Convert.sol";

function _getMakerVaultDebt(uint256 _vaultId) view returns (uint256 wad) {
    IMcdManager manager = IMcdManager(MCD_MANAGER);

    (bytes32 ilk, address urn) = _getVaultData(manager, _vaultId);
    IVat vat = IVat(manager.vat());
    (, uint256 rate, , , ) = vat.ilks(ilk);
    (, uint256 art) = vat.urns(ilk, urn);
    uint256 dai = vat.dai(urn);

    uint256 rad = sub(mul(art, rate), dai);
    wad = rad / RAY;

    wad = mul(wad, RAY) < rad ? wad + 1 : wad;
}

function _getMakerRawVaultDebt(uint256 _vaultId) view returns (uint256 tab) {
    IMcdManager manager = IMcdManager(MCD_MANAGER);

    (bytes32 ilk, address urn) = _getVaultData(manager, _vaultId);
    IVat vat = IVat(manager.vat());
    (, uint256 rate, , , ) = vat.ilks(ilk);
    (, uint256 art) = vat.urns(ilk, urn);

    uint256 rad = mul(art, rate);

    tab = rad / RAY;
    tab = mul(tab, RAY) < rad ? tab + 1 : tab;
}

function _getMakerVaultCollateralBalance(uint256 _vaultId)
    view
    returns (uint256)
{
    IMcdManager manager = IMcdManager(MCD_MANAGER);

    IVat vat = IVat(manager.vat());
    (bytes32 ilk, address urn) = _getVaultData(manager, _vaultId);
    (uint256 ink, ) = vat.urns(ilk, urn);

    return ink;
}

function _vaultWillBeSafe(
    uint256 _vaultId,
    uint256 _colAmt,
    uint256 _daiDebtAmt
) view returns (bool) {
    require(_vaultId != 0, "_vaultWillBeSafe: invalid vault id.");

    IMcdManager manager = IMcdManager(MCD_MANAGER);

    (bytes32 ilk, address urn) = _getVaultData(manager, _vaultId);

    ITokenJoinInterface tokenJoinContract =
        ITokenJoinInterface(InstaMapping(INSTA_MAPPING).gemJoinMapping(ilk));

    IVat vat = IVat(manager.vat());
    (, uint256 rate, uint256 spot, , ) = vat.ilks(ilk);
    (uint256 ink, uint256 art) = vat.urns(ilk, urn);
    uint256 dai = vat.dai(urn);

    uint256 dink = _convertTo18(tokenJoinContract.dec(), _colAmt);
    uint256 dart = _getDebtAmt(_daiDebtAmt, dai, rate);

    ink = add(ink, dink);
    art = add(art, dart);

    uint256 tab = mul(rate, art);

    return tab <= mul(ink, spot);
}

function _newVaultWillBeSafe(
    string memory _colType,
    uint256 _colAmt,
    uint256 _daiDebtAmt
) view returns (bool) {
    IMcdManager manager = IMcdManager(MCD_MANAGER);
    IVat vat = IVat(manager.vat());

    bytes32 ilk = _stringToBytes32(_colType);

    (, uint256 rate, uint256 spot, , ) = vat.ilks(ilk);

    ITokenJoinInterface tokenJoinContract =
        ITokenJoinInterface(InstaMapping(INSTA_MAPPING).gemJoinMapping(ilk));

    uint256 ink = _convertTo18(tokenJoinContract.dec(), _colAmt);
    uint256 art = _getDebtAmt(_daiDebtAmt, 0, rate);

    uint256 tab = mul(rate, art);

    return tab <= mul(ink, spot);
}

function _debtCeilingIsReachedNewVault(
    string memory _colType,
    uint256 _daiDebtAmt
) view returns (bool) {
    IMcdManager manager = IMcdManager(MCD_MANAGER);
    IVat vat = IVat(manager.vat());

    bytes32 ilk = _stringToBytes32(_colType);

    (uint256 Art, uint256 rate, , uint256 line, ) = vat.ilks(ilk);
    uint256 Line = vat.Line();
    uint256 debt = vat.debt();

    uint256 dart = _getDebtAmt(_daiDebtAmt, 0, rate);
    uint256 dtab = mul(rate, dart);

    debt = add(debt, dtab);
    Art = add(Art, dart);

    return mul(Art, rate) > line || debt > Line;
}

function _debtCeilingIsReached(uint256 _vaultId, uint256 _daiDebtAmt)
    view
    returns (bool)
{
    IMcdManager manager = IMcdManager(MCD_MANAGER);
    IVat vat = IVat(manager.vat());

    (bytes32 ilk, address urn) = _getVaultData(manager, _vaultId);

    (uint256 Art, uint256 rate, , uint256 line, ) = vat.ilks(ilk);
    uint256 dai = vat.dai(urn);
    uint256 Line = vat.Line();
    uint256 debt = vat.debt();

    uint256 dart = _getDebtAmt(_daiDebtAmt, dai, rate);
    uint256 dtab = mul(rate, dart);

    debt = add(debt, dtab);
    Art = add(Art, dart);

    return mul(Art, rate) > line || debt > Line;
}

function _debtIsDustNewVault(string memory _colType, uint256 _daiDebtAmt)
    view
    returns (bool)
{
    IMcdManager manager = IMcdManager(MCD_MANAGER);
    IVat vat = IVat(manager.vat());

    bytes32 ilk = _stringToBytes32(_colType);

    (, uint256 rate, , , uint256 dust) = vat.ilks(ilk);
    uint256 art = _getDebtAmt(_daiDebtAmt, 0, rate);

    uint256 tab = mul(rate, art);

    return tab < dust;
}

function _debtIsDust(uint256 _vaultId, uint256 _daiDebtAmt)
    view
    returns (bool)
{
    IMcdManager manager = IMcdManager(MCD_MANAGER);
    IVat vat = IVat(manager.vat());

    (bytes32 ilk, address urn) = _getVaultData(manager, _vaultId);
    (, uint256 art) = vat.urns(ilk, urn);
    (, uint256 rate, , , uint256 dust) = vat.ilks(ilk);

    uint256 dai = vat.dai(urn);
    uint256 dart = _getDebtAmt(_daiDebtAmt, dai, rate);
    art = add(art, dart);
    uint256 tab = mul(rate, art);

    return tab < dust;
}

function _getVaultData(IMcdManager _manager, uint256 _vault)
    view
    returns (bytes32 ilk, address urn)
{
    ilk = _manager.ilks(_vault);
    urn = _manager.urns(_vault);
}

function _getDebtAmt(
    uint256 _amt,
    uint256 _dai,
    uint256 _rate
) pure returns (uint256 dart) {
    dart = sub(mul(_amt, RAY), _dai) / _rate;
    dart = mul(dart, _rate) < mul(_amt, RAY) ? dart + 1 : dart;
}

function _isVaultOwner(uint256 _vaultId, address _owner) view returns (bool) {
    if (_vaultId == 0) return false;

    try IMcdManager(MCD_MANAGER).owns(_vaultId) returns (address owner) {
        return _owner == owner;
    } catch Error(string memory error) {
        revert(string(abi.encodePacked("FMaker._isVaultOwner:", error)));
    } catch {
        revert("FMaker._isVaultOwner:undefined");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import {GELATO_GAS_PRICE_ORACLE} from "../../constants/CGelato.sol";
import {mul} from "../../vendor/DSMath.sol";

function _getGelatoGasPrice() view returns (uint256) {
    int256 oracleGasPrice = GELATO_GAS_PRICE_ORACLE.latestAnswer();
    if (oracleGasPrice <= 0) revert("_getGelatoGasPrice:0orBelow");
    return uint256(oracleGasPrice);
}

function _getGelatoExecutorFees(uint256 _gas) view returns (uint256) {
    return mul(_gas, _getGelatoGasPrice());
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import {wmul, wdiv} from "../../vendor/DSMath.sol";
import {
    INSTA_POOL_RESOLVER,
    ROUTE_1_TOLERANCE
} from "../../constants/CInstaDapp.sol";
import {DebtBridgeInputData} from "../../structs/SDebtBridge.sol";
import {
    _canDoMakerToAaveDebtBridge,
    _canDoMakerToMakerDebtBridge,
    _canDoMakerToCompoundDebtBridge
} from "./conditions/FCanDoRefinance.sol";
import {
    PROTOCOL,
    GAS_COSTS_FOR_FULL_REFINANCE_MAKER_TO_MAKER,
    GAS_COSTS_FOR_FULL_REFINANCE_MAKER_TO_COMPOUND,
    GAS_COSTS_FOR_FULL_REFINANCE_MAKER_TO_AAVE,
    FAST_TX_FEE,
    VAULT_CREATION_COST
} from "../../constants/CDebtBridge.sol";
import {
    IInstaPoolResolver
} from "../../interfaces/InstaDapp/resolvers/IInstaPoolResolver.sol";
import {_getMakerVaultDebt, _debtCeilingIsReached} from "../dapps/FMaker.sol";
import {_isAaveUnderlyingLiquidV1} from "../dapps/FAave.sol";
import {_isCompoundUnderlyingLiquidity} from "../dapps/FCompound.sol";
import {_getGelatoExecutorFees} from "./FGelato.sol";
import {DAI, ETH} from "../../constants/CTokens.sol";
import {IOracleAggregator} from "../../interfaces/gelato/IOracleAggregator.sol";
import {_convertTo18} from "../../vendor/Convert.sol";

function _getFlashLoanRoute(
    address _debtToken,
    uint256 _vaultId,
    uint256 _debtAmt
) view returns (uint256) {
    IInstaPoolResolver.RouteData memory rData =
        IInstaPoolResolver(INSTA_POOL_RESOLVER).getTokenLimit(_debtToken);

    if (rData.dydx > _debtAmt) return 0;

    if (rData.maker > _debtAmt && !_debtCeilingIsReached(_vaultId, _debtAmt))
        return 1;
    if (
        rData.compound > _debtAmt &&
        _isCompoundUnderlyingLiquidity(_debtToken, _debtAmt)
    ) return 2;
    if (
        rData.aave > _debtAmt && _isAaveUnderlyingLiquidV1(_debtToken, _debtAmt)
    ) return 3;
    revert("FGelatoDebtBridge._getFlashLoanRoute: illiquid");
}

function _getDebtBridgeRoute(DebtBridgeInputData memory _data)
    view
    returns (PROTOCOL)
{
    if (_canDoMakerToAaveDebtBridge(_data)) return PROTOCOL.AAVE;
    else if (_canDoMakerToMakerDebtBridge(_data)) return PROTOCOL.MAKER;
    else if (_canDoMakerToCompoundDebtBridge(_data)) return PROTOCOL.COMPOUND;
    return PROTOCOL.NONE;
}

function _getGasCostMakerToMaker(bool _newVault, uint256 _route)
    pure
    returns (uint256)
{
    _checkRouteIndex(
        _route,
        "FGelatoDebtBridge._getGasCostMakerToMaker: invalid route index"
    );
    return
        _getGasCostPremium(
            _newVault
                ? GAS_COSTS_FOR_FULL_REFINANCE_MAKER_TO_MAKER()[_route] +
                    VAULT_CREATION_COST
                : GAS_COSTS_FOR_FULL_REFINANCE_MAKER_TO_MAKER()[_route]
        );
}

function _getGasCostMakerToCompound(uint256 _route) pure returns (uint256) {
    _checkRouteIndex(
        _route,
        "FGelatoDebtBridge._getGasCostMakerToCompound: invalid route index"
    );
    return
        _getGasCostPremium(
            GAS_COSTS_FOR_FULL_REFINANCE_MAKER_TO_COMPOUND()[_route]
        );
}

function _getGasCostMakerToAave(uint256 _route) pure returns (uint256) {
    _checkRouteIndex(
        _route,
        "FGelatoDebtBridge._getGasCostMakerToAave: invalid route index"
    );
    return
        _getGasCostPremium(
            GAS_COSTS_FOR_FULL_REFINANCE_MAKER_TO_AAVE()[_route]
        );
}

function _getGasCostPremium(uint256 _rawGasCost) pure returns (uint256) {
    return (_rawGasCost * (100 + FAST_TX_FEE)) / 100;
}

function _getRealisedDebt(uint256 _debtToMove) pure returns (uint256) {
    return wmul(_debtToMove, ROUTE_1_TOLERANCE);
}

function _checkRouteIndex(uint256 _route, string memory _revertMsg) pure {
    require(_route <= 4, _revertMsg);
}

function _getMaxAmtToBorrowMakerToAave(
    uint256 _fromVaultId,
    uint256 _fees,
    address _oracleAggregator
) view returns (uint256) {
    uint256 wDaiToBorrow = _getRealisedDebt(_getMakerVaultDebt(_fromVaultId));

    return
        _getMaxAmtToBorrow(
            wDaiToBorrow,
            _getGasCostMakerToAave(
                _getFlashLoanRoute(DAI, _fromVaultId, wDaiToBorrow)
            ),
            _fees,
            _oracleAggregator
        );
}

function _getMaxAmtToBorrowMakerToCompound(
    uint256 _fromVaultId,
    uint256 _fees,
    address _oracleAggregator
) view returns (uint256) {
    uint256 wDaiToBorrow = _getRealisedDebt(_getMakerVaultDebt(_fromVaultId));

    return
        _getMaxAmtToBorrow(
            wDaiToBorrow,
            _getGasCostMakerToCompound(
                _getFlashLoanRoute(DAI, _fromVaultId, wDaiToBorrow)
            ),
            _fees,
            _oracleAggregator
        );
}

function _getMaxAmtToBorrowMakerToMaker(
    uint256 _fromVaultId,
    bool _newVault,
    uint256 _fees,
    address _oracleAggregator
) view returns (uint256) {
    uint256 wDaiToBorrow = _getRealisedDebt(_getMakerVaultDebt(_fromVaultId));

    return
        _getMaxAmtToBorrow(
            wDaiToBorrow,
            _getGasCostMakerToMaker(
                _newVault,
                _getFlashLoanRoute(DAI, _fromVaultId, wDaiToBorrow)
            ),
            _fees,
            _oracleAggregator
        );
}

function _getMaxAmtToBorrow(
    uint256 _wDaiToBorrow,
    uint256 _gasCost,
    uint256 _fees,
    address _oracleAggregator
) view returns (uint256) {
    (uint256 gasCostInDAI, uint256 decimals) =
        IOracleAggregator(_oracleAggregator).getExpectedReturnAmount(
            _getGelatoExecutorFees(_gasCost),
            ETH,
            DAI
        );

    gasCostInDAI = _convertTo18(decimals, gasCostInDAI);

    return _wDaiToBorrow + gasCostInDAI + wmul(_wDaiToBorrow, _fees);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import {_isAaveLiquid} from "./aave/FAaveHasLiquidity.sol";
import {_aavePositionWillBeSafe} from "./aave/FAavePositionWillBeSafe.sol";
import {_isDebtAmtDust} from "./maker/FIsDebtAmtDust.sol";
import {_isDebtCeilingReached} from "./maker/FDebtCeilingIsReached.sol";
import {_destVaultWillBeSafe} from "./maker/FDestVaultWillBeSafe.sol";
import {_cTokenHasLiquidity} from "./compound/FCompoundHasLiquidity.sol";
import {
    _compoundPositionWillBeSafe
} from "./compound/FCompoundPositionWillBeSafe.sol";
import {DebtBridgeInputData} from "../../../structs/SDebtBridge.sol";
import {DAI} from "../../../constants/CTokens.sol";
import {
    _getMaxAmtToBorrow,
    _getGasCostMakerToAave,
    _getGasCostMakerToCompound,
    _getGasCostMakerToMaker
} from "../FGelatoDebtBridge.sol";

function _canDoMakerToAaveDebtBridge(DebtBridgeInputData memory _data)
    view
    returns (bool)
{
    uint256 maxBorToAavePos =
        _getMaxAmtToBorrow(
            _data.debtAmt,
            _getGasCostMakerToAave(_data.flashRoute),
            _data.fees,
            _data.oracleAggregator
        );
    return
        _isAaveLiquid(DAI, maxBorToAavePos) &&
        _aavePositionWillBeSafe(
            _data.dsa,
            _data.colAmt,
            _data.colToken,
            maxBorToAavePos,
            _data.oracleAggregator
        );
}

function _canDoMakerToMakerDebtBridge(DebtBridgeInputData memory _data)
    view
    returns (bool)
{
    uint256 maxBorToMakerPos =
        _getMaxAmtToBorrow(
            _data.debtAmt,
            _getGasCostMakerToMaker(
                _data.makerDestVaultId == 0,
                _data.flashRoute
            ),
            _data.fees,
            _data.oracleAggregator
        );
    return
        !_isDebtAmtDust(
            _data.dsa,
            _data.makerDestVaultId,
            _data.makerDestColType,
            maxBorToMakerPos
        ) &&
        !_isDebtCeilingReached(
            _data.dsa,
            _data.makerDestVaultId,
            _data.makerDestColType,
            maxBorToMakerPos
        ) &&
        _destVaultWillBeSafe(
            _data.dsa,
            _data.makerDestVaultId,
            _data.makerDestColType,
            _data.colAmt,
            maxBorToMakerPos
        );
}

function _canDoMakerToCompoundDebtBridge(DebtBridgeInputData memory _data)
    view
    returns (bool)
{
    uint256 maxBorToCompPos =
        _getMaxAmtToBorrow(
            _data.debtAmt,
            _getGasCostMakerToCompound(_data.flashRoute),
            _data.fees,
            _data.oracleAggregator
        );

    return
        _cTokenHasLiquidity(
            DAI,
            _data.flashRoute == 2
                ? _data.debtAmt + maxBorToCompPos
                : maxBorToCompPos
        ) &&
        _compoundPositionWillBeSafe(
            _data.dsa,
            _data.colToken,
            _data.colAmt,
            DAI,
            maxBorToCompPos
        );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import {_isAaveUnderlyingLiquid} from "../../../dapps/FAave.sol";

function _isAaveLiquid(address _debtToken, uint256 _debtAmt)
    view
    returns (bool)
{
    return _isAaveUnderlyingLiquid(_debtToken, _debtAmt);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import {
    _getUserData,
    _getAssetLiquidationThreshold
} from "../../../../functions/dapps/FAave.sol";
import {AaveUserData} from "../../../../structs/SAave.sol";
import {GelatoBytes} from "../../../../lib/GelatoBytes.sol";
import {wdiv, wmul, mul} from "../../../../vendor/DSMath.sol";
import {
    IOracleAggregator
} from "../../../../interfaces/gelato/IOracleAggregator.sol";
import {ETH, DAI} from "../../../../constants/CTokens.sol";
import {_convertTo18} from "../../../../vendor/Convert.sol";

function _aavePositionWillBeSafe(
    address _dsa,
    uint256 _colAmt,
    address _colToken,
    uint256 _debtAmt,
    address _oracleAggregator
) view returns (bool) {
    uint256 _colAmtInETH;
    uint256 _decimals;
    IOracleAggregator oracleAggregator = IOracleAggregator(_oracleAggregator);

    AaveUserData memory userData = _getUserData(_dsa);

    if (_colToken == ETH) _colAmtInETH = _colAmt;
    else {
        (_colAmtInETH, _decimals) = oracleAggregator.getExpectedReturnAmount(
            _colAmt,
            _colToken,
            ETH
        );

        _colAmtInETH = _convertTo18(_decimals, _colAmtInETH);
    }

    (_debtAmt, _decimals) = oracleAggregator.getExpectedReturnAmount(
        _debtAmt,
        DAI,
        ETH
    );
    _debtAmt = _convertTo18(_decimals, _debtAmt);

    //
    //                  __
    //                  \
    //                  /__ (Collateral)i in ETH x (Liquidation Threshold)i
    //  HealthFactor =  _________________________________________________
    //
    //                  Total Borrows in ETH + Total Fees in ETH
    //

    return
        wdiv(
            (
                (mul(
                    userData.currentLiquidationThreshold,
                    userData.totalCollateralETH
                ) + mul(_colAmtInETH, _getAssetLiquidationThreshold(_colToken)))
            ) / 1e4,
            userData.totalBorrowsETH + _debtAmt
        ) > 1e18;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import {_isCompoundUnderlyingLiquidity} from "../../../dapps/FCompound.sol";

function _cTokenHasLiquidity(address _debtToken, uint256 _debtAmt)
    view
    returns (bool)
{
    return _isCompoundUnderlyingLiquidity(_debtToken, _debtAmt);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import {DAI} from "../../../../constants/CTokens.sol";
import {
    _getCToken,
    _wouldCompoundAccountBeLiquid
} from "../../../dapps/FCompound.sol";

function _compoundPositionWillBeSafe(
    address _dsa,
    address _colToken,
    uint256 _colAmt,
    address _debtToken,
    uint256 _debtAmt
) view returns (bool) {
    return
        _wouldCompoundAccountBeLiquid(
            _dsa,
            _getCToken(_colToken),
            _colAmt,
            _getCToken(_debtToken),
            _debtAmt
        );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import {
    _debtCeilingIsReachedNewVault,
    _debtCeilingIsReached,
    _isVaultOwner
} from "../../../../functions/dapps/FMaker.sol";

function _isDebtCeilingReached(
    address _dsa,
    uint256 _destVaultId,
    string memory _destColType,
    uint256 _daiDebtAmt
) view returns (bool) {
    _destVaultId = _isVaultOwner(_destVaultId, _dsa) ? _destVaultId : 0;

    return
        _debtCeilingIsReachedExplicit(_destVaultId, _destColType, _daiDebtAmt);
}

function _debtCeilingIsReachedExplicit(
    uint256 _destVaultId,
    string memory _destColType,
    uint256 _daiDebtAmt
) view returns (bool) {
    return
        _destVaultId == 0
            ? _debtCeilingIsReachedNewVault(_destColType, _daiDebtAmt)
            : _debtCeilingIsReached(_destVaultId, _daiDebtAmt);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import {
    _vaultWillBeSafe,
    _newVaultWillBeSafe,
    _isVaultOwner
} from "../../../../functions/dapps/FMaker.sol";

function _destVaultWillBeSafe(
    address _dsa,
    uint256 _destVaultId,
    string memory _destColType,
    uint256 _colAmt,
    uint256 _daiDebtAmt
) view returns (bool) {
    _destVaultId = _isVaultOwner(_destVaultId, _dsa) ? _destVaultId : 0;

    return
        _destVaultWillBeSafeExplicit(
            _destVaultId,
            _destColType,
            _colAmt,
            _daiDebtAmt
        );
}

function _destVaultWillBeSafeExplicit(
    uint256 _destVaultId,
    string memory _destColType,
    uint256 _colAmt,
    uint256 _daiDebtAmt
) view returns (bool) {
    return
        _destVaultId == 0
            ? _newVaultWillBeSafe(_destColType, _colAmt, _daiDebtAmt)
            : _vaultWillBeSafe(_destVaultId, _colAmt, _daiDebtAmt);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import {
    _debtIsDustNewVault,
    _debtIsDust,
    _isVaultOwner
} from "../../../../functions/dapps/FMaker.sol";

function _isDebtAmtDust(
    address _dsa,
    uint256 _destVaultId,
    string memory _destColType,
    uint256 _daiDebtAmt
) view returns (bool) {
    _destVaultId = _isVaultOwner(_destVaultId, _dsa) ? _destVaultId : 0;

    return _isDebtAmtDustExplicit(_destVaultId, _destColType, _daiDebtAmt);
}

function _isDebtAmtDustExplicit(
    uint256 _destVaultId,
    string memory _destColType,
    uint256 _daiDebtAmt
) view returns (bool) {
    return
        _destVaultId == 0
            ? _debtIsDustNewVault(_destColType, _daiDebtAmt)
            : _debtIsDust(_destVaultId, _daiDebtAmt);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

/// @notice Interface InstaDapp Index
interface IndexInterface {
    function connectors(uint256 version) external view returns (address);

    function list() external view returns (address);
}

/// @notice Interface InstaDapp List
interface ListInterface {
    function accountID(address _account) external view returns (uint64);
}

/// @notice Interface InstaDapp InstaMemory
interface MemoryInterface {
    function setUint(uint256 _id, uint256 _val) external;

    function getUint(uint256 _id) external returns (uint256);
}

/// @notice Interface InstaDapp Defi Smart Account wallet
interface AccountInterface {
    function cast(
        address[] calldata _targets,
        bytes[] calldata _datas,
        address _origin
    ) external payable returns (bytes32[] memory responses);

    function version() external view returns (uint256);

    function isAuth(address user) external view returns (bool);

    function shield() external view returns (bool);
}

interface ConnectorInterface {
    function connectorID() external view returns (uint256 _type, uint256 _id);

    function name() external view returns (string memory);
}

interface InstaMapping {
    function gemJoinMapping(bytes32) external view returns (address);

    function cTokenMapping(address) external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface IInstaFeeCollector {
    function setFeeCollector(address payable _feeCollector) external;

    function setFee(uint256 _fee) external;

    function fee() external view returns (uint256);

    function feeCollector() external view returns (address payable);
}

// "SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.8.0;

interface IInstaPoolResolver {
    struct RouteData {
        uint256 dydx;
        uint256 maker;
        uint256 compound;
        uint256 aave;
    }

    function getTokenLimit(address token)
        external
        view
        returns (RouteData memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface ChainLinkInterface {
    function latestAnswer() external view returns (int256);

    function decimals() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface IAaveProtocolDataProvider {
    function getUserReserveData(address asset, address user)
        external
        view
        returns (
            uint256 currentATokenBalance,
            uint256 currentStableDebt,
            uint256 currentVariableDebt,
            uint256 principalStableDebt,
            uint256 scaledVariableDebt,
            uint256 stableBorrowRate,
            uint256 liquidityRate,
            uint40 stableRateLastUpdated,
            bool usageAsCollateralEnabled
        );

    function getReserveConfigurationData(address asset)
        external
        view
        returns (
            uint256 decimals,
            uint256 ltv,
            uint256 liquidationThreshold,
            uint256 liquidationBonus,
            uint256 reserveFactor,
            bool usageAsCollateralEnabled,
            bool borrowingEnabled,
            bool stableBorrowRateEnabled,
            bool isActive,
            bool isFrozen
        );

    function getReserveData(address asset)
        external
        view
        returns (
            uint256 availableLiquidity,
            uint256 totalStableDebt,
            uint256 totalVariableDebt,
            uint256 liquidityRate,
            uint256 variableBorrowRate,
            uint256 stableBorrowRate,
            uint256 averageStableBorrowRate,
            uint256 liquidityIndex,
            uint256 variableBorrowIndex,
            uint40 lastUpdateTimestamp
        );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import {ReserveData} from "../../../structs/SAave.sol";

interface ILendingPool {
    function getReserveData(address asset)
        external
        view
        returns (ReserveData memory);

    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );

    function getReservesList() external view returns (address[] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface ILendingPoolAddressesProvider {
    function getLendingPool() external view returns (address);

    function getPriceOracle() external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface ICToken {
    function getAccountSnapshot(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function getCash() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import {ICToken} from "./ICToken.sol";

interface IComptroller {
    function getAssetsIn(address account)
        external
        view
        returns (ICToken[] memory);

    function oracle() external view returns (address);

    function markets(address cToken)
        external
        view
        returns (
            bool isListed,
            uint256 collateralFactorMantissa,
            bool isComped
        );

    function getAccountLiquidity(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import {ICToken} from "./ICToken.sol";

interface IPriceOracle {
    function getUnderlyingPrice(ICToken cToken) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface IMcdManager {
    function ilks(uint256) external view returns (bytes32);

    function urns(uint256) external view returns (address);

    function vat() external view returns (address);

    function owns(uint256) external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface ITokenJoinInterface {
    function dec() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface IVat {
    function ilks(bytes32)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function dai(address) external view returns (uint256);

    function urns(bytes32, address) external view returns (uint256, uint256);

    function debt() external view returns (uint256);

    // solhint-disable-next-line
    function Line() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface IGelatoGasPriceOracle {
    function latestAnswer() external view returns (int256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IOracleAggregator {
    function getExpectedReturnAmount(
        uint256 amountIn,
        address inToken,
        address outToken
    ) external view returns (uint256 returnAmount, uint256 outTokenDecimals);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

library GelatoBytes {
    function calldataSliceSelector(bytes calldata _bytes)
        internal
        pure
        returns (bytes4 selector)
    {
        selector =
            _bytes[0] |
            (bytes4(_bytes[1]) >> 8) |
            (bytes4(_bytes[2]) >> 16) |
            (bytes4(_bytes[3]) >> 24);
    }

    function memorySliceSelector(bytes memory _bytes)
        internal
        pure
        returns (bytes4 selector)
    {
        selector =
            _bytes[0] |
            (bytes4(_bytes[1]) >> 8) |
            (bytes4(_bytes[2]) >> 16) |
            (bytes4(_bytes[3]) >> 24);
    }

    function revertWithError(bytes memory _bytes, string memory _tracingInfo)
        internal
        pure
    {
        // 68: 32-location, 32-length, 4-ErrorSelector, UTF-8 err
        if (_bytes.length % 32 == 4) {
            bytes4 selector;
            assembly {
                selector := mload(add(0x20, _bytes))
            }
            if (selector == 0x08c379a0) {
                // Function selector for Error(string)
                assembly {
                    _bytes := add(_bytes, 68)
                }
                revert(string(abi.encodePacked(_tracingInfo, string(_bytes))));
            } else {
                revert(
                    string(abi.encodePacked(_tracingInfo, "NoErrorSelector"))
                );
            }
        } else {
            revert(
                string(abi.encodePacked(_tracingInfo, "UnexpectedReturndata"))
            );
        }
    }

    function returnError(bytes memory _bytes, string memory _tracingInfo)
        internal
        pure
        returns (string memory)
    {
        // 68: 32-location, 32-length, 4-ErrorSelector, UTF-8 err
        if (_bytes.length % 32 == 4) {
            bytes4 selector;
            assembly {
                selector := mload(add(0x20, _bytes))
            }
            if (selector == 0x08c379a0) {
                // Function selector for Error(string)
                assembly {
                    _bytes := add(_bytes, 68)
                }
                return string(abi.encodePacked(_tracingInfo, string(_bytes)));
            } else {
                return
                    string(abi.encodePacked(_tracingInfo, "NoErrorSelector"));
            }
        } else {
            return
                string(abi.encodePacked(_tracingInfo, "UnexpectedReturndata"));
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

// ////////// LendingPool /////////////////
struct AaveUserData {
    uint256 totalCollateralETH;
    uint256 totalBorrowsETH;
    uint256 availableBorrowsETH;
    uint256 currentLiquidationThreshold;
    uint256 ltv;
    uint256 healthFactor;
    uint256 ethPriceInUsd;
}

struct ReserveConfigurationMap {
    uint256 data;
}

struct ReserveData {
    //stores the reserve configuration
    ReserveConfigurationMap configuration;
    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    //the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    //the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    //the current stable borrow rate. Expressed in ray
    uint128 currentStableBorrowRate;
    uint40 lastUpdateTimestamp;
    //tokens addresses
    address aTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    //address of the interest rate strategy
    address interestRateStrategyAddress;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint8 id;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

struct DebtBridgeInputData {
    address dsa;
    uint256 colAmt;
    address colToken;
    uint256 debtAmt;
    address oracleAggregator;
    uint256 makerDestVaultId;
    string makerDestColType;
    uint256 fees;
    uint256 flashRoute;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import {mul as _mul} from "./DSMath.sol";

function _stringToBytes32(string memory str) pure returns (bytes32 result) {
    require(bytes(str).length != 0, "string-empty");
    assembly {
        result := mload(add(str, 32))
    }
}

function _convertTo18(uint256 _dec, uint256 _amt) pure returns (uint256 amt) {
    amt = _mul(_amt, 10**(18 - _dec));
}

// "SPDX-License-Identifier: AGPL-3.0-or-later"
/// math.sol -- mixin for inline numerical wizardry

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.8.0;

function add(uint256 x, uint256 y) pure returns (uint256 z) {
    require((z = x + y) >= x, "ds-math-add-overflow");
}

function sub(uint256 x, uint256 y) pure returns (uint256 z) {
    require((z = x - y) <= x, "ds-math-sub-underflow");
}

function mul(uint256 x, uint256 y) pure returns (uint256 z) {
    require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
}

function min(uint256 x, uint256 y) pure returns (uint256 z) {
    return x <= y ? x : y;
}

function max(uint256 x, uint256 y) pure returns (uint256 z) {
    return x >= y ? x : y;
}

function imin(int256 x, int256 y) pure returns (int256 z) {
    return x <= y ? x : y;
}

function imax(int256 x, int256 y) pure returns (int256 z) {
    return x >= y ? x : y;
}

uint256 constant WAD = 10**18;
uint256 constant RAY = 10**27;

//rounds to zero if x*y < WAD / 2
function wmul(uint256 x, uint256 y) pure returns (uint256 z) {
    z = add(mul(x, y), WAD / 2) / WAD;
}

//rounds to zero if x*y < WAD / 2
function rmul(uint256 x, uint256 y) pure returns (uint256 z) {
    z = add(mul(x, y), RAY / 2) / RAY;
}

//rounds to zero if x*y < WAD / 2
function wdiv(uint256 x, uint256 y) pure returns (uint256 z) {
    z = add(mul(x, WAD), y / 2) / y;
}

//rounds to zero if x*y < RAY / 2
function rdiv(uint256 x, uint256 y) pure returns (uint256 z) {
    z = add(mul(x, RAY), y / 2) / y;
}

// This famous algorithm is called "exponentiation by squaring"
// and calculates x^n with x as fixed-point and n as regular unsigned.
//
// It's O(log n), instead of O(n) for naive repeated multiplication.
//
// These facts are why it works:
//
//  If n is even, then x^n = (x^2)^(n/2).
//  If n is odd,  then x^n = x * x^(n-1),
//   and applying the equation for even x gives
//    x^n = x * (x^2)^((n-1) / 2).
//
//  Also, EVM division is flooring and
//    floor[(n-1) / 2] = floor[n / 2].
//
function rpow(uint256 x, uint256 n) pure returns (uint256 z) {
    z = n % 2 != 0 ? x : RAY;

    for (n /= 2; n != 0; n /= 2) {
        x = rmul(x, x);

        if (n % 2 != 0) {
            z = rmul(z, x);
        }
    }
}