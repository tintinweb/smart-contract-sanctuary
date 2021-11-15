// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

/// BridgeBeams.sol
/// @title BEAMS token helper functions
/// @author artbridge.eth
/// @dev Library assists requirement checks across contracts
library BridgeBeams {
  struct Project {
    uint256 id;
    string name;
    string artist;
    string description;
    string website;
    uint256 supply;
    uint256 maxSupply;
    uint256 startBlock;
  }

  struct ProjectState {
    bool initialized;
    bool mintable;
    bool released;
    uint256 remaining;
  }

  struct ReserveParameters {
    uint256 maxMintPerTransaction;
    uint256 reservedMints;
    bytes32 reserveRoot;
  }

  /// @param _project Target project struct
  /// @return Project state struct derived from given input
  function projectState(Project memory _project)
    external
    view
    returns (BridgeBeams.ProjectState memory)
  {
    return
      ProjectState({
        initialized: isInitialized(_project),
        mintable: isMintable(_project),
        released: isReleased(_project),
        remaining: _project.maxSupply - _project.supply
      });
  }

  /// @param _project Target project struct
  /// @return True if project has required initial parameters, false if not
  function isInitialized(Project memory _project) internal pure returns (bool) {
    if (
      _project.id == 0 ||
      bytes(_project.artist).length == 0 ||
      bytes(_project.description).length == 0 ||
      _project.startBlock == 0
    ) {
      return false;
    }
    return true;
  }

  /// @param _project Target project struct
  /// @return True if project is past mint start block, false if not
  function isReleased(Project memory _project) internal view returns (bool) {
    return _project.startBlock > 0 && _project.startBlock <= block.number;
  }

  /// @param _project Target project struct
  /// @return True if project is available for public mint, false if not
  function isMintable(Project memory _project) internal view returns (bool) {
    if (!isInitialized(_project)) {
      return false;
    }
    return isReleased(_project) && _project.supply < _project.maxSupply;
  }
}

