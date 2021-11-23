/**
 *Submitted for verification at Etherscan.io on 2021-11-23
*/

pragma solidity 0.8.10;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



contract Timelock {
    address private owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner, "!owner");
        _;
    }
    
    modifier ifUnlocked {
        // 1638306000
        require(block.timestamp > 1637658627);
        _;
    }
    
    function withdraw(address _addr) onlyOwner ifUnlocked public {
        IERC20 lp = IERC20(_addr);
        lp.transfer(owner, lp.balanceOf(address(this)));
    }
}