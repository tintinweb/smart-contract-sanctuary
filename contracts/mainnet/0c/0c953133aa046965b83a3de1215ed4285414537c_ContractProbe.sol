pragma solidity ^0.4.23;

/*
The MIT License (MIT)

Copyright (c) 2018 Murray Software, LLC.

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
//solhint-disable max-line-length

contract ContractProbe {

    function probe(address _addr) public view returns (bool isContract, address forwardedTo) {
        bytes memory clone = hex"6000368180378080368173bebebebebebebebebebebebebebebebebebebebe5af43d82803e15602c573d90f35b3d90fd";
        uint size;
        bytes memory code;

        assembly {  //solhint-disable-line
            size := extcodesize(_addr)
        }

        isContract = size > 0;
        forwardedTo = _addr;

        if (size <= 48 && size >= 44) {
            bool matches = true;
            uint i;

            assembly { //solhint-disable-line
                code := mload(0x40)
                mstore(0x40, add(code, and(add(add(size, 0x20), 0x1f), not(0x1f))))
                mstore(code, size)
                extcodecopy(_addr, add(code, 0x20), 0, size)
            }
            for (i = 0; matches && i < 10; i++) { 
                matches = code[i] == clone[i];
            }
            for (i = 0; matches && i < 17; i++) {
                if (i == 8) {
                    matches = code[code.length - i - 1] == byte(uint(clone[48 - i - 1]) - (48 - size));
                } else {
                    matches = code[code.length - i - 1] == clone[48 - i - 1];
                }
            }
            if (code[10] != byte(0x73 - (48 - size))) {
                matches = false;
            }
            uint forwardedToBuffer;
            if (matches) {
                assembly { //solhint-disable-line
                    forwardedToBuffer := mload(add(code, 31))
                }
                forwardedToBuffer &= (0x1 << 20 * 8) - 1;
                forwardedTo = address(forwardedToBuffer >> ((48 - size) * 8));
            }
        }
    }
}