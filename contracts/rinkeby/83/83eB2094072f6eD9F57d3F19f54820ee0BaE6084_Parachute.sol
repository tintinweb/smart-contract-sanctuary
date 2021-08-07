//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.3;

import "contracts/tellor3/ITellor.sol";
import "contracts/tellor3/TellorStorage.sol";

contract Parachute is TellorStorage {
  address constant tellorMaster = 0x88dF592F8eb5D7Bd38bFeF7dEb0fBc02cf3778a0;
  address constant multis = 0x39E419bA25196794B595B2a595Ea8E527ddC9856;
  bytes32 challenge;
  uint256 challengeUpdate;

  /**
   * @dev Use this function to end parachutes ability to reinstate Tellor's admin key
   */
  function killContract() external {
    require(msg.sender == multis,"only multis wallet can call this");
    ITellor(tellorMaster).changeDeity(address(0));
  }

  /**
   * @dev This function allows the Tellor Team to migrate old TRB token to the new one
   * @param _destination is the destination adress to migrate tokens to
   * @param _amount is the amount of tokens to migrate
   */
  function migrateFor(address _destination,uint256 _amount) external {
    require(msg.sender == multis,"only multis wallet can call this");
    ITellor(tellorMaster).transfer(_destination, _amount);
  }

  /**
   * @dev This function allows the Tellor community to reinstate and admin key if an attacker
   * is able to get 51% or more of the total TRB supply.
   * @param _tokenHolder address to check if they hold more than 51% of TRB
   */
  function rescue51PercentAttack(address _tokenHolder) external {
    require(
      ITellor(tellorMaster).balanceOf(_tokenHolder) * 100 / ITellor(tellorMaster).totalSupply() >= 51,
      "attacker balance is < 51% of total supply"
    );
    ITellor(tellorMaster).changeDeity(multis);
  }

  /**
   * @dev Allows the TellorTeam to reinstate the admin key if a long time(timeBeforeRescue)
   * has gone by without a value being added on-chain
   */
  function rescueBrokenDataReporting() external {
    bytes32 _newChallenge;
    (_newChallenge,,,) = ITellor(tellorMaster).getNewCurrentVariables();
    if(_newChallenge == challenge){
      if(block.timestamp - challengeUpdate > 7 days){
        ITellor(tellorMaster).changeDeity(multis);
      }
    }
    else{
      challenge = _newChallenge;
      challengeUpdate = block.timestamp;
    }
  }

  /**
   * @dev Allows the Tellor community to reinstate the admin key if tellor is updated
   * to an invalid address.
   */
  function rescueFailedUpdate() external {
    (bool success, bytes memory data) =
        address(tellorMaster).call(
            abi.encodeWithSelector(0xfc735e99, "") //verify() signature
        );
    uint _val;
    if(data.length > 0){
      _val = abi.decode(data, (uint256));
    }
    require(!success || _val < 2999,"new tellor is valid");
    ITellor(tellorMaster).changeDeity(multis);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

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
        returns (uint256[5] memory idsOnDeck, uint256[5] memory tipsOnDeck);

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
pragma solidity 0.8.3;

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

{
  "optimizer": {
    "enabled": true,
    "runs": 200
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