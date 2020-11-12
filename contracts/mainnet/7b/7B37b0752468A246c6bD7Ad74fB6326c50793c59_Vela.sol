pragma solidity ^0.6.0;

import "./ERC20.sol";

contract Vela is ERC20 {
    constructor() public ERC20("Vela", "Vela") {
        _mint(msg.sender, 100000000*(10**uint256(decimals())));
    }
}
