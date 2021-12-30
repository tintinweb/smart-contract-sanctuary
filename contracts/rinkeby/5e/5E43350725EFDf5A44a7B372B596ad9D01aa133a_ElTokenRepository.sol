/**
 *Submitted for verification at Etherscan.io on 2021-12-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

contract ElTokenRepository {

    string[] CIDs;
    mapping(string => uint256) tokenIdOffsets;
    string[] projects;
    uint256 tokenOptionsCount;

    function addProject(string calldata _project, string[] calldata _CIDs) public {
        // TODO: only owner!
        require(!projectExists(_project), 'Project already exists!');

        addCIDs(_CIDs);
        tokenIdOffsets[_project] = tokenOptionsCount;
        tokenOptionsCount += _CIDs.length;
    }

    function projectExists(string calldata _project) internal view returns (bool) {
        for (uint i = 0; i < projects.length; i++) {
            if (keccak256(abi.encodePacked(projects[i])) == keccak256(abi.encodePacked(_project))) {
                return true;
            }
        }
        return false;
    }

    function tokenURI(uint256 _tokenOptionID) public view returns(string memory) {
        return string(abi.encodePacked('ipfs://', CIDs[_tokenOptionID]));
    }

    function addCIDs(string[] calldata _CIDs) internal {
        for (uint i = 0; i < _CIDs.length; i++) {
            CIDs.push(_CIDs[i]);
        }
    }
}