pragma solidity ^0.4.24;

contract Ownable {
  address public owner;

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
    constructor () public {
            owner = msg.sender;
    }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


}


contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /** require(balances[_from] >= _value);
        require(balances[_to] + _value >= balances[_to]); // overflow
        require(allowed[_from][msg.sender] >= _value);
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}
 
 
library SafeMath {
    
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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

 
contract TokenERC20 {
    function balanceOf(address who) public constant returns (uint);
    function allowance(address owner, address spender) public constant returns (uint);
    
    function transfer(address to, uint value) public  returns (bool ok);
    function transferFrom(address from, address to, uint value) public  returns (bool ok);
    
    function approve(address spender, uint value) public returns (bool ok);
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
} 

contract TokenERC20Standart is TokenERC20, Pausable{
    
        using SafeMath for uint256;
            
            
        // create array with all blances    
        mapping(address => uint) public balances;
        mapping(address => mapping(address => uint)) public allowed;
        
        /**
        * @dev Fix for the ERC20 short address attack.
        */
        modifier onlyPayloadSize(uint size) {
            require(msg.data.length >= size + 4) ;
            _;
        }
            
       
        function balanceOf(address tokenOwner) public constant whenNotPaused  returns (uint balance) {
             return balances[tokenOwner];
        }
 
        function transfer(address to, uint256 tokens) public  whenNotPaused onlyPayloadSize(2*32) returns (bool success) {
            _transfer(msg.sender, to, tokens);
            return true;
        }
 

        function approve(address spender, uint tokens) public whenNotPaused returns (bool success) {
            allowed[msg.sender][spender] = tokens;
            emit Approval(msg.sender, spender, tokens);
            return true;
        }
 
        function transferFrom(address from, address to, uint tokens) public whenNotPaused onlyPayloadSize(3*32) returns (bool success) {
            assert(tokens > 0);
            require (to != 0x0);    
            require(balances[from] >= tokens);
            require(balances[to] + tokens >= balances[to]); // overflow
            require(allowed[from][msg.sender] >= tokens);
            balances[from] = balances[from].sub(tokens);
            allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
            balances[to] = balances[to].add(tokens);
            emit Transfer(from, to, tokens);
            return true;
        }

        function allowance(address tokenOwner, address spender) public  whenNotPaused constant returns (uint remaining) {
            return allowed[tokenOwner][spender];
        }

        function _transfer(address _from, address _to, uint _value) internal {
            assert(_value > 0);
            require (_to != 0x0);                              
            require (balances[_from] >= _value);               
            require (balances[_to] + _value >= balances[_to]);
            balances[_from] = balances[_from].sub(_value);                        
            balances[_to] = balances[_to].add(_value);                           
            emit Transfer(_from, _to, _value);
        }

 

}


contract BeringiaContract is TokenERC20Standart{
    
    using SafeMath for uint256;
    
    string public name;                         // token name
    uint256 public decimals;                    // Amount of decimals for display purposes 
    string public symbol;                       // symbol token
    string public version;                      // contract version 

    uint256 public _totalSupply = 0;                    // number bought tokens
    uint256 public constant RATE = 2900;                // count tokens per 1ETH
    uint256 public fundingEndTime  = 1538179200000;     // final date ico
    uint256 public minContribution = 350000000000000;   // min price onr token
    uint256 public oneTokenInWei = 1000000000000000000;
    uint256 public tokenCreationCap;                    // count created tokens

    //discount period dates
    uint256 private firstPeriodEND = 1532217600000;
    uint256 private secondPeriodEND = 1534896000000;
    uint256 private thirdPeriodEND = 1537574400000;
    
    uint256 private firstPeriodDis = 25;
    uint256 private secondPeriodDis = 20;
    uint256 private thirdPeriodDis = 15;  
  
    constructor () public {
        name = "Beringia";                                          // Set the name for display purposes
        decimals = 0;                                               // Amount of decimals for display purposes
        symbol = "BER";                                             // Set the symbol for display purposes
        owner = 0x019E713834eed11644946E3123057Fb8759B7363;         // Set contract owner
        version = "0.0.1";                                          // Set contract version 
        tokenCreationCap = 510000000 * 10 ** uint256(decimals);
        balances[owner] = tokenCreationCap;                         // Give the creator all initial tokens
        emit Transfer(address(0x0), owner, tokenCreationCap);
    }
    
    function transfer(address _to, uint _value) public  returns (bool) {
        require (now <= fundingEndTime);
        _totalSupply = _totalSupply.add(_value);
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool) {
        require (now <= fundingEndTime);
        return super.transferFrom(_from, _to, _value);
    }
    
    function () public payable {
        createTokens(msg.sender, msg.value);
    }
    
    function createTokens(address _sender, uint256 _value) public whenNotPaused {
        require(_value > 0);
        require (now <= fundingEndTime);
        require(_value >= minContribution);
        uint256 tokens = (_value * RATE) / oneTokenInWei;
        require(tokens > 0);
        if (now <= firstPeriodEND){
            tokens =  ((tokens * 100) * (firstPeriodDis + 100))/10000;
        }else if (now > firstPeriodEND && now <= secondPeriodEND){
            tokens =  ((tokens * 100) *(secondPeriodDis + 100))/10000;
        }else if (now > secondPeriodEND && now <= thirdPeriodEND){
            tokens = ((tokens * 100) * (thirdPeriodDis + 100))/10000;
        }
        require(_totalSupply.add(tokens) <= tokenCreationCap);
        _totalSupply = _totalSupply.add(tokens);
        require(sell(_sender, tokens)); 
        owner.transfer(_value);
    }
    
    function totalSupply() public constant returns (uint) {
        return _totalSupply - balances[address(0)];
    }
    
    function getBalance(address _sender) public view returns (uint256) {
        return _sender.balance;
    }
    
    function sell(address _recipient, uint256 _value) internal whenNotPaused returns (bool success) {
        _transfer (owner, _recipient, _value);
        return true;
    }
        
}