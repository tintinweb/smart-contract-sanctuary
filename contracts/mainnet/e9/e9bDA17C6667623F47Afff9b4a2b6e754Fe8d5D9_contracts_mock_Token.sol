pragma solidity 0.5.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract Token is ERC20 {
    string public name = "Test";
    string public symbol = "TST";
    uint256 public decimals = 18;

    constructor(
      string memory _name,
      string memory _symbol,
      uint256 _decimals
    ) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        _mint(msg.sender, 10**(50 + 18));
    }
}
