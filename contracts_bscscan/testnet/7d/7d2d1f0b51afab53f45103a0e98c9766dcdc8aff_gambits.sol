/**
 *Submitted for verification at BscScan.com on 2021-10-01
*/

/**
 *Submitted for verification at FtmScan.com on 2021-09-21
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

contract gambits {
    string constant public index = "Gambits";
    string constant public class = "Any";
    
    function gambit_by_id(uint _id) external pure returns (uint id, uint8 target, string memory description) {
        if (_id == 1) {
            return (_id, 0, "Ally: lowest HP");
        } else if (_id == 2) {
            return (_id, 0, "Ally: highest damage");
        } else if (_id == 3) {
            return (_id, 0, "Ally: lowest AC");
        } else if (_id == 4) {
            return (_id, 0, "Ally: HP < 100%");
        } else if (_id == 5) {
            return (_id, 0, "Ally: HP < 90%");
        } else if (_id == 6) {
            return (_id, 0, "Ally: HP < 80%");
        } else if (_id == 7) {
            return (_id, 0, "Ally: HP < 70%");
        } else if (_id == 8) {
            return (_id, 0, "Ally: HP < 60%");
        } else if (_id == 9) {
            return (_id, 0, "Ally: HP < 50%");
        } else if (_id == 10) {
            return (_id, 0, "Ally: HP < 40%");
        } else if (_id == 11) {
            return (_id, 0, "Ally: HP < 30%");
        } else if (_id == 12) {
            return (_id, 0, "Ally: HP < 20%");
        } else if (_id == 13) {
            return (_id, 0, "Ally: HP < 10%");
        } else if (_id == 14) {
            return (_id, 0, "Ally: Status: Stone");
        } else if (_id == 15) {
            return (_id, 0, "Ally: Status: Petrify");
        } else if (_id == 16) {
            return (_id, 0, "Ally: Status: Stop");
        } else if (_id == 17) {
            return (_id, 0, "Ally: Status: Sleep");
        } else if (_id == 18) {
            return (_id, 0, "Ally: Status: Confuse");
        } else if (_id == 19) {
            return (_id, 0, "Ally: Status: Blind");
        } else if (_id == 20) {
            return (_id, 0, "Ally: Status: Poison");
        } else if (_id == 21) {
            return (_id, 0, "Ally: Status: Silence");
        } else if (_id == 22) {
            return (_id, 0, "Ally: Status: Immobilize");
        } else if (_id == 23) {
            return (_id, 0, "Ally: Status: Slow");
        } else if (_id == 24) {
            return (_id, 0, "Ally: Status: Disease");
        } else if (_id == 25) {
            return (_id, 0, "Ally: Status:  Berserk");
        } else if (_id == 26) {
            return (_id, 0, "Ally: Status: HP Critical");
        } else if (_id == 27) {
            return (_id, 1, "Foe: any");
        } else if (_id == 28) {
            return (_id, 1, "Foe: targeted by ally");
        } else if (_id == 29) {
            return (_id, 1, "Foe: not targeted by ally");
        } else if (_id == 30) {
            return (_id, 1, "Foe: targeting self");
        } else if (_id == 31) {
            return (_id, 1, "Foe: targeting ally");
        } else if (_id == 32) {
            return (_id, 1, "Foe: highest HP");
        } else if (_id == 33) {
            return (_id, 1, "Foe: lowest HP");
        } else if (_id == 34) {
            return (_id, 1, "Foe: highest max HP");
        } else if (_id == 35) {
            return (_id, 1, "Foe: highest level");
        } else if (_id == 36) {
            return (_id, 1, "Foe: lowest level");
        } else if (_id == 37) {
            return (_id, 1, "Foe: highest damage");
        } else if (_id == 38) {
            return (_id, 1, "Foe: lowest damage");
        } else if (_id == 39) {
            return (_id, 1, "Foe: highest AC");
        } else if (_id == 40) {
            return (_id, 1, "Foe: lowest AC");
        } else if (_id == 41) {
            return (_id, 1, "Foe: HP = 100%");
        } else if (_id == 42) {
            return (_id, 1, "Foe: HP >= 90%");
        } else if (_id == 43) {
            return (_id, 1, "Foe: HP >= 70%");
        } else if (_id == 44) {
            return (_id, 1, "Foe: HP >= 50%");
        } else if (_id == 45) {
            return (_id, 1, "Foe: HP >= 30%");
        } else if (_id == 46) {
            return (_id, 1, "Foe: HP >= 10%");
        } else if (_id == 47) {
            return (_id, 1, "Foe: Status: Petrify");
        } else if (_id == 47) {
            return (_id, 1, "Foe: Status: Stop");
        } else if (_id == 47) {
            return (_id, 1, "Foe: Status: Sleep");
        } else if (_id == 47) {
            return (_id, 1, "Foe: Status: Confuse");
        } else if (_id == 47) {
            return (_id, 1, "Foe: Status: Blind");
        } else if (_id == 47) {
            return (_id, 1, "Foe: Status: Poison");
        } else if (_id == 47) {
            return (_id, 1, "Foe: Status: Silence");
        } else if (_id == 47) {
            return (_id, 1, "Foe: Status: Immobilize");
        } else if (_id == 47) {
            return (_id, 1, "Foe: Status: Slow");
        } else if (_id == 47) {
            return (_id, 1, "Foe: Status: Disease");
        } else if (_id == 47) {
            return (_id, 1, "Foe: Status: Protect");
        } else if (_id == 47) {
            return (_id, 1, "Foe: Status: Shell");
        } else if (_id == 47) {
            return (_id, 1, "Foe: Status: Haste");
        } else if (_id == 47) {
            return (_id, 1, "Foe: Status: Bravery");
        } else if (_id == 47) {
            return (_id, 1, "Foe: Status: Faith");
        } else if (_id == 47) {
            return (_id, 1, "Foe: Status: Reflect");
        } else if (_id == 47) {
            return (_id, 1, "Foe: Status: Regen");
        } else if (_id == 48) {
            return (_id, 1, "Foe: Status: Berserk");
        } else if (_id == 49) {
            return (_id, 1, "Foe: Status: HP Critical");
        } else if (_id == 50) {
            return (_id, 2, "Self: HP < 100%");
        } else if (_id == 51) {
            return (_id, 2, "Self: HP < 90%");
        } else if (_id == 52) {
            return (_id, 2, "Self: HP < 80%");
        } else if (_id == 53) {
            return (_id, 2, "Self: HP < 70%");
        } else if (_id == 54) {
            return (_id, 2, "Self: HP < 60%");
        } else if (_id == 55) {
            return (_id, 2, "Self: HP < 50%");
        } else if (_id == 56) {
            return (_id, 2, "Self: HP < 40%");
        } else if (_id == 57) {
            return (_id, 2, "Self: HP < 30%");
        } else if (_id == 58) {
            return (_id, 2, "Self: HP < 20%");
        } else if (_id == 59) {
            return (_id, 2, "Self: HP < 10%");
        } else if (_id == 60) {
            return (_id, 2, "Self: Status: Petrify");
        } else if (_id == 61) {
            return (_id, 2, "Self: Status: Blind");
        } else if (_id == 62) {
            return (_id, 2, "Self: Status: Poison");
        } else if (_id == 63) {
            return (_id, 2, "Self: Status: Silence");
        } else if (_id == 64) {
            return (_id, 2, "Self: Status: Immobilize");
        } else if (_id == 65) {
            return (_id, 2, "Self: Status: Slow");
        } else if (_id == 66) {
            return (_id, 2, "Self: Status: Disease");
        } else if (_id == 67) {
            return (_id, 2, "Self: Status: HP Critical");
        }
    }
    
}