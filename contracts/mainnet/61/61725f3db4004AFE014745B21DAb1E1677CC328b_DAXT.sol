pragma solidity ^0.4.13;

contract Versioned {
    string public version;

    function Versioned(string _version) public {
        version = _version;
    }
}

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

contract Pausable is Ownable {
    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused || msg.sender == owner);
        _;
    }

    function pause() onlyOwner public {
        paused = true;
    }

    function unpause() onlyOwner public {
        paused = false;
    }
}

contract Extractable is Ownable {
    // allow contract to receive ether
    function () payable public {}

    // allow to extract ether from contract
    function extractEther(address withdrawalAddress) public onlyOwner {
        if (this.balance > 0) {
            withdrawalAddress.transfer(this.balance);
        }
    }

    // Allow to withdraw ERC20 token from contract
    function extractToken(address tokenAddress, address withdrawalAddress) public onlyOwner {
        ERC20Basic tokenContract = ERC20Basic(tokenAddress);
        uint256 balance = tokenContract.balanceOf(this);
        if (balance > 0) {
            tokenContract.transfer(withdrawalAddress, balance);
        }
    }
}

contract Destructible is Ownable {

  function Destructible() public payable { }

  /**
   * @dev Transfers the current balance to the owner and terminates the contract.
   */
  function destroy() onlyOwner public {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) onlyOwner public {
    selfdestruct(_recipient);
  }
}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  function DetailedERC20(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}

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
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
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

contract FloatingSupplyToken is Ownable, StandardToken {
    using SafeMath for uint256;
    // create new token tranche for contract you own
    // this increases total supply and credits new tokens to owner
    function issueTranche(uint256 _amount) public onlyOwner returns (uint256) {
        require(_amount > 0);

        totalSupply = totalSupply.add(_amount);
        balances[owner] = balances[owner].add(_amount);

        emit Transfer(address(0), owner, _amount);
        return totalSupply;
    }

    // destroy tokens that belongs to you
    // this decreases your balance and total supply
    function burn(uint256 _amount) public {
        require(_amount > 0);
        require(balances[msg.sender] > 0);
        require(_amount <= balances[msg.sender]);

        assert(_amount <= totalSupply);

        totalSupply = totalSupply.sub(_amount);
        balances[msg.sender] = balances[msg.sender].sub(_amount);

        emit Transfer(msg.sender, address(0), _amount);
    }
}

