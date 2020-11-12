pragma solidity ^0.5.0;

/// @title Named Contract
/// @author growlot (@growlot)
contract NamedContract {
    /// @notice The name of contract, which can be set once
    string public name;

    /// @notice Sets contract name.
    function setContractName(string memory newName) internal {
        name = newName;
    }
}
