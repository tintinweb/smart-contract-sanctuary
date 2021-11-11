// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "./TellorVars.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/IController.sol";
import "./interfaces/ITreasury.sol";

/**
 @author Tellor Inc.
 @title Governance
 @dev This is the Governance contract which defines the functionality for
 * proposing and executing votes, handling vote mechanism for voters,
 * and distributing funds for initiators and disputed reporters depending
 * on result.
*/
contract Governance is TellorVars {
    // Storage
    uint256 public voteCount; // total number of votes initiated
    uint256 public disputeFee; // dispute fee for a vote
    mapping(address => Delegation[]) private delegateInfo; // mapping of delegate addresses to an array of their delegations
    mapping(bytes4 => bool) private functionApproved; // mapping of function hashes to bools of whether the functions are approved
    mapping(bytes32 => uint256[]) private voteRounds; // mapping of vote identifier hashes to an array of dispute IDs
    mapping(uint256 => Vote) private voteInfo; // mapping of vote IDs to the details of the vote
    mapping(uint256 => Dispute) private disputeInfo; // mapping of dispute IDs to the details of the dispute
    mapping(bytes32 => uint256) private openDisputesOnId; // mapping of a query ID to the number of disputes on that query ID
    enum VoteResult {
        FAILED,
        PASSED,
        INVALID
    } // status of a potential vote

    // Structs
    struct Delegation {
        address delegate; // address of holder delegating their tokens
        uint256 fromBlock; // block number when address started delegating
    }

    struct Dispute {
        bytes32 queryId; // query ID of disputed value
        uint256 timestamp; // timestamp of disputed value
        bytes value; // disputed value
        address disputedReporter; // reporter who submitted the disputed value
    }

    struct Vote {
        bytes32 identifierHash; // identifier hash of the vote
        uint256 voteRound; // the round of voting on a given dispute or proposal
        uint256 startDate; // timestamp of when vote was initiated
        uint256 blockNumber; // block number of when vote was initiated
        uint256 fee; // fee associated with the vote
        uint256 tallyDate; // timestamp of when the votes were tallied
        uint256 doesSupport; // number of votes in favor
        uint256 against; // number of votes against
        bool executed; // boolean of is the dispute settled
        VoteResult result; // VoteResult of did the vote pass?
        bool isDispute; // boolean of is the vote a dispute as opposed to a proposal
        uint256 invalidQuery; // number of votes for invalid
        bytes data; // arguments used to execute a proposal
        bytes4 voteFunction; // hash of the function associated with a proposal vote
        address voteAddress; // address of contract to execute function on
        address initiator; // address which initiated dispute/proposal
        mapping(address => bool) voted; // mapping of address to whether or not they voted
    }

    // Events
    event DelegateSet(address _delegate, address _delegator); // Emitted when voting delegate is set
    event NewDispute(
        uint256 _disputeId,
        bytes32 _queryId,
        uint256 _timestamp,
        address _reporter
    ); // Emitted when a new dispute is opened
    event NewVote(
        address _contract,
        bytes4 _function,
        bytes _data,
        uint256 _disputeId
    ); // Emitted when a new proposal vote is initiated
    event Voted(
        uint256 _disputeId,
        bool _supports,
        address _voter,
        uint256 _voteWeight,
        bool _invalidQuery
    ); // Emitted when an address casts their vote
    event VoteExecuted(uint256 _disputeId, VoteResult _result); // Emitted when a vote is executed
    event VoteTallied(
        uint256 _disputeId,
        VoteResult _result,
        address _initiator,
        address _reporter
    ); // Emitted when all casting for a vote is tallied

    // Functions
    /**
     * @dev Initializes approved function hashes and updates the minimum dispute fees
     */
    constructor(address _master) {
        bytes4[10] memory _funcs = [
            bytes4(0x3c46a185), // changeControllerContract(address)
            0xe8ce51d7, // changeGovernanceContract(address)
            0x1cbd3151, // changeOracleContract(address)
            0xbd87e0c9, // changeTreasuryContract(address)
            0x740358e6, // changeUint(bytes32,uint256)
            0x40c10f19, // mint(address,uint256)
            0xe48d4b3b, // setApprovedFunction(bytes4,bool)
            0x5d183cfa, // changeReportingLock(uint256)
            0x6d53585f, // changeTimeBasedReward(uint256)
            0x6274885f // issueTreasury(uint256,uint256,uint256)
        ];
        // Approve function hashes and update dispute fee
        for (uint256 _i = 0; _i < _funcs.length; _i++) {
            functionApproved[_funcs[_i]] = true;
        }
        TELLOR_ADDRESS = _master;
        updateMinDisputeFee();
    }

    /**
     * @dev Helps initialize a dispute by assigning it a disputeId
     * @param _queryId being disputed
     * @param _timestamp being disputed
     */
    function beginDispute(bytes32 _queryId, uint256 _timestamp) external {
        // Ensure mined block is not 0
        address _oracle = IController(TELLOR_ADDRESS).addresses(
            _ORACLE_CONTRACT
        );
        require(
            IOracle(_oracle).getBlockNumberByTimestamp(_queryId, _timestamp) !=
                0,
            "Mined block is 0"
        );
        address _reporter = IOracle(_oracle).getReporterByTimestamp(
            _queryId,
            _timestamp
        );
        bytes32 _hash = keccak256(abi.encodePacked(_queryId, _timestamp));
        // Increment vote count and push new vote round
        voteCount++;
        uint256 _disputeId = voteCount;
        voteRounds[_hash].push(_disputeId);
        // Check if dispute is started within correct time frame
        if (voteRounds[_hash].length > 1) {
            uint256 _prevId = voteRounds[_hash][voteRounds[_hash].length - 2];
            require(
                block.timestamp - voteInfo[_prevId].tallyDate < 1 days,
                "New dispute round must be started within a day"
            ); // Within a day for new round
        } else {
            require(
                block.timestamp - _timestamp < IOracle(_oracle).reportingLock(),
                "Dispute must be started within 12 hours...same variable as reporting lock"
            ); // New dispute within reporting lock
            openDisputesOnId[_queryId]++;
        }
        // Create new vote and dispute
        Vote storage _thisVote = voteInfo[_disputeId];
        Dispute storage _thisDispute = disputeInfo[_disputeId];
        // Initialize dispute information - query ID, timestamp, value, etc.
        _thisDispute.queryId = _queryId;
        _thisDispute.timestamp = _timestamp;
        _thisDispute.value = IOracle(_oracle).getValueByTimestamp(
            _queryId,
            _timestamp
        );
        _thisDispute.disputedReporter = _reporter;
        // Initialize vote information - hash, initiator, block number, etc.
        _thisVote.identifierHash = _hash;
        _thisVote.initiator = msg.sender;
        _thisVote.blockNumber = block.number;
        _thisVote.startDate = block.timestamp;
        _thisVote.voteRound = voteRounds[_hash].length;
        _thisVote.isDispute = true;
        // Calculate dispute fee based on number of current vote rounds
        uint256 _fee;
        if (voteRounds[_hash].length == 1) {
            _fee = disputeFee * 2**(openDisputesOnId[_queryId] - 1);
            IOracle(_oracle).removeValue(_queryId, _timestamp);
        } else {
            _fee = disputeFee * 2**(voteRounds[_hash].length - 1);
        }
        _thisVote.fee = (_fee * 9) / 10;
        require(
            IController(TELLOR_ADDRESS).approveAndTransferFrom(
                msg.sender,
                address(this),
                _fee
            ),
            "Fee must be paid"
        ); // This is the fork fee. Returned if dispute passes
        // Add an initial tip and change the current staking status of reporter
        IOracle(_oracle).tipQuery(_queryId, _fee - _thisVote.fee, bytes(""));
        (uint256 _status, ) = IController(TELLOR_ADDRESS).getStakerInfo(
            _thisDispute.disputedReporter
        );
        if (_status == 1) {
            uint256 _stakeCount = IController(TELLOR_ADDRESS).getUintVar(
                _STAKE_COUNT
            );
            IController(TELLOR_ADDRESS).changeUint(
                _STAKE_COUNT,
                _stakeCount - 1
            );
            updateMinDisputeFee();
        }
        IController(TELLOR_ADDRESS).changeStakingStatus(_reporter, 3);
        emit NewDispute(_disputeId, _queryId, _timestamp, _reporter);
    }

    /**
     * @dev Allows a delegate address to vote on behalf of another address
     * @param _delegate is the address the sender is delegating to
     */
    function delegate(address _delegate) external {
        Delegation[] storage checkpoints = delegateInfo[msg.sender];
        // Check if sender hasn't delegated the specific address, or if the current delegate is from old block number
        if (
            checkpoints.length == 0 ||
            checkpoints[checkpoints.length - 1].fromBlock != block.number
        ) {
            // Push a new delegate
            checkpoints.push(
                Delegation({
                    delegate: _delegate,
                    fromBlock: uint128(block.number)
                })
            );
        } else {
            // Else, update old delegate
            Delegation storage oldCheckPoint = checkpoints[
                checkpoints.length - 1
            ];
            oldCheckPoint.delegate = _delegate;
        }
        emit DelegateSet(_delegate, msg.sender);
    }

    /**
     * @dev Queries the delegate of _user at a specific _blockNumber
     * @param _user The address delegating voting power
     * @param _blockNumber The block number for which the delegate is retrieved
     * @return The delegate at _blockNumber specified
     */
    function delegateOfAt(address _user, uint256 _blockNumber)
        public
        view
        returns (address)
    {
        Delegation[] storage checkpoints = delegateInfo[_user];
        // Checks if delegate doesn't exist or has block number greater than queried
        if (
            checkpoints.length == 0 || checkpoints[0].fromBlock > _blockNumber
        ) {
            return address(0);
        } else {
            if (_blockNumber >= checkpoints[checkpoints.length - 1].fromBlock)
                return checkpoints[checkpoints.length - 1].delegate;
            // Binary search of correct delegate address
            uint256 _min = 0;
            uint256 _max = checkpoints.length - 2;
            while (_max > _min) {
                uint256 _mid = (_max + _min + 1) / 2;
                if (checkpoints[_mid].fromBlock == _blockNumber) {
                    return checkpoints[_mid].delegate;
                } else if (checkpoints[_mid].fromBlock < _blockNumber) {
                    _min = _mid;
                } else {
                    _max = _mid - 1;
                }
            }
            return checkpoints[_min].delegate;
        }
    }

    /**
     * @dev Executes vote by using result and transferring balance to either
     * initiator or disputed reporter
     * @param _disputeId is the ID of the vote being executed
     */
    function executeVote(uint256 _disputeId) external {
        // Ensure validity of vote ID, vote has been executed, and vote must be tallied
        Vote storage _thisVote = voteInfo[_disputeId];
        require(_disputeId <= voteCount, "Vote ID must be valid");
        require(!_thisVote.executed, "Vote has been executed");
        require(_thisVote.tallyDate > 0, "Vote must be tallied");
        // Ensure vote must be final vote and that time has to be pass (86400 = 24 * 60 * 60 for seconds in a day)
        require(
            voteRounds[_thisVote.identifierHash].length == _thisVote.voteRound,
            "Must be the final vote"
        );
        // require(
        //     block.timestamp - _thisVote.tallyDate >=
        //         86400 * _thisVote.voteRound,
        //     "Vote needs to be tallied and time must pass"
        // );
        _thisVote.executed = true;
        if (!_thisVote.isDispute) {
            // If vote is not in dispute and passed, execute proper vote function with vote data
            if (_thisVote.result == VoteResult.PASSED) {
                address _destination = _thisVote.voteAddress;
                bool _succ;
                bytes memory _res;
                (_succ, _res) = _destination.call(
                    abi.encodePacked(_thisVote.voteFunction, _thisVote.data)
                ); // Be sure to send enough gas!
            }
            emit VoteExecuted(_disputeId, _thisVote.result);
        } else {
            Dispute storage _thisDispute = disputeInfo[_disputeId];
            if (
                voteRounds[_thisVote.identifierHash].length ==
                _thisVote.voteRound
            ) {
                openDisputesOnId[_thisDispute.queryId]--;
            }
            IController _controller = IController(TELLOR_ADDRESS);
            uint256 _i;
            uint256 _voteID;
            if (_thisVote.result == VoteResult.PASSED) {
                // If vote is in dispute and passed, iterate through each vote round and transfer the dispute to initiator
                for (
                    _i = voteRounds[_thisVote.identifierHash].length;
                    _i > 0;
                    _i--
                ) {
                    _voteID = voteRounds[_thisVote.identifierHash][_i - 1];
                    _thisVote = voteInfo[_voteID];
                    // If the first vote round, also make sure to slash the reporter and send their balance to the initiator
                    if (_i == 1) {
                        _controller.slashReporter(
                            _thisDispute.disputedReporter,
                            _thisVote.initiator
                        );
                    }
                    _controller.transfer(_thisVote.initiator, _thisVote.fee);
                }
            } else if (_thisVote.result == VoteResult.INVALID) {
                // If vote is in dispute and is invalid, iterate through each vote round and transfer the dispute fee to initiator
                for (
                    _i = voteRounds[_thisVote.identifierHash].length;
                    _i > 0;
                    _i--
                ) {
                    _voteID = voteRounds[_thisVote.identifierHash][_i - 1];
                    _thisVote = voteInfo[_voteID];
                    _controller.transfer(_thisVote.initiator, _thisVote.fee);
                }
                uint256 _stakeCount = IController(TELLOR_ADDRESS).getUintVar(
                    _STAKE_COUNT
                );
                IController(TELLOR_ADDRESS).changeUint(
                    _STAKE_COUNT,
                    _stakeCount + 1
                );
                _controller.changeStakingStatus(
                    _thisDispute.disputedReporter,
                    1
                ); // Change staking status of disputed reporter, but don't slash
            } else if (_thisVote.result == VoteResult.FAILED) {
                // If vote is in dispute and fails, iterate through each vote round and transfer the dispute fee to disputed reporter
                uint256 _reporterReward = 0;
                for (
                    _i = voteRounds[_thisVote.identifierHash].length;
                    _i > 0;
                    _i--
                ) {
                    _voteID = voteRounds[_thisVote.identifierHash][_i - 1];
                    _thisVote = voteInfo[_voteID];
                    _reporterReward += _thisVote.fee;
                }
                _controller.transfer(
                    _thisDispute.disputedReporter,
                    _reporterReward
                );
                uint256 _stakeCount = IController(TELLOR_ADDRESS).getUintVar(
                    _STAKE_COUNT
                );
                IController(TELLOR_ADDRESS).changeUint(
                    _STAKE_COUNT,
                    _stakeCount - 1
                );
                _controller.changeStakingStatus(
                    _thisDispute.disputedReporter,
                    1
                );
            }
            emit VoteExecuted(_disputeId, voteInfo[_disputeId].result);
        }
    }

    /**
     * @dev Proposes a vote for an associated Tellor contract and function, and defines the properties of the vote
     * @param _contract is the Tellor contract to propose a vote for -> used to calculate identifier hash
     * @param _function is the Tellor function to propose a vote for -> used to calculate identifier hash
     * @param _data is the function argument data associated with the vote proposal -> used to calculate identifier hash
     * @param _timestamp is the timestamp associated with the vote -> used to calculate identifier hash
     */
    function proposeVote(
        address _contract,
        bytes4 _function,
        bytes calldata _data,
        uint256 _timestamp
    ) external {
        // Update vote count, vote ID, current vote, and timestamp
        voteCount++;
        uint256 _disputeId = voteCount;
        Vote storage _thisVote = voteInfo[_disputeId];
        if (_timestamp == 0) {
            _timestamp = block.timestamp;
        }
        // Calculate vote identifier hash and push to vote rounds
        bytes32 _hash = keccak256(
            abi.encodePacked(_contract, _function, _data, _timestamp)
        );
        voteRounds[_hash].push(_disputeId);
        // Ensure new dispute round started within a day
        if (voteRounds[_hash].length > 1) {
            uint256 _prevId = voteRounds[_hash][voteRounds[_hash].length - 2];
            require(
                block.timestamp - voteInfo[_prevId].tallyDate < 1 days,
                "New dispute round must be started within a day"
            ); // 1 day for new disputes
        }
        // Calculate fee to do anything (just 10 tokens flat, no refunds.  Goes up quickly to prevent spamming)
        uint256 _fee = 10e18 * 2**(voteRounds[_hash].length - 1);
        require(
            IController(TELLOR_ADDRESS).approveAndTransferFrom(
                msg.sender,
                address(this),
                _fee
            ),
            "Fee must be paid"
        );
        // Update information on vote -- hash, vote round, start date, block number, fee, etc.
        _thisVote.identifierHash = _hash;
        _thisVote.voteRound = voteRounds[_hash].length;
        _thisVote.startDate = block.timestamp;
        _thisVote.blockNumber = block.number;
        _thisVote.fee = _fee;
        _thisVote.data = _data;
        _thisVote.voteFunction = _function;
        _thisVote.voteAddress = _contract;
        _thisVote.initiator = msg.sender;
        // Contract must be a Tellor contract, and function must be approved
        require(
            _contract == TELLOR_ADDRESS ||
                _contract ==
                IController(TELLOR_ADDRESS).addresses(_GOVERNANCE_CONTRACT) ||
                _contract ==
                IController(TELLOR_ADDRESS).addresses(_TREASURY_CONTRACT) ||
                _contract ==
                IController(TELLOR_ADDRESS).addresses(_ORACLE_CONTRACT),
            "Must interact with the Tellor system"
        );
        require(functionApproved[_function], "Function must be approved");
        emit NewVote(_contract, _function, _data, _disputeId);
    }

    /**
     * @dev Sets a given function's approved status
     * @param _func is the hash of the function to change status
     * @param _val is the boolean of the function's status (approved or not)
     */
    function setApprovedFunction(bytes4 _func, bool _val) public {
        require(
            msg.sender ==
                IController(TELLOR_ADDRESS).addresses(_GOVERNANCE_CONTRACT),
            "Only the Governance contract can change a function's status"
        );
        functionApproved[_func] = _val;
    }

    /**
     * @dev Tallies the votes and begins the 1 day challenge period
     * @param _disputeId is the dispute id
     */
    function tallyVotes(uint256 _disputeId) external {
        // Ensure vote has not been executed and that vote has not been tallied
        Vote storage _thisVote = voteInfo[_disputeId];
        require(!_thisVote.executed, "Dispute has been already executed");
        require(_thisVote.tallyDate == 0, "Vote should not already be tallied");
        require(_disputeId <= voteCount, "Vote does not exist");
        // Determine appropriate vote duration and quorum based on dispute status
        uint256 _duration = 2 days;
        uint256 _quorum = 0;
        if (!_thisVote.isDispute) {
            _duration = 7 days;
            _quorum = 5;
        }
        // Ensure voting is not still open
        // require(
        //     block.timestamp - _thisVote.startDate > _duration,
        //     "Time for voting has not elapsed"
        // );
        // If there are more invalid votes than for and against, result is invalid
        if (
            _thisVote.invalidQuery >= _thisVote.doesSupport &&
            _thisVote.invalidQuery >= _thisVote.against &&
            _thisVote.isDispute
        ) {
            _thisVote.result = VoteResult.INVALID;
        } else if (_thisVote.doesSupport > _thisVote.against) {
            // If there are more support votes than against votes, and the vote has reached quorum, allow the vote to pass
            if (
                _thisVote.doesSupport >=
                ((IController(TELLOR_ADDRESS).uints(_TOTAL_SUPPLY) * _quorum) /
                    100)
            ) {
                _thisVote.result = VoteResult.PASSED;
                Dispute storage _thisDispute = disputeInfo[_disputeId];
                // In addition, change staking status of disputed miner as appropriate
                (uint256 _status, ) = IController(TELLOR_ADDRESS).getStakerInfo(
                    _thisDispute.disputedReporter
                );
                if (_thisVote.isDispute && _status == 3) {
                    IController(TELLOR_ADDRESS).changeStakingStatus(
                        _thisDispute.disputedReporter,
                        4
                    );
                }
            }
        }
        // If there are more against votes than support votes, the result failed
        else {
            _thisVote.result = VoteResult.FAILED;
        }
        _thisVote.tallyDate = block.timestamp; // Update time vote was tallied
        emit VoteTallied(
            _disputeId,
            _thisVote.result,
            _thisVote.initiator,
            disputeInfo[_disputeId].disputedReporter
        );
    }

    /**
     * @dev This function updates the minimum dispute fee as a function of the amount
     * of staked miners
     */
    function updateMinDisputeFee() public {
        uint256 _stakeAmt = IController(TELLOR_ADDRESS).uints(_STAKE_AMOUNT);
        uint256 _trgtMiners = IController(TELLOR_ADDRESS).uints(_TARGET_MINERS);
        uint256 _stakeCount = IController(TELLOR_ADDRESS).uints(_STAKE_COUNT);
        uint256 _minFee = IController(TELLOR_ADDRESS).uints(
            _MINIMUM_DISPUTE_FEE
        );
        uint256 _reducer;
        // Calculate total dispute fee using stake count
        if (_stakeCount > 0) {
            _reducer =
                (((_stakeAmt - _minFee) * (_stakeCount * 1000)) / _trgtMiners) /
                1000;
        }
        if (_reducer >= _stakeAmt - _minFee) {
            disputeFee = _minFee;
        } else {
            disputeFee = _stakeAmt - _reducer;
        }
    }

    /**
     * @dev Enables the sender address to cast a vote
     * @param _disputeId is the ID of the vote
     * @param _supports is the address's vote: whether or not they support or are against
     * @param _invalidQuery is whether or not the dispute is valid
     */
    function vote(
        uint256 _disputeId,
        bool _supports,
        bool _invalidQuery
    ) external {
        require(
            delegateOfAt(msg.sender, voteInfo[_disputeId].blockNumber) ==
                address(0),
            "the vote should not be delegated"
        );
        _vote(msg.sender, _disputeId, _supports, _invalidQuery);
    }

    /**
     * @dev Enables the sender address to cast a vote for other addresses
     * @param _addys is the array of addresses that the sender votes for
     * @param _disputeId is the ID of the vote
     * @param _supports is the address's vote: whether or not they support or are against
     * @param _invalidQuery is whether or not the dispute is valid
     */
    function voteFor(
        address[] calldata _addys,
        uint256 _disputeId,
        bool _supports,
        bool _invalidQuery
    ) external {
        for (uint256 _i = 0; _i < _addys.length; _i++) {
            require(
                delegateOfAt(_addys[_i], voteInfo[_disputeId].blockNumber) ==
                    msg.sender,
                "Sender is not delegated to vote for this address"
            );
            _vote(_addys[_i], _disputeId, _supports, _invalidQuery);
        }
    }

    // Getters
    /**
     * @dev Determines if an address voted for a specific vote
     * @param _disputeId is the ID of the vote
     * @param _voter is the address of the voter to check for
     * @return bool of whether or note the address voted for the specific vote
     */
    function didVote(uint256 _disputeId, address _voter)
        external
        view
        returns (bool)
    {
        return voteInfo[_disputeId].voted[_voter];
    }

    /**
     * @dev Returns info on a delegate for a given holder
     * @param _holder is the address of the holder of TRB tokens
     * @return address of the delegate at the given holder and block number
     * @return uint of the block number of the delegate
     */
    function getDelegateInfo(address _holder)
        external
        view
        returns (address, uint256)
    {
        if (delegateInfo[_holder].length > 0) {
            return (
                delegateOfAt(_holder, block.number),
                delegateInfo[_holder][delegateInfo[_holder].length - 1]
                    .fromBlock
            );
        } else {
            return (address(0), 0);
        }
    }

    /**
     * @dev Returns info on a dispute for a given ID
     * @param _disputeId is the ID of a specific dispute
     * @return bytes32 of the data ID of the dispute
     * @return uint256 of the timestamp of the dispute
     * @return bytes memory of the value being disputed
     * @return address of the reporter being disputed
     */
    function getDisputeInfo(uint256 _disputeId)
        external
        view
        returns (
            bytes32,
            uint256,
            bytes memory,
            address
        )
    {
        Dispute storage _d = disputeInfo[_disputeId];
        return (_d.queryId, _d.timestamp, _d.value, _d.disputedReporter);
    }

    /**
     * @dev Returns the number of open disputes for a specific query ID
     * @param _queryId is the ID of a specific data feed
     * @return uint256 of the number of open disputes for the query ID
     */
    function getOpenDisputesOnId(bytes32 _queryId)
        external
        view
        returns (uint256)
    {
        return openDisputesOnId[_queryId];
    }

    /**
     * @dev Returns the total number of votes
     * @return uint256 of the total number of votes
     */
    function getVoteCount() external view returns (uint256) {
        return voteCount;
    }

    /**
     * @dev Returns info on a vote for a given vote ID
     * @param _disputeId is the ID of a specific vote
     * @return bytes32 identifier hash of the vote
     * @return uint256[8] memory of the pertinent round info (vote rounds, start date, fee, etc.)
     * @return bool[2] memory of both whether or not the vote was executed and is dispute
     * @return VoteResult result of the vote
     * @return bytes memory of the argument data of a proposal vote
     * @return bytes4 of the function selector proposed to be called
     * @return address[2] memory of the Tellor system contract address and vote initiator
     */
    function getVoteInfo(uint256 _disputeId)
        external
        view
        returns (
            bytes32,
            uint256[8] memory,
            bool[2] memory,
            VoteResult,
            bytes memory,
            bytes4,
            address[2] memory
        )
    {
        Vote storage _v = voteInfo[_disputeId];
        return (
            _v.identifierHash,
            [
                _v.voteRound,
                _v.startDate,
                _v.blockNumber,
                _v.fee,
                _v.tallyDate,
                _v.doesSupport,
                _v.against,
                _v.invalidQuery
            ],
            [_v.executed, _v.isDispute],
            _v.result,
            _v.data,
            _v.voteFunction,
            [_v.voteAddress, _v.initiator]
        );
    }

    /**
     * @dev Returns an array of voting rounds for a given vote
     * @param _hash is the identifier hash for a vote
     * @return uint256[] memory dispute IDs of the vote rounds
     */
    function getVoteRounds(bytes32 _hash)
        external
        view
        returns (uint256[] memory)
    {
        return voteRounds[_hash];
    }

    /**
     * @dev Used for future governance contract upgrades. Hardcode old contract address in next upgrade
     * @param _contract is the contract address to check
     */
    function isApprovedGovernanceContract(address _contract)
        external
        returns (bool)
    {
        if (
            _contract ==
            IController(TELLOR_ADDRESS).addresses(_GOVERNANCE_CONTRACT)
        ) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns whether or not a function is approved for proposals
     * @param _func is the hash of the function to be checked
     * @return bool of whether or not the function is approved
     */
    function isFunctionApproved(bytes4 _func) external view returns (bool) {
        return functionApproved[_func];
    }

    /**
     * @dev Used during the upgrade process to verify valid Tellor Contracts
     */
    function verify() external pure returns (uint256) {
        return 9999;
    }

    // Internal
    /**
     * @dev Allows an address to vote by calculating their total vote weight and updating vote count
     * for the vote ID
     * @param _voter is the address casting their vote
     * @param _disputeId is the vote ID the address is casting their vote for
     * @param _supports is a boolean of whether the voter supports the dispute
     * @param _invalidQuery is a boolean of whether the voter believes the dispute is invalid
     */
    function _vote(
        address _voter,
        uint256 _disputeId,
        bool _supports,
        bool _invalidQuery
    ) internal {
        // Ensure that dispute has not been executed and that vote does not exist and is not tallied
        require(_disputeId <= voteCount, "Vote does not exist");
        Vote storage _thisVote = voteInfo[_disputeId];
        require(_thisVote.tallyDate == 0, "Vote has already been tallied");
        IController _controller = IController(TELLOR_ADDRESS);
        uint256 voteWeight = _controller.balanceOfAt(
            _voter,
            _thisVote.blockNumber
        );
        IOracle _oracle = IOracle(_controller.addresses(_ORACLE_CONTRACT));
        ITreasury _treasury = ITreasury(
            _controller.addresses(_TREASURY_CONTRACT)
        );
        // Add to vote weight of voter based on treasury funds, reports submitted, and total tips
        voteWeight += _treasury.getTreasuryFundsByUser(_voter);
        voteWeight += _oracle.getReportsSubmittedByAddress(_voter) * 1e18;
        voteWeight += _oracle.getTipsByUser(_voter);
        // Make sure voter can't already be disputed, has already voted, or if balance is 0
        (uint256 _status, ) = _controller.getStakerInfo(_voter);
        require(_status != 3, "Cannot vote if being disputed");
        require(!_thisVote.voted[_voter], "Sender has already voted");
        require(voteWeight > 0, "User balance is 0");
        // Update voting status and increment total queries for support, invalid, or against based on vote
        _thisVote.voted[_voter] = true;
        if (_thisVote.isDispute && _invalidQuery) {
            _thisVote.invalidQuery += voteWeight;
        } else if (_supports) {
            _thisVote.doesSupport += voteWeight;
        } else {
            _thisVote.against += voteWeight;
        }
        emit Voted(_disputeId, _supports, _voter, voteWeight, _invalidQuery);
    }
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
pragma solidity 0.8.3;

interface IOracle{
    function getReportTimestampByIndex(bytes32 _queryId, uint256 _index) external view returns(uint256);
    function getValueByTimestamp(bytes32 _queryId, uint256 _timestamp) external view returns(bytes memory);
    function getBlockNumberByTimestamp(bytes32 _queryId, uint256 _timestamp) external view returns(uint256);
    function getReporterByTimestamp(bytes32 _queryId, uint256 _timestamp) external view returns(address);
    function getReporterLastTimestamp(address _reporter) external view returns(uint256);
    function reportingLock() external view returns(uint256);
    function removeValue(bytes32 _queryId, uint256 _timestamp) external;
    function getReportsSubmittedByAddress(address _reporter) external view returns(uint256);
    function getTipsByUser(address _user) external view returns(uint256);
    function tipQuery(bytes32 _queryId, uint256 _tip, bytes memory _queryData) external;
    function submitValue(bytes32 _queryId, bytes calldata _value, uint256 _nonce, bytes memory _queryData) external;
    function burnTips() external;
    function verify() external pure returns(uint);
    function changeReportingLock(uint256 _newReportingLock) external;
    function changeTimeBasedReward(uint256 _newTimeBasedReward) external;
    function getTipsById(bytes32 _queryId) external view returns(uint256);
    function getTimestampCountById(bytes32 _queryId) external view returns(uint256);
    function getTimestampIndexByTimestamp(bytes32 _queryId, uint256 _timestamp) external view returns(uint256);
    function getCurrentValue(bytes32 _queryId) external view returns(bytes memory);
    function getTimeOfLastNewValue() external view returns(uint256);
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

interface ITreasury{
    function issueTreasury(uint256 _amount, uint256 _rate, uint256 _duration) external;
    function payTreasury(address _investor,uint256 _id) external;
    function buyTreasury(uint256 _id,uint256 _amount) external;
    function getTreasuryDetails(uint256 _id) external view returns(uint256,uint256,uint256,uint256);
    function getTreasuryAccount(uint256 _id, address _investor) external view returns(uint256);
    function getTreasuryOwners(uint256 _id) external view returns(address[] memory);
    function getTreasuryFundsByUser(address _user) external view returns(uint256);
    function wasPaid(uint256 _id, address _investor) external view returns(bool);
    function verify() external pure returns(uint);
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