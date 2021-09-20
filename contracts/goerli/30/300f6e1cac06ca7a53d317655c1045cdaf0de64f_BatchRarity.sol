/**
 *Submitted for verification at Etherscan.io on 2021-09-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface rarity {
    function adventurers_log(uint) external view returns (uint);
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

contract BatchRarity is IERC721Receiver {
    rarity private rm; //0xd20c5771dB9977266C7bcA4250b0ebd475B64CA7
    
    constructor(address _rarity_address) {
        rm = rarity(_rarity_address);
    }
    
    function summon(uint _class, uint _count, address _to) public {
        require(1 <= _class && _class <= 11);
        require(_count > 0);
        uint next_summoner = rm.next_summoner();
        for (uint i = 0; i < _count; i++) {
            rm.summon(_class);
            rm.transferFrom(address(this), _to, next_summoner + i);
        }
    }
    
    function adventure(uint[] memory summoners) public {
        for (uint i = 0; i < summoners.length; i++) {
            rm.adventure(summoners[i]);
        }
    }
    
    function adventureWithCheck(uint[] memory summoners) public {
        for (uint i = 0; i < summoners.length; i++) {
            if (block.timestamp > rm.adventurers_log(summoners[i])) {
                rm.adventure(summoners[i]);
            }
        }
    }
    
    function getLogs(uint256[] memory summoners) public view returns (uint[] memory) {
        uint[] memory logs = new uint[](summoners.length);
        for (uint i = 0; i < summoners.length; i++) {
            logs[i] = rm.adventurers_log(summoners[i]);
        }
        return logs;
    }
    
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}