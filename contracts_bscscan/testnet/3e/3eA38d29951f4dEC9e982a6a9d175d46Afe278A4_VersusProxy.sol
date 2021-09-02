/**
 *Submitted for verification at BscScan.com on 2021-09-01
*/

pragma solidity ^0.8.0;

contract VersusProxy {
    event myEvent(bytes);
    
    // Code position in storage is keccak256("PROXIABLE") = "0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7"
    constructor(bytes memory constructData, address contractLogic) public {
        // save the code address
        assembly { // solium-disable-line
            sstore(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7, contractLogic)
        }
        (bool success, bytes memory __ ) = contractLogic.delegatecall(constructData); // solium-disable-line
        emit myEvent(__);
        require(success, "Construction failed");
    }

    fallback() external payable {
        assembly { // solium-disable-line
            let contractLogic := sload(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7)
            calldatacopy(0x0, 0x0, calldatasize())
            let success := delegatecall(gas(), contractLogic, 0x0, calldatasize(), 0, 0)
            
            returndatacopy(0, 0, returndatasize())
            switch success
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}