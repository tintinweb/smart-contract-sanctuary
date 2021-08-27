// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

/**
 * @title Pixel Map Wrapper Proxy
 */
contract Proxy {

    address public constant PIXELMAP = 0xbB7CeFa7CAA3FfE70b68A3E508D19d412490EECC;
    address public constant WRAPPER = 0x17C3005A014409370eC7Bbc875005971cbC4cC55;
    
    function delegateCallWrap(uint _location) external payable {
        
        (bool setSuccess, bytes memory setData) = PIXELMAP.delegatecall(
            abi.encodeWithSignature("setTile(uint, string, string, uint", _location, 'x', 'x', msg.value)
        );
        assert(setSuccess);
        
        (bool wrapSuccess, bytes memory wrapData) = WRAPPER.delegatecall(abi.encodeWithSignature("wrap(uint)", _location));
        assert(wrapSuccess);
    }
}

{
  "optimizer": {
    "enabled": true,
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