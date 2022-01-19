// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;
import "../Storage/variable.sol";

contract Test2Facet is Variable {
    

    function getFirst() public view returns(uint) {
        PoolStorage storage ps = poolStorage();
        return ps.first;
    }

    function getSecond() public view returns(uint) {
        PoolStorage storage ps = poolStorage();
        return ps.second;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

contract Variable {
    bytes32 constant ADVANCED_POOL_STORAGE_POSITION = keccak256("diamond.testProject.storage.variable");
    
    struct PoolStorage {
        uint first;
        uint second;
    }
    function poolStorage() internal pure returns (PoolStorage storage ps) {
        bytes32 position = ADVANCED_POOL_STORAGE_POSITION;
        assembly {
            ps.slot := position
        }
    }
}