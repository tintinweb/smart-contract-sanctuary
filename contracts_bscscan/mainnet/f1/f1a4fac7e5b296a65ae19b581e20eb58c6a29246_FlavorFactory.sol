/**
 *Submitted for verification at BscScan.com on 2021-10-18
*/

// After deploying the flavors factory factory, deploy this from the
// flavors factory wallet by interacting with the flavors factory factory.
// Use the bytecode and salt to deploy this contract to the predetermined
// 0xfla45Fac factory address


// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
contract FlavorFactory {
    address FlavorFactoryWallet = 0xf1a45Fac9A879242BcE8A2837e6C90F5088c519E;
    function deploy(
        uint256 amount,
        bytes32 salt,
        bytes memory bytecode
    ) public returns (address) {
        require (msg.sender == FlavorFactoryWallet, "Don't get salty... but you aren't the FlavorFactoryWallet");
        address addr;
        require(address(this).balance >= amount, "FlavorFactory: insufficient balance");
        require(bytecode.length != 0, "FlavorFactory: bytecode length is zero");
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "FlavorFactory: Failed on deploy");
        return addr;
    }

    function computeAddress(bytes32 salt, bytes32 bytecodeHash) public view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    function computeAddress(
        bytes32 salt,
        bytes32 bytecodeHash,
        address deployer
    ) public pure returns (address) {
        bytes32 _data = keccak256(abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash));
        return address(uint160(uint256(_data)));
    }
}