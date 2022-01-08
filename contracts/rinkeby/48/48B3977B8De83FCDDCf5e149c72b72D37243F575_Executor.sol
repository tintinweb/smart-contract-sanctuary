/**
 *Submitted for verification at Etherscan.io on 2022-01-07
*/

contract Executor {
    event Result(bool success, bytes result);

    function execute(address target, bytes memory data) external {
        // Make the function call
        (bool success, bytes memory result) = target.call(data);

        // success is false if the call reverts, true otherwise
        require(success, "Call failed");

        // result contains whatever has returned the function
        emit Result(success, result);
    }
}