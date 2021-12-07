// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract codex {
    string constant public index = "Feats";
    string constant public class = "Any";

    function feat_by_id(uint _id) external pure returns(
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        if (_id == 66) {
            return improved_sunder();
        } else if (_id == 67) {
            return improved_trip();
        }
    }

    function improved_sunder() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 66;
        name = "Improved Sunder";
        prerequisites = true;
        prequisite_feat = 13;
        preprequisite_class = 2047;
        prequisite_level = 0;
        benefit = "When you strike at an object held or carried by an opponent (such as a weapon or shield), you do not provoke an attack of opportunity. You also gain a +4 bonus on any attack roll made to attack an object held or carried by another character.";
    }

    function improved_trip() public pure returns (
        uint id,
        string memory name,
        bool prerequisites,
        uint prequisite_feat,
        uint preprequisite_class,
        uint prequisite_level,
        string memory benefit
    ) {
        id = 67;
        name = "Improved Trip";
        prerequisites = true;
        prequisite_feat = 16;
        preprequisite_class = 2047;
        prequisite_level = 0;
        benefit = "You do not provoke an attack of opportunity when you attempt to trip an opponent while you are unarmed. You also gain a +4 bonus on your Strength check to trip your opponent. If you trip an opponent in melee combat, you immediately get a melee attack against that opponent as if you hadnt used your attack for the trip attempt.";
    }
}