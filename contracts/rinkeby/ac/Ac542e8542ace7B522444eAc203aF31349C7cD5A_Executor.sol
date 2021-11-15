pragma solidity ^0.5.17;

contract Executor {
    address public admin;
    //address public pendingAdmin;

    mapping(bytes32 => bool) queuedTransactions;

    uint256 constant ERROR_MESSAGE_SHIFT = 68; // EVM silent revert error string length

    constructor(address admin_) public {
        admin = admin_;
    }

    function() external payable {}

    function setPendingAdmin(address pendingAdmin_) public {
        require(
            msg.sender == address(this),
            "Must be called from this contract"
        );

        admin = pendingAdmin_;
    }

    function queueTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data
    ) public returns (bytes32) {
        require(msg.sender == admin, "Call must come from admin");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data));
        queuedTransactions[txHash] = true;

        return txHash;
    }

    function executeTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data
    ) public payable returns (bytes memory) {
        require(msg.sender == admin, "Must come from admin");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data));
        require(queuedTransactions[txHash], "Must be queued.");

        queuedTransactions[txHash] = false;

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(
                bytes4(keccak256(bytes(signature))),
                data
            );
        }

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call.value(value)(
            callData
        );
        if (!success) {
            if (returnData.length <= ERROR_MESSAGE_SHIFT) {
                revert("Transaction Reverted");
            } else {
                "Transaction Success";
            }
        }
        return returnData;
    }
}

