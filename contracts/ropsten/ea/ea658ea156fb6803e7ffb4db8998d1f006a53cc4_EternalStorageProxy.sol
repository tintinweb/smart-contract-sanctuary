pragma solidity 0.5.17;

import "./EternalStorageData.sol";

/**
 * @title EternalStorageProxy
 * @dev This is a proxy pattern that holds all the necessary state variables to carry out the storage of any contract.
 * After V1.0 audit
 */
contract EternalStorageProxy is EternalStorageData {
    
    /**
     * @param contractLogic - the address of the first implementation of this contract's logic
     */
    constructor(address contractLogic) public {
        // save the code address
        addressStorage[keccak256('proxy.implementation')] = contractLogic; 
    }
    
    /**
     * This function runs every time a function is invoked on this contract, it is the "fallback function"
     */
    function() external payable {
        
        //get the address of the contract holding the logic implementation
        address contractLogic = addressStorage[keccak256('proxy.implementation')];
        assembly { 
            //copy the data embedded in the function call that triggered the fallback
            calldatacopy(0x0, 0x0, calldatasize)
            //delegate this call to the linked contract
            let success := delegatecall(sub(gas, 10000), contractLogic, 0x0, calldatasize, 0, 0)
            let retSz := returndatasize
            //get the returned data
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