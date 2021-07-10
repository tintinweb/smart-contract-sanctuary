pragma solidity =0.5.16;

import './libraries/SafeMathM.sol';
import './ZapMaster.sol';

contract Vault {
    using SafeMathM for uint256;

    address public zapToken;
    ZapMaster zapMaster;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => bool)) keys;

    uint256 constant MAX_INT = 2**256 - 1;

    constructor (address token, address master) public {
        zapToken = token;
        zapMaster = ZapMaster(address(uint160(master)));
        
        token.call(abi.encodeWithSignature("approve(address,uint256)", master, MAX_INT));
    }

    function increaseApproval() public returns (bool) {
        (bool s, bytes memory balance) = zapToken.call(abi.encodeWithSignature("allowance(address,address)", address(this), zapMaster));
        uint256 amount = MAX_INT.sub(toUint256(balance, 0));
        (bool success, bytes memory data) = zapToken.call(abi.encodeWithSignature("increaseApproval(address,uint256)", zapMaster, amount));
        return success;
    }

    function lockSmith(address miniVault, address authorizedUser) public {
        require(msg.sender == miniVault, "You do not own this vault.");
        require(msg.sender != address(0) || miniVault != msg.sender, "The zero address can not own a vault.");

        // gives the mini-vault owner keys if they don't already have
        if (!keys[miniVault][msg.sender]){
            keys[miniVault][miniVault] = true;
        }

        keys[miniVault][authorizedUser] = true;
    }

    function hasAccess(address user, address miniVault) public view returns (bool) {
        require(msg.sender != address(0) || miniVault != msg.sender, "The zero address does not own a vault.");
        return keys[miniVault][user];
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function deposit(address userAddress, uint256 value) public {
        require(userAddress != address(0), "The zero address does not own a vault.");
        require(hasAccess(msg.sender, userAddress), "You are not authorized to access this vault.");
        balances[userAddress] = balances[userAddress].add(value);
    }

    function withdraw(address userAddress, uint256 value) public {
        require(userAddress != address(0), "The zero address does not own a vault.");
        require(hasAccess(msg.sender, userAddress), "You are not authorized to access this vault.");
        require(userBalance(userAddress) >= value, "Your balance is insufficient.");
        balances[userAddress] = balances[userAddress].sub(value);
    }

    function userBalance(address userAddress) public view returns (uint256 balance) {
        return balances[userAddress];
    }
}

pragma solidity =0.5.16;

//Slightly modified SafeMath library - includes a min and max function, removes useless div function
library SafeMathM {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
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
}

pragma solidity =0.5.16;

import './ZapGetters.sol';

/**
 * @title Zap Master
 * @dev This is the Master contract with all zap getter functions and delegate call to Zap.
 * The logic for the functions on this contract is saved on the ZapGettersLibrary, ZapTransfer,
 * ZapGettersLibrary, and ZapStake
 */
contract ZapMaster is ZapGetters {
    event NewZapAddress(address _newZap);

    /**
     * @dev The constructor sets the original `zapStorageOwner` of the contract to the sender
     * account, the zap contract to the Zap master address and owner to the Zap master owner address
     * @param _zapContract is the address for the zap contract
     */
    constructor(address _zapContract, address tokenAddress)
        public
        ZapGetters(tokenAddress)
    {
        zap.init();
        zap.addressVars[keccak256('_owner')] = msg.sender;
        zap.addressVars[keccak256('_deity')] = msg.sender;
        zap.addressVars[keccak256('zapContract')] = _zapContract;
        zap.addressVars[keccak256('zapTokenContract')] = tokenAddress;

        emit NewZapAddress(_zapContract);
    }

    /**
     * @dev Gets the 5 miners who mined the value for the specified requestId/_timestamp
     * @dev Only needs to be in library
     * @param _newDeity the new Deity in the contract
     */

    function changeDeity(address _newDeity) external {
        zap.changeDeity(_newDeity);
    }

    /**
     * @dev  allows for the deity to make fast upgrades.  Deity should be 0 address if decentralized
     * @param _zapContract the address of the new Zap Contract
     */
    function changeZapContract(address _zapContract) external {
        zap.changeZapContract(_zapContract);
    }

    /**
     * @dev  allows for the deity to make fast upgrades.  Deity should be 0 address if decentralized
     * @param _vaultContract the address of the new Vault Contract
     */
    function changeVaultContract(address _vaultContract) external {
        zap.changeVaultContract(_vaultContract);
    }

    /**
     * @dev This is the fallback function that allows contracts to call the zap contract at the address stored
     */
    function() external payable {
        address addr = zap.addressVars[keccak256('zapContract')];
        bytes memory _calldata = msg.data;
        assembly {
            let result := delegatecall(
                not(0),
                addr,
                add(_calldata, 0x20),
                mload(_calldata),
                0,
                0
            )
            let size := returndatasize
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, size)
            // revert instead of invalid() bc if the underlying call failed with invalid() it already wasted gas.
            // if the call returned error data, forward it
            switch result
            case 0 {
                revert(ptr, size)
            }
            default {
                return(ptr, size)
            }
        }
    }
}

pragma solidity =0.5.16;

import './libraries/SafeMathM.sol';
import './libraries/ZapStorage.sol';
import './libraries/ZapTransfer.sol';
import './libraries/ZapGettersLibrary.sol';
import './libraries/ZapStake.sol';
import '../token/ZapTokenBSC.sol';

/**
 * @title Zap Getters
 * @dev Oracle contract with all zap getter functions. The logic for the functions on this contract
 * is saved on the ZapGettersLibrary, ZapTransfer, ZapGettersLibrary, and ZapStake
 */
