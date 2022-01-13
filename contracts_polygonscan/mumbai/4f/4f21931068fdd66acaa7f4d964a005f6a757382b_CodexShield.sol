/**
 *Submitted for verification at polygonscan.com on 2022-01-12
*/

// Verified by Darwinia Network

// hevm: flattened sources of src/codex/codex-shield.sol

pragma solidity >=0.6.7 <0.7.0;
pragma experimental ABIEncoderV2;

////// src/codex/codex-shield.sol
/* pragma solidity ^0.6.7; */
/* pragma experimental ABIEncoderV2; */

contract CodexShield {
    string constant public index = "Equipment";
    string constant public class = "Shield";

    bytes32 public constant CONTRACT_ELEMENT_TOKEN = "CONTRACT_ELEMENT_TOKEN";
    bytes32 public constant CONTRACT_LP_ELEMENT_TOKEN = "CONTRACT_LP_ELEMENT_TOKEN";

    struct shield {
        uint256 id;
        uint256[] materials;
        uint256[] mcosts;
        uint256 ecost;
        uint256 srate;
        string name;
    }

    function obj_by_rarity(uint rarity) public pure returns (shield memory _s) {
        if (rarity == 1) {
            return shield1();
        } else if (rarity == 2) {
            return shield2();
        } else if (rarity == 3) {
            return shield3();
        }
    }

    function shield1() public pure returns (shield memory _s) {
        _s.id = 1;
        _s.name = "Wooden Shield, normal";
        _s.materials = new uint256[](2);
        _s.materials[0] = 1;
        _s.materials[1] = 4;
        _s.mcosts = new uint256[](2);
        _s.mcosts[0] = 100;
        _s.mcosts[1] = 30;
        _s.ecost = 80e18;
        _s.srate = 90;
    }

    function shield2() public pure returns (shield memory _s) {
        _s.id = 2;
        _s.name = "Steel Shield, rare";
        _s.materials = new uint256[](2);
        _s.materials[0] = 1;
        _s.materials[1] = 4;
        _s.mcosts = new uint256[](2);
        _s.mcosts[0] = 200;
        _s.mcosts[1] = 60;
        _s.ecost = 160e18;
        _s.srate = 60;
    }

    function shield3() public pure returns (shield memory _s) {
        _s.id = 3;
        _s.name = "Aurora Shield, epic";
        _s.materials = new uint256[](2);
        _s.materials[0] = 2;
        _s.materials[1] = 5;
        _s.mcosts = new uint256[](2);
        _s.mcosts[0] = 100;
        _s.mcosts[1] = 30;
        _s.ecost = 320e18;
        _s.srate = 30;
    }

    struct formula {
        bytes32 minor;
        uint256 cost;
        uint256 srate;
        uint256 lrate;
    }

    function formula_by_class(uint id) public pure returns (formula memory _f) {
        if (id == 0) {
            return formula0();
        } else if (id == 1) {
            return formula1();
        }
    }

    function formula0() public pure returns (formula memory _f) {
        _f.minor = CONTRACT_ELEMENT_TOKEN;
        _f.cost = 400e18;
        _f.srate = 100;
        _f.lrate = 50;
    }

    function formula1() public pure returns (formula memory _f) {
        _f.minor = CONTRACT_LP_ELEMENT_TOKEN;
        _f.cost = 800e18;
        _f.srate = 100;
        _f.lrate = 50;
    }
}