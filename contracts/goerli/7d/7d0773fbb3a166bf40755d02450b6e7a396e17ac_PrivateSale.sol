// SPDX-License-Identifier: MIT

pragma solidity 0.7.3;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./Context.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

contract PrivateSale is ReentrancyGuard, Context, Ownable {
  using SafeMath for uint256;

  constructor (address _gasToken , address payable _holdingAddress, uint256 _price) {
    GAS_TOKEN = IERC20(_gasToken);
    holdingAddress = _holdingAddress;
    isFrozen = false;
    price = _price;
  }

  IERC20 private GAS_TOKEN;
  bool private isFrozen;
  uint256 public price;
  address payable private holdingAddress;

  function buy(uint256 amount) public payable nonReentrant { // replaced total with msg.value
    require(amount > 0, "Must buy an amount of tokens");
    require(msg.value >= amount.mul(price), "insufficient payment");
    require(!isFrozen, "contract is frozen");
  
    GAS_TOKEN.transferFrom(holdingAddress, _msgSender(), amount.mul(1e18));
    _safeTransfer(holdingAddress, msg.value);
  }

  function getIsFrozen() public view returns(bool) {
    return isFrozen;
  }

  function setIsFrozen(bool _isFrozen) public onlyOwner {
    isFrozen = _isFrozen;
  }

  function getPrice() public view returns(uint256) {
    return price;
  }

  function setPrice(uint256 _price) public onlyOwner {
    price = _price;
  }

  function _safeTransfer(address payable to, uint256 amount) internal {
    uint256 balance;
    balance = address(this).balance;
    if (amount > balance) {
        amount = balance;
    }
    Address.sendValue(to, amount);
  }

}