/**
 *Submitted for verification at Etherscan.io on 2021-08-27
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;
library LCG {
        struct iterator {
            uint x;
            uint a;  
            uint c;
            uint m;
        }
        
        function iterate (iterator storage _i) external {
            _i.x =  (_i.a * _i.x + _i.c) % _i.m;
        }
        
        // https://stackoverflow.com/questions/47129173/how-to-convert-uint-to-string-in-solidity
        function convertToString(iterator storage _i) view external returns (string memory _uintAsString) {
            if (_i.x == 0) {
                return "0";
            }
            uint i = _i.x;
            uint j = i;
            uint len;
            while (j != 0) {
                len++;
                j /= 10;
            }
            bytes memory bstr = new bytes(len);
            uint k = len;
            while (i != 0) {
                k = k-1;
                uint8 temp = (48 + uint8(i - i / 10 * 10));
                bytes1 b1 = bytes1(temp);
                bstr[k] = b1;
                i /= 10;
            }
            
            // maybe fill up the remaining digits with zeros
            return string(bstr);
        }  
        
    }