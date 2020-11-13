// File: contracts/lib/interface/IVirtContractResolver.sol

pragma solidity ^0.5.1;

/**
 * @title VirtContractResolver interface
 */
interface IVirtContractResolver {
    function deploy(bytes calldata _code, uint _nonce) external returns (bool);
    
    function resolve(bytes32 _virtAddr) external view returns (address);

    event Deploy(bytes32 indexed virtAddr);
}

// File: contracts/VirtContractResolver.sol

pragma solidity ^0.5.1;


/**
 * @title Virtual Contract Resolver contract
 * @notice Implementation of the Virtual Contract Resolver.
 * @dev this resolver establishes the mapping from off-chain address to on-chain address
 */
contract VirtContractResolver is IVirtContractResolver {
    mapping(bytes32 => address) virtToRealMap;

    /**
     * @notice Deploy virtual contract to an on-chain address
     * @param _code bytes of virtual contract code
     * @param _nonce nonce associated to virtual contract code
     * @return true if deployment succeeds
     */
    function deploy(bytes calldata _code, uint _nonce) external returns(bool) {
        bytes32 virtAddr = keccak256(abi.encodePacked(_code, _nonce));
        bytes memory c = _code;
        require(virtToRealMap[virtAddr] == address(0), "Current real address is not 0");
        address deployedAddress;
        assembly {
            deployedAddress := create(0, add(c, 32), mload(c))
        }
        require(deployedAddress != address(0), 'Create contract failed.');

        virtToRealMap[virtAddr] = deployedAddress;
        emit Deploy(virtAddr);
        return true;
    }

    /**
     * @notice look up the deployed address of a virtual address
     * @param _virtAddr the virtual address to be looked up
     * @return the deployed address of the input virtual address
     */
    function resolve(bytes32 _virtAddr) external view returns(address) {
        require(virtToRealMap[_virtAddr] != address(0), 'Nonexistent virtual address');
        return virtToRealMap[_virtAddr];
    }
}