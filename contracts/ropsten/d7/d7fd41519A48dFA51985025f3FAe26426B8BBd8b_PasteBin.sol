/**
 *Submitted for verification at Etherscan.io on 2021-10-27
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract PasteBin {
    struct Paste {
      string text;
      bool exists;
    }

    mapping(string => Paste) pastes;

    function addPaste(string memory id, string memory pasteText)
        public
        payable
    {
        require(!pastes[id].exists, "This ID is already occupied");

        pastes[id].text = pasteText;
        pastes[id].exists = true;
    }

    function getPaste(string memory id)
        public
        view
        returns (Paste memory)
    {
        return pastes[id];
    }
}