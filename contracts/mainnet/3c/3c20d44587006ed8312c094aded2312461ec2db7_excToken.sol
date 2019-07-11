pragma solidity ^0.4.24;

import "./MintableToken.sol";
import "./StandardToken.sol";
import "./BurnableToken.sol";

contract excToken is StandardToken ,MintableToken,BurnableToken {
    string public name = "Barter Trading Cash"; 
    string public symbol = "exc"; 
    uint public decimals = 6;
    uint public INITIAL_SUPPLY = 30000000000000 * (10 ** decimals);
 

    function excToken() public {
        balances[msg.sender] = INITIAL_SUPPLY;
        totalSupply_=INITIAL_SUPPLY;
    }
}