contract ZapGetters {
    using SafeMathM for uint256;

    using ZapTransfer for ZapStorage.ZapStorageStruct;
    using ZapGettersLibrary for ZapStorage.ZapStorageStruct;
    using ZapStake for ZapStorage.ZapStorageStruct;

    ZapStorage.ZapStorageStruct zap;
    ZapTokenBSC token;

    constructor(address zapTokenBsc) public {
        token = ZapTokenBSC(zapTokenBsc);
    }

    /**
     * @param _user address
     * @param _spender address
     * @return Returns the remaining allowance of tokens granted to the _spender from the _user
     */
    function allowance(address _user, address _spender)
        public
        view
        returns (uint256)
    {
        //    return zap.allowance(_user,_spender);
        return token.allowance(_user, _spender);
    }

    /**
     * @dev This function returns whether or not a given user is allowed to trade a given amount
     * @param _user address
     * @param _amount uint of amount
     * @return true if the user is alloed to trade the amount specified
     */
    function allowedToTrade(address _user, uint256 _amount)
        external
        view
        returns (bool)
    {
        return zap.allowedToTrade(_user, _amount);
    }

    /**
     * @dev Gets balance of owner specified
     * @param _user is the owner address used to look up the balance
     * @return Returns the balance associated with the passed in _user
     */
    function balanceOf(address _user) public view returns (uint256) {
        // return zap.balanceOf(_user);
        return token.balanceOf(_user);
    }

    /**
     * @dev Queries the balance of _user at a specific _blockNumber
     * @param _user The address from which the balance will be retrieved
     * @param _blockNumber The block number when the balance is queried
     * @return The balance at _blockNumber
     */
    // function balanceOfAt(address _user, uint _blockNumber) external view returns (uint) {
    //     return zap.balanceOfAt(_user,_blockNumber);
    // }

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
        return zap.didMine(_challenge, _miner);
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
        return zap.didVote(_disputeId, _address);
    }

    /**
     * @dev allows Zap to read data from the addressVars mapping
     * @param _data is the keccak256("variable_name") of the variable that is being accessed.
     * These are examples of how the variables are saved within other functions:
     * addressVars[keccak256("_owner")]
     * addressVars[keccak256("zapContract")]
     */
    function getAddressVars(bytes32 _data) external view returns (address) {
        return zap.getAddressVars(_data);
    }

    /**
     * @dev Gets all dispute variables
     * @param _disputeId to look up
     * @return bytes32 hash of dispute
     * @return bool executed where true if it has been voted on
     * @return bool disputeVotePassed
     * @return bool isPropFork true if the dispute is a proposed fork
     * @return address of reportedMiner
     * @return address of reportingParty
     * @return address of proposedForkAddress
     * @return uint of requestId
     * @return uint of timestamp
     * @return uint of value
     * @return uint of minExecutionDate
     * @return uint of numberOfVotes
     * @return uint of blocknumber
     * @return uint of minerSlot
     * @return uint of quorum
     * @return uint of fee
     * @return int count of the current tally
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
        return zap.getAllDisputeVars(_disputeId);
    }

    /**
     * @dev Getter function for variables for the requestId being currently mined(currentRequestId)
     * @return current challenge, curretnRequestId, level of difficulty, api/query string, and granularity(number of decimals requested), total tip for the request
     */
    function getCurrentVariables()
        external
        view
        returns (
            bytes32,
            uint256,
            uint256,
            string memory,
            uint256,
            uint256
        )
    {
        return zap.getCurrentVariables();
    }

    /**
     * @dev Checks if a given hash of miner,requestId has been disputed
     * @param _hash is the sha256(abi.encodePacked(_miners[2],_requestId));
     * @return uint disputeId
     */
    function getDisputeIdByDisputeHash(bytes32 _hash)
        external
        view
        returns (uint256)
    {
        return zap.getDisputeIdByDisputeHash(_hash);
    }

    /**
     * @dev Checks for uint variables in the disputeUintVars mapping based on the disuputeId
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
        return zap.getDisputeUintVars(_disputeId, _data);
    }

    /**
     * @dev Gets the a value for the latest timestamp available
     * @return value for timestamp of last proof of work submited
     * @return true if the is a timestamp for the lastNewValue
     */
    function getLastNewValue() external view returns (uint256, bool) {
        return zap.getLastNewValue();
    }

    /**
     * @dev Gets the a value for the latest timestamp available
     * @param _requestId being requested
     * @return value for timestamp of last proof of work submited and if true if it exist or 0 and false if it doesn't
     */
    function getLastNewValueById(uint256 _requestId)
        external
        view
        returns (uint256, bool)
    {
        return zap.getLastNewValueById(_requestId);
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
        return zap.getMinedBlockNum(_requestId, _timestamp);
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
        return zap.getMinersByRequestIdAndTimestamp(_requestId, _timestamp);
    }

    /**
     * @dev Get the name of the token
     * return string of the token name
     */
    function getName() external view returns (string memory) {
        return zap.getName();
    }

    /**
     * @dev Counts the number of values that have been submited for the request
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
        return zap.getNewValueCountbyRequestId(_requestId);
    }

    /**
     * @dev Getter function for the specified requestQ index
     * @param _index to look up in the requestQ array
     * @return uint of reqeuestId
     */
    function getRequestIdByRequestQIndex(uint256 _index)
        external
        view
        returns (uint256)
    {
        return zap.getRequestIdByRequestQIndex(_index);
    }

    /**
     * @dev Getter function for requestId based on timestamp
     * @param _timestamp to check requestId
     * @return uint of reqeuestId
     */
    function getRequestIdByTimestamp(uint256 _timestamp)
        external
        view
        returns (uint256)
    {
        return zap.getRequestIdByTimestamp(_timestamp);
    }

    /**
     * @dev Getter function for requestId based on the queryHash
     * @param _request is the hash(of string api and granularity) to check if a request already exists
     * @return uint requestId
     */
    function getRequestIdByQueryHash(bytes32 _request)
        external
        view
        returns (uint256)
    {
        return zap.getRequestIdByQueryHash(_request);
    }

    /**
     * @dev Getter function for the requestQ array
     * @return the requestQ arrray
     */
    function getRequestQ() public view returns (uint256[51] memory) {
        return zap.getRequestQ();
    }

    /**
     * @dev Allowes access to the uint variables saved in the apiUintVars under the requestDetails struct
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
        return zap.getRequestUintVars(_requestId, _data);
    }

    /**
     * @dev Gets the API struct variables that are not mappings
     * @param _requestId to look up
     * @return string of api to query
     * @return string of symbol of api to query
     * @return bytes32 hash of string
     * @return bytes32 of the granularity(decimal places) requested
     * @return uint of index in requestQ array
     * @return uint of current payout/tip for this requestId
     */
    function getRequestVars(uint256 _requestId)
        external
        view
        returns (
            string memory,
            string memory,
            bytes32,
            uint256,
            uint256,
            uint256
        )
    {
        return zap.getRequestVars(_requestId);
    }

    /**
     * @dev This function allows users to retireve all information about a staker
     * @param _staker address of staker inquiring about
     * @return uint current state of staker
     * @return uint startDate of staking
     */
    function getStakerInfo(address _staker)
        external
        view
        returns (uint256, uint256)
    {
        return zap.getStakerInfo(_staker);
    }

    /**
     * @dev Gets the 5 miners who mined the value for the specified requestId/_timestamp
     * @param _requestId to look up
     * @param _timestamp is the timestampt to look up miners for
     * @return address[5] array of 5 addresses ofminers that mined the requestId
     */
    function getSubmissionsByTimestamp(uint256 _requestId, uint256 _timestamp)
        external
        view
        returns (uint256[5] memory)
    {
        return zap.getSubmissionsByTimestamp(_requestId, _timestamp);
    }

    /**
     * @dev Get the symbol of the token
     * return string of the token symbol
     */
    function getSymbol() external view returns (string memory) {
        return zap.getSymbol();
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
        return zap.getTimestampbyRequestIDandIndex(_requestID, _index);
    }

    /**
     * @dev Getter for the variables saved under the ZapStorageStruct uintVars variable
     * @param _data the variable to pull from the mapping. _data = keccak256("variable_name") where variable_name is
     * the variables/strings used to save the data in the mapping. The variables names are
     * commented out under the uintVars under the ZapStorageStruct struct
     * This is an example of how data is saved into the mapping within other functions:
     * self.uintVars[keccak256("stakerCount")]
     * @return uint of specified variable
     */
    function getUintVar(bytes32 _data) public view returns (uint256) {
        return zap.getUintVar(_data);
    }

    /**
     * @dev Getter function for next requestId on queue/request with highest payout at time the function is called
     * @return onDeck/info on request with highest payout-- RequestId, Totaltips, and API query string
     */
    function getVariablesOnDeck()
        external
        view
        returns (
            uint256,
            uint256,
            string memory
        )
    {
        return zap.getVariablesOnDeck();
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
        return zap.isInDispute(_requestId, _timestamp);
    }

    /**
     * @dev Retreive value from oracle based on timestamp
     * @param _requestId being requested
     * @param _timestamp to retreive data/value from
     * @return value for timestamp submitted
     */
    function retrieveData(uint256 _requestId, uint256 _timestamp)
        external
        view
        returns (uint256)
    {
        return zap.retrieveData(_requestId, _timestamp);
    }

    /**
     * @dev Getter for the total_supply of oracle tokens
     * @return uint total supply
     */
    function totalTokenSupply() external view returns (uint256) {
        return zap.totalSupply();
        // return token.totalSupply;
    }
}

pragma solidity ^0.5.1;

/**
 * @title Zap Oracle Storage Library
 * @dev Contains all the variables/structs used by Zap
 */

