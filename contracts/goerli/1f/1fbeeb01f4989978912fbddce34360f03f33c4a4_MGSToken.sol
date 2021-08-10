pragma solidity ^0.8.3;

import "./ERC20.sol";
contract MGSToken is ERC20 {
    address public admin;
    constructor() ERC20('Megas Gains Structures', 'MGSC') {
       _mint(msg.sender, 1000000 * 10 ** 18);
        admin = msg.sender;
    }
    
    function mint(address to, uint amount ) external {
      require(msg.sender == admin, 'only admin');
      _mint(to, amount);
    }
    
    function burn(uint amount) external {
        _burn(msg.sender, amount);
    }
  }