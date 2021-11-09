/**
 *Submitted for verification at Etherscan.io on 2021-11-09
*/

/**
 *Submitted for verification at Etherscan.io on 2021-09-08
*/

// File: contracts/base/AdminStorage.sol

pragma solidity ^0.6.12;


contract AdminStorage{
    address public admin;
    address public implementation;
}

// File: contracts/sashimi/GameOfTrustSashimiDelegator.sol

pragma solidity ^0.6.12;



contract GameOfTrustSashimiDelegator is AdminStorage{

    event NewImplementation(address oldImplementation, address newImplementation);
    event NewAdmin(address oldAdmin, address newAdmin);

    constructor(
        uint256 _startBlock,
        uint256 _stakeEndBlock,
        uint256 _blocksDaliy,
        address _GAN,
        address _SASHIMI,
        address _pair,
        address _implementation
    ) public {
        admin = msg.sender;
        delegateTo(
            _implementation,
            abi.encodeWithSignature(
                "initialize(uint256,uint256,uint256,address,address,address)",
                _startBlock,
                _stakeEndBlock,
                _blocksDaliy,
                _GAN,
                _SASHIMI,
                _pair
            )
        );
        _setImplementation(_implementation);
    }

    function _setImplementation(address implementation_) public {
        require(msg.sender == admin, "UNAUTHORIZED");

        address oldImplementation = implementation;
        implementation = implementation_;

        emit NewImplementation(oldImplementation, implementation);
    }

    function _setAdmin(address newAdmin) public {
        require(msg.sender == admin, "UNAUTHORIZED");

        address oldAdmin = admin;

        admin = newAdmin;

        emit NewAdmin(oldAdmin, newAdmin);
    }

    function delegateTo(address callee, bytes memory data)
    internal
    returns (bytes memory)
    {
        (bool success, bytes memory returnData) = callee.delegatecall(data);
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize())
            }
        }
        return returnData;
    }

    receive() external payable {}

    /**
  * @notice Delegates execution to an implementation contract
  * @dev It returns to the external caller whatever the implementation returns or forwards reverts
 //  */
    fallback() external payable {
        // delegate all other functions to current implementation
        (bool success,) = implementation.delegatecall(msg.data);
        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize())
            switch success
            case 0 {
                revert(free_mem_ptr, returndatasize())
            }
            default {
                return (free_mem_ptr, returndatasize())
            }
        }
    }

}