// Libraries contain reusable Solidity types
library ZapStorage {
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
        //e.g. ZapStorageStruct.DisputeById[disputeID].disputeUintVars[keccak256("requestId")]
        //These are the variables saved in this mapping:
        // uint keccak256("requestId");//apiID of disputed value
        // uint keccak256("timestamp");//timestamp of distputed value
        // uint keccak256("value"); //the value being disputed
        // uint keccak256("minExecutionDate");//7 days from when dispute initialized
        // uint keccak256("numberOfVotes");//the number of parties who have voted on the measure
        // uint keccak256("blockNumber");// the blocknumber for which votes will be calculated from
        // uint keccak256("minerSlot"); //index in dispute array
        // uint keccak256("quorum"); //quorum for dispute vote NEW
        // uint keccak256("fee"); //fee paid corresponding to dispute
        mapping(address => bool) voted; //mapping of address to whether or not they voted
    }

    struct StakeInfo {
        uint256 currentStatus; //0-not Staked, 1=Staked, 2=LockedForWithdraw 3= OnDispute
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
        mapping(uint256 => uint256) finalValues; //This the time series of finalValues stored by the contract where uint UNIX timestamp is mapped to value
        mapping(uint256 => bool) inDispute; //checks if API id is in dispute or finalized.
        mapping(uint256 => address[5]) minersByValue;
        mapping(uint256 => uint256[5]) valuesByTimestamp;
    }

    struct ZapStorageStruct {
        bytes32 currentChallenge; //current challenge to be solved
        uint256[51] requestQ; //uint50 array of the top50 requests by payment amount
        uint256[] newValueTimestamps; //array of all timestamps requested
        Details[5] currentMiners; //This struct is for organizing the five mined values to find the median
        mapping(bytes32 => address) addressVars;
        //Address fields in the Zap contract are saved the addressVars mapping
        //e.g. addressVars[keccak256("zapContract")] = address
        //These are the variables saved in this mapping:
        // address keccak256("zapContract");//Zap address
        // address  keccak256("zapTokenContract");//ZapToken address
        // address  keccak256("_owner");//Zap Owner address
        // address  keccak256("_deity");//Zap Owner that can do things at will
        // address  keccak256("_vault");//Address of the vault contract set in Zap.sol
        mapping(bytes32 => uint256) uintVars;
        //uint fields in the Zap contract are saved the uintVars mapping
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
        // keccak256("currentMinerReward"); //The last reward given to miners on creation of a new block
        mapping(bytes32 => mapping(address => bool)) minersByChallenge; //This is a boolean that tells you if a given challenge has been completed by a given miner
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

pragma solidity =0.5.16;

import './SafeMathM.sol';
import './ZapStorage.sol';

/**
 * @title Zap Transfer
 * @dev Contais the methods related to transfers and ERC20. Zap.sol and ZapGetters.sol
 * reference this library for function's logic.
 */
library ZapTransfer {
    using SafeMathM for uint256;

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    ); //ERC20 Approval event
    event Transfer(address indexed _from, address indexed _to, uint256 _value); //ERC20 Transfer Event

    /*Functions*/

    /**
     * @param _user address of party with the balance
     * @param _spender address of spender of parties said balance
     * @return Returns the remaining allowance of tokens granted to the _spender from the _user
     */
    function allowance(
        ZapStorage.ZapStorageStruct storage self,
        address _user,
        address _spender
    ) public view returns (uint256) {
        return self.allowed[_user][_spender];
    }

    /**
     * @dev Completes POWO transfers by updating the balances on the current block number
     * @param _from address to transfer from
     * @param _to addres to transfer to
     * @param _amount to transfer
     */
    function doTransfer(
        ZapStorage.ZapStorageStruct storage self,
        address _from,
        address _to,
        uint256 _amount
    ) public {
        require(_amount > 0);
        require(_to != address(0));
        require(allowedToTrade(self, _from, _amount)); //allowedToTrade checks the stakeAmount is removed from balance if the _user is staked
        uint256 previousBalance = balanceOfAt(self, _from, block.number);
        updateBalanceAtNow(self.balances[_from], previousBalance - _amount);
        previousBalance = balanceOfAt(self, _to, block.number);
        require(previousBalance + _amount >= previousBalance); // Check for overflow
        updateBalanceAtNow(self.balances[_to], previousBalance + _amount);
        previousBalance = balanceOfAt(self, _to, block.number);
        emit Transfer(_from, _to, _amount);
    }

    /**
     * @dev Queries the balance of _user at a specific _blockNumber
     * @param _user The address from which the balance will be retrieved
     * @param _blockNumber The block number when the balance is queried
     * @return The balance at _blockNumber specified
     */
    function balanceOfAt(
        ZapStorage.ZapStorageStruct storage self,
        address _user,
        uint256 _blockNumber
    ) public view returns (uint256) {
        if (
            (self.balances[_user].length == 0) ||
            (self.balances[_user][0].fromBlock > _blockNumber)
        ) {
            return 0;
        } else {
            return getBalanceAt(self.balances[_user], _blockNumber);
        }
    }

    /**
     * @dev Getter for balance for owner on the specified _block number
     * @param checkpoints gets the mapping for the balances[owner]
     * @param _block is the block number to search the balance on
     * @return the balance at the checkpoint
     */
    function getBalanceAt(
        ZapStorage.Checkpoint[] storage checkpoints,
        uint256 _block
    ) public view returns (uint256) {
        if (checkpoints.length == 0) return 0;
        if (_block >= checkpoints[checkpoints.length - 1].fromBlock)
            return checkpoints[checkpoints.length - 1].value;
        if (_block < checkpoints[0].fromBlock) return 0;
        // Binary search of the value in the array
        uint256 min = 0;
        uint256 max = checkpoints.length - 1;
        while (max > min) {
            uint256 mid = (max + min + 1) / 2;
            if (checkpoints[mid].fromBlock <= _block) {
                min = mid;
            } else {
                max = mid - 1;
            }
        }
        return checkpoints[min].value;
    }

    /**
     * @dev This function returns whether or not a given user is allowed to trade a given amount
     * and removing the staked amount from their balance if they are staked
     * @param _user address of user
     * @param _amount to check if the user can spend
     * @return true if they are allowed to spend the amount being checked
     */
    function allowedToTrade(
        ZapStorage.ZapStorageStruct storage self,
        address _user,
        uint256 _amount
    ) public view returns (bool) {
        if (self.stakerDetails[_user].currentStatus > 0) {
            //Removes the stakeAmount from balance if the _user is staked
            if (
                balanceOfAt(self, _user, block.number).sub(_amount) >= 0
                // .sub(self.uintVars[keccak256('stakeAmount')])
            ) {
                return true;
            }
        } else if (balanceOfAt(self, _user, block.number).sub(_amount) >= 0) {
            return true;
        }
        return false;
    }

    /**
     * @dev Updates balance for from and to on the current block number via doTransfer
     * @param checkpoints gets the mapping for the balances[owner]
     * @param _value is the new balance
     */
    function updateBalanceAtNow(
        ZapStorage.Checkpoint[] storage checkpoints,
        uint256 _value
    ) public {
        if (
            (checkpoints.length == 0) ||
            (checkpoints[checkpoints.length - 1].fromBlock < block.number)
        ) {
            ZapStorage.Checkpoint storage newCheckPoint = checkpoints[
                checkpoints.length++
            ];
            newCheckPoint.fromBlock = uint128(block.number);
            newCheckPoint.value = uint128(_value);
        } else {
            ZapStorage.Checkpoint storage oldCheckPoint = checkpoints[
                checkpoints.length - 1
            ];
            oldCheckPoint.value = uint128(_value);
        }
    }
}

pragma solidity =0.5.16;

import './SafeMathM.sol';
import './ZapStorage.sol';
import './Utilities.sol';

/**
 * @title Zap Getters Library
 * @dev This is the getter library for all variables in the Zap Token system. ZapGetters references this
 * libary for the getters logic
 */
