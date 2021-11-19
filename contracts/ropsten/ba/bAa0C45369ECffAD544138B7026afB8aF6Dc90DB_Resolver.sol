//SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import './Example.sol';

contract Resolver {
    
    Example public exampleContract;
    address public owner;
    
    constructor(address _exampleAddress) {
        exampleContract = Example(_exampleAddress);
        owner = msg.sender;
    }
    
    function checker() external returns (bool canExec, bytes memory execPayload) {
        uint256 counter = exampleContract.counter();
        canExec = counter < 2;
        execPayload = abi.encodeWithSelector(exampleContract.increment.selector, counter);
        exampleContract.increment();
        return (canExec, execPayload);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract Example {
// Example2
    uint256 public counter = 0;

    function increment() external {
        counter++;
    }
}