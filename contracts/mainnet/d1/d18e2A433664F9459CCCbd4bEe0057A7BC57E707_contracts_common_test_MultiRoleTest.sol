/*
  MultiRoleTest contract.
*/

pragma solidity ^0.6.0;

import "../implementation/MultiRole.sol";


// The purpose of this contract is to make the MultiRole creation methods externally callable for testing purposes.
contract MultiRoleTest is MultiRole {
    function createSharedRole(
        uint256 roleId,
        uint256 managingRoleId,
        address[] calldata initialMembers
    ) external {
        _createSharedRole(roleId, managingRoleId, initialMembers);
    }

    function createExclusiveRole(
        uint256 roleId,
        uint256 managingRoleId,
        address initialMember
    ) external {
        _createExclusiveRole(roleId, managingRoleId, initialMember);
    }

    // solhint-disable-next-line no-empty-blocks
    function revertIfNotHoldingRole(uint256 roleId) external view onlyRoleHolder(roleId) {}
}
