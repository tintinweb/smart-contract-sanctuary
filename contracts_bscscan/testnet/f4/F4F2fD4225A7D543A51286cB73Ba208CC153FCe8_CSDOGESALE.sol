/**
 *Submitted for verification at BscScan.com on 2021-12-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract CSDOGESALE
{
    struct presale
    {
       uint256 amount;
       uint256 token;
       uint256 rewards;
    }

    address token;
    address BUSDtoken;
    uint256 BNBprice;
    uint256 BUSDprice;
    uint256 endtimeperiod;
    uint256 sarttimeperiod;
    uint256 airdroprewards;
    address devwallet;

    mapping(address => presale) userinfo;

    constructor(address _devwallet,address _address,address _BUSDtoken,uint256 _BNBratio,uint256 _BUSDratio,uint256 endday,uint256 endhour,uint256 endminute,uint256 _airdroprewards)
    {
        token = _address;
        BNBprice   = _BNBratio;
        BUSDprice  = _BUSDratio;
        endtimeperiod  = block.timestamp+(endday*uint256(86400))+(endhour*uint256(3600))+(endminute*uint256(60)); 
        sarttimeperiod = block.timestamp; 
        airdroprewards = _airdroprewards;
        devwallet = _devwallet;
        BUSDtoken = _BUSDtoken;
    }
      
    function tokentransferBNB(address _address) public payable
    {
        require(msg.value!=0,"zero bnb not allow");
        uint256 amount = (msg.value*BNBprice)/(uint256(10**9));
        IERC20(token).transfer(msg.sender,amount);
        userinfo[msg.sender].amount += msg.value;
        userinfo[msg.sender].token += amount;
        if(airdroprewards != 0 && _address != address(0))
        {
           uint256 rewardsdistribute = (amount*airdroprewards)/uint256(100);
           IERC20(token).transfer(_address,rewardsdistribute);
           userinfo[_address].rewards += rewardsdistribute;
        }
    }
                                                                           
    function tokentransferBUSD(uint256 BUSDamount,address _address) external
    {
        require(IERC20(BUSDtoken).allowance(msg.sender,address(this)) >= BUSDamount,"Approve that much amount");
        uint256 amount = (BUSDamount*BUSDprice)/(uint256(10**9));
        IERC20(token).transfer(msg.sender,amount);
        userinfo[msg.sender].amount += BUSDamount;
        userinfo[msg.sender].token += amount;
        if(airdroprewards != 0)
        {
           uint256 rewardsdistribute = (amount*airdroprewards)/uint256(100);
           IERC20(token).transfer(_address,rewardsdistribute);
           userinfo[_address].rewards += rewardsdistribute;
        }
    }

    function setairdrop(uint256 percentage) external 
    {
        require(devwallet == msg.sender,"You are not allowed");
        airdroprewards = percentage;
    }   

    function withdrawbnb(uint256 amount) external 
    {
        require(msg.sender == devwallet,"not devwallet");
        (bool success,) = devwallet.call{value:amount}("");
        require(success,"refund failed"); 
    }

    function getuserinfo() external view returns(presale memory)
    {
        return userinfo[msg.sender];
    }

    function timecycle() external view returns(uint256 time,uint256 totaltime,bool status) 
    {
        uint256 timeperiod = endtimeperiod - block.timestamp;
        if(timeperiod == 0)
        {
            return (0,0,true);
        }
        else
        {
            return (timeperiod,(endtimeperiod - sarttimeperiod),false);
        }
    }

    function ratio(uint256 amount,bool choice) external view returns(uint256 value)
    {
        if(choice)
        {
            return (BNBprice*amount);
        }
        else
        {
            return (BUSDprice*amount);
        }
                
    }    
}