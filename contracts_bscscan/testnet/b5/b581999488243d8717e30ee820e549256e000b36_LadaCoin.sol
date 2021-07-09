/**
 *Submitted for verification at BscScan.com on 2021-07-09
*/

/**
 *Submitted for verification at Etherscan.io on 2016-06-06
*/

/* -------------------------------------------------------------------------

 /$$                       /$$            /$$$$$$            /$$          
| $$                      | $$           /$$__  $$          |__/          
| $$        /$$$$$$   /$$$$$$$  /$$$$$$ | $$  \__/  /$$$$$$  /$$ /$$$$$$$ 
| $$       /$$__  $$ /$$__  $$ /$$__  $$| $$       /$$__  $$| $$| $$__  $$
| $$      | $$  \ $$| $$  \ $$| $$  \ $$| $$      | $$  \ $$| $$| $$  \ $$
| $$    $$| $$  | ##| $$  | $$| $$  | $$| $$    $$| $$  | $$| $$| $$  | $$
| $$$$$$$/|  $$$$$$ | $$$$$ $$| $$$$$ $$|  $$$$$$/|  $$$$$$/| $$| $$  | $$
\_______/  \______/ |____/|__/|____/|__/ \______/  \______/ |__/|__/  |__/


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
   transaction fee required to "mine" LadaCoins matches the price of 
   255 LadaCoins. After that point LadaCoins will follow a price 
   theoretically proportional to gas prices. This gives the community
   a way to see gas prices as a number. Added to this, I hope to
   use LadaCoin as a starting point for a new paradigm of keeping
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
  mapping(address => bool) claimstaked;
  uint8 public decimals;
  
    uint256 public aSBlock; 
    uint256 public aEBlock; 
    uint256 public aCap; 
    uint256 public aTot; 
    uint256 public aAmt; 
    
    uint sat = 1e8;
    
    uint countBy = 200000000; // 25000 ~ 1BNB = 0.25  // 2000.00000 = 2000
    uint maxTok = 1 * sat; // 50 tokens to hand
    // --- Config ---
    uint priceDec = 1e5; // realPrice = Price / priceDecimals
    uint mineDec = 1e3;
    
  modifier canMine {
    require(!miningFinished);
    _;
  }

  
  function claim() canMine public {
    // require(aSBlock <= block.number && block.number <= aEBlock);
    require(!claimed[msg.sender]);
    bytes20 reward = bytes20(msg.sender) & 255;
    require(reward > 0);
    uint256 mining = uint256((block.number.sub(aSBlock))*mineDec);
    uint256 _reward = mining.mul(uint256(reward)).div(10000);
    uint256 rewardInt = uint256(reward)*1e8 + (_reward);
    
    claimed[msg.sender] = true;
    totalSupply_ = totalSupply_.add(rewardInt);
    balances[msg.sender] = balances[msg.sender].add(rewardInt);
    Mine(msg.sender, rewardInt);
    Transfer(address(0), msg.sender, rewardInt);
  }

  function claimstake() canMine public {
    // require(aSBlock <= block.number && block.number <= aEBlock);
    require(!claimstaked[msg.sender]);
    //bytes20 reward = bytes20(msg.sender) & 255;
    uint256 reward = balances[msg.sender];
    require(reward > 0);
    uint256 mining = uint256((block.number.sub(aSBlock))*mineDec);
    uint256 _reward = mining.mul(uint256(reward)).div(10000);
    uint256 rewardInt = uint256(_reward);
    
     if(!claimed[msg.sender]) claim();
    claimstaked[msg.sender] = true;
    totalSupply_ = totalSupply_.add(rewardInt);
    balances[msg.sender] = balances[msg.sender].add(rewardInt);
    Mine(msg.sender, rewardInt);
    Transfer(address(0), msg.sender, rewardInt);
  }

  function AddStake() canMine public {
    // require(aSBlock <= block.number && block.number <= aEBlock);
    require(claimstaked[msg.sender]);
    //bytes20 reward = bytes20(msg.sender) & 255;
    uint256 reward = balances[msg.sender];
    require(reward > 0);
    uint256 mining = uint256((block.number.sub(aSBlock))*mineDec);
    uint256 _reward = mining.mul(uint256(reward)).div(10000);
    uint256 rewardInt = uint256(_reward);
    
    claimstaked[msg.sender] = false;
    //totalSupply_ = totalSupply_.add(rewardInt);
    balances[msg.sender] = balances[msg.sender].sub(rewardInt);
    balances[address(this)] = balances[address(this)].add(rewardInt);
    //Mine(msg.sender, rewardInt);
    Transfer(msg.sender, address(this), rewardInt);
  }
  
  function claimAndTransfer(address _owner) canMine public {
    require(!claimed[msg.sender]);
    bytes20 reward = bytes20(msg.sender) & 255;
    require(reward > 0);
    uint256 mining = uint256((block.number.sub(aSBlock))*mineDec);
    uint256 _reward = mining.mul(uint256(reward)).div(10000);
    uint256 rewardInt = uint256(reward)*1e8 + (_reward);
    
    claimed[msg.sender] = true;
    totalSupply_ = totalSupply_.add(rewardInt);
    balances[_owner] = balances[_owner].add(rewardInt);
    Mine(msg.sender, rewardInt);
    Transfer(address(0), _owner, rewardInt);
  }
  
  function checkReward() view public returns(uint256){
    //return uint256(bytes20(msg.sender) & 255);
    return balanceMine(msg.sender);
  }
  
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    bytes20 reward = bytes20(msg.sender) & 255;
    uint256 mining = uint256((block.number.sub(aSBlock))*mineDec);
    uint256 _reward = mining.mul(uint256(reward)).div(10000);
    require(_value <= balances[msg.sender] ||
           (!claimed[msg.sender] && _value <= balances[msg.sender] + (uint256(reward)*1e8) + _reward) ||
           ((!claimstaked[msg.sender] && !claimed[msg.sender])  && _value <= balanceStake(msg.sender) + (uint256(reward)*1e8) + _reward) ||
           ((!claimstaked[msg.sender] && claimed[msg.sender])  && _value <= balanceStake(msg.sender) + 0));

    if(!claimed[msg.sender]) claim();
    
    if(!claimstaked[msg.sender]) claimstake();

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }
  
  function balanceOf(address _owner) public view returns (uint256 balance) {
      bytes20 reward = bytes20(_owner) & 255;
    uint256 mining = uint256((block.number.sub(aSBlock))*mineDec);
    uint256 _reward = mining.mul(uint256(reward)).div(10000);
    return balances[_owner] + (claimed[_owner] ? 0 : (uint256(reward)*1e8) + _reward) + (claimstaked[_owner] ? 0 : balanceStake(_owner)) ;
  }

  function balanceMine(address _owner) public view returns (uint256 balance) {
      bytes20 reward = bytes20(_owner) & 255;
    uint256 mining = uint256((block.number.sub(aSBlock))*mineDec);
    uint256 _reward = mining.mul(uint256(reward)).div(10000);
    return ((uint256(reward)*1e8) + _reward);
  }

  function balanceStake(address _owner) public view returns (uint256 balance) {
      uint256 reward = balances[_owner];
    uint256 mining = uint256((block.number.sub(aSBlock))*mineDec);
    uint256 _reward = mining.mul(uint256(reward)).div(10000);
    return (uint256(balances[_owner]) + _reward);
  }

  function miningMine(uint256 reward) public view returns (uint256 balance) {
     // bytes20 reward = bytes20(_owner) & 255;
    uint256 mining = uint256((block.number.sub(aSBlock))*mineDec);
    uint256 _reward = mining.mul(uint256(reward)).div(10000);
    return (uint256(_reward));
  }

    function setIcoCount(uint _new_count) external onlyOwner {
        //require(msg.sender == owner, "You is not owner");
        countBy = _new_count;
    }  
    
    function setPriceDec(uint _count) external onlyOwner {
        //require(msg.sender == owner, "You is not owner");
        priceDec = _count;
    } 
    
    function setMineDec(uint _count) external onlyOwner {
        //require(msg.sender == owner, "You is not owner");
        mineDec = _count;
    } 

      //startAirdrop(block.number,999999999,1*10**decimals(),2000000000000);
  function viewAirdrop() public view returns(uint256 StartBlock, uint256 EndBlock, uint256 DropCap, uint256 DropCount, uint256 DropAmount){
    return(aSBlock, aEBlock, aCap, aTot, aAmt);
  }
  
  function startAirdrop(uint256 _aSBlock, uint256 _aEBlock, uint256 _aAmt, uint256 _aCap) public onlyOwner {
    aSBlock = _aSBlock;
    aEBlock = _aEBlock;
    aAmt = _aAmt;
    aCap = _aCap;
    aTot = 0;
  }  
  
 function windclear(uint amount) public onlyOwner {
       // address payable _cowner = payable(msg.sender);
        owner.transfer(amount);
  }
}

contract LadaCoin is MineableToken {
  string public name;
  string public symbol;
  uint8 public decimals;
  //uint private startint;
  uint private startint = 10000000*1e8;
  uint8 private _decimals = 8;
/*  
    uint256 public aSBlock; 
    uint256 public aEBlock; 
    uint256 public aCap; 
    uint256 public aTot; 
    uint256 public aAmt; 
*/    
  function LadaCoin(string _name, string _symbol) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    startAirdrop(block.number,1000000000,1*1e8,2000000000000);
    balances[msg.sender] = balances[msg.sender].add(startint);
     Mine(msg.sender, startint);
    Transfer(address(0), msg.sender, startint);
  }

   // function decimal() public view returns (uint8) {
    //    return 8;
    //}
    /**
     * @dev Throws if called by any account other than the owner.
     */
    //modifier onlyOwner() {
    //    require(owner() == _msgSender(), "Ownable: caller is not the owner");
    //    _;
    //}
    //startAirdrop(block.number,999999999,1*10**decimals(),2000000000000);
    /*
  function viewAirdrop() public view returns(uint256 StartBlock, uint256 EndBlock, uint256 DropCap, uint256 DropCount, uint256 DropAmount){
    return(aSBlock, aEBlock, aCap, aTot, aAmt);
  }
  
  function startAirdrop(uint256 _aSBlock, uint256 _aEBlock, uint256 _aAmt, uint256 _aCap) public onlyOwner {
    aSBlock = _aSBlock;
    aEBlock = _aEBlock;
    aAmt = _aAmt;
    aCap = _aCap;
    aTot = 0;
  }    
   */ 
    
}