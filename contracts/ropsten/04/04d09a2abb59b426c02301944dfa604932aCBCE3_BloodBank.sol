/**
 *Submitted for verification at Etherscan.io on 2022-01-07
*/

// SPDX-Licence-Identifier: MIT
pragma solidity ^0.8.0;
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
contract BloodBank {
    struct Bank{
        string bb_name;
        string bb_id;
        string bb_email;
        string bb_licence_no;
        string bb_pwd;
        string bb_address;
    }
    Bank[] public bank;
    BloodDonor[] public DonorContractArray;
    mapping(string=>address) public bbid_to_donors;
    mapping(string=>uint256) public index_to_bank;
    function add(string memory bb_name, string memory bb_id, string memory bb_email,
                 string memory bb_licence_no, string memory bb_pwd,
                 string memory bb_address) public {
        bank.push(Bank({bb_name:bb_name,bb_id:bb_id,bb_email:bb_email,bb_licence_no:bb_licence_no,bb_pwd:bb_pwd,bb_address:bb_address}));
        uint256 l = bank.length-1;
        index_to_bank[bb_id] = l;
    }
    function login(string memory bb_id, string memory bb_pwd) public view
    returns(string memory, string memory, string memory, string memory ){
        uint256 index = index_to_bank[bb_id];
        if (keccak256(abi.encodePacked(bank[index].bb_pwd)) == keccak256(abi.encodePacked(bb_pwd))){
            Bank memory b = bank[index] ;
            return (b.bb_name, b.bb_email, b.bb_licence_no, b.bb_address) ;
        }
        return ("None","None","None","None");
    }
    function register_donor(string memory d_name, string memory d_id, string memory d_email,
                            string memory d_aadhar_no, string memory d_pwd,
                            string memory d_blood_type, string memory d_dob, string memory bb_id) public {

        if (bbid_to_donors[bb_id] == 0x0000000000000000000000000000000000000000){
            address contract_address = create_donor_contract_for_bank();
            bbid_to_donors[bb_id] = contract_address;
        }
        BloodDonor b = BloodDonor(bbid_to_donors[bb_id]);
        b.badd( d_name,  d_id,  d_email,  d_aadhar_no,  d_pwd,  d_blood_type, d_dob);
    }
    function donor_login(string memory d_id, string memory d_pwd, string memory bb_id) public view returns (string memory, string memory, string memory, string memory, string memory){
        if (bbid_to_donors[bb_id] == 0x0000000000000000000000000000000000000000){
            return ("None","None","None","None","None");
        }
        BloodDonor b = BloodDonor(bbid_to_donors[bb_id]);
        return b.blogin(d_id,d_pwd);
    }
    function create_donor_contract_for_bank() public returns(address){
        BloodDonor bDonor = new BloodDonor();
        DonorContractArray.push(bDonor);
        return address(bDonor);
    }
    function bank_values_view(string memory bb_id) public view returns(string memory,string memory,string memory,string memory){
        uint256 index = index_to_bank[bb_id];
        Bank memory b = bank[index] ;
        return (b.bb_name, b.bb_email, b.bb_licence_no, b.bb_address) ;
    }

}