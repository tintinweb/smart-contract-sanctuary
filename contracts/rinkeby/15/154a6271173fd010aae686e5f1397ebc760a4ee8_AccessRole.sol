pragma solidity >=0.4.25 <0.7.0;

// import "github/OpenZeppelin/openzeppelin-contracts/contracts/access/Roles.sol";
// import "@openzeppelin/contracts/access/Roles.sol";
import "./Roles.sol";

contract AccessRole {
     using Roles for Roles.Role;
     
     Roles.Role private _uploader;
     Roles.Role private _doctor;
     
     string private image_description;
     
     // Constructor to make a list of accounts that has role uploader and doctor
     // Role "doctor" can only read data but can add a new one
     // Role "uploader" can only write data but can't read it
     constructor(address[] memory uploader, address[] memory doctor, string memory _image_description) 
     public
     {
         image_description = _image_description;
         for(uint256 i = 0; i < uploader.length; ++i) {
             _uploader.add(uploader[i]);
         }
         for(uint256 i = 0; i < doctor.length; ++i) {
             _doctor.add(doctor[i]);
         }
        //  _uploader.add(uploader);
        //  _doctor.add(doctor);
     }
     
     // This function is to make a new data, it can only be performed by "Uploader" account
     function upload(string memory desc) public returns (string memory) {
        require(_uploader.has(msg.sender), "It is not an uploader");
        image_description = desc;
        return "image_description successfully updated";
     }
     
     // This function is to read data, it can only be performed by "Doctor" account
     function getDescription() public view returns (string memory) {
         require(_doctor.has(msg.sender), "It is not a doctor");
         return image_description;
     }
     
}