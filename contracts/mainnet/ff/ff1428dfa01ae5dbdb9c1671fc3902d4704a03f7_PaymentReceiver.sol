pragma solidity ^0.4.19;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract PaymentReceiver
{
 address private constant taxman = 0xB13D7Dab5505512924CB8E1bE970B849009d34Da;
 address private constant store = 0x23859DBF88D714125C65d1B41a8808cADB199D9E;
 address private constant pkt = 0x2604fa406be957e542beb89e6754fcde6815e83f;

  modifier onlyTaxman { require(msg.sender == taxman); _; }

  function withdrawTokens(uint256 value) external onlyTaxman
  {
    ERC20 token = ERC20(pkt);
    token.transfer(store, value);
  }
}