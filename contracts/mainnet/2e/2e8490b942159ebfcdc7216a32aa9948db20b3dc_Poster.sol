/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

/*

██████╗  ██████╗ ███████╗████████╗███████╗██████╗
██╔══██╗██╔═══██╗██╔════╝╚══██╔══╝██╔════╝██╔══██╗
██████╔╝██║   ██║███████╗   ██║   █████╗  ██████╔╝
██╔═══╝ ██║   ██║╚════██║   ██║   ██╔══╝  ██╔══██╗
██║     ╚██████╔╝███████║   ██║   ███████╗██║  ██║
╚═╝      ╚═════╝ ╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝

A ridiculously simple general purpose social media smart contract.
It takes a string as a parameter and emits that string, along with a unique id, as an event. That's it.

Made with ❤️ by Auryn.eth

*/
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.0;


contract Poster {
    event NewPost(uint256 indexed id, address indexed user, string content);

    uint256 public id = 0;

    function post(string memory content) public {
        emit NewPost(id, msg.sender, content);
        id ++;
    }
}