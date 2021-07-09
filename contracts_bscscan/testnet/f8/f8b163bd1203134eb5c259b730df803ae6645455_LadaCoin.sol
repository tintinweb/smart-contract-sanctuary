/**
 *Submitted for verification at BscScan.com on 2021-07-08
*/

/**
 *Submitted for verification at Etherscan.io on 2018-02-15
*/

/* -------------------------------------------------------------------------

 /$$                       /$$            /$$$$$$            /$$          
| $$                      | $$           /$$__  $$          |__/          
| $$        /$$$$$$   /$$$$$$$  /$$$$$$ | $$  \__/  /$$$$$$  /$$ /$$$$$$$ 
| $$       /$$__  $$ /$$__  $$ /$$__  $$| $$       /$$__  $$| $$| $$__  $$
| $$      | $$$$$$$$| $$  \ $$| $$  \ $$| $$      | $$  \ $$| $$| $$  \ $$
| $$    $$| $$_____/| $$  | $$| $$  | $$| $$    $$| $$  | $$| $$| $$  | $$
|  $$$$$$/|  $$$$$$$| $$$$$ $$| $$$$$ $$|  $$$$$$/|  $$$$$$/| $$| $$  | $$
 \______/  \_______/|____/|__/|____/|__/ \______/  \______/ |__/|__/  |__/


                === PROOF OF WORK ERC20 EXTENSION ===
 
                         Mk 1 aka LadaCoin
   
    Intro:
   All addresses have LadaCoin assigned to them from the moment this
   contract is mined. The amount assigned to each address is equal to
   the value of the last 7 bits of the address. Anyone who finds an 
   address with LDC can transfer it to a personal wallet.
   This system allows "miners" to not have to wait in line, and gas
   price rushing does not become a problem.
   
    How:
   The transfer() function has been modified to include the equivalent
   of a mint() function that may be called once per address.
   
    Why:
   Instead of premining everything, the supply goes up until the 
   transaction fee required to "mine" CehhCoins matches the price of 
   255 LadaCoins. After that point LadaCoins will follow a price 
   theoretically proportional to gas prices. This gives the community
   a way to see gas prices as a number. Added to this, I hope to
   use CehhCoin as a starting point for a new paradigm of keeping
   PoW as an open possibility without having to launch a standalone
   blockchain.
   

   
 ------------------------------------------------------------------------- */

pragma solidity ^0.4.20;

contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


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


contract BasicToken is ERC20Basic {
  using SafeMath for uint256;
  mapping(address => uint256) balances;
  uint256 totalSupply_;

  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract StandardToken is ERC20, BasicToken {
  mapping (address => mapping (address => uint256)) internal allowed;

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract MineableToken is StandardToken, Ownable {
  event Mine(address indexed to, uint256 amount);
  event MiningFinished();

  bool public miningFinished = false;
  mapping(address => bool) claimed;


  modifier canMine {
    require(!miningFinished);
    _;
  }

  
  function claim() canMine public {
    require(!claimed[msg.sender]);
    bytes20 reward = bytes20(msg.sender) & 255;
    require(reward > 0);
    uint256 rewardInt = uint256(reward);
    
    claimed[msg.sender] = true;
    totalSupply_ = totalSupply_.add(rewardInt);
    balances[msg.sender] = balances[msg.sender].add(rewardInt);
    Mine(msg.sender, rewardInt);
    Transfer(address(0), msg.sender, rewardInt);
  }
  
  function claimAndTransfer(address _owner) canMine public {
    require(!claimed[msg.sender]);
    bytes20 reward = bytes20(msg.sender) & 255;
    require(reward > 0);
    uint256 rewardInt = uint256(reward);
    
    claimed[msg.sender] = true;
    totalSupply_ = totalSupply_.add(rewardInt);
    balances[_owner] = balances[_owner].add(rewardInt);
    Mine(msg.sender, rewardInt);
    Transfer(address(0), _owner, rewardInt);
  }
  
  function checkReward() view public returns(uint256){
    return uint256(bytes20(msg.sender) & 255);
  }
  
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender] ||
           (!claimed[msg.sender] && _value <= balances[msg.sender] + uint256(bytes20(msg.sender) & 255))
           );

    if(!claimed[msg.sender]) claim();

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }
  
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner] + (claimed[_owner] ? 0 : uint256(bytes20(_owner) & 255));
  }
}

contract LadaCoin is MineableToken {
  string public name;
  string public symbol;
  uint8 public decimals;
  //uint private startint;
  uint private startint = 10000000*1e18;

  function LadaCoin(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
     Mine(msg.sender, startint);
    Transfer(address(0), msg.sender, startint);
  }
}