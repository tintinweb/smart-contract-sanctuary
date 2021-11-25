// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

//  helper contracts
import { RegistryStorage } from "./RegistryStorage.sol";
import { ModifiersController } from "./ModifiersController.sol";

/**
 * @title RegistryProxy Contract
 * @author Opty.fi
 * @dev Storage for the Registry is at this address,
 * while execution is delegated to the `registryImplementation`.
 * Registry should reference this contract as their controller.
 * It defines a fallback function that delegates all calls to the address
 * returned by the abstract _implementation() internal function.
 */
contract RegistryProxy is RegistryStorage, ModifiersController {
    /**
     * @notice Emitted when pendingComptrollerImplementation is changed
     * @param oldPendingImplementation Old Registry contract's implementation address which is still pending
     * @param newPendingImplementation New Registry contract's implementation address which is still pending
     */
    event NewPendingImplementation(address oldPendingImplementation, address newPendingImplementation);

    /**
     * @notice Emitted when pendingComptrollerImplementation is updated
     * @param oldImplementation Old Registry Contract's implementation address
     * @param newImplementation New Registry Contract's implementation address
     */
    event NewImplementation(address oldImplementation, address newImplementation);

    /**
     * @notice Emitted when pendingGovernance is changed
     * @param oldPendingGovernance Old Governance's address which is still pending
     * @param newPendingGovernance New Governance's address which is still pending
     */
    event NewPendingGovernance(address oldPendingGovernance, address newPendingGovernance);

    /**
     * @notice Emitted when pendingGovernance is accepted, which means governance is updated
     * @param oldGovernance Old Governance's address
     * @param newGovernance New Governance's address
     */
    event NewGovernance(address oldGovernance, address newGovernance);

    constructor() public {
        governance = msg.sender;
        setFinanceOperator(msg.sender);
        setRiskOperator(msg.sender);
        setStrategyOperator(msg.sender);
        setOperator(msg.sender);
        setOPTYDistributor(msg.sender);
    }

    /* solhint-disable */
    receive() external payable {
        revert();
    }

    /**
     * @notice Delegates execution to an implementation contract
     * @dev Returns to external caller whatever implementation returns or forwards reverts
     */
    fallback() external payable {
        // delegate all other functions to current implementation
        (bool success, ) = registryImplementation.delegatecall(msg.data);

        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize())

            switch success
                case 0 {
                    revert(free_mem_ptr, returndatasize())
                }
                default {
                    return(free_mem_ptr, returndatasize())
                }
        }
    }

    /* solhint-disable */

    /*** Admin Functions ***/
    /**
     * @dev Set the registry contract as pending implementation initally
     * @param newPendingImplementation registry address to act as pending implementation
     */
    function setPendingImplementation(address newPendingImplementation) external onlyOperator {
        address oldPendingImplementation = pendingRegistryImplementation;

        pendingRegistryImplementation = newPendingImplementation;

        emit NewPendingImplementation(oldPendingImplementation, pendingRegistryImplementation);
    }

    /**
     * @notice Accepts new implementation of registry
     * @dev Governance function for new implementation to accept it's role as implementation
     */
    function acceptImplementation() external returns (uint256) {
        // Check caller is pendingImplementation and pendingImplementation ≠ address(0)
        require(
            msg.sender == pendingRegistryImplementation && pendingRegistryImplementation != address(0),
            "!pendingRegistryImplementation"
        );

        // Save current values for inclusion in log
        address oldImplementation = registryImplementation;
        address oldPendingImplementation = pendingRegistryImplementation;

        registryImplementation = pendingRegistryImplementation;

        pendingRegistryImplementation = address(0);

        emit NewImplementation(oldImplementation, registryImplementation);
        emit NewPendingImplementation(oldPendingImplementation, pendingRegistryImplementation);

        return uint256(0);
    }

    /**
     * @notice Transfers the governance rights
     * @dev The newPendingGovernance must call acceptGovernance() to finalize the transfer
     * @param newPendingGovernance New pending governance address
     */
    function setPendingGovernance(address newPendingGovernance) external onlyOperator {
        // Save current value, if any, for inclusion in log
        address oldPendingGovernance = pendingGovernance;

        // Store pendingGovernance with value newPendingGovernance
        pendingGovernance = newPendingGovernance;

        // Emit NewPendingGovernance(oldPendingGovernance, newPendingGovernance)
        emit NewPendingGovernance(oldPendingGovernance, newPendingGovernance);
    }

    /**
     * @notice Accepts transfer of Governance rights
     * @dev Governance function for pending governance to accept role and update Governance
     */
    function acceptGovernance() external returns (uint256) {
        require(msg.sender == pendingGovernance && msg.sender != address(0), "!pendingGovernance");

        // Save current values for inclusion in log
        address oldGovernance = governance;
        address oldPendingGovernance = pendingGovernance;

        // Store admin with value pendingGovernance
        governance = pendingGovernance;

        // Clear the pending value
        pendingGovernance = address(0);

        emit NewGovernance(oldGovernance, governance);
        emit NewPendingGovernance(oldPendingGovernance, pendingGovernance);
        return uint256(0);
    }
}

