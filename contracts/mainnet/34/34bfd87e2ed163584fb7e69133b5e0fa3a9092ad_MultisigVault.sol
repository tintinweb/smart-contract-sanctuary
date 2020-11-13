// File: contracts/IMultisigCarrier.sol

pragma solidity ^0.5.0;

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract IMultisigCarrier {

    function approveFrom(
        address caller,
        address payable destination,
        address currencyAddress,
        uint256 amount
    ) public returns (bool);

}

// File: contracts/MultisigVault.sol

pragma solidity ^0.5.0;


contract MultisigVault {

    address private _carrier;

    constructor() public {
        _carrier = msg.sender;
    }

    function owner() public view returns (address) {
        return _carrier;
    }

    function approve(
        address payable destination,
        address currencyAddress,
        uint256 amount
    ) public returns (bool) {
        IMultisigCarrier multisigCarrier = IMultisigCarrier(_carrier);
        return multisigCarrier.approveFrom(msg.sender, destination, currencyAddress, amount);
    }

    function external_call(address destination, uint value, bytes memory data) public returns (bool) {
        require(msg.sender == _carrier, "Ownable: caller is not the owner");

        bool result;
        assembly {
            let dataLength := mload(data)
            let d := add(data, 32) // First 32 bytes are the padded length of data, so exclude that
            result := call(
                sub(gas(), 34710),   // 34710 is the value that solidity is currently emitting
                                   // It includes callGas (700) + callVeryLow (3, to pay for SUB) + callValueTransferGas (9000) +
                                   // callNewAccountGas (25000, in case the destination address does not exist and needs creating)
                destination,
                value,
                d,
                dataLength,        // Size of the input (in bytes) - this is what fixes the padding problem
                0,
                0                  // Output is ignored, therefore the output size is zero
            )
        }
        return result;
    }


    function () external payable {}
}