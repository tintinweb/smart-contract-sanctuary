/* _____              _
  / ____|            | |
 | |     ___ _ __ ___| |__  _ __ _   _ _ __ ___
 | |    / _ \ '__/ _ \ '_ \| '__| | | | '_ ` _ \
 | |___|  __/ | |  __/ |_) | |  | |_| | | | | | |
  \_____\___|_|  \___|_.__/|_|   \__,_|_| |_| |_|
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
pragma experimental ABIEncoderV2;

contract CerebrumMeta {
    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    struct MetaTransaction {
        uint256 nonce;
        address from;
    }

    mapping(address => uint256) public nonces;
    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(bytes("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"));
    bytes32 internal constant META_TRANSACTION_TYPEHASH = keccak256(bytes("MetaTransaction(uint256 nonce,address from)"));
    bytes32 internal DOMAIN_SEPARATOR = keccak256(abi.encode(
        EIP712_DOMAIN_TYPEHASH,
    		keccak256(bytes("Cerebrum")),
    		keccak256(bytes("1")),
    		80001,
    		address(this)
    ));
}

contract Cerebrum is CerebrumMeta {

    struct Task {
        uint256 taskID;
        uint256 currentRound;
        uint256 totalRounds;
        uint256 cost;
        string[] modelHashes;
    }

    address public owner;
    address public coordinatorAddress = 0xBeb71662FF9c08aFeF3866f85A6591D4aeBE6e4E;

    uint256 public nextTaskID = 1;
    mapping (uint256 => Task) public CerebrumTasks;
    mapping (address => uint256[]) public UserTaskIDs;
    mapping (address => string[]) public UserFiles;

    event newTaskCreated(uint256 indexed taskID, address indexed _user, string _modelHash, uint256 _amt, uint256 _time);
    event modelUpdated(uint256 indexed taskID, string _modelHash, uint256 _time);
    event fileAdded(address indexed _user, string _fileHash, uint256 _time);

    modifier onlyOwner () {
      require(msg.sender == owner);
      _;
    }
    modifier onlyCoordinator () {
      require(msg.sender == coordinatorAddress);
      _;
    }

    constructor(address _coordinatorAddress) {
        owner = msg.sender;
        coordinatorAddress = _coordinatorAddress;
    }

    function updateCoordinator(address _coordinatorAddress)
        public onlyOwner
    {
        coordinatorAddress = _coordinatorAddress;
    }

    function createTask(string memory _modelHash, uint256 _rounds)
        public payable
    {
        require(_rounds < 10, "Number of Rounds should be less than 10");
        uint256 taskCost = msg.value;

        Task memory newTask;
        newTask = Task({
            taskID: nextTaskID,
            currentRound: 1,
            totalRounds: _rounds,
            cost: taskCost,
            modelHashes: new string[](_rounds)
        });
        newTask.modelHashes[0] = _modelHash;
        CerebrumTasks[nextTaskID] = newTask;
        UserTaskIDs[msg.sender].push(nextTaskID);
        emit newTaskCreated(nextTaskID, msg.sender, _modelHash, taskCost, block.timestamp);

        nextTaskID = nextTaskID + 1;
    }

    function updateModelForTask(uint256 _taskID,  string memory _modelHash, address payable computer)
        public onlyCoordinator
    {
        require(_taskID <= nextTaskID, "Invalid Task ID");
        uint256 newRound = CerebrumTasks[_taskID].currentRound + 1;
        require(newRound <= CerebrumTasks[_taskID].totalRounds, "All Rounds Completed");


        CerebrumTasks[_taskID].currentRound = newRound;
        CerebrumTasks[_taskID].modelHashes[newRound - 1] = _modelHash;
        computer.transfer(CerebrumTasks[_taskID].cost / CerebrumTasks[_taskID].totalRounds);
        emit modelUpdated(_taskID, _modelHash, block.timestamp);

    }

    function getTaskHashes(uint256 _taskID) public view returns (string[] memory) {
        return (CerebrumTasks[_taskID].modelHashes);
    }

    function getTaskCount() public view returns (uint256) {
        return nextTaskID - 1;
    }
    function getTasksOfUser() public view returns (uint256[] memory) {
        return UserTaskIDs[msg.sender];
    }

    function storeFile(string memory _fileHash) public {
        UserFiles[msg.sender].push(_fileHash);
        emit fileAdded(msg.sender, _fileHash, block.timestamp);
    }

    function getFiles() public view returns (string[] memory){
        return UserFiles[msg.sender];
    }

}

{
  "optimizer": {
    "enabled": true,
    "runs": 99999
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