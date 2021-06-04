/**
 *Submitted for verification at Etherscan.io on 2021-06-04
*/

pragma solidity ^0.5.16;

contract Token {
    address public minter;
    string public name;
    mapping(address => uint256) public ethBalanceOf;

    constructor() public {
        minter = msg.sender; //only initially
        name = "Decentralized Bank Currency";
    }

    function() external payable {
      ethBalanceOf[msg.sender] = msg.value;
    }
}