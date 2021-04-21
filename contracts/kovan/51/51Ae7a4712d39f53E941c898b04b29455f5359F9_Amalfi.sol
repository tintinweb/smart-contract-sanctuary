// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./SafeMath.sol";
import "./Address.sol";
import "./Ownable.sol";

 /**
  * @title Amalfi
  * @dev Basic trust contract, holds funds designated for a payee until a
  * maturity date when they may be withdrawn.
  */
contract Amalfi is Ownable {
  using SafeMath for uint256;
  using Address for address payable;

  event MaturitySet(address indexed payee, uint maturity);
  event Deposited(address indexed payee, uint256 weiAmount);
  event Withdrawn(address indexed payee, uint256 weiAmount);
  event FeeDeposited(address indexed payee, uint256 weiAmount);

  mapping(address => uint256) private _deposits;
  mapping(address => uint) private _maturities;
  uint256 public _feeBasisPoints = 10;


  function depositsOf(address payee) public view returns (uint256) {
    return _deposits[payee];
  }

  function maturityOf(address payee) public view returns (uint) {
    return _maturities[payee];
  }

  function setMaturity(address payee, uint maturity) public {
    require(_maturities[payee] == 0, "Maturity has already been set.");
    require(payee != owner(), "You can't set the maturity of the owner.");
    require(block.timestamp < maturity, "Maturity must be in the future.");

    _maturities[payee] = maturity;

    emit MaturitySet(payee, maturity);
  }

  function deposit(address payee) public payable {
    require(block.timestamp < _maturities[payee], "Maturity not valid.");
    uint256 total = msg.value;

    if (owner() != address(0)) {
      uint256 fee = total.mul(_feeBasisPoints).div(10000);

      depositFunds(payee, total.sub(fee));
      depositFee(fee);

    } else {
      depositFunds(payee, total);
    }
  }

  function depositFunds(address payee, uint256 amount) private {
    _deposits[payee] = _deposits[payee].add(amount);

    emit Deposited(payee, amount);
  }

  function depositFee(uint256 fee) private {
    address owner = owner();
    require(owner != address(0), "No owner exists.");
    _deposits[owner] = _deposits[owner].add(fee);

    emit FeeDeposited(owner, fee);
  }

  function withdraw() public {
    address payable payee = _msgSender();
    uint256 payment = _deposits[payee];

    require(block.timestamp > _maturities[payee], "Trust not mature yet.");

    _deposits[payee] = 0;
    _maturities[payee] = 0;
    payee.sendValue(payment);

    emit Withdrawn(payee, payment);
  }
}