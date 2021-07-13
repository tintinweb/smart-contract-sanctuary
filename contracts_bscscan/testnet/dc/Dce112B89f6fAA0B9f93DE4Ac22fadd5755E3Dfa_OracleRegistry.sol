/**
 *Submitted for verification at BscScan.com on 2021-07-13
*/

/**
 *Submitted for verification at BscScan.com on 2021-05-03
*/

// File: contracts/VaultParameters.sol

// SPDX-License-Identifier: bsl-1.1

/*
    Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
    This program is distributed in the hope that it will be useful,  but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE; Contact [email protected] 
*/

pragma solidity 0.7.6;



/**
 * @title Auth
 * @dev Manages USDP's system access
 **/
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



/**
 * @title VaultParameters
 **/
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

// File: contracts/oracles/OracleRegistry.sol

/*
    Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
    This program is distributed in the hope that it will be useful,  but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE; Contact [email protected] 
*/
pragma solidity 0.7.6;
pragma abicoder v2;


contract OracleRegistry is Auth {
    
    struct Oracle {
        uint oracleType;
        address oracleAddress;
    }

    uint public maxOracleType;

    address public immutable WETH;

    // map asset to oracle type ID
    mapping(address => uint) public oracleTypeByAsset;

    // map oracle type ID to oracle address
    mapping(uint => address) public oracleByType;

    // map oracle address to oracle type ID
    mapping(address => uint) public oracleTypeByOracle;

    // list of keydonix oracleType IDs
    uint[] public keydonixOracleTypes;

    event AssetOracle(address indexed asset, uint indexed oracleType);
    event OracleType(uint indexed oracleType, address indexed oracle);
    event KeydonixOracleTypes();

    modifier validAddress(address asset) {
        require(asset != address(0), "CryptoPeso protocol : ZERO_ADDRESS");
        _;
    }

    modifier validType(uint _type) {
        require(_type != 0, "CryptoPeso protocol : INVALID_TYPE");
        _;
    }

    constructor(address vaultParameters, address _weth)
        Auth(vaultParameters)
        validAddress(vaultParameters)
        validAddress(_weth)
    {
        WETH = _weth;
    }

    function setKeydonixOracleTypes(uint[] calldata _keydonixOracleTypes) public onlyManager {
        for (uint i = 0; i < _keydonixOracleTypes.length; i++) {
            require(_keydonixOracleTypes[i] != 0, "CryptoPeso protocol : INVALID_TYPE");
            require(oracleByType[_keydonixOracleTypes[i]] != address(0), "CryptoPeso protocol : INVALID_ORACLE");
        }

        keydonixOracleTypes = _keydonixOracleTypes;

        emit KeydonixOracleTypes();
    }

    function setOracle(uint oracleType, address oracle) public
        onlyManager
        validType(oracleType)
        validAddress(oracle)
    {
        if (oracleType > maxOracleType) {
            maxOracleType = oracleType;
        }

        address oldOracle = oracleByType[oracleType];
        if (oldOracle != address(0)) {
            delete oracleTypeByOracle[oldOracle];
        }

        uint oldOracleType = oracleTypeByOracle[oracle];
        if (oldOracleType != 0) {
            delete oracleByType[oldOracleType];
        }

        oracleByType[oracleType] = oracle;
        oracleTypeByOracle[oracle] = oracleType;

        emit OracleType(oracleType, oracle);
    }

    function unsetOracle(uint oracleType) public onlyManager validType(oracleType) validAddress(oracleByType[oracleType]) {
        address oracle = oracleByType[oracleType];
        delete oracleByType[oracleType];
        delete oracleTypeByOracle[oracle];

        emit OracleType(oracleType, address(0));
    }

    function setOracleTypeForAsset(address asset, uint oracleType) public
        onlyManager
        validAddress(asset)
        validType(oracleType)
        validAddress(oracleByType[oracleType])
    {
        oracleTypeByAsset[asset] = oracleType;
        emit AssetOracle(asset, oracleType);
    }

    function setOracleTypeForAssets(address[] calldata assets, uint oracleType) public {
        for (uint i = 0; i < assets.length; i++) {
            setOracleTypeForAsset(assets[i], oracleType);
        }
    }

    function unsetOracleForAsset(address asset) public
        onlyManager
        validAddress(asset)
        validType(oracleTypeByAsset[asset])
    {
        delete oracleTypeByAsset[asset];
        emit AssetOracle(asset, 0);
    }

    function unsetOracleForAssets(address[] calldata assets) public {
        for (uint i = 0; i < assets.length; i++) {
            unsetOracleForAsset(assets[i]);
        }
    }

    function getOracles() external view returns (Oracle[] memory foundOracles) {

        Oracle[] memory allOracles = new Oracle[](maxOracleType);

        uint actualOraclesCount;

        for (uint _type = 1; _type <= maxOracleType; ++_type) {
            if (oracleByType[_type] != address(0)) {
                allOracles[actualOraclesCount++] = Oracle(_type, oracleByType[_type]);
            }
        }

        foundOracles = new Oracle[](actualOraclesCount);

        for (uint i = 0; i < actualOraclesCount; ++i) {
            foundOracles[i] = allOracles[i];
        }
    }

    function getKeydonixOracleTypes() external view returns (uint[] memory) {
        return keydonixOracleTypes;
    }

    function oracleByAsset(address asset) external view returns (address) {
        uint oracleType = oracleTypeByAsset[asset];
        if (oracleType == 0) {
            return address(0);
        }
        return oracleByType[oracleType];
    }

}