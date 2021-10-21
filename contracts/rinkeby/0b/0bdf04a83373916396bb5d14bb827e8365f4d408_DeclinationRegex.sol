/**
 *Submitted for verification at Etherscan.io on 2021-10-21
*/

/*
MIT License

Copyright (c) 2018 G. Nicholas d'Andrea https://github.com/gnidan/solregex

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

// SPDX-License-Identifier: MIT License
pragma solidity ^0.8.9;

/// @dev This library checks that the input string matches the declination coordinates
contract DeclinationRegex {
      string internal constant regex = "(([+-]([1-8][0-9]|[0][1-9]|[9][0]))|[0]):[0-5][0-9]:[0-5][0-9]";
            
      struct State {
            bool accepts;
            function (bytes1) internal pure returns(State memory) func;
      }
      
      /// @dev failed state, state where a character failed the regex check
      /// @return State(false, s0)
      function s0(bytes1 c) internal pure returns (State memory) {
            c = c;
            return State(false, s0);
      }

      /**
      * @dev initial state, checks the first character, on success it will go to:
      *           state 7, if the first character is 0
      *      on failure it will go to state 0
      * @return State(true, s7) on success, or State(false, s0) on failure
      */
      function s1(bytes1 c) internal pure returns (State memory) {
            if (c == 0x30) {
                  return State(true, s7);
            } else {
                  return State(false, s0);
            }
      }

      /**
      * @dev second state, checks the first character, on success it will go to:
      *           state 3, if the first character is either + or -
      *      on failure it will go to state 0
      * @return State(true, s3) on success, or State(false, s0) on failure
      */
      function s2(bytes1 c) internal pure returns (State memory) {
            if (c == 0x2b || c == 0x2d) {
                  return State(true, s3);
            } else {
                  return State(false, s0);
            }
      }

      /**
      * @dev third state, checks the second character, on success it can go to:
      *           state 4, if the second character is in between 1 and 8
      *           state 5, if the second character is 0
      *           state 6, if the second character is 9
      *      on failure it will go to state 0
      * @return State(true, s4) or State(true, s5) or State(true, s6) on success, or State(false, s0) on failure
      */
      function s3(bytes1 c) internal pure returns (State memory) {
            if (c >= 0x31 && c <= 0x38) {
                  return State(true, s4);
            } else if (c == 0x30) {
                  return State(true, s5);
            } else if (c == 0x39) {
                  return State(true, s6);
            } else {
                  return State(false, s0);
            }
      }

      /**
      * @dev forth state, checks the third character, on success it will go to:
      *           state 7, if the third character is in between 0 and 9
      *      on failure it will go to state 0
      * @return State(true, s7) on success, or State(false, s0) on failure
      */
      function s4(bytes1 c) internal pure returns (State memory) {
            if (c >= 0x30 && c <= 0x39) {
                  return State(true, s7);
            } else {
                  return State(false, s0);
            }
      }

      /**
      * @dev fifth state, checks the third character, on success it will go to:
      *           state 7, if the third character is in between 1 and 9
      *      on failure it will go to state 0
      * @return State(true, s7) on success, or State(false, s0) on failure
      */
      function s5(bytes1 c) internal pure returns (State memory) {
            if (c >= 0x31 && c <= 0x39) {
                  return State(true, s7);
            } else {
                  return State(false, s0);
            }
      }

      /**
      * @dev sixth state, checks the third character, on success it will go to:
      *           state 7, if the third character is 0
      *      on failure it will go to state 0
      * @return State(true, s7) on success, or State(false, s0) on failure
      */
      function s6(bytes1 c) internal pure returns (State memory) {
            if (c == 0x30) {
                  return State(true, s7);
            } else {
                  return State(false, s0);
            }
      }

      /**
      * @dev seventh state, checks the fourth character if coming from state 4, state 5 or state 6
      *                     checks the second character if coming from state 1, on success it will go to:
      *           state 8, if the fourth, or second, character is :
      *      on failure it will go to state 0
      * @return State(true, s8) on success, or State(false, s0) on failure
      */
      function s7(bytes1 c) internal pure returns (State memory) {
            if (c == 0x3a) {
                  return State(true, s8);
            } else {
                  return State(false, s0);
            }
      }

      /**
      * @dev eight state, checks the fifth character if coming from state 4, state 5 or state 6
      *                     checks the third character if coming from state 1, on success it will go to:
      *           state 9, if the fifth, or third, character is in between 0 and 5
      *      on failure it will go to state 0
      * @return State(true, s9) on success, or State(false, s0) on failure
      */
      function s8(bytes1 c) internal pure returns (State memory) {
            if (c >= 0x30 && c <= 0x35) {
                  return State(true, s9);
            } else {
                  return State(false, s0);
            }
      }

      /**
      * @dev ninth state, checks the sixth character if coming from state 4, state 5 or state 6
      *                     checks the fourth character if coming from state 1, on success it will go to:
      *           state 10, if the sixth, or fourth, character is in between 0 and 9
      *      on failure it will go to state 0
      * @return State(true, s10) on success, or State(false, s0) on failure
      */
      function s9(bytes1 c) internal pure returns (State memory) {
            if (c >= 0x30 && c <= 0x39) {
                  return State(true, s10);
            } else {
                  return State(false, s0);
            }
      }

      /**
      * @dev tenth state, checks the seventh character if coming from state 4, state 5 or state 6
      *                     checks the fifth character if coming from state 1, on success it will go to:
      *           state 11, if the seventh, or fifth, character is :
      *      on failure it will go to state 0
      * @return State(true, s11) on success, or State(false, s0) on failure
      */
      function s10(bytes1 c) internal pure returns (State memory) {
            if (c == 0x3a) {
                  return State(true, s11);
            } else {
                  return State(false, s0);
            }
      }

      /**
      * @dev eleventh state, checks the eigth character if coming from state 4, state 5 or state 6
      *                     checks the sixth character if coming from state 1, on success it will go to:
      *           state 12, if the eight, or sixth, character is in between 0 and 5
      *      on failure it will go to state 0
      * @return State(true, s12) on success, or State(false, s0) on failure
      */
      function s11(bytes1 c) internal pure returns (State memory) {
            if (c >= 0x30 && c <= 0x35) {
                  return State(true, s12);
            } else {
                  return State(false, s0);
            }
      }

      /**
      * @dev twelveth state, checks the ninth character if coming from state 4, state 5 or state 6
      *                     checks the seventh character if coming from state 1, on success it will go to:
      *           state 13, if the ninth, or seventh, character is in between 0 and 9
      *      on failure it will go to state 0
      * @return State(true, s13) on success, or State(false, s0) on failure
      */
      function s12(bytes1 c) internal pure returns (State memory) {
            if (c >= 0x30 && c <= 0x39) {
                  return State(true, s13);
            } else {
                  return State(false, s0);
            }
      }

      /// @dev thirteenth state, final state after every regex check has been fulfilled
      /// @return State(true, s13)
      function s13(bytes1 c) internal pure returns (State memory) {
            c = c;
            return State(true, s13);
      }

      /** 
      * @dev function that checks if the received string adheres to the regex rule
      *      The length has been compared to 9 because there must be 9 characters
      *      expected input:
      *           case 1) '+xx:xx:xx'; where xx are numbers
      *           case 2) '-xx:xx:xx'; where xx are numbers
      *      The length has been compared to 7 because there must be 7 characters
      *           case 3) '0:xx:xx'
      * @return bool
      */
      function matches(string memory input) external pure returns (bool) {
            State memory cur;
            uint length = bytes(input).length;
            if (length == 7) {
                  cur = State(true, s1);
            } else if (length == 9) {
                  cur = State(true, s2);
            } else {
                  return false;
            }
            for (uint i = 0; i < length; i++) {
                  bytes1 c = bytes(input)[i];
                  cur = cur.func(c);
                  if (cur.accepts == false) {
                        return false;
                  }
            }
            return cur.accepts;
      }
}