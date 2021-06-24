/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

pragma solidity ^0.4.26;

/// import base  contracts, interfaces, libraries from latest gitHUB

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
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }
 
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a); 
    return a - b; 
  } 
  
  function add(uint256 a, uint256 b) internal pure returns (uint256) { 
    uint256 c = a + b; assert(c >= a);
    return c;
  }
 
}

/**
 * @title ERC223 interface
 * @dev interface ERC223 for emit tokenFallback event
 */
 
contract TokenReceiver {
  function tokenFallback(address _sender, address _origin, uint _value) public returns (bool ok);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 * @dev Addedd ERC223 send tokens to another contract Implementation
 */
 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;
 
  mapping(address => uint256) balances;
  
  modifier onlyPayloadSize(uint size) {
      require(!(msg.data.length < size + 4));
      _;
  }
 
  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public onlyPayloadSize(2*32) returns (bool) {
    bool result = _transfer(msg.sender, _to, _value);
    if (result && isContract(_to)) {
        result = _transferToContract(msg.sender, _to, _value);
    }
    return result;
  }
  
  function _transfer(address _from, address _to, uint256 _value) internal returns (bool) {
    require(_to != address(0));
    require(_value > 0);
    require(_value <= balances[_from]); 
    // SafeMath.sub will throw if there is not enough balance. 
    balances[_from] = balances[_from].sub(_value); 
    balances[_to] = balances[_to].add(_value); 
    emit Transfer(_from, _to, _value); 
    return true; 
  }
  
  //assemble the given address bytecode. If bytecode exists then the _addr is a contract.
  function isContract(address _addr) internal constant returns (bool is_contract) {
    uint length;
    assembly {
        //retrieve the size of the code on target address, this needs assembly
        length := extcodesize(_addr)
    }
    return (length > 0);
  }
  
  /**
    * @dev Function that is called when a user or another contract wants
    *  to transfer funds to smart-contract
    * @return A boolean that indicates if the operation was successful
    */
    function _transferToContract(address _from, address _to, uint _value) internal returns (bool success) {
        TokenReceiver receiver = TokenReceiver(_to);
        return receiver.tokenFallback(_from, this, _value);
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
 
  mapping (address => mapping (address => uint256)) internal allowed;
 
  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public onlyPayloadSize(3*32) returns (bool) {
    require(_value <= allowed[_from][msg.sender]);
    bool result = _transfer(_from, _to, _value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    if (result && isContract(_to)) {
        result = _transferToContract(_from, _to, _value);
    }
    return result; 
  } 
 
 /** 
  * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender. 
  * 
  * Beware that changing an allowance with this method brings the risk that someone may use both the old 
  * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this 
  * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards: 
  * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729 
  * @param _spender The address which will spend the funds. 
  * @param _value The amount of tokens to be spent. 
  */ 
  function approve(address _spender, uint256 _value) public onlyPayloadSize(2*32) returns (bool) { 
    allowed[msg.sender][_spender] = _value; 
    emit Approval(msg.sender, _spender, _value); 
    return true; 
  }
 
 /** 
  * @dev Function to check the amount of tokens that an owner allowed to a spender. 
  * @param _owner address The address which owns the funds. 
  * @param _spender address The address which will spend the funds. 
  * @return A uint256 specifying the amount of tokens still available for the spender. 
  */ 
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) { 
    return allowed[_owner][_spender]; 
  } 
 
 /** 
  * approve should be called when allowed[_spender] == 0. To increment 
  * allowed value is better to use this function to avoid 2 calls (and wait until 
  * the first transaction is mined) * From MonolithDAO Token.sol 
  */ 
  function increaseApproval (address _spender, uint _addedValue) public onlyPayloadSize(2*32) returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]); 
    return true; 
  }
 
  function decreaseApproval (address _spender, uint _subtractedValue) public onlyPayloadSize(2*32) returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender]; 
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
 
  /*this function is commented for payload to commissions ability. see ERC223Receiver contract
  function () public payable {
    revert();
  }*/
 
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;
 
 
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
 
 
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
 
 
  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
 
}

/**
 * @title ERC223 receiver
 * @dev - basic implementation that sent all tokens to special address, by default to owner.
 */
