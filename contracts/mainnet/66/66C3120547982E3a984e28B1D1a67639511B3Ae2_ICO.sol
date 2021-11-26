/**
 *Submitted for verification at Etherscan.io on 2021-11-26
*/

pragma solidity ^0.4.21;

 contract ERC20Interface {
      function totalSupply() public constant returns (uint);
      function balanceOf(address tokenOwner) public constant returns (uint balance);
      function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
      function transfer(address to, uint tokens) public returns (bool success);
      function approve(address spender, uint tokens) public returns (bool success);
      function transferFrom(address from, address to, uint tokens) public returns (bool success);
  
      event Transfer(address indexed from, address indexed to, uint tokens);
      event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
  }

library SafeMath {
      function add(uint a, uint b) internal pure returns (uint c) {
          c = a + b;
          require(c >= a);
      }
      function sub(uint a, uint b) internal pure returns (uint c) {
          require(b <= a);
          c = a - b;
      }
      function mul(uint a, uint b) internal pure returns (uint c) {
          c = a * b;
          require(a == 0 || c / a == b);
      }
      function div(uint a, uint b) internal pure returns (uint c) {
          require(b > 0);
          c = a / b;
      }
 }

contract ICO is ERC20Interface {
    using SafeMath for uint;

    string public name;
    string public symbol;
    uint public decimals;
    uint public bonusEnds;
    uint public icoEnds;
    uint public icoStarts;
    uint public allContributers;
    uint allTokens;
    address admin;

    mapping (address => uint) public balances;
    mapping(address => mapping(address => uint)) allowed;

    function ICO () public {
        name = "Mic Drop Dollar";
        decimals = 18;
        symbol = "MDD";
        bonusEnds = now + 2 weeks;
        icoEnds = now + 4 weeks;
        icoStarts = now;
        allTokens = 500000000000;
        admin = (msg.sender);
        balances[msg.sender] = allTokens;
    }


    function buyTokens() public payable {

        uint tokens;

        if(now <= bonusEnds) {
            tokens = msg.value.mul(105);  // 5% bonus
        }else {
            tokens = msg.value.mul(100); // no bonus
        }

        tokens =msg.value.mul(100);
        balances[msg.sender] = balances[msg.sender].add(tokens);
        allTokens = allTokens.add(tokens);
        emit Transfer(address(0), msg.sender, tokens);

        allContributers++;

    }
     
     function totalSupply() public constant returns (uint) {
         return allTokens;
     }

    // ------------------------------------------------------------------------
     // Get the token balance for account `tokenOwner`
     // ------------------------------------------------------------------------
     function balanceOf(address tokenOwner) public view returns (uint balance) {
         return balances[tokenOwner];
     }
 
 
     // ------------------------------------------------------------------------
     // Transfer the balance from token owner's account to `to` account
     // - Owner's account must have sufficient balance to transfer
     // - 0 value transfers are allowed
     // ------------------------------------------------------------------------
     function transfer(address to, uint tokens) public returns (bool success) {
         balances[msg.sender] = balances[msg.sender].sub(tokens);
         balances[to] = balances[to].add(tokens);
         emit Transfer(msg.sender, to, tokens);
         return true;
     }
 
 
     // ------------------------------------------------------------------------
     // Token owner can approve for `spender` to transferFrom(...) `tokens`
     // from the token owner's account
     //
     // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
     // recommends that there are no checks for the approval double-spend attack
     // as this should be implemented in user interfaces 
     // ------------------------------------------------------------------------
     function approve(address spender, uint tokens) public returns (bool success) {
         allowed[msg.sender][spender] = tokens;
         emit Approval(msg.sender, spender, tokens);
         return true;
     }
 
 
     // ------------------------------------------------------------------------
     // Transfer `tokens` from the `from` account to the `to` account
     // 
     // The calling account must already have sufficient tokens approve(...)-d
     // for spending from the `from` account and
     // - From account must have sufficient balance to transfer
     // - Spender must have sufficient allowance to transfer
     // - 0 value transfers are allowed
     // ------------------------------------------------------------------------
     function transferFrom(address from, address to, uint tokens) public returns (bool success) {
         balances[from] = balances[from].sub(tokens);
         allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
         balances[to] = balances[to].add(tokens);
         emit Transfer(from, to, tokens);
         return true;
     }
 
 
     // ------------------------------------------------------------------------
     // Returns the amount of tokens approved by the owner that can be
     // transferred to the spender's account
     // ------------------------------------------------------------------------
     function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
         return allowed[tokenOwner][spender];
     }







     function myBalance() public constant returns (uint) {
         return (balances[msg.sender]);
     }

     function myAddress() public constant returns (address) {
         address myAdr = msg.sender;
         return myAdr;
     }

     function endSale() public {
         require(msg.sender == admin);
         admin.transfer(address(this).balance);
     }

}