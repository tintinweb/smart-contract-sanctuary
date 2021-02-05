pragma solidity 0.8.0;

import "./ERC20.sol";
import "./IERC20.sol";


contract Token is ERC20 {
    
    constructor() ERC20("BilionToken", "BLT") {
        
    }
    
}