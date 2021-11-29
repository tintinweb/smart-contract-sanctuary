/**
 *Submitted for verification at polygonscan.com on 2021-11-28
*/

pragma solidity ^0.8.0;


contract MyLOLStorage  {

    event StoreMatch(string matchId, string league, int currentLp);


    string[] public matchIdList;
    Match[] public matchStorage;
    uint256  private counter = 1;

    struct Match {
        string matchId;
        string league;
        int currentLp;
    }

    function store(string memory matchId, string memory league, int currentLp) public  {
        matchIdList[counter] = matchId;
        Match memory curMatch = Match(matchId, league, currentLp);
        matchStorage[counter] = curMatch;
        counter += 1;
        emit StoreMatch(matchId, league, currentLp);
    }
}