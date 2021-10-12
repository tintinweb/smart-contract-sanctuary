/**
 *Submitted for verification at BscScan.com on 2021-10-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

/// @notice Transferrer storage for Tangle
/// @dev This is a Diamond Storage implementation described in EIP-2535.
library SLib {
    
    struct SInfo {
        string _0;
        string _1;
        uint8 _2;
        uint _3;
        uint piecesPerUnit;
    }
    struct SBalances {
        mapping(address => uint) balances;
        bool _0;
    }
    struct SAllowances {
        mapping(address => mapping(address => uint)) allowances;
    }
    /// @notice Records all transfers
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
    function getSInfo() internal pure returns (SInfo storage s) {
        bytes32 storagePosition = keccak256("Tangle.Info");
        assembly { s.slot := storagePosition }
    }

    function getSBalances(
        string memory id
    ) internal pure returns (SBalances storage s) {
        bytes32 storagePosition = keccak256(bytes(id));
        assembly { s.slot := storagePosition }
    }

    function getSAllowances(
        string memory id
    ) internal pure returns (SAllowances storage s) {
        bytes32 storagePosition = keccak256(bytes(id));
        assembly { s.slot := storagePosition }
    }

}

/// @title Transferrer, handles Tangle transfers
/// @author Brad Brown
/// @notice Contains the transfer and transferFrom functions for Tangle
contract Transferrer {

    mapping(bytes4 => address) private _0;
    address private owner;

    /// @notice Transfers Tangle from one holder to another, may implement a
    /// variable number of taxes and may modify the amount transferred
    /// @dev Modifies the value transferred according to the pre and tax
    /// Transformers (external implementations)
    /// @param _to The address Tangle will be sent to
    /// @param value The amount of Tangle sent
    /// @return Whether or not the transfer was successful
    function transfer(address _to, uint value) external returns (bool) {
        value = preTransform(msg.sender, value);
        _transfer(msg.sender, _to, value);
        return true;
    }

    /// @notice Transfers Tangle from one holder to another, may implement a
    /// variable number of taxes and may modify the amount transferred. Can be
    /// initiated by an approved 3rd party
    /// @dev Modifies the value transferred according to the pre and tax
    /// Transformers, which are implementation.
    /// @param _from The address Tangle will be sent from
    /// @param _to The address Tangle will be sent to
    /// @param value The amount of Tangle sent
    /// @return Whether or not the transfer was successful
    function transferFrom(address _from, address _to, uint value)
        external
        returns
    (bool) {
        value = preTransform(_from, value);
        SLib.SAllowances storage s = SLib.getSAllowances(getMappingId("allowances"));
        s.allowances[_from][msg.sender] -= value;
        _transfer(_from, _to, value);
        return true;
    }

    function _transfer(address spender, address receiver, uint value)
        internal
    {
        SLib.SBalances storage s = SLib.getSBalances(getMappingId("balances"));
        s.balances[spender] -= unitsToPieces(value);
        value = tax(spender, value);
        s.balances[receiver] += unitsToPieces(value);
        emit SLib.Transfer(spender, receiver, value);
        executePostTransferHooks(spender, receiver, value);
    }

    function unitsToPieces(uint units) internal view returns (uint) {
        return units * SLib.getSInfo().piecesPerUnit;
    }

    function preTransform(address sender, uint value)
        internal
        view
        returns (uint)
    {
        (bool success, bytes memory result) = address(this).staticcall(
            abi.encodeWithSignature(
                "preTransform(address,uint256)",
                sender,
                value
            )
        );
        if (success) value = uint(bytes32(result));
        return value;
    }

    function tax(address sender, uint value)
        internal
        returns (uint)
    {
        (bool success, bytes memory result) = address(this).call(
            abi.encodeWithSignature(
                "tax(address,uint256)",
                sender,
                value
            )
        );
        if (success) value = uint(bytes32(result));
        return value;
    }

    function executePostTransferHooks(
        address sender,
        address receiver,
        uint value
    ) internal {
        (bool success,) = address(this).call(
            abi.encodeWithSignature(
                "executePostTransferHooks(address,address,uint256)",
                sender,
                receiver,
                value
            )
        );
        require(success, "executePostTransferHooks");
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
        require(success, "getMappingId transferrer");
        assembly { id := add(result, 0x40) }
    }

}