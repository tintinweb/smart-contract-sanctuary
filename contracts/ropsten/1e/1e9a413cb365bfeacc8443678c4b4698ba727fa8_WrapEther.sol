pragma solidity ^0.4.24;


contract WrapEther {
    mapping (address => uint256) private balances;
    
    function () public payable{
        deposit(msg.sender);
    }
    function deposit(address _depositFrom) public payable{
        uint256 amount = msg.value;
        balances[_depositFrom] = amount;
    }
    function withdraw() public{
        balances[msg.sender] = 0;
        msg.sender.transfer(balances[msg.sender]);
    }
    function balance() public view returns(uint256 balanceOf){
        balanceOf = balances[msg.sender];
        return balanceOf;
    }
}