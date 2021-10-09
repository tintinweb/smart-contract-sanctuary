// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "https://github.com/0xsequence/create3/blob/master/contracts/Create3.sol";
import "./Child1.sol";
import "./Child2.sol";

contract Deployer {
    function create1() external returns (address) {
        return Create3.create3(keccak256(bytes("salty")), type(Child1).creationCode);
    }

    function create2() external returns (address) {
        return Create3.create3(keccak256(bytes("salty")), type(Child2).creationCode);
    }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity >=0.7.0 <0.9.0;

contract Child2 {
    function get() external pure returns(uint256) {
        return 2;
    }
    
    function go() external {
        selfdestruct(payable(address(0)));
    }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity >=0.7.0 <0.9.0;

contract Child1 {
    function get() external pure returns(uint256) {
        return 1;
    }
    
    function go() external {
        selfdestruct(payable(address(0)));
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/**
  @title A library for deploying contracts EIP-3171 style.
  @author Agustin Aguilar <[email protected]>
*/
library Create3 {
  error ErrorCreatingProxy();
  error ErrorCreatingContract();
  error TargetAlreadyExists();

  /**
    @notice The bytecode for a contract that proxies the creation of another contract
    @dev If this code is deployed using CREATE2 it can be used to decouple `creationCode` from the child contract address

      0x00    0x63         0x63XXXXXX  PUSH4 _code.length  size
      0x01    0x80         0x80        DUP1                size size
      0x02    0x60         0x600e      PUSH1 14            14 size size
      0x03    0x60         0x6000      PUSH1 00            0 14 size size
      0x04    0x39         0x39        CODECOPY            size
      0x05    0x60         0x6000      PUSH1 00            0 size
      0x06    0xf3         0xf3        RETURN

      <--- CODE --->

      0x00    0x36         0x36      CALLDATASIZE      cds
      0x01    0x3d         0x3d      RETURNDATASIZE    0 cds
      0x02    0x80         0x80      DUP1              0 0 cds
      0x03    0x37         0x37      CALLDATACOPY
      0x04    0x36         0x36      CALLDATASIZE      cds
      0x05    0x3d         0x3d      RETURNDATASIZE    0 cds
      0x06    0x34         0x34      CALLVALUE         val 0 cds
      0x07    0xf0         0xf0      CREATE            addr
      0x08    0xff         0xff      SELFDESTRUCT
  */
  bytes internal constant PROXY_CHILD_BYTECODE = hex"63_00_00_00_09_80_60_0E_60_00_39_60_00_F3_36_3d_80_37_36_3d_34_f0_ff";

  //                        KECCAK256_PROXY_CHILD_BYTECODE = keccak256(PROXY_CHILD_BYTECODE);
  bytes32 internal constant KECCAK256_PROXY_CHILD_BYTECODE = 0x68afe50fe78ae96feb6ec11f21f31fdd467c9fcc7add426282cfa3913daf04e9;

  /**
    @notice Returns the size of the code on a given address
    @param _addr Address that may or may not contain code
    @return size of the code on the given `_addr`
  */
  function codeSize(address _addr) internal view returns (uint256 size) {
    assembly { size := extcodesize(_addr) }
  }

  /**
    @notice Creates a new contract with given `_creationCode` and `_salt`
    @param _salt Salt of the contract creation, resulting address will be derivated from this value only
    @param _creationCode Creation code (constructor) of the contract to be deployed, this value doesn't affect the resulting address
    @return addr of the deployed contract, reverts on error
  */
  function create3(bytes32 _salt, bytes memory _creationCode) internal returns (address addr) {
    return create3(_salt, _creationCode, 0);
  }

  /**
    @notice Creates a new contract with given `_creationCode` and `_salt`
    @param _salt Salt of the contract creation, resulting address will be derivated from this value only
    @param _creationCode Creation code (constructor) of the contract to be deployed, this value doesn't affect the resulting address
    @param _value In WEI of ETH to be forwarded to child contract
    @return addr of the deployed contract, reverts on error
  */
  function create3(bytes32 _salt, bytes memory _creationCode, uint256 _value) internal returns (address addr) {
    // Creation code
    bytes memory creationCode = PROXY_CHILD_BYTECODE;

    // Get target final address
    addr = addressOf(_salt);
    if (codeSize(addr) != 0) revert TargetAlreadyExists();

    // Create CREATE2 proxy
    address proxy; assembly { proxy := create2(_value, add(creationCode, 32), mload(creationCode), _salt)}
    if (proxy == address(0)) revert ErrorCreatingProxy();

    // Call proxy with final init code
    (bool success,) = proxy.call(_creationCode);
    if (!success || codeSize(addr) == 0) revert ErrorCreatingContract();
  }

  /**
    @notice Computes the resulting address of a contract deployed using address(this) and the given `_salt`
    @param _salt Salt of the contract creation, resulting address will be derivated from this value only
    @return addr of the deployed contract, reverts on error

    @dev The address creation formula is: keccak256(rlp([keccak256(0xff ++ address(this) ++ _salt ++ keccak256(childBytecode))[12:], 0x01]))
  */
  function addressOf(bytes32 _salt) internal view returns (address) {
    address proxy = address(
      uint160(
        uint256(
          keccak256(
            abi.encodePacked(
              hex'ff',
              address(this),
              _salt,
              KECCAK256_PROXY_CHILD_BYTECODE
            )
          )
        )
      )
    );

    return address(
      uint160(
        uint256(
          keccak256(
            abi.encodePacked(
              hex"d6_94",
              proxy,
              hex"01"
            )
          )
        )
      )
    );
  }
}