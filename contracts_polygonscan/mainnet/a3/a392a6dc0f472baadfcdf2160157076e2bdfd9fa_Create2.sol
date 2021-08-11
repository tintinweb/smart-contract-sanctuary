// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Create2 {

    function getAddress(uint _salt, bytes memory bytecode, address contractCreator) internal pure returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(contractCreator),
                _salt,
                keccak256(bytecode)
            )
        );

        // NOTE: cast last 20 bytes of hash to address
        return address(uint160(uint256(hash)));
    }

    function deployContract(uint _salt, bytes memory bytecode) internal returns(address addr) {

        /*
        NOTE: How to call create2

        create2(v, p, n, s)
        create new contract with code at memory p to p + n
        and send v wei
        and return the new address
        where new address = first 20 bytes of keccak256(0xff + address(this) + s + keccak256(mem[p…(p+n)))
              s = big-endian 256-bit value
        */
        assembly {
            addr := create2(
                0, // wei sent with current call
                // Actual code starts after skipping the first 32 bytes
                add(bytecode, 0x20),
                mload(bytecode), // Load the size of code contained in the first 32 bytes
                _salt // Salt from function arguments
            )

            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }


    }
}