/**
 *Submitted for verification at Etherscan.io on 2021-09-02
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.8.7;

abstract contract Ownable {

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function renounceOwnership() public onlyOwner {
        _setOwner(address(0));
    }

    function _setOwner(address newOwner) private {
        owner = newOwner;
    }
}

contract ShareHolder is Ownable {

    address[] public shareHolders;

    constructor() {
        shareHolders = new address[](1);
        shareHolders[0] = msg.sender;
    }

    function addShareHolder(address addr) public onlyOwner {
        require(addr != address(0), "Zero address");
        uint len = shareHolders.length;
        for (uint i=0; i<len; i++) {
            require(addr != shareHolders[i], "Already added");
        }
        shareHolders.push(addr);
    }

    function buy() public payable {
        require(msg.value == 0.01 ether, "Price is 0.01 ether");
        uint256 share = msg.value / shareHolders.length;
        uint len = shareHolders.length;
        for (uint i=0; i<len; i++) {
            address payable addr = payable(shareHolders[i]);
            addr.transfer(share);
        }
    }
}