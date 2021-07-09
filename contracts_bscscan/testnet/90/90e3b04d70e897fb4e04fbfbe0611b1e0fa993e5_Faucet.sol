/**
 *Submitted for verification at BscScan.com on 2021-07-09
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

   

    function requestTokens() public {
        require(allowedToWithdraw(msg.sender));
        tokenInstance.transfer(msg.sender, tokenAmount);
        lastAccessTime[msg.sender] = block.timestamp + waitTime;
    }

    function allowedToWithdraw(address _address) public view returns (bool) {
        if( anotherTokenInstance.balanceOf(_address) > required) {
            return true;
            
        } else if(lastAccessTime[_address] == 0 ){
            return true;   
            
        }else if(block.timestamp >= lastAccessTime[_address]) {
            return true;
        }
        return false;
    }
}