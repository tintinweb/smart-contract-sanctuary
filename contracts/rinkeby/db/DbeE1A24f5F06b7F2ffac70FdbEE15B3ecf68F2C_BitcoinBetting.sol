// SPDX-License-Identifier: MIT
pragma solidity >=0.8.3;

import "usingtellor/contracts/UsingTellor.sol";

contract BitcoinBetting is UsingTellor {
    constructor(address payable _tellorAddress) UsingTellor(_tellorAddress) {}

    //create Events for each function
    //Event for when a new bet is created
    //Event for when creator has a response better
    //Event for when the payoutBetters function is called
    event NewBet(
        address betCreator,
        uint256 total,
        uint256 betAmount,
        bool senderIsOver,
        uint256 deadline
    );
    event NewReponseBet(
        address betResponder,
        uint256 total,
        uint256 responseAmount,
        bool responderIsOver,
        uint256 deadline
    );
    event Payout(uint256 bitCoinPrice, address winner, uint256 winAmount);
    event PayoutPush(uint256 bitCoinPrice, bool totalWasPushed);

    struct Total {
        address addressOver;
        address addressUnder;
        uint256 total;
        uint256 addressOverBet;
        uint256 addressUnderBet;
        uint256 deadline;
        uint256 responseDeadline;
        bool addressOverPaid;
        bool addressUnderPaid;
        bool betPaidOut;
    }
    uint256 public deadline = 2 * 1 minutes;
    uint256 public responseDeadline = 1 minutes;
    bytes32 public bitCoinQueryId =
        0x0000000000000000000000000000000000000000000000000000000000000002;
    Total[] public betRoundInfo;

    function createBet(uint256 _total, bool _senderIsOver) external payable {
        require(msg.value > 0);
        if (_senderIsOver) {
            betRoundInfo.push(
                Total({
                    addressOver: msg.sender,
                    addressUnder: address(0),
                    total: _total,
                    addressOverBet: msg.value,
                    addressUnderBet: 0,
                    deadline: block.timestamp + deadline,
                    responseDeadline: block.timestamp + responseDeadline,
                    addressOverPaid: true,
                    addressUnderPaid: false,
                    betPaidOut: false
                })
            );
        } else {
            betRoundInfo.push(
                Total({
                    addressOver: address(0),
                    addressUnder: msg.sender,
                    total: _total,
                    addressOverBet: 0,
                    addressUnderBet: msg.value,
                    deadline: block.timestamp + deadline,
                    responseDeadline: block.timestamp + responseDeadline,
                    addressOverPaid: false,
                    addressUnderPaid: true,
                    betPaidOut: false
                })
            );
        }
        emit NewBet(
            msg.sender,
            _total,
            msg.value,
            _senderIsOver,
            block.timestamp + deadline
        );
    }

    function responseBet(uint256 _betId) external payable {
        require(block.timestamp < betRoundInfo[_betId].responseDeadline);
        if (betRoundInfo[_betId].addressOver == address(0)) {
            require(
                msg.value == betRoundInfo[_betId].addressUnderBet,
                "Your bet value does not match initial bet creators stake"
            );
            require(
                betRoundInfo[_betId].addressUnder != msg.sender,
                "You can't respond to your own bet."
            );
            betRoundInfo[_betId].addressOver = msg.sender;
            betRoundInfo[_betId].addressOverBet = msg.value;
            betRoundInfo[_betId].addressOverPaid = true;
            emit NewReponseBet(
                msg.sender,
                betRoundInfo[_betId].total,
                msg.value,
                true,
                betRoundInfo[_betId].deadline
            );
        } else if (betRoundInfo[_betId].addressUnder == address(0)) {
            require(
                msg.value == betRoundInfo[_betId].addressOverBet,
                "Your bet value does not match initial bet creators stake"
            );
            require(
                betRoundInfo[_betId].addressOver != msg.sender,
                "You can't respond to your own bet."
            );
            betRoundInfo[_betId].addressUnder = msg.sender;
            betRoundInfo[_betId].addressUnderBet = msg.value;
            betRoundInfo[_betId].addressUnderPaid = true;
            emit NewReponseBet(
                msg.sender,
                betRoundInfo[_betId].total,
                msg.value,
                false,
                betRoundInfo[_betId].deadline
            );
        }
    }

    function payoutBetters(uint256 _betId) external payable {
        Total storage bet = betRoundInfo[_betId];

        require(block.timestamp > betRoundInfo[_betId].deadline);
        require(bet.betPaidOut == false);

        if (bet.addressOver == address(0)) {
            payable(bet.addressUnder).transfer(bet.addressUnderBet);
        } else if (bet.addressUnder == address(0)) {
            payable(bet.addressOver).transfer(bet.addressOverBet);
        }

        (, bytes memory bitCoinBytes, ) = getDataBefore(
            bitCoinQueryId,
            bet.deadline
        );

        uint256 bitCoinUint = _sliceUint(bitCoinBytes);
        bet.betPaidOut = true;
        if (bet.total > bitCoinUint) {
            payable(bet.addressUnder).transfer(
                bet.addressOverBet + bet.addressUnderBet
            );
            emit Payout(
                bitCoinUint,
                bet.addressUnder,
                bet.addressOverBet + bet.addressUnderBet
            );
        } else if (bet.total < bitCoinUint) {
            payable(bet.addressOver).transfer(
                bet.addressOverBet + bet.addressUnderBet
            );
            emit Payout(
                bitCoinUint,
                bet.addressOver,
                bet.addressOverBet + bet.addressUnderBet
            );
        } else {
            payable(bet.addressUnder).transfer(bet.addressUnderBet);
            payable(bet.addressOver).transfer(bet.addressOverBet);
            emit PayoutPush(bitCoinUint, true);
        }
    }

    // Internal
    /**
     * @dev Utilized to help slice a bytes variable into a uint
     * @param _b is the bytes variable to be sliced
     * @return _x of the sliced uint256
     */
    function _sliceUint(bytes memory _b) public pure returns (uint256 _x) {
        uint256 _number = 0;
        for (uint256 _i = 0; _i < _b.length; _i++) {
            _number = _number * 2**8;
            _number = _number + uint8(_b[_i]);
        }
        return _number;
    }
}

