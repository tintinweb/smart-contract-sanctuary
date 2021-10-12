/**
 *Submitted for verification at BscScan.com on 2021-10-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

/// @notice Storage for the Tangle Contract
/// @dev This is a Diamond Storage implementation described in EIP-2535.
library SLib {
    
    enum SplitCutAction {Add, Replace, Remove}
    struct S {
        address[] addresses;
        mapping(address => uint) addressIndex;
        mapping(address => Split) splits;
    }
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
    struct Split {
        address to;
        uint16 numerator;
        uint16 denominator;
    }
    struct SplitCut_ {
        SplitCutAction action;
        Split split;
    }
    /// @notice Records all split changes
    event SplitCut(SplitCut_[] splitCuts);
    /// @notice Records all transfers
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    function getS() internal pure returns (S storage s) {
        bytes32 storagePosition = keccak256("Tangle.TaxMan");
        assembly {s.slot := storagePosition}
    }
    
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

}

/// @title TaxMan, handles all Tangle taxes
/// @author Brad Brown
/// @notice Allows adding/changing/removing of any taxes, provides
/// information about current taxes, and holds the tax function
/// used in Tangle transfers.
contract TaxMan {
    
    mapping(bytes4 => address) private _0;
    address private owner;

    /// @notice Taxes a Tangle transfer, routes taxes and
    /// reduces transfer value by each tax amount routed
    /// @param value The value of Tangle being transferred
    /// @return The post-tax transfer value
    function tax(address from, uint value)
        external
        returns (uint)
    {
        require(msg.sender == address(this), "internal");
        uint preTaxValue = value;
        if (value == 0) return value;
        SLib.S storage s = SLib.getS();
        SLib.SBalances storage sBalances = SLib.getSBalances(getMappingId("balances"));
        for (uint i = 0; i < s.addresses.length; i++) {
            SLib.Split memory split = s.splits[s.addresses[i]];
            uint numerator = split.numerator;
            uint denominator = split.denominator;
            uint splitAmount = preTaxValue * numerator / denominator;
            sBalances.balances[split.to] += unitsToPieces(splitAmount);
            value -= splitAmount;
            emit SLib.Transfer(from, split.to, splitAmount);
        }
        return value;
    }

    function unitsToPieces(uint units) internal view returns (uint) {
        return units * SLib.getSInfo().piecesPerUnit;
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
    
    function addSplit(SLib.Split memory split) internal {
        SLib.S storage s = SLib.getS();
        require(!splitExists(split.to), "split add");
        s.addressIndex[split.to] = s.addresses.length;
        s.addresses.push(split.to);
        s.splits[split.to] = split;
    }

    function removeSplit(SLib.Split memory split) internal {
        SLib.S storage s = SLib.getS();
        require(splitExists(split.to), "split remove");
        address lastAddress = s.addresses[s.addresses.length - 1];
        if (lastAddress != split.to) {
            s.addressIndex[lastAddress] = s.addressIndex[split.to];
            s.addresses[s.addressIndex[split.to]] = lastAddress;
        }
        s.addresses.pop();
        s.addressIndex[split.to] = 0;
        s.splits[split.to] = SLib.Split(address(0),0,0);
    }

    function replaceSplit(SLib.Split memory split) internal {
        SLib.S storage s = SLib.getS();
        SLib.Split memory currentSplit = s.splits[split.to];
        bool numsEqual = split.numerator == currentSplit.numerator;
        bool denomsEqual = split.denominator == currentSplit.denominator;
        require(
            splitExists(split.to) &&
            (!numsEqual || !denomsEqual),
            "split replace"
        );
        s.splits[split.to] = split;
    }

    function splitExists(address  address_) internal view returns (bool) {
        SLib.S storage s = SLib.getS();
        if (s.addresses.length == 0)
            return false;
        if (
            s.addressIndex[address_] > 0 ||
            s.addresses[0] == address_
        )
            return true;
        return false;
    }

    /// @notice Add/change/remove any number of splits
    /// @param splitCuts Contains the splits and which add/change/remove
    /// action will be used
    function splitCut(SLib.SplitCut_[] calldata splitCuts) external {
        require(msg.sender == owner, "splitCut");
        bool changesMade = false;
        for (uint i = 0; i < splitCuts.length; i++) {
            SLib.SplitCut_ memory splitCut_ = splitCuts[i];
            SLib.Split memory split = splitCut_.split;
            if (splitCut_.action == SLib.SplitCutAction.Add) {
                addSplit(split);
                if (!changesMade) changesMade = true;
            }
            if (splitCut_.action == SLib.SplitCutAction.Replace) {
                replaceSplit(split);
                if (!changesMade) changesMade = true;
            }
            if (splitCut_.action == SLib.SplitCutAction.Remove) {
                removeSplit(split);
                if (!changesMade) changesMade = true;
            }
        }
        if (changesMade) emit SLib.SplitCut(splitCuts);
    }
    
    /// @notice Gets all splits and their address, numerator, and denominator
    /// @return All splits and their address, numerator, and denominator
    function splits() external view returns (SLib.Split[] memory) {
        SLib.S storage s = SLib.getS();
        SLib.Split[] memory splits_ = new SLib.Split[](s.addresses.length);
        for (uint i = 0; i < s.addresses.length; i++) {
            splits_[i] = s.splits[s.addresses[i]];
        }
        return splits_;
    }

}