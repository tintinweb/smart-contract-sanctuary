pragma solidity ^0.6.0;

interface IVotingEscrow {
    function getLastUserSlope(address addr) external view returns(int128);
    function lockedEnd(address addr) external view returns(uint256);
    function userPointEpoch(address addr) external view returns(uint256);
    function userPointHistoryTs(address addr, uint256 epoch) external view returns(uint256);
    function balanceOfAt(address addr, uint256 _block) external view returns(uint256);
    function lockStarts(address addr) external view returns(uint256);
}

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/math/Math.sol";

import "../interfaces/IVotingEscrow.sol";

contract GaugeController is Initializable {

    // # 7 * 86400 seconds - all future times are rounded by week
    uint256 public constant WEEK = 604800;

    // # Cannot change weight votes more often than once in 10 days
    uint256 public constant WEIGHT_VOTE_DELAY = 10 * 86400;

    struct Point {
        uint256 bias;
        uint256 slope;
    }

    struct VotedSlope {
        uint256 slope;
        uint256 power;
        uint256 end;
    }

    event CommitOwnership(address admin);
    event ApplyOwnership(address admin);
    event AddType(string name, int128 typeId);
    event NewTypeWeight(int128 typeId, uint256 time, uint256 weight, uint256 totalWeight);
    event NewGaugeWeight(address gaugeAddress, uint256 time, uint256 weight, uint256 totalWeight);
    event VoteForGauge(uint256 time, address user, address gaugeAddr, uint256 weight);
    event NewGauge(address addr, int128 gaugeType, uint256 weight);

    // Custom added event
    event GaugeWeightWrite(address addr, uint256 time, uint256 weight);

    uint256 public constant MULTIPLIER = 10 ** 18;

    address public admin;
    address public futureAdmin;

    address public token;
    address public votingEscrow;

    // # Gauge parameters
    // # All numbers are "fixed point" on the basis of 1e18
    int128 public nGaugeTypes;
    int128 public nGauges;
    mapping(int128 => string) public gaugeTypeNames;

    // # Needed for enumeration
    address[1000000000] public gauges;

    // # we increment values by 1 prior to storing them here so we can rely on a value
    // # of zero as meaning the gauge has not been set
    mapping(address => int128) internal _gaugeTypes;

    // # user -> gauge_addr -> VotedSlope
    mapping(address => mapping(address => VotedSlope)) public voteUserSlopes;

    // # Total vote power used by user
    mapping(address => uint256) public voteUserPower;

    // # Last user vote's timestamp for each gauge address
    mapping(address => mapping(address => uint256)) public lastUserVote;

    // # Past and scheduled points for gauge weight, sum of weights per type, total weight
    // # Point is for bias+slope
    // # changes_* are for changes in slope
    // # time_* are for the last change timestamp
    // # timestamps are rounded to whole weeks

    // # gauge_addr -> time -> Point
    mapping(address => mapping(uint256 => Point)) public pointsWeight;

    // # gauge_addr -> time -> slope
    mapping(address => mapping(uint256 => uint256)) internal _changesWeight;

    // # gauge_addr -> last scheduled time (next week)
    mapping(address => uint256) public timeWeight;

    // # type_id -> time -> Point
    mapping(int128 => mapping(uint256 => Point)) public pointsSum;

    // # type_id -> time -> slope
    mapping(int128 => mapping(uint256 => uint256)) internal _changesSum;

    // # type_id -> last scheduled time (next week)
    uint256[1000000000] public timeSum;

    // # time -> total weight
    mapping(uint256 => uint256) public pointsTotal;
    uint256 public timeTotal; // # last scheduled time

    // # type_id -> time -> type weight
    mapping(int128 => mapping(uint256 => uint256)) public pointsTypeWeight;
    uint256[1000000000] public timeTypeWeight;

    // """
    // @notice Contract initializer
    // @param _token `XBEInflation` contract address
    // @param _voting_escrow `VotingEscrow` contract address
    // """
    function configure(address _token, address _votingEscrow) external initializer {
        require(_token != address(0), "tokenZero");
        require(_votingEscrow != address(0), "votingEscrowZero");

        admin = msg.sender;
        token = _token;
        votingEscrow = _votingEscrow;
        timeTotal = block.timestamp / WEEK * WEEK;
    }

    // """
    // @notice Transfer ownership of GaugeController to `addr`
    // @param addr Address to have ownership transferred to
    // """
    function commitTransferOwnership(address addr) external {
        require(msg.sender == admin, "!admin");
        futureAdmin = addr;
        emit CommitOwnership(addr);
    }

    // """
    // @notice Apply pending ownership transfer
    // """
    function applyTransferOwnership() external {
        require(msg.sender == admin, "!admin");
        address _admin = futureAdmin;
        require(_admin != address(0), "adminZero");
        admin = _admin;
        emit ApplyOwnership(_admin);
    }

    // """
    // @notice Get gauge type for address
    // @param _addr Gauge address
    // @return Gauge type id
    // """
    function gaugeTypes(address _addr) external view returns(int128) {
        int128 gaugeType = _gaugeTypes[_addr];
        require(gaugeType != 0, "gaugeTypeZero");
        return gaugeType - 1;
    }

    // """
    // @notice Fill historic type weights week-over-week for missed checkins
    //         and return the type weight for the future week
    // @param gauge_type Gauge type id
    // @return Type weight
    // """
    function _getTypeWeight(int128 _gaugeType) internal returns(uint256) {
        require(_gaugeType >= 0, "cannotCastToUint256");
        uint256 gaugeType = uint256(_gaugeType);
        uint256 t = timeTypeWeight[gaugeType];
        if (t > 0) {
            uint256 w = pointsTypeWeight[_gaugeType][t];
            for (uint256 i = 0; i < 500; i++) {
                if (t > block.timestamp) {
                    break;
                }
                t += WEEK;
                pointsTypeWeight[_gaugeType][t] = w;
                if (t > block.timestamp) {
                    timeTypeWeight[gaugeType] = t;
                }
            }
            return w;
        } else {
            return 0;
        }
    }

    // """
    // @notice Fill sum of gauge weights for the same type week-over-week for
    //         missed checkins and return the sum for the future week
    // @param gauge_type Gauge type id
    // @return Sum of weights
    // """
    function _getSum(int128 _gaugeType) internal returns(uint256) {
        require(_gaugeType >= 0, "cannotCastToUint256");
        uint256 gaugeType = uint256(_gaugeType);
        uint256 t = timeSum[gaugeType];
        if (t > 0) {
            Point storage pt = pointsSum[_gaugeType][t];
            for (uint256 i = 0; i < 500; i++) {
                if (t > block.timestamp) {
                    break;
                }
                t += WEEK;
                uint256 dBias = pt.slope * WEEK;
                if (pt.bias > dBias) {
                    pt.bias -= dBias;
                    uint256 dSlope = _changesSum[_gaugeType][t];
                    pt.slope -= dSlope;
                } else {
                    pt.bias = 0;
                    pt.slope = 0;
                }
                pointsSum[_gaugeType][t] = pt;
                if (t > block.timestamp) {
                    timeSum[gaugeType] = t;
                }
            }
            return pt.bias;
        } else {
            return 0;
        }
    }

    // """
    // @notice Fill historic total weights week-over-week for missed checkins
    //         and return the total for the future week
    // @return Total weight
    // """
    function _getTotal() internal returns(uint256) {
        uint256 t = timeTotal;
        int128 _nGaugeTypes = nGaugeTypes;
        if (t > block.timestamp) {
            // # If we have already checkpointed - still need to change the value
            t -= WEEK;
        }
        uint256 pt = pointsTotal[t];

        for (int128 gaugeType = 0; gaugeType < 100; gaugeType++) {
            if (gaugeType == _nGaugeTypes) {
                break;
            }
            _getSum(gaugeType);
            _getTypeWeight(gaugeType);
        }

        for (uint256 i = 0; i < 500; i++) {
            if (t > block.timestamp) {
                break;
            }
            t += WEEK;
            pt = 0;

            // # Scales as n_types * n_unchecked_weeks (hopefully 1 at most)
            for (int128 gaugeType = 0; i < 100; gaugeType++) {
                if (gaugeType == _nGaugeTypes) {
                    break;
                }
                uint256 typeSum = pointsSum[gaugeType][t].bias;
                uint256 typeWeight = pointsTypeWeight[gaugeType][t];
                pt += typeSum * typeWeight;
            }
            pointsTotal[t] = pt;

            if (t > block.timestamp) {
                timeTotal = t;
            }
        }
        return pt;
    }

    // """
    // @notice Fill historic gauge weights week-over-week for missed checkins
    //         and return the total for the future week
    // @param gauge_addr Address of the gauge
    // @return Gauge weight
    // """
    function _getWeight(address gaugeAddr) internal returns(uint256) {
        uint256 t = timeWeight[gaugeAddr];
        if (t > 0) {
            Point storage pt = pointsWeight[gaugeAddr][t];
            for (uint256 i = 0; i < 500; i++) {
                if (t > block.timestamp) {
                    break;
                }
                t += WEEK;
                uint256 dBias = pt.slope * WEEK;
                if (pt.bias > dBias) {
                    pt.bias -= dBias;
                    uint256 dSlope = _changesWeight[gaugeAddr][t];
                    pt.slope -= dSlope;
                } else {
                    pt.bias = 0;
                    pt.slope = 0;
                }
                pointsWeight[gaugeAddr][t] = pt;
                if (t > block.timestamp) {
                    timeWeight[gaugeAddr] = t;
                }
            }
            return pt.bias;
        } else {
            return 0;
        }
    }

    // """
    // @notice Add gauge `addr` of type `gauge_type` with weight `weight`
    // @param addr Gauge address
    // @param gauge_type Gauge type
    // @param weight Gauge weight
    // """
    function addGauge(address addr, int128 _gaugeType, uint256 weight) external {
        require(_gaugeType >= 0, "cannotCastTypeToUint256");
        uint256 gaugeType = uint256(_gaugeType);
        require(msg.sender == admin, "!admin");
        require(_gaugeType < nGaugeTypes, "invalidGaugeType");
        require(_gaugeTypes[addr] == 0, "sameGaugeAdd");

        int128 n = nGauges;
        nGauges = n + 1;
        gauges[uint256(n)] = addr;

        _gaugeTypes[addr] = _gaugeType + 1;
        uint256 nextTime = (block.timestamp + WEEK) / WEEK * WEEK;

        if (weight > 0) {
            uint256 _typeWeight = _getTypeWeight(_gaugeType);
            uint256 _oldSum = _getSum(_gaugeType);
            uint256 _oldTotal = _getTotal();

            pointsSum[_gaugeType][nextTime].bias = weight + _oldSum;
            timeSum[gaugeType] = nextTime;
            pointsTotal[nextTime] = _oldTotal + _typeWeight * weight;
            timeTotal = nextTime;

            pointsWeight[addr][nextTime].bias = weight;
        }

        if (timeSum[gaugeType] == 0) {
            timeSum[gaugeType] = nextTime;
        }
        timeWeight[addr] = nextTime;

        emit NewGauge(addr, _gaugeType, weight);
    }

    // """
    // @notice Checkpoint to fill data common for all gauges
    // """
    function checkpoint() external {
        _getTotal();
    }

    // """
    // @notice Checkpoint to fill data for both a specific gauge and common for all gauges
    // @param addr Gauge address
    // """
    function checkpointGauge(address addr) external {
        _getWeight(addr);
        _getTotal();
    }

    // """
    // @notice Get Gauge relative weight (not more than 1.0) normalized to 1e18
    //         (e.g. 1.0 == 1e18). Inflation which will be received by it is
    //         inflation_rate * relative_weight / 1e18
    // @param addr Gauge address
    // @param time Relative weight at the specified timestamp in the past or present
    // @return Value of relative weight normalized to 1e18
    // """
    function _gaugeRelativeWeight(address addr, uint256 time) internal view returns(uint256) {
        uint256 t = time / WEEK * WEEK;
        uint256 _totalWeight = pointsTotal[t];

        if (_totalWeight > 0) {
            int128 gaugeType = _gaugeTypes[addr] - 1;
            uint256 _typeWeight = pointsTypeWeight[gaugeType][t];
            uint256 _gaugeWeight = pointsWeight[addr][t].bias;
            return MULTIPLIER * _typeWeight * _gaugeWeight / _totalWeight;
        }
        return 0;
    }

    // """
    // @notice Get Gauge relative weight (not more than 1.0) normalized to 1e18
    //         (e.g. 1.0 == 1e18). Inflation which will be received by it is
    //         inflation_rate * relative_weight / 1e18
    // @param addr Gauge address
    // @param time Relative weight at the specified timestamp in the past or present
    // @return Value of relative weight normalized to 1e18
    // """
    function gaugeRelativeWeight(address addr, uint256 time) public view returns(uint256) {
        return _gaugeRelativeWeight(addr, time);
    }

    function gaugeRelativeWeight(address addr) external view returns(uint256) {
        return gaugeRelativeWeight(addr, block.timestamp);
    }


    // """
    // @notice Get gauge weight normalized to 1e18 and also fill all the unfilled
    //         values for type and gauge records
    // @dev Any address can call, however nothing is recorded if the values are filled already
    // @param addr Gauge address
    // @param time Relative weight at the specified timestamp in the past or present
    // @return Value of relative weight normalized to 1e18
    // """
    function gaugeRelativeWeightWrite(address addr, uint256 time) public returns(uint256) {
        _getWeight(addr);
        _getTotal();
        uint256 weight = _gaugeRelativeWeight(addr, time);
        emit GaugeWeightWrite(addr, time, weight);
        return weight;
    }

    function gaugeRelativeWeightWrite(address addr) external returns(uint256) {
        return gaugeRelativeWeightWrite(addr, block.timestamp);
    }

    // """
    // @notice Change type weight
    // @param type_id Type id
    // @param weight New type weight
    // """
    function _changeTypeWeight(int128 typeId, uint256 weight) internal {
        uint256 oldWeight = _getTypeWeight(typeId);
        uint256 oldSum = _getSum(typeId);
        uint256 _totalWeight = _getTotal();
        uint256 nextTime = (block.timestamp + WEEK) / WEEK * WEEK;

        _totalWeight = _totalWeight + oldSum * weight - oldSum * oldWeight;
        pointsTotal[nextTime] = _totalWeight;
        pointsTypeWeight[typeId][nextTime] = weight;
        timeTotal = nextTime;
        timeTypeWeight[uint256(typeId)] = nextTime;

        emit NewTypeWeight(typeId, nextTime, weight, _totalWeight);
    }

    // """
    // @notice Add gauge type with name `_name` and weight `weight`
    // @param _name Name of gauge type
    // @param weight Weight of gauge type
    // """
    function addType(string calldata _name, uint256 weight) external {
        require(msg.sender == admin, "!admin");
        int128 typeId = nGaugeTypes;
        gaugeTypeNames[typeId] = _name;
        nGaugeTypes = typeId + 1;
        if (weight != 0) {
            _changeTypeWeight(typeId, weight);
            emit AddType(_name, typeId);
        }
    }

    // """
    // @notice Change gauge type `type_id` weight to `weight`
    // @param type_id Gauge type id
    // @param weight New Gauge weight
    // """
    function changeTypeWeight(int128 typeId, uint256 weight) external {
        require(msg.sender == admin, "!admin");
        _changeTypeWeight(typeId, weight);
    }

    function _changeGaugeWeight(address addr, uint256 weight) internal {
        // # Change gauge weight
        // # Only needed when testing in reality
        int128 gaugeType = _gaugeTypes[addr] - 1;
        uint256 oldGaugeWeight = _getWeight(addr);
        uint256 typeWeight = _getTypeWeight(gaugeType);

        uint256 oldSum = _getSum(gaugeType);
        uint256 _totalWeight = _getTotal();
        uint256 nextTime = (block.timestamp + WEEK) / WEEK * WEEK;

        pointsWeight[addr][nextTime].bias = weight;
        timeWeight[addr] = nextTime;

        uint256 newSum = oldSum + weight - oldGaugeWeight;
        pointsSum[gaugeType][nextTime].bias = newSum;
        timeSum[uint256(gaugeType)] = nextTime;

        _totalWeight = _totalWeight + newSum * typeWeight - oldSum * typeWeight;
        pointsTotal[nextTime] = _totalWeight;
        timeTotal = nextTime;

        emit NewGaugeWeight(addr, block.timestamp, weight, _totalWeight);
    }

    // """
    // @notice Change weight of gauge `addr` to `weight`
    // @param addr `GaugeController` contract address
    // @param weight New Gauge weight
    // """
    function changeGaugeWeight(address addr, uint256 weight) external {
        require(msg.sender == admin, "!admin");
        _changeGaugeWeight(addr, weight);
    }

    // """
    // @notice Allocate voting power for changing pool weights
    // @param _gauge_addr Gauge which `msg.sender` votes for
    // @param _user_weight Weight for a gauge in bps (units of 0.01%). Minimal is 0.01%. Ignored if 0
    // """
    function voteForGaugeWeight(address _gaugeAddr, uint256 _userWeight) external {

        uint256 slope = uint256(
          IVotingEscrow(votingEscrow).getLastUserSlope(msg.sender)
        );

        uint256 lockEnd = IVotingEscrow(votingEscrow).lockedEnd(msg.sender);

        // int128 _nGauges = nGauges;

        uint256 nextTime = (block.timestamp + WEEK) / WEEK * WEEK;

        require(lockEnd > nextTime, "lockExpiresTooSoon");

        require(_userWeight >= 0 && _userWeight <= 10000, "allVotingPowerIsUsed");

        require(
          block.timestamp >= lastUserVote[msg.sender][_gaugeAddr] + WEIGHT_VOTE_DELAY,
          "cannotVoteSoOften"
        );

        int128 gaugeType = _gaugeTypes[_gaugeAddr] - 1;
        require(gaugeType >= 0, "gaugeNotAdded");

        // # Prepare slopes and biases in memory
        VotedSlope memory oldSlope = voteUserSlopes[msg.sender][_gaugeAddr];

        uint256 oldDt = 0;

        if (oldSlope.end > nextTime) {
            oldDt = oldSlope.end - nextTime;
        }

        uint256 oldBias = oldSlope.slope * oldDt;

        VotedSlope memory newSlope = VotedSlope({
          slope: slope * _userWeight / 10000,
          end: lockEnd,
          power: _userWeight
        });

        // uint256 newDt = lockEnd - nextTime; // # dev: raises when expired
        uint256 newBias = newSlope.slope * (lockEnd - nextTime)/*newDt*/;

        {
          // # Check and update powers (weights) used
          uint256 powerUsed = voteUserPower[msg.sender];
          powerUsed = powerUsed + newSlope.power - oldSlope.power;
          voteUserPower[msg.sender] = powerUsed;
          require(powerUsed >= 0 && powerUsed <= 10000, "usedTooMuchPower");
        }

        // ## Remove old and schedule new slope changes
        // # Remove slope changes for old slopes
        // # Schedule recording of initial slope for next_time
        // uint256 oldWeightBias = _getWeight(_gaugeAddr);
        // uint256 oldWeightSlope = pointsWeight[_gaugeAddr][nextTime].slope;
        // uint256 oldSumBias = _getSum(gaugeType);
        // uint256 oldSumSlope = pointsSum[gaugeType][nextTime].slope;

        pointsWeight[_gaugeAddr][nextTime].bias = Math.max(
          _getWeight(_gaugeAddr)/*oldWeightBias*/ + newBias,
          oldBias
        ) - oldBias;

        pointsSum[gaugeType][nextTime].bias = Math.max(
          _getSum(gaugeType)/*oldSumBias*/ + newBias,
          oldBias
        ) - oldBias;

        if (oldSlope.end > nextTime) {

            pointsWeight[_gaugeAddr][nextTime].slope = Math.max(
              pointsWeight[_gaugeAddr][nextTime].slope/*oldWeightSlope*/ + newSlope.slope,
              oldSlope.slope
            ) - oldSlope.slope;

            pointsSum[gaugeType][nextTime].slope = Math.max(
              pointsSum[gaugeType][nextTime].slope/*oldSumSlope*/ + newSlope.slope,
              oldSlope.slope
            ) - oldSlope.slope;

        } else {
            pointsWeight[_gaugeAddr][nextTime].slope += newSlope.slope;
            pointsSum[gaugeType][nextTime].slope += newSlope.slope;
        }

        if (oldSlope.end > block.timestamp) {
            // # Cancel old slope changes if they still didn't happen
            _changesWeight[_gaugeAddr][oldSlope.end] -= oldSlope.slope;
            _changesSum[gaugeType][oldSlope.end] -= oldSlope.slope;
        }

        // # Add slope changes for new slopes
        _changesWeight[_gaugeAddr][newSlope.end] += newSlope.slope;
        _changesSum[gaugeType][newSlope.end] += newSlope.slope;

        _getTotal();

        voteUserSlopes[msg.sender][_gaugeAddr] = newSlope;

        // # Record last action time
        lastUserVote[msg.sender][_gaugeAddr] = block.timestamp;

        emit VoteForGauge(block.timestamp, msg.sender, _gaugeAddr, _userWeight);
    }

    // """
    // @notice Get current gauge weight
    // @param addr Gauge address
    // @return Gauge weight
    // """
    function getGaugeWeight(address addr) external view returns(uint256) {
        return pointsWeight[addr][timeWeight[addr]].bias;
    }

    // """
    // @notice Get current type weight
    // @param type_id Type id
    // @return Type weight
    // """
    function getTypeWeight(int128 typeId) external view returns(uint256) {
        require(typeId >= 0, "cannotCastTypeIdToUint256");
        return pointsTypeWeight[typeId][timeTypeWeight[uint256(typeId)]];
    }

    // """
    // @notice Get current total (type-weighted) weight
    // @return Total weight
    // """
    function getTotalWeight() external view returns(uint256) {
        return pointsTotal[timeTotal];
    }

    // """
    // @notice Get sum of gauge weights per type
    // @param type_id Type id
    // @return Sum of gauge weights
    // """
    function getWeightsSumPerType(int128 typeId) external view returns(uint256) {
        require(typeId >= 0, "cannotCastTypeIdToUint256");
        return pointsSum[typeId][timeSum[uint256(typeId)]].bias;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
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

