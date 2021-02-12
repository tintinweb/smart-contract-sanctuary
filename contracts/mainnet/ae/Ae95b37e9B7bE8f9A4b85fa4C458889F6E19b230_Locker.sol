/**
 *Submitted for verification at Etherscan.io on 2021-02-11
*/

pragma solidity ^0.4.13;

contract _ERC20Basic {
  function balanceOf(address _owner) public returns (uint256 balance);
  function transfer(address to, uint256 value) public returns (bool);
}

contract Locker {
    address owner;
    
    address tokenAddress = 0x4A01C8775319244Bf0680ED61a61AB4f6ec38a39; // $GASPAY token address
    uint256 unlockUnix = now + (90 days); // 3 months
    
    _ERC20Basic token = _ERC20Basic(tokenAddress);
    
    constructor() public {
        owner = msg.sender;
    }
    
    function unlockTeamTokens() public {
        require(owner == msg.sender, "Sender not owner");
        require( now > unlockUnix, "Unlock Time not reached yet");
        token.transfer(owner, token.balanceOf(address(this)));
    }
    
    function getLockAmount() public view returns (uint256) {
        return token.balanceOf(address(this));
    }
    
    function getTokenAddress()  public view returns (address) {
        return tokenAddress;
    }
    
    function getUnlockTimeLeft() public view returns (uint) {
        return unlockUnix - now;
    }
}