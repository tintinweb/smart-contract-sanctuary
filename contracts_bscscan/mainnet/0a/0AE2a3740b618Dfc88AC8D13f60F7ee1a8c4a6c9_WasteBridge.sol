// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "./ERC20.sol";
  
contract WasteBridge is ERC20 {
    uint256 public constant INITIAL_SUPPLY = 950000000 * 10 ** 18;
    address public admin;
    uint public hardCap;
      
    constructor() ERC20('WasteBridge', 'WASTE') {
        _mint(msg.sender, INITIAL_SUPPLY);
        hardCap = INITIAL_SUPPLY;
        admin = msg.sender;
    }
      
    function mint(uint amount) external {
        require(hardCap + amount <= 1000000000 * 10 ** 18, 'cannot mint more than 1B tokens');
        require(msg.sender == admin, 'only admin');
        hardCap += amount;
        _mint(msg.sender, amount);
    }

    function burn(uint amount) external {
        require(msg.sender == admin, 'only admin');
        _burn(msg.sender, amount);
    }
}