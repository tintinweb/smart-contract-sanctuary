/**
 *Submitted for verification at Etherscan.io on 2021-09-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VaccineData {
    mapping(uint256 => vaccine_data) vaccines_detail_list;
    uint256 current_id = 0;
    struct vaccine_data{
        uint256 id;
        string metadata_uri;
    }

    function add_vaccine_data(string memory uri) external {
        
        current_id = current_id + 1;
        vaccines_detail_list[current_id] = vaccine_data(current_id, uri);
     
    }

    function get_vaccine_data(uint256 id) public view returns (vaccine_data memory) {
        return vaccines_detail_list[id];
    }
    
    function get_current_id() external view returns(uint256){
        return current_id;
    }
    
    function get_next_id() external view returns(uint256){
        return current_id + 1;
    }
}