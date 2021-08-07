// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./Ownable.sol";
import "./ERC20Burnable.sol";
import "./ERC20.sol";

contract EtherRockDAO is ERC20,Ownable, ERC20Burnable {


  function burnFrom(address account, uint256 amount) public onlyOwner override {

      _burn(account, amount);
  }

  function mint(address account, uint256 amount) public onlyOwner {
      _mint(account, amount);
  }



  function burnFromBatch(address[] memory accounts, uint256[] memory amounts) public onlyOwner {
      _burnFromBatch(accounts, amounts);
  }

  function mintFromBatch(address[] memory accounts, uint256[] memory amounts) public onlyOwner {

      _mintFromBatch(accounts, amounts);
  }

  function transfer(address recipient, uint256 amount) public onlyOwner override returns (bool) {
      _transfer(_msgSender(), recipient, amount);
      return true;
  }

}