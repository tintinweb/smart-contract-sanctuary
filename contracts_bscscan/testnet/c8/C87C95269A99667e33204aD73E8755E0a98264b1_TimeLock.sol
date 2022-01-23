/**
 *Submitted for verification at BscScan.com on 2022-01-22
*/

// SPDX-License-Identifier: MIT
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


contract TimeLock{
    mapping(address => uint)public balance;
    mapping(address =>uint) public timeLock;
    IERC20 token;//0x86a6DdF3E5766365BeE95A17541d3a6455887482
    uint public constant lockTime = 5 hours;
    constructor(IERC20 adrToken){
        token = adrToken;
    }
    function AddLock()public{
        uint blc = token.balanceOf(msg.sender);
        balance[msg.sender] +=blc;
        //token.transferFrom(msg.sender, address(this), blc);
        require( token.transferFrom(msg.sender, address(this), blc));//transferimos desde el sender que es el usuario al contrato!
        timeLock[msg.sender] = block.timestamp + lockTime;

    }
    function WhenUnlock(address adr)public view returns(uint){
        uint t = timeLock[adr] - block.timestamp;//90 -24  = 66 dias aun.    90-100 = 0ok
        return t;
    }
    function Withdraw()public{
        uint t = timeLock[msg.sender] - block.timestamp;
        require(t<=1, "Still Lock");
        uint balanceToSend = balance[msg.sender];
        balance[msg.sender]= 0;
        require( token.transfer(msg.sender,balanceToSend));
    }
}