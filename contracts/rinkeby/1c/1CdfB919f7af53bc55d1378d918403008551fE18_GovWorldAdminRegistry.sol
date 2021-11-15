// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";


contract GovWorldAdminRegistry is Ownable{

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

    }

    //list of approved admins  with the access that they have
    mapping(address => AdminAccess) public approvedAdmins;

    //list of all approved admin addresses
    address [] allApprovedAdmins;

    //list of pending admins to be approved by approved admins
    mapping(address => AdminAccess) public pendingAdmins;

    //a list of admins approved by other admins. Stores the key for mapping approvedAdmins
    mapping (address => address[]) public approvedByAdmins;

    // access-modifier for adding gov admin 
    modifier onlyAddGovAdminRole (address _admin){
        require(approvedAdmins[_admin].addGovAdmin, "GAR: onlyAddGovAdminRole can add admin.");
        _;
    }

    // access-modifier for editing gov admin 
    modifier onlyEditGovAdminRole (address _admin){
        require(approvedAdmins[_admin].editGovAdmin, "GAR: OnlyEditGovAdminRole can edit or remove admin.");
        _;
    }


    event NewAdminApprovedByAll(address indexed _newAdmin);
    event NewAdminApproved(address indexed _newADmin, address indexed admin);
    
    /**
    * @dev Checks if a given _newAdmin is not approved by the _approvedBy admin.
    * @param _newAdmin Address of the new admin
    * @param _approvedBy Address of the existing admin that may have approved _newAdmin already.
    */
    function notApproved(address _newAdmin, address _approvedBy)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < approvedByAdmins[_newAdmin].length; i++) {
            if(approvedByAdmins[_newAdmin][i] == _approvedBy) {
                return false; //not not approved
            }
        }
        return true; //not approved
    }

    /**
    * @dev Checks if a given _newAdmin is approved by all other already approved amins
    * @param _newAdmin Address of the new admin
    */
    function isApprovedByAll(address _newAdmin)
        internal
        view
        returns (bool)
    {
        //following two loops check if all currenctly 
        //approvedAdmins are present in approvebyAdmins of the _newAdmin
        //loop all existing admins approvedBy array
        for (uint256 i = 0; i < approvedByAdmins[_newAdmin].length; i++) {
            bool isPresent = false;
            //Loop all currently approved admins.
            for (uint256 j = 0; j < allApprovedAdmins.length; j++) {
                //check
                if(approvedByAdmins[_newAdmin][i] == allApprovedAdmins[j]) {
                    isPresent = true;
                }
            }
            if(!isPresent)
                return false;
        }
        return true; 
    }


    function addAdmin(address _newAdmin, AdminAccess memory _adminAccess)
        external
        onlyAddGovAdminRole(msg.sender)
    {

        //the admin that is adding _newAdmin must not already have approved.
        require(notApproved(_newAdmin, msg.sender),"GAR: Admin already approved this admin. ");
        
        //the admin who is adding the new admin is approving _newAdmin by default
        approvedByAdmins[_newAdmin].push(msg.sender);


        //add _newAdmin to pendingAdmins for approval  by all other current.
        pendingAdmins[_newAdmin] = _adminAccess;
    }

    function approveAddedAdmin(address _newAdmin)
        external
        onlyAddGovAdminRole(msg.sender)
    {
        //the admin that is adding _newAdmin must not already have approved.
        require(notApproved(_newAdmin, msg.sender),"GAR: Admin already approved this admin. ");

        //if the _newAdmin is approved by all other admins
        if(isApprovedByAll(_newAdmin))
        {
            // _newAdmin is now an approved admin.
            approvedAdmins[_newAdmin] = pendingAdmins[_newAdmin];
            //new key for mapping approvedAdmins
            allApprovedAdmins.push(_newAdmin);

            emit NewAdminApprovedByAll(_newAdmin);
        }
        else{

            approvedByAdmins[_newAdmin].push(msg.sender);
            emit NewAdminApproved(_newAdmin, msg.sender);
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

