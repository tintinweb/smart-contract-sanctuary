// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract ForceSend {
    constructor(address payable to) payable {
        selfdestruct(to);
    }
}

contract CoinbasePay {

    function pay() public payable {
        bytes memory bytecode = type(ForceSend).creationCode;
        bytes32 _hash = blockhash(block.number);

        address addr;
        uint value = msg.value;
        uint size;
        assembly {
            addr := create2(value, add(bytecode, 0x20), mload(bytecode), _hash)
            size := extcodesize(addr)
        }
        require(size > 1, "Could not forward eth");
    }

    function rev() public payable {
        revert("Revert message");
    }
}