/**
 *Submitted for verification at Etherscan.io on 2021-10-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Mint {
    address payable public owner;
    uint256 public totalMinted = 0;
    mapping(address => uint256) public minters;

    uint256 public maxSupply = 6969;
    uint256 public mintPrice = 69000000000000000;
    uint256 public maxMintPerMinter = 5;

    constructor(address payable _owner) {
        owner = _owner;
    }

    function mint(uint256 _amount) public payable {
        require(totalMinted < maxSupply);
        require(_amount > 0);
        uint256 minted = minters[msg.sender];
        require(minted + _amount <= maxMintPerMinter);
        owner.transfer(_amount * mintPrice);
        minters[msg.sender] += _amount;
        totalMinted += _amount;
    }
}