/**
 *Submitted for verification at snowtrace.io on 2021-12-31
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface XMAS_Interface {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface DAPP_Interface {
    function getNodeCount(address _user) external view returns (uint);
}

contract Airdrop {

    address XMAS = 0xbf77597b47491F3D341de5373aC7ab418e9e9fe2;
    XMAS_Interface public xmas = XMAS_Interface(XMAS);

    address DAPP = 0x49F8359fB10225f0714a9d47d6378249B75573D6;
    DAPP_Interface public dapp = DAPP_Interface(DAPP);

    mapping (address => bool) hasClaimed;
    uint reward = 20 * 1e18;

    function claim() public {
        require(hasClaimed[msg.sender] == false);

        xmas.transfer(msg.sender, reward * dapp.getNodeCount(msg.sender));

        hasClaimed[msg.sender] = true;
    }
}