pragma solidity >0.4.23 <0.5.0;
library SafeMath {
function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }
function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }
function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;
  mapping(address => uint256) balances;
  uint256 totalSupply_;
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }
}
contract StandardToken is ERC20, BasicToken {
    // delete extra methods
  mapping (address => mapping (address => uint256)) internal allowed;
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }
function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }
function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }
function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
}
contract Art is StandardToken {
    string public name = "the first point of view";
    string public symbol = "POV";
    uint256 public decimals = 18;
    uint256 public totalSupply = 1 ether;
    
    // Struct
    address public artist = msg.sender;
    string public artistName = "zhang ji";
    string public artistEmail= "six@beslab.xyz";//艺术家邮箱
    string public artExplain= "the first crypto art";//解释，可以改
    string public artHash= "e87bb90a679d3f39295ebf31fcc59d0c";//艺术品Hash
    string public artDescription = "a work describe the view from higher level creatures; to see us; the typing keyboard is how we input thoughts to Silicon based memory system; indeed it is the eye of creatures; fingers are how they see us as.";//艺术品描述
    string public artCopyright = "Token holder has full copyright of this art piece including its interpretation, commercial use, ownership transfer, derivatives production, etc. ";//艺术品版权方案
    uint256 public transferLimit = 1 ether;
    string public artUrlList = "http://o9y6d5w69.bkt.clouddn.com/the%20first%20point%20of%20view.cryptoart";
    string public logo = &#39;<svg xmlns="http://www.w3.org/2000/svg" width="521" height="402"><path fill="#040404" d="M0 0v402h521V0H0z"/><path fill="#fbfbfb" d="M143 25c-19 3-40 5-57 15-8 6-16 15-10 25 7 10 21 14 32 17 30 9 64 9 95 5 16-2 34-6 47-16 10-7 12-18 2-27-9-7-20-11-31-13-18-5-36-6-54-6h-24m188 0c-19 3-40 5-56 15-8 5-16 15-10 24 6 10 19 14 30 18 29 9 63 10 93 6 17-3 36-6 50-16 9-6 14-16 6-25-7-8-19-12-29-15-20-6-40-7-60-7h-24z"/><path fill="#040404" d="M156 34c-19 3-38 3-56 11-5 2-16 6-16 12 0 3 3 5 5 7 6 4 14 7 21 9 28 8 59 8 88 5 14-2 28-5 40-11 4-2 11-6 10-11-1-8-15-11-21-13-15-5-30-7-46-8-8-1-17-2-25-1m189 0c-19 3-38 3-56 11-5 2-15 6-15 12 0 3 2 5 4 6 5 5 13 7 19 9a198 198 0 0 0 128-4c4-2 14-6 12-12-1-7-14-11-20-13-15-5-31-7-47-8-8-1-17-2-25-1z"/><path fill="#fbfbfb" d="M164 43c-19 3-13 32 6 28 18-4 11-32-6-28m186 1c-18 6-6 33 11 26 18-6 6-32-11-26z"/><path fill="#040404" d="M164 52c-7 2-3 13 4 10 7-2 3-13-4-10m189 0c-6 2-2 12 4 10 7-2 3-13-4-10z"/><path fill="#fbfbfb" d="M159 92c-23 3-46 3-67 13-9 5-20 11-18 23s20 18 30 21c31 10 67 10 99 6 15-2 33-6 46-15 7-5 13-13 9-21-5-9-15-13-24-17-17-6-37-8-55-9l-20-1m189 0c-23 3-44 3-66 13-9 4-20 10-19 21 1 12 18 19 28 22 29 10 63 11 94 8 17-2 36-6 51-15 7-4 14-11 11-20s-14-14-22-18c-18-7-38-9-57-10l-20-1z"/><path fill="#040404" d="M153 102c-18 3-37 3-54 11-5 2-15 6-15 12 0 3 3 5 5 7 6 4 13 6 20 8 28 9 59 9 88 6 14-2 28-5 41-11 4-2 11-6 10-11-1-8-15-12-21-14-14-4-29-6-44-7-10-1-20-2-30-1m189 0c-18 3-37 3-54 11-5 2-15 6-14 12 0 3 3 5 5 7 6 4 13 7 20 9 28 7 59 8 87 5 14-2 28-5 41-11 4-2 12-6 10-12-2-7-16-11-22-13-14-4-28-6-43-7-10-1-20-2-30-1z"/><path fill="#fbfbfb" d="M164 111c-19 3-13 32 6 28 18-4 11-32-6-28m189 0c-19 3-13 32 6 28 18-4 11-32-6-28z"/><path fill="#040404" d="M164 120c-7 2-2 12 4 10 7-2 3-13-4-10m189 0c-6 2-2 12 4 10 7-2 3-13-4-10z"/><path fill="#fbfbfb" d="M153 161c-21 3-43 4-63 14-9 4-18 11-16 22 3 12 19 17 29 21 29 8 61 10 91 7 18-2 38-6 53-15 7-4 14-11 11-20-3-10-16-16-25-19-16-5-32-8-49-9-10-1-21-2-31-1m189 0c-22 3-43 4-63 14-9 4-19 12-15 23 3 12 20 17 30 20 31 10 65 10 97 6 16-2 35-6 48-16 8-6 12-15 5-24-6-7-17-12-26-14a228 228 0 0 0-76-9z"/><path fill="#040404" d="M149 171c-17 3-35 4-51 11-4 2-14 6-14 12 1 3 4 5 6 7 6 4 13 7 20 8 28 7 57 9 85 6 14-2 30-5 43-11 4-2 12-6 10-12-2-7-16-11-22-13-23-8-52-11-77-8m191 0c-18 3-35 4-52 11-5 2-15 6-15 12 1 3 4 5 6 7 6 4 12 6 19 8a209 209 0 0 0 129-5c4-2 12-6 10-12-2-7-16-11-22-13-23-7-51-11-75-8z"/><path fill="#fbfbfb" d="M163 180c-18 4-11 32 7 27 18-4 11-32-7-27m189 0c-18 4-11 32 7 28 18-5 11-33-7-28z"/><path fill="#040404" d="M163 189c-6 4 0 13 6 10 6-4 1-14-6-10m189 0c-6 4 0 13 6 10 6-4 1-14-6-10z"/><path fill="#fbfbfb" d="M155 229c-22 3-43 4-63 13-9 4-19 11-18 22 2 12 18 18 28 21a221 221 0 0 0 145-7c7-4 14-11 11-20-3-10-14-15-23-18-17-7-36-9-54-10-9-1-17-2-26-1m189 0c-22 3-44 4-64 14-8 4-18 10-17 21 2 12 18 18 28 21 29 10 63 11 93 8 17-2 37-6 52-15 7-4 14-12 11-21-3-10-16-15-25-18-17-6-34-8-51-9-9-1-18-2-27-1z"/><path fill="#040404" d="M151 239c-18 3-35 4-52 11-4 2-16 6-15 12 0 3 4 5 6 7 6 4 13 6 20 8 28 8 59 9 87 6 14-2 29-5 41-11 4-2 11-6 10-11-1-8-15-12-22-14-23-7-51-11-75-8m189 0c-18 3-35 4-52 11-5 2-15 6-15 12 1 3 4 5 6 7 6 4 13 6 20 8 28 8 59 9 87 6 14-2 29-5 41-11 4-2 12-6 10-12-2-7-16-11-22-13-23-7-51-11-75-8z"/><path fill="#fbfbfb" d="M164 247c-19 4-13 33 6 29 17-4 11-32-6-29m189 1c-19 3-13 32 6 28 18-4 12-32-6-28z"/><path fill="#040404" d="M163 257c-6 4 0 13 6 10 6-4 0-14-6-10m190 0c-6 2-2 12 4 10 7-2 3-13-4-10z"/><path fill="#fbfbfb" d="M159 297c-23 3-46 3-67 13-9 5-19 11-18 22 1 12 18 18 28 21a219 219 0 0 0 145-7c7-4 14-11 11-20s-14-15-22-18c-18-7-38-9-57-10l-20-1m189 0c-23 3-46 3-67 13-8 4-19 10-18 21 1 12 18 19 28 22 29 10 63 11 94 8 17-2 36-6 51-15 7-4 14-11 11-20-3-10-14-15-23-18-18-7-37-9-56-10l-20-1z"/><path fill="#040404" d="M153 307c-18 3-37 3-54 11-4 2-16 6-15 12 0 3 3 5 5 6 6 5 14 8 21 10 28 7 59 8 87 5 14-2 28-5 41-11 4-2 11-6 10-11-1-8-15-12-21-14-14-4-29-6-44-7-10-1-20-2-30-1m189 0c-18 3-37 3-54 11-5 2-15 6-14 12 0 3 3 5 5 7 6 4 13 7 20 9 28 7 59 8 87 5 14-2 28-5 41-11 4-2 12-6 10-12-2-7-16-11-22-13a210 210 0 0 0-73-8z"/><path fill="#fbfbfb" d="M164 316c-19 3-13 32 6 28 17-4 11-32-6-28m189 0c-19 3-13 32 6 28 18-4 11-32-6-28z"/><path fill="#040404" d="M164 325c-7 2-2 12 4 10 7-2 3-13-4-10m189 0c-6 2-2 12 4 10 7-2 3-13-4-10z"/></svg>"&#39;; 
    
    constructor() public {
        totalSupply_ = totalSupply;
        balances[artist] = totalSupply;
        emit Transfer(0x0, artist, totalSupply);
    }
event TransferOwner(address newOwner, address lastOwner);
modifier onlyArtist() {
        require(msg.sender == artist, "Only artist can do this.");
        _;
    }
    
    function changeOwner(address newOwner) internal onlyArtist returns (bool) {
        artist = newOwner;
    }
    
    function changeExplain(string newExplain) public onlyArtist returns (bool) {
        artExplain = newExplain;
    }
    
    function changeArtName(string newName, string newSymbol) public onlyArtist returns (bool) {
        name = newName;
        symbol = newSymbol;
    }
    
    function changeArtUrl(string newUrl) public onlyArtist returns (bool) {
        artUrlList = newUrl;
    }
    
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        require(_value == transferLimit, "Token unit is 1.");
    
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        changeOwner(_to);
        emit TransferOwner(_to,msg.sender);
        return true;
  }
}