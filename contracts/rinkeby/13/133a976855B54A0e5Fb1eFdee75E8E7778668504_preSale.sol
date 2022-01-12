/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

pragma solidity ^0.8.9;

contract preSale {
    
    mapping(address => uint256) public coinBalancePublic;

    constructor(){}

    function buyToken() public payable {
        coinBalancePublic[msg.sender] = coinBalancePublic[msg.sender] + (msg.value);
    }


    function claim() public {
        uint256 numberOfTokens = coinBalancePublic[msg.sender];

        payable(msg.sender).transfer(numberOfTokens);
        coinBalancePublic[msg.sender] = 0;
    }

    function balance(address addr) public view returns (uint256) {
        return coinBalancePublic[addr];

    }

    receive() external payable {}
}