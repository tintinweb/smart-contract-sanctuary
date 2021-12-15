// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {OperationCenterInterface} from "./interfaces/IOperationCenter.sol";

contract AccountProxy {
    event ShowAddress(address addr);
    // auth is shared storage with AccountProxy and any OpCode.
    mapping(address => bool) internal _auth;

    address internal immutable opCenterAddress;

    constructor(address _opCenterAddress) {
        opCenterAddress = _opCenterAddress;
    }

    fallback() external payable {
        delegate(msg.sig);
    }

    receive() external payable {
        if (msg.sig != 0x00000000) {
            delegate(msg.sig);
        }
    }

    function delegate(bytes4 _sig) internal {
        address _opCodeAddress = OperationCenterInterface(opCenterAddress)
            .getOpCodeAddress(_sig);
        require(_opCodeAddress != address(0), "CHFRY Account: Not found OpCode");
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OperationCenterInterface {
    function eventCenterAddress() external view returns (address);
    function connectorCenterAddress() external view returns (address);
    function tokenCenterAddress() external view returns (address);
    function protocolCenterAddress() external view returns (address);
    function getOpCodeAddress(bytes4 _sig) external view returns (address);
}