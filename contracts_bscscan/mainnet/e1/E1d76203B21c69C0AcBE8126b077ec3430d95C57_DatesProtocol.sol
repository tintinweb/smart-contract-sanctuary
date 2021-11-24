// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

import './ERC20.sol';
import './Ownable.sol';
import './ImaxSupply.sol';

contract DatesProtocol is ERC20('Dates Protocol', 'DATES'), ImaxSupply, Ownable {

  uint256 private _maxSupply;
  address public liquidator;

  constructor() {
    _maxSupply = 1000000000 * (10 ** decimals());
  }
  function getOwner() public view returns (address) {
    return owner();
  }

  function setLiquidator(address _liquidator) external onlyOwner {
    liquidator = _liquidator;
  }
  function mint(uint256 _value) public onlyOwner {
    require(_maxSupply >= totalSupply() + _value, 'Max Supply exceeded');
    _mint(msg.sender, _value);
  }

  function mintBonus(address to, uint256 _amount) external {
    require(msg.sender == liquidator && liquidator != address(0), 'Only liquidator');
    require(_maxSupply >= totalSupply() + _amount, 'Max Supply exceeded');
    _mint(to, _amount);
  }

  function burn(uint256 _value) public onlyOwner {
    _burn(msg.sender, _value);
  }

  function maxSupply() public view override returns (uint256) {
    return _maxSupply;
  }
}