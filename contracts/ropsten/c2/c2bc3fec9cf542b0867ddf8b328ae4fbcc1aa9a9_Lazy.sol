pragma solidity 0.5.10;
pragma experimental ABIEncoderV2;

import "./IVerifier.sol";
import "./Structs.sol";

contract Lazy is Structs {
    event Submitted(address indexed sender, uint256 index, Task task);
    event Challenged(address indexed challenger, uint256 index);

    enum Status {UNCHECKED, VALID, INVALID, FINALIZED}
    struct Task {
        Data data;
        Proof proof;
        address payable submitter;
        uint256 timestamp;
        Status status;
    }

    Task[] public tasks;

    function tasksNum() external view returns (uint256) {
        return tasks.length;
    }

    uint256 public stake = 0.1 ether;
    IVerifier public verifier;

    constructor(IVerifier _verifier) public {
        verifier = _verifier;
    }

    /// @dev This function submits data.
    /// @param data - public inptut for zkp
    /// @param proof - proof that verifies input
    function submit(Data calldata data, Proof calldata proof) external payable {
        require(msg.value == stake, "!msg.value == stake");

        Task memory task = Task(data, proof, msg.sender, now, Status.UNCHECKED);
        uint256 index = tasks.push(task);

        emit Submitted(msg.sender, index, task);
    }

    /// @dev This function challenges a submission by calling the validation function.
    /// @param id The id of the submission to challenge.
    function challenge(uint256 id) external {
        Task storage task = tasks[id];
        require(
            now < task.timestamp + 5 minutes,
            "!now < task.timestamp + 5 minutes"
        );
        require(task.status == Status.UNCHECKED);

        if (verifier.isValid(task.data, task.proof)) {
            task.status = Status.VALID;
            task.submitter.transfer(stake);
        } else {
            task.status = Status.INVALID;
            msg.sender.transfer(stake);
        }

        // пруф не подходит, на это надо реагировать

        emit Challenged(msg.sender, id);
    }

    function finzalize(uint256 id) external {
        Task storage task = tasks[id];
        require(
            now > task.timestamp + 1 minutes,
            "!now > task.timestamp + 1 minutes"
        );
        require(
            task.status == Status.UNCHECKED,
            "!task.status == Status.UNCHECKED"
        );

        task.status = Status.FINALIZED;
        msg.sender.transfer(stake);
    }

    function taskDataById(uint256 id)
        external
        view
        returns (uint256[13] memory data)
    {
        Task memory task = tasks[id];

        data[0] = task.data.input[0];
        data[1] = task.data.input[1];
        data[2] = task.data.input[2];
        data[3] = task.data.input[3];
        data[4] = task.data.input[4];

        data[5] = task.proof.a[0];
        data[6] = task.proof.a[1];

        data[7] = task.proof.b[0][0];
        data[8] = task.proof.b[0][1];
        data[9] = task.proof.b[1][0];
        data[10] = task.proof.b[1][1];

        data[11] = task.proof.c[0];
        data[12] = task.proof.c[1];
    }
}