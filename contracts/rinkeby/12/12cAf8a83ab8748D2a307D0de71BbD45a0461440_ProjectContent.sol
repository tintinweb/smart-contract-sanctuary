/**
 *Submitted for verification at Etherscan.io on 2021-07-31
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.0;

contract ProjectContent {

    string public projectTitle;
    string public projectLocation;
    string public projectStart;
    string public projectEnd;
    string public teamType;


    function projectContent(string memory initialProjectTitle, string memory initialProjectLocation, string memory initialProjectStart, string memory initialProjectEnd, string memory initialTeamType) public {
        projectTitle = initialProjectTitle;
        projectLocation = initialProjectLocation;
        projectStart = initialProjectStart;
        projectEnd = initialProjectEnd;
        teamType = initialTeamType;
    }

    function setContract(string memory newProjectTitle, string memory newProjectLocation, string memory newProjectStart, string memory newProjectEnd, string memory newTeamType) public {
        projectTitle = newProjectTitle;
        projectLocation = newProjectLocation;
        projectStart = newProjectStart;
        projectEnd = newProjectEnd;
        teamType = newTeamType;

    }

    function getProjectTitle() public view returns ( string memory) {
      return projectTitle;
    }

    function getProjectLocation() public view returns ( string memory) {
      return projectLocation;
    }

    function getProjectStart() public view returns ( string memory) {
        return projectStart;
    }

    function getProjectEnd() public view returns ( string memory) {
        return projectEnd;
    }

    function getTeamType() public view returns ( string memory) {
        return teamType;
    }



}