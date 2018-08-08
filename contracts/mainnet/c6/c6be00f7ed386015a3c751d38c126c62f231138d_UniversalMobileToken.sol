/*
*
* Universal Mobile Token smart contract
* Developed by Phenom.team <info@phenom.team>   
*
*/

pragma solidity ^0.4.24;


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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint a, uint b) internal pure returns (uint) {
    if (a == 0) {
      return 0;
    }
    uint c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint a, uint b) internal pure returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }
}

contract UniversalMobileToken is Ownable {
    
    using SafeMath for uint;

    /*
        Standard ERC20 token
    */
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    // Name of token
    string public name;
    // Short symbol for token
    string public symbol;

    // Nubmer of decimal places
    uint public decimals;

    // Token&#39;s total supply
    uint public totalSupply;

    // Is minting active
    bool public mintingIsFinished;

    // Is transfer possible
    bool public transferIsPossible;

    modifier onlyEmitter() {
        require(emitters[msg.sender] == true);
        _;
    }
    
    mapping (address => uint) public balances;
    mapping (address => bool) public emitters;
    mapping (address => mapping (address => uint)) internal allowed;
    
    constructor() Ownable() public {
        name = "Universal Mobile Token";
        symbol = "UMT";
        decimals = 18;   
        // Make the Owner also an emitter
        emitters[msg.sender] = true;
    }

    /**
    *   @dev Finish minting process
    */
    function finishMinting() public onlyOwner {
        mintingIsFinished = true;
        transferIsPossible = true;
    }

    /**
    *   @dev Send coins
    *   throws on any error rather then return a false flag to minimize
    *   user errors
    *   @param _to           target address
    *   @param _value       transfer amount
    *
    *   @return true if the transfer was successful
    */
    function transfer(address _to, uint _value) public returns (bool success) {
        // Make transfer only if transfer is possible
        require(transferIsPossible);
        require(_to != address(0) && _to != address(this));
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    *   @dev Allows another account/contract to spend some tokens on its behalf
    *   throws on any error rather then return a false flag to minimize user errors
    *
    *   also, to minimize the risk of the approve/transferFrom attack vector
    *   approve has to be called twice in 2 separate transactions - once to
    *   change the allowance to 0 and secondly to change it to the new allowance
    *   value
    *
    *   @param _spender      approved address
    *   @param _value       allowance amount
    *
    *   @return true if the approval was successful
    */
    function approve(address _spender, uint _value) public returns (bool success) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
    *   @dev An account/contract attempts to get the coins
    *   throws on any error rather then return a false flag to minimize user errors
    *
    *   @param _from         source address
    *   @param _to           target address
    *   @param _value        amount
    *
    *   @return true if the transfer was successful
    */
    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        // Make transfer only if transfer is possible
        require(transferIsPossible);

        require(_to != address(0) && _to != address(this));

        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
    *   @dev Add an emitter account
    *   
    *   @param _emitter     emitter&#39;s address
    */
    function addEmitter(address _emitter) public onlyOwner {
        emitters[_emitter] = true;
    }
    
    /**
    *   @dev Remove an emitter account
    *   
    *   @param _emitter     emitter&#39;s address
    */
    function removeEmitter(address _emitter) public onlyOwner {
        emitters[_emitter] = false;
    }
    
    /**
    *   @dev Mint token in batches
    *   
    *   @param _adresses     token holders&#39; adresses
    *   @param _values       token holders&#39; values
    */
    function batchMint(address[] _adresses, uint[] _values) public onlyEmitter {
        require(_adresses.length == _values.length);
        for (uint i = 0; i < _adresses.length; i++) {
            require(minted(_adresses[i], _values[i]));
        }
    }

    /**
    *   @dev Transfer token in batches
    *   
    *   @param _adresses     token holders&#39; adresses
    *   @param _values       token holders&#39; values
    */
    function batchTransfer(address[] _adresses, uint[] _values) public {
        require(_adresses.length == _values.length);
        for (uint i = 0; i < _adresses.length; i++) {
            require(transfer(_adresses[i], _values[i]));
        }
    }

    /**
    *   @dev Burn Tokens
    *   @param _from       token holder address which the tokens will be burnt
    *   @param _value      number of tokens to burn
    */
    function burn(address _from, uint _value) public onlyEmitter {
        // Burn tokens only if minting stage is not finished
        require(!mintingIsFinished);

        require(_value <= balances[_from]);
        balances[_from] = balances[_from].sub(_value);
        totalSupply = totalSupply.sub(_value);
    }

    /**
    *   @dev Function to check the amount of tokens that an owner allowed to a spender.
    *
    *   @param _tokenOwner        the address which owns the funds
    *   @param _spender      the address which will spend the funds
    *
    *   @return              the amount of tokens still avaible for the spender
    */
    function allowance(address _tokenOwner, address _spender) public constant returns (uint remaining) {
        return allowed[_tokenOwner][_spender];
    }

    /**
    *   @dev Function to check the amount of tokens that _tokenOwner has.
    *
    *   @param _tokenOwner        the address which owns the funds
    *
    *   @return              the amount of tokens _tokenOwner has
    */
    function balanceOf(address _tokenOwner) public constant returns (uint balance) {
        return balances[_tokenOwner];
    }

    function minted(address _to, uint _value) internal returns (bool) {
        // Mint tokens only if minting stage is not finished
        require(!mintingIsFinished);
        balances[_to] = balances[_to].add(_value);
        totalSupply = totalSupply.add(_value);
        emit Transfer(address(0), _to, _value);
        return true;
    }
}