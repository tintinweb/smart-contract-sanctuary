// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./IERC20.sol";

contract Task {
    address private _contractOwner;
    address private _token;
    uint256 private _fee = 29;
    uint256 private sumTasksAmount = 0;

    struct TaskInfo {
        uint256 creationDate;
        uint256 deadLine;
        address developer;
        address taskOwner;
        uint256 amount;
        bool contested;
        bool created;
    }

    mapping(uint256 => TaskInfo) tasks;

    constructor(address tokenAddress) {
        _contractOwner = msg.sender;
        _token = tokenAddress;
    }

    function _executeTaskPayment(uint256 task) private {
        IERC20(_token).transfer(tasks[task].developer, tasks[task].amount);
        sumTasksAmount = sumTasksAmount - tasks[task].amount;
        delete tasks[task];
    }

    function _onlyOwner() private view {
        require(
            msg.sender == _contractOwner,
            "Ownable: caller is not the owner"
        );
    }

    function _onlyTaskOwner(uint256 task) private view {
        require(
            msg.sender == tasks[task].taskOwner,
            "Task: caller is not the task owner"
        );
    }

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function setFee(uint256 fee) external onlyOwner {
        require(fee <= 100, "Task: fee is too high, it must be lower than 100");
        require(fee >= 10, "Task: fee is too low, it must be higher than 10");
        _fee = fee;
    }

    function getTokenAddress() external view returns (address) {
        return _token;
    }

    function getOwner() external view returns (address) {
        return _contractOwner;
    }

    function getSumTasksAmount() external view returns (uint256) {
        return sumTasksAmount;
    }

    function getCreationDate(uint256 taskId) external view returns (uint256) {
        return tasks[taskId].creationDate;
    }

    function getDeadLine(uint256 taskId) external view returns (uint256) {
        return tasks[taskId].deadLine;
    }

    function getTaskDev(uint256 taskId) external view returns (address) {
        return tasks[taskId].developer;
    }

    function getTaskOwner(uint256 taskId) external view returns (address) {
        return tasks[taskId].taskOwner;
    }

    function getTaskValue(uint256 taskId) external view returns (uint256) {
        return tasks[taskId].amount;
    }

    function getContested(uint256 taskId) external view returns (bool) {
        return tasks[taskId].contested;
    }

    function getCreated(uint256 taskId) external view returns (bool) {
        return tasks[taskId].created;
    }

    function getFee() external view returns (uint256) {
        return _fee;
    }

    function getFeeBalance() external view returns (uint256) {
        uint256 currentBalance = IERC20(_token).balanceOf(address(this));
        return currentBalance - sumTasksAmount;
    }

    function getTaskFee(uint256 amount) public view returns (uint256) {
        uint256 roundedAmount = (amount / 1000) * 1000;
        return (roundedAmount * _fee) / 1000;
    }

    function addTask(
        uint256 task,
        address developer,
        uint256 amount,
        uint256 deadLine
    ) external {
        require(
            msg.sender != developer,
            "Task: the developer and the task owner cannot be the same"
        );
        require(
            msg.sender != _contractOwner,
            "Task: the contract owner and the task owner cannot be the same"
        );
        require(
            developer != _contractOwner,
            "Task: the contract owner and the task developer cannot be the same"
        );
        require(
            amount >= 1000,
            "Task: amount needs to be greater or equal than 1000"
        );
        require(
            deadLine > block.timestamp,
            "Task: the deadline must be a future date"
        );
        require(tasks[task].created != true, "Task: task already exists");

        uint256 fee = getTaskFee(amount);

        bool isTransfered = IERC20(_token).transferFrom(
            msg.sender,
            address(this),
            amount + fee
        );

        if (isTransfered == true) {
            tasks[task] = TaskInfo(
                block.timestamp,
                deadLine,
                developer,
                msg.sender,
                amount,
                false,
                true
            );

            sumTasksAmount = sumTasksAmount + amount;
        }
    }

    function payTaskDeveloper(uint256 task) external {
        if (tasks[task].contested == true) {
            require(
                msg.sender == _contractOwner ||
                    msg.sender == tasks[task].taskOwner,
                "Task: caller is not the contract owner or the task owner"
            );
        } else {
            _onlyTaskOwner(task);
        }

        _executeTaskPayment(task);
    }

    function contestTask(uint256 task) external {
        _onlyTaskOwner(task);
        require(
            block.timestamp > tasks[task].deadLine,
            "Task: the dead line was not reached yet"
        );
        require(
            block.timestamp < tasks[task].deadLine + 4 weeks,
            "Task: It is not possible to contest a task after 4 weeks from the deadline"
        );

        tasks[task].contested = true;
    }

    function returnPayment(uint256 task) external onlyOwner {
        require(tasks[task].contested == true, "Task: task was not contested");
        IERC20(_token).transfer(tasks[task].taskOwner, tasks[task].amount);
        sumTasksAmount = sumTasksAmount - tasks[task].amount;
        delete tasks[task];
    }

    function askTaskPayment(uint256 task) external {
        require(
            block.timestamp > (tasks[task].deadLine + 4 weeks),
            "Task: the developer can ask the payment only 4 weeks after the deadline"
        );
        require(
            tasks[task].contested == false,
            "Task: the developer cannot ask the payment when the task was contested"
        );
        require(
            msg.sender == tasks[task].developer,
            "Task: caller is not the developer"
        );

        _executeTaskPayment(task);
    }

    function collectFees() external onlyOwner {
        uint256 currentBalance = IERC20(_token).balanceOf(address(this));
        uint256 feeBalance = currentBalance - sumTasksAmount;
        IERC20(_token).transfer(_contractOwner, feeBalance);
    }
}