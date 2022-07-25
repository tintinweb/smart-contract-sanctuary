// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IBeacon.sol";
import "Address.sol";

import "ILido.sol";
import "IAuthManager.sol";

/**
 * @dev This contract is used in conjunction with one or more instances of {BeaconProxy} to determine their
 * implementation contract, which is where they will delegate all function calls.
 *
 * An ROLE_BEACON_MANAGER is able to change the implementation the beacon points to, thus upgrading the proxies that use this beacon.
 */
contract LedgerBeacon is IBeacon {
    // LIDO address
    address public LIDO;

    // current revision index
    uint256 public currentRevision;

    // index of newest revision
    uint256 public latestRevision;

    // array of implementations
    address[] public revisionImplementation;

    // revision index for specific ledger (if revision == 0 => current revision used)
    mapping(address => uint256) public ledgerRevision;

    // index of max revision for ledger
    mapping(address => uint256) public ledgerMaxRevision;

    // Beacon manager role
    bytes32 internal constant ROLE_BEACON_MANAGER = keccak256("ROLE_BEACON_MANAGER");

    /**
     * @dev Emitted when new implementation revision added.
     */
    event NewRevision(address indexed implementation);

    /**
     * @dev Emitted when current revision updated.
     */
    event NewCurrentRevision(address indexed implementation);

    /**
     * @dev Emitted when ledger current revision updated.
     */
    event NewLedgerRevision(address indexed ledger, address indexed implementation);

    modifier auth(bytes32 role) {
        require(IAuthManager(ILido(LIDO).AUTH_MANAGER()).has(role, msg.sender), "LEDGER_BEACON: UNAUTHOROZED");
        _;
    }

    /**
     * @dev Sets the address of the initial implementation, and the deployer account as the owner who can upgrade the
     * beacon.
     */
    constructor(address implementation_, address _lido) {
        _setImplementation(implementation_);
        currentRevision = latestRevision;
        LIDO = _lido;
    }

    /**
     * @dev Returns the current implementation address.
     */
    function implementation() public view virtual override returns (address) {
        if (ledgerRevision[msg.sender] != 0) {
            return revisionImplementation[ledgerRevision[msg.sender] - 1];
        }
        return revisionImplementation[currentRevision - 1];
    }

    /**
    * @dev Set ledger revision to `_revision`
    */
    function setLedgerRevision(address _ledger, uint256 _revision) external auth(ROLE_BEACON_MANAGER) {
        require(
            (ledgerRevision[_ledger] == 0 && _revision > ledgerMaxRevision[_ledger] && _revision <= latestRevision) || 
            (ledgerRevision[_ledger] > 0 && _revision == 0), 
            "LEDGER_BEACON: INCORRECT_REVISION"
        );
        ledgerRevision[_ledger] = _revision;

        if (_revision == 0) {
            _revision = currentRevision;
        }
        else {
            ledgerMaxRevision[_ledger] = _revision;
        }
        emit NewLedgerRevision(_ledger, revisionImplementation[_revision - 1]);
    }

    /**
    * @dev Update current revision
    */
    function setCurrentRevision(uint256 _newCurrentRevision) external auth(ROLE_BEACON_MANAGER) {
        require(_newCurrentRevision > currentRevision && _newCurrentRevision <= latestRevision, "LEDGER_BEACON: INCORRECT_REVISION");
        currentRevision = _newCurrentRevision;
        emit NewCurrentRevision(revisionImplementation[_newCurrentRevision - 1]);
    }

    /**
     * @dev Add new revision of implementation to beacon.
     *
     * Emits an {Upgraded} event.
     *
     * Requirements:
     *
     * - msg.sender must be the owner of the contract.
     * - `newImplementation` must be a contract.
     */
    function addImplementation(address newImplementation) public auth(ROLE_BEACON_MANAGER) {
        _setImplementation(newImplementation);
        emit NewRevision(newImplementation);
    }

    /**
     * @dev Sets the implementation contract address for this beacon
     *
     * Requirements:
     *
     * - `newImplementation` must be a contract.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "LEDGER_BEACON: implementation is not a contract");
        latestRevision += 1;
        revisionImplementation.push(newImplementation);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
pragma solidity ^0.8.0;

import "Types.sol";

interface ILido {
    function MAX_ALLOWABLE_DIFFERENCE() external view returns(uint128);

    function deposit(uint256 amount) external returns (uint256);

    function distributeRewards(uint256 totalRewards, uint256 ledgerBalance) external;

    function distributeLosses(uint256 totalLosses, uint256 ledgerBalance) external;

    function getStashAccounts() external view returns (bytes32[] memory);

    function getLedgerAddresses() external view returns (address[] memory);

    function ledgerStake(address ledger) external view returns (uint256);

    function transferFromLedger(uint256 amount, uint256 excess) external;

    function transferFromLedger(uint256 amount) external;

    function transferToLedger(uint256 amount) external;

    function flushStakes() external;

    function findLedger(bytes32 stash) external view returns (address);

    function AUTH_MANAGER() external returns(address);

    function ORACLE_MASTER() external view returns (address);

    function decimals() external view returns (uint8);

    function getPooledKSMByShares(uint256 sharesAmount) external view returns (uint256);

    function getSharesByPooledKSM(uint256 amount) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Types {
    struct Fee{
        uint16 total;
        uint16 operators;
        uint16 developers;
        uint16 treasury;
    }

    struct Stash {
        bytes32 stashAccount;
        uint64  eraId;
    }

    enum LedgerStatus {
        // bonded but not participate in staking
        Idle,
        // participate as nominator
        Nominator,
        // participate as validator
        Validator,
        // not bonded not participate in staking
        None
    }

    struct UnlockingChunk {
        uint128 balance;
        uint64 era;
    }

    struct OracleData {
        bytes32 stashAccount;
        bytes32 controllerAccount;
        LedgerStatus stakeStatus;
        // active part of stash balance
        uint128 activeBalance;
        // locked for stake stash balance.
        uint128 totalBalance;
        // totalBalance = activeBalance + sum(unlocked.balance)
        UnlockingChunk[] unlocking;
        uint32[] claimedRewards;
        // stash account balance. It includes locked (totalBalance) balance assigned
        // to a controller.
        uint128 stashBalance;
        // slashing spans for ledger
        uint32 slashingSpans;
    }

    struct RelaySpec {
        uint16 maxValidatorsPerLedger;
        uint128 minNominatorBalance;
        uint128 ledgerMinimumActiveBalance;
        uint256 maxUnlockingChunks;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAuthManager {
    function has(bytes32 role, address member) external view returns (bool);

    function add(bytes32 role, address member) external;

    function remove(bytes32 role, address member) external;
}