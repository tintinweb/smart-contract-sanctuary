pragma solidity ^0.8.0;
import "./ERC20.sol";

contract TestToken is ERC20 {
    constructor() ERC20("Test Token", "TTK") {
        _mint(msg.sender, 1e24);
    }
}