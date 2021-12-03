// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import './ERC20.sol';
contract AdarshSangramParty is ERC20 {
  constructor()ERC20('Adarsh Sangram Party', 'ASP') {
     _mint(msg.sender, 50000000000000000000000000*10 ** 12);
  }
}