/**
 *Submitted for verification at Etherscan.io on 2022-01-07
*/

// SPDX-Licence-Identifier: MIT
pragma solidity ^0.8.0;

contract Hospitals{
    struct Hospital{
        string h_name;
        string h_id;
        string h_email;
        string h_licence_no;
        string h_pwd;
        string h_address;
    }
    Hospital[] public hospitals;
    mapping(string=>uint256) public index_to_hospital;
    function add(string memory h_name, string memory h_id, string memory h_email, string memory h_licence_no, string memory h_pwd, string memory h_address) public {
        hospitals.push(Hospital({h_name:h_name,h_id:h_id,h_email:h_email,h_licence_no:h_licence_no,h_pwd:h_pwd,h_address:h_address}));
        uint256 l = hospitals.length-1;
        index_to_hospital[h_id] = l;
    }
    function login(string memory h_id, string memory h_pwd) public view returns(string memory, string memory, string memory, string memory ){
        uint256 index = index_to_hospital[h_id];
        if (keccak256(abi.encodePacked(hospitals[index].h_pwd)) == keccak256(abi.encodePacked(h_pwd))){
            Hospital memory b = hospitals[index] ;
            return (b.h_name, b.h_email, b.h_licence_no, b.h_address) ;
        }
        return ("None","None","None","None");
    }
}