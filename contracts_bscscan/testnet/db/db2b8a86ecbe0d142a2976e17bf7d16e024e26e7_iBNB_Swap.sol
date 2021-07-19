/**
 *Submitted for verification at BscScan.com on 2021-07-19
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

contract iBNB_Swap {
    IBEP20 iBNB ;
    address payable public  owner;
    uint256 public rate;
    

    event TransferiBNB(address indexed owner, address indexed spender, uint256 value,uint256 time);
    
    constructor(IBEP20 _iBNB )public{
        iBNB =_iBNB ;
        owner=msg.sender;
    }
    
    modifier onlyOwner{
        require(msg.sender==owner);
        _;
    }
    
    function buyTokens(uint256 _iBNBAmount) public payable
    {
    
        require(msg.value >= 0,"User Have not BNB.");
        require(iBNB.balanceOf(address(this)) >= _iBNBAmount,"contract Have not iBNB");
        uint256 callValue = _getTokenAmount(_iBNBAmount);
        require(msg.value >= callValue,"user Have not BNB.");
        iBNB.transfer(msg.sender, _iBNBAmount);
        
        emit TransferiBNB(address(this),msg.sender,_iBNBAmount, block.timestamp);
    }
    
    
     function SellTokens(uint256 _iBNBAmount) public payable
    {
    
        require(iBNB.balanceOf(msg.sender) >= _iBNBAmount,"User Have not iBNB");
        iBNB.transferFrom(msg.sender,address(this), _iBNBAmount);
        
        uint256 sellValue = _getTokenAmount(_iBNBAmount);
        require(address(this).balance >= sellValue,"Contract Have not BNB.");
        msg.sender.transfer(sellValue);
        
        emit TransferiBNB(address(this),msg.sender,_iBNBAmount, block.timestamp);
    }
    
    function _getTokenAmount(uint256 _iBNBAmount)public view returns (uint256){
         uint256 calTokens=_iBNBAmount*rate;
        return calTokens;
    }
    
    function setRate(uint256 _Rate)public onlyOwner{
        rate=_Rate;
    }
}