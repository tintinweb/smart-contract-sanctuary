/**
 *Submitted for verification at Etherscan.io on 2021-06-26
*/

pragma solidity >=0.4.25 <0.6.0;

//@title Instaminter
//@R^3
//@notice creates ERC-20 token contracts

contract ERC20Basic {
  uint256 public totalSupply;

  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);


}

contract Ownable {
  address public owner;

    address public creator;

    modifier onlyTokenOwner() {
        require(msg.sender == creator || msg.sender == owner);
        _;
    }


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
  function transferOwnership(address newOwner) onlyTokenOwner public {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

  function transferCreator(address newCreator) onlyTokenOwner public {
    if (newCreator != address(0)) {
      creator = newCreator;
    }
  }

}

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
  modifier whenPaused {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyTokenOwner whenNotPaused public returns (bool) {
    paused = true;
    emit Pause();
    return true;
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyTokenOwner whenPaused public returns (bool) {
    paused = false;
    emit Unpause();
    return true;
  }
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

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
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    uint value = _value;
    balances[msg.sender] = balances[msg.sender].sub(value);
    balances[_to] = balances[_to].add(value);
    emit Transfer(msg.sender, _to, value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256 balance) {
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
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    uint _allowance = allowed[_from][msg.sender];
    uint value = _value;
    balances[_to] = balances[_to].add(value);
    balances[_from] = balances[_from].sub(value);
    allowed[_from][msg.sender] = _allowance.sub(value);
    emit Transfer(_from, _to, value);
    return true;
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    uint value = _value;
    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = value;
    emit Approval(msg.sender, _spender, value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

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
  function mint(address _to, uint256 _amount) onlyTokenOwner canMint public returns (bool) {
    uint amount = _amount;
    totalSupply = totalSupply.add(amount);
    balances[_to] = balances[_to].add(amount);
    emit Mint(_to, amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyTokenOwner public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint _value) whenNotPaused public returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) whenNotPaused public returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }
}

contract BurnableToken is StandardToken {

    event Burn(address indexed burner, uint256 value);

    /**
     * @dev Burns a specified amount of tokens.
     * @param _value The amount of tokens to burn.
     */
    function burn(uint256 _value) public {
        require(_value > 0);
        uint value = _value;
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Burn(msg.sender, value);
    }

}

contract ERCDetailed is BurnableToken, PausableToken, MintableToken {

    string private _name;
    string private _symbol;
    uint256 private _decimals;

    constructor (string memory name, string memory symbol, uint256 decimals, address _creator) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        creator = _creator;
    }

    /**
     * @return the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @return the symbol of the token.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @return the number of decimals of the token.
     */
    function decimals() public view returns (uint256) {
        return _decimals;
    }

    function burn(uint256 _value) whenNotPaused public {
        super.burn(_value);
    }
}

//@dev contract creates new ERC-20 tokens
contract TokenFactory is Ownable {
    address[] public deployedTokens;
    ERCDetailed public newToken;
    //@dev allows for check on which tokens are associated with a specific address
    mapping (address => address) public myTokens;

      //@dev fee for generating token contract
    uint public tokenFee = 0.01 ether;
    //@dev set token fee (owner only)
    function setTokenFee(uint _fee) external onlyOwner {
      tokenFee = _fee;
}

//@dev creates ERC-20 token
    function createToken(string _name, string _symbol, uint256 _decimals) external payable returns (ERCDetailed) {
        require(msg.value == tokenFee);
        newToken = new ERCDetailed(_name, _symbol, _decimals, msg.sender);
        deployedTokens.push(address(newToken));
        myTokens[address(newToken)] = msg.sender;
        return(newToken);
    }

//@dev gets list of all deployed tokens
    function getDeployedTokens() public view returns (address[] memory) {
        return deployedTokens;
    }

//@dev allows owner to withdraw fees
      function withdraw() external onlyOwner {
      address _owner = address(uint160(owner));
      _owner.transfer(address(this).balance);
      }
}