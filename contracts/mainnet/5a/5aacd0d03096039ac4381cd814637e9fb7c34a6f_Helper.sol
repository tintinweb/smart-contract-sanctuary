/**
 *Submitted for verification at Etherscan.io on 2021-04-03
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.2;

interface ManagementList {
    function isManager(address accountAddress) external returns (bool);
}

contract Manageable {
    ManagementList public managementList;

    constructor(address _managementListAddress) {
        managementList = ManagementList(_managementListAddress);
    }

    modifier onlyManagers() {
        bool isManager = managementList.isManager(msg.sender);
        require(isManager, "ManagementList: caller is not a manager");
        _;
    }
}

contract Helper is Manageable {
    address[] public _helpers;

    constructor(address _managementListAddress)
        Manageable(_managementListAddress)
    {}

    function setHelpers(address[] memory helperAddresses)
        external
        onlyManagers
    {
        _helpers = helperAddresses;
    }

    function helpers() external view returns (address[] memory) {
        return (_helpers);
    }

    fallback() external {
        for (uint256 i = 0; i < _helpers.length; i++) {
            address helper = _helpers[i];
            assembly {
                calldatacopy(0, 0, calldatasize())
                let success := staticcall(
                    gas(),
                    helper,
                    0,
                    calldatasize(),
                    0,
                    0
                )
                returndatacopy(0, 0, returndatasize())
                if success {
                    return(0, returndatasize())
                }
            }
        }
        revert("Helper: Fallback proxy failed to return data");
    }
}