/**
 *Submitted for verification at Etherscan.io on 2021-04-15
*/

pragma solidity ^0.5.10;

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
}


contract VaultETH {
	
	uint256 public unlockDate = 1735689661; //01-01-2025

	address payable _owner = address(0x9faa4Eb1a6d569b7fBD4Df10b6c875bDf56c8a8D);

    modifier onlyOwner() {
        require(msg.sender == _owner, "need owner");
        _;
    }
    
    constructor () public{
	}

	function () external payable{
		if(block.timestamp > unlockDate){
			_owner.transfer(address(this).balance);
		}
		emit Received(msg.sender, msg.value);
	}
	
	function setApprove(address _token, address spender,uint256 amount) public onlyOwner{
		IERC20(_token).approve(spender, amount);	
	}
	
	event Received(address from, uint256 amount);
	
}