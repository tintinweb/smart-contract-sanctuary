/**
 *Submitted for verification at BscScan.com on 2021-07-10
*/

pragma solidity ^0.4.13;

contract _ERC20Basic {
  function balanceOf(address _owner) public returns (uint256 balance);
  function transfer(address to, uint256 value) public returns (bool);
}


contract PotentLock  {
    address owner;

    address tokenAddress = 0xEa37c7AFBa8Efd0C8c0bB49c0aD5aa86aEA80327; 
    uint256 unlockBEP20Time = now + 90 days;

    _ERC20Basic token = _ERC20Basic(tokenAddress);

    constructor() public {
        owner = msg.sender;
    }

    function unlockBEP20Tokens() public {
        require(owner == msg.sender, "Only owner is allowed");
        require( now > unlockBEP20Time, "Sorry tokens are still locked.");
        token.transfer(owner, token.balanceOf(address(this)));
    }

    function getLockAmount() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function getTokenAddress()  public view returns (address) {
        return tokenAddress;
    }

    function getUnlockTimeLeft() public view returns (uint) {
        return unlockBEP20Time - now;
    }
}