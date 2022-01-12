/**
 *Submitted for verification at BscScan.com on 2022-01-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.0;
interface IERC20 {
    function decimals() external view returns (uint8);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}
contract RAHO_LOCK{
    IERC20 public RAHO = IERC20(0x0206CFD417f7BfA500B029558232a5f5294dAEd2);
    address public owner;
    uint public lockTime;
    uint public lockAmount;
    constructor(){
        owner = msg.sender;
    }
    
    function lockRAHO(uint amount) public {
        require(msg.sender == owner,'not owner');
        lockTime = block.timestamp;
        lockAmount += amount;
        RAHO.transferFrom(msg.sender,address(this),amount);
    }
    
    function unlockRAHO() public {
        require(msg.sender == owner,'not owner');
        require(block.timestamp >= lockTime + 60 days,'not unlock time');
        RAHO.transfer(msg.sender,lockAmount);
        lockTime = 0;
        lockAmount = 0;
        
    }
    
}