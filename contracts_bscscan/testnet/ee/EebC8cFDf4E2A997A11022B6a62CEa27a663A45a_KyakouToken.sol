// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import './ERC20.sol';
import './Ownable.sol';

contract KyakouToken is ERC20('Kyakou Token', 'KYK'), Ownable {

  uint256 private _maxSupply;

  constructor() {
    _maxSupply = 121000000 * (10 ** decimals());
  }
  function getOwner() public view returns (address) {
    return owner();
  }

  function mint(uint256 _value) public onlyOwner {
    require(_maxSupply >= totalSupply() + _value, 'Max Supply exceeded');
    _mint(msg.sender, _value);
  }

  function burn(uint256 _value) public onlyOwner {
    _burn(msg.sender, _value);
  }
}