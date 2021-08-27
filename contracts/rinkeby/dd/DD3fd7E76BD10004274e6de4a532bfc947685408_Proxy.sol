// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

/**
 * @title Pixel Map Wrapper Proxy
 */
contract Proxy {

    address public constant PIXELMAP = 0xa916B776F8aB8f024e1A34bF99CfDCF8aF6CA01F;
    address public constant WRAPPER = 0x0A3f9E7e9190dBE301AB63A87e8b47871a331223;
    
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