library ZapGettersLibrary {
    using SafeMathM for uint256;

    event NewZapAddress(address _newZap); //emmited when a proposed fork is voted true

    /*Functions*/

    //The next two functions are onlyOwner functions.  For Zap to be truly decentralized, we will need to transfer the Deity to the 0 address.
    //Only needs to be in library
    /**
     * @dev This function allows us to set a new Deity (or remove it)
     * @param _newDeity address of the new Deity of the zap system
     */
    function changeDeity(
        ZapStorage.ZapStorageStruct storage self,
        address _newDeity
    ) internal {
        require(self.addressVars[keccak256('_deity')] == msg.sender);
        self.addressVars[keccak256('_deity')] = _newDeity;
    }

    //Only needs to be in library
    /**
     * @dev This function allows the deity to upgrade the Zap System
     * @param _zapContract address of new updated ZapCore contract
     */
    function changeZapContract(
        ZapStorage.ZapStorageStruct storage self,
        address _zapContract
    ) internal {
        require(self.addressVars[keccak256('_deity')] == msg.sender);
        self.addressVars[keccak256('zapContract')] = _zapContract;
        emit NewZapAddress(_zapContract);
    }

    function changeVaultContract(
        ZapStorage.ZapStorageStruct storage self,
        address _vaultAddress
    ) internal {
        require(self.addressVars[keccak256('_owner')] == msg.sender);
        self.addressVars[keccak256('_vault')] = _vaultAddress;
    }

    /*Zap Getters*/

    /**
     * @dev This function tells you if a given challenge has been completed by a given miner
     * @param _challenge the challenge to search for
     * @param _miner address that you want to know if they solved the challenge
     * @return true if the _miner address provided solved the
     */
    function didMine(
        ZapStorage.ZapStorageStruct storage self,
        bytes32 _challenge,
        address _miner
    ) internal view returns (bool) {
        return self.minersByChallenge[_challenge][_miner];
    }

    /**
     * @dev Checks if an address voted in a dispute
     * @param _disputeId to look up
     * @param _address of voting party to look up
     * @return bool of whether or not party voted
     */
    function didVote(
        ZapStorage.ZapStorageStruct storage self,
        uint256 _disputeId,
        address _address
    ) internal view returns (bool) {
        return self.disputesById[_disputeId].voted[_address];
    }

    /**
     * @dev allows Zap to read data from the addressVars mapping
     * @param _data is the keccak256("variable_name") of the variable that is being accessed.
     * These are examples of how the variables are saved within other functions:
     * addressVars[keccak256("_owner")]
     * addressVars[keccak256("zapContract")]
     */
    function getAddressVars(
        ZapStorage.ZapStorageStruct storage self,
        bytes32 _data
    ) internal view returns (address) {
        return self.addressVars[_data];
    }

    /**
     * @dev Gets all dispute variables
     * @param _disputeId to look up
     * @return bytes32 hash of dispute
     * @return bool executed where true if it has been voted on
     * @return bool disputeVotePassed
     * @return bool isPropFork true if the dispute is a proposed fork
     * @return address of reportedMiner
     * @return address of reportingParty
     * @return address of proposedForkAddress
     * @return uint of requestId
     * @return uint of timestamp
     * @return uint of value
     * @return uint of minExecutionDate
     * @return uint of numberOfVotes
     * @return uint of blocknumber
     * @return uint of minerSlot
     * @return uint of quorum
     * @return uint of fee
     * @return int count of the current tally
     */
    function getAllDisputeVars(
        ZapStorage.ZapStorageStruct storage self,
        uint256 _disputeId
    )
        internal
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
        ZapStorage.Dispute storage disp = self.disputesById[_disputeId];
        return (
            disp.hash,
            disp.executed,
            disp.disputeVotePassed,
            disp.isPropFork,
            disp.reportedMiner,
            disp.reportingParty,
            disp.proposedForkAddress,
            [
                disp.disputeUintVars[keccak256('requestId')],
                disp.disputeUintVars[keccak256('timestamp')],
                disp.disputeUintVars[keccak256('value')],
                disp.disputeUintVars[keccak256('minExecutionDate')],
                disp.disputeUintVars[keccak256('numberOfVotes')],
                disp.disputeUintVars[keccak256('blockNumber')],
                disp.disputeUintVars[keccak256('minerSlot')],
                disp.disputeUintVars[keccak256('quorum')],
                disp.disputeUintVars[keccak256('fee')]
            ],
            disp.tally
        );
    }

    /**
     * @dev Getter function for variables for the requestId being currently mined(currentRequestId)
     * @return current challenge, curretnRequestId, level of difficulty, api/query string, and granularity(number of decimals requested), total tip for the request
     */
    function getCurrentVariables(ZapStorage.ZapStorageStruct storage self)
        internal
        view
        returns (
            bytes32,
            uint256,
            uint256,
            string memory,
            uint256,
            uint256
        )
    {
        return (
            self.currentChallenge,
            self.uintVars[keccak256('currentRequestId')],
            self.uintVars[keccak256('difficulty')],
            self
                .requestDetails[self.uintVars[keccak256('currentRequestId')]]
                .queryString,
            self
                .requestDetails[self.uintVars[keccak256('currentRequestId')]]
                .apiUintVars[keccak256('granularity')],
            self
                .requestDetails[self.uintVars[keccak256('currentRequestId')]]
                .apiUintVars[keccak256('totalTip')]
        );
    }

    /**
     * @dev Checks if a given hash of miner,requestId has been disputed
     * @param _hash is the sha256(abi.encodePacked(_miners[2],_requestId));
     * @return uint disputeId
     */
    function getDisputeIdByDisputeHash(
        ZapStorage.ZapStorageStruct storage self,
        bytes32 _hash
    ) internal view returns (uint256) {
        return self.disputeIdByDisputeHash[_hash];
    }

    /**
     * @dev Checks for uint variables in the disputeUintVars mapping based on the disuputeId
     * @param _disputeId is the dispute id;
     * @param _data the variable to pull from the mapping. _data = keccak256("variable_name") where variable_name is
     * the variables/strings used to save the data in the mapping. The variables names are
     * commented out under the disputeUintVars under the Dispute struct
     * @return uint value for the bytes32 data submitted
     */
    function getDisputeUintVars(
        ZapStorage.ZapStorageStruct storage self,
        uint256 _disputeId,
        bytes32 _data
    ) internal view returns (uint256) {
        return self.disputesById[_disputeId].disputeUintVars[_data];
    }

    /**
     * @dev Gets the a value for the latest timestamp available
     * @return value for timestamp of last proof of work submited
     * @return true if the is a timestamp for the lastNewValue
     */
    function getLastNewValue(ZapStorage.ZapStorageStruct storage self)
        internal
        view
        returns (uint256, bool)
    {
        return (
            retrieveData(
                self,
                self.requestIdByTimestamp[
                    self.uintVars[keccak256('timeOfLastNewValue')]
                ],
                self.uintVars[keccak256('timeOfLastNewValue')]
            ),
            true
        );
    }

    /**
     * @dev Gets the a value for the latest timestamp available
     * @param _requestId being requested
     * @return value for timestamp of last proof of work submited and if true if it exist or 0 and false if it doesn't
     */
    function getLastNewValueById(
        ZapStorage.ZapStorageStruct storage self,
        uint256 _requestId
    ) internal view returns (uint256, bool) {
        ZapStorage.Request storage _request = self.requestDetails[_requestId];
        if (_request.requestTimestamps.length > 0) {
            return (
                retrieveData(
                    self,
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
    function getMinedBlockNum(
        ZapStorage.ZapStorageStruct storage self,
        uint256 _requestId,
        uint256 _timestamp
    ) internal view returns (uint256) {
        return self.requestDetails[_requestId].minedBlockNum[_timestamp];
    }

    /**
     * @dev Gets the 5 miners who mined the value for the specified requestId/_timestamp
     * @param _requestId to look up
     * @param _timestamp is the timestamp to look up miners for
     * @return the 5 miners' addresses
     */
    function getMinersByRequestIdAndTimestamp(
        ZapStorage.ZapStorageStruct storage self,
        uint256 _requestId,
        uint256 _timestamp
    ) internal view returns (address[5] memory) {
        return self.requestDetails[_requestId].minersByValue[_timestamp];
    }

    /**
     * @dev Get the name of the token
     * @return string of the token name
     */
    function getName(ZapStorage.ZapStorageStruct storage self)
        internal
        pure
        returns (string memory)
    {
        return 'Zap BEP20';
    }

    /**
     * @dev Counts the number of values that have been submited for the request
     * if called for the currentRequest being mined it can tell you how many miners have submitted a value for that
     * request so far
     * @param _requestId the requestId to look up
     * @return uint count of the number of values received for the requestId
     */
    function getNewValueCountbyRequestId(
        ZapStorage.ZapStorageStruct storage self,
        uint256 _requestId
    ) internal view returns (uint256) {
        return self.requestDetails[_requestId].requestTimestamps.length;
    }

    /**
     * @dev Getter function for the specified requestQ index
     * @param _index to look up in the requestQ array
     * @return uint of reqeuestId
     */
    function getRequestIdByRequestQIndex(
        ZapStorage.ZapStorageStruct storage self,
        uint256 _index
    ) internal view returns (uint256) {
        require(_index <= 50);
        return self.requestIdByRequestQIndex[_index];
    }

    /**
     * @dev Getter function for requestId based on timestamp
     * @param _timestamp to check requestId
     * @return uint of reqeuestId
     */
    function getRequestIdByTimestamp(
        ZapStorage.ZapStorageStruct storage self,
        uint256 _timestamp
    ) internal view returns (uint256) {
        return self.requestIdByTimestamp[_timestamp];
    }

    /**
     * @dev Getter function for requestId based on the qeuaryHash
     * @param _queryHash hash(of string api and granularity) to check if a request already exists
     * @return uint requestId
     */
    function getRequestIdByQueryHash(
        ZapStorage.ZapStorageStruct storage self,
        bytes32 _queryHash
    ) internal view returns (uint256) {
        return self.requestIdByQueryHash[_queryHash];
    }

    /**
     * @dev Getter function for the requestQ array
     * @return the requestQ arrray
     */
    function getRequestQ(ZapStorage.ZapStorageStruct storage self)
        internal
        view
        returns (uint256[51] memory)
    {
        return self.requestQ;
    }

    /**
     * @dev Allowes access to the uint variables saved in the apiUintVars under the requestDetails struct
     * for the requestId specified
     * @param _requestId to look up
     * @param _data the variable to pull from the mapping. _data = keccak256("variable_name") where variable_name is
     * the variables/strings used to save the data in the mapping. The variables names are
     * commented out under the apiUintVars under the requestDetails struct
     * @return uint value of the apiUintVars specified in _data for the requestId specified
     */
    function getRequestUintVars(
        ZapStorage.ZapStorageStruct storage self,
        uint256 _requestId,
        bytes32 _data
    ) internal view returns (uint256) {
        return self.requestDetails[_requestId].apiUintVars[_data];
    }

    /**
     * @dev Gets the API struct variables that are not mappings
     * @param _requestId to look up
     * @return string of api to query
     * @return string of symbol of api to query
     * @return bytes32 hash of string
     * @return bytes32 of the granularity(decimal places) requested
     * @return uint of index in requestQ array
     * @return uint of current payout/tip for this requestId
     */
    function getRequestVars(
        ZapStorage.ZapStorageStruct storage self,
        uint256 _requestId
    )
        internal
        view
        returns (
            string memory,
            string memory,
            bytes32,
            uint256,
            uint256,
            uint256
        )
    {
        ZapStorage.Request storage _request = self.requestDetails[_requestId];
        return (
            _request.queryString,
            _request.dataSymbol,
            _request.queryHash,
            _request.apiUintVars[keccak256('granularity')],
            _request.apiUintVars[keccak256('requestQPosition')],
            _request.apiUintVars[keccak256('totalTip')]
        );
    }

    /**
     * @dev This function allows users to retireve all information about a staker
     * @param _staker address of staker inquiring about
     * @return uint current state of staker
     * @return uint startDate of staking
     */
    function getStakerInfo(
        ZapStorage.ZapStorageStruct storage self,
        address _staker
    ) internal view returns (uint256, uint256) {
        return (
            self.stakerDetails[_staker].currentStatus,
            self.stakerDetails[_staker].startDate
        );
    }

    /**
     * @dev Gets the 5 miners who mined the value for the specified requestId/_timestamp
     * @param _requestId to look up
     * @param _timestamp is the timestampt to look up miners for
     * @return address[5] array of 5 addresses ofminers that mined the requestId
     */
    function getSubmissionsByTimestamp(
        ZapStorage.ZapStorageStruct storage self,
        uint256 _requestId,
        uint256 _timestamp
    ) internal view returns (uint256[5] memory) {
        return self.requestDetails[_requestId].valuesByTimestamp[_timestamp];
    }

    /**
     * @dev Get the symbol of the token
     * @return string of the token symbol
     */
    function getSymbol(ZapStorage.ZapStorageStruct storage self)
        internal
        pure
        returns (string memory)
    {
        return 'ZAPB';
    }

    /**
     * @dev Gets the timestamp for the value based on their index
     * @param _requestID is the requestId to look up
     * @param _index is the value index to look up
     * @return uint timestamp
     */
    function getTimestampbyRequestIDandIndex(
        ZapStorage.ZapStorageStruct storage self,
        uint256 _requestID,
        uint256 _index
    ) internal view returns (uint256) {
        return self.requestDetails[_requestID].requestTimestamps[_index];
    }

    /**
     * @dev Getter for the variables saved under the ZapStorageStruct uintVars variable
     * @param _data the variable to pull from the mapping. _data = keccak256("variable_name") where variable_name is
     * the variables/strings used to save the data in the mapping. The variables names are
     * commented out under the uintVars under the ZapStorageStruct struct
     * This is an example of how data is saved into the mapping within other functions:
     * self.uintVars[keccak256("stakerCount")]
     * @return uint of specified variable
     */
    function getUintVar(ZapStorage.ZapStorageStruct storage self, bytes32 _data)
        internal
        view
        returns (uint256)
    {
        return self.uintVars[_data];
    }

    /**
     * @dev Getter function for next requestId on queue/request with highest payout at time the function is called
     * @return onDeck/info on request with highest payout-- RequestId, Totaltips, and API query string
     */
    function getVariablesOnDeck(ZapStorage.ZapStorageStruct storage self)
        internal
        view
        returns (
            uint256,
            uint256,
            string memory
        )
    {
        uint256 newRequestId = getTopRequestID(self);
        return (
            newRequestId,
            self.requestDetails[newRequestId].apiUintVars[
                keccak256('totalTip')
            ],
            self.requestDetails[newRequestId].queryString
        );
    }

    /**
     * @dev Getter function for the request with highest payout. This function is used withing the getVariablesOnDeck function
     * @return uint _requestId of request with highest payout at the time the function is called
     */
    function getTopRequestID(ZapStorage.ZapStorageStruct storage self)
        internal
        view
        returns (uint256 _requestId)
    {
        uint256 _max;
        uint256 _index;
        (_max, _index) = Utilities.getMax(self.requestQ);
        _requestId = self.requestIdByRequestQIndex[_index];
    }

    /**
     * @dev Gets the 5 miners who mined the value for the specified requestId/_timestamp
     * @param _requestId to look up
     * @param _timestamp is the timestamp to look up miners for
     * @return bool true if requestId/timestamp is under dispute
     */
    function isInDispute(
        ZapStorage.ZapStorageStruct storage self,
        uint256 _requestId,
        uint256 _timestamp
    ) internal view returns (bool) {
        return self.requestDetails[_requestId].inDispute[_timestamp];
    }

    /**
     * @dev Retreive value from oracle based on requestId/timestamp
     * @param _requestId being requested
     * @param _timestamp to retreive data/value from
     * @return uint value for requestId/timestamp submitted
     */
    function retrieveData(
        ZapStorage.ZapStorageStruct storage self,
        uint256 _requestId,
        uint256 _timestamp
    ) internal view returns (uint256) {
        return self.requestDetails[_requestId].finalValues[_timestamp];
    }

    /**
     * @dev Getter for the total_supply of oracle tokens
     * @return uint total supply
     */
    function totalSupply(ZapStorage.ZapStorageStruct storage self)
        internal
        view
        returns (uint256)
    {
        return self.uintVars[keccak256('total_supply')];
    }
}

pragma solidity =0.5.16;

import "./ZapStorage.sol";
import "./ZapTransfer.sol";
import "./ZapDispute.sol";
// import "hardhat/console.sol";

/**
* @title Zap Dispute
* @dev Contais the methods related to miners staking and unstaking. Zap.sol 
* references this library for function's logic.
*/

library ZapStake {
    event NewStake(address indexed _sender);//Emits upon new staker
    event StakeWithdrawn(address indexed _sender);//Emits when a staker is now no longer staked
    event StakeWithdrawRequested(address indexed _sender);//Emits when a staker begins the 7 day withdraw period

    /*Functions*/
    
    /**
    * @dev This function stakes the five initial miners, sets the supply and all the constant variables.
    * This function is called by the constructor function on ZapMaster.sol
    */
    function init(ZapStorage.ZapStorageStruct storage self) public{
        require(self.uintVars[keccak256("decimals")] == 0);
        //Give this contract 10000000 Zap Token as the starting balance within Zap-Miner

        ZapTransfer.updateBalanceAtNow(self.balances[address(this)], 10000000);

        // //the initial 5 miner addresses are specfied below
        // //changed payable[5] to 6
        address payable[6] memory _initalMiners = [
            address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266),
            address(0xcd3B766CCDd6AE721141F452C550Ca635964ce71),
            address(0x2546BcD3c84621e976D8185a91A922aE77ECEc30),
            address(0xbDA5747bFD65F08deb54cb465eB87D40e51B197E),
            address(0xdD2FD4581271e230360230F9337D5c0430Bf44C0),
            address(0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199)
        ];
        //Stake each of the 5 miners specified above
        for(uint i=0;i<6;i++){//6th miner to allow for dispute
            //Miner balance is set at 1000 at the block that this function is ran
            ZapTransfer.updateBalanceAtNow(self.balances[_initalMiners[i]],500000);

            newStake(self, _initalMiners[i]);
        }

        //update the total suppply
        self.uintVars[keccak256("total_supply")] += 3000000;//6th miner to allow for dispute
        //set Constants
        self.uintVars[keccak256("decimals")] = 18;
        self.uintVars[keccak256("targetMiners")] = 200;
        self.uintVars[keccak256("stakeAmount")] = 500000;
        self.uintVars[keccak256("disputeFee")] = 970;
        self.uintVars[keccak256("timeTarget")]= 600;
        self.uintVars[keccak256("timeOfLastNewValue")] = now - now  % self.uintVars[keccak256("timeTarget")];
        self.uintVars[keccak256("difficulty")] = 1;
    }


    /**
    * @dev This function allows stakers to request to withdraw their stake (no longer stake)
    * once they lock for withdraw(stakes.currentStatus = 2) they are locked for 7 days before they
    * can withdraw the deposit
    */
    function requestStakingWithdraw(ZapStorage.ZapStorageStruct storage self) public {
        ZapStorage.StakeInfo storage stakes = self.stakerDetails[msg.sender];
        //Require that the miner is staked
        require(stakes.currentStatus == 1);

        //Change the miner staked to locked to be withdrawStake
        stakes.currentStatus = 2;

        //Change the startDate to now since the lock up period begins now
        //and the miner can only withdraw 7 days later from now(check the withdraw function)
        stakes.startDate = now -(now % 86400);

        //Reduce the staker count
        self.uintVars[keccak256("stakerCount")] -= 1;
        ZapDispute.updateDisputeFee(self);
        emit StakeWithdrawRequested(msg.sender);
    }

    /**
    * @dev This function allows users to withdraw their stake after a 7 day waiting period from request 
    */
    function withdrawStake(ZapStorage.ZapStorageStruct storage self) public {
        ZapStorage.StakeInfo storage stakes = self.stakerDetails[msg.sender];
        //Require the staker has locked for withdraw(currentStatus ==2) and that 7 days have 
        //passed by since they locked for withdraw
        require(now - (now % 86400) - stakes.startDate >= 7 days, "Can't withdraw yet. Need to wait at LEAST 7 days from stake start date.");
        require(stakes.currentStatus == 2);
        stakes.currentStatus = 0;

        /*
            NOT TOTALLY SURE OF THESE FUNCTON NAMES.
            BUT THE LOGIC SHOULD BE SOMETHING LIKE THIS...
            // msg.sender is the staker that wants to withdraw their tokens
            previousBalance = balanceOf(msg.sender); // grab the balance of the staker
            updateBalanceAtNow(self.balancecs(msg.sender), previousBalance) // update 
            tranferFrom(vault, msg.sender);
            
            // updates the storage portion that keeps track of balances at a block. set it to 0 since staker is unstaking
            updateBalanceAtNow(self.balancecs(msg.sender), 0) 
        */
        emit StakeWithdrawn(msg.sender);
    }

    /**
    * @dev This function allows miners to deposit their stake.
    */
    function depositStake(ZapStorage.ZapStorageStruct storage self) public {
      newStake(self, msg.sender);
      //self adjusting disputeFee
      ZapDispute.updateDisputeFee(self);
    }

    /**
    * @dev This function is used by the init function to succesfully stake the initial 5 miners.
    * The function updates their status/state and status start date so they are locked it so they can't withdraw
    * and updates the number of stakers in the system.
    */
    function newStake(ZapStorage.ZapStorageStruct storage self, address staker) internal {
        // require(ZapTransfer.balanceOf(self,staker) >= self.uintVars[keccak256("stakeAmount")]);
        //Ensure they can only stake if they are not currrently staked or if their stake time frame has ended
        //and they are currently locked for witdhraw
        require(self.stakerDetails[staker].currentStatus == 0 || self.stakerDetails[staker].currentStatus == 2);
        self.uintVars[keccak256("stakerCount")] += 1;
        self.stakerDetails[staker] = ZapStorage.StakeInfo({
            currentStatus: 1,
            //this resets their stake start date to today
            startDate: now - (now % 86400)
        });
        // self.uintVars[keccak256("stakeAmount")]
        ZapTransfer.updateBalanceAtNow(self.balances[staker], self.uintVars[keccak256("stakeAmount")]);

        emit NewStake(staker);
    }

     /**
    * @dev Getter function for the requestId being mined 
    * @return variables for the current minin event: Challenge, 5 RequestId, difficulty and Totaltips
    */
    function getNewCurrentVariables(ZapStorage.ZapStorageStruct storage self) internal view returns(bytes32 _challenge,uint[5] memory _requestIds,uint256 _difficulty, uint256 _tip){
        for(uint i=0;i<5;i++){
            _requestIds[i] =  self.currentMiners[i].value;
        }
        return (self.currentChallenge,_requestIds,self.uintVars[keccak256("difficulty")],self.uintVars[keccak256("currentTotalTips")]);
    }
}

pragma solidity =0.5.16;



library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        uint256 c = a * b;

        assert(a == 0 || c / a == b);

        return c;

    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {

        // assert(b > 0); // Solidity automatically throws when dividing by 0

        uint256 c = a / b;

        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;

    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {

        assert(b <= a);

        return a - b;

    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {

        uint256 c = a + b;

        assert(c >= a);

        return c;

    }

}



 contract ERC20Basic {

    uint256 public _totalSupply = 100000000000000000000000000;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address who)  public view returns (uint256);

    function transfer(address to, uint256 value)  public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

}



/**

 * @title ERC20 interface

 * @dev see https://github.com/ethereum/EIPs/issues/20

 */

 contract ERC20 is ERC20Basic {

    function allowance(address owner, address spender)  public view returns (uint256);

    function transferFrom(address from, address to, uint256 value)  public returns (bool);

    function approve(address spender, uint256 value)  public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);

}



contract BasicToken is ERC20Basic {

    using SafeMath for uint256;

    mapping(address => uint256) balances;

    /**

    * @dev transfer token for a specified address

    * @param _to The address to transfer to.

    * @param _value The amount to be transferred.

    */

    function transfer(address _to, uint256 _value)  public returns (bool) {

        require(_to != address(0));

        // SafeMath.sub will throw if there is not enough balance.

        balances[msg.sender] = balances[msg.sender].sub(_value);

        balances[_to] = balances[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);

        return true;

    }

    /**

    * @dev Gets the balance of the specified address.

    * @param _owner The address to query the the balance of.

    * @return balance : An uint256 representing the amount owned by the passed address.

    */

    function balanceOf(address _owner)  public view returns (uint256 balance) {

        return balances[_owner];

    }

}

contract Ownable {
    address payable public owner;
    event OwnershipTransferred(address indexed previousOwner,address indexed newOwner);

    /// @dev The Ownable constructor sets the original `owner` of the contract to the sender account.
    constructor() public { owner = msg.sender; }

    function getOwner() external view returns (address) {
        return owner;
    }

    /// @dev Throws if called by any contract other than latest designated caller
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /// @dev Allows the current owner to transfer control of the contract to a newOwner.
    /// @param newOwner The address to transfer ownership to.
    function transferOwnership(address payable newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract StandardToken is ERC20, BasicToken {

    using SafeMath for uint256;

    mapping (address => mapping (address => uint256)) allowed;

    /**

     * @dev Transfer tokens from one address to another

     * @param _from address The address which you want to send tokens from

     * @param _to address The address which you want to transfer to

     * @param _value uint256 the amount of tokens to be transferred

     */

    function transferFrom(address _from, address _to, uint256 _value)  public returns (bool) {

        require(_to != address(0));

        uint256 _allowance = allowed[_from][msg.sender];

        // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met

        // require (_value <= _allowance);

        balances[_from] = balances[_from].sub(_value);

        balances[_to] = balances[_to].add(_value);

        allowed[_from][msg.sender] = _allowance.sub(_value);

        emit Transfer(_from, _to, _value);

        return true;

    }

    /**

     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.

     *

     * Beware that changing an allowance with this method brings the risk that someone may use both the old

     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this

     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:

     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729

     * @param _spender The address which will spend the funds.

     * @param _value The amount of tokens to be spent.

     */

    function approve(address _spender, uint256 _value)  public returns (bool) {

        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;

    }

    /**

     * @dev Function to check the amount of tokens that an owner allowed to a spender.

     * @param _owner address The address which owns the funds.

     * @param _spender address The address which will spend the funds.

     * @return remaining A uint256 specifying the amount of tokens still available for the spender.

     */

    function allowance(address _owner, address _spender)  public view returns (uint256 remaining) {

        return allowed[_owner][_spender];

    }

    /**

     * approve should be called when allowed[_spender] == 0. To increment

     * allowed value is better to use this function to avoid 2 calls (and wait until

     * the first transaction is mined)

     * From MonolithDAO Token.sol

     */

    function increaseApproval (address _spender, uint _addedValue) public

        returns (bool success) {

        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);

        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

        return true;

    }

    function decreaseApproval (address _spender, uint _subtractedValue) public

        returns (bool success) {

        uint oldValue = allowed[msg.sender][_spender];

        if (_subtractedValue > oldValue) {

            allowed[msg.sender][_spender] = 0;

        } else {

            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);

        }

        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

        return true;

    }

}



contract MintableToken is StandardToken, Ownable {

    using SafeMath for uint256;

    event Mint(address indexed to, uint256 amount);

    event MintFinished();

    bool public mintingFinished = false;

    modifier canMint() {

        require(!mintingFinished);

        _;

    }



    /**

     * @dev Function to mint tokens

     * @param _to The address that will receive the minted tokens.

     * @param _amount The amount of tokens to mint.

     * @return A boolean that indicates if the operation was successful.

     */

    function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {

        _totalSupply = _totalSupply.add(_amount);

        balances[_to] = balances[_to].add(_amount);

        emit Mint(_to, _amount);

        emit Transfer(address(0), _to, _amount);

        return true;

    }



    /**

     * @dev Function to stop minting new tokens.

     * @return True if the operation was successful.

     */

    function finishMinting() onlyOwner public returns (bool) {

        mintingFinished = true;

        emit MintFinished();

        return true;

    }

}



contract ZapTokenBSC is MintableToken {

    string public _name = "Zap BEP20";

    string public _symbol = "ZAPB";

    uint8 public _decimals = 18;

    constructor() public {
        balances[msg.sender] = _totalSupply;
        
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8) {
    return _decimals;
  }

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory) {
    return _symbol;
  }

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory) {
    return _name;
  }

    function allocate(address to, uint amount) public{

        mint(to,amount);

    }

}

