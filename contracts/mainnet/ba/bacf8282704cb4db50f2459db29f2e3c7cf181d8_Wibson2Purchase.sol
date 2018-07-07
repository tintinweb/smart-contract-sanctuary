pragma solidity ^0.4.21;

contract Ownable {
  address public owner;


  /** 
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() internal {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner. 
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to. 
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    owner = newOwner;
  }

}

/**
 * Interface for the standard token.
 * Based on https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
 */
interface EIP20Token {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool success);
  function approve(address spender, uint256 value) external returns (bool success);
  function allowance(address owner, address spender) external view returns (uint256 remaining);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


// The owner of this contract should be an externally owned account
contract Wibson2Purchase is Ownable {

  // Address of the target contract
  address public purchase_address = 0x40AF356665E9E067139D6c0d135be2B607e01Ab3;
  // First partner address
  address public first_partner_address = 0xeAf654f12F33939f765F0Ef3006563A196A1a569;
  // Second partner address
  address public second_partner_address = 0x1B78C30171A45CA627889356cf74f77d872682c2;
  // Additional gas used for transfers. This is added to the standard 2300 gas for value transfers.
  uint public gas = 1000;

  // Payments to this contract require a bit of gas. 100k should be enough.
  function() payable public {
    execute_transfer(msg.value);
  }

  // Transfer some funds to the target purchase address.
  function execute_transfer(uint transfer_amount) internal {
    // First partner fee is 2.5 for each 100
    uint first_fee = transfer_amount * 25 / 1000;
    // Second partner fee is 2.5 for each 100
    uint second_fee = transfer_amount * 25 / 1000;

    transfer_with_extra_gas(first_partner_address, first_fee);
    transfer_with_extra_gas(second_partner_address, second_fee);

    // Send the rest
    uint purchase_amount = transfer_amount - first_fee - second_fee;
    transfer_with_extra_gas(purchase_address, purchase_amount);
  }

  // Transfer with additional gas.
  function transfer_with_extra_gas(address destination, uint transfer_amount) internal {
    require(destination.call.gas(gas).value(transfer_amount)());
  }

  // Sets the amount of additional gas allowed to addresses called
  // @dev This allows transfers to multisigs that use more than 2300 gas in their fallback function.
  function set_transfer_gas(uint transfer_gas) public onlyOwner {
    gas = transfer_gas;
  }

  // We can use this function to move unwanted tokens in the contract
  function approve_unwanted_tokens(EIP20Token token, address dest, uint value) public onlyOwner {
    token.approve(dest, value);
  }

  // This contract is designed to have no balance.
  // However, we include this function to avoid stuck value by some unknown mishap.
  function emergency_withdraw() public onlyOwner {
    transfer_with_extra_gas(msg.sender, address(this).balance);
  }

}