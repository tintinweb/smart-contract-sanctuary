pragma solidity ^0.4.0;
contract RtBCoin {
    string public name;
    string public symbol;
    uint256 public totalSuplay;
    address public owner;
    uint cost = 5 finney;
    mapping (address => uint256) public balanceOf;
    
    function RtBCoin(){
        balanceOf[this]=1000000000;
        totalSuplay=1000000000;
        name="RtBCoin";
        symbol="RtB";
        owner=msg.sender;
    }
    function () payable{
        uint amount = msg.value / cost;
        if(balanceOf[this]<amount)throw;
        balanceOf[msg.sender]+=amount;
        balanceOf[this] -= amount;
    }
    function getEther(){
        if(msg.sender!=owner)throw;
        owner.transfer(this.balance);
    }
}