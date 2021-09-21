//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./StringUtils.sol";

library ProfanityLib {
    using strings for *;

    uint private constant one_count = 28;
    uint private constant two_count = 48;
    uint private constant three_count = 147;
    uint private constant four_count = 26;
    uint private constant color_count = 13;

    string private constant one = "shit, you're a|eat shit, you|fuck, what a|oh no, a|my partner is a|my mom is a|I'd fuck that|fuck off, you|wow, what a|baby, you're a|hey, look at the|I love my|omg u|dad, I'm a|my husband is a|mom, I'm a|ngmi, you|gm, you|shit, i'm a|my dad is a|I'm a|what a|my neighbor is a|you're a|I'm married to a|ygmi, you|my wife is a|you|i spy a";
    string private constant two = "bastardized|fancy fucking|failed|big black|kinky|rim jobbing|snowballing|sodomizing|leg spreading|cum guzzling|taint licking|wet dreaming|leaking|tea bagging|throbbing|god damn|slutty|weak ass|fucking|motherfucking|bullshitting|hot ass|nasty|naked|sexy|skanky|two bit|skanky ass|slippery|slimy|well lubed|skeezy|selfish|half assed|tight ass|lazy ass|lazy fucking|crazy ass|paper handed|diamond handed|punk ass|cheap fucking|sopping wet|dripping wet|fucking irrelevant|uneducated|dumb ass|scat munching|pindicked";
    string private constant three = "titty fucker|pussy eater|cockmuncher|shit eater|fistfucker|pegger|ass clown|fudge packer|fat ass|fuck|dickhead|shit face|wanker|douche|tit fucker|cum shot|jizz slurper|buttplug|blowjob|prickhead|squirter|vibrator|bunny fucker|deep throater|whore|face fucker|jackoff|bitch|bum fuck|pussy pounder|cock|cock cowboy|cum guzzler|cockface|dildo|sodomizer|cum fest|ass kisser|ass hole|virgin breaker|cum bubble|fingerfucker|swallower|ass blaster|sloppy slut|dick for brains|nutsack|cherry popper|crack whore|cyberfucker|numbnuts|shit stain|limp dick|snatch|cum jockey|prick|ass bagger|asshole|drip dick|donkeyribber|shit fuck|dripping cunt|sperm bag|ball licker|skin flute|soaking cunt|clit|cock sucker|cunt sucker|felcher|dripping snatch|ass muncher|orgasm|cunt|slut|fannyfucker|son of a bitch|skank|jizz face|sex slave|shit dick|dumb bitch|spready puss|bumble fuck|cock block|fat fuck|pin dick|milf|shit fucker|dilf|snowballer|fuckhead|lesbian|butthole|ass puppy|sex kitten|knob|shit can|knob jocky|ass licker|whiskey dick|boner|dick|cumshot|ass fucker|stupid fuck|anus|loose slut|ass monkey|ass hat|bastard|pussy|rimjaw|ass packer|cuntlicker|juicy snatch|dipshit|dog fucker|shithouse|pig fucker|ass jockey|ass munch|ballbag|sperm hearder|cock smoker|nobhead|ass fuck|foreskin slurper|pussy licker|dripping slut|cockhead|ballsack|cum queen|butt fucker|giant cock|carpet muncher|ass man|jerk off|scrotum|motherfucker|shit head|fist fucker|ass pirate|ass cowboy|buttmunch|breast man|cock tease|dumb fuck";
    string private constant four = "suck a dick|balls|up the ass|suck my ass|fuck em|gn, assclowns|gm shitfucks|fuck me|gm fuckers, wgmi|what a shitty nft|fucking hell|suck my titties|fuck yea... wgmi|fucking nfts|fuck you|suck me|fucking jpegs|suck my dick|eat my ass|fuck off|eat shit|fuck|titties|gm fuckheads|tits|gm assholes, wagmi|shit|jizz|ass";
    string private constant colors = "#FF0000;#FFFFFF|#ff008d;#fdff00;#00ecff;#00abff;#00ff38|#264653;#2a9d8f;#e9c46a;#f4a261;#e76f51|#1a535c;#4ecdc4;#f7fff7;#ff6b6b;#ffe66d|#FFFFFF;#000000|#EF476F;#FFD166;#FFD166;#118AB2;#073B4C|#eeeeee;#e4eaec;#ecf4f2;#e3e5e5;#ccd8d7;#EF476F|#8dbd05;#00a1ae;#5e36cc;#fe318e;#ff7540|#d00000;#ffba08;#3f88c5;#032b43;#136f63|#FF0000;#149414|#eeeeee;#CCCCCC;#999999;#666666;#333333|#ef476f;#ffd166;#06d6a0;#118ab2;#073b4c|#f72585;#7209b7;#3a0ca3;#4361ee;#4cc9f0|#FE7C00;#FFD832;#00B4AB";
    
    function random(uint max, uint seed, uint tokenId) public pure returns (uint) {
        // not really random, but since we can provide variations of the user's N as seeds it will do.
        uint randomHash = uint(keccak256(abi.encode(seed, tokenId)));
        return randomHash % max;
    }

    function getStringToken(string memory input, uint256 index) private pure returns (string memory) {
        // we need to slice up delimitted strings, because storing them all in a string array on contract is
        // cost prohibitive, whereas storing within a string is far cheaper.
        strings.slice memory s = input.toSlice();
        strings.slice memory delim = "|".toSlice();

        // just iterate and throw away anything up until our target index.
        for (uint i = 0; i <= index; i++) {
            if (i == index) {
                return s.split(delim).toString();
            } else {
                s.split(delim);
            }
        }

        return "";
    }

    function getWords(uint seedOne, uint seedTwo, uint seedThree, uint seedFour, uint tokenId) public pure returns (string memory, string memory, string memory, string memory) {
        return (
            getStringToken(one, random(one_count, seedOne, tokenId)),
            getStringToken(two, random(two_count, seedTwo, tokenId)),
            getStringToken(three, random(three_count, seedThree, tokenId)),
            getStringToken(string(abi.encodePacked(three, "|", four)), random(three_count + four_count, seedFour, tokenId))
        );
    }

    function getColorScheme(uint seed, uint tokenId) public pure returns (string memory) {
        return getStringToken(colors, random(color_count, seed, tokenId));
    }

    function getFontFace() public pure returns (string memory) {
        return '@font-face {font-family: "Early GameBoy";src: url(data:application/font-woff;base64,d09GRgABAAAAAA1QAA0AAAAAIxQAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAABGRlRNAAANNAAAABwAAAAcdMnt9kdERUYAAA0UAAAAHQAAAB4AKABgT1MvMgAAAZwAAABGAAAAYGWn/KRjbWFwAAACKAAAAO0AAAGiP83G5Gdhc3AAAA0MAAAACAAAAAj//wADZ2x5ZgAAA9AAAAVCAAAVmLCLBEhoZWFkAAABMAAAADMAAAA2EeCkpmhoZWEAAAFkAAAAHwAAACQcnxhbaG10eAAAAeQAAABCAAABaHMFBoBsb2NhAAADGAAAALYAAAC25qrhgG1heHAAAAGEAAAAGAAAACAAawB5bmFtZQAACRQAAANRAAAG3px3oa1wb3N0AAAMaAAAAKIAAADbYIRaiHicY2BkYGAAYv4ZIrfj+W2+MnCzMIDA6eCyNyD63NuXe/83/GeQZACLczAwgSgAQbALzQB4nGNgZGBgYfjPwCAryfC/gYFBkoEBKIICogBKCQMuAHicY2BkYGCIYqhgEGAAAUYGNAAAFvYA5XicTYq7DYAwEMV8H8ZAuh3okiZVBgAGygiMDOSaWHrPjTGv8rDhigLS0t8O4cdJBhgL/bpPGhG7oYPizH6eZRrIC+SnBKsAAHicY21iAAPGBgYGJiDNwsAIxDD6fwOEDcYNUIzMZyCAIXqAZgNxA5p5+PQQUkMEJsouqtknicJnRApHCAAAjc0L9QAAeJxjYGBgZoBgGQZGBhCYA+QxgvksDA1gWgAowsOgxKDFoMdgw2DPEM0Qy1DFUMNQx7BSQVJB9v9/oCoFBnUGHQYDBjsGR6BsIlRWQkHm////j//f/3/v/93/d/7f/n/r//X/1/5f/b/6ge0Da6iNOAEjGwNcCSMTkGBCVwB0OgsriMXGzsHJwMXNw8DLxy8gKCQsIiomLiHJICXNICMrJ6+gqKSsoqqmrqGppa2jq6dvYGhkbGJqxmAO1GlhaWVtY2tn7+Do5Ozi6ubu4enl7ePr5x8QyBDEEIzfgcgghFiF4RGhYcQbCwCdYzOSAAAAAAAAAAAAAAAAAAAUAC4APgCCAKYA3gDyAQABDAEqAUABZAGCAaIBwgHkAf4CKgJMAmICfgLEAuADBgMiA0gDaAOCA5gDrAPMA+QD+gQUBDYERgRkBIIEoAS+BO4FFgU6BUwFZgWIBaYF3AX4BhYGTAZeBnoGoAbABtoG8AcEByQHPAdSB2wHjgeeB7wH2gf4CBYIRghuCJIIpAi+COAI/gk0CVAJbgoiCjYKeAqICpgKsgrMCswAAHic7Vg9j+REEK22d7TsrZbFGlmr1QkhyzpdvLIsRHABP4AfQEhIQExav5eMgAx7qPequt2emeMkSGfnwzu2q+vrvapyS5NEpNFWpJV7kWEe+tQNXZKkqyZVTdLIarfgbfepHORR5DiPdtfAb9yThDfa16r8slUl4VQjlJHEe5Nu98m7k55Ms12H7kd5lqO8yHv5Tkb5KPJitnyYp36wD45zN3UH+wz2SeX80JuZq8BWU62LamPf/lvgwPaX5CQKb/wTZ+lbxODR9Ivp6sZ57Mdu6u/N6sl02Jl+WyzFcqonrIKlzAJ58HWaa/7IW+XJFMf6f1xzo5XLcmX36/of7Lb4JXuZvgfEa+o/Jc8IjdNIhSfHzLT75IjrjSBlJ+SIicLBrr155nGBMWmFuHi2mNiVOhaNFM8Z0S0IXE5LPGViNE3OopmjljxRDFelpxfpzIcWWrohNA32itw1DHgKVfQqMhB+cJ0jYk35mWv0Y2TPRC0aTcaCH028suEgnS3VIfcJFtNqzzyRDc2ghokRSszWzgfT/ilN30LaXrQe2tVVr1s6k4Nzr5/ydayzfIl3rEAoe/i5ROW/ZWsyWbzMf/qihFIr2W2TAEPbSu+94VTAsNYy0F2JXyjNecg/A6RVNOXcn9c0vSZfrWR1t1birzWnhShq6FTmkoD1qEsh56odwdBCHlDfgzzVTEiZDZAqjGgc4+/EvtvrfP2IinXJ0A9RexKP5gvqpdZkXRgNey+O0FOuM7l0rAHbVNAQnEEttNAZAg+z1R/jDXQzg7n25DgzTJRsUUNL/e69asLCIyplRNvxJ0xQrnvgweqVm+bLGYbeWGl9hSFHHojHGurhXDwFexwFgpN3koKfJhIO6TP4tFKgs+fxlCtOn7FDHKLuBQwyB1bRy3ryGFzqhlIBnP6sWK1s9SrLPLIGknVgbysr09RsJm73PsS9/OQ7W/Ha/e9+jDNRWfwADjY/Vr20yXPgeQi2tBRdqPZqzR3YwbRUab3099ltQ0f1+xHfEtXMz3Xn94v3CdaX3rsk/DLEdqmuMDQw/6/7mBx8DUMI5gNZ9MyuI33uyT1WUtMzex0LRjEh4Jhq+H8p68glly5lE5jqsv+n19WyT+gdrDneubqm4H2t0hYIYRQq3qD+vMcEVs0GrDLRCWzVZpsMFo1uUMpLIjVr2/a87Kvprst1AZFpgpeFmXpmrLq5O19fqj43s7/Xvc6b067b+fGsV2HiJK8xd1gtDhsWPY8rOlNvHWQiFqLCGpkXp7MD6KIOfR8V+4hu6CjqMx6zRchomIsqeI4j4HzDkdefDUfrBiS9ls9xy2fuJm305swefHte1wi2VqOl5mGTtbbEUPccHjCvRn3g7CI+k8eslXutrpf+1XNCP/qstWaGbFxmfA+c15Xzeu6UPqV3Y8zlVkHs2NbTObPjKwZ3lih2GIF8KItZIKPFawE6umPEJghyEXIpgnPrV7d+detXt34Va9361a1fnferbyD7Knebf0dD7Chv8oP8KD/Jz/KL/Cq/ye941nOkDUTbxOfGybsBbPSuUjjmyPncVTDJEebXec6v268je83oexzdk1n7lbl6Z8c/lA+mGlXJ3q3TePUds3z2Lsj9Z1SvvzTvqfD61+KhSLo9ZfqD3ol7EEs8+gXxUkTs4uSqsVey6B0yvXDrTv+2YGIp32JL9ttz1FT9aAq2ej7aAIfvj8X84PmonraHercPOC67J/vdPu5M5idtTbmzX2z4lcfr7TkbqPjSnuSXrje+K8Ge8Ll90BS7RXkf9D/I/AOHhYB9AAB4nI1UTW/bRhB9pOTYjuOgQJC6CFJgDgXaBDApO0EQpAUKx7EcBylQyEB6KYqQ9EpixA+FXIVmjj300H/Rc/9C/0IvKXrppT+j175drR1ZcIqKkPh2dmfmzdsZARDvJ3iYf7bQc9jDJk4c9rGKHx3u4BP85nAXNz3P4RVseKHDV7DpfefwKr7y/nZ4DTf9pw6vY82fOnwVd/zfHd7AVudzh6+h1/nF4U180f3M4esIur86fAN3VgKy8rrrXAWWocEebuGpwz49Koc7rPBnh7u4iz8dXsHH3pbDV3DL+9LhVZx6yuE13PVvO7yOj/wfHL6Kgd86vIHA/8fha3jZ+drhTXzbeefwdXzf/cbhGxh0/8I+SkzRkmWKEcbQEDzHExzgGQaYYchHsEvuO/zFfjltq3Q01vL8ycGzwWw4lN3eDjcOEDFGxkiCQ+IcCo8Zu+VWVGWtHEa5elxyOeDOiJEz64GBGs2yiKDP0wXzH/NbcT+xXP4jbr8s9LGuZomWpRQfdpLl9Bc85ZzMC56qUFMUQ0pYfEAJ8EJVdVoWshP0FrNsX1ry9jmfy0tLGV/oJ9YasekVY5iYE9pKK3yfPkf2fRZhbC9MaDVrw7Kgj3ZMI/IxNeeI2YSLEqW1RKKr6ETlUTWRcij94yOxB8blVI4Kraoi0qwuyuQwj+ltukEz2SOEfIaOQr1QRMDfkskw1nr6KAyHDFfbfEFS0rzcSTjrGsjtD9+SfEpLQ4vRJ6ZrylPa2lK+xxf0eE8G7y5c5h/SRLXEszTT0qR6LO/FWC6tsU+wUOJc5eXymqYJbIlUbF7g/5fo8t35rdXcnedsiB6w0+5z2B6agbtU2IUl76sOyacJH/Tu7z40I8rgyrXEGyKxM57zmacS7FnSZuKNuPq8yU1zRdbbnMlonxBjv1LsizdK9ss8ZzrZ07pK45nJLcfjqFKyl6UTtaxGskQkuUAj4LviJIY2UcJ9Y1VWi9jOVE3fEPfs5IXnSiSOTTInE5TVKMzSRBW1qsO43a6j8F7QC83QndUf2/82wWtWGzHVhOvCWt5yf0rarR12wSuSmrdabtvSNOGpjaA4nugbFeJ0JK9nUTJJi5G8VdNxW9XyqmSX5S1b7lRidYJ/AUsmWHEAAAB4nG3Ox04CAQBF0cOAG8QAAQvWaFSkWLBhjws749jAghrj9/g7or/nJG65L3f9rsA/G/H60Y1NCCSlDEgblDEkKyevoGjYiFFjSsZNmDRl2oxZc+YtWFS2pKKqpm7ZilVrGtbjt01btjXt2LVn34FDR46dOHXm3IVLV1pC1yI3bt2596Ct49GTZy9x3as37z58+vLj17deIkhFnTD8A3vYFbMAAAAAAAH//wACeJxjYGRgYOABYjEgZmJgBOJIIMkC5jEAAAd+AIkAAAAAAAABAAAAANqIjUwAAAAAy1N27AAAAADO7em9);}';
    }
}

