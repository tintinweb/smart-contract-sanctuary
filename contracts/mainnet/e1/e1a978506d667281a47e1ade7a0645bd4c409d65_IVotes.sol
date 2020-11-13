// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.8.0;

/*
 * @title IVotes
 */
interface IVotes {
    function isVoted(address _who) external view returns (bool);

    function totalVotes() external view returns (uint);

    function totalWeight() external view returns (uint);

//    function deposit() external payable;
    function withdraw() external;

    function voteForRepublicans() external payable;

    function voteForDemocrats() external payable;

    // after 1 month contract can be destroyed
    function destroyIt() external;

    function democratsWon() external;

    function republicansWon() external;
}
