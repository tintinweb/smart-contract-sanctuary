/**
 *Submitted for verification at Etherscan.io on 2021-02-20
*/

pragma solidity 0.8.1;

// ----------------------------------------------------------------------------
// 'GGMToken' token contract
//
// Deployed to : 0x7C16FF1254B8Ad0693ACC54c608b39bC34C7D37F
// Symbol      : TSCU
// Name        : TestCoinSpike
// Total supply: 100000000
// Decimals    : 18
//
// SPDX-License-Identifier: UNLICENSED
// (c) By Cedrick Josemarie
// ----------------------------------------------------------------------------


// Safe maths
contract SafeMath {
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


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
abstract contract ERC20Interface {
    function totalSupply() virtual public view returns (uint);
    function balanceOf(address tokenOwner) virtual public view returns (uint balance);
    function allowance(address tokenOwner, address spender) virtual public view returns (uint remaining);
    function transfer(address to, uint tokens) virtual public returns (bool success);
    function approve(address spender, uint tokens) virtual public returns (bool success);
    function transferFrom(address from, address to, uint tokens) virtual public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Burn(address indexed from, uint tokens);
}

// Contract function to receive approval and execute function in one call
abstract contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) virtual public;
}


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address internal owner;
    address internal newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract TestCoinSpike is ERC20Interface, Owned, SafeMath {
    string public  name;
    string public symbol;
    uint8 public decimals;
    uint internal _totalSupply;
    

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() {
        name = "TestCoinSpike";
        symbol = "TSCU3";
        decimals = 1;
//        _totalSupply = 1000000000000000;
        _totalSupply = 50000;
        balances[0x7C16FF1254B8Ad0693ACC54c608b39bC34C7D37F] = _totalSupply;
        emit Transfer(address(0), 0x7C16FF1254B8Ad0693ACC54c608b39bC34C7D37F, _totalSupply);
    }


    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public override view returns (uint) {
        return _totalSupply - balances[address(0)];
    }


    // ------------------------------------------------------------------------
    // Get the token balance for an account
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public override view returns (uint balance) {
        return balances[tokenOwner];
    }


    // Transfer the balance from token owner's account to to account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    function transfer(address to, uint tokens) public override returns (bool success) {
        require(to != address(0));
        require(balances[msg.sender] >= tokens);
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    
    //Burn Coins
    function burn(uint _value) public returns (bool success) {
      //Check if sender has enough tokens to burn.
        require(balances[msg.sender] >= _value);
		require(_value > 0); 
	  //Subtract balance from the sender.
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        _totalSupply = safeSub(_totalSupply, _value);
        emit Burn(msg.sender, _value);
        return true;
    }
        
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner's account
    function approve(address spender, uint tokens) public override returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Transfer tokens from the from account to the to account
    // 
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the from account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public override returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }



    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    function allowance(address tokenOwner, address spender) public override view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner's account. The spender contract function
    // receiveApproval(...) is then executed
    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }
    
    //Mint out new Coins
    function mint(address _to, uint tokens) public returns (bool success) {
     balances[_to] = safeAdd(balances[_to], tokens);
     _totalSupply = safeAdd(_totalSupply, tokens);
     require(balances[_to] >= tokens && _totalSupply >= tokens); // overflow checks
     emit Transfer(address(0), _to, tokens);
     return true;
   }
    
   /* ------------------------------------------------------------------------
     Owner can transfer out any accidentally sent ERC20 tokens
     Owner can withdrwal ethereum.
     Transfer balanace to owner
    ---------------------------------------------------------------------- */
    function withdraw(uint8 op, uint amount, address tokenAddress, address payable to) public onlyOwner returns(bool success) {
      if(op == 1) {
        //Withdraw ethereum
        to.transfer(amount);
        return true;
      }else if(op == 2) {
        //Withdraw tokens
        return ERC20Interface(tokenAddress).transfer(to, amount);
      }else { return false; }
    }
    
    //Can accept ETH
    receive() external payable {
        //Accepts Ether
    }
}