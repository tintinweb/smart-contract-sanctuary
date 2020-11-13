pragma solidity ^0.5.0;

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      require(c >= a);
      return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      require(b <= a);
      uint256 c = a - b;
      return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
    uint256 c = add(a,m);
    uint256 d = sub(c,1);
    return mul(div(d,m),m);
  }
}

contract ERC20 {
  function totalSupply() public view returns (uint256);
  function balanceOf(address holder) public view returns (uint256);
  function allowance(address holder, address spender) public view returns (uint256);
  function transfer(address to, uint256 amount) public returns (bool success);
  function approve(address spender, uint256 amount) public returns (bool success);
  function transferFrom(address from, address to, uint256 amount) public returns (bool success);

  event Transfer(address indexed from, address indexed to, uint256 amount);
  event Approval(address indexed holder, address indexed spender, uint256 amount);
}

contract BlastFinance is ERC20 {

    using SafeMath for uint256;

    string public symbol = "BLAST";
    string public name = "Blast Finance";
    uint8 public decimals = 18;
    uint256 private _totalSupply = 70000000000000000000;
    uint256 oneHundredPercent = 100;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    constructor() public {
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() public view returns (uint256) {
      return _totalSupply;
    }

    function balanceOf(address holder) public view returns (uint256) {
        return balances[holder];
    }

    function allowance(address holder, address spender) public view returns (uint256) {
        return allowed[holder][spender];
    }

    function findOnePercent(uint256 amount) private view returns (uint256)  {
        uint256 roundAmount = amount.ceil(oneHundredPercent);
        uint256 fivePercent = roundAmount.mul(oneHundredPercent).div(2000);
        return fivePercent;
    }

    function transfer(address to, uint256 amount) public returns (bool success) {
      require(amount <= balances[msg.sender]);
      require(to != address(0));

      uint256 tokensToBurn = findOnePercent(amount);
      uint256 tokensToTransfer = amount.sub(tokensToBurn);

      balances[msg.sender] = balances[msg.sender].sub(amount);
      balances[to] = balances[to].add(tokensToTransfer);

      _totalSupply = _totalSupply.sub(tokensToBurn);

      emit Transfer(msg.sender, to, tokensToTransfer);
      emit Transfer(msg.sender, address(0), tokensToBurn);
      return true;
    }

    function approve(address spender, uint256 amount) public returns (bool success) {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool success) {
      require(amount <= balances[from]);
      require(amount <= allowed[from][msg.sender]);
      require(to != address(0));

      balances[from] = balances[from].sub(amount);

      uint256 tokensToBurn = findOnePercent(amount);
      uint256 tokensToTransfer = amount.sub(tokensToBurn);

      balances[to] = balances[to].add(tokensToTransfer);
      _totalSupply = _totalSupply.sub(tokensToBurn);

      allowed[from][msg.sender] = allowed[from][msg.sender].sub(amount);

      emit Transfer(from, to, tokensToTransfer);
      emit Transfer(from, address(0), tokensToBurn);

      return true;
    }
}