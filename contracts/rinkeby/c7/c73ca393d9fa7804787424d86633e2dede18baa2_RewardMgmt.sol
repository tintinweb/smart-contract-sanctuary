/**
 *Submitted for verification at Etherscan.io on 2021-04-05
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.6;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner, 'You must be owner');
    _;
  }
   function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }
}

contract RewardMgmt is Ownable {
    using SafeMath for uint256;
    uint256 public maxDayToken;
    uint256 public maxTransToken;
    uint256 public conversionRatio;
    TOKEN erc20;
    
     constructor() {
        owner = msg.sender;
        erc20 = TOKEN(address(0x6BE0745129Bdf354975e5A37C0dC478326c94b5c));
     }
    struct UserRewards {
        address userAddr;
		uint256 dayWithdrawn;
		uint256 lastWithdrawn;
    }
    mapping (address => UserRewards) public rewards;
    
    function redeemToken(uint256 tokenToRedeem) public returns(bool) {
       UserRewards memory user = rewards[msg.sender];
       uint256 diff = block.timestamp.sub(user.lastWithdrawn);
       
       if(diff <= 86400){
           require(user.dayWithdrawn.add(tokenToRedeem) <= maxDayToken, "You are crossing day limit");
       } 
       require(tokenToRedeem <= maxTransToken, 'You have exceeded max tokens per txions');
       erc20.transfer(msg.sender, tokenToRedeem);
       
       if(user.userAddr != address(0x0)) {
           rewards[msg.sender] = UserRewards(msg.sender, tokenToRedeem, block.timestamp);
       } else {
           if(diff <= 86400){
               rewards[msg.sender].dayWithdrawn = user.dayWithdrawn.add(tokenToRedeem);
           } else {
               rewards[msg.sender].dayWithdrawn = tokenToRedeem;
           }
               rewards[msg.sender].lastWithdrawn = block.timestamp;
       }

       return true;
    }
    
    function changeOwnership(address newOwner) onlyOwner public returns(bool) {
        transferOwnership(newOwner);
        return true;
    }
    
    /* Admin Set the day limit*/
    function setDayLimit(uint256 amount) onlyOwner public returns(bool success)  {
        maxDayToken = amount;
        return true;
    }

    /* Admin Set the transaction limit*/
    function setTranLimit(uint256 amount) onlyOwner public returns(bool success) {
        maxTransToken = amount;
        return true;
    }
    
    /* Admin Set points to token conversion ratio*/
    function setConversionRatio(uint256 ratio) onlyOwner public returns(bool success) {
        conversionRatio = ratio;
        return true;
    }
    
    
    function createPool(uint256 poolTokens) onlyOwner public {
       require(erc20.approve(address(this), poolTokens), 'Token must be approved.');
       erc20.transferFrom(msg.sender, address(this), poolTokens);
    }
    
    function poolBalance() public view returns(uint256) {
      return erc20.balanceOf(address(this));
    }
     
    function ownerBalance() public view returns(uint256) {
      return erc20.balanceOf(owner);
    }
    function userBalance() public view returns(uint256) {
      return erc20.balanceOf(msg.sender);
    }

}

abstract contract TOKEN {
     function totalSupply() external view virtual returns(uint256);
     function balanceOf(address account) external view virtual returns(uint256);
     function transfer(address recipient, uint256 amount) external virtual returns(bool);
     function allowance(address owner, address spender) external view virtual returns(uint256);
     function approve(address spender, uint256 amount) external virtual returns(bool);
     function transferFrom(address sender, address recipient, uint256 amount) external virtual returns(bool);
}