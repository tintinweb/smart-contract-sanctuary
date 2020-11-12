pragma solidity 0.4.24;

import "./DetailedERC20.sol";
import "./MintableToken.sol";
import "./PausableToken.sol";

contract BancannabisToken is MintableToken, PausableToken, DetailedERC20 {
    constructor(string _name, string _symbol, uint8 _decimals)
        DetailedERC20(_name, _symbol, _decimals)
        public
    {

    }
}
