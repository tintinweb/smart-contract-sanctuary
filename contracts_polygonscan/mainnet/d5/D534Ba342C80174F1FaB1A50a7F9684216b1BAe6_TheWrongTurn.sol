/**
 *Submitted for verification at polygonscan.com on 2021-09-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract TheWrongTurn{
    event pushhh(string alert_text);

    struct Secret {
        address owner;
        string secret_text;
    }

    mapping(address => Secret) private secrets;

    function set_secret(string memory text) public {
        secrets[msg.sender] = Secret(msg.sender, text);
        emit pushhh(text);
    }

    function get_secret() public view returns (string memory) {
        return secrets[msg.sender].secret_text;
    }
}