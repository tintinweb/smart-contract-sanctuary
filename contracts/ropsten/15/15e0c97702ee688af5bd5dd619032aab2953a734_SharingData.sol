/**
 *Submitted for verification at Etherscan.io on 2021-09-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.16 <0.9.0;
pragma experimental ABIEncoderV2;

/** 
 * @title Ballot
 * @dev Implements voting process along with vote delegation
 */
contract SharingData {
   
    struct User {
        string codeid;
        string publickey;
        string eth_address;
    }
    
    struct SharingFile {
        string hash;
        string from_id;
        string to_id;
        string timestamp;
        string filename;
        string keyword;
        string keyAES;
        
        
    }
    User[] public users;
    SharingFile[] public sharingfiles;
    
    uint public id_ketiep;
    
    function create_new_users(string memory codeid, string memory publickey, string memory eth_address) public {
        users.push(User( codeid, publickey, eth_address));
    }
    function get_all_user() view public returns(string[] memory, string[] memory, string[] memory){
       // return (users.codeid, users.publickey, users.eth_address);
        
        uint n = get_count_user();
        string [] memory codeid_arr = new string[](n);
        string [] memory publickey_arr = new string[](n);
        string [] memory eth_address_arr = new string[](n);
        for(uint i =0; i< users.length; i++)
        {
               codeid_arr[i] = string(users[i].codeid);
               publickey_arr[i] = string(users[i].publickey);
               eth_address_arr[i]= string(users[i].eth_address);
        }
        return (codeid_arr, publickey_arr, eth_address_arr);
    }
    function find(string memory codeid) view internal returns(uint) {
        for(uint i = 0; i < users.length; i++) {
            if(keccak256(bytes(users[i].codeid)) == keccak256(bytes(codeid))) {
                return i;
                
               /// keccak256(bytes(a)) == keccak256(bytes(b));
            }
        }
        revert('User does not exits');
    }
    function share_file(string memory hash, string memory  from_id, string memory  to_id, string memory timestamp, string memory filename, string memory keyword, string memory keyAES) public {
        sharingfiles.push(SharingFile(hash,from_id,to_id,timestamp,filename,keyword,keyAES));
    }
    function get_count_hash(string memory to_id) view internal returns(uint) {
        uint  tmp;
        for(uint i =0; i< sharingfiles.length; i++)
        {
            if(keccak256(bytes(sharingfiles[i].to_id)) == keccak256(bytes(to_id)))
            {
                ++tmp;

            }
        }
        return tmp;
    }
    function get_count_user() view internal returns(uint) {
        uint  tmp;
        for(uint i =0; i< users.length; i++)
        {
            ++tmp;
        }
        return tmp;
    }
     function get_list_fileshare(string calldata to_id) view external returns(string[] memory, string[] memory, string[] memory )  {
        uint n = get_count_hash(to_id);
        string [] memory hash_arr = new string[](n);
        string [] memory filename_arr = new string[](n);
        string [] memory keyAES_arr  = new string[](n);
      
        for(uint i =0; i< sharingfiles.length; i++)
        {
            if(keccak256(bytes(sharingfiles[i].to_id)) == keccak256(bytes(to_id)))
            {
               hash_arr[i] = string(sharingfiles[i].hash);
               filename_arr[i] = string(sharingfiles[i].filename);
               keyAES_arr[i] = string(sharingfiles[i].keyAES);
            }
        }
        return (hash_arr, filename_arr, keyAES_arr);
        
    }


}