pragma solidity =0.5.16;

//Functions for retrieving min and Max in 51 length array (requestQ)
//Taken partly from: https://github.com/modular-network/ethereum-libraries-array-utils/blob/master/contracts/Array256Lib.sol

library Utilities {
    /// @dev Returns the minimum value and position in an array.
    //@note IT IGNORES THE 0 INDEX
    function getMin(uint256[51] memory arr)
        internal
        pure
        returns (uint256 min, uint256 minIndex)
    {
        assembly {
            minIndex := 50
            min := mload(add(arr, mul(minIndex, 0x20)))
            for {
                let i := 49
            } gt(i, 0) {
                i := sub(i, 1)
            } {
                let item := mload(add(arr, mul(i, 0x20)))
                if lt(item, min) {
                    min := item
                    minIndex := i
                }
            }
        }
    }

    // function getMin(uint[51] memory data) internal pure returns(uint256 minimal,uint minIndex) {
    //       minIndex = data.length - 1;
    //       minimal = data[minIndex];
    //       for(uint i = data.length-1;i > 0;i--) {
    //           if(data[i] < minimal) {
    //               minimal = data[i];
    //               minIndex = i;
    //           }
    //       }
    // }

    function getMax(uint256[51] memory arr)
        internal
        pure
        returns (uint256 max, uint256 maxIndex)
    {
        assembly {
            for {
                let i := 0
            } lt(i, 51) {
                i := add(i, 1)
            } {
                let item := mload(add(arr, mul(i, 0x20)))
                if lt(max, item) {
                    max := item
                    maxIndex := i
                }
            }
        }
    }
}

