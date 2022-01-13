// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract Token is ERC20, ERC20Burnable, Ownable {
  constructor (string memory _name, string memory _symbol, uint256 _supply, uint256 _fee, address _feeOwner ) ERC20(_name, _symbol) {
    _mint(msg.sender, _supply * 10 ** 18);

    setFee(_fee);
    setFeeOwner(_feeOwner);
  }

  function setFee(uint256 _fee) public onlyOwner returns (bool) {
    fee = _fee;
    return true;
  }

  function setFeeOwner(address _feeOwner) public onlyOwner returns (bool) {
    feeOwner = _feeOwner;
    return true;
  }

}