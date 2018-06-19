pragma solidity ^0.4.19;

contract Ownable {
  address public owner;


  /** 
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() internal {
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
contract RenderTokenInvestment1 is Ownable {

  // Address of the target contract
  address public investment_address = 0x46dda95DEf0ddD0d9F6829352dB2622f27Fe5da7;
  // Major partner address
  address public major_partner_address = 0x212286e36Ae998FAd27b627EB326107B3aF1FeD4;
  // Minor partner address
  address public minor_partner_address = 0x515962688858eD980EB2Db2b6fA2802D9f620C6d;
  // Additional gas used for transfers.
  uint public gas = 1000;

  // Payments to this contract require a bit of gas. 100k should be enough.
  function() payable public {
    execute_transfer(msg.value);
  }

  // Transfer some funds to the target investment address.
  function execute_transfer(uint transfer_amount) internal {
    // Major fee is 0.3 for each 10.5
    uint major_fee = transfer_amount * 3 / 105;
    // Minor fee is 0.2 for each 10.5
    uint minor_fee = transfer_amount * 2 / 105;

    require(major_partner_address.call.gas(gas).value(major_fee)());
    require(minor_partner_address.call.gas(gas).value(minor_fee)());

    // Send the rest
    uint investment_amount = transfer_amount - major_fee - minor_fee;
    require(investment_address.call.gas(gas).value(investment_amount)());
  }

  // Sets the amount of additional gas allowed to addresses called
  // @dev This allows transfers to multisigs that use more than 2300 gas in their fallback function.
  //  
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
    require(msg.sender.call.gas(gas).value(address(this).balance)());
  }

}