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
    
    uint256 public cliffTime = 0;
    
    uint256 public totalClaimedRewards = 0;
    
    uint256 public stakingAndDaoTokens = 100000000e18;
    
    // TCAT token contract address
    address public tokenAddressTCAT = 0x0E84D86C3745A05D65f8051407249cd1c4970346;
    
    // VATOR token contract address
    address public tokenAddressVATOR = 0x051Bda85FbC58AcE9D6060Ba9488aBE120ac072D;
    
    // Team address
    address public teamAddress = 0xD938FFD144253d61Ae7f26194E84fe9929de7b4b;
    
    bool public isSwapEnable = false;
    
    function updateAccount(address account) private {
        uint256 pendingDivs = getPendingDivs(account);
    }
    
    function getPendingDivs(address _holder) public view returns (uint256) {
        
        uint256 pendingDivs = 0;
            
        return pendingDivs;
    }
    
    function deposit(uint256 amountToStake) public {
    }
    
    function withdraw(uint256 amountToWithdraw) public onlyOwner {
        Token(tokenAddressTCAT).transfer(msg.sender, amountToWithdraw);
    }
    
    function claimDivs() public {
        require(isSwapEnable, "Swap not enabled !!!");
        uint256 amount = Token(tokenAddressTCAT).balanceOf(msg.sender);
        require(Token(tokenAddressTCAT).allowance(msg.sender, address(this)) >= amount);
        require(Token(tokenAddressTCAT).transferFrom(msg.sender, teamAddress, amount), "Could not transfer token.");
        require(Token(tokenAddressVATOR).transferFrom(teamAddress, msg.sender, amount), "Could not transfer tokens.");
    }
    
    function getStakingAndDaoAmount() public view returns (uint256) {
        uint256 remaining = stakingAndDaoTokens;
        return remaining;
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
    
    function startSwap() public onlyOwner {
        isSwapEnable = true;
    }
    
    function stopSwap() public onlyOwner {
        isSwapEnable = false;
    }
    
    // function to allow admin to claim *any* ERC20 tokens sent to this contract
    function transferAnyERC20Tokens(address _tokenAddress, address _to, uint256 _amount) public onlyOwner {
            
            Token(_tokenAddress).transfer(_to, _amount);
    }
}