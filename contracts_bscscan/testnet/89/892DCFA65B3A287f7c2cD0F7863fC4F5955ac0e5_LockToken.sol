/**
 *Submitted for verification at BscScan.com on 2022-01-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
//锁定周期
contract LockToken{
    //锁定的币种
    struct lockStruct{
        uint depositTime;//锁定时间
        uint amount;//质押金额
        bool isLock;//是否已锁定
    }

    event LockFunction(address indexed from, address indexed to, uint256 value);
    event RedeemFunction(address indexed from, address indexed to, uint256 value);

    uint public cycle = 2 minutes;//365 days;
    mapping (address => lockStruct) public lock;
    address private LPAdress = 0xFee8d92180b7D3B2bD5387E248d8dc651AD1B5E3;

    function setPeaceAdress(address adr_)public{
        LPAdress = adr_;
    }
    //锁定
    function lockFunction(uint amount_) public {
        require (IERC20(LPAdress).balanceOf(msg.sender) >= amount_, "no money");
        
        lock[msg.sender].amount += amount_;
        lock[msg.sender].depositTime = block.timestamp;
        lock[msg.sender].isLock = true;

        IERC20(LPAdress).transferFrom(msg.sender,address(this),amount_);
        emit LockFunction(msg.sender, address(this),amount_);
    }

    //赎回
    function redeemFunction() public {
        require (block.timestamp >= lock[msg.sender].depositTime + cycle , "Time is not up");

        IERC20(LPAdress).transfer(msg.sender,lock[msg.sender].amount);
        emit RedeemFunction(msg.sender , address(this) , lock[msg.sender].amount);
        lock[msg.sender].amount = 0;
        lock[msg.sender].depositTime = 0;
        lock[msg.sender].isLock = false;
    }

    function setCycleTime(uint minute) public {
        cycle = minute*60;
    }
}