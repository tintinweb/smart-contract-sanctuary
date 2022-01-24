/**
 *Submitted for verification at BscScan.com on 2022-01-24
*/

pragma solidity >= 0.5.17;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract FreeportTeamLock{
	address manager;
	uint256 public TimeLock = 1737388800; //Unlock at Tue Jan 21 2025 00:00:00 UTC+0800.
	
    constructor() public {
        manager = msg.sender;
    }

    modifier onlyManager{
        require(msg.sender == manager, "Not manager");
        _;
    }

    function changeManager(address _new_manager) public {
        require(msg.sender == manager, "Not superManager");
        manager = _new_manager;
    }

    function withdraw() external onlyManager{
        (msg.sender).transfer(address(this).balance);
    }

    function withdrawTokens(address tokenAddr) external onlyManager{
        require(isUnlocked(), "Freeport Lock : Time lock not released.");
        require(IERC20(tokenAddr).transfer(msg.sender, 50000000 * 10 ** uint(18)));
		TimeLock += 31536000;
    }

    function isUnlocked() public view returns (bool) {
        return now >= TimeLock;
    }
	
	function destroy() external onlyManager{ 
        selfdestruct(msg.sender); 
	}
}