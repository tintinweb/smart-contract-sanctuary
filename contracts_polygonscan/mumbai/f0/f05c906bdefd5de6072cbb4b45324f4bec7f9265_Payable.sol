/**
 *Submitted for verification at polygonscan.com on 2022-01-12
*/

// File: src/Payable.sol


pragma solidity ^0.8.11;

/**
 * With love, 🆀🆆🅴🆁🆃🆈
 */

contract Payable {

  address internal owner;

  uint public lastCreditorIndex;
  mapping (uint => address) internal creditors;
  mapping (uint => uint) internal amounts;

  constructor() { owner = msg.sender; }

  function deposit() public payable {
    lastCreditorIndex++;
    creditors[lastCreditorIndex] = msg.sender;
    amounts[lastCreditorIndex] = msg.value;
  }

  // function getBalance() public view returns (uint) {
  //   return address(this).balance;
  // }

  function getDeposit(uint index) public view returns (address, uint) {
    require(index <= lastCreditorIndex, 'No deposit with such index.');
    return (creditors[index], amounts[index]);
  }

  function transfer(address payable to, uint256 amount) public onlyOwner {
    require(address(this).balance >= amount, 'Not enough balance left.');
    require(address(this).balance > 0, 'Balance is already withdrawn.');
    payable(to).transfer(amount);
  }

  /// Make sure you stored the list of creditors first. This operation is irreversible and results in all data being inaccessible, effectively erasing them.
  function reset() public onlyOwner {
    lastCreditorIndex = 0;
  }

  /// Careful, you can't take this back. You will lose control of this contract.
  function changeOwner(address newOwner) public onlyOwner {
    owner = newOwner;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, 'Only owner can call this.');
    _;
  }

}