pragma solidity ^0.4.19;


library CampaignLibrary {

    struct Campaign {
        bytes32 bidId;
        uint price;
        uint budget;
        uint startDate;
        uint endDate;
        bool valid;
        address  owner;
    }

    function convertCountryIndexToBytes(uint[] countries) internal returns (uint,uint,uint){
        uint countries1 = 0;
        uint countries2 = 0;
        uint countries3 = 0;
        for(uint i = 0; i < countries.length; i++){
            uint index = countries[i];

            if(index<256){
                countries1 = countries1 | uint(1) << index;
            } else if (index<512) {
                countries2 = countries2 | uint(1) << (index - 256);
            } else {
                countries3 = countries3 | uint(1) << (index - 512);
            }
        }

        return (countries1,countries2,countries3);
    }

    
}