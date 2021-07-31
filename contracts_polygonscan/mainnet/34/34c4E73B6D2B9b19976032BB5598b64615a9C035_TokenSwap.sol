/**
 *Submitted for verification at polygonscan.com on 2021-07-31
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
  address public burn_account;
  address public owner;
  uint public swap_multiplier;
  bool public burn_also;
  
  mapping (address => mapping (address => uint)) public tokens; //mapping of token addresses to mapping of account balances (token=0 means Ether)

  event Deposit(address token, address user, uint amount, uint balance);
  event Withdraw(address token, address user, uint amount, uint balance);

  constructor() TokenSwap() public {

    owner = msg.sender;
    admin = 0xEAe12592170251D793e0F4d70A76fD0849be92eb;
    input_token = 0x422E0Cba8e57Acc799fC14DAdf2b72DfbA281c5F; // must be equal decimals 
    output_token = 0xBB816b9556f171FbD73746759FD7dDE7d8f54337;  // must be equal decimals OR adjust multiplier
    burn_account = 0x000000000000000000000000000000000000dEaD;
    swap_multiplier = 1;
    burn_also = false;
  }

  function changeAdmin(address new_admin_) public {
    require(msg.sender == owner);
    admin = new_admin_;
  }

  function changeInputToken(address input_token_) public {
    require(msg.sender == owner);
    input_token = input_token_;
  }

  function changeOutputToken(address output_token_) public {
    require(msg.sender == owner);
    output_token = output_token_;
  }

  function changeMultiplier(uint multiplier_) public {
    require(msg.sender == owner);
    swap_multiplier = multiplier_;
  }
  
  function changeBurnOption(bool burn_also_) public {
    require(msg.sender == owner);
    burn_also = burn_also_;
  }

  //remember to call Token(address).approve(this, amount)
  function swapToken(address token, uint amount) public {
    require (token!=0);
    require (token == input_token);

    // transfer input tokens to admin
    require (ERC20Interface(token).transferFrom(msg.sender, this, amount));

    uint withdraw_amount = safeMul(amount, swap_multiplier);

    // Withdraw output tokens from admin 
    require (ERC20Interface(output_token).transferFrom(admin, msg.sender, withdraw_amount));

    // burn input tokens
    if (burn_also == true) {
        require (ERC20Interface(input_token).transferFrom(admin, burn_account, amount));
    }
  }


  function withdrawInputTokens() public {
    require (msg.sender == admin);
    uint input_balance = ERC20Interface(input_token).balanceOf(this);
    ERC20Interface(input_token).transfer(msg.sender, input_balance);
  }


  function balanceOf(address token, address user) constant public returns (uint) {
    return tokens[token][user];
  }

}