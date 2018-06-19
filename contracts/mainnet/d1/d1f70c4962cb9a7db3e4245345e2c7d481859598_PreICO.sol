contract SafeMath {
  function safeMul(uint a, uint b) internal constant returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint a, uint b) internal constant returns (uint) {
    require(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint a, uint b) internal constant returns (uint) {
    require(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal constant returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }
}

contract PreICO is SafeMath {
  mapping (address => uint) public balance;
  uint public tokensIssued;

  address public ethWallet = 0x412790a9E6A6Dd5b201Bfa29af8d589CB85Ff20c;

  // Blocks
  uint public startPreico = 4307708;
  uint public endPreico = 4369916;

  // Tokens with decimals
  uint public limit = 100000000000000000000000000;

  event e_Purchase(address who, uint amount);

  modifier onTime() {
    require(block.number >= startPreico && block.number <= endPreico);

    _;
  }

  function() payable {
    buy();
  }

  function buy() onTime payable {
    uint numTokens = safeDiv(safeMul(msg.value, getPrice(msg.value)), 1 ether);
    assert(tokensIssued + numTokens <= limit);

    ethWallet.transfer(msg.value);
    balance[msg.sender] += numTokens;
    tokensIssued += numTokens;

    e_Purchase(msg.sender, numTokens);
  }

  function getPrice(uint value) constant returns (uint price) {
    if(value < 150 ether)
      revert();
    else if(value < 300 ether)
      price = 5800;
    else if(value < 1500 ether)
      price = 6000;
    else if(value < 3000 ether)
      price = 6200;
    else if(value >= 3000 ether)
      price = 6400;
  }
}