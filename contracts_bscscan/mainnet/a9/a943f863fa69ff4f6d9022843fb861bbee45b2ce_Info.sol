/**
 *Submitted for verification at BscScan.com on 2021-10-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

/// @notice Info Storage for Tangle
/// @dev This is a Diamond Storage implementation described in EIP-2535.
library SLib {

    struct S {
        string name;
        string symbol;
        uint8 decimals;
        uint totalSupply;
        uint piecesPerUnit;
    }
    /// Records all info changes
    event InfoChange(S s);

    function getS() internal pure returns (S storage s) {
        bytes32 storagePosition = keccak256("Tangle.Info");
        assembly { s.slot := storagePosition }
    }

}

/// @title Info, the information for Tangle
/// @author Brad Brown
/// @notice This contract provides the basic information related to Tangle
contract Info {

    mapping(bytes4 => address) private _0;
    address private owner;

    function infoChange(SLib.S calldata s_) external {
        require(msg.sender == owner, "infoChange");
        SLib.S storage s = SLib.getS();
        s.name = s_.name;
        s.symbol = s_.symbol;
        s.decimals = s_.decimals;
        s.totalSupply = s_.totalSupply;
        s.piecesPerUnit = s_.piecesPerUnit;
        emit SLib.InfoChange(s_);
    }

    /// @notice Returns the name of the Tangle token
    /// @return The name of the Tangle token (ex. "Tangle")
    function name() external view returns (string memory) {
        return SLib.getS().name;
    }

    /// @notice Returns the symbol of the Tangle token
    /// @return The symbol of the Tangle token (ex. "TNGL")
    function symbol() external view returns (string memory) {
        return SLib.getS().symbol;
    }

    /// @notice Returns the decimals of the Tangle token
    /// @return The decimals of the Tangle token (ex. 9)
    function decimals() external view returns (uint8) {
        return SLib.getS().decimals;
    }

    /// @notice Returns the total supply of the Tangle token
    /// @return The total supply of the Tangle token
    /// (ex. 1,000,000,000.000000000)
    function totalSupply() external view returns (uint) {
        return SLib.getS().totalSupply;
    }

}