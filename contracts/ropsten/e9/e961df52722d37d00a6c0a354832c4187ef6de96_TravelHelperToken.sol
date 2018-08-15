pragma solidity 0.4.24;

contract ERC20 {
 // modifiers

 // mitigate short address attack
 // thanks to https://github.com/numerai/contract/blob/c182465f82e50ced8dacb3977ec374a892f5fa8c/contracts/Safe.sol#L30-L34.
 // TODO: doublecheck implication of >= compared to ==
    modifier onlyPayloadSize(uint numWords) {
        assert(msg.data.length >= numWords * 32 + 4);
        _;
    }

    uint256 public totalSupply;
    /*
      *  Public functions
      */
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);

    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);

    /*
      *  Events
      */
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed from, uint256 value);
    event SaleContractActivation(address saleContract, uint256 tokensForSale);
}
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  // it is recommended to define functions which can neither read the state of blockchain nor write in it as pure instead of constant

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */

contract Ownable {
    address public owner;
    address public creater;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    function Ownable(address _owner) public {
        creater = msg.sender;
        if (_owner != 0) {
            owner = _owner;

        }
        else {
            owner = creater;
        }

    }
    /**
    * @dev Throws if called by any account other than the owner.
    */

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier isCreator() {
        require(msg.sender == creater);
        _;
    }

   

}






