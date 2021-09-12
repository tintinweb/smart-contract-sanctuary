/**
 *Submitted for verification at polygonscan.com on 2021-09-12
*/

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract Locker {
    address public BloodySwap = 0x67617B91Ccd1428D00004fAF6d3a320eF306a1AE;
    address public RugDoc = 0x8a3A27Ae9C4457739265D92D14AADC0594236aB1;
    
    uint256 public unlockTimestamp;
    
    bool public unlocked = false;
    
    constructor() {
        unlockTimestamp = block.timestamp + 60 * 60 * 24 * 365; // 1 year lock
    }
    function withdraw(IERC20 token) external {
        require(msg.sender == BloodySwap, "not bloodyswap");
        require(block.timestamp > unlockTimestamp || unlocked, "locked");
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }
    
    function rugdocUnlock() external {
        require(msg.sender == RugDoc);
        unlocked = true;
    }
    
}