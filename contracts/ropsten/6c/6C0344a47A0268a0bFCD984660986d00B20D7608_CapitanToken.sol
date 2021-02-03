pragma solidity >=0.4.25 <0.7.0;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

contract CapitanToken is ERC20 {
    // Set token parameters

    constructor(
        string memory name,
        string memory symbol,
        uint256 INITIAL_SUPPLY
    ) public ERC20(name, symbol) {
        _mint(msg.sender, INITIAL_SUPPLY);
    }
}