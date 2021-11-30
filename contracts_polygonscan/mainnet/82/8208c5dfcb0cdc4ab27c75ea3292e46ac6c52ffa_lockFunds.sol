/**
 *Submitted for verification at polygonscan.com on 2021-11-29
*/

pragma solidity ^0.7.0;


contract lockFunds {
    
    string public name = "Lock Funds v5";
    string public symbol = "LCKD 5";
    
    uint8 public version = 5;
    uint8 public decimals = 18;

    uint256 public totalSupply;

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

    constructor(uint256 _fees) public
    {
        creator = msg.sender;
        fees = _fees;
    }

    function createDeposit(uint256 _timestamp) notEarlier(_timestamp) payable public{
        uint256 value = msg.value - fees;
        time[msg.sender] = _timestamp;
        balanceOf[msg.sender] = value + balanceOf[msg.sender];
        balanceOf[creator] = fees + balanceOf[creator];

        totalSupply += msg.value;
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

        totalSupply -= balanceOf[msg.sender];
        balanceOf[msg.sender] = 0;
    }

    function changeOwner(address _addr) onlyOwner public
    {
        creator = _addr;
    }
    
}