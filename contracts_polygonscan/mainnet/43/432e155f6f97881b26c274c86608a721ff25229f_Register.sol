/**
 *Submitted for verification at polygonscan.com on 2021-07-06
*/

pragma solidity ^0.8.3;

// SPDX-License-Identifier: GPL-3.0-or-later

contract Register {

    string public title;
    string public yourName;
    string public text;
    address public target;

    constructor(string memory Title, address Target    ) {
        title = Title;
        target = Target;
    }

    function update(string memory YourName, string memory Text ) public {
        yourName = YourName;
        text = Text;
        address payable thistarget = payable(target);
        thistarget.transfer(1);

    }
}

/*

The point of this function is to create a logical connection to any speficied Address.
Rather than focus on tokenization. I prefer to build specific social networks. The point 
is to "color" the address in the way of a Gen1 OP_RETURN address so that the ledger directly
represents an exchange of ideas.

I also peridocally monitor this address for communication:

0x1111111111111111111111111111111111111111.

---
  - this is an example of yaml to be interpreted off-chain 
  - abcdefg

*/