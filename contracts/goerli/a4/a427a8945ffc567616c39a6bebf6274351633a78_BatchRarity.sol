/**
 *Submitted for verification at Etherscan.io on 2021-09-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface rarity {
    function next_summoner() external view returns (uint);
    function level(uint) external view returns (uint);
    function getApproved(uint) external view returns (address);
    function ownerOf(uint) external view returns (address);
    function adventure(uint _summoner) external;
    function level_up(uint _summoner) external;
    function summoner(uint _summoner) external view returns (uint _xp, uint _log, uint _class, uint _level);
    function summon(uint _class) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract BatchRarity {
    rarity private rm; //0xd20c5771dB9977266C7bcA4250b0ebd475B64CA7
    
    constructor(address _rarity_address) {
        rm = rarity(_rarity_address);
    }
    
    function summon(uint classId, uint count, address to) public {
        require(1 <= classId && classId <= 11, "class id be 1 - 11");
        require(count > 0, "count must > 0");
        uint next_summoner = rm.next_summoner();
        for (uint i = 0; i < count; i++) {
            rm.summon(classId);
            rm.transferFrom(address(this), to, next_summoner + i);
        }
    }
    
    function adventure(uint[] memory summoners) public {
        for (uint i = 0; i < summoners.length; i++) {
            rm.adventure(summoners[i]);
        }
    }
    
    function getLogs(uint256[] memory summoners) public view returns (uint[] memory) {
        uint[] memory logs;
        for (uint i = 0; i < summoners.length; i++) {
            (, logs[i], , ) = rm.summoner(summoners[i]);
        }
        return logs;
    }
}