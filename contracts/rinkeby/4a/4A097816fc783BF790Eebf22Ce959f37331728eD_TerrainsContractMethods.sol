//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import '../libraries/terrain/Terrain.sol';


contract TerrainsContractMethods {
    
    address public methodsContractAddress;
    uint256 public terrainId = 1;
    string error = "Failed to delegatecall";
    mapping(uint256 => Arena.Default) public terrains;
    
    event NewTerrain(uint256 indexed terrainId, Arena.Default terrain);
    event EditTerrain(uint256 indexed terrainId, Arena.Default terrain);

    function setGlobalParameters(address methods) external {
        methodsContractAddress = methods;
    }

    function createTerrain(Arena.Default memory terrain) external {
        terrains[terrainId] = terrain;
        emit NewTerrain(terrainId,terrain);
        ++terrainId;
    }
    
    function editTerrain(uint256 _id, Arena.Default memory terrain) external {
        terrains[_id] = terrain;
        emit EditTerrain(_id,terrain);
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity <=0.8.10;


library Arena {
    
    struct Default {
        uint32 surface;
        uint32 distance;
        uint32 weather;
    }

    struct Wrapped {
        uint256 id;
        Default terrain;
    }

}