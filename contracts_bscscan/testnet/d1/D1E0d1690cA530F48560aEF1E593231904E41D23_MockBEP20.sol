pragma solidity 0.6.12;

import "./BEP20.sol";

contract MockBEP20 is BEP20 {
    constructor(
        string memory name,
        string memory symbol,
        uint256 supply
    ) public BEP20(name, symbol) {
        _setupDecimals(9);
        _mint(msg.sender, supply);

    }
}