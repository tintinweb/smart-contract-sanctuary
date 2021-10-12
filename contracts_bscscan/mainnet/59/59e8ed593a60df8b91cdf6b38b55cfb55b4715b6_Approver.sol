/**
 *Submitted for verification at BscScan.com on 2021-10-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

/// @notice Allowance storage for Tangle
/// @dev This is a Diamond Storage implementation described in EIP-2535.
library SLib {
    
    struct SAllowances {
        mapping(address => mapping(address => uint)) allowances;
    }
    /// @notice Records all allowancesId changes
    event AllowancesIdChange(string allowancesId);
    /// @notice Records all approvals
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    function getSAllowances(
        string memory id
    ) internal pure returns (SAllowances storage s) {
        bytes32 storagePosition = keccak256(bytes(id));
        assembly {s.slot := storagePosition}
    }

}

/// @title Approver, handles Tangle approvals
/// @author Brad Brown
/// @notice Contains the approve function for Tangle
contract Approver {
    
    mapping(bytes4 => address) private _0;
    address private owner;

    /// @notice Approves a spender to spend an amount of Tangle
    /// @param _spender The address of the spender
    /// @param _value The amount that the spender can spend
    /// @return Whether or not the approval was successful
    function approve(address _spender, uint _value) external returns (bool) {
        string memory allowancesId = getMappingId("allowances");
        SLib.SAllowances storage s = SLib.getSAllowances(allowancesId);
        s.allowances[msg.sender][_spender] = _value;
        emit SLib.Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function getMappingId(string memory name)
        internal
        view
        returns (string memory id)
    {
        (bool success, bytes memory result) = address(this).staticcall(
            abi.encodeWithSignature(
                "getId(string)",
                name
            )
        );
        require(success, "getMappingId staticdelegate");
        assembly { id := add(result, 0x40) }
    }

}