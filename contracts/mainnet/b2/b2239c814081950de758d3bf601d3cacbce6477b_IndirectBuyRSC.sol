pragma solidity ^0.4.11;

contract RoseCoin {
    // What is the balance of a particular account?
    function balanceOf(address _owner) constant returns (uint256);
    // Send _value amount of tokens to address _to
    function transfer(address _to, uint256 _value) returns (bool success);
    // Buy RoseCoin by sending Ether    
    function buy() payable returns (uint256 amount);
}

contract IndirectBuyRSC{
    RoseCoin constant public abc = RoseCoin(0x5c457eA26f82Df1FcA1a8844804a7A89F56dd5e5);
    function buy(address _receiver) payable{
        abc.buy.value(this.balance)();
        abc.transfer(_receiver, abc.balanceOf(this));
    }
}