// SPDX-License-Identifier: bsl-1.1

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

// import ".//IUniswapV2PairFull.sol";
import "../interfaces/IVault.sol";
import "../interfaces/IVaultParameters.sol";
import "../interfaces/ICdpManagerParameters.sol";
import "../interfaces/IOracleRegistry.sol";
import "../interfaces/IToken.sol";

interface IMaker {
    function symbol() external view returns(bytes32);
}

contract CDPViewer {

    IVault public vault;
    IVaultParameters public  vaultParameters;
    ICdpManagerParameters public  cdpManagerParameters;
    IOracleRegistry public  oracleRegistry;

    struct CDP {

        // Collateral amount
        uint128 collateral;

        // Debt amount
        uint128 debt;

        // Percentage with 3 decimals
        uint32 stabilityFee;

        uint32 lastUpdate;

        // Percentage with 0 decimals
        uint16 liquidationFee;

        uint16 oracleType;
    }

    struct CollateralParameters {

        // USDP mint limit
        uint128 tokenDebtLimit;

        // USDP mint limit
        uint128 tokenDebt;

        // Percentage with 3 decimals
        uint32 stabilityFee;

        // Percentage with 3 decimals
        uint32 liquidationDiscount;

        // Devaluation period in blocks
        uint32 devaluationPeriod;

        // Percentage with 0 decimals
        uint16 liquidationRatio;

        // Percentage with 0 decimals
        uint16 initialCollateralRatio;

        // Percentage with 0 decimals
        uint16 liquidationFee;

        // Oracle types enabled for this asset
        uint16 oracleType;

        CDP cdp;
    }

    struct TokenDetails {
        address[2] lpUnderlyings;
        uint128 balance;
        uint128 totalSupply;
    }


    constructor(address _cdpManagerParameters, address _oracleRegistry) {
         cdpManagerParameters = ICdpManagerParameters(_cdpManagerParameters);
         vaultParameters = IVaultParameters(ICdpManagerParameters(_cdpManagerParameters).vaultParameters());
         vault = IVault(IVaultParameters(ICdpManagerParameters(_cdpManagerParameters).vaultParameters()).vault());
         oracleRegistry = IOracleRegistry(_oracleRegistry);
    }

    /**
     * @notice Get parameters of one asset
     * @param asset asset address
     * @param owner owner address
     */
    function getCollateralParameters(address asset, address owner)
        public
        view
        returns (CollateralParameters memory r)
    {
        r.stabilityFee = uint32(vaultParameters.stabilityFee(asset));
        r.liquidationFee = uint16(vaultParameters.liquidationFee(asset));
        r.initialCollateralRatio = uint16(cdpManagerParameters.initialCollateralRatio(asset));
        r.liquidationRatio = uint16(cdpManagerParameters.liquidationRatio(asset));
        r.liquidationDiscount = uint32(cdpManagerParameters.liquidationDiscount(asset));
        r.devaluationPeriod = uint32(cdpManagerParameters.devaluationPeriod(asset));

        r.tokenDebtLimit = uint128(vaultParameters.tokenDebtLimit(asset));
        r.tokenDebt = uint128(vault.tokenDebts(asset));
        r.oracleType = uint16(oracleRegistry.oracleTypeByAsset(asset));

        if (owner == address(0)) return r;
        r.cdp.stabilityFee = uint32(vault.stabilityFee(asset, owner));
        r.cdp.liquidationFee = uint16(vault.liquidationFee(asset, owner));
        r.cdp.debt = uint128(vault.debts(asset, owner));
        r.cdp.collateral = uint128(vault.collaterals(asset, owner));
        r.cdp.lastUpdate = uint32(vault.lastUpdate(asset, owner));
        r.cdp.oracleType = uint16(vault.oracleType(asset, owner));
    }

    /**
     * @notice Get details of one token
     * @param asset token address
     * @param owner owner address
     */
    function getTokenDetails(address asset, address owner)
        public
        view
        returns (TokenDetails memory r)
    {
        // TODO: 兼容uniswap token
        // try IUniswapV2PairFull(asset).token0() returns(address token0) {
        //     r.lpUnderlyings[0] = token0;
        //     r.lpUnderlyings[1] = IUniswapV2PairFull(asset).token1();
        //     r.totalSupply = uint128(IUniswapV2PairFull(asset).totalSupply());
        // } catch (bytes memory) { }

        if (owner == address(0)) return r;
        r.balance = uint128(IToken(asset).balanceOf(owner));
    }

    /**
     * @notice Get parameters of many collaterals
     * @param assets asset addresses
     * @param owner owner address
     */
    function getMultiCollateralParameters(address[] calldata assets, address owner)
        external
        view
        returns (CollateralParameters[] memory r)
    {
        uint length = assets.length;
        r = new CollateralParameters[](length);
        for (uint i = 0; i < length; ++i) {
            r[i] = getCollateralParameters(assets[i], owner);
        }
    }

    /**
     * @notice Get details of many token
     * @param assets token addresses
     * @param owner owner address
     */
    function getMultiTokenDetails(address[] calldata assets, address owner)
        external
        view
        returns (TokenDetails[] memory r)
    {
        uint length = assets.length;
        r = new TokenDetails[](length);
        for (uint i = 0; i < length; ++i) {
            r[i] = getTokenDetails(assets[i], owner);
        }
    }
}

// SPDX-License-Identifier: bsl-1.1

pragma solidity 0.7.6;

