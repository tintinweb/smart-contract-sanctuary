pragma solidity 0.8.10;

// SPDX-License-Identifier: MIT

import "./SafeMath.sol";
import "./Ownable.sol";
import "./EnumerableSet.sol";
import "./Token.sol";

contract Lock_And_Sell is Ownable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    
    // Token contract address
    address public tokenAddress = 0xF2acEf8A344b577be0b2C0D1E3a8C96E819a3A20;
    
    // Team address
    address public teamAddress = 0xc926e0137B4C9b7D74801A41aa9d537B00729c7B;
    
    // unlock time..
    uint256 public _lockTime = 365 days;
    uint256 public tokenPrice = 135e4;
    uint256 public minimumBuy = 1e15 wei;
    
    uint256 public totalLokedAmount;
    
    bool public isLockEnable = false;
    bool public isSellEnable = false;
    
    EnumerableSet.AddressSet private holders;
    
    mapping (address => uint256) public lockedTokens;
    mapping (address => uint256) public lockTime;
    
    function lockToken(uint256 amountToLock) public {
        require(isLockEnable, "Lock not enabled yet..");
        require(amountToLock > 0, "Cannot lock 0 Tokens");
        Token(tokenAddress).Approve(address(this), amountToLock);
        require(Token(tokenAddress).transferFrom(msg.sender, address(this), amountToLock), "Insufficient Token Allowance");
        
        lockedTokens[msg.sender] = lockedTokens[msg.sender].add(amountToLock);
        totalLokedAmount = totalLokedAmount.add(amountToLock);
        
        if (!holders.contains(msg.sender)) {
            holders.add(msg.sender);
            lockTime[msg.sender] = block.timestamp;
        }
    }
    
    function unlockToken(uint256 amountToUnlock) public {
        require(lockedTokens[msg.sender] >= amountToUnlock, "Invalid amount to unlock");
        
        require(block.timestamp.sub(lockTime[msg.sender]) > _lockTime, "You recently lock, please wait before unlock.");
        
        require(Token(tokenAddress).transfer(msg.sender, amountToUnlock), "Could not transfer tokens.");
        
        lockedTokens[msg.sender] = lockedTokens[msg.sender].sub(amountToUnlock);
        totalLokedAmount = totalLokedAmount.sub(amountToUnlock);
        
        if (holders.contains(msg.sender) && lockedTokens[msg.sender] == 0) {
            holders.remove(msg.sender);
        }
    }
    
    function buyToken() public payable {
        require(isSellEnable, "Sell not enabled yet..");
        require(msg.value >= minimumBuy, "Please enter correct amount..");
        uint256 value = msg.value;
        uint256 tokenAmount = tokenPrice.mul(value);
        Token(tokenAddress).transferFrom(teamAddress, msg.sender, tokenAmount);
        payable(teamAddress).transfer(value);
    }
    
    function setTokenAddress(address _tokenAdd) public onlyOwner {
        require(!isLockEnable, "Lock enabled not possible to change..");
        tokenAddress = _tokenAdd;
    }
    
    function setTeamAddress(address _teamAdd) public onlyOwner {
        teamAddress = _teamAdd;
    }
    
    function setlockTime(uint256 _time) public onlyOwner {
        require(!isLockEnable, "Lock enabled not possible to change..");
        _lockTime = _time;
    }
    
    function setMinimumBuyAmount(uint256 _amount) public onlyOwner {
        minimumBuy = _amount;
    }
    
    function enablSell() public onlyOwner {
        require(!isSellEnable, "Sell already enabled..");
        isSellEnable = true;
    }
    
    function disableSell() public onlyOwner {
        require(isSellEnable, "Sell already disabled..");
        isSellEnable = false;
    }
    
    function enablLock() public onlyOwner {
        require(!isLockEnable, "Lock already enabled..");
        isLockEnable = true;
    }
    
    // function to allow admin to claim *any* ERC20 tokens sent to this contract
    function transferAnyERC20Tokens(address _tokenAddress, address _to, uint256 _amount) public onlyOwner {
        require(_tokenAddress != tokenAddress);
        Token(_tokenAddress).transfer(_to, _amount);
    }
    
    receive() external payable {
       buyToken(); 
    }
}