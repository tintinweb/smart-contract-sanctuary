/**
 *Submitted for verification at polygonscan.com on 2021-10-14
*/

// Sources flattened with hardhat v2.6.4 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// File contracts/libraries/MinHeap.sol

/// @title Implementation of a min-heap
/// @author Adrián Calvo (https://github.com/adrianclv)

struct heap{
        // Array of elements with a size of (MAX_ELEMS + 1)
        uint[249] elems;//6049
        uint numElems;
}

library MinHeap{
    // Maximum number of elements allowed in the heap
    uint private constant MAX_ELEMS = 249;

    /// @notice Inserts the element `elem` in the heap
    /// @param elem Element to be inserted
    function insert(heap storage self, uint elem) internal {
        if(self.numElems == MAX_ELEMS) revert();

        self.numElems++;
        self.elems[self.numElems] = elem;

        shiftUp(self, self.numElems);
    }

    /// @notice Deletes the element with the minimum value
    function deleteMin(heap storage self) internal {
        if(self.numElems == 0) revert();

        deletePos(self, 1);
    }

    /// @notice Deletes the element in the position `pos`
    /// @param pos Position of the element to be deleted
    function deletePos(heap storage self, uint pos) internal {
        if(self.numElems < pos) revert();

        self.elems[pos] = self.elems[self.numElems];
        delete self.elems[self.numElems];
        self.numElems--;

        shiftDown(self, pos);
    }

    /// @notice Returns the element with the minimum value
    /// @return The element with the minimum value
    function min(heap storage self) public view returns(uint){
        if(self.numElems == 0) revert();

        return self.elems[1];
    }

    /// @notice Checks if the heap is empty
    /// @return True if there are no elements in the heap
    function isEmpty(heap storage self) public view returns(bool){

        return (self.numElems == 0);
    }

    /* Private functions */

    // Move a element up in the tree
    // Used to restore heap condition after insertion
    function shiftUp(heap storage self, uint pos) internal{
        uint copy = self.elems[pos];

        while(pos != 1 && copy < self.elems[pos/2]){
            self.elems[pos] = self.elems[pos/2];
            pos = pos/2;
        }
        self.elems[pos] = copy;
    }

    // Move a element down in the tree
    // Used to restore heap condition after deletion
    function shiftDown(heap storage self, uint pos) internal{
        uint copy = self.elems[pos];
        bool isHeap = false;

        uint sibling = pos*2;
        while(sibling <= self.numElems && !isHeap){
            if(sibling != self.numElems && self.elems[sibling+1] < self.elems[sibling])
                sibling++;
            if(self.elems[sibling] < copy){
                self.elems[pos] = self.elems[sibling];
                pos = sibling;
                sibling = pos*2;
            }else{
                isHeap = true;
            }
        }
        self.elems[pos] = copy;
    }
}


// File contracts/interfaces/IAccountant.sol



interface IAccountant{
    function platformBurn(address target, uint amount, uint platformID) external;
}


// File @openzeppelin/contracts/utils/[email protected]



/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/[email protected]



/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File contracts/BotRouter.sol

