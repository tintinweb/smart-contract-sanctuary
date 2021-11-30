/**
 *Submitted for verification at polygonscan.com on 2021-11-30
*/

/*
  /$$$$$$   /$$$$$$  /$$$$$$$  /$$$$$$$$ /$$$$$$$$ /$$   /$$       /$$$$$$$$                                       /$$    
 /$$__  $$ /$$__  $$| $$__  $$| $$_____/| $$_____/| $$$ | $$      | $$_____/                                      | $$    
| $$  \__/| $$  \__/| $$  \ $$| $$      | $$      | $$$$| $$      | $$    /$$$$$$  /$$   /$$  /$$$$$$$  /$$$$$$  /$$$$$$  
| $$ /$$$$| $$ /$$$$| $$$$$$$/| $$$$$   | $$$$$   | $$ $$ $$      | $$$$$|____  $$| $$  | $$ /$$_____/ /$$__  $$|_  $$_/  
| $$|_  $$| $$|_  $$| $$__  $$| $$__/   | $$__/   | $$  $$$$      | $$__/ /$$$$$$$| $$  | $$| $$      | $$$$$$$$  | $$    
| $$  \ $$| $$  \ $$| $$  \ $$| $$      | $$      | $$\  $$$      | $$   /$$__  $$| $$  | $$| $$      | $$_____/  | $$ /$$
|  $$$$$$/|  $$$$$$/| $$  | $$| $$$$$$$$| $$$$$$$$| $$ \  $$      | $$  |  $$$$$$$|  $$$$$$/|  $$$$$$$|  $$$$$$$  |  $$$$/
 \______/  \______/ |__/  |__/|________/|________/|__/  \__/      |__/   \_______/ \______/  \_______/ \_______/   \___/  
 
 100 000 GGREEN Tokens - 0x68CaF7335aA11188D9d91E1c9a5ab73a6de827bE
 Available every 60 minutes per one wallet
 ~12% tax will be deducted from this amount 
*/
pragma solidity ^0.5.1;

interface ERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Faucet {
    uint256 constant public tokenAmount = 100000000000000000000000;
    uint256 constant public waitTime = 30 minutes;

    ERC20 public tokenInstance;
    
    mapping(address => uint256) lastAccessTime;

    constructor(address _tokenInstance) public {
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