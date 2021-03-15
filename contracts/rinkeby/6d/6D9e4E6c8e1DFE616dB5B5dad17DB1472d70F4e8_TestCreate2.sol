pragma solidity =0.5.16;

import "./TestContract.sol";

contract TestCreate2 {
    event Done(bytes32 salt, address addr);

    function createContract(address addr1, address addr2) external {
        address pair;

        bytes memory bytecode = type(TestContract).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(addr1, addr2));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        emit Done(salt, pair);
    }
}

pragma solidity =0.5.16;

contract TestContract {
    constructor() public {
        
    }
}