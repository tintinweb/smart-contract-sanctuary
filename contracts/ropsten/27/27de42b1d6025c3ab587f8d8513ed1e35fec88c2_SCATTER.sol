/**
 *Submitted for verification at Etherscan.io on 2021-06-29
*/

pragma solidity >=0.5.12;

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

contract Owned {
  address public owner;
  address public newOwner;

  event OwnershipTransferred(address indexed _from, address indexed _to);

  constructor() public {
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

contract SCATTER is ERC20Interface, Owned{
  using SafeMath for uint;

  constructor() public {
    symbol = "STT";
    name = "Scatter.cx";
    decimals = 6;
    _totalSupply =  10**6 * 10**uint(decimals);
    balances[owner] = _totalSupply;
    active[owner] = true;
    emit Transfer(address(0), owner, _totalSupply);

    dropcooldown = 10;
    eth2tkn = 10**9;
    salecutoff = 25 * 10**7 * 10**uint(decimals);
    softcap = 10**9 * 10**uint(decimals);
    tailemission = 10;
    baseemission = 10**3 * 10**uint(decimals);
  }


  mapping(address => uint) public lastdrop;
  mapping(address => bool) public active;
  mapping(uint => address) public droplist;

  uint public droplistcount;

  uint public softcap;
  uint public tailemission;
  uint public baseemission;
  uint public dropcooldown;

  uint public eth2tkn;
  uint public salecutoff;


  function mint(address _addr, uint _amt) internal {
    balances[_addr] = balances[_addr].add(_amt);
    _totalSupply = _totalSupply.add(_amt);
    emit Transfer(address(0), _addr, _amt);
  }

  function randomDrop(address _addr, uint _tkns) internal view returns(address) {
    uint _rand = uint256(keccak256(abi.encodePacked(block.timestamp, _addr, _tkns)));
    return(droplist[_rand % droplistcount]);
  }

  function calcEm() public view returns(uint){
    if (_totalSupply >= softcap) {
      return(tailemission);
    }
    else {
      uint _lesstkns = baseemission * _totalSupply / softcap;
      uint _tkns = baseemission - _lesstkns;
      return(_tkns);
    }
  }



  function getAirdrop(address _addr) public {
    require(_addr != msg.sender && active[_addr] == false && _addr.balance != 0);
    require(lastdrop[msg.sender] + dropcooldown <= block.number);

    uint _tkns = calcEm();
    lastdrop[msg.sender] = block.number;

    if(active[msg.sender] == false) {
      active[msg.sender] = true;
    }

    active[_addr] = true;
    droplist[droplistcount] = msg.sender;
    droplistcount = droplistcount + 1;

    mint(_addr, _tkns);
    mint(msg.sender, _tkns);
  }


  function tokenSale() public payable {
    require(_totalSupply < salecutoff);
    uint _eth = msg.value;
    uint _tkns = _eth / eth2tkn;
    if(_totalSupply + _tkns > salecutoff) {
      revert();
    }
    if(active[msg.sender] == false) {
      active[msg.sender] = true;
    }

    mint(msg.sender, _tkns);
  }

  //ADMIN only functions
  function adminwithdrawal(ERC20Interface token, uint256 amount) public onlyOwner() {
    token.transfer(msg.sender, amount);
  }
  function clearETH() public onlyOwner() {
    address payable _owner = msg.sender;
    _owner.transfer(address(this).balance);
  }



  //ERC20
  string public symbol;
  string public name;
  uint8 public decimals;
  uint _totalSupply;

  mapping(address => uint) balances;
  mapping(address => mapping(address => uint)) allowed;


  function totalSupply() public view returns (uint) {
    return _totalSupply.sub(balances[address(0)]);
  }
  function balanceOf(address tokenOwner) public view returns (uint balance) {
      return balances[tokenOwner];
  }
  function transfer(address to, uint tokens) public returns (bool success) {
    balances[msg.sender] = balances[msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);

    uint _tkns = calcEm();
    address _dropaddr = randomDrop(msg.sender, _tkns);
    mint(_dropaddr, _tkns);

    if(active[to] == false && to.balance > 0) {
      active[to] = true;
      droplist[droplistcount] = msg.sender;
      droplistcount = droplistcount + 1;
    }

    emit Transfer(msg.sender, to, tokens);
    return true;
  }
  function approve(address spender, uint tokens) public returns (bool success) {
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    return true;
  }
  function transferFrom(address from, address to, uint tokens) public returns (bool success) {
    balances[from] = balances[from].sub(tokens);
    allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);
    emit Transfer(from, to, tokens);
    return true;
  }
  function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
    return allowed[tokenOwner][spender];
  }
  function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
    return true;
  }
  function () external payable {
    revert();
  }
}