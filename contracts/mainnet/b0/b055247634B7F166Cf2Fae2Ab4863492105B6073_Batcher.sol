pragma solidity ^0.7.0;
pragma abicoder v2;

contract Batcher {
  function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
    // If the _res length is less than 68, then the transaction failed silently (without a revert message)
    if (_returnData.length < 68) return "Transaction reverted silently";

    assembly {
      // Slice the sighash.
      _returnData := add(_returnData, 0x04)
    }
    return abi.decode(_returnData, (string)); // All that remains is the revert string
  }

  function batch(
    bytes[] memory calls
  ) public payable returns (bytes[] memory results) {
    // Interactions
    results = new bytes[](calls.length);
    for (uint256 i = 0; i < calls.length; i++) {
      bytes memory data = calls[i];
      address target;
      bool doDelegate;
      uint88 value;
      assembly {

        let opts := mload(add(data, mload(data)))
        target := shr(96, opts)
        doDelegate := byte(20, opts)
        value := and(opts, 0xffffffffffffffffffffff)
        mstore(data, sub(mload(data), 32))
      }
      (bool success, bytes memory result) = doDelegate ? target.delegatecall(data) : target.call{value: value}(data);
      if (!success) {
        revert(_getRevertMsg(result));
      }
      results[i] = result;
    }
  }
}

