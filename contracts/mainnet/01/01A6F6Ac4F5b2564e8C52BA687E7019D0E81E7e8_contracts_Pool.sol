// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;

import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol";
import "./OwnerPausable.sol";

contract Pool is Initializable, OwnableUpgradeSafe, OwnerPausable {
  using SafeMath for uint256;
  uint public sharePrice;
  uint mantissa;
  uint public totalShares;
  mapping(address => uint) public capitalProviders;
  address public erc20address;
  string name;
  uint public totalFundsLimit = 0;
  uint public transactionLimit = 0;

  event DepositMade(address indexed capitalProvider, uint amount);
  event WithdrawalMade(address indexed capitalProvider, uint amount);
  event TransferMade(address indexed from, address indexed to, uint amount);
  event InterestCollected(address indexed payer, uint amount);
  event PrincipalCollected(address indexed payer, uint amount);
  event LimitChanged(address indexed owner, string limitType, uint amount);

  function initialize(address _erc20address, string memory _name, uint _mantissa) public initializer {
    __Context_init_unchained();
    __Ownable_init_unchained();
    __OwnerPausable__init();
    name = _name;
    erc20address = _erc20address;
    mantissa = _mantissa;
    sharePrice = _mantissa;

    // Sanity check the address
    ERC20UpgradeSafe(erc20address).totalSupply();

    // Unlock self for infinite amount
    ERC20UpgradeSafe(erc20address).approve(address(this), uint(-1));
  }

  function deposit(uint amount) external payable whenNotPaused {
    require(transactionWithinLimit(amount), "Amount is over the per-transaction limit.");
    // Determine current shares the address has, and the amount of new shares to be added
    uint currentShares = capitalProviders[msg.sender];
    uint depositShares = getNumShares(amount, mantissa, sharePrice);
    uint potentialNewTotalShares = totalShares.add(depositShares);
    require(poolWithinLimit(potentialNewTotalShares), "Deposit would put the Pool over the total limit.");

    doERC20Transfer(msg.sender, address(this), amount);

    // Add the new shares to both the pool and the address
    totalShares = totalShares.add(depositShares);
    capitalProviders[msg.sender] = currentShares.add(depositShares);

    emit DepositMade(msg.sender, amount);
  }

  function withdraw(uint amount) external whenNotPaused {
    // Determine current shares the address has and the shares requested to withdraw
    require(transactionWithinLimit(amount), "Amount is over the per-transaction limit");
    uint currentShares = capitalProviders[msg.sender];
    uint withdrawShares = getNumShares(amount, mantissa, sharePrice);

    // Ensure the address has enough value in the pool
    require(withdrawShares <= currentShares, "Amount requested is greater than what this address owns");

    // Remove the new shares from both the pool and the address
    totalShares = totalShares.sub(withdrawShares);
    capitalProviders[msg.sender] = currentShares.sub(withdrawShares);

    // Send the amount to the address
    doERC20Transfer(address(this), msg.sender, amount);
    emit WithdrawalMade(msg.sender, amount);
  }

  function collectInterestRepayment(address from, uint amount) external whenNotPaused {
    doERC20Transfer(from, address(this), amount);
    uint increment = amount.mul(mantissa).div(totalShares);
    sharePrice = sharePrice + increment;
    emit InterestCollected(from, amount);
  }

  function collectPrincipalRepayment(address from, uint amount) external whenNotPaused {
    // Purposefully does nothing except receive money. No share price updates for principal.
    doERC20Transfer(from, address(this), amount);
    emit PrincipalCollected(from, amount);
  }

  function setTotalFundsLimit(uint amount) public onlyOwner whenNotPaused {
    totalFundsLimit = amount;
    emit LimitChanged(msg.sender, "totalFundsLimit", amount);
  }

  function setTransactionLimit(uint amount) public onlyOwner whenNotPaused {
    transactionLimit = amount;
    emit LimitChanged(msg.sender, "transactionLimit", amount);
  }

  function transferFrom(address from, address to, uint amount) public onlyOwner whenNotPaused returns (bool) {
    bool result = doERC20Transfer(from, to, amount);
    emit TransferMade(from, to, amount);
    return result;
  }

  function enoughBalance(address user, uint amount) public view whenNotPaused returns(bool) {
    return ERC20UpgradeSafe(erc20address).balanceOf(user) >= amount;
  }

  /* Internal Functions */

  function poolWithinLimit(uint _totalShares) internal view returns (bool) {
    return _totalShares.mul(sharePrice).div(mantissa) <= totalFundsLimit;
  }

  function transactionWithinLimit(uint amount) internal view returns (bool) {
    return amount <= transactionLimit;
  }

  function getNumShares(uint amount, uint multiplier, uint price) internal pure returns (uint) {
    return amount.mul(multiplier).div(price);
  }

  function doERC20Transfer(address from, address to, uint amount) internal returns (bool) {
    ERC20UpgradeSafe erc20 = ERC20UpgradeSafe(erc20address);
    uint balanceBefore = erc20.balanceOf(to);

    bool success = erc20.transferFrom(from, to, amount);

    // Calculate the amount that was *actually* transferred
    uint balanceAfter = erc20.balanceOf(to);
    require(balanceAfter >= balanceBefore, "Token Transfer Overflow Error");
    return success;
  }

  function doERC20Withdraw(address payable to, uint amount) internal returns (bool) {
    ERC20UpgradeSafe erc20 = ERC20UpgradeSafe(erc20address);
    bool success = erc20.transfer(to, amount);

    require(success, "Token Withdraw Failed");
    return success;
  }
}
