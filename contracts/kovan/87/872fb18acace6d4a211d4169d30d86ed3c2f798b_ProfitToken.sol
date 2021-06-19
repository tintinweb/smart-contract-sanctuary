//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "./MYERC20.sol";

contract ProfitToken is MYERC20 {

    using SafeMath for uint256;

    string  private _name;
    string  private _symbol;
    uint8   private _decimals;

    uint256 _initialAmount = 1000000;

    constructor (  string  memory symbolc) public {
        _name = "dh";
        _symbol = symbolc;
        _decimals = 18;
        _totalSupply = _initialAmount.mul(10 ** uint256(_decimals));
        _balances[msg.sender] = _initialAmount.mul(10 ** uint256(_decimals));
    }

    /**
    * @return the name of the token.
    */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
    * @return the symbol of the token.
    */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
    * @return the number of decimals of the token.
    */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

}