pragma solidity ^0.6.0;

interface MemoryInterface {
    function getUint(uint _id) external returns (uint _num);
    function setUint(uint _id, uint _val) external;
}

contract DSMath {

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "math-not-safe");
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }
}


contract Helpers is DSMath {
    /**
     * @dev Return Memory Variable Address
     */
    function getMemoryAddr() internal pure returns (address) {
        return 0x8a5419CfC711B2343c17a6ABf4B2bAFaBb06957F; // InstaMemory Address
    }

    /**
     * @dev Get Uint value from InstaMemory Contract.
    */
    function getUint(uint getId, uint val) internal returns (uint returnVal) {
        returnVal = getId == 0 ? val : MemoryInterface(getMemoryAddr()).getUint(getId);
    }

    /**
     * @dev Set Uint value in InstaMemory Contract.
    */
    function setUint(uint setId, uint val) internal {
        if (setId != 0) MemoryInterface(getMemoryAddr()).setUint(setId, val);
    }

    /**
     * @dev Connector Details
    */
    function connectorID() public pure returns(uint _type, uint _id) {
        (_type, _id) = (1, 47);
    }
}

contract BasicResolver is Helpers {

    /**
     * @dev Add getIds
     * @param getIds Array of get token amount at this IDs from `InstaMemory` Contract.
     * @param setId Set ctoken amount at this ID in `InstaMemory` Contract.
    */
    function addIds(uint[] calldata getIds, uint setId) external payable {
        uint amt;
        for (uint i = 0; i < getIds.length; i++) {
            amt = add(amt, getUint(getIds[i], 0));
        }

        setUint(setId, amt);
    }

    /**
     * @dev Sub two getId.
     * @param getIdOne Get token amount at this ID from `InstaMemory` Contract.
     * @param getIdTwo Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set ctoken amount at this ID in `InstaMemory` Contract.
    */
    function subIds(uint getIdOne, uint getIdTwo, uint setId) external payable {
        uint amt = sub(getUint(getIdOne, 0), getUint(getIdTwo, 0));

        setUint(setId, amt);
    }
}

contract ConnectVariableMath is BasicResolver {
    string public name = "memory-variable-math-v1";
}