/**
 *Submitted for verification at Etherscan.io on 2019-07-10
*/

pragma solidity >=0.4.22 <0.6.0;

contract Splitter {
    mapping (address => uint) balances;

    event Splitted(address indexed _bob, address indexed _carol, uint256 _value);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    constructor() public payable {
    }

    function split(address bob, address carol) public payable returns(bool status){

        // To check if the amount to be send is positive or not.
        assert(msg.value > 0);
        
        uint msgValueAmountByTwo = msg.value/2;

        // To check if the amount can be divided by two equally or if there is any truncated numbers
        assert(msgValueAmountByTwo + msgValueAmountByTwo == msg.value);

        // Balances of Bob and Carol is updated
        balances[bob] += msgValueAmountByTwo;
        balances[carol] += msgValueAmountByTwo;

        emit Splitted(bob, carol, msgValueAmountByTwo);
        return true;
    }
    
    function getBalanceOf(address check) public view returns(uint amount){
        return balances[check];
    }
    
    // https://stackoverflow.com/a/52438518/7520013
    function withdraw(uint amount) public returns(bool status){
        require(balances[msg.sender] > 0, "Nothing to withdraw");
        require(balances[msg.sender] >= amount, "Withdraw amount requested higher than balance");

        balances[msg.sender] -= amount;
        msg.sender.transfer(amount);

        emit Transfer(address(this), msg.sender, amount);
        return true;
    }
}