/**
 *Submitted for verification at BscScan.com on 2021-10-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

/// @notice Balance storage for Tangle
/// @dev This is a Diamond Storage implementation described in EIP-2535.
/// This is in a separate contract with a numbered ID because mappings cannot
/// be cleared. In the event the balances need to be reset, a new Balances
/// contract can be created without needing to redeploy other contracts.
library SLib {

    struct S {
        mapping(address => uint) balances;
        bool minted;
    }
    struct SInfo {
        string _0;
        string _1;
        uint8 _2;
        uint totalSupply;
        uint piecesPerUnit;
    }
    /// @notice Records all transfers
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    function getS() internal pure returns (S storage s) {
        bytes32 storagePosition = keccak256("Tangle.Balances0");
        assembly { s.slot := storagePosition }
    }

    function getSInfo() internal pure returns (SInfo storage s) {
        bytes32 storagePosition = keccak256("Tangle.Info");
        assembly { s.slot := storagePosition }
    }

}

/// @title Balances for Tangle
/// @author Brad Brown
/// @notice Stores and provides information related to Tangle holders'
/// balances
contract Balances {

    mapping(bytes4 => address) private _0;
    address private owner;

    /// @notice Mints the initial supply of Tangle to an address.
    /// Can only be used once.
    /// @param to The address to mint the initial supply to
    function mintOnce(address to) external {
        require(msg.sender == owner, "mintOnce owner");
        SLib.S storage s = SLib.getS();
        require(!s.minted, "mintOnce minted");
        s.minted = true;
        uint totalSupply = SLib.getSInfo().totalSupply;
        s.balances[to] = unitsToPieces(totalSupply);
        emit SLib.Transfer(address(0), to, totalSupply);
    }

    /// @notice Returns the balance of a Tangle token holder
    /// @param _owner The Tangle token holder's address
    /// @return The balance of a holder
    function balanceOf(address _owner) external view returns (uint) {
        return piecesToUnits(SLib.getS().balances[_owner]);
    }

    function piecesToUnits(uint pieces) internal view returns (uint) {
        return pieces / SLib.getSInfo().piecesPerUnit;
    }

    function unitsToPieces(uint units) internal view returns (uint) {
        return units * SLib.getSInfo().piecesPerUnit;
    }

}