/**
 *Submitted for verification at Etherscan.io on 2021-03-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.0;

// import '@openzeppelin/contracts/math/SafeMath.sol';
// import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/solc-0.6/contracts/math/SafeMath.sol';

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract Storage is SafeMath {
    
    // using SafeMath for uint256;
    mapping (address => uint) public contributions;
    address payable public owner;
    
    constructor() public {
        owner = msg.sender;
        contributions[msg.sender] = 0 * (1 ether);
    }
    
    modifier onlyOwner {
        require(
            msg.sender == owner,
            "caller is not the owner"
        );
        _;
    }
    
    function contribute() public payable {
        contributions[msg.sender] += msg.value;
    }
    
    function getContribution() public view returns (uint) {
        return contributions[msg.sender];
    }
    
    function withdraw() public onlyOwner {
        owner.transfer(address(this).balance);
    }
    
    //Use msg.sender instead of owner, so everyone can selfdestruct
    function close() public { 
        selfdestruct(msg.sender); 
    }
 
}