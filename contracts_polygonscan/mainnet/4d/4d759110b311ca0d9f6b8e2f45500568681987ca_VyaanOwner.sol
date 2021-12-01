/**
 *Submitted for verification at polygonscan.com on 2021-12-01
*/

pragma solidity ^0.8.0;

// SPDX-License-Identifier: none
interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function changeOwnership(address  _newOwner) external;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



contract VyaanOwner {
    address public admin;
    IERC20 public token;
    address public tokenAddress = 0x0E7903Fa2d2EB5dEB930046c8C607Fff6F670828;
    uint startTime = block.timestamp;
    
    event OwnershipTransferred(address indexed _from, address indexed _to);
    
    constructor() {
        admin = msg.sender;
        token = IERC20(tokenAddress);
    }


   // transfer Ownership to other address
    function transferOwnership(address _newOwner) public {
        require(_newOwner != address(0x0));
        require(msg.sender == admin);
        emit OwnershipTransferred(admin,_newOwner);
        admin = _newOwner;
    }
    
 // transfer Ownership to other address
    function transferTokenOwnership(address _newOwner) public {
        require(_newOwner != address(0x0));
        require(msg.sender == admin);
        require(block.timestamp >= (startTime+10 minutes),"Unlock time not reached");
        
        token.changeOwnership(_newOwner);
    }    

    
    function transferAnyBEP20Token(address _token,address to,uint amount) external{
         require(msg.sender == admin, 'only admin');
         require(token.balanceOf(address(this))>=amount);
         IERC20(_token).transfer(to,amount);
    }

    // Owner BNB Withdraw
    function withdrawBNB(address payable to, uint amount) public returns(bool) {
        require(msg.sender == admin, "Only owner");
        require(to != address(0), "Cannot send to zero address");
        to.transfer(amount);
        return true;
    }
}