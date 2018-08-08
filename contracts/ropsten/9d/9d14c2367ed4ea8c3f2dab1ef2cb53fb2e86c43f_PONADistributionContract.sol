pragma solidity ^0.4.21;
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

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

contract Owned {
    address public owner;
    address public newOwner;
    event OwnershipTransferred(address indexed _from, address indexed _to);
  
    function Owned() public {
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public onlyOwner {
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract PONADistributionContract is ERC20Interface, Owned {
    using SafeMath for uint;
    string public symbol;
    string public name;
    int256 public rate;
    uint8 public decimals;
    uint public _totalSupply;
    address public fundsWallet;
    bool frozen = false;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    mapping (address => uint256) accounts;
    mapping (address =>  uint256) internal holds;
    
    function PONADistributionContract() public {
        symbol = "PONA";
        name = "Ponder Airdrop Token";
        decimals = 18;
        _totalSupply = 480000000 * 10**uint(decimals);
        balances[owner] = _totalSupply;
        Transfer(address(0), owner, _totalSupply);
        fundsWallet = msg.sender;
    }
    
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }
    
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }
    
    function transfer(address to, uint tokens) public returns (bool success) {
        if (frozen) return false;
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }
    
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        if (frozen) return false;
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(from, to, tokens);
        return true;
    }
    
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }
    
    function sendTokens (address receiver, uint token) public onlyOwner {
        require(balances[msg.sender] >= token);
        balances[msg.sender] -= token; 
        balances[receiver] += token;
        Transfer(msg.sender, receiver, token);
    }
  
    function sendInitialTokens (address user) public onlyOwner {
        sendTokens(user, balanceOf(owner));
    }
    
    function kill () public onlyOwner { 
        selfdestruct(msg.sender);
    }
    
    function freezeTransfers () public onlyOwner {
        if (!frozen) {
          frozen = true;
          emit Freeze ();
        }
    }

    function unfreezeTransfers () public onlyOwner{
        if (frozen) {
          frozen = false;
          emit Unfreeze ();
        }
    }
    
    event Freeze ();
    event Unfreeze ();
    
    function initAccounts (address [] _to, uint256 [] _value) public onlyOwner{
      require (_to.length == _value.length);
      for (uint256 i=0; i < _to.length; i++){
          uint256 amountToAdd;
          uint256 amountToSub;
          if (_value[i] > accounts[_to[i]]){
            amountToAdd = _value[i].sub(accounts[_to[i]]);
          }else{
            amountToSub = accounts[_to[i]].sub(_value[i]);
          }
          accounts [owner] = accounts [owner].add (amountToSub);
          accounts [owner] = accounts [owner].sub (amountToAdd);
          accounts [_to[i]] = _value[i];
          if (amountToAdd > 0){
            emit Transfer (owner, _to[i], amountToAdd);
          }
      }
    }
    
    function initAccounts (address [] _to, uint256 [] _value, uint256 [] _holds) public {
        setHolds(_to, _holds);
        initAccounts(_to, _value);
    }
    
    function setHolds (address [] _account, uint256 [] _value) public onlyOwner {
        require (_account.length == _value.length);
        for (uint256 i=0; i < _account.length; i++){
            holds[_account[i]] = _value[i];
        }
    }
}