/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20 {
    using SafeMath for uint256;
    mapping (address => mapping (address => uint256)) internal allowed;
    mapping(address => uint256) balances;

  /// @dev Returns number of tokens owned by given address
  /// @param _owner Address of token owner
  /// @return Balance of owner

  // it is recommended to define functions which can read the state of blockchain but cannot write in it as view instead of constant

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

  /// @dev Transfers sender&#39;s tokens to a given address. Returns success
  /// @param _to Address of token receiver
  /// @param _value Number of tokens to transfer
  /// @return Was transfer successful?

    function transfer(address _to, uint256 _value) public onlyPayloadSize(2) returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0 && balances[_to].add(_value) > balances[_to]) {
            balances[msg.sender] = balances[msg.sender].sub(_value);
            balances[_to] = balances[_to].add(_value);
            emit Transfer(msg.sender, _to, _value); // solhint-disable-line
            return true;
        } else {
            return false;
        }
    }

    /// @dev Allows allowed third party to transfer tokens from one address to another. Returns success
    /// @param _from Address from where tokens are withdrawn
    /// @param _to Address to where tokens are sent
    /// @param _value Number of tokens to transfer
    /// @return Was transfer successful?

    function transferFrom(address _from, address _to, uint256 _value) public onlyPayloadSize(3) returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value); // solhint-disable-line
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


    function approve(address _spender, uint256 _value) public onlyPayloadSize(2) returns (bool) {
      // To change the approve amount you first have to reduce the addresses`
      //  allowance to zero by calling `approve(_spender, 0)` if it is not
      //  already 0 to mitigate the race condition described here:
      //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729

        require(_value == 0 && (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); // solhint-disable-line
        return true;
    }

    function changeApproval(address _spender, uint256 _oldValue, uint256 _newValue) public onlyPayloadSize(3) returns (bool success) {
        require(allowed[msg.sender][_spender] == _oldValue);
        allowed[msg.sender][_spender] = _newValue;
        emit Approval(msg.sender, _spender, _newValue); // solhint-disable-line
        return true;
    }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

 /**
  * @dev Burns a specific amount of tokens.
  * @param _value The amount of token to be burned.
  */
    function burn(uint256 _value) public returns (bool burnSuccess) {
        require(_value > 0);
        require(_value <= balances[msg.sender]);
        // no need to require value <= totalSupply, since that would imply the
        // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(burner, _value); // solhint-disable-line
        return true;
    }

}
contract TravelHelperToken is StandardToken, Ownable {


//Begin: state variables
    address public saleContract;
    string public constant name = "TravelHelperToken";
    string public constant symbol = "TRH";
    uint public constant decimals = 18;
    bool public fundraising = true;
    uint public totalReleased = 0;
    address public teamAddressOne;
    address public teamAddressTwo;
    address public marketingAddress;
    address public advisorsAddress;
    address public teamAddressThree;
    uint public icoStartBlock;
    uint256 public tokensUnlockPeriod = 37 days / 15; // 7 days presale + 30 days crowdsale
    uint public tokensSupply = 5000000000; // 5 billion
    uint public teamTokens = 1480000000 * 1 ether; // 1.48 billion
    uint public teamAddressThreeTokens = 20000000 * 1 ether; // 20 million
    uint public marketingTeamTokens = 500000000 * 1 ether; // 500 million
    uint public advisorsTokens = 350000000 * 1 ether; // 350 million
    uint public bountyTokens = 150000000 * 1 ether; //150 million
     uint public tokensForSale = 2500000000 * 1 ether; // 2.5 billion
    uint public releasedTeamTokens = 0;
    uint public releasedAdvisorsTokens = 0;
    uint public releasedMarketingTokens = 0;
    bool public tokensLocked = true;
    Ownable ownable;
    mapping (address => bool) public frozenAccounts;
   
 //End: state variables
 //Begin: events
    event FrozenFund(address target, bool frozen);
    event PriceLog(string text);
//End: events

//Begin: modifiers


    modifier manageTransfer() {
        if (msg.sender == owner) {
            _;
        }
        else {
            require(fundraising == false);
            _;
        }
    }
    
    modifier tokenNotLocked() {
      if (icoStartBlock > 0 && block.number.sub(icoStartBlock) > tokensUnlockPeriod) {
        tokensLocked = false;
        _;
      } else {
        revert();
      }
    
  }

//End: modifiers

//Begin: constructor
    function TravelHelperToken(
    address _tokensOwner,
    address _teamAddressOne,
    address _teamAddressTwo,
    address _marketingAddress,
    address _advisorsAddress,
    address _teamAddressThree) public Ownable(_tokensOwner) {
        require(_tokensOwner != 0x0);
        require(_teamAddressOne != 0x0);
        require(_teamAddressTwo != 0x0);
        teamAddressOne = _teamAddressOne;
        teamAddressTwo = _teamAddressTwo;
        advisorsAddress = _advisorsAddress;
        marketingAddress = _marketingAddress;
        teamAddressThree = _teamAddressThree;
        totalSupply = tokensSupply * (uint256(10) ** decimals);

    }

   

//End: constructor

    

//Begin: overriden methods

    function transfer(address _to, uint256 _value) public manageTransfer onlyPayloadSize(2) returns (bool success) {
        require(_to != address(0));
        require(!frozenAccounts[msg.sender]);
        super.transfer(_to,_value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value)
        public
        manageTransfer
        onlyPayloadSize(3) returns (bool)
    {
        require(_to != address(0));
        require(_from != address(0));
        require(!frozenAccounts[msg.sender]);
        super.transferFrom(_from,_to,_value);
        return true;

    }



//End: overriden methods


//Being: setters
   
    function activateSaleContract(address _saleContract) public onlyOwner {
    require(tokensForSale > 0);
    require(teamTokens > 0);
    require(_saleContract != address(0));
    require(saleContract == address(0));
    saleContract = _saleContract;
    uint  totalValue = teamTokens.mul(50).div(100);
    balances[teamAddressOne] = balances[teamAddressOne].add(totalValue);
    balances[teamAddressTwo] = balances[teamAddressTwo].add(totalValue);
    balances[advisorsAddress] = balances[advisorsAddress].add(advisorsTokens);
    balances[teamAddressThree] = balances[teamAddressThree].add(teamAddressThreeTokens);
    balances[marketingAddress] = balances[marketingAddress].add(marketingTeamTokens);
    releasedTeamTokens = releasedTeamTokens.add(teamTokens);
    releasedAdvisorsTokens = releasedAdvisorsTokens.add(advisorsTokens);
    releasedMarketingTokens = releasedMarketingTokens.add(marketingTeamTokens);
    balances[saleContract] = balances[saleContract].add(tokensForSale);
    totalReleased = totalReleased.add(tokensForSale).add(teamTokens).add(advisorsTokens).add(teamAddressThreeTokens).add(marketingTeamTokens);
    tokensForSale = 0; 
    teamTokens = 0; 
    teamAddressThreeTokens = 0;
    icoStartBlock = block.number;
    assert(totalReleased <= totalSupply);
    emit Transfer(address(this), teamAddressOne, totalValue);
    emit Transfer(address(this), teamAddressTwo, totalValue);
    emit Transfer(address(this),teamAddressThree,teamAddressThreeTokens);
    emit Transfer(address(this), saleContract, 2500000000 * 1 ether);
    emit SaleContractActivation(saleContract, 2500000000 * 1 ether);
  }
  
 function saleTransfer(address _to, uint256 _value) public returns (bool) {
    require(saleContract != address(0));
    require(msg.sender == saleContract);
    return super.transfer(_to, _value);
  }
  
  
  function burnTokensForSale() public returns (bool) {
    require(saleContract != address(0));
    require(msg.sender == saleContract);
    uint256 tokens = balances[saleContract];
    require(tokens > 0);
    require(tokens <= totalSupply);
    balances[saleContract] = 0;
    totalSupply = totalSupply.sub(tokens);
    emit Burn(saleContract, tokens);
    return true;
  }
  
   
 
    

    function finalize() public {
        require(fundraising != false);
        require(msg.sender == saleContract);
        // Switch to Operational state. This is the only place this can happen.
        fundraising = false;
    }

   function freezeAccount (address target, bool freeze) public onlyOwner {
        require(target != 0x0);
        require(freeze == (true || false));
        frozenAccounts[target] = freeze;
        emit FrozenFund(target, freeze); // solhint-disable-line
    }
    
    function sendBounty(address _to, uint256 _value) public onlyOwner returns (bool) {
    uint256 value = _value.mul(1 ether);
    require(bountyTokens >= value);
    totalReleased = totalReleased.add(value);
    require(totalReleased <= totalSupply);
    balances[_to] = balances[_to].add(value);
    bountyTokens = bountyTokens.sub(value);
    emit Transfer(address(this), _to, value);
    return true;
  }
 /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) onlyOwner public  {
        owner = newOwner;
        emit OwnershipTransferred(owner, newOwner); // solhint-disable-line
        
    }
//End: setters
   
    function() public {
        revert();
    }

}