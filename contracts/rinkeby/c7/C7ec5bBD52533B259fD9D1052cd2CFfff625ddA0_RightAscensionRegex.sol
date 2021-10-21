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

/// @dev This library checks that the input string matches the right ascension coordinates
contract RightAscensionRegex {
      string internal constant regex = "([01][0-9]|[2][0-3]):[0-5][0-9]:[0-5][0-9]";
      
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
      * @dev initial state, checks the first character, on success it can go to:
      *           state 2, if the first character is either 0 or 1
      *           state 3, if the first character is 2
      *      on failure it will go to state 0
      * @return State(true, s2) or State(true, s3) on success, or State(false, s0) on failure
      */
      function s1(bytes1 c) internal pure returns (State memory) {
            if (c == 0x30 || c == 0x31) {
                  return State(true, s2);
            } else if (c == 0x32) {
                  return State(true, s3);
            } else {
                  return State(false, s0);
            }
      }
      
      /**
      * @dev second state, checks the second character, on success it will go to:
      *           state 4, if the second character is in between 0 and 9
      *      on failure it will go to state 0
      * @return State(true, s4) on success or State(false, s0) on failure
      */
      function s2(bytes1 c) internal pure returns (State memory) {
            if (c >= 0x30 && c <= 0x39) {
                  return State(true, s4);
            } else {
                  return State(false, s0);
            }
      }
      
      /**
      * @dev third state, checks the second character, on success it will go to:
      *           state 4, if the second character is in between 0 and 3
      *      on failure it will go to state 0
      * @return State(true, s4) on success or State(false, s0) on failure
      */
      function s3(bytes1 c) internal pure returns (State memory) {
            if (c >= 0x30 && c <= 0x33) {
                  return State(true, s4);
            } else {
                  return State(false, s0);
            }
      }
      
      /**
      * @dev fourth state, checks the third character, on success it will go to:
      *           state 5, is the third character is equal to :
      *      on failure it will go to state 0
      * @return State(true, s5) on success or State(false, s0) on failure
      */
      function s4(bytes1 c) internal pure returns (State memory) {
            if (c == 0x3a) {
                  return State(true, s5);
            } else {
                  return State(false, s0);
            }
      }
      
      /**
      * @dev fifth state, checks the forth character, on success it will go to:
      *           state 6, if the forth character is in between 0 and 5
      *      on failure it will go to state 0
      * @return State(true, s6) on success or State(false, s0) on failure
      */
      function s5(bytes1 c) internal pure returns (State memory) {
            if (c >= 0x30 && c <= 0x35) {
                  return State(true, s6);
            } else {
                  return State(false, s0);
            }
      }
      
      /**
      * @dev sixth state, checks the fifth character, on success it will go to:
      *           state 7, if the fifth character is in between 0 and 9
      *      on failure it will go to state 0
      * @return State(true, s7) on success or State(false, s0) on failure
      */
      function s6(bytes1 c) internal pure returns (State memory) {
            if (c >= 0x30 && c <= 0x39) {
                  return State(true, s7);
            } else {
                  return State(false, s0);
            }
      }
      
      /**
      * @dev seventh state, checks the sixth character, on success it will go to:
      *           state 8, is the sixth character is equal to :
      *      on failure it will go to state 0
      * @return State(true, s8) on success or State(false, s0) on failure
      */
      function s7(bytes1 c) internal pure returns (State memory) {
            if (c == 0x3a) {
                  return State(true, s8);
            } else {
                  return State(false, s0);
            }
      }
      
      /**
      * @dev eight state, checks the seventh character, on success it will go to:
      *           state 9, if the seventh character is in between 0 and 5
      *      on failure it will go to state 0
      * @return State(true, s9) on success or State(false, s0) on failure
      */
      function s8(bytes1 c) internal pure returns (State memory) {
            if (c >= 0x30 && c <= 0x35) {
                  return State(true, s9);
            } else {
                  return State(false, s0);
            }
      }
      
      /**
      * @dev ninth state, checks the eight character, on success it will go to:
      *           state 10, if the eight character is in between 0 and 9
      *      on failure it will go to state 0
      * @return State(true, s10) on success or State(false, s0) on failure
      */
      function s9(bytes1 c) internal pure returns (State memory) {
            if (c >= 0x30 && c <= 0x39) {
                  return State(true, s10);
            } else {
                  return State(false, s0);
            }
      }
      
      /// @dev tenth state, final state after every regex check has been fulfilled
      /// @return State(true, s10)
      function s10(bytes1 c) internal pure returns (State memory) {
            c = c;
            return State(true, s10);
      }
      
      /** 
      * @dev function that checks if the received string adheres to the regex rule
      *      The length has been compared to 8 because there must be 8 characters
      *      expected input = 'xx:xx:xx'; where xx are numbers
      * @return bool
      */
      function matches(string memory input) external pure returns (bool) {
            State memory cur;
            uint length = bytes(input).length;
            if (length == 8) {
                  cur = State(true, s1);
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