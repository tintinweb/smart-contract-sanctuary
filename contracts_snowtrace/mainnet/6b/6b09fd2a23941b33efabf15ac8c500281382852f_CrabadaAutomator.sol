/**
 *Submitted for verification at snowtrace.io on 2021-12-31
*/

pragma solidity >=0.8.0;

interface CrabadaGame {
    function startGame(uint256 teamId) external;
    function closeGame(uint256 gameId) external;
}

contract CrabadaAutomator {
    CrabadaGame crabadaContract = CrabadaGame(0x82a85407BD612f52577909F4A58bfC6873f14DA8);

    function startGame(uint256 teamId) external {
        crabadaContract.startGame(teamId);
    }

    function closeGame(uint gameId) external {
        crabadaContract.closeGame(gameId);
    }
}