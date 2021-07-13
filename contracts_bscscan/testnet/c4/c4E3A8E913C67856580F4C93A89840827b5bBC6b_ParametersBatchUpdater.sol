/**
 *Submitted for verification at BscScan.com on 2021-07-13
*/

/*
    Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
    This program is distributed in the hope that it will be useful,  but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE; Contact [email protected] 
*/

pragma solidity 0.7.6;
pragma abicoder v2;


contract Auth {

    // address of the the contract with vault parameters
    VaultParameters public vaultParameters;

    constructor(address _parameters) {
        vaultParameters = VaultParameters(_parameters);
    }

    // ensures tx's sender is a manager
    modifier onlyManager() {
        require(vaultParameters.isManager(msg.sender), "CryptoPeso protocol : AUTH_FAILED");
        _;
    }

    // ensures tx's sender is able to modify the Vault
    modifier hasVaultAccess() {
        require(vaultParameters.canModifyVault(msg.sender), "CryptoPeso protocol : AUTH_FAILED");
        _;
    }

    // ensures tx's sender is the Vault
    modifier onlyVault() {
        require(msg.sender == vaultParameters.vault(), "CryptoPeso protocol : AUTH_FAILED");
        _;
    }
}

contract VaultParameters is Auth {

    // map token to stability fee percentage; 3 decimals
    mapping(address => uint) public stabilityFee;

    // map token to liquidation fee percentage, 0 decimals
    mapping(address => uint) public liquidationFee;

    // map token to USDP mint limit
    mapping(address => uint) public tokenDebtLimit;

    // permissions to modify the Vault
    mapping(address => bool) public canModifyVault;

    // managers
    mapping(address => bool) public isManager;

    // enabled oracle types
    mapping(uint => mapping (address => bool)) public isOracleTypeEnabled;

    // address of the Vault
    address payable public vault;

    // The foundation address
    address public foundation;

    /**
     * The address for an Ethereum contract is deterministically computed from the address of its creator (sender)
     * and how many transactions the creator has sent (nonce). The sender and nonce are RLP encoded and then
     * hashed with Keccak-256.
     * Therefore, the Vault address can be pre-computed and passed as an argument before deployment.
    **/
    constructor(address payable _vault, address _foundation) Auth(address(this)) {
        require(_vault != address(0), "CryptoPeso protocol : ZERO_ADDRESS");
        require(_foundation != address(0), "CryptoPeso protocol : ZERO_ADDRESS");

        isManager[msg.sender] = true;
        vault = _vault;
        foundation = _foundation;
    }

    /**
     * @notice Only manager is able to call this function
     * @dev Grants and revokes manager's status of any address
     * @param who The target address
     * @param permit The permission flag
     **/
    function setManager(address who, bool permit) external onlyManager {
        isManager[who] = permit;
    }

    /**
     * @notice Only manager is able to call this function
     * @dev Sets the foundation address
     * @param newFoundation The new foundation address
     **/
    function setFoundation(address newFoundation) external onlyManager {
        require(newFoundation != address(0), "CryptoPeso protocol : ZERO_ADDRESS");
        foundation = newFoundation;
    }

    /**
     * @notice Only manager is able to call this function
     * @dev Sets ability to use token as the main collateral
     * @param asset The address of the main collateral token
     * @param stabilityFeeValue The percentage of the year stability fee (3 decimals)
     * @param liquidationFeeValue The liquidation fee percentage (0 decimals)
     * @param usdpLimit The USDP token issue limit
     * @param oracles The enables oracle types
     **/
    function setCollateral(
        address asset,
        uint stabilityFeeValue,
        uint liquidationFeeValue,
        uint usdpLimit,
        uint[] calldata oracles
    ) external onlyManager {
        setStabilityFee(asset, stabilityFeeValue);
        setLiquidationFee(asset, liquidationFeeValue);
        setTokenDebtLimit(asset, usdpLimit);
        for (uint i=0; i < oracles.length; i++) {
            setOracleType(oracles[i], asset, true);
        }
    }

    /**
     * @notice Only manager is able to call this function
     * @dev Sets a permission for an address to modify the Vault
     * @param who The target address
     * @param permit The permission flag
     **/
    function setVaultAccess(address who, bool permit) external onlyManager {
        canModifyVault[who] = permit;
    }

    /**
     * @notice Only manager is able to call this function
     * @dev Sets the percentage of the year stability fee for a particular collateral
     * @param asset The address of the main collateral token
     * @param newValue The stability fee percentage (3 decimals)
     **/
    function setStabilityFee(address asset, uint newValue) public onlyManager {
        stabilityFee[asset] = newValue;
    }

    /**
     * @notice Only manager is able to call this function
     * @dev Sets the percentage of the liquidation fee for a particular collateral
     * @param asset The address of the main collateral token
     * @param newValue The liquidation fee percentage (0 decimals)
     **/
    function setLiquidationFee(address asset, uint newValue) public onlyManager {
        require(newValue <= 100, "CryptoPeso protocol : VALUE_OUT_OF_RANGE");
        liquidationFee[asset] = newValue;
    }

    /**
     * @notice Only manager is able to call this function
     * @dev Enables/disables oracle types
     * @param _type The type of the oracle
     * @param asset The address of the main collateral token
     * @param enabled The control flag
     **/
    function setOracleType(uint _type, address asset, bool enabled) public onlyManager {
        isOracleTypeEnabled[_type][asset] = enabled;
    }

    /**
     * @notice Only manager is able to call this function
     * @dev Sets USDP limit for a specific collateral
     * @param asset The address of the main collateral token
     * @param limit The limit number
     **/
    function setTokenDebtLimit(address asset, uint limit) public onlyManager {
        tokenDebtLimit[asset] = limit;
    }
}

