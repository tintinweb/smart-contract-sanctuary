// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "./interfaces/IERC20.sol";

/**
 @author Tellor Inc.
 @title TellorFlex
 @dev This is a streamlined Tellor oracle system which handles staking, reporting,
 * slashing, and user data getters in one contract. This contract is controlled
 * by a single address known as 'governance', which could be an externally owned
 * account or a contract, allowing for a flexible, modular design.
*/
contract TellorFlex {
    IERC20 public token;
    address public governance;
    uint256 public stakeAmount; //amount required to be a staker
    uint256 public totalStakeAmount; //total amount of tokens locked in contract (via stake)
    uint256 public reportingLock; // base amount of time before a reporter is able to submit a value again
    uint256 public timeOfLastNewValue = block.timestamp; // time of the last new submitted value, originally set to the block timestamp
    mapping(bytes32 => Report) private reports; // mapping of query IDs to a report
    mapping(address => StakeInfo) stakerDetails; //mapping from a persons address to their staking info

    // Structs
    struct Report {
        uint256[] timestamps; // array of all newValueTimestamps reported
        mapping(uint256 => uint256) timestampIndex; // mapping of timestamps to respective indices
        mapping(uint256 => uint256) timestampToBlockNum; // mapping of timestamp to block number
        mapping(uint256 => bytes) valueByTimestamp; // mapping of timestamps to values
        mapping(uint256 => address) reporterByTimestamp; // mapping of timestamps to reporters
    }

    struct StakeInfo {
        uint256 startDate; //stake start date
        uint256 stakedBalance; // staked balance
        uint256 lockedBalance; // amount locked for withdrawal
        uint256 reporterLastTimestamp; // timestamp of reporter's last reported value
        uint256 reportsSubmitted; // total number of reports submitted by reporter
        mapping(bytes32 => uint256) reportsSubmittedByQueryId;
    }

    // Events
    event NewGovernanceAddress(address _newGovernanceAddress);
    event NewReport(
        bytes32 _queryId,
        uint256 _time,
        bytes _value,
        uint256 _nonce,
        bytes _queryData,
        address _reporter
    );
    event NewReportingLock(uint256 _newReportingLock);
    event NewStakeAmount(uint256 _newStakeAmount);
    event NewStaker(address _staker, uint256 _amount);
    event ReporterSlashed(
        address _reporter,
        address _recipient,
        uint256 _slashAmount
    );
    event StakeWithdrawRequested(address _staker, uint256 _amount);
    event StakeWithdrawn(address _staker);
    event ValueRemoved(bytes32 _queryId, uint256 _timestamp);

    /**
     * @dev Initializes system parameters
     * @param _token address of token used for staking
     * @param _governance address which controls system
     * @param _stakeAmount amount of token needed to report oracle values
     * @param _reportingLock base amount of time (seconds) before reporter is able to report again
     */
    constructor(
        address _token,
        address _governance,
        uint256 _stakeAmount,
        uint256 _reportingLock
    ) {
        require(_token != address(0), "must set token address");
        require(_governance != address(0), "must set governance address");
        token = IERC20(_token);
        governance = _governance;
        stakeAmount = _stakeAmount;
        reportingLock = _reportingLock;
    }

    /**
     * @dev Changes governance address
     * @param _newGovernanceAddress new governance address
     */
    function changeGovernanceAddress(address _newGovernanceAddress) external {
        require(msg.sender == governance, "caller must be governance address");
        require(
            _newGovernanceAddress != address(0),
            "must set governance address"
        );
        governance = _newGovernanceAddress;
        emit NewGovernanceAddress(_newGovernanceAddress);
    }

    /**
     * @dev Changes base amount of time (seconds) before reporter is allowed to report again
     * @param _newReportingLock new reporter lock time in seconds
     */
    function changeReportingLock(uint256 _newReportingLock) external {
        require(msg.sender == governance, "caller must be governance address");
        require(
            _newReportingLock > 0,
            "reporting lock must be greater than zero"
        );
        reportingLock = _newReportingLock;
        emit NewReportingLock(_newReportingLock);
    }

    /**
     * @dev Changes amount of token stake required to report values
     * @param _newStakeAmount new reporter stake amount
     */
    function changeStakeAmount(uint256 _newStakeAmount) external {
        require(msg.sender == governance, "caller must be governance address");
        require(_newStakeAmount > 0, "stake amount must be greater than zero");
        stakeAmount = _newStakeAmount;
        emit NewStakeAmount(_newStakeAmount);
    }

    /**
     * @dev Allows a reporter to submit stake
     * @param _amount amount of tokens to stake
     */
    function depositStake(uint256 _amount) external {
        StakeInfo storage _staker = stakerDetails[msg.sender];
        if (_staker.lockedBalance > 0) {
            if (_staker.lockedBalance >= _amount) {
                _staker.lockedBalance -= _amount;
            } else {
                require(
                    token.transferFrom(
                        msg.sender,
                        address(this),
                        _amount - _staker.lockedBalance
                    )
                );
                _staker.lockedBalance = 0;
            }
        } else {
            require(token.transferFrom(msg.sender, address(this), _amount));
        }
        _staker.startDate = block.timestamp; // This resets their stake start date to now
        _staker.stakedBalance += _amount;
        totalStakeAmount += _amount;
        emit NewStaker(msg.sender, _amount);
    }

    /**
     * @dev Removes a value from the oracle.
     * Note: this function is only callable by the Governance contract.
     * @param _queryId is ID of the specific data feed
     * @param _timestamp is the timestamp of the data value to remove
     */
    function removeValue(bytes32 _queryId, uint256 _timestamp) external {
        require(msg.sender == governance, "caller must be governance address");
        Report storage rep = reports[_queryId];
        uint256 _index = rep.timestampIndex[_timestamp];
        require(_timestamp == rep.timestamps[_index], "invalid timestamp");
        // Shift all timestamps back to reflect deletion of value
        for (uint256 _i = _index; _i < rep.timestamps.length - 1; _i++) {
            rep.timestamps[_i] = rep.timestamps[_i + 1];
            rep.timestampIndex[rep.timestamps[_i]] -= 1;
        }
        // Delete and reset timestamp and value
        delete rep.timestamps[rep.timestamps.length - 1];
        rep.timestamps.pop();
        rep.valueByTimestamp[_timestamp] = "";
        rep.timestampIndex[_timestamp] = 0;
        emit ValueRemoved(_queryId, _timestamp);
    }

    /**
     * @dev Allows a reporter to request to withdraw their stake
     * @param _amount amount of staked tokens requesting to withdraw
     */
    function requestStakingWithdraw(uint256 _amount) external {
        StakeInfo storage _staker = stakerDetails[msg.sender];
        require(
            _staker.stakedBalance >= _amount,
            "insufficient staked balance"
        );
        _staker.startDate = block.timestamp;
        _staker.lockedBalance += _amount;
        _staker.stakedBalance -= _amount;
        totalStakeAmount -= _amount;
        emit StakeWithdrawRequested(msg.sender, _amount);
    }

    /**
     * @dev Slashes a reporter and transfers their stake amount to the given recipient
     * Note: this function is only callable by the governance address.
     * @param _reporter is the address of the reporter being slashed
     * @param _recipient is the address receiving the reporter's stake
     * @return uint256 amount of token slashed and sent to recipient address
     */
    function slashReporter(address _reporter, address _recipient)
        external
        returns (uint256)
    {
        require(msg.sender == governance, "only governance can slash reporter");
        StakeInfo storage _staker = stakerDetails[_reporter];
        require(
            _staker.stakedBalance + _staker.lockedBalance > 0,
            "zero staker balance"
        );
        uint256 _slashAmount;
        if (_staker.lockedBalance >= stakeAmount) {
            _slashAmount = stakeAmount;
            _staker.lockedBalance -= stakeAmount;
        } else if (
            _staker.lockedBalance + _staker.stakedBalance >= stakeAmount
        ) {
            _slashAmount = stakeAmount;
            _staker.stakedBalance -= stakeAmount - _staker.lockedBalance;
            totalStakeAmount -= stakeAmount - _staker.lockedBalance;
            _staker.lockedBalance = 0;
        } else {
            _slashAmount = _staker.stakedBalance + _staker.lockedBalance;
            totalStakeAmount -= _staker.stakedBalance;
            _staker.stakedBalance = 0;
            _staker.lockedBalance = 0;
        }
        token.transfer(_recipient, _slashAmount);
        emit ReporterSlashed(_reporter, _recipient, _slashAmount);
        return (_slashAmount);
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
            _nonce == rep.timestamps.length || _nonce == 0,
            "nonce must match timestamp index"
        );
        StakeInfo storage _staker = stakerDetails[msg.sender];
        require(
            _staker.stakedBalance >= stakeAmount,
            "balance must be greater than stake amount"
        );
        // Require reporter to abide by given reporting lock
        require(
            (block.timestamp - _staker.reporterLastTimestamp) * 1000 >
                (reportingLock * 1000) / (_staker.stakedBalance / stakeAmount),
            "still in reporter time lock, please wait!"
        );
        require(
            _queryId == keccak256(_queryData) || uint256(_queryId) <= 100,
            "id must be hash of bytes data"
        );
        _staker.reporterLastTimestamp = block.timestamp;
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
        // Update last oracle value and number of values submitted by a reporter
        timeOfLastNewValue = block.timestamp;
        _staker.reportsSubmitted++;
        _staker.reportsSubmittedByQueryId[_queryId]++;
        emit NewReport(
            _queryId,
            block.timestamp,
            _value,
            _nonce,
            _queryData,
            msg.sender
        );
    }

    /**
     * @dev Withdraws a reporter's stake
     */
    function withdrawStake() external {
        StakeInfo storage _s = stakerDetails[msg.sender];
        // Ensure reporter is locked and that enough time has passed
        require(block.timestamp - _s.startDate >= 7 days, "7 days didn't pass");
        require(_s.lockedBalance > 0, "reporter not locked for withdrawal");
        token.transfer(msg.sender, _s.lockedBalance);
        _s.lockedBalance = 0;
        emit StakeWithdrawn(msg.sender);
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
     * @dev Returns governance address
     * @return address governance
     */
    function getGovernanceAddress() external view returns (address) {
        return governance;
    }

    /**
     * @dev Counts the number of values that have been submitted for the request.
     * @param _queryId the id to look up
     * @return uint256 count of the number of values received for the id
     */
    function getNewValueCountbyQueryId(bytes32 _queryId)
        external
        view
        returns (uint256)
    {
        return reports[_queryId].timestamps.length;
    }

    /**
     * @dev Returns reporter address and whether a value was removed for a given queryId and timestamp
     * @param _queryId the id to look up
     * @param _timestamp is the timestamp of the value to look up
     * @return address reporter who submitted the value
     * @return bool true if the value was removed
     */
    function getReportDetails(bytes32 _queryId, uint256 _timestamp)
        external
        view
        returns (address, bool)
    {
        bool _wasRemoved = reports[_queryId].timestampIndex[_timestamp] == 0 &&
            keccak256(reports[_queryId].valueByTimestamp[_timestamp]) ==
            keccak256(bytes("")) &&
            reports[_queryId].reporterByTimestamp[_timestamp] != address(0);
        return (reports[_queryId].reporterByTimestamp[_timestamp], _wasRemoved);
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
        return stakerDetails[_reporter].reporterLastTimestamp;
    }

    /**
     * @dev Returns the reporting lock time, the amount of time a reporter must wait to submit again
     * @return uint256 reporting lock time
     */
    function getReportingLock() external view returns (uint256) {
        return reportingLock;
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
        return stakerDetails[_reporter].reportsSubmitted;
    }

    /**
     * @dev Returns the number of values submitted to a specific queryId by a specific reporter address
     * @param _reporter is the address of a reporter
     * @param _queryId is the ID of the specific data feed
     * @return uint256 of the number of values submitted by the given reporter to the given queryId
     */
    function getReportsSubmittedByAddressAndQueryId(
        address _reporter,
        bytes32 _queryId
    ) external view returns (uint256) {
        return stakerDetails[_reporter].reportsSubmittedByQueryId[_queryId];
    }

    /**
     * @dev Returns amount required to report oracle values
     * @return uint256 stake amount
     */
    function getStakeAmount() external view returns (uint256) {
        return stakeAmount;
    }

    /**
     * @dev Allows users to retrieve all information about a staker
     * @param _staker address of staker inquiring about
     * @return uint startDate of staking
     * @return uint current amount staked
     * @return uint current amount locked for withdrawal
     * @return uint reporter's last reported timestamp
     * @return uint total number of reports submitted by reporter
     */
    function getStakerInfo(address _staker)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            stakerDetails[_staker].startDate,
            stakerDetails[_staker].stakedBalance,
            stakerDetails[_staker].lockedBalance,
            stakerDetails[_staker].reporterLastTimestamp,
            stakerDetails[_staker].reportsSubmitted
        );
    }

    /**
     * @dev Returns the timestamp for the last value of any ID from the oracle
     * @return uint256 of timestamp of the last oracle value
     */
    function getTimeOfLastNewValue() external view returns (uint256) {
        return timeOfLastNewValue;
    }

    /**
     * @dev Gets the timestamp for the value based on their index
     * @param _queryId is the id to look up
     * @param _index is the value index to look up
     * @return uint256 timestamp
     */
    function getTimestampbyQueryIdandIndex(bytes32 _queryId, uint256 _index)
        external
        view
        returns (uint256)
    {
        return reports[_queryId].timestamps[_index];
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
     * @dev Returns the address of the token used for staking
     * @return address of the token used for staking
     */
    function getTokenAddress() external view returns (address) {
        return address(token);
    }

    /**
     * @dev Returns total amount of token staked for reporting
     * @return uint256 total amount of token staked
     */
    function getTotalStakeAmount() external view returns (uint256) {
        return totalStakeAmount;
    }

    /**
     * @dev Retrieve value from oracle based on timestamp
     * @param _queryId being requested
     * @param _timestamp to retrieve data/value from
     * @return bytes value for timestamp submitted
     */
    function retrieveData(bytes32 _queryId, uint256 _timestamp)
        external
        view
        returns (bytes memory)
    {
        return reports[_queryId].valueByTimestamp[_timestamp];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}