pragma solidity ^0.4.24;


import "./StandardToken.sol";


contract excToken is StandardToken {
    string public name = "Smart Barter Exchange System"; 
    string public symbol = "exc"; //통화단위
    uint public decimals = 6; //자리수
    uint public INITIAL_SUPPLY = 30000000000000 * (10 ** decimals); //초기 공급량
 
    //생성자
    function excToken() public {
        balances[msg.sender] = INITIAL_SUPPLY;
    }
}