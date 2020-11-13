pragma solidity ^0.5.16;

//Slightly modified SafeMath library - includes a min and max function, removes useless div function
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

pragma solidity ^0.5.0;

/**
 * @title Tellor Oracle Storage Library
 * @dev Contains all the variables/structs used by Tellor
 */

library TellorStorage {
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
        address reportedMiner; //miner who alledgedly submitted the 'bad value' will get disputeFee if dispute vote fails
        address reportingParty; //miner reporting the 'bad value'-pay disputeFee will get reportedMiner's stake if dispute vote passes
        address proposedForkAddress; //new fork address (if fork proposal)
        mapping(bytes32 => uint256) disputeUintVars;
        //Each of the variables below is saved in the mapping disputeUintVars for each disputeID
        //e.g. TellorStorageStruct.DisputeById[disputeID].disputeUintVars[keccak256("requestId")]
        //These are the variables saved in this mapping:
        // uint keccak256("requestId");//apiID of disputed value
        // uint keccak256("timestamp");//timestamp of distputed value
        // uint keccak256("value"); //the value being disputed
        // uint keccak256("minExecutionDate");//7 days from when dispute initialized
        // uint keccak256("numberOfVotes");//the number of parties who have voted on the measure
        // uint keccak256("blockNumber");// the blocknumber for which votes will be calculated from
        // uint keccak256("minerSlot"); //index in dispute array
        // uint keccak256("fee"); //fee paid corresponding to dispute
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
        string queryString; //id to string api
        string dataSymbol; //short name for api request
        bytes32 queryHash; //hash of api string and granularity e.g. keccak256(abi.encodePacked(_sapi,_granularity))
        uint256[] requestTimestamps; //array of all newValueTimestamps requested
        mapping(bytes32 => uint256) apiUintVars;
        //Each of the variables below is saved in the mapping apiUintVars for each api request
        //e.g. requestDetails[_requestId].apiUintVars[keccak256("totalTip")]
        //These are the variables saved in this mapping:
        // uint keccak256("granularity"); //multiplier for miners
        // uint keccak256("requestQPosition"); //index in requestQ
        // uint keccak256("totalTip");//bonus portion of payout
        mapping(uint256 => uint256) minedBlockNum; //[apiId][minedTimestamp]=>block.number
        //This the time series of finalValues stored by the contract where uint UNIX timestamp is mapped to value
        mapping(uint256 => uint256) finalValues;
        mapping(uint256 => bool) inDispute; //checks if API id is in dispute or finalized.
        mapping(uint256 => address[5]) minersByValue;
        mapping(uint256 => uint256[5]) valuesByTimestamp;
    }

    struct TellorStorageStruct {
        bytes32 currentChallenge; //current challenge to be solved
        uint256[51] requestQ; //uint50 array of the top50 requests by payment amount
        uint256[] newValueTimestamps; //array of all timestamps requested
        Details[5] currentMiners; //This struct is for organizing the five mined values to find the median
        mapping(bytes32 => address) addressVars;
        //Address fields in the Tellor contract are saved the addressVars mapping
        //e.g. addressVars[keccak256("tellorContract")] = address
        //These are the variables saved in this mapping:
        // address keccak256("tellorContract");//Tellor address
        // address  keccak256("_owner");//Tellor Owner address
        // address  keccak256("_deity");//Tellor Owner that can do things at will
        // address  keccak256("pending_owner"); // The proposed new owner
        mapping(bytes32 => uint256) uintVars;
        //uint fields in the Tellor contract are saved the uintVars mapping
        //e.g. uintVars[keccak256("decimals")] = uint
        //These are the variables saved in this mapping:
        // keccak256("decimals");    //18 decimal standard ERC20
        // keccak256("disputeFee");//cost to dispute a mined value
        // keccak256("disputeCount");//totalHistoricalDisputes
        // keccak256("total_supply"); //total_supply of the token in circulation
        // keccak256("stakeAmount");//stakeAmount for miners (we can cut gas if we just hardcode it in...or should it be variable?)
        // keccak256("stakerCount"); //number of parties currently staked
        // keccak256("timeOfLastNewValue"); // time of last challenge solved
        // keccak256("difficulty"); // Difficulty of current block
        // keccak256("currentTotalTips"); //value of highest api/timestamp PayoutPool
        // keccak256("currentRequestId"); //API being mined--updates with the ApiOnQ Id
        // keccak256("requestCount"); // total number of requests through the system
        // keccak256("slotProgress");//Number of miners who have mined this value so far
        // keccak256("miningReward");//Mining Reward in PoWo tokens given to all miners per value
        // keccak256("timeTarget"); //The time between blocks (mined Oracle values)
        // keccak256("_tblock"); //
        // keccak256("runningTips"); // VAriable to track running tips
        // keccak256("currentReward"); // The current reward
        // keccak256("devShare"); // The amount directed towards th devShare
        // keccak256("currentTotalTips"); //
        //This is a boolean that tells you if a given challenge has been completed by a given miner
        mapping(bytes32 => mapping(address => bool)) minersByChallenge;
        mapping(uint256 => uint256) requestIdByTimestamp; //minedTimestamp to apiId
        mapping(uint256 => uint256) requestIdByRequestQIndex; //link from payoutPoolIndex (position in payout pool array) to apiId
        mapping(uint256 => Dispute) disputesById; //disputeId=> Dispute details
        mapping(address => Checkpoint[]) balances; //balances of a party given blocks
        mapping(address => mapping(address => uint256)) allowed; //allowance for a given party and approver
        mapping(address => StakeInfo) stakerDetails; //mapping from a persons address to their staking info
        mapping(uint256 => Request) requestDetails; //mapping of apiID to details
        mapping(bytes32 => uint256) requestIdByQueryHash; // api bytes32 gets an id = to count of requests array
        mapping(bytes32 => uint256) disputeIdByDisputeHash; //maps a hash to an ID for each dispute
    }
}


