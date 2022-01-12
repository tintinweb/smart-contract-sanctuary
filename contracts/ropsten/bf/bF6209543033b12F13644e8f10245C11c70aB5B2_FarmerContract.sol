/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract FarmerContract {

  address constant NULL = address(0);

    struct Farmer {
        uint farmer_id;
        address farmer_wallet_address;
        string farmer_land_id;
        string name;
        string phone_no;
        string aggriculture_land_no;
    }

    Farmer []farmers;

    function create_account (
        uint farmer_id, string memory farmer_land_id, string memory name,
        string memory phone_no,
        string memory aggriculture_land_no ) public {
            Farmer memory e = Farmer(
                farmer_id,
                msg.sender,
                farmer_land_id,
                name,
                phone_no,
                aggriculture_land_no
            );
        farmers.push(e);
    }

    function get_farmer(uint farmerid) public view returns (
        string memory,
        address,
        string memory,
        string memory,
        string memory){
        uint i;
        
        for(i=0;i<farmers.length;i++) {
            Farmer memory e = farmers[i];
            if (e.farmer_id==farmerid) {
                return(e.farmer_land_id,
                    e.farmer_wallet_address,
                    e.name,
                    e.phone_no,
                    e.aggriculture_land_no
                );
            }
        }
        
        return("Not Found",
            NULL,
            "Not Found",
            "Not Found",
            "Not Found"
        );
    }
}