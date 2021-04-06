// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import {SimpleInvoice} from "./Invoice.sol";

/// @title The InvoiceFactory allows withdrawing ERC20 tokens from a temporary Invoice
/// @author davy42
/// @notice The InvoiceFactory can compute the address for deposit and withdraw funds
/// @dev The InvoiceFactory use the bytecode of the Invoice contract with dynamic token and receiver addresses
contract InvoiceFactory  {

    bytes constant private invoiceCreationCode = type(SimpleInvoice).creationCode;

    /// @notice Witdraws erc20 tokens from the deposit wallet and send to the receiver
    /// @param salt The unique salt
    /// @param token The address of the erc20 token which will be withdrawed
    /// @param receiver The address which will get tokens
    /// @return wallet the address of the wallet
    function withdraw(uint256 salt, address token, address receiver) external returns (address wallet) {
        bytes memory bytecode = getByteCode(token, receiver);
        assembly {
            wallet := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(wallet != address(0), "Create2: Failed on deploy");
    }

    /// @notice  Returns the address of the wallet
    /// @dev Compute address for depositing funds using salt, token and receivers
    /// @param salt The unique salt
    /// @param token The address of the erc20 token which will be deposited
    /// @param receiver The address which will get tokens when withdraw
    /// @return wallet the address of the wallet
    function computeAddress(uint256 salt, address token, address receiver) public view returns (address) {
        bytes32 _data = keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(getByteCode(token, receiver))));
        return address(uint160(uint256(_data)));
    }

    /// @notice Generate the bytecode of wallet contract with token and receiver
    /// @dev Explain to a developer any extra details
    /// @param token The address of the erc20 token which will be deposited
    /// @param receiver The address which will get tokens when withdraw
    /// @return bytecode the bytecode of the wallet contract
    function getByteCode(address token, address receiver) private pure returns (bytes memory bytecode) {
        bytecode = abi.encodePacked(invoiceCreationCode, abi.encode(token, receiver));
    }
}