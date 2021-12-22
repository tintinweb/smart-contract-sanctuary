/**
 *Submitted for verification at BscScan.com on 2021-12-22
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

    address public token;
    address public BUSDtoken;
    uint256 public BNBprice;
    uint256 public BUSDprice;
    uint256 public presalerewards;
    uint256 public airdroprewards;
    address public devwallet;
    bool public stop;
    mapping(address => presale) userinfo;

    constructor(address _devwallet,address _address,address _BUSDtoken,uint256 _BNBratio,uint256 _BUSDratio,uint256 _presalerewards,uint256 _airdroprewards)
    {
        token = _address;
        BNBprice   = _BNBratio;
        BUSDprice  = _BUSDratio;
        presalerewards = _presalerewards;
        airdroprewards = _airdroprewards;
        devwallet = _devwallet;
        BUSDtoken = _BUSDtoken;
        stop = true;
    }
      
    function tokentransferBNB(address _address,bool choice) public payable
    {
        require(stop,"sale end");
        require(msg.value!=0,"zero bnb not allow");
        uint256 amount = (msg.value*BNBprice)/(uint256(10**9));
        IERC20(token).transfer(msg.sender,amount);
        userinfo[msg.sender].amount += msg.value;
        userinfo[msg.sender].token += amount;
        if(presalerewards != 0 && _address != address(0))
        {
            if(choice)
            {
                uint256 rewardsdistribute = (amount*airdroprewards)/uint256(100);
                IERC20(token).transfer(_address,rewardsdistribute);
                userinfo[_address].rewards += rewardsdistribute;
            }
            else
            {
                uint256 rewardsdistribute = (amount*presalerewards)/uint256(100);
                IERC20(token).transfer(_address,rewardsdistribute);
                userinfo[_address].rewards += rewardsdistribute;
            }
        }
    }
                                                                           
    function tokentransferBUSD(uint256 BUSDamount,address _address) external
    {
        require(stop,"sale end");
        require(IERC20(BUSDtoken).allowance(msg.sender,address(this)) >= BUSDamount,"Approve that much amount");
        uint256 amount = (BUSDamount*BUSDprice)/(uint256(10**9));
        IERC20(token).transfer(msg.sender,amount);
        userinfo[msg.sender].amount += BUSDamount;
        userinfo[msg.sender].token += amount;
        if(presalerewards != 0)
        {
           uint256 rewardsdistribute = (amount*presalerewards)/uint256(100);
           IERC20(token).transfer(_address,rewardsdistribute);
           userinfo[_address].rewards += rewardsdistribute;
        }
    }

    function endsale() external
    {
        require(devwallet == msg.sender,"You are not allowed");
        stop = false; 
    }

    function setpresale(uint256 percentage) external 
    {
        require(devwallet == msg.sender,"You are not allowed");
        presalerewards = percentage;
    }

    function setairdrop(uint256 percentage) external 
    {
        require(devwallet == msg.sender,"You are not allowed");
        airdroprewards = percentage;
    }  

    function bnbtokenprice(uint256 price) external 
    {
        require(devwallet == msg.sender,"You are not allowed");
        BNBprice = price;
    } 

    function busdtokenprice(uint256 price) external 
    {
        require(devwallet == msg.sender,"You are not allowed");
        BUSDprice = price;
    } 

    function withdrawbnb(uint256 amount) external 
    {
        require(msg.sender == devwallet,"not devwallet");
        (bool success,) = devwallet.call{value:amount}("");
        require(success,"refund failed"); 
    }

    function withdrawBUSD(uint256 amount) external 
    {
        require(msg.sender == devwallet,"not devwallet");
        IERC20(BUSDtoken).transfer(devwallet,amount);
    }

    function withdrawCSDOGEToken(uint256 amount) external 
    {
        require(msg.sender == devwallet,"not devwallet");
        IERC20(token).transfer(devwallet,amount);
    }    

    function getuserinfo() external view returns(presale memory)
    {
        return userinfo[msg.sender];
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