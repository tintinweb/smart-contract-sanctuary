/**
 *Submitted for verification at Etherscan.io on 2022-01-07
*/

// SPDX-Licence-Identifier: MIT
pragma solidity >=0.6.6 <0.9.0;

contract BloodDonor{
    struct Donor{
        string d_name;
        string d_id;
        string d_email;
        string d_aadhar_no;
        string d_pwd;
        string d_dob;
        string d_blood_type;
    }
    Donor[] public donors;
    mapping(string=>uint256) public index_to_donor;
    function badd(string memory d_name, string memory d_id, string memory d_email, string memory d_aadhar_no, string memory d_pwd, string memory d_blood_type, string memory d_dob) public {
        donors.push(Donor({d_name:d_name,d_id:d_id,d_email:d_email,d_aadhar_no:d_aadhar_no,d_pwd:d_pwd,d_blood_type:d_blood_type,d_dob:d_dob}));
        uint256 l = donors.length-1;
        index_to_donor[d_id] = l;
    }
    function blogin(string memory d_id, string memory d_pwd) public view returns(string memory, string memory, string memory, string memory, string memory){
        uint256 index = index_to_donor[d_id];
        if (keccak256(abi.encodePacked(donors[index].d_pwd)) == keccak256(abi.encodePacked(d_pwd))){
            Donor memory b = donors[index] ; 
            return (b.d_name, b.d_email, b.d_aadhar_no, b.d_blood_type, b.d_dob) ;
        }
        return ("None","None","None","None","None");
    }
}