pragma solidity ^0.5.0;

import "./Ownable.sol";


/// @title Upgradeable contract
/// @author growlot (@growlot)
contract Upgradeable is Ownable {
    /// @notice Storage position of the current implementation address.
    /// @dev The address of the current implementation is stored in a
    /// constant pseudorandom slot of the contract proxy contract storage
    /// (slot number obtained as a result of hashing a certain message),
    /// the probability of rewriting which is almost zero
    bytes32 private constant implementationPosition = keccak256(
        "implementation"
    );

    /// @notice Contract constructor
    /// @dev Calls Ownable contract constructor
    constructor() public Ownable() {}

    /// @notice Returns the current implementation contract address
    function getImplementation() public view returns (address implementation) {
        bytes32 position = implementationPosition;
        assembly {
            implementation := sload(position)
        }
    }

    /// @notice Sets new implementation contract address as current
    /// @param _newImplementation New implementation contract address
    function setImplementation(address _newImplementation) public {
        requireOwner();
        require(_newImplementation != address(0), "New implementation must have non-zero address");
        address currentImplementation = getImplementation();
        require(currentImplementation != _newImplementation, "New implementation must have new address");
        bytes32 position = implementationPosition;
        assembly {
            sstore(position, _newImplementation)
        }
    }

    /// @notice Sets new implementation contract address and call its initializer.
    /// @dev New implementation call is a low level delegatecall.
    /// @param _newImplementation the new implementation address.
    /// @param _newImplementaionCallData represents the msg.data to bet sent through the low level delegatecall.
    /// This parameter may include the initializer function signature with the needed payload.
    function setImplementationAndCall(
        address _newImplementation,
        bytes calldata _newImplementaionCallData
    ) external payable {
        setImplementation(_newImplementation);
        if (_newImplementaionCallData.length > 0) {
            (bool success, ) = address(this).call.value(msg.value)(
                _newImplementaionCallData
            );
            require(success, "Delegatecall has failed");
        }
    }
}