//Betting on the price of Bitcoin
//Person1 invests a token amount(maybe TRB or some new token) or ether (aka a bet).
//Get bitcoin price for start date and end date.
//Pay out token based on how close they were.

//Do I have to mint a certain amount of TRB/Rando token in order to cover my losses?
//Figure out payment system, spread betting?
//Central Pool for the tokens to be initially deposited and also from where to pay out
//Frontend? Possibly for entering in bet/values

//There are five steps involved in a bitcoin spread trade.
//First, look at the current bitcoin bid/ask spread, then speculate on a price movement direction.
//Next, calculate the stake of the trader per price movement.
//Fourth, close the trade, and finally, calculate the profit or loss.

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./interface/ITellor.sol";

/**
 * @title UserContract
 * This contract allows for easy integration with the Tellor System
 * by helping smart contracts to read data from Tellor
 */
contract UsingTellor {
    ITellor private tellor;

    /*Constructor*/
    /**
     * @dev the constructor sets the tellor address in storage
     * @param _tellor is the TellorMaster address
     */
    constructor(address payable _tellor) {
        tellor = ITellor(_tellor);
    }

    /*Getters*/
    /**
     * @dev Allows the user to get the latest value for the queryId specified
     * @param _queryId is the id to look up the value for
     * @return _ifRetrieve bool true if non-zero value successfully retrieved
     * @return _value the value retrieved
     * @return _timestampRetrieved the retrieved value's timestamp
     */
    function getCurrentValue(bytes32 _queryId)
        public
        view
        returns (
            bool _ifRetrieve,
            bytes memory _value,
            uint256 _timestampRetrieved
        )
    {
        uint256 _count = tellor.getNewValueCountbyQueryId(_queryId);
        uint256 _time = tellor.getTimestampbyQueryIdandIndex(
            _queryId,
            _count - 1
        );
        _value = tellor.retrieveData(_queryId, _time);
        if (keccak256(_value) != keccak256(bytes("")))
            return (true, _value, _time);
        return (false, bytes(""), _time);
    }

    /**
     * @dev Retrieves the latest value for the queryId before the specified timestamp
     * @param _queryId is the queryId to look up the value for
     * @param _timestamp before which to search for latest value
     * @return _ifRetrieve bool true if able to retrieve a non-zero value
     * @return _value the value retrieved
     * @return _timestampRetrieved the value's timestamp
     */
    function getDataBefore(bytes32 _queryId, uint256 _timestamp)
        public
        view
        returns (
            bool _ifRetrieve,
            bytes memory _value,
            uint256 _timestampRetrieved
        )
    {
        (bool _found, uint256 _index) = getIndexForDataBefore(
            _queryId,
            _timestamp
        );
        if (!_found) return (false, bytes(""), 0);
        uint256 _time = tellor.getTimestampbyQueryIdandIndex(_queryId, _index);
        _value = tellor.retrieveData(_queryId, _time);
        //If value is diputed it'll return zero
        if (keccak256(_value) != keccak256(bytes("")))
            return (true, _value, _time);
        return (false, bytes(""), 0);
    }

    /**
     * @dev Retrieves latest array index of data before the specified timestamp for the queryId
     * @param _queryId is the queryId to look up the index for
     * @param _timestamp is the timestamp before which to search for the latest index
     * @return _found whether the index was found
     * @return _index the latest index found before the specified timestamp
     */
    // slither-disable-next-line calls-loop
    function getIndexForDataBefore(bytes32 _queryId, uint256 _timestamp)
        public
        view
        returns (bool _found, uint256 _index)
    {
        uint256 _count = tellor.getNewValueCountbyQueryId(_queryId);
        if (_count > 0) {
            uint256 middle;
            uint256 start = 0;
            uint256 end = _count - 1;
            uint256 _time;

            //Checking Boundaries to short-circuit the algorithm
            _time = tellor.getTimestampbyQueryIdandIndex(_queryId, start);
            if (_time >= _timestamp) return (false, 0);
            _time = tellor.getTimestampbyQueryIdandIndex(_queryId, end);
            if (_time < _timestamp) return (true, end);

            //Since the value is within our boundaries, do a binary search
            while (true) {
                middle = (end - start) / 2 + 1 + start;
                _time = tellor.getTimestampbyQueryIdandIndex(_queryId, middle);
                if (_time < _timestamp) {
                    //get imeadiate next value
                    uint256 _nextTime = tellor.getTimestampbyQueryIdandIndex(
                        _queryId,
                        middle + 1
                    );
                    if (_nextTime >= _timestamp) {
                        //_time is correct
                        return (true, middle);
                    } else {
                        //look from middle + 1(next value) to end
                        start = middle + 1;
                    }
                } else {
                    uint256 _prevTime = tellor.getTimestampbyQueryIdandIndex(
                        _queryId,
                        middle - 1
                    );
                    if (_prevTime < _timestamp) {
                        // _prevtime is correct
                        return (true, middle - 1);
                    } else {
                        //look from start to middle -1(prev value)
                        end = middle - 1;
                    }
                }
                //We couldn't found a value
                //if(middle - 1 == start || middle == _count) return (false, 0);
            }
        }
        return (false, 0);
    }

    /**
     * @dev Counts the number of values that have been submitted for the queryId
     * @param _queryId the id to look up
     * @return uint256 count of the number of values received for the queryId
     */
    function getNewValueCountbyQueryId(bytes32 _queryId)
        public
        view
        returns (uint256)
    {
        return tellor.getNewValueCountbyQueryId(_queryId);
    }

    // /**
    //  * @dev Gets the timestamp for the value based on their index
    //  * @param _queryId is the id to look up
    //  * @param _index is the value index to look up
    //  * @return uint256 timestamp
    //  */
    function getTimestampbyQueryIdandIndex(bytes32 _queryId, uint256 _index)
        public
        view
        returns (uint256)
    {
        return tellor.getTimestampbyQueryIdandIndex(_queryId, _index);
    }

    /**
     * @dev Determines whether a value with a given queryId and timestamp has been disputed
     * @param _queryId is the value id to look up
     * @param _timestamp is the timestamp of the value to look up
     * @return bool true if queryId/timestamp is under dispute
     */
    function isInDispute(bytes32 _queryId, uint256 _timestamp)
        public
        view
        returns (bool)
    {
        ITellor _governance = ITellor(
            tellor.addresses(
                keccak256(abi.encodePacked("_GOVERNANCE_CONTRACT"))
            )
        );
        return
            _governance
                .getVoteRounds(
                keccak256(abi.encodePacked(_queryId, _timestamp))
            )
                .length >
            0;
    }

    /**
     * @dev Retrieve value from oracle based on queryId/timestamp
     * @param _queryId being requested
     * @param _timestamp to retrieve data/value from
     * @return bytes value for query/timestamp submitted
     */
    function retrieveData(bytes32 _queryId, uint256 _timestamp)
        public
        view
        returns (bytes memory)
    {
        return tellor.retrieveData(_queryId, _timestamp);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface ITellor{
    //Controller
    function addresses(bytes32) external view returns(address);
    function uints(bytes32) external view returns(uint256);
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
    function getAllDisputeVars(uint256 _disputeId) external view returns (bytes32,bool,bool,bool,address,address,address,uint256[9] memory,int256);
    function getDisputeIdByDisputeHash(bytes32 _hash) external view returns (uint256);
    function getDisputeUintVars(uint256 _disputeId, bytes32 _data) external view returns(uint256);
    function getLastNewValueById(uint256 _requestId) external view returns (uint256, bool);
    function retrieveData(uint256 _requestId, uint256 _timestamp) external view returns (uint256);
    function getNewValueCountbyRequestId(uint256 _requestId) external view returns (uint256);
    function getAddressVars(bytes32 _data) external view returns (address);
    function getUintVar(bytes32 _data) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function isMigrated(address _addy) external view returns (bool);
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
    function getTimestampbyRequestIDandIndex(uint256 _requestId, uint256 _index) external view returns (uint256);
    function getNewCurrentVariables()external view returns (bytes32 _c,uint256[5] memory _r,uint256 _d,uint256 _t);
    function getNewValueCountbyQueryId(bytes32 _queryId) external view returns(uint256);
    function getTimestampbyQueryIdandIndex(bytes32 _queryId, uint256 _index) external view returns(uint256);
    function retrieveData(bytes32 _queryId, uint256 _timestamp) external view returns(bytes memory);
    //Governance
    enum VoteResult {FAILED,PASSED,INVALID}
    function setApprovedFunction(bytes4 _func, bool _val) external;
    function beginDispute(bytes32 _queryId,uint256 _timestamp) external;
    function delegate(address _delegate) external;
    function delegateOfAt(address _user, uint256 _blockNumber) external view returns (address);
    function executeVote(uint256 _disputeId) external;
    function proposeVote(address _contract,bytes4 _function, bytes calldata _data, uint256 _timestamp) external;
    function tallyVotes(uint256 _disputeId) external;
    function updateMinDisputeFee() external;
    function verify() external pure returns(uint);
    function vote(uint256 _disputeId, bool _supports, bool _invalidQuery) external;
    function voteFor(address[] calldata _addys,uint256 _disputeId, bool _supports, bool _invalidQuery) external;
    function getDelegateInfo(address _holder) external view returns(address,uint);
    function isFunctionApproved(bytes4 _func) external view returns(bool);
    function isApprovedGovernanceContract(address _contract) external returns (bool);
    function getVoteRounds(bytes32 _hash) external view returns(uint256[] memory);
    function getVoteCount() external view returns(uint256);
    function getVoteInfo(uint256 _disputeId) external view returns(bytes32,uint256[9] memory,bool[2] memory,VoteResult,bytes memory,bytes4,address[2] memory);
    function getDisputeInfo(uint256 _disputeId) external view returns(uint256,uint256,bytes memory, address);
    function getOpenDisputesOnId(bytes32 _queryId) external view returns(uint256);
    function didVote(uint256 _disputeId, address _voter) external view returns(bool);
    //Oracle
    function getReportTimestampByIndex(bytes32 _queryId, uint256 _index) external view returns(uint256);
    function getValueByTimestamp(bytes32 _queryId, uint256 _timestamp) external view returns(bytes memory);
    function getBlockNumberByTimestamp(bytes32 _queryId, uint256 _timestamp) external view returns(uint256);
    function getReportingLock() external view returns(uint256);
    function getReporterByTimestamp(bytes32 _queryId, uint256 _timestamp) external view returns(address);
    function reportingLock() external view returns(uint256);
    function removeValue(bytes32 _queryId, uint256 _timestamp) external;
    function getReportsSubmittedByAddress(address _reporter) external view returns(uint256);
    function getTipsByUser(address _user) external view returns(uint256);
    function tipQuery(bytes32 _queryId, uint256 _tip, bytes memory _queryData) external;
    function submitValue(bytes32 _queryId, bytes calldata _value, uint256 _nonce, bytes memory _queryData) external;
    function burnTips() external;
    function changeReportingLock(uint256 _newReportingLock) external;
    function changeTimeBasedReward(uint256 _newTimeBasedReward) external;
    function getReporterLastTimestamp(address _reporter) external view returns(uint256);
    function getTipsById(bytes32 _queryId) external view returns(uint256);
    function getTimeBasedReward() external view returns(uint256);
    function getTimestampCountById(bytes32 _queryId) external view returns(uint256);
    function getTimestampIndexByTimestamp(bytes32 _queryId, uint256 _timestamp) external view returns(uint256);
    function getCurrentReward(bytes32 _queryId) external view returns(uint256, uint256);
    function getCurrentValue(bytes32 _queryId) external view returns(bytes memory);
    function getTimeOfLastNewValue() external view returns(uint256);
    //Treasury
    function issueTreasury(uint256 _maxAmount, uint256 _rate, uint256 _duration) external;
    function payTreasury(address _investor,uint256 _id) external;
    function buyTreasury(uint256 _id,uint256 _amount) external;
    function getTreasuryDetails(uint256 _id) external view returns(uint256,uint256,uint256,uint256);
    function getTreasuryFundsByUser(address _user) external view returns(uint256);
    function getTreasuryAccount(uint256 _id, address _investor) external view returns(uint256,uint256,bool);
    function getTreasuryCount() external view returns(uint256);
    function getTreasuryOwners(uint256 _id) external view returns(address[] memory);
    function wasPaid(uint256 _id, address _investor) external view returns(bool);
    //Test functions
    function changeAddressVar(bytes32 _id, address _addy) external;

    //parachute functions
    function killContract() external;
    function migrateFor(address _destination,uint256 _amount) external;
    function rescue51PercentAttack(address _tokenHolder) external;
    function rescueBrokenDataReporting() external;
    function rescueFailedUpdate() external;
}