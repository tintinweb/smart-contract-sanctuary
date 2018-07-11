pragma solidity ^0.4.13;

contract E2E {
  using SafeMath for uint256;

  // ERC20 Meta-data
  string public name = &quot;E2E Message&quot;;
  uint8 public decimals; // set to 0, messages are not divisible
  string public symbol = &quot;MSG&quot;;
  // string public version = &quot;1.0&quot;; // leave versioning out for now

  // We keep total supply for ERC20 compatibility
  uint256 public totalSupply;

  /**
   * event Message(). This is the main event representing an encrypted message.
   */
  event Message(
    address indexed _recepient,
    address indexed _sender,
    string _msg
     );

  // mapping indicating sent messages.
  mapping (address => uint256) private messages;

  // Fallback - Prevent ETH being sent
  function () public { revert(); }

  // Implementation of the ERC20 balanceOf
  function balanceOf(address _owner) view public returns (uint256) {
    return messages[_owner];
  }

  /**
   * Send Message function. - This simply lodges an event with
   * the message information
   * @param _recipient  The address to which the message is sent
   * @param _msg        The (encrypted) message being sent
   */
  function send(address _recipient, string _msg) public {
    require(_recipient != address(0));
    // potentially give user the option to avoid the following to save gas and
    // not modify storage
    messages[_recipient] = messages[_recipient].add(1);
    totalSupply = totalSupply.add(1);
    emit Message(_recipient, msg.sender, _msg);
  }

  /**
   * MarkRead function. Removes the token balances of the caller and reduces
   * the total token supply (total unread messages)
   */
  function MarkRead() public {
    totalSupply = totalSupply.sub(messages[msg.sender]);
    messages[msg.sender] = 0;
  }

}

library SafeMath {
  // Multiplication
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  // Division - We keep for consistency
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    return c;
  }
  // Subtraction
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  // Addition
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

}