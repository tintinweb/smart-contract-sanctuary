pragma solidity ^0.4.24;

/* 
Welcome to the greates pyramid scheme of the Internet! And it&#39;s UNSTOPPABLE
You can access it on IPFS here: https://ipfs.io/ipfs/Qmb6q3oWG33xeNoVppRHv1Mk23e5zMd8JK7dmKAhgiFk9H/
*/

contract UnstoppablePyramid {
    
    /* Admin */
    address devAddress = 0x75E129b02D12ECa5A5D7548a5F75007f84387b8F;

    /* The Unstoppable Ponzi Core */
    uint256 basePricePonzi = 50000000000000000;    // 0.05 ETH

    /* Some stats */
    uint256 totalAmountPlayed;
    uint256 totalCommissionSent;

    struct PonziFriend {
        address playerAddr;
        uint parent;
        uint256 amountPlayed;   // We keep track of the amount invested
        uint256 amountEarned;   // We keep track of the commissions received. It can&#39;t be more than 10x the amount invested
    }
    PonziFriend[] ponziFriends;
    mapping (address => uint) public ponziFriendsToId;
    
    /* Track Level 1, 2 and 3 commissions */
    mapping (uint => uint) public ponziFriendToLevel1Ref;
    mapping (uint => uint) public ponziFriendToLevel2Ref;
    mapping (uint => uint) public ponziFriendToLevel3Ref;

    // The main function, we call it when a new friend wants to join
    function newPonziFriend(uint _parentId) public payable isHuman() {
        /* Commissions */
        uint256 com1percent = msg.value / 100;
        uint256 comLevel1 = com1percent * 50; // 50%
        uint256 comLevel2 = com1percent * 35; // 35%
        uint256 comLevel3 = com1percent * 15; // 15%
    
        require(msg.value >= basePricePonzi);

        /* Transfer commission to parents (level 1, 2 & 3) */

        // Transfer to level 1 if parent[l1] hasn&#39;t reached its limit
        if(ponziFriends[_parentId].amountEarned < (ponziFriends[_parentId].amountPlayed * 5) && _parentId < ponziFriends.length) {
            // Transfer commission
            ponziFriends[_parentId].playerAddr.transfer(comLevel1);

            // Record amount received
            ponziFriends[_parentId].amountEarned += comLevel1;
            
            // Increment level 1 ref
            ponziFriendToLevel1Ref[_parentId]++;
        } else {
            // If the parent has exceeded its x5 limit we transfer the commission to the dev
            devAddress.transfer(comLevel1);
        }
        

        // Transfer to level 2
        uint level2parent = ponziFriends[_parentId].parent;
        if(ponziFriends[level2parent].amountEarned < (ponziFriends[level2parent].amountPlayed *5 )) {
            // Transfer commission
            ponziFriends[level2parent].playerAddr.transfer(comLevel2);

            // Record amount received
            ponziFriends[level2parent].amountEarned += comLevel2;
            
            // Increment level 2 ref
            ponziFriendToLevel2Ref[level2parent]++;
        } else {
            // If the parent has exceeded its x5 limit we transfer the commission to the dev
            devAddress.transfer(comLevel2);
        }
        

        // Transfer to level 3
        uint level3parent = ponziFriends[level2parent].parent;
        if(ponziFriends[level3parent].amountEarned < (ponziFriends[level3parent].amountPlayed * 5)) {
            // Transfer commission
            ponziFriends[level3parent].playerAddr.transfer(comLevel3); 

            // Record amount received
            ponziFriends[level3parent].amountEarned += comLevel3;
            
            // Increment level 3 ref
            ponziFriendToLevel3Ref[level3parent]++;
        } else {
            // If the parent has exceeded its x5 limit we transfer the commission to the dev
            devAddress.transfer(comLevel3);
        }

        /* End Transfer */

        /* Save Ponzi Friend in struct */

        if(ponziFriendsToId[msg.sender] > 0) {
            // Player exists, update data
            ponziFriends[ponziFriendsToId[msg.sender]].amountPlayed += msg.value;
        } else {
            // Player doesn&#39;t exist create it
            uint pzfId = ponziFriends.push(PonziFriend(msg.sender, _parentId, msg.value, 0)) - 1;
            ponziFriendsToId[msg.sender] = pzfId;
        }

        /* End Save Ponzi Friend */

        /* Save stats */
        totalAmountPlayed = totalAmountPlayed + msg.value;
        totalCommissionSent = totalCommissionSent + comLevel1 + comLevel2 + comLevel3;

    }

    // This function is called when the contract is deployed
    constructor() public {
        // We initiate the first player
        uint pzfId = ponziFriends.push(PonziFriend(devAddress, 0, 1000000000000000000000000000, 0)) - 1;
        ponziFriendsToId[msg.sender] = pzfId;
    }

    // This will return the stats for a ponzi friend // returns(ponziFriendId, parent, amoutPlayed, amountEarned)
    function getPonziFriend(address _addr) public view returns(uint, uint, uint256, uint256, uint, uint, uint) {
        uint pzfId = ponziFriendsToId[_addr];
        if(pzfId == 0) {
            return(0, 0, 0, 0, 0, 0, 0);
        } else {
            return(pzfId, ponziFriends[pzfId].parent, ponziFriends[pzfId].amountPlayed, ponziFriends[pzfId].amountEarned, ponziFriendToLevel1Ref[pzfId], ponziFriendToLevel2Ref[pzfId], ponziFriendToLevel3Ref[pzfId]);
        }
    }

    // Return some general stats about the game // returns(friendsLength, amountPlayed, commissionsSent)
    function getStats() public view returns(uint, uint256, uint256) {
        return(ponziFriends.length, totalAmountPlayed, totalCommissionSent);
    }

    // Add isHuman check for the newPonziFriend function (we want to avoid contract to participate in this experience)
    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;
        
        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }

    
}