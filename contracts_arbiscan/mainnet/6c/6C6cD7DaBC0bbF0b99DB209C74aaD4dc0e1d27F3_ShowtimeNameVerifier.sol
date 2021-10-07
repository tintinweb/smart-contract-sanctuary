// SPDX-License-Identifier: MIT
pragma solidity 0.6.9;

import "./IIdeaTokenNameVerifier.sol";

/**
 * @title ShowtimeNameVerifier
 * @author Alexander Schlindwein
 *
 * Verifies a string to be a Showtime name: tryshowtime.com/<the name>
 * Allowed characters are a-z (lowercase), 0-9 and _
 * Mininum length 2, Maximum length 42.
 */
contract ShowtimeNameVerifier is IIdeaTokenNameVerifier {
    /**
     * Verifies whether a string matches the required format
     *
     * @param name The input string (Showtime name)
     *
     * @return Bool; True=matches, False=does not match
     */
    function verifyTokenName(string calldata name) external pure override returns (bool) {
        bytes memory b = bytes(name);
        if(b.length < 2 || b.length > 42) {
            return false;
        }

        for(uint i = 0; i < b.length; i++) {
            bytes1 char = b[i];
            if (!(char >= 0x61 && char <= 0x7A) && // a-z
                !(char >= 0x30 && char <= 0x39) && // 0-9
                !(char == 0x5F)) {                 // _
                return false;
            }
        }

        return true;
    }
}