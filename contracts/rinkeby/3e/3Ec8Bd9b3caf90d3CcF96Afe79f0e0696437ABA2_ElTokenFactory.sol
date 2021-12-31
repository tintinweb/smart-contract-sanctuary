/**
 *Submitted for verification at Etherscan.io on 2021-12-30
*/

// SPDX-License-Identifier: MIT

// 0.00587378 ETH

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

    function tokenOptionID(string calldata _project, uint256 _factoryOptionID) public view returns (uint256) {
        require(projectExists(_project), "Project doesn't exist");
        return tokenIdOffsets[_project] + _factoryOptionID;
    }

    function tokenURI(uint256 _tokenOptionID) public view returns (string memory) {
        // TODO: require()
        return string(abi.encodePacked('ipfs://', CIDs[_tokenOptionID]));
    }

    function addCIDs(string[] calldata _CIDs) internal {
        for (uint i = 0; i < _CIDs.length; i++) {
            CIDs.push(_CIDs[i]);
        }
    }
}


contract ElTokenFactory {

    string project;
    address repositoryAddress;
    uint256 optionsCount;

    constructor(string memory _project, string[] memory _CIDs, address _repositoryAddress) {
        project = _project;
        repositoryAddress = _repositoryAddress;

        ElTokenRepository repository = ElTokenRepository(_repositoryAddress);
        repository.addProject(_project, _CIDs);
    }

    function tokenURI(uint256 _optionID) public view returns(string memory) {
        ElTokenRepository repository = ElTokenRepository(repositoryAddress);
        uint256 _tokenOptionID = repository.tokenOptionID(project, _optionID);
        return repository.tokenURI(_tokenOptionID);
    }
}