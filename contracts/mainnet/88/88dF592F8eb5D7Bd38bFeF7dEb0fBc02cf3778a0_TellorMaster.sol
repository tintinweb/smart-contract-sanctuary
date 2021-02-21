// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

import "./TellorStorage.sol";
import "./TellorVariables.sol";

/**
 * @title Tellor Master
 * @dev This is the Master contract with all tellor getter functions and delegate call to Tellor.
 * The logic for the functions on this contract is saved on the TellorGettersLibrary, TellorTransfer,
 * TellorGettersLibrary, and TellorStake
 */
contract TellorMaster is TellorStorage, TellorVariables {
    event NewTellorAddress(address _newTellor);

    constructor(address _tContract, address _oTellor) {
        addresses[_OWNER] = msg.sender;
        addresses[_DEITY] = msg.sender;
        addresses[_TELLOR_CONTRACT] = _tContract;
        addresses[_OLD_TELLOR] = _oTellor;
        bytesVars[_CURRENT_CHALLENGE] = bytes32("1");
        uints[_DIFFICULTY] = 100;
        uints[_TIME_TARGET] = 240;
        uints[_TARGET_MINERS] = 200;
        uints[_CURRENT_REWARD] = 1e18;
        uints[_DISPUTE_FEE] = 500e18;
        uints[_STAKE_AMOUNT] = 500e18;
        uints[_TIME_OF_LAST_NEW_VALUE] = block.timestamp - 240;

        currentMiners[0].value = 1;
        currentMiners[1].value = 2;
        currentMiners[2].value = 3;
        currentMiners[3].value = 4;
        currentMiners[4].value = 5;

        // Bootstraping Request Queue
        for (uint256 index = 1; index < 51; index++) {
            Request storage req = requestDetails[index];
            req.apiUintVars[_REQUEST_Q_POSITION] = index;
            requestIdByRequestQIndex[index] = index;
        }

        assembly {
            sstore(_EIP_SLOT, _tContract)
        }

        emit NewTellorAddress(_tContract);
    }

    /**
     * @dev This function allows the Deity to set a new deity
     * @param _newDeity the new Deity in the contract
     */
    function changeDeity(address _newDeity) external {
        require(msg.sender == addresses[_DEITY]);
        addresses[_DEITY] = _newDeity;
    }

    /**
     * @dev This function allows the owner to set a new _owner
     * @param _newOwner the new Owner in the contract
     */
    function changeOwner(address _newOwner) external {
        require(msg.sender == addresses[_OWNER]);
        addresses[_OWNER] = _newOwner;
    }

    /**
     * @dev  allows for the deity to make fast upgrades.  Deity should be 0 address if decentralized
     * @param _tContract the address of the new Tellor Contract
     */
    function changeTellorContract(address _tContract) external {
        require(msg.sender == addresses[_DEITY]);
        addresses[_TELLOR_CONTRACT] = _tContract;

        assembly {
            sstore(_EIP_SLOT, _tContract)
        }
    }

    /**
     * @dev This is the internal function that allows for delegate calls to the Tellor logic
     * contract address
     */
    function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(
                gas(),
                implementation,
                0,
                calldatasize(),
                0,
                0
            )

            // Copy the returned data.
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

    /**
     * @dev This is the fallback function that allows contracts to call the tellor
     * contract at the address stored
     */
    fallback() external payable {
        address addr = addresses[_TELLOR_CONTRACT];
        _delegate(addr);
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