contract ERC223Receiver is TokenReceiver, Ownable {
    address tokenHolder;
    event getTokens(address indexed _from, address indexed _origin, uint _value);
    
    constructor () public {
        tokenHolder = msg.sender;
    }
    
    /**
     * @dev - set new address to sent all incoming tokens.
     * @param _newTokenHolder address to sent all incoming tokens.
     */
    function setTokenHolder(address _newTokenHolder) public onlyOwner {
        tokenHolder = _newTokenHolder;
    }
    
    /**
     * @dev - ERC223 special callback function. callable from another contract.
     * @param _sender address that sent tokens
     * @param _origin ERC223 contract address
     * @param _value amount of transferred tokens.
     */
    function tokenFallback(address _sender, address _origin, uint _value) public returns (bool ok) {
        // in contract._origin was transfer(_sender, this, _value);
        // to send all we can
        // 1. create contract._origin
        // 2. transfer from this to special address _value tokens.
        // 3. do something changes in this contract? mint some tokens?
        ERC20Basic erc223 = ERC20Basic(_origin);
        bool result = erc223.transfer(tokenHolder, _value);
        emit getTokens(_sender, _origin, _value);
        return result;
    }
    
    /**
     * @dev noERC223 special function for transfer erc20 basable tokens from this contract to tokenHolder(by default owner) special address.
     * @param _contract address of contract to check for balance & transfer tokens to tokenHolder.
     * @return true if balance greter than 0 & transfer is ok.
     */
    function collectTokens(address _contract) public returns (bool ok) {
        ERC20Basic erc20 = ERC20Basic(_contract);
        uint256 balance = erc20.balanceOf(this);
        ok = false;
        if (balance > 0) {
            ok = erc20.transfer(tokenHolder, balance);
            emit getTokens(msg.sender, _contract, balance);
        }
        return ok;
    }
    
    /**
     * @dev function to send all ethers from contract to owner
     */
    function collectEther() public onlyOwner payable {
        owner.transfer(address(this).balance);
    }
    
    function () external payable {
    }
}

/**
 * @title - Liqnet Extension Token
 * @dev - LIQNET Extension for Mintable & Burnable for maxMintableSupply
 */
contract LiqnetExtToken is ERC223Receiver {
    
    using SafeMath for uint256;
    
    uint public maxMintSupply;
    uint public totalMinted = 0;
    
    modifier canMint(uint value) {
        require((totalMinted.add(value)) <= maxMintSupply);
        _;
    }
    
    function isMintFinished() internal view returns (bool isFinished) {
        return (totalMinted >= maxMintSupply);
    }
}


 
/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
 
contract MintableToken is StandardToken, Ownable, LiqnetExtToken {
    
  event Mint(address indexed to, uint256 amount);
  
  event MintFinished();
 
  bool public mintingFinished = false;
 
  address public saleAgent;
  
  constructor () public {
      saleAgent = msg.sender;
  }
  
  /**
   * @dev Allows the current owner to approve control of the minting to additional address.
   * @param newSaleAgent The address to approve minting control.
   */
  function setSaleAgent(address newSaleAgent) public {
    require(msg.sender == saleAgent || msg.sender == owner);
    saleAgent = newSaleAgent;
  }
  
  /**
   * @dev Allows the current owner or saleAgent mint some coins to address.
   * @param _to The address for new coins.
   * @param _amount amount of coin to mint.
   * @return true if mint is successful.
   */
  function mint(address _to, uint256 _amount) public canMint(_amount) returns (bool) {
    require((msg.sender == saleAgent || msg.sender == owner) && !mintingFinished);
    totalSupply = totalSupply.add(_amount);
    totalMinted = totalMinted.add(_amount); //**************************LiqnetExtToken
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    if (isMintFinished()) { finishMinting(); } //***********LiqnetExtToken
    return true;
  }
 
  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() public returns (bool) {
    require((msg.sender == saleAgent || msg.sender == owner) && !mintingFinished);
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

/**
 * @title Burnable tokens
 * @dev functions for burn previosly minted tokens
 */
contract BurnableToken is StandardToken, Ownable, LiqnetExtToken {
    
    uint public totalBurned = 0;
    
    /**
   * @dev Allows the current owner of coins burn it.
   * @param value - amount of coins to burn.
   */
    function burn(uint value) public onlyPayloadSize(32) {
        require(value>0 && balances[msg.sender] >= value);
        balances[msg.sender] = balances[msg.sender].sub(value);
        totalSupply = totalSupply.sub(value);
        totalBurned = totalBurned.add(value);
        emit Burn(msg.sender, value);
    }
    
    /**
   * @dev Allows the spender (approve function) to burn some coins from another address.
   * @param from - address for burn coins.
   * @param value - amount of coins to burn.
   */
    function burnFrom(address from, uint value) public onlyPayloadSize(2*32)  {
        require(value > 0 && value <= balances[from] && value <= allowed[from][msg.sender]);
        balances[from] = balances[from].sub(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        totalSupply = totalSupply.sub(value);
        totalBurned = totalBurned.add(value);
        emit Burn(from, value);
    }
    
    event Burn(address indexed burner, uint indexed value);
}


/**
 * @title - LIQNET Liqidity Exchange Network tokens
 * @dev mint will be executed from Crowdsale contract
 */
contract LiqnetCoin is MintableToken, BurnableToken {
    
    string public constant name = "Liqnet Coin";
    
    string public constant symbol = "LEN";
    
    uint32 public constant decimals = 18;
    
    constructor() public {
        maxMintSupply = 3500000 * (1 ether);
    }
    
}