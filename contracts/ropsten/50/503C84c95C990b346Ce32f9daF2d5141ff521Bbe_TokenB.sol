pragma solidity ^0.8.0;

import './StandardToken.sol';
import './SafeMath.sol';
////////////////////////////////////////////////////////////////////////////////

/*
 * SimpleToken
 *
 * Very simple ERC20 Token example, where all tokens are pre-assigned
 * to the creator. Note they can later distribute these tokens
 * as they wish using `transfer` and other `StandardToken` functions.
 */
contract TokenB is StandardToken {
    using SafeMath for uint256;

    string public name = "Token B";
    string public symbol = "TKB";
    uint256 public decimals = 18;
    uint256 public INITIAL_SUPPLY = 10**(50+18);

    constructor (string memory _name, string memory _symbol, uint256 _decimals) {
        totalSupply = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    event Burn(address indexed _burner, uint256 _value);

    function burn(uint256 _value) public returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(msg.sender, _value);
        emit Transfer(msg.sender, address(0x0), _value);
        return true;
    }

    // save some gas by making only one contract call
    function burnFrom(address _from, uint256 _value) public returns (bool) {
        transferFrom( _from, msg.sender, _value );
        return burn(_value);
    }
}