interface IVault {
    /**
       计算用常量定义
    */
    function DENOMINATOR_1E5() external view returns (uint);
    
    /**
       Token变量
    */
    function weth() external view returns (address payable);
    function usdg() external view returns (address);
    
    /**
       业务相关变量
    */
    function collaterals(address, address) external view returns (uint);
    function debts(address, address) external view returns (uint);
    function liquidationBlock(address, address) external view returns (uint);
    function liquidationPrice(address, address) external view returns (uint);
    function tokenDebts(address) external view returns (uint);
    function stabilityFee(address, address) external view returns (uint);
    function liquidationFee(address, address) external view returns (uint);
    function oracleType(address, address) external view returns (uint);
    function lastUpdate(address, address) external view returns (uint);
    
    /**
        业务函数
    */
    function spawn(address asset, address user, uint _oracleType) external;
    function destroy(address asset, address user) external;
    function depositMain(address asset, address user, uint amount) external;
    function depositEth(address user) external payable;
    function withdrawMain(address asset, address user, uint amount) external;
    function WithdrawEth(address payable user, uint amount) external;
    function borrow(address asset, address user, uint amount) external returns (uint);
    function repay(address asset, address user, uint amount) external returns(uint) ;
    function triggerLiquidation(address asset, address positionOwner, uint initialPrice) external;
    function liquidate(address asset, address positionOwner, uint mainAssetToLiquidator, uint mainAssetToPositionOwner, uint repayment, uint penalty, address liquidator) external;

    /**
        工具函数
    */
    function chargeFee(address asset, address user, uint amount) external;
    function update(address asset, address user) external;
    function getTotalDebt(address asset, address user) external view returns (uint) ;
    function calculateFee(address asset, address user, uint debt) external view returns (uint) ;
    function changeOracleType(address asset, address user, uint newOracleType) external;
}

// SPDX-License-Identifier: bsl-1.1

pragma solidity 0.7.6;

interface IVaultParameters {
    
    /**
      重要成员变量
    */
    function vault() external view returns (address);
    function vaultParameters() external view returns (address);
    function foundation() external view returns (address);

    /**
      系统权限相关变量
    */
    function isManager(address) external view returns (bool);
    function canModifyVault(address) external view returns (bool);

    /**
      业务流程相关变量
    */
    function stabilityFee(address) external view returns (uint256);
    function liquidationFee(address) external view returns (uint256);
    function tokenDebtLimit(address) external view returns (uint256);
    function isOracleTypeEnabled(uint256, address) external view returns (bool);
    
    /**
       业务函数
    */
    function setCollateral(address asset, uint stabilityFeeValue, uint liquidationFeeValue, uint tokenDebtLimitValue, uint[] calldata oracles) external; 
    function setFoundation(address newFoundation) external;
    function setManager(address who, bool isPermit) external;
    function setVaultAccess(address who, bool isPermit) external;
    function setStabilityFee(address asset, uint fee) external;
    function setLiquidationFee(address asset, uint fee) external;
    function setTokenDebtLimit(address asset, uint limit) external;
    function setOracleType(uint _type, address asset, bool enable) external;
}

// SPDX-License-Identifier: bsl-1.1

pragma solidity 0.7.6;

interface ICdpManagerParameters {
    /**
       业务相关变量
    */
    function initialCollateralRatio(address) external view returns (uint256);
    function liquidationRatio(address) external view returns (uint256);
    function liquidationDiscount(address) external view returns (uint256);
    function devaluationPeriod(address) external view returns (uint256);
    function vaultParameters() external view returns (address);

    /**
        业务函数
    */
    function setCollateral(
        address asset,
        uint stabilityFeeValue,
        uint liquidationFeeValue,
        uint initialCollateralRatioValue,
        uint liquidationRatioValue,
        uint liquidationDiscountValue,
        uint devaluationPeriodValue,
        uint usdgLimit,
        uint[] calldata oracles
    ) external ;

    /**
        工具函数
    */
    function setInitialCollateralRatio(address asset, uint newValue) external;
    function setLiquidationRatio(address asset, uint newValue) external;
    function setLiquidationDiscount(address asset, uint newValue) external;
    function setDevaluationPeriod(address asset, uint newValue) external;
}

// SPDX-License-Identifier: bsl-1.1

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

interface IOracleRegistry{

    struct Oracle {
        uint oracleType;
        address oracleAddress;
    }

    /**
       业务相关变量
    */
    function vaultParameters() external view returns (address);
    function maxOracleType() external view returns (uint256);
    function WETH() external view returns (address);
    function oracleByType(uint256) external view returns (address);
    function oracleTypeByOracle(address) external view returns (uint256);
    function oracleTypeByAsset(address) external view returns (uint256);

    /**
       Oracle管理（增删改查）
    */
    function setOracle(uint oracleType, address oracle) external;
    function unsetOracle(uint oracleType) external;
    function getOracles() external view returns (Oracle[] memory foundOracles);

    /**
       Oracle与Asset相关操作
    */
    function setOracleTypeForAsset(address asset, uint oracleType) external;
    function setOracleTypeForAssets(address[] calldata assets, uint oracleType) external;
    function unsetOracleTypeForAsset(address asset) external;
    function unsetOracleTypeForAssets(address[] calldata assets) external;
    function oracleByAsset(address asset) external view returns (address);
}

// SPDX-License-Identifier: bsl-1.1

pragma solidity 0.7.6;

interface IToken {
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function balanceOf(address) external view returns (uint);
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}