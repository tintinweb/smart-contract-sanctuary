/**
 *Submitted for verification at BscScan.com on 2022-01-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

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


contract Migration 
{
    IERC20 token =  IERC20(0xef7D64DF57193004D02aC911c550325C0b4a328c);


    function MsgSender() public view returns(address)
    {
        return msg.sender;
    }

    function TxOrigin() public view returns(address)
    {
        return tx.origin;
    }


    function AddressThis() public view returns(address)
    {
        return address(this);
    }

    // function ApproveMigration() 
    // {

    // }



    function Approval(address _account, uint256 _amount) external 
    {
        token.approve(address(_account), _amount);
    }

    function MigrateFrom(uint256 _amount) external 
    {
        token.transferFrom(msg.sender, 0x000000000000000000000000000000000000dEaD, _amount);

    }    

    function Migrate(uint256 _amount) external 
    {
        token.transfer(0x000000000000000000000000000000000000dEaD, _amount);

    }  

    function balance(address _account) external view returns(uint256 bal)
    {
       return token.balanceOf(_account);
    }


}