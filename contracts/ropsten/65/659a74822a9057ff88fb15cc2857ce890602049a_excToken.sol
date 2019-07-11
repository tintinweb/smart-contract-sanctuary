pragma solidity ^0.4.24;


import "./StandardToken.sol";
import "./BurnableToken.sol";
import "./MintableToken.sol";

contract excToken is StandardToken,BurnableToken,MintableToken {
    string public name = "testyo"; 
    string public symbol = "yoyo"; //통화단위
    uint public decimals = 6; //자리수
    uint256 public totalSupply = 30000000000000 * (10 ** decimals); //초기 공급량
    //uint256 public totalSupply = INITIAL_SUPPLY;
    
    //생성자
    function excToken() public {
        balances[msg.sender] = totalSupply;
    }
}