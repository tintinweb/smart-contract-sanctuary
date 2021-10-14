/**
 *Submitted for verification at BscScan.com on 2021-10-14
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract codex {
    string constant public index = "Base";
    string constant public class = "Random";

    function d100(uint _summoner) external view returns (uint) {
        return dn(_summoner, 100);
    }

    function d20(uint _summoner) external view returns (uint) {
        return dn(_summoner, 20);
    }

    function d12(uint _summoner) external view returns (uint) {
        return dn(_summoner, 12);
    }

    function d10(uint _summoner) external view returns (uint) {
        return dn(_summoner, 10);
    }

    function d8(uint _summoner) external view returns (uint) {
        return dn(_summoner, 8);
    }

    function d6(uint _summoner) external view returns (uint) {
        return dn(_summoner, 6);
    }

    function d4(uint _summoner) external view returns (uint) {
        return dn(_summoner, 4);
    }

    function dn(uint _summoner, uint _number) public view returns (uint) {
        return _seed(_summoner) % _number;
    }

    function _random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function _seed(uint _summoner) internal view returns (uint rand) {
        rand = _random(
            string(
                abi.encodePacked(
                    block.timestamp,
                    blockhash(block.number - 1),
                    _summoner,
                    msg.sender
                )
            )
        );
    }
}