/**
 *Submitted for verification at BscScan.com on 2021-10-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

/// @notice MappingIDs storage for Tangle
/// @dev This is a Diamond Storage implementation described in EIP-2535.
library SLib {

    enum MappingIDCutAction {Add, Replace, Remove}
    struct S {
        string[] names;
        mapping(string => uint) nameIndex;
        mapping(string => string) ids;
    }
    struct MappingIDCut_ {
        MappingIDCutAction action;
        string name;
        string id;
    }
    /// @notice Records all mappingId changes
    event MappingIDCut(MappingIDCut_[] mappingIdCuts);

    function getS() internal pure returns (S storage s) {
        bytes32 storagePosition = keccak256("Tangle.MappingIDs");
        assembly { s.slot := storagePosition }
    }

}

/// @title MappingIDs for Tangle
/// @author Brad Brown
/// @notice Stores and provides information related to Tangle's Mapping IDs
contract MappingIDs {

    mapping(bytes4 => address) private _0;
    address private owner;

    function addMappingId(SLib.MappingIDCut_ memory cut) internal {
        SLib.S storage s = SLib.getS();
        require(!nameExists(cut.name), "mappingId add");
        s.nameIndex[cut.name] = s.names.length;
        s.names.push(cut.name);
        s.ids[cut.name] = cut.id;
    }

    function removeMappingId(SLib.MappingIDCut_ memory cut) internal {
        SLib.S storage s = SLib.getS();
        require(nameExists(cut.name), "mappingId remove");
        string memory lastName = s.names[s.names.length - 1];
        if (keccak256(bytes(lastName)) != keccak256(bytes(cut.name))) {
            s.nameIndex[lastName] = s.nameIndex[cut.name];
            s.names[s.nameIndex[cut.name]] = lastName;
        }
        s.nameIndex[cut.name] = 0;
        s.names.pop();
        s.ids[cut.name] = "";
    }

    function replaceMappingId(SLib.MappingIDCut_ memory cut) internal {
        SLib.S storage s = SLib.getS();
        bytes32 cutIdHash = keccak256(bytes(cut.id));
        bytes32 currentIdHash = keccak256(bytes(s.ids[cut.name]));
        require(cutIdHash != currentIdHash, "mappingId replace");
        s.ids[cut.name] = cut.id;
    }

    function nameExists(string memory name) internal view returns (bool) {
        SLib.S storage s = SLib.getS();
        if (s.names.length == 0)
            return false;
        if (
            s.nameIndex[name] > 0 ||
            keccak256(bytes(s.names[0])) == keccak256(bytes(name))
        )
            return true;
        return false;
    }

    /// @notice Add/change/remove any number of mapping IDs
    /// @param mappingIdCuts Contains the splits and which add/change/remove
    /// action will be used
    function mappingIdCut(
        SLib.MappingIDCut_[] calldata mappingIdCuts
    ) external {
        require(msg.sender == owner, "mappingIdCut");
        bool changesMade = false;
        for (uint i = 0; i < mappingIdCuts.length; i++) {
            SLib.MappingIDCut_ memory mappingIdCut_ = mappingIdCuts[i];
            if (mappingIdCut_.action == SLib.MappingIDCutAction.Add) {
                addMappingId(mappingIdCut_);
                if (!changesMade) changesMade = true;
            }
            if (mappingIdCut_.action == SLib.MappingIDCutAction.Replace) {
                replaceMappingId(mappingIdCut_);
                if (!changesMade) changesMade = true;
            }
            if (mappingIdCut_.action == SLib.MappingIDCutAction.Remove) {
                removeMappingId(mappingIdCut_);
                if (!changesMade) changesMade = true;
            }
        }
        if (changesMade) emit SLib.MappingIDCut(mappingIdCuts);
    }
    
    /// @notice Gets all mapping IDs
    /// @return A list of all mapping names and their respective IDs
    function mappingIds() 
        external 
        view 
        returns (string[][] memory) 
    {
        SLib.S storage s = SLib.getS();
        string[][] memory mappings = new string[][](s.names.length);
        for (uint i = 0; i < s.names.length; i++) {
            string[] memory mapping_ = new string[](2);
            mapping_[0] = s.names[i];
            mapping_[1] = s.ids[s.names[i]];
            mappings[i] = mapping_;
        }
        return mappings;
    }
    
    /// @notice Gets a mapping id from a mapping name
    /// @param name The mapping's name
    /// @return The ID of the mapping
    function getId(string memory name) 
        external 
        view 
        returns (string memory)
    {
        SLib.S storage s = SLib.getS();
        return s.ids[name];
    }

}