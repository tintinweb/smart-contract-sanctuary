// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.5;

import "./ERC20.sol";
  
contract WasteBridgeToken is ERC20 {
    uint256 public constant INITIAL_SUPPLY = 4000000000 * 10 ** 18;
    address public admin;
    uint public hardCap;
      
    constructor() ERC20('WasteBridge', 'WASTE') {
        _mint(msg.sender, INITIAL_SUPPLY);
        hardCap = INITIAL_SUPPLY;
        admin = msg.sender;
    }
      
    function mint(uint amount) external {
        hardCap += amount;
        require(hardCap <= 10000000000 * 10 ** 18, 'cannot mint more than 10B tokens');
        require(msg.sender == admin, 'only admin');
        _mint(msg.sender, amount);
    }

    function burn(uint amount) external {
        require(msg.sender == admin, 'only admin');
        _burn(msg.sender, amount);
    }
}