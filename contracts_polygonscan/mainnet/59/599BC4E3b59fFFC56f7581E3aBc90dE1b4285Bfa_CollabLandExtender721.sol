// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.6;

import "./Ownable.sol";
import "./ERC721.sol";
import "./EnumerableSet.sol";

contract CollabLandExtender721 is ERC721, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private _projects;

    constructor() ERC721("Collab.Land ERC-721 Extender", "CLE721") {}

    function balanceOf(address owner) public view override returns (uint256) {
        uint256 _totalOwned;
        for (uint256 i = 0; i < _projects.length(); i++) {
            if (IERC721(_projects.at(i)).balanceOf(owner) > 0) {
                _totalOwned++;
            }
        }
        return _totalOwned;
    }

    function addProjects(address[] memory _projectsToAdd) external onlyOwner {
        for (uint256 i = 0; i < _projectsToAdd.length; i++) {
            _projects.add(_projectsToAdd[i]);
        }
    }

    function removeProjects(address[] memory _projectsToRemove)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _projectsToRemove.length; i++) {
            _projects.remove(_projectsToRemove[i]);
        }
    }

    function getProjects() external view returns (address[] memory) {
        return _projects.values();
    }
}