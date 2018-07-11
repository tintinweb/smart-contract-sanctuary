pragma solidity ^0.4.14;

/**
 * Contract that exposes the needed erc20 token functions
 */

contract ERC20Interface {
  // Send _value amount of tokens to address _to
  function transfer(address _to, uint256 _value) returns (bool success);
  // Get the account balance of another account with address _owner
  function balanceOf(address _owner) constant returns (uint256 balance);
}

/**
 * Contract that will forward any incoming Ether to its creator
 */
contract Forwarder {
  // Address to which any funds sent to this contract will be forwarded
  address public parentAddress;
  event ForwarderDeposited(address from, uint value, bytes data);

  event TokensFlushed(
    address tokenContractAddress, // The contract address of the token
    uint value // Amount of token sent
  );

  /**
   * Create the contract, and set the destination address to that of the creator
   */
  function Forwarder() {
    parentAddress = msg.sender;
  }

  /**
   * Modifier that will execute internal code block only if the sender is a parent of the forwarder contract
   */
  modifier onlyParent {
    if (msg.sender != parentAddress) {
      throw;
    }
    _;
  }

  /**
   * Default function; Gets called when Ether is deposited, and forwards it to the destination address
   */
  function() payable {
    if (!parentAddress.call.value(msg.value)(msg.data))
      throw;
    // Fire off the deposited event if we can forward it  
    ForwarderDeposited(msg.sender, msg.value, msg.data);
  }

  /**
   * Execute a token transfer of the full balance from the forwarder token to the main wallet contract
   * @param tokenContractAddress the address of the erc20 token contract
   */
  function flushTokens(address tokenContractAddress) onlyParent {
    ERC20Interface instance = ERC20Interface(tokenContractAddress);
    var forwarderAddress = address(this);
    var forwarderBalance = instance.balanceOf(forwarderAddress);
    if (forwarderBalance == 0) {
      return;
    }
    if (!instance.transfer(parentAddress, forwarderBalance)) {
      throw;
    }
    TokensFlushed(tokenContractAddress, forwarderBalance);
  }

  /**
   * It is possible that funds were sent to this address before the contract was deployed.
   * We can flush those funds to the destination address.
   */
  function flush() {
    if (!parentAddress.call.value(this.balance)())
      throw;
  }
}