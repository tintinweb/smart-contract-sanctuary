/**
 *Submitted for verification at snowtrace.io on 2021-12-22
*/

pragma solidity 0.8.3;

// SPDX-License-Identifier: MIT
contract IGame {
    function startGame(uint256 teamId) external {}
    function attack(uint256 gameId, uint256 attackTeamId) external {}
    function reinforceAttack(uint256 gameId, uint256 crabadaId, uint256 borrowPrice) external {}
    function reinforceDefense(uint256 gameId, uint256 crabadaId, uint256 borrowPrice) external {}
    function settleGame(uint256 gameId) external {}
    function closeGame(uint256 gameId) external {}
    function addCrabadaToTeam(uint256 teamId, uint256 position, uint256 crabadaId)  external {}
    function createTeam(uint256 crabadaId1, uint256 crabadaId2, uint256 crabadaId3) external {}
    function deposit(uint256[] calldata crabadaIds) external {}
    function withdraw(address to, uint256[] calldata crabadaIds) external {}
    function setLendingPrice(uint256 crabadaId, uint256 price) external {}
    function removeCrabadaFromTeam(uint256 teamId, uint256 position)  external {}
}