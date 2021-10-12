/**
 *Submitted for verification at Etherscan.io on 2021-10-12
*/

pragma solidity ^0.8.7;

interface dotdotdot {
    function mint(uint256 numberOfTokensMax5) external payable;
}

contract dotdotbot {
    // the address of the dotdotdot contract implementation
    address private _dotdotdotContract;
    address private _owner;

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "you must be an owner to execute this function");
        _;
    }

    // sets the implementation of the dotdotdot interface
    function setImplementation(address addr) public onlyOwner {
        _dotdotdotContract = addr;
    }

    function owner() external view returns(address) {
        return _owner;
    } 

    function tryMint(uint256 count) public payable {
        dotdotdot(_dotdotdotContract).mint(count);
    }
}