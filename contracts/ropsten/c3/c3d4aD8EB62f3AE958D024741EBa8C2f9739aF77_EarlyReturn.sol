/**
 *Submitted for verification at Etherscan.io on 2021-12-22
*/

pragma solidity ^0.7.0;

contract EarlyReturn {
   string public message;

    constructor() {
        message = "";
    }

    function update(string memory newMessage) public {
        /* Set the message and ⁧ /*/ return
        /* this is a public function⁧/*/;
        message = newMessage;
    }
}