// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.25 <0.7.0;

import "./Roles.sol";

/** 
 * @title AccessRole
 * @dev Implements role checking and administration to allow a certain task to users with required role
 */
contract AccessRole {
     using Roles for Roles.Role;
     
     Roles.Role private _uploaderRole;
     Roles.Role private _doctorRole;
     
     address private roleMaker;
     
     /** 
     * @dev Create a new list of access role and assign the deployer user as the role maker
     */
     constructor() public {
         roleMaker = msg.sender;
     }
     
     /** 
     * @dev Allow the role maker to give the role of uploader (permission to upload) to the specific address of user.
     * @param uploader  the address of the user to be added as uploader
     */
     function addUploader (address uploader) public {
         require(
             msg.sender == roleMaker,
             "Only contract owner/rolemaker can add uploader."
             );
        _uploaderRole.add(uploader);
     }
     
     /** 
     * @dev Allow the role maker to give the role of doctor (permission to see data) to the specific address of user.
     * @param doctor    the address of the user to be added as doctor
     */
     function addDoctor (address doctor) public {
         require(
             msg.sender == roleMaker,
             "Only contract owner/rolemaker can add doctor."
             );
        _doctorRole.add(doctor);
     }
     
     /** 
     * @dev Checking whether or not the address of sender is Uploader.
     * @return bool logical statement of user's validity for the uploader role.
     */
     function checkUploaderRole() public view returns (bool) {
         require(_uploaderRole.has(msg.sender));
         return true;
     }
     
     /** 
     * @dev Checking whether or not the address of sender is Doctor.
     * @return bool logical statement of user's validity for the doctor role.
     */
     function checkDoctorRole() public view returns (bool) {
         require(_doctorRole.has(msg.sender));
         return true;
     }
     
}