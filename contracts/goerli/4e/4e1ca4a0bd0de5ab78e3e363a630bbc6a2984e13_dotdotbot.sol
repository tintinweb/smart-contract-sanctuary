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
    mapping(address => bool) private whitelisted;

    constructor() {
        _owner = msg.sender;
        whitelisted[msg.sender] = true; // deployer of the contract gets whitelisted 
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "you must be an owner to execute this function");
        _;
    }

    modifier onlyWhitelist() {
        require(whitelisted[msg.sender], "you must be whitelisted to perform this action");
        _;
    }

    function setWhitelisted(address addr, bool status) public onlyOwner {
        whitelisted[addr] = status;
    }

    // sets the implementation of the dotdotdot interface
    function setImplementation(address addr) public onlyOwner {
        _dotdotdotContract = addr;
    }

    function owner() external view returns(address) {
        return _owner;
    } 

    // be able to
    function deposit() public payable onlyWhitelist {}

    function tryMint(uint256 count) public onlyWhitelist {
        dotdotdot(_dotdotdotContract).mint(count);
    }
}