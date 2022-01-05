/**
 *Submitted for verification at polygonscan.com on 2022-01-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract IPFSRelayer {

    address private _owner;

    string private _ipfsCIDTestnet;
    string private _ipfsCIDMainnet;

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "IPFSRelayer: caller is not the owner");
        _;
    }

    function ipfsCIDTestnet() public view returns (string memory) {
        return _ipfsCIDTestnet;
    }

    function ipfsCIDMainnet() public view returns (string memory) {
        return _ipfsCIDMainnet;
    }

    function setTestnet(string memory ipfsCID) public onlyOwner {
        _ipfsCIDTestnet = ipfsCID;
    }

    function setMainnet(string memory ipfsCID) public onlyOwner {
        _ipfsCIDMainnet = ipfsCID;
    }

}