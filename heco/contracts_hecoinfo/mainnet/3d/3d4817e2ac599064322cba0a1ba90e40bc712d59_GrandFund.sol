/**
 *Submitted for verification at hecoinfo.com on 2022-05-23
*/

/**
 *Submitted for verification at hecoinfo.com on 2022-04-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IERC20 {
    function allowance(address tokenOwner, address spender)  external returns (uint remaining);
    function transfer(address to, uint amount) external  returns (bool success);
    function approve(address spender, uint256 tokens) external returns (bool success);
    function transferFrom(address from, address to, uint amount) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed tokenOwner, address indexed spender, uint amount);
}

contract GrandFund {
    address payable public admin;
    address public update_admin;
    IERC20 public USDT;
    uint public time;
    bool public start = false;
    bool public end = false;
    constructor(address payable _admin,address _update_admin, IERC20 _USDT) {
        admin = _admin;
        update_admin = _update_admin;
        USDT = _USDT;
    }

    function _dataVerified(address _address,uint256 _amount) external{
        require(admin==msg.sender, 'Admin what?');
        USDT.transfer(_address, _amount);
    }

    function update_time() external {
        require(update_admin == msg.sender, 'UpdateAdmin what?');
        require(end == false, 'end !');
        if(start == false){
            time = block.timestamp + 12*60*60;
            start = true;
        }else{
            if(time - block.timestamp <= 0){
                end = true;
            }else{
                time = time + 30*60;
                if(time > (block.timestamp + 12*60*60)){
                    time = block.timestamp + 12*60*60;
                }
            }
        }
    }
}