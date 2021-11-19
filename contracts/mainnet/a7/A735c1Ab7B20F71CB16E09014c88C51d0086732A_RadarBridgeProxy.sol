// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RadarBridgeProxy {
    
    constructor(bytes memory _constructorData, address _radarBridge) {

        assembly {
            // solium-disable-line
            sstore(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc, _radarBridge)
        }

        (bool success, bytes memory returnData) = _radarBridge.delegatecall(_constructorData); // solium-disable-line
        require(success, string(returnData));
    }

    fallback() external payable {
        assembly {
            // solium-disable-line
            let contractLogic := sload(
                0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
            )
            calldatacopy(0x0, 0x0, calldatasize())
            let success := delegatecall(
                sub(gas(), 10000),
                contractLogic,
                0x0,
                calldatasize(),
                0,
                0
            )
            let retSz := returndatasize()
            returndatacopy(0, 0, retSz)
            switch success
                case 0 {
                    revert(0, retSz)
                }
                default {
                    return(0, retSz)
                }
        }
    }
}