pragma solidity ^0.6.0;


// Tests reentrancy guards defined in Lockable.sol.
// Copied from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.0.1/contracts/mocks/ReentrancyAttack.sol.
contract ReentrancyAttack {
    function callSender(bytes4 data) public {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = msg.sender.call(abi.encodeWithSelector(data));
        require(success, "ReentrancyAttack: failed call");
    }
}
