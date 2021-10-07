// SPDX-License-Identifier: MIT
pragma solidity 0.6.9;

import "./IIdeaTokenNameVerifier.sol";

/**
 * @title TwitterHandleNameVerifier
 * @author Alexander Schlindwein
 *
 * Verifies a string to be a Twitter handle: @ followed by 1-15 letters or numbers including "_". All lower-case.
 */
contract TwitterHandleNameVerifier is IIdeaTokenNameVerifier {
    /**
     * Verifies whether a string matches the required format
     *
     * @param name The input string (Twitter handle)
     *
     * @return Bool; True=matches, False=does not match
     */
    function verifyTokenName(string calldata name) external pure override returns (bool) {
        bytes memory b = bytes(name);
        if(b.length < 2 || b.length > 16) {
            return false;
        }

        if(b[0] != 0x40) { // @
            return false;
        }

        for(uint i = 1; i < b.length; i++) {
            bytes1 char = b[i];
            if (!(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x61 && char <= 0x7A) && //a-z
                !(char == 0x5F)) { //_
                
                return false;
            }
        }

        return true;
    }
}