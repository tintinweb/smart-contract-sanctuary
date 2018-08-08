pragma solidity ^0.4.23;
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return a / b;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}
 contract ERC20Interface {
    function totalSupply() public view returns (uint256);
    function balanceOf(address tokenOwner) public view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) public view returns (uint256 remaining);
    function transfer(address to, uint256 tokens) public returns (bool success);
    function approve(address spender, uint256 tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}
 contract Owned {
    address public owner;
    address public newOwner;
    mapping (address => bool) public admins;
    event OwnershipTransferred(address indexed _from, address indexed _to);
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    modifier onlyAdmins {
        require(admins[msg.sender]);
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
    function addAdmin(address _admin) onlyOwner public {
        admins[_admin] = true;
    }
    function removeAdmin(address _admin) onlyOwner public {
        delete admins[_admin];
    }
}
contract Pausable is Owned {
  event Pause();
  event Unpause();
  bool public paused = false;
  modifier whenNotPaused() {
    require(!paused);
    _;
  }
  modifier whenPaused() {
    require(paused);
    _;
  }
  function pause() onlyAdmins whenNotPaused public {
    paused = true;
    emit Pause();
  }
  function unpause() onlyAdmins whenPaused public {
    paused = false;
    emit Unpause();
  }
}
 contract HahahahahToken is ERC20Interface, Pausable {
    using SafeMath for uint256;
    string public constant NAME = "Hahahahah Token";
    string public constant SYMBOL = "HAT";
    uint8 public constant decimals = 18;
    uint256 public totalSupply = 10 ** 10 * 10**uint(decimals);

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    constructor() public {
        owner = msg.sender;
        admins[msg.sender] = true;

        balances[owner] = totalSupply;        
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    function totalSupply() public view returns (uint256) {
        return totalSupply;
    }    
    function balanceOf(address _tokenOwner) public view returns (uint256 balance) {
        return balances[_tokenOwner];
    } 
    function transfer(address _to, uint256 _tokens) public whenNotPaused returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(_tokens);
        balances[_to] = balances[_to].add(_tokens);
        emit Transfer(msg.sender, _to, _tokens);
        return true;
    }
    function approve(address _spender, uint256 _tokens) public whenNotPaused returns (bool success) {
        allowed[msg.sender][_spender] = _tokens;
        emit Approval(msg.sender, _spender, _tokens);
        return true;
    }
    function transferFrom(address _from, address _to, uint256 _tokens) public whenNotPaused returns (bool success) {
        balances[_from] = balances[_from].sub(_tokens);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_tokens);
        balances[_to] = balances[_to].add(_tokens);
        emit Transfer(_from, _to, _tokens);
        return true;
    }
    function allowance(address _tokenOwner, address _spender) public view returns (uint256 remaining) {
        return allowed[_tokenOwner][_spender];
    }
    function approveAndCall(address _spender, uint256 _tokens, bytes _data) public whenNotPaused returns (bool success) {
        allowed[msg.sender][_spender] = _tokens;
        emit Approval(msg.sender, _spender, _tokens);
        ApproveAndCallFallBack(_spender).receiveApproval(msg.sender, _tokens, this, _data);
        return true;
    }
    function batchTransfer(address[] _receivers, uint256 _value) public whenNotPaused returns (bool) {
        uint cnt = _receivers.length;
        uint256 amount = uint256(cnt).mul(_value);
        require(cnt > 0 && cnt <= 200);
        require(_value > 0 && balances[msg.sender] >= amount);
    
        balances[msg.sender] = balances[msg.sender].sub(amount);
        for (uint i = 0; i < cnt; i++) {
            balances[_receivers[i]] = balances[_receivers[i]].add(_value);
            Transfer(msg.sender, _receivers[i], _value);
        }
        return true;
    }
    function () public payable {
        revert();
    }
    function transferAnyERC20Token(address tokenAddress, uint256 tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}