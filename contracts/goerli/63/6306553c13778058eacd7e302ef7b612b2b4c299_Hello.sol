/**
 *Submitted for verification at Etherscan.io on 2022-01-16
*/

// SPDX-License-Identifier: MIT
// compiler version must be greater than or equal to 0.8.10 and less than 0.9.0
pragma solidity ^0.8.10;

//import "github.com/Arachnid/solidity-stringutils/strings.sol";
contract Hello { string public name;

string public name1="Hello Word";
        function set(string memory _name) public {
           name= string(bytes.concat(bytes(name), "  ", bytes(_name)));
          //  name=s = name.toSlice().concat(_name.toSlice());
    }
}