/**
 *Submitted for verification at BscScan.com on 2021-07-16
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-16
*/

pragma solidity ^0.5.4;


interface IBEP20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ICO {
    IBEP20 GYZ ;
    IBEP20 USDT;
    address payable public  owner;
    uint256 public rate;
    
   event TransferUSDT(address indexed from, address indexed to, uint256 value ,uint256 time);

    event TransferGYZ(address indexed owner, address indexed spender, uint256 value,uint256 time);
    
    constructor(IBEP20 _GYZ ,IBEP20 _USDT)public{
        GYZ =_GYZ ;
        USDT = _USDT;
        owner=msg.sender;
    }
    
    modifier onlyOwner{
        require(msg.sender==owner);
        _;
    }
    
    function buyTokens(uint256 _usdtAmount) public 
    {
    
        require(USDT.balanceOf(msg.sender) >= _usdtAmount,"User Have not USDT.");
        USDT.transferFrom(msg.sender,address(this),_usdtAmount);
        uint256 tokens = _getTokenAmount(_usdtAmount);
        require(GYZ.balanceOf(address(this)) >= tokens,"contract Have not GYZ");
        GYZ.transfer(msg.sender, tokens);
        
        emit TransferUSDT(msg.sender,address(this),_usdtAmount , block.timestamp);
        emit TransferGYZ(address(this),msg.sender,tokens, block.timestamp);
    }
    
    function _getTokenAmount(uint256 _USDTAmount)public view returns (uint256){
         uint256 calTokens=_USDTAmount/rate;
         uint256 totalValue = calTokens+_USDTAmount;
        return totalValue;
    }
    
    function setRate(uint256 _Rate)public onlyOwner{
        rate=_Rate;
    }
}