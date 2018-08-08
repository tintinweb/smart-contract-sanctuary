pragma solidity ^0.4.24;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
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
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of. 
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public constant returns (uint256 balance) {
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

  mapping (address => mapping (address => uint256)) allowed;

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    uint256 _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

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
  constructor() public {
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
  function transferOwnership(address newOwner) public onlyOwner {
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
   * @param _to The address that will recieve the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
  
}

contract SMAR is MintableToken {
    
    string public constant name = "SmartRetail ICO";
    
    string public constant symbol = "SMAR";
    
    uint32 public constant decimals = 18;
    
}


contract Crowdsale is Ownable {
    
    using SafeMath for uint;
    
    address public multisig = 0xF15eE43d0345089625050c08b482C3f2285e4F12;
    
    uint dec = 1000000000000000000;
    
    SMAR public token = new SMAR();

    
    uint public icoStartP1 = 1528675200; // GMT: Mon, 11 Jun 2018 00:00:00 GMT
    uint public icoStartP2 = 1531267200; // Wed, 11 Jul 2018 00:00:00 GMT
    uint public icoStartP3 = 1533945600; // GMT: Sat, 11 Aug 2018 00:00:00 GMT
    uint public icoStartP4 = 1536624000; // Tue, 11 Sep 2018 00:00:00 GMT
    uint public icoStartP5 = 1539216000; // GMT: Thu, 11 Oct 2018 00:00:00 GMT
    uint public icoStartP6 = 1541894400; // GMT: Sun, 11 Nov 2018 00:00:00 GMT
    uint public icoEnd = 1544486400; // Tue, 11 Dec 2018 00:00:00 GMT
    
    
    
    uint public icoSoftcap = 35000*dec; // 35 000 SMAR
    uint public icoHardcap =  1000000*dec; // 1 000 000 SMAR


    //----
    uint public tokensFor1EthP6 = 50*dec; //0.02 ETH for 1 token
    uint public tokensFor1EthP1 = tokensFor1EthP6*125/100; //0,016   ETH for 1 token
    uint public tokensFor1EthP2 = tokensFor1EthP6*120/100; //0,01667 ETH for 1 token
    uint public tokensFor1EthP3 = tokensFor1EthP6*115/100; //0,01739 ETH for 1 token
    uint public tokensFor1EthP4 = tokensFor1EthP6*110/100; //0,01818 ETH for 1 token
    uint public tokensFor1EthP5 = tokensFor1EthP6*105/100; //0,01905 ETH for 1 token
    //----
        
    mapping(address => uint) public balances;



    constructor() public {
       owner = multisig;
       token.mint(multisig, 5000*dec);  
    }


    function refund() public {

      require(  (now>icoEnd)&&(token.totalSupply()<icoSoftcap) );
      uint value = balances[msg.sender]; 
      balances[msg.sender] = 0; 
      msg.sender.transfer(value); 
    }
    

    function refundToWallet(address _wallet) public  {

      require(  (now>icoEnd)&&(token.totalSupply()<icoSoftcap) );
      uint value = balances[_wallet]; 
      balances[_wallet] = 0; 
      _wallet.transfer(value); 
    }    
    

    function withdraw() public onlyOwner {

       require(token.totalSupply()>=icoSoftcap);
       multisig.transfer(address(this).balance);
    }



    function finishMinting() public onlyOwner {
      if(now>icoEnd) {
        token.finishMinting();
        token.transferOwnership(multisig);
      }
    }


   function createTokens()  payable public {

      require( (now>=icoStartP1)&&(now<icoEnd) );

      require(token.totalSupply()<icoHardcap);
       
      uint tokens = 0;
      uint sum = msg.value;
      uint tokensFor1EthCurr = tokensFor1EthP6;
      uint rest = 0;
      

      if(now < icoStartP2) {
        tokensFor1EthCurr = tokensFor1EthP1;
      } else if(now >= icoStartP2 && now < icoStartP3) {
        tokensFor1EthCurr = tokensFor1EthP2;
      } else if(now >= icoStartP3 && now < icoStartP4) {
        tokensFor1EthCurr = tokensFor1EthP3;
      } else if(now >= icoStartP4 && now < icoStartP5) {
        tokensFor1EthCurr = tokensFor1EthP4;
      } else if(now >= icoStartP5 && now < icoStartP6) {
        tokensFor1EthCurr = tokensFor1EthP5;
      }
      
      

      tokens = sum.mul(tokensFor1EthCurr).div(1000000000000000000);  
        

      if(token.totalSupply().add(tokens) > icoHardcap){

          tokens = icoHardcap.sub(token.totalSupply());

          rest = sum.sub(tokens.mul(1000000000000000000).div(tokensFor1EthCurr));
      }      
      

      token.mint(msg.sender, tokens);
      if(rest!=0){
          msg.sender.transfer(rest);
      }
      

      balances[msg.sender] = balances[msg.sender].add(sum.sub(rest));
      

      if(token.totalSupply()>=icoSoftcap){

        multisig.transfer(address(this).balance);
      }
    }

    function() external payable {
      createTokens();
    }
    
}