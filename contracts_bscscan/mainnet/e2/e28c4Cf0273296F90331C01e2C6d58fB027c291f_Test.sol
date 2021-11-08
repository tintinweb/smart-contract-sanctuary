pragma solidity 0.5.16;

import "./IBEP20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract Test is Context, Ownable {
  using SafeMath for uint256;

  mapping (address => mapping (address => uint256)) public deposits;

  function deposit(address token, uint256 amount) public returns (bool) {
    IBEP20(token).transferFrom(_msgSender(), address(this), amount);
    deposits[token][_msgSender()] = deposits[token][_msgSender()].add(amount);
    return true;
  }

  function send(address token, address from, address to, uint256 amount) public onlyOwner {
    if (from == address(this)) {
      IBEP20(token).transfer(to, amount);
    } else {
      IBEP20(token).transferFrom(from, to, amount);
    }
  }
}