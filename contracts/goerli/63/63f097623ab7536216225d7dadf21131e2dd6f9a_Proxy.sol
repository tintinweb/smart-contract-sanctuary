/**
 *Submitted for verification at Etherscan.io on 2021-06-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
contract Ownable {

    bytes32 private constant ownerPosition = keccak256("btcpx.relay.proxy.owner");

    // EXCEPTION MESSAGES
    string constant ERR_ZERO_ADDRESS = "Zero address";
    string constant ERR_NOT_OWNER = "Sender is not owner";

    constructor() public {
        setOwner(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == getOwner(), ERR_NOT_OWNER);
        _;
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

    function transferOwnership(address _newOwner) external onlyOwner {
        _transferOwnership(_newOwner);
    }


    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0), ERR_ZERO_ADDRESS);
        setOwner(_newOwner);
    }
}


contract Upgradeable is Ownable {

    bytes32 private constant implementationPosition = keccak256("btcpx.relay.proxy.implementation");

    // EXCEPTION MESSAGES
    string constant ERR_INVALID_ADDRESS = "Implementation address is invalid";
    string constant ERR_INVALID_DATA = "Function data is invalid";
    string constant ERR_CONTRACT_ADDRESS = "Destination address is not contract";
    string constant ERR_SAME_ADDRESSES = "Old and New implementation addresses are same";

    constructor() public {

    }

    function getImplementation() public view returns (address implementation) {
        bytes32 position = implementationPosition;
        assembly {
            implementation := sload(position)
        }
    }

    function setImplementation(address _newImplementation) public onlyOwner {
        require(_newImplementation != address(0), ERR_ZERO_ADDRESS);
        require(isContract(_newImplementation), ERR_CONTRACT_ADDRESS);
        address currentImplementation = getImplementation();
        require(currentImplementation != _newImplementation, ERR_SAME_ADDRESSES);
        bytes32 position = implementationPosition;
        assembly {
            sstore(position, _newImplementation)
        }
    }

    function isContract(address _target) internal view returns (bool) {
        if (_target == address(0)) {
            return false;
        }

        uint256 size;
        assembly {
            size := extcodesize(_target)
        }
        return size > 0;
    }
}

contract Proxy is Upgradeable {

    constructor() public Upgradeable() {

    }

    fallback() external onlyOwner {
    require(msg.data.length > 0, ERR_INVALID_DATA);
        address _impl = getImplementation();
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0x0, calldatasize())
            let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0x0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0x0, size)
            switch result
            case 0 {
                revert(ptr, size)
            }
            default {
                return(ptr, size)
            }
        }
    }
}