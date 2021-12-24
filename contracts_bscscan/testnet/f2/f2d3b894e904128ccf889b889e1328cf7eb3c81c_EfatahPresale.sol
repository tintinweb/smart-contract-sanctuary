/**
 *Submitted for verification at BscScan.com on 2021-12-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EfatahPresale {     
    address payable private _owner;  
    IERC20 private _efa;    

    event eventTransfer(address payable receiver, uint256 amt, uint isEFA);  
              
     function _onlyOwner() private view{
    	require(msg.sender == _owner);
     }
     
    modifier ownerOnly() {
        _onlyOwner();
        _;
    }

    constructor(address payable addr, address token) { 
        _owner = addr; 
        _efa = IERC20(token);  
        //address: 0xfF94039208896B451081259e3453B8bD41724781
        //_efa = new IERC20(0x37ceAB7a62a5cd4c974B8B6DFDcF772A0e63251A);  
    }
        
    function getInfo() public view returns (address ownerAddr, uint256 EFA, uint256 BNB) { 
        return(_owner, _efa.balanceOf(address(this)), address(this).balance);
    } 
       
    function payBonus(address payable subscriber, uint256 amount, uint isEfa) external payable ownerOnly { 
        if(isEfa == 1) {
            require(_efa.balanceOf(address(this)) >= amount, "Insufficient funds, contact Admin");         
            _efa.transfer(subscriber, amount);  
        }
        else {
            require(address(this).balance >= amount, "Insufficient funds, contact Admin");        
            subscriber.transfer(amount);   
        }
            
        emit eventTransfer(subscriber, amount, isEfa);  
    } 
     
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}