pragma solidity ^0.5.16;


/**
* @title Tellor Transfer
* @dev Contains the methods related to transfers and ERC20. Tellor.sol and TellorGetters.sol
* reference this library for function's logic.
*/
library TellorTransfer {
    using SafeMath for uint256;

    event Approval(address indexed _owner, address indexed _spender, uint256 _value); //ERC20 Approval event
    event Transfer(address indexed _from, address indexed _to, uint256 _value); //ERC20 Transfer Event

    bytes32 public constant stakeAmount = 0x7be108969d31a3f0b261465c71f2b0ba9301cd914d55d9091c3b36a49d4d41b2; //keccak256("stakeAmount")

    /*Functions*/

    /**
    * @dev Allows for a transfer of tokens to _to
    * @param _to The address to send tokens to
    * @param _amount The amount of tokens to send
    * @return true if transfer is successful
    */
    function transfer(TellorStorage.TellorStorageStruct storage self, address _to, uint256 _amount) public returns (bool success) {
        doTransfer(self, msg.sender, _to, _amount);
        return true;
    }

    /**
    * @notice Send _amount tokens to _to from _from on the condition it
    * is approved by _from
    * @param _from The address holding the tokens being transferred
    * @param _to The address of the recipient
    * @param _amount The amount of tokens to be transferred
    * @return True if the transfer was successful
    */
    function transferFrom(TellorStorage.TellorStorageStruct storage self, address _from, address _to, uint256 _amount)
        public
        returns (bool success)
    {
        require(self.allowed[_from][msg.sender] >= _amount, "Allowance is wrong");
        self.allowed[_from][msg.sender] -= _amount;
        doTransfer(self, _from, _to, _amount);
        return true;
    }

    /**
    * @dev This function approves a _spender an _amount of tokens to use
    * @param _spender address
    * @param _amount amount the spender is being approved for
    * @return true if spender appproved successfully
    */
    function approve(TellorStorage.TellorStorageStruct storage self, address _spender, uint256 _amount) public returns (bool) {
        require(_spender != address(0), "Spender is 0-address");
        require(self.allowed[msg.sender][_spender] == 0 || _amount == 0, "Spender is already approved");
        self.allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    /**
    * @param _user address of party with the balance
    * @param _spender address of spender of parties said balance
    * @return Returns the remaining allowance of tokens granted to the _spender from the _user
    */
    function allowance(TellorStorage.TellorStorageStruct storage self, address _user, address _spender) public view returns (uint256) {
        return self.allowed[_user][_spender];
    }

    /**
    * @dev Completes POWO transfers by updating the balances on the current block number
    * @param _from address to transfer from
    * @param _to addres to transfer to
    * @param _amount to transfer
    */
    function doTransfer(TellorStorage.TellorStorageStruct storage self, address _from, address _to, uint256 _amount) public {
        require(_amount != 0, "Tried to send non-positive amount");
        require(_to != address(0), "Receiver is 0 address");
        require(allowedToTrade(self, _from, _amount), "Should have sufficient balance to trade");
        uint256 previousBalance = balanceOf(self, _from);
        updateBalanceAtNow(self.balances[_from], previousBalance - _amount);
        previousBalance = balanceOf(self,_to);
        require(previousBalance + _amount >= previousBalance, "Overflow happened"); // Check for overflow
        updateBalanceAtNow(self.balances[_to], previousBalance + _amount);
        emit Transfer(_from, _to, _amount);
    }

    /**
    * @dev Gets balance of owner specified
    * @param _user is the owner address used to look up the balance
    * @return Returns the balance associated with the passed in _user
    */
    function balanceOf(TellorStorage.TellorStorageStruct storage self, address _user) public view returns (uint256) {
        return balanceOfAt(self, _user, block.number);
    }

    /**
    * @dev Queries the balance of _user at a specific _blockNumber
    * @param _user The address from which the balance will be retrieved
    * @param _blockNumber The block number when the balance is queried
    * @return The balance at _blockNumber specified
    */
    function balanceOfAt(TellorStorage.TellorStorageStruct storage self, address _user, uint256 _blockNumber) public view returns (uint256) {
        TellorStorage.Checkpoint[] storage checkpoints = self.balances[_user];
        if (checkpoints.length == 0|| checkpoints[0].fromBlock > _blockNumber) {
            return 0;
        } else {
            if (_blockNumber >= checkpoints[checkpoints.length - 1].fromBlock) return checkpoints[checkpoints.length - 1].value;
            // Binary search of the value in the array
            uint256 min = 0;
            uint256 max = checkpoints.length - 2;
            while (max > min) {
                uint256 mid = (max + min + 1) / 2;
                if  (checkpoints[mid].fromBlock ==_blockNumber){
                    return checkpoints[mid].value;
                }else if(checkpoints[mid].fromBlock < _blockNumber) {
                    min = mid;
                } else {
                    max = mid - 1;
                }
            }
            return checkpoints[min].value;
        }
    }
    /**
    * @dev This function returns whether or not a given user is allowed to trade a given amount
    * and removing the staked amount from their balance if they are staked
    * @param _user address of user
    * @param _amount to check if the user can spend
    * @return true if they are allowed to spend the amount being checked
    */
    function allowedToTrade(TellorStorage.TellorStorageStruct storage self, address _user, uint256 _amount) public view returns (bool) { 
        if (self.stakerDetails[_user].currentStatus != 0 && self.stakerDetails[_user].currentStatus < 5) {
            //Subtracts the stakeAmount from balance if the _user is staked
            if (balanceOf(self, _user)- self.uintVars[stakeAmount] >= _amount) {
                return true;
            }
            return false;
        } 
        return (balanceOf(self, _user) >= _amount);
    }

    /**
    * @dev Updates balance for from and to on the current block number via doTransfer
    * @param checkpoints gets the mapping for the balances[owner]
    * @param _value is the new balance
    */
    function updateBalanceAtNow(TellorStorage.Checkpoint[] storage checkpoints, uint256 _value) public {
        if (checkpoints.length == 0 || checkpoints[checkpoints.length - 1].fromBlock != block.number) {
           checkpoints.push(TellorStorage.Checkpoint({
                fromBlock : uint128(block.number),
                value : uint128(_value)
            }));
        } else {
            TellorStorage.Checkpoint storage oldCheckPoint = checkpoints[checkpoints.length - 1];
            oldCheckPoint.value = uint128(_value);
        }
    }
}


pragma solidity ^0.5.16;


/**
* @title Tellor Dispute
* @dev Contains the methods related to disputes. Tellor.sol references this library for function's logic.
*/

library TellorDispute {
    using SafeMath for uint256;
    using SafeMath for int256;

    //emitted when a new dispute is initialized
    event NewDispute(uint256 indexed _disputeId, uint256 indexed _requestId, uint256 _timestamp, address _miner);
    //emitted when a new vote happens
    event Voted(uint256 indexed _disputeID, bool _position, address indexed _voter, uint256 indexed _voteWeight);
    //emitted upon dispute tally
    event DisputeVoteTallied(uint256 indexed _disputeID, int256 _result, address indexed _reportedMiner, address _reportingParty, bool _active);
    event NewTellorAddress(address _newTellor); //emmited when a proposed fork is voted true

    /*Functions*/

    /**
    * @dev Helps initialize a dispute by assigning it a disputeId
    * when a miner returns a false on the validate array(in Tellor.ProofOfWork) it sends the
    * invalidated value information to POS voting
    * @param _requestId being disputed
    * @param _timestamp being disputed
    * @param _minerIndex the index of the miner that submitted the value being disputed. Since each official value
    * requires 5 miners to submit a value.
    */
    function beginDispute(TellorStorage.TellorStorageStruct storage self, uint256 _requestId, uint256 _timestamp, uint256 _minerIndex) public {
        TellorStorage.Request storage _request = self.requestDetails[_requestId];
        require(_request.minedBlockNum[_timestamp] != 0, "Mined block is 0");
        require(_minerIndex < 5, "Miner index is wrong");

        //_miner is the miner being disputed. For every mined value 5 miners are saved in an array and the _minerIndex
        //provided by the party initiating the dispute
        address _miner = _request.minersByValue[_timestamp][_minerIndex];
        bytes32 _hash = keccak256(abi.encodePacked(_miner, _requestId, _timestamp));



        //Increase the dispute count by 1
        uint256 disputeId = self.uintVars[keccak256("disputeCount")] + 1;
        self.uintVars[keccak256("disputeCount")] = disputeId;

        //Sets the new disputeCount as the disputeId

                //Ensures that a dispute is not already open for the that miner, requestId and timestamp
        uint256 hashId = self.disputeIdByDisputeHash[_hash];
        if(hashId != 0){
            self.disputesById[disputeId].disputeUintVars[keccak256("origID")] = hashId;

        }
        else{
            self.disputeIdByDisputeHash[_hash] = disputeId;
            hashId = disputeId;
        }
        uint256 origID = hashId;
        uint256 dispRounds = self.disputesById[origID].disputeUintVars[keccak256("disputeRounds")] + 1;
        self.disputesById[origID].disputeUintVars[keccak256("disputeRounds")] = dispRounds;
        self.disputesById[origID].disputeUintVars[keccak256(abi.encode(dispRounds))] = disputeId;
        if(disputeId != origID){
            uint256 lastID =  self.disputesById[origID].disputeUintVars[keccak256(abi.encode(dispRounds-1))];
            require(self.disputesById[lastID].disputeUintVars[keccak256("minExecutionDate")] <= now, "Dispute is already open");
            if(self.disputesById[lastID].executed){
                require(now - self.disputesById[lastID].disputeUintVars[keccak256("tallyDate")] <= 1 days, "Time for voting haven't elapsed");
            }
        }
        uint256 _fee;
        if (_minerIndex == 2) {
            self.requestDetails[_requestId].apiUintVars[keccak256("disputeCount")] = self.requestDetails[_requestId].apiUintVars[keccak256("disputeCount")] +1;
            //update dispute fee for this case
            _fee = self.uintVars[keccak256("stakeAmount")]*self.requestDetails[_requestId].apiUintVars[keccak256("disputeCount")];
        } else {

            _fee = self.uintVars[keccak256("disputeFee")] * dispRounds;
        }

        //maps the dispute to the Dispute struct
        self.disputesById[disputeId] = TellorStorage.Dispute({
            hash: _hash,
            isPropFork: false,
            reportedMiner: _miner,
            reportingParty: msg.sender,
            proposedForkAddress: address(0),
            executed: false,
            disputeVotePassed: false,
            tally: 0
        });

        //Saves all the dispute variables for the disputeId
        self.disputesById[disputeId].disputeUintVars[keccak256("requestId")] = _requestId;
        self.disputesById[disputeId].disputeUintVars[keccak256("timestamp")] = _timestamp;
        self.disputesById[disputeId].disputeUintVars[keccak256("value")] = _request.valuesByTimestamp[_timestamp][_minerIndex];
        self.disputesById[disputeId].disputeUintVars[keccak256("minExecutionDate")] = now + 2 days * dispRounds;
        self.disputesById[disputeId].disputeUintVars[keccak256("blockNumber")] = block.number;
        self.disputesById[disputeId].disputeUintVars[keccak256("minerSlot")] = _minerIndex;
        self.disputesById[disputeId].disputeUintVars[keccak256("fee")] = _fee;
        TellorTransfer.doTransfer(self, msg.sender, address(this),_fee);

   

        //Values are sorted as they come in and the official value is the median of the first five
        //So the "official value" miner is always minerIndex==2. If the official value is being
        //disputed, it sets its status to inDispute(currentStatus = 3) so that users are made aware it is under dispute
        if (_minerIndex == 2) {
            _request.inDispute[_timestamp] = true;
            _request.finalValues[_timestamp] = 0;
        }
        if (self.stakerDetails[_miner].currentStatus != 4){
            self.stakerDetails[_miner].currentStatus = 3;
        }
        emit NewDispute(disputeId, _requestId, _timestamp, _miner);
    }

    /**
    * @dev Allows token holders to vote
    * @param _disputeId is the dispute id
    * @param _supportsDispute is the vote (true=the dispute has basis false = vote against dispute)
    */
    function vote(TellorStorage.TellorStorageStruct storage self, uint256 _disputeId, bool _supportsDispute) public {
        TellorStorage.Dispute storage disp = self.disputesById[_disputeId];

        //Get the voteWeight or the balance of the user at the time/blockNumber the disupte began
        uint256 voteWeight = TellorTransfer.balanceOfAt(self, msg.sender, disp.disputeUintVars[keccak256("blockNumber")]);

        //Require that the msg.sender has not voted
        require(disp.voted[msg.sender] != true, "Sender has already voted");

        //Requre that the user had a balance >0 at time/blockNumber the disupte began
        require(voteWeight != 0, "User balance is 0");

        //ensures miners that are under dispute cannot vote
        require(self.stakerDetails[msg.sender].currentStatus != 3, "Miner is under dispute");

        //Update user voting status to true
        disp.voted[msg.sender] = true;

        //Update the number of votes for the dispute
        disp.disputeUintVars[keccak256("numberOfVotes")] += 1;

        //If the user supports the dispute increase the tally for the dispute by the voteWeight
        //otherwise decrease it
        if (_supportsDispute) {
            disp.tally = disp.tally.add(int256(voteWeight));
        } else {
            disp.tally = disp.tally.sub(int256(voteWeight));
        }

        //Let the network know the user has voted on the dispute and their casted vote
        emit Voted(_disputeId, _supportsDispute, msg.sender, voteWeight);
    }

    /**
    * @dev tallies the votes and locks the stake disbursement(currentStatus = 4) if the vote passes
    * @param _disputeId is the dispute id
    */
    function tallyVotes(TellorStorage.TellorStorageStruct storage self, uint256 _disputeId) public {
        TellorStorage.Dispute storage disp = self.disputesById[_disputeId];

        //Ensure this has not already been executed/tallied
        require(disp.executed == false, "Dispute has been already executed");
        require(now >= disp.disputeUintVars[keccak256("minExecutionDate")], "Time for voting haven't elapsed");
        require(disp.reportingParty != address(0), "reporting Party is address 0");
        int256  _tally = disp.tally;
        if (_tally > 0) {
            //Set the dispute state to passed/true
            disp.disputeVotePassed = true;
        }
        //If the vote is not a proposed fork
        if (disp.isPropFork == false) {
                //Ensure the time for voting has elapsed
                    TellorStorage.StakeInfo storage stakes = self.stakerDetails[disp.reportedMiner];
                    //If the vote for disputing a value is succesful(disp.tally >0) then unstake the reported
                    // miner and transfer the stakeAmount and dispute fee to the reporting party
                    if(stakes.currentStatus == 3){
                        stakes.currentStatus = 4;
                    }
        } else if (uint(_tally) >= ((self.uintVars[keccak256("total_supply")] * 10) / 100)) {
            emit NewTellorAddress(disp.proposedForkAddress);
        }
        disp.disputeUintVars[keccak256("tallyDate")] = now;
        disp.executed = true;
        emit DisputeVoteTallied(_disputeId, _tally, disp.reportedMiner, disp.reportingParty, disp.disputeVotePassed);
    }

    /**
    * @dev Allows for a fork to be proposed
    * @param _propNewTellorAddress address for new proposed Tellor
    */
    function proposeFork(TellorStorage.TellorStorageStruct storage self, address _propNewTellorAddress) public {
        bytes32 _hash = keccak256(abi.encode(_propNewTellorAddress));
        TellorTransfer.doTransfer(self, msg.sender, address(this), 100e18); //This is the fork fee (just 100 tokens flat, no refunds)
        self.uintVars[keccak256("disputeCount")]++;
        uint256 disputeId = self.uintVars[keccak256("disputeCount")];
        if(self.disputeIdByDisputeHash[_hash] != 0){
            self.disputesById[disputeId].disputeUintVars[keccak256("origID")] = self.disputeIdByDisputeHash[_hash];
        }
        else{
            self.disputeIdByDisputeHash[_hash] = disputeId;
        }
        uint256 origID = self.disputeIdByDisputeHash[_hash];

        self.disputesById[origID].disputeUintVars[keccak256("disputeRounds")]++;
        uint256 dispRounds = self.disputesById[origID].disputeUintVars[keccak256("disputeRounds")];
        self.disputesById[origID].disputeUintVars[keccak256(abi.encode(dispRounds))] = disputeId;
        if(disputeId != origID){
            uint256 lastID =  self.disputesById[origID].disputeUintVars[keccak256(abi.encode(dispRounds-1))];
            require(self.disputesById[lastID].disputeUintVars[keccak256("minExecutionDate")] <= now, "Dispute is already open");
            if(self.disputesById[lastID].executed){
                require(now - self.disputesById[lastID].disputeUintVars[keccak256("tallyDate")] <= 1 days, "Time for voting haven't elapsed");
            }
        }
        self.disputesById[disputeId] = TellorStorage.Dispute({
            hash: _hash,
            isPropFork: true,
            reportedMiner: msg.sender,
            reportingParty: msg.sender,
            proposedForkAddress: _propNewTellorAddress,
            executed: false,
            disputeVotePassed: false,
            tally: 0
        });
        self.disputesById[disputeId].disputeUintVars[keccak256("blockNumber")] = block.number;
        self.disputesById[disputeId].disputeUintVars[keccak256("minExecutionDate")] = now + 7 days;
    }

    /**
    * @dev Updates the Tellor address after a proposed fork has 
    * passed the vote and day has gone by without a dispute
    * @param _disputeId the disputeId for the proposed fork
    */
    function updateTellor(TellorStorage.TellorStorageStruct storage self, uint _disputeId) public {
        bytes32 _hash = self.disputesById[_disputeId].hash;
        uint256 origID = self.disputeIdByDisputeHash[_hash];
        uint256 lastID =  self.disputesById[origID].disputeUintVars[keccak256(abi.encode(self.disputesById[origID].disputeUintVars[keccak256("disputeRounds")]))];
        TellorStorage.Dispute storage disp = self.disputesById[lastID];
        require(disp.disputeVotePassed == true, "vote needs to pass");
        require(now - disp.disputeUintVars[keccak256("tallyDate")] > 1 days, "Time for voting for further disputes has not passed");
        self.addressVars[keccak256("tellorContract")] = disp.proposedForkAddress;
    }

    /**
    * @dev Allows disputer to unlock the dispute fee
    * @param _disputeId to unlock fee from
    */
    function unlockDisputeFee (TellorStorage.TellorStorageStruct storage self, uint _disputeId) public {
        uint256 origID = self.disputeIdByDisputeHash[self.disputesById[_disputeId].hash];
        uint256 lastID =  self.disputesById[origID].disputeUintVars[keccak256(abi.encode(self.disputesById[origID].disputeUintVars[keccak256("disputeRounds")]))];
        if(lastID == 0){
            lastID = origID;
        }
        TellorStorage.Dispute storage disp = self.disputesById[origID];
        TellorStorage.Dispute storage last = self.disputesById[lastID];
                //disputeRounds is increased by 1 so that the _id is not a negative number when it is the first time a dispute is initiated
        uint256 dispRounds = disp.disputeUintVars[keccak256("disputeRounds")];
        if(dispRounds == 0){
          dispRounds = 1;  
        }
        uint256 _id;
        require(disp.disputeUintVars[keccak256("paid")] == 0,"already paid out");
        require(now - last.disputeUintVars[keccak256("tallyDate")] > 1 days, "Time for voting haven't elapsed");
        TellorStorage.StakeInfo storage stakes = self.stakerDetails[disp.reportedMiner];
        disp.disputeUintVars[keccak256("paid")] = 1;
        if (last.disputeVotePassed == true){
                //Changing the currentStatus and startDate unstakes the reported miner and transfers the stakeAmount
                stakes.startDate = now - (now % 86400);

                //Reduce the staker count
                self.uintVars[keccak256("stakerCount")] -= 1;

                //Update the minimum dispute fee that is based on the number of stakers 
                updateMinDisputeFee(self);
                //Decreases the stakerCount since the miner's stake is being slashed
                if(stakes.currentStatus == 4){
                    stakes.currentStatus = 5;
                    TellorTransfer.doTransfer(self,disp.reportedMiner,disp.reportingParty,self.uintVars[keccak256("stakeAmount")]);
                    stakes.currentStatus =0 ;
                }
                for(uint i = 0; i < dispRounds;i++){
                    _id = disp.disputeUintVars[keccak256(abi.encode(dispRounds-i))];
                    if(_id == 0){
                        _id = origID;
                    }
                    TellorStorage.Dispute storage disp2 = self.disputesById[_id];
                        //transfer fee adjusted based on number of miners if the minerIndex is not 2(official value)
                    TellorTransfer.doTransfer(self,address(this), disp2.reportingParty, disp2.disputeUintVars[keccak256("fee")]);
                }
            }
            else {
                stakes.currentStatus = 1;
                TellorStorage.Request storage _request = self.requestDetails[disp.disputeUintVars[keccak256("requestId")]];
                if(disp.disputeUintVars[keccak256("minerSlot")] == 2) {
                    //note we still don't put timestamp back into array (is this an issue? (shouldn't be))
                  _request.finalValues[disp.disputeUintVars[keccak256("timestamp")]] = disp.disputeUintVars[keccak256("value")];
                }
                if (_request.inDispute[disp.disputeUintVars[keccak256("timestamp")]] == true) {
                    _request.inDispute[disp.disputeUintVars[keccak256("timestamp")]] = false;
                }
                for(uint i = 0; i < dispRounds;i++){
                    _id = disp.disputeUintVars[keccak256(abi.encode(dispRounds-i))];
                    if(_id != 0){
                        last = self.disputesById[_id];//handling if happens during an upgrade
                    }
                    TellorTransfer.doTransfer(self,address(this),last.reportedMiner,self.disputesById[_id].disputeUintVars[keccak256("fee")]);
                }
            }

            if (disp.disputeUintVars[keccak256("minerSlot")] == 2) {
                self.requestDetails[disp.disputeUintVars[keccak256("requestId")]].apiUintVars[keccak256("disputeCount")]--;
            } 
    }

    /**
    * @dev This function upates the minimun dispute fee as a function of the amount
    * of staked miners
    */
    function updateMinDisputeFee(TellorStorage.TellorStorageStruct storage self) public {
        uint256 stakeAmount = self.uintVars[keccak256("stakeAmount")];
        uint256 targetMiners = self.uintVars[keccak256("targetMiners")];
        self.uintVars[keccak256("disputeFee")] = SafeMath.max(15e18,
                (stakeAmount-(stakeAmount*(SafeMath.min(targetMiners,self.uintVars[keccak256("stakerCount")])*1000)/
                targetMiners)/1000));
    }
}

pragma solidity ^0.5.16;

//Functions for retrieving min and Max in 51 length array (requestQ)
//Taken partly from: https://github.com/modular-network/ethereum-libraries-array-utils/blob/master/contracts/Array256Lib.sol

library Utilities {
    /**
    * @dev Returns the max value in an array.
    * The zero position here is ignored. It's because 
    * there's no null in solidity and we map each address 
    * to an index in this array. So when we get 51 parties, 
    * and one person is kicked out of the top 50, we 
    * assign them a 0, and when you get mined and pulled 
    * out of the top 50, also a 0. So then lot's of parties 
    * will have zero as the index so we made the array run 
    * from 1-51 with zero as nothing.
    * @param data is the array to calculate max from
    * @return max amount and its index within the array
    */
    function getMax(uint256[51] memory data) internal pure returns (uint256 max, uint256 maxIndex) {
        maxIndex = 1;
        max = data[maxIndex];
        for (uint256 i = 2; i < data.length; i++) {
            if (data[i] > max) {
                max = data[i];
                maxIndex = i;
            }
        }
    }

    /**
    * @dev Returns the minimum value in an array.
    * @param data is the array to calculate min from
    * @return min amount and its index within the array
    */
    function getMin(uint256[51] memory data) internal pure returns (uint256 min, uint256 minIndex) {
        minIndex = data.length - 1;
        min = data[minIndex];
        for (uint256 i = data.length - 2; i > 0; i--) {
            if (data[i] < min) {
                min = data[i];
                minIndex = i;
            }
        }
    }

    /**
    * @dev Returns the 5 requestsId's with the top payouts in an array.
    * @param data is the array to get the top 5 from
    * @return to 5 max amounts and their respective index within the array
    */
    function getMax5(uint256[51] memory data) internal pure returns (uint256[5] memory max, uint256[5] memory maxIndex) {
        uint256 min5 = data[1];
        uint256 minI = 0;
        for(uint256 j=0;j<5;j++){
            max[j]= data[j+1];//max[0]=data[1]
            maxIndex[j] = j+1;//maxIndex[0]= 1
            if(max[j] < min5){
                min5 = max[j];
                minI = j;
            }
        }
        for(uint256 i = 6; i < data.length; i++) {
            if (data[i] > min5) {
                max[minI] = data[i];
                maxIndex[minI] = i;
                min5 = data[i];
                for(uint256 j=0;j<5;j++){
                    if(max[j] < min5){
                        min5 = max[j];
                        minI = j;
                    }
                }
            }
        }
    }
}


pragma solidity ^0.5.16;


/**
* itle Tellor Stake
* @dev Contains the methods related to miners staking and unstaking. Tellor.sol
* references this library for function's logic.
*/

library TellorStake {
    event NewStake(address indexed _sender); //Emits upon new staker
    event StakeWithdrawn(address indexed _sender); //Emits when a staker is now no longer staked
    event StakeWithdrawRequested(address indexed _sender); //Emits when a staker begins the 7 day withdraw period

    /*Functions*/

    /**
    * @dev This function stakes the five initial miners, sets the supply and all the constant variables.
    * This function is called by the constructor function on TellorMaster.sol
    */
    function init(TellorStorage.TellorStorageStruct storage self) public {
        require(self.uintVars[keccak256("decimals")] == 0, "Too many decimals");
        //Give this contract 6000 Tellor Tributes so that it can stake the initial 6 miners
        TellorTransfer.updateBalanceAtNow(self.balances[address(this)], 2**256 - 1 - 6000e18);

        // //the initial 5 miner addresses are specfied below
        // //changed payable[5] to 6
        address payable[6] memory _initalMiners = [
            address(0xE037EC8EC9ec423826750853899394dE7F024fee),
            address(0xcdd8FA31AF8475574B8909F135d510579a8087d3),
            address(0xb9dD5AfD86547Df817DA2d0Fb89334A6F8eDd891),
            address(0x230570cD052f40E14C14a81038c6f3aa685d712B),
            address(0x3233afA02644CCd048587F8ba6e99b3C00A34DcC),
            address(0xe010aC6e0248790e08F42d5F697160DEDf97E024)
        ];
        //Stake each of the 5 miners specified above
        for (uint256 i = 0; i < 6; i++) {
            //6th miner to allow for dispute
            //Miner balance is set at 1000e18 at the block that this function is ran
            TellorTransfer.updateBalanceAtNow(self.balances[_initalMiners[i]], 1000e18);

            newStake(self, _initalMiners[i]);
        }

        //update the total suppply
        self.uintVars[keccak256("total_supply")] += 6000e18; //6th miner to allow for dispute
        //set Constants
        self.uintVars[keccak256("decimals")] = 18;
        self.uintVars[keccak256("targetMiners")] = 200;
        self.uintVars[keccak256("stakeAmount")] = 1000e18;
        self.uintVars[keccak256("disputeFee")] = 970e18;
        self.uintVars[keccak256("timeTarget")] = 600;
        self.uintVars[keccak256("timeOfLastNewValue")] = now - (now % self.uintVars[keccak256("timeTarget")]);
        self.uintVars[keccak256("difficulty")] = 1;
    }

    /**
    * @dev This function allows stakers to request to withdraw their stake (no longer stake)
    * once they lock for withdraw(stakes.currentStatus = 2) they are locked for 7 days before they
    * can withdraw the deposit
    */
    function requestStakingWithdraw(TellorStorage.TellorStorageStruct storage self) public {
        TellorStorage.StakeInfo storage stakes = self.stakerDetails[msg.sender];
        //Require that the miner is staked
        require(stakes.currentStatus == 1, "Miner is not staked");

        //Change the miner staked to locked to be withdrawStake
        stakes.currentStatus = 2;

        //Change the startDate to now since the lock up period begins now
        //and the miner can only withdraw 7 days later from now(check the withdraw function)
        stakes.startDate = now - (now % 86400);

        //Reduce the staker count
        self.uintVars[keccak256("stakerCount")] -= 1;

        //Update the minimum dispute fee that is based on the number of stakers 
        TellorDispute.updateMinDisputeFee(self);
        emit StakeWithdrawRequested(msg.sender);
    }

    /**
    * @dev This function allows users to withdraw their stake after a 7 day waiting period from request
    */
    function withdrawStake(TellorStorage.TellorStorageStruct storage self) public {
        TellorStorage.StakeInfo storage stakes = self.stakerDetails[msg.sender];
        //Require the staker has locked for withdraw(currentStatus ==2) and that 7 days have
        //passed by since they locked for withdraw
        require(now - (now % 86400) - stakes.startDate >= 7 days, "7 days didn't pass");
        require(stakes.currentStatus == 2, "Miner was not locked for withdrawal");
        stakes.currentStatus = 0;
        emit StakeWithdrawn(msg.sender);
    }

    /**
    * @dev This function allows miners to deposit their stake.
    */
    function depositStake(TellorStorage.TellorStorageStruct storage self) public {
        newStake(self, msg.sender);
        //self adjusting disputeFee
        TellorDispute.updateMinDisputeFee(self);
    }

    /**
    * @dev This function is used by the init function to succesfully stake the initial 5 miners.
    * The function updates their status/state and status start date so they are locked it so they can't withdraw
    * and updates the number of stakers in the system.
    */
    function newStake(TellorStorage.TellorStorageStruct storage self, address staker) internal {
        require(TellorTransfer.balanceOf(self, staker) >= self.uintVars[keccak256("stakeAmount")], "Balance is lower than stake amount");
        //Ensure they can only stake if they are not currrently staked or if their stake time frame has ended
        //and they are currently locked for witdhraw
        require(self.stakerDetails[staker].currentStatus == 0 || self.stakerDetails[staker].currentStatus == 2, "Miner is in the wrong state");
        self.uintVars[keccak256("stakerCount")] += 1;
        self.stakerDetails[staker] = TellorStorage.StakeInfo({
            currentStatus: 1, //this resets their stake start date to today
            startDate: now - (now % 86400)
        });
        emit NewStake(staker);
    }

    /**
    * @dev Getter function for the requestId being mined 
    * @return variables for the current minin event: Challenge, 5 RequestId, difficulty and Totaltips
    */
    function getNewCurrentVariables(TellorStorage.TellorStorageStruct storage self) internal view returns(bytes32 _challenge,uint[5] memory _requestIds,uint256 _difficulty, uint256 _tip){
        for(uint i=0;i<5;i++){
            _requestIds[i] =  self.currentMiners[i].value;
        }
        return (self.currentChallenge,_requestIds,self.uintVars[keccak256("difficulty")],self.uintVars[keccak256("currentTotalTips")]);
    }

    /**
    * @dev Getter function for next requestId on queue/request with highest payout at time the function is called
    * @return onDeck/info on top 5 requests(highest payout)-- RequestId, Totaltips
    */
    function getNewVariablesOnDeck(TellorStorage.TellorStorageStruct storage self) internal view returns (uint256[5] memory idsOnDeck, uint256[5] memory tipsOnDeck) {
        idsOnDeck = getTopRequestIDs(self);
        for(uint i = 0;i<5;i++){
            tipsOnDeck[i] = self.requestDetails[idsOnDeck[i]].apiUintVars[keccak256("totalTip")];
        }
    }
    
    /**
    * @dev Getter function for the top 5 requests with highest payouts. This function is used within the getNewVariablesOnDeck function
    * @return uint256[5] is an array with the top 5(highest payout) _requestIds at the time the function is called
    */
    function getTopRequestIDs(TellorStorage.TellorStorageStruct storage self) internal view returns (uint256[5] memory _requestIds) {
        uint256[5] memory _max;
        uint256[5] memory _index;
        (_max, _index) = Utilities.getMax5(self.requestQ);
        for(uint i=0;i<5;i++){
            if(_max[i] != 0){
                _requestIds[i] = self.requestIdByRequestQIndex[_index[i]];
            }
            else{
                _requestIds[i] = self.currentMiners[4-i].value;
            }
        }
    }


   
}