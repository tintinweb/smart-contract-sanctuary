/**
 *Submitted for verification at Etherscan.io on 2021-07-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.16 <0.9.0;

/** 
 * @title Ballot
 * @dev Implements voting process along with vote delegation
 */
contract SharingData {
   
    struct User {
        uint id;
        string nickname;
        string publickey;
        string eth_address;
    }
    
    struct SharingFile {
        string hash;
        uint from_id;
        uint to_id;
        string timestamp;
        
        
    }
    User[] public users;
    SharingFile[] public sharingfiles;
    uint public id_ketiep;
    
    function create_new_users(string memory nickname, string memory publickey, string memory eth_address) public {
        users.push(User(id_ketiep, nickname, publickey, eth_address));
        ++id_ketiep;
    }
    function get_user(string memory nickname) view public returns(uint, string memory, string memory, string memory){
        uint index = find(nickname);
        return (users[index].id,users[index].nickname, users[index].publickey,users[index].eth_address);
    }
    function update_user(uint id, string memory nickname) public {
        uint index = find_id(id);
        users[index].nickname = nickname;
    }
    
    function delete_user(uint id) public {
        uint index = find_id(id);
        delete users[index];
    }
    function find(string memory nickname) view internal returns(uint) {
        for(uint i = 0; i < users.length; i++) {
            if(keccak256(bytes(users[i].nickname)) == keccak256(bytes(nickname))) {
                return i;
                
               /// keccak256(bytes(a)) == keccak256(bytes(b));
            }
        }
        revert('User does not exits');
    }
    function find_id(uint id) view internal returns(uint) {
        for(uint i = 0; i < users.length; i++) {
            if(users[i].id == id) {
                return i;
            }
        }
        revert('User does not exits');
    }
    function share_file(string memory hash, uint  from_id, uint  to_id, string memory timestamp) public {
        sharingfiles.push(SharingFile(hash,from_id,to_id,timestamp));
    }

}