pragma solidity ^0.6.0;

import "../implementation/Lockable.sol";
import "./ReentrancyAttack.sol";


// Tests reentrancy guards defined in Lockable.sol.
// Extends https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.0.1/contracts/mocks/ReentrancyMock.sol.
contract ReentrancyMock is Lockable {
    uint256 public counter;

    constructor() public {
        counter = 0;
    }

    function callback() external nonReentrant {
        _count();
    }

    function countAndSend(ReentrancyAttack attacker) external nonReentrant {
        _count();
        bytes4 func = bytes4(keccak256("callback()"));
        attacker.callSender(func);
    }

    function countAndCall(ReentrancyAttack attacker) external nonReentrant {
        _count();
        bytes4 func = bytes4(keccak256("getCount()"));
        attacker.callSender(func);
    }

    function countLocalRecursive(uint256 n) public nonReentrant {
        if (n > 0) {
            _count();
            countLocalRecursive(n - 1);
        }
    }

    function countThisRecursive(uint256 n) public nonReentrant {
        if (n > 0) {
            _count();
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = address(this).call(abi.encodeWithSignature("countThisRecursive(uint256)", n - 1));
            require(success, "ReentrancyMock: failed call");
        }
    }

    function countLocalCall() public nonReentrant {
        getCount();
    }

    function countThisCall() public nonReentrant {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = address(this).call(abi.encodeWithSignature("getCount()"));
        require(success, "ReentrancyMock: failed call");
    }

    function getCount() public view nonReentrantView returns (uint256) {
        return counter;
    }

    function _count() private {
        counter += 1;
    }
}
