pragma solidity ^0.5.0;

import "./ERC20Mintable.sol";
import "./ERC20Detailed.sol";

contract Token is ERC20Mintable, ERC20Detailed {

    constructor () public ERC20Detailed("GlobalEdu", "GEFT", 2) { 
    }

}