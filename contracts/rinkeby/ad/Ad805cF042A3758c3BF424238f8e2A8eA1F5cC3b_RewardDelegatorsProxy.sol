pragma solidity >=0.4.21 <0.7.0;


/// @title Contract to reward overlapping stakes
/// @author Marlin
/// @notice Use this contract only for testing
/// @dev Contract may or may not change in future (depending upon the new slots in proxy-store)
contract RewardDelegatorsProxy {
    bytes32 internal constant IMPLEMENTATION_SLOT = bytes32(
        uint256(keccak256("eip1967.proxy.implementation")) - 1
    );
    bytes32 internal constant PROXY_ADMIN_SLOT = bytes32(
        uint256(keccak256("eip1967.proxy.admin")) - 1
    );

    constructor(address contractLogic, address proxyAdmin) public {
        // save the code address
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            sstore(slot, contractLogic)
        }
        // save the proxy admin
        slot = PROXY_ADMIN_SLOT;
        address sender = proxyAdmin;
        assembly {
            sstore(slot, sender)
        }
    }

    function updateAdmin(address _newAdmin) public {
        require(
            msg.sender == getAdmin(),
            "Only the current admin should be able to new admin"
        );
        bytes32 slot = PROXY_ADMIN_SLOT;
        assembly {
            sstore(slot, _newAdmin)
        }
    }

    /// @author Marlin
    /// @dev Only admin can update the contract
    /// @param _newLogic address is the address of the contract that has to updated to
    function updateLogic(address _newLogic) public {
        require(
            msg.sender == getAdmin(),
            "Only Admin should be able to update the contracts"
        );
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            sstore(slot, _newLogic)
        }
    }

    /// @author Marlin
    /// @dev use assembly as contract store slot is manually decided
    function getAdmin() internal view returns (address result) {
        bytes32 slot = PROXY_ADMIN_SLOT;
        assembly {
            result := sload(slot)
        }
    }

    /// @author Marlin
    /// @dev add functionality to forward the balance as well.
    function() external payable {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            let contractLogic := sload(slot)
            calldatacopy(0x0, 0x0, calldatasize())
            let success := delegatecall(
                sub(gas(), 10000),
                contractLogic,
                0x0,
                calldatasize(),
                0,
                0
            )
            let retSz := returndatasize()
            returndatacopy(0, 0, retSz)

            switch success
                case 0 {
                    revert(0, retSz)
                }
                default {
                    return(0, retSz)
                }
        }
    }
}