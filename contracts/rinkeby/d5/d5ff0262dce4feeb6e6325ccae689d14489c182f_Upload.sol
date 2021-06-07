/**
 *Submitted for verification at Etherscan.io on 2021-06-07
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.25 <0.7.0;


contract Upload{
    
    struct image {
        string id;
        string nama;
        string deskripsi;
        string imgHash;
    }
 
    mapping(string => image) public imageMap;

     function set(
         string calldata _id,
         string calldata _nama,
         string calldata _deskripsi,
         string calldata _imgHash
         ) public {
            imageMap[_id] = image(_id, _nama, _deskripsi, _imgHash);
     }
    
     function get(string calldata _id) 
     public view returns(
         string memory,
         string memory,
         string memory
         ) {
        image memory imgEntry = imageMap[_id];
        return (imgEntry.nama, imgEntry.deskripsi, imgEntry.imgHash);
    }
}