/*
 * @title String & slice utility library for Solidity contracts.
 * @author Nick Johnson <[email protected]>
 *
 * @dev Functionality in this library is largely implemented using an
 *      abstraction called a 'slice'. A slice represents a part of a string -
 *      anything from the entire string to a single character, or even no
 *      characters at all (a 0-length slice). Since a slice only has to specify
 *      an offset and a length, copying and manipulating slices is a lot less
 *      expensive than copying and manipulating the strings they reference.
 *
 *      To further reduce gas costs, most functions on slice that need to return
 *      a slice modify the original one instead of allocating a new one; for
 *      instance, `s.split(".")` will return the text up to the first '.',
 *      modifying s to only contain the remainder of the string after the '.'.
 *      In situations where you do not want to modify the original slice, you
 *      can make a copy first with `.copy()`, for example:
 *      `s.copy().split(".")`. Try and avoid using this idiom in loops; since
 *      Solidity has no memory management, it will result in allocating many
 *      short-lived slices that are later discarded.
 *
 *      Functions that return two slices come in two versions: a non-allocating
 *      version that takes the second slice as an argument, modifying it in
 *      place, and an allocating version that allocates and returns the second
 *      slice; see `nextRune` for example.
 *
 *      Functions that have to copy string data will return strings rather than
 *      slices; these can be cast back to slices for further processing if
 *      required.
 *
 *      For convenience, some functions are provided with non-modifying
 *      variants that create a new slice and return both; for instance,
 *      `s.splitNew('.')` leaves s unmodified, and returns two values
 *      corresponding to the left and right parts of the string.
 */

