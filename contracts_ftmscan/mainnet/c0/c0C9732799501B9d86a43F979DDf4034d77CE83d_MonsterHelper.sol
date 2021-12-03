/**
 *Submitted for verification at FtmScan.com on 2021-12-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;


interface IRarity {
    function ownerOf(uint) external view returns (address);
    function isApprovedForAll(address owner, address operator) external pure returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

interface IRarityAttributes {
    function point_buy(uint _summoner, uint32 _str, uint32 _dex, uint32 _const, uint32 _int, uint32 _wis, uint32 _cha) external;
}

interface IMonkFirstAdventure {
    function adventure(uint _summoner) external;
}

contract MonsterHelper {
    IRarity constant rar = IRarity(0xce761D788DF608BD21bdd59d6f4B54b2e27F25Bb);
    IRarityAttributes constant ra = IRarityAttributes(0xB5F5AF1087A8DA62A23b08C00C6ec9af21F397a1);
    IMonkFirstAdventure constant mfa = IMonkFirstAdventure(0xbcedCE1e91dDDA15acFD10D0E55febB21FC6Aa38);
    
    address payable owner;
 
    constructor() { owner = payable(msg.sender); }
    
    function multiple_transfer(uint[] calldata _summoners, address to) external {
        for (uint256 i = 0; i < _summoners.length; i++) {
            require(_isOwner(_summoners[i]), "Only owner can transfer token");
            rar.safeTransferFrom(msg.sender, to, _summoners[i]);
        }
    }

    function multiple_buypoint(uint[] calldata _summoners, uint32 _str, uint32 _dex, uint32 _const, uint32 _int, uint32 _wis, uint32 _cha) external {
        for (uint256 i = 0; i < _summoners.length; i++) {
            require(_isOwner(_summoners[i]), "Only owner can buy point");
            ra.point_buy(_summoners[i], _str, _dex, _const, _int, _wis, _cha);
        }
    }

    function multiple_adventure(uint[] calldata _summoners) external {
        for (uint256 i = 0; i < _summoners.length; i++) {
            mfa.adventure(_summoners[i]);
        }
    }
    
    function destroy() external {
        require(msg.sender == owner, "Only contract owner can call this function.");
        selfdestruct(owner);
    }
    
    function _isOwner(uint _summoner) internal view returns (bool) {
        return (rar.ownerOf(_summoner) == msg.sender);
    }
}