interface IVaultManagerParameters {
    function devaluationPeriod ( address ) external view returns ( uint256 );
    function initialCollateralRatio ( address ) external view returns ( uint256 );
    function liquidationRatio ( address ) external view returns ( uint256 );
    function maxColPercent ( address ) external view returns ( uint256 );
    function minColPercent ( address ) external view returns ( uint256 );
    function setColPartRange ( address asset, uint256 min, uint256 max ) external;
    function setCollateral (
        address asset,
        uint256 stabilityFeeValue,
        uint256 liquidationFeeValue,
        uint256 initialCollateralRatioValue,
        uint256 liquidationRatioValue,
        uint256 devaluationPeriodValue,
        uint256 usdpLimit,
        uint256[] calldata oracles,
        uint256 minColP,
        uint256 maxColP
    ) external;
    function setDevaluationPeriod ( address asset, uint256 newValue ) external;
    function setInitialCollateralRatio ( address asset, uint256 newValue ) external;
    function setLiquidationRatio ( address asset, uint256 newValue ) external;
    function vaultParameters (  ) external view returns ( address );
}

interface IBearingAssetOracle {
    function assetToUsd ( address bearing, uint256 amount ) external view returns ( uint256 );
    function bearingToUnderlying ( address bearing, uint256 amount ) external view returns ( address, uint256 );
    function oracleRegistry (  ) external view returns ( address );
    function setUnderlying ( address bearing, address underlying ) external;
    function vaultParameters (  ) external view returns ( address );
}

interface IOracleRegistry {

    struct Oracle {
        uint oracleType;
        address oracleAddress;
    }

    function WETH (  ) external view returns ( address );
    function getKeydonixOracleTypes (  ) external view returns ( uint256[] memory );
    function getOracles (  ) external view returns ( Oracle[] memory foundOracles );
    function keydonixOracleTypes ( uint256 ) external view returns ( uint256 );
    function maxOracleType (  ) external view returns ( uint256 );
    function oracleByAsset ( address asset ) external view returns ( address );
    function oracleByType ( uint256 ) external view returns ( address );
    function oracleTypeByAsset ( address ) external view returns ( uint256 );
    function oracleTypeByOracle ( address ) external view returns ( uint256 );
    function setKeydonixOracleTypes ( uint256[] memory _keydonixOracleTypes ) external;
    function setOracle ( uint256 oracleType, address oracle ) external;
    function setOracleTypeForAsset ( address asset, uint256 oracleType ) external;
    function setOracleTypeForAssets ( address[] memory assets, uint256 oracleType ) external;
    function unsetOracle ( uint256 oracleType ) external;
    function unsetOracleForAsset ( address asset ) external;
    function unsetOracleForAssets ( address[] memory assets ) external;
    function vaultParameters (  ) external view returns ( address );
}


