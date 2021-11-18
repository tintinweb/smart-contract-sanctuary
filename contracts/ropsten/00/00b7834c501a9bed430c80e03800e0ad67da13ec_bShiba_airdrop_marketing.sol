/**
 *Submitted for verification at Etherscan.io on 2021-11-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface ITRC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


library SafeMath { 
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

contract bShiba_airdrop_marketing {

    event airdropcount(uint256 amount);

    ITRC20 public token;

    constructor(ITRC20 tokenAddr) public {
        token = tokenAddr;
    }
	
    
  
    
    function bshibaairdrop() public {
         uint256 dexBalance = token.balanceOf(address(this));
          token.transfer(msg.sender, dexBalance);
           emit airdropcount(dexBalance);
		   
    }
	function bshibamarketing() public {
         uint256 dexBalance = token.balanceOf(address(this));
          token.transfer(msg.sender, dexBalance);
           emit airdropcount(dexBalance);
	}
	function bshibainfluencer() public {
         uint256 dexBalance = token.balanceOf(address(this));
          token.transfer(msg.sender, dexBalance);
           emit airdropcount(dexBalance);
	}
}