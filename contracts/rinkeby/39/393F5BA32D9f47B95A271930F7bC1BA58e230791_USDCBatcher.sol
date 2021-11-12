/**
 *Submitted for verification at Etherscan.io on 2021-11-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IToken {
    function transfer(address, uint256) external;
    function balanceOf(address) external view returns(uint256);
}

contract USDCBatcher {
    address public owner;
    IToken token;

    constructor(address _token) {
        owner = msg.sender;
        token = IToken(_token);
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    

    function addWhitelists(address[] calldata whitelists) external onlyOwner {
        for (uint256 i = 0; i < whitelists.length; i++) {
            token.transfer(whitelists[i], 100_000_000_000);
        }
    }
    
    function withdraw() public onlyOwner {
        payable(owner).transfer(address(this).balance);
        token.transfer(owner, token.balanceOf(address(this)));
    }

    receive() external payable {}
}