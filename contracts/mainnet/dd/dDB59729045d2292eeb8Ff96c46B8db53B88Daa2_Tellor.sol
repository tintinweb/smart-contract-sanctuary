// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

import "./TellorStake.sol";
import "./TellorGetters.sol";
import "./Utilities.sol";
import "./ITellor.sol";
import "./SafeMath.sol";

 /** 
 @author Tellor Inc.
 @title Tellor
 @dev  Main functionality for Tellor Oracle system
**/
contract Tellor is TellorStake,Utilities {
    using SafeMath for uint256;

    /*Events*/
    //Emits when a tip is added (asking for this ID to be mined                                         )
    event TipAdded(
        address indexed _sender,
        uint256 indexed _requestId,
        uint256 _tip,
        uint256 _totalTips
    );
    //Emits when a new challenge is created (either on mined block or when a new request is pushed forward on waiting system)
    event NewChallenge(
        bytes32 indexed _currentChallenge,
        uint256[5] _currentRequestId,
        uint256 _difficulty,
        uint256 _totalTips
    );
    //Emits upon a successful Mine, indicates the blockTime at point of the mine and the value mined
    event NewValue(
        uint256[5] _requestId,
        uint256 _time,
        uint256[5] _value,
        uint256 _totalTips,
        bytes32 indexed _currentChallenge
    );
    //Emits upon each mine (5 total) and shows the miner, nonce, and value submitted
    event NonceSubmitted(
        address indexed _miner,
        string _nonce,
        uint256[5] _requestId,
        uint256[5] _value,
        bytes32 indexed _currentChallenge,
        uint256 _slot
    );

    /*Storage -- constant only*/
    address immutable extensionAddress;
    
    /*Functions*/
    /**
     * @dev Constructor to set extension address
     * @param _ext Extension address
    */
    constructor(address _ext) {
        extensionAddress = _ext;
    }

    /**
     * @dev Add tip to a request ID
     * @param _requestId being requested to be mined
     * @param _tip amount the requester is willing to pay to be get on queue. Miners
     * mine the ID with the highest tip
    */
    function addTip(uint256 _requestId, uint256 _tip) external {
        require(_requestId != 0, "RequestId is 0");
        require(_tip != 0, "Tip should be greater than 0");
        uint256 _count = uints[_REQUEST_COUNT] + 1;
        if (_requestId == _count) {
            uints[_REQUEST_COUNT] = _count;
        } else {
            require(_requestId < _count, "RequestId is not less than count");
        }
        _doBurn(msg.sender, _tip);
        //Update the information for the request that should be mined next based on the tip submitted
        _updateOnDeck(_requestId, _tip);
        emit TipAdded(
            msg.sender,
            _requestId,
            _tip,
            requestDetails[_requestId].apiUintVars[_TOTAL_TIP]
        );
    }

    /**
     * @dev This function allows users to swap old trb tokens for new ones based
     * on the user's old Tellor balance
    */
    function migrate() external {
        _migrate(msg.sender);
    }

    /**
     * @dev This is function used by the migrator to help
     *  swap old trb tokens for new ones based on the user's old Tellor balance
     * @param _destination is the address that will receive tokens
     * @param _amount is the amount to mint to the user
     * @param _bypass whether or not to bypass the check if they migrated already
    */
    function migrateFor(
        address _destination,
        uint256 _amount,
        bool _bypass
    ) external {
        require(msg.sender == addresses[_DEITY], "not allowed");
        _migrateFor(_destination, _amount, _bypass);
    }

    /**
     * @dev This function allows miners to submit their mining solution and data requested
     * @param _nonce is the mining solution
     * @param _requestIds are the 5 request ids being mined
     * @param _values are the 5 values corresponding to the 5 request ids
    */
    function submitMiningSolution(
        string calldata _nonce,
        uint256[5] calldata _requestIds,
        uint256[5] calldata _values
    ) external {
        bytes32 _hashMsgSender = keccak256(abi.encode(msg.sender));
        require(
            uints[_hashMsgSender] == 0 ||
                block.timestamp - uints[_hashMsgSender] > 15 minutes,
            "Miner can only win rewards once per 15 min"
        );
        if (uints[_SLOT_PROGRESS] != 4) {
            _verifyNonce(_nonce);
        }
        uints[_hashMsgSender] = block.timestamp;
        _submitMiningSolution(_nonce, _requestIds, _values);
    }

    /*Internal Functions*/
    /**
     * @dev This is an internal function used by submitMiningSolution and adjusts the difficulty
     * based on the difference between the target time and how long it took to solve
     * the previous challenge otherwise it sets it to 1
    */
    function _adjustDifficulty() internal {
        // If the difference between the timeTarget and how long it takes to solve the challenge this updates the challenge
        // difficulty up or down by the difference between the target time and how long it took to solve the previous challenge
        // otherwise it sets it to 1
        uint256 timeDiff = block.timestamp - uints[_TIME_OF_LAST_NEW_VALUE];
        int256 _change = int256(SafeMath.min(1200, timeDiff));
        int256 _diff = int256(uints[_DIFFICULTY]);
        _change = (_diff * (int256(uints[_TIME_TARGET]) - _change)) / 4000;
        if (_change == 0) {
            _change = 1;
        }
        uints[_DIFFICULTY] = uint256(SafeMath.max(_diff + _change, 1));
    }

    /**
     * @dev This is an internal function called by updateOnDeck that gets the min value
     * @param _data is an array [51] to determine the min from
     * @return min the min value and it's index in the data array
     */
    function _getMin(uint256[51] memory _data)
        internal
        pure
        returns (uint256 min, uint256 minIndex)
    {
        minIndex = _data.length - 1;
        min = _data[minIndex];
        for (uint256 i = _data.length - 2; i > 0; i--) {
            if (_data[i] < min) {
                min = _data[i];
                minIndex = i;
            }
        }
    }

    /**
     * @dev Getter function for the top 5 requests with highest payouts.
     * This function is used within the newBlock function
     * @return _requestIds the top 5 requests ids based on tips or the last 5 requests ids mined
    */
    function _getTopRequestIDs()
        internal
        view
        returns (uint256[5] memory _requestIds)
    {
        uint256[5] memory _max;
        uint256[5] memory _index;
        (_max, _index) = _getMax5(requestQ);
        for (uint256 i = 0; i < 5; i++) {
            if (_max[i] != 0) {
                _requestIds[i] = requestIdByRequestQIndex[_index[i]];
            } else {
                _requestIds[i] = currentMiners[4 - i].value;
            }
        }
    }

    /**
     * @dev This is an internal function used by the function migrate  that helps to
     *  swap old trb tokens for new ones based on the user's old Tellor balance
     * @param _user is the msg.sender address of the user to migrate the balance from
    */
    function _migrate(address _user) internal {
        require(!migrated[_user], "Already migrated");
        _doMint(_user, ITellor(addresses[_OLD_TELLOR]).balanceOf(_user));
        migrated[_user] = true;
    }

    /**
     * @dev This is an internal function used by the function migrate  that helps to
     *  swap old trb tokens for new ones based on a custom amount
     * @param _destination is the address that will receive tokens
     * @param _amount is the amount to mint to the user
     * @param _bypass is true if the migrator contract needs to bypass the migrated = true flag
     *  for users that have already  migrated 
    */
    function _migrateFor(
        address _destination,
        uint256 _amount,
        bool _bypass
    ) internal {
        if (!_bypass) require(!migrated[_destination], "already migrated");
        _doMint(_destination, _amount);
        migrated[_destination] = true;
    }

    /**
     * @dev This is an internal function called by submitMiningSolution and adjusts the difficulty,
     * sorts and stores the first 5 values received, pays the miners, the dev share and
     * assigns a new challenge
     * @param _nonce or solution for the PoW for the current challenge
     * @param _requestIds array of the current request IDs being mined
    */
    function _newBlock(string memory _nonce, uint256[5] memory _requestIds)
        internal
    {
        Request storage _tblock = requestDetails[uints[_T_BLOCK]];
        bytes32 _currChallenge = bytesVars[_CURRENT_CHALLENGE];
        uint256 _previousTime = uints[_TIME_OF_LAST_NEW_VALUE];
        uint256 _timeOfLastNewValueVar = block.timestamp;
        uints[_TIME_OF_LAST_NEW_VALUE] = _timeOfLastNewValueVar;
        //this loop sorts the values and stores the median as the official value
        uint256[5] memory a;
        uint256[5] memory b;
        for (uint256 k = 0; k < 5; k++) {
            for (uint256 i = 1; i < 5; i++) {
                uint256 temp = _tblock.valuesByTimestamp[k][i];
                address temp2 = _tblock.minersByValue[k][i];
                uint256 j = i;
                while (j > 0 && temp < _tblock.valuesByTimestamp[k][j - 1]) {
                    _tblock.valuesByTimestamp[k][j] = _tblock.valuesByTimestamp[
                        k
                    ][j - 1];
                    _tblock.minersByValue[k][j] = _tblock.minersByValue[k][
                        j - 1
                    ];
                    j--;
                }
                if (j < i) {
                    _tblock.valuesByTimestamp[k][j] = temp;
                    _tblock.minersByValue[k][j] = temp2;
                }
            }
            Request storage _request = requestDetails[_requestIds[k]];
            //Save the official(finalValue), timestamp of it, 5 miners and their submitted values for it, and its block number
            a = _tblock.valuesByTimestamp[k];
            _request.finalValues[_timeOfLastNewValueVar] = a[2];
            b[k] = a[2];
            _request.minersByValue[_timeOfLastNewValueVar] = _tblock
                .minersByValue[k];
            _request.valuesByTimestamp[_timeOfLastNewValueVar] = _tblock
                .valuesByTimestamp[k];
            delete _tblock.minersByValue[k];
            delete _tblock.valuesByTimestamp[k];
            _request.requestTimestamps.push(_timeOfLastNewValueVar);
            _request.minedBlockNum[_timeOfLastNewValueVar] = block.number;
            _request.apiUintVars[_TOTAL_TIP] = 0;
        }
        emit NewValue(
            _requestIds,
            _timeOfLastNewValueVar,
            b,
            uints[_CURRENT_TOTAL_TIPS],
            _currChallenge
        );
        //add timeOfLastValue to the newValueTimestamps array
        newValueTimestamps.push(_timeOfLastNewValueVar);
        address[5] memory miners =
            requestDetails[_requestIds[0]].minersByValue[
                _timeOfLastNewValueVar
            ];
        //pay Miners Rewards
        _payReward(miners, _previousTime);
        uints[_T_BLOCK]++;
        uint256[5] memory _topId = _getTopRequestIDs();
        for (uint256 i = 0; i < 5; i++) {
            currentMiners[i].value = _topId[i];
            requestQ[
                requestDetails[_topId[i]].apiUintVars[_REQUEST_Q_POSITION]
            ] = 0;
            uints[_CURRENT_TOTAL_TIPS] += requestDetails[_topId[i]].apiUintVars[
                _TOTAL_TIP
            ];
        }
        _currChallenge = keccak256(
            abi.encode(_nonce, _currChallenge, blockhash(block.number - 1))
        );
        bytesVars[_CURRENT_CHALLENGE] = _currChallenge; // Save hash for next proof
        emit NewChallenge(
            _currChallenge,
            _topId,
            uints[_DIFFICULTY],
            uints[_CURRENT_TOTAL_TIPS]
        );
    }

    /**
     * @dev This is an internal function used by submitMiningSolution to
     * calculate and pay rewards to miners
     * @param miners are the 5 miners to reward
     * @param _previousTime is the previous mine time based on the 4th entry
    */
    function _payReward(address[5] memory miners, uint256 _previousTime)
        internal
    {
        //_timeDiff is how many seconds passed since last block
        uint256 _timeDiff = block.timestamp - _previousTime;
        uint256 reward = (_timeDiff * uints[_CURRENT_REWARD]) / 300;
        uint256 _tip = uints[_CURRENT_TOTAL_TIPS] / 10;
        uint256 _devShare = reward / 2;
        _doMint(miners[0], reward + _tip);
        _doMint(miners[1], reward + _tip);
        _doMint(miners[2], reward + _tip);
        _doMint(miners[3], reward + _tip);
        _doMint(miners[4], reward + _tip);
        _doMint(addresses[_OWNER], _devShare);
        uints[_CURRENT_TOTAL_TIPS] = 0;
    }

    /**
     * @dev This is an internal function used by submitMiningSolution to  allow miners to submit
     * their mining solution and data requested. It checks the miner is staked, has not
     * won in the last 15 min, and checks they are submitting all the correct requestids
     * @param _nonce is the mining solution
     * @param _requestIds are the 5 request ids being mined
     * @param _values are the 5 values corresponding to the 5 request ids
    */
    function _submitMiningSolution(
        string memory _nonce,
        uint256[5] memory _requestIds,
        uint256[5] memory _values
    ) internal {
        bytes32 _hashMsgSender = keccak256(abi.encode(msg.sender));
        require(
            stakerDetails[msg.sender].currentStatus == 1,
            "Miner status is not staker"
        );
        require(
            _requestIds[0] == currentMiners[0].value,
            "Request ID is wrong"
        );
        require(
            _requestIds[1] == currentMiners[1].value,
            "Request ID is wrong"
        );
        require(
            _requestIds[2] == currentMiners[2].value,
            "Request ID is wrong"
        );
        require(
            _requestIds[3] == currentMiners[3].value,
            "Request ID is wrong"
        );
        require(
            _requestIds[4] == currentMiners[4].value,
            "Request ID is wrong"
        );
        uints[_hashMsgSender] = block.timestamp;
        bytes32 _currChallenge = bytesVars[_CURRENT_CHALLENGE];
        uint256 _slotP = uints[_SLOT_PROGRESS];
        //Checking and updating Miner Status
        require(
            minersByChallenge[_currChallenge][msg.sender] == false,
            "Miner already submitted the value"
        );
        //Update the miner status to true once they submit a value so they don't submit more than once
        minersByChallenge[_currChallenge][msg.sender] = true;
        //Updating Request
        Request storage _tblock = requestDetails[uints[_T_BLOCK]];
        //Assigning directly is cheaper than using a for loop
        _tblock.valuesByTimestamp[0][_slotP] = _values[0];
        _tblock.valuesByTimestamp[1][_slotP] = _values[1];
        _tblock.valuesByTimestamp[2][_slotP] = _values[2];
        _tblock.valuesByTimestamp[3][_slotP] = _values[3];
        _tblock.valuesByTimestamp[4][_slotP] = _values[4];
        _tblock.minersByValue[0][_slotP] = msg.sender;
        _tblock.minersByValue[1][_slotP] = msg.sender;
        _tblock.minersByValue[2][_slotP] = msg.sender;
        _tblock.minersByValue[3][_slotP] = msg.sender;
        _tblock.minersByValue[4][_slotP] = msg.sender;
        if (_slotP + 1 == 4) {
            _adjustDifficulty();
        }
        emit NonceSubmitted(
            msg.sender,
            _nonce,
            _requestIds,
            _values,
            _currChallenge,
            _slotP
        );
        if (_slotP + 1 == 5) {
            //slotProgress has been incremented, but we're using the variable on stack to save gas
            _newBlock(_nonce, _requestIds);
            uints[_SLOT_PROGRESS] = 0;
        } else {
            uints[_SLOT_PROGRESS]++;
        }
    }

    /**
     * @dev This function updates the requestQ when addTip are ran
     * @param _requestId being requested
     * @param _tip is the tip to add
    */
    function _updateOnDeck(uint256 _requestId, uint256 _tip) internal {
        Request storage _request = requestDetails[_requestId];
        _request.apiUintVars[_TOTAL_TIP] = _request.apiUintVars[_TOTAL_TIP].add(
            _tip
        );
        if (
            currentMiners[0].value == _requestId ||
            currentMiners[1].value == _requestId ||
            currentMiners[2].value == _requestId ||
            currentMiners[3].value == _requestId ||
            currentMiners[4].value == _requestId
        ) {
            uints[_CURRENT_TOTAL_TIPS] += _tip;
        } else {
            // if the request is not part of the requestQ[51] array
            // then add to the requestQ[51] only if the _payout/tip is greater than the minimum(tip) in the requestQ[51] array
            if (_request.apiUintVars[_REQUEST_Q_POSITION] == 0) {
                uint256 _min;
                uint256 _index;
                (_min, _index) = _getMin(requestQ);
                //we have to zero out the oldOne
                //if the _payout is greater than the current minimum payout in the requestQ[51] or if the minimum is zero
                //then add it to the requestQ array and map its index information to the requestId and the apiUintVars
                if (_request.apiUintVars[_TOTAL_TIP] > _min || _min == 0) {
                    requestQ[_index] = _request.apiUintVars[_TOTAL_TIP];
                    requestDetails[requestIdByRequestQIndex[_index]]
                        .apiUintVars[_REQUEST_Q_POSITION] = 0;
                    requestIdByRequestQIndex[_index] = _requestId;
                    _request.apiUintVars[_REQUEST_Q_POSITION] = _index;
                }
                // else if the requestId is part of the requestQ[51] then update the tip for it
            } else {
                requestQ[_request.apiUintVars[_REQUEST_Q_POSITION]] += _tip;
            }
        }
    }

    /**
     * @dev This is an internal function used by submitMiningSolution to allows miners to submit
     * their mining solution and data requested. It checks the miner has submitted a
     * valid nonce or allows any solution if 15 minutes or more have passed since last
     * mined values
     * @param _nonce is the mining solution
    */
    function _verifyNonce(string memory _nonce) internal view {
        require(
            uint256(
                sha256(
                    abi.encodePacked(
                        ripemd160(
                            abi.encodePacked(
                                keccak256(
                                    abi.encodePacked(
                                        bytesVars[_CURRENT_CHALLENGE],
                                        msg.sender,
                                        _nonce
                                    )
                                )
                            )
                        )
                    )
                )
            ) %
                uints[_DIFFICULTY] ==
                0 ||
                block.timestamp - uints[_TIME_OF_LAST_NEW_VALUE] >= 15 minutes,
            "Incorrect nonce for current challenge"
        );
    }

    /**
     * @dev The tellor logic does not fit in one contract so it has been split into two:
     * Tellor and TellorGetters This functions helps delegate calls to the TellorGetters
     * contract.
    */
    fallback() external {
        address addr = extensionAddress;
        (bool result, ) =  addr.delegatecall(msg.data);
        assembly {
            returndatacopy(0, 0, returndatasize())
            switch result
                // delegatecall returns 0 on error.
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

import "./TellorTransfer.sol";
import "./TellorGetters.sol";
import "./Extension.sol";
import "./Utilities.sol";

/**
 @author Tellor Inc.
 @title TellorStake
 @dev Contains the methods related to initiating disputes and
 * voting on them.
 * Because of space limitations some functions are currently on the Extensions contract
*/
contract TellorStake is TellorTransfer {
    using SafeMath for uint256;
    using SafeMath for int256;

    //this belongs to Tellor, not to master
    uint256 private constant CURRENT_VERSION = 2999;

    //emitted when a new dispute is initialized
    event NewDispute(
        uint256 indexed _disputeId,
        uint256 indexed _requestId,
        uint256 _timestamp,
        address _miner
    );
    //emitted when a new vote happens
    event Voted(
        uint256 indexed _disputeID,
        bool _position,
        address indexed _voter,
        uint256 indexed _voteWeight
    );

    /**
     * @dev Helps initialize a dispute by assigning it a disputeId
     * when a miner returns a false/bad value on the validate array(in Tellor.ProofOfWork) it sends the
     * invalidated value information to POS voting
     * @param _requestId being disputed
     * @param _timestamp being disputed
     * @param _minerIndex the index of the miner that submitted the value being disputed. Since each official value
     * requires 5 miners to submit a value.
     */
    function beginDispute(
        uint256 _requestId,
        uint256 _timestamp,
        uint256 _minerIndex
    ) external {
        Request storage _request = requestDetails[_requestId];
        require(_request.minedBlockNum[_timestamp] != 0, "Mined block is 0");
        require(_minerIndex < 5, "Miner index is wrong");
        //_miner is the miner being disputed. For every mined value 5 miners are saved in an array and the _minerIndex
        //provided by the party initiating the dispute
        address _miner = _request.minersByValue[_timestamp][_minerIndex];
        uints[keccak256(abi.encodePacked(_miner,"DisputeCount"))]++;
        bytes32 _hash =
            keccak256(abi.encodePacked(_miner, _requestId, _timestamp));
        //Increase the dispute count by 1
        uints[_DISPUTE_COUNT]++;
        uint256 disputeId = uints[_DISPUTE_COUNT];
        //Ensures that a dispute is not already open for the that miner, requestId and timestamp
        uint256 hashId = disputeIdByDisputeHash[_hash];
        if (hashId != 0) {
            disputesById[disputeId].disputeUintVars[_ORIGINAL_ID] = hashId;
        } else {
            require(block.timestamp - _timestamp < 7 days, "Dispute must be started within a week of bad value");
            disputeIdByDisputeHash[_hash] = disputeId;
            hashId = disputeId;
        }
        uint256 dispRounds = _updateLastId(disputeId,hashId);
        uint256 _fee;
        if (_minerIndex == 2) {
            requestDetails[_requestId].apiUintVars[_DISPUTE_COUNT] =
                requestDetails[_requestId].apiUintVars[_DISPUTE_COUNT] +
                1;
            //update dispute fee for this case
            _fee =
                uints[_STAKE_AMOUNT] *
                requestDetails[_requestId].apiUintVars[_DISPUTE_COUNT];
        } else {
            _fee = uints[_DISPUTE_FEE] * dispRounds;
        }
        //maps the dispute to the Dispute struct
        disputesById[disputeId].hash = _hash;
        disputesById[disputeId].isPropFork = false;
        disputesById[disputeId].reportedMiner = _miner;
        disputesById[disputeId].reportingParty = msg.sender;
        disputesById[disputeId].proposedForkAddress = address(0);
        disputesById[disputeId].executed = false;
        disputesById[disputeId].disputeVotePassed = false;
        disputesById[disputeId].tally = 0;
        //Saves all the dispute variables for the disputeId
        disputesById[disputeId].disputeUintVars[_REQUEST_ID] = _requestId;
        disputesById[disputeId].disputeUintVars[_TIMESTAMP] = _timestamp;
        disputesById[disputeId].disputeUintVars[_VALUE] = _request
            .valuesByTimestamp[_timestamp][_minerIndex];
        disputesById[disputeId].disputeUintVars[_MIN_EXECUTION_DATE] =
            block.timestamp +
            2 days *
            dispRounds;
        disputesById[disputeId].disputeUintVars[_BLOCK_NUMBER] = block.number;
        disputesById[disputeId].disputeUintVars[_MINER_SLOT] = _minerIndex;
        disputesById[disputeId].disputeUintVars[_FEE] = _fee;
        _doTransfer(msg.sender, address(this), _fee);
        //Values are sorted as they come in and the official value is the median of the first five
        //So the "official value" miner is always minerIndex==2. If the official value is being
        //disputed, it sets its status to inDispute(currentStatus = 3) so that users are made aware it is under dispute
        if (_minerIndex == 2) {
            _request.inDispute[_timestamp] = true;
            _request.finalValues[_timestamp] = 0;
        }
        stakerDetails[_miner].currentStatus = 3;
        emit NewDispute(disputeId, _requestId, _timestamp, _miner);
    }

    /**
     * @dev Allows for a fork to be proposed
     * @param _propNewTellorAddress address for new proposed Tellor
    */
    function proposeFork(address _propNewTellorAddress) external {
        require(uints[_LOCK] == 0, "no rentrancy");
        uints[_LOCK] = 1;
        _verify(_propNewTellorAddress);
        uints[_LOCK] = 0;
        bytes32 _hash = keccak256(abi.encode(_propNewTellorAddress));
        uints[_DISPUTE_COUNT]++;
        uint256 disputeId = uints[_DISPUTE_COUNT];
        if (disputeIdByDisputeHash[_hash] != 0) {
            disputesById[disputeId].disputeUintVars[
                _ORIGINAL_ID
            ] = disputeIdByDisputeHash[_hash];
        } else {
            disputeIdByDisputeHash[_hash] = disputeId;
        }
        uint256 dispRounds = _updateLastId(disputeId,disputeIdByDisputeHash[_hash]);
        disputesById[disputeId].hash = _hash;
        disputesById[disputeId].isPropFork = true;
        // I don't think we need those
        disputesById[disputeId].reportedMiner = msg.sender;
        disputesById[disputeId].reportingParty = msg.sender;
        disputesById[disputeId].proposedForkAddress = _propNewTellorAddress;
        disputesById[disputeId].tally = 0;
        _doTransfer(msg.sender, address(this), 100e18 * 2**(dispRounds - 1)); //This is the fork fee (just 100 tokens flat, no refunds.  Goes up quickly to dispute a bad vote)
        disputesById[disputeId].disputeUintVars[_BLOCK_NUMBER] = block.number;
        disputesById[disputeId].disputeUintVars[_MIN_EXECUTION_DATE] =
            block.timestamp +
            7 days;
    }

    /**
     * @dev Allows disputer to unlock the dispute fee
     * @param _disputeId to unlock fee from
    */
    function unlockDisputeFee(uint256 _disputeId) external {
        require(_disputeId <= uints[_DISPUTE_COUNT], "dispute does not exist");
        uint256 origID = disputeIdByDisputeHash[disputesById[_disputeId].hash];
        uint256 lastID =
            disputesById[origID].disputeUintVars[
                keccak256(
                    abi.encode(
                        disputesById[origID].disputeUintVars[_DISPUTE_ROUNDS]
                    )
                )
            ];
        if (lastID == 0) {
            lastID = origID;
        }
        Dispute storage disp = disputesById[origID];
        Dispute storage last = disputesById[lastID];
        //disputeRounds is increased by 1 so that the _id is not a negative number when it is the first time a dispute is initiated
        uint256 dispRounds = disp.disputeUintVars[_DISPUTE_ROUNDS];
        if (dispRounds == 0) {
            dispRounds = 1;
        }
        uint256 _id;
        require(disp.disputeUintVars[_PAID] == 0, "already paid out");
        require(!disp.isPropFork, "function not callable fork fork proposals");
        require(disp.disputeUintVars[_TALLY_DATE] > 0, "vote needs to be tallied");
        require(
            block.timestamp - last.disputeUintVars[_TALLY_DATE] > 1 days,
            "Time for a follow up dispute hasn't elapsed"
        );
        StakeInfo storage stakes = stakerDetails[disp.reportedMiner];
        disp.disputeUintVars[_PAID] = 1;
        if (last.disputeVotePassed == true) {
            //Changing the currentStatus and startDate unstakes the reported miner and transfers the stakeAmount
            stakes.startDate = block.timestamp - (block.timestamp % 86400);
            //Reduce the staker count
            uints[_STAKE_COUNT] -= 1;
            //Decreases the stakerCount since the miner's stake is being slashed
            uint256 _transferAmount = uints[_STAKE_AMOUNT];
            if(balanceOf(disp.reportedMiner)  < uints[_STAKE_AMOUNT]){
                _transferAmount = balanceOf(disp.reportedMiner);
            }
            if (stakes.currentStatus == 4) {
                stakes.currentStatus = 5;
                _doTransfer(
                    disp.reportedMiner,
                    disp.reportingParty,
                    _transferAmount
                );
                stakes.currentStatus = 0;
            }
            for (uint256 i = 0; i < dispRounds; i++) {
                _id = disp.disputeUintVars[
                    keccak256(abi.encode(dispRounds - i))
                ];
                if (_id == 0) {
                    _id = origID;
                }
                Dispute storage disp2 = disputesById[_id];
                //transfer fee adjusted based on number of miners if the minerIndex is not 2(official value)
                _doTransfer(
                    address(this),
                    disp2.reportingParty,
                    disp2.disputeUintVars[_FEE]
                );
            }
        } else {
            if(uints[keccak256(abi.encodePacked(last.reportedMiner,"DisputeCount"))] == 1){
                stakes.currentStatus = 1;
            }
            TellorStorage.Request storage _request =
                requestDetails[disp.disputeUintVars[_REQUEST_ID]];
            if (disp.disputeUintVars[_MINER_SLOT] == 2) {
                //note we still don't put timestamp back into array (is this an issue? (shouldn't be))
                _request.finalValues[disp.disputeUintVars[_TIMESTAMP]] = disp
                    .disputeUintVars[_VALUE];
            }
            if (_request.inDispute[disp.disputeUintVars[_TIMESTAMP]] == true) {
                _request.inDispute[disp.disputeUintVars[_TIMESTAMP]] = false;
            }
            for (uint256 i = 0; i < dispRounds; i++) {
                _id = disp.disputeUintVars[
                    keccak256(abi.encode(dispRounds - i))
                ];
                if (_id != 0) {
                    last = disputesById[_id]; //handling if happens during an upgrade
                }
                _doTransfer(
                    address(this),
                    last.reportedMiner,
                    disputesById[_id].disputeUintVars[_FEE]
                );
            }
        }
        uints[keccak256(abi.encodePacked(last.reportedMiner,"DisputeCount"))]--;
        if (disp.disputeUintVars[_MINER_SLOT] == 2) {
            requestDetails[disp.disputeUintVars[_REQUEST_ID]].apiUintVars[
                _DISPUTE_COUNT
            ]--;
        }
    }

    /**
     * @dev Used during upgrade process to verify valid Tellor Contract
    */
    function verify() external virtual returns (uint256) {
        return CURRENT_VERSION;
    }

    /**
     * @dev Allows token holders to vote
     * @param _disputeId is the dispute id
     * @param _supportsDispute is the vote (true=the dispute has basis false = vote against dispute)
    */
    function vote(uint256 _disputeId, bool _supportsDispute) external {
        require(_disputeId <= uints[_DISPUTE_COUNT], "dispute does not exist");
        Dispute storage disp = disputesById[_disputeId];
        require(!disp.executed, "the dispute has already been executed");
        //Get the voteWeight or the balance of the user at the time/blockNumber the dispute began
        uint256 voteWeight = balanceOfAt(msg.sender, disp.disputeUintVars[_BLOCK_NUMBER]);
        //Require that the msg.sender has not voted
        require(disp.voted[msg.sender] != true, "Sender has already voted");
        //Require that the user had a balance >0 at time/blockNumber the dispute began
        require(voteWeight != 0, "User balance is 0");
        //ensures miners that are under dispute cannot vote
        require(
            stakerDetails[msg.sender].currentStatus != 3,
            "Miner is under dispute"
        );
        //Update user voting status to true
        disp.voted[msg.sender] = true;
        //Update the number of votes for the dispute
        disp.disputeUintVars[_NUM_OF_VOTES] += 1;
        //If the user supports the dispute increase the tally for the dispute by the voteWeight
        //otherwise decrease it
        if (_supportsDispute) {
            disp.tally = disp.tally.add(int256(voteWeight));
        } else {
            disp.tally = disp.tally.sub(int256(voteWeight));
        }
        //Let the network kblock.timestamp the user has voted on the dispute and their casted vote
        emit Voted(_disputeId, _supportsDispute, msg.sender, voteWeight);
    }

    /**
     * @dev Internal function with round checking logic from beginDispute/ proposeFork
     * @param _disputeId new dispute ID of round
     * @param _origId original ID of the hash
    */
    function _updateLastId(uint _disputeId,uint _origId) internal returns(uint256 _dispRounds){
        _dispRounds = disputesById[_origId].disputeUintVars[_DISPUTE_ROUNDS] + 1;
        disputesById[_origId].disputeUintVars[_DISPUTE_ROUNDS] = _dispRounds;
        disputesById[_origId].disputeUintVars[
            keccak256(abi.encode(_dispRounds))
        ] = _disputeId;
        if (_disputeId != _origId) {
            uint256 _lastId =
            disputesById[_origId].disputeUintVars[keccak256(abi.encode(_dispRounds - 1))];
            require(
                disputesById[_lastId].disputeUintVars[_MIN_EXECUTION_DATE] <=
                    block.timestamp,
                "Dispute is already open"
            );
            if (disputesById[_lastId].executed) {
                require(
                    block.timestamp - disputesById[_lastId].disputeUintVars[_TALLY_DATE] <=
                        1 days,
                    "Time for voting haven't elapsed"
                );
            }
        }
    }
    
    /**
     * @dev Used during upgrade process to verify valid Tellor Contract
    */
    function _verify(address _newTellor) internal {
        (bool success, bytes memory data) =
            address(_newTellor).call(
                abi.encodeWithSelector(0xfc735e99, "") //verify() signature
            );
        require(
            success && abi.decode(data, (uint256)) > CURRENT_VERSION, //we could enforce versioning through this return value, but we're almost in the size limit.
            "new tellor is invalid"
        );
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;
import "./SafeMath.sol";
import "./TellorStorage.sol";
import "./TellorVariables.sol";
import "./Utilities.sol";

/**
 @author Tellor Inc.
 @title TellorGetters
 @dev Getter functions for Tellor Oracle system
*/
contract TellorGetters is TellorStorage, TellorVariables, Utilities {
    using SafeMath for uint256;

    /**
     * @dev This function tells you if a given challenge has been completed by a given miner
     * @param _challenge the challenge to search for
     * @param _miner address that you want to know if they solved the challenge
     * @return true if the _miner address provided solved the
     */
    function didMine(bytes32 _challenge, address _miner)
        external
        view
        returns (bool)
    {
        return minersByChallenge[_challenge][_miner];
    }

    /**
     * @dev Checks if an address voted in a given dispute
     * @param _disputeId to look up
     * @param _address to look up
     * @return bool of whether or not party voted
     */
    function didVote(uint256 _disputeId, address _address)
        external
        view
        returns (bool)
    {
        return disputesById[_disputeId].voted[_address];
    }

    /**
     * @dev allows Tellor to read data from the addressVars mapping
     * @param _data is the keccak256("variable_name") of the variable that is being accessed.
     * These are examples of how the variables are saved within other functions:
     * addressVars[keccak256("_owner")]
     * addressVars[keccak256("tellorContract")]
     * @return address of the requested variable
     */
    function getAddressVars(bytes32 _data) external view returns (address) {
        return addresses[_data];
    }

    /**
     * @dev Gets all dispute variables
     * @param _disputeId to look up
     * @return bytes32 hash of dispute
     * bool executed where true if it has been voted on
     * bool disputeVotePassed
     * bool isPropFork true if the dispute is a proposed fork
     * address of reportedMiner
     * address of reportingParty
     * address of proposedForkAddress
     * uint of requestId
     * uint of timestamp
     * uint of value
     * uint of minExecutionDate
     * uint of numberOfVotes
     * uint of blocknumber
     * uint of minerSlot
     * uint of quorum
     * uint of fee
     * int count of the current tally
     */
    function getAllDisputeVars(uint256 _disputeId)
        external
        view
        returns (
            bytes32,
            bool,
            bool,
            bool,
            address,
            address,
            address,
            uint256[9] memory,
            int256
        )
    {
        Dispute storage disp = disputesById[_disputeId];
        return (
            disp.hash,
            disp.executed,
            disp.disputeVotePassed,
            disp.isPropFork,
            disp.reportedMiner,
            disp.reportingParty,
            disp.proposedForkAddress,
            [
                disp.disputeUintVars[_REQUEST_ID],
                disp.disputeUintVars[_TIMESTAMP],
                disp.disputeUintVars[_VALUE],
                disp.disputeUintVars[_MIN_EXECUTION_DATE],
                disp.disputeUintVars[_NUM_OF_VOTES],
                disp.disputeUintVars[_BLOCK_NUMBER],
                disp.disputeUintVars[_MINER_SLOT],
                disp.disputeUintVars[keccak256("quorum")],
                disp.disputeUintVars[_FEE]
            ],
            disp.tally
        );
    }

    /**
     * @dev Checks if a given hash of miner,requestId has been disputed
     * @param _hash is the sha256(abi.encodePacked(_miners[2],_requestId,_timestamp));
     * @return uint disputeId
     */
    function getDisputeIdByDisputeHash(bytes32 _hash)
        external
        view
        returns (uint256)
    {
        return disputeIdByDisputeHash[_hash];
    }

    /**
     * @dev Checks for uint variables in the disputeUintVars mapping based on the disputeId
     * @param _disputeId is the dispute id;
     * @param _data the variable to pull from the mapping. _data = keccak256("variable_name") where variable_name is
     * the variables/strings used to save the data in the mapping. The variables names are
     * commented out under the disputeUintVars under the Dispute struct
     * @return uint value for the bytes32 data submitted
     */
    function getDisputeUintVars(uint256 _disputeId, bytes32 _data)
        external
        view
        returns (uint256)
    {
        return disputesById[_disputeId].disputeUintVars[_data];
    }

    /**
     * @dev Gets the a value for the latest timestamp available
     * @param _requestId being requested
     * @return value for timestamp of last proof of work submitted and if true if it exist or 0 and false if it doesn't
     */
    function getLastNewValueById(uint256 _requestId)
        external
        view
        returns (uint256, bool)
    {
        Request storage _request = requestDetails[_requestId];
        if (_request.requestTimestamps.length != 0) {
            return (
                retrieveData(
                    _requestId,
                    _request.requestTimestamps[
                        _request.requestTimestamps.length - 1
                    ]
                ),
                true
            );
        } else {
            return (0, false);
        }
    }

    /**
     * @dev Gets blocknumber for mined timestamp
     * @param _requestId to look up
     * @param _timestamp is the timestamp to look up blocknumber
     * @return uint of the blocknumber which the dispute was mined
     */
    function getMinedBlockNum(uint256 _requestId, uint256 _timestamp)
        external
        view
        returns (uint256)
    {
        return requestDetails[_requestId].minedBlockNum[_timestamp];
    }

    /**
     * @dev Gets the 5 miners who mined the value for the specified requestId/_timestamp
     * @param _requestId to look up
     * @param _timestamp is the timestamp to look up miners for
     * @return the 5 miners' addresses
     */
    function getMinersByRequestIdAndTimestamp(
        uint256 _requestId,
        uint256 _timestamp
    ) external view returns (address[5] memory) {
        return requestDetails[_requestId].minersByValue[_timestamp];
    }

    /**
     * @dev Counts the number of values that have been submitted for the request
     * if called for the currentRequest being mined it can tell you how many miners have submitted a value for that
     * request so far
     * @param _requestId the requestId to look up
     * @return uint count of the number of values received for the requestId
     */
    function getNewValueCountbyRequestId(uint256 _requestId)
        external
        view
        returns (uint256)
    {
        return requestDetails[_requestId].requestTimestamps.length;
    }

    /**
     * @dev Getter function for the specified requestQ index
     * @param _index to look up in the requestQ array
     * @return uint of requestId
     */
    function getRequestIdByRequestQIndex(uint256 _index)
        external
        view
        returns (uint256)
    {
        require(_index <= 50, "RequestQ index is above 50");
        return requestIdByRequestQIndex[_index];
    }

    /**
     * @dev Getter function for the requestQ array
     * @return the requestQ array
     */
    function getRequestQ() external view returns (uint256[51] memory) {
        return requestQ;
    }

    /**
     * @dev Allows access to the uint variables saved in the apiUintVars under the requestDetails struct
     * for the requestId specified
     * @param _requestId to look up
     * @param _data the variable to pull from the mapping. _data = keccak256("variable_name") where variable_name is
     * the variables/strings used to save the data in the mapping. The variables names are
     * in TellorVariables.sol
     * @return uint value of the apiUintVars specified in _data for the requestId specified
     */
    function getRequestUintVars(uint256 _requestId, bytes32 _data)
        external
        view
        returns (uint256)
    {
        return requestDetails[_requestId].apiUintVars[_data];
    }

    /**
     * @dev Gets the API struct variables that are not mappings
     * @param _requestId to look up
     * @return uint of index in requestQ array
     * @return uint of current payout/tip for this requestId
     */
    function getRequestVars(uint256 _requestId)
        external
        view
        returns (uint256, uint256)
    {
        Request storage _request = requestDetails[_requestId];
        return (
            _request.apiUintVars[_REQUEST_Q_POSITION],
            _request.apiUintVars[_TOTAL_TIP]
        );
    }

    /**
     * @dev This function allows users to retrieve all information about a staker
     * @param _staker address of staker inquiring about
     * @return uint current state of staker
     * @return uint startDate of staking
     */
    function getStakerInfo(address _staker)
        external
        view
        returns (uint256, uint256)
    {
        return (
            stakerDetails[_staker].currentStatus,
            stakerDetails[_staker].startDate
        );
    }

    /**
     * @dev Gets the 5 miners who mined the value for the specified requestId/_timestamp
     * @param _requestId to look up
     * @param _timestamp is the timestamp to look up miners for
     * @return address[5] array of 5 addresses of miners that mined the requestId
     */
    function getSubmissionsByTimestamp(uint256 _requestId, uint256 _timestamp)
        external
        view
        returns (uint256[5] memory)
    {
        return requestDetails[_requestId].valuesByTimestamp[_timestamp];
    }

    /**
     * @dev Gets the timestamp for the value based on their index
     * @param _requestID is the requestId to look up
     * @param _index is the value index to look up
     * @return uint timestamp
     */
    function getTimestampbyRequestIDandIndex(uint256 _requestID, uint256 _index)
        external
        view
        returns (uint256)
    {
        return requestDetails[_requestID].requestTimestamps[_index];
    }

    /**
     * @dev Getter for the variables saved under the TellorStorageStruct uints variable
     * @param _data the variable to pull from the mapping. _data = keccak256("variable_name")
     * where variable_name is the variables/strings used to save the data in the mapping.
     * The variables names in the TellorVariables contract
     * @return uint of specified variable
     */
    function getUintVar(bytes32 _data) external view returns (uint256) {
        return uints[_data];
    }

    /**
     * @dev Gets the 5 miners who mined the value for the specified requestId/_timestamp
     * @param _requestId to look up
     * @param _timestamp is the timestamp to look up miners for
     * @return bool true if requestId/timestamp is under dispute
     */
    function isInDispute(uint256 _requestId, uint256 _timestamp)
        external
        view
        returns (bool)
    {
        return requestDetails[_requestId].inDispute[_timestamp];
    }

    /**
     * @dev Retrieve value from oracle based on timestamp
     * @param _requestId being requested
     * @param _timestamp to retrieve data/value from
     * @return value for timestamp submitted
     */
    function retrieveData(uint256 _requestId, uint256 _timestamp)
        public
        view
        returns (uint256)
    {
        return requestDetails[_requestId].finalValues[_timestamp];
    }

    /**
     * @dev Getter for the total_supply of oracle tokens
     * @return uint total supply
     */
    function totalSupply() external view returns (uint256) {
        return uints[_TOTAL_SUPPLY];
    }

    /**
     * @dev Allows users to access the token's name
     */
    function name() external pure returns (string memory) {
        return "Tellor Tributes";
    }

    /**
     * @dev Allows users to access the token's symbol
     */
    function symbol() external pure returns (string memory) {
        return "TRB";
    }

    /**
     * @dev Allows users to access the number of decimals
     */
    function decimals() external pure returns (uint8) {
        return 18;
    }

    /**
     * @dev Getter function for the requestId being mined
     * returns the currentChallenge, array of requestIDs, difficulty, and the current Tip of the 5 IDs
     */
    function getNewCurrentVariables()
        external
        view
        returns (
            bytes32 _challenge,
            uint256[5] memory _requestIds,
            uint256 _diff,
            uint256 _tip
        )
    {
        for (uint256 i = 0; i < 5; i++) {
            _requestIds[i] = currentMiners[i].value;
        }
        return (
            bytesVars[_CURRENT_CHALLENGE],
            _requestIds,
            uints[_DIFFICULTY],
            uints[_CURRENT_TOTAL_TIPS]
        );
    }

    /**
     * @dev Getter function for next requestIds on queue/request with highest payouts at time the function is called
     */
    function getNewVariablesOnDeck()
        external
        view
        returns (uint256[5] memory idsOnDeck, uint256[5] memory tipsOnDeck)
    {
        idsOnDeck = getTopRequestIDs();
        for (uint256 i = 0; i < 5; i++) {
            tipsOnDeck[i] = requestDetails[idsOnDeck[i]].apiUintVars[
                _TOTAL_TIP
            ];
        }
    }

    /**
     * @dev Getter function for the top 5 requests with highest payouts. This function is used within the getNewVariablesOnDeck function
     */
    function getTopRequestIDs()
        public
        view
        returns (uint256[5] memory _requestIds)
    {
        uint256[5] memory _max;
        uint256[5] memory _index;
        (_max, _index) = _getMax5(requestQ);
        for (uint256 i = 0; i < 5; i++) {
            if (_max[i] != 0) {
                _requestIds[i] = requestIdByRequestQIndex[_index[i]];
            } else {
                _requestIds[i] = currentMiners[4 - i].value;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

/**
 @author Tellor Inc.
 @title Utilities
 @dev Functions for retrieving min and Max in 51 length array (requestQ)
 *Taken partly from: https://github.com/modular-network/ethereum-libraries-array-utils/blob/master/contracts/Array256Lib.sol
*/
contract Utilities {
    /**
     * @dev This is an internal function called by updateOnDeck that gets the top 5 values
     * @param data is an array [51] to determine the top 5 values from
     * @return max the top 5 values and their index values in the data array
     */
    function _getMax5(uint256[51] memory data)
        internal
        pure
        returns (uint256[5] memory max, uint256[5] memory maxIndex)
    {
        uint256 min5 = data[1];
        uint256 minI = 0;
        for (uint256 j = 0; j < 5; j++) {
            max[j] = data[j + 1]; //max[0]=data[1]
            maxIndex[j] = j + 1; //maxIndex[0]= 1
            if (max[j] < min5) {
                min5 = max[j];
                minI = j;
            }
        }
        for (uint256 i = 6; i < data.length; i++) {
            if (data[i] > min5) {
                max[minI] = data[i];
                maxIndex[minI] = i;
                min5 = data[i];
                for (uint256 j = 0; j < 5; j++) {
                    if (max[j] < min5) {
                        min5 = max[j];
                        minI = j;
                    }
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

/** 
 @author Tellor Inc.
 @title ITellor
 @dev  This contract holds the interface for all Tellor functions
**/
interface ITellor {
    /*Events*/
    event NewTellorAddress(address _newTellor);
    event NewDispute(
        uint256 indexed _disputeId,
        uint256 indexed _requestId,
        uint256 _timestamp,
        address _miner
    );
    event Voted(
        uint256 indexed _disputeID,
        bool _position,
        address indexed _voter,
        uint256 indexed _voteWeight
    );
    event DisputeVoteTallied(
        uint256 indexed _disputeID,
        int256 _result,
        address indexed _reportedMiner,
        address _reportingParty,
        bool _passed
    );
    event TipAdded(
        address indexed _sender,
        uint256 indexed _requestId,
        uint256 _tip,
        uint256 _totalTips
    );
    event NewChallenge(
        bytes32 indexed _currentChallenge,
        uint256[5] _currentRequestId,
        uint256 _difficulty,
        uint256 _totalTips
    );
    event NewValue(
        uint256[5] _requestId,
        uint256 _time,
        uint256[5] _value,
        uint256 _totalTips,
        bytes32 indexed _currentChallenge
    );
    event NonceSubmitted(
        address indexed _miner,
        string _nonce,
        uint256[5] _requestId,
        uint256[5] _value,
        bytes32 indexed _currentChallenge,
        uint256 _slot
    );
    event NewStake(address indexed _sender); //Emits upon new staker
    event StakeWithdrawn(address indexed _sender); //Emits when a staker is now no longer staked
    event StakeWithdrawRequested(address indexed _sender); //Emits when a staker begins the 7 day withdraw period
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
    event Transfer(address indexed _from, address indexed _to, uint256 _value); //ERC20 Transfer Event

    /*Functions -- master*/
    function changeDeity(address _newDeity) external;
    function changeOwner(address _newOwner) external;
    function changeTellorContract(address _tellorContract) external;
    /*Functions -- Extension*/
    function depositStake() external;
    function requestStakingWithdraw() external;
    function tallyVotes(uint256 _disputeId) external;
    function updateMinDisputeFee() external;
    function updateTellor(uint256 _disputeId) external;
    function withdrawStake() external;
    /*Functions -- Tellor*/
    function addTip(uint256 _requestId, uint256 _tip) external;
    function changeExtension(address _extension) external;
    function changeMigrator(address _migrator) external;
    function migrate() external;
    function migrateFor(
        address _destination,
        uint256 _amount,
        bool _bypass
    ) external;
    function migrateForBatch(
        address[] calldata _destination,
        uint256[] calldata _amount
    ) external;
    function migrateFrom(
        address _origin,
        address _destination,
        uint256 _amount,
        bool _bypass
    ) external;
    function migrateFromBatch(
        address[] calldata _origin,
        address[] calldata _destination,
        uint256[] calldata _amount
    ) external;
    function submitMiningSolution(
        string calldata _nonce,
        uint256[5] calldata _requestIds,
        uint256[5] calldata _values
    ) external;
    /*Functions -- TellorGetters*/
    function didMine(bytes32 _challenge, address _miner)
        external
        view
        returns (bool);
    function didVote(uint256 _disputeId, address _address)
        external
        view
        returns (bool);
    function getAddressVars(bytes32 _data) external view returns (address);
    function getAllDisputeVars(uint256 _disputeId)
        external
        view
        returns (
            bytes32,
            bool,
            bool,
            bool,
            address,
            address,
            address,
            uint256[9] memory,
            int256
        );
    function getDisputeIdByDisputeHash(bytes32 _hash)
        external
        view
        returns (uint256);
    function getDisputeUintVars(uint256 _disputeId, bytes32 _data)
        external
        view
        returns (uint256);
    function getLastNewValue() external view returns (uint256, bool);
    function getLastNewValueById(uint256 _requestId)
        external
        view
        returns (uint256, bool);
    function getMinedBlockNum(uint256 _requestId, uint256 _timestamp)
        external
        view
        returns (uint256);
    function getMinersByRequestIdAndTimestamp(
        uint256 _requestId,
        uint256 _timestamp
    ) external view returns (address[5] memory);

    function getNewValueCountbyRequestId(uint256 _requestId)
        external
        view
        returns (uint256);
    function getRequestIdByRequestQIndex(uint256 _index)
        external
        view
        returns (uint256);
    function getRequestIdByTimestamp(uint256 _timestamp)
        external
        view
        returns (uint256);
    function getRequestQ() external view returns (uint256[51] memory);
    function getRequestUintVars(uint256 _requestId, bytes32 _data)
        external
        view
        returns (uint256);
    function getRequestVars(uint256 _requestId)
        external
        view
        returns (uint256, uint256);
    function getStakerInfo(address _staker)
        external
        view
        returns (uint256, uint256);
    function getSubmissionsByTimestamp(uint256 _requestId, uint256 _timestamp)
        external
        view
        returns (uint256[5] memory);
    function getTimestampbyRequestIDandIndex(uint256 _requestID, uint256 _index)
        external
        view
        returns (uint256);
    function getUintVar(bytes32 _data) external view returns (uint256);
    function isInDispute(uint256 _requestId, uint256 _timestamp)
        external
        view
        returns (bool);
    function retrieveData(uint256 _requestId, uint256 _timestamp)
        external
        view
        returns (uint256);
    function totalSupply() external view returns (uint256);
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function getNewCurrentVariables()
        external
        view
        returns (
            bytes32 _challenge,
            uint256[5] memory _requestIds,
            uint256 _difficulty,
            uint256 _tip
        );
    function getNewVariablesOnDeck()
        external
        view
        returns (uint256[5] memory idsOnDeck, uint256[5] memory tipsOnDeck
        );
    function getTopRequestIDs()
        external
        view
        returns (uint256[5] memory _requestIds);
    /*Functions -- TellorStake*/
    function beginDispute(
        uint256 _requestId,
        uint256 _timestamp,
        uint256 _minerIndex
    ) external;
    function proposeFork(address _propNewTellorAddress) external;
    function unlockDisputeFee(uint256 _disputeId) external;
    function verify() external returns (uint256);
    function vote(uint256 _disputeId, bool _supportsDispute) external;
    /*Functions -- TellorTransfer*/
    function approve(address _spender, uint256 _amount) external returns (bool);
    function allowance(address _user, address _spender)
        external
        view
        returns (uint256);
    function allowedToTrade(address _user, uint256 _amount)
        external
        view
        returns (bool);
    function balanceOf(address _user) external view returns (uint256);
    function balanceOfAt(address _user, uint256 _blockNumber)
        external
        view
        returns (uint256);
    function transfer(address _to, uint256 _amount) external returns (bool);
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) external returns (bool);
    //Test Functions
    function theLazyCoon(address _address, uint256 _amount) external;
    function testSubmitMiningSolution(
        string calldata _nonce,
        uint256[5] calldata _requestId,
        uint256[5] calldata _value
    ) external;
    function manuallySetDifficulty(uint256 _diff) external;
    function testgetMax5(uint256[51] memory requests)
        external
        view
        returns (uint256[5] memory _max, uint256[5] memory _index);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

/** 
 @author Tellor Inc.
 @title SafeMath
 @dev  Slightly modified SafeMath library - includes a min and max function, removes useless div function
**/
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function add(int256 a, int256 b) internal pure returns (int256 c) {
        if (b > 0) {
            c = a + b;
            assert(c >= a);
        } else {
            c = a + b;
            assert(c <= a);
        }
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    function max(int256 a, int256 b) internal pure returns (uint256) {
        return a > b ? uint256(a) : uint256(b);
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function sub(int256 a, int256 b) internal pure returns (int256 c) {
        if (b > 0) {
            c = a - b;
            assert(c <= a);
        } else {
            c = a - b;
            assert(c >= a);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

import "./SafeMath.sol";
import "./TellorStorage.sol";
import "./TellorVariables.sol";

/**
 @author Tellor Inc.
 @title TellorTransfer
 @dev Contains the methods related to transfers and ERC20, its storage and hashes of tellor variables
 * that are used to save gas on transactions.
*/
contract TellorTransfer is TellorStorage, TellorVariables {
    using SafeMath for uint256;

    /*Events*/
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    ); //ERC20 Approval event
    event Transfer(address indexed _from, address indexed _to, uint256 _value); //ERC20 Transfer Event

    /*Functions*/
    /**
     * @dev Getter function for remaining spender balance
     * @param _user address of party with the balance
     * @param _spender address of spender of parties said balance
     * @return Returns the remaining allowance of tokens granted to the _spender from the _user
    */
    function allowance(address _user, address _spender)
        public
        view
        returns (uint256)
    {
        return _allowances[_user][_spender];
    }

    /**
     * @dev This function returns whether or not a given user is allowed to trade a given amount
     * and removing the staked amount from their balance if they are staked
     * @param _user address of user
     * @param _amount to check if the user can spend
     * @return true if they are allowed to spend the amount being checked
    */
    function allowedToTrade(address _user, uint256 _amount)
        public
        view
        returns (bool)
    {
        if (
            stakerDetails[_user].currentStatus != 0 &&
            stakerDetails[_user].currentStatus < 5
        ) {
            //Subtracts the stakeAmount from balance if the _user is staked
            if (balanceOf(_user).sub(uints[_STAKE_AMOUNT]) >= _amount) {
                return true;
            }
            return false;
        }
        return (balanceOf(_user) >= _amount);
    }

    /**
     * @dev This function approves a _spender an _amount of tokens to use
     * @param _spender address
     * @param _amount amount the spender is being approved for
     * @return true if spender approved successfully
     */
    function approve(address _spender, uint256 _amount) public returns (bool) {
        require(_spender != address(0), "ERC20: approve to the zero address");

        _allowances[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    /**
     * @dev Gets balance of owner specified
     * @param _user is the owner address used to look up the balance
     * @return Returns the balance associated with the passed in _user
     */
    function balanceOf(address _user) public view returns (uint256) {
        return balanceOfAt(_user, block.number);
    }

    /**
     * @dev Queries the balance of _user at a specific _blockNumber
     * @param _user The address from which the balance will be retrieved
     * @param _blockNumber The block number when the balance is queried
     * @return The balance at _blockNumber specified
     */
    function balanceOfAt(address _user, uint256 _blockNumber)
        public
        view
        returns (uint256)
    {
        TellorStorage.Checkpoint[] storage checkpoints = balances[_user];
        if (
            checkpoints.length == 0 || checkpoints[0].fromBlock > _blockNumber
        ) {
            return 0;
        } else {
            if (_blockNumber >= checkpoints[checkpoints.length - 1].fromBlock)
                return checkpoints[checkpoints.length - 1].value;
            // Binary search of the value in the array
            uint256 min = 0;
            uint256 max = checkpoints.length - 2;
            while (max > min) {
                uint256 mid = (max + min + 1) / 2;
                if (checkpoints[mid].fromBlock == _blockNumber) {
                    return checkpoints[mid].value;
                } else if (checkpoints[mid].fromBlock < _blockNumber) {
                    min = mid;
                } else {
                    max = mid - 1;
                }
            }
            return checkpoints[min].value;
        }
    }

    /**
     * @dev Allows for a transfer of tokens to _to
     * @param _to The address to send tokens to
     * @param _amount The amount of tokens to send
     */
    function transfer(address _to, uint256 _amount)
        public
        returns (bool success)
    {
        _doTransfer(msg.sender, _to, _amount);
        return true;
    }

    /**
     * @notice Send _amount tokens to _to from _from on the condition it
     * is approved by _from
     * @param _from The address holding the tokens being transferred
     * @param _to The address of the recipient
     * @param _amount The amount of tokens to be transferred
    */
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public returns (bool success) {
        require(
            _allowances[_from][msg.sender] >= _amount,
            "Allowance is wrong"
        );
        _allowances[_from][msg.sender] -= _amount;
        _doTransfer(_from, _to, _amount);
        return true;
    }

    /*Internal Functions*/
    /**
     * @dev Completes transfers by updating the balances on the current block number
     * and ensuring the amount does not contain tokens staked for mining
     * @param _from address to transfer from
     * @param _to address to transfer to
     * @param _amount to transfer
    */
    function _doTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        require(_amount != 0, "Tried to send non-positive amount");
        require(_to != address(0), "Receiver is 0 address");
        require(
            allowedToTrade(_from, _amount),
            "Should have sufficient balance to trade"
        );
        uint128 previousBalance = uint128(balanceOf(_from));
        uint128 _sizedAmount  = uint128(_amount);
        _updateBalanceAtNow(_from, previousBalance - _sizedAmount);
        previousBalance = uint128(balanceOf(_to));
        require(
            previousBalance + _sizedAmount >= previousBalance,
            "Overflow happened"
        ); // Check for overflow
        _updateBalanceAtNow(_to, previousBalance + _sizedAmount);
        emit Transfer(_from, _to, _amount);
    }

    /**
     * @dev Helps swap the old Tellor contract Tokens to the new one
     * @param _to is the adress to send minted amount to
     * @param _amount is the amount of TRB to send
    */
    function _doMint(address _to, uint256 _amount) internal {
        require(_amount != 0, "Tried to mint non-positive amount");
        require(_to != address(0), "Receiver is 0 address");
        uint128 previousBalance = uint128(balanceOf(_to));
        uint128 _sizedAmount  = uint128(_amount);
        require(
            previousBalance + _sizedAmount >= previousBalance,
            "Overflow happened"
        );
        uint256 previousSupply = uints[_TOTAL_SUPPLY];
        require(
            previousSupply + _amount >= previousSupply,
            "Overflow happened"
        );
        uints[_TOTAL_SUPPLY] += _amount;
        _updateBalanceAtNow(_to, previousBalance + _sizedAmount);
        emit Transfer(address(0), _to, _amount);
    }

    /**
     * @dev Helps burn TRB Tokens
     * @param _from is the adress to burn or remove TRB amount
     * @param _amount is the amount of TRB to burn
     */
    function _doBurn(address _from, uint256 _amount) internal {
        if (_amount == 0) return;
        require(
            allowedToTrade(_from, _amount),
            "Should have sufficient balance to trade"
        );
        uint128 previousBalance = uint128(balanceOf(_from));
        uint128 _sizedAmount  = uint128(_amount);
        require(
            previousBalance - _sizedAmount <= previousBalance,
            "Overflow happened"
        );
        uint256 previousSupply = uints[_TOTAL_SUPPLY];
        require(
            previousSupply - _amount <= previousSupply,
            "Overflow happened"
        );
        _updateBalanceAtNow(_from, previousBalance - _sizedAmount);
        uints[_TOTAL_SUPPLY] -= _amount;
    }

    /**
     * @dev Updates balance for from and to on the current block number via doTransfer
     * @param _value is the new balance
     */
    function _updateBalanceAtNow(address _user, uint128 _value) internal {
        Checkpoint[] storage checkpoints = balances[_user];
        if (
            checkpoints.length == 0 ||
            checkpoints[checkpoints.length - 1].fromBlock != block.number
        ) {
            checkpoints.push(
                TellorStorage.Checkpoint({
                    fromBlock: uint128(block.number),
                    value: _value
                })
            );
        } else {
            TellorStorage.Checkpoint storage oldCheckPoint =
                checkpoints[checkpoints.length - 1];
            oldCheckPoint.value = _value;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

import "./SafeMath.sol";
import "./TellorGetters.sol";
import "./TellorVariables.sol";
import "./Utilities.sol";

/** 
 @author Tellor Inc.
 @title Extension
 @dev  This contract holds staking functions, tallyVotes and updateDisputeFee
 * Because of space limitations and will be consolidated in future iterations
**/
contract Extension is TellorGetters {
    using SafeMath for uint256;
    
    /*Events*/
    //emitted upon dispute tally
    event DisputeVoteTallied(
        uint256 indexed _disputeID,
        int256 _result,
        address indexed _reportedMiner,
        address _reportingParty,
        bool _passed
    );
    event StakeWithdrawn(address indexed _sender); //Emits when a staker is block.timestamp no longer staked
    event StakeWithdrawRequested(address indexed _sender); //Emits when a staker begins the 7 day withdraw period
    event NewStake(address indexed _sender); //Emits upon new staker
    event NewTellorAddress(address _newTellor);
    /*Functions*/
    /**
     * @dev This function allows miners to deposit their stake.
     */
    function depositStake() external{
        _newStake(msg.sender);
        updateMinDisputeFee();
    }

    /**
     * @dev This function allows stakers to request to withdraw their stake (no longer stake)
     * once they lock for withdraw(stakes.currentStatus = 2) they are locked for 7 days before they
     * can withdraw the deposit
     */
    function requestStakingWithdraw() external {
        StakeInfo storage stakes = stakerDetails[msg.sender];
        //Require that the miner is staked
        require(stakes.currentStatus == 1, "Miner is not staked");
        //Change the miner staked to locked to be withdrawStake
        stakes.currentStatus = 2;
        //Change the startDate to block.timestamp since the lock up period begins block.timestamp
        //and the miner can only withdraw 7 days later from block.timestamp(check the withdraw function)
        stakes.startDate = block.timestamp - (block.timestamp % 86400);
        //Reduce the staker count
        uints[_STAKE_COUNT] -= 1;
        //Update the minimum dispute fee that is based on the number of stakers
        updateMinDisputeFee();
        emit StakeWithdrawRequested(msg.sender);
    }

    /**
     * @dev tallies the votes and locks the stake disbursement(currentStatus = 4) if the vote passes
     * @param _disputeId is the dispute id
     */
    function tallyVotes(uint256 _disputeId) external {
        Dispute storage disp = disputesById[_disputeId];
        //Ensure this has not already been executed/tallied
        require(disp.executed == false, "Dispute has been already executed");
        //Ensure that the vote has been open long enough
        require(
            block.timestamp >= disp.disputeUintVars[_MIN_EXECUTION_DATE],
            "Time for voting haven't elapsed"
        );
        //Ensure that it's a valid disputeId
        require(
            disp.reportingParty != address(0),
            "reporting Party is address 0"
        );
        int256 _tally = disp.tally;
        if (_tally > 0) {
        //If the vote is not a proposed fork
            if (disp.isPropFork == false) {
                //Set the dispute state to passed/true
                disp.disputeVotePassed = true;
                //Ensure the time for voting has elapsed
                StakeInfo storage stakes = stakerDetails[disp.reportedMiner];
                //If the vote for disputing a value is successful(disp.tally >0) then unstake the reported
                if (stakes.currentStatus == 3) {
                    stakes.currentStatus = 4;
                }
            } else if (uint256(_tally) >= ((uints[_TOTAL_SUPPLY] * 5) / 100)) {
                disp.disputeVotePassed = true;
            }
        }
        disp.disputeUintVars[_TALLY_DATE] = block.timestamp;
        disp.executed = true;
        emit DisputeVoteTallied(
            _disputeId,
            _tally,
            disp.reportedMiner,
            disp.reportingParty,
            disp.disputeVotePassed
        );
    }

    /**
     * @dev This function updates the minimum dispute fee as a function of the amount
     * of staked miners
     */
    function updateMinDisputeFee() public {
        uint256 _stakeAmt = uints[_STAKE_AMOUNT];
        uint256 _trgtMiners = uints[_TARGET_MINERS];
        uints[_DISPUTE_FEE] = SafeMath.max(
            15e18,
            (_stakeAmt -
                ((_stakeAmt *
                    (SafeMath.min(_trgtMiners, uints[_STAKE_COUNT]) * 1000)) /
                    _trgtMiners) /
                1000)
        );
    }

    /**
     * @dev Updates the Tellor address after a proposed fork has
     * passed the vote and day has gone by without a dispute
     * @param _disputeId the disputeId for the proposed fork
    */
    function updateTellor(uint256 _disputeId) external {
        bytes32 _hash = disputesById[_disputeId].hash;
        uint256 origID = disputeIdByDisputeHash[_hash];
        //this checks the "lastID" or the most recent if this is a multiple dispute case
        uint256 lastID =
            disputesById[origID].disputeUintVars[
                keccak256(
                    abi.encode(
                        disputesById[origID].disputeUintVars[_DISPUTE_ROUNDS]
                    )
                )
            ];
        TellorStorage.Dispute storage disp = disputesById[lastID];
        require(disp.isPropFork, "must be a fork proposal");
        require(
            disp.disputeUintVars[_FORK_EXECUTED] == 0,
            "update Tellor has already been run"
        );
        require(disp.disputeVotePassed == true, "vote needs to pass");
        require(disp.disputeUintVars[_TALLY_DATE] > 0, "vote needs to be tallied");
        require(
            block.timestamp - disp.disputeUintVars[_TALLY_DATE] > 1 days,
            "Time for voting for further disputes has not passed"
        );
        disp.disputeUintVars[_FORK_EXECUTED] = 1;
        address _newTellor =disp.proposedForkAddress;
        addresses[_TELLOR_CONTRACT] = _newTellor; 
        assembly {
            sstore(_EIP_SLOT, _newTellor)
        }
        emit NewTellorAddress(_newTellor);
    }

    /**
     * @dev This function allows users to withdraw their stake after a 7 day waiting
     * period from request
     */
    function withdrawStake() external {
        StakeInfo storage stakes = stakerDetails[msg.sender];
        //Require the staker has locked for withdraw(currentStatus ==2) and that 7 days have
        //passed by since they locked for withdraw
        require(
            block.timestamp - (block.timestamp % 86400) - stakes.startDate >=
                7 days,
            "7 days didn't pass"
        );
        require(
            stakes.currentStatus == 2,
            "Miner was not locked for withdrawal"
        );
        stakes.currentStatus = 0;
        emit StakeWithdrawn(msg.sender);
    }

    /**
     * @dev This internal function is used the depositStake function to successfully stake miners.
     * The function updates their status/state and status start date so they are locked it so they can't withdraw
     * and updates the number of stakers in the system.
     * @param _staker the address of the new staker
    */
    function _newStake(address _staker) internal {
        require(
            balances[_staker][balances[_staker].length - 1].value >=
                uints[_STAKE_AMOUNT],
            "Balance is lower than stake amount"
        );
        //Ensure they can only stake if they are not currently staked or if their stake time frame has ended
        //and they are currently locked for withdraw
        require(
            stakerDetails[_staker].currentStatus == 0 ||
                stakerDetails[_staker].currentStatus == 2,
            "Miner is in the wrong state"
        );
        uints[_STAKE_COUNT] += 1;
        stakerDetails[_staker] = StakeInfo({
            currentStatus: 1, 
            startDate: block.timestamp//this resets their stake start date to now
        });
        emit NewStake(_staker);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

/**
  @author Tellor Inc.
  @title TellorStorage
  @dev Contains all the variables/structs used by Tellor
*/
contract TellorStorage {
    //Internal struct for use in proof-of-work submission
    struct Details {
        uint256 value;
        address miner;
    }
    struct Dispute {
        bytes32 hash; //unique hash of dispute: keccak256(_miner,_requestId,_timestamp)
        int256 tally; //current tally of votes for - against measure
        bool executed; //is the dispute settled
        bool disputeVotePassed; //did the vote pass?
        bool isPropFork; //true for fork proposal NEW
        address reportedMiner; //miner who submitted the 'bad value' will get disputeFee if dispute vote fails
        address reportingParty; //miner reporting the 'bad value'-pay disputeFee will get reportedMiner's stake if dispute vote passes
        address proposedForkAddress; //new fork address (if fork proposal)
        mapping(bytes32 => uint256) disputeUintVars;
        mapping(address => bool) voted; //mapping of address to whether or not they voted
    }
    struct StakeInfo {
        uint256 currentStatus; //0-not Staked, 1=Staked, 2=LockedForWithdraw 3= OnDispute 4=ReadyForUnlocking 5=Unlocked
        uint256 startDate; //stake start date
    }
    //Internal struct to allow balances to be queried by blocknumber for voting purposes
    struct Checkpoint {
        uint128 fromBlock; // fromBlock is the block number that the value was generated from
        uint128 value; // value is the amount of tokens at a specific block number
    }
    struct Request {
        uint256[] requestTimestamps; //array of all newValueTimestamps requested
        mapping(bytes32 => uint256) apiUintVars;
        mapping(uint256 => uint256) minedBlockNum; //[apiId][minedTimestamp]=>block.number
        //This the time series of finalValues stored by the contract where uint UNIX timestamp is mapped to value
        mapping(uint256 => uint256) finalValues;
        mapping(uint256 => bool) inDispute; //checks if API id is in dispute or finalized.
        mapping(uint256 => address[5]) minersByValue;
        mapping(uint256 => uint256[5]) valuesByTimestamp;
    }
    uint256[51] requestQ; //uint50 array of the top50 requests by payment amount
    uint256[] public newValueTimestamps; //array of all timestamps requested
    //This is a boolean that tells you if a given challenge has been completed by a given miner
    mapping(uint256 => uint256) requestIdByTimestamp; //minedTimestamp to apiId
    mapping(uint256 => uint256) requestIdByRequestQIndex; //link from payoutPoolIndex (position in payout pool array) to apiId
    mapping(uint256 => Dispute) public disputesById; //disputeId=> Dispute details
    mapping(bytes32 => uint256) public requestIdByQueryHash; // api bytes32 gets an id = to count of requests array
    mapping(bytes32 => uint256) public disputeIdByDisputeHash; //maps a hash to an ID for each dispute
    mapping(bytes32 => mapping(address => bool)) public minersByChallenge;
    Details[5] public currentMiners; //This struct is for organizing the five mined values to find the median
    mapping(address => StakeInfo) stakerDetails; //mapping from a persons address to their staking info
    mapping(uint256 => Request) requestDetails;
    mapping(bytes32 => uint256) public uints;
    mapping(bytes32 => address) public addresses;
    mapping(bytes32 => bytes32) public bytesVars;
    //ERC20 storage
    mapping(address => Checkpoint[]) public balances;
    mapping(address => mapping(address => uint256)) public _allowances;
    //Migration storage
    mapping(address => bool) public migrated;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

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

{
  "optimizer": {
    "enabled": true,
    "runs": 300
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}