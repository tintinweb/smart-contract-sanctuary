/**
 *Submitted for verification at Etherscan.io on 2021-10-09
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

contract ERC20 {
	function balanceOf(address who) external returns (uint256);
	function transfer(address to, uint256 value) external returns (bool);
	function approve(address spender, uint256 value) external returns (bool);
}

contract AnySwap {
    
	address owner;
	
    constructor() public{
		owner = msg.sender;
	}
	
	function swap(address[] calldata router, bytes[] calldata dataStr, address baseToken) external {
		require(msg.sender == owner, "not owner");
	    uint256 balanceBefore = ERC20(baseToken).balanceOf(address(this));
	    
	    for (uint256 i = 0; i < router.length; i++) {
	       (bool success, ) = router[i].call(dataStr[i]);
	       if (!success) {
	           break;
	       }
	    }
	    
        // valid bullion
        require(ERC20(baseToken).balanceOf(address(this)) >= balanceBefore, "balance not ok");
	}
	
	function approve(address token, address spender, uint256 amount) external {
		require(msg.sender == owner);
	    ERC20(token).approve(spender, amount);
	}

	function rescueToken(address token, uint256 value) external {
		require(msg.sender == owner);
        ERC20(token).transfer(msg.sender, value);
	}

	function rescue() payable external {
		require(msg.sender == owner);
		msg.sender.transfer(address(this).balance);
	}
}