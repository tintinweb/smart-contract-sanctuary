pragma solidity =0.5.16;

import './ContractTest.sol';

contract Create2Test {
    event Done(address addr);

    ContractTest[] public contracts;

    function createContract() external {
        // bytes memory bytecode = type(ContractTest).creationCode;
        // bytes32 salt = 0xcadf04226e49056c444e4100657777374bdf98447a63bc9f017e7c30dd9fcc46;
        // address addr;
        // assembly {
        //     addr := create2(0, add(bytecode, 32), mload(bytecode), salt)
        // }
        // emit Done(addr);

        ContractTest addr = new ContractTest();

        contracts.push(addr);

        emit Done(address(addr));
    }
}

pragma solidity =0.5.16;

contract ContractTest {
    uint public num;

    constructor() public {

    }

    function setNum(uint _num) public {
        num = _num;
    }
}