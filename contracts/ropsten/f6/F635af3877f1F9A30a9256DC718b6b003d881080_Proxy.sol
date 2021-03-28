/**
 *Submitted for verification at Etherscan.io on 2021-03-28
*/

pragma solidity 0.5.16;

contract Ownable {
    bytes32 private constant ownerPosition = keccak256("owner");

    constructor() public {
        setOwner(msg.sender);
    }

    function requireOwner() internal view {
        require(msg.sender == getOwner(), "55f1136901"); // 55f1136901 - sender must be owner
    }

    function getOwner() public view returns (address owner) {
        bytes32 position = ownerPosition;
        assembly {
            owner := sload(position)
        }
    }

    function setOwner(address _newOwner) internal {
        bytes32 position = ownerPosition;
        assembly {
            sstore(position, _newOwner)
        }
    }

    function transferOwnership(address _newOwner) external {
        requireOwner();
        require(_newOwner != address(0), "f2fde38b01"); // f2fde38b01 - new owner cant be zero address
        setOwner(_newOwner);
    }
}


contract Upgradeable is Ownable {

    bytes32 private constant implementationPosition = keccak256(
        "implementation"
    );


    constructor() public Ownable() {}

    function getImplementation() public view returns (address implementation) {
        bytes32 position = implementationPosition;
        assembly {
            implementation := sload(position)
        }
    }

    function setImplementation(address _newImplementation) public {
        requireOwner();
        require(_newImplementation != address(0), "d784d42601"); // d784d42601 - new implementation must have non-zero address
        address currentImplementation = getImplementation();
        require(currentImplementation != _newImplementation, "d784d42602"); // d784d42602 - new implementation must have new address
        bytes32 position = implementationPosition;
        assembly {
            sstore(position, _newImplementation)
        }
    }

    function setImplementationAndCall(
        address _newImplementation,
        bytes calldata _newImplementaionCallData
    ) external payable {
        setImplementation(_newImplementation);
        if (_newImplementaionCallData.length > 0) {
            (bool success, ) = address(this).call.value(msg.value)(
                _newImplementaionCallData
            );
            require(success, "e9c8588d01"); // e9c8588d01 - delegatecall has failed
        }
    }
}

contract Proxy is Upgradeable {

    constructor() public Upgradeable() {}

     function() external payable {
        require(msg.data.length > 0, "9d96e2df01"); // 9d96e2df01 - calldata must not be empty
        address _impl = getImplementation();
        assembly {
            // The pointer to the free memory slot
            let ptr := mload(0x40)
            // Copy function signature and arguments from calldata at zero position into memory at pointer position
            calldatacopy(ptr, 0x0, calldatasize)
            // Delegatecall method of the implementation contract, returns 0 on error
            let result := delegatecall(gas, _impl, ptr, calldatasize, 0x0, 0)
            // Get the size of the last return data
            let size := returndatasize
            // Copy the size length of bytes from return data at zero position to pointer position
            returndatacopy(ptr, 0x0, size)
            // Depending on result value
            switch result
                case 0 {
                    // End execution and revert state changes
                    revert(ptr, size)
                }
                default {
                    // Return data with length of size at pointers position
                    return(ptr, size)
                }
        }
    }
}