pragma solidity ^0.4.13;

contract ERC20Basic {
  function balanceOf(address _owner) public returns (uint256 balance);
  function transfer(address to, uint256 value) public returns (bool);
}


contract A_Locker {
    address owner;
    
    address tokenAddress = 0xd03B6ae96CaE26b743A6207DceE7Cbe60a425c70;
    uint256 unlockUnix = now + 31 days;
    
    ERC20Basic token = ERC20Basic(tokenAddress);
    
    constructor() public {
        owner = msg.sender;
    }
    
    function unlockTeamTokens() public {
        require(owner == msg.sender, "You is not owner");
        require( now > unlockUnix, "Is not unlock time now");
        token.transfer(owner, token.balanceOf(address(this)));
    }
    
    //Control
    function getLockAmount() public view returns (uint256){
        return token.balanceOf(address(this));
    }
    
    function getTokenAddress()  public view returns (address){
        return tokenAddress;
    }
    
    function getUnlockTimeLeft() public view returns (uint){
        return unlockUnix - now;
    }
}