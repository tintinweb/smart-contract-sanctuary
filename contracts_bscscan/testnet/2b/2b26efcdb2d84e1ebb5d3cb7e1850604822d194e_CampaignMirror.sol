/**
 *Submitted for verification at BscScan.com on 2021-12-10
*/

// SPDX-License-Identifier: agpl-3.0

// File: interfaces/ISuperDeedNFT.sol



pragma solidity ^0.8.0;

interface ISuperDeedNFT {
    function mint(address to, uint weight) external returns (uint);
    function setTotalRaise(uint raised, uint entitledTokens) external;
}

// File: interfaces/IRoleAccess.sol



pragma solidity ^0.8.0;

interface IRoleAccess {
    function isAdmin(address user) view external returns (bool);
    function isDeployer(address user) view external returns (bool);
    function isConfigurator(address user) view external returns (bool);
    function isApprover(address user) view external returns (bool);
    function isRole(string memory roleName, address user) view external returns (bool);
}

// File: interfaces/IManager.sol



pragma solidity ^0.8.0;


interface IManager {
    function addCampaign(address newContract, address distributor, address newNFTContract) external;   
    function getRoles() external view returns (IRoleAccess);
}


// File: Test.sol



pragma solidity ^0.8.0;



contract CampaignMirror  {

    uint public totalRaised;
    uint public totalEntitlement;


    struct Purchase {
        address bscAddress;
        uint bought; 
        uint entitlement;
    }

    Purchase[] public purchases; // individual purchases
    uint public purchaseCount;
    mapping(address => uint) public purchaseMap; // For verification purpose. 1 BSC address can only have 1 purchase.
 
    struct ClaimerStat {
        uint[] purchasesIndex;
        uint totalBought;
        uint totalEntitlement;
        bool mintedNFT;     // user has claimed ? (ie minted his NFT)
    }
    mapping(address => ClaimerStat) public claimers;



    function uploadData_1(address[] calldata bscAddresses, address[] calldata destAddresses, uint[] calldata boughts, uint[] calldata entitlements) 
        external 
    {
        uint len = bscAddresses.length;
        require(destAddresses.length == len, "Error.InvalidRange");
        require(boughts.length == len, "Error.InvalidRange");
        require(entitlements.length == len, "Error.InvalidRange");

        address bscAddress;
        uint bought;
        uint entitle;

        for (uint n=0; n<len; n++) {
            
            bscAddress = bscAddresses[n];
            bought = boughts[n];
            entitle = entitlements[n];

            // Save purchases array
            purchases.push( Purchase(bscAddress, bought, entitle) );
            uint index = purchaseCount++;

            purchaseMap[bscAddress] = index; // Each bsc address can only have 1 purchase.

            // Save claimer map
            ClaimerStat storage stat = claimers[msg.sender];
            stat.purchasesIndex.push(index);
            stat.totalBought += bought; 
            stat.totalEntitlement += entitle;

            // Update total raise, entitlements
            totalRaised += bought; 
            totalEntitlement += entitle;
        }
    }

     function uploadData_2(address[] calldata destAddresses, uint[] calldata boughts, uint[] calldata entitlements) 
        external 
    {
        uint len = destAddresses.length;
        require(boughts.length == len, "Error.InvalidRange");
        require(entitlements.length == len, "Error.InvalidRange");

        uint bought;
        uint entitle;

        for (uint n=0; n<len; n++) {
            
            bought = boughts[n];
            entitle = entitlements[n];

            // Save claimer map
            ClaimerStat storage stat = claimers[msg.sender];
           // stat.purchasesIndex.push(index);
            stat.totalBought += bought; 
            stat.totalEntitlement += entitle;

            // Update total raise, entitlements
            totalRaised += bought; 
            totalEntitlement += entitle;
        }
    }


}