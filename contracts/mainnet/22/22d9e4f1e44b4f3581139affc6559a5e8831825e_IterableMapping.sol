/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


// ----------------------------------------------------------------------------
// 'FBond' token contract
//
// Deployed to : 0x22d9e4f1e44b4f3581139affc6559a5e8831825e
// Symbol      : FBond
// Name        : FBond Token
// Total supply: 100
// Decimals    : 18
//
// author: ffyring
// version: 20210504_1100
// ----------------------------------------------------------

library IterableMapping {
     // Iterable mapping from address to uint;
     struct Map {
         address[] keys;
         mapping(address => uint) values;
         mapping(address => uint) indexOf;
         mapping(address => bool) inserted;
     }

     function get(Map storage map, address key) public view returns (uint) {
         return map.values[key];
     }

     function getOrDefault(Map storage map, address key, uint d) public view returns (uint) {
         if(map.inserted[key]) {
             return map.values[key];
         }
         else {
             return d;
         }
     }

     function getKeyAtIndex(Map storage map, uint index) public view returns (address) {
         return map.keys[index];
     }

     function size(Map storage map) public view returns (uint) {
         return map.keys.length;
     }

     function set(Map storage map, address key, uint val) public {
         if (map.inserted[key]) {
             map.values[key] = val;
         } else {
             map.inserted[key] = true;
             map.values[key] = val;
             map.indexOf[key] = map.keys.length;
             map.keys.push(key);
         }
     }

     function remove(Map storage map, address key) public {
         if (!map.inserted[key]) {
             return;
         }

         delete map.inserted[key];
         delete map.values[key];

         uint index = map.indexOf[key];
         uint lastIndex = map.keys.length - 1;
         address lastKey = map.keys[lastIndex];

         map.indexOf[lastKey] = index;
         delete map.indexOf[key];

         map.keys[index] = lastKey;
         map.keys.pop();
     }
}

//----------------------------------------------------------------------------
// Safe maths
//----------------------------------------------------------------------------
contract SafeMath
{
     function safeAdd(uint a, uint b) internal pure returns (uint c) {
         c = a + b;
         require(c >= a);
     }
     function safeSub(uint a, uint b) internal pure returns (uint c) {
         require(b <= a);
         c = a - b;
     }
     function safeMul(uint a, uint b) internal pure returns (uint c) {
         c = a * b;
         require(a == 0 || c / a == b);
     }
     function safeDiv(uint a, uint b) internal pure returns (uint c) {
         require(b > 0);
         c = a / b;
     }
}

//----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
//----------------------------------------------------------------------------
interface ERC20Interface
{
     function totalSupply() external returns (uint);
     function balanceOf(address tokenOwner) external returns (uint balance);
     function allowance(address tokenOwner, address spender) external returns (uint remaining);
     function transfer(address payable to, uint tokens) external returns (bool success);
     function approve(address payable spender, uint tokens) external returns (bool success);
     function transferFrom(address payable from, address payable to, uint tokens) external returns (bool success);

     event Transfer(address payable indexed from, address indexed to, uint tokens);
     event Approval(address indexed tokenOwner, address indexed spender, uint tokens); }


// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call // // Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
interface ApproveAndCallFallBack
{
     function receiveApproval(address payable from, uint256 tokens, address token, bytes memory data) external; }


//----------------------------------------------------------------------------
// Owned contract
//----------------------------------------------------------------------------
contract Owned
{
     address payable public owner;
     address payable public newOwner;

     event OwnershipTransferred(address payable indexed _from, address payable indexed _to);

     constructor() payable
     {
         owner = payable(msg.sender);
     }

     modifier onlyOwner
     {
         require(msg.sender == owner);
         _;
     }

     function transferOwnership(address payable _newOwner) public onlyOwner
     {
         newOwner = _newOwner;
     }

     function acceptOwnership() public
     {
         require(msg.sender == newOwner);
         emit OwnershipTransferred(owner, newOwner);
         owner = newOwner;
         newOwner = payable(address(0));
     }
}


