pragma solidity ^0.4.11;
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }
  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;
  mapping(address => uint256) balances;
  //address[] public addressLUT;
  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) returns (bool) {
      
    // Check to see if transfer window has been reached
    require (now >= 1512835200); // transfers can&#39;t happen until 3mo after sale ends (1512835200)
    
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }
  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of. 
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }
}

contract StandardToken is ERC20, BasicToken {
  mapping (address => mapping (address => uint256)) allowed;
  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];
    
    // Check to see if transfer window has been reached
    require (now >= 1512835200); // transfers can&#39;t happen until 3mo after sale ends (1512835200)
    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }
  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) returns (bool) {
    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }
  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
}

/**
 * Upgrade agent interface inspired by Lunyr.
 *
 * Upgrade agent transfers tokens to a new contract.
 * Upgrade agent itself can be the token contract, or just a middle man contract doing the heavy lifting.
 */
contract UpgradeAgent {
  /** Interface marker */
  function isUpgradeAgent() public constant returns (bool) {
    return true;
  }
  function upgradeFrom(address _from, uint256 _value) public;
}

contract PSIToken is StandardToken {
    address public owner;
    string public constant name = "Protostarr"; // Protostarr
    string public constant symbol = "PSR"; // PSR
    uint256 public constant decimals = 4;
    
    // Address for founder&#39;s PSI token and ETH deposits
    address public constant founders_addr = 0xEa16ebd8Cdf5A51fa0a80bFA5665146b2AB82210;
    
    UpgradeAgent public upgradeAgent;
    uint256 public totalUpgraded;
    
    event Upgrade(address indexed _from, address indexed _to, uint256 _value);
    
    event UpgradeAgentSet(address agent);
    function setUpgradeAgent(address agent) external {
        if (agent == 0x0) revert();
        // Only owner can designate the next agent
        if (msg.sender != owner) revert();
        upgradeAgent = UpgradeAgent(agent);
        
        // Bad interface
        if(!upgradeAgent.isUpgradeAgent()) revert();
        UpgradeAgentSet(upgradeAgent);
    }
    function upgrade(uint256 value) public {
        
        if(address(upgradeAgent) == 0x00) revert();
        // Validate input value.
        if (value <= 0) revert();
        
        balances[msg.sender] = balances[msg.sender].sub(value);
        
        // Take tokens out from circulation
        totalSupply = totalSupply.sub(value);
        totalUpgraded = totalUpgraded.add(value);
        
        // Upgrade agent reissues the tokens
        upgradeAgent.upgradeFrom(msg.sender, value);
        Upgrade(msg.sender, upgradeAgent, value);
    }

    // Constructor
    function PSIToken() {
        // set owner as sender
        owner = msg.sender;
        
        // add founders to address LUT
        //addressLUT.push(founders_addr);
    }
    // check to see if sender is owner
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    // Allows the current owner to transfer control of the contract to a newOwner.
    // newOwner The address to transfer ownership to.
    function transferOwnership(address newOwner) onlyOwner {
        require(newOwner != address(0));      
        owner = newOwner;
    }
    // catch received ether
    function () payable {
        createTokens(msg.sender);
    }
    // issue tokens for received ether
    function createTokens(address recipient) payable {
        if(msg.value<=uint256(1 ether).div(600)) {
            revert();
        }
    
        uint multiplier = 10 ** decimals;
    
        // create tokens for buyer
        uint tokens = ((msg.value.mul(getPrice())).mul(multiplier)).div(1 ether);
        totalSupply = totalSupply.add(tokens);
        balances[recipient] = balances[recipient].add(tokens);      
        
        // add buyer to address LUT
        //addressLUT.push(founders_addr);        
        
        // create 10% additional tokens for founders
        uint ftokens = tokens.div(10);
        totalSupply = totalSupply.add(ftokens);
        balances[founders_addr] = balances[founders_addr].add(ftokens);
    
        // send ETH for buy to founders
        if(!founders_addr.send(msg.value)) {
            revert();
        }
    
    }
  
    // get tiered pricing based on block.timestamp, or revert transaction if before/after sale times
    // Unix Timestamps
    // 1502640000 power hour start (170 tokens)
    // 1502643600 week 1 start (150 tokens)
    // 1503244800 week 2 start (130 tokens)
    // 1503849600 week 3 start (110 tokens)
    // 1504454400 week 4 start (100 tokens)
    // 1505059200 SALE ENDS
    // 1512835200 transfer period begins
    function getPrice() constant returns (uint result) {
        if (now < 1502640000) { // before power hour  1502640000
            revert(); // DISQUALIFIED!!! There&#39;s one every season!!!
        } else {
            if (now < 1502645400) { // before week 1 start (in power hour)  1502643600 (new 1502645400)
                return 170;
            } else {
                if (now < 1503244800) { // before week 2 start (in week 1)  1503244800
                    return 150;
                } else {
                    if (now < 1503849600) { // before week 3 start (in week 2)  1503849600
                        return 130;
                    } else {
                        if (now < 1504454400) { // before week 4 start (in week 3)  1504454400
                            return 110;
                        } else {
                            if (now < 1505059200) { // before end of sale (in week 4)  1505059200
                                return 100;
                            } else {
                                revert(); // sale has ended, kill transaction
                            }
                        }
                    }
                }
            }
        }
    }
  
}