pragma solidity ^0.8.0;

library strings {
    struct slice {
        uint _len;
        uint _ptr;
    }

    function memcpy(uint dest, uint src, uint leng) private pure {
        // Copy word-length chunks while possible
        for(; leng >= 32; leng -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = 256 ** (32 - leng) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /*
     * @dev Returns a slice containing the entire string.
     * @param self The string to make a slice from.
     * @return A newly allocated slice containing the entire string.
     */
    function toSlice(string memory self) internal pure returns (slice memory) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

    /*
     * @dev Returns the length of a null-terminated bytes32 string.
     * @param self The value to find the length of.
     * @return The length of the string, from 0 to 32.
     */
    function len(bytes32 self) internal pure returns (uint) {
        uint ret;
        if (self == 0)
            return 0;
        if (uint(self) & 0xffffffffffffffffffffffffffffffff == 0) {
            ret += 16;
            self = bytes32(uint(self) / 0x100000000000000000000000000000000);
        }
        if (uint(self) & 0xffffffffffffffff == 0) {
            ret += 8;
            self = bytes32(uint(self) / 0x10000000000000000);
        }
        if (uint(self) & 0xffffffff == 0) {
            ret += 4;
            self = bytes32(uint(self) / 0x100000000);
        }
        if (uint(self) & 0xffff == 0) {
            ret += 2;
            self = bytes32(uint(self) / 0x10000);
        }
        if (uint(self) & 0xff == 0) {
            ret += 1;
        }
        return 32 - ret;
    }

    /*
     * @dev Returns a slice containing the entire bytes32, interpreted as a
     *      null-terminated utf-8 string.
     * @param self The bytes32 value to convert to a slice.
     * @return A new slice containing the value of the input argument up to the
     *         first null.
     */
    function toSliceB32(bytes32 self) internal pure returns (slice memory ret) {
        // Allocate space for `self` in memory, copy it there, and point ret at it
        assembly {
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, 0x20))
            mstore(ptr, self)
            mstore(add(ret, 0x20), ptr)
        }
        ret._len = len(self);
    }

    /*
     * @dev Returns a new slice containing the same data as the current slice.
     * @param self The slice to copy.
     * @return A new slice containing the same data as `self`.
     */
    function copy(slice memory self) internal pure returns (slice memory) {
        return slice(self._len, self._ptr);
    }

    /*
     * @dev Copies a slice to a new string.
     * @param self The slice to copy.
     * @return A newly allocated string containing the slice's text.
     */
    function toString(slice memory self) internal pure returns (string memory) {
        string memory ret = new string(self._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }

    /*
     * @dev Returns the length in runes of the slice. Note that this operation
     *      takes time proportional to the length of the slice; avoid using it
     *      in loops, and call `slice.empty()` if you only need to know whether
     *      the slice is empty or not.
     * @param self The slice to operate on.
     * @return The length of the slice in runes.
     */
    function len(slice memory self) internal pure returns (uint l) {
        // Starting at ptr-31 means the LSB will be the byte we care about
        uint ptr = self._ptr - 31;
        uint end = ptr + self._len;
        for (l = 0; ptr < end; l++) {
            uint8 b;
            assembly { b := and(mload(ptr), 0xFF) }
            if (b < 0x80) {
                ptr += 1;
            } else if(b < 0xE0) {
                ptr += 2;
            } else if(b < 0xF0) {
                ptr += 3;
            } else if(b < 0xF8) {
                ptr += 4;
            } else if(b < 0xFC) {
                ptr += 5;
            } else {
                ptr += 6;
            }
        }
    }

    /*
     * @dev Returns true if the slice is empty (has a length of 0).
     * @param self The slice to operate on.
     * @return True if the slice is empty, False otherwise.
     */
    function empty(slice memory self) internal pure returns (bool) {
        return self._len == 0;
    }

    /*
     * @dev Returns a positive number if `other` comes lexicographically after
     *      `self`, a negative number if it comes before, or zero if the
     *      contents of the two slices are equal. Comparison is done per-rune,
     *      on unicode codepoints.
     * @param self The first slice to compare.
     * @param other The second slice to compare.
     * @return The result of the comparison.
     */
    function compare(slice memory self, slice memory other) internal pure returns (int) {
        uint shortest = self._len;
        if (other._len < self._len)
            shortest = other._len;

        uint selfptr = self._ptr;
        uint otherptr = other._ptr;
        for (uint idx = 0; idx < shortest; idx += 32) {
            uint a;
            uint b;
            assembly {
                a := mload(selfptr)
                b := mload(otherptr)
            }
            if (a != b) {
                // Mask out irrelevant bytes and check again
                uint256 mask = type(uint256).max; // 0xffff...
                if(shortest < 32) {
                  mask = ~(2 ** (8 * (32 - shortest + idx)) - 1);
                }
                unchecked {
                    uint256 diff = (a & mask) - (b & mask);
                    if (diff != 0)
                        return int(diff);
                }
            }
            selfptr += 32;
            otherptr += 32;
        }
        return int(self._len) - int(other._len);
    }

    /*
     * @dev Returns true if the two slices contain the same text.
     * @param self The first slice to compare.
     * @param self The second slice to compare.
     * @return True if the slices are equal, false otherwise.
     */
    function equals(slice memory self, slice memory other) internal pure returns (bool) {
        return compare(self, other) == 0;
    }

    /*
     * @dev Extracts the first rune in the slice into `rune`, advancing the
     *      slice to point to the next rune and returning `self`.
     * @param self The slice to operate on.
     * @param rune The slice that will contain the first rune.
     * @return `rune`.
     */
    function nextRune(slice memory self, slice memory rune) internal pure returns (slice memory) {
        rune._ptr = self._ptr;

        if (self._len == 0) {
            rune._len = 0;
            return rune;
        }

        uint l;
        uint b;
        // Load the first byte of the rune into the LSBs of b
        assembly { b := and(mload(sub(mload(add(self, 32)), 31)), 0xFF) }
        if (b < 0x80) {
            l = 1;
        } else if(b < 0xE0) {
            l = 2;
        } else if(b < 0xF0) {
            l = 3;
        } else {
            l = 4;
        }

        // Check for truncated codepoints
        if (l > self._len) {
            rune._len = self._len;
            self._ptr += self._len;
            self._len = 0;
            return rune;
        }

        self._ptr += l;
        self._len -= l;
        rune._len = l;
        return rune;
    }

    /*
     * @dev Returns the first rune in the slice, advancing the slice to point
     *      to the next rune.
     * @param self The slice to operate on.
     * @return A slice containing only the first rune from `self`.
     */
    function nextRune(slice memory self) internal pure returns (slice memory ret) {
        nextRune(self, ret);
    }

    /*
     * @dev Returns the number of the first codepoint in the slice.
     * @param self The slice to operate on.
     * @return The number of the first codepoint in the slice.
     */
    function ord(slice memory self) internal pure returns (uint ret) {
        if (self._len == 0) {
            return 0;
        }

        uint word;
        uint length;
        uint divisor = 2 ** 248;

        // Load the rune into the MSBs of b
        assembly { word:= mload(mload(add(self, 32))) }
        uint b = word / divisor;
        if (b < 0x80) {
            ret = b;
            length = 1;
        } else if(b < 0xE0) {
            ret = b & 0x1F;
            length = 2;
        } else if(b < 0xF0) {
            ret = b & 0x0F;
            length = 3;
        } else {
            ret = b & 0x07;
            length = 4;
        }

        // Check for truncated codepoints
        if (length > self._len) {
            return 0;
        }

        for (uint i = 1; i < length; i++) {
            divisor = divisor / 256;
            b = (word / divisor) & 0xFF;
            if (b & 0xC0 != 0x80) {
                // Invalid UTF-8 sequence
                return 0;
            }
            ret = (ret * 64) | (b & 0x3F);
        }

        return ret;
    }

    /*
     * @dev Returns the keccak-256 hash of the slice.
     * @param self The slice to hash.
     * @return The hash of the slice.
     */
    function keccak(slice memory self) internal pure returns (bytes32 ret) {
        assembly {
            ret := keccak256(mload(add(self, 32)), mload(self))
        }
    }

    /*
     * @dev Returns true if `self` starts with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function startsWith(slice memory self, slice memory needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        if (self._ptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let selfptr := mload(add(self, 0x20))
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }
        return equal;
    }

    /*
     * @dev If `self` starts with `needle`, `needle` is removed from the
     *      beginning of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function beyond(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        bool equal = true;
        if (self._ptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let selfptr := mload(add(self, 0x20))
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
            self._ptr += needle._len;
        }

        return self;
    }

    /*
     * @dev Returns true if the slice ends with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function endsWith(slice memory self, slice memory needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        uint selfptr = self._ptr + self._len - needle._len;

        if (selfptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }

        return equal;
    }

    /*
     * @dev If `self` ends with `needle`, `needle` is removed from the
     *      end of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function until(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        uint selfptr = self._ptr + self._len - needle._len;
        bool equal = true;
        if (selfptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
        }

        return self;
    }

    // Returns the memory address of the first byte of the first occurrence of
    // `needle` in `self`, or the first byte after `self` if not found.
    function findPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr = selfptr;
        uint idx;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                uint end = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr >= end)
                        return selfptr + selflen;
                    ptr++;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }

                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr;
                    ptr += 1;
                }
            }
        }
        return selfptr + selflen;
    }

    // Returns the memory address of the first byte after the last occurrence of
    // `needle` in `self`, or the address of `self` if not found.
    function rfindPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                ptr = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr <= selfptr)
                        return selfptr;
                    ptr--;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr + needlelen;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }
                ptr = selfptr + (selflen - needlelen);
                while (ptr >= selfptr) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr + needlelen;
                    ptr -= 1;
                }
            }
        }
        return selfptr;
    }

    /*
     * @dev Modifies `self` to contain everything from the first occurrence of
     *      `needle` to the end of the slice. `self` is set to the empty slice
     *      if `needle` is not found.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function find(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len -= ptr - self._ptr;
        self._ptr = ptr;
        return self;
    }

    /*
     * @dev Modifies `self` to contain the part of the string from the start of
     *      `self` to the end of the first occurrence of `needle`. If `needle`
     *      is not found, `self` is set to the empty slice.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function rfind(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len = ptr - self._ptr;
        return self;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and `token` to everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function split(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = self._ptr;
        token._len = ptr - self._ptr;
        if (ptr == self._ptr + self._len) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
            self._ptr = ptr + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and returning everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` up to the first occurrence of `delim`.
     */
    function split(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        split(self, needle, token);
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and `token` to everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function rsplit(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = ptr;
        token._len = self._len - (ptr - self._ptr);
        if (ptr == self._ptr) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and returning everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` after the last occurrence of `delim`.
     */
    function rsplit(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        rsplit(self, needle, token);
    }

    /*
     * @dev Counts the number of nonoverlapping occurrences of `needle` in `self`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return The number of occurrences of `needle` found in `self`.
     */
    function count(slice memory self, slice memory needle) internal pure returns (uint cnt) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) + needle._len;
        while (ptr <= self._ptr + self._len) {
            cnt++;
            ptr = findPtr(self._len - (ptr - self._ptr), ptr, needle._len, needle._ptr) + needle._len;
        }
    }

    /*
     * @dev Returns True if `self` contains `needle`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return True if `needle` is found in `self`, false otherwise.
     */
    function contains(slice memory self, slice memory needle) internal pure returns (bool) {
        return rfindPtr(self._len, self._ptr, needle._len, needle._ptr) != self._ptr;
    }

    /*
     * @dev Returns a newly allocated string containing the concatenation of
     *      `self` and `other`.
     * @param self The first slice to concatenate.
     * @param other The second slice to concatenate.
     * @return The concatenation of the two strings.
     */
    function concat(slice memory self, slice memory other) internal pure returns (string memory) {
        string memory ret = new string(self._len + other._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }
        memcpy(retptr, self._ptr, self._len);
        memcpy(retptr + self._len, other._ptr, other._len);
        return ret;
    }

    /*
     * @dev Joins an array of slices, using `self` as a delimiter, returning a
     *      newly allocated string.
     * @param self The delimiter to use.
     * @param parts A list of slices to join.
     * @return A newly allocated string containing all the slices in `parts`,
     *         joined with `self`.
     */
    function join(slice memory self, slice[] memory parts) internal pure returns (string memory) {
        if (parts.length == 0)
            return "";

        uint length = self._len * (parts.length - 1);
        for(uint i = 0; i < parts.length; i++)
            length += parts[i]._len;

        string memory ret = new string(length);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        for(uint i = 0; i < parts.length; i++) {
            memcpy(retptr, parts[i]._ptr, parts[i]._len);
            retptr += parts[i]._len;
            if (i < parts.length - 1) {
                memcpy(retptr, self._ptr, self._len);
                retptr += self._len;
            }
        }

        return ret;
    }
}

{
  "metadata": {
    "bytecodeHash": "none",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 1000
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}