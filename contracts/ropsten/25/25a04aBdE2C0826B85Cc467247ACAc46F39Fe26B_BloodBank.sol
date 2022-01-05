/**
 *Submitted for verification at Etherscan.io on 2022-01-05
*/

// SPDX-Licence-Identifier: MIT
pragma solidity ^0.8.0;

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
    mapping(string=>uint256) public index_to_bank;
    function add(string memory bb_name, string memory bb_id, string memory bb_email, string memory bb_licence_no, string memory bb_pwd, string memory bb_address) public {
        bank.push(Bank({bb_name:bb_name,bb_id:bb_id,bb_email:bb_email,bb_licence_no:bb_licence_no,bb_pwd:bb_pwd,bb_address:bb_address}));
        uint256 l = bank.length-1;
        index_to_bank[bb_id] = l;
    }
    function login(string memory bb_id, string memory bb_pwd) public view returns(string memory, string memory, string memory, string memory ){
        uint256 index = index_to_bank[bb_id];
        if (keccak256(abi.encodePacked(bank[index].bb_pwd)) == keccak256(abi.encodePacked(bb_pwd))){
            Bank memory b = bank[index] ;
            return (b.bb_name, b.bb_email, b.bb_licence_no, b.bb_address) ;
        }
        return ("None","None","None","None");
    }

}