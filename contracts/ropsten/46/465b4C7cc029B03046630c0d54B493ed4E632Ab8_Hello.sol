pragma solidity 0.6.12;
contract Hello{
    /// @notice Platform fee
    uint256 public platformFee;

    /// @notice Platform fee receipient
    address payable public feeReceipient;

    constructor(
        address payable _feeRecipient,
        uint256 _platformFee
    ) public {
        platformFee = _platformFee;
        feeReceipient = _feeRecipient;
    }

}