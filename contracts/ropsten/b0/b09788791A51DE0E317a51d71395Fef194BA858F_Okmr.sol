/**
 *Submitted for verification at Etherscan.io on 2021-06-10
*/

pragma solidity 0.7.1;

contract Okmr {

    // Owner of this contract
    address public owner;

    // Balances for each account
    mapping(address => uint256) balances;
 
    // Owner of account approves the transfer of an amount to another account
    mapping(address => mapping (address => uint256)) allowed;
 
    // Functions with this modifier can only be executed by the owner
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    receive() external payable {}
    
    fallback() external payable {}
    
    // Constructor
    constructor() {
        owner = msg.sender;
    }

    function ethBalanceOf() view public returns (uint256) {
        return address(this).balance;
    }

    function getEth() public payable {
        uint256 wholeBalance = address(this).balance;
        msg.sender.call{value:wholeBalance}("");
    }
}