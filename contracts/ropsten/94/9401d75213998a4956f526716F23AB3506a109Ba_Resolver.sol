/**
 *Submitted for verification at Etherscan.io on 2021-11-16
*/

// File: contracts/Example.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract Example {

    uint256 public counter = 0;

    function increment() external {
        counter++;
    }
}

// File: contracts/Resolver.sol

pragma solidity ^0.8.3;


contract Resolver {
    
    Example exampleContract;
    
    function setAddress(address _exampleAddress) public {
        exampleContract = Example(_exampleAddress);
    }

    function getExampleCounter() public view returns (uint256) {
        return exampleContract.counter();
    }

  
    function checker() external returns (bool canExec, bytes memory execPayload) {
        uint256 counter = getExampleCounter();
        canExec = counter < 2;
        execPayload = abi.encodeWithSelector(exampleContract.increment.selector, counter);
        exampleContract.increment();
        return (canExec, execPayload);
    }
}