/**
 *Submitted for verification at Etherscan.io on 2021-11-18
*/

pragma solidity 0.8.10;

// SPDX-License-Identifier: MIT

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

interface Token {
    function transferFrom(address, address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function balanceOf(address) external returns (uint256);
    function allowance(address, address) external returns (uint256);
}

contract TCAT_TO_VATOR is Ownable {
    
    event RewardsTransferred(address holder, uint256 amount);
    
    // TCAT token contract address
    address public tokenAddressTCAT = 0x366199645FDd391b4f2F1F37398D94750529abaa;
    
    // VATOR token contract address
    address public tokenAddressVATOR = 0x3Da1B980b6d97691F70BeD4Bd02CbA5e5EB057E5;
    
    // Team address
    address public teamAddress = 0x33Bc71bB9aBf03e08CA43f2506650DEA6fA421F9;
    
    uint256 public cliffTime = 3 days;
    
    uint256 public stakingAndDaoTokens;
    
    function getPendingDivs(address) public pure returns (uint256) {
        return 0;
    }
    
    function claimDivs() public {
        uint256 amount = getPendingDivs(msg.sender);
        require(Token(tokenAddressTCAT).transferFrom(msg.sender, teamAddress, amount), "Could not transfer token.");
        require(Token(tokenAddressVATOR).transferFrom(teamAddress, msg.sender, amount), "Could not transfer tokens.");
    }
    
    function getStakingAndDaoAmount() public pure returns (uint256) {
        return 0;
    }
    
    function setTokenAddressTCAT(address _tokenAddress) public onlyOwner {
        tokenAddressTCAT = _tokenAddress;
    }
    
    function setTokenAddressVATOR(address _tokenAddress) public onlyOwner {
        tokenAddressVATOR = _tokenAddress;
    }
    
    function setTeamAddress(address _teamAddress) public onlyOwner {
        teamAddress = _teamAddress;
    }
    
    // function to allow admin to claim *any* ERC20 tokens sent to this contract
    function transferAnyERC20Tokens(address _tokenAddress, address _to, uint256 _amount) public onlyOwner {
            
            Token(_tokenAddress).transfer(_to, _amount);
    }
}