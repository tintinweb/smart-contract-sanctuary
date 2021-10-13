// SPDX-License-Identifier: MIT

/**
 * Polkally (https://polkally.com)
 * @author Polkally <[email protected]>
 */

pragma solidity ^0.8.0;

contract PermissionManager {


    event GrantRole(string roleName, address indexed _account, uint256 accountId);
    event Revoke(string roleName, address indexed _account, uint256 accountId);
    event RemoveMember(string roleName, address indexed _account, uint256 accountId);

    //default role
    string SUPER_ADMIN_ROLE = "SUPER_ADMIN";
    string MODERATOR_ROLE   = "MODERATOR";
    string ADMIN_ROLE       = "ADMIN";

    struct RoleItem {
        address   account;
        bytes32   role;
        bool      isActive;
        uint256   createdAt;
        uint256   updatedAt;
    }

    mapping(uint256 => RoleItem) private Roles;
    mapping(address => uint256) private roleMapIndexes;

    uint256 totalMembers;

     constructor() {

        address _owner = msg.sender;
        _grantRole(SUPER_ADMIN_ROLE, _owner);
    }

    /**
     * grant role to an address
     */
    function _grantRole(string memory roleName, address _account) private  {

        require(bytes(roleName).length > 0,"PERMISSION_MANAGER: ROLE_NAME_REQUIRED");
        
        // lets check if user account exists already
        if(roleMapIndexes[_account] > 0 && Roles[roleMapIndexes[_account]].account == _account){
            revert("PERMISSION_MANAGER: ACCOUNT_ALREADY_HAVE_A_ROLE");
        }

        uint256 nextMemberId = ++totalMembers;

        Roles[nextMemberId] = RoleItem({
            account: _account,
            role: strToBytes32(roleName),
            isActive: true,
            createdAt: block.timestamp,
            updatedAt: block.timestamp
        });
        
        //add index
        roleMapIndexes[_account] = nextMemberId;

        //allRolesMembers
         emit GrantRole(roleName,_account, nextMemberId);
    } //end fun


    /**
     * grantRole
     */
    function grantRole(string memory roleName, address _account) public onlySuperAdmin {
        return _grantRole(roleName, _account);
    }

    /**
     * hasRole
     */
    function hasRole(string memory roleName, address _account) public view returns(bool) {
        uint256 _accountId = roleMapIndexes[_account];
        return (Roles[_accountId].isActive && Roles[_accountId].role == strToBytes32(roleName));
    }


        /**
     * @dev is super admin
     */
     function isSuperAdmin(address _account) public view returns (bool) {
        return hasRole(SUPER_ADMIN_ROLE,_account);
     }

    /**
    * isAdmin
    */
    function isAdmin(address _account) public view  returns(bool) {
        return hasRole(ADMIN_ROLE,_account) || isSuperAdmin(_account);
    }

    /**
     * @dev isModerator
     */
    function isModerator(address _account) public view returns (bool) {
      return hasRole(MODERATOR_ROLE,_account) || isAdmin(_account);
    }


    /**
     * @dev super admin only modifier
     */
    modifier onlySuperAdmin() {
         //ONLY_SUPER_ADMINS_ALLOWED
        require(isSuperAdmin(msg.sender) == true, "PERMISSION_MANAGER: ONLY_SUPER_ADMINS_ALLOWED");
        _;
    }


    /**
     * remove user from role
     */
    function revoke(string memory roleName, address _account) external onlySuperAdmin {

        require(msg.sender != _account, "PERMISSION_MANAGER: SELF_REVOKE_NOT_POSSIBLE");

        uint256 _accountId = roleMapIndexes[_account];

        Roles[_accountId].isActive = false;

        emit Revoke(roleName, _account, _accountId);
    }

    /**
     * remove user from role
     */
    function removeMember(string memory roleName, address _account) external onlySuperAdmin {

        require(msg.sender != _account, "PERMISSION_MANAGER: SELF_REMOVE_NOT_POSSIBLE");

        uint256 _accountId = roleMapIndexes[_account];

        delete Roles[_accountId];
        delete roleMapIndexes[_account];

        emit RemoveMember(roleName, _account, _accountId);
    }

    /**
     * @dev get all members
     */
    function getMembers() public view onlySuperAdmin returns(RoleItem[] memory) {

        RoleItem[] memory rolesItemsArray = new RoleItem[](totalMembers+1);

        if(totalMembers == 0){
            return rolesItemsArray;
        }

        for(uint256 i = totalMembers; i >= 1; i--){

            if(Roles[i].account == address(0)) continue;

            rolesItemsArray[i] = Roles[i];
        }

        return rolesItemsArray;
    } //en function


    function strToBytes32(string memory source) public pure returns (bytes32 result) {
                
        if (bytes(source).length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

}