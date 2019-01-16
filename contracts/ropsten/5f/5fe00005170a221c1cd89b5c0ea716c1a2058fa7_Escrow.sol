pragma solidity ^0.4.24;

contract IERC20Token {
  uint256 public totalSupply;

  function balanceOf(address _who) public view returns (uint256);

  function allowance(address _owner, address _spender) public view returns (uint256);

  function transfer(address _to, uint256 _value) public returns (bool);
  
  function approve(address _spender, uint256 _value) public returns (bool);

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool);

  event Transfer( address indexed from, address indexed to,  uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
  
  event Burn(address indexed from, uint256 value);
}

contract Escrow {
    uint256 public escrowTime;

    constructor(uint256 _escrowTime) public {
        escrowTime = _escrowTime;
    }

    mapping(address => mapping(address => uint256)) public escrowBalance;
    mapping(address => mapping(address => uint256)) public escrowExpiration;
    
    function balanceOf(address token) public view returns (uint256) {
        return escrowBalance[msg.sender][token];
    }

    function deposit(IERC20Token token, uint256 amount) public {
        require(token.transferFrom(msg.sender, this, amount));
        escrowBalance[msg.sender][token] += amount;
        escrowExpiration[msg.sender][token] = 2**256-1;
    }

    event StartWithdrawal(address indexed account, address token, uint256 time);

    function startWithdrawal(IERC20Token token) public {
        uint256 expiration = now + escrowTime;
        escrowExpiration[msg.sender][token] = expiration;
        emit StartWithdrawal(msg.sender, token, expiration);
    }

    function withdraw(IERC20Token token) public {
        require(now > escrowExpiration[msg.sender][token],
            "Funds still in escrow.");

        uint256 amount = escrowBalance[msg.sender][token];
        escrowBalance[msg.sender][token] = 0;
        require(token.transfer(msg.sender, amount));
    }

    function transfer(
        address from,
        address to,
        IERC20Token token,
        uint256 tokens
    )
        internal
    {
        require(escrowBalance[from][token] >= tokens, "Insufficient balance.");

        escrowBalance[from][token] -= tokens;
        escrowBalance[to][token] += tokens;
    }
}