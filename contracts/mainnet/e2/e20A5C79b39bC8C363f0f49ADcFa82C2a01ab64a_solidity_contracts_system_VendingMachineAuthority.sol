pragma solidity 0.5.17;

/// @title  Vending Machine Authority.
/// @notice Contract to secure function calls to the Vending Machine.
/// @dev    Secured by setting the VendingMachine address and using the
///         onlyVendingMachine modifier on functions requiring restriction.
contract VendingMachineAuthority {
    address internal VendingMachine;

    constructor(address _vendingMachine) public {
        VendingMachine = _vendingMachine;
    }

    /// @notice Function modifier ensures modified function caller address is the vending machine.
    modifier onlyVendingMachine() {
        require(msg.sender == VendingMachine, "caller must be the vending machine");
        _;
    }
}
