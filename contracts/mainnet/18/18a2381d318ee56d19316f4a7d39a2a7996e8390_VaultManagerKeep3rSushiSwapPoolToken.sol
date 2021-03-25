// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity ^0.7.1;

import "./VaultManagerKeep3rPoolTokenBase.sol";


/**
 * @title VaultManagerKeep3rSushiSwapPoolToken
 **/
contract VaultManagerKeep3rSushiSwapPoolToken is VaultManagerKeep3rPoolTokenBase {

    /**
     * @param _vaultManagerParameters The address of the contract with vault manager parameters
     * @param _keep3rPoolToken The address of Keep3r-based Oracle for pool tokens
     **/
    constructor(address payable _vaultManagerParameters, address _keep3rPoolToken)
    public
    VaultManagerKeep3rPoolTokenBase(_vaultManagerParameters, _keep3rPoolToken, 8)
    {}
}

// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity ^0.7.1;

import "../Vault.sol";
import "../helpers/Math.sol";
import "../helpers/ReentrancyGuard.sol";
import "./VaultManagerParameters.sol";
import "../oracles/OracleSimple.sol";


/**
 * @title VaultManagerKeep3rPoolTokenBase
 **/
contract VaultManagerKeep3rPoolTokenBase is ReentrancyGuard {
    using SafeMath for uint;

    Vault public immutable vault;
    VaultManagerParameters public immutable vaultManagerParameters;
    OracleSimplePoolToken public immutable oracle;
    uint public immutable ORACLE_TYPE;
    uint public constant Q112 = 2 ** 112;

    /**
     * @dev Trigger when joins are happened
    **/
    event Join(address indexed asset, address indexed user, uint main, uint usdp);

    /**
     * @dev Trigger when exits are happened
    **/
    event Exit(address indexed asset, address indexed user, uint main, uint usdp);

    modifier spawned(address asset, address user) {

        // check the existence of a position
        require(vault.getTotalDebt(asset, user) != 0, "Unit Protocol: NOT_SPAWNED_POSITION");
        require(vault.oracleType(asset, user) == ORACLE_TYPE, "Unit Protocol: WRONG_ORACLE_TYPE");
        _;
    }

    /**
     * @param _vaultManagerParameters The address of the contract with vault manager parameters
     * @param _keep3rPoolToken The address of Keep3r-based Oracle for pool tokens
     * @param _oracleType The oracle type ID
     **/
    constructor(address _vaultManagerParameters, address _keep3rPoolToken, uint _oracleType) public {
        vaultManagerParameters = VaultManagerParameters(_vaultManagerParameters);
        vault = Vault(VaultManagerParameters(_vaultManagerParameters).vaultParameters().vault());
        oracle = OracleSimplePoolToken(_keep3rPoolToken);
        ORACLE_TYPE = _oracleType;
    }

    /**
      * @notice Cannot be used for already spawned positions
      * @notice Token using as main collateral must be whitelisted
      * @notice Depositing tokens must be pre-approved to vault address
      * @dev Spawns new positions
      * @dev Adds collaterals to non-spawned positions
      * @notice position actually considered as spawned only when usdpAmount > 0
      * @param asset The address of token using as main collateral
      * @param mainAmount The amount of main collateral to deposit
      * @param usdpAmount The amount of USDP token to borrow
      **/
    function spawn(address asset, uint mainAmount, uint usdpAmount) public nonReentrant {
        require(usdpAmount != 0, "Unit Protocol: ZERO_BORROWING");

        // check whether the position is spawned
        require(vault.getTotalDebt(asset, msg.sender) == 0, "Unit Protocol: SPAWNED_POSITION");

        // oracle availability check
        require(vault.vaultParameters().isOracleTypeEnabled(ORACLE_TYPE, asset), "Unit Protocol: WRONG_ORACLE_TYPE");

        // USDP minting triggers the spawn of a position
        vault.spawn(asset, msg.sender, ORACLE_TYPE);

        _depositAndBorrow(asset, msg.sender, mainAmount, usdpAmount);

        // fire an event
        emit Join(asset, msg.sender, mainAmount, usdpAmount);
    }

    /**
     * @notice Position should be spawned (USDP borrowed from position) to call this method
     * @notice Depositing tokens must be pre-approved to vault address
     * @notice Token using as main collateral must be whitelisted
     * @dev Deposits collaterals to spawned positions
     * @dev Borrows USDP
     * @param asset The address of token using as main collateral
     * @param mainAmount The amount of main collateral to deposit
     * @param usdpAmount The amount of USDP token to borrow
     **/
    function depositAndBorrow(
        address asset,
        uint mainAmount,
        uint usdpAmount
    )
    public
    spawned(asset, msg.sender)
    nonReentrant
    {
        require(usdpAmount != 0, "Unit Protocol: ZERO_BORROWING");

        _depositAndBorrow(asset, msg.sender, mainAmount, usdpAmount);

        // fire an event
        emit Join(asset, msg.sender, mainAmount, usdpAmount);
    }

    /**
      * @notice Tx sender must have a sufficient USDP balance to pay the debt
      * @dev Withdraws collateral
      * @dev Repays specified amount of debt
      * @param asset The address of token using as main collateral
      * @param mainAmount The amount of main collateral token to withdraw
      * @param usdpAmount The amount of USDP token to repay
      **/
    function withdrawAndRepay(
        address asset,
        uint mainAmount,
        uint usdpAmount
    )
    public
    spawned(asset, msg.sender)
    nonReentrant
    {
        // check usefulness of tx
        require(mainAmount != 0, "Unit Protocol: USELESS_TX");

        uint debt = vault.debts(asset, msg.sender);
        require(debt != 0 && usdpAmount != debt, "Unit Protocol: USE_REPAY_ALL_INSTEAD");

        // withdraw main collateral to the user address
        vault.withdrawMain(asset, msg.sender, mainAmount);

        if (usdpAmount != 0) {
            uint fee = vault.calculateFee(asset, msg.sender, usdpAmount);
            vault.chargeFee(vault.usdp(), msg.sender, fee);
            vault.repay(asset, msg.sender, usdpAmount);
        }

        vault.update(asset, msg.sender);

        _ensurePositionCollateralization(asset, msg.sender);

        // fire an event
        emit Exit(asset, msg.sender, mainAmount, usdpAmount);
    }

    function _depositAndBorrow(address asset, address user, uint mainAmount, uint usdpAmount) internal {
        if (mainAmount != 0) {
            vault.depositMain(asset, user, mainAmount);
        }

        // mint USDP to user
        vault.borrow(asset, user, usdpAmount);

        // check collateralization
        _ensurePositionCollateralization(asset, user);
    }

    // ensures that borrowed value is in desired range
    function _ensurePositionCollateralization(address asset, address user) internal view {
        // main collateral value of the position in USD
        uint mainUsdValue_q112 = oracle.assetToUsd(asset, vault.collaterals(asset, user));

        _ensureCollateralization(asset, user, mainUsdValue_q112);
    }

    // ensures that borrowed value is in desired range
    function _ensureCollateralization(address asset, address user, uint mainUsdValue_q112) internal view {
        // USD limit of the position
        uint usdLimit = mainUsdValue_q112 * vaultManagerParameters.initialCollateralRatio(asset) / Q112 / 100;

        // revert if collateralization is not enough
        require(vault.getTotalDebt(asset, user) <= usdLimit, "Unit Protocol: UNDERCOLLATERALIZED");
    }
}

// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity ^0.7.1;

import "./helpers/SafeMath.sol";
import "./VaultParameters.sol";
import "./helpers/TransferHelper.sol";
import "./USDP.sol";
import "./helpers/IWETH.sol";


/**
 * @title Vault
 * @notice Vault is the core of Unit Protocol USDP Stablecoin system
 * @notice Vault stores and manages collateral funds of all positions and counts debts
 * @notice Only Vault can manage supply of USDP token
 * @notice Vault will not be changed/upgraded after initial deployment for the current stablecoin version
 **/
contract Vault is Auth {
    using SafeMath for uint;

    // COL token address
    address public immutable col;

    // WETH token address
    address payable public immutable weth;

    uint public constant DENOMINATOR_1E5 = 1e5;

    uint public constant DENOMINATOR_1E2 = 1e2;

    // USDP token address
    address public immutable usdp;

    // collaterals whitelist
    mapping(address => mapping(address => uint)) public collaterals;

    // COL token collaterals
    mapping(address => mapping(address => uint)) public colToken;

    // user debts
    mapping(address => mapping(address => uint)) public debts;

    // block number of liquidation trigger
    mapping(address => mapping(address => uint)) public liquidationBlock;

    // initial price of collateral
    mapping(address => mapping(address => uint)) public liquidationPrice;

    // debts of tokens
    mapping(address => uint) public tokenDebts;

    // stability fee pinned to each position
    mapping(address => mapping(address => uint)) public stabilityFee;

    // liquidation fee pinned to each position, 0 decimals
    mapping(address => mapping(address => uint)) public liquidationFee;

    // type of using oracle pinned for each position
    mapping(address => mapping(address => uint)) public oracleType;

    // timestamp of the last update
    mapping(address => mapping(address => uint)) public lastUpdate;

    modifier notLiquidating(address asset, address user) {
        require(liquidationBlock[asset][user] == 0, "Unit Protocol: LIQUIDATING_POSITION");
        _;
    }

    /**
     * @param _parameters The address of the system parameters
     * @param _col COL token address
     * @param _usdp USDP token address
     **/
    constructor(address _parameters, address _col, address _usdp, address payable _weth) public Auth(_parameters) {
        col = _col;
        usdp = _usdp;
        weth = _weth;
    }

    // only accept ETH via fallback from the WETH contract
    receive() external payable {
        require(msg.sender == weth, "Unit Protocol: RESTRICTED");
    }

    /**
     * @dev Updates parameters of the position to the current ones
     * @param asset The address of the main collateral token
     * @param user The owner of a position
     **/
    function update(address asset, address user) public hasVaultAccess notLiquidating(asset, user) {

        // calculate fee using stored stability fee
        uint debtWithFee = getTotalDebt(asset, user);
        tokenDebts[asset] = tokenDebts[asset].sub(debts[asset][user]).add(debtWithFee);
        debts[asset][user] = debtWithFee;

        stabilityFee[asset][user] = vaultParameters.stabilityFee(asset);
        liquidationFee[asset][user] = vaultParameters.liquidationFee(asset);
        lastUpdate[asset][user] = block.timestamp;
    }

    /**
     * @dev Creates new position for user
     * @param asset The address of the main collateral token
     * @param user The address of a position's owner
     * @param _oracleType The type of an oracle
     **/
    function spawn(address asset, address user, uint _oracleType) external hasVaultAccess notLiquidating(asset, user) {
        oracleType[asset][user] = _oracleType;
        delete liquidationBlock[asset][user];
    }

    /**
     * @dev Clears unused storage variables
     * @param asset The address of the main collateral token
     * @param user The address of a position's owner
     **/
    function destroy(address asset, address user) public hasVaultAccess notLiquidating(asset, user) {
        delete stabilityFee[asset][user];
        delete oracleType[asset][user];
        delete lastUpdate[asset][user];
        delete liquidationFee[asset][user];
    }

    /**
     * @notice Tokens must be pre-approved
     * @dev Adds main collateral to a position
     * @param asset The address of the main collateral token
     * @param user The address of a position's owner
     * @param amount The amount of tokens to deposit
     **/
    function depositMain(address asset, address user, uint amount) external hasVaultAccess notLiquidating(asset, user) {
        collaterals[asset][user] = collaterals[asset][user].add(amount);
        TransferHelper.safeTransferFrom(asset, user, address(this), amount);
    }

    /**
     * @dev Converts ETH to WETH and adds main collateral to a position
     * @param user The address of a position's owner
     **/
    function depositEth(address user) external payable notLiquidating(weth, user) {
        IWETH(weth).deposit{value: msg.value}();
        collaterals[weth][user] = collaterals[weth][user].add(msg.value);
    }

    /**
     * @dev Withdraws main collateral from a position
     * @param asset The address of the main collateral token
     * @param user The address of a position's owner
     * @param amount The amount of tokens to withdraw
     **/
    function withdrawMain(address asset, address user, uint amount) external hasVaultAccess notLiquidating(asset, user) {
        collaterals[asset][user] = collaterals[asset][user].sub(amount);
        TransferHelper.safeTransfer(asset, user, amount);
    }

    /**
     * @dev Withdraws WETH collateral from a position converting WETH to ETH
     * @param user The address of a position's owner
     * @param amount The amount of ETH to withdraw
     **/
    function withdrawEth(address payable user, uint amount) external hasVaultAccess notLiquidating(weth, user) {
        collaterals[weth][user] = collaterals[weth][user].sub(amount);
        IWETH(weth).withdraw(amount);
        TransferHelper.safeTransferETH(user, amount);
    }

    /**
     * @notice Tokens must be pre-approved
     * @dev Adds COL token to a position
     * @param asset The address of the main collateral token
     * @param user The address of a position's owner
     * @param amount The amount of tokens to deposit
     **/
    function depositCol(address asset, address user, uint amount) external hasVaultAccess notLiquidating(asset, user) {
        colToken[asset][user] = colToken[asset][user].add(amount);
        TransferHelper.safeTransferFrom(col, user, address(this), amount);
    }

    /**
     * @dev Withdraws COL token from a position
     * @param asset The address of the main collateral token
     * @param user The address of a position's owner
     * @param amount The amount of tokens to withdraw
     **/
    function withdrawCol(address asset, address user, uint amount) external hasVaultAccess notLiquidating(asset, user) {
        colToken[asset][user] = colToken[asset][user].sub(amount);
        TransferHelper.safeTransfer(col, user, amount);
    }

    /**
     * @dev Increases position's debt and mints USDP token
     * @param asset The address of the main collateral token
     * @param user The address of a position's owner
     * @param amount The amount of USDP to borrow
     **/
    function borrow(
        address asset,
        address user,
        uint amount
    )
    external
    hasVaultAccess
    notLiquidating(asset, user)
    returns(uint)
    {
        require(vaultParameters.isOracleTypeEnabled(oracleType[asset][user], asset), "Unit Protocol: WRONG_ORACLE_TYPE");
        update(asset, user);
        debts[asset][user] = debts[asset][user].add(amount);
        tokenDebts[asset] = tokenDebts[asset].add(amount);

        // check USDP limit for token
        require(tokenDebts[asset] <= vaultParameters.tokenDebtLimit(asset), "Unit Protocol: ASSET_DEBT_LIMIT");

        USDP(usdp).mint(user, amount);

        return debts[asset][user];
    }

    /**
     * @dev Decreases position's debt and burns USDP token
     * @param asset The address of the main collateral token
     * @param user The address of a position's owner
     * @param amount The amount of USDP to repay
     * @return updated debt of a position
     **/
    function repay(
        address asset,
        address user,
        uint amount
    )
    external
    hasVaultAccess
    notLiquidating(asset, user)
    returns(uint)
    {
        uint debt = debts[asset][user];
        debts[asset][user] = debt.sub(amount);
        tokenDebts[asset] = tokenDebts[asset].sub(amount);
        USDP(usdp).burn(user, amount);

        return debts[asset][user];
    }

    /**
     * @dev Transfers fee to foundation
     * @param asset The address of the fee asset
     * @param user The address to transfer funds from
     * @param amount The amount of asset to transfer
     **/
    function chargeFee(address asset, address user, uint amount) external hasVaultAccess notLiquidating(asset, user) {
        if (amount != 0) {
            TransferHelper.safeTransferFrom(asset, user, vaultParameters.foundation(), amount);
        }
    }

    /**
     * @dev Deletes position and transfers collateral to liquidation system
     * @param asset The address of the main collateral token
     * @param positionOwner The address of a position's owner
     * @param initialPrice The starting price of collateral in USDP
     **/
    function triggerLiquidation(
        address asset,
        address positionOwner,
        uint initialPrice
    )
    external
    hasVaultAccess
    notLiquidating(asset, positionOwner)
    {
        // reverts if oracle type is disabled
        require(vaultParameters.isOracleTypeEnabled(oracleType[asset][positionOwner], asset), "Unit Protocol: WRONG_ORACLE_TYPE");

        // fix the debt
        debts[asset][positionOwner] = getTotalDebt(asset, positionOwner);

        liquidationBlock[asset][positionOwner] = block.number;
        liquidationPrice[asset][positionOwner] = initialPrice;
    }

    /**
     * @dev Internal liquidation process
     * @param asset The address of the main collateral token
     * @param positionOwner The address of a position's owner
     * @param mainAssetToLiquidator The amount of main asset to send to a liquidator
     * @param colToLiquidator The amount of COL to send to a liquidator
     * @param mainAssetToPositionOwner The amount of main asset to send to a position owner
     * @param colToPositionOwner The amount of COL to send to a position owner
     * @param repayment The repayment in USDP
     * @param penalty The liquidation penalty in USDP
     * @param liquidator The address of a liquidator
     **/
    function liquidate(
        address asset,
        address positionOwner,
        uint mainAssetToLiquidator,
        uint colToLiquidator,
        uint mainAssetToPositionOwner,
        uint colToPositionOwner,
        uint repayment,
        uint penalty,
        address liquidator
    )
        external
        hasVaultAccess
    {
        require(liquidationBlock[asset][positionOwner] != 0, "Unit Protocol: NOT_TRIGGERED_LIQUIDATION");

        uint mainAssetInPosition = collaterals[asset][positionOwner];
        uint mainAssetToFoundation = mainAssetInPosition.sub(mainAssetToLiquidator).sub(mainAssetToPositionOwner);

        uint colInPosition = colToken[asset][positionOwner];
        uint colToFoundation = colInPosition.sub(colToLiquidator).sub(colToPositionOwner);

        delete liquidationPrice[asset][positionOwner];
        delete liquidationBlock[asset][positionOwner];
        delete debts[asset][positionOwner];
        delete collaterals[asset][positionOwner];
        delete colToken[asset][positionOwner];

        destroy(asset, positionOwner);

        // charge liquidation fee and burn USDP
        if (repayment > penalty) {
            if (penalty != 0) {
                TransferHelper.safeTransferFrom(usdp, liquidator, vaultParameters.foundation(), penalty);
            }
            USDP(usdp).burn(liquidator, repayment.sub(penalty));
        } else {
            if (repayment != 0) {
                TransferHelper.safeTransferFrom(usdp, liquidator, vaultParameters.foundation(), repayment);
            }
        }

        // send the part of collateral to a liquidator
        if (mainAssetToLiquidator != 0) {
            TransferHelper.safeTransfer(asset, liquidator, mainAssetToLiquidator);
        }

        if (colToLiquidator != 0) {
            TransferHelper.safeTransfer(col, liquidator, colToLiquidator);
        }

        // send the rest of collateral to a position owner
        if (mainAssetToPositionOwner != 0) {
            TransferHelper.safeTransfer(asset, positionOwner, mainAssetToPositionOwner);
        }

        if (colToPositionOwner != 0) {
            TransferHelper.safeTransfer(col, positionOwner, colToPositionOwner);
        }

        if (mainAssetToFoundation != 0) {
            TransferHelper.safeTransfer(asset, vaultParameters.foundation(), mainAssetToFoundation);
        }

        if (colToFoundation != 0) {
            TransferHelper.safeTransfer(col, vaultParameters.foundation(), colToFoundation);
        }
    }

    /**
     * @notice Only manager can call this function
     * @dev Changes broken oracle type to the correct one
     * @param asset The address of the main collateral token
     * @param user The address of a position's owner
     * @param newOracleType The new type of an oracle
     **/
    function changeOracleType(address asset, address user, uint newOracleType) external onlyManager {
        oracleType[asset][user] = newOracleType;
    }

    /**
     * @dev Calculates the total amount of position's debt based on elapsed time
     * @param asset The address of the main collateral token
     * @param user The address of a position's owner
     * @return user debt of a position plus accumulated fee
     **/
    function getTotalDebt(address asset, address user) public view returns (uint) {
        uint debt = debts[asset][user];
        if (liquidationBlock[asset][user] != 0) return debt;
        uint fee = calculateFee(asset, user, debt);
        return debt.add(fee);
    }

    /**
     * @dev Calculates the amount of fee based on elapsed time and repayment amount
     * @param asset The address of the main collateral token
     * @param user The address of a position's owner
     * @param amount The repayment amount
     * @return fee amount
     **/
    function calculateFee(address asset, address user, uint amount) public view returns (uint) {
        uint sFeePercent = stabilityFee[asset][user];
        uint timePast = block.timestamp.sub(lastUpdate[asset][user]);

        return amount.mul(sFeePercent).mul(timePast).div(365 days).div(DENOMINATOR_1E5);
    }
}

// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity ^0.7.1;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

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

// SPDX-License-Identifier: GPL-3.0-or-later

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity ^0.7.1;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity ^0.7.1;

import "./VaultParameters.sol";
import "./helpers/SafeMath.sol";


/**
 * @title USDP token implementation
 * @dev ERC20 token
 **/
contract USDP is Auth {
    using SafeMath for uint;

    // name of the token
    string public constant name = "USDP Stablecoin";

    // symbol of the token
    string public constant symbol = "USDP";

    // version of the token
    string public constant version = "1";

    // number of decimals the token uses
    uint8 public constant decimals = 18;

    // total token supply
    uint public totalSupply;

    // balance information map
    mapping(address => uint) public balanceOf;

    // token allowance mapping
    mapping(address => mapping(address => uint)) public allowance;

    /**
     * @dev Trigger on any successful call to approve(address spender, uint amount)
    **/
    event Approval(address indexed owner, address indexed spender, uint value);

    /**
     * @dev Trigger when tokens are transferred, including zero value transfers
    **/
    event Transfer(address indexed from, address indexed to, uint value);

    /**
      * @param _parameters The address of system parameters contract
     **/
    constructor(address _parameters) public Auth(_parameters) {}

    /**
      * @notice Only Vault can mint USDP
      * @dev Mints 'amount' of tokens to address 'to', and MUST fire the
      * Transfer event
      * @param to The address of the recipient
      * @param amount The amount of token to be minted
     **/
    function mint(address to, uint amount) external onlyVault {
        require(to != address(0), "Unit Protocol: ZERO_ADDRESS");

        balanceOf[to] = balanceOf[to].add(amount);
        totalSupply = totalSupply.add(amount);

        emit Transfer(address(0), to, amount);
    }

    /**
      * @notice Only manager can burn tokens from manager's balance
      * @dev Burns 'amount' of tokens, and MUST fire the Transfer event
      * @param amount The amount of token to be burned
     **/
    function burn(uint amount) external onlyManager {
        _burn(msg.sender, amount);
    }

    /**
      * @notice Only Vault can burn tokens from any balance
      * @dev Burns 'amount' of tokens from 'from' address, and MUST fire the Transfer event
      * @param from The address of the balance owner
      * @param amount The amount of token to be burned
     **/
    function burn(address from, uint amount) external onlyVault {
        _burn(from, amount);
    }

    /**
      * @dev Transfers 'amount' of tokens to address 'to', and MUST fire the Transfer event. The
      * function SHOULD throw if the _from account balance does not have enough tokens to spend.
      * @param to The address of the recipient
      * @param amount The amount of token to be transferred
     **/
    function transfer(address to, uint amount) external returns (bool) {
        return transferFrom(msg.sender, to, amount);
    }

    /**
      * @dev Transfers 'amount' of tokens from address 'from' to address 'to', and MUST fire the
      * Transfer event
      * @param from The address of the sender
      * @param to The address of the recipient
      * @param amount The amount of token to be transferred
     **/
    function transferFrom(address from, address to, uint amount) public returns (bool) {
        require(to != address(0), "Unit Protocol: ZERO_ADDRESS");
        require(balanceOf[from] >= amount, "Unit Protocol: INSUFFICIENT_BALANCE");

        if (from != msg.sender) {
            require(allowance[from][msg.sender] >= amount, "Unit Protocol: INSUFFICIENT_ALLOWANCE");
            _approve(from, msg.sender, allowance[from][msg.sender].sub(amount));
        }
        balanceOf[from] = balanceOf[from].sub(amount);
        balanceOf[to] = balanceOf[to].add(amount);

        emit Transfer(from, to, amount);
        return true;
    }

    /**
      * @dev Allows 'spender' to withdraw from your account multiple times, up to the 'amount' amount. If
      * this function is called again it overwrites the current allowance with 'amount'.
      * @param spender The address of the account able to transfer the tokens
      * @param amount The amount of tokens to be approved for transfer
     **/
    function approve(address spender, uint amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, allowance[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, allowance[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    function _approve(address owner, address spender, uint amount) internal virtual {
        require(owner != address(0), "Unit Protocol: approve from the zero address");
        require(spender != address(0), "Unit Protocol: approve to the zero address");

        allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _burn(address from, uint amount) internal virtual {
        balanceOf[from] = balanceOf[from].sub(amount);
        totalSupply = totalSupply.sub(amount);

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity ^0.7.1;


interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity ^0.7.1;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.1;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () public {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity ^0.7.1;

import "../VaultParameters.sol";


/**
 * @title VaultManagerParameters
 **/
contract VaultManagerParameters is Auth {

    // determines the minimum percentage of COL token part in collateral, 0 decimals
    mapping(address => uint) public minColPercent;

    // determines the maximum percentage of COL token part in collateral, 0 decimals
    mapping(address => uint) public maxColPercent;

    // map token to initial collateralization ratio; 0 decimals
    mapping(address => uint) public initialCollateralRatio;

    // map token to liquidation ratio; 0 decimals
    mapping(address => uint) public liquidationRatio;

    // map token to liquidation discount; 3 decimals
    mapping(address => uint) public liquidationDiscount;

    // map token to devaluation period in blocks
    mapping(address => uint) public devaluationPeriod;

    constructor(address _vaultParameters) public Auth(_vaultParameters) {}

    /**
     * @notice Only manager is able to call this function
     * @dev Sets ability to use token as the main collateral
     * @param asset The address of the main collateral token
     * @param stabilityFeeValue The percentage of the year stability fee (3 decimals)
     * @param liquidationFeeValue The liquidation fee percentage (0 decimals)
     * @param initialCollateralRatioValue The initial collateralization ratio
     * @param liquidationRatioValue The liquidation ratio
     * @param liquidationDiscountValue The liquidation discount (3 decimals)
     * @param devaluationPeriodValue The devaluation period in blocks
     * @param usdpLimit The USDP token issue limit
     * @param oracles The enabled oracles type IDs
     * @param minColP The min percentage of COL value in position (0 decimals)
     * @param maxColP The max percentage of COL value in position (0 decimals)
     **/
    function setCollateral(
        address asset,
        uint stabilityFeeValue,
        uint liquidationFeeValue,
        uint initialCollateralRatioValue,
        uint liquidationRatioValue,
        uint liquidationDiscountValue,
        uint devaluationPeriodValue,
        uint usdpLimit,
        uint[] calldata oracles,
        uint minColP,
        uint maxColP
    ) external onlyManager {
        vaultParameters.setCollateral(asset, stabilityFeeValue, liquidationFeeValue, usdpLimit, oracles);
        setInitialCollateralRatio(asset, initialCollateralRatioValue);
        setLiquidationRatio(asset, liquidationRatioValue);
        setDevaluationPeriod(asset, devaluationPeriodValue);
        setLiquidationDiscount(asset, liquidationDiscountValue);
        setColPartRange(asset, minColP, maxColP);
    }

    /**
     * @notice Only manager is able to call this function
     * @dev Sets the initial collateral ratio
     * @param asset The address of the main collateral token
     * @param newValue The collateralization ratio (0 decimals)
     **/
    function setInitialCollateralRatio(address asset, uint newValue) public onlyManager {
        require(newValue != 0 && newValue <= 100, "Unit Protocol: INCORRECT_COLLATERALIZATION_VALUE");
        initialCollateralRatio[asset] = newValue;
    }

    /**
     * @notice Only manager is able to call this function
     * @dev Sets the liquidation ratio
     * @param asset The address of the main collateral token
     * @param newValue The liquidation ratio (0 decimals)
     **/
    function setLiquidationRatio(address asset, uint newValue) public onlyManager {
        require(newValue != 0 && newValue >= initialCollateralRatio[asset], "Unit Protocol: INCORRECT_COLLATERALIZATION_VALUE");
        liquidationRatio[asset] = newValue;
    }

    /**
     * @notice Only manager is able to call this function
     * @dev Sets the liquidation discount
     * @param asset The address of the main collateral token
     * @param newValue The liquidation discount (3 decimals)
     **/
    function setLiquidationDiscount(address asset, uint newValue) public onlyManager {
        require(newValue < 1e5, "Unit Protocol: INCORRECT_DISCOUNT_VALUE");
        liquidationDiscount[asset] = newValue;
    }

    /**
     * @notice Only manager is able to call this function
     * @dev Sets the devaluation period of collateral after liquidation
     * @param asset The address of the main collateral token
     * @param newValue The devaluation period in blocks
     **/
    function setDevaluationPeriod(address asset, uint newValue) public onlyManager {
        require(newValue != 0, "Unit Protocol: INCORRECT_DEVALUATION_VALUE");
        devaluationPeriod[asset] = newValue;
    }

    /**
     * @notice Only manager is able to call this function
     * @dev Sets the percentage range of the COL token part for specific collateral token
     * @param asset The address of the main collateral token
     * @param min The min percentage (0 decimals)
     * @param max The max percentage (0 decimals)
     **/
    function setColPartRange(address asset, uint min, uint max) public onlyManager {
        require(max <= 100 && min <= max, "Unit Protocol: WRONG_RANGE");
        minColPercent[asset] = min;
        maxColPercent[asset] = max;
    }
}

// SPDX-License-Identifier: bsl-1.1

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

{
  "metadata": {
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
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
  }
}