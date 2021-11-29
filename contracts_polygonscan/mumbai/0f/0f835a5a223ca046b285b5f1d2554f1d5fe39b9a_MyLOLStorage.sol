/**
 *Submitted for verification at polygonscan.com on 2021-11-28
*/

pragma solidity ^0.8.0;


contract MyLOLStorage  {

    event StoreMatch(uint256 matchId, string league, uint currentLp);

    // string[] public matchIdList;
    mapping(uint256 => Match) public mapIdtoMatch;
    mapping(uint256 => uint256) public mapCountertoId;
    Match[] public matchStorage;
    uint256 private counter = 1;

    struct Match {
        uint256 matchId;
        string league;
        uint currentLp;
    }

    function store(uint256 matchId, string calldata league, uint currentLp) public  {
        
        Match memory curMatch = Match(matchId, league, currentLp);
        mapIdtoMatch[matchId] = curMatch;
        mapCountertoId[counter] = matchId;
        counter += 1;
        emit StoreMatch(matchId, league, currentLp);
    }

    function readByIndex(uint256 index) public view returns(Match memory)  {
        uint256 matchId = mapCountertoId[index];
        return readByMatchId(matchId);
    }

    function readByMatchId(uint256 index) public view returns(Match memory)  {
        return mapIdtoMatch[index];
    }
}