/* solhint-disable max-states-count */
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

//  libraries
import { DataTypes } from "../../libraries/types/DataTypes.sol";

/**
 * @title RegistryAdminStorage Contract
 * @author Opty.fi
 * @dev Contract used to store registry's admin account
 */
contract RegistryAdminStorage {
    /**
     * @notice Governance of optyfi's earn protocol
     */
    address public governance;

    /**
     * @notice Finance operator of optyfi's earn protocol
     * @dev Handle functions having withdrawal fee, treasury and finance related logic
     */
    address public financeOperator;

    /**
     * @notice Risk operator of optyfi's earn protocol
     * @dev Handle functions for maintaining the risk profiles and rating of liquidity/credit pools
     */
    address public riskOperator;

    /**
     * @notice Strategy operator of optyfi's earn protocol
     * @dev Handle functions related to strategies/vault strategies to be used
     */
    address public strategyOperator;

    /**
     * @notice Operator of optyfi's earn protocol
     */
    address public operator;

    /**
     * @notice Treasury of optyfi's earn protocol
     */
    address public treasury;

    /**
     * @notice Distributor for OPTY token
     */
    address public optyDistributor;

    /**
     * @notice Pending governance for optyfi's earn protocol
     */
    address public pendingGovernance;

    /**
     * @notice Active brains of Registry
     */
    address public registryImplementation;

    /**
     * @notice Pending brains of Registry
     */
    address public pendingRegistryImplementation;

    /**
     * @notice notify when transfer operation of financeOperator occurs
     * @param financeOperator address of Finance operator of optyfi's earn protocol
     * @param caller address of user who has called the respective function to trigger this event
     */
    event TransferFinanceOperator(address indexed financeOperator, address indexed caller);

    /**
     * @notice notify when transfer operation of riskOperator occurs
     * @param riskOperator address of Risk operator of optyfi's earn protocol
     * @param caller address of user who has called the respective function to trigger this event
     */
    event TransferRiskOperator(address indexed riskOperator, address indexed caller);

    /**
     * @notice notify when transfer operation of strategyOperator occurs
     * @param strategyOperator address of Strategy operator of optyfi's earn protocol
     * @param caller address of user who has called the respective function to trigger this event
     */
    event TransferStrategyOperator(address indexed strategyOperator, address indexed caller);

    /**
     * @notice notify when transfer operation of operator occurs
     * @param operator address of Operator of optyfi's earn protocol
     * @param caller address of user who has called the respective function to trigger this event
     */
    event TransferOperator(address indexed operator, address indexed caller);

    /**
     * @notice notify when transfer operation of treasury occurs
     * @param treasury address of Treasury of optyfi's earn protocol
     * @param caller address of user who has called the respective function to trigger this event
     */
    event TransferTreasury(address indexed treasury, address indexed caller);

    /**
     * @notice notify when transfer operation of optyDistributor occurs
     * @param optyDistributor address of Opty distributor of optyfi's earn protocol
     * @param caller address of user who has called the respective function to trigger this event
     */
    event TransferOPTYDistributor(address indexed optyDistributor, address indexed caller);
}

/**
 * @title RegistryStorage Contract
 * @author Opty.fi
 * @dev Contract used to store registry's contract state variables and events
 */
