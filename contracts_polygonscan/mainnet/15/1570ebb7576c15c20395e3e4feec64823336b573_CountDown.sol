/**
 *Submitted for verification at polygonscan.com on 2021-08-13
*/

pragma solidity 0.5.8;

contract CountDown {
    address private owner;
	uint256 public startTime = 0;

	constructor() public {
		owner = msg.sender;
	}
	
    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    } 	
    
    function updateStartTime(uint unixTime) external onlyOwner {
        startTime = unixTime;
    } 	

	function getLaunchTime() public view returns(uint256) {
		return minZero(startTime, block.timestamp);
	}
	
    function minZero(uint a, uint b) private pure returns(uint) {
        if (a > b) {
           return a - b; 
        } else {
           return 0;    
        }    
    }	
}