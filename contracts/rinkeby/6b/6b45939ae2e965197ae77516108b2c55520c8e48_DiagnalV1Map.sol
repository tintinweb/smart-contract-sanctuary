/**
 *Submitted for verification at Etherscan.io on 2021-09-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

/**
 * @title DiagonalV1
 * @author trozler.
 * @dev A sample contract written by trozler demoing constant flow agreemnt.
 */
contract DiagnalV1Map {

    mapping(address => mapping(uint256 => mapping(uint256 => mapping(address => int96)))) public bigMap;
    mapping(bytes32 => mapping(address => int96)) public smallMap;

    function toBytesNum(uint256 x) internal pure returns (bytes memory b) {
        b = new bytes(32);
        assembly { mstore(add(b, 32), x) }
    }
    
    function toBytesAddr(address x) internal pure returns (bytes memory b) {
        b = new bytes(32);
        assembly { mstore(add(b, 32), x) }
    }
    

    function writeBigMap() public {
        
        address provider = 0x49a9f3D47816f5715Dd75e7728d1781e29eF2460;
        uint256 serviceId = 1;
        uint256 packageId = 2;
        
        bigMap[provider][serviceId][packageId][address(0x0)] = 10;

    }
    
    function readBiglMap() public view returns(int96) {
        
        address provider = 0x49a9f3D47816f5715Dd75e7728d1781e29eF2460;
        uint256 serviceId = 1;
        uint256 packageId = 2;
        
        return  bigMap[provider][serviceId][packageId][address(0x01)];

    }
    
    /// @dev lets you compute kecc256(provider || serviceId || packageId)
    function findHash(address provider, uint256 serviceId, uint256 packageId) internal pure returns (bytes32 hash) {
        // assembly { 
        //     // Get end of current free memory
        //     let ptr := mload(0x40)
            
        //     // Write items to memeory
        //     mstore(ptr, packageId) 
        //     mstore(add(ptr, 32), serviceId)
        //     mstore(add(ptr, 64), provider)
            
        //     // Compute hash from start of free memory to end of memory allocated.
        //     hash := keccak256(ptr, add(ptr, 96))
        // }
        
        bytes memory b = new bytes(96);
        assembly { 
            mstore(add(b, 32), packageId)
            mstore(add(b, 64), serviceId)
            mstore(add(b, 96), provider)
            
            hash := keccak256(b, add(b, 128))
        
        }
    }
    
    
    event HashFound(bytes32 indexed hash);
    
    
    function writeSmallMap() public  {
        address provider = 0x49a9f3D47816f5715Dd75e7728d1781e29eF2460;
        uint256 serviceId = 1;
        uint256 packageId = 2;
    
        // bytes32 hash = findHash(provider, serviceId, packageId);
        
        // emit HashFound(hash);
        

        bytes32 providerServicePkgIdKey = keccak256(abi.encodePacked(provider, serviceId, packageId));

        smallMap[providerServicePkgIdKey][address(0x01)] = 10;

    }
    
    
    function readSmallMap(address provider, uint256 serviceId, uint256 packageId) public view returns(int96) {
        
        bytes32 providerServicePkgIdKey = keccak256(abi.encodePacked(provider, serviceId, packageId));

        return smallMap[providerServicePkgIdKey][address(0x0)];

    }

}