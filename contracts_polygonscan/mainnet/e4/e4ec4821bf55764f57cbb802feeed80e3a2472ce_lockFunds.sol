/**
 *Submitted for verification at polygonscan.com on 2021-11-28
*/

pragma solidity ^0.7.0;


contract lockFunds {
    
    string public name = "Lock Funds";
    string public symbol;
    
    uint8 public version = 4;

    address public creator;

    uint256 public fees;
    
    mapping(address => uint256) public balanceOf;
    
    mapping(address => uint256) public time;
    
    modifier notEarlier(uint256 _time){
        require(_time >= time[msg.sender]);
        _;
    }

    modifier isReady{
        require(block.timestamp >= time[msg.sender]);
        _;
    }

    modifier onlyOwner{
        require(msg.sender == creator);
        _;
    }

    constructor(uint256 _fees, string memory sym)public
    {
        creator = msg.sender;
        fees = _fees;
        symbol = sym;
    }

    function createDeposit(uint256 _timestamp) notEarlier(_timestamp) payable public{
        uint256 value = msg.value - fees;
        time[msg.sender] = _timestamp;
        balanceOf[msg.sender] = value + balanceOf[msg.sender];
        balanceOf[creator] = fees + balanceOf[creator];
    }
    
    function transfer(address _addr, uint256 _sum) public
    {
        if(balanceOf[msg.sender] >= _sum)
        {
            balanceOf[msg.sender] -= _sum;
            balanceOf[_addr] += _sum;
        }
    }

    function setFee(uint256 _fee) onlyOwner public {
        fees = _fee;
    }

    function withdraw() isReady public {
        msg.sender.transfer(balanceOf[msg.sender]);
        time[msg.sender] = 0;
        balanceOf[msg.sender] = 0;
    }
    
}