//----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted // token transfers.
//
// The contract holds all issued tokens and gives proceeds to issuer when someone buys a // contract. In v2 the contract will give tokens to issuer as proof of the lending 
// ----------------------------------------------------------------------------
contract FBondToken is ERC20Interface, Owned, SafeMath {
     /*
         The bond has a _totalSupply which is the issued amount. The issuer, who creates the bond
         could perhaps be short it. Have to check a bit how to make it work
     */
     using IterableMapping for IterableMapping.Map;

     string public symbol;
     string public name;
     uint8 public decimals;
     uint public issueDate;
     uint public maturityDate;
     address public issuer;
     address public administrator;
     // How many bonds per eth (other way around than usual nomenclature)
     uint16 constant denomination = 1000;
     // We issue 100 bonds, nominal value 1/denomination (1 finney, approx 23 kr) per bond
     uint16 constant issuedAmount = 100;
     uint16 private _totalSupply;
     uint constant weiMultiplier = 1e18/denomination;
     uint constant weiRateMultiplier = (weiMultiplier/100)*120; //20% interest
     IterableMapping.Map private balances;
     mapping(address => mapping(address => uint)) private allowed;

     event Print(string msg, uint v);
     //------------------------------------------------------------------------
     // Constructor
     //------------------------------------------------------------------------
     constructor() payable
     {
         symbol = "FYR";
         name = "FBond Token";
         //decimals = 18;
         decimals = 0;
         issueDate = block.timestamp;
         maturityDate = block.timestamp + 1 weeks;
         _totalSupply = issuedAmount;
         issuer = address(this);
         administrator = msg.sender;
         owner = payable(issuer); //Let the contract own the bond and not the creator
         balances.set(issuer, _totalSupply);
         emit Transfer(payable(address(0)), payable(issuer), _totalSupply);
     }

     //------------------------------------------------------------------------
     // Total supply
     //------------------------------------------------------------------------
     function totalSupply() public view override returns (uint)
     {
         return _totalSupply;
     }
     function noOfOwners() public view returns (uint)
     {
         return balances.size() - 1; //Don't count issuer as owner
     }
     //------------------------------------------------------------------------
     // Get the token balance for account `tokenOwner`
     //-----------------------------------------------------------------------
     function balanceOf(address tokenOwner) public view override returns (uint balance)
     {
         return balances.get(tokenOwner);
     }

     //------------------------------------------------------------------------
     // Transfer the balance from token owner's account to `to` account
     // - Owner's account must have sufficient balance to transfer
     // - 0 value transfers are allowed
     //------------------------------------------------------------------------
     function transfer(address payable to, uint tokens) public override returns (bool success)
     {
         balances.set(msg.sender, safeSub(balances.get(msg.sender), tokens));
         balances.set(to, safeAdd(balances.getOrDefault(to, 0), tokens));
         emit Transfer(payable(msg.sender), to, tokens);
         return true;
     }


     //------------------------------------------------------------------------
     // Token owner can approve for `spender` to transferFrom(...) `tokens`
     // from the token owner's account
     //
     //https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
     // recommends that there are no checks for the approval double-spend attack
     // as this should be implemented in user interfaces
     //------------------------------------------------------------------------
     function approve(address payable spender, uint tokens) public override returns (bool success)
     {
         allowed[msg.sender][spender] = tokens;
         emit Approval(msg.sender, spender, tokens);
         return true;
     }


     //------------------------------------------------------------------------
     // Transfer `tokens` from the `from` account to the `to` account
     //
     // The calling account must already have sufficient tokens approve(...)-d
     // for spending from the `from` account and
     // - From account must have sufficient balance to transfer
     // - Spender must have sufficient allowance to transfer
     // - 0 value transfers are allowed
     //------------------------------------------------------------------------
     function transferFrom(address payable from, address payable to, uint tokens) public override returns (bool success)
     {
         balances.set(from, safeSub(balances.get(from), tokens));
         allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
         balances.set(to, safeAdd(balances.getOrDefault(to,0), tokens));
         emit Transfer(from, to, tokens);
         return true;
     }


     //------------------------------------------------------------------------
     // Returns the amount of tokens approved by the owner that can be
     // transferred to the spender's account
     //------------------------------------------------------------------------
     function allowance(address tokenOwner, address spender) public view override returns (uint remaining)
     {
         return allowed[tokenOwner][spender];
     }

     // ------------------------------------------------------------------------
     // Token owner can approve for `spender` to transferFrom(...) `tokens`
     // from the token owner's account. The `spender` contract function
     // `receiveApproval(...)` is then executed
     // ------------------------------------------------------------------------
     function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success)
     {
         allowed[msg.sender][spender] = tokens;
         Approval(msg.sender, spender, tokens);
         
         ApproveAndCallFallBack(payable(spender)).receiveApproval(payable(msg.sender), tokens, address(this), data);
         return true;
     }

      function transferTokens(address payable fromAddress, address payable toAddress, uint tokens) private returns (bool success)
     {
         balances.set(fromAddress, safeSub(balances.get(fromAddress), tokens));
         balances.set(toAddress, safeAdd(balances.getOrDefault(toAddress, 0), tokens));
         emit Transfer(fromAddress, toAddress, tokens);
         return true;
     }

     // ------------------------------------------------------------------------
     // Issuer can call bond at or after maturityDate.
     // This is a three-step process: first deposit correct funds into contract and then repay holders. Optionally repay
     // every other fund in contract
     //
     function callBondTransferFunds(uint repayAmnt) public payable returns (bool success)
     {
         /*
             This is called by administrator to repay full amount. To make sure
             we accidentally don't send wrong funds we must send exactly outstanding amount.

         */
         // require(block.timestamp >= maturityDate, 'Cannot call before maturity.')
        require(msg.sender == administrator, 'Only administrator can call bond');
        require(msg.value == repayAmnt * 1e15, 'Did you mean to send this amount? Argument is in Finney');
        require(msg.value == (issuedAmount - _totalSupply) * weiRateMultiplier , 'Sent amount does not match outstanding');
        require(msg.value <= msg.sender.balance, 'You have not enough funds to repay!'); //Not necessary but nice warning.
        return true;
     }
     
     function callBondAndRepay() public payable returns (bool success)
     {
         /*
             This is called by administrator to repay full amount. To make sure
             we accidentally don't send wrong funds we must send exactly outstanding amount.

         */

         // require(block.timestamp >= maturityDate, 'Cannot call before maturity.')
         
         require(msg.sender == administrator, 'Only administrator can call bond');
         require(issuer.balance >= (issuedAmount - _totalSupply) * weiRateMultiplier , 'Contract has insufficient funds');
         for(uint i=0 ; i<balances.size(); i++) {
             // Transfer back the bonds to the contract
             address holder = balances.getKeyAtIndex(i);
           
             if(holder != address(this))
             {
                uint amnt = balances.get(holder);
                // Transfer back the bonds to the issuer
                transferTokens(payable(holder), payable(issuer), amnt);
                //Repay with interest
                payable(holder).transfer(amnt * weiRateMultiplier);
             }
         }
        return true;
     }
     
     function deposit(uint depositAmnt) public payable returns(bool success)
     {
           require(msg.sender == administrator, 'Only administrator can deposit funds');
           require(msg.value == depositAmnt * 1e15, 'Did you mean to send this amount? Argument is in Finney');
           return true;
     }
     
       function withdraw_all() public payable returns (bool success)
       {
       
         if(address(this).balance > 0)
         {
            withdraw(address(this).balance);
         }
         return true;
       }
       
       function withdraw(uint f) public payable returns (bool success)
       {
          require(msg.sender == administrator, 'Only administrator can withdraw funds');
          payable(administrator).transfer(f);
          return true;         
       }
     // ------------------------------------------------------------------------
     // 1,000 FBond Tokens per 1 ETH
     // ------------------------------------------------------------------------
     fallback() external payable
   {

   }

     receive() external payable
     {
         // This datecomparison is not quite right
         //require(block.timestamp <= issueDate + 1 days, 'Funds not accepted. Passed issuedate.');
         uint16 tokens = uint16(msg.value / weiMultiplier);
         require(tokens <= _totalSupply, 'Not enough supply of bonds for order.');
         transferTokens(payable(issuer), payable(msg.sender), tokens);
         _totalSupply = uint16(safeSub(_totalSupply, tokens));
         // Lend out the transfered ether to issuer
         payable(administrator).transfer(msg.value);
     }

     // ------------------------------------------------------------------------
     // Owner can transfer out any accidentally sent ERC20 tokens
     // ------------------------------------------------------------------------
     function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success)
     {
         return ERC20Interface(tokenAddress).transfer(owner, tokens);
     }
}