// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "./IERC20.sol";

contract Task {
    address private _contractOwner;
    address private _token;

    struct TaskInfo {
        uint256 creationDate;
        uint256 deadLine;
        address developer;
        address taskOwner;
        uint256 amount;
        bool contested;
    }

    mapping(uint256 => TaskInfo) tasks;

    constructor() {
        _contractOwner = msg.sender;
    }

    function setTokenAddress(address usdtTokenAddress) public {
        _token = usdtTokenAddress;
    }

    function getOwner() public view virtual returns (address) {
        return _contractOwner;
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

    function addTask(
        uint256 task,
        address developer,
        uint256 amount,
        uint256 deadLine
    ) public {
        require(
            msg.sender != developer,
            "Task: the developer and the task owner cannot be the same"
        );

        require(amount > 0, "Task: amount needs to be greater than 0");
        require(
            deadLine > block.timestamp,
            "Task: the deadline must be a future date"
        );

        bool isTransfered = IERC20(_token).transferFrom(
            msg.sender,
            address(this),
            amount
        );

        if (isTransfered == true) {
            tasks[task] = TaskInfo(
                block.timestamp,
                deadLine,
                developer,
                msg.sender,
                amount,
                false
            );
        }
    }

    function contestTask(uint256 task) public {
        require(
            msg.sender == tasks[task].taskOwner,
            "Task: caller is not the task owner"
        );
        require(
            block.timestamp > tasks[task].deadLine,
            "Task: the dead line was not reached yet"
        );
        require(
            block.timestamp < tasks[task].deadLine + 4 weeks,
            "Task: the dead line was not reached yet"
        );

        tasks[task].contested = true;
    }

    function payTaskDeveloper(uint256 task) public {
        if (tasks[task].contested == true) {
            require(
                msg.sender == _contractOwner ||
                    msg.sender == tasks[task].taskOwner,
                "Task: caller is not the contract owner or the task owner"
            );
        } else {
            require(
                msg.sender == tasks[task].taskOwner,
                "Task: caller is not the task owner"
            );
        }

        //! attenzione a questa che non deve essere gestita dall'owner
        _executeTaskPayment(task);
    }

    function returnPayment(uint256 task) public {
        require(tasks[task].contested == true, "Task: task was not contested");
        require(
            msg.sender == _contractOwner,
            "Ownable: caller is not the owner"
        );

        IERC20(_token).transfer(tasks[task].taskOwner, tasks[task].amount);
        delete tasks[task];
    }

    function askTaskPayment(uint256 task) public {
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

    function _executeTaskPayment(uint256 task) private {
        IERC20(_token).transfer(tasks[task].developer, tasks[task].amount);
        delete tasks[task];
    }
}