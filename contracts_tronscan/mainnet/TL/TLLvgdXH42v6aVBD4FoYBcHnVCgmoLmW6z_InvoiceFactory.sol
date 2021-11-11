//SourceUnit: Invoice.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface IERC20 {
    function transfer(address, uint256) external;
    function balanceOf(address) external view returns(uint256);
}

/// @title The Invoice contract sends all tokens to the receiver and destructs himself
/// @author davy42
/// @dev The rest of ETH on the wallet will be sent to the receiver even if it's a contract without receive function
contract Invoice {

    /// @notice Constructor
    /// @dev The Invoice contract has only constructor.
    /// @param token The address of the erc20 token contract
    /// @param receiver The address to which tokens will be sent
    /// @param amount amount of tokens
    constructor (IERC20 token, address payable receiver, uint256 amount) {
        token.transfer(receiver, amount);
        selfdestruct(receiver);
    }
}

/// @title The Invoice contract sends all tokens to the receiver and destructs himself
/// @author davy42
/// @dev The rest of ETH on the wallet will be sent to the receiver even if it's a contract without receive function
contract SimpleInvoice {

    /// @notice Constructor
    /// @dev The Invoice contract has only constructor.
    /// @param token The address of the erc20 token contract
    /// @param receiver The address to which tokens will be sent
    constructor(IERC20 token, address payable receiver) {
        token.transfer(receiver, token.balanceOf(address(this)));
        selfdestruct(receiver);
    }
}

//SourceUnit: InvoiceFactory.sol

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
            abi.encodePacked(bytes1(0x41), deployer, salt, bytecodeHashHash)
        );
        return address(bytes20(_data << 96));
    }
    
    
    function getByteCode(address token, address receiver) private pure returns (bytes memory bytecode) {
        bytecode = abi.encodePacked(invoiceCreationCode, abi.encode(token, receiver));
    }
}