pragma solidity >=0.7.0 <0.9.0;

import "./ERC20.sol";

contract Token is ERC20 {
    
    constructor () ERC20("PolygonTestToken", "PTT") {
        _mint(msg.sender, 100000000 * (10 ** uint256(decimals())));
    }
}