/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
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
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
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
  function balanceOf(address _owner) public view returns (uint256 balance) {
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
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
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
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  /**
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is StandardToken {

    event Burn(address indexed burner, uint256 value);

    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(uint256 _value) public {
        require(_value > 0);
        require(_value <= balances[msg.sender]);
        // no need to require value <= totalSupply, since that would imply the
        // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }
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
  function Ownable() public {
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract CHXToken is BurnableToken, Ownable {
    string public constant name = "Chainium";
    string public constant symbol = "CHX";
    uint8 public constant decimals = 18;

    bool public isRestricted = true;
    address public tokenSaleContractAddress;

    function CHXToken()
        public
    {
        totalSupply = 200000000e18;
        balances[owner] = totalSupply;
        Transfer(address(0), owner, totalSupply);
    }

    function setTokenSaleContractAddress(address _tokenSaleContractAddress)
        external
        onlyOwner
    {
        require(_tokenSaleContractAddress != address(0));
        tokenSaleContractAddress = _tokenSaleContractAddress;
    }


    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Transfer Restriction
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    function setRestrictedState(bool _isRestricted)
        external
        onlyOwner
    {
        isRestricted = _isRestricted;
    }

    modifier restricted() {
        if (isRestricted) {
            require(
                msg.sender == owner ||
                (msg.sender == tokenSaleContractAddress && tokenSaleContractAddress != address(0))
            );
        }
        _;
    }


    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Transfers
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    function transfer(address _to, uint _value)
        public
        restricted
        returns (bool)
    {
        require(_to != address(this));
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value)
        public
        restricted
        returns (bool)
    {
        require(_to != address(this));
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint _value)
        public
        restricted
        returns (bool)
    {
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue)
        public
        restricted
        returns (bool success)
    {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue)
        public
        restricted
        returns (bool success)
    {
        return super.decreaseApproval(_spender, _subtractedValue);
    }


    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Batch transfers
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    function batchTransfer(address[] _recipients, uint[] _values)
        external
        returns (bool)
    {
        require(_recipients.length == _values.length);

        for (uint i = 0; i < _values.length; i++) {
            require(transfer(_recipients[i], _values[i]));
        }

        return true;
    }

    function batchTransferFrom(address _from, address[] _recipients, uint[] _values)
        external
        returns (bool)
    {
        require(_recipients.length == _values.length);

        for (uint i = 0; i < _values.length; i++) {
            require(transferFrom(_from, _recipients[i], _values[i]));
        }

        return true;
    }

    function batchTransferFromMany(address[] _senders, address _to, uint[] _values)
        external
        returns (bool)
    {
        require(_senders.length == _values.length);

        for (uint i = 0; i < _values.length; i++) {
            require(transferFrom(_senders[i], _to, _values[i]));
        }

        return true;
    }

    function batchTransferFromManyToMany(address[] _senders, address[] _recipients, uint[] _values)
        external
        returns (bool)
    {
        require(_senders.length == _recipients.length);
        require(_senders.length == _values.length);

        for (uint i = 0; i < _values.length; i++) {
            require(transferFrom(_senders[i], _recipients[i], _values[i]));
        }

        return true;
    }

    function batchApprove(address[] _spenders, uint[] _values)
        external
        returns (bool)
    {
        require(_spenders.length == _values.length);

        for (uint i = 0; i < _values.length; i++) {
            require(approve(_spenders[i], _values[i]));
        }

        return true;
    }

    function batchIncreaseApproval(address[] _spenders, uint[] _addedValues)
        external
        returns (bool)
    {
        require(_spenders.length == _addedValues.length);

        for (uint i = 0; i < _addedValues.length; i++) {
            require(increaseApproval(_spenders[i], _addedValues[i]));
        }

        return true;
    }

    function batchDecreaseApproval(address[] _spenders, uint[] _subtractedValues)
        external
        returns (bool)
    {
        require(_spenders.length == _subtractedValues.length);

        for (uint i = 0; i < _subtractedValues.length; i++) {
            require(decreaseApproval(_spenders[i], _subtractedValues[i]));
        }

        return true;
    }


    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Miscellaneous
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    function burn(uint _value)
        public
        onlyOwner
    {
        super.burn(_value);
    }

    // Enable recovery of ether sent by mistake to this contract&#39;s address.
    function drainStrayEther(uint _amount)
        external
        onlyOwner
        returns (bool)
    {
        owner.transfer(_amount);
        return true;
    }

    // Enable recovery of any ERC20 compatible token, sent by mistake to this contract&#39;s address.
    function drainStrayTokens(ERC20Basic _token, uint _amount)
        external
        onlyOwner
        returns (bool)
    {
        return _token.transfer(owner, _amount);
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

contract Whitelistable is Ownable {

    mapping (address => bool) whitelist;
    address public whitelistAdmin;

    function Whitelistable()
        public
    {
        whitelistAdmin = owner; // Owner fulfils the role of the admin initially, until new admin is set.
    }

    modifier onlyOwnerOrWhitelistAdmin() {
        require(msg.sender == owner || msg.sender == whitelistAdmin);
        _;
    }

    modifier onlyWhitelisted() {
        require(whitelist[msg.sender]);
        _;
    }

    function isWhitelisted(address _address)
        external
        view
        returns (bool)
    {
        return whitelist[_address];
    }

    function addToWhitelist(address[] _addresses)
        external
        onlyOwnerOrWhitelistAdmin
    {
        for (uint i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = true;
        }
    }

    function removeFromWhitelist(address[] _addresses)
        external
        onlyOwnerOrWhitelistAdmin
    {
        for (uint i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = false;
        }
    }

    function setWhitelistAdmin(address _newAdmin)
        public
        onlyOwnerOrWhitelistAdmin
    {
        require(_newAdmin != address(0));
        whitelistAdmin = _newAdmin;
    }
}

contract CHXTokenSale is Whitelistable {
    using SafeMath for uint;

    event TokenPurchased(address indexed investor, uint contribution, uint tokens);

    uint public constant TOKEN_PRICE = 170 szabo; // Assumes token has 18 decimals

    uint public saleStartTime;
    uint public saleEndTime;
    uint public maxGasPrice = 20e9 wei; // 20 GWEI - to prevent "gas race"
    uint public minContribution = 100 finney; // 0.1 ETH
    uint public maxContributionPhase1 = 500 finney; // 0.5 ETH
    uint public maxContributionPhase2 = 10 ether;
    uint public phase1DurationInHours = 24;

    CHXToken public tokenContract;

    mapping (address => uint) public etherContributions;
    mapping (address => uint) public tokenAllocations;
    uint public etherCollected;
    uint public tokensSold;

    function CHXTokenSale()
        public
    {
    }

    function setTokenContract(address _tokenContractAddress)
        external
        onlyOwner
    {
        require(_tokenContractAddress != address(0));
        tokenContract = CHXToken(_tokenContractAddress);
        require(tokenContract.decimals() == 18); // Calculations assume 18 decimals (1 ETH = 10^18 WEI)
    }

    function transferOwnership(address newOwner)
        public
        onlyOwner
    {
        require(newOwner != owner);

        if (whitelistAdmin == owner) {
            setWhitelistAdmin(newOwner);
        }

        super.transferOwnership(newOwner);
    }


    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Sale
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    function()
        public
        payable
    {
        address investor = msg.sender;
        uint contribution = msg.value;

        require(saleStartTime <= now && now <= saleEndTime);
        require(tx.gasprice <= maxGasPrice);
        require(whitelist[investor]);
        require(contribution >= minContribution);
        if (phase1DurationInHours.mul(1 hours).add(saleStartTime) >= now) {
            require(etherContributions[investor].add(contribution) <= maxContributionPhase1);
        } else {
            require(etherContributions[investor].add(contribution) <= maxContributionPhase2);
        }

        etherContributions[investor] = etherContributions[investor].add(contribution);
        etherCollected = etherCollected.add(contribution);

        uint multiplier = 1e18; // 18 decimal places
        uint tokens = contribution.mul(multiplier).div(TOKEN_PRICE);
        tokenAllocations[investor] = tokenAllocations[investor].add(tokens);
        tokensSold = tokensSold.add(tokens);

        require(tokenContract.transfer(investor, tokens));
        TokenPurchased(investor, contribution, tokens);
    }

    function sendCollectedEther(address _recipient)
        external
        onlyOwner
    {
        if (this.balance > 0) {
            _recipient.transfer(this.balance);
        }
    }

    function sendRemainingTokens(address _recipient)
        external
        onlyOwner
    {
        uint unsoldTokens = tokenContract.balanceOf(this);
        if (unsoldTokens > 0) {
            require(tokenContract.transfer(_recipient, unsoldTokens));
        }
    }


    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Configuration
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    function setSaleTime(uint _newStartTime, uint _newEndTime)
        external
        onlyOwner
    {
        require(_newStartTime <= _newEndTime);
        saleStartTime = _newStartTime;
        saleEndTime = _newEndTime;
    }

    function setMaxGasPrice(uint _newMaxGasPrice)
        external
        onlyOwner
    {
        require(_newMaxGasPrice > 0);
        maxGasPrice = _newMaxGasPrice;
    }

    function setMinContribution(uint _newMinContribution)
        external
        onlyOwner
    {
        require(_newMinContribution > 0);
        minContribution = _newMinContribution;
    }

    function setMaxContributionPhase1(uint _newMaxContributionPhase1)
        external
        onlyOwner
    {
        require(_newMaxContributionPhase1 > minContribution);
        maxContributionPhase1 = _newMaxContributionPhase1;
    }

    function setMaxContributionPhase2(uint _newMaxContributionPhase2)
        external
        onlyOwner
    {
        require(_newMaxContributionPhase2 > minContribution);
        maxContributionPhase2 = _newMaxContributionPhase2;
    }

    function setPhase1DurationInHours(uint _newPhase1DurationInHours)
        external
        onlyOwner
    {
        require(_newPhase1DurationInHours > 0);
        phase1DurationInHours = _newPhase1DurationInHours;
    }
}