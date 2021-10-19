/**
 *Submitted for verification at Etherscan.io on 2021-10-19
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;

contract Certification {
    
    struct Certificate {
        string _candidate_name;
        string _org_name;
        string _course_name;
        string _ipfs_hash;
    }
    
    string ipfs_hash;
    
    mapping(string => Certificate) public certificates;
    mapping(string => bool) public ipfsHash;
    
    
    function generateCertificate(
        string memory _id,
        string memory _candidate_name,
        string memory _org_name,
        string memory _course_name,
        string memory _ipfs_hash 
    ) public {
        certificates[_id] = Certificate(
            _candidate_name,
            _org_name,
            _course_name,
            _ipfs_hash
            );
        ipfsHash[_ipfs_hash] = true;
        ipfs_hash = _ipfs_hash;
        //emit certificateGenerated(_id, _ipfs_hash);
    }
    
    function isVerified(string memory _id) public view returns (bool) {
        if (ipfsHash[_id]) {
            return true;
        }
        return false;
    }
    
    function getHash() public view returns (string memory) {
        return ipfs_hash;
    }

}