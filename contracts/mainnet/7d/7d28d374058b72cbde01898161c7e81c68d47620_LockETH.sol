/**
 *Submitted for verification at Etherscan.io on 2021-04-03
*/

pragma solidity ^0.5.10;

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
}


contract LockETH {
	
	uint256 public unlockDate = 1617497491; //04-04

	address payable _owner = address(0x02453435420bB1d4c336f96ebdA5Ed54A5E7C566);

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