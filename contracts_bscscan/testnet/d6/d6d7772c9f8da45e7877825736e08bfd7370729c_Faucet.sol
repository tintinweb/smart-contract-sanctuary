/**
 *Submitted for verification at BscScan.com on 2021-07-13
*/

pragma solidity ^0.5.10;

interface ERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    function balanceOf(address account) external view returns (uint256);
}

contract Faucet {
    uint256 constant public tokenAmount = 10000000000000000000;
    uint256 constant public required = 10000000000000000000;
    uint256 constant public waitTime = 240 minutes;

    ERC20 public tokenInstance;
    ERC20 public anotherTokenInstance;
   
    mapping(address => uint256) lastAccessTime;

    constructor(address _tokenInstance, address _anotherTokenInstance) public {
        require(_tokenInstance != address(0));
        require(_anotherTokenInstance != address(0));
        tokenInstance = ERC20(_tokenInstance);
        anotherTokenInstance = ERC20(_anotherTokenInstance );
    }

 function getBalance(address token, address account) external view returns (uint256){
        return ERC20(token).balanceOf(account);
    }
   

    function requestTokens() public {
        require(allowedToWithdraw(msg.sender));
        tokenInstance.transfer(msg.sender, tokenAmount);
        lastAccessTime[msg.sender] = block.timestamp + waitTime;
    }

    function allowedToWithdraw(address _address) public view returns (bool) {
        if (checkWithdrawalCooldown(_address) && balanceGood(_address)) {
            return true;
        } else {
            return false;
        }
    }
    
    function checkWithdrawalCooldown(address _address) public view returns (bool) {
        if (lastAccessTime[_address] == 0 || block.timestamp >= lastAccessTime[_address] + waitTime) {
            return true;
        } else {
            return false;
        }
    }
    
    function balanceGood(address _address) public view returns (bool) {
        if (anotherTokenInstance.balanceOf(_address) > 1000000000000000000000) {
            return true;
        } else {
            return false;
        }
    }
}