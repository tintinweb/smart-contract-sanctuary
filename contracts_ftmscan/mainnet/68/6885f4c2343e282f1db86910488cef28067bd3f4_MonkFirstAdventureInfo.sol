/**
 *Submitted for verification at FtmScan.com on 2021-12-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;


interface IRarity {
    function summoner(uint256 _summoner) external view returns(uint256 _xp, uint256 _log, uint256 _class, uint256 _level);
    function getApproved(uint256 tokenid) external view returns(address _address);
}

interface IRarity_attributes {
    function ability_scores(uint256) external view returns(uint32 strength, uint32 dexterity, uint32 constitution, uint32 intelligence, uint32 wisdom, uint32 charisma);
}

interface IMonkFirstAdventure {
    function adventureCount(uint256 _summoner) external view returns(uint256 _adventureCount);
    function winsCount(uint256 _summoner) external view returns(uint256 _winsCount);
    function lastAdventure(uint256 _summoner) external view returns(uint256 _lastAdventure);
}

interface ICopperBox {
    function balanceOfSummoner(uint256 _summoner) external view returns(uint256 _balanceOfSummoner);
}

contract MonkFirstAdventureInfo {
    IRarity constant rm = IRarity(0xce761D788DF608BD21bdd59d6f4B54b2e27F25Bb);
    IRarity_attributes constant ra = IRarity_attributes(0xB5F5AF1087A8DA62A23b08C00C6ec9af21F397a1);
    IMonkFirstAdventure constant mfa = IMonkFirstAdventure(0xbcedCE1e91dDDA15acFD10D0E55febB21FC6Aa38);
    ICopperBox constant cb = ICopperBox(0x253e55363F9440B532D13C228CB633Bac94F3b7C);
    
    function getSummonersInfo(uint[] calldata _summoners) view external returns(uint[] memory) {
        uint256 length = _summoners.length * 15;
        uint[] memory summonersInfo = new uint[](length);
        for (uint256 i = 0; i < _summoners.length; i++) {
            summonersInfo[i*15] = _summoners[i];
            uint[] memory summonerBase = new uint[](4);
            {
                (summonerBase[0], summonerBase[1], summonerBase[2], summonerBase[3]) = rm.summoner(_summoners[i]);
            }
            uint[] memory summonerAttributes = new uint[](6);
            {
                (summonerAttributes[0], summonerAttributes[1], summonerAttributes[2], summonerAttributes[3], summonerAttributes[4], summonerAttributes[5]) = ra.ability_scores(_summoners[i]);
            }
            uint[] memory adventureLogs = new uint[](3);
            adventureLogs[0] = mfa.adventureCount(_summoners[i]);
            adventureLogs[1] = mfa.winsCount(_summoners[i]);
            adventureLogs[2] = mfa.lastAdventure(_summoners[i]);
            uint256 copper = cb.balanceOfSummoner(_summoners[i]);
            summonersInfo[i*15+1] = summonerBase[0];
            summonersInfo[i*15+2] = summonerBase[1];
            summonersInfo[i*15+3] = summonerBase[2];
            summonersInfo[i*15+4] = summonerBase[3];
            summonersInfo[i*15+5] = summonerAttributes[0];
            summonersInfo[i*15+6] = summonerAttributes[1];
            summonersInfo[i*15+7] = summonerAttributes[2];
            summonersInfo[i*15+8] = summonerAttributes[3];
            summonersInfo[i*15+9] = summonerAttributes[4];
            summonersInfo[i*15+10] = summonerAttributes[5];
            summonersInfo[i*15+11] = adventureLogs[0];
            summonersInfo[i*15+12] = adventureLogs[1];
            summonersInfo[i*15+13] = adventureLogs[2];
            summonersInfo[i*15+14] = copper;
        }
        return summonersInfo;
    }

    function getApproveInfo(uint[] calldata _summoners) view external returns(address[] memory) {
        address[] memory approveInfo = new address[](_summoners.length);
        for (uint256 i = 0; i < _summoners.length; i++) {
            approveInfo[i] = rm.getApproved(_summoners[i]);
        }
        return approveInfo;
    }
}