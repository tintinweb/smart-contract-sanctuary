// contracts/DataTypesV2.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract DataTypesV2 {
    uint256 private x;
    string[] private dataTypes;

    // Emitted when the stored data types change
    event ValueChanged(uint256 newValue);

    // Stores the new data types in the contract
    function setDataTypes(uint256 _x) public {
        dataTypes = [
            "1"
        ];
        //emit ValueChanged(dataTypes);
    }

    function retrieveDataTypes() public view returns (string[] memory) {
        return dataTypes;
    }
}