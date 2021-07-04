pragma solidity ^0.4.23;

library StaticCallProxy {
    function read(address, bytes memory) public returns (bytes32) {
        assembly {
            let _calldatasize := calldatasize()
            calldatacopy(0, 0, _calldatasize)
            
            // 0x9569bf28 = keccak256(readInternal(address,bytes))
            mstore8(0, 0x95)
            mstore8(add(0, 1), 0x69)
            mstore8(add(0, 2), 0xbf)
            mstore8(add(0, 3), 0x28)
            pop(call(gas(), address(), 0, 0, _calldatasize, 0, 0))
            returndatacopy(0, 0, returndatasize())
            return(0, 32)
        }
    }
}

contract Test {
    bytes32 abc = 0x5;
    
    function readInternal(address _destination, bytes _calldata) public returns (bytes32) {
        uint256 _calldata_length = _calldata.length;
        assembly {
            pop(call(gas(), _destination, 0, add(_calldata, 0x20), _calldata_length, 0, 0))
            returndatacopy(0, 0, returndatasize())
            revert(0, 32)
        }
    }
    
    function fakeState() public returns (bytes32) {
        abc = 0xd0990;
        return abc;
    }

    function newState() public view returns (bytes32) {
        return StaticCallProxy.read(address(this), abi.encodeWithSignature("fakeState()"));
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
  }
}