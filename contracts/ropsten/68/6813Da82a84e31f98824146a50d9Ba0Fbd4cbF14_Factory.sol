// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
import "./Wallet.sol";


contract Factory {
  /**
   * @notice Will deploy a new wallet instance
   * @param _mainModule Address of the main module to be used by the wallet
   * @param _salt Salt used to generate the wallet, which is the imageHash
   *       of the wallet's configuration.
   * @dev It is recommended to not have more than 200 signers as opcode repricing
   *      could make transactions impossible to execute as all the signers must be
   *      passed for each transaction.
   */
  function deploy(address _mainModule, bytes32 _salt) public payable returns (address _contract) {
    bytes memory code = abi.encodePacked(Wallet.creationCode, uint256(_mainModule));
    assembly { _contract := create2(callvalue(), add(code, 32), mload(code), _salt) }
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

/**
    Minimal upgradeable proxy implementation, delegates all calls to the address
    defined by the storage slot matching the wallet address.

    Inspired by EIP-1167 Implementation (https://eips.ethereum.org/EIPS/eip-1167)

    deployed code:

        0x00    0x36         0x36      CALLDATASIZE      cds
        0x01    0x3d         0x3d      RETURNDATASIZE    0 cds
        0x02    0x3d         0x3d      RETURNDATASIZE    0 0 cds
        0x03    0x37         0x37      CALLDATACOPY
        0x04    0x3d         0x3d      RETURNDATASIZE    0
        0x05    0x3d         0x3d      RETURNDATASIZE    0 0
        0x06    0x3d         0x3d      RETURNDATASIZE    0 0 0
        0x07    0x36         0x36      CALLDATASIZE      cds 0 0 0
        0x08    0x3d         0x3d      RETURNDATASIZE    0 cds 0 0 0
        0x09    0x30         0x30      ADDRESS           addr 0 cds 0 0 0
        0x0A    0x54         0x54      SLOAD             imp 0 cds 0 0 0
        0x0B    0x5a         0x5a      GAS               gas imp 0 cds 0 0 0
        0x0C    0xf4         0xf4      DELEGATECALL      suc 0
        0x0D    0x3d         0x3d      RETURNDATASIZE    rds suc 0
        0x0E    0x82         0x82      DUP3              0 rds suc 0
        0x0F    0x80         0x80      DUP1              0 0 rds suc 0
        0x10    0x3e         0x3e      RETURNDATACOPY    suc 0
        0x11    0x90         0x90      SWAP1             0 suc
        0x12    0x3d         0x3d      RETURNDATASIZE    rds 0 suc
        0x13    0x91         0x91      SWAP2             suc 0 rds
        0x14    0x60 0x18    0x6018    PUSH1             0x18 suc 0 rds
    /-- 0x16    0x57         0x57      JUMPI             0 rds
    |   0x17    0xfd         0xfd      REVERT
    \-> 0x18    0x5b         0x5b      JUMPDEST          0 rds
        0x19    0xf3         0xf3      RETURN

    flat deployed code: 0x363d3d373d3d3d363d30545af43d82803e903d91601857fd5bf3

    deploy function:

        0x00    0x60 0x3a    0x603a    PUSH1             0x3a
        0x02    0x60 0x0e    0x600e    PUSH1             0x0e 0x3a
        0x04    0x3d         0x3d      RETURNDATASIZE    0 0x0e 0x3a
        0x05    0x39         0x39      CODECOPY
        0x06    0x60 0x1a    0x601a    PUSH1             0x1a
        0x08    0x80         0x80      DUP1              0x1a 0x1a
        0x09    0x51         0x51      MLOAD             imp 0x1a
        0x0A    0x30         0x30      ADDRESS           addr imp 0x1a
        0x0B    0x55         0x55      SSTORE            0x1a
        0x0C    0x3d         0x3d      RETURNDATASIZE    0 0x1a
        0x0D    0xf3         0xf3      RETURN
        [...deployed code]

    flat deploy function: 0x603a600e3d39601a805130553df3363d3d373d3d3d363d30545af43d82803e903d91601857fd5bf3
*/
library Wallet {
  bytes internal constant creationCode = hex"603a600e3d39601a805130553df3363d3d373d3d3d363d30545af43d82803e903d91601857fd5bf3";
}