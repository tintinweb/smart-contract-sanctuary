pragma solidity ^0.4.18;



/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
   function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b; 
    assert(a == 0 || c / a == b);
    return c;
    }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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



/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
    
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
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
  function balanceOf(address _owner) public returns (uint256 balance) {
    return balances[_owner];
  }

}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    var _allowance = allowed[_from][msg.sender];
    
    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));
    
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
  
}
 

contract Ownable {
    
    address public owner;

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner  {
        require(newOwner != address(0));
        owner = newOwner;
    }
    
}

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
  
  
}

contract ARKCoin is MintableToken {
    
    string public constant name = "ARK Coin";
    
    string public constant symbol = "ARC";
    
    uint32 public constant decimals = 18;
    
}

contract Crowdsale is Ownable {
    
    using SafeMath for uint;
    
    address public multisig;

    uint public restrictedPercent;

    address public restricted;

    ARKCoin public token = new ARKCoin();

    uint public start;
    
    uint public period;

    uint public hardcap;

    uint256 public rate;

    uint public softcap;
    
    mapping (address => uint) public balances;
    
    uint public ratePreSale = 7500000000000000000000; // 1ETH = 7500 SWC
    uint public rateSale = 5000000000000000000000; // 1ETH = 5000 SWC


    function Crowdsale() public {
	    multisig = 0x6D1D26103b62Bf9f13E3409C8f069Cb3484e7A96;
	    restricted = 0x1076c08E332401759aFE65E02D67aDE5e28E5762;
	    restrictedPercent = 41;
	    rate = 5000000000000000000000;
	    start = 1533902400;
	    period = 31;
	    hardcap = 200 ether;
	    softcap = 31 ether;
    }

    modifier saleIsOn() {
    	require(now > start && now < start + period * 1 days);
    	_;
    }
	
    modifier isUnderHardCap() {
        require(multisig.balance <= hardcap);
        _;
    }

    function refund() public {
        require(this.balance < softcap && now > start + period * 1 days);
        uint value = balances[msg.sender];
        balances[msg.sender] = 0;
        msg.sender.transfer(value);
    } 

    function finishMinting() public onlyOwner {
        if(this.balance > softcap) {
            multisig.transfer(this.balance);
            uint issuedTokenSupply = token.totalSupply();
            uint restrictedTokens = issuedTokenSupply.mul(restrictedPercent).div(100 - restrictedPercent);
            token.mint(restricted, restrictedTokens);
            token.finishMinting(); 
        }
    }


   function createTokens() public isUnderHardCap saleIsOn payable {
        multisig.transfer(msg.value);
        uint tokens = rate.mul(msg.value).div(1 ether);
        uint bonusTokens = 0;
        if(now < start + (period * 1 days).div(3)) {
          bonusTokens = tokens.div(2);
        } else if(now >= start + (period * 1 days).div(3) && now < (period * 1 days).div(3).mul(2)) {
          bonusTokens = tokens.div(5);
        } else if(now >= start + (period * 1 days).div(3).mul(2) && now < (period * 1 days).div(3).mul(3)) {
          bonusTokens = tokens.div(10);
        }
        tokens += bonusTokens;
        token.mint(msg.sender, tokens);
        balances[msg.sender] = balances[msg.sender].add(msg.value);
    }
    

    function() external payable {
        createTokens();
    }
    
}