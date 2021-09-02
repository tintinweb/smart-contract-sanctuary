/**
 *Submitted for verification at Etherscan.io on 2021-09-02
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/deployer.sol
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.6.12;

////// src/deployer.sol
/* pragma solidity >=0.6.12; */

contract MainDeployer {
    function deploy(bytes memory bytecode, bytes32 salt) public returns (address addr)  {
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            if iszero(extcodesize(addr)) { revert(0, 0) }
        }
    }

    /// returns address(0) if contract doesn't exist
    function getAddress(bytes32 bytecodeHash_, bytes32 salt) public view returns(address) {
        // create2 address calculation
        // name is used as salt
        // keccak256(0xff ++ deployingAddr ++ salt ++ keccak256(bytecode))[12:]
        bytes32 _data = keccak256(
            abi.encodePacked(bytes1(0xff), address(this), salt, bytecodeHash_)
        );
        address addr = address(bytes20(_data << 96));
        uint size;
        assembly {
            size := extcodesize(addr)
        }
        if (size > 0) {
            return addr;
        }
        return address(0);
    }

    function bytecodeHash(bytes memory bytecode) public pure returns(bytes32) {
        return keccak256(bytecode);
    }
}