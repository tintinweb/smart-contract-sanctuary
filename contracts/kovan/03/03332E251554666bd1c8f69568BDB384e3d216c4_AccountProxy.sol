// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OperationCenterInterface {
    function getOpCodeAddress(bytes4 _sig) external view returns (address);
}

contract AccountProxy {

    address accountIndex;
    
    // auth is shared storage with AccountProxy and any OpCode.
    mapping(address => bool) internal _auth;
    
    OperationCenterInterface public immutable opCenter;
    
    constructor(address _opCenterInterface) {
        opCenter = OperationCenterInterface(_opCenterInterface);
    }

    fallback () external payable {
        delegate(msg.sig);
    }

    receive () external payable {
        if (msg.sig != 0x00000000) {
            delegate(msg.sig);
        }
    }

    function delegate(bytes4 _sig) internal {
        address _opCodeAddress = opCenter.getOpCodeAddress(_sig);
        require(_opCodeAddress != address(0), "CHFRY Account: Not able to find OpCode");
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), _opCodeAddress, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
                case 0 { revert(0, returndatasize()) }
                default { return(0, returndatasize()) }
        }
    }
}