pragma solidity ^0.4.18;

contract Balance {
    mapping ( address => uint ) userBalances ;

    function getBalance (address u) public constant returns ( uint ){
        return userBalances [u];
    }
	
    function addToBalance (uint256 value) public {
        userBalances[msg.sender] += value ;
    }
}