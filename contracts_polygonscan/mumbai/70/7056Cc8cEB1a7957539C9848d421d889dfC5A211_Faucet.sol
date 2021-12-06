// SPDX-License-Identifier: MIT
pragma solidity >= 0.5.1;

interface ERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Faucet {
    uint256 constant public tokenAmount = 0.0037 * 10 ** 18;
    uint256 constant public waitTime = 10 days;

    ERC20 public tokenInstance;
    
    mapping(address => uint256) lastAccessTime;

    constructor(address _tokenInstance) {
        require(_tokenInstance != address(0));
        tokenInstance = ERC20(_tokenInstance);
    }

    function requestTokens() public {
        require(allowedToWithdraw(msg.sender));
        tokenInstance.transfer(msg.sender, tokenAmount);
        lastAccessTime[msg.sender] = block.timestamp + waitTime;
    }

    function allowedToWithdraw(address _address) public view returns (bool) {
        if(lastAccessTime[_address] == 0) {
            return true;
        } else if(block.timestamp >= lastAccessTime[_address]) {
            return true;
        }
        return false;
    }
}