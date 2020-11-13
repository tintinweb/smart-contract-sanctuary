// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "./Controllable.sol";

contract Randomizable is Controllable {
    uint256 private randNonce = 0;

    function getPseudoRand(uint256 modulus) internal returns (uint256) {
        randNonce = randNonce.add(1);
        return
            uint256(keccak256(abi.encodePacked(now, _msgSender(), randNonce))) %
            modulus;
    }
}
