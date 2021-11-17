// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.0;

import "./GovWorldAdminRegistry.sol";
import "./admininterfaces/IGovWorldTierLevel.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract GovWorldTierLevel is IGovWorldTierLevel {
    using SafeMath for uint256;

    //list of new tier levels
    mapping(bytes32 => TierData) public tierLevels;

    //list of all added tier levels. Stores the key for mapping => tierLevels
    bytes32[] allTierLevelKeys;

    GovWorldAdminRegistry govAdminRegistry;
    address private govToken;
    address private govGovToken;

    constructor(
        address _govAdminRegistry,
        address _govTokenAddress,
        bytes32 _bronze,
        bytes32 _silver,
        bytes32 _gold,
        bytes32 _platinum,
        bytes32 _allStar
    ) {
        govAdminRegistry = GovWorldAdminRegistry(_govAdminRegistry);
        govToken = _govTokenAddress;

        _addTierLevel(
            _bronze,
            TierData(
                15000e18,
                30,
                false,
                false,
                true,
                false,
                true,
                false,
                false,
                false
            )
        );
        _addTierLevel(
            _silver,
            TierData(
                30000e18,
                40,
                false,
                false,
                true,
                true,
                true,
                false,
                false,
                false
            )
        );
        _addTierLevel(
            _gold,
            TierData(
                75000e18,
                50,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true
            )
        );
        _addTierLevel(
            _platinum,
            TierData(
                150000e18,
                70,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true
            )
        );
        _addTierLevel(
            _allStar,
            TierData(
                300000e18,
                70,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true
            )
        );
    }

    modifier onlyEditTierLevelRole(address admin) {
        require(
            govAdminRegistry.isEditAdminAccessGranted(admin),
            "GTL: No admin right to add or remove tier level."
        );
        _;
    }

    //external functions

    /**
    @dev external function to add new tier level (keys with their access values)
    @param _newTierLevel must be a new tier key in bytes32
    @param _tierData access variables of the each Tier Level
     */
    function addTierLevel(bytes32 _newTierLevel, TierData memory _tierData)
        external
        override
        onlyEditTierLevelRole(msg.sender)
    {
        //admin have not already added new tier level
        require(
            !_isAlreadyTierLevel(_newTierLevel),
            "GTL: already added tier level"
        );
        require(
            _tierData.govHoldings >
                tierLevels[allTierLevelKeys[maxGovTierLevel()]].govHoldings,
            "GovHolding Should be greater then last tier level Gov Holdings"
        );
        //adding tier level called by the admin
        _addTierLevel(_newTierLevel, _tierData);
    }

    /**
    @dev external function to update the existing tier level, also check if it is already added or not
    @param _updatedTierLevelKey existing tierlevel key
    @param _newTierData new data for the updateding Tier level
     */
    function updateTierLevel(
        bytes32 _updatedTierLevelKey,
        TierData memory _newTierData
    ) external override onlyEditTierLevelRole(msg.sender) {
        require(
            _isAlreadyTierLevel(_updatedTierLevelKey),
            "GovWorldTier: cannot update Tier, create new tier first"
        );
        _updateTierLevel(_updatedTierLevelKey, _newTierData);
    }

    /**
    @dev remove tier level key as well as from mapping
    @param _existingTierLevel tierlevel hash in bytes32
     */
    function removeTierLevel(bytes32 _existingTierLevel)
        external
        override
        onlyEditTierLevelRole(msg.sender)
    {
        require(
            _isAlreadyTierLevel(_existingTierLevel),
            "GovWorldTier: cannot remove, Tier Level not exist"
        );
        delete tierLevels[_existingTierLevel];
        emit TierLevelRemoved(_existingTierLevel);
        
        _removeTierLevelKey(_getIndex(_existingTierLevel));
    }

    /**
    @dev this function add new tier level if not exist and update tier level if already exist.
     */
    function saveTierLevel(
        bytes32[] memory _tierLevelKeys,
        TierData[] memory _newTierData
    ) external override onlyEditTierLevelRole(msg.sender) {
        require(
            _tierLevelKeys.length == _newTierData.length,
            "New Tier Keys and TierData length must be equal"
        );
        _saveTierLevel(_tierLevelKeys, _newTierData);
    }

    //public functions

    /**
     * @dev get all the Tier Level Keys from the allTierLevelKeys array
     */
    function getAllTierLevels() public view returns (bytes32[] memory) {
        return allTierLevelKeys;
    }

    /**
     * @dev get Single Tier Level Data
     */
    function getSingleTierData(bytes32 _tierLevelKey)
        public
        view
        returns (TierData memory)
    {
        return tierLevels[_tierLevelKey];
    }

    //internal functions

    /**
     * @dev makes _new a pendsing adnmin for approval to be given by all current admins
     * @param _newTierLevel value type of the New Tier Level in bytes
     * @param _tierData access variables for _newadmin
     */

    function _addTierLevel(bytes32 _newTierLevel, TierData memory _tierData)
        internal
    {
        //new Tier is added to the mapping tierLevels
        tierLevels[_newTierLevel] = _tierData;

        //new Tier Key for mapping tierLevel
        allTierLevelKeys.push(_newTierLevel);
        emit TierLevelAdded(_newTierLevel, _tierData);
    }

    /**
     * @dev Checks if a given _newTierLevel is already added by the admin.
     * @param _newTierLevel value of the new tier
     */
    function _isAlreadyTierLevel(bytes32 _newTierLevel)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < allTierLevelKeys.length; i++) {
            if (allTierLevelKeys[i] == _newTierLevel) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev update already created tier level
     * @param _updatedTierLevelKey key value type of the already created Tier Level in bytes
     * @param _newTierData access variables for updating the Tier Level
     */

    function _updateTierLevel(
        bytes32 _updatedTierLevelKey,
        TierData memory _newTierData
    ) internal {
        //update Tier Level to the updatedTier
        uint256 currentIndex = _getIndex(_updatedTierLevelKey);
        uint256 lowerLimit = 0;
        uint256 upperLimit = _newTierData.govHoldings.add(10);
        if (currentIndex > 0) {
            lowerLimit = tierLevels[allTierLevelKeys[currentIndex.sub(1)]]
                .govHoldings;
        }
        if (currentIndex < allTierLevelKeys.length.sub(1))
            upperLimit = tierLevels[allTierLevelKeys[currentIndex + 1]]
                .govHoldings;

        require(
            _newTierData.govHoldings < upperLimit &&
                _newTierData.govHoldings > lowerLimit,
            "Gov Holding Should be in range of previous and next tier level"
        );

        tierLevels[_updatedTierLevelKey] = _newTierData;
        emit TierLevelUpdated(_updatedTierLevelKey, _newTierData);
    }

    /**
     * @dev remove tier level
     * @param index already existing tierlevel index
     */
    function _removeTierLevelKey(uint256 index) internal {
        if (allTierLevelKeys.length != 1) {
            for (uint256 i = index; i < allTierLevelKeys.length.sub(1); i++) {
                allTierLevelKeys[i] = allTierLevelKeys[i + 1];
            }
        }
        allTierLevelKeys.pop();

    }

    /**
    @dev internal function for the save tier level, which will update and add tier level at a time
     */
    function _saveTierLevel(
        bytes32[] memory _tierLevelKeys,
        TierData[] memory _newTierData
    ) internal {
        for (uint256 i = 0; i < _tierLevelKeys.length; i++) {
            if (!_isAlreadyTierLevel(_tierLevelKeys[i])) {
                _addTierLevel(_tierLevelKeys[i], _newTierData[i]);
            } else if (_isAlreadyTierLevel(_tierLevelKeys[i])) {
                _updateTierLevel(_tierLevelKeys[i], _newTierData[i]);
            }
        }
    }

    /**
    @dev this function returns the index of the maximum govholding tier level
     */
    function maxGovTierLevel() public view returns (uint256) {
        uint256 max = tierLevels[allTierLevelKeys[0]].govHoldings;
        uint256 maxIndex = 0;

        for (uint256 i = 0; i < allTierLevelKeys.length; i++) {
            if (tierLevels[allTierLevelKeys[i]].govHoldings > max) {
                maxIndex = i;
                max = tierLevels[allTierLevelKeys[i]].govHoldings;
            }
        }

        return maxIndex;
    }

    /**
    @dev get index of the tierLevel from the allTierLevel array
    @param _tierLevel hash of the tier level
     */
    function _getIndex(bytes32 _tierLevel)
        internal
        view
        returns (uint256 index)
    {
        for (uint256 i = 0; i < allTierLevelKeys.length; i++) {
            if (allTierLevelKeys[i] == _tierLevel) {
                return i;
            }
        }
    }

    /**
    @dev this function returns the tierLevel data by user's Gov Token Balance
    @param userWalletAddress user address for check tier level data
     */
    function getTierDatabyGovBalance(address userWalletAddress)
        public
        override
        view
        returns (TierData memory _tierData)
    {
        //govToken.transfer(recipient, amount);
        uint256 userGovBalance = IERC20(govToken).balanceOf(userWalletAddress);
        require(
            userGovBalance >= 15000e18,
            "User Balance is too low, Not Eligible for any Tier Level"
        );
        for (uint256 i = 1; i < allTierLevelKeys.length; i++) {
            if (
                (userGovBalance >=
                    tierLevels[allTierLevelKeys[i.sub(1)]].govHoldings) &&
                (userGovBalance < tierLevels[allTierLevelKeys[i]].govHoldings)
            ) {
                return tierLevels[allTierLevelKeys[i.sub(1)]];
            } else if (
                userGovBalance >=
                tierLevels[allTierLevelKeys[allTierLevelKeys.length .sub(1)]]
                    .govHoldings
            ) {
                return
                    tierLevels[allTierLevelKeys[allTierLevelKeys.length.sub(1)]];
            }
        }
    }

    /**
    @dev this function returns the tierLevel Name by user's Gov Token Balance
    @param userWalletAddress user address for check tier level name
     */
    function getTierNamebyGovToken(address userWalletAddress)
        public
        view
        returns (bytes32 tierLevel)
    {
        //govToken.transfer(recipient, amount);
        uint256 userGovBalance = IERC20(govToken).balanceOf(userWalletAddress)+IERC20(govGovToken).balanceOf(userWalletAddress);

        require(
            userGovBalance >= 15000e18,
            "GTL: User Balance is too low, Not Eligible for any Tier Level"
        );
        for (uint256 i = 1; i < allTierLevelKeys.length; i++) {
            if (
                (userGovBalance >=
                    tierLevels[allTierLevelKeys[i.sub(1)]].govHoldings) &&
                (userGovBalance < tierLevels[allTierLevelKeys[i]].govHoldings)
            ) {
                return allTierLevelKeys[i.sub(1)];
            } else if (
                userGovBalance >=
                tierLevels[allTierLevelKeys[allTierLevelKeys.length.sub(1)]]
                    .govHoldings
            ) {
                return allTierLevelKeys[allTierLevelKeys.length.sub(1)];
            }
        }
    }



    function stringToBytes32(string memory _string)
        public
        pure
        returns (bytes32 result)
    {
        bytes memory tempEmptyStringTest = bytes(_string);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(_string, 32))
        }
    }

    // set govGovToken address, only superadmin
    function configuregovGovToken(address _govGovTokenAddress) external {
        require(govAdminRegistry.isSuperAdminAccess(msg.sender), "GTL: Invalid Access");
        require(_govGovTokenAddress != address(0), 'GTL: Invalid Contract Address!');
        require(govGovToken == address(0), 'GTL: Contract Alredy Configured!');

        govGovToken = _govGovTokenAddress;
    }
}

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
        require(_adminAccess.addGovIntel == true || _adminAccess.editGovIntel ==true ||_adminAccess.addToken ==true || 
        _adminAccess.editToken ==true || _adminAccess.addSp ==true || _adminAccess.editSp ==true ||_adminAccess.addGovAdmin ==true || 
        _adminAccess.editGovAdmin ==true || _adminAccess.addBridge ==true || _adminAccess.editBridge ==true ||  _adminAccess.addPool ==true || _adminAccess.editPool ==true,  "GAR: admin right error");
        require(_newAdmin != address(0),'invalid address');        
        require(_newAdmin != msg.sender, "GAR: Cannot add himself again, you already an Admin");//the GovAdmin cannot add himself as admin again
        //the admin that is adding _newAdmin must not already have approved. 
        require(allApprovedAdmins.length > 0, "GAR: addDefaultAdmin as onwer first. ");
        require(_notApproved(_newAdmin, msg.sender), "GAR: Admin already approved this admin.");
        require(!_addressExists(_newAdmin, pendingAddedAdminKeys) ,"GAR: Admin already pending for remove approval" );
        require(!_addressExists(_newAdmin, allApprovedAdmins), "GAR: Cannot Add again other admins");
        require(_adminAccess.superAdmin == false, "GAR: cannot assign super admin role");

        if(allApprovedAdmins.length == 1) {
            //this admin is now approved just by one admin
         _makeDefaultApproved(_newAdmin, _adminAccess);   
        } else {
        //this admin is now in the pending list.
        _makePending(_newAdmin, _adminAccess);
       
        }
        performPendingActions();

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
        } else {
            //this admin is now in the pending list.
            _makePendingForRemove(_admin);
        }
        performPendingActions();
        
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
        } else {
            emit RemoveAdminForApprove(_admin, msg.sender);
        }
         performPendingActions();
    }
    
    function performPendingActions()
        internal        
    {
        for(uint256 i = 0 ; i < pendingAddedAdminKeys.length; i++)
        {
            if(this.isApprovedByAll(pendingAddedAdminKeys[i])){
                _makeApproved(pendingAddedAdminKeys[i], pendingAddedAdminRoles[pendingAddedAdminKeys[i]]);
                performPendingActions();
            }
        }
        for(uint256 i = 0 ; i < pendingEditAdminKeys.length; i++)
        {
            if(this.isEditedByAll(pendingEditAdminKeys[i])){
                _editAdmin(pendingEditAdminKeys[i]);
                performPendingActions();
            }
        }
        for(uint256 i = 0 ; i < pendingRemoveAdminKeys.length; i++)
        {
            if(this.isRemovedByAll(pendingRemoveAdminKeys[i])){
                _removeAdmin(pendingRemoveAdminKeys[i]);
                performPendingActions();
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
        require(_adminAccess.addGovIntel == true || _adminAccess.editGovIntel ==true ||_adminAccess.addToken ==true || 
        _adminAccess.editToken ==true || _adminAccess.addSp ==true || _adminAccess.editSp ==true ||_adminAccess.addGovAdmin ==true || 
        _adminAccess.editGovAdmin ==true || _adminAccess.addBridge ==true || _adminAccess.editBridge ==true ||  _adminAccess.addPool ==true || _adminAccess.editPool ==true, "GAR: admin right error");
        
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
        } else {
        //this admin is now in the pending list.
        _makePendingForEdit(_admin, _adminAccess);
        
        }
        performPendingActions();             
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

struct TierData {
        // Gov  Holdings to check if it lies in that tier
        uint256 govHoldings;
        // LTV percentage of the Gov Holdings
        uint8 loantoValue;
        //checks that if tier level have access
        bool govIntel;
        bool singleToken;
        bool multiToken;
        bool singleNFT;
        bool multiNFT;
        bool reverseLoan;
        bool _15PercentDiscount;
        bool _25PercentDiscount;
    }

interface IGovWorldTierLevel {
    
    event TierLevelAdded(bytes32 _newTierLevel, TierData _tierData);
    event TierLevelUpdated(bytes32 _updatetierLevel, TierData _tierData);
    event TierLevelRemoved(bytes32 _removedtierLevel);

    //external functions

    /**
    @dev external function to add new tier level (keys with their access values)
    @param _newTierLevel must be a new tier key in bytes32
    @param _tierData access variables of the each Tier Level
     */
    function addTierLevel(bytes32 _newTierLevel, TierData memory _tierData)
        external;

    /**
    @dev external function to update the existing tier level, also check if it is already added or not
    @param _updatedTierLevelKey existing tierlevel key
    @param _newTierData new data for the updateding Tier level
     */
    function updateTierLevel(
        bytes32 _updatedTierLevelKey,
        TierData memory _newTierData
    ) external;

    /**
    @dev remove tier level key as well as from mapping
    @param _existingTierLevel tierlevel hash in bytes32
     */
    function removeTierLevel(bytes32 _existingTierLevel) external;

    /**
    @dev it should add and save tier levels at once
     */
    function saveTierLevel(bytes32[] memory _tierLevelKeys, TierData[] memory _newTierData)
    external;

    function getTierDatabyGovBalance(address userWalletAddress) external view returns (TierData memory _tierData);
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
        delete editedByAdmins[_admin];
        delete  approvedByAdmins[_admin];
        
        delete pendingEditAdminRoles[_admin];
        delete pendingRemovedAdminRoles[_admin];

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