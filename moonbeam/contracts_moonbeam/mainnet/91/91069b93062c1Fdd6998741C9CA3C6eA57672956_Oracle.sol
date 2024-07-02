// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Types.sol";
import "ILedger.sol";
import "IOracleMaster.sol";

import "ReportUtils.sol";


contract Oracle {
    using ReportUtils for uint256;

    event Completed(uint256);

    // is already pushed flag
    bool public isPushed;

    // Current era report  hashes
    uint256[] internal currentReportVariants;

    // Current era reports
    Types.OracleData[] private currentReports;

    // Then oracle member push report, its bit is set
    uint256 internal currentReportBitmask;

    // oracle master contract address
    address public ORACLE_MASTER;

    // linked ledger contract address
    address public LEDGER;

    // Allows function calls only from OracleMaster
    modifier onlyOracleMaster() {
        require(msg.sender == ORACLE_MASTER);
        _;
    }

    /**
    * @notice Initialize oracle contract
    * @param _oracleMaster oracle master address
    * @param _ledger linked ledger address
    */
    function initialize(address _oracleMaster, address _ledger) external {
        require(ORACLE_MASTER == address(0), "ORACLE: ALREADY_INITIALIZED");
        ORACLE_MASTER = _oracleMaster;
        LEDGER = _ledger;
    }

    /**
    * @notice Returns true if member is already reported
    * @param _index oracle member index
    * @return is reported indicator
    */
    function isReported(uint256 _index) external view returns (bool) {
        return (currentReportBitmask & (1 << _index)) != 0;
    }

    /**
    * @notice Accept oracle report data, allowed to call only by oracle master contract
    * @param _index oracle member index
    * @param _quorum the minimum number of voted oracle members to accept a variant
    * @param _eraId current era id
    * @param _staking report data
    */
    function reportRelay(uint256 _index, uint256 _quorum, uint64 _eraId, Types.OracleData calldata _staking) external onlyOracleMaster {
        {
            uint256 mask = 1 << _index;
            uint256 reportBitmask = currentReportBitmask;
            require(reportBitmask & mask == 0, "ORACLE: ALREADY_SUBMITTED");
            currentReportBitmask = (reportBitmask | mask);
        }
        // return instantly if already got quorum and pushed data
        if (isPushed) {
            return;
        }

        // convert staking report into 31 byte hash. The last byte is used for vote counting
        uint256 variant = uint256(keccak256(abi.encode(_staking))) & ReportUtils.COUNT_OUTMASK;

        uint256 i = 0;
        uint256 _length = currentReportVariants.length;
        // iterate on all report variants we already have, limited by the oracle members maximum
        while (i < _length && currentReportVariants[i].isDifferent(variant)) ++i;
        if (i < _length) {
            if (currentReportVariants[i].getCount() + 1 >= _quorum) {
                _push(_eraId, _staking);
            } else {
                ++currentReportVariants[i];
                // increment variant counter, see ReportUtils for details
            }
        } else {
            if (_quorum == 1) {
                _push(_eraId, _staking);
            } else {
                currentReportVariants.push(variant + 1);
                currentReports.push(_staking);
            }
        }
    }

    /**
    * @notice Change quorum threshold, allowed to call only by oracle master contract
    * @dev Method can trigger to pushing data to ledger if quorum threshold decreased and
           now for contract already reached new threshold.
    * @param _quorum new quorum threshold
    * @param _eraId current era id
    */
    function softenQuorum(uint8 _quorum, uint64 _eraId) external onlyOracleMaster {
        (bool isQuorum, uint256 reportIndex) = _getQuorumReport(_quorum);
        if (isQuorum) {
            Types.OracleData memory report = _getStakeReport(reportIndex);
            _push(
                _eraId, report
            );
        }
    }

    /**
    * @notice Clear data about current reporting, allowed to call only by oracle master contract
    */
    function clearReporting() external onlyOracleMaster {
        _clearReporting();
    }

    /**
    * @notice Returns report by given index
    * @param _index oracle member index
    * @return staking report data
    */
    function _getStakeReport(uint256 _index) internal view returns (Types.OracleData storage staking) {
        assert(_index < currentReports.length);
        return currentReports[_index];
    }

    /**
    * @notice Clear data about current reporting
    */
    function _clearReporting() internal {
        currentReportBitmask = 0;
        isPushed = false;

        delete currentReportVariants;
        delete currentReports;
    }

    /**
    * @notice Push data to ledger
    */
    function _push(uint64 _eraId, Types.OracleData memory report) internal {
        ILedger(LEDGER).pushData(_eraId, report);
        isPushed = true;
    }

    /**
    * @notice Return whether the `_quorum` is reached and the final report can be pushed
    */
    function _getQuorumReport(uint256 _quorum) internal view returns (bool, uint256) {
        // check most frequent cases first: all reports are the same or no reports yet
        uint256 _length = currentReportVariants.length;
        if (_length == 1) {
            return (currentReportVariants[0].getCount() >= _quorum, 0);
        } else if (_length == 0) {
            return (false, type(uint256).max);
        }

        // if more than 2 kind of reports exist, choose the most frequent
        uint256 maxind = 0;
        uint256 repeat = 0;
        uint16 maxval = 0;
        uint16 cur = 0;
        for (uint256 i = 0; i < _length; ++i) {
            cur = currentReportVariants[i].getCount();
            if (cur >= maxval) {
                if (cur == maxval) {
                    ++repeat;
                } else {
                    maxind = i;
                    maxval = cur;
                    repeat = 0;
                }
            }
        }
        return (maxval >= _quorum && repeat == 0, maxind);
    }
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

import "Types.sol";

interface ILedger {
    function initialize(
        bytes32 _stashAccount,
        bytes32 controllerAccount,
        address vKSM,
        address controller,
        uint128 minNominatorBalance,
        address lido,
        uint128 _minimumBalance,
        uint256 _maxUnlockingChunks
    ) external;

    function pushData(uint64 eraId, Types.OracleData calldata staking) external;

    function nominate(bytes32[] calldata validators) external;

    function status() external view returns (Types.LedgerStatus);

    function isEmpty() external view returns (bool);

    function stashAccount() external view returns (bytes32);

    function totalBalance() external view returns (uint128);

    function setRelaySpecs(uint128 minNominatorBalance, uint128 minimumBalance, uint256 _maxUnlockingChunks) external;

    function cachedTotalBalance() external view returns (uint128);

    function transferDownwardBalance() external view returns (uint128);
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