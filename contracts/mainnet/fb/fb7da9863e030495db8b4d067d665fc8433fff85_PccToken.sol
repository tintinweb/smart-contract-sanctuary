pragma solidity ^0.4.15;

/**
 * @dev PCC token smart contract. For more details see: www.pccico.com
 */

contract SafeMath {

    function safeAdd(uint256 x, uint256 y) internal returns(uint256) {
      uint256 z = x + y;
      assert((z >= x) && (z >= y));
      return z;
    }

    function safeSubtract(uint256 x, uint256 y) internal returns(uint256) {
      assert(x >= y);
      uint256 z = x - y;
      return z;
    }

    function safeMult(uint256 x, uint256 y) internal returns(uint256) {
      uint256 z = x * y;
      assert((x == 0)||(z/x == y));
      return z;
    }

    function safeDiv(uint256 a, uint256 b) internal returns (uint256) {
      assert(b > 0);
      uint c = a / b;
      assert(a == b * c + a % b);
      return c;
    }

}

contract Token {
    uint256 public totalSupply;
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
      if (balances[msg.sender] >= _value && _value > 0) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
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

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

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
  function Ownable() {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }

}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev modifier to allow actions only when the contract IS paused
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev modifier to allow actions only when the contract IS NOT paused
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused {
    paused = true;
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused {
    paused = false;
    Unpause();
  }
}

contract PccToken is SafeMath, StandardToken, Pausable {

    string public constant name = "PCC Token";
    string public constant symbol = "PCC";
    uint256 public constant decimals = 18;
    uint256 public constant tokenCreationCap = 1000000000*10**decimals;
    uint256 constant tokenCreationCapPreICO = 1000000*10**decimals;

    uint256 public oneTokenInWei = 200000000000000;

    uint public totalEthRecieved;

    Phase public currentPhase = Phase.PreICO;

    enum Phase {
        PreICO,
        ICO
    }

    event CreatePCC(address indexed _to, uint256 _value);
    event PriceChanged(string _text, uint _newPrice);
    event StageChanged(string _text);
    event Withdraw(address to, uint amount);

    function PccToken() {
    }

    function () payable {
        createTokens();
    }


    function createTokens() internal whenNotPaused {
        uint multiplier = 10 ** 10;
        uint256 tokens = safeDiv(msg.value*100000000, oneTokenInWei) * multiplier;
        uint256 checkedSupply = safeAdd(totalSupply, tokens);

        if (currentPhase == Phase.PreICO &&  checkedSupply <= tokenCreationCapPreICO) {
            addTokens(tokens);
        } else if (currentPhase == Phase.ICO && checkedSupply <= tokenCreationCap) {
            addTokens(tokens);
        } else {
            revert();
        }
    }

    function addTokens(uint256 tokens) internal {
        if (msg.value <= 0) revert();
        balances[msg.sender] += tokens;
        totalSupply = safeAdd(totalSupply, tokens);
        totalEthRecieved += msg.value;
        CreatePCC(msg.sender, tokens);
    }

    function withdraw(address _toAddress, uint256 amount) external onlyOwner {
        require(_toAddress != address(0));
        _toAddress.transfer(amount);
        Withdraw(_toAddress, amount);
    }

    function setEthPrice(uint256 _tokenPrice) external onlyOwner {
        oneTokenInWei = _tokenPrice;
        PriceChanged("New price set", _tokenPrice);
    }

    function setICOPhase() external onlyOwner {
        currentPhase = Phase.ICO;
        StageChanged("Current stage: ICO");
    }

    function setPreICOPhase() external onlyOwner {
        currentPhase = Phase.PreICO;
        StageChanged("Current stage: PreICO");
    }

    function generateTokens(address _reciever, uint256 _amount) external onlyOwner {
        require(_reciever != address(0));
        balances[_reciever] += _amount;
        totalSupply = safeAdd(totalSupply, _amount);
        CreatePCC(_reciever, _amount);
    }

}