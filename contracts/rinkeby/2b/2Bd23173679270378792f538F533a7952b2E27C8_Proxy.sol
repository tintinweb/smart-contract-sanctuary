// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

/**
 * @title Pixel Map Wrapper Proxy
 */
contract Proxy {

    address public constant PIXELMAP = 0x26225f47d5967a4D9Af8e4B2589d58fB2325E13e;
    address public constant WRAPPER = 0xc2e91fE0289fB8Faaa141FC4430020634492Fd71;
    
    function delegateCallWrap(uint256 _location) external payable {
        
        (bool setSuccess,bytes memory setData) = PIXELMAP.delegatecall(
            abi.encodeWithSignature("setTile(uint256,string,string,uint256)",_location,'x','x',msg.value)
        );
        if(!setSuccess) {
            revert(string(setData));
        }
        
        //(bool wrapSuccess,) = WRAPPER.call{value: msg.value}(abi.encodeWithSignature("wrap(uint256)",_location));
        //assert(wrapSuccess);
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