contract RegistryStorage is RegistryAdminStorage {
    /**
     * @notice token address status which are approved or not
     */
    mapping(address => bool) public tokens;

    /**
     * @notice token data mapped to token/tokens address/addresses hash
     */
    mapping(bytes32 => DataTypes.Token) public tokensHashToTokens;

    /**
     * @notice liquidityPool address mapped to its struct having `pool`, `outputToken`, `isBorrow`
     */
    mapping(address => DataTypes.LiquidityPool) public liquidityPools;

    /**
     * @notice creaditPool address mapped to its struct having `pool`, `outputToken`, `isBorrow`
     */
    mapping(address => DataTypes.LiquidityPool) public creditPools;

    /**
     * @notice liquidityPool address mapped to its adapter
     */
    mapping(address => address) public liquidityPoolToAdapter;

    /**
     * @notice underlying asset (token address's hash) mapped to riskProfileCode and vault contract
     *         address for keeping track of all the vault contracts
     */
    mapping(bytes32 => mapping(uint256 => address)) public underlyingAssetHashToRPToVaults;

    /**
     * @dev riskProfileCode mapped to its struct `RiskProfile`
     */
    mapping(uint256 => DataTypes.RiskProfile) internal riskProfiles;

    /**
     * @notice vault contract address mapped to VaultConfiguration
     */
    mapping(address => DataTypes.VaultConfiguration) public vaultToVaultConfiguration;

    /**
     * @notice withdrawal fee's range
     */
    DataTypes.WithdrawalFeeRange public withdrawalFeeRange;

    /**
     * @notice List of all the tokenHashes
     */
    bytes32[] public tokensHashIndexes;

    /**
     * @notice List of all the riskProfiles
     */
    uint256[] public riskProfilesArray;

    /**
     * @notice strategyProvider contract address
     */
    address public strategyProvider;

    /**
     * @notice investStrategyRegistry contract address
     */
    address public investStrategyRegistry;

    /**
     * @notice riskManager contract address
     */
    address public riskManager;

    /**
     * @notice harvestCodeProvider contract address
     */
    address public harvestCodeProvider;

    /**
     * @notice strategyManager contract address
     */
    address public strategyManager;

    /**
     * @notice priceOracle contract address
     */
    address public priceOracle;

    /**
     * @notice opty contract address
     */
    address public opty;

    /**
     * @notice aprOracle contract address
     */
    address public aprOracle;

    /**
     * @notice optyStakingRateBalancer contract address
     */
    address public optyStakingRateBalancer;

    /**
     * @notice OD vaultBooster contract address
     */
    address public odefiVaultBooster;

    /**
     * @notice Emitted when token is approved or revoked
     * @param token Underlying Token's address which is approved or revoked
     * @param enabled Token is approved (true) or revoked (false)
     * @param caller Address of user who has called the respective function to trigger this event
     */
    event LogToken(address indexed token, bool indexed enabled, address indexed caller);

    /**
     * @notice Emitted when pool is approved or revoked as liquidity pool
     * @param pool Liquidity Pool's address which is approved or revoked
     * @param enabled Liquidity Pool is approved (true) or revoked (false)
     * @param caller Address of user who has called the respective function to trigger this event
     */
    event LogLiquidityPool(address indexed pool, bool indexed enabled, address indexed caller);

    /**
     * @notice Emitted when pool is approved or revoked as credit pool
     * @param pool Credit Pool's address which is approved or revoked
     * @param enabled Credit pool is approved (true) or revoked (false)
     * @param caller Address of user who has called the respective function to trigger this event
     */
    event LogCreditPool(address indexed pool, bool indexed enabled, address indexed caller);

    /**
     * @notice Emitted when liquidity pool is rated
     * @param pool Liquidity Pool's address which is rated
     * @param rate Rating of Liquidity Pool set
     * @param caller Address of user who has called the respective function to trigger this event
     */
    event LogRateLiquidityPool(address indexed pool, uint8 indexed rate, address indexed caller);

    /**
     * @notice Emitted when credit pool is rated
     * @param pool Credit Pool's address which is rated
     * @param rate Rating of Credit Pool set
     * @param caller Address of user who has called the respective function to trigger this event
     */
    event LogRateCreditPool(address indexed pool, uint8 indexed rate, address indexed caller);

    /**
     * @notice Emitted when liquidity pool pool is assigned to adapter
     * @param pool Liquidity Pool's address which is mapped to the adapter
     * @param adapter Address of the respective OptyFi's defi-adapter contract which is mapped to the Liquidity Pool
     * @param caller Address of user who has called the respective function to trigger this event
     */
    event LogLiquidityPoolToAdapter(address indexed pool, address indexed adapter, address indexed caller);

    /**
     * @notice Emitted when tokens are assigned to tokensHash
     * @param tokensHash Hash of the token/list of tokens mapped to the provided token/list of tokens
     * @param caller Address of user who has called the respective function to trigger this event
     */
    event LogTokensToTokensHash(bytes32 indexed tokensHash, address indexed caller);

    /**
     * @dev Emitted when Discontinue over vault is activated
     * @param vault OptyFi's Vault contract address which is discontinued from being operational
     * @param discontinued Discontinue status (true) of OptyFi's Vault contract
     * @param caller Address of user who has called the respective function to trigger this event
     */
    event LogDiscontinueVault(address indexed vault, bool indexed discontinued, address indexed caller);

    /**
     * @notice Emitted when Pause over vault is activated/deactivated
     * @param vault OptyFi's Vault contract address which is temporarily paused or unpaused
     * @param unpaused Unpause status of OptyFi's Vault contract - false (if paused) and true (if unpaused)
     * @param caller Address of user who has called the respective function to trigger this event
     */
    event LogUnpauseVault(address indexed vault, bool indexed unpaused, address indexed caller);

    /**
     * @notice Emitted when setUnderlyingAssetHashToRPToVaults function is called
     * @param underlyingAssetHash Underlying token's hash mapped to risk profile and OptyFi's Vault contract address
     * @param riskProfileCode Risk Profile Code used to map Underlying token hash and OptyFi's Vault contract address
     * @param vault OptyFi's Vault contract address
     * @param caller Address of user who has called the respective function to trigger this event
     */
    event LogUnderlyingAssetHashToRPToVaults(
        bytes32 indexed underlyingAssetHash,
        uint256 indexed riskProfileCode,
        address indexed vault,
        address caller
    );

    /**
     * @notice Emitted when RiskProfile is added
     * @param index Index of an array at which risk profile is added
     * @param exists Status of risk profile if it exists (true) or not (false)
     * @param canBorrow Borrow is allowed (true) or not (false) for the specified risk profile
     * @param caller Address of user who has called the respective function to trigger this event
     */
    event LogRiskProfile(uint256 indexed index, bool indexed exists, bool indexed canBorrow, address caller);

    /**
     * @notice Emitted when Risk profile is added/updated
     * @param index Index of an array at which risk profile is added or updated
     * @param lowerLimit Lower limit of the pool for the specified risk profile
     * @param upperLimit Upper limit of the pool for the specified risk profile
     * @param caller Address of user who has called the respective function to trigger this event
     */
    event LogRPPoolRatings(uint256 indexed index, uint8 indexed lowerLimit, uint8 indexed upperLimit, address caller);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

//  libraries
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

//  helper contracts
import { RegistryStorage } from "./RegistryStorage.sol";

//  interfaces
import { IModifiersController } from "../../interfaces/opty/IModifiersController.sol";

/**
 * @title ModifiersController Contract
 * @author Opty.fi
 * @notice Contract used by registry contract and acts as source of truth
 * @dev It manages operator, optyDistributor addresses as well as modifiers
 */
abstract contract ModifiersController is IModifiersController, RegistryStorage {
    using Address for address;

    /**
     * @inheritdoc IModifiersController
     */
    function setFinanceOperator(address _financeOperator) public override onlyGovernance {
        require(_financeOperator != address(0), "!address(0)");
        financeOperator = _financeOperator;
        emit TransferFinanceOperator(financeOperator, msg.sender);
    }

    /**
     * @inheritdoc IModifiersController
     */
    function setRiskOperator(address _riskOperator) public override onlyGovernance {
        require(_riskOperator != address(0), "!address(0)");
        riskOperator = _riskOperator;
        emit TransferRiskOperator(riskOperator, msg.sender);
    }

    /**
     * @inheritdoc IModifiersController
     */
    function setStrategyOperator(address _strategyOperator) public override onlyGovernance {
        require(_strategyOperator != address(0), "!address(0)");
        strategyOperator = _strategyOperator;
        emit TransferStrategyOperator(strategyOperator, msg.sender);
    }

    /**
     * @inheritdoc IModifiersController
     */
    function setOperator(address _operator) public override onlyGovernance {
        require(_operator != address(0), "!address(0)");
        operator = _operator;
        emit TransferOperator(operator, msg.sender);
    }

    /**
     * @inheritdoc IModifiersController
     */
    function setOPTYDistributor(address _optyDistributor) public override onlyGovernance {
        require(_optyDistributor != address(0), "!address(0)");
        optyDistributor = _optyDistributor;
        emit TransferOPTYDistributor(optyDistributor, msg.sender);
    }

    /**
     * @notice Modifier to check caller is governance or not
     */
    modifier onlyGovernance() {
        require(msg.sender == governance, "caller is not having governance");
        _;
    }

    /**
     * @notice Modifier to check caller is financeOperator or not
     */
    modifier onlyFinanceOperator() {
        require(msg.sender == financeOperator, "caller is not the finance operator");
        _;
    }

    /**
     * @notice Modifier to check caller is riskOperator or not
     */
    modifier onlyRiskOperator() {
        require(msg.sender == riskOperator, "caller is not the risk operator");
        _;
    }

    /**
     * @notice Modifier to check caller is operator or not
     */
    modifier onlyOperator() {
        require(msg.sender == operator, "caller is not the operator");
        _;
    }

    /**
     * @notice Modifier to check caller is optyDistributor or not
     */
    modifier onlyOptyDistributor() {
        require(msg.sender == optyDistributor, "caller is not the optyDistributor");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

library DataTypes {
    /**
     * @notice Container for User Deposit/withdraw operations
     * @param account User's address
     * @param isDeposit True if it is deposit and false if it withdraw
     * @param value Amount to deposit/withdraw
     */
    struct UserDepositOperation {
        address account;
        uint256 value;
    }

    /**
     * @notice Container for token balance in vault contract in a specific block
     * @param actualVaultValue current balance of the vault contract
     * @param blockMinVaultValue minimum balance recorded for vault contract in the same block
     * @param blockMaxVaultValue maximum balance recorded for vault contract in the same block
     */
    struct BlockVaultValue {
        uint256 actualVaultValue;
        uint256 blockMinVaultValue;
        uint256 blockMaxVaultValue;
    }

    /**
     * @notice Container for Strategy Steps used by Strategy
     * @param pool Liquidity Pool address
     * @param outputToken Output token of the liquidity pool
     * @param isBorrow If borrow is allowed or not for the liquidity pool
     */
    struct StrategyStep {
        address pool;
        address outputToken;
        bool isBorrow;
    }

    /**
     * @notice Container for pool's configuration
     * @param rating Rating of the liquidity pool
     * @param isLiquidityPool If pool is enabled as liquidity pool
     */
    struct LiquidityPool {
        uint8 rating;
        bool isLiquidityPool;
    }

    /**
     * @notice Container for Strategy used by Vault contract
     * @param index Index at which strategy is stored
     * @param strategySteps StrategySteps consisting pool, outputToken and isBorrow
     */
    struct Strategy {
        uint256 index;
        StrategyStep[] strategySteps;
    }

    /**
     * @notice Container for all Tokens
     * @param index Index at which token is stored
     * @param tokens List of token addresses
     */
    struct Token {
        uint256 index;
        address[] tokens;
    }

    /**
     * @notice Container for pool and its rating
     * @param pool Address of liqudity pool
     * @param rate Value to be set as rate for the liquidity pool
     */
    struct PoolRate {
        address pool;
        uint8 rate;
    }

    /**
     * @notice Container for mapping the liquidity pool and adapter
     * @param pool liquidity pool address
     * @param adapter adapter contract address corresponding to pool
     */
    struct PoolAdapter {
        address pool;
        address adapter;
    }

    /**
     * @notice Container for having limit range for the pools
     * @param lowerLimit liquidity pool rate's lower limit
     * @param upperLimit liquidity pool rate's upper limit
     */
    struct PoolRatingsRange {
        uint8 lowerLimit;
        uint8 upperLimit;
    }

    /**
     * @notice Container for having limit range for withdrawal fee
     * @param lowerLimit withdrawal fee's lower limit
     * @param upperLimit withdrawal fee's upper limit
     */
    struct WithdrawalFeeRange {
        uint256 lowerLimit;
        uint256 upperLimit;
    }

    /**
     * @notice Container for containing risk Profile's configuration
     * @param index Index at which risk profile is stored
     * @param canBorrow True if borrow is allowed for the risk profile
     * @param poolRatingsRange Container for having limit range for the pools
     * @param exists if risk profile exists or not
     */
    struct RiskProfile {
        uint256 index;
        bool canBorrow;
        PoolRatingsRange poolRatingsRange;
        bool exists;
        string name;
        string symbol;
    }

    /**
     * @notice Container for holding percentage of reward token to hold and convert
     * @param hold reward token hold percentage in basis point
     * @param convert reward token convert percentage in basis point
     */
    struct VaultRewardStrategy {
        uint256 hold; //  should be in basis eg: 50% means 5000
        uint256 convert; //  should be in basis eg: 50% means 5000
    }

    /** @notice Named Constants for defining max exposure state */
    enum MaxExposure { Number, Pct }

    /** @notice Named Constants for defining default strategy state */
    enum DefaultStrategyState { Zero, CompoundOrAave }

    /**
     * @notice Container for persisting ODEFI contract's state
     * @param index The market's last index
     * @param timestamp The block number the index was last updated at
     */
    struct RewardsState {
        uint224 index;
        uint32 timestamp;
    }

    /**
     * @notice Container for Treasury accounts along with their shares
     * @param treasury treasury account address
     * @param share treasury's share in percentage from the withdrawal fee
     */
    struct TreasuryShare {
        address treasury;
        uint256 share; //  should be in basis eg: 5% means 500
    }

    /**
     * @notice Container for combining Vault contract's configuration
     * @param discontinued If the vault contract is discontinued or not
     * @param unpaused If the vault contract is paused or unpaused
     * @param withdrawalFee withdrawal fee for a particular vault contract
     * @param treasuryShares Treasury accounts along with their shares
     */
    struct VaultConfiguration {
        bool discontinued;
        bool unpaused;
        uint256 withdrawalFee; //  should be in basis eg: 15% means 1500
        TreasuryShare[] treasuryShares;
    }

    /**
     * @notice Container for persisting all strategy related contract's configuration
     * @param investStrategyRegistry investStrategyRegistry contract address
     * @param strategyProvider strategyProvider contract address
     * @param aprOracle aprOracle contract address
     */
    struct StrategyConfiguration {
        address investStrategyRegistry;
        address strategyProvider;
        address aprOracle;
    }

    /**
     * @notice Container for persisting contract addresses required by vault contract
     * @param strategyManager strategyManager contract address
     * @param riskManager riskManager contract address
     * @param optyDistributor optyDistributor contract address
     * @param operator operator contract address
     */
    struct VaultStrategyConfiguration {
        address strategyManager;
        address riskManager;
        address optyDistributor;
        address odefiVaultBooster;
        address operator;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

/**
 * @title Interface for ModifiersController Contract
 * @author Opty.fi
 * @notice Interface used to authorize operator and minter accounts
 */
interface IModifiersController {
    /**
     * @notice Transfers financeOperator to a new account (`_financeOperator`)
     * @param _financeOperator address of financeOperator's account
     */
    function setFinanceOperator(address _financeOperator) external;

    /**
     * @notice Transfers riskOperator to a new account (`_riskOperator`)
     * @param _riskOperator address of riskOperator's account
     */
    function setRiskOperator(address _riskOperator) external;

    /**
     * @notice Transfers strategyOperator to a new account (`_strategyOperator`)
     * @param _strategyOperator address of strategyOperator's account
     */
    function setStrategyOperator(address _strategyOperator) external;

    /**
     * @notice Transfers operator to a new account (`_operator`)
     * @param _operator address of Operator's account
     */
    function setOperator(address _operator) external;

    /**
     * @notice Transfers optyDistributor to a new account (`_optyDistributor`)
     * @param _optyDistributor address of optyDistributor's account
     */
    function setOPTYDistributor(address _optyDistributor) external;
}