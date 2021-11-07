/**
 *Submitted for verification at BscScan.com on 2021-11-06
*/

pragma solidity ^0.8.9;

// SPDX-License-Identifier: Apache

interface IERC20 {
    function name() external view returns(string memory);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract Loker {
    
    address private _owner;
    string public _name;
    
    modifier onlyOwner{
        require(msg.sender == _owner, "Only ownered");
        _;
    }
    
    
    constructor(){
        _owner = msg.sender;
        _name = "MistickLoker V1";
    }
    
    function setName(string memory newName) public onlyOwner {
        _name = newName;
    }
    
    function name() public view returns(string memory){
        return _name;
    }
    
    function unlock(address token) public onlyOwner {
        
            IERC20 loked = IERC20(token);
            uint256 contractBalance = loked.balanceOf(address(this));
            loked.transferFrom(address(this), msg.sender, contractBalance);
        
    }
    
    function owner() public view returns(address) {
        return _owner;
    }
    
    function approve(address token , address spender, uint256 amount) external returns(bool){
        
            IERC20 loked = IERC20(token);
            loked.approve(spender, amount);
            
        return true;
        
    }
    
    function setOwner(address newOwner) public onlyOwner {
        _owner = newOwner;
    }
}