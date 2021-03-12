/**
 *Submitted for verification at Etherscan.io on 2021-03-12
*/

pragma solidity ^0.4.26;

contract _ERC20Basic {
  function balanceOf(address _owner) public returns (uint256 balance);
  function transfer(address to, uint256 value) public returns (bool);
}


contract MEDUSALPLOCK  {
    address owner;

    address tokenPairAddress = 0xc3fa5e801dbc35b115a28720730f0dfbbfa342e5; 
    uint256 unlockLPTime = now + 1 hours;

    _ERC20Basic token = _ERC20Basic(tokenPairAddress);

    constructor() public {
        owner = msg.sender;
    }

    function unlockLPTokens() public {
        require(owner == msg.sender, "Only owner is allowed");
        require( now > unlockLPTime, "Sorry tokens are still locked.");
        token.transfer(owner, token.balanceOf(address(this)));
    }

    function getLockAmount() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function getTokenAddress()  public view returns (address) {
        return tokenPairAddress;
    }

    function getUnlockTimeLeft() public view returns (uint) {
        return unlockLPTime - now;
    }
}