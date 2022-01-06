/**
 *Submitted for verification at Etherscan.io on 2022-01-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract FarmerContract {

    struct Farmer {
        int farmer_id;
        string farmer_land_id;
        string name;
        string phone_no;
        string aggriculture_land_no;
    }

    Farmer []farmers;

    function create_account (
        int farmer_id, string memory farmer_land_id, string memory name,
        string memory phone_no,
        string memory aggriculture_land_no ) public {
            Farmer memory e = Farmer(
                farmer_id,
                farmer_land_id,
                name,
                phone_no,
                aggriculture_land_no
            );
        farmers.push(e);
    }

    function get_farmer(int farmerid) public view returns (
        string memory,
        string memory,
        string memory,
        string memory){
        uint i;
        
        for(i=0;i<farmers.length;i++) {
            Farmer memory e = farmers[i];
            if (e.farmer_id==farmerid) {
                return(e.farmer_land_id,
                    e.name,
                    e.phone_no,
                    e.aggriculture_land_no
                );
            }
        }
        
        return("Not Found",
            "Not Found",
            "Not Found",
            "Not Found"
        );
    }
}