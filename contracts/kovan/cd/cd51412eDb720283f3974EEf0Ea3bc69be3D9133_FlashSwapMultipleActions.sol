//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.3;

import { IFlashSwapResolver } from "./interfaces/IFlashSwapResolver.sol";

contract FlashSwapMultipleActions is IFlashSwapResolver{

    function resolveUniswapV2Call(
        address sender,
        address tokenRequested,
        address tokenToReturn,
        uint256 amountRecived,
        uint256 amountToReturn,
        bytes memory _data
        ) public payable override{

        ( 
            address target, 
            bytes memory datacall,
            bool hasNext,
            bytes memory dataForNext
        ) = abi.decode(_data, (
                address, bytes, bool, bytes
            )
        );

        execute(target, datacall);

        if (hasNext)
            resolveUniswapV2Call(sender, tokenRequested, tokenToReturn, amountRecived, amountToReturn, dataForNext);

    }

    function execute(
        address _target, bytes memory _data
        ) 
        internal
        returns (bytes32 response)
        {

        require(_target != address(0));

        // dynamic call passing ETH value, and where this would be msg.sender
        assembly {

            let succeeded := call(
                sub(gas(), 5000),  // we are passing the remaining gas except for 5000
                _target, // the target contract
                callvalue(), // ETH value sent to this function
                add(_data, 0x20), // pointer to data (the first 0x20 (32) bytes indicates de length)
                mload(_data), // size of data (the first 0x20 (32) bytes indicates de length)
                0, // pointer to store returned data
                32) // size of the memory where will be stored the data (defined 32 bytes fixed)
            response := mload(0)      // load call output
            switch iszero(succeeded)
            case 1 {
                // throw if delegatecall failed
                let ptr := mload(0x40)
                let size := returndatasize()
                returndatacopy(ptr, 0, size)
                revert(ptr, size)
            }
        }

    }

}

pragma solidity >=0.6.0 <0.8.0;

interface IFlashSwapResolver{

    /**
    @param sender The address who calls IUniswapV2Pair.swap.
    @param tokenRequested The address of the token that was requested to IUniswapV2Pair.swap.
    @param tokenToReturn The address of the token that should be returned to IUniswapV2Pair(msg.sender).
    @param amountRecived The ammount recived of tokenRequested.
    @param amountToReturn The ammount recived of tokenRequested.
    @param _data dataForResolveUniswapV2Call: check FlashSwapProxy.uniswapV2Call documentation
     */
    function resolveUniswapV2Call(
            address sender,
            address tokenRequested,
            address tokenToReturn,
            uint256 amountRecived,
            uint256 amountToReturn,
            bytes calldata _data
            ) external payable;
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "remappings": [],
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