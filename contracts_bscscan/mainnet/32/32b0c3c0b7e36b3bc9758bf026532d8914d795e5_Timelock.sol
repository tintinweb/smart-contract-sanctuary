/**
 *Submitted for verification at BscScan.com on 2021-09-30
*/

// SPDX-License-Identifier: UNLICENSED 
//MARBILOCK
pragma solidity ^0.8.4;
 
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
    uint public end;
    address payable public owner;
    address payable public pendingOwner;
    uint public duration = 183 days;
    
    
    constructor(address payable _owner) {
        owner = _owner;
        end = block.timestamp + duration;
    }
    
    function deposit(address token, uint amount) external {
        IERC20(token).transferFrom(msg.sender, address(this), amount);
    }
    
    function timeLeft() public view returns (uint) {
        if (end > block.timestamp) {
            return end - block.timestamp;
        } else {
            return 0;
        }
    }
    
    /**
     * @notice Allows owner to change ownership
     * @param _owner new owner address to set
     */
    function setOwner(address payable _owner) external {
        require(msg.sender == owner, "owner: !owner");
        pendingOwner = _owner;
    }

    /**
     * @notice Allows pendingOwner to accept their role as owner (protection pattern)
     */
    function acceptOwnership() external {
        require(msg.sender == pendingOwner, "acceptOwnership: !pendingOwner");
        owner = pendingOwner;
    }
    
    function ExtendLockTime(uint locktime) public {
        require(msg.sender == owner, "only owner");
        end += locktime;
    }
    
    function getOwner() public view returns (address) {
        return owner;
    }
    
    function getEthBalance() view public returns (uint) {
        return address(this).balance;
    }
    
    function getTokenBalance(address tokenaddr) view public returns (uint) {
        return IERC20(tokenaddr).balanceOf(address(this));
    }
    
    receive() external payable {}
    
    function withdraw(address token, uint amount) external {
        require(msg.sender == owner, "only owner");
        require(block.timestamp <= end, "too early");
        if(token == address(0)) {
            owner.transfer(amount);
        } else {
            IERC20(token).transfer(owner, amount);
        }
    }
}