contract FundToken is StandardToken {
    using SafeMath for uint256;

    // Fund internal balances are held in here
    mapping (address => mapping (address => uint256)) fundBalances;

    // Owner of account manages funds on behalf of third parties and
    // need to keep an account of what belongs to whom
    mapping (address => bool) public fundManagers;

    // modifiers
    // only fund manager can execute that
    modifier onlyFundManager() {
        require(fundManagers[msg.sender]);
        _;
    }

    // simple balance management
    // wrapper for StandardToken to control fundmanager status
    function transfer(address _to, uint _value) public returns (bool success) {
        require(!fundManagers[msg.sender]);
        require(!fundManagers[_to]);

        return super.transfer(_to, _value);
    }

    // events

    // register address as fund address
    event RegisterFund(address indexed _fundManager);

    // remove address from registered funds
    event DissolveFund(address indexed _fundManager);

    // owner&#39;s tokens moved into the fund
    event FundTransferIn(address indexed _from, address indexed _fundManager,
                         address indexed _owner, uint256 _value);

    // tokens moved from the fund to a regular address
    event FundTransferOut(address indexed _fundManager, address indexed _from,
                          address indexed _to, uint256 _value);

    // tokens moved from the fund to a regular address
    event FundTransferWithin(address indexed _fundManager, address indexed _from,
                             address indexed _to, uint256 _value);

    // fund register/dissolve
    // register fund status for an address, address must be empty for that
    function registerFund() public {
        require(balances[msg.sender] == 0);
        require(!fundManagers[msg.sender]);

        fundManagers[msg.sender] = true;

        emit RegisterFund(msg.sender);
    }

    // unregister fund status for an address, address must be empty for that
    function dissolveFund() public {
        require(balances[msg.sender] == 0);
        require(fundManagers[msg.sender]);

        delete fundManagers[msg.sender];

        emit DissolveFund(msg.sender);
    }


    // funded balance management

    // returns balance of an account inside the fund
    function fundBalanceOf(address _fundManager, address _owner) public view returns (uint256) {
        return fundBalances[_fundManager][_owner];
    }

    // Transfer the balance from simple account to account in the fund
    function fundTransferIn(address _fundManager, address _to, uint256 _amount) public {
        require(fundManagers[_fundManager]);
        require(!fundManagers[msg.sender]);

        require(balances[msg.sender] >= _amount);
        require(_amount > 0);

        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_fundManager] = balances[_fundManager].add(_amount);
        fundBalances[_fundManager][_to] = fundBalances[_fundManager][_to].add(_amount);

        emit FundTransferIn(msg.sender, _fundManager, _to, _amount);
        emit Transfer(msg.sender, _fundManager, _amount);
    }

    // Transfer the balance from account in the fund to simple account
    function fundTransferOut(address _from, address _to, uint256 _amount) public {
        require(!fundManagers[_to]);
        require(fundManagers[msg.sender]);

        require(_amount > 0);
        require(balances[msg.sender] >= _amount);
        require(fundBalances[msg.sender][_from] >= _amount);
        
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        fundBalances[msg.sender][_from] = fundBalances[msg.sender][_from].sub(_amount);
        
        if (fundBalances[msg.sender][_from] == 0){
            delete fundBalances[msg.sender][_from];
        }
        
        emit FundTransferOut(msg.sender, _from, _to, _amount);
        emit Transfer(msg.sender, _to, _amount);
    }

    // Transfer the balance between two accounts within the fund
    function fundTransferWithin(address _from, address _to, uint256 _amount) public {
        require(fundManagers[msg.sender]);

        require(_amount > 0);
        require(balances[msg.sender] >= _amount);
        require(fundBalances[msg.sender][_from] >= _amount);

        fundBalances[msg.sender][_from] = fundBalances[msg.sender][_from].sub(_amount);
        fundBalances[msg.sender][_to] = fundBalances[msg.sender][_to].add(_amount);

        if (fundBalances[msg.sender][_from] == 0){
            delete fundBalances[msg.sender][_from];
        }

        emit FundTransferWithin(msg.sender, _from, _to, _amount);
    }

    // check fund controls before forwarding call
    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value .
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(!fundManagers[msg.sender]);

        return super.approve(_spender, _value);
    }

    // check fund controls before forwarding call to standard token allowance spending function
    function transferFrom(address _from, address _to,
                          uint256 _amount) public returns (bool success) {
        require(!fundManagers[_from]);
        require(!fundManagers[_to]);

        return super.transferFrom(_from, _to, _amount);
    }
}

contract BurnFundToken is FundToken, FloatingSupplyToken {
    using SafeMath for uint256;

    //events
    // owner&#39;s tokens from the managed fund burned
    event FundBurn(address indexed _fundManager, address indexed _owner, uint256 _value);

    // destroy tokens that belongs to you
    // this decreases total supply
    function burn(uint256 _amount) public {
        require(!fundManagers[msg.sender]);

        super.burn(_amount);
    }

    // destroy tokens that belong to the fund you control
    // this decreases that account&#39;s balance, fund balance, total supply
    function fundBurn(address _fundAccount, uint256 _amount) public onlyFundManager {
        require(fundManagers[msg.sender]);
        require(balances[msg.sender] != 0);
        require(fundBalances[msg.sender][_fundAccount] > 0);
        require(_amount > 0);
        require(_amount <= fundBalances[msg.sender][_fundAccount]);

        assert(_amount <= totalSupply);
        assert(_amount <= balances[msg.sender]);

        totalSupply = totalSupply.sub(_amount);
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        fundBalances[msg.sender][_fundAccount] = fundBalances[msg.sender][_fundAccount].sub(_amount);

        emit FundBurn(msg.sender, _fundAccount, _amount);
    }
}

contract PausableToken is BurnFundToken, Pausable {

    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }

    function burn(uint256 _amount) public whenNotPaused {
        return super.burn(_amount);
    }

    function fundBurn(address _fundAccount, uint256 _amount) public whenNotPaused {
        return super.fundBurn(_fundAccount, _amount);
    }

    function registerFund() public whenNotPaused {
        return super.registerFund();
    }

    function dissolveFund() public whenNotPaused {
        return super.dissolveFund();
    }

    function fundTransferIn(address _fundManager, address _to, uint256 _amount) public whenNotPaused {
        return super.fundTransferIn(_fundManager, _to, _amount);
    }

    function fundTransferOut(address _from, address _to, uint256 _amount) public whenNotPaused {
        return super.fundTransferOut(_from, _to, _amount);
    }

    function fundTransferWithin(address _from, address _to, uint256 _amount) public whenNotPaused {
        return super.fundTransferWithin(_from, _to, _amount);
    }
}

contract DAXT is PausableToken,
    DetailedERC20("Digital Asset Exchange Token", "DAXT", 18),
    Versioned("1.2.0"),
    Destructible,
    Extractable {

}