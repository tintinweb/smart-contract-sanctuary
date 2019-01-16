pragma solidity ^0.4.11;
/**
 * Contract that exposes the needed erc20 token functions
 */

contract ERC20Interface {
  // Send _value amount of tokens to address _to
  function transfer(address _to, uint256 _value) public returns (bool success);
  // Get the account balance of another account with address _owner
  function balanceOf(address _owner) public constant returns (uint256 balance);
}
/**
 * Contract that will forward any incoming Ether to the creator of the contract
 */
contract Forwarder {
  // Address to which any funds sent to this contract will be forwarded
  address public parentAddress;
  event ForwarderDeposited(address from, uint value, bytes data);

  /**
   * Create the contract, and sets the destination address to that of the creator
   */
  function Forwarder(address pool) public {
    parentAddress = 0xE4402b9f8034A9B2857FFeE4Cf96605a364B16A1;
  }
 
  /**
   * Modifier that will execute internal code block only if the sender is the parent address
   */
  modifier onlyParent {
    if (msg.sender != parentAddress) {
      revert();
    }
    _;
  }

  /**
   * Default function; Gets called when Ether is deposited, and forwards it to the parent address
   */
  function() public payable {
    // throws on failure
    parentAddress.transfer(msg.value);
    // Fire off the deposited event if we can forward it
    ForwarderDeposited(msg.sender, msg.value, msg.data);
  }

  /**
   * Execute a token transfer of the full balance from the forwarder token to the parent address
   * @param tokenContractAddress the address of the erc20 token contract
   */
  function flushTokens(address tokenContractAddress) public {
    ERC20Interface instance = ERC20Interface(tokenContractAddress);
    var forwarderAddress = address(this);
    var forwarderBalance = instance.balanceOf(forwarderAddress);
    if (forwarderBalance == 0) {
      return;
    }
    if (!instance.transfer(parentAddress, forwarderBalance)) {
      revert();
    }
  }

  /**
   * It is possible that funds were sent to this address before the contract was deployed.
   * We can flush those funds to the parent address.
   */
  function flush() public {
    // throws on failure
    parentAddress.transfer(this.balance);
  }
}

// This is a test target for a Forwarder.
// It contains a public function with a side-effect.
contract ForwarderTarget {
  uint public data;

  function ForwarderTarget() public {
  }

  function createForwarder(address pool) public returns (address) {
    return new Forwarder(pool);
  }

  function() public payable {
    // accept unspendable balance
  }
}