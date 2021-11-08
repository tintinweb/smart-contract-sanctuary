// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.6;

import "./Ownable.sol";
import "./ERC721.sol";
import "./IERC1155.sol";
import "./EnumerableSet.sol";

contract CollabLandExtender1155 is ERC721, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    EnumerableSet.AddressSet private _projects;
    mapping(address => EnumerableSet.UintSet) private _projectIds;

    constructor() ERC721("Collab.Land ERC-1155 Extender", "CLE1155") {}

    function balanceOf(address account)
        public
        view
        override
        returns (uint256)
    {
        uint256 _totalOwned;
        for (uint256 i = 0; i < _projects.length(); i++) {
            address _currentProject = _projects.at(i);
            for (
                uint256 j = 0;
                j < _projectIds[_currentProject].length();
                j++
            ) {
                if (IERC1155(_currentProject).balanceOf(account, j) > 0) {
                    _totalOwned++;
                }
            }
        }
        return _totalOwned;
    }

    function addProjectsAndIds(
        address[] memory _projectsToAdd,
        uint256[] memory _idsToAdd
    ) external onlyOwner {
        require(
            _projectsToAdd.length == _idsToAdd.length,
            "array lengths must match"
        );
        for (uint256 i = 0; i < _projectsToAdd.length; i++) {
            _projects.add(_projectsToAdd[i]);
            _projectIds[_projectsToAdd[i]].add(_idsToAdd[i]);
        }
    }

    function removeProjectsAndIds(
        address[] memory _projectsToRemove,
        uint256[] memory _idsToRemove
    ) external onlyOwner {
        require(
            _projectsToRemove.length == _idsToRemove.length,
            "array lengths must match"
        );
        for (uint256 i = 0; i < _projectsToRemove.length; i++) {
            _projectIds[_projectsToRemove[i]].remove(_idsToRemove[i]);
            if (_projectIds[_projectsToRemove[i]].length() == 0) {
                _projects.remove(_projectsToRemove[i]);
            }
        }
    }

    function getProjects() external view returns (address[] memory) {
        return _projects.values();
    }

    function getIdsForProject(address _project)
        external
        view
        returns (uint256[] memory)
    {
        return _projectIds[_project].values();
    }
}