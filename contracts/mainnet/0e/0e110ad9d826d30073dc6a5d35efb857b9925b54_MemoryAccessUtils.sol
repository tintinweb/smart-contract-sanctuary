pragma solidity ^0.5.2;

import "./MemoryMap.sol";

contract MemoryAccessUtils is MemoryMap {
    function getPtr(uint256[] memory ctx, uint256 offset)
        internal pure
        returns (uint256) {
        uint256 ctxPtr;
        require(offset < MM_CONTEXT_SIZE, "Overflow protection failed");
        assembly {
            ctxPtr := add(ctx, 0x20)
        }
        return ctxPtr + offset * 0x20;
    }

    function getProofPtr(uint256[] memory proof)
        internal pure
        returns (uint256)
    {
        uint256 proofPtr;
        assembly {
            proofPtr := proof
        }
        return proofPtr;
    }

    function getChannelPtr(uint256[] memory ctx)
        internal pure
        returns (uint256) {
        uint256 ctxPtr;
        assembly {
            ctxPtr := add(ctx, 0x20)
        }
        return ctxPtr + MM_CHANNEL * 0x20;
    }

    function getQueries(uint256[] memory ctx)
        internal pure
        returns (uint256[] memory)
    {
        uint256[] memory queries;
        // Dynamic array holds length followed by values.
        uint256 offset = 0x20 + 0x20*MM_N_UNIQUE_QUERIES;
        assembly {
            queries := add(ctx, offset)
        }
        return queries;
    }

    function getMerkleQueuePtr(uint256[] memory ctx)
        internal pure
        returns (uint256)
    {
        return getPtr(ctx, MM_MERKLE_QUEUE);
    }

    function getFriSteps(uint256[] memory ctx)
        internal pure
        returns (uint256[] memory friSteps)
    {
        uint256 friStepsPtr = getPtr(ctx, MM_FRI_STEPS_PTR);
        assembly {
            friSteps := mload(friStepsPtr)
        }
    }
}
