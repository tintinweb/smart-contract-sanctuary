/**
 *Submitted for verification at Etherscan.io on 2021-03-19
*/

// File: localhost/VaultParameters.sol

// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity ^0.7.1;


/**
 * @title Auth
 * @dev Manages USDP's system access
 **/
contract Auth {

    // address of the the contract with vault parameters
    VaultParameters public vaultParameters;

    constructor(address _parameters) public {
        vaultParameters = VaultParameters(_parameters);
    }

    // ensures tx's sender is a manager
    modifier onlyManager() {
        require(vaultParameters.isManager(msg.sender), "Unit Protocol: AUTH_FAILED");
        _;
    }

    // ensures tx's sender is able to modify the Vault
    modifier hasVaultAccess() {
        require(vaultParameters.canModifyVault(msg.sender), "Unit Protocol: AUTH_FAILED");
        _;
    }

    // ensures tx's sender is the Vault
    modifier onlyVault() {
        require(msg.sender == vaultParameters.vault(), "Unit Protocol: AUTH_FAILED");
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
    constructor(address payable _vault, address _foundation) public Auth(address(this)) {
        require(_vault != address(0), "Unit Protocol: ZERO_ADDRESS");
        require(_foundation != address(0), "Unit Protocol: ZERO_ADDRESS");

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
        require(newFoundation != address(0), "Unit Protocol: ZERO_ADDRESS");
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
        require(newValue <= 100, "Unit Protocol: VALUE_OUT_OF_RANGE");
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

// File: localhost/oracles/OracleRegistry.sol

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity ^0.7.1;


contract OracleRegistry is Auth {

    // map token to oracle address
    mapping(address => address) public oracleByAsset;

    // map oracle ID to oracle address
    mapping(uint => address) public oracleByType;

    constructor(address vaultParameters) Auth(vaultParameters) {
        require(vaultParameters != address(0), "Unit Protocol: ZERO_ADDRESS");
    }

    /**
     * @notice Only manager is able to call this function
     * @dev Sets the oracle address
     * @param asset The address of the collateral
     * @param oracle The oracle address
     * @param oracleType The oracle type ID
     **/
    function setOracle(address asset, address oracle, uint oracleType) public onlyManager {
        require(asset != address(0) && oracleType != 0, "Unit Protocol: INVALID_ARGS");
        oracleByAsset[asset] = oracle;
        oracleByType[oracleType] = oracle;
    }

}

// File: localhost/helpers/ERC20Like.sol

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity ^0.7.1;


interface ERC20Like {
    function balanceOf(address) external view returns (uint);
    function decimals() external view returns (uint8);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function totalSupply() external view returns (uint256);
}

// File: localhost/oracles/OracleSimple.sol

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity ^0.7.1;


/**
 * @title OracleSimple
 **/
abstract contract OracleSimple {
    function assetToUsd(address asset, uint amount) public virtual view returns (uint);
}


/**
 * @title OracleSimplePoolToken
 **/
abstract contract OracleSimplePoolToken is OracleSimple {
    ChainlinkedOracleSimple public oracleMainAsset;
}


/**
 * @title ChainlinkedOracleSimple
 **/
abstract contract ChainlinkedOracleSimple is OracleSimple {
    address public WETH;
    function ethToUsd(uint ethAmount) public virtual view returns (uint);
    function assetToEth(address asset, uint amount) public virtual view returns (uint);
}

// File: localhost/oracles/WrappedToUnderlyingOracle.sol

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity ^0.7.1;




/**
 * @title WrappedToUnderlyingOracle
 * @dev Oracle to quote wrapped tokens to underlying
 **/
contract WrappedToUnderlyingOracle is OracleSimple, Auth {

    OracleRegistry public immutable oracleRegistry;

    event NewUnderlying(address indexed wrapped, address indexed underlying);

    mapping (address => address) public assetToUnderlying;

    constructor(address _vaultParameters, address _oracleRegistry) Auth(_vaultParameters) {
        require(_vaultParameters != address(0) && _oracleRegistry != address(0), "Unit Protocol: ZERO_ADDRESS");
        oracleRegistry = OracleRegistry(_oracleRegistry);
    }

    function setUnderlying(address wrapped, address underlying) external onlyManager {
        assetToUnderlying[wrapped] = underlying;
        emit NewUnderlying(wrapped, underlying);
    }

    // returns Q112-encoded value
    function assetToUsd(address asset, uint amount) public override view returns (uint) {
        if (amount == 0) return 0;
        address underlying = assetToUnderlying[asset];
        require(underlying != address(0), "Unit Protocol: UNDEFINED_UNDERLYING");
        
        OracleSimple _oracleForUnderlying = OracleSimple(oracleRegistry.oracleByAsset(underlying));
        return _oracleForUnderlying.assetToUsd(underlying, amount);
    }

}