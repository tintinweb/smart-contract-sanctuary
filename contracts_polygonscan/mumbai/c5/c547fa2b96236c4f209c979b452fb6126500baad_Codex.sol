/**
 *Submitted for verification at polygonscan.com on 2022-01-12
*/

// Verified by Darwinia Network

// hevm: flattened sources of src/Codex.sol

pragma solidity >=0.6.7 <0.7.0;

////// src/Codex.sol

/* pragma solidity ^0.6.7; */

contract Codex {
    uint256 private constant _CLEAR_HIGH = 0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff;
    string public constant class = "Material";

    function name(uint256 tokenId) public pure returns(bytes memory) {
        uint128 id = uint128(tokenId & _CLEAR_HIGH);
        if (id == 1) {
            return "Junior Monster Bone";
        } else if (id == 2) {
            return "Intermediate Monster Bone";
        } else if (id == 3) {
            return "Senior Monster Bone";
        } else if (id == 4) {
            return "Junior Monster Spirit";
        } else if (id == 5) {
            return "Intermediate Monster Spirit";
        } else if (id == 6) {
            return "Senior Monster Spirit";
        }
    }
}