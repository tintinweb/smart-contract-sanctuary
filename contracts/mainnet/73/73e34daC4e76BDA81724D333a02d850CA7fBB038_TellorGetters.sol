// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;
import "./SafeMath.sol";
import "./TellorStorage.sol";
import "./TellorVariables.sol";
import "./Utilities.sol";

/**
 * @title Tellor Getters
 * @dev Oracle contract with all tellor getter functions
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
        public
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
        public
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
     * @return value for timestamp of last proof of work submitted
     * @return true if the is a timestamp for the lastNewValue
     */
    function getLastNewValue() external view returns (uint256, bool) {
        return (
            retrieveData(
                requestIdByTimestamp[uints[_TIME_OF_LAST_NEW_VALUE]],
                uints[_TIME_OF_LAST_NEW_VALUE]
            ),
            true
        );
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
     * @dev Getter function for requestId based on timestamp
     * @param _timestamp to check requestId
     * @return uint of requestId
     */
    function getRequestIdByTimestamp(uint256 _timestamp)
        external
        view
        returns (uint256)
    {
        return requestIdByTimestamp[_timestamp];
    }

    /**
     * @dev Getter function for the requestQ array
     * @return the requestQ array
     */
    function getRequestQ() public view returns (uint256[51] memory) {
        return requestQ;
    }

    /**
     * @dev Allows access to the uint variables saved in the apiUintVars under the requestDetails struct
     * for the requestId specified
     * @param _requestId to look up
     * @param _data the variable to pull from the mapping. _data = keccak256("variable_name") where variable_name is
     * the variables/strings used to save the data in the mapping. The variables names are
     * commented out under the apiUintVars under the requestDetails struct
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
    function getUintVar(bytes32 _data) public view returns (uint256) {
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
        (_max, _index) = getMax5(requestQ);
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

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

/**
 * @title Tellor Oracle Storage Library
 * @dev Contains all the variables/structs used by Tellor
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
        //Each of the variables below is saved in the mapping disputeUintVars for each disputeID
        //e.g. TellorStorageStruct.DisputeById[disputeID].disputeUintVars[keccak256("requestId")]
        //These are the variables saved in this mapping:
        // uint keccak256("requestId");//apiID of disputed value
        // uint keccak256("timestamp");//timestamp of disputed value
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
        uint256[] requestTimestamps; //array of all newValueTimestamps requested
        mapping(bytes32 => uint256) apiUintVars;
        //Each of the variables below is saved in the mapping apiUintVars for each api request
        //e.g. requestDetails[_requestId].apiUintVars[keccak256("totalTip")]
        //These are the variables saved in this mapping:
        // uint keccak256("requestQPosition"); //index in requestQ
        // uint keccak256("totalTip");//bonus portion of payout
        mapping(uint256 => uint256) minedBlockNum; //[apiId][minedTimestamp]=>block.number
        //This the time series of finalValues stored by the contract where uint UNIX timestamp is mapped to value
        mapping(uint256 => uint256) finalValues;
        mapping(uint256 => bool) inDispute; //checks if API id is in dispute or finalized.
        mapping(uint256 => address[5]) minersByValue;
        mapping(uint256 => uint256[5]) valuesByTimestamp;
    }

    uint256[51] requestQ; //uint50 array of the top50 requests by payment amount
    uint256[] public newValueTimestamps; //array of all timestamps requested
    //Address fields in the Tellor contract are saved the addressVars mapping
    //e.g. addressVars[keccak256("tellorContract")] = address
    //These are the variables saved in this mapping:
    // address keccak256("tellorContract");//Tellor address
    // address  keccak256("_owner");//Tellor Owner address
    // address  keccak256("_deity");//Tellor Owner that can do things at will
    // address  keccak256("pending_owner"); // The proposed new owner
    //uint fields in the Tellor contract are saved the uintVars mapping
    //e.g. uintVars[keccak256("decimals")] = uint
    //These are the variables saved in this mapping:
    // keccak256("decimals");    //18 decimal standard ERC20
    // keccak256("disputeFee");//cost to dispute a mined value
    // keccak256("disputeCount");//totalHistoricalDisputes
    // keccak256("total_supply"); //total_supply of the token in circulation
    // keccak256("stakeAmount");//stakeAmount for miners (we can cut gas if we just hardcoded it in...or should it be variable?)
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

// Helper contract to store hashes of variables
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
    bytes32 constant _FEE =
        0x1da95f11543c9b03927178e07951795dfc95c7501a9d1cf00e13414ca33bc409; //keccak256("FEE");
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

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

//Functions for retrieving min and Max in 51 length array (requestQ)
//Taken partly from: https://github.com/modular-network/ethereum-libraries-array-utils/blob/master/contracts/Array256Lib.sol

contract Utilities {
    /**
     * @dev This is an internal function called by updateOnDeck that gets the top 5 values
     * @param data is an array [51] to determine the top 5 values from
     * @return max the top 5 values and their index values in the data array
     */
    function getMax5(uint256[51] memory data)
        public
        view
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