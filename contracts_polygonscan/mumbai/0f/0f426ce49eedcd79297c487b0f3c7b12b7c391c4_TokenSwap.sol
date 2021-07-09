/**
 *Submitted for verification at polygonscan.com on 2021-07-09
*/

/**
 *Submitted for verification at Etherscan.io on 2017-02-09
*/

pragma solidity ^0.4.26;

contract SafeMath {
  function safeMul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeSub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

}

contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}

contract TokenSwap is SafeMath {
  address public admin; //the admin address
  
  address public input_token;
  address public output_token;
  
  // address public feeAccount; //the account that will receive fees
  // uint public feeMake; //percentage times (1 ether)
  mapping (address => mapping (address => uint)) public tokens; //mapping of token addresses to mapping of account balances (token=0 means Ether)

  event Deposit(address token, address user, uint amount, uint balance);
  event Withdraw(address token, address user, uint amount, uint balance);

  constructor() TokenSwap() public {

    admin = 0xEE2a7b2c72217f6EbF0401DAbb407C7a600d910F;
    input_token = 0x46E719462EA181907B8AaBdcea8f209C117A6426;
    output_token = 0xEeB7DE1f5F532C4137D4e620febD9D50A0736B90;
    // burn_account = 0x000000000000000000000000000000000000dEaD;
    
  }

  function changeAdmin(address admin_) public {
    require(msg.sender == admin);
    admin = admin_;
  }

/*
  function changeFeeAccount(address feeAccount_) public {
    require(msg.sender == admin);
    feeAccount = feeAccount_;
  }
  
  // deposit ETH
  function deposit() payable public {
    tokens[0][msg.sender] = safeAdd(tokens[0][msg.sender], msg.value);
    emit Deposit(0, msg.sender, msg.value, tokens[0][msg.sender]);
  }

  // withdraw ETH
  function withdraw(uint amount) public {
    require (tokens[0][msg.sender] >= amount);
    tokens[0][msg.sender] = safeSub(tokens[0][msg.sender], amount);
    require (msg.sender.call.value(amount)());
    emit Withdraw(0, msg.sender, amount, tokens[0][msg.sender]);
  }
*/

  // remember to call Token(address).approve(this, amount)
  // only admin can fund the contract
  function fundContract(address token, uint amount) public {
    require (token!=0);
    require (token == output_token);
    require (msg.sender == admin);
    require (ERC20Interface(token).transferFrom(msg.sender, this, amount));
    tokens[token][msg.sender] = safeAdd(tokens[token][msg.sender], amount);
    emit Deposit(token, msg.sender, amount, tokens[token][msg.sender]);
  }

  //remember to call Token(address).approve(this, amount)
  function swapToken(address token, uint amount) public {
    require (token!=0);
    require (token == input_token);
    require (ERC20Interface(token).transferFrom(msg.sender, this, amount));

    // tokens[token][msg.sender] = safeAdd(tokens[token][msg.sender], amount);
    // emit Deposit(token, msg.sender, amount, tokens[token][msg.sender]);    
    
    tokens[token][admin] = safeAdd(tokens[token][admin], amount);
    emit Deposit(token, admin, amount, tokens[token][admin]);

    tokens[output_token][msg.sender] = safeAdd(tokens[output_token][msg.sender], amount);
    emit Withdraw(output_token, msg.sender, amount, tokens[output_token][msg.sender]);

  }


  function withdrawToken(address token, uint amount) public {
    require (token!=0);
    require (tokens[token][msg.sender] >= amount);
    require (msg.sender == admin);
    tokens[token][msg.sender] = safeSub(tokens[token][msg.sender], amount);
    require (ERC20Interface(token).transfer(msg.sender, amount));
    emit Withdraw(token, msg.sender, amount, tokens[token][msg.sender]);
  }

  function balanceOf(address token, address user) constant public returns (uint) {
    return tokens[token][user];
  }

}