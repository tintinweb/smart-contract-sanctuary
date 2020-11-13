pragma solidity ^0.5.0;


/// @title Ownable Contract
/// @author growlot (@growlot)
contract Ownable {
    /// @notice Storage position of the owner address
    /// @dev The address of the current owner is stored in a
    /// constant pseudorandom slot of the contract storage
    /// (slot number obtained as a result of hashing a certain message),
    /// the probability of rewriting which is almost zero
    bytes32 private constant _ownerPosition = keccak256("owner");

    /// @notice Storage position of the authorized new owner address
    bytes32 private constant _authorizedNewOwnerPosition = keccak256("authorizedNewOwner");

    /// @notice Contract constructor
    /// @dev Sets msg sender address as owner address
    constructor() public {
        bytes32 ownerPosition = _ownerPosition;
        address owner = msg.sender;
        assembly {
            sstore(ownerPosition, owner)
        }
    }

    /// @notice Check that requires msg.sender to be the current owner
    function requireOwner() internal view {
        require(
            msg.sender == getOwner(),
            "Sender must be owner"
        );
    }

    /// @notice Returns contract owner address
    function getOwner() public view returns (address owner) {
        bytes32 ownerPosition = _ownerPosition;
        assembly {
            owner := sload(ownerPosition)
        }
    }

    /// @notice Returns authorized new owner address
    function getAuthorizedNewOwner() public view returns (address newOwner) {
        bytes32 authorizedNewOwnerPosition = _authorizedNewOwnerPosition;
        assembly {
            newOwner := sload(authorizedNewOwnerPosition)
        }
    }

    /**
     * @notice Authorizes the transfer of ownership to the provided address.
     * NOTE: No transfer will occur unless authorizedAddress calls assumeOwnership( ).
     * This authorization may be removed by another call to this function authorizing
     * the null address.
     *
     * @param authorizedAddress The address authorized to become the new owner.
     */
    function authorizeOwnershipTransfer(address authorizedAddress) external {
        requireOwner();
        bytes32 authorizedNewOwnerPosition = _authorizedNewOwnerPosition;
        assembly {
            sstore(authorizedNewOwnerPosition, authorizedAddress)
        }
    }
    
    /**
     * @notice Transfers ownership of this contract to the authorizedNewOwner.
     */
    function assumeOwnership() external {
        bytes32 authorizedNewOwnerPosition = _authorizedNewOwnerPosition;
        address newOwner;

        assembly {
            newOwner := sload(authorizedNewOwnerPosition)
        }

        require(
            msg.sender == newOwner,
            "Only the authorized new owner can accept ownership"
        );
        
        bytes32 ownerPosition = _ownerPosition;
        address zero = address(0);

        assembly {
            sstore(ownerPosition, newOwner)
            sstore(authorizedNewOwnerPosition, zero)
        }
    }
}
