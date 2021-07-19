/**
 *Submitted for verification at BscScan.com on 2021-07-19
*/

// Sources flattened with hardhat v2.4.3 https://hardhat.org

// File contracts/zap-miner/libraries/SafeMathM.sol

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


// File contracts/zap-miner/libraries/ZapStorage.sol

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


// File contracts/zap-miner/libraries/ZapTransfer.sol

pragma solidity =0.5.16;


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