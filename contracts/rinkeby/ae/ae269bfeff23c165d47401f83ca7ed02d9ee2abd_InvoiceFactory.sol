// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import {SimpleInvoice} from "./Invoice.sol";

contract InvoiceFactory  {

    bytes constant private invoiceCreationCode = type(SimpleInvoice).creationCode;

    function withdraw(uint256 salt, address token, address receiver) external returns (address wallet) {
        bytes memory bytecode = getByteCode(token, receiver);
        assembly {
            wallet := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(wallet != address(0), "Create2: Failed on deploy");
    }

    function computeAddress(uint256 salt, address token, address receiver) external view returns (address) {
        bytes memory bytecode = getByteCode(token, receiver);
        return computeAddress(bytes32(salt), bytecode, address(this));
    }

    // function computeAddress(bytes32 salt, bytes memory bytecode) external view returns (address) {
    //     return computeAddress(salt, bytecode, address(this));
    // }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(bytes32 salt, bytes memory bytecodeHash, address deployer) internal pure returns (address) {
        bytes32 bytecodeHashHash = keccak256(bytecodeHash);
        bytes32 _data = keccak256(
            abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHashHash)
        );
        return address(bytes20(_data << 96));
    }
    
    
    function getByteCode(address token, address receiver) private pure returns (bytes memory bytecode) {
        bytecode = abi.encodePacked(invoiceCreationCode, abi.encode(token, receiver));
    }
}