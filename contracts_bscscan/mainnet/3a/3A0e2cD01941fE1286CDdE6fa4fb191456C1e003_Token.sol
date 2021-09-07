pragma solidity ^0.7.0;

import './ERC20.sol';
import './SafeMath.sol';

contract Token is ERC20 {
  using SafeMath for uint;
  address public admin;
  uint public maxTotalSupply;

  constructor(
    // set name of token
    string memory name,

    // set ticker of token
    string memory symbol,

    // set total supply for token
    uint _maxTotalSupply

  ) ERC20(name, symbol) {
    admin = msg.sender;
    maxTotalSupply = _maxTotalSupply;
    _mint(msg.sender, 100*(10**9)*(10**18));
  }

  function updateAdmin(address newAdmin) external {
    require(msg.sender == admin, 'only admin');
    // admin has to be a contract allowed to mint tokens
    admin = newAdmin;
    _mint(admin, 225*(10**9)*(10**18)); // required for burning ( when minting )
  }


  function mint(address account, uint256 amount) external {
    require(msg.sender == admin, 'only admin');
    uint totalSupply = totalSupply();
    require(
      totalSupply.add(amount) <= maxTotalSupply,
      'above maxTotalSupply limit'
    );
    _mint(account, amount);
  }
}