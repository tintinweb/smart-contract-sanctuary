/**
 *Submitted for verification at Etherscan.io on 2021-09-10
*/

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.8.0;
pragma abicoder v2;

contract CSM {
    event DelegateAdded(address indexed delegate, address indexed sender);

    event DelegateRemoved(address indexed delegate, address indexed sender);

    event RoleAdded(bytes32 indexed role, address indexed sender);

    event RoleRemoved(bytes32 indexed role, address indexed sender);

    event RoleGranted(
        bytes32 indexed role,
        address indexed delegate,
        address indexed sender
    );

    event RoleRevoked(
        bytes32 indexed role,
        address indexed delegate,
        address indexed sender
    );

    event AssocContractFuncs(
        bytes32 indexed role,
        address indexed _contract,
        string[] funcList,
        address indexed sender
    );

    event DissocContractFuncs(
        bytes32 indexed role,
        address indexed _contract,
        string[] funcList,
        address indexed sender
    );

    function isDelegate(address delegate) public view returns (bool) {
        return true;
    }

    function grantRole(bytes32 role, address delegate) external {}

    function revokeRole(bytes32 role, address delegate) external {}

    function hasRole(bytes32 role, address delegate)
        public
        view
        returns (bool)
    {
        return true;
    }

    function addRole(bytes32 role) external {}

    function removeRole(bytes32 role) external {}

    function execTransaction(address to, bytes memory data) external {}

    function execTransactions(address[] memory toList, bytes[] memory dataList)
        external
    {}

    function hasPermission(
        address delegate,
        address to,
        bytes memory data
    ) public view returns (bool) {
        return true;
    }

    function hasPermission(
        address delegate,
        address to,
        bytes4 selector
    ) public view returns (bool) {
        return true;
    }

    function assocRoleWithContractFuncs(
        bytes32 role,
        address _contract,
        string[] memory funcList
    ) external {}

    function dissocRoleFromContractFuncs(
        bytes32 role,
        address _contract,
        string[] memory funcList
    ) external {}

    constructor(address payable _safe) {}
}