interface ICollateralRegistry {
    function addCollateral ( address asset ) external;
    function collateralId ( address ) external view returns ( uint256 );
    function collaterals (  ) external view returns ( address[] memory );
    function removeCollateral ( address asset ) external;
    function vaultParameters (  ) external view returns ( address );
    function isCollateral ( address asset ) external view returns ( bool );
    function collateralList ( uint id ) external view returns ( address );
    function collateralsCount (  ) external view returns ( uint );
}

interface IVault {
    function DENOMINATOR_1E2 (  ) external view returns ( uint256 );
    function DENOMINATOR_1E5 (  ) external view returns ( uint256 );
    function borrow ( address asset, address user, uint256 amount ) external returns ( uint256 );
    function calculateFee ( address asset, address user, uint256 amount ) external view returns ( uint256 );
    function changeOracleType ( address asset, address user, uint256 newOracleType ) external;
    function chargeFee ( address asset, address user, uint256 amount ) external;
    function col (  ) external view returns ( address );
    function colToken ( address, address ) external view returns ( uint256 );
    function collaterals ( address, address ) external view returns ( uint256 );
    function debts ( address, address ) external view returns ( uint256 );
    function depositCol ( address asset, address user, uint256 amount ) external;
    function depositEth ( address user ) external payable;
    function depositMain ( address asset, address user, uint256 amount ) external;
    function destroy ( address asset, address user ) external;
    function getTotalDebt ( address asset, address user ) external view returns ( uint256 );
    function lastUpdate ( address, address ) external view returns ( uint256 );
    function liquidate ( address asset, address positionOwner, uint256 mainAssetToLiquidator, uint256 colToLiquidator, uint256 mainAssetToPositionOwner, uint256 colToPositionOwner, uint256 repayment, uint256 penalty, address liquidator ) external;
    function liquidationBlock ( address, address ) external view returns ( uint256 );
    function liquidationFee ( address, address ) external view returns ( uint256 );
    function liquidationPrice ( address, address ) external view returns ( uint256 );
    function oracleType ( address, address ) external view returns ( uint256 );
    function repay ( address asset, address user, uint256 amount ) external returns ( uint256 );
    function spawn ( address asset, address user, uint256 _oracleType ) external;
    function stabilityFee ( address, address ) external view returns ( uint256 );
    function tokenDebts ( address ) external view returns ( uint256 );
    function triggerLiquidation ( address asset, address positionOwner, uint256 initialPrice ) external;
    function update ( address asset, address user ) external;
    function usdp (  ) external view returns ( address );
    function vaultParameters (  ) external view returns ( address );
    function weth (  ) external view returns ( address payable );
    function withdrawCol ( address asset, address user, uint256 amount ) external;
    function withdrawEth ( address user, uint256 amount ) external;
    function withdrawMain ( address asset, address user, uint256 amount ) external;
}



/**
 * @title ParametersBatchUpdater
 **/
