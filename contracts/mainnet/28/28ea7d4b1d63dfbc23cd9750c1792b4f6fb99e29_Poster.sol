/**
 *Submitted for verification at Etherscan.io on 2021-07-28
*/

/**
 *Submitted for verification at Etherscan.io on 2021-03-30
*/

/**
 *Submitted for verification at Etherscan.io on 2021-03-30
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
    event NewPost(bytes32 indexed id, address indexed user, string content);

    function post(string memory content) public {
        bytes32 id = keccak256(abi.encodePacked(msg.sender, block.chainid, block.number, gasleft()));
        emit NewPost(id, msg.sender, content);
    }
}