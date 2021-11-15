// SPDX-License-Identifier: MIT

pragma solidity ^0.6.10;

import { RegistryStorage } from "./RegistryStorage.sol";
import { ModifiersController } from "./ModifiersController.sol";

/**
 * @title RegistryCore
 * @dev Storage for the Registry is at this address, while execution is delegated to the `registryImplementation`.
 * Registry should reference this contract as their controller.
 */
contract RegistryProxy is RegistryStorage, ModifiersController {
    /**
     * @notice Emitted when pendingComptrollerImplementation is changed
     */
    event NewPendingImplementation(address oldPendingImplementation, address newPendingImplementation);

    /**
     * @notice Emitted when pendingComptrollerImplementation is accepted,
     *         which means comptroller implementation is updated
     */
    event NewImplementation(address oldImplementation, address newImplementation);

    /**
     * @notice Emitted when pendingGovernance is changed
     */
    event NewPendingGovernance(address oldPendingGovernance, address newPendingGovernance);

    /**
     * @notice Emitted when pendingGovernance is accepted, which means governance is updated
     */
    event NewGovernance(address oldGovernance, address newGovernance);

    constructor() public {
        governance = msg.sender;
        setStrategist(msg.sender);
        setOperator(msg.sender);
        setMinter(msg.sender);
    }

    /*** Admin Functions ***/
    function setPendingImplementation(address newPendingImplementation) public onlyOperator {
        address oldPendingImplementation = pendingRegistryImplementation;

        pendingRegistryImplementation = newPendingImplementation;

        emit NewPendingImplementation(oldPendingImplementation, pendingRegistryImplementation);
    }

    /**
     * @notice Accepts new implementation of registry. msg.sender must be pendingImplementation
     * @dev Governance function for new implementation to accept it's role as implementation
     */
    function acceptImplementation() public returns (uint256) {
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
     * @notice Begins transfer of governance rights.
     *         The newPendingGovernance must call `acceptGovernance`
     *         to finalize the transfer.
     * @dev Governance function to begin change of governance.
     *      The newPendingGovernance must call `acceptGovernance`
     *      to finalize the transfer.
     * @param newPendingGovernance New pending governance.
     */
    function setPendingGovernance(address newPendingGovernance) public onlyOperator {
        // Save current value, if any, for inclusion in log
        address oldPendingGovernance = pendingGovernance;

        // Store pendingGovernance with value newPendingGovernance
        pendingGovernance = newPendingGovernance;

        // Emit NewPendingGovernance(oldPendingGovernance, newPendingGovernance)
        emit NewPendingGovernance(oldPendingGovernance, newPendingGovernance);
    }

    /**
     * @notice Accepts transfer of Governance rights. msg.sender must be pendingGovernance
     * @dev Governance function for pending governance to accept role and update Governance
     */
    function acceptGovernance() public returns (uint256) {
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

    /* solhint-disable */
    receive() external payable {
        revert();
    }

    /**
     * @dev Delegates execution to an implementation contract.
     * It returns to the external caller whatever the implementation returns
     * or forwards reverts.
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import { DataTypes } from "../../libraries/types/DataTypes.sol";

/**
 * @dev Contract used to store registry's admin account
 */

contract RegistryAdminStorage {
    /**
     * @notice Governance of optyfi's earn protocol
     */
    address public governance;

    /**
     * @notice Operator of optyfi's earn protocol
     */
    address public operator;

    /**
     * @notice Strategist for this contract
     */
    address public strategist;

    /**
     * @notice Treasury for this contract
     */
    address public treasury;

    /**
     * @notice Minter for OPTY token
     */
    address public minter;

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
     * @notice when transfer operation of protocol occurs
     */
    event TransferOperator(address indexed operator, address indexed caller);

    /**
     * @notice Change strategist of protocol
     */
    event TransferStrategist(address indexed strategist, address indexed caller);

    /**
     * @notice Change minter of protocol
     */
    event TransferMinter(address indexed minter, address indexed caller);

    /**
     * @notice Change treasurer of protocol
     */
    event TransferTreasury(address indexed treasurer, address indexed caller);
}

contract RegistryStorage is RegistryAdminStorage {
    mapping(address => bool) public tokens;
    mapping(bytes32 => DataTypes.Token) public tokensHashToTokens;
    mapping(address => DataTypes.LiquidityPool) public liquidityPools;
    mapping(address => DataTypes.LiquidityPool) public creditPools;
    mapping(bytes32 => DataTypes.Strategy) public strategies;
    mapping(bytes32 => bytes32[]) public tokenToStrategies;
    mapping(address => mapping(address => bytes32)) public liquidityPoolToTokenHashes;
    mapping(address => address) public liquidityPoolToAdapter;
    mapping(address => mapping(string => address)) public underlyingTokenToRPToVaults;
    mapping(address => bool) public vaultToDiscontinued;
    mapping(address => bool) public vaultToPaused;
    mapping(string => DataTypes.RiskProfile) public riskProfiles;
    bytes32[] public strategyHashIndexes;
    bytes32[] public tokensHashIndexes;
    string[] public riskProfilesArray;
    /**
     * @dev Emitted when `token` is approved or revoked.
     *
     * Note that `token` cannot be zero address or EOA.
     */
    event LogToken(address indexed token, bool indexed enabled, address indexed caller);

    /**
     * @dev Emitted when `pool` is approved or revoked.
     *
     * Note that `pool` cannot be zero address or EOA.
     */
    event LogLiquidityPool(address indexed pool, bool indexed enabled, address indexed caller);

    /**
     * @dev Emitted when credit `pool` is approved or revoked.
     *
     * Note that `pool` cannot be zero address or EOA.
     */
    event LogCreditPool(address indexed pool, bool indexed enabled, address indexed caller);

    /**
     * @dev Emitted when `pool` is rated.
     *
     * Note that `pool` cannot be zero address or EOA.
     */
    event LogRateLiquidityPool(address indexed pool, uint8 indexed rate, address indexed caller);

    /**
     * @dev Emitted when `pool` is rated.
     *
     * Note that `pool` cannot be zero address or EOA.
     */
    event LogRateCreditPool(address indexed pool, uint8 indexed rate, address indexed caller);

    /**
     * @dev Emitted when `hash` strategy is set.
     *
     * Note that `token` cannot be zero address or EOA.
     */
    event LogSetStrategy(bytes32 indexed tokensHash, bytes32 indexed hash, address indexed caller);

    /**
     * @dev Emitted when `hash` strategy is scored.
     *
     * Note that `hash` startegy should exist in {strategyHashIndexes}.
     */
    event LogScoreStrategy(address indexed caller, bytes32 indexed hash, uint8 indexed score);

    /**
     * @dev Emitted when liquidity pool `pool` is assigned to `adapter`.
     *
     * Note that `pool` should be approved in {liquidityPools}.
     */
    event LogLiquidityPoolToDepositToken(address indexed pool, address indexed adapter, address indexed caller);

    /**
     * @dev Emitted when tokens are assigned to `_tokensHash`.
     *
     * Note that tokens should be approved
     */
    event LogTokensToTokensHash(bytes32 indexed _tokensHash, address indexed caller);

    /**
     * @dev Emiited when `Discontinue` over vault is activated
     *
     * Note that `vault` can not be a zero address
     */
    event LogDiscontinueVault(address indexed vault, bool indexed discontinued, address indexed caller);

    /**
     * @dev Emiited when `Pause` over vault is activated/deactivated
     *
     * Note that `vault` can not be a zero address
     */
    event LogPauseVault(address indexed vault, bool indexed paused, address indexed caller);

    /**
     * @dev Emitted when `setUnderlyingTokenToRPToVaults` function is called.
     *
     * Note that `underlyingToken` cannot be zero address or EOA.
     */
    event LogUnderlyingTokenRPVault(
        address indexed underlyingToken,
        string indexed riskProfile,
        address indexed vault,
        address caller
    );

    /**
     * @dev Emitted when RiskProfile is added
     *
     * Note that `riskProfile` can not be empty
     */
    event LogRiskProfile(uint256 indexed index, bool indexed exists, uint8 indexed steps, address caller);

    /**
     * @dev Emitted when Risk profile is set
     *
     * Note that `riskProfile` can not be empty
     */
    event LogRPPoolRatings(uint256 indexed index, uint8 indexed lowerLimit, uint8 indexed upperLimit, address caller);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.10;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { RegistryStorage } from "./RegistryStorage.sol";

/**
 * @dev Contract used to authorize and keep all the modifiers at one place
 */
contract ModifiersController is RegistryStorage {
    using Address for address;

    /**
     * @dev Transfers operator to a new account (`_governance`).
     * Can only be called by the governance.
     */

    function setOperator(address _operator) public onlyGovernance {
        require(_operator != address(0), "!address(0)");
        operator = _operator;
        emit TransferOperator(operator, msg.sender);
    }

    /**
     * @dev Transfers strategist to a new account (`_strategist`).
     * Can only be called by the current governance.
     */

    function setStrategist(address _strategist) public onlyGovernance {
        require(_strategist != address(0), "!address(0)");
        strategist = _strategist;
        emit TransferStrategist(strategist, msg.sender);
    }

    /**
     * @dev Transfers minter to a new account (`_minter`).
     * Can only be called by the current governance.
     */

    function setMinter(address _minter) public onlyGovernance {
        require(_minter != address(0), "!address(0)");
        minter = _minter;
        emit TransferMinter(minter, msg.sender);
    }

    /**
     * @dev Modifier to check caller is governance or not
     */
    modifier onlyGovernance() {
        require(msg.sender == governance, "caller is not having governance");
        _;
    }

    /**
     * @dev Modifier to check caller is operator or not
     */
    modifier onlyOperator() {
        require(msg.sender == operator, "caller is not the operator");
        _;
    }

    /**
     * @dev Modifier to check caller is strategist or not
     */
    modifier onlyStrategist() {
        require(msg.sender == strategist, "caller is not the strategist");
        _;
    }

    /**
     * @dev Modifier to check caller is minter or not
     */
    modifier onlyMinter() {
        require(msg.sender == minter, "caller is not the minter");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;

library DataTypes {
    struct Operation {
        address account;
        bool isDeposit;
        uint256 value;
    }

    struct BlockVaultValue {
        uint256 actualVaultValue;
        uint256 blockMinVaultValue;
        uint256 blockMaxVaultValue;
    }

    struct StrategyStep {
        address pool;
        address outputToken;
        bool isBorrow;
    }

    struct LiquidityPool {
        uint8 rating;
        bool isLiquidityPool;
    }

    struct Strategy {
        uint256 index;
        StrategyStep[] strategySteps;
    }

    struct Token {
        uint256 index;
        address[] tokens;
    }

    struct PoolRate {
        address pool;
        uint8 rate;
    }

    struct PoolAdapter {
        address pool;
        address adapter;
    }

    struct PoolRatingsRange {
        uint8 lowerLimit;
        uint8 upperLimit;
    }

    struct RiskProfile {
        uint256 index;
        uint8 steps;
        uint8 lowerLimit;
        uint8 upperLimit;
        bool exists;
    }

    struct VaultRewardStrategy {
        uint256 hold; //  should be in basis eg: 50% means 5000
        uint256 convert; //  should be in basis eg: 50% means 5000
    }

    enum MaxExposure { Number, Pct }

    /// @notice The market's last index
    /// @notice The block number the index was last updated at
    struct ODEFIState {
        uint224 index;
        uint32 timestamp;
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

