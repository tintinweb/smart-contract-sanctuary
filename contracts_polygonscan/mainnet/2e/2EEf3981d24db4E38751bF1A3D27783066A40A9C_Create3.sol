//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


contract Create3 {
  error ErrorCreatingContract();

  function bytecode() private view returns (bytes memory) {
    /*
      3D RETURNDATASIZE (0) // retLength = 0
      80 DUP1               // retOffset = 0
      80 DUP1               // argsLength = 0
      80 DUP1               // argsOffset = 0
      80 DUP1               // value = 0
      73 PUSH20 <self>      // to = address(this)
      80 DUP1               // gas = address(this)
      F1 CALL               // call address(this) from init code
      3D RETURNDATASIZE     // code size
      60 PUSH1 00           // offset
      80 DUP1               // destOffset
      3E RETURNDATACOPY     // copy returned code
      3D RETURNDATASIZE     // code size
      60 PUSH1 00           // offset
      F3 RETURN
    */
    return abi.encodePacked(
      hex"3D_80_80_80_80_73",
      address(this),
      hex"80_F1_3D_60_00_80_3E_3D_60_00_F3"
    );
  }
  
  function create(bytes32 _salt, bytes calldata _code) external payable returns (address addr) {
    // Creation code
    bytes memory creationCode = bytecode();
    
    // CREATE2 salt uses msg.sender + provided salt
    bytes32 salt = keccak256(abi.encodePacked(msg.sender, _salt));

    // Store _code in buffer
    assembly {
      let codeSize := _code.length

      sstore(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff, codeSize)
      let offSet := _code.offset

      for
        { let i := 0 }
        lt(i, codeSize)
        { i := add(i, 0x20) }
      {
        sstore(i, calldataload(add(offSet, i)))
      }

      // Call CREATE2 contract
      addr := create2(callvalue(), add(creationCode, 32), mload(creationCode), salt)
    }

    if (addr == address(0)) revert ErrorCreatingContract();
  }
  
  function addressOf(address _sender, bytes32 _salt) external view returns (address) {
    return address(
      uint160(
        uint256(
          keccak256(
            abi.encodePacked(
              hex'ff',
              address(this),
              keccak256(abi.encodePacked(_sender, _salt)),
              keccak256(bytecode())
            )
          )
        )
      )
    );
  }

  fallback() external {
    assembly {
      // Consume buffer
      let size := sload(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
      sstore(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff, 0)

      for
        { let i := 0 }
        lt(i, size)
        { i := add(i, 0x20) }
      {
        mstore(i, sload(i))
        sstore(i, 0)
      }
  
      return(0, size)
    }
  }
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}