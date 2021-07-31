/**
 *Submitted for verification at Etherscan.io on 2021-07-31
*/

/*

██████╗  ██████╗ ███████╗████████╗███████╗██████╗
██╔══██╗██╔═══██╗██╔════╝╚══██╔══╝██╔════╝██╔══██╗
██████╔╝██║   ██║███████╗   ██║   █████╗  ██████╔╝
██╔═══╝ ██║   ██║╚════██║   ██║   ██╔══╝  ██╔══██╗
██║     ╚██████╔╝███████║   ██║   ███████╗██║  ██║
╚═╝      ╚═════╝ ╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝

A ridiculously simple general purpose social media smart contract.
It takes a string as a parameter and emits that string, along with msg.sender, as an event. That's it.

Made with ❤️ by Auryn.eth

*/
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.0;


contract Poster {
    event NewPost(address indexed user, string content);

    function post(string memory content) public {
        emit NewPost(msg.sender, content);
    }
}