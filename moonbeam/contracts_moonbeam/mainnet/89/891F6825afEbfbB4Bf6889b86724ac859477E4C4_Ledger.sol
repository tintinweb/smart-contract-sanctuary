// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "IERC20.sol";
import "SafeCast.sol";

import "IOracleMaster.sol";
import "ILido.sol";
import "IAuthManager.sol";
import "IRelayEncoder.sol";
import "IXcmTransactor.sol";
import "IController.sol";
import "Types.sol";

import "LedgerUtils.sol";
import "ReportUtils.sol";



contract Ledger {
    using LedgerUtils for Types.OracleData;
    using SafeCast for uint256;

    event DownwardComplete(uint128 amount);
    event UpwardComplete(uint128 amount);
    event Rewards(uint128 amount, uint128 balance);
    event Slash(uint128 amount, uint128 balance);

    // Lido main contract address
    ILido public LIDO;

    // vKSM precompile
    IERC20 internal VKSM;

    // controller for sending xcm messages to relay chain
    IController internal CONTROLLER;

    // ledger stash account
    bytes32 public stashAccount;

    // ledger controller account
    bytes32 public controllerAccount;

    // Stash balance that includes locked (bounded in stake) and free to transfer balance
    uint128 public totalBalance;

    // Locked, or bonded in stake module, balance
    uint128 public lockedBalance;

    // last reported active ledger balance
    uint128 public activeBalance;

    // last reported ledger status
    Types.LedgerStatus public status;

    // Cached stash balance. Need to calculate rewards between successfull up/down transfers
    uint128 public cachedTotalBalance;

    // Pending transfers
    uint128 public transferUpwardBalance;
    uint128 public transferDownwardBalance;

    // Pending bonding
    uint128 public pendingBonds;

    // Minimal allowed balance to being a nominator
    uint128 public MIN_NOMINATOR_BALANCE;

    // Minimal allowable active balance
    uint128 public MINIMUM_BALANCE;

    // Ledger manager role
    bytes32 internal constant ROLE_LEDGER_MANAGER = keccak256("ROLE_LEDGER_MANAGER");

    // Maximum allowable unlocking chunks amount
    uint256 public MAX_UNLOCKING_CHUNKS;

    // Allows function calls only from LIDO
    modifier onlyLido() {
        require(msg.sender == address(LIDO), "LEDGER: NOT_LIDO");
        _;
    }

    // Allows function calls only from Oracle
    modifier onlyOracle() {
        address oracle = IOracleMaster(ILido(LIDO).ORACLE_MASTER()).getOracle(address(this));
        require(msg.sender == oracle, "LEDGER: NOT_ORACLE");
        _;
    }

    // Allows function calls only from member with specific role
    modifier auth(bytes32 role) {
        require(IAuthManager(ILido(LIDO).AUTH_MANAGER()).has(role, msg.sender), "LEDGER: UNAUTHOROZED");
        _;
    }

    /**
    * @notice Initialize ledger contract.
    * @param _stashAccount - stash account id
    * @param _controllerAccount - controller account id
    * @param _vKSM - vKSM contract address
    * @param _controller - xcmTransactor(relaychain calls relayer) contract address
    * @param _minNominatorBalance - minimal allowed nominator balance
    * @param _lido - LIDO address
    * @param _minimumBalance - minimal allowed active balance for ledger
    * @param _maxUnlockingChunks - maximum amount of unlocking chunks
    */
    function initialize(
        bytes32 _stashAccount,
        bytes32 _controllerAccount,
        address _vKSM,
        address _controller,
        uint128 _minNominatorBalance,
        address _lido,
        uint128 _minimumBalance,
        uint256 _maxUnlockingChunks
    ) external {
        require(_vKSM != address(0), "LEDGER: INCORRECT_VKSM");
        require(address(VKSM) == address(0), "LEDGER: ALREADY_INITIALIZED");

        // The owner of the funds
        stashAccount = _stashAccount;
        // The account which handles bounded part of stash funds (unbond, rebond, withdraw, nominate)
        controllerAccount = _controllerAccount;

        status = Types.LedgerStatus.None;

        LIDO = ILido(_lido);

        VKSM = IERC20(_vKSM);

        CONTROLLER = IController(_controller);

        MIN_NOMINATOR_BALANCE = _minNominatorBalance;

        MINIMUM_BALANCE = _minimumBalance;
        
        MAX_UNLOCKING_CHUNKS = _maxUnlockingChunks;

        _refreshAllowances();
    }

    /**
    * @notice Set new minimal allowed nominator balance and minimal active balance, allowed to call only by lido contract
    * @dev That method designed to be called by lido contract when relay spec is changed
    * @param _minNominatorBalance - minimal allowed nominator balance
    * @param _minimumBalance - minimal allowed ledger active balance
    * @param _maxUnlockingChunks - maximum amount of unlocking chunks
    */
    function setRelaySpecs(uint128 _minNominatorBalance, uint128 _minimumBalance, uint256 _maxUnlockingChunks) external onlyLido {
        MIN_NOMINATOR_BALANCE = _minNominatorBalance;
        MINIMUM_BALANCE = _minimumBalance;
        MAX_UNLOCKING_CHUNKS = _maxUnlockingChunks;
    }

    /**
    * @notice Refresh allowances for ledger
    */
    function refreshAllowances() external auth(ROLE_LEDGER_MANAGER) {
        _refreshAllowances();
    }

    /**
    * @notice Return target stake amount for this ledger
    * @return target stake amount
    */
    function ledgerStake() public view returns (uint256) {
        return LIDO.ledgerStake(address(this));
    }

    /**
    * @notice Return true if ledger doesn't have any funds
    */
    function isEmpty() external view returns (bool) {
        return totalBalance == 0 && transferUpwardBalance == 0 && transferDownwardBalance == 0;
    }

    /**
    * @notice Nominate on behalf of this ledger, allowed to call only by lido contract
    * @dev Method spawns xcm call to relaychain.
    * @param _validators - array of choosen validator to be nominated
    */
    function nominate(bytes32[] calldata _validators) external onlyLido {
        require(activeBalance >= MIN_NOMINATOR_BALANCE, "LEDGER: NOT_ENOUGH_STAKE");
        CONTROLLER.nominate(_validators);
    }

    /**
    * @notice Provide portion of relaychain data about current ledger, allowed to call only by oracle contract
    * @dev Basically, ledger can obtain data from any source, but for now it allowed to recieve only from oracle.
           Method perform calculation of current state based on report data and saved state and expose
           required instructions(relaychain pallet calls) via xcm to adjust bonded amount to required target stake.
    * @param _eraId - reporting era id
    * @param _report - data that represent state of ledger on relaychain for `_eraId`
    */
    function pushData(uint64 _eraId, Types.OracleData memory _report) external onlyOracle {
        require(stashAccount == _report.stashAccount, "LEDGER: STASH_ACCOUNT_MISMATCH");

        status = _report.stakeStatus;
        activeBalance = _report.activeBalance;

        (uint128 unlockingBalance, uint128 withdrawableBalance) = _report.getTotalUnlocking(_eraId);

        if (!_processRelayTransfers(_report)) {
            return;
        }
        uint128 _cachedTotalBalance = cachedTotalBalance;
        
        if (cachedTotalBalance > 0) {
            uint128 relativeDifference = _report.stashBalance > cachedTotalBalance ? 
                _report.stashBalance - cachedTotalBalance :
                cachedTotalBalance - _report.stashBalance;
            // NOTE: 1 / 10000 - one base point
            relativeDifference = relativeDifference * 10000 / cachedTotalBalance;
            require(relativeDifference < LIDO.MAX_ALLOWABLE_DIFFERENCE(), "LEDGER: DIFFERENCE_EXCEEDS_BALANCE");
        }

        if (_cachedTotalBalance < _report.stashBalance) { // if cached balance > real => we have reward
            uint128 reward = _report.stashBalance - _cachedTotalBalance;
            LIDO.distributeRewards(reward, _report.stashBalance);

            emit Rewards(reward, _report.stashBalance);
        }
        else if (_cachedTotalBalance > _report.stashBalance) {
            uint128 slash = _cachedTotalBalance - _report.stashBalance;
            LIDO.distributeLosses(slash, _report.stashBalance);

            emit Slash(slash, _report.stashBalance);
        }

        uint128 _ledgerStake = ledgerStake().toUint128();

        // Always transfer deficit to relay chain
        if (_report.stashBalance < _ledgerStake) {
            uint128 deficit = _ledgerStake - _report.stashBalance;
            require(VKSM.balanceOf(address(LIDO)) >= deficit, "LEDGER: TRANSFER_EXCEEDS_BALANCE");
            LIDO.transferToLedger(deficit);
            CONTROLLER.transferToRelaychain(deficit);
            transferUpwardBalance += deficit;
        }

        uint128 relayFreeBalance = _report.getFreeBalance();
        pendingBonds = 0; // Always set bonds to zero (if we have old free balance then it will bond again)

        if (activeBalance < _ledgerStake) {
            // NOTE: if ledger stake > active balance we are trying to bond all funds
            uint128 diff = _ledgerStake - activeBalance;
            uint128 diffToRebond = diff > unlockingBalance ? unlockingBalance : diff;
            if (diffToRebond > 0) {
                CONTROLLER.rebond(diffToRebond, MAX_UNLOCKING_CHUNKS);
                diff -= diffToRebond;
            }

            if (transferUpwardBalance > 0 && relayFreeBalance == transferUpwardBalance) {
                // In case if bond amount = transferUpwardBalance we can't distinguish 2 messages were success or 2 messages were failed
                relayFreeBalance -= 1;
            }

            if (diff > 0 && relayFreeBalance > 0) {
                uint128 diffToBond = diff > relayFreeBalance ? relayFreeBalance : diff;
                if (_report.stakeStatus == Types.LedgerStatus.Nominator || _report.stakeStatus == Types.LedgerStatus.Idle) {
                    CONTROLLER.bondExtra(diffToBond);
                    pendingBonds = diffToBond;
                } else if (_report.stakeStatus == Types.LedgerStatus.None && diffToBond >= MIN_NOMINATOR_BALANCE) {
                    CONTROLLER.bond(controllerAccount, diffToBond);
                    pendingBonds = diffToBond;
                }
                relayFreeBalance -= diffToBond;
            }
        }
        else {
            if (_ledgerStake < MIN_NOMINATOR_BALANCE && status != Types.LedgerStatus.Idle && activeBalance > 0) {
                CONTROLLER.chill();
            }

            // NOTE: if ledger stake < active balance we unbond
            uint128 diff = activeBalance - _ledgerStake;
            if (diff > 0) {
                CONTROLLER.unbond(diff);
            }

            // NOTE: if ledger stake == active balance we only withdraw unlocked balance
            if (withdrawableBalance > 0) {
                uint32 slashSpans = 0;
                if (_report.unlocking.length == 0 && _report.activeBalance <= MINIMUM_BALANCE) {
                    slashSpans = _report.slashingSpans;
                }
                CONTROLLER.withdrawUnbonded(slashSpans);
            }
        }
        
        // NOTE: always transfer all free baalance to parachain
        if (relayFreeBalance > 0) {
            CONTROLLER.transferToParachain(relayFreeBalance);
            transferDownwardBalance += relayFreeBalance;
        }

        cachedTotalBalance = _report.stashBalance;
    }

    /**
    * @notice Await for all transfers from/to relay chain
    * @param _report - data that represent state of ledger on relaychain
    */
    function _processRelayTransfers(Types.OracleData memory _report) internal returns(bool) {
        // wait for the downward transfer to complete
        uint128 _transferDownwardBalance = transferDownwardBalance;
        if (_transferDownwardBalance > 0) {
            uint128 totalDownwardTransferred = uint128(VKSM.balanceOf(address(this)));

            if (totalDownwardTransferred >= _transferDownwardBalance ) {
                // send all funds to lido
                LIDO.transferFromLedger(_transferDownwardBalance, totalDownwardTransferred - _transferDownwardBalance);

                // Clear transfer flag
                cachedTotalBalance -= _transferDownwardBalance;
                transferDownwardBalance = 0;

                emit DownwardComplete(_transferDownwardBalance);
                _transferDownwardBalance = 0;
            }
        }

        // wait for the upward transfer to complete
        uint128 _transferUpwardBalance = transferUpwardBalance;
        if (_transferUpwardBalance > 0) {
            // NOTE: pending Bonds allows to control balance which was bonded in previous era, but not in lockedBalance yet
            // (see single_ledger_test:test_equal_deposit_bond)
            uint128 ledgerFreeBalance = (totalBalance - lockedBalance);
            int128 freeBalanceDiff = int128(_report.getFreeBalance()) - int128(ledgerFreeBalance);
            int128 expectedBalanceDiff = int128(transferUpwardBalance) - int128(pendingBonds);

            if (freeBalanceDiff >= expectedBalanceDiff) {
                cachedTotalBalance += _transferUpwardBalance;

                transferUpwardBalance = 0;
                // pendingBonds = 0;
                emit UpwardComplete(_transferUpwardBalance);
                _transferUpwardBalance = 0;
            }
        }

        if (_transferDownwardBalance == 0 && _transferUpwardBalance == 0) {
            // update ledger data from oracle report
            totalBalance = _report.stashBalance;
            lockedBalance = _report.totalBalance;
            return true;
        }

        return false;
    }

    /**
    * @notice Refresh allowances for ledger
    */
    function _refreshAllowances() internal {
        VKSM.approve(address(LIDO), type(uint256).max);
        VKSM.approve(address(CONTROLLER), type(uint256).max);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOracleMaster {
    function addLedger(address ledger) external;

    function removeLedger(address ledger) external;

    function getOracle(address ledger) view external returns (address);

    function eraId() view external returns (uint64);

    function setLido(address lido) external;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @author The Moonbeam Team
/// @title The interface through which solidity contracts will interact with Relay Encoder
/// We follow this same interface including four-byte function selectors, in the precompile that
/// wraps the pallet
interface IRelayEncoder {
    // dev Encode 'bond' relay call
    // Selector: 31627376
    // @param controller_address: Address of the controller
    // @param amount: The amount to bond
    // @param reward_destination: the account that should receive the reward
    // @returns The bytes associated with the encoded call
    function encode_bond(uint256 controller_address, uint256 amount, bytes memory reward_destination) external view returns (bytes memory result);

    // dev Encode 'bond_extra' relay call
    // Selector: 49def326
    // @param amount: The extra amount to bond
    // @returns The bytes associated with the encoded call
    function encode_bond_extra(uint256 amount) external view returns (bytes memory result);

    // dev Encode 'unbond' relay call
    // Selector: bc4b2187
    // @param amount: The amount to unbond
    // @returns The bytes associated with the encoded call
    function encode_unbond(uint256 amount) external view returns (bytes memory result);

    // dev Encode 'withdraw_unbonded' relay call
    // Selector: 2d220331
    // @param slashes: Weight hint, number of slashing spans
    // @returns The bytes associated with the encoded call
    function encode_withdraw_unbonded(uint32 slashes) external view returns (bytes memory result);

    // dev Encode 'validate' relay call
    // Selector: 3a0d803a
    // @param comission: Comission of the validator as parts_per_billion
    // @param blocked: Whether or not the validator is accepting more nominations
    // @returns The bytes associated with the encoded call
    // selector: 3a0d803a
    // function encode_validate(uint256 comission, bool blocked) external pure returns (bytes memory result);

    // dev Encode 'nominate' relay call
    // Selector: a7cb124b
    // @param nominees: An array of AccountIds corresponding to the accounts we will nominate
    // @param blocked: Whether or not the validator is accepting more nominations
    // @returns The bytes associated with the encoded call
    function encode_nominate(uint256 [] memory nominees) external view returns (bytes memory result);

    // dev Encode 'chill' relay call
    // Selector: bc4b2187
    // @returns The bytes associated with the encoded call
    function encode_chill() external view returns (bytes memory result);

    // dev Encode 'set_payee' relay call
    // Selector: 9801b147
    // @param reward_destination: the account that should receive the reward
    // @returns The bytes associated with the encoded call
    // function encode_set_payee(bytes memory reward_destination) external pure returns (bytes memory result);

    // dev Encode 'set_controller' relay call
    // Selector: 7a8f48c2
    // @param controller: The controller address
    // @returns The bytes associated with the encoded call
    // function encode_set_controller(uint256 controller) external pure returns (bytes memory result);

    // dev Encode 'rebond' relay call
    // Selector: add6b3bf
    // @param amount: The amount to rebond
    // @returns The bytes associated with the encoded call
    function encode_rebond(uint256 amount) external view returns (bytes memory result);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Xcm Transactor Interface
 *
 * The interface through which solidity contracts will interact with xcm transactor pallet
 *
 */
interface IXcmTransactor {
    // A multilocation is defined by its number of parents and the encoded junctions (interior)
    struct Multilocation {
        uint8 parents;
        bytes [] interior;
    }

    /** Get index of an account in xcm transactor
     *
     * @param index The index of which we want to retrieve the account
     */
    function index_to_account(uint16 index) external view returns(address);

    /** Get transact info of a multilocation
     * Selector 71b0edfa
     * @param multilocation The location for which we want to retrieve transact info
     */
    function transact_info(Multilocation memory multilocation)
        external view  returns(uint64, uint256, uint64, uint64, uint256);

    /** Transact through XCM using fee based on its multilocation
     *
     * @dev The token transfer burns/transfers the corresponding amount before sending
     * @param transactor The transactor to be used
     * @param index The index to be used
     * @param fee_asset The asset in which we want to pay fees.
     * It has to be a reserve of the destination chain
     * @param weight The weight we want to buy in the destination chain
     * @param inner_call The inner call to be executed in the destination chain
     */
    function transact_through_derivative_multilocation(
        uint8 transactor,
        uint16 index,
        Multilocation memory fee_asset,
        uint64 weight,
        bytes memory inner_call
    ) external;

    /** Transact through XCM using fee based on its currency_id
     *
     * @dev The token transfer burns/transfers the corresponding amount before sending
     * @param transactor The transactor to be used
     * @param index The index to be used
     * @param currency_id Address of the currencyId of the asset to be used for fees
     * It has to be a reserve of the destination chain
     * @param weight The weight we want to buy in the destination chain
     * @param inner_call The inner call to be executed in the destination chain
     */
    function transact_through_derivative(
        uint8 transactor,
        uint16 index,
        address currency_id,
        uint64 weight,
        bytes memory inner_call
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IController {
    function newSubAccount(uint16 index, bytes32 accountId, address paraAddress) external;

    function deleteSubAccount(address paraAddress) external;

    function nominate(bytes32[] calldata _validators) external;

    function bond(bytes32 controller, uint256 amount) external;

    function bondExtra(uint256 amount) external;

    function unbond(uint256 amount) external;

    function withdrawUnbonded(uint32 slashingSpans) external;

    function rebond(uint256 amount, uint256 unbondingChunks) external;

    function chill() external;

    function transferToParachain(uint256 amount) external;

    function transferToRelaychain(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Types.sol";


library LedgerUtils {
    /// @notice Return unlocking and withdrawable balances
    function getTotalUnlocking(Types.OracleData memory report, uint64 _eraId) internal pure returns (uint128, uint128) {
        uint128 _total = 0;
        uint128 _withdrawble = 0;
        for (uint i = 0; i < report.unlocking.length; i++) {
            _total += report.unlocking[i].balance;
            if (report.unlocking[i].era <= _eraId) {
                _withdrawble += report.unlocking[i].balance;
            }
        }
        return (_total, _withdrawble);
    }
    /// @notice Return stash balance that can be freely transfer or allocated for stake
    function getFreeBalance(Types.OracleData memory report) internal pure returns (uint128) {
        return report.stashBalance - report.totalBalance;
    }

    /// @notice Return true if report is consistent
    function isConsistent(Types.OracleData memory report) internal pure returns (bool) {
        (uint128 _total,) = getTotalUnlocking(report, 0);
        return report.unlocking.length < type(uint8).max
            && report.totalBalance == (report.activeBalance + _total)
            && report.stashBalance >= report.totalBalance;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


library ReportUtils {
    // last bytes used to count votes
    uint256 constant internal COUNT_OUTMASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00;

    /// @notice Check if the given reports are different, not considering the counter of the first
    function isDifferent(uint256 value, uint256 that) internal pure returns (bool) {
        return (value & COUNT_OUTMASK) != that;
    }

    /// @notice Return the total number of votes recorded for the variant
    function getCount(uint256 value) internal pure returns (uint8) {
        return uint8(value);
    }
}