contract BotRouter is Ownable {
    Task[] public taskList;// 0 ID is reserved
    IERC20 DAT;

    mapping(uint => heap) public tierTaskHeap;
    mapping(uint => uint) public tierRewardMultiplier;
    mapping(uint => uint[]) public timeToTaskID;
    mapping(uint => uint) public timeToCounter;
    mapping(uint => bool) public heapTimeScheduled;

    uint public botStake = 1000;
    uint public gasPrice = 100 * 10**9;//in gwei, can be changed by the DAO to up the caller reward for task calls
    uint constant public timeRounding = 1000; //All stored timestamps will have their last 2 0s zeroed out to batch jobs together
    uint constant public maxDelay = 604800; // 1 Week
    uint constant public taskCreationBurnMultiplier = 100 * 10**9; //Multiplied by the gasTank to figure out how much DAT to burn
    address public accountant;
    uint constant public baseGas = 250000;

    mapping(address => bool) public approvedTargets;//gravity vaults, crows contract etc...
    mapping(address => bytes) public targetAdminAddressCall;//gravity vaults, crows contract etc...
    mapping(address => uint) public adminWallet;
    mapping(address => uint) public adminGasRequirement;//variable that records how much gas in total all admin tasks use

    struct Task{
        uint taskTier;//min bot tier required to call this task
        address target;//target address
        bytes taskInput; // bytes data to send with call
        uint desiredFrequency; //time in seconds you want this task called, must be greater than or equal to 300
        address admin; //address of task creator used for task modification
        uint gasTank; //sets the amount of gas calls have, and determines the bots reward, if zero, then gasleft is used to determine gasTank
        bool variableCalling; //bool used to determine whether admin wants the uint returned from task calls to be used to set the next time the task will be called
        uint nextScheduledRunTime;
    }

    struct Bot {
        uint tier;
        uint totalCalls;
        uint withdrawTime; //when a stake withdraw request was made
        uint pendingDAT;
        address admin;
        uint lastCheckinTime;
        uint startTime;
        uint lastReward;
    }

    struct TaskContract{
        bool approved;
        bytes getTargetAdmin;
        uint platformID;
    }
    mapping(address => TaskContract) public targetMap;
    mapping(address => mapping(uint => uint[2])) public botHistory;
    mapping(address => Bot) public bot;
    mapping(uint  => uint) public tierToBotCount;

    mapping(address => uint[]) public adminTaskList;
    mapping(address => address[]) public adminBotList;

    uint constant public baseStakeAmount = 1000;
    uint constant public withdrawTimelock = 604800;//1 Week
    uint public totalTasksCalled;

    event TaskSuccess(uint taskID);
    event TaskFail(uint taskID);

    modifier validTier(uint tier){
        require(tier > 0 && tier < 4, "Invalid tier");
        _;
    }

    modifier withdrawStarted(address _bot){
        require(bot[_bot].withdrawTime == 0, "Forbidden, Cancel Withdraw");
        _;
    }

    constructor(address _DAT) {
        DAT = IERC20(_DAT);
        uint[249] memory heap0;//was 6049
        uint[249] memory heap1;
        uint[249] memory heap2;
        tierTaskHeap[1] = heap({
            elems: heap0,
            numElems: 0
        });
        tierTaskHeap[2] = heap({
            elems: heap1,
            numElems: 0
        });
        tierTaskHeap[3] = heap({
            elems: heap2,
            numElems: 0
        });
        tierRewardMultiplier[1] = 1;
        tierRewardMultiplier[2] = 10;
        tierRewardMultiplier[3] = 100;

        //Create dummy task
        Task memory dummy = Task({
            taskTier: 0,
            target: address(0),
            taskInput: "0x0",
            desiredFrequency: timeRounding,
            admin: address(0),
            gasTank: 0,
            variableCalling: false,
            nextScheduledRunTime: 0
        });
        taskList.push(dummy);

        //create another dummy task used to unschedule tasks
        Task memory dummy1 = Task({
            taskTier: 0,
            target: address(0),
            taskInput: "0x0",
            desiredFrequency: timeRounding,
            admin: address(0),
            gasTank: 0,
            variableCalling: false,
            nextScheduledRunTime: 0
        });
        taskList.push(dummy1);
    }


    //*********************** External Mutative Functions ***********************//
    function addNewTarget(address target, bytes memory data, uint platform) external onlyOwner{
        if(data.length > 0){
            (bool success, ) = target.call{value: 0}(data);
            require(success, "Unable to get admin address from proposed target");
        }
        TaskContract memory newTarget = TaskContract({
            approved: true,
            getTargetAdmin: data,
            platformID: platform
        });
        targetMap[target] = newTarget;
    }

    function setAccountant(address _accountant) external onlyOwner{
        accountant = _accountant;
    }

    function createTask(
        uint _taskTier,
        address _target, 
        bytes memory _taskInput, 
        uint _desiredFrequency, 
        uint _gasTank,
        uint _amountToFund,
        bool _variableCalling
        ) external validTier(_taskTier){

        require(targetMap[_target].approved, 'Target is not approved');
        require(_desiredFrequency >= timeRounding && _desiredFrequency < maxDelay, "Invalid _desiredFrequency");

        DAT.transferFrom(msg.sender, address(this), _amountToFund);
        adminWallet[msg.sender] += _amountToFund;
        bool success;
        bytes memory result;
        if(targetMap[_target].getTargetAdmin.length > 0){
            (success, result) = _target.call{value: 0}(targetMap[_target].getTargetAdmin);
            require(result.length == 20, "Invalid result");//should be length 20 cuz it should return an address
            address admin = abi.decode(result,(address)); //bytesToAddress(result);
            require(msg.sender == admin, "Caller is not contract admin");
        }
        
        //make sure task actually runs
        if(_gasTank == 0){
            uint gasBefore = gasleft();
            (success, result) = _target.call{value: 0}(_taskInput);
            if(_gasTank == 0){_gasTank = gasBefore - gasleft();}
        }
        else{
            (success, result) = _target.call{value: 0, gas: _gasTank}(_taskInput);
        }
        require(success, "Task call failed");
        if(_variableCalling){
            require(result.length == 32, "result is not of length 32");
        }

        IAccountant(accountant).platformBurn(address(this), (taskCreationBurnMultiplier * _gasTank), targetMap[_target].platformID);
        require(adminWallet[msg.sender] >= (_gasTank+baseGas) * gasPrice * tierRewardMultiplier[_taskTier], 'adminWallet not big enough to cover 1 call');

        uint nextTimeToRun = block.timestamp + _desiredFrequency;

        //Create the task
        Task memory newTask = Task({
            taskTier: _taskTier,
            target: _target,
            taskInput: _taskInput,
            desiredFrequency: _desiredFrequency,
            admin: msg.sender,
            gasTank: _gasTank,
            variableCalling: _variableCalling,
            nextScheduledRunTime: nextTimeToRun
        });
        //set up task
        uint taskID = taskList.length;
        taskList.push(newTask);
        
        taskList[taskID].nextScheduledRunTime = addTaskToHeap(nextTimeToRun, taskID, _taskTier);
        adminTaskList[msg.sender].push(taskID);
        adminGasRequirement[msg.sender] += (_gasTank+baseGas) * tierRewardMultiplier[_taskTier];
    }

    function withdrawFromAdminWallet() external{
        if(adminWallet[msg.sender] >= adminGasRequirement[msg.sender]*gasPrice){
            DAT.transfer(msg.sender, (adminWallet[msg.sender] - adminGasRequirement[msg.sender]*gasPrice));
        }
    }

    function updateTask(uint _taskID, uint _gasTank, uint _desiredFrequency) external{
        //should update the reward amount
        Task memory task = taskList[_taskID];
        require(task.admin == msg.sender, "Caller is not task admin");
        require(task.nextScheduledRunTime == 0, "Task is already scheduled to run");
        require(_desiredFrequency >= timeRounding && _desiredFrequency < maxDelay, "Invalid _desiredFrequency");
        //make sure task actually runs
        bool success;
        bytes memory result;
        uint oldGas = task.gasTank;
        if(_gasTank == 0){
            uint gasBefore = gasleft();
            (success, result) = task.target.call{value: 0}(task.taskInput);
            if(_gasTank == 0){_gasTank = gasBefore - gasleft();}
        }
        else{
            (success, result) = task.target.call{value: 0, gas: _gasTank}(task.taskInput);
        }
        require(success, "Task call failed");
        if(task.variableCalling){
            require(result.length == 32, "result is not of length 32");
        }

        uint newGasRequirement = ( adminGasRequirement[msg.sender] + (_gasTank*tierRewardMultiplier[task.taskTier]) ) - (oldGas*tierRewardMultiplier[task.taskTier]);
        require(newGasRequirement*gasPrice <= adminWallet[msg.sender], "Admin wallet doesn't have enough DAT to cover new gas costs");
        task.gasTank = _gasTank;
        task.desiredFrequency = _desiredFrequency;
        adminGasRequirement[msg.sender] = newGasRequirement;

        //schedule it
    }


    function unscheduleTask(uint _taskID) external{
        Task memory task = taskList[_taskID];
        require(task.admin == msg.sender, "Caller is not task admin");
        require(task.nextScheduledRunTime > block.timestamp, "Task is about to run");
        uint time = task.nextScheduledRunTime;
        for(uint i=0; i<timeToTaskID[time].length; i++){
            if(_taskID == timeToTaskID[time][i]){
                timeToTaskID[time][i] = 1;//1 task is the dummy task for unscheduling tasks
                task.nextScheduledRunTime = 0;//set it to sometime in the past
                adminGasRequirement[msg.sender] -= (task.gasTank + baseGas) * tierRewardMultiplier[task.taskTier];
                break;
            }
        }
    }

    function scheduleTask(uint _taskID) external{
        Task memory task = taskList[_taskID];
        require(task.admin == msg.sender, "Caller is not task admin");
        require(task.nextScheduledRunTime == 0, "Task is already scheduled to run");
        require(adminWallet[task.admin] >= adminGasRequirement[task.admin] * gasPrice, "Admin Wallet needs more DAT");
        uint nextTimeToRun = block.timestamp + task.desiredFrequency;
        task.nextScheduledRunTime = addTaskToHeap(nextTimeToRun, _taskID, task.taskTier);
        adminGasRequirement[msg.sender] += (task.gasTank + baseGas) * tierRewardMultiplier[task.taskTier];
    }

    function fundWallet(address _admin, uint _amount) external{
        DAT.transferFrom(msg.sender, address(this), _amount);
        adminWallet[_admin] += _amount;
    }


    function createBot(
        uint _tier,
        address _botAddress
    ) external validTier(_tier){
        require(bot[_botAddress].tier == 0, "Bot already exists");
        DAT.transferFrom(msg.sender, address(this), baseStakeAmount * tierRewardMultiplier[_tier] * 10**18);
        Bot memory newBot = Bot({
            tier: _tier,
            totalCalls: 0,
            withdrawTime: 0,
            pendingDAT: 0,
            admin: msg.sender,
            lastCheckinTime: 0,
            startTime: 0,
            lastReward: 0
        });
        
        bot[_botAddress] = newBot;
        adminBotList[msg.sender].push(_botAddress);
        tierToBotCount[_tier] += 1;
    }

    function checkin() external {
        uint checkinPeriod = block.timestamp / timeRounding;
        checkinPeriod = checkinPeriod * timeRounding;

        if(bot[msg.sender].lastCheckinTime < (checkinPeriod - timeRounding)){
            bot[msg.sender].startTime = checkinPeriod - timeRounding;
        }
        //update the bots times
        bot[msg.sender].lastCheckinTime = checkinPeriod;
    }

    //TODO when I had two bots runnning, it seemed like they would both try to go after the same jobs, and both would print a success message, but looking at the Txs only one of them actually went through the other failed
    function runJob(uint _taskTier) external validTier(_taskTier) withdrawStarted(msg.sender){
        require(msg.sender == tx.origin, 'No Contracts');
        require(bot[msg.sender].tier >= _taskTier, "Proposed bot is not high enough tier");
        //check if bot checked in during the last checkin period
        //if they didn't, then set their startTime to be the last checkin period
        uint checkinPeriod = block.timestamp / timeRounding;
        checkinPeriod = checkinPeriod * timeRounding;

        require(checkinPeriod == bot[msg.sender].lastCheckinTime, "call checkin before running jobs this period");
        //calcualte the bots checkin tally, using the lastCheckinTime, and startTime
        uint checkinTally = (bot[msg.sender].lastCheckinTime - bot[msg.sender].startTime); // / timeRounding;

        //if bot meets tally requirements, then get a taskID
        uint minTally;
        if((block.timestamp - MinHeap.min(tierTaskHeap[_taskTier])) >= timeRounding){//no checks required, allow bot to run job
            minTally = 0;
        }
        else{
            minTally = tierToBotCount[_taskTier] * (timeRounding - (block.timestamp - checkinPeriod) ); // / timeRounding;
        }
        
        if(checkinTally >= minTally){
            //run the job
            uint taskID = getJob(_taskTier);//note calling this means the task is no longer in the queue
            Task memory task = taskList[taskID];


            //if it is a dummy task, or if adminWallet would not cover cost, then return 0 telling bot to recall this function
            if(taskID == 0 || taskID == 1 || (adminWallet[task.admin] <  (task.gasTank+baseGas) * gasPrice * tierRewardMultiplier[_taskTier]) ){
                if((adminWallet[task.admin] <  task.gasTank * gasPrice * tierRewardMultiplier[_taskTier])){//unschedule the task
                    task.nextScheduledRunTime = 0;
                    adminGasRequirement[task.admin] -= task.gasTank * tierRewardMultiplier[task.taskTier];
                }
            }
            else{
                //set this bots tally to 1 bc it got a job
                bot[msg.sender].startTime = checkinPeriod - timeRounding;

                //run the task
                (bool success, bytes memory result) = task.target.call{value: 0, gas: task.gasTank}(task.taskInput);
                if(success){
                    emit TaskSuccess(taskID);
                }
                else{
                    emit TaskFail(taskID);
                }

                //pay out reward
                uint amount = (task.gasTank+baseGas) * gasPrice * tierRewardMultiplier[_taskTier];
                adminWallet[task.admin] -= amount;
                bot[msg.sender].pendingDAT += amount / 2;
                IAccountant(accountant).platformBurn(address(this), (amount/2), targetMap[task.target].platformID);

                //schedule next call if users wallet still has enough DAT
                if(adminWallet[task.admin] >= adminGasRequirement[task.admin] * gasPrice){
                    uint nextTimeToRun;
                    if(task.variableCalling && result.length == 32){
                        uint res = abi.decode(result, (uint));
                        if(res==0){res = 1;}//Make sure res is atleast 1, so it is in the future
                        nextTimeToRun = block.timestamp + res;
                        //nextTimeToRun = block.timestamp + toUint256(result, 0);
                    }
                    else{
                        nextTimeToRun = block.timestamp + task.desiredFrequency;
                    }
                    task.nextScheduledRunTime = addTaskToHeap(nextTimeToRun, taskID, _taskTier);
                }
                else{
                    task.nextScheduledRunTime = 0;
                    adminGasRequirement[task.admin] -= task.gasTank * tierRewardMultiplier[task.taskTier];
                }
            }
        }
    }

    function upgradeBotTier(address _botAddress, uint _newTier) external validTier(_newTier) withdrawStarted(_botAddress){
        require(bot[_botAddress].admin == msg.sender, "Caller does not own bot");
        require(_newTier > bot[_botAddress].tier, "New tier not high enough");
        uint oldTier = bot[_botAddress].tier;
        DAT.transferFrom(msg.sender, address(this), (baseStakeAmount * tierRewardMultiplier[_newTier]) - (baseStakeAmount * tierRewardMultiplier[oldTier]));
        bot[_botAddress].tier = _newTier;
        bot[_botAddress].withdrawTime = 0;
    }

    function claimBotRewards() external returns(uint total){
        for(uint i=0; i<adminBotList[msg.sender].length; i++){
            total += payOutPending(msg.sender, adminBotList[msg.sender][i]);
        }
    }
    
    function withdrawBotBacking(address _bot) external{
        require(msg.sender == bot[_bot].admin, "Caller does not own bot");
        require(bot[_bot].tier > 0, "Bot does not exist");
        uint time = block.timestamp;
        if(bot[_bot].withdrawTime == 0){
            bot[_bot].withdrawTime = block.timestamp + withdrawTimelock;
        }
        else if(bot[_bot].withdrawTime <= time){
            payOutPending(msg.sender, _bot);//payOut any pending rewards
            DAT.transfer(msg.sender, (baseStakeAmount * tierRewardMultiplier[bot[_bot].tier]));//transfer staked amount back to caller
            tierToBotCount[bot[_bot].tier] -= 1;
            bot[_bot].tier = 0;
        }
    }

    function cancelWithdrawBotBacking(address _bot) external{
        require(msg.sender == bot[_bot].admin, "Caller does not own bot");
        bot[_bot].withdrawTime = 0;
    }

    //*********************** External View Functions ***********************//
    function minJobs(uint _taskTier) public view validTier(_taskTier) returns(uint jobCount){
        uint minTimeStamp = MinHeap.min(tierTaskHeap[_taskTier]);
        if(minTimeStamp <= block.timestamp){
            jobCount = timeToTaskID[minTimeStamp].length - timeToCounter[minTimeStamp];
        }
    }

    function viewAdminTasks(address admin) external view returns(uint[] memory tasks){
        //returns all the tasks the admin has
        return adminTaskList[admin];
    }

    function viewAdminBots(address admin) external view returns(address[] memory bots){
        return adminBotList[admin];
    }

    function viewBotRewards(address admin) external view returns(uint total){
        for(uint i=0; i<adminBotList[admin].length; i++){
            total += bot[adminBotList[admin][i]].pendingDAT;
        }
    }
    //TODO so this one worked the first time, when no jobs were available, but when jobs were available it reverted!
    function viewTimeToCall(address _bot, uint _taskTier) external view validTier(_taskTier) returns(uint){
        require(bot[_bot].tier >= _taskTier, "Proposed bot is not high enough tier");
        uint checkinTally = (bot[_bot].lastCheckinTime - bot[_bot].startTime); // / timeRounding;

        if(minJobs(_taskTier) > 0){
            if((block.timestamp - MinHeap.min(tierTaskHeap[_taskTier])) >= timeRounding){//no checks required, allow bot to run job
                return 0;
            }
            else{
                uint result;
                if(timeRounding > checkinTally/tierToBotCount[_taskTier]){
                    result = (timeRounding - checkinTally/tierToBotCount[_taskTier]);
                }
                else{
                    return 0;
                }
                
                if(result > (block.timestamp % timeRounding)){
                    return result - (block.timestamp % timeRounding);
                }
                else{//means that say they had to wait for 500 sec from the start of the checkin period, but we are already more than half way through check in period
                    return 0;
                }
            }
        }
        else{
            return 1000;
        }
    }

    function addTaskToHeap(uint desiredTime, uint taskID, uint taskTier) internal returns(uint){
        
        uint batchTime = desiredTime / timeRounding;
        batchTime *= timeRounding;

        //If proposed batch time is current or in the past, then add time rounding seconds to it
        if(batchTime <= block.timestamp){
            batchTime += timeRounding;
        }
        timeToTaskID[batchTime].push(taskID);
        if(!heapTimeScheduled[batchTime]){
            MinHeap.insert(tierTaskHeap[taskTier], batchTime);
            heapTimeScheduled[batchTime] = true;
        }
        return batchTime;
    }

    function getJob(uint _taskTier) internal returns(uint taskID){
        uint minTimeStamp = MinHeap.min(tierTaskHeap[_taskTier]);
        if(minTimeStamp <= block.timestamp){
            taskID = timeToTaskID[minTimeStamp][timeToCounter[minTimeStamp]];
            delete timeToTaskID[minTimeStamp][timeToCounter[minTimeStamp]];//refund some gas to caller
            timeToCounter[minTimeStamp] += 1;
            if(timeToCounter[minTimeStamp] == timeToTaskID[minTimeStamp].length){//if we are at the end of tasks for this timestamp, remove the min
                MinHeap.deleteMin(tierTaskHeap[_taskTier]);
            }
        }
    }

    function payOutPending(address recipient, address _bot) internal returns(uint pending){
        pending = bot[_bot].pendingDAT;
        if(pending > 0){
            bot[_bot].pendingDAT = 0;
            DAT.transfer(recipient, pending);
        }
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }
    
    function bytesToAddress(bytes memory bys) internal pure returns (address addr) {
        assembly {
            addr := mload(add(bys,20))
        }
    } 

    function viewJob(uint _taskTier) public view returns(uint taskID){
        uint minTimeStamp = MinHeap.min(tierTaskHeap[_taskTier]);
        if(minTimeStamp <= block.timestamp){
            taskID = timeToTaskID[minTimeStamp][timeToCounter[minTimeStamp]];
        }
    }

    function viewBotTier(address _bot) public view returns(uint){
        return bot[_bot].tier;
    }
}