pragma solidity =0.5.16;

import './ZapStorage.sol';
import './ZapTransfer.sol';

/**
 * @title Zap Dispute
 * @dev Contais the methods related to disputes. Zap.sol references this library for function's logic.
 */

library ZapDispute {
    using SafeMathM for uint256;

    event NewDispute(
        uint256 indexed _disputeId,
        uint256 indexed _requestId,
        uint256 _timestamp,
        address _miner
    ); //emitted when a new dispute is initialized
    event Voted(
        uint256 indexed _disputeID,
        bool _position,
        address indexed _voter
    ); //emitted when a new vote happens
    event DisputeVoteTallied(
        uint256 indexed _disputeID,
        int256 _result,
        address indexed _reportedMiner,
        address _reportingParty,
        bool _active
    ); //emitted upon dispute tally
    event NewZapAddress(address _newZap); //emmited when a proposed fork is voted true

    /*Functions*/

    /**
     * @dev Allows token holders to vote
     * @param _disputeId is the dispute id
     * @param _supportsDispute is the vote (true=the dispute has basis false = vote against dispute)
     */
    function vote(
        ZapStorage.ZapStorageStruct storage self,
        uint256 _disputeId,
        bool _supportsDispute
    ) public {
        ZapStorage.Dispute storage disp = self.disputesById[_disputeId];

        //Get the voteWeight or the balance of the user at the time/blockNumber the disupte began
        uint256 voteWeight = ZapTransfer.balanceOfAt(
            self,
            msg.sender,
            disp.disputeUintVars[keccak256('blockNumber')]
        );

        //Require that the msg.sender has not voted
        require(disp.voted[msg.sender] != true);

        //Requre that the user had a balance >0 at time/blockNumber the disupte began
        require(voteWeight > 0);

        //ensures miners that are under dispute cannot vote
        require(self.stakerDetails[msg.sender].currentStatus != 3);

        //Update user voting status to true
        disp.voted[msg.sender] = true;

        //Update the number of votes for the dispute
        disp.disputeUintVars[keccak256('numberOfVotes')] += 1;

        //Update the quorum by adding the voteWeight
        disp.disputeUintVars[keccak256('quorum')] += voteWeight;

        //If the user supports the dispute increase the tally for the dispute by the voteWeight
        //otherwise decrease it
        if (_supportsDispute) {
            disp.tally = disp.tally + int256(voteWeight);
        } else {
            disp.tally = disp.tally - int256(voteWeight);
        }

        //Let the network know the user has voted on the dispute and their casted vote
        emit Voted(_disputeId, _supportsDispute, msg.sender);
    }

    /**
     * @dev tallies the votes.
     * @param _disputeId is the dispute id
     */
    function tallyVotes(
        ZapStorage.ZapStorageStruct storage self,
        uint256 _disputeId
    ) public returns (address _from, address _to, uint _disputeFee) {

        ZapStorage.Dispute storage disp = self.disputesById[_disputeId];
        ZapStorage.Request storage _request = self.requestDetails[
            disp.disputeUintVars[keccak256('requestId')]
        ];

        
        uint disputeFeeForDisputeId = disp.disputeUintVars[keccak256("fee")];
        address disputeFeeWinnerAddress;
        
        //Ensure this has not already been executed/tallied
        require(disp.executed == false);

        //Ensure the time for voting has elapsed
        require(now > disp.disputeUintVars[keccak256('minExecutionDate')]);

        //If the vote is not a proposed fork
        if (disp.isPropFork == false) {
            ZapStorage.StakeInfo storage stakes = self.stakerDetails[
                disp.reportedMiner
            ];
            //If the vote for disputing a value is succesful(disp.tally >0) then unstake the reported
            // miner and transfer the stakeAmount and dispute fee to the reporting party
            if (disp.tally > 0) {
                //Changing the currentStatus and startDate unstakes the reported miner and allows for the
                //transfer of the stakeAmount
                stakes.currentStatus = 0;
                stakes.startDate = now - (now % 86400);

                //Decreases the stakerCount since the miner's stake is being slashed
                self.uintVars[keccak256('stakerCount')]--;
                updateDisputeFee(self);

                //Transfers the StakeAmount from the reported miner to the reporting party
                ZapTransfer.doTransfer(
                    self,
                    disp.reportedMiner,
                    disp.reportingParty,
                    self.uintVars[keccak256('stakeAmount')]
                );


                //Returns the dispute fee to the reporting party
                // don't need to run this because tokens transfer will be an actual state change.
                // ZapTransfer.doTransfer(
                //     self,
                //     address(this),
                //     disp.reportingParty,
                //     disp.disputeUintVars[keccak256('fee')]
                // );
                
                //Set the dispute state to passed/true
                disp.disputeVotePassed = true;

                //If the dispute was succeful(miner found guilty) then update the timestamp value to zero
                //so that users don't use this datapoint
                if (
                    _request.inDispute[
                        disp.disputeUintVars[keccak256('timestamp')]
                    ] == true
                ) {
                    _request.finalValues[
                        disp.disputeUintVars[keccak256('timestamp')]
                    ] = 0;
                }
                

                disputeFeeWinnerAddress = disp.reportingParty;

                // return (address(this), disp.reportingParty, disputeFeeForDisputeId);

                //If the vote for disputing a value is unsuccesful then update the miner status from being on
                //dispute(currentStatus=3) to staked(currentStatus =1) and tranfer the dispute fee to the miner
            } else {
                //Update the miner's current status to staked(currentStatus = 1)
                stakes.currentStatus = 1;

                //tranfer the dispute fee to the miner
                // // token is transfer using token.transferFrom right after tallyVotes() in zap.sol
                // ZapTransfer.doTransfer(
                //     self,
                //     address(this),
                //     disp.reportedMiner,
                //     disp.disputeUintVars[keccak256('fee')]
                // );

                if (
                    _request.inDispute[
                        disp.disputeUintVars[keccak256('timestamp')]
                    ] == true
                ) {
                    _request.inDispute[
                        disp.disputeUintVars[keccak256('timestamp')]
                    ] = false;
                }
                
                disputeFeeWinnerAddress = disp.reportedMiner;

                // return (address(this), disp.reportedMiner, disputeFeeForDisputeId);

            }
            //If the vote is for a proposed fork require a 20% quorum before exceduting the update to the new zap contract address
        } else {
            if (disp.tally > 0) {
                require(
                    disp.disputeUintVars[keccak256('quorum')] >
                        ((self.uintVars[keccak256('total_supply')] * 20) / 100)
                );
                self.addressVars[keccak256('zapContract')] = disp
                .proposedForkAddress;
                disp.disputeVotePassed = true;
                emit NewZapAddress(disp.proposedForkAddress);
            }
        }

        //update the dispute status to executed
        disp.executed = true;
        emit DisputeVoteTallied(
            _disputeId,
            disp.tally,
            disp.reportedMiner,
            disp.reportingParty,
            disp.disputeVotePassed
        );
        return (address(this), disputeFeeWinnerAddress, disputeFeeForDisputeId);
    }

    /**
     * @dev Allows for a fork to be proposed
     * @param _propNewZapAddress address for new proposed Zap
     */
    function proposeFork(
        ZapStorage.ZapStorageStruct storage self,
        address _propNewZapAddress
    ) public {
        bytes32 _hash = keccak256(abi.encodePacked(_propNewZapAddress));
        require(self.disputeIdByDisputeHash[_hash] == 0);
        ZapTransfer.doTransfer(
            self,
            msg.sender,
            address(this),
            self.uintVars[keccak256('disputeFee')]
        ); //This is the fork fee
        self.uintVars[keccak256('disputeCount')]++;
        uint256 disputeId = self.uintVars[keccak256('disputeCount')];
        self.disputeIdByDisputeHash[_hash] = disputeId;
        self.disputesById[disputeId] = ZapStorage.Dispute({
            hash: _hash,
            isPropFork: true,
            reportedMiner: msg.sender,
            reportingParty: msg.sender,
            proposedForkAddress: _propNewZapAddress,
            executed: false,
            disputeVotePassed: false,
            tally: 0
        });
        self.disputesById[disputeId].disputeUintVars[
            keccak256('blockNumber')
        ] = block.number;
        self.disputesById[disputeId].disputeUintVars[keccak256('fee')] = self
        .uintVars[keccak256('disputeFee')];
        self.disputesById[disputeId].disputeUintVars[
            keccak256('minExecutionDate')
        ] = now + 7 days;
    }

    /**
     * @dev this function allows the dispute fee to fluctuate based on the number of miners on the system.
     * The floor for the fee is 15.
     */
    function updateDisputeFee(ZapStorage.ZapStorageStruct storage self) public {
        //if the number of staked miners divided by the target count of staked miners is less than 1
        if (
            (self.uintVars[keccak256('stakerCount')] * 1000) /
                self.uintVars[keccak256('targetMiners')] <
            1000
        ) {
            //Set the dispute fee at stakeAmt * (1- stakerCount/targetMiners)
            //or at the its minimum of 15
            self.uintVars[keccak256('disputeFee')] = SafeMathM.max(
                15,
                self.uintVars[keccak256('stakeAmount')].mul(
                    1000 -
                        (self.uintVars[keccak256('stakerCount')] * 1000) /
                        self.uintVars[keccak256('targetMiners')]
                ) / 1000
            );
        } else {
            //otherwise set the dispute fee at 15 (the floor/minimum fee allowed)
            self.uintVars[keccak256('disputeFee')] = 15;
        }
    }
}