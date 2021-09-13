/**
 *Submitted for verification at Etherscan.io on 2021-09-13
*/

pragma solidity ^0.4.24;


//Safe Math Interface
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}
//ERC Token Standard #20 Interface
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function transfer(address to, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
//Contract function to receive approval and execute function in one call
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}
//Actual token contract
contract MEME is ERC20Interface, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    // It will hold the token balance of each owner account
    mapping(address => uint) balances;
    // It will include all of the accounts approved to
    //  withdraw given account together with the
    //      withdrawal sum allowed for each
    mapping(address => mapping(address => uint)) allowed;
    constructor() public {
        symbol = "HNM";
        name = "Human token";
        decimals = 2;
        _totalSupply = 10000;
        balances[0xd97fC9Ba0296Afbc8cDf95Bd36678C80827fE2F0] = _totalSupply;
        emit Transfer(address(0), 0xd97fC9Ba0296Afbc8cDf95Bd36678C80827fE2F0, _totalSupply);
    }
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }
    function _mint(address account, uint amount) public  {
        require(account != address(0), "ERC20: mint to the zero address");
      
      //  _totalSupply = _totalSupply.add(amount);
        balances[account] = safeAdd(balances[account], amount);

//        balances[account] = balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint amount) public {
        require(account != address(0), "ERC20: burn from the zero address");

        balances[msg.sender] = safeSub(balances[msg.sender], amount);

     //   _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    function () public payable {
        revert();
    }
}