pragma solidity ^0.4.19;

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

    function Own() public {
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
     emit   OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract Flame is ERC20Interface, Owned {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    uint public _maxSupply;
    uint public _ratio;
    bool disabled;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    


    function Flames() public {
            disabled = false;
        symbol = "FLAME";

        name = "Flame";
        decimals = 18;
        _totalSupply = 25000 * 10**uint(decimals);      

        _ratio = 1000;

        _maxSupply = 125000 * 10**uint(decimals);    
        balances[owner] = _totalSupply;
 
      emit  Transfer(address(0), owner, _totalSupply);
    }

    function totalSupply() public constant returns (uint) {
        return _totalSupply;
    }


    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }

 
    function transfer(address to, uint tokens) public returns (bool success) {
        require(balances[msg.sender] >= tokens);
        balances[msg.sender] -= tokens;
        balances[to] += tokens;
      emit  Transfer(msg.sender, to, tokens);
        return true;
    }


    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
     emit Approval(msg.sender, spender, tokens);
        return true;
    }

 function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        require (allowed[from][msg.sender] >= tokens);
        require (balances[from] >= tokens);
        
        balances[from] -= tokens;
        allowed[from][msg.sender] -= tokens;
        balances[to] += tokens;
      emit  Transfer(from, to, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
      emit  Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }


    function disablePresale(bool _disabled) public onlyOwner returns (bool success) {
        disabled = _disabled;
        return true;
    }

    function () public payable {
        require(msg.value >= 100000000000);
        require(_totalSupply+(msg.value*_ratio)<=_maxSupply);
        
        uint tokens;
        tokens = msg.value*_ratio;

        balances[msg.sender] += tokens;
        _totalSupply += tokens;
     emit   Transfer(address(0), msg.sender, tokens);
    }



    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }



    function checkBalance() public constant returns (uint checkBal) {
        return address(this).balance;
    }



    function transferFunds(address _address, uint amount) public onlyOwner {
       require(amount <= address(this).balance);
        _address.transfer(amount);
    }
}