contract ParametersBatchUpdater is Auth {

    IVaultManagerParameters public immutable vaultManagerParameters;
    IOracleRegistry public immutable oracleRegistry;
    ICollateralRegistry public immutable collateralRegistry;

    uint public constant BEARING_ASSET_ORACLE_TYPE = 9;

    constructor(
        address _vaultManagerParameters,
        address _oracleRegistry,
        address _collateralRegistry
    ) Auth(IVaultManagerParameters(_vaultManagerParameters).vaultParameters()) {
        require(
            _vaultManagerParameters != address(0) &&
            _oracleRegistry != address(0) &&
            _collateralRegistry != address(0), "CryptoPeso protocol : ZERO_ADDRESS");
        vaultManagerParameters = IVaultManagerParameters(_vaultManagerParameters);
        oracleRegistry = IOracleRegistry(_oracleRegistry);
        collateralRegistry = ICollateralRegistry(_collateralRegistry);
    }

    /**
     * @notice Only manager is able to call this function
     * @dev Grants and revokes manager's status
     * @param who The array of target addresses
     * @param permit The array of permission flags
     **/
    function setManagers(address[] calldata who, bool[] calldata permit) external onlyManager {
        require(who.length == permit.length, "CryptoPeso protocol : ARGUMENTS_LENGTH_MISMATCH");
        for (uint i = 0; i < who.length; i++) {
            vaultParameters.setManager(who[i], permit[i]);
        }
    }

    /**
     * @notice Only manager is able to call this function
     * @dev Sets a permission for provided addresses to modify the Vault
     * @param who The array of target addresses
     * @param permit The array of permission flags
     **/
    function setVaultAccesses(address[] calldata who, bool[] calldata permit) external onlyManager {
        require(who.length == permit.length, "CryptoPeso protocol : ARGUMENTS_LENGTH_MISMATCH");
        for (uint i = 0; i < who.length; i++) {
            vaultParameters.setVaultAccess(who[i], permit[i]);
        }
    }

    /**
     * @notice Only manager is able to call this function
     * @dev Sets the percentage of the year stability fee for a particular collateral
     * @param assets The array of addresses of the main collateral tokens
     * @param newValues The array of stability fee percentages (3 decimals)
     **/
    function setStabilityFees(address[] calldata assets, uint[] calldata newValues) public onlyManager {
        require(assets.length == newValues.length, "CryptoPeso protocol : ARGUMENTS_LENGTH_MISMATCH");
        for (uint i = 0; i < assets.length; i++) {
            vaultParameters.setStabilityFee(assets[i], newValues[i]);
        }
    }

    /**
     * @notice Only manager is able to call this function
     * @dev Sets the percentages of the liquidation fee for provided collaterals
     * @param assets The array of addresses of the main collateral tokens
     * @param newValues The array of liquidation fee percentages (0 decimals)
     **/
    function setLiquidationFees(address[] calldata assets, uint[] calldata newValues) public onlyManager {
        require(assets.length == newValues.length, "CryptoPeso protocol : ARGUMENTS_LENGTH_MISMATCH");
        for (uint i = 0; i < assets.length; i++) {
            vaultParameters.setLiquidationFee(assets[i], newValues[i]);
        }
    }

    /**
     * @notice Only manager is able to call this function
     * @dev Enables/disables oracle types
     * @param _types The array of types of the oracles
     * @param assets The array of addresses of the main collateral tokens
     * @param flags The array of control flags
     **/
    function setOracleTypes(uint[] calldata _types, address[] calldata assets, bool[] calldata flags) public onlyManager {
        require(_types.length == assets.length && _types.length == flags.length, "CryptoPeso protocol : ARGUMENTS_LENGTH_MISMATCH");
        for (uint i = 0; i < _types.length; i++) {
            vaultParameters.setOracleType(_types[i], assets[i], flags[i]);
        }
    }

    /**
     * @notice Only manager is able to call this function
     * @dev Sets USDP limits for a provided collaterals
     * @param assets The addresses of the main collateral tokens
     * @param limits The borrow USDP limits
     **/
    function setTokenDebtLimits(address[] calldata assets, uint[] calldata limits) public onlyManager {
        require(assets.length == limits.length, "CryptoPeso protocol : ARGUMENTS_LENGTH_MISMATCH");
        for (uint i = 0; i < assets.length; i++) {
            vaultParameters.setTokenDebtLimit(assets[i], limits[i]);
        }
    }

    function changeOracleTypes(address[] calldata assets, address[] calldata users, uint[] calldata oracleTypes) public onlyManager {
        require(assets.length == users.length && assets.length == oracleTypes.length, "CryptoPeso protocol : ARGUMENTS_LENGTH_MISMATCH");
        for (uint i = 0; i < assets.length; i++) {
            IVault(vaultParameters.vault()).changeOracleType(assets[i], users[i], oracleTypes[i]);
        }
    }

    function setInitialCollateralRatios(address[] calldata assets, uint[] calldata values) public onlyManager {
        require(assets.length == values.length, "CryptoPeso protocol : ARGUMENTS_LENGTH_MISMATCH");
        for (uint i = 0; i < assets.length; i++) {
            vaultManagerParameters.setInitialCollateralRatio(assets[i], values[i]);
        }
    }

    function setLiquidationRatios(address[] calldata assets, uint[] calldata values) public onlyManager {
        require(assets.length == values.length, "CryptoPeso protocol : ARGUMENTS_LENGTH_MISMATCH");
        for (uint i = 0; i < assets.length; i++) {
            vaultManagerParameters.setLiquidationRatio(assets[i], values[i]);
        }
    }
    
    function setDevaluationPeriods(address[] calldata assets, uint[] calldata values) public onlyManager {
        require(assets.length == values.length, "CryptoPeso protocol : ARGUMENTS_LENGTH_MISMATCH");
        for (uint i = 0; i < assets.length; i++) {
            vaultManagerParameters.setDevaluationPeriod(assets[i], values[i]);
        }
    }

    function setOracleTypesInRegistry(uint[] calldata oracleTypes, address[] calldata oracles) public onlyManager {
        require(oracleTypes.length == oracles.length, "CryptoPeso protocol : ARGUMENTS_LENGTH_MISMATCH");
        for (uint i = 0; i < oracleTypes.length; i++) {
            oracleRegistry.setOracle(oracleTypes[i], oracles[i]);
        }
    }

    function setOracleTypesToAssets(address[] calldata assets, uint[] calldata oracleTypes) public onlyManager {
        require(oracleTypes.length == assets.length, "CryptoPeso protocol : ARGUMENTS_LENGTH_MISMATCH");
        for (uint i = 0; i < assets.length; i++) {
            oracleRegistry.setOracleTypeForAsset(assets[i], oracleTypes[i]);
        }
    }

    function setOracleTypesToAssetsBatch(address[][] calldata assets, uint[] calldata oracleTypes) public onlyManager {
        require(oracleTypes.length == assets.length, "CryptoPeso protocol : ARGUMENTS_LENGTH_MISMATCH");
        for (uint i = 0; i < assets.length; i++) {
            oracleRegistry.setOracleTypeForAssets(assets[i], oracleTypes[i]);
        }
    }

    function setUnderlyings(address[] calldata bearings, address[] calldata underlyings) public onlyManager {
        require(bearings.length == underlyings.length, "CryptoPeso protocol : ARGUMENTS_LENGTH_MISMATCH");
        for (uint i = 0; i < bearings.length; i++) {
            IBearingAssetOracle(oracleRegistry.oracleByType(BEARING_ASSET_ORACLE_TYPE)).setUnderlying(bearings[i], underlyings[i]);
        }
    }

    function setCollaterals(
        address[] calldata assets,
        uint stabilityFeeValue,
        uint liquidationFeeValue,
        uint initialCollateralRatioValue,
        uint liquidationRatioValue,
        uint devaluationPeriodValue,
        uint usdpLimit,
        uint[] calldata oracles
    ) external onlyManager {
        for (uint i = 0; i < assets.length; i++) {
            vaultManagerParameters.setCollateral(
                assets[i],
                stabilityFeeValue,
                liquidationFeeValue,
                initialCollateralRatioValue,
                liquidationRatioValue,
                devaluationPeriodValue,
                usdpLimit,
                oracles,
                0,
                0
            );

            collateralRegistry.addCollateral(assets[i]);
        }
    }

    function setCollateralAddresses(address[] calldata assets, bool add) external onlyManager {
        for (uint i = 0; i < assets.length; i++) {
            add ? collateralRegistry.addCollateral(assets[i]) : collateralRegistry.removeCollateral(assets[i]);
        }
    }
}