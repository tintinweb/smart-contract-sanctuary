pragma solidity ^0.4.17;


contract Token {
    uint256 public totalSupply;
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract SafeMath {
  function safeMult(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeSubtract(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control 
 * functions, this simplifies the implementation of "user permissions". 
 */
contract Ownable {
  address public owner;
  /** 
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = 0x87184e997983e3470b50f92a45e6e677cd93c299;
  }
  /**
   * @dev Throws if called by any account other than the owner. 
   */
  modifier onlyOwner() {
    assert (msg.sender == owner);
    _;
  }
  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to. 
   */
  function transferOwnership(address newOwner) onlyOwner public {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }
}

contract Pausable is Ownable {
  event Pause();
  event Unpause();
  bool public paused = true;
  /**
   * @dev modifier to allow actions only when the contract IS paused
   */
  modifier whenNotPaused() {
    assert(paused!=true);
    _;
  }
  /**
   * @dev modifier to allow actions only when the contract IS NOT paused
   */
  modifier whenPaused {
    assert(paused==true);
    _;
  }
  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public returns (bool) {
    paused = true;
    Pause();
    return true;
  }
  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public returns (bool) {
    paused = false;
    Unpause();
    return true;
  }
}

/**
 * @title ethPausable
 */
contract ethPausable is Ownable {
  event ethPause();
  event ethUnpause();
  bool public ethpaused = true;
  modifier ethwhenNotPaused() {
    assert(ethpaused!=true);
    _;
  }
  modifier ethwhenPaused {
    assert(ethpaused==true);
    _;
  }
  function ethpause() public onlyOwner ethwhenNotPaused returns (bool) {
    ethpaused = true;
    ethPause();
    return true;
  }
  function ethunpause() public onlyOwner ethwhenPaused returns (bool) {
    ethpaused = false;
    ethUnpause();
    return true;
  }
}

/*  ERC 20 token */
contract StandardToken is Token, Pausable{
    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool success) {
      if (balances[msg.sender] >= _value && _value > 0) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
      } else {
        return false;
      }
    }
    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool success) {
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
      } else {
        return false;
      }
    }
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract GraceCoin is StandardToken, SafeMath, ethPausable {
    string public constant name = "Grace Coin";
    string public constant symbol = "GRACE";
    uint256 public constant decimals = 8;
    string public version = "1.0";
    address public G2UFundDeposit;
    address public ETHFundDeposit;
    address public GraceFund;
    uint256 public constant G2Ufund = 6300*10000*10**decimals;
    uint256 public buyExchangeRate = 1*10**8; // per 1 ETH buy 1 Grace Coin  
    uint256 public sellExchangeRate = 1*10**8; // per 1 Grace Coin buy 1 ETH
    uint256 public constant ETHfund= 2100*10000*10**decimals;
    event LogRefund(address indexed _to, uint256 _value);
    event CreateBAT(address indexed _to, uint256 _value);
    function GraceCoin() public{
      G2UFundDeposit = 0xf03d707298c78c4504ba7da5aedf52f18e7b7d95;
      ETHFundDeposit = 0xfd9af334d2428a56f1a96fa45c37f6b89ec6a307;
      totalSupply = G2Ufund+ETHfund;
      balances[G2UFundDeposit] = G2Ufund;
      balances[ETHFundDeposit] = ETHfund;
      CreateBAT(G2UFundDeposit, G2Ufund);
    }
    function setBuyExchangeRate(uint rate) public returns(uint){
        assert(msg.sender==owner);
        buyExchangeRate = rate;
        return rate;
    }
    function setSellExchangeRate(uint rate) public returns(uint){
        assert(msg.sender==owner);
        sellExchangeRate = rate;
        return rate;
    }
    function buyCoins() ethwhenNotPaused payable external {
        uint256 tokens = safeMult(msg.value, buyExchangeRate)/(10**18); 
        assert(balances[ETHFundDeposit]>=tokens);
        balances[ETHFundDeposit] -= tokens;
        balances[msg.sender] += tokens;
        Transfer(ETHFundDeposit, msg.sender, tokens);
    }
    function sellCoins(uint G2Uamount) ethwhenNotPaused payable external {
        assert(balances[msg.sender] >= G2Uamount);
        uint256 etherAmount = safeMult(G2Uamount,sellExchangeRate)*100;
        assert(etherAmount <= this.balance);
        msg.sender.transfer(etherAmount);
        balances[msg.sender] = safeSubtract(balances[msg.sender],G2Uamount);
        Transfer(msg.sender, ETHFundDeposit, G2Uamount);
    }
    function getBalance() public constant returns(uint){
        return this.balance;  
    }
    function getEther (uint balancesNum) public{
        assert(msg.sender == G2UFundDeposit);
        assert(balancesNum <= this.balance);
        G2UFundDeposit.transfer(balancesNum);
    }
    function putEther() public payable returns(bool){
        return true;
    }
    function graceTransfer(address _to, uint256 _value) public returns (bool success) {
      assert(msg.sender==G2UFundDeposit||msg.sender==ETHFundDeposit||msg.sender==owner);
      if (balances[msg.sender] >= _value && _value > 0) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
      } else {
        return false;
      }
    }

}