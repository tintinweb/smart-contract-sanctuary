pragma solidity ^0.5.8;

import "./Context.sol";
import "./ITRC20.sol";
import "./BaseTRC20.sol";

contract CFCOToken is ITRC20, TRC20Detailed {
    constructor(address gr) public TRC20Detailed("CFCO TOKEN", "CFCO", 5){
        require(gr != address(0), "invalid gr");
        _mint(gr, 8000000 * 10 ** 5);
    }
}