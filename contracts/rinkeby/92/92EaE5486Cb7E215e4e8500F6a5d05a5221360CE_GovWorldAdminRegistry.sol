// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.0;
import "./GovWorldAdminBase.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract GovWorldAdminRegistry is GovWorldAdminBase {

    using SafeMath for *;

    address public superAdmin; //it should be private

    constructor(
        address _superAdmin,
        address _admin1,
        address _admin2,
        address _admin3
    ) {
        //owner becomes the default admin.
        _makeDefaultApproved(
            _superAdmin,
            AdminAccess(
                true, true, true, true,
                true, true, true, true,
                true, true, true, true, true
            )
        );

        _makeDefaultApproved(
            _admin1,
            AdminAccess(
                true, true, true, true,
                true, true, true, true,
                true, true, true, true, false
            )
        );
        _makeDefaultApproved(
            _admin2,
            AdminAccess(
                true, true, true, true,
                true, true, true, true,
                true, true, true, true, false
            )
        );
        _makeDefaultApproved(
            _admin3,
            AdminAccess(
                true, true, true, true,
                true, true, true, true,
                true, true, true, true, false
            )
        );

        superAdmin = _superAdmin;
    }

    function transferSuperAdmin(address _newSuperAdmin)
    external
    {
        require(_newSuperAdmin!=address(0),'invalid newSuperAdmin');
        require(_newSuperAdmin != superAdmin, 'already designated');
        require(msg.sender == superAdmin,'not super admin');
        for(uint i = 0; i < allApprovedAdmins.length; i++) {
        if(allApprovedAdmins[i] == _newSuperAdmin) { 
        approvedAdminRoles[_newSuperAdmin].superAdmin = true;
        approvedAdminRoles[superAdmin].superAdmin = false;
        superAdmin = _newSuperAdmin;
       
        }
        emit SuperAdminOwnershipTransfer(_newSuperAdmin, approvedAdminRoles[_newSuperAdmin]);

        }
        
    }

    /**
     * @dev Checks if a given _newAdmin is approved by all other already approved amins
     * @param _newAdmin Address of the new admin
     */
    function isApprovedByAll(address _newAdmin) external view returns (bool) {
        //following two loops check if all currenctly
        //approvedAdminRoles are present in approvebyAdmins of the _newAdmin
        //loop all existing admins approvedBy array
        address[] memory _approvedByAdmins = approvedByAdmins[_newAdmin];
      
        uint256 presentCount = 0;
        uint256 allCount = 0;
        //get All admins with add govAdmin rights
        for (uint256 i = 0; i < allApprovedAdmins.length; i++) {
            if (approvedAdminRoles[allApprovedAdmins[i]].addGovAdmin && allApprovedAdmins[i] != _newAdmin ) {
                allCount =  allCount.add(1);
                for (uint256 j = 0; j < _approvedByAdmins.length; j++) {
                    if (_approvedByAdmins[j] == allApprovedAdmins[i]) {
                        presentCount = presentCount.add(1);
                    }
                }
            }
        }
       if(presentCount >= allCount.div(2)+1)// standard multi-sig 51 % approvals needed to perform
            return true;
        else return false;
    }

    /**
     * @dev Checks if a given _admin is removed by all other already approved amins
     * @param _admin Address of the new admin
     */
    function isRemovedByAll(address _admin) external view returns (bool) {
        //following two loops check if all currenctly
        //removedAdminRoles are present in removedbyAdmins of the _admin
        //loop all existing admins removedBy array
        address[] memory _removedByAdmins = removedByAdmins[_admin];

        uint256 presentCount = 0;
        uint256 allCount = 0;

        //get All admins with only edit govAdmin rights
        for (uint256 i = 0; i < allApprovedAdmins.length; i++) {
            if (
                approvedAdminRoles[allApprovedAdmins[i]].editGovAdmin &&
                allApprovedAdmins[i] != _admin
            )
             {  
                allCount =  allCount.add(1);
                for (uint256 j = 0; j < _removedByAdmins.length; j++) {
                    if (_removedByAdmins[j] == allApprovedAdmins[i]) {
                        presentCount = presentCount.add(1);
                    }
                }
            }
        }
        if(presentCount >= allCount.div(2)+1)// standard multi-sig 51 % approvals needed to perform
            return true;
        else return false;
    }

    /**
     * @dev Checks if a given _admin is approved for editby all other already approved amins
     * @param _admin Address of the new admin
     */
    function isEditedByAll(address _admin) external view returns (bool) {
        //following two loops check if all currenctly
        //approvedAdminRoles are present in approvebyAdmins of the _newAdmin
        //loop all existing admins approvedBy array
        address[] memory _editedByAdmins = editedByAdmins[_admin];

        uint256 presentCount = 0;
        uint256 allCount = 0;
        //get All admins with add govAdmin rights
        for (uint256 i = 0; i < allApprovedAdmins.length; i++) {
            if (
                approvedAdminRoles[allApprovedAdmins[i]].editGovAdmin && 
                allApprovedAdmins[i] != _admin  //all but yourself.
                ) {
                allCount =  allCount.add(1);
                //needs to check availability for all allowed admins to approve in editByAdmins.
                for (uint256 j = 0; j < _editedByAdmins.length; j++) {
                    if (_editedByAdmins[j] == allApprovedAdmins[i]) {
                         presentCount = presentCount.add(1);
                    }
                }
            }
        }
       if(presentCount >= allCount.div(2)+1)// standard multi-sig 51 % approvals needed to perform
            return true;
        else return false;
    }

    
    /**
     * @dev makes _newAdmin an approved admin if there is only one curernt admin _newAdmin becomes
     * becomes approved as it is and if currently more then 1 admins then approveAddedAdmin needs to be
     * called  by all current admins
     * @param _newAdmin Address of the new admin
     * @param _adminAccess access variables for _newadmin
     */
    function addAdmin(address _newAdmin, AdminAccess memory _adminAccess)
        external
        onlyAddGovAdminRole(msg.sender)
    {
        require(_newAdmin != address(0),'invalid address');        
        require(_newAdmin != msg.sender, "GAR: Cannot add himself again, you already an Admin");//the GovAdmin cannot add himself as admin again
        //the admin that is adding _newAdmin must not already have approved. 
        require(allApprovedAdmins.length > 0, "GAR: addDefaultAdmin as onwer first. ");
        require(_notApproved(_newAdmin, msg.sender), "GAR: Admin already approved this admin.");
        require(!_addressExists(_newAdmin, allApprovedAdmins), "GAR: Cannot Add again other admins");
        require(_adminAccess.superAdmin == false, "GAR: cannot assign super admin role");

        if(allApprovedAdmins.length == 1) {
            //this admin is now approved just by one admin
         _makeDefaultApproved(_newAdmin, _adminAccess);   
        } else
        //this admin is now in the pending list.
        if(this.isApprovedByAll(_newAdmin)) {
        _makeDefaultApproved(_newAdmin, _adminAccess);
        }  else {
        _makePending(_newAdmin, _adminAccess);
        }
    }

    /**
     * @dev call approved the admin which is already added to pending by other admin
     * if all current admins call approveAddedAdmin are complete the admin auto becomes the approved admin
     * @param _newAdmin Address of the new admin
     */
    function approveAddedAdmin(address _newAdmin)
        external
        onlyAddGovAdminRole(msg.sender)
    {        
        require(_newAdmin != msg.sender, "GAR: cannot self approve");
        //the admin that is adding _newAdmin must not already have approved.
        require(
            _notApproved(_newAdmin, msg.sender),
            "GAR: Admin already approved this admin."
        );
        require(_addressExists(_newAdmin, pendingAddedAdminKeys),"GAR: Non Pending admin can not be approved.");
       
        approvedByAdmins[_newAdmin].push(msg.sender);
        emit NewAdminApproved(_newAdmin, msg.sender);

        //if the _newAdmin is approved by all other admins
        if (this.isApprovedByAll(_newAdmin)) {
            //no need for approvedby anymore
            delete approvedByAdmins[_newAdmin];
            //making this admin approved.
            _makeApproved(_newAdmin, pendingAddedAdminRoles[_newAdmin]);
            //no  need  for pending  role now
            delete pendingAddedAdminRoles[_newAdmin];
            
            emit NewAdminApprovedByAll(_newAdmin,  approvedAdminRoles[_newAdmin]);
        }
    }

    /**
     * @dev any admin can reject the pending admin during the approval process and one rejection means
     * not pending anymore.
     * @param _admin Address of the new admin
     */
    function rejectAddAdmin(address _admin)
        external
        onlyAddGovAdminRole(msg.sender)
    {
        require(_admin != msg.sender, "GAR: Can not call rejectAddAdmin himself");
        require(_addressExists(_admin, pendingAddedAdminKeys),"GAR: Non Pending admin can not be rejected.");
        //the admin that is adding _newAdmin must not already have approved.
        require(_notApproved(_admin, msg.sender),"GAR: Can not remove admin, you already approved.");
       
        //only with the reject of one admin call delete roles from mapping
        delete pendingAddedAdminRoles[_admin];
        for(uint256 i = 0; i < approvedByAdmins[_admin].length; i++){
            approvedByAdmins[_admin].pop();
        }
        _removePendingAddedIndex(_getIndex(_admin, pendingAddedAdminKeys));

        //delete admin roles from approved mapping
        delete approvedByAdmins[_admin];

        emit AddAdminRejected(_admin, msg.sender);
    }

    /**
     * @dev any admin can reject the pending admin during the edit approval process and one rejection means
     * not pending anymore.
     * @param _admin Address of the new admin
     */
    function rejectEditAdmin(address _admin)
        external
        onlyEditGovAdminRole(msg.sender)
    {
        require(_admin != msg.sender, "GAR: Can not call rejectEditAdmin for himself");
        require(_addressExists(_admin, pendingEditAdminKeys),"GAR: Non Pending admin can not be rejected.");
        require(editedByAdmins[_admin].length > 0, "GAR: Not available for rejection");
        //the admin that is adding _newAdmin must not already have approved.
        require(_notEdited(_admin, msg.sender),"GAR: Can not remove admin, you already approved.");
       
        //if the _newAdmin is approved by all other admins
        delete pendingEditAdminRoles[_admin];
        _removePendingEditIndex(_getIndex(_admin, pendingEditAdminKeys));

        for(uint256 i = 0; i < editedByAdmins[_admin].length; i++){
            editedByAdmins[_admin].pop();
        }
        delete editedByAdmins[_admin];

        emit EditAdminRejected(_admin, msg.sender);
    }
    /**
     * @dev any admin can reject the pending admin during the approval process and once rejection means
     * not pending anymore.
     * @param _admin Address of the new admin
     */
    function rejectRemoveAdmin(address _admin)
        external
        onlyEditGovAdminRole(msg.sender)
    {
        require(_admin != msg.sender, "GAR: Can not call rejectRemoveAdmin for himself");
        require(_addressExists(_admin, pendingRemoveAdminKeys),"GAR: Non Pending admin can not be rejected.");
        require(removedByAdmins[_admin].length > 0, "GAR: Not available for rejection");
        require(
            _notRemoved(_admin, msg.sender),
            "GAR: Can not reject remove. You already approved. "
        );
        //remove from pending removal mapping
        delete pendingRemovedAdminRoles[_admin];
        _removePendingRemoveIndex(_getIndex(_admin, pendingRemoveAdminKeys));
        //remove from removeByAdmins
        //this identifies removedByAll
        for(uint256 i = 0; i < removedByAdmins[_admin].length; i++){
            removedByAdmins[_admin].pop();
        }
        delete removedByAdmins[_admin];

        emit RemoveAdminRejected(_admin, msg.sender);
    }

    /**
    @dev Get all Approved Admins 
     */
    function getAllApproved() public view returns (address[] memory) {
        return allApprovedAdmins;
    }

    /**
    @dev Get all Pending Added Admin Keys */
    function getAllPendingAddedAdminKeys() public view returns(address[] memory) {
        return pendingAddedAdminKeys;
    }

     /**
    @dev Get all Pending Added Admin Keys */
    function getAllPendingEditAdminKeys() public view returns(address[] memory) {
        return pendingEditAdminKeys;
    }

     /**
    @dev Get all Pending Added Admin Keys */
    function getAllPendingRemoveAdminKeys() public view returns(address[] memory) {
        return pendingRemoveAdminKeys;
    }

    /**
    @dev Get all admin addresses which approved the address in the parameter
    @param _addedAdmin address of the approved/proposed added admin.
     */
    function getApprovedByAdmins(address _addedAdmin) public view returns(address[] memory) {
        return approvedByAdmins[_addedAdmin];
    }

    /**
    @dev Get all edit by admins addresses
     */
    function getEditbyAdmins(address _editAdmin) public view returns(address[] memory) {
        return editedByAdmins[_editAdmin];
    }

      /**
    @dev Get all admin addresses which approved the address in the parameter
    @param _removedAdmin address of the approved/proposed added admin.
     */
    function getRemovedByAdmins(address _removedAdmin) public view returns(address[] memory) {
        return removedByAdmins[_removedAdmin];
    }


    /**
    @dev Get pending edit admin roles
     */
    function getpendingEditAdminRoles(address _editAdmin) public view returns(AdminAccess memory) {
        return pendingEditAdminRoles[_editAdmin];
    }
    /**
     * @dev Initiate process of removal of admin,
     * in case there is only one admin removal is done instantly.
     * If there are more then one admin all must call removePendingAdmin.
     * @param _admin Address of the admin requested to be removed
     */
    function removeAdmin(address _admin)
        external
        onlyEditGovAdminRole(msg.sender)
    {
        require(_admin != address(0),'invalid address');
        require(_admin != superAdmin, "GAR: Cannot Remove Super Admin");
        require(_admin != msg.sender, "GAR: Can not call removeAdmin for himself");
        //the admin that is removing _admin must not already have approved.
        require(_notRemoved(_admin, msg.sender),"GAR: Admin already removed this admin. ");
        require(allApprovedAdmins.length > 0, "Can not remove last remaining admin.");
        require(!_addressExists(_admin, pendingRemoveAdminKeys) ,"GAR: Admin already pending for remove approval" );
        require(_addressExists(_admin, allApprovedAdmins), "GAR: Not an admin");
        
        // require(pendingRemoveAdminKeys.length == 0, "GAR: pending actions, cannot remove now");
        //if length is 1 there is only one admin and he/she is removing another admin
         if(allApprovedAdmins.length == 1) {
            //this admin is now approved just by one admin
         _removeAdmin(_admin);   
        } else
        //this admin is now in the pending list.
        if(this.isRemovedByAll(_admin)) {
        _removeAdmin(_admin);
        } else{ 
        _makePendingForRemove(_admin); 
        }         
    }

    /**
     * @dev call approved the admin which is already added to pending by other admin
     * if all current admins call approveAddedAdmin are complete the admin auto becomes the approved admin
     * @param _admin Address of the new admin
     */
    function approveRemovedAdmin(address _admin)
        external
        onlyEditGovAdminRole(msg.sender)
    {
        require(_admin != msg.sender, "GAR: Can not call approveRemovedAdmin for himself");
        //the admin that is adding _admin must not already have approved.
        require(_notRemoved(_admin, msg.sender),"GAR: Admin already approved this admin.");
        require(_admin != msg.sender, "GAR: Can not self remove");
        require(_addressExists(_admin, pendingRemoveAdminKeys),"GAR: Non Pending admin can not be approved.");

        removedByAdmins[_admin].push(msg.sender);

        //if the _admin is approved by all other admins for removal
        if (this.isRemovedByAll(_admin)) {
            // _admin is now an approved admin.
            _removeAdmin(_admin);
            performPendingActions();
        } else {
            emit RemoveAdminForApprove(_admin, msg.sender);
        }
    }
    
    function performPendingActions()
        internal        
    {
        for(uint256 i = 0 ; i < pendingAddedAdminKeys.length; i++)
        {
            if(this.isApprovedByAll(pendingAddedAdminKeys[i])){
                _makeApproved(pendingAddedAdminKeys[i], pendingAddedAdminRoles[pendingAddedAdminKeys[i]]);
            }
        }
        for(uint256 i = 0 ; i < pendingEditAdminKeys.length; i++)
        {
            if(this.isEditedByAll(pendingEditAdminKeys[i])){
                _editAdmin(pendingEditAdminKeys[i]);
            }
        }
        for(uint256 i = 0 ; i < pendingRemoveAdminKeys.length; i++)
        {
            if(this.isRemovedByAll(pendingRemoveAdminKeys[i])){
                _removeAdmin(pendingEditAdminKeys[i]);
            }
        }
    }
    /**
     * @dev Initiate process of edit of an admin,
     * If there are more then one admin all must call approveEditAdmin
     * @param _admin Address of the admin requested to be removed
     */
    function editAdmin(address _admin, AdminAccess memory _adminAccess)
        external
        onlyEditGovAdminRole(msg.sender)
    {
        require(_admin != msg.sender, "GAR: Can not edit roles for himself");
        require(_admin != superAdmin, "GAR: Cannot Edit Super Admin");
        require(allApprovedAdmins.length > 0, "Can not remove last remaining admin.");
        //the admin that is removing _admin must not already have approved.
        require(_notEdited(_admin, msg.sender),"GAR: Admin already approved for edit. ");
        require(!_addressExists(_admin, pendingEditAdminKeys) ,"GAR: Admin already pending for edit approval");
        require(_addressExists(_admin, allApprovedAdmins), "GAR: Not an admin");

        require(_adminAccess.superAdmin == false, "GAR: cannot assign super admin role");

        if(allApprovedAdmins.length == 1) {
            _editAdmin(_admin);   
        } else
        //this admin is now in the pending list.
        _makePendingForEdit(_admin, _adminAccess);
        if(this.isEditedByAll(_admin)) {
            _editAdmin(_admin);
        }             
    }

    /**
     * @dev call approved the admin which is already added to pending by other admin
     * if all current admins call approveEditAdmin are complete the admin edits become active
     * @param _admin Address of the new admin
     */
    function approveEditAdmin(address _admin)
        external
        onlyEditGovAdminRole(msg.sender)
    {
        require(_admin != msg.sender, "GAR: Can not call approveEditAdmin for himself");
        require(_addressExists(_admin, pendingEditAdminKeys),"GAR: Non Pending admin can not be approved.");
        //the admin that is adding _admin must not already have approved.
        require(_notEdited(_admin, msg.sender),"GAR: Admin already approved this admin.");
        editedByAdmins[_admin].push(msg.sender);

        //if the _admin is approved by all other admins for removal
        if (this.isEditedByAll(_admin)) {
            // _admin is now an approved admin.
            _editAdmin(_admin);
            performPendingActions();
        } else {
            emit EditAdminApproved(_admin, msg.sender);
        }
    }

}

// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "../admin/admininterfaces/IGovWorldAdminRegistry.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract GovWorldAdminBase is Ownable, IGovWorldAdminRegistry {

    using SafeMath for *;

    //list of already approved admins.
    mapping(address => AdminAccess) public approvedAdminRoles;

    //list of all approved admin addresses. Stores the key for mapping approvedAdminRoles
    address[] allApprovedAdmins;

    //list of pending admins to be approved by already approved admins.
    mapping(address => AdminAccess) public pendingAddedAdminRoles;
    address [] public pendingAddedAdminKeys;

    //list of pending removed admins to be approved by already approved admins.
    mapping(address => AdminAccess) public pendingRemovedAdminRoles;
    address [] public pendingRemoveAdminKeys;

    //list of pending edit admins to be approved by already approved admins.
    mapping(address => AdminAccess) public pendingEditAdminRoles;
    address [] public pendingEditAdminKeys;

    //a list of admins approved by other admins.
    mapping(address => address[]) public approvedByAdmins;

    //a list of admins removed by other admins.
    mapping(address => address[]) public removedByAdmins;

    //a list of admins updated by other admins.
    mapping(address => address[]) public editedByAdmins;

    // access-modifier for adding gov admin
    modifier onlyAddGovAdminRole(address _admin) {
        require(approvedAdminRoles[_admin].addGovAdmin,"GAR: onlyAddGovAdminRole can add admin.");
        _;
    }

    // access-modifier for editing gov admin
    modifier onlyEditGovAdminRole(address _admin) {
        require(approvedAdminRoles[_admin].editGovAdmin,"GAR: OnlyEditGovAdminRole can edit or remove admin.");
        _;
    }

    /**
     * @dev Checks if a given _newAdmin is not approved by the _approvedBy admin.
     * @param _newAdmin Address of the new admin
     * @param _approvedBy Address of the existing admin that may have approved _newAdmin already.
     */
    function _notApproved(address _newAdmin, address _approvedBy)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < approvedByAdmins[_newAdmin].length; i++) {
            if (approvedByAdmins[_newAdmin][i] == _approvedBy) {
                return false; //approved
            }
        }
        return true; //not approved
    }

    /**
     * @dev Checks if a given _admin is not removed by the _removedBy admin.
     * @param _admin Address of the new admin
     * @param _removedBy Address of the existing admin that may have removed _admin already.
     */
    function _notRemoved(address _admin, address _removedBy)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < removedByAdmins[_admin].length; i++) {
            if (removedByAdmins[_admin][i] == _removedBy) {
                return false; //removed
            }
        }
        return true; //not removed
    }

    /**
     * @dev Checks if a given _admin is not edited by the _removedBy admin.
     * @param _admin Address of the edit admin
     * @param _editedBy Address of the existing admin that may have approved edit for _admin already.
     */
    function _notEdited(address _admin, address _editedBy)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < editedByAdmins[_admin].length; i++) {
            if (editedByAdmins[_admin][i] == _editedBy) {
                return false; //removed
            }
        }
        return true; //not removed
    }

    /**
     * @dev makes _newAdmin an approved admin and emits the event
     * @param _newAdmin Address of the new admin
     * @param _adminAccess access variables for _newadmin
     */
    function _makeDefaultApproved(address _newAdmin, AdminAccess memory _adminAccess)
        internal
    {

        //no need for approved by admin for the new  admin anymore.
        delete approvedByAdmins[_newAdmin];
        // _newAdmin is now an approved admin.
        approvedAdminRoles[_newAdmin] = _adminAccess;
        //new key for mapping approvedAdminRoles
        allApprovedAdmins.push(_newAdmin);
        emit NewAdminApprovedByAll(_newAdmin, _adminAccess);
    }

    /**
     * @dev makes _newAdmin an approved admin and emits the event
     * @param _newAdmin Address of the new admin
     * @param _adminAccess access variables for _newadmin
     */
    function _makeApproved(address _newAdmin, AdminAccess memory _adminAccess)
        internal
    {
        //no need for approved by admin for the new  admin anymore.
        delete approvedByAdmins[_newAdmin];
        // _newAdmin is now an approved admin.
        approvedAdminRoles[_newAdmin] = _adminAccess;
        //new key for mapping approvedAdminRoles
        allApprovedAdmins.push(_newAdmin);
        _removePendingAddedIndex(_getIndex(_newAdmin, pendingAddedAdminKeys));
        
    }
    

    /**
     * @dev makes _newAdmin a pendsing adnmin for approval to be given by all current admins
     * @param _newAdmin Address of the new admin
     * @param _adminAccess access variables for _newadmin
     */
    function _makePending(address _newAdmin, AdminAccess memory _adminAccess)
        internal
    {
        //the admin who is adding the new admin is approving _newAdmin by default
        approvedByAdmins[_newAdmin].push(msg.sender);

        //add _newAdmin to pendingAddedAdminRoles for approval  by all other current.
        pendingAddedAdminRoles[_newAdmin] = _adminAccess;
        pendingAddedAdminKeys.push(_newAdmin);
        emit NewAdminApproved(_newAdmin, msg.sender);
    }


    /**
     * @dev makes _newAdmin an removed admin and emits the event
     * @param _admin Address of the new admin
     */
    function _removeAdmin(address _admin) internal {
        // _admin is now a removed admin.
        delete approvedAdminRoles[_admin];
        delete removedByAdmins[_admin];
        
        //remove key for mapping approvedAdminRoles
        _removeIndex(_getIndex(_admin, allApprovedAdmins));
        _removePendingRemoveIndex(_getIndex(_admin, pendingRemoveAdminKeys));
        emit AdminRemovedByAll(_admin, msg.sender);
    }

    /**
     * @dev makes _newAdmin an removed admin and emits the event
     * @param _admin Address of the new admin
     */
    function _editAdmin(address _admin) internal {
        // _admin is now an removed admin.

        approvedAdminRoles[_admin] = pendingEditAdminRoles[_admin];

        delete editedByAdmins[_admin];
        delete pendingEditAdminRoles[_admin];
        _removePendingEditIndex(_getIndex(_admin, pendingEditAdminKeys));

        emit AdminEditedApprovedByAll(_admin, approvedAdminRoles[_admin]);
    }


    function _removeIndex(uint index) internal {

        for (uint256 i = index; i < allApprovedAdmins.length.sub(1); i++) {
            allApprovedAdmins[i] = allApprovedAdmins[i + 1];
        }
        // allApprovedAdmins[index] = allApprovedAdmins[allApprovedAdmins.length.sub(1];
        allApprovedAdmins.pop();
        
    }

    function _removePendingAddedIndex(uint index) internal {
        for (uint256 i = index; i < pendingAddedAdminKeys.length.sub(1); i++) {
            pendingAddedAdminKeys[i] = pendingAddedAdminKeys[i + 1];
        }
        // allApprovedAdmins[index] = allApprovedAdmins[allApprovedAdmins.length.sub(1];
        pendingAddedAdminKeys.pop();
    }


    function _removePendingEditIndex(uint index) internal {
        for (uint256 i = index; i < pendingEditAdminKeys.length.sub(1); i++) {
            pendingEditAdminKeys[i] = pendingEditAdminKeys[i + 1];
        }
        // allApprovedAdmins[index] = allApprovedAdmins[allApprovedAdmins.length.sub(1];
        pendingEditAdminKeys.pop();
    }


    function _removePendingRemoveIndex(uint index) internal {
        for (uint256 i = index; i < pendingRemoveAdminKeys.length.sub(1); i++) {
            pendingRemoveAdminKeys[i] = pendingRemoveAdminKeys[i + 1];
        }
        // allApprovedAdmins[index] = allApprovedAdmins[allApprovedAdmins.length.sub(1];
        pendingRemoveAdminKeys.pop();
    }
    /**
     * @dev makes _admin a pendsing adnmin for approval to be given by
     * all current admins for removing this admnin.
     * @param _admin Address of the new admin
     */
    function _makePendingForRemove(address _admin) internal {
        //the admin who is adding the new admin is approving _newAdmin by default
        removedByAdmins[_admin].push(msg.sender);
        pendingRemoveAdminKeys.push(_admin);
        //add _newAdmin to pendingAddedAdminRoles for approval  by all other current.
        pendingRemovedAdminRoles[_admin] = approvedAdminRoles[_admin];

        emit RemoveAdminForApprove(_admin, msg.sender);
    }

    /**
     * @dev makes _admin a pendsing adnmin for approval to be given by
     * all current admins for editing this admnin.
     * @param _admin Address of the new admin.
     * @param _newAccess Address of the new admin.
     */
    function _makePendingForEdit(address _admin, AdminAccess memory _newAccess) internal {
        //the admin who is adding the new admin is approving _newAdmin by default
        editedByAdmins[_admin].push(msg.sender);
        pendingEditAdminKeys.push(_admin);
        //add _newAdmin to pendingAddedAdminRoles for approval  by all other current.
        pendingEditAdminRoles[_admin] = _newAccess;

        emit EditAdminApproved(_admin, msg.sender);
    }

    function _removeKey(address _valueToFindAndRemove, address[] memory from) 
        internal
        pure
        returns(address [] memory) 
    {
        address[] memory auxArray;
        for (uint256 i = 0; i < from.length; i++) {
            if (from[i] != _valueToFindAndRemove) {
                auxArray[i] = from[i];
            }
        }
        from = auxArray;
        return from;
    }

    function _getIndex(address _valueToFindAndRemove, address [] memory from)
        internal
        pure
        returns (uint256 index)
    {
        for (uint256 i = 0; i < from.length; i++) {
            if (from[i] == _valueToFindAndRemove) {
                return i;
            }
        }
    }

    function _addressExists(address _valueToFind, address [] memory from)
        internal
        pure
        returns (bool)
    {
        for (uint256 i = 0; i < from.length; i++) {
            if (from[i] == _valueToFind) {
                return true;
            }
        }
        return false;
    }

    function isAddGovAdminRole(address admin)external view override returns (bool) {
        return approvedAdminRoles[admin].addGovAdmin;
    }

    //using this function externally in Gov Tier Level Smart Contract
    function isEditAdminAccessGranted(address admin) external override view returns (bool) {
        if (approvedAdminRoles[admin].editGovAdmin == true) return true;

        return false;
    }

    //using this function externally in other Smart Contracts
    function isAddTokenRole(address admin) external view override returns (bool) {
        return approvedAdminRoles[admin].addToken;
    }

    //using this function externally in other Smart Contracts
    function isEditTokenRole(address admin) external view override returns (bool) {
        return approvedAdminRoles[admin].editToken;
    }

    //using this function externally in other Smart Contracts
    function isAddSpAccess(address admin) external view override returns (bool) {
             return approvedAdminRoles[admin].addSp;

    }

    //using this function externally in other Smart Contracts
    function isEditSpAccess(address admin) external view override returns(bool) {
       return approvedAdminRoles[admin].editSp;
    }

    //using this function externally in other smart contracts
    function isEditAPYPerAccess(address admin) external view override returns(bool) {
        return approvedAdminRoles[admin].addGovAdmin;
    }

    //using this function in loan smart contracts to withdraw network balance
    function isSuperAdminAccess(address admin) external view override returns(bool) {
        return approvedAdminRoles[admin].superAdmin;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface IGovWorldAdminRegistry {
    struct AdminAccess {
        //access-modifier variables to add projects to gov-intel
        bool addGovIntel;
        bool editGovIntel;
        //access-modifier variables to add tokens to gov-world protocol
        bool addToken;
        bool editToken;
        //access-modifier variables to add strategic partners to gov-world protocol
        bool addSp;
        bool editSp;
        //access-modifier variables to add gov-world admins to gov-world protocol
        bool addGovAdmin;
        bool editGovAdmin;
        //access-modifier variables to add bridges to gov-world protocol
        bool addBridge;
        bool editBridge;
        //access-modifier variables to add pools to gov-world protocol
        bool addPool;
        bool editPool;

        //superAdmin role assigned only by the super admin
        bool superAdmin;
    }

    event NewAdminApproved(address indexed _newAdmin, address indexed _addByAdmin);
    event NewAdminApprovedByAll(address indexed _newAdmin, AdminAccess _adminAccess);
    event RemoveAdminForApprove(address indexed _admin, address indexed _removedByAdmin);
    event AdminRemovedByAll(address indexed _admin, address indexed _removedByAdmin);
    event EditAdminApproved(address indexed _admin,address indexed _editedByAdmin);
    event AdminEditedApprovedByAll(address indexed _admin, AdminAccess _adminAccess);
    event AddAdminRejected(address indexed _newAdmin, address indexed _rejectByAdmin);
    event EditAdminRejected(address indexed _newAdmin, address indexed _rejectByAdmin);
    event RemoveAdminRejected(address indexed _newAdmin, address indexed _rejectByAdmin);
    event SuperAdminOwnershipTransfer(address indexed _superAdmin, AdminAccess _adminAccess);
    
    function isAddGovAdminRole(address admin)external view returns (bool);

    //using this function externally in Gov Tier Level Smart Contract
    function isEditAdminAccessGranted(address admin) external view returns (bool);

    //using this function externally in other Smart Contracts
    function isAddTokenRole(address admin) external view returns (bool);

    //using this function externally in other Smart Contracts
    function isEditTokenRole(address admin) external view returns (bool);

    //using this function externally in other Smart Contracts
    function isAddSpAccess(address admin) external view returns (bool);

    //using this function externally in other Smart Contracts
    function isEditSpAccess(address admin) external view returns (bool);

    //using this function externally in other Smart Contracts
    function isEditAPYPerAccess(address admin) external view returns (bool);

     //using this function in loan smart contracts to withdraw network balance
    function isSuperAdminAccess(address admin) external view returns(bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}