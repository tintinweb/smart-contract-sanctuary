pragma solidity ^0.4.23;

import "./FreezableToken.sol";
import "./IKYTE.sol";

/**
 * @title KYTE Token
 *
 * @dev Constructor of the deployment
 */
contract KYTE is FreezableToken, IKYTE {
    string private _name;
    string private _symbol;
    uint256 private _decimals;

    /**
     * @dev constructor
     */
    constructor() public {
        _name = "Kambria Yield Tuning Engine";
        _symbol = "KYTE";
        _decimals = 18;
        _totalSupply = 25000000 * 10**(_decimals); // 25000000

        balances[msg.sender] = _totalSupply; // coinbase
    }

    function name() public view returns (string) {
        return _name;
    }

    function symbol() public view returns (string) {
        return _symbol;
    }

    function decimals() public view returns (uint256) {
        return _decimals;
    }
}