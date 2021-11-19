pragma solidity ^0.5.0;

import "./Context.sol";
import "./ERC20.sol";
import "./ERC20Detailed.sol";

contract COOK is Context, ERC20, ERC20Detailed {
    
    constructor () public ERC20Detailed("Poly-Peg COOK", "COOK", 18) {
        _mint(0xd3b90E2603D265Bf46dBC788059AC12D52B6AC57, 10000000000*10**18);
    }
}