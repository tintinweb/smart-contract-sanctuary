/**
 *Submitted for verification at polygonscan.com on 2022-01-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract IPFSRelayer {

    address private _owner;

    string public ipfsCIDTestnet;
    string public ipfsCIDMainnet;

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "IPFSRelayer: caller is not the owner");
        _;
    }

    function setTestnet(string memory ipfsCID) public onlyOwner {
        ipfsCIDTestnet = ipfsCID;
    }

    function setMainnet(string memory ipfsCID) public onlyOwner {
        ipfsCIDMainnet = ipfsCID;
    }

}