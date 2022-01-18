// SPDX-License-Identifier: MIT
pragma solidity 0.6.9;

import "./IIdeaTokenNameVerifier.sol";

/**
 * @title TwitterHandleNameVerifier
 * @author Kelton Madden
 *
 * Verifies a string to be a Minds handle: @ followed by 1-15 letters or numbers including "_". Letters may be upper and lowercase.
 * String must be at least 5 characters long and less than 129 characters
 */
contract MindsNameVerifier is IIdeaTokenNameVerifier {
    /**
     * Verifies whether a string matches the required format
     *
     * @param name The input string (Minds handle)
     *
     * @return Bool; True=matches, False=does not match
     */
    function verifyTokenName(string calldata name) external pure override returns (bool) {
        bytes memory b = bytes(name);
        if(b.length < 5 || b.length > 129) {
            return false;
        }

        if(b[0] != 0x40) { // @
            return false;
        }

        for(uint i = 1; i < b.length; i++) {
            bytes1 char = b[i];
            if (!(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A) && //a-z
                !(char == 0x5F)) { //_
                
                return false;
            }
        }

        return true;
    }
}