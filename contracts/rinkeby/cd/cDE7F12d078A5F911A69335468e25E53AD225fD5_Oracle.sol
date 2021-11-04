// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "./interfaces/IController.sol";
import "./TellorVars.sol";

/**
 @author Tellor Inc.
 @title Oracle
 @dev This is the Oracle contract which defines the functionality for the Tellor
 * oracle, where reporters submit values on chain and users can retrieve values.
*/
contract Oracle is TellorVars {
    // Storage
    uint256 public reportingLock = 12 hours; // amount of time before a reporter is able to submit a value again
    uint256 public timeBasedReward = 5e17; // time based reward for a reporter for successfully submitting a value
    uint256 public timeOfLastNewValue = block.timestamp; // time of the last new submitted value, originally set to the block timestamp
    uint256 public tipsInContract; // amount of tips within the contract
    mapping(bytes32 => Report) private reports; // mapping of query IDs to a report
    mapping(bytes32 => uint256) public tips; // mapping of query IDs to the amount of TRB they are tipped
    mapping(address => uint256) private reporterLastTimestamp; // mapping of reporter addresses to the timestamp of their last reported value
    mapping(address => uint256) private reportsSubmittedByAddress; // mapping of reporter addresses to the number of reports they've submitted
    mapping(address => uint256) private tipsByUser; // mapping of a user to the amount of tips they've paid

    // Structs
    struct Report {
        uint256[] timestamps; // array of all newValueTimestamps reported
        mapping(uint256 => uint256) timestampIndex; // mapping of timestamps to respective indices
        mapping(uint256 => uint256) timestampToBlockNum; // mapping of timestamp to block number
        mapping(uint256 => bytes) valueByTimestamp; // mapping of timestamps to values
        mapping(uint256 => address) reporterByTimestamp; // mapping of timestamps to reporters
    }

    // Events
    event ReportingLockChanged(uint256 _newReportingLock);
    event NewReport(
        bytes32 _queryId,
        uint256 _time,
        bytes _value,
        uint256 _reward,
        uint256 _nonce,
        bytes _queryData,
        address _reporter
    );
    event TimeBasedRewardsChanged(uint256 _newTimeBasedReward);
    event TipAdded(
        address indexed _user,
        bytes32 indexed _queryId,
        uint256 _tip,
        uint256 _totalTip,
        bytes _queryData
    );

    // Functions
    constructor(address _master) {
      TELLOR_ADDRESS = _master;
    }

    /**
     * @dev Changes reporting lock for reporters.
     * Note: this function is only callable by the Governance contract.
     * @param _newReportingLock is the new reporting lock.
     */
    function changeReportingLock(uint256 _newReportingLock) external {
        require(
            msg.sender ==
                IController(TELLOR_ADDRESS).addresses(_GOVERNANCE_CONTRACT),
            "Only governance contract can change reporting lock."
        );
        require(_newReportingLock < 8640000, "Invalid _newReportingLock value");
        reportingLock = _newReportingLock;
        emit ReportingLockChanged(_newReportingLock);
    }

    /**
     * @dev Changes time based reward for reporters.
     * Note: this function is only callable by the Governance contract.
     * @param _newTimeBasedReward is the new time based reward.
     */
    function changeTimeBasedReward(uint256 _newTimeBasedReward) external {
        require(
            msg.sender ==
                IController(TELLOR_ADDRESS).addresses(_GOVERNANCE_CONTRACT),
            "Only governance contract can change time based reward."
        );
        timeBasedReward = _newTimeBasedReward;
        emit TimeBasedRewardsChanged(_newTimeBasedReward);
    }

    /**
     * @dev Removes a value from the oracle.
     * Note: this function is only callable by the Governance contract.
     * @param _queryId is ID of the specific data feed
     * @param _timestamp is the timestamp of the data value to remove
     */
    function removeValue(bytes32 _queryId, uint256 _timestamp) external {
        require(
            msg.sender ==
                IController(TELLOR_ADDRESS).addresses(_GOVERNANCE_CONTRACT) ||
                msg.sender ==
                IController(TELLOR_ADDRESS).addresses(_ORACLE_CONTRACT),
            "caller must be the governance contract or the oracle contract"
        );
        Report storage rep = reports[_queryId];
        uint256 _index = rep.timestampIndex[_timestamp];
        // Shift all timestamps back to reflect deletion of value
        for (uint256 i = _index; i < rep.timestamps.length - 1; i++) {
            rep.timestamps[i] = rep.timestamps[i + 1];
            rep.timestampIndex[rep.timestamps[i]] -= 1;
        }
        // Delete and reset timestamp and value
        delete rep.timestamps[rep.timestamps.length - 1];
        rep.timestamps.pop();
        rep.valueByTimestamp[_timestamp] = "";
        rep.timestampIndex[_timestamp] = 0;
    }

    /**
     * @dev Allows a reporter to submit a value to the oracle
     * @param _queryId is ID of the specific data feed. Equals keccak256(_queryData) for non-legacy IDs
     * @param _value is the value the user submits to the oracle
     * @param _nonce is the current value count for the query id
     * @param _queryData is the data used to fulfill the data query
     */
    function submitValue(
        bytes32 _queryId,
        bytes calldata _value,
        uint256 _nonce,
        bytes memory _queryData
    ) external {
        Report storage rep = reports[_queryId];
        require(
            _nonce == rep.timestamps.length,
            "nonce must match timestamp index"
        );
        // Require reporter to abide by given reporting lock
        require(
            block.timestamp - reporterLastTimestamp[msg.sender] > reportingLock,
            "still in reporter time lock, please wait!"
        );
        require(
            address(this) ==
                IController(TELLOR_ADDRESS).addresses(_ORACLE_CONTRACT),
            "can only submit to current oracle contract"
        );
        require(
            _queryId == keccak256(_queryData) || uint256(_queryId) <= 100,
            "id must be hash of bytes data"
        );
        reporterLastTimestamp[msg.sender] = block.timestamp;
        IController _tellor = IController(TELLOR_ADDRESS);
        // Checks that reporter is not already staking TRB
        (uint256 _status, ) = _tellor.getStakerInfo(msg.sender);
        require(_status == 1, "Reporter status is not staker");
        // Check is in case the stake amount increases
        require(
            _tellor.balanceOf(msg.sender) >= _tellor.uints(_STAKE_AMOUNT),
            "balance must be greater than stake amount"
        );
        // Checks for no double reporting of timestamps
        require(
            rep.reporterByTimestamp[block.timestamp] == address(0),
            "timestamp already reported for"
        );
        // Update number of timestamps, value for given timestamp, and reporter for timestamp
        rep.timestampIndex[block.timestamp] = rep.timestamps.length;
        rep.timestamps.push(block.timestamp);
        rep.timestampToBlockNum[block.timestamp] = block.number;
        rep.valueByTimestamp[block.timestamp] = _value;
        rep.reporterByTimestamp[block.timestamp] = msg.sender;
        // Send tips + timeBasedReward to reporter of value, and reset tips for ID
        (uint256 _tip, uint256 _reward) = getCurrentReward(_queryId);
        tipsInContract -= _tip;
        if (_reward + _tip > 0) {
            _tellor.transfer(msg.sender, _reward + _tip);
        }
        tips[_queryId] = 0;
        // Update last oracle value and number of values submitted by a reporter
        timeOfLastNewValue = block.timestamp;
        reportsSubmittedByAddress[msg.sender]++;
        emit NewReport(
            _queryId,
            block.timestamp,
            _value,
            _tip + _reward,
            _nonce,
            _queryData,
            msg.sender
        );
    }

    /**
     * @dev Adds tips to incentivize reporters to submit values for specific data IDs.
     * @param _queryId is ID of the specific data feed
     * @param _tip is the amount to tip the given data ID
     * @param _queryData is required for IDs greater than 100, informs reporters how to fulfill request. See github.com/tellor-io/dataSpecs
     */
    function tipQuery(
        bytes32 _queryId,
        uint256 _tip,
        bytes memory _queryData
    ) external {
        // Require tip to be greater than 1 and be paid
        require(_tip > 1, "Tip should be greater than 1");
        require(
            IController(TELLOR_ADDRESS).approveAndTransferFrom(
                msg.sender,
                address(this),
                _tip
            ),
            "tip must be paid"
        );
        require(
            _queryId == keccak256(_queryData) ||
                uint256(_queryId) <= 100 ||
                msg.sender ==
                IController(TELLOR_ADDRESS).addresses(_GOVERNANCE_CONTRACT),
            "id must be hash of bytes data"
        );
        // Burn half the tip
        _tip = _tip / 2;
        IController(TELLOR_ADDRESS).burn(_tip);
        // Update total tip amount for user, data ID, and in total contract
        tips[_queryId] += _tip;
        tipsByUser[msg.sender] += _tip;
        tipsInContract += _tip;
        emit TipAdded(msg.sender, _queryId, _tip, tips[_queryId], _queryData);
    }

    //Getters
    /**
     * @dev Returns the block number at a given timestamp
     * @param _queryId is ID of the specific data feed
     * @param _timestamp is the timestamp to find the corresponding block number for
     * @return uint256 block number of the timestamp for the given data ID
     */
    function getBlockNumberByTimestamp(bytes32 _queryId, uint256 _timestamp)
        external
        view
        returns (uint256)
    {
        return reports[_queryId].timestampToBlockNum[_timestamp];
    }

    /**
     * @dev Calculates the current reward for a reporter given tips
     * and time based reward
     * @param _queryId is ID of the specific data feed
     * @return uint256 tips on given queryId
     * @return uint256 time based reward
     */
    function getCurrentReward(bytes32 _queryId)
        public
        view
        returns (uint256, uint256)
    {
        IController _tellor = IController(TELLOR_ADDRESS);
        uint256 _timeDiff = block.timestamp - timeOfLastNewValue;
        uint256 _reward = (_timeDiff * timeBasedReward) / 300; //.5 TRB per 5 minutes (should we make this upgradeable)
        if (_tellor.balanceOf(address(this)) < _reward + tipsInContract) {
            _reward = _tellor.balanceOf(address(this)) - tipsInContract;
        }
        return (tips[_queryId], _reward);
    }

    /**
     * @dev Returns the current value of a data feed given a specific ID
     * @param _queryId is the ID of the specific data feed
     * @return bytes memory of the current value of data
     */
    function getCurrentValue(bytes32 _queryId)
        external
        view
        returns (bytes memory)
    {
        return
            reports[_queryId].valueByTimestamp[
                reports[_queryId].timestamps[
                    reports[_queryId].timestamps.length - 1
                ]
            ];
    }

    /**
     * @dev Returns the reporting lock time, the amount of time a reporter must wait to submit again
     * @return uint256 reporting lock time
     */
    function getReportingLock() external view returns (uint256) {
        return reportingLock;
    }

    /**
     * @dev Returns the address of the reporter who submitted a value for a data ID at a specific time
     * @param _queryId is ID of the specific data feed
     * @param _timestamp is the timestamp to find a corresponding reporter for
     * @return address of the reporter who reported the value for the data ID at the given timestamp
     */
    function getReporterByTimestamp(bytes32 _queryId, uint256 _timestamp)
        external
        view
        returns (address)
    {
        return reports[_queryId].reporterByTimestamp[_timestamp];
    }

    /**
     * @dev Returns the timestamp of the reporter's last submission
     * @param _reporter is address of the reporter
     * @return uint256 timestamp of the reporter's last submission
     */
    function getReporterLastTimestamp(address _reporter)
        external
        view
        returns (uint256)
    {
        return reporterLastTimestamp[_reporter];
    }

    /**
     * @dev Returns the number of values submitted by a specific reporter address
     * @param _reporter is the address of a reporter
     * @return uint256 of the number of values submitted by the given reporter
     */
    function getReportsSubmittedByAddress(address _reporter)
        external
        view
        returns (uint256)
    {
        return reportsSubmittedByAddress[_reporter];
    }

    /**
     * @dev Returns the timestamp of a reported value given a data ID and timestamp index
     * @param _queryId is ID of the specific data feed
     * @param _index is the index of the timestamp
     * @return uint256 timestamp of the given queryId and index
     */
    function getReportTimestampByIndex(bytes32 _queryId, uint256 _index)
        external
        view
        returns (uint256)
    {
        return reports[_queryId].timestamps[_index];
    }

    /**
     * @dev Returns the time based reward for submitting a value
     * @return uint256 of time based reward
     */
    function getTimeBasedReward() external view returns (uint256) {
        return timeBasedReward;
    }

    /**
     * @dev Returns the number of timestamps/reports for a specific data ID
     * @param _queryId is ID of the specific data feed
     * @return uint256 of the number of timestamps/reports for the given data ID
     */
    function getTimestampCountById(bytes32 _queryId)
        external
        view
        returns (uint256)
    {
        return reports[_queryId].timestamps.length;
    }

    /**
     * @dev Returns the timestamp for the last value of any ID from the oracle
     * @return uint256 of timestamp of the last oracle value
     */
    function getTimeOfLastNewValue() external view returns (uint256) {
        return timeOfLastNewValue;
    }

    /**
     * @dev Returns the index of a reporter timestamp in the timestamp array for a specific data ID
     * @param _queryId is ID of the specific data feed
     * @param _timestamp is the timestamp to find in the timestamps array
     * @return uint256 of the index of the reporter timestamp in the array for specific ID
     */
    function getTimestampIndexByTimestamp(bytes32 _queryId, uint256 _timestamp)
        external
        view
        returns (uint256)
    {
        return reports[_queryId].timestampIndex[_timestamp];
    }

    /**
     * @dev Returns the amount of tips available for a specific query ID
     * @param _queryId is ID of the specific data feed
     * @return uint256 of the amount of tips added for the specific ID
     */
    function getTipsById(bytes32 _queryId) external view returns (uint256) {
        return tips[_queryId];
    }

    /**
     * @dev Returns the amount of tips made by a user
     * @param _user is the address of the user
     * @return uint256 of the amount of tips made by the user
     */
    function getTipsByUser(address _user) external view returns (uint256) {
        return tipsByUser[_user];
    }

    /**
     * @dev Returns the value of a data feed given a specific ID and timestamp
     * @param _queryId is the ID of the specific data feed
     * @param _timestamp is the timestamp to look for data
     * @return bytes memory of the value of data at the associated timestamp
     */
    function getValueByTimestamp(bytes32 _queryId, uint256 _timestamp)
        external
        view
        returns (bytes memory)
    {
        return reports[_queryId].valueByTimestamp[_timestamp];
    }

    /**
     * @dev Used during the upgrade process to verify valid Tellor Contracts
     */
    function verify() external pure returns (uint256) {
        return 9999;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

interface IController{
    function addresses(bytes32) external returns(address);
    function uints(bytes32) external returns(uint256);
    function burn(uint256 _amount) external;
    function changeDeity(address _newDeity) external;
    function changeOwner(address _newOwner) external;
    function changeTellorContract(address _tContract) external;
    function changeControllerContract(address _newController) external;
    function changeGovernanceContract(address _newGovernance) external;
    function changeOracleContract(address _newOracle) external;
    function changeTreasuryContract(address _newTreasury) external;
    function changeUint(bytes32 _target, uint256 _amount) external;
    function migrate() external;
    function mint(address _reciever, uint256 _amount) external;
    function init() external;
    function getDisputeIdByDisputeHash(bytes32 _hash) external view returns (uint256);
    function getLastNewValueById(uint256 _requestId) external view returns (uint256, bool);
    function retrieveData(uint256 _requestId, uint256 _timestamp) external view returns (uint256);
    function getNewValueCountbyRequestId(uint256 _requestId) external view returns (uint256);
    function getAddressVars(bytes32 _data) external view returns (address);
    function getUintVar(bytes32 _data) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function allowance(address _user, address _spender) external view  returns (uint256);
    function allowedToTrade(address _user, uint256 _amount) external view returns (bool);
    function approve(address _spender, uint256 _amount) external returns (bool);
    function approveAndTransferFrom(address _from, address _to, uint256 _amount) external returns(bool);
    function balanceOf(address _user) external view returns (uint256);
    function balanceOfAt(address _user, uint256 _blockNumber)external view returns (uint256);
    function transfer(address _to, uint256 _amount)external returns (bool success);
    function transferFrom(address _from,address _to,uint256 _amount) external returns (bool success) ;
    function depositStake() external;
    function requestStakingWithdraw() external;
    function withdrawStake() external;
    function changeStakingStatus(address _reporter, uint _status) external;
    function slashReporter(address _reporter, address _disputer) external;
    function getStakerInfo(address _staker) external view returns (uint256, uint256);
    function getTimestampbyRequestIDandIndex(uint256 _requestID, uint256 _index) external view returns (uint256);
    function getNewCurrentVariables()external view returns (bytes32 _c,uint256[5] memory _r,uint256 _d,uint256 _t);
    //in order to call fallback function
    function beginDispute(uint256 _requestId, uint256 _timestamp,uint256 _minerIndex) external;
    function unlockDisputeFee(uint256 _disputeId) external;
    function vote(uint256 _disputeId, bool _supportsDispute) external;
    function tallyVotes(uint256 _disputeId) external;
    //test functions
    function tipQuery(uint,uint,bytes memory) external;
    function getNewVariablesOnDeck() external view returns (uint256[5] memory idsOnDeck, uint256[5] memory tipsOnDeck);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "./tellor3/TellorVariables.sol";

/**
 @author Tellor Inc.
 @title TellorVariables
 @dev Helper contract to store hashes of variables.
 * For each of the bytes32 constants, the values are equal to
 * keccak256([VARIABLE NAME])
*/
contract TellorVars is TellorVariables {
    // Storage
    address TELLOR_ADDRESS;
        // 0x88dF592F8eb5D7Bd38bFeF7dEb0fBc02cf3778a0; // Address of main Tellor Contract
    // Hashes for each pertinent contract
    bytes32 constant _GOVERNANCE_CONTRACT =
        0xefa19baa864049f50491093580c5433e97e8d5e41f8db1a61108b4fa44cacd93;
    bytes32 constant _ORACLE_CONTRACT =
        0xfa522e460446113e8fd353d7fa015625a68bc0369712213a42e006346440891e;
    bytes32 constant _TREASURY_CONTRACT =
        0x1436a1a60dca0ebb2be98547e57992a0fa082eb479e7576303cbd384e934f1fa;
    bytes32 constant _SWITCH_TIME =
        0x6c0e91a96227393eb6e42b88e9a99f7c5ebd588098b549c949baf27ac9509d8f;
    bytes32 constant _MINIMUM_DISPUTE_FEE =
        0x7335d16d7e7f6cb9f532376441907fe76aa2ea267285c82892601f4755ed15f0;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.4;

/**
 @author Tellor Inc.
 @title TellorVariables
 @dev Helper contract to store hashes of variables
*/
contract TellorVariables {
    bytes32 constant _BLOCK_NUMBER =
        0x4b4cefd5ced7569ef0d091282b4bca9c52a034c56471a6061afd1bf307a2de7c; //keccak256("_BLOCK_NUMBER");
    bytes32 constant _CURRENT_CHALLENGE =
        0xd54702836c9d21d0727ffacc3e39f57c92b5ae0f50177e593bfb5ec66e3de280; //keccak256("_CURRENT_CHALLENGE");
    bytes32 constant _CURRENT_REQUESTID =
        0xf5126bb0ac211fbeeac2c0e89d4c02ac8cadb2da1cfb27b53c6c1f4587b48020; //keccak256("_CURRENT_REQUESTID");
    bytes32 constant _CURRENT_REWARD =
        0xd415862fd27fb74541e0f6f725b0c0d5b5fa1f22367d9b78ec6f61d97d05d5f8; //keccak256("_CURRENT_REWARD");
    bytes32 constant _CURRENT_TOTAL_TIPS =
        0x09659d32f99e50ac728058418d38174fe83a137c455ff1847e6fb8e15f78f77a; //keccak256("_CURRENT_TOTAL_TIPS");
    bytes32 constant _DEITY =
        0x5fc094d10c65bc33cc842217b2eccca0191ff24148319da094e540a559898961; //keccak256("_DEITY");
    bytes32 constant _DIFFICULTY =
        0xf758978fc1647996a3d9992f611883adc442931dc49488312360acc90601759b; //keccak256("_DIFFICULTY");
    bytes32 constant _DISPUTE_COUNT =
        0x310199159a20c50879ffb440b45802138b5b162ec9426720e9dd3ee8bbcdb9d7; //keccak256("_DISPUTE_COUNT");
    bytes32 constant _DISPUTE_FEE =
        0x675d2171f68d6f5545d54fb9b1fb61a0e6897e6188ca1cd664e7c9530d91ecfc; //keccak256("_DISPUTE_FEE");
    bytes32 constant _DISPUTE_ROUNDS =
        0x6ab2b18aafe78fd59c6a4092015bddd9fcacb8170f72b299074f74d76a91a923; //keccak256("_DISPUTE_ROUNDS");
    bytes32 constant _EXTENSION =
        0x2b2a1c876f73e67ebc4f1b08d10d54d62d62216382e0f4fd16c29155818207a4; //keccak256("_EXTENSION");
    bytes32 constant _FEE =
        0x1da95f11543c9b03927178e07951795dfc95c7501a9d1cf00e13414ca33bc409; //keccak256("_FEE");
    bytes32 constant _FORK_EXECUTED =
        0xda571dfc0b95cdc4a3835f5982cfdf36f73258bee7cb8eb797b4af8b17329875; //keccak256("_FORK_EXECUTED");
    bytes32 constant _LOCK =
        0xd051321aa26ce60d202f153d0c0e67687e975532ab88ce92d84f18e39895d907;
    bytes32 constant _MIGRATOR =
        0xc6b005d45c4c789dfe9e2895b51df4336782c5ff6bd59a5c5c9513955aa06307; //keccak256("_MIGRATOR");
    bytes32 constant _MIN_EXECUTION_DATE =
        0x46f7d53798d31923f6952572c6a19ad2d1a8238d26649c2f3493a6d69e425d28; //keccak256("_MIN_EXECUTION_DATE");
    bytes32 constant _MINER_SLOT =
        0x6de96ee4d33a0617f40a846309c8759048857f51b9d59a12d3c3786d4778883d; //keccak256("_MINER_SLOT");
    bytes32 constant _NUM_OF_VOTES =
        0x1da378694063870452ce03b189f48e04c1aa026348e74e6c86e10738514ad2c4; //keccak256("_NUM_OF_VOTES");
    bytes32 constant _OLD_TELLOR =
        0x56e0987db9eaec01ed9e0af003a0fd5c062371f9d23722eb4a3ebc74f16ea371; //keccak256("_OLD_TELLOR");
    bytes32 constant _ORIGINAL_ID =
        0xed92b4c1e0a9e559a31171d487ecbec963526662038ecfa3a71160bd62fb8733; //keccak256("_ORIGINAL_ID");
    bytes32 constant _OWNER =
        0x7a39905194de50bde334d18b76bbb36dddd11641d4d50b470cb837cf3bae5def; //keccak256("_OWNER");
    bytes32 constant _PAID =
        0x29169706298d2b6df50a532e958b56426de1465348b93650fca42d456eaec5fc; //keccak256("_PAID");
    bytes32 constant _PENDING_OWNER =
        0x7ec081f029b8ac7e2321f6ae8c6a6a517fda8fcbf63cabd63dfffaeaafa56cc0; //keccak256("_PENDING_OWNER");
    bytes32 constant _REQUEST_COUNT =
        0x3f8b5616fa9e7f2ce4a868fde15c58b92e77bc1acd6769bf1567629a3dc4c865; //keccak256("_REQUEST_COUNT");
    bytes32 constant _REQUEST_ID =
        0x9f47a2659c3d32b749ae717d975e7962959890862423c4318cf86e4ec220291f; //keccak256("_REQUEST_ID");
    bytes32 constant _REQUEST_Q_POSITION =
        0xf68d680ab3160f1aa5d9c3a1383c49e3e60bf3c0c031245cbb036f5ce99afaa1; //keccak256("_REQUEST_Q_POSITION");
    bytes32 constant _SLOT_PROGRESS =
        0xdfbec46864bc123768f0d134913175d9577a55bb71b9b2595fda21e21f36b082; //keccak256("_SLOT_PROGRESS");
    bytes32 constant _STAKE_AMOUNT =
        0x5d9fadfc729fd027e395e5157ef1b53ef9fa4a8f053043c5f159307543e7cc97; //keccak256("_STAKE_AMOUNT");
    bytes32 constant _STAKE_COUNT =
        0x10c168823622203e4057b65015ff4d95b4c650b308918e8c92dc32ab5a0a034b; //keccak256("_STAKE_COUNT");
    bytes32 constant _T_BLOCK =
        0xf3b93531fa65b3a18680d9ea49df06d96fbd883c4889dc7db866f8b131602dfb; //keccak256("_T_BLOCK");
    bytes32 constant _TALLY_DATE =
        0xf9e1ae10923bfc79f52e309baf8c7699edb821f91ef5b5bd07be29545917b3a6; //keccak256("_TALLY_DATE");
    bytes32 constant _TARGET_MINERS =
        0x0b8561044b4253c8df1d9ad9f9ce2e0f78e4bd42b2ed8dd2e909e85f750f3bc1; //keccak256("_TARGET_MINERS");
    bytes32 constant _TELLOR_CONTRACT =
        0x0f1293c916694ac6af4daa2f866f0448d0c2ce8847074a7896d397c961914a08; //keccak256("_TELLOR_CONTRACT");
    bytes32 constant _TELLOR_GETTERS =
        0xabd9bea65759494fe86471c8386762f989e1f2e778949e94efa4a9d1c4b3545a; //keccak256("_TELLOR_GETTERS");
    bytes32 constant _TIME_OF_LAST_NEW_VALUE =
        0x2c8b528fbaf48aaf13162a5a0519a7ad5a612da8ff8783465c17e076660a59f1; //keccak256("_TIME_OF_LAST_NEW_VALUE");
    bytes32 constant _TIME_TARGET =
        0xd4f87b8d0f3d3b7e665df74631f6100b2695daa0e30e40eeac02172e15a999e1; //keccak256("_TIME_TARGET");
    bytes32 constant _TIMESTAMP =
        0x2f9328a9c75282bec25bb04befad06926366736e0030c985108445fa728335e5; //keccak256("_TIMESTAMP");
    bytes32 constant _TOTAL_SUPPLY =
        0xe6148e7230ca038d456350e69a91b66968b222bfac9ebfbea6ff0a1fb7380160; //keccak256("_TOTAL_SUPPLY");
    bytes32 constant _TOTAL_TIP =
        0x1590276b7f31dd8e2a06f9a92867333eeb3eddbc91e73b9833e3e55d8e34f77d; //keccak256("_TOTAL_TIP");
    bytes32 constant _VALUE =
        0x9147231ab14efb72c38117f68521ddef8de64f092c18c69dbfb602ffc4de7f47; //keccak256("_VALUE");
    bytes32 constant _EIP_SLOT =
        0x7050c9e0f4ca769c69bd3a8ef740bc37934f8e2c036e